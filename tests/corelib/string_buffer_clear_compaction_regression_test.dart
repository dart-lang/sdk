// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

const int _iterations = 10000;

void _writeFooBar(StringBuffer buffer) {
  for (int i = 0; i < _iterations; i++) {
    buffer.write(i.isEven ? "foo" : "bar");
    buffer.write(" ");
  }
}

Symbol _privateSymbol(InstanceMirror mirror, String fieldName) {
  final owner = mirror.type.owner;
  if (owner is! LibraryMirror) {
    throw StateError(
      "Expected StringBuffer owner to be LibraryMirror, got $owner",
    );
  }
  return MirrorSystem.getSymbol(fieldName, owner);
}

T _readPrivateField<T>(Object object, String fieldName) {
  final mirror = reflect(object);
  return mirror.getField(_privateSymbol(mirror, fieldName)).reflectee as T;
}

int _leadingNonCompactedPrefixLength(List<String> parts) {
  int prefixLength = 0;
  for (final part in parts) {
    if (part.length <= 4) {
      prefixLength++;
      continue;
    }
    break;
  }
  return prefixLength;
}

void main() {
  final buffer = StringBuffer();

  _writeFooBar(buffer);
  buffer.clear();

  Expect.equals(0, _readPrivateField<int>(buffer, "_partsCompactionIndex"));
  Expect.equals(
    0,
    _readPrivateField<int>(buffer, "_partsCodeUnitsSinceCompaction"),
  );

  _writeFooBar(buffer);
  final parts = _readPrivateField<List<String>?>(buffer, "_parts");
  Expect.isNotNull(parts);
  final leadingPrefixLength = _leadingNonCompactedPrefixLength(parts!);
  Expect.isTrue(
    leadingPrefixLength < 16,
    "Unexpected large uncompacted prefix in _parts: $leadingPrefixLength",
  );
}
