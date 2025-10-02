#only return instance names that are online
#detect and handle cluster

$server = $env:computername

$object = Get-service -ComputerName $server  | where {($_.name -like "MSSQL$*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQL Server (*") }

if ($object)
{
$instDetails = $object | Where-Object -Property status -eq Running |select @{Name="Instance"; Expression ={$_.Name.replace('MSSQL$',"")}}

}else
{
  "NoSQLOnline" | ConvertTo-Json
}
$instDetails = $instDetails | Select-Object -ExpandProperty instance

#test for windows clustering
try
    {
        Import-Module failoverclusters -ErrorAction SilentlyContinue

            $arrINST = Get-Clusterresource `
            | Where-Object {($_.resourcetype -like 'sql server')} `
            | Get-Clusterparameter "instancename" `
            | Sort-Object objectname `
            | Select-Object -expandproperty value #| Where-Object -FilterScript {$_.value -in $instDetails}

            $arrVSN = Get-Clusterresource `
            | Where-Object {$_.resourcetype -like 'sql server'} `
            | Get-Clusterparameter "virtualservername" `
            | Sort-Object objectname `
            | Select-Object -expandproperty value

            $instonline = foreach ($i in 0..($arrINST.count-1))
                {
                   if($instDetails -contains $arrINST[$i]){
                    $arrVSN[$i] + "\" + $arrINST[$i]}
                }
    }
catch{
          $instonline = foreach ($i in $instDetails) {("$server\$i").Replace('\MSSQLSERVER','')}

        }

    $instonline | ConvertTo-Json


