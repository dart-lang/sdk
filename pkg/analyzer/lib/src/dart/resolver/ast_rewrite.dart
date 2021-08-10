// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/error/codes.dart';

/// Helper for [MethodInvocation]s into [InstanceCreationExpression] to support
/// the optional `new` and `const` feature, or [ExtensionOverride].
class AstRewriter {
  final ErrorReporter _errorReporter;

  AstRewriter(this._errorReporter);

  /// Possibly rewrites [node] as an [ExtensionOverride] or as an
  /// [InstanceCreationExpression].
  AstNode methodInvocation(Scope nameScope, MethodInvocation node) {
    SimpleIdentifier methodName = node.methodName;
    if (methodName.isSynthetic) {
      // This isn't a constructor invocation because the method name is
      // synthetic.
      return node;
    }

    var target = node.target;
    if (target == null) {
      // Possible cases: C() or C<>()
      if (node.realTarget != null) {
        // This isn't a constructor invocation because it's in a cascade.
        return node;
      }
      var element = nameScope.lookup(methodName.name).getter;
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
      var element = nameScope.lookup(target.name).getter;
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
        var prefixedElement = element.scope.lookup(methodName.name).getter;
        if (prefixedElement is ClassElement) {
          return _toInstanceCreation_prefix_type(
            node: node,
            prefixIdentifier: target,
            typeIdentifier: methodName,
          );
        } else if (prefixedElement is ExtensionElement) {
          PrefixedIdentifier extensionName =
              astFactory.prefixedIdentifier(target, node.operator!, methodName);
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
    } else if (target is PrefixedIdentifierImpl) {
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

  /// Possibly rewrites [node] as a [ConstructorReference].
  AstNode prefixedIdentifier(Scope nameScope, PrefixedIdentifier node) {
    if (node.parent is Annotation) {
      // An annotations which is a const constructor invocation can initially be
      // represented with a [PrefixedIdentifier]. Do not rewrite such nodes.
      return node;
    }
    if (node.parent is CommentReference) {
      // TODO(srawlins): This probably should be rewritten to a
      // [ConstructorReference] at some point.
      return node;
    }
    var identifier = node.identifier;
    if (identifier.isSynthetic) {
      // This isn't a constructor reference.
      return node;
    }
    var prefix = node.prefix;
    var element = nameScope.lookup(prefix.name).getter;
    if (element is ClassElement) {
      // Example:
      //     class C { C.named(); }
      //     C.named
      return _toConstructorReference_prefixed(
          node: node, classElement: element);
    } else if (element is TypeAliasElement) {
      var aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        // Example:
        //     class C { C.named(); }
        //     typedef X = C;
        //     X.named
        return _toConstructorReference_prefixed(
            node: node, classElement: aliasedType.element);
      }
    }
    return node;
  }

  AstNode propertyAccess(Scope nameScope, PropertyAccess node) {
    if (node.isCascaded) {
      // For example, `List..filled`: this is a property access on an instance
      // `Type`.
      return node;
    }
    var receiver = node.target!;
    if (receiver is! FunctionReference) {
      return node;
    }
    var propertyName = node.propertyName;
    if (propertyName.isSynthetic) {
      // This isn't a constructor reference.
      return node;
    }
    // A [ConstructorReference] with explicit type arguments is initially parsed
    // as a [PropertyAccess] with a [FunctionReference] target; for example:
    // `List<int>.filled` or `core.List<int>.filled`.
    var receiverIdentifier = receiver.function;
    if (receiverIdentifier is! Identifier) {
      // If [receiverIdentifier] is not an Identifier then [node] is not a
      // ConstructorReference.
      return node;
    }

    Element? element;
    if (receiverIdentifier is SimpleIdentifier) {
      element = nameScope.lookup(receiverIdentifier.name).getter;
    } else if (receiverIdentifier is PrefixedIdentifier) {
      var prefixElement =
          nameScope.lookup(receiverIdentifier.prefix.name).getter;
      if (prefixElement is PrefixElement) {
        element = prefixElement.scope
            .lookup(receiverIdentifier.identifier.name)
            .getter;
      } else {
        // This expression is something like `foo.List<int>.filled` where `foo`
        // is not an import prefix.
        // TODO(srawlins): Tease out a `null` prefixElement from others for
        // specific errors.
        return node;
      }
    }

    if (element is ClassElement) {
      // Example:
      //     class C<T> { C.named(); }
      //     C<int>.named
      return _toConstructorReference_propertyAccess(
        node: node,
        receiver: receiverIdentifier,
        typeArguments: receiver.typeArguments!,
        classElement: element,
      );
    } else if (element is TypeAliasElement) {
      var aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        // Example:
        //     class C<T> { C.named(); }
        //     typedef X<T> = C<T>;
        //     X<int>.named
        return _toConstructorReference_propertyAccess(
          node: node,
          receiver: receiverIdentifier,
          typeArguments: receiver.typeArguments!,
          classElement: aliasedType.element,
        );
      }
    }

    // If [receiverIdentifier] is an Identifier, but could not be resolved to
    // an Element, we cannot assume [node] is a ConstructorReference.
    //
    // TODO(srawlins): However, take an example like `Lisst<int>.filled;`
    // (where 'Lisst' does not resolve to any element). Possibilities include:
    // the user tried to write a TypeLiteral or a FunctionReference, then access
    // a property on that (these include: hashCode, runtimeType, tearoff of
    // toString, and extension methods on Type); or the user tried to write a
    // ConstructReference. It seems much more likely that the user is trying to
    // do the latter. Consider doing the work so that the user gets an error in
    // this case about `Lisst` not being a type, or `Lisst.filled` not being a
    // known constructor.
    return node;
  }

  AstNode _instanceCreation_prefix_type_name({
    required MethodInvocation node,
    required PrefixedIdentifier typeNameIdentifier,
    required SimpleIdentifier constructorIdentifier,
    required ClassElement classElement,
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

  AstNode _toConstructorReference_prefixed(
      {required PrefixedIdentifier node, required ClassElement classElement}) {
    var name = node.identifier.name;
    var constructorElement = name == 'new'
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(name);
    if (constructorElement == null) {
      return node;
    }

    var typeName = astFactory.typeName(node.prefix, null);
    var constructorName =
        astFactory.constructorName(typeName, node.period, node.identifier);
    var constructorReference =
        astFactory.constructorReference(constructorName: constructorName);
    NodeReplacer.replace(node, constructorReference);
    return constructorReference;
  }

  AstNode _toConstructorReference_propertyAccess({
    required PropertyAccess node,
    required Identifier receiver,
    required TypeArgumentList typeArguments,
    required ClassElement classElement,
  }) {
    var name = node.propertyName.name;
    var constructorElement = name == 'new'
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(name);
    if (constructorElement == null) {
      return node;
    }

    var operator = node.operator;

    var typeName = astFactory.typeName(receiver, typeArguments);
    var constructorName =
        astFactory.constructorName(typeName, operator, node.propertyName);
    var constructorReference =
        astFactory.constructorReference(constructorName: constructorName);
    NodeReplacer.replace(node, constructorReference);
    return constructorReference;
  }

  InstanceCreationExpression _toInstanceCreation_prefix_type({
    required MethodInvocation node,
    required SimpleIdentifier prefixIdentifier,
    required SimpleIdentifier typeIdentifier,
  }) {
    var typeName = astFactory.typeName(
        astFactory.prefixedIdentifier(
            prefixIdentifier, node.operator!, typeIdentifier),
        node.typeArguments);
    var constructorName = astFactory.constructorName(typeName, null, null);
    var instanceCreationExpression = astFactory.instanceCreationExpression(
        null, constructorName, node.argumentList);
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  InstanceCreationExpression _toInstanceCreation_type({
    required MethodInvocation node,
    required SimpleIdentifier typeIdentifier,
  }) {
    var typeName = astFactory.typeName(typeIdentifier, node.typeArguments);
    var constructorName = astFactory.constructorName(typeName, null, null);
    var instanceCreationExpression = astFactory.instanceCreationExpression(
        null, constructorName, node.argumentList);
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  AstNode _toInstanceCreation_type_constructor({
    required MethodInvocation node,
    required SimpleIdentifier typeIdentifier,
    required SimpleIdentifier constructorIdentifier,
    required ClassElement classElement,
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
