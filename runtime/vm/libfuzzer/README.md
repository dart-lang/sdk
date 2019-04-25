DartLibFuzzer
=============

DartLibFuzzer is a fuzzing tool built with LibFuzzer, which
is an in-process, coverage-guided, evolutionary fuzzing engine
(https://llvm.org/docs/LibFuzzer.html). The tool consists of a
collection of "target functions", each of which stresses a
particular part of the Dart runtime and compiler.

How to build and run DartLibFuzzer
==================================
Build the dart_libfuzzer binary as follows (first either export
DART_USE_ASAN=1 or run ./tools/gn.py --mode=debug --asan):

./tools/build.py --mode debug dart_libfuzzer

Then, to start a blank fuzzing session, run:

dart_libfuzzer

To start a fuzzing session with an initial corpus inside
the directory CORPUS, run:

dart_libfuzzer CORPUS
