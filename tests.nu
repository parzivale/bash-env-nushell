use std/assert
use bash-env.nu

@test
def "pipe exported var" [] {
    let actual = "export A=123" | bash-env
    assert equal $actual {A: "123"}
}

@test
def "non-exported vars excluded" [] {
    let actual = "A=123" | bash-env
    assert equal $actual {}
}

@test
def "deprecated --export flag" [] {
    let actual = "A=123" | bash-env --export [A]
    assert equal $actual {A: "123"}
}

@test
def "empty value" [] {
    let actual = 'export A=""' | bash-env
    assert equal $actual {A: ""}
}

@test
def "simple file" [] {
    let actual = bash-env tests/simple.env
    assert equal $actual {A: "a", B: "b"}
}

@test
def "single var file" [] {
    let actual = bash-env tests/single.env
    assert equal $actual {MISSION: "Impossible"}
}

@test
def "empty file" [] {
    let actual = bash-env tests/empty.env
    assert equal $actual {}
}

@test
def "shell variables from file" [] {
    let actual = bash-env tests/shell-variables.env
    assert equal $actual {B: "exported"}
}

@test
def "deprecated --export from file" [] {
    let actual = bash-env --export [A] tests/shell-variables.env
    assert equal $actual {A: "not exported", B: "exported"}
}

@test
def "nasty values from file" [] {
    let actual = bash-env "tests/Ming's menu of (merciless) monstrosities.env"
    assert equal $actual {
        SPACEMAN: "One small step for a man ..."
        QUOTE: "\"Well done!\" is better than \"Well said!\""
        MIXED_BAG: "Did the sixth sheik's sixth sheep say \"baa\", or not?"
    }
}

@test
def "error file" [] {
    assert error { bash-env tests/error.env }
}

@test
def "shellvars flag" [] {
    let actual = ("A=123" | bash-env -s).shellvars
    assert equal $actual {A: "123"}
}

@test
def "shellvars from file" [] {
    let actual = bash-env -s tests/shell-variables.env | reject meta
    assert equal $actual {shellvars: {A: "not exported"}, env: {B: "exported"}}
}

@test
def "shell functions" [] {
    let actual = bash-env -f [f2 f3] tests/shell-functions.env | reject meta
    assert equal $actual {
        env: {B: "1", A: "1"}
        shellvars: {}
        fn: {
            f2: {
                env: {B: "2", A: "2"}
                shellvars: {C2: "I am shell variable C2"}
            }
            f3: {
                env: {B: "3", A: "3"}
                shellvars: {C3: "I am shell variable C3"}
            }
        }
    }
}
