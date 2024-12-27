# Автоматическая выгрузка баз 1с. Файловая версия.

# Список баз данных
$Bases = @(
    @{
        Path     = "c:\1c\base1\"   # Путь к первой базе
    },
    @{
        Path     = "c:\1c\base2\"   # Путь ко второй базе
    },
    @{
        Path     = "c:\1c\base3\"   # Путь к третьей базе
    }
)

# Путь к исполняемому файлу 1С
$OneCExecutable = "c:\Program Files\1cv8\8.3.25.1501\bin\1cv8.exe"

# Папка для сохранения резервных копий
$BackupFolder = "c:\transfer\1C_transfer\"

# Имя процесса, связанного с 1С
$ProcessName = "1cv8"

# Получение списка процессов
$Processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if ($Processes) {
    Write-Output "Найдено $($Processes.Count) процессов $ProcessName. Попытка завершить..."
    
    # Завершение процессов
    foreach ($Process in $Processes) {
        try {
            Write-Output "Завершение процесса ID: $($Process.Id), имя: $($Process.Name)"
            Stop-Process -Id $Process.Id -Force -ErrorAction Stop
        } catch {
            Write-Error "Не удалось завершить процесс ID: $($Process.Id). Ошибка: $($_.Exception.Message)"
        }
    }

    Write-Output "Все процессы $ProcessName завершены."
} else {
    Write-Output "Процессов $ProcessName не найдено."
}

# Проверка существования папки для резервных копий
if (!(Test-Path -Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder | Out-Null
}

# Массив для отслеживания фоновых процессов
$Processes = @()

# Цикл по базам данных
foreach ($Base in $Bases) {
    $BasePath = $Base.Path

    # Генерация имени файла резервной копии
    $BackupPath = Join-Path -Path $BackupFolder -ChildPath ("{0}.dt" -f (Split-Path -Leaf $BasePath))#, (Get-Date -Format 'yyyyMMdd_HHmmss'))

    # Формирование команды для выгрузки
    $Command = "`"$OneCExecutable`" DESIGNER /F `"$BasePath`" /DumpIB `"$BaseDtFile`""

    Write-Output "Запуск выгрузки базы данных: $BasePath в фоновом режиме"

    # Запуск команды в фоновом режиме
    $Process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$Command`"" -PassThru -WindowStyle Hidden
    $Processes += $Process
}

# Ожидание завершения всех фоновых процессов
Write-Output "Ожидание завершения фоновых задач..."
foreach ($Process in $Processes) {
    $Process.WaitForExit()
    if ($Process.ExitCode -eq 0) {
        Write-Output "Процесс ID $($Process.Id) успешно завершён."
    } else {
        Write-Error "Процесс ID $($Process.Id) завершился с ошибкой. Код ошибки: $($Process.ExitCode)"
    }
}

Write-Output "Все процессы завершены."
