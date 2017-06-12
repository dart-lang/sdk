// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_import_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'other_library.dart';

main() {
  LibraryMirror thisLibrary =
      currentMirrorSystem().findLibrary(#test.invoke_import_test);

  Expect.throws(
      () => thisLibrary.invoke(#topLevelMethod, []),
      (e) => e is NoSuchMethodError,
      'Should not invoke imported method #topLevelMethod');

  Expect.throws(
      () => thisLibrary.getField(#topLevelGetter),
      (e) => e is NoSuchMethodError,
      'Should not invoke imported getter #topLevelGetter');

  Expect.throws(
      () => thisLibrary.getField(#topLevelField),
      (e) => e is NoSuchMethodError,
      'Should not invoke imported field #topLevelField');

  Expect.throws(
      () => thisLibrary.setField(#topLevelSetter, 23),
      (e) => e is NoSuchMethodError,
      'Should not invoke imported setter #topLevelSetter');

  Expect.throws(
      () => thisLibrary.setField(#topLevelField, 23),
      (e) => e is NoSuchMethodError,
      'Should not invoke imported field #topLevelField');
}
