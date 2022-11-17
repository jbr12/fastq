#!/usr/bin/env bash

# Defining varaibles 
# - $N_TS is the total number of sequences
# - $L_TS is the total length of the sequences

N_TS=0
L_TS=0

# - $LIST is the list of .fasta and .fa file

# Checking if the argument $1 was set.

if [[ -z $1 ]] 

	# Search in the current folder if no argument was set
	
	then LIST=$(find . \( -name "*.fa" -or -name "*.fasta" \))
	
	# Search in the folder $1

	else LIST=$(find $1 \( -name "*.fa" -or -name "*.fasta" \)) 
	
fi

# Checking if there are .fasta or .fa files. If there are not any, exit the script

if [[ -z "$LIST" ]]

	then echo -e "\nNo .fa or .fasta files found\n" ; exit 1
	
fi

echo -e "\n ###### Files found ###### \n"

for i in $LIST

do 	
	# Checking if the file is a symbolic link
			
	if [[ -h $i ]]
	   
		then echo === $i === Is a symbolic link
		
		else echo === $i ===
	fi
		
	# Checking if the file is empty. If it is empty, skip it and continue with the next

	if [[ ! -s $i ]] 
	
		then echo -e "This file is empty\n" ; continue
	fi
		
	# $N_S is the number of sequences found in a given file
	
	N_S=$(grep -c ">" $i)

		# If the file is not empty, but does not contain any sequence, skip it and continue with the next
		
	if [[ $N_S -eq 0 ]]

		then echo -e "This file does not contain any sequence in fasta format, but it is not empty\n"; continue 

		else 
		
		# Replace all the "-" for "" in the sequences
		# Transform the .fasta file into a table:
		# 	- The input record separator is now ">". Now each "new line" starts in ">"
		#	- A new empty line is created when RS=">", therefore all the actions will be done for NR>1
		# 	- Replace the first line break for a tab space -> Column 1 = ID+Description Column 2 = Sequence
		#	- Replace the rest of the line breaks (all of them in column 2) for nothing. The sequences (column 2) do not have any line breaks now, they will not be counted.
		
		# Each row is a different sequence ID. The first column is title and description, the second column is the sequence.
		
		# The length [0] and the last sequence of each file [1] are stored in the array "data". The array was necesary in order to export multiple strings from the awk script. 
		# Otherwise, two lines of awk would have been needed, converting it into a table twice: one time to print the length and a second one to print the sequence.
		
		data=( $(sed '/>/! s/-//g' $i | awk -F'\t' 'BEGIN{RS=">"}NR>1{sub("\n","\t"); gsub("\n","");n=n+length($2)}END{print n;print $2}') )

						
		# Take the length from the second column of each sequence ID.
		
		L_S=$(echo ${data[0]})
		
		# Take the sequence content
		
		seq=$(echo ${data[1]})

		# If there are only these charactes [NATGCUatgcnu] in the sequnce, it is a nucleotide file. Otherwise, it is an aminoacid file. Store the type of sequence in the $type variabe.
			
		echo $seq | grep -q [^NATGCUatgcnu] && type=aminoacid || type=nucleotide 
	fi
	
		
	if [[ $N_S -gt 1 ]]
	
		# If the file contains more than 1 sequence, use plural
		
		then echo There are $N_S $type sequences
				
		# If the file contains only 1 sequence, use singular
		
		else echo There is $N_S $type sequence
				
	fi
	
	# If the length is greater than 1, then the variable $type is plural
	
	if [[ $L_S -gt 1 ]] ; then type+=s; fi
	
	# The length of the sequences contained in the fasta file
	
	echo -e "The length is $L_S $type \n"

	# The total number of sequences ($N_TS) and the total length ($L_TS) of all the files
	 
	N_TS=$(($N_TS+$N_S))
	
	L_TS=$(($L_TS+$L_S))

done

# Take a title from any of the fasta files: To do this, check if there are titles across all the files in the list. 
# If no titles are found, print there are no titles.

# grep -h -> Suppress the prefixing of file names on output. Only the title is shown.

titles=$(grep ">" -h $LIST)

if [[ -n "$titles" ]]
	
	then echo -e "A single fasta title from any of the files: $(echo "$titles" | head -n 1)\n" 
	
	else echo -e "No titles were found\n"
fi

if [[ $N_TS -gt 1 ]]
	
	# If the global total number is greater then 1 sequence, use plural
	
	then echo There is a global total number of $N_TS sequences
	
	# If the global total number is not greater than 1 sequence, use singular
	
	else echo There is a global total number of $N_TS sequence
	
fi

echo -e "There is a global total length of $L_TS \n"

