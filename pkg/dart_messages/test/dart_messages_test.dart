// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../lib/shared_messages.dart';

void testJsonIsUpdated() {
  var packageRoot = Platform.packageRoot;
  if (packageRoot == null || packageRoot == "") {
    throw new UnsupportedError("This test requires a package root.");
  }
  var jsonUri =
      Uri.parse(packageRoot).resolve('dart_messages/shared_messages.json');
  var jsonPath = jsonUri.toFilePath();
  var content = new File(jsonPath).readAsStringSync();
  if (JSON.encode(MESSAGES) != content) {
    print("The content of the Dart messages and the corresponding JSON file");
    print("is not the same.");
    print("Please run bin/json_converter to update the JSON file.");
    throw "Content is not the same";
  }
}

void testIdsAreUnique() {
  var usedIds = new Set();
  for (var entry in MESSAGES.values) {
    var id = entry['id'];
    if (!usedIds.add(id)) {
      throw "Id appears twice: $id";
    }
  }
}

void main() {
  testJsonIsUpdated();
  testIdsAreUnique();
}
