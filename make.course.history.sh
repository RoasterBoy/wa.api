#!/bin/bash
# 
# This script uses the Wild Apricot API to fetch information about events (courses).
# 
# Uses jq
# See https://stedolan.github.io/jq/
# 
# WA_key is our API key 
# WA_account is our Wild Apricot account number
# Both are set in .bashrc
# 
# API key must be encoded to base64 with the prefix APIKEY:
# For example, APIKEY:WFVHjqxMsz9k637XCI64bEahTmO7gjv
#
tmp=/tmp/wa
getReg=false
init=false
thisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
setup ()
{
#
#--------------------------------------------------------- 
# Set up working directory
#

    if [ ! -d "$tmp" ]; then
	mkdir -v $tmp
#    else
#	rm $tmp/*
    fi 
#
} # end setup
# 
getAuth()
{
thisKey=`echo -ne "APIKEY:$WA_key"|base64`
curl -s  --header "Content-Type:application/x-www-form-urlencoded" \
     --header "Authorization: Basic $thisKey" -d "grant_type=client_credentials&scope=auto"\
     https://oauth.wildapricot.org/auth/token  -o $tmp/token.json
# 
thisAuth=$(jq -r '.access_token' $tmp/token.json)
#
}

#--------------------------------------------------------- 
# Loop through the events and get the details and registrations
#
getFiles ()
{
curl -s --header "Authorization: Bearer $thisAuth"\
     'https://api.wildapricot.org/v2.1/accounts/'"$WA_account"'/Events'$filter -o $tmp/events.json
jq '.[] | sort_by(.Name) | .[].Id | rtrimstr(",")' $tmp/events.json > $tmp/events.list
#
while IFS='' read -r thisEvent || [[ -n "$thisEvent" ]]; do
#    echo "Got this event $thisEvent"
    if [ ! -f $tmp/$thisEvent-details.json ]; then
	curl -s --header "Authorization: Bearer $thisAuth"  \
	     "https://api.wildapricot.org/v2.1/accounts/$WA_account/events/$thisEvent"\
	     -o $tmp/$thisEvent-details.json
	fi
done  < $tmp/events.list
}
mungFiles ()
{
    # TODO
    # This sed section needs some serious cleanup.
    # 
    echo "" > $tmp/allFiles.tsv
    echo "" > $tmp/regcount.txt
    FILES=$tmp/*details.json
    for f in $FILES
    do
	#	echo "Working on $f"
	jq  --raw-output -f $thisDir/makeHistory.jq $f >> $tmp/allFiles.tsv
	jq '.Details.RegistrationTypes[].CurrentRegistrantsCount' $f >> $tmp/regcount.txt
	
    done
	cat allFiles.tsv | ftfy -g >  textfile.txt
	# Cleanup tags as best we can
#
	sed -i'.bak' "/cancelled/d" textfile.txt
	sed -i'.bak' "/Membership/d" textfile.txt
	sed -i'.special' "/special/d" textfile.txt
	sed -i'.annual' "/annual meeting/d" textfile.txt
#
	sed -i'.bak' -e "$(sed 's:.*:s/\\t&\\b//g:' $thisDir/Island.of.Unwanted.Tags.txt)" textfile.txt
	echo "" > mumble.txt
	#	awk -F "\t"  '{for(i=2; i<=NF; i++) printf "%s \t", $i}{printf "%s\n", $1}' textfile.txt >> mumble.txt
	awk -F "\t"  '{for(i=2; i<=NF; i++) printf "%s\t%s\n", $i,$1}' textfile.txt >> mumble.txt
	sed -i'.bak' '/^$/d' mumble.txt
	cat mumble.txt  | sort | sed 's/^\(.\)/\U\1/' > course.tags.txt
	# Fix case for selected tags
	sed -i'.bak' 's/Cwi/CWI/gi' course.tags.txt
	#	datamash -s -g 1  collapse 2 < course.tags.txt | sed -e  's/\t\|,\([A-D,S]\)/<li>\1/g'| sed G | perl -pe 's|^(.*?)<li>|<h1>$1</h1><li>|g' | perl -pe 's|\(.*?\)||g' > past.wise.courses.html
	cp $thisDir/course.header.html past.wise.courses.html
	
	datamash -s -g 1  collapse 2 < course.tags.txt |
	    sed -e  's/\t\|,\([A-D,S]\)/<li>\1/g'|\
	    sed G |\
	    perl -pe 's|^(.*?)<li>|</p></div><div class="column" onclick="openTabOPEN$1CLOSE\;" style="background:white;">$1</div><div class="containerTab" style="display:none;background:white;"id="$1"><p>|g' |\
	    perl -pe 's|\(.*?\)||g' >> past.wise.courses.html
	sed -i'.bak' "s/OPEN\(.*\)CLOSE/\(\'\1\'\)/g" past.wise.courses.html
#	echo "Is this trouble?"
	sed -i'.bak2' 's/<\/i>,/<\/i> /g' past.wise.courses.html
	sed -i'.burp' 's/\<li>/<\/p><p>/g' past.wise.courses.html
	sed -i'.bak' 's/[A-D,S][[:digit:]]\+[[:space:]]\?[-,.][[:space:]]\?//g' past.wise.courses.html
	thisDate=$(date  +"%B %d, %Y %-I:%m %p")
	echo "<p>Updated: $thisDate" >> past.wise.courses.html
	cat $thisDir/course.footer.html >> past.wise.courses.html
}

msg()
{
    if [  "$verbose" = true ];
    then
#       echo "Verbose is $verbose"
        thisString=$@
        echo "%% $thisString"
    fi
}

getHelp() {
    printf "%s\n" "Usage:"
    printf "%s\n" "-u Get upcoming events"
    printf "%s\n" "-i Get events. Otherwise, use what we have in $tmp"
    printf "%s\n" "-t Use these tags. Tags must be comma-separated in a quoted string: \"fall,spring\""
    printf "%s\n" "-s Start date for course filtering yyyy-mm-dd"
    printf "%s\n" "-r Get registration: y/n. Default is y if init is yes."
    printf "%s\n" "-h Prints this message"
    exit
    }
while getopts "uit:hrs:" opt; do
    case ${opt} in
	u ) # Get Upcoming Events
	    echo "Getting upcoming events"
	    filter="?$filter=IsUpcoming%20eq%20true"
	    ;;
	r ) # Do we need registrations
	    getReg=true
	    ;;
	i )
	    init=true
	    ;;
	t ) # Tags
	    tags=$OPTARG
	    filter="?\$filter=Tags%20in%20%5B$tags%5D"
	    ;;
	s ) #StartDate
	    startDate=$OPTARG
	    filter="?\$filter=StartDate%20ge%20$startDate"
	    ;;
	h) # Print help and exit
	    getHelp
	    ;;
	?)
	    getHelp
	    ;;
	
    esac
done
# 
# 
#
set -eE -o functrace
failure() {
    local lineno=$1
    local msg=$2
    echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR
start_time="$(date -u +%s)"
if [ $init = true ]; then
   setup
   getAuth
   echo "Getting events, putting details in $tmp"
   getFiles
fi
mungFiles 
end_time=$(date -u +%s)
elapsed=$((end_time-start_time))
msg "Elapsed time: $elapsed seconds"
