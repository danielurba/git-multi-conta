param(
    [Parameter(Mandatory)][string]$NomePessoal,
    [Parameter(Mandatory)][string]$EmailPessoal,
    [Parameter(Mandatory)][string]$NomeEmpresa,
    [Parameter(Mandatory)][string]$EmailEmpresa
)
# Nunca sobrescreve arquivo existente. Gera chaves ED25519 se nao existirem
# (ssh-keygen pergunta a passphrase). Nao envia nada para a rede.

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ssh  = Join-Path $HOME '.ssh'
New-Item -ItemType Directory $ssh -Force | Out-Null

function Copy-Template($src, $dst, $map) {
    if (Test-Path $dst) { Write-Host "SKIP (ja existe): $dst"; return }
    $txt = Get-Content $src -Raw
    foreach ($k in $map.Keys) { $txt = $txt.Replace($k, $map[$k]) }
    [IO.File]::WriteAllText($dst, $txt, (New-Object Text.UTF8Encoding $false))
    Write-Host "OK: $dst"
}

# Ordem importa: 'SEU NOME - EMPRESA' antes de 'SEU NOME'
$map = [ordered]@{
    'SEU NOME - EMPRESA'    = $NomeEmpresa
    'seu.email@empresa.com' = $EmailEmpresa
    'seu.email@pessoal.com' = $EmailPessoal
    'SEU NOME'              = $NomePessoal
}

Copy-Template "$root\ssh\config.example"                 "$ssh\config"                     $map
Copy-Template "$root\git\gitconfig.example"              "$HOME\.gitconfig"                $map
Copy-Template "$root\git\gitconfig-pessoal.example"      "$HOME\.gitconfig-pessoal"        $map
Copy-Template "$root\git\gitconfig-empresa.example"      "$HOME\.gitconfig-empresa"        $map

foreach ($c in @(@('pessoal',$EmailPessoal), @('empresa',$EmailEmpresa))) {
    $key = Join-Path $ssh "github_$($c[0])"
    if (Test-Path $key) { Write-Host "SKIP (chave existe): $key"; continue }
    ssh-keygen -t ed25519 -C $c[1] -f $key
}

Set-Service ssh-agent -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service ssh-agent -ErrorAction SilentlyContinue

Write-Host "`nProximos passos:"
Write-Host "1. Cadastre cada .pub em GitHub > Settings > SSH and GPG keys (conta certa)."
Write-Host "2. ssh-add $ssh\github_pessoal ; ssh-add $ssh\github_empresa"
Write-Host "3. ssh -T git@github-pessoal ; ssh -T git@github-empresa"
