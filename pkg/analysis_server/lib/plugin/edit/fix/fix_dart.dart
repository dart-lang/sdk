// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';

/**
 * Complete with top-level declarations with the given [name].
 */
typedef Future<List<TopLevelDeclarationInSource>> GetTopLevelDeclarations(
    String name);

/**
 * An object used to provide context information for [DartFixContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFixContext implements FixContext {
  /**
   * The provider for parsed or resolved ASTs.
   */
  AstProvider get astProvider;

  /**
   * The function to get top-level declarations from.
   */
  GetTopLevelDeclarations get getTopLevelDeclarations;

  /**
   * The [CompilationUnit] to compute fixes in.
   */
  CompilationUnit get unit;
}
