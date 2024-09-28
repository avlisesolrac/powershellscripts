# Definir variáveis
$opensshPath = "C:\Program Files\OpenSSH"
$dataAtual = Get-Date -Format "yyyy-MM-dd"
$backupPath = "$opensshPath`_$dataAtual"
$zipUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip"
$zipPath = "$opensshPath\OpenSSH-Win64.zip"

# Verificar a versão do OpenSSH
$versaoSSH = Get-Command 'C:\Program Files\OpenSSH\sshd.exe' | Select-Object Version
Write-Host "Versão do OpenSSH: $($versaoSSH)"

# Fazer backup do OpenSSH atual
if (Test-Path $opensshPath) {
    Copy-Item $opensshPath $backupPath -Recurse -Force
    Write-Host "Backup realizado com sucesso em: $backupPath"
} else {
    Write-Host "A pasta do OpenSSH não foi encontrada."
}

# Parar o serviço SSHD
Stop-Service sshd -Force
Write-Host "Serviço SSHD parado com sucesso."

# Download do OpenSSH
Start-BitsTransfer -Source $zipUrl -Destination $zipPath
Write-Host "Download concluído com sucesso: $zipPath"

# Remover arquivos antigos
if (Test-Path $opensshPath) {
    Get-ChildItem 'C:\Program Files\OpenSSH\*' | Where-Object { $_.Name -ne 'null' -and $_.Name -ne 'sshd_config_Totvs'  -and $_.Name -ne 'OpenSSH-Win64.zip' } | Remove-Item -Recurse -Force
    Write-Host "Arquivos antigos removidos com sucesso."
} else {
    Write-Host "A pasta do OpenSSH não foi encontrada."
}

# Extrair o conteúdo para o diretório temporário
Expand-Archive -Path $zipPath -DestinationPath $opensshPath -Force
Write-Host "Arquivo extraído com sucesso."

# Mover arquivos da instalação nova e excluir o diretório OpenSSH-Win64 que foi criado na extração
Move-Item "$opensshPath\OpenSSH-Win64\*" "$opensshPath" -Force
Remove-Item "$opensshPath\OpenSSH-Win64\" -Recurse -Force
Write-Host "Arquivos do OpenSSH movidos com sucesso."

# Verificar se o serviço SSHD existe
if (-Not (Get-Service -Name sshd -ErrorAction SilentlyContinue)) {
    New-Service -Name sshd -Binary "$opensshPath\sshd.exe" -DisplayName "OpenSSH SSH Server" -Description "OpenSSH Server for secure remote access"
    Write-Host "Serviço SSHD instalado com sucesso."
} else {
    Write-Host "Serviço SSHD já existe."
}

# Abrir e alterar o arquivo sshd_config
$configFilePath = "C:\ProgramData\ssh\sshd_config"
if (Test-Path $configFilePath) {
    (Get-Content $configFilePath) -replace '\\', '\\' | Set-Content $configFilePath
    Write-Host "Arquivo sshd_config atualizado com sucesso."
} else {
    Write-Host "Arquivo sshd_config não encontrado."
}

# Iniciar o serviço SSHD
Start-Service sshd
Write-Host "Serviço SSHD iniciado com sucesso."

# Verificar a versão do OpenSSH
$versaoSSH = Get-Command 'C:\Program Files\OpenSSH\sshd.exe' | Select-Object Version
Write-Host "Versão do OpenSSH: $($versaoSSH)"