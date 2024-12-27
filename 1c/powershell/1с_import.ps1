# Автоматический импорт выгрузок 1с. Для файловой версии.

# Список баз данных и их параметры
$Bases = @(
    @{
        Path = "c:\1c\base1\"     					   # Путь к файловой базе
        DtFile = "c:\transfer\1C_transfer\base1.dt"	   # Путь к файлу резервной копии
    },
    @{
        Path = "c:\1c\base2\"
        DtFile = "c:\transfer\1C_transfer\base2.dt"
    },
	    @{
        Path = "c:\1c\base3\"
        DtFile = "c:\transfer\1C_transfer\base3.dt"
    }
)

# Путь к исполняемому файлу 1С
$OneCExecutable = "c:\Program Files\1cv8\8.3.25.1501\bin\1cv8.exe"

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

# Массив для отслеживания фоновых процессов
$Processes = @()

# Функция для загрузки базы
foreach ($Base in $Bases) {
    $BasePath = $Base.Path
	$BaseDtFile = $Base.DtFile

    # Проверка существования файла .dt
    if (-Not (Test-Path -Path $BaseDtFile)) {
        Write-Error "Файл резервной копии $BaseDtFile не найден. Пропуск базы $BasePath."
        return
    }

    # Формирование команды для загрузки
    $Command = "`"$OneCExecutable`" DESIGNER /F `"$BasePath`" /RestoreIB `"$BaseDtFile`""

	Write-Output $Command
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