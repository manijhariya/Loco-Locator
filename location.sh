#!/bin/bash
#Author: Manish
#Filename: location.sh
#Required-file: ca-certificates.crt,settings.txt
#Loco-Locator source file it has different functions for particular operation. If conguration doesn't work from
#here for msmtp. Please try it by yourself. settings.txt file should not edited if you want to use previous setup
#you can use help command for more.. -- Author


dependencies() {
required=()
command -v jq > /dev/null 2>&1 || { echo >&2 "I require jq for json parsing but it's not installed.."; required+=( "jq" ); }
command -v curl > /dev/null 2>&1 || { echo >&2 "I require curl for sending request to server for location but it's not installed..";required+=( "curl" );}
command -v msmtp > /dev/null 2>&1 || { echo >&2 "I require msmtp for sending email to but it's not installed..";required+=( "msmtp" ); }
return 0
}

configuremsmtp() {
echo "Enter a valid email-id(Gmail)"
read email
echo "Enter password this will require for auth0"
read password
echo "# Set default values for all following accounts.
defaults
auth           on
tls            on
tls_trust_file $(pwd)/ca-certificates.crt
logfile        ~/.msmtp.log

# Gmail
account        gmail
host           smtp.gmail.com
port           587
from           $email
user           $email
password       $password

# Set a default account
account default : gmail" > /root/.msmtprc

chmod 600 /root/.msmtprc
}

installation() {
echo >&2 "Do you want to install required elements!!(Y/N)";
read x
if [ $x == "y" ] || [ $x == "Y" ]; then
	for i in ${required[@]};do
		apt install $i
		if [ $i == "msmtp" ]; then
			echo >&2 "Do you want to configure /root/.msmtp.conf file(before configuration it will not work)";
			read y
			if [ $y == "y" ] || [ $y == "Y" ]; then
				configuremsmtp
				echo >&2 "If configuration doesn't work from here try to configure it by yourself"

			else
				continue;
			fi
		else
			continue;
		fi
	done
else
	exit 1;

fi
}

testmessage() {
	echo "Test Message" | msmtp -a default ${receiver}
}

LocSender(){
# there is 10,000 request limit to this site per month so use wisely
while true;do								#in echo the message is there to send to the mail..
	var=$(curl -s "http://ipwhois.app/json/")
	lag=$(echo $var | jq '.latitude')
	log=$(echo $var | jq '.longitude')
	echo "Text Message from msmtp $lag $log" | msmtp -a gmail $receiver
	sleep $delay
done
}

usage(){
printf "\rLocoLocator commandline Location Sender [version 0.0.1]\n\n"
printf "\rUsage: bash locator.sh [options]\n"
printf "\rOptions: -p --previous Only flag to run in previous settings\n"
printf "\r	 -r --recevier <username@mail.com> e-mail address of mail receiver\n"
printf "\r	 -d --delay <30000>delay between two emails(in seconds)\n"
printf "\r         -t --test Only flag to send a test email\n"
printf "\r 	   -s --save Only flag to save settings for next time"
printf "\r         -h --help this page only\n"
printf "\rExample:\r\n"
printf "\r	    bash locator.sh -r someone@something.com -s 3000 -t\r\n"
printf "\r\n\nSee the Documntation Page for more\n"
printf "\rReport bugs to <manijhariya@github>\n"
exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--recevier) receiver="$2"; shift ;;
	-d|--delay) delay="$2"; shift ;;
	-p|--previous) previous=1; ;;
 	-s|--save) save=1; ;;
        -t|--test) testmsg=1; ;;
	-h|--help) usage ;;
        *) echo "Try --help|-h "; exit 1 ;;
    esac
    shift
done

if [[ ${previous} -eq "1" ]]; then
	receiver=$(sed '1q;d' settings.txt)
	delay=$(sed '2q;d' settings.txt)
fi

if [[ ${save} -eq "1" ]]; then
echo "${receiver}
${delay}"> settings.txt
fi

dependencies

if [[ ${#required} -eq 0 ]]; then
	echo
else
	installation $?
	exit 1
fi

if [[ ${testmsg} -eq "1" ]]; then
	testmessage ${receiver}
fi

LocSender ${receiver},${delay}          #finally calling to sender current location

