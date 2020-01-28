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

  Expect.throwsNoSuchMethodError(
      () => thisLibrary.invoke(#topLevelMethod, []),
      'Should not invoke imported method #topLevelMethod');

  Expect.throwsNoSuchMethodError(
      () => thisLibrary.getField(#topLevelGetter),
      'Should not invoke imported getter #topLevelGetter');

  Expect.throwsNoSuchMethodError(
      () => thisLibrary.getField(#topLevelField),
      'Should not invoke imported field #topLevelField');

  Expect.throwsNoSuchMethodError(
      () => thisLibrary.setField(#topLevelSetter, 23),
      'Should not invoke imported setter #topLevelSetter');

  Expect.throwsNoSuchMethodError(
      () => thisLibrary.setField(#topLevelField, 23),
      'Should not invoke imported field #topLevelField');
}
