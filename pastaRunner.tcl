#!/usr/bin/tclsh

# Class for run commands
package provide "pastaRunner" 1.0

oo::class create pastaRunner {
    variable envVars
    variable workingDir
    variable debugMode
    variable strictExitCode
    variable strictStderr
    variable mergeStderr
    variable shellCmd

    constructor {} {
        #set envVars [array create]
        #set envVars {} # Используем словарь вместо массива
        set envVars [dict create]
        set workingDir ""
        set debugMode 0
        set strictExitCode 0
        set strictStderr 0
        set mergeStderr 0
        set shellCmd ""   ;# По умолчанию выполняем напрямую, без shell
    }

    method configure {option value} {
        switch -- $option {
            env {
                # array set envVars $value
                # set envVars $value # Ожидаем словарь
                #if {![dict exists $value]} {
                #  error "Invalid dict format for envVars"
                #}
                #set envVars $value   ;# Теперь `envVars` корректно хранит словарь
                
                if {[catch {dict size $value}]} {
                    error "Invalid dict format for envVars"
                }
                set envVars $value
                
            }
            cwd {
                set workingDir $value
            }
            debug {
                set debugMode $value
            }
            strictExitCode {
                set strictExitCode $value
            }
            strictStderr {
                set strictStderr $value
            }
            mergeStderr {
                set mergeStderr $value
            }
            shell {
                set shellCmd $value  ;# Можно установить оболочку (например, /bin/bash)
            }
            default {
                error "Unknown option: $option"
            }
        }
    }

    method run {command} {
        set envBackup [array get ::env]

        ## Применяем переменные окружения
        #foreach {key val} [array get envVars] {
        #    set ::env($key) $val
        #}
        # Применяем переменные окружения
        dict for {key val} $envVars {
            set ::env($key) $val
        }

        # Устанавливаем рабочую директорию (если указана)
        if {$workingDir ne ""} {
            set prevDir [pwd]
            cd $workingDir
        }

        # Отладочный вывод
        if {$debugMode} {
            puts "Executing: $command"
            puts "Shell: $shellCmd"
            puts "Working directory: [pwd]"
            puts "Environment: [array get envVars]"
            puts "Strict exit code: $strictExitCode, Strict stderr: $strictStderr, Merge stderr: $mergeStderr"
        }
        
        # Выбираем, объединять ли stderr с stdout
        if {$mergeStderr} {
            set redirect "2>@1"
        } else {
            set redirect "2>@ stderrVar"
        }
        
        # Если выбран shell, запускаем команду через него
        if {$shellCmd ne ""} {
            set execCommand [list $shellCmd -c $command]
        } else {
            set execCommand [concat $command]
        }
        
        
        # Выполняем команду и ловим ошибки
        set output ""
        set stderrOutput ""
        set exitCode [catch {
            set output [exec {*}$execCommand $redirect]
        } errorMsg options]
        
        
        ## Восстанавливаем окружение
        #array set ::env $envBackup
        # Восстанавливаем окружение
        dict for {key val} $envBackup {
          set ::env($key) $val
        }

        # Восстанавливаем рабочую директорию
        if {$workingDir ne ""} {
            cd $prevDir
        }

        # Получаем код возврата процесса
        set realExitCode [dict get $options -code]

        # Если stderr не объединен, получаем его содержимое
        if {!$mergeStderr} {
            set stderrOutput $errorMsg
        }

        # Отладочный вывод
        if {$debugMode} {
            puts "Exit code: $realExitCode"
            puts "Stderr: $stderrOutput"
        }

        # Обрабатываем ошибки в зависимости от режима
        if {($strictExitCode && $realExitCode != 0) || ($strictStderr && $stderrOutput ne "")} {
            error "Command failed: $command\nExit code: $realExitCode\nStderr: $stderrOutput"
        }

        # Возвращаем результат как список [stdout stderr exitCode]
        return [list $output $stderrOutput $realExitCode]
    }
}
