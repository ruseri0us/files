#requires -version 2

filter Get-U {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    # extract the computer name from whatever object was passed on the pipeline
    $Computer = $ComputerName | Get-NF

    # open up a handle to the Remote Desktop Session host
    #$Handle = $Wtsapi32::WTSOpenServerEx($Computer)
	$Handle = $Wtsapi32::WTSOpenServerEx("127.0.0.1")

    # if we get a non-zero handle back, everything was successful
    if ($Handle -ne 0) {

        # arguments for WTSEnumerateSessionsEx
        $ppSessionInfo = [IntPtr]::Zero
        $pCount = 0
        
        # get information on all current sessions
        $Result = $Wtsapi32::WTSEnumerateSessionsEx($Handle, [ref]1, 0, [ref]$ppSessionInfo, [ref]$pCount);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

        # Locate the offset of the initial intPtr
        $Offset = $ppSessionInfo.ToInt64()

        if (($Result -ne 0) -and ($Offset -gt 0)) {

            # Work out how much to increment the pointer by finding out the size of the structure
            $Increment = $WTS_SESSION_INFO_1::GetSize()

            # parse all the result structures
            for ($i = 0; ($i -lt $pCount); $i++) {
 
                # create a new int ptr at the given offset and cast the pointer as our result structure
                $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
                $Info = $NewIntPtr -as $WTS_SESSION_INFO_1

                $RDPSession = New-Object PSObject

                if ($Info.pHostName) {
                    $RDPSession | Add-Member Noteproperty 'ComputerName' $Info.pHostName
                }
                else {
                    # if no hostname returned, use the specified hostname
                    $RDPSession | Add-Member Noteproperty 'ComputerName' $Computer
                }

                $RDPSession | Add-Member Noteproperty 'SessionName' $Info.pSessionName

                if ($(-not $Info.pDomainName) -or ($Info.pDomainName -eq '')) {
                    # if a domain isn't returned just use the username
                    $RDPSession | Add-Member Noteproperty 'UserName' "$($Info.pUserName)"
                }
                else {
                    $RDPSession | Add-Member Noteproperty 'UserName' "$($Info.pDomainName)\$($Info.pUserName)"
                }

                $RDPSession | Add-Member Noteproperty 'ID' $Info.SessionID
                $RDPSession | Add-Member Noteproperty 'State' $Info.State

                $ppBuffer = [IntPtr]::Zero
                $pBytesReturned = 0

                # query for the source client IP with WTSQuerySessionInformation
                #   https://msdn.microsoft.com/en-us/library/aa383861(v=vs.85).aspx
                $Result2 = $Wtsapi32::WTSQuerySessionInformation($Handle, $Info.SessionID, 14, [ref]$ppBuffer, [ref]$pBytesReturned);$LastError2 = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                if($Result -eq 0) {
                    Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError2).Message)"
                }
                else {
                    $Offset2 = $ppBuffer.ToInt64()
                    $NewIntPtr2 = New-Object System.Intptr -ArgumentList $Offset2
                    $Info2 = $NewIntPtr2 -as $WTS_CLIENT_ADDRESS

                    $SourceIP = $Info2.Address       
                    if($SourceIP[2] -ne 0) {
                        $SourceIP = [String]$SourceIP[2]+"."+[String]$SourceIP[3]+"."+[String]$SourceIP[4]+"."+[String]$SourceIP[5]
                    }
                    else {
                        $SourceIP = $Null
                    }

                    $RDPSession | Add-Member Noteproperty 'SourceIP' $SourceIP
                    $RDPSession

                    # free up the memory buffer
                    $Null = $Wtsapi32::WTSFreeMemory($ppBuffer)

                    $Offset += $Increment
                }
            }
            # free up the memory result buffer
            $Null = $Wtsapi32::WTSFreeMemoryEx(2, $ppSessionInfo, $pCount)
        }
        else {
            Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        }
        # Close off the service handle
        $Null = $Wtsapi32::WTSCloseServer($Handle)
    }
    else {
        Write-Verbose "Error opening the Remote Desktop Session Host (RD Session Host) server for: $ComputerName"
    }
}

filter Get-NF {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Object]
        $Object,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $DnsHostName,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $Name
    )

    if($PSBoundParameters['DnsHostName']) {
        $DnsHostName
    }
    elseif($PSBoundParameters['Name']) {
        $Name
    }
    elseif($Object) {
        if ( [bool]($Object.PSobject.Properties.name -match "dnshostname") ) {
            # objects from Get-NetComputer
            $Object.dnshostname
        }
        elseif ( [bool]($Object.PSobject.Properties.name -match "name") ) {
            # objects from Get-NetDomainController
            $Object.name
        }
        else {
            # strings and catch alls
            $Object
        }
    }
    else {
        return $Null
    }
}

Get-U