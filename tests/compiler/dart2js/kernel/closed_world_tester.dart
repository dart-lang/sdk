// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper application to run `closed_world2_test` on multiple files or
/// directories.

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/filenames.dart';
import 'closed_world2_test.dart';

main(List<String> args) async {
  for (String arg in args) {
    String path = nativeToUriPath(arg);
    if (FileSystemEntity.isDirectorySync(path)) {
      Directory dir = new Directory(path);
      for (FileSystemEntity file in dir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          await testFile(file);
        }
      }
    } else if (FileSystemEntity.isFileSync(path)) {
      await testFile(new File(path));
    } else {
      print("$arg doesn't exist");
    }
  }
}

Future testFile(File file) async {
  print('====================================================================');
  print('testing ${file.path}');
  await mainInternal([file.path]);
}
