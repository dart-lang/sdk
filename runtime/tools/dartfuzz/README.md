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

    dartfuzz.py [--help] [--seed SEED]

where

    --help : prints help and exits
    --seed : defines random seed (system-set by default)

DartFuzz sends all output to stdout, and provides
a runnable main isolate. A typical test run looks as:

    dartfuzz.py > fuzz.dart
    dart fuzz.dart

How to start DartFuzz testing
=============================

    run_dartfuzz_test.py  [--help]
                          [--repeat REPEAT]
                          [--true_divergence]
                          [--mode1 MODE]
                          [--mode2 MODE]

where

    --help            : prints help and exits
    --repeat          : number of tests to run (1000 by default)
    --true_divergence : only report true divergences
    --mode1           : m1
    --mode2           : m2, and values one of
        jit = Dart JIT
        aot = Dart AOT
        js  = dart2js + JS

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
as input to a system in an attempt to find bugs or make it crash. Generation-
based fuzz testing constructs random, but properly formatted input data.
Mutation-based fuzz testing applies small random changes to existing inputs
in order to detect shortcomings in a system. Profile-guided or coverage-guided
fuzzing adds a direction to the way these random changes are applied. Multi-
layered approaches generate random inputs that are subsequently mutated at
various stages of execution.

The randomness of fuzz testing implies that the size and scope of testing is
no longer bounded. Every new run can potentially discover bugs and crashes
that were hereto undetected.
