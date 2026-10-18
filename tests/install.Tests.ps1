# Pester 5: the generated launcher (no install, no firewall: only New-LauncherText is loaded).
BeforeAll {
    $src = Get-Content (Join-Path $PSScriptRoot "..\windows\install.ps1") -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
    $fn = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                         $args[0].Name -eq "New-LauncherText" }, $true) | Select-Object -First 1
    Invoke-Expression $fn.Extent.Text
}

Describe "New-LauncherText" {
    It "starts ttyd on the port with the auth header and no password" {
        $t = New-LauncherText -Port 7777 -Command "claude" -WorkingDirectory "C:\Work" -AuthHeader "X-Auth-User"
        $t | Should -Match "-p 7777 -W -H X-Auth-User"
        $t | Should -Not -Match " -c "
    }
    It "clears inherited CLAUDE variables before the command" {
        $t = New-LauncherText -Port 7681 -Command "claude" -WorkingDirectory "C:\Work" -AuthHeader "X-A"
        $t | Should -Match "Get-ChildItem Env:CLAUDE\* \| Remove-Item; Set-Location 'C:\\Work'; claude"
    }
    It "escapes quotes in the command and the folder" {
        $t = New-LauncherText -Port 7681 -Command 'pwsh -c "echo hi"' -WorkingDirectory "C:\it's" -AuthHeader "X-A"
        $t | Should -Match "Set-Location 'C:\\it''s'"
        $t | Should -Match 'pwsh -c """"echo hi""""'
    }
    It "rejects a header name with spaces or symbols" {
        { New-LauncherText -Port 1 -Command "x" -WorkingDirectory "C:\" -AuthHeader "X Bad;" } | Should -Throw
    }
}
