#!/bin/sh

# ESCAPED_PASSWORD=$(python -c "import urllib.parse; print(urllib.parse.quote('$SQLCMDPASSWORD'),end='')")

DBEXTRA="?trustServerCertificate&encrypt"
#DBURL="sqlserver://$SQLCMDUSER:$ESCAPED_PASSWORD@$SQLSERVER:$SQLPORT"
DBURL="sqlserver://$SQLCMDUSER@$SQLSERVER:$SQLPORT"
export DB_UI_CargasEnergy="$DBURL/CargasEnergy$DBEXTRA"
export DB_UI_CargasEnergyTest="$DBURL/CargasEnergyTest$DBEXTRA"
export DB_UI_ConversionScripts="$DBURL/ConversionScripts$DBEXTRA"
export DB_UI_LegacyData="$DBURL/LegacyData$DBEXTRA"

export SQLCMDSERVER="$SQLSERVER,$SQLPORT"

export CUSTOMER=$(sqlcmd -C -l 1 -W -h -1 -Q "SET NOCOUNT ON; SELECT TOP 1 Name FROM bCompany" 2> /dev/null)

if [ "$(echo $CUSTOMER | cut -d' ' -f 1-3)" = "unable to open" ]; then
	export CUSTOMER=""
fi
