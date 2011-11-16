TODO(rnystrom): This is moving from a sample to being a real project. Right
now, to try this out:

1. Compile interact.dart to JS:
   dartdoc$ ../../frog/frogsh --libdir=../../frog/lib --out=docs/interact.js \
     --compile-only interact.dart

2. Run the doc generator:
   dartdoc$ ../../frog/frogsh --libdir=../../frog/lib dartdoc.dart dartdoc.dart

   Note here that the first "dartdoc.dart" is to run this program, and the
   second is passing its own name to itself to generate its own docs.

3. Look at the results in frog/docs/