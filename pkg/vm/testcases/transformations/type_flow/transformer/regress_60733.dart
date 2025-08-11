// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/60733.
// Verifies that intersection of a wide cone with an empty cone
// results in empty type.

// This test assumes the following low thresholds:
// maxAllocatedTypesInSetSpecialization = 4,

class Widget {}

class W1 implements Widget {}

class W2 implements Widget {}

class W3 implements Widget {}

class W4 implements Widget {}

class W5 implements Widget {}

class _HasCreationLocation {
  Object? get location => 'hey';
}

Object? _getObjectCreationLocation(Object object) {
  return object is _HasCreationLocation ? object.location : null;
}

final widgets = <Widget>[W1(), W2(), W3(), W4(), W5()];

void main() {
  for (Widget w in widgets) {
    print(_getObjectCreationLocation(w));
  }
}
