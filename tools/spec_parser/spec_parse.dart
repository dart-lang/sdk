#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

const String classPath = '.:/usr/share/java/antlr3-runtime.jar';
const String mainClass = 'SpecParser';
const String javaExecutable = 'java';

void main(List<String> arguments) {
  for (String arg in arguments) {
    void handleResult(ProcessResult result) {
      if ((result.stderr as String).isNotEmpty) {
        print('Error parsing $arg:\n${result.stderr}');
      }
      print(result.stdout);
    }

    List<String> javaArguments = <String>['-cp', classPath, mainClass, arg];
    Process.run(javaExecutable, javaArguments).then(handleResult);
  }
}
