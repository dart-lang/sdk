// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart_doctest_impl.dart';

Future<void> main(List<String> args) async {
  DartDocTest dartDocTest = new DartDocTest();
  for (String filename in args) {
    await dartDocTest.process(Uri.base.resolve(filename));
  }
}
