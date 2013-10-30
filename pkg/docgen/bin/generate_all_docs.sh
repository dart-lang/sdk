# A simple shell script to generate all docs for the sdk and pkg directories
# into the docs folder in this directory.
# TODO(alanknight): This should get subsumed into the python scripts
dart --package-root=$DART_SDK/../packages/ docgen.dart --parse-sdk --json
dart --old_gen_heap_size=1024 --package-root=$DART_SDK/../packages/ docgen.dart \
  --package-root=$DART_SDK/../packages/ --append --json $DART_SDK/../../../pkg
