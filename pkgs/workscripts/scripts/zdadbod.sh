#!/bin/sh

ESCAPED_PASSWORD=$(python -c "import urllib.parse; print(urllib.parse.quote('$SQLCMDPASSWORD'),end='')")

DBEXTRA="?trustServerCertificate&encrypt"
DBURL="sqlserver://$SQLCMDUSER:$ESCAPED_PASSWORD@$SQLSERVER:$SQLPORT"
export DB_UI_CargasEnergy="$DBURL/CargasEnergy$DBEXTRA"
export DB_UI_CargasEnergyTest="$DBURL/CargasEnergyTest$DBEXTRA"
export DB_UI_ConversionScripts="$DBURL/ConversionScripts$DBEXTRA"
export DB_UI_LegacyData="$DBURL/LegacyData$DBEXTRA"
