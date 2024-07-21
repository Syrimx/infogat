#!/bin/bash

# maybe implement caching features
# maybe implement report export functionality

# {Eye Candy}
echo "
   _      ___               __ 
  (_)__  / _/__  ___ ____ _/ /_
 / / _ \/ _/ _ \/ _ `/ _ `/ __/
/_/_//_/_/ \___/\_, /\_,_/\__/ 
               /___/           

"
echo "[*] build by ely sylvain schybol"
echo "

                                            .........                                          
                                           ...%...%...                                         
                               .....       ..%.. ..%..      ......                             
                             ...%%=...     .%-:..:-=-..   ....#%%...                           
                             ..%...%:.....:+%%%%%%%%%=......#=...#..                           
                     .....   ..%....#%#==-================%%*....%..    ...                    
                   ...+:.......%%*=============================#%%.......==..                  
                   .*....%..%%====================================-%+.+%...#.                  
                   .*:...*%============%=================*============%-...+.                  
                   ..%-%===============*================#===============##-%.                  
                   ..%=================-%===============%=================*#... .....          
          .........**===================+==============%-===================%.........         
          .*#..:%%%======================%============*+======================%%....%..        
          .*.....%=====-*=================%-=========#==================#======%....%..        
         ..%----%========%=====##================================%====*#========%--#:..        
         ...%--%===========%%=%..%==========%%#==+%%%-=========#-..*%*==========-%%....        
          ....%==============#....#+=====#-============*======%....%=============+-..          
           ...*==============%......%+=====================++#.....-*=============%..          
          ...%==============-#..  ...#+====================%......::#=============+*...        
      .......*===============%-:..  ...%#================%:......---*=============+%.......    
    ...%+...%++==============#----......%================#.....----%==============+*:...%%...  
    ..%.....%++===============%-------+#==================%-------#==============+++#....:+..  
    ..:#----%+++==%%%%**=====+=%---+%*=====================-%#---%=+====+*#%%%#==+++%----%...  
      ..#%--%++++==========++======================================++==========+++++%--%:..    
      .....:%+++++++======+++======%..%==================*#.-%======+++======+++++++%......    
          ..%+++++++++++++++-=====%...%%-=====+#.%======#%%..:*=====-+++++++++++++++*..        
           .=++++++++++++%========%..%=%%====*=...%=====%%:%..%=======+%+++++++++++#..         
          ...%+++++++++++*+==%-===%..*.%%===-*.. ..%====%%.%..%===-*==+%+++++++++++%..         
          ..%.%++++++++++%+++#+-==*:.%%%%===%..  ...%==-%%%%.#-===*++++%++++++++++%.%..        
         ..%..-%++++++++++%++%++===%:#%%-==%..     .====*%%.#+===++*+*#++++++++++%-..%..       
         ..%.----%++++++++++%%++======-====*..     ..%=====-=====++%#+++++++++#%----.%..       
          ..........-%%%%%%%%*++==========%-.... ...::#==========++%%%%%%%%%:..........        
            .............%=++#++==========%----..:----*==========++%++==... .   .....          
                       ..#==+*#+++=====%#=+%---------%+=%%=====+++%++=*..                      
                       ...*=+++%++++++===-=+%=-----*#+====++++++*%+++=%...                     
                       ...%==++++*%#*+++++==+++##*+++==+++++*%%+++++=-#...                     
                       ...=+=++++++%+++%#+++++++++++++++%%++%++++++==%...                      
                   .....-%+%==++++++#*++++*%#+++++++%%+++++%+++++++==%*%.....                  
            .... .....%+==++*==+++++++#%++++++++++++++++*%++++++++==%++==#%....  ...           
           ..++....=%=====++%===+++++++++*%%#++++++*%%#++++++++++===*++=====%.....*..          
           ..:*=+%%======++++%===+++++++++++++++%+++++++++++++++===%++++======%%==%..          
           ...%=======-++++++*+===++++++++++++++%++++++++++++++===%+++++++========#..          
           ...:*====++++++++++%-===+++++++++++++%+++++++++++++===+++++++++++=====%..           
             ..%+++++++++++++++%====++++++++++++%++++++++++++===-%++++++++++++++++.            
             ...%+++++++++++++++%===++++++++++++%+++++++++++====%+++++++++++++++%..            
              ...#+++++++++++++++%===+++++++++++%+++++++++++===%+++++++++++++++%...            
               ...%++*%%%%#=.....%===+++++++++++%+++++++++++===%.....+%%%%#*++%..              
                 .......       .#####%%%%%%#+:.....:*%%%%%%%###%:.      .........              
                               ...........             ...........                             



"

# {Error Handling}
if [[ $# < 2 || "$1" =~ "--" ]];then
	echo $'[*] Please provide a flag and an IP adresse/domain to enjoy the features...\n[*] ./infogat.sh 10.11.12.13 --<flag1> --<flag2>\n[*] Flags: [--help, --basic, --smb, --ftp]'
	exit 1
fi

# {Preparation}
# check if a reporting folder exists and creating one if it doesn't
[[ ! -d ./reports ]] && mkdir ./reports || :


# main functionalities
if [[ "$*" == *"--basic"* ]];then
	echo "[*] starting port scanning..."
	sudo nmap $1 -p- -Pn -oN "./reports/$1_basicScan"  
	sudo nmap $1 -sC -sV -p- --min-rate 5000 -Pn -oN "./reports/$1_advancedScan" 

	if [[ $(curl -s $1) ]];then
		echo "[*] starting directory fuzzing..."
		gobuster dir -w /usr/share/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt -u $1 -o "./reports/$1_dirGoFuzz" -b 404,503,500  
		dirsearch -u $1 -o "./reports/$1_dirSearchFuzz" -x 500,503,404  

		echo "[*] starting subdomain enumeration..."
		gobuster dns -w /usr/share/wordlists/SecLists/DNS/subdomains-top1million-110000.txt -d $1 -o "./reports/$1_subList"  
	fi

	echo "[*] starting vulnerability scanning..."
	[[ $(curl -s $1) ]] && : || nikto -h $1 > "./reports/$1_niktoVuln"  
	sudo nmap --script "vuln" $1 -Pn -oN "./reports/$1_nmapVuln"  
fi

if [[ "$*" == *"--ftp"* ]];then
  echo "[*] starting ftp enumeration..."
  sudo nmap --script "ftp" $1 -Pn --min-rate 5000 "./reports/$1_ftpScans"
fi

if [[ "$*" == *"--smb"* ]];then
  echo "[*] starting smb enumeration..."
  sudo nmap --script "smb-vuln*" $1 -Pn --min-rate 5000 -oN "./reports/$1_smbNmapScans"
  enum4linux -a $1 | tee "./reports/$1_smb4Linux"
  smbclient \\\\$1\\ -L | tee "./reports/$1_smbClientShares"
fi

#<tba> --install --help
if [[ "$*" == *"--install"* ]];then
  echo $'[*] The script does potentially make changes to your system by installing required software.\nDo you want to continue?y/n'
  read answer
  if [[ -z $answer || $answer == "y" ]];then
    echo "[*] starting software installation..."
    sudo apt install nmap gobuster dirsearch nikto smbclient wget -y
    sudo snap install enum4linux -y

    # installing SecList
    if [[ ! -d /usr/share/wordlists/SecList ]]
      [[ -d /usr/share/wordlists ]] && : || mkdir /usr/share/wordlists # check if wordlists is present and if not create it 
      sudo wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O /usr/share/wordlists/SecList.zip \
        && sudo unzip /usr/share/wordlists/SecList.zip \
        && sudo rm -f /usr/share/wordlists/SecList.zip
      echo "[*] required software was installed successfully"
      exit 0;
    fi
  fi
fi


exit 0;