// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class PrefixedIdentifierResolver {
  final ResolverVisitor _resolver;

  PrefixedIdentifierResolver(this._resolver);

  InvocationInferenceHelper get _inferenceHelper => _resolver.inferenceHelper;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  void resolve(PrefixedIdentifier node) {
    node.prefix.accept(_resolver);

    var resolver = PropertyElementResolver(_resolver);
    var result = resolver.resolvePrefixedIdentifier(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var identifier = node.identifier;
    identifier.staticElement = result.readElement;

    _resolve2(node);
  }

  /// Return the type that should be recorded for a node that resolved to the given accessor.
  ///
  /// @param accessor the accessor that the node resolved to
  /// @return the type that should be recorded for a node that resolved to the given accessor
  ///
  /// TODO(scheglov) this is duplicate
  DartType _getTypeOfProperty(PropertyAccessorElement accessor) {
    FunctionType functionType = accessor.type;
    if (functionType == null) {
      // TODO(brianwilkerson) Report this internal error. This happens when we
      // are analyzing a reference to a property before we have analyzed the
      // declaration of the property or when the property does not have a
      // defined type.
      return DynamicTypeImpl.instance;
    }
    if (accessor.isSetter) {
      List<DartType> parameterTypes = functionType.normalParameterTypes;
      if (parameterTypes != null && parameterTypes.isNotEmpty) {
        return parameterTypes[0];
      }
      PropertyAccessorElement getter = accessor.variable.getter;
      if (getter != null) {
        functionType = getter.type;
        if (functionType != null) {
          return functionType.returnType;
        }
      }
      return DynamicTypeImpl.instance;
    }
    return functionType.returnType;
  }

  /// Given a property access [node] with static type [nodeType],
  /// and [id] is the property name being accessed, infer a type for the
  /// access itself and its constituent components if the access is to one of the
  /// methods or getters of the built in 'Object' type, and if the result type is
  /// a sealed type. Returns true if inference succeeded.
  bool _inferObjectAccess(
      Expression node, DartType nodeType, SimpleIdentifier id) {
    // If we have an access like `libraryPrefix.hashCode` don't infer it.
    if (node is PrefixedIdentifier &&
        node.prefix.staticElement is PrefixElement) {
      return false;
    }
    // Search for Object accesses.
    String name = id.name;
    PropertyAccessorElement inferredElement =
        _typeProvider.objectType.element.getGetter(name);
    if (inferredElement == null || inferredElement.isStatic) {
      return false;
    }
    inferredElement = _resolver.toLegacyElement(inferredElement);
    DartType inferredType = inferredElement.returnType;
    if (nodeType != null &&
        nodeType.isDynamic &&
        inferredType is InterfaceType &&
        _typeProvider.nonSubtypableClasses.contains(inferredType.element)) {
      _recordStaticType(id, inferredType);
      _recordStaticType(node, inferredType);
      return true;
    }
    return false;
  }

  /// Return `true` if the given [node] is not a type literal.
  ///
  /// TODO(scheglov) this is duplicate
  bool _isExpressionIdentifier(Identifier node) {
    var parent = node.parent;
    if (node is SimpleIdentifier && node.inDeclarationContext()) {
      return false;
    }
    if (parent is ConstructorDeclaration) {
      if (parent.name == node || parent.returnType == node) {
        return false;
      }
    }
    if (parent is ConstructorName ||
        parent is MethodInvocation ||
        parent is PrefixedIdentifier && parent.prefix == node ||
        parent is PropertyAccess ||
        parent is TypeName) {
      return false;
    }
    return true;
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplicate
  void _recordStaticType(Expression expression, DartType type) {
    _inferenceHelper.recordStaticType(expression, type);
  }

  void _resolve2(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element staticElement = prefixedIdentifier.staticElement;

    if (staticElement is ExtensionElement) {
      _setExtensionIdentifierType(node);
      return;
    }

    if (identical(node.prefix.staticType, NeverTypeImpl.instance)) {
      _recordStaticType(prefixedIdentifier, NeverTypeImpl.instance);
      _recordStaticType(node, NeverTypeImpl.instance);
      return;
    }

    DartType staticType = DynamicTypeImpl.instance;
    if (staticElement is ClassElement) {
      if (_isExpressionIdentifier(node)) {
        var type = _typeProvider.typeType;
        node.staticType = type;
        node.identifier.staticType = type;
      }
      return;
    } else if (staticElement is DynamicElementImpl) {
      var type = _typeProvider.typeType;
      node.staticType = type;
      node.identifier.staticType = type;
      return;
    } else if (staticElement is FunctionTypeAliasElement) {
      if (node.parent is TypeName) {
        // no type
      } else {
        var type = _typeProvider.typeType;
        node.staticType = type;
        node.identifier.staticType = type;
      }
      return;
    } else if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(staticElement);
    } else if (staticElement is ExecutableElement) {
      staticType = staticElement.type;
    } else if (staticElement is VariableElement) {
      staticType = staticElement.type;
    }

    staticType = _resolver.inferenceHelper
        .inferTearOff(node, node.identifier, staticType);
    if (!_inferObjectAccess(node, staticType, prefixedIdentifier)) {
      _recordStaticType(prefixedIdentifier, staticType);
      _recordStaticType(node, staticType);
    }
  }

  /// TODO(scheglov) this is duplicate
  void _setExtensionIdentifierType(Identifier node) {
    if (node is SimpleIdentifier && node.inDeclarationContext()) {
      return;
    }

    var parent = node.parent;

    if (parent is PrefixedIdentifier && parent.identifier == node) {
      node = parent;
      parent = node.parent;
    }

    if (parent is CommentReference ||
        parent is ExtensionOverride && parent.extensionName == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixedIdentifier && parent.prefix == node ||
        parent is PropertyAccess && parent.target == node) {
      return;
    }

    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.EXTENSION_AS_EXPRESSION,
      node,
      [node.name],
    );

    if (node is PrefixedIdentifier) {
      node.identifier.staticType = DynamicTypeImpl.instance;
      node.staticType = DynamicTypeImpl.instance;
    } else if (node is SimpleIdentifier) {
      node.staticType = DynamicTypeImpl.instance;
    }
  }
}
