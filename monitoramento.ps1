# =========================================================
# Monitoramento Windows (CPU/RAM/DISCO) + MySQL + Discord
# =========================================================

# ---------------- CONFIG ----------------
$mysqlHost = "127.0.0.1"
$mysqlPort = 3306
$dbName    = "monitoramento"
$mysqlUser = "root"
$mysqlPass = ""   # Coloque sua senha aqui

$discordWebhookUrl = ""   # Coloque seu webhook aqui

$CPU_ALERT  = 85
$RAM_ALERT  = 90
$DISK_ALERT = 90
$ALWAYS_NOTIFY = $true

# ---------------- FUNÇÃO DISCORD ----------------
function Send-DiscordMessage {
    param([Parameter(Mandatory=$true)][string]$Text)

    if (-not $discordWebhookUrl -or $discordWebhookUrl -notmatch "^https:\/\/discord\.com\/api\/webhooks\/") {
        throw "Webhook inválido. Use: https://discord.com/api/webhooks/ID/TOKEN"
    }

    $payload = @{ content = $Text } | ConvertTo-Json -Depth 3
    try {
        Invoke-RestMethod -Uri $discordWebhookUrl -Method Post -ContentType "application/json" -Body $payload -TimeoutSec 10 | Out-Null
    } catch {
        # mostra erro real do Discord (melhor que o 405 genérico)
        $detail = $_.ErrorDetails.Message
        throw "Falha ao enviar Discord. Erro: $($_.Exception.Message) Detalhe: $detail"
    }
}

# ---------------- IDENTIDADE DO SERVIDOR ----------------
$serverName = $env:COMPUTERNAME

# Pega o IPv4 principal (pega 192.168.15.35)
$serverIP = (Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq "Up" } |
    Select-Object -First 1 -ExpandProperty IPv4Address |
    Select-Object -First 1 -ExpandProperty IPAddress)

if (-not $serverIP) {
    # fallback: pega primeiro IPv4 "Up"
    $serverIP = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "169.254*" -and
            $_.IPAddress -ne "127.0.0.1" -and
            $_.InterfaceOperationalStatus -eq "Up"
        } |
        Select-Object -First 1 -ExpandProperty IPAddress)
}

if (-not $serverIP) { $serverIP = "0.0.0.0" }

# ---------------- COLETA DE MÉTRICAS ----------------
$cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$cpu = [math]::Round([double]$cpu, 2)

$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [double]$os.TotalVisibleMemorySize
$freeRAM  = [double]$os.FreePhysicalMemory
$ramPercent = (($totalRAM - $freeRAM) / $totalRAM) * 100
$ramPercent = [math]::Round([double]$ramPercent, 2)

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskPercent = ((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100)
$diskPercent = [math]::Round([double]$diskPercent, 2)

# ---------------- MYSQL (SimplySql) ----------------
Import-Module SimplySql -ErrorAction Stop

$cred = New-Object System.Management.Automation.PSCredential(
    $mysqlUser,
    (ConvertTo-SecureString $mysqlPass -AsPlainText -Force)
)

Open-MySqlConnection -Server $mysqlHost -Port $mysqlPort -Database $dbName -Credential $cred -ConnectionName "lab"

Invoke-SqlUpdate -ConnectionName "lab" -Query @"
CREATE TABLE IF NOT EXISTS servidores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL UNIQUE,
    ip VARCHAR(45),
    ambiente VARCHAR(50),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"@ | Out-Null

Invoke-SqlUpdate -ConnectionName "lab" -Query @"
CREATE TABLE IF NOT EXISTS metricas (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    servidor_id INT NOT NULL,
    cpu_percent DECIMAL(5,2) NOT NULL,
    ram_percent DECIMAL(5,2) NOT NULL,
    disco_percent DECIMAL(5,2) NOT NULL,
    coletado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (servidor_id),
    CONSTRAINT fk_servidor FOREIGN KEY (servidor_id) REFERENCES servidores(id)
);
"@ | Out-Null

$serverRow = Invoke-SqlQuery -ConnectionName "lab" -Query "SELECT id FROM servidores WHERE nome = '$serverName' LIMIT 1;"

if (-not $serverRow) {
    Invoke-SqlUpdate -ConnectionName "lab" -Query "INSERT INTO servidores (nome, ip, ambiente) VALUES ('$serverName', '$serverIP', 'LAB');" | Out-Null
    $serverRow = Invoke-SqlQuery -ConnectionName "lab" -Query "SELECT id FROM servidores WHERE nome = '$serverName' LIMIT 1;"
}

$id = [int]$serverRow.id

Invoke-SqlUpdate -ConnectionName "lab" -Query @"
INSERT INTO metricas (servidor_id, cpu_percent, ram_percent, disco_percent)
VALUES ($id, $cpu, $ramPercent, $diskPercent);
"@ | Out-Null

Close-SqlConnection -ConnectionName "lab"

# ---------------- ALERTA / ENVIO ----------------
$alert = $false
$reasons = @()

if ($cpu -ge $CPU_ALERT)         { $alert = $true; $reasons += "CPU $cpu%" }
if ($ramPercent -ge $RAM_ALERT)  { $alert = $true; $reasons += "RAM $ramPercent%" }
if ($diskPercent -ge $DISK_ALERT){ $alert = $true; $reasons += "DISCO $diskPercent%" }

$msg = @"
MONITORAMENTO - $serverName
IP: $serverIP
CPU: $cpu%
RAM: $ramPercent%
DISCO (C:): $diskPercent%
"@

if ($alert) {
    $msg += "`nALERTA: " + ($reasons -join " | ")
    Send-DiscordMessage -Text $msg
}
elseif ($ALWAYS_NOTIFY) {
    Send-DiscordMessage -Text $msg
}

Write-Host "OK - $serverName | IP $serverIP | CPU $cpu% | RAM $ramPercent% | DISCO $diskPercent%"
