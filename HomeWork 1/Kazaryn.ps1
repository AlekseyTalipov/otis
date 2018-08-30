#########################################################################################################
##	Описание
##	Автор: Талипов А.Г 
##	Верися 0.8
##
##	Скрипт выполняет загрузку файлов с сайта brokenstone.ru
##	В качестве входных параметров необходимо перадить логи и пароль от сайта и путь для сохранения файлов.
##
#########################################################################################################
[CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$false, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("DownloadFolder")] 
        [string]$OutFolder="\\avtostrada.biz\Екатеринбург\Общая корзина\Ж.Д. База\brokstone\"  
 
      <#  [Parameter(Mandatory=$false)] 
        [string]$Login='Avtostrada', 
         
        [Parameter(Mandatory=$false)]
        [string]$Password="5ed8f5"#>
     )
        

$h1 = @{
Host= 'brokenstone.ru'
'User-Agent'= 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
Accept= 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'    
'Accept-Language'= 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4'
'Accept-Encoding'= 'gzip, deflate, sdch'
}

switch ($Env:COMPUTERNAME) {
    'gatzilla' { $downloadFolder ="G:\Temp\brokstone\"; break }
    'k001'     { $downloadFolder ="c:\usr\"; break }

    Default {$downloadFolder=$OutFolder}
}

#$logfile=$downloadFolder + "logs\script.log"

function ChekFolders ($folder=$downloadFolder) {
    
    if (!(Test-Path $folder)) {

        $NewFolder = New-Item $folder -Force -ItemType Directory 
        $newFolderLog = New-Item ($folder + "logs") -Force -ItemType Directory 
        $newFolderMounth = New-Item ($folder + "за месяц") -Force -ItemType Directory
        Write-Log -Message "Созданы папки"
               
    }


}


function Write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path=$downloadFolder + "logs\script.log", 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'SilentlyContinue' 
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Создан $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End 
    { 
    } 
}
# данная функция определяет папку для сохранения файла в зввисимости от названия ссылки
function outFolder ($Link, $downloadFolder) {

				switch -regex ($Link) {
											
									"Январь"    {$outFolder=$downloadFolder + "за Месяц\"; break}
									"Февраль"   {$outFolder=$downloadFolder + "за Месяц\"; break}
									"Март"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Апрель"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Май"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Июнь"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Июль"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Август"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Сентябрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Октябрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Ноябрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Декабрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									Default 	{$outFolder=$downloadFolder}
									}

		return $outFolder
}
#Данная функция выдает массив объектами которые сожержат очишенные ссылки названия и ид файлов а так же пути для сохранения. 
function getURL ($links,$downloadFolder){
	$URLS1 = @()
	$OldUrlsTemp =@()
	if ((Test-Path ($downloadFolder + "logs\downloadurls.xml")) -eq $true) {
	$OldUrls1 = Import-Clixml ($downloadFolder + "logs\downloadurls.xml")
	}
	else { Write-log "файла  downloadurls.xml нет"}
					
		foreach ($download in ($links | Where-Object {$_.href -like "*Downloading.aspx?file*"})) {
			
			$fileNameID=$download.href  -split "[=;]" -replace "&amp"
			$FileName=$fileNameID[1] 
			$FileID=$fileNameID[3]
			
			$NameLinks = $download.outerHTML -split "[><]"
			
			$outFolder= outFolder $download.outerHTML $downloadFolder
					
			$downloadFiles=$outFolder + $Fileid+"_"+$FileName
   
   			$downloadURL=("http://brokenstone.ru/" + $download.href) -replace "amp;"
   			
			
				$properties = @{'downloadURL'=$downloadURL;
	                			'downloadFiles'=$downloadFiles;
								'NameLinks'=$NameLinks[2];
								'NameFile'=$Fileid+"_"+$FileName;
								'idFiles'=$FileID;
	                		}
			$URL1 = New-Object –TypeName PSObject –Prop $properties
			
			if ($OldUrls1 | Where-Object {(($_.idFiles -eq $URL1.idFiles) -and ($_.NameFile -eq $URL1.NameFile))}) {
			
						$OldUrlsTemp+=$URL1
			}

						else {
												
						$URLS1+=$URL1
			}
		
	}
 			
return $URLS1, $OldUrlsTemp
		
}
#загрузка файла
function DownloadFiles {
    $DownUrls=@()

	$getURLs = getURL $webRequest.links $downloadFolder
	
	
	if ($getURLs[0].count -eq 0){
	
	write-log -Message "Нет новых файлов для загрузки"  #-Path $logfile
	
	}
	
	else {
   
	  foreach ($url in $getURLs[0]) {
     	 		
		
		$start_time = Get-Date
		$webRequest1=Invoke-WebRequest $URL.downloadURL -WebSession $session # -PassThru -outfile $URL.downloadFiles
		
		Switch  ($webRequest1.BaseResponse.ContentType) {
		
				'application/octet-stream' {
		
		
		[io.file]::WriteAllBytes($URL.downloadFiles,$webRequest1.Content)
        $DownUrls+=$url
		Write-log -Message ("Файл "+$url.NameFile+ " загружен за $((Get-Date).Subtract($start_time).Seconds) second(s)") #-Path $logfile
		
		write-log -Message ("Загружен файл " + $url.NameFile)  #-Path $logfile
			}	
		
				default {
				
					write-log -Message ("ContentType  в заголовке ответа не соотвесвует 'application/octet-stream' файл не загружен, возвращенный ContentType = " + $webRequest.BaseResponse.ContentType)  #-Path $logfile
				}
			}
		
		
		}
	}
Export-Clixml ($downloadFolder + "logs/downloadurls.xml") -InputObject ($DownUrls + $getURLs[1])
write-log -Message "Работа скрипта завершена " #-Path $logfile
}
ChekFolders
#Авторизация на сайте
#Надо разобраться с формированием строки BODY POST.

#$Request = Invoke-WebRequest 'http://brokenstone.ru/account/login.aspx' -Headers $h1 -SessionVariable session

#$Request.Forms.Fields.ctl00_ctl00_ContentPanel_MainContent_LoginUserControl_LoginTextBox = 'Avtostrada'
#
#$Request.Forms.Fields.ctl00_ctl00_ContentPanel_MainContent_LoginUserControl_PasswordTextBox = '5ed8f5'
#
#$Request.Forms.Fields.__EVENTTARGET = 'ctl00$ctl00$ContentPanel$MainContent$LoginUserControl$LoginButton'

$b1='__EVENTTARGET=ctl00%24ctl00%24ContentPanel%24MainContent%24LoginUserControl%24LoginButton&__EVENTARGUMENT=&__VIEWSTATE=%2FwEPDwUKLTQzMzQzMTk3Ng9kFgJmD2QWAmYPZBYEAgEPZBYCAhAPFRIPLi4vanMvanF1ZXJ5LmpzDy4uL2pzL3NsaWRlci5qcx0uLi9qcy9qcXVlcnkuc2VsZWN0Ym94Lm1pbi5qcxouLi9qcy9qcXVlcnkubWFwaGlsaWdodC5qcx4uLi9qcy9qcXVlcnkubWFwaGlsaWdodC5taW4uanMYLi4vanMvanF1ZXJ5LnF0aXAubWluLmpzEC4uL2pzL3JhcGhhZWwuanMOLi4vanMvcGF0aHMuanMNLi4vanMvaW5pdC5qcx4uLi9qcy9qcXVlcnkubmljZXNjcm9sbC5taW4uanMNLi4vanMvbWFpbi5qcw0uLi9qcy9tZW51LmpzEC4uL2pzL3NjcmlwdHMuanMfLi4vanMvanMtcGFnZXMtZm9ybXMvdG9vbHRpcC5qcyUuLi9qcy9qcy1wYWdlcy1mb3Jtcy9jdXNlbC1taW4tMi41LmpzFi4uL2FuaW1fMTUwXzIwMF9taW4uanMdLi4vMTcwNTIxLWJyby1ua3Jzcy03Mzh4NzAuanMNLi4vdHJ1Y2tlci5qc2QCBQ9kFgYCAg8WAh4HVmlzaWJsZWhkAgcPFgIfAGhkAgsPFgIeB0VuYWJsZWRoZBgCBR5fX0NvbnRyb2xzUmVxdWlyZVBvc3RCYWNrS2V5X18WAgVAY3RsMDAkY3RsMDAkQ29udGVudFBhbmVsJE1haW5Db250ZW50JExvZ2luVXNlckNvbnRyb2wkUmVtZW1iZXJNZQUoY3RsMDAkY3RsMDAkTW9kYWxMb2dpbjEkUmVtZW1iZXJDaGVja0JveAUmY3RsMDAkY3RsMDAkTW9kYWxTZW5kMSRDYXB0Y2hhQ29udHJvbDEPBSQ1MjIxMTU3NS1hNWZjLTRiZDgtYWI4Zi00MzhmZmUyNzFiNjRkmNCGoW%2FR%2BNWsVD92rN6g8CIxI%2BE%3D&__VIEWSTATEGENERATOR=CD85D8D2&__EVENTVALIDATION=%2FwEdAGwoxC7FO12yU1dZJyKrYCr5MHdCM%2FkCuAXL1MygfKtMdYQr863Dch3AEpGfh7KhSmEG7j8yD0xw%2ForAcH5u2P9VF3ZLgJNFi9rqyyie2y6yCVp6J5NH2PJWKs4eUU5IL6eqXv%2Bp97CZZ4H4%2FWDuGmUNTRcXhyV7vYtxHCVTu6l1rxV7i3gUhHn%2Fu2vu5TgjdVpQ2btD%2Fwa8neBdhchheCdspm%2FLOAj7%2BOHpDJN6eng%2F5BnC9Ot%2Bvr1z%2FqTYq09bDmDxb4%2B%2Fe8XwEP4MIKkF%2Fik9XIWpYTzlWglmajI%2B9WlJkk3simLvbdyynQyPW05vsqoATXmZvXfWpOHpZyk%2FRtWZIxiHFYsoZ9vmQlIgQObub8wFwq%2F7h2dDC9XY6RJizSjU3ERcHGfQXZsOoGkuicOlJ6JsoWW4EEDnfJa4x9v92O5ZzQ0oEqOhpG3bzaX7cmrJtminmH5ZKQwlS4iX80o3CGahogJA7KSU55G7fJtJOWmVbbUr53L8nutZrqA%2BloAlAVbBEmldiG5iJ%2BJAUeOU4JF9Na8dFFhp%2BHFOloTyfpiFFMuYDzCmI5j44uHuADo3Yy35PqOQV520iLHB8Yu5H2Y84lW1OwSyPPyNT3WPF8W9N2%2BK7sugj5MSsFTaZbg87AwYGiag8ulFu3yESIuc4XxKSRIE6WjuNRTjXvFdpc2aGGAEE3GjzrvJAk989dmEg6bZL%2B26J8uGYpUiP%2FZD4Ov9qaKc85q9P6hn2pD5ml4GDu2god2QlitY16JsNPTmBXhtuoTF6qXVbAvYjlbW3Vph3OQLNGUhFConLFlWqB5fb%2BnRGghwrDxbnUC1onxbzR4b0NjGVTCXmNZHAuiqQFbBC2eXsCSoI%2FR1q8jo2kky4OtuFv7K7r0M%2FZmuk9B5IrcEXGpsqkKeclSTUdjXOwLnDWs5X%2FniQXRbVzOgT1DpabQ%2FWoKuaxF8i8S1kHYJJEBRPWhnlohj6kpPuO1oWUYhDF8LOQw4SF2W7RV%2B1tsjm5dY0HAktvUaNdNUXrdR4habyGPSQyYFuKmQXX6O0FyejwbYZXJoImcOxx%2FnUmd7Gyc74tkbbg27H%2BybEjeJ70A7buAler%2B8u1T8D9PLZ5UdZAxOZkV9hmRmQLWYnOUs9ofxrr%2F6EMIXliyyg34KwvTkXO9D2jLof1XYd6BmM3i1R2dnVAQ0pbVTd0Zb3GeBJl%2Bbn56%2FrQqeeMPF9Yy%2Ff2Q4AE%2BhLf%2BE3bBwVEX3jAJTQzQalr%2FjBHHesJa%2FwzkpOz3VFpSIoDJhzkLDOc0IlhnVXoABmNRuP1iN%2FwP7Lsvh1Dq%2BtKMA1cEAptSwm5%2BkDmPFLA7sA3EOUXjIqZyrWcaTkXSI9W3XfaYi5pItThpXUhythmTJJzbg3j0COc0xQ69ovVghIHIryajY5YbY%2F04gkPXW3aquNf9nHdu1OjtUkuXX9cLMNhL0xR9OMhJfCvsXQ1hjqz%2F%2FywohoJ4fI1lkOGpafCIF4u8wx2hxHWlPL4JtZF2PMTcQPeTd9zAu%2FdS8XEsSZOUAkxvT6FhPok7277LiRx7pdPTHS%2FH4B%2FmQ5T%2F9901zrbqcfHX5jv7BHc32thF%2BYjxQVUlRQ%2B47Rz76Wq6FULSmyQjofYrwdIbriTuFaDdP4fzNV6%2Fm6Ffwp0%2FY7851utbVQodIjsQn3RaQ%2F9YI7We%2B8lMR2HAVpRzHb9EeEfjHqZBzh9K2M17tZs0VDcSIw3DSZwSe10od1U6QA5d6nUnRFAejw3SaYbNyUSnXvtJs2KW60%2Bo1hB6HhCwB8bGjiDKRyoYMHXu2f%2BVjJOcHaDQnzLHLM2EVGC0Lygk8dwNs8vU07NOJw6O99rl%2BC%2FzkEUci2VesuaKiTi47%2BMfYdInLJrBzszW1mJGru6nJakDIomguXXjmBk1ihELeV2OvrOBmTEqpeB5nCPhnV6FQKIH1%2B2TDhYCk00xXyf13q5jzSo4me1fpp94kzEH7mAOW3g8vuwAAcs%2FVyfeTMBpZDME2z7x0aXapjLyJp9ubVYj2E1ffyU7WRO4n9osmWjd3hDKpQkVt6AgU4Ln9iT9UrugUDZNZGsDF9tKoMcvdydqYyN1ClpvimVB0TBMTjcCH46nR1mtjT34FQa4pnK4U%2FqEX2SgpaadGXf4yy8c3%2Be231CbhyzBpSbwBwSSUkbx4pJ%2FHMuWAmWMhxe0vNOTPHI8I%2F8AMKJLZbk5yI6mtoY5FEciJviHzphKqTwgD6aFK6osjx%2BiYa4ZzPPqNg8PzqKJWUjtNd8lZ0t8wACUBnSJ57cdMbSJjgN9IjsNzKCkte6y2LAlh0eTdIbqPZcROkt5kRmwQFEGmbTl6Kw%3D%3D&ctl00%24ctl00%24ContentPanel%24MainContent%24LoginUserControl%24LoginTextBox=Avtostrada&ctl00%24ctl00%24ContentPanel%24MainContent%24LoginUserControl%24PasswordTextBox=5ed8f5&ctl00%24ctl00%24ModalSend1%24SubjectTextBox=&ctl00%24ctl00%24ModalSend1%24TextTextBox=&ctl00%24ctl00%24ModalSend1%24FIOTextBox=&ctl00%24ctl00%24ModalSend1%24EmailTextBox=&ctl00%24ctl00%24ModalSend1%24PhoneTextBox=&ctl00%24ctl00%24ModalSend1%24CaptchaControl1=&ctl00%24ctl00%24ModalReg1%24LoginTextBox=&ctl00%24ctl00%24ModalReg1%24EmailTextBox=&ctl00%24ctl00%24ModalLogin1%24LoginTextBox=&ctl00%24ctl00%24ModalLogin1%24PasswordTextBox=&ctl00%24ctl00%24ModalForgot1%24LoginTextBox=&ctl00%24ctl00%24ModalForgot1%24EmailTextBox='
#$b1='__EVENTTARGET=ctl00%24ctl00%24ContentPanel%24MainContent%24LoginUserControl%24LoginButton&__EVENTARGUMENT=&__VIEWSTATE=%2FwEPDwUKLTQzMzQzMTk3Ng9kFgJmD2QWAmYPZBYEAgEPZBYCAg8PFREPLi4vanMvanF1ZXJ5LmpzDy4uL2pzL3NsaWRlci5qcx0uLi9qcy9qcXVlcnkuc2VsZWN0Ym94Lm1pbi5qcxouLi9qcy9qcXVlcnkubWFwaGlsaWdodC5qcx4uLi9qcy9qcXVlcnkubWFwaGlsaWdodC5taW4uanMYLi4vanMvanF1ZXJ5LnF0aXAubWluLmpzEC4uL2pzL3JhcGhhZWwuanMOLi4vanMvcGF0aHMuanMNLi4vanMvaW5pdC5qcx4uLi9qcy9qcXVlcnkubmljZXNjcm9sbC5taW4uanMNLi4vanMvbWFpbi5qcw0uLi9qcy9tZW51LmpzEC4uL2pzL3NjcmlwdHMuanMfLi4vanMvanMtcGFnZXMtZm9ybXMvdG9vbHRpcC5qcyUuLi9qcy9qcy1wYWdlcy1mb3Jtcy9jdXNlbC1taW4tMi41LmpzFi4uL2FuaW1fMTUwXzIwMF9taW4uanMdLi4vMTcwNTIxLWJyby1ua3Jzcy03Mzh4NzAuanNkAgUPZBYGAgMPFgIeB1Zpc2libGVoZAIIDxYCHwBoZAILDxYCHgdFbmFibGVkaGQYAgUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgIFQGN0bDAwJGN0bDAwJENvbnRlbnRQYW5lbCRNYWluQ29udGVudCRMb2dpblVzZXJDb250cm9sJFJlbWVtYmVyTWUFKGN0bDAwJGN0bDAwJE1vZGFsTG9naW4xJFJlbWVtYmVyQ2hlY2tCb3gFJmN0bDAwJGN0bDAwJE1vZGFsU2VuZDEkQ2FwdGNoYUNvbnRyb2wxDwUkMzAxYjRmNzktNWJjYS00NTI3LWI3Y2YtYWFhNDUyZDM1Y2FkZASkPkVNooRIJJ1K9HlWNrjlL2m%2B&__VIEWSTATEGENERATOR=CD85D8D2&__EVENTVALIDATION=%2FwEdAGwNDKZHcr8THbVb72U37xMqMHdCM%2FkCuAXL1MygfKtMdYQr863Dch3AEpGfh7KhSmEG7j8yD0xw%2ForAcH5u2P9VF3ZLgJNFi9rqyyie2y6yCVp6J5NH2PJWKs4eUU5IL6eqXv%2Bp97CZZ4H4%2FWDuGmUNTRcXhyV7vYtxHCVTu6l1rxV7i3gUhHn%2Fu2vu5TgjdVpQ2btD%2Fwa8neBdhchheCdspm%2FLOAj7%2BOHpDJN6eng%2F5BnC9Ot%2Bvr1z%2FqTYq09bDmDxb4%2B%2Fe8XwEP4MIKkF%2Fik9XIWpYTzlWglmajI%2B9WlJkk3simLvbdyynQyPW05vsqoATXmZvXfWpOHpZyk%2FRtWZIxiHFYsoZ9vmQlIgQObub8wFwq%2F7h2dDC9XY6RJizSjU3ERcHGfQXZsOoGkuicOlJ6JsoWW4EEDnfJa4x9v92O5ZzQ0oEqOhpG3bzaX7cmrJtminmH5ZKQwlS4iX80o3CGahogJA7KSU55G7fJtJOWmVbbUr53L8nutZrqA%2BloAlAVbBEmldiG5iJ%2BJAUeOU4JF9Na8dFFhp%2BHFOloTyfpiFFMuYDzCmI5j44uHuADo3Yy35PqOQV520iLHB8Yu5H2Y84lW1OwSyPPyNT3WPF8W9N2%2BK7sugj5MSsFTaZbg87AwYGiag8ulFu3yESIuc4XxKSRIE6WjuNRTjXvFdpc2aGGAEE3GjzrvJAk989dmEg6bZL%2B26J8uGYpUiP%2FZD4Ov9qaKc85q9P6hn2pD5ml4GDu2god2QlitY16JsNPTmBXhtuoTF6qXVbAvYjlbW3Vph3OQLNGUhFConLFlWqB5fb%2BnRGghwrDxbnUC1onxbzR4b0NjGVTCXmNZHAuiqQFbBC2eXsCSoI%2FR1q8jo2kky4OtuFv7K7r0M%2FZmuk9B5IrcEXGpsqkKeclSTUdjXOwLnDWs5X%2FniQXRbVzOgT1DpabQ%2FWoKuaxF8i8S1kHYJJEBRPWhnlohj6kpPuO1oWUYhDF8LOQw4SF2W7RV%2B1tsjm5dY0HAktvUaNdNUXrdR4habyGPSQyYFuKmQXX6O0FyejwbYZXJoImcOxx%2FnUmd7Gyc74tkbbg27H%2BybEjeJ70A7buAler%2B8u1T8D9PLZ5UdZAxOZkV9hmRmQLWYnOUs9ofxrr%2F6EMIXliyyg34KwvTkXO9D2jLof1XYd6BmM3i1R2dnVAQ0pbVTd0Zb3GeBJl%2Bbn56%2FrQqeeMPF9Yy%2Ff2Q4AE%2BhLf%2BE3bBwVEX3jAJTQzQalr%2FjBHHesJa%2FwzkpOz3VFpSIoDJhzkLDOc0IlhnVXoABmNRuP1iN%2FwP7Lsvh1Dq%2BtKMA1cEAptSwm5%2BkDmPFLA7sA3EOUXjIqZyrWcaTkXSI9W3XfaYi5pItThpXUhythmTJJzbg3j0COc0xQ69ovVghIHIryajY5YbY%2F04gkPXW3aquNf9nHdu1OjtUkuXX9cLMNhL0xR9OMhJfCvsXQ1hjqz%2F%2FywohoJ4fI1lkOGpafCIF4u8wx2hxHWlPL4JtZF2PMTcQPeTd9zAu%2FdS8XEsSZOUAkxvT6FhPok7277LiRx7pdPTHS%2FH4B%2FmQ5T%2F9901zrbqcfHX5jv7BHc32thF%2BYjxQVUlRQ%2B47Rz76Wq6FULSmyQjofYrwdIbriTuFaDdP4fzNV6%2Fm6Ffwp0%2FY7851utbVQodIjsQn3RaQ%2F9YI7We%2B8lMR2HAVpRzHb9EeEfjHqZBzh9K2M17tZs0VDcSIw3DSZwSe10od1U6QA5d6nUnRFAejw3SaYbNyUSnXvtJs2KW60%2Bo1hB6HhCwB8bGjiDKRyoYMHXu2f%2BVjJOcHaDQnzLHLM2EVGC0Lygk8dwNs8vU07NOJw6O99rl%2BC%2FzkEUci2VesuaKiTi47%2BMfYdInLJrBzszW1mJGru6nJakDIomguXXjmBk1ihELeV2OvrOBmTEqpeB5nCPhnV6FQKIH1%2B2TDhYCk00xXyf13q5jzSo4me1fpp94kzEH7mAOW3g8vuwAAcs%2FVyfeTMBpZDME2z7x0aXapjLyJp9ubVYj2E1ffyU7WRO4n9osmWjd3hDKpQkVt6AgU4Ln9iT9UrugUDZNZGsDF9tKoMcvdydqYyN1ClpvimVB0TBMTjcCH46nR1mtjT34FQa4pnK4U%2FqEX2SgpaadGXf4yy8c3%2Be231CbhyzBpSbwBwSSUkbx4pJ%2FHMuWAmWMhxe0vNOTPHI8I%2F8AMKJLZbk5yI6mtoY5FEciJviHzphKqTwgD6aFK6osjx%2BiYa4ZzPPqNg8PzqKJWUjtNd8lZ0t8wACUBnSJ57cdMbSJjgN9IjsNzKCkte6y2LAlh0eS4SI8HGAoEuE9%2BYr9dF22FSOGfuA%3D%3D&ctl00%24ctl00%24ContentPanel%24MainContent%24LoginUserControl%24LoginTextBox=Avtostrada&ctl00%24ctl00%24ContentPanel%24MainContent%24LoginUserControl%24PasswordTextBox=5ed8f5&ctl00%24ctl00%24ModalSend1%24SubjectTextBox=&ctl00%24ctl00%24ModalSend1%24TextTextBox=&ctl00%24ctl00%24ModalSend1%24FIOTextBox=&ctl00%24ctl00%24ModalSend1%24EmailTextBox=&ctl00%24ctl00%24ModalSend1%24PhoneTextBox=&ctl00%24ctl00%24ModalSend1%24CaptchaControl1=&ctl00%24ctl00%24ModalReg1%24LoginTextBox=&ctl00%24ctl00%24ModalReg1%24EmailTextBox=&ctl00%24ctl00%24ModalLogin1%24LoginTextBox=&ctl00%24ctl00%24ModalLogin1%24PasswordTextBox=&ctl00%24ctl00%24ModalForgot1%24LoginTextBox=&ctl00%24ctl00%24ModalForgot1%24EmailTextBox='
#$log=Invoke-WebRequest -method POST -URI 'http://brokenstone.ru/account/login.aspx' -Body $b1 -WebSession $session -ContentType 'application/x-www-form-urlencoded'
$log=Invoke-WebRequest -method POST -URI 'http://brokenstone.ru/account/login.aspx' -Body $b1 -Headers $h1 -SessionVariable session -ContentType 'application/x-www-form-urlencoded' #-UseBasicParsing

$webRequest=Invoke-WebRequest 'http://brokenstone.ru/supplyfileexport.aspx' -WebSession $session -UseBasicParsing

if ($webRequest.links.href | Where-Object {$_ -like "*downloading.aspx*"}){
	write-log -Message "Авторизация удалась - Здравствуйте,Avtostrada!" #-Path $logfile
	
	DownloadFiles

			
	} else {
			write-log -Message "Авторизация не удалась" #-Path $logfile
			
	}