// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// File-listing utils used by dartdevrun.
library dev_compiler.src.runner.file_utils;

import 'dart:async';
import 'dart:io';

Future<List<File>> listJsFiles(Directory dir) async {
  var list = [];
  await for (var file in dir.list(recursive: true, followLinks: true)) {
    if (file is File && file.path.endsWith(".js")) list.add(file.absolute);
  }
  return list;
}
