// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

/// Base class for visitor used in rules where we want to lint about invoking
/// methods on generic classes where the type of the singular argument is
/// unrelated to the singular type argument of the class. Extending this
/// visitor is as simple as knowing the method, class and library that uniquely
/// define the target, i.e. implement only [interface] and [methodName].
abstract class UnrelatedTypesProcessors extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;
  final TypeProvider typeProvider;

  UnrelatedTypesProcessors(this.rule, this.typeSystem, this.typeProvider);

  /// The type definition which this [UnrelatedTypesProcessors] is concerned
  /// with.
  InterfaceElement get interface;

  /// The name of the method which this [UnrelatedTypesProcessors] is concerned
  /// with.
  String get methodName;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList.arguments.length != 1) {
      return;
    }
    if (node.methodName.name != methodName) {
      return;
    }

    // At this point, we know that [node] is an invocation of a method which
    // has the same name as the method that this [UnrelatedTypesProcessors] is
    // concerned with, and that the method call has a single argument.
    //
    // We've completed the "cheap" checks, and must now continue with the
    // arduous task of determining whether the method target implements
    // [definition].

    DartType? targetType;
    var target = node.realTarget;
    if (target != null) {
      targetType = target.staticType;
    } else {
      for (AstNode? parent = node; parent != null; parent = parent.parent) {
        if (parent is ClassDeclaration) {
          targetType = parent.declaredElement?.thisType;
          break;
        } else if (parent is MixinDeclaration) {
          targetType = parent.declaredElement?.thisType;
          break;
        } else if (parent is EnumDeclaration) {
          targetType = parent.declaredElement?.thisType;
          break;
        } else if (parent is ExtensionDeclaration) {
          targetType = parent.extendedType.type;
          break;
        }
      }
    }

    if (targetType is! InterfaceType) {
      return;
    }

    var collectionType = targetType.asInstanceOf(interface);
    if (collectionType == null) {
      return;
    }

    // Finally, determine whether the type of the argument is related to the
    // type of the method target.
    var argumentType = node.argumentList.arguments.first.staticType;

    var typeArgument = collectionType.typeArguments.first;
    if (typesAreUnrelated(typeSystem, argumentType, typeArgument)) {
      rule.reportLint(node,
          arguments: [typeArgument.getDisplayString(withNullability: true)]);
    }
  }
}
