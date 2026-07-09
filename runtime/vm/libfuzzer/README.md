DartLibFuzzer
=============

DartLibFuzzer is a fuzzing tool built with LibFuzzer, which
is an in-process, coverage-guided, evolutionary fuzzing engine.
The DartLibFuzzer tool consists of a collection of "target
functions", each of which stresses a particular part of the
Dart runtime and compiler.

How to build and run DartLibFuzzer
==================================

Build the dart_libfuzzer binary as follows (first either export
DART_USE_ASAN=1 or run ./tools/gn.py --mode=debug --asan):

    ./tools/build.py \
      -m [all|debug|release|product] \
      -a [x64|arm64|simarm64] \
      dart_libfuzzer

Then, to start a blank fuzzing session on a particular target
function (as defined in dart_libfuzzer.cc), run:

    dart_libfuzzer [--t=<target-function>]

To start a fuzzing session with an initial corpus inside
the directory CORPUS, run:

    dart_libfuzzer CORPUS

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
