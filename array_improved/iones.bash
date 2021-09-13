#!/usr/bin/bash

if [[ $# != 2 ]]; then
    echo Wrong parameter number
    exit 1
fi

# name of system (pdb file name)
SYSTEM=$1
TASK=$2
# Solution salt concentration (mM/l):
CONCENTRATION=150

# Distance from protein to box edge (nm)
BOXEDGE=1.5

# Simple cubic box length (nm):
BOXLENGHT=$(cat tleap_${TASK}.output | awk '/Volume/{print ($2^(0.333))*0.1 }' )

# Net charge of solutes (proton charge units). The value by default is 0
CHARGE=$(cat tleap_${TASK}.output | perl -ane 'if( /unperturbed charge/) { /(-?\d+\.?\d+?)/ && print $1}')
CHARGE=${CHARGE:-0}

# Number of water molecules
WATER=$(cat tleap_${TASK}.output | awk '/WAT/{print $2}')

# calculate Protein mass in kDa
PMASS=$(cpptraj --interactive  -p $SYSTEM -y $SYSTEM  <<EOF | awk '/Sum/{print $NF*0.001}'
mass
quit
EOF
)

# extract the least number of iones, by using the page SLTCAP
IONS=$(
curl https://www.phys.ksu.edu/personal/schmit/SLTCAP/SLTCAP.pl \
     -d "ProteinMass=$PMASS"      \
     -d "SoluteCharges=$CHARGE"  \
     -d "BoxLength=$BOXLENGHT"   \
     -d "Molecules=$WATER"       \
     -d "BoxEdge=$BOXEDGE"       \
     -d "Concentration=$CONCENTRATION" \
     -s | sed -e 's/<[^>]*>//g' | awk '/requires/{printf("%.0f", $4<$7?$4:$7)}' \
    )

cat <<EOF | tee ions_add.txt
System:                 $SYSTEM
Protein mass (kDa):     $PMASS
Ion concentration (mM): $CONCENTRATION
Charge:                 $CHARGE
Box lenght (nm):        $BOXLENGHT
Molecules of water:     $WATER
Distance to edge (nm):  $BOXEDGE

Require (c)anions to 
concentration (not 
for neutralizing):      $IONS 
EOF

ADD_IONS=$(cat <<EOF
# neutralize by add the necessary ions
#addIons chip K+ 0
addIons chip Na+ 0
addIons chip Cl- 0

# $CONCENTRATON mM
#addIons chip K+ $IONS
addIons chip Na+ $IONS
addIons chip Cl- $IONS
EOF
)

perl -pi.bak -e "s/\#xxxIONIZINGxxx/$ADD_IONS/" tleap_${TASK}.input

