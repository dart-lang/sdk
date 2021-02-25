// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:meta/meta.dart';

/// Helper for [MethodInvocation]s into [InstanceCreationExpression] to support
/// the optional `new` and `const` feature, or [ExtensionOverride].
class AstRewriter {
  final ErrorReporter _errorReporter;

  AstRewriter(this._errorReporter);

  AstNode methodInvocation(Scope nameScope, MethodInvocation node) {
    SimpleIdentifier methodName = node.methodName;
    if (methodName.isSynthetic) {
      // This isn't a constructor invocation because the method name is
      // synthetic.
      return node;
    }

    Expression target = node.target;
    if (target == null) {
      // Possible cases: C() or C<>()
      if (node.realTarget != null) {
        // This isn't a constructor invocation because it's in a cascade.
        return node;
      }
      Element element = nameScope.lookup(methodName.name).getter;
      if (element is ClassElement) {
        return _toInstanceCreation_type(
          node: node,
          typeIdentifier: methodName,
        );
      } else if (element is ExtensionElement) {
        ExtensionOverride extensionOverride = astFactory.extensionOverride(
            extensionName: methodName,
            typeArguments: node.typeArguments,
            argumentList: node.argumentList);
        NodeReplacer.replace(node, extensionOverride);
        return extensionOverride;
      } else if (element is TypeAliasElement &&
          element.aliasedType is InterfaceType) {
        return _toInstanceCreation_type(
          node: node,
          typeIdentifier: methodName,
        );
      }
    } else if (target is SimpleIdentifier) {
      // Possible cases: C.n(), p.C() or p.C<>()
      if (node.isNullAware) {
        // This isn't a constructor invocation because a null aware operator is
        // being used.
      }
      Element element = nameScope.lookup(target.name).getter;
      if (element is ClassElement) {
        // class C { C.named(); }
        // C.named()
        return _toInstanceCreation_type_constructor(
          node: node,
          typeIdentifier: target,
          constructorIdentifier: methodName,
          classElement: element,
        );
      } else if (element is PrefixElement) {
        // Possible cases: p.C() or p.C<>()
        Element prefixedElement = element.scope.lookup(methodName.name).getter;
        if (prefixedElement is ClassElement) {
          return _toInstanceCreation_prefix_type(
            node: node,
            prefixIdentifier: target,
            typeIdentifier: methodName,
          );
        } else if (prefixedElement is ExtensionElement) {
          PrefixedIdentifier extensionName =
              astFactory.prefixedIdentifier(target, node.operator, methodName);
          ExtensionOverride extensionOverride = astFactory.extensionOverride(
              extensionName: extensionName,
              typeArguments: node.typeArguments,
              argumentList: node.argumentList);
          NodeReplacer.replace(node, extensionOverride);
          return extensionOverride;
        } else if (prefixedElement is TypeAliasElement &&
            prefixedElement.aliasedType is InterfaceType) {
          return _toInstanceCreation_prefix_type(
            node: node,
            prefixIdentifier: target,
            typeIdentifier: methodName,
          );
        }
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          // class C { C.named(); }
          // typedef X = C;
          // X.named()
          return _toInstanceCreation_type_constructor(
            node: node,
            typeIdentifier: target,
            constructorIdentifier: methodName,
            classElement: aliasedType.element,
          );
        }
      }
    } else if (target is PrefixedIdentifier) {
      // Possible case: p.C.n()
      var prefixElement = nameScope.lookup(target.prefix.name).getter;
      target.prefix.staticElement = prefixElement;
      if (prefixElement is PrefixElement) {
        var prefixedName = target.identifier.name;
        var element = prefixElement.scope.lookup(prefixedName).getter;
        if (element is ClassElement) {
          return _instanceCreation_prefix_type_name(
            node: node,
            typeNameIdentifier: target,
            constructorIdentifier: methodName,
            classElement: element,
          );
        } else if (element is TypeAliasElement) {
          var aliasedType = element.aliasedType;
          if (aliasedType is InterfaceType) {
            return _instanceCreation_prefix_type_name(
              node: node,
              typeNameIdentifier: target,
              constructorIdentifier: methodName,
              classElement: aliasedType.element,
            );
          }
        }
      }
    }
    return node;
  }

  AstNode _instanceCreation_prefix_type_name({
    @required MethodInvocation node,
    @required PrefixedIdentifier typeNameIdentifier,
    @required SimpleIdentifier constructorIdentifier,
    @required ClassElement classElement,
  }) {
    var constructorElement = classElement.getNamedConstructor(
      constructorIdentifier.name,
    );
    if (constructorElement == null) {
      return node;
    }

    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [classElement.name, constructorElement.name]);
    }

    var typeName = astFactory.typeName(typeNameIdentifier, typeArguments);
    var constructorName = astFactory.constructorName(
        typeName, node.operator, constructorIdentifier);
    var instanceCreationExpression = astFactory.instanceCreationExpression(
        null, constructorName, node.argumentList);
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  InstanceCreationExpression _toInstanceCreation_prefix_type({
    @required MethodInvocation node,
    @required SimpleIdentifier prefixIdentifier,
    @required SimpleIdentifier typeIdentifier,
  }) {
    var typeName = astFactory.typeName(
        astFactory.prefixedIdentifier(
            prefixIdentifier, node.operator, typeIdentifier),
        node.typeArguments);
    var constructorName = astFactory.constructorName(typeName, null, null);
    var instanceCreationExpression = astFactory.instanceCreationExpression(
        null, constructorName, node.argumentList);
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  InstanceCreationExpression _toInstanceCreation_type({
    @required MethodInvocation node,
    @required SimpleIdentifier typeIdentifier,
  }) {
    var typeName = astFactory.typeName(typeIdentifier, node.typeArguments);
    var constructorName = astFactory.constructorName(typeName, null, null);
    var instanceCreationExpression = astFactory.instanceCreationExpression(
        null, constructorName, node.argumentList);
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  AstNode _toInstanceCreation_type_constructor({
    @required MethodInvocation node,
    @required SimpleIdentifier typeIdentifier,
    @required SimpleIdentifier constructorIdentifier,
    @required ClassElement classElement,
  }) {
    var name = constructorIdentifier.name;
    var constructorElement = classElement.getNamedConstructor(name);
    if (constructorElement == null) {
      return node;
    }

    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [classElement.name, constructorElement.name]);
    }
    var typeName = astFactory.typeName(typeIdentifier, null);
    var constructorName = astFactory.constructorName(
        typeName, node.operator, constructorIdentifier);
    // TODO(scheglov) I think we should drop "typeArguments" below.
    var instanceCreationExpression = astFactory.instanceCreationExpression(
        null, constructorName, node.argumentList,
        typeArguments: typeArguments);
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }
}
