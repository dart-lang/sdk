// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Scopes are used to resolve names to elements.
///
/// Clients may not extend, implement or mix-in this class.
abstract class Scope {
  /// Return the result of lexical lookup for the given [id], not `null`.
  ///
  /// Getters and setters are bundled, when we found one or another, we are
  /// done with the lookup, and return both the getter and the setter, if
  /// available.
  ScopeLookupResult lookup(String id);
}

/// The result of a single name lookup.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ScopeLookupResult {
  Element? get getter => getter2?.asElement;
  Element2? get getter2;

  Element? get setter => setter2?.asElement;

  Element2? get setter2;
}
