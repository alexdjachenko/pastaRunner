# pastaRunner.tcl - Tcl пакет для удобного запуска консольных команд
package provide pastaRunner 1.0

namespace eval pastaRunner {
    variable defaults
    array set defaults {
        env {}
        cwd ""
        strict false
        debug false
    }
}

proc pastaRunner::new {} {
    set obj [namespace current]::[incr ::pastaRunner::counter]
    namespace eval $obj {
        variable env {}
        variable cwd ""
        variable strict false
        variable debug false
        variable last_output ""
        variable last_error ""
        variable last_exit_code 0
    }
    return $obj
}

proc CmdRunner::configure {obj args} {
    foreach {key val} $args {
        if {[info exists ${obj}::$key]} {
            set ${obj}::$key $val
        } else {
            return -code error "Unknown option: $key"
        }
    }
}

proc CmdRunner::run {obj command} {
    variable ${obj}::env
    variable ${obj}::cwd
    variable ${obj}::strict
    variable ${obj}::debug
    variable ${obj}::last_output
    variable ${obj}::last_error
    variable ${obj}::last_exit_code

    set env_backup [array get ::env]
    array set ::env $env
    if {$cwd ne ""} {
        set old_cwd [pwd]
        cd $cwd
    }

    if {$debug} {
        puts "Executing: $command"
    }

    set result [catch {exec {*}$command} output]
    set last_output $output

    if {$result} {
        set last_error $output
        set last_exit_code $::errorCode
        if {$strict} {
            return -code error "Command failed: $command\nError: $output"
        }
    } else {
        set last_exit_code 0
    }

    array set ::env $env_backup
    if {[info exists old_cwd]} {
        cd $old_cwd
    }

    return $last_output
}

proc CmdRunner::get_env {obj var} {
    if {[info exists ${obj}::env($var)]} {
        return ${obj}::env($var)
    }
    return ""
}

proc CmdRunner::set_env {obj var value} {
    set ${obj}::env($var) $value
}

proc CmdRunner::get_last_output {obj} {
    return ${obj}::last_output
}

proc CmdRunner::get_last_error {obj} {
    return ${obj}::last_error
}

proc CmdRunner::get_last_exit_code {obj} {
    return ${obj}::last_exit_code
}
