// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// End-to-end test of the analyzer2dart compiler.
library test.end2end;

import 'mock_sdk.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../lib/src/closed_world.dart';
import '../lib/src/driver.dart';
import '../lib/src/converted_world.dart';
import '../lib/src/dart_backend.dart';

import 'test_helper.dart' hide TestSpec;
import 'output_helper.dart';
import 'end2end_data.dart';

main() {
  performTests(TEST_DATA, unittester, checkResult);
}

checkResult(TestSpec result) {
  String input = result.input;
  String expectedOutput = result.output.trim();

  CollectingOutputProvider outputProvider = new CollectingOutputProvider();
  MemoryResourceProvider provider = new MemoryResourceProvider();
  DartSdk sdk = new MockSdk();
  Driver driver = new Driver(provider, sdk, outputProvider);
  String rootFile = '/root.dart';
  provider.newFile(rootFile, input);
  Source rootSource = driver.setRoot(rootFile);
  FunctionElement entryPoint = driver.resolveEntryPoint(rootSource);
  ClosedWorld world = driver.computeWorld(entryPoint);
  ConvertedWorld convertedWorld = convertWorld(world);
  compileToDart(driver, convertedWorld);
  String output = outputProvider.output.text.trim();
  expect(output, equals(expectedOutput));
}
