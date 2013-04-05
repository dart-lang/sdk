// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.descriptor.utils;

import 'dart:async';
import 'dart:io';

import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

export '../utils.dart';

String sandbox;

void scheduleSandbox() {
  schedule(() {
    return new Directory('').createTemp().then((dir) {
      sandbox = dir.path;
      d.defaultRoot = sandbox;
    });
  });

  currentSchedule.onComplete.schedule(() {
    d.defaultRoot = null;
    if (sandbox == null) return;
    var oldSandbox = sandbox;
    sandbox = null;
    return new Directory(oldSandbox).delete(recursive: true);
  });
}

Future<List<int>> byteStreamToList(Stream<List<int>> stream) {
  return stream.fold(<int>[], (buffer, chunk) {
    buffer.addAll(chunk);
    return buffer;
  });
}

Future<String> byteStreamToString(Stream<List<int>> stream) =>
  byteStreamToList(stream).then((bytes) => new String.fromCharCodes(bytes));

