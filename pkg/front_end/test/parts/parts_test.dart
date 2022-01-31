// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/messages.dart';

Future<void> main() async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  CompilerOptions options = new CompilerOptions()
    ..sdkRoot = computePlatformBinariesLocation()
    ..packagesFileUri = Uri.base.resolve('.packages');
  for (FileSystemEntity dir in dataDir.listSync()) {
    if (dir is Directory) {
      print('Compiling ${dir.path}');
      List<Uri> input = [];
      for (FileSystemEntity file in dir.listSync()) {
        input.add(file.absolute.uri);
      }
      input.sort((a, b) => a.path.compareTo(b.path));
      bool hasError = false;
      options.onDiagnostic = (message) {
        if (message.severity == Severity.error) {
          hasError = true;
        }
        message.plainTextFormatted.forEach(print);
      };
      await kernelForModule(input, options);
      Expect.isFalse(hasError, "Unexpected errors");
    }
  }
}
