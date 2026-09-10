// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that private symbol literals in different libraries are not equal
// or identical, according to Dart Spec §16.11.

import 'package:expect/expect.dart';

import 'private_symbol_literal_lib.dart';

const mainPrivateSymbol = #_private;

Symbol getMainPrivateSymbol() => #_private;

void main() {
  // Identical within the same library.
  Expect.identical(mainPrivateSymbol, getMainPrivateSymbol());
  Expect.equals(mainPrivateSymbol, getMainPrivateSymbol());

  Expect.identical(libraryPrivateSymbol, getLibraryPrivateSymbol());
  Expect.equals(libraryPrivateSymbol, getLibraryPrivateSymbol());

  // Different libraries must NOT be equal or identical.
  Expect.notEquals(mainPrivateSymbol, libraryPrivateSymbol);
  Expect.isFalse(identical(mainPrivateSymbol, libraryPrivateSymbol));

  Expect.notEquals(getMainPrivateSymbol(), getLibraryPrivateSymbol());
  Expect.isFalse(identical(getMainPrivateSymbol(), getLibraryPrivateSymbol()));

  // Map key lookups distinguish between private symbols from different libraries.
  var map = {mainPrivateSymbol: 'main', libraryPrivateSymbol: 'lib'};
  Expect.equals(2, map.length);
  Expect.equals('main', map[mainPrivateSymbol]);
  Expect.equals('lib', map[libraryPrivateSymbol]);

  // Set entries distinguish between private symbols from different libraries.
  var set = {mainPrivateSymbol, libraryPrivateSymbol};
  Expect.equals(2, set.length);
}
