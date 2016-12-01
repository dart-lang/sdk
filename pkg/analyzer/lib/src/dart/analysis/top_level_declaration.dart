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
}

/**
 * Kind of a top-level declaration.
 *
 * We don't need it to be precise, just enough to support quick fixes.
 */
enum TopLevelDeclarationKind { type, function, variable }

/**
 * Top-level declarations in the export namespace of a library.
 */
class TopLevelLibraryDeclarations {
  /**
   * The source of the library.
   */
  final Source source;

  /**
   * Top-level declarations in the export namespace of the library.
   */
  final List<TopLevelDeclaration> declarations = [];

  TopLevelLibraryDeclarations(this.source);
}
