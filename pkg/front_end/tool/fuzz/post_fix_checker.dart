// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, FileSystemEntity;

import '../../test/utils/io_utils.dart' show computeRepoDirUri;

import 'compile_helper.dart';
import 'stacktrace_utils.dart';

final Uri repoDir = computeRepoDirUri();

Future<void> main(List<String> args) async {
  Directory d = new Directory(args.single);
  Helper helper = new Helper();
  await helper.setup();
  int good = 0;
  int bad = 0;
  for (FileSystemEntity file in d.listSync(recursive: false)) {
    if (file is! File) continue;
    (Object, StackTrace)? result = await helper.compile(
      file.readAsStringSync(),
    );
    String filename = file.uri.pathSegments.last;
    if (result == null) {
      print("${filename}: OK");
      good++;
    } else {
      print("${filename}: Still crashes: ${categorize(result.$2)}");
      bad++;
    }
  }
  print("Done. $good good, $bad bad.");
}
