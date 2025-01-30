#!/usr/bin/tclsh

lappend auto_path ../
package require "pastaRunner"

set runner [pastaRunner::new]
pastaRunner::configure $runner env [list PATH "/usr/bin:/bin"]
pastaRunner::configure $runner cwd "/tmp"
pastaRunner::configure $runner debug true

set output [pastaRunner::run $runner "ls"]
puts "Output: $output"
puts "Exit Code: [pastaRunner::get_last_exit_code $runner]"

