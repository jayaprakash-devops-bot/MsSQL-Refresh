    $Versions = @();
     try{
        $Instances = Invoke-Command -ScriptBlock {(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances}
        foreach ($i in $Instances)
        {                       
            $name = Invoke-Command -ScriptBlock { (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').($args[0]) } -ArgumentList $i
            $SearchString = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\Setup" -f $name
            $Versions += Invoke-Command -ScriptBlock {(Get-ItemProperty -Path ($args[0])).PatchLevel} -ArgumentList $SearchString
        }
        Write-Verbose -Message "Listing of Sql Versions found for $HostName are"
    }
    catch{
       Write-Warning -Message "Error Checking SQL Versions for $HostName"
    }
    finally{
    }
    return $Versions | ConvertTo-Json;