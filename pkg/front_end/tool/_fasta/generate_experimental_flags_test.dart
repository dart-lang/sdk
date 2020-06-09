// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File, exitCode;

import "generate_experimental_flags.dart"
    show
        computeCfeGeneratedFile,
        computeKernelGeneratedFile,
        generateCfeFile,
        generateKernelFile;

main() {
  {
    Uri generatedFile = computeCfeGeneratedFile();
    String generated = generateCfeFile();
    String actual = (new File.fromUri(generatedFile).readAsStringSync())
        .replaceAll('\r\n', '\n');
    check(generated, actual, generatedFile);
  }
  {
    Uri generatedFile = computeKernelGeneratedFile();
    String generated = generateKernelFile();
    String actual = (new File.fromUri(generatedFile).readAsStringSync())
        .replaceAll('\r\n', '\n');
    check(generated, actual, generatedFile);
  }
}

void check(String generated, String actual, Uri generatedFile) {
  if (generated != actual) {
    print("""
------------------------

The generated file
  ${generatedFile.path}

is out of date. To regenerate the file, run
  dart pkg/front_end/tool/fasta.dart generate-experimental-flags

------------------------
""");
    exitCode = 1;
  }
}
