import times, strutils

proc prettyTime(rep: float, elapsed: float): tuple[byTime, byRep: string]

template testing*(body: untyped): untyped =
    ## Run test in Go style
    when (isMainModule and (defined(test) or defined(bench))) or
    defined(testall) or defined(benchall):
        var
            BenchDurationSeconds {.inject.} = 0.5
            f = instantiationInfo(fullPaths = true).filename
            t = cpuTime()
            rounded: string # Strange bug if rounded defined after body
        echo "== RUN     ", f
        body
        rounded = (cpuTime() - t).formatFloat(ffDefault, 4)
        echo "--- DONE:  ", f, " (", rounded, "s)"

template runTest*(body: untyped): untyped =
    runTest("", body)

template runTest*(name: string, body: untyped): untyped =
    when defined(test) or defined(testall):
        block:
            var
                t = cpuTime()
                rounded: string
            echo "  >= TEST     ", name
            body
            rounded = (cpuTime() - t).formatFloat(ffDefault, 4)
            echo "  >-- PASS:   ", rounded, "s"

template runBench*(body: untyped): untyped =
    runBench("", body)

template runBench*(name: string, body: untyped): untyped =
    ## Loop the code until approximatively maxTime is reached
    ## Due to its own calculations, it can't measure times < 10ns
    ## Use timeIt to compare code that runs in ns
    when defined(bench) or defined(benchall):
        block:
            when not declared(BenchDurationSeconds):
                var BenchDurationSeconds {.inject.} = 0.5
            echo "  >= BENCH     ", name
            let startTime = epochTime() # CpuTime is too slow
            var Control {.inject.}: float # To avoid compiler remove code

            var rep: float
            var elapsed: float
            while true:
                for _ in 0 .. int(max(1 / 10 * rep , 1 / 10 * elapsed)) + 1:
                    body
                    rep += 1.0
                elapsed = epochTime() - startTime
                if elapsed > BenchDurationSeconds:
                    break
            let time = prettyTime(rep, elapsed)
            #stdout.write "  >-- DONE:    " & name & " ".repeat(max(20 - name.len, 5))
            stdout.write "  >-- PASS:             "
            if Control != 0:
                stdout.write "Control:" & Control.formatFloat(ffDefault, 4)
            else:
                stdout.write " ".repeat(13)
            echo " ".repeat(10), time.byTime, " | ", time.byRep

template timeIt*(rep: int, body: untyped): untyped =
    ## Quick and dirty, high precision
    block:
        var
            Control {.inject.}: float # To avoid compiler remove code
            t = cpuTime()
        for i in 0 ..< rep:
            body
        let elapsed = cpuTime() - t
        let time = prettyTime(float(rep), elapsed)
        echo "Done in ", elapsed.formatFloat(ffDefault, 5), "s    ->      ",
            time.byTime, " | ", time.byRep
        if Control != 0:
            echo "> Control: ", Control

proc prettyTime(rep: float, elapsed: float): tuple[byTime, byRep: string] =
    var rep = rep / elapsed
    var timerep: float
    var unit, unit2: string
    var truncate = true
    if rep > 1_000_000_000:
        rep /= 1_000_000_000
        timerep = 1 / rep
        unit = "ns"
        unit2 = "ns"
        truncate = false
    elif rep > 1_000_000:
        rep /= 1_000_000
        timerep = 1000 / rep
        unit = "μs"
        unit2 = "ns"
    elif rep > 1_000:
        rep /= 1_000
        timerep = 1000 / rep
        unit = "ms"
        unit2 = "μs"
    elif rep < 1_000:
        timerep = 1000 / rep
        unit = "s"
        unit2 = "ms"
    else:
        timerep = 1 / rep
        unit = "s"
        unit2 = "s"
    return (rep.formatFloat(ffDefault, 5) & " op/" & unit,
        timerep.formatFloat(ffDefault, 5) & " " & unit2 & "/op")
