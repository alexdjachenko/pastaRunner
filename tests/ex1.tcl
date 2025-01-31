#!/usr/bin/tclsh

lappend auto_path ../
package require "pastaRunner"


set runner [pastaRunner new]

# Настраиваем поведение
#$runner configure env {MY_VAR "Hello"}
$runner configure env [dict create MY_VAR "Hello"]  ;# Передаем как `dict`
$runner configure cwd "/home"
$runner configure debug 1
$runner configure strictExitCode 1
$runner configure strictStderr 0
$runner configure mergeStderr 1

# Запускаем команду
set result [$runner run "ls"]

# Разбираем результат
set stdout [lindex $result 0]
set stderr [lindex $result 1]
set exitCode [lindex $result 2]

puts "STDOUT: $stdout"
puts "STDERR: $stderr"
puts "EXIT CODE: $exitCode"

# Используем оболочку Bash
$runner configure shell "/bin/bash"

# Запускаем команду
set result [$runner run "ls"]

# Разбираем результат
set stdout [lindex $result 0]
set stderr [lindex $result 1]
set exitCode [lindex $result 2]

puts "STDOUT: $stdout"
puts "STDERR: $stderr"
puts "EXIT CODE: $exitCode"

# Запускаем команду
set result [$runner run "ls"]

# Запускаем команду
set result [$runner run "ls /nonexistent"]

# Разбираем результат
set stdout [lindex $result 0]
set stderr [lindex $result 1]
set exitCode [lindex $result 2]

puts "STDOUT: $stdout"
puts "STDERR: $stderr"
puts "EXIT CODE: $exitCode"
