// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

/**
 * Provider for resolved and unresolved [CompilationUnit]s that contain, or
 * [AstNode]s that declare [Element]s.
 */
abstract class AstProvider {
  /**
   * Return the driver that is used to provide ASTs.
   */
  AnalysisDriver get driver;

  /**
   * Completes with the [SimpleIdentifier] that declares the [element]. The
   * enclosing unit is only parsed, but not resolved. Completes with `null` if
   * the [element] is synthetic, or the file where it is declared cannot be
   * parsed, etc.
   */
  Future<SimpleIdentifier> getParsedNameForElement(Element element);

  /**
   * Completes with the parsed [CompilationUnit] that contains the [element].
   */
  Future<CompilationUnit> getParsedUnitForElement(Element element);

  /**
   * Completes with the [SimpleIdentifier] that declares the [element]. The
   * enclosing unit is fully resolved. Completes with `null` if the [element]
   * is synthetic, or the file where it is declared cannot be parsed and
   * resolved, etc.
   */
  Future<SimpleIdentifier> getResolvedNameForElement(Element element);

  /**
   * Completes with the resolved [CompilationUnit] that contains the [element].
   */
  Future<CompilationUnit> getResolvedUnitForElement(Element element);
}
