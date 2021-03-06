
# HElPER FUNCTIONS

# Used with most Infocyte Get methods. Takes a filter object (hashtable) and adds authentication and passes it as the body for URI encoded parameters. NoLimit will iterate 1000 results at a time to the end of the data set.
function _ICGetMethod ([String]$url, [HashTable]$filter, [Switch]$NoLimit) {
  $skip = 0
  Write-Progress -Activity "Getting Data from Hunt Server API" -status "Requesting data from $url [$skip]"
  $count = 0
  $body = @{
		access_token = $Global:ICToken
	}
  if ($filter) {
    $body['filter'] = $filter | ConvertTo-JSON -Depth 8 -Compress
  }
  Write-Verbose "Requesting data from $url (Limited to $resultlimit unless using -NoLimit)"
  Write-Verbose "$($body | ConvertTo-JSON -Depth 8 -Compress)"
	try {
		$Objects = Invoke-RestMethod $url -body $body -Method GET -ContentType 'application/json'
	} catch {
		Write-Warning "Error: $_"
		return "ERROR: $($_.Exception.Message)"
	}
	if ($Objects) {
    $count += $Objects.count
		Write-Output $Objects
	} else {
		return $null
	}

  if ($NoLimit -AND $Objects.count -eq $resultlimit) { $more = $true } else { $more = $false }
	While ($more) {
		$skip += $resultlimit
		$filter['skip'] = $skip
		$body.remove('filter') | Out-Null
		$body.Add('filter', ($filter | ConvertTo-JSON -Depth 8 -Compress))
    Write-Progress -Activity "Getting Data from Hunt Server API" -status "Requesting data from $url [$skip]"
		try {
			$moreobjects = Invoke-RestMethod $url -body $body -Method GET -ContentType 'application/json'
		} catch {
			Write-Warning "Error: $_"
			return "ERROR: $($_.Exception.Message)"
		}
		if ($moreobjects.count -gt 0) {
      $count += $moreobjects.count
			Write-Output $moreobjects
		} else {
			$more = $false
		}
	}
  Write-Verbose "Recieved $count objects from $url"
}

# Used with all other rest methods. Pass a body (hashtable) and it will add authentication.
function _ICRestMethod ([String]$url, $body=$null, [String]$method) {
  $headers = @{
    Authorization = $Global:ICToken
  }
  Write-verbose "Sending $method command to $url"
  Write-verbose "Body = $($body | ConvertTo-JSON -Compress -Depth 8)"
	try {
		$Result = Invoke-RestMethod $url -headers $headers -body ($body|ConvertTo-JSON -Compress -Depth 4) -Method $method -ContentType 'application/json'
	} catch {
		Write-Warning "Error: $_"
		return "ERROR: $($_.Exception.Message)"
	}
	if ($Result) {
		Write-Output $Result
	} else {
		return $null
	}
}
