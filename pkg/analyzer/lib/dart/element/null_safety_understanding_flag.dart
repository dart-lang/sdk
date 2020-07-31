// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Every [DartType] has the nullability suffix, elements declared in legacy
/// libraries have types with star suffixes, and types in migrated libraries
/// have none, question mark, or star suffixes.  Analyzer itself can handle
/// mixtures of nullabilities with legacy and migrated libraries.
///
/// However analyzer clients saw only star suffixes so far.  Exposing other
/// nullabilities is a breaking change, because types types with different
/// nullabilities are not equal, `null` cannot be used where a non-nullable
/// type is expected, etc.  When accessing elements and types that come from
/// migrated libraries, while analyzing a legacy library, nullabilities must
/// be erased, using [LibraryElement.toLegacyElementIfOptOut] and
/// [LibraryElement.toLegacyTypeIfOptOut].  The client must explicitly do
/// this, and explicitly specify that it knows how to handle nullabilities
/// by setting this flag to `true`.
///
/// When this flag is `false` (by default), all types will return their
/// nullability as star.  So, type equality and subtype checks will work
/// as they worked before some libraries migrated.  Note, that during
/// analysis (building element models, and resolving ASTs), analyzer will use
/// actual nullabilities, according to the language specification, so report
/// all corresponding errors, and perform necessary type operations.  It is
/// only when the client later views on the types, they will look as legacy.
class NullSafetyUnderstandingFlag {
  static final _zoneKey = Object();

  static bool get isEnabled {
    return Zone.current[_zoneKey] ?? false;
  }

  /// Code that understands nullability should be run using this method,
  /// otherwise all type operations will treat all nullabilities as star.
  static R enableNullSafetyTypes<R>(R Function() body) {
    return runZoned<R>(body, zoneValues: {_zoneKey: true});
  }
}
