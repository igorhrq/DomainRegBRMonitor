#!/bin/bash
# Author: Igor Andrade 
# First Release in 15/06/2022 
# Thanks to Debian-PB.org
#
# Rescrito em 01/12/2022
#  - Adicionado Telegram
#  - Adicionado Checks de validação binários
#  - Adicionado Validação de teste do whois em caso de timeout
#  - Melhoria de código
#  - Adicionado Comentários 
#
# Script para monitorar status de domínios do registro.br
# Script to monitor domains avaibility to purchase on registro.br
#
#
# Script para monitoramento de domínios do registro.br apenas, auxiliará durante o processo de disputa, e avisará quando o mesmo estiver disponível para submeter processo de disputa dele
# entrando nas listas de competitividade do registro.br



# Variáveis constantes

#@ webhooks @#

# Escolha uma opção para uso de webhooks
# Apenas Telegram = 1
# Apenas Teams = 2 
# Usar ambos Telegram e Teams ajuste = 3
ChoiceWebHook="0"

# Dados teams webhook (dados abaixo são inválidos, e precisam ser substituidos pelos seus)
URL_TEAMS1="https://suaURLdoteams.com/webhookb2/IncomingWebhook/....."

# Dados telegram webhook (dados abaixo são inválidos, e precisam ser substituidos pelos seus)
chat_id="-1000000000"
token="1000000000:AAAAA5AlaaAS8q19HGFJjiAAAAAzzzTwOyxc"
URLTelegram="https://api.telegram.org/bot$token/sendMessage"


# Escreva uma lista de domínios a serem monitorados
domainz="
DomainToMonitor.com.br
Domain2ToMonitor.com.br
Domain3ToMonitor.com.br
"


# NAO ALTERAR NADA NO CÓDIGO APOS ESSA LINHA
###################################################################

# Checa as listas do registro.br e verifica se os domínios escolhidos estão em alguma delas
lista1="https://registro.br/dominio/processo-de-liberacao/"
lista2="https://registro.br/dominio/lista-processo-competitivo.txt"
lista3="https://registro.br/dominio/lista-competicao.txt"
testOnly="registro.br"


# Função que dispara os webhooks
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

# Analisa váriavel de escolha de webhooks
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
        echo -e "Opção errada escolhida na váriavel ChoiceWebHook, Por favor escolha o número 1,2 or 3 para essa variável, detalhes nos comentários do código"
    fi
}

# Lista de liberação do registro.br
processoLiberacao(){
curl -ks https://registro.br/dominio/lista-processo-liberacao.txt | egrep "^$Dominios$"

	if [ $? -eq 0 ] ; then
		liberacao=$(echo -e "Domain $Dominios is on list Liberacao, CHECK IT NOW on Open Documentations List")
	else 
		liberacao=$(echo -e "Not yet on list Liberacao... Monitoring")
	fi
}

# Lista Competitivo do registro.br

processoCompetitivo(){
curl -ks https://registro.br/dominio/lista-processo-competitivo.txt | egrep "^$Dominios$"

	if [ $? -eq 0 ] ; then
		competitividade=$(echo -e "Domain $Dominios is on list Competitivo, CHECK IT NOW on Open Documentations List")
	else 
		competitividade=$(echo -e "Not yet on list Competitividade... Monitoring")
	fi
}

# Lista Competição do registro.br

processoCompeticao(){
curl -ks https://registro.br/dominio/lista-competicao.txt | egrep "^$Dominios$"

	if [ $? -eq 0 ] ; then
		competicao=$(echo -e "Domain $Dominios is on list Competicao, CHECK IT NOW on Open Documentations List")
	else 
		competicao=$(echo -e "Not yet on list Competicao... Monitoring")
	fi
}


# Função principal, verifica o domínio passado 1 por 1 dentro de um loop(for) através do whois, checa o status e checa a última alteração

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

    # Carrega funções complementares
    processoLiberacao
    processoCompetitivo
    processoCompeticao
    send_alarm
done
}

# Checks inicais antes do script rodar, analisa se os binários existem no servidor do whois e curl existem e checa se o whois dá timeout por algum motivo
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
