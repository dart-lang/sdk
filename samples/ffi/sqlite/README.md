# Sample code dart:ffi

This is an illustrative sample for how to use `dart:ffi`.


## Building and Running this Sample

Building and running this sample is done through pub.
Running `pub get` and `pub run test` should produce the following output.

```sh
$ pub get
Resolving dependencies... (6.8s)
+ analyzer 0.35.4
...
+ yaml 2.1.15
Downloading analyzer 0.35.4...
Downloading kernel 0.3.14...
Downloading front_end 0.1.14...
Changed 47 dependencies!
Precompiling executables... (18.0s)
Precompiled test:test.

```

```
$ pub run test
00:01 +0: test/sqlite_test.dart: sqlite integration test                                                                                                     
1 Chocolade chip cookie Chocolade cookie foo
2 Ginger cookie null 42
3 Cinnamon roll null null
1 Chocolade chip cookie Chocolade cookie foo
2 Ginger cookie null 42
expected exception on accessing result data after close: The result has already been closed.
expected this query to fail: no such column: non_existing_column (Code 1: SQL logic error)
00:02 +3: All tests passed! 
```

## Tutorial

A tutorial walking through the code is available in [docs/sqlite-tutorial.md](docs/sqlite-tutorial.md).