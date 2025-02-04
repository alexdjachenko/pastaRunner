#!/usr/bin/tclsh

# Class for run commands
package provide "pastaRunner" 1.0

oo::class create pastaRunner {
    variable envVars
    variable workingDir
    variable debugMode
    variable strictExitCode
    variable strictStderr
    variable strictStdout
    variable mergeStderr
    variable shellCmd

    constructor {} {
        #set envVars [array create]
        #set envVars {} # Используем словарь вместо массива
        set envVars [dict create]
        set workingDir ""
        set debugMode 0
        set strictExitCode 1
        # Выдать ошибку, если stderr непуст
        set strictStderr 0
        # Выдать ошибку, если stdout пуст
        set strictStdout 0
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
            strictStdout {
                set strictStdout $value
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
        
        # Выбираем, объединять ли stderr с stdout
        if {$mergeStderr} {
            set redirect "2>&1"
        } else {
            set redirect ""
        }
        
        # Если выбран shell, запускаем команду через него
        if {$shellCmd ne ""} {
            set execCommand [list $shellCmd -c $command]
            # Добавляем команду для редиректа в конке только для варианта с shell
            # т.к. без shell эта магия не работает
            # Однако, если команда возвращает ненулевой код ошибки, $output все-равно будет пустым
            lappend execCommand " $redirect"
        } else {
            # Если мы не используем shell, просто используем то, что нам передали и положимся на то, что команду подготовили правильно,
            # в виде списка
            set execCommand $command
        }
        
        # Отладочный вывод
        if {$debugMode} {
            puts "Executing: $command"
            puts "Shell: $shellCmd"
            puts "ExecCommand $execCommand"
            puts "Working directory: [pwd]"
            puts "Environment: [array get envVars]"
            puts "Strict exit code: $strictExitCode, Strict stderr: $strictStderr, Merge stderr: $mergeStderr"
        }
        
        # Документация по exec https://wiki.tcl-lang.org/page/exec
        # Сбрасываем сообщения об ошибках, чтобы в $::errorInfo не было мусора
        # На всякий случай объявляем остальные переменные, чтобы не было ошибок их отсутствия
        set ::errorInfo ""
        set ::errorCode ""
        set output ""
        set errorMsg ""
        set options ""
        # Выполняем команду и ловим ошибки
        
        set exitCode [catch {
              set output [exec {*}$execCommand]
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

        # Отладочный вывод
        if {$debugMode} {
            # Числовой код ошибки. Если всё хорошо - 0
            puts "exitCode: $exitCode"
            puts "realExitCode: $realExitCode"
            # Текстовый вывод команды, если он был. При ошибке может отсутствовать, т.к всё идет в поток ошибок
            puts "Output: $output"
            puts "---"
            # Сообщение об ошибке или дублирует текстовый вывод.
            # На это поле не надо ориентироваться при определении ошибок выполнения
            puts "errorMsg: $errorMsg"
            puts "::errorCode: $::errorCode"
            puts "::errorInfo: $::errorInfo"
            puts "---"
        }

        # Обрабатываем ошибки в зависимости от режима
        if {($strictExitCode && $realExitCode != 0) 
          || ($strictStderr && $::errorInfo ne "")
          || ($strictStdout && $output eq "") } {
            set errMsg "Command failed: $command\nExit code: $realExitCode\nOutput: $output\nmsg: $errorMsg\nStderr: $::errorInfo"
            error $errMsg
            # error "Command failed: $command\nExit code: $realExitCode\nOutput: $output\nmsg: $errorMsg\nStderr:$::errorInfo"
        }
        

        # Возвращаем результат как список [stdout stderr exitCode]
        return [list $realExitCode $output $errorMsg $::errorInfo]
    }
}
