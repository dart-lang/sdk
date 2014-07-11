// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that poi.dart finds the right element.

library trydart.poi_find_test;

import 'dart:io' show
    Platform;

import 'dart:async' show
    Future;

import 'package:try/poi/poi.dart' as poi;

import 'package:async_helper/async_helper.dart';

import 'package:expect/expect.dart';

import 'package:compiler/implementation/elements/elements.dart' show
    Element;

Future testPoi() {
  Uri script = Platform.script.resolve('data/empty_main.dart');
  return poi.runPoi(script, 225).then((Element element) {
    Uri foundScript = element.compilationUnit.script.resourceUri;
    Expect.stringEquals('$script', '$foundScript');
    Expect.stringEquals('main', element.name);
  });
}

void main() {
  asyncTest(testPoi);
}
