// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of the main method in poi.dart. This test only ensures that poi.dart
/// doesn't crash.

library trydart.poi_test;

import 'dart:io' show
    Platform;

import 'dart:async' show
    Future;

import 'package:try/poi/poi.dart' as poi;

import 'package:async_helper/async_helper.dart';

class PoiTest {
  final Uri script;
  final int offset;

  PoiTest(this.script, this.offset);

  Future run() => poi.main(<String>[script.toFilePath(), '$offset']);
}

void main() {
  int position = 695;
  List tests = [
      // The file empty_main.dart is a regression test for crash in
      // resolveMetadataAnnotation in dart2js.
      new PoiTest(Platform.script.resolve('data/empty_main.dart'), 225),
      new PoiTest(Platform.script, position),
  ];

  poi.isDartMindEnabled = false;

  asyncTest(() => Future.forEach(tests, (PoiTest test) => test.run()));
}
