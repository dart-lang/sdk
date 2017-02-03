// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/**
 * Provider for resolved and unresolved [CompilationUnit]s that contain, or
 * [AstNode]s that declare [Element]s.
 */
abstract class AstProvider {
  AstNode findNodeForElement(CompilationUnit unit, Element element);

  /**
   * Completes with the parsed [AstNode] that declares the [element].
   */
  Future<T> getParsedNodeForElement<T extends AstNode>(Element element);

  /**
   * Completes with the parsed [CompilationUnit] that contains the [element].
   */
  Future<CompilationUnit> getParsedUnitForElement(Element element);

  /**
   * Completes with the resolved [AstNode] that declares the [element].
   */
  Future<T> getResolvedNodeForElement<T extends AstNode>(Element element);

  /**
   * Completes with the resolved [CompilationUnit] that contains the [element].
   */
  Future<CompilationUnit> getResolvedUnitForElement(Element element);
}
