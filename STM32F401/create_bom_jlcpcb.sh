#!/bin/bash

# Look for the project name
filename=$(ls *.pro | cut -f1 -d '.')

# Top file CSV
filenameTop=${filename}_bom_top.csv
# Bottom file CSV
filenameBot=${filename}_bom_bottom.csv

# Create the merged file
cat ${filenameTop} ${filenameBot} > ${filename}_bom_jlc.csv

echo "Done as ${filename}_bom_jlc.csv"
exit 0
