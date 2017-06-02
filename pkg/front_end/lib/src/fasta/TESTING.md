<!--
Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->
# How to test Fasta

When changing Fasta, your changes can affect dart2js or the VM, so you may need
to test them.

Most of the tests below use a 32-bit build because the test runs significantly faster.

<!-- TODO(ahe): Soon, also the analyzer. -->

## Test package:front_end and package:analyzer.

The absolutely bare minimum of testing is the basic unit tests:

```
./tools/test.py -mrelease 'pkg/front_end|*fasta*' --checked --time -pcolor --report -aia32
```

## Testing dart2js

If you're making changes to dart2js, it most likely involves the scanner or parser (at least for now). In that case, you should run dart2js' unit tests (the test suite called dart2js) as well as language and co19.

```
# Unit tests for dart2js
./tools/test.py --dart2js-batch --time -pcolor --report -aia32 -mrelease --checked dart2js

# Language and co19, dart2js.
./tools/test.py --dart2js-batch --time -pcolor --report -aia32 -mrelease -cdart2js -rd8 language co19
```

## Testing the Dart VM

If you're making changes that affect Kernel output, for example, BodyBuilder.dart, you probably also need to test on the VM:

Note that this test requires a 64-bit build because app-jit snapshot does not work for ia32.

```
# Language, co19, kernel, for VM using Fasta.
./tools/build.py -mrelease runtime_kernel && ./tools/test.py -mrelease -cdartk co19 language kernel --time -pcolor --report -j16
```


Notice that the option is -cdartk, but it is actually Fasta. Not dartk.

If you're running on a Mac, it's important that you use the -j option with test.py. It defaults to the number of cores on your machine (including hyper-threads), and for Linux that works fine. But Macs don't seem to be able to run as many processes in parallel. On a Mac Pro with 24 threads, using -j16 seems optimal.
