// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';

/// Scopes are used to resolve names to elements.
abstract class Scope {
  /// Return the element with the name `id` or `id=` (if [setter] is `true`),
  /// `null` if the name is not defined within this scope.
  @Deprecated('Use lookup2() that is closer to the language specification')
  Element lookup({@required String id, @required bool setter});

  /// Return the result of lexical lookup for the given [id], not `null`.
  ///
  /// Getters and setters are bundled, when we found one or another, we are
  /// done with the lookup, and return both the getter and the setter, if
  /// available.
  ScopeLookupResult lookup2(String id);
}

class ScopeLookupResult {
  final Element getter;
  final Element setter;

  ScopeLookupResult(this.getter, this.setter);
}
