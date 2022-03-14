#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

const String classPath = '.:/usr/share/java/antlr3-runtime.jar';
const String mainClass = 'SpecParser';
const String javaExecutable = 'java';

main([arguments]) {
  for (String arg in arguments) {
    handleResult(ProcessResult result) {
      if (result.stderr.length != 0) {
        print('Error parsing $arg:\n${result.stderr}');
      }
      print(result.stdout);
    }

    List<String> javaArguments = <String>['-cp', classPath, mainClass, arg];
    Process.run(javaExecutable, javaArguments).then(handleResult);
  }
}
