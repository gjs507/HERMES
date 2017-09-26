### HERMES Code Version 0.3.5 ###
# Creator: Greg Smith 
#
# York Plasma Institute
# 
# last update on: 26-09-17
#
# To be used in conjunction with Hybrid Plamsa Equipment Model (HPEM) which belongs to Prof Mark Kushner
# http://uigelz.eecs.umich.edu/
#
# Legal stuff: open source do what you want to it, but keep it that way for everyone you give it to
# author takes no responsibility if it breaks things
# 
# Code Notes:  "readme.txt" to be created (05-09-17), TAB has been used to indent things so take care (yes, i can't code properly)
#

##########################
###   Universal Functions   ###
########################## 
# Show variables function (searches for icp.nam and if present shows a selection of variables, also shows top 10 lines of .dat data and all .exe files in the directory)
# Replacement process  function (performs the replacement process of a variable in the icp.nam care to be taken in ensuring the variable is correctly defined)
##########################

##### Generic Search of directory for icp.nam 
##### Provides icp.nam search in directory as well. Start all Functions with this option

function SHOWVARIABLES(){



	if [ -f "icp.nam" ];
	then
		echo "icp.nam present"
		echo
		echo "Current variables function"
		echo
		grep -rnw icp.nam -e ITERATIONS
		grep -rnw icp.nam -e 'IBOLTZ'
		grep -rnw icp.nam -e CMETAL
		grep -rnw icp.nam -e IETRODEM
		grep -rnw icp.nam -e IBIAS
		grep -rnw icp.nam -e FREQM
		grep -rnw icp.nam -e VRFM
		grep -rnw icp.nam -e ICUSTOM
		grep -rnw icp.nam -e PRES
		grep -rnw icp.nam -e PWRNORM  	# Show current settings includeing line number (Check that the correct value is returned here as only the first instance will be replaced by the variable changer
		############################
		# Additional searches can be added here
		      		               	
		echo "Current Chemistry"

		head -10 icp.dat     #shows top of dat file

		echo "Current *.exe file"    #shows all .exe files

		find  *.exe 
		
	else # Error else to show no files found
		echo "no icp.nam file found"    
		Question="Do you wish to return to the welcome screen?"
		while true; do
    		read -p "Do you wish to return to the welcome screen?" yn
   			case $yn in
        			[Yy]* ) WELCOMESCREEN
					break;;
			
        			[Nn]* ) exit
					break;;
				 
		
       				* ) echo "Please answer yes or no.";;
    		esac
	done 
	fi	
}
##########################
##### Basic replacement function #####
####### Requires current_variable, Variable, Replacement, returns a replaced_variable in situ current variable is search of icp.nam, Variable is user defined search, 
####### replacment is user defined replacement 

function REPLACEMENTPROCESS(){


	echo "replacement function"
	sed -i "s/$current_icp_input/ \t $changing_icp_input = $replacement_icp_input/g" icp.nam
	replaced_icp_input=$(grep -rw icp.nam -e $changing_icp_input)
	echo "Replaced value is $replaced_icp_input"
		
}


##########################
###   Run Code Function   ### 
# User defines 3 variables, wih one being the choice of hpem.exe to use. (which is listed)
# Creates a command document into which all the code required to run a hpem simulation is copied
# alters the permission and runs the newly created command with outputs in the form of a progress file in running directory are provided.
# Returns user to welcome screen
##########################

function RUNCODE(){
	echo "run code"
	echo "running HPEM, Please enter a filename (file will also be progress file name):"   # Running code here
	read file_name

	echo "Please enter a mesh name? (will replace the hpem.exe with mesh name does not require .exe)"  # Maybe disable this as mesh names will be non intuitive
	read mesh_name

	echo "Which HPEM.exe file to use?" # Shows the current hpem and initmesh.exe files
	echo find *.exe
	read HPEM_File
	
	while true; do  
    		read -p "Do you wish to run this simulation? y/n" yn

		# yes/no option to check user actually wants to simulate

   		case $yn in
        	[Yy]* )	echo "
			mkdir $file_name
			cd $file_name
					#
			cp ../icp.nam          	icp.nam    
			cp ../icp.dat           icp.dat
			cp ../initmesh.dat      initmesh.dat
			cp ../initmesh.out	initmesh.out
			cp ../$HPEM_File.exe		$mesh_name.exe
			./$mesh_name.exe
			#
			cd ..
			#
			exit./" > ./icpH.com 
	
			chmod 777 icpH.com
	
			nohup ./icpH.com >./Progress_$file_name &
			# 
			# ask to auto create file names
			# Needs to make a directory of the changed variables
			# cp the files into the directory
			# make file icpH.com inside the directory
			# nohup the icpH.com
			#

			WELCOMESCREEN 
			break;;
		

		# yes option This creates the icpH.com file which actually runs the simulation 
			
        	[Nn]* ) WELCOMESCREEN; break;; 
		
       		* ) echo "Please answer yes or no.";;
    		esac
	done 

} 




##########################
###   Change Variable Function  ###
##########################
# Show Variables (called the show variables function)
# Replacement Function ( Defines variables and sets the process of replacing them up)
# Change Variables process (is where the process occurs calling all the aforementioned functions as required, also takes the user to run code section if desired)
##########################

function REPLACEVARIABLES_Singular(){
	echo "Replace variables function"

	echo "Which icp.nam variable do you wish to change?"
	read changing_icp_input


	current_icp_input=$(grep -rw icp.nam -e $changing_icp_input)

	echo "Current icp.nam value for this variable is $current_icp_input"
	echo "What is the replacement value for this variable (without the variable name and equals (include commas))"	
	read replacement_icp_input



	while true; do
    		read -p "Change this value from $current_icp_input to $replacement_icp_input ? y/n" yn
   			case $yn in
        		[Yy]* ) REPLACEMENTPROCESS; 
				ANOTHER;
					break;;
			
        		[Nn]* ) ANOTHER;
					break;;
		
       			* ) echo "Please answer yes or no.";;
    		esac
	done 
}
# Simply checks to see whether user wants to repeat the process
function ANOTHER(){
	while true; do
    		read -p "Do you wish to change another Variable? y/n" yn
   		case $yn in
        	[Yy]* ) REPLACEVARIABLES_Singular; break;;
		
			
        	[Nn]* )  break;; 
		
       		* ) echo "Please answer yes or no.";;
    		esac
	done 
}

# This function controls the order of this welcome screen option
function CHANGEVARIABLE(){
	SHOWVARIABLES
	REPLACEVARIABLES_Singular

	while true; do
    		read -p "Do you wish to run the simulation with these settings? y/n" yn
   		case $yn in
        	[Yy]* ) RUNCODE; break;;
		
			
        	[Nn]* ) WELCOMESCREEN; break;; 
		
       		* ) echo "Please answer yes or no.";;
    		esac
	done 
	
}



##########################
# Parameter Scan Function
##########################
# Generic yes no function to simplify coding (not sure if this could cause issues with shared variables if used extensively)
function YNQUESTION(){
	echo "question function running"
	while true; do
    		read -p "$Question y/n" yn
   			case $yn in
        			[Yy]* ) #echo "$yes_option"; 
					eval $yes_option
					break;;
			
        			[Nn]* ) #echo "$no_option"
					eval $no_option
					break;;
				 
		
       				* ) echo "Please answer yes or no.";;
    		esac
	done 
}



function DEFINEPARAMETERSCAN(){

	echo "Parameter Scan function called"
	echo "Which Variable is to be scanned over?"
	read changing_icp_input_scan


	current_icp_input_scan=$(grep -rw icp.nam -e $changing_icp_input_scan)
	echo "Current value is $current_icp_input_scan"
	numbers=$(echo $current_icp_input_scan | sed 's/.*=//')
	echo $numbers

	commas="${numbers//[^,]}"
	#echo "$commas"
	echo "${#commas}"
}




function SINGORMULTI(){

	num_of_comma="${#commas}"
	echo "num_of_comma =" $num_of_comma
	if [ "$num_of_comma" -eq 1 ];then
		SINGLEPARAMETER;
	else
		SELECTPARAMETER;

	fi
}



function SELECTPARAMETER(){

	echo "choose which number (BUT NOT YET)"
	echo $current_icp_input_scan
	icp_variable_name=$(echo $current_icp_input_scan | sed 's/=.*//')
	
	echo "write out variable up to variable to be changed including comma eg if current value is 0, 200, 0, 0, 1 and want to change 3rd number type 0, 200,"
	read start_of_current_variable


	echo "write out variable after variable to be changedeg eg if current value is 0, 200, 0, 0, 1 and want to change 3rd number type 0, 1, (if last just put comma)"
	read end_of_current_variable
	
	echo "Parameterscan Function"
	echo "What is the start value of the scan?"
	read start_value_of_scan


	echo "What is the end value of the scan?"
	read end_value_of_scan


	echo "What increments do you wish to go through? (uses seq function "seq [options] [start] [increment] [end]")"
	read increment
	
	Parameter_scan=$(seq $start_value_of_scan $increment $end_value_of_scan)  

	echo "For this $current_icp_input_scan run a parameter scan at these values : $Parameter_scan?" 
	echo "name files for saving (will give file name_(each value of scan) as folder name"
	read file_name


	echo "name directory to save all simulations into (will move completed simulations here)"
	read directory_name


	echo "all present *.exe file"    #shows all .exe files
	find  *.exe 
	echo "use which hpem file?"
	read HPEM_File

	yes_option=break;
	no_option=WELCOMESCREEN
	Question="For this $current_icp_input_scan run a parameter scan at these values : $Parameter_scan?"
	YNQUESTION
	mkdir $directory_name


	mkdir $directory_name

	for m in $Parameter_scan
	do	
		#echo $numbers
		#echo "$Variable_name = $initial_variable" "$m""," "$final_variable"
		icp_input_replacement ="$icp_variable_name = $start_of_current_variable $m , $end_of_current_variable"
		CHECKFORREPLACEMENT_SELECTPARAMETER
		
		echo "
		mkdir "$file_name"_"$m"
		cd "$file_name"_"$m"
				#
		cp ../icp.nam          	icp.nam    
		cp ../icp.dat           icp.dat
		cp ../initmesh.dat      initmesh.dat
		cp ../initmesh.out	initmesh.out
		cp ../$HPEM_File.exe		$HPEM_File.exe    #COMMENTED OUT FOR NOW
		./$HPEM_File.exe
		#
		cd ..
		#
		mv "$file_name"_"$m" $directory_name
		

		exit" > ./icpH.com 


		chmod 777 icpH.com
		
		nohup ./icpH.com >./Progress_"$file_name"_"$m" &
	done
	


	
	
	

	






	WELCOMESCREEN
}

function CHECKFORREPLACEMENT_SELECTPARAMETER(){
		
	icp_variable_name_scan=$(echo $current_icp_input_scan | sed 's/=.*//')

	current_icp_input_scan=$(grep -rw icp.nam -e $changing_icp_input_scan)

	echo $icp_input_replacement  

	new_value_for_scan="$icp_variable_name_scan = $start_of_current_variable $m , $end_of_current_variable"


	if [ "$icp_input_replacement" = "$current_icp_input_scan" ];
	then
		echo "1stoption"
		sed -i "s/$icp_input_replacement/ \t $new_value_for_scan /g" icp.nam
		icp_input_replacement=$(grep -rw icp.nam -e $icp_variable_name_scan)
		echo "Replaced value is $icp_input_replacement"
	else
		echo "2ndoption"
		sed -i "s/$current_icp_input_scan/ \t $new_value_for_scan /g" icp.nam
		icp_input_replacement=$(grep -rw icp.nam -e $icp_variable_name_scan)
		echo "Replaced value is $icp_input_replacement"
	
	fi
}

function CHECKFORREPLACEMENT(){
	
	        
	numbers=$(echo $current_icp_input_scan  | sed 's/.*=//')
	
	icp_variable_name_scan=$(echo $current_icp_input_scan  | sed 's/=.*//')
	
	new_value_for_scan="$icp_variable_name_scan = $m ,"
	

	if [ "$icp_input_replacement" = "$current_icp_input_scan" ];
	then
		echo "1stoption"
		sed -i "s/$icp_input_replacement/ \t $new_value_for_scan /g" icp.nam
		icp_input_replacement=$(grep -rw icp.nam -e $icp_variable_name_scan)
		echo "Replaced value is $icp_input_replacement"
	else
		echo "2ndoption"
		sed -i "s/$current_icp_input_scan/ \t $new_value_for_scan /g" icp.nam
		icp_input_replacement=$(grep -rw icp.nam -e $icp_variable_name_scan)
		echo "Replaced value is $icp_input_replacement"
	
	fi
}


function SINGLEPARAMETER(){
	SHOWVARIABLES
	echo "THIS CAN BE GLITCHY, Check outputs carefully!!!!"
	
	echo "Parameterscan Function"
	echo "What is the start value of the scan?"
	read start_value_of_scan


	echo "What is the end value of the scan?"
	read end_value_of_scan


	echo "What increments do you wish to go through?"
	read increment
	
	Parameter_scan=$(seq $start_value_of_scan $increment $end_value_of_scan)  
	#echo $Parameter_scan
	
	
 	current_icp_input_scan=$(grep -rw icp.nam -e $changing_icp_input_scan)
	echo "For this $current_icp_input_scan run a parameter scan at these values : $Parameter_scan?" 
	echo "name files for saving"
	read file_name


	echo "name directory to save all simulations into"
	read directory_name


	echo "use which hpem file?"
	read HPEM_File
	
	yes_option=break;
	no_option=WELCOMESCREEN
	Question="For this $current_icp_input_scan run a parameter scan at these values : $Parameter_scan?"
	YNQUESTION
	mkdir $directory_name
	
	for m in $Parameter_scan
	do
		#echo "$m""," 
		CHECKFORREPLACEMENT
		echo "
		mkdir "$file_name"_"$m"
		cd "$file_name"_"$m"
				#
		cp ../icp.nam          	icp.nam    
		cp ../icp.dat           icp.dat
		cp ../initmesh.dat      initmesh.dat
		cp ../initmesh.out	initmesh.out
		cp ../$HPEM_File.exe		$HPEM_File.exe    #COMMENTED OUT FOR NOW
		./$HPEM_File.exe
		#
		cd ..
		#
		mv "$file_name"_"$m" $directory_name
		

		exit" > ./icpH.com 


		chmod 777 icpH.com
		
		nohup ./icpH.com >./Progress_"$file_name"_"$m" &

		
		# 
		# ask to auto create file names
		# make file icpH.com inside the directory
		# nohup the icpH.com
		# moves completed files to a new directory

		
done
	 

	
} 






function PARAMETERSCAN(){
	SHOWVARIABLES
	DEFINEPARAMETERSCAN
	SINGORMULTI
	
	
	WELCOMESCREEN

}



##########################
# Quick Setup Function
##########################
# Combination of previous setups with fewer options and a streamlined progression for quick simulations
# Care to be taken as fewer chances to check for mistakes or errors
##########################
function QUICKSETUP(){
	
	
	SHOWVARIABLES
	echo "input variable to change (will create a folder labelled quickie_(variable)_(value)"
	read changing_icp_input_quick


	current_icp_input_quick=$(grep -rw icp.nam -e $changing_icp_input_quick)


	echo "What is the replacement value for this variable"
	read replacement_icp_input_quick
	
	
	yes_option=break;
	no_option=WELCOMESCREEN
	Question="For this $current_icp_input_quick run a simulation with this value : $replacement_icp_input_quick ?"
	YNQUESTION
	
	find *.exe
	echo "what is the .exe to use?"
	read HPEM_File

##########################################


	echo "replacement function"
	sed -i "s/$current_icp_input_quick/ \t $changing_icp_input_quick = $replacement_icp_input_quick/g" icp.nam
	replaced_icp_input_quick=$(grep -rw icp.nam -e $changing_icp_input_quick)
	echo "Replaced value is $replaced_icp_input_quick"


##########################################


	echo "
	mkdir quickie_"$changing_icp_input_quick"_"$replacement_icp_input_quick"
	cd quickie_"$changing_icp_input_quick"_"$replacement_icp_input_quick"
			#
	cp ../icp.nam          	icp.nam    
	cp ../icp.dat           icp.dat
	cp ../initmesh.dat      initmesh.dat
	cp ../initmesh.out	initmesh.out
	cp ../$HPEM_File.exe		$HPEM_File.exe
	./$HPEM_File.exe
	#
	cd ..
	#
	exit./" > ./icpH.com 

	chmod 777 icpH.com

	nohup ./icpH.com >./Progress_quickie_"$changing_icp_input_quick"_"$replacement_icp_input_quick" &
	# 
	# ask to auto create file names
	# Needs to make a directory of the changed variables
	# cp the files into the directory
	# make file icpH.com inside the directory
	# nohup the icpH.com
	#


	
##########################################	
	
	WELCOMESCREEN
}




##########################
# Settings (?)
##########################

# Is it possible to use this to create folders and move items around inside the code?
# Could create alternative folder paths

##########################
# Extraction code (?)
##########################

# Create a code to move the simulations from the servers to desktop/documents
# Possibly move it to a HELENA.py folder and automate the analysis as well ? (that would be cool)




##########################
# Choose Function
##########################
function WELCOMESCREEN(){
	echo 
	echo
	echo "Welcome to HERMES 0.3"
	echo
	echo "last update 26.09.17"
	echo
	echo "HPEM Easily Runs, Making Exciting Simulations"
	echo
	echo "Creator: Greg Smith, York Plasma Institute, gjs507"
	echo 
	echo "Feel free to alter things to suit your purposes or ask for things to be implemented"
	echo 	
	echo "Do you wish to: "
	echo
	
	options=("Change Variables" "Parameter Scan" "Run Simulation" "Quick Setup(not implemented)" "Quit")
	select opt in "${options[@]}"
	do
		case $opt in
			"Change Variables")   #Functions to change 1 variable at a time in the folder HERMES is put into USeful if using old icp.com
				echo "Take to Change Variable function";
				CHANGEVARIABLE;
				;;
			"Parameter Scan")
				echo "Take to Parameter Scan Function"
				PARAMETERSCAN
				;;
			"Run Simulation")
				echo "Take to Run Code section";
				RUNCODE;
				;;
			"Quick Setup(not implemented)") # Should be similar to change variables but makes files and runs in one
				echo "Take to Quick setup section"
				QUICKSETUP
				;;
			"Quit")
				exit
				;;
			*) echo invalid option;;
		esac	
	done

}
############################

WELCOMESCREEN


exit









##  junk code  ##

#numbers=$(echo $varying_variable | sed 's/.*=//')
	#echo $numbers
	#echo "position of commas in number"
	#echo $numbers | grep -aob ',' | grep -oE '[0-9]+'
	#echo "pattern attempt"	
	#echo
	#echo $numbers | grep  -aob  ',' 
	#echo
	#NUMBERS=${numbers:4:10}
	#echo $NUMBERS
	
	#echo
	#echo position
	#echo
	
		
	#echo $numbers | grep -aob ',' | grep -oE '[0-9]+'  
	#echo ${numbers:$User_Position_start:$User_Position_finish}
	#echo  
	#Something=${numbers:$User_Position_start:$User_Position_finish}
	#echo "finding the values in the original" $Something
	#Variable=$(echo $varying_variable | sed 's/=.*//')
	#new_replacement_value="$Variable = $m ,"
	#echo "replacement" $new_replacement_value
	
	#numbers=$(echo $varying_variable | sed 's/.*=//')
	#echo $numbers
	#echo "position of commas in number"
	#echo $numbers | grep -aob ',' | grep -oE '[0-9]+'
	#Variable_name=$(echo $varying_variable | sed 's/=.*//')
	#echo $Variable_name
	newvalue="$Variable_name = $m ,"

	#test1=${numbers:0:selected}
	#echo "test1" $test1
	
	#commas="${numbers//[^,]}"
	#echo "$commas"
	#echo "${#commas}"

	#replacement="TREE,"
	#echo $replacement

	#echo "define which variable to alter (numbering from left to right 1 to x separated by commas)"
	#read selected
	#echo "define which variable comma separated (numbering from left to right)"
	#altered=$(echo $numbers | sed -e "s/*[0-9]*,/$replacement/$selected")
	#altered1=$(echo $numbers | sed -e s/,.*, /$replacement/$selected")
	#echo $numbers
	#echo $altered
