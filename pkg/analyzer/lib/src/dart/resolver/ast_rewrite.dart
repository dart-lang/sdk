// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// A visitor that will re-write an AST to support the optional `new` and
/// `const` feature.
class AstRewriteVisitor extends ScopedVisitor {
  final TypeSystem typeSystem;

  /// Initialize a newly created visitor.
  AstRewriteVisitor(
      this.typeSystem,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    SimpleIdentifier methodName = node.methodName;
    if (methodName.isSynthetic) {
      // This isn't a constructor invocation because the method name is
      // synthetic.
      return;
    }

    Expression target = node.target;
    if (target == null) {
      // Possible cases: C() or C<>()
      if (node.realTarget != null) {
        // This isn't a constructor invocation because it's in a cascade.
        return;
      }
      Element element = nameScope.lookup(methodName, definingLibrary);
      if (element is ClassElement) {
        TypeName typeName = astFactory.typeName(methodName, node.typeArguments);
        ConstructorName constructorName =
            astFactory.constructorName(typeName, null, null);
        InstanceCreationExpression instanceCreationExpression =
            astFactory.instanceCreationExpression(
                null, constructorName, node.argumentList);
        NodeReplacer.replace(node, instanceCreationExpression);
      } else if (element is ExtensionElement) {
        ExtensionOverride extensionOverride = astFactory.extensionOverride(
            extensionName: methodName,
            typeArguments: node.typeArguments,
            argumentList: node.argumentList);
        NodeReplacer.replace(node, extensionOverride);
      }
    } else if (target is SimpleIdentifier) {
      // Possible cases: C.n(), p.C() or p.C<>()
      if (node.isNullAware) {
        // This isn't a constructor invocation because a null aware operator is
        // being used.
      }
      Element element = nameScope.lookup(target, definingLibrary);
      if (element is ClassElement) {
        // Possible case: C.n()
        var constructorElement = element.getNamedConstructor(methodName.name);
        if (constructorElement != null) {
          var typeArguments = node.typeArguments;
          if (typeArguments != null) {
            errorReporter.reportErrorForNode(
                StaticTypeWarningCode
                    .WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
                typeArguments,
                [element.name, constructorElement.name]);
          }
          TypeName typeName = astFactory.typeName(target, null);
          ConstructorName constructorName =
              astFactory.constructorName(typeName, node.operator, methodName);
          // TODO(scheglov) I think we should drop "typeArguments" below.
          InstanceCreationExpression instanceCreationExpression =
              astFactory.instanceCreationExpression(
                  null, constructorName, node.argumentList,
                  typeArguments: typeArguments);
          NodeReplacer.replace(node, instanceCreationExpression);
        }
      } else if (element is PrefixElement) {
        // Possible cases: p.C() or p.C<>()
        Identifier identifier = astFactory.prefixedIdentifier(
            astFactory.simpleIdentifier(target.token),
            null,
            astFactory.simpleIdentifier(methodName.token));
        Element prefixedElement = nameScope.lookup(identifier, definingLibrary);
        if (prefixedElement is ClassElement) {
          TypeName typeName = astFactory.typeName(
              astFactory.prefixedIdentifier(target, node.operator, methodName),
              node.typeArguments);
          ConstructorName constructorName =
              astFactory.constructorName(typeName, null, null);
          InstanceCreationExpression instanceCreationExpression =
              astFactory.instanceCreationExpression(
                  null, constructorName, node.argumentList);
          NodeReplacer.replace(node, instanceCreationExpression);
        } else if (prefixedElement is ExtensionElement) {
          PrefixedIdentifier extensionName =
              astFactory.prefixedIdentifier(target, node.operator, methodName);
          ExtensionOverride extensionOverride = astFactory.extensionOverride(
              extensionName: extensionName,
              typeArguments: node.typeArguments,
              argumentList: node.argumentList);
          NodeReplacer.replace(node, extensionOverride);
        }
      }
    } else if (target is PrefixedIdentifier) {
      // Possible case: p.C.n()
      Element prefixElement = nameScope.lookup(target.prefix, definingLibrary);
      target.prefix.staticElement = prefixElement;
      if (prefixElement is PrefixElement) {
        Element element = nameScope.lookup(target, definingLibrary);
        if (element is ClassElement) {
          var constructorElement = element.getNamedConstructor(methodName.name);
          if (constructorElement != null) {
            var typeArguments = node.typeArguments;
            if (typeArguments != null) {
              errorReporter.reportErrorForNode(
                  StaticTypeWarningCode
                      .WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
                  typeArguments,
                  [element.name, constructorElement.name]);
            }
            TypeName typeName = astFactory.typeName(target, typeArguments);
            ConstructorName constructorName =
                astFactory.constructorName(typeName, node.operator, methodName);
            InstanceCreationExpression instanceCreationExpression =
                astFactory.instanceCreationExpression(
                    null, constructorName, node.argumentList);
            NodeReplacer.replace(node, instanceCreationExpression);
          }
        }
      }
    }
  }
}
