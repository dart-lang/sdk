// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

import 'package:expect/expect.dart';
import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

part 'libraries_part.dart';

void main() {
  // Test getLibraries()
  var libraries = dart.getLibraries();
  Expect.isTrue(libraries.contains('dart:core'));
  Expect.isTrue(libraries.contains('package:expect/expect.dart'));

  // Test getParts(...)
  var expectParts = dart.getParts('package:expect/expect.dart');
  Expect.isTrue(expectParts.isEmpty);

  var testLibraries =
      libraries.where((l) => l.endsWith('libraries_test.dart')).toList();
  Expect.isTrue(testLibraries.length == 1);
  var testParts = dart.getParts(testLibraries.first);
  Expect.isTrue(testParts.length == 1);
  Expect.isTrue(testParts.first.endsWith('libraries_part.dart'));

  // Test getLibrary(...)
  var core = dart.getLibrary('dart:core');
  var stackTraceType = dart.wrapType(JS('', '#.StackTrace', core));
  Expect.equals(StackTrace, stackTraceType);
}
