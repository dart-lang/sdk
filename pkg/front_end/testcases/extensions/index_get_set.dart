// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class HasNone {}

class HasIndexGet {
  operator [](_) {}
}

class HasIndexSet {
  operator []=(_, _) {}
}

class HasIndexGetSet {
  operator [](_) {}
  operator []=(_, _) {}
}

extension HasNoneExtension on HasNone {
  operator [](_) {}
  operator []=(_, _) {}
}

extension HasIndexGetExtension on HasIndexGet {
  operator [](_) {}
  operator []=(_, _) {}
}

extension HasIndexSetExtension on HasIndexSet {
  operator [](_) {}
  operator []=(_, _) {}
}

extension HasIndexGetSetExtension on HasIndexGetSet {
  operator [](_) {}
  operator []=(_, _) {}
}

implicit(
  HasNone hasNone,
  HasIndexGet hasIndexGet,
  HasIndexSet hasIndexSet,
  HasIndexGetSet hasIndexGetSet,
) {
  hasNone[0]; // Ok
  hasNone[0] = 0; // Ok

  hasIndexGet[0]; // Ok
  hasIndexGet[0] = 0; // Error

  hasIndexSet[0]; // Error
  hasIndexSet[0] = 0; // Ok

  hasIndexGetSet[0]; // Ok
  hasIndexGetSet[0] = 0; // Ok
}

explicit(
  HasNone hasNone,
  HasIndexGet hasIndexGet,
  HasIndexSet hasIndexSet,
  HasIndexGetSet hasIndexGetSet,
) {
  HasNoneExtension(hasNone)[0]; // Ok
  HasNoneExtension(hasNone)[0] = 0; // Ok

  HasIndexGetExtension(hasIndexGet)[0]; // Ok
  HasIndexGetExtension(hasIndexGet)[0] = 0; // Ok

  HasIndexSetExtension(hasIndexSet)[0]; // Ok
  HasIndexSetExtension(hasIndexSet)[0] = 0; // Ok

  HasIndexGetSetExtension(hasIndexGetSet)[0]; // Ok
  HasIndexGetSetExtension(hasIndexGetSet)[0] = 0; // Ok
}
