// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/source.dart';

/**
 * Information about a single top-level declaration.
 */
class TopLevelDeclaration {
  final TopLevelDeclarationKind kind;
  final String name;

  TopLevelDeclaration(this.kind, this.name);

  @override
  String toString() => '($kind, $name)';
}

/**
 * A declaration in a source.
 */
class TopLevelDeclarationInSource {
  /**
   * The declaring source.
   */
  final Source source;

  /**
   * The declaration.
   */
  final TopLevelDeclaration declaration;

  /**
   * Is `true` if the [declaration] is exported, not declared in the [source].
   */
  final bool isExported;

  TopLevelDeclarationInSource(this.source, this.declaration, this.isExported);

  @override
  String toString() => '($source, $declaration, $isExported)';
}

/**
 * Kind of a top-level declaration.
 *
 * We don't need it to be precise, just enough to support quick fixes.
 */
enum TopLevelDeclarationKind { type, function, variable }
