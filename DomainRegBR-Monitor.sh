#!/bin/bash
# Igor Andrade on 15/06/2022 
# Debian-PB.org
#
# Revamped on 01/12/2022
# Script to monitor domains avaibility to purchase on registro.br
#
# This script should send everyday data about the status of the domain, when they enter on the lists of registro.br you will see the status as available to
# enter in a dispute to register it.



#constant Vars

#@ webhooks @#

# Choice webhook to use
# Only Telegram = 1
# Only Teams = 2 
# Use Both Telegram and Teams set = 3
ChoiceWebHook="0"

#teams
URL_TEAMS1="https://yourteamsURL.com/webhookb2/IncomingWebhook/....."

#telegram
chat_id="-1000000000"
token="1000000000:AAAAA5AlaaAS8q19HGFJjiAAAAAzzzTwOyxc"
URLTelegram="https://api.telegram.org/bot$token/sendMessage"


# Do a list about the domains that you want monitor 
domainz="
DomainToMonitor.com.br
Domain2ToMonitor.com.br
Domain3ToMonitor.com.br
"


# DO NOT CHANGE ANYTHING BELOW THIS LINE
###################################################################

# Check domain on lists if released for registration on Registro-BR:
lista1="https://registro.br/dominio/processo-de-liberacao/"
lista2="https://registro.br/dominio/lista-processo-competitivo.txt"
lista3="https://registro.br/dominio/lista-competicao.txt"
testOnly="registro.br"

send_alarm()
{

    telegram(){
        #Telegram
        caption=$(echo -e "Domain Monitor Details: $Dominios \n ListaLiberação: $liberacao \n ListaCompetitividade: $competitividade \n ListaCompeticao: $competicao \n Status on whois now: $status \n LastChangeOnRegistrar is $lastchange \n Date today: `date '+%d-%m-%Y %H:%M:%S'` \n Listas: \n ListaLiberacao: $lista1 \n ListaCompetitividade: $lista2 \n ListaCompeticao: $lista3 \n Look Documentation on RegBR: $URLregistrobr")
        curl -s -X POST -d chat_id=$chat_id -d text="$caption" $URLTelegram > /dev/null 2>&1
    }
    teams(){
        #Teams
        curl -d '{"@type": "MessageCard","@context": "http://schema.org/extensions","themeColor": "0076D7","summary": "DomainRegBRAlerts :: Domain monitor","sections": [{"activityTitle": "DomainRegBRAlerts :: Domain '"$Dominios"' monitor","activitySubtitle": "","activityImage": "https://mir-s3-cdn-cf.behance.net/projects/404/62c830116280499.Y3JvcCwxNjcyLDEzMDcsNDE4LDMyMg.png","facts": [{"name": "List Liberaçao:","value": "'"$liberacao"'"}, {"name": "List Competitividade:","value": "'"$competitividade"'"}, {"name": "List Competicao:","value": "'"$competicao"'"}, {"name": "Status on whois is now:","value": "'"$status"'"}, {"name": "Last change on registrar is:","value": "'"$lastchange"'"}, {"name": "Date today:","value": "'"$(date "+%d-%m-%Y %H:%M:%S")"'"}, {"name": "Lists to Check:","value": "ListaLiberacao: '"$lista1"' ListaCompetitividade: '"$lista2"' ListaCompeticao: '"$lista3"'"}],"markdown": true}], "potentialAction": [{"@type": "OpenUri","name": "Open Documentations and List","targets": [{"os": "default","uri": "'"$URLregistrobr"'"}]}]}' -H 'Content-Type: application/json; charset=UTF-8' "$URL_TEAMS1"
    }

    if [ $ChoiceWebHook -eq "1" ]
        then
        telegram
    elif [ $ChoiceWebHook -eq "2" ] 
        then
        teams
    elif [ $ChoiceWebHook -eq "3" ]
        then 
        teams
        telegram
    else
        echo -e "Wrong Option choiced on variable ChoiceWebHook, Please set 1,2 or 3 for this variable"
    fi
}

processoLiberacao(){
curl -ks https://registro.br/dominio/lista-processo-liberacao.txt | egrep "^$Dominios$"

	if [ $? -eq 0 ] ; then
		liberacao=$(echo -e "Domain $Dominios is on list Liberacao, CHECK IT NOW on Open Documentations List")
	else 
		liberacao=$(echo -e "Not yet on list Liberacao... Monitoring")
	fi
}

processoCompetitivo(){
curl -ks https://registro.br/dominio/lista-processo-competitivo.txt | egrep "^$Dominios$"

	if [ $? -eq 0 ] ; then
		competitividade=$(echo -e "Domain $Dominios is on list Competitivo, CHECK IT NOW on Open Documentations List")
	else 
		competitividade=$(echo -e "Not yet on list Competitividade... Monitoring")
	fi
}

processoCompeticao(){
curl -ks https://registro.br/dominio/lista-competicao.txt | egrep "^$Dominios$"

	if [ $? -eq 0 ] ; then
		competicao=$(echo -e "Domain $Dominios is on list Competicao, CHECK IT NOW on Open Documentations List")
	else 
		competicao=$(echo -e "Not yet on list Competicao... Monitoring")
	fi
}



main(){
for Dominios in $domainz 
    do

    status=$(/usr/bin/whois $Dominios | egrep status | awk {'print $2'})
    lastchange=$(/usr/bin/whois $Dominios | egrep changed | head -1 | awk {'print $2'})

    if [[ $status == "" ]] && [[ $lastchange == "" ]] 
    then
        status="This domain should be available or very close"
        lastchange="This domain should be available or very close"
    fi

    #Load other functions
    processoLiberacao
    processoCompetitivo
    processoCompeticao
    send_alarm
done
}

if [ -f /usr/bin/whois ] && [ -f /usr/bin/curl ]
    then
            if /usr/bin/whois $testOnly >/dev/null 2>&1
                then
                    main
            else
                    echo -e "Please check if your firewall have the port 43 opened on iptables/fw"
            fi
else
    echo -e "Check if Whois and Curl package is installed on this server, at least one of them are not present on the server"
    exit 0
fi
