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
    return Directory.systemTemp.createTemp('descriptor_sandbox_').then((dir) {
      sandbox = dir.path;
      d.defaultRoot = sandbox;
    });
  });

  currentSchedule.onComplete.schedule(() {
    d.defaultRoot = null;
    if (sandbox == null) return null;
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

Matcher isDirectoryDescriptor(String name, List contents) {
  return predicate((object) {
    try {
      expect(object, new isInstanceOf<d.DirectoryDescriptor>());
      expect(object.name, equals(name));
      expect(object.contents, unorderedMatches(contents));
      return true;
    } on TestFailure catch (_) {
      return false;
    }
  }, "a directory descriptor named $name containing $contents");
}

Matcher isFileDescriptor(String name, contents) {
  return predicate((object) {
    try {
      expect(object, new isInstanceOf<d.FileDescriptor>());
      expect(object.name, equals(name));
      expect(object.textContents, contents);
      return true;
    } on TestFailure catch (_) {
      return false;
    }
  }, "a file descriptor named $name containing $contents");
}

