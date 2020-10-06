// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class LinkedElementBuilder {
  final CompilationUnitElementImpl _unitElement;
  final Reference _classRef;
  final Reference _enumRef;
  final Reference _extensionRef;
  final Reference _functionRef;
  final Reference _getterRef;
  final Reference _mixinRef;
  final Reference _setterRef;
  final Reference _typeAliasRef;
  final Reference _variableRef;

  var _nextUnnamedExtensionId = 0;

  LinkedElementBuilder(LinkedUnitContext unitContext)
      : _unitElement = unitContext.reference.element,
        _classRef = unitContext.reference.getChild('@class'),
        _enumRef = unitContext.reference.getChild('@enum'),
        _extensionRef = unitContext.reference.getChild('@extension'),
        _functionRef = unitContext.reference.getChild('@function'),
        _getterRef = unitContext.reference.getChild('@getter'),
        _mixinRef = unitContext.reference.getChild('@mixin'),
        _setterRef = unitContext.reference.getChild('@setter'),
        _typeAliasRef = unitContext.reference.getChild('@typeAlias'),
        _variableRef = unitContext.reference.getChild('@variable');

  ClassElementImpl classDeclaration(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = ClassElementImpl.forLinkedNode(
      _unitElement,
      _classRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }

  ClassElementImpl classTypeAlias(ClassTypeAlias node) {
    var element = node.declaredElement as ClassElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = ClassElementImpl.forLinkedNode(
      _unitElement,
      _classRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }

  EnumElementImpl enumDeclaration(EnumDeclaration node) {
    var element = node.declaredElement as EnumElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = EnumElementImpl.forLinkedNode(
      _unitElement,
      _enumRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }

  ExtensionElementImpl extensionDeclaration(ExtensionDeclarationImpl node) {
    var element = node.declaredElement as ExtensionElementImpl;
    if (element != null) {
      return element;
    }

    var name = node.name?.name;
    var refName = name ?? 'extension-${_nextUnnamedExtensionId++}';
    element = ExtensionElementImpl.forLinkedNode(
      _unitElement,
      _extensionRef.getChild(refName),
      node,
    );
    node.declaredElement = element;
    return element;
  }

  ExecutableElementImpl functionDeclaration(FunctionDeclaration node) {
    var element = node.declaredElement as ExecutableElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    var name = nameNode.name;

    if (node.isGetter) {
      element = PropertyAccessorElementImpl.forLinkedNode(
        _unitElement,
        _getterRef.getChild(name),
        node,
      );
    } else if (node.isSetter) {
      element = PropertyAccessorElementImpl.forLinkedNode(
        _unitElement,
        _setterRef.getChild(name),
        node,
      );
    } else {
      element = FunctionElementImpl.forLinkedNode(
        _unitElement,
        _functionRef.getChild(name),
        node,
      );
    }

    nameNode.staticElement = element;
    return element;
  }

  GenericTypeAliasElementImpl functionTypeAlias(FunctionTypeAlias node) {
    var element = node.declaredElement as GenericTypeAliasElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = GenericTypeAliasElementImpl.forLinkedNode(
      _unitElement,
      _typeAliasRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }

  GenericTypeAliasElementImpl genericTypeAlias(GenericTypeAlias node) {
    var element = node.declaredElement as GenericTypeAliasElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = GenericTypeAliasElementImpl.forLinkedNode(
      _unitElement,
      _typeAliasRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }

  MixinElementImpl mixinDeclaration(MixinDeclaration node) {
    var element = node.declaredElement as MixinElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = MixinElementImpl.forLinkedNode(
      _unitElement,
      _mixinRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }

  TopLevelVariableElementImpl topLevelVariable(VariableDeclaration node) {
    var element = node.declaredElement as TopLevelVariableElementImpl;
    if (element != null) {
      return element;
    }

    var nameNode = node.name;
    element = TopLevelVariableElementImpl.forLinkedNodeFactory(
      _unitElement,
      _variableRef.getChild(nameNode.name),
      node,
    );
    nameNode.staticElement = element;
    return element;
  }
}
