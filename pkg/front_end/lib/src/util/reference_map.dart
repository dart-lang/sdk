// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';

/// Map for builders created with a reference from a previous step in an
/// incremental compilation.
///
/// This is used for looking up source builders when finalizing
/// exports in dill builders, and for computing [TypeBuilder]s from dill that
/// refer to classes or extension types corresponding to source builders.
class ReferenceMap {
  final Map<Reference, NamedBuilder> _map = {};

  /// Registers that [builder] has being created with [reference]
  void registerNamedBuilder(Reference reference, NamedBuilder builder) {
    _map[reference] = builder;
  }

  /// Returns the [NamedBuilder] corresponding to [reference], if any.
  NamedBuilder? lookupNamedBuilder(Reference reference) => _map[reference];

  /// Returns the [ClassBuilder] corresponding to [reference], if any.
  ClassBuilder? lookupClassBuilder(Reference reference) {
    NamedBuilder? builder = _map[reference];
    if (builder is ClassBuilder) {
      return builder;
    }
    return null;
  }

  /// Returns the [ExtensionTypeDeclarationBuilder] corresponding to
  /// [reference], if any.
  ExtensionTypeDeclarationBuilder? lookupExtensionTypeDeclarationBuilder(
      Reference reference) {
    NamedBuilder? builder = _map[reference];
    if (builder is ExtensionTypeDeclarationBuilder) {
      return builder;
    }
    return null;
  }

  /// Clears the map.
  ///
  /// This is done in preparation for a new incremental compilation step.
  void clear() {
    _map.clear();
  }
}
