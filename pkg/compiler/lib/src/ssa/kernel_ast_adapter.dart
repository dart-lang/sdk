// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
import '../kernel/kernel.dart';
import '../resolution/tree_elements.dart';
import '../tree/tree.dart' as ast;
import '../types/masks.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import 'types.dart';

/// A helper class that abstracts all accesses of the AST from Kernel nodes.
///
/// The goal is to remove all need for the AST from the Kernel SSA builder.
class KernelAstAdapter {
  final Kernel kernel;
  final JavaScriptBackend _backend;
  final ResolvedAst _resolvedAst;
  final Map<ir.Node, ast.Node> _nodeToAst;
  final Map<ir.Node, Element> _nodeToElement;
  DartTypeConverter _typeConverter;

  KernelAstAdapter(this.kernel, this._backend, this._resolvedAst,
      this._nodeToAst, this._nodeToElement) {
    // TODO(het): Maybe just use all of the kernel maps directly?
    for (FieldElement fieldElement in kernel.fields.keys) {
      _nodeToElement[kernel.fields[fieldElement]] = fieldElement;
    }
    for (FunctionElement functionElement in kernel.functions.keys) {
      _nodeToElement[kernel.functions[functionElement]] = functionElement;
    }
    for (ClassElement classElement in kernel.classes.keys) {
      _nodeToElement[kernel.classes[classElement]] = classElement;
    }
    for (LibraryElement libraryElement in kernel.libraries.keys) {
      _nodeToElement[kernel.libraries[libraryElement]] = libraryElement;
    }
    for (LocalFunctionElement localFunction in kernel.localFunctions.keys) {
      _nodeToElement[kernel.localFunctions[localFunction]] = localFunction;
    }
    _typeConverter = new DartTypeConverter(this);
  }

  Compiler get _compiler => _backend.compiler;
  TreeElements get _elements => _resolvedAst.elements;

  ConstantValue getConstantForSymbol(ir.SymbolLiteral node) {
    ast.Node astNode = getNode(node);
    ConstantValue constantValue = _backend.constants
        .getConstantValueForNode(astNode, _resolvedAst.elements);
    assert(invariant(astNode, constantValue != null,
        message: 'No constant computed for $node'));
    return constantValue;
  }

  Element getElement(ir.Node node) {
    Element result = _nodeToElement[node];
    assert(result != null);
    return result;
  }

  ast.Node getNode(ir.Node node) {
    ast.Node result = _nodeToAst[node];
    assert(result != null);
    return result;
  }

  bool getCanThrow(ir.Node procedure) {
    FunctionElement function = getElement(procedure);
    return !_compiler.closedWorld.getCannotThrow(function);
  }

  TypeMask returnTypeOf(ir.Member node) {
    return TypeMaskFactory.inferredReturnTypeForElement(
        getElement(node), _compiler);
  }

  SideEffects getSideEffects(ir.Node node) {
    return _compiler.closedWorld.getSideEffectsOfElement(getElement(node));
  }

  CallStructure getCallStructure(ir.Arguments arguments) {
    int argumentCount = arguments.positional.length + arguments.named.length;
    List<String> namedArguments = arguments.named.map((e) => e.name).toList();
    return new CallStructure(argumentCount, namedArguments);
  }

  Name getName(ir.Name name) {
    return new Name(
        name.name, name.isPrivate ? getElement(name.library) : null);
  }

  // TODO(het): Create the selector directly from the invocation
  Selector getSelector(ir.InvocationExpression invocation) {
    Name name = getName(invocation.name);
    SelectorKind kind;
    if (Elements.isOperatorName(invocation.name.name)) {
      if (name == Names.INDEX_NAME || name == Names.INDEX_SET_NAME) {
        kind = SelectorKind.INDEX;
      } else {
        kind = SelectorKind.OPERATOR;
      }
    } else {
      kind = SelectorKind.CALL;
    }

    CallStructure callStructure = getCallStructure(invocation.arguments);
    return new Selector(kind, name, callStructure);
  }

  Selector getGetterSelector(ir.PropertyGet getter) {
    ir.Name irName = getter.name;
    Name name = new Name(
        irName.name, irName.isPrivate ? getElement(irName.library) : null);
    return new Selector.getter(name);
  }

  TypeMask typeOfInvocation(ir.MethodInvocation invocation) {
    return _compiler.globalInference.results
        .typeOfSend(getNode(invocation), _elements);
  }

  TypeMask typeOfGet(ir.PropertyGet getter) {
    return _compiler.globalInference.results
        .typeOfSend(getNode(getter), _elements);
  }

  TypeMask inferredTypeOf(ir.Member node) {
    return TypeMaskFactory.inferredTypeForElement(getElement(node), _compiler);
  }

  TypeMask selectorTypeOf(ir.MethodInvocation invocation) {
    return TypeMaskFactory.inferredTypeForSelector(
        getSelector(invocation), typeOfInvocation(invocation), _compiler);
  }

  TypeMask selectorGetterTypeOf(ir.PropertyGet getter) {
    return TypeMaskFactory.inferredTypeForSelector(
        getGetterSelector(getter), typeOfGet(getter), _compiler);
  }

  ConstantValue getConstantFor(ir.Node node) {
    ConstantValue constantValue =
        _backend.constants.getConstantValueForNode(getNode(node), _elements);
    assert(invariant(getNode(node), constantValue != null,
        message: 'No constant computed for $node'));
    return constantValue;
  }

  bool isIntercepted(ir.Node node) {
    Selector selector;
    if (node is ir.PropertyGet) {
      selector = getGetterSelector(node);
    } else {
      selector = getSelector(node);
    }
    return _backend.isInterceptedSelector(selector);
  }

  ir.Procedure get mapLiteralConstructor =>
      kernel.functions[_backend.helpers.mapLiteralConstructor];

  ir.Procedure get mapLiteralConstructorEmpty =>
      kernel.functions[_backend.helpers.mapLiteralConstructorEmpty];

  DartType getDartType(ir.DartType type) {
    return type.accept(_typeConverter);
  }

  List<DartType> getDartTypes(List<ir.DartType> types) {
    return types.map(getDartType).toList();
  }
}

class DartTypeConverter extends ir.DartTypeVisitor<DartType> {
  final KernelAstAdapter astAdapter;

  DartTypeConverter(this.astAdapter);

  List<DartType> visitTypes(List<ir.DartType> types) {
    return new List.generate(
        types.length, (int index) => types[index].accept(this));
  }

  @override
  DartType visitTypeParameterType(ir.TypeParameterType node) {
    return new TypeVariableType(astAdapter.getElement(node.parameter));
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    throw new UnimplementedError("Function types not currently supported");
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassElement cls = astAdapter.getElement(node.classNode);
    return new InterfaceType(cls, visitTypes(node.typeArguments));
  }

  @override
  DartType visitVoidType(ir.VoidType node) {
    return const VoidType();
  }

  @override
  DartType visitDynamicType(ir.DynamicType node) {
    return const DynamicType();
  }

  @override
  DartType visitInvalidType(ir.InvalidType node) {
    throw new UnimplementedError("Invalid types not currently supported");
  }
}
