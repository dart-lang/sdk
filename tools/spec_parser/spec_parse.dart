#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

const String ClassPath = '.:/usr/share/java/antlr3-runtime.jar';
const String MainClass = 'SpecParser';
const String JavaExecutable = 'java';

main([arguments]) {
  for (String arg in arguments) {
    handleResult(ProcessResult result) {
      if (result.stderr.length != 0) {
        print('Error parsing $arg:\n${result.stderr}');
      }
      print(result.stdout);
    }

    List<String> javaArguments = <String>['-cp', ClassPath, MainClass, arg];
    Process.run(JavaExecutable, javaArguments).then(handleResult);
  }
}
