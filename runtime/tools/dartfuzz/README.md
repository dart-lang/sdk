DartFuzz
========

DartFuzz is a tool for generating random programs with the objective
of fuzz testing the Dart project. Each randomly generated program
can be run under various modes of execution, such as using JIT,
using AOT, using JavaScript after dart2js, and using various target
architectures (x86, arm, etc.). Any difference between the outputs
(**divergence**) may indicate a bug in one of the execution modes.

How to run DartFuzz
===================
To generate a single random Dart program, run

    dart dartfuzz.dart [--help] [--seed SEED] [--[no-]fp] FILENAME

where

    --help      : prints help and exits
    --seed      : defines random seed (system-set by default)
    --[no-]fp   : enables/disables floating-point operations (default: on)
    --[no-]ffi  : enables/disables FFI method calls (default: off)
    --[no-]flat : enables/disables flat types (default: off)
    --[no-]mini : enables minimization mode (default: off)
    --smask     : bitmask indicating which statements to omit (Bit=1 omits, defaults to "0")
    --emask     : bitmask indicating which expressions to omit (Bit=1 omits, defaults to "0")

The tool provides a runnable main isolate. A typical single
test run looks as:

    dart dartfuzz.dart fuzz.dart
    dart fuzz.dart

How to start DartFuzz testing
=============================
To start a fuzz testing session, run

    dart dartfuzz_test.dart [--help]
                            [--isolates ISOLATES ]
                            [--repeat REPEAT]
                            [--time TIME]
                            [--num-output-lines NUMOUTPUTLINES]
                            [--true_divergence]
                            [--show-stats]
                            [--dart-top DARTTOP]
                            [--mode1 MODE]
                            [--mode2 MODE]
                            [--[no-]rerun]

where

    --help             : prints help and exits
    --isolates         : number of isolates in the session (1 by default)
    --repeat           : number of tests to run (1000 by default)
    --time             : time limit in seconds (none by default)
    --num-output-lines : number of output lines to be printed in the case of a divergence (200 by default)
    --true-divergence  : only report true divergences (true by default)
    --show-stats       : show statistics during session (true by default)
    --dart-top         : sets DART_TOP explicitly through command line
    --mode1            : m1
    --mode2            : m2, and values one of
        jit-[debug-][ia32|x64|arm32|arm64]               = Dart JIT
        aot-[debug-][x64|arm32|arm64]                    = Dart AOT
        djs-x64                                          = dart2js + Node.JS
    --[no-]rerun       : re-run a testcase if there is only a divergence in
                         the return codes outside the range [-255,+255];
                         if the second run produces no divergence the previous
                         one will be ignored (true by default)

If no modes are given, a random combination is used.

This fuzz testing tool must have access to the top of a Dart SDK
development tree (DART_TOP) in which all proper binaries have been
built already (for example, testing jit-ia32 will invoke the binary
${DART_TOP}/out/ReleaseIA32/dart to start the Dart VM). The DART_TOP
can be provided through the --dart-top option, as an environment
variable, or, by default, as the current directory by invoking the
fuzz testing tool from the Dart SDK top.

Background
==========

Although test suites are extremely useful to validate the correctness of a
system and to ensure that no regressions occur, any test suite is necessarily
finite in size and scope. Tests typically focus on validating particular
features by means of code sequences most programmers would expect. Regression
tests often use slightly less idiomatic code sequences, since they reflect
problems that were not anticipated originally, but occurred “in the field”.
Still, any test suite leaves the developer wondering whether undetected bugs
and flaws still linger in the system.

Over the years, fuzz testing has gained popularity as a testing technique for
discovering such lingering bugs, including bugs that can bring down a system
in an unexpected way. Fuzzing refers to feeding a large amount of random data
as input to a system in an attempt to find bugs or make it crash.
Generation-based fuzz testing constructs random, but properly formatted input
data. Mutation-based fuzz testing applies small random changes to existing
inputs in order to detect shortcomings in a system. Profile-guided or
coverage-guided fuzz testing adds a direction to the way these random changes
are applied. Multi-layered approaches generate random inputs that are
subsequently mutated at various stages of execution.

The randomness of fuzz testing implies that the size and scope of testing is
no longer bounded. Every new run can potentially discover bugs and crashes
that were hereto undetected.

Links
=====

* [Dart bugs found with fuzzing](https://github.com/dart-lang/sdk/issues?utf8=%E2%9C%93&q=label%3Adartfuzz+)
* [DartFuzz](https://github.com/dart-lang/sdk/tree/master/runtime/tools/dartfuzz)
* [DartLibFuzzer](https://github.com/dart-lang/sdk/tree/master/runtime/vm/libfuzzer)
* [Dust](https://pub.dev/packages/dust)
* [LibFuzzer](https://llvm.org/docs/LibFuzzer.html)
