// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:dart_messages/shared_messages.dart';

void testJsonIsUpdated() {
  var packageRoot = io.Platform.packageRoot;
  if (packageRoot == null || packageRoot == "") {
    throw new UnsupportedError("This test requires a package root.");
  }
  var jsonUri = Uri
      .parse(packageRoot)
      .resolve('dart_messages/generated/shared_messages.json');
  var jsonPath = jsonUri.toFilePath();
  var content = new io.File(jsonPath).readAsStringSync();
  if (messagesAsJson != content) {
    print("The content of the Dart messages and the corresponding JSON file");
    print("is not the same.");
    print("Please run bin/publish.dart to update the JSON file.");
    throw "Content is not the same";
  }
}

void testIdsAreUnique() {
  var usedIds = new Set();
  for (var entry in MESSAGES.values) {
    var id = "${entry.id}-${entry.subId}";
    if (!usedIds.add(id)) {
      throw "Id appears twice: $id";
    }
  }
}

void testSpecializationsAreOfSameId() {
  for (var entry in MESSAGES.values) {
    var specializationOf = entry.specializationOf;
    if (specializationOf == null) continue;
    var generic = MESSAGES[specializationOf];
    if (generic == null) {
      throw "More generic message doesn't exist: $specializationOf";
    }
    if (generic.id != entry.id) {
      var id = "${entry.id}-${entry.subId}";
      var genericId = "${generic.id}-${generic.subId}";
      throw "Specialization doesn't have same id: $id - $genericId";
    }
  }
}

void main() {
  testJsonIsUpdated();
  testIdsAreUnique();
  testSpecializationsAreOfSameId();
}
