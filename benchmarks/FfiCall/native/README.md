To upload a new package to CIPD:
```
$ cd benchmarks/FfiCall/native
$ make
$ find . -name "*.o" -type f -delete
$ cipd create -pkg-def=cipd.yaml
```

Then update the top level DEPS file with the new hash.
The new hash can be found with:
```
$ cipd instances dart/benchmarks/fficall
```
