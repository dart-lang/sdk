// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.closedWorld;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * Container for the elements and AST nodes which have been determined by
 * tree shaking to be reachable by the program being compiled.
 */
class ClosedWorld {
  // TODO(paulberry): is it a problem to hold on to all the AST's for the
  // duration of tree shaking & CPS generation?

  /**
   * Methods, toplevel functions, etc. that are reachable.
   */
  Map<ExecutableElement, Declaration> executableElements =
      new HashMap<ExecutableElement, Declaration>();

  /**
   * Fields that are reachable.
   */
  Map<FieldElement, VariableDeclaration> fields =
      new HashMap<FieldElement, VariableDeclaration>();

  /**
   * Classes that are instantiated from reachable code.
   *
   * TODO(paulberry): Also keep track of classes that are reachable but not
   * instantiated (because they are extended or mixed in)
   */
  Map<ClassElement, ClassDeclaration> instantiatedClasses =
      new HashMap<ClassElement, ClassDeclaration>();

  ClosedWorld();
}
