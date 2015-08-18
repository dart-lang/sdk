// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.strong_mode;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * An object used to find static variables whose types should be inferred and
 * classes whose members should have types inferred. Clients are expected to
 * visit a [CompilationUnit].
 */
class InferrenceFinder extends SimpleAstVisitor {
  /**
   * The static variables that should have types inferred for them.
   */
  final List<VariableElement> staticVariables = <VariableElement>[];

  /**
   * The classes defined in the unit.
   *
   * TODO(brianwilkerson) We don't currently remove classes whose members do not
   * need to be processed, but we potentially could.
   */
  final List<ClassElement> classes = <ClassElement>[];

  /**
   * Initialize a newly created finder.
   */
  InferrenceFinder();

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    classes.add(node.element);
    for (ClassMember member in node.members) {
      member.accept(this);
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    classes.add(node.element);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (CompilationUnitMember declaration in node.declarations) {
      declaration.accept(this);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic && node.fields.type == null) {
      _addVariables(node.fields.variables);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.type == null) {
      _addVariables(node.variables.variables);
    }
  }

  /**
   * Add all of the [variables] with initializers to the list of variables whose
   * type can be inferred. Technically, we only infer the types of variables
   * that do not have a static type, but all variables with initializers
   * potentially need to be re-resolved after inference because they might
   * refer to fields whose type was inferred.
   */
  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      if (variable.initializer != null) {
        staticVariables.add(variable.element);
      }
    }
  }
}
