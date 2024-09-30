// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:collection/collection.dart';

/// Lists files yet to be migrated to the new element model.
main() async {
  print('Unmigrated files:\n\n');
  // (Start w/ rules.)
  for (var rule in ruleFiles) {
    if (!migratedFiles.contains(rule)) {
      print(rule);
    }
  }
}

List<String> get migratedFiles =>
    File('analyzer_use_new_elements.txt').readAsLinesSync();

List<String> get ruleFiles =>
    Directory('lib/src/rules').listSync().map((r) => r.path).sorted();
