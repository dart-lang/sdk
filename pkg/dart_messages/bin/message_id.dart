// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:dart_messages/shared_messages.dart' as shared_messages;

math.Random random = new math.Random();

const idLength = 6;
final $A = "A".codeUnitAt(0);
final $Z = "Z".codeUnitAt(0);

String computeId() {
  List<int> charCodes = [];
  for (int i = 0; i < idLength; i++) {
    charCodes.add($A + random.nextInt($Z - $A));
  }
  return new String.fromCharCodes(charCodes);
}

/// Computes a random message ID that hasn't been used before.
void main() {
  var usedIds =
      shared_messages.MESSAGES.values.map((entry) => entry.id).toSet();

  print("${usedIds.length} existing ids");

  var newId;
  do {
    newId = computeId();
  } while (usedIds.contains(newId));
  print("Available id: $newId");
}
