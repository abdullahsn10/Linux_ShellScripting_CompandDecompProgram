#!/bin/bash


#--------------------------------------------------------------
# SHELL PROJECT - COMPRESSION AND DECOMPRESSION TOOL
# STUDENT NAME : Abdullah Sami Naser
# STUDENT ID : 1201952
#--------------------------------------------------------------


#compress function
function compress(){
	# define needed variables , words will contain every word in the input file
	local i=0
	local word=""
	words=()

	# read each word from the input file and store them in an array
	while IFS="" read -r -N1 c; do
		# check for special chars to stop
		if echo "$c" | grep "[^A-Za-z]" > /dev/null || [[ "$c" == $'\n' ]]; then
			if [[ ! -z "$word" ]]; then
				words["$i"]="$word"
				(( i++ ))
			fi
			if [[ "$c" == " " ]]; then
				words["$i"]="sp"
			elif [[ "$c" == $'\n' ]]; then
				words["$i"]="newline"
			else
				words["$i"]="$c"
			fi
			(( i++ ))
			word=""
		else
			word+="$c"
		fi
	done < $userfile

	# create the compressed file
	if [ -f compressed.txt ]; then
		rm compressed.txt
	fi
	touch compressed.txt

	# store the binary codes in the compressed file
	for ((i=0; i<"${#words[@]}"; i++)); do
		# check if the word has a value in dictionary
		if [[ ! -z "${dict_array["${words["$i"]}"]}" ]]; then
			echo "${dict_array["${words["$i"]}"]}" >> compressed.txt
		else
			dict_array["${words["$i"]}"]=$(printf "0x%04X" "${#dict_array[@]}")
			echo "${dict_array["${words["$i"]}"]}" >> compressed.txt
		fi
	done
}





#decompress function
function decompress(){

	# create the decompressed file
	if [ -f decompressed.txt ]; then
		rm decompressed.txt
	fi
	touch decompressed.txt
	while IFS= read -r code; do
		# check that we read the code correctly
		if echo "$code" | grep "0x" > /dev/null; then
			if [[ ! -z "${dict_array["$code"]}" ]]; then
				if [[ "${dict_array["$code"]}" == "newline" ]]; then
					printf "\n" >> decompressed.txt
				elif [[ "${dict_array["$code"]}" == "sp" ]]; then
					printf " " >> decompressed.txt
				else
					printf "%s" "${dict_array["$code"]}" >> decompressed.txt
				fi
			else
				echo "$code Does not match anything in Dictionary"
				echo "DECOMPRESS OPERATION FAILED ..."
				echo
				exit 1
			fi
		fi
	done < "$comp_ufile"
}




#load dictionary function
function load_dict(){
	local dict_file="$1"
	local is_comp="$2"
	while read -r line;do
		# split line into word and binary code
		binary_code=$(echo "$line" | awk '{print $1}')
		dict_word=$(echo "$line" | awk '{print $2}')

		# check if its compression or decompression , and load based on what is
		if [ "$is_comp" -eq 1 ]; then
			# check if the word is not empty
			if [[ -n "$dict_word" ]]; then
				dict_array["$dict_word"]="$binary_code"
			fi
		else
			if [[ -n "$binary_code" ]]; then
				dict_array["$binary_code"]="$dict_word"
			fi
		fi

	done < "$dict_file"
}


# this function used to refresh the dictionary
function refresh_dict(){
	local dc_file="$1"
	for key in "${!dict_array[@]}"; do
		value="${dict_array["$key"]}"
		echo "$value $key" >> "$dc_file"
	done
}








#Welcoming Message
echo "--------------------------------------------------------------------"
echo "   Welcome to Dictionary-Based Compression and Decompression Tool"
echo "--------------------------------------------------------------------"

# declare the associative array (Hash table)
declare -A dict_array

# This is the main menu of the program
while true
do
	echo -e ">> Do you have a Dictionary file? [Y/N] : \c"
	read havedict
	if [ "$havedict" = "Y" ]
	then
		echo -e ">> Please Enter the path of that dictionary: \c"
		read dictpath
		if [ -e $dictpath ]
		then
			:
		else
			echo ">> ERROR: File does not exist, please check path and try again..."
			continue
		fi
	else
		touch dictionary.txt
		dictpath="dictionary.txt"
		echo "> A Dictionary file created in current working directory (dictionary.txt)"
	fi



	# Menu of the program
	echo "----------------------------------------------------------"
	echo " -Compress A File"
	echo " -Decompress A File"
	echo " -Quit"
	echo -e ">> Please Enter a choice from the menu above: \c"
	read
	userchoice=$(echo $REPLY | tr [A-Z] [a-z])
	case $userchoice in
	c|compress|compression )

		#load the dictionary
		load_dict "$dictpath" "1"
		echo "----------------------------------------------"
		echo "> COMPRESS OPERATION ..."
		echo "-----------------------------------------------"
		echo -e ">> Please Enter the Path of The File You Want to Compress it: \c"
		read userfile
		if [ -e $userfile ]
		then
			echo "> The File Opened Successfully"
		else
			echo "> ERROR: The file Can't be opened, Please Check path and try again"
			continue
		fi
		# call compress function
		compress
		# refresh the dictionary after compress operation
		rm $dictpath
	        refresh_dict $dictpath
        	sort $dictpath > temp
        	mv temp $dictpath

		# calculate the compress ration
		echo "> COMPRESS OPERATION DONE ..."
		echo "> OPERATION STATUS: "
		uncomp_size=$(( $(wc -c "$userfile" | awk '{print $1}') * 16 ))
		comp_size=$(( $(wc -l compressed.txt | awk '{print $1}') * 16 ))
		echo "> UNCOMPRESSED FILE SIZE = $uncomp_size bits = $(( "$uncomp_size" / 8 )) bytes"
		echo "> COMPRESSED FILE SIZE = $comp_size bits = $(( "$comp_size" / 8 )) bytes"
		echo "> COMPRESS RATIO = $(echo "scale=3; $uncomp_size/$comp_size" | bc)" 
		echo "Check the file named (compressed.txt)"
		echo "----------------------------------------------"
		echo
		echo;;

	# decompress operation
	d|decompress|decompression )
		load_dict $dictpath 0
		echo "---------------------------------------------"
		echo "> DECOMPRESS OPERATIION ..."
		echo "---------------------------------------------"
		echo -e ">> Please Enter the path of the compressed file: \c"
		read comp_ufile
		if [ -e $comp_ufile ]; then
			echo "> The file Opened Successfully"
		else
			echo "> ERROR: The file Can't be opened, Please Check path and try again"
			continue
		fi
		decompress
		echo "DECOMPRESS OPERATION DONE ..."
		echo "Check file named (decompressed.txt)"
		echo "--------------------------------------------"
		echo
		echo;;

	q|quit )
		echo "----Thank You for using our tool, Good Luck----"
		exit;;
	* )
		echo "> ERROR: choice not available"
		echo
		continue;;
	esac
	echo
done



# ---------------------------------------------------------------------------------






