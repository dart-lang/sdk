// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'model.dart';

/// Returns the [DynamicModuleTest] associated with a folder under [uri].
DynamicModuleTest loadTest(Uri uri) {
  var folder = Directory.fromUri(uri);
  var testUri = folder.uri; // normalized in case the trailing '/' was missing.
  final name = testUri.pathSegments.lastWhere((s) => s.isNotEmpty);
  String? main;
  String? interface;
  final dynamicModules = <String, String>{};
  for (var entry in folder.listSync(recursive: true)) {
    var entryUri = entry.uri;
    if (entry is! File) continue;
    var filePath = entryUri.path.substring(testUri.path.length);

    if (filePath == 'dynamic_interface.yaml') {
      interface = filePath;
      continue;
    }

    if (!filePath.endsWith('.dart')) continue;
    if (filePath == 'main.dart') {
      main = filePath;
    } else if (filePath.startsWith('modules/entry')) {
      var moduleName = filePath.substring('modules/'.length);
      assert(!dynamicModules.containsKey(moduleName));
      dynamicModules[moduleName] = filePath;
    }
  }

  // Validate the test is well structured
  if (main == null) {
    throw UnsupportedError("missing main.dart entrypoint in '$name'");
  }
  if (interface == null) {
    throw UnsupportedError("missing dynamic_interface.yaml in '$name'");
  }
  if (dynamicModules.isEmpty) {
    throw UnsupportedError("no dynamic modules found in '$name'");
  }
  return DynamicModuleTest(name, testUri, main, interface, dynamicModules);
}

/// Returns all [DynamicModuleTests]s under [uri], one per subfolder.
List<DynamicModuleTest> loadAllTests(Uri uri) {
  var folder = Directory.fromUri(uri);
  final result = <DynamicModuleTest>[];
  for (var entry in folder.listSync(recursive: false)) {
    if (entry is! Directory) continue;
    result.add(loadTest(entry.uri));
  }
  return result;
}
