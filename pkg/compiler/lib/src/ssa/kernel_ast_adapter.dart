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
import '../types/types.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../world.dart';
import 'locals_handler.dart';
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
  final Map<ir.VariableDeclaration, SyntheticLocal> _syntheticLocals =
      <ir.VariableDeclaration, SyntheticLocal>{};
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
  TreeElements get elements => _resolvedAst.elements;
  GlobalTypeInferenceResults get _inferenceResults =>
      _compiler.globalInference.results;

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

  Local getLocal(ir.VariableDeclaration variable) {
    // If this is a synthetic local, return the synthetic local
    if (variable.name == null) {
      return _syntheticLocals.putIfAbsent(
          variable, () => new SyntheticLocal("x", null));
    }
    return getElement(variable) as LocalElement;
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

  Selector getSelector(ir.Expression node) {
    if (node is ir.PropertyGet) return getGetterSelector(node);
    if (node is ir.InvocationExpression) return getInvocationSelector(node);
    _compiler.reporter.internalError(getNode(node),
        "Can only get the selector for a property get or an invocation.");
    return null;
  }

  Selector getInvocationSelector(ir.InvocationExpression invocation) {
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

  TypeMask typeOfInvocation(ir.Expression send) {
    return _inferenceResults.typeOfSend(getNode(send), elements);
  }

  TypeMask typeOfGet(ir.PropertyGet getter) {
    return _inferenceResults.typeOfSend(getNode(getter), elements);
  }

  TypeMask typeOfSend(ir.Expression send) {
    assert(send is ir.InvocationExpression || send is ir.PropertyGet);
    return _inferenceResults.typeOfSend(getNode(send), elements);
  }

  TypeMask typeOfNewList(Element owner, ir.ListLiteral listLiteral) {
    return _inferenceResults.typeOfNewList(owner, getNode(listLiteral)) ??
        _compiler.commonMasks.dynamicType;
  }

  TypeMask typeOfIterator(ir.ForInStatement forInStatement) {
    return _inferenceResults.typeOfIterator(getNode(forInStatement), elements);
  }

  TypeMask typeOfIteratorCurrent(ir.ForInStatement forInStatement) {
    return _inferenceResults.typeOfIteratorCurrent(
        getNode(forInStatement), elements);
  }

  TypeMask typeOfIteratorMoveNext(ir.ForInStatement forInStatement) {
    return _inferenceResults.typeOfIteratorMoveNext(
        getNode(forInStatement), elements);
  }

  bool isJsIndexableIterator(ir.ForInStatement forInStatement) {
    TypeMask mask = typeOfIterator(forInStatement);
    ClosedWorld closedWorld = _compiler.closedWorld;
    return mask != null &&
        mask.satisfies(_backend.helpers.jsIndexableClass, closedWorld) &&
        // String is indexable but not iterable.
        !mask.satisfies(_backend.helpers.jsStringClass, closedWorld);
  }

  bool isFixedLength(TypeMask mask) {
    ClosedWorld closedWorld = _compiler.closedWorld;
    JavaScriptBackend backend = _compiler.backend;
    if (mask.isContainer && (mask as ContainerTypeMask).length != null) {
      // A container on which we have inferred the length.
      return true;
    }
    // TODO(sra): Recognize any combination of fixed length indexables.
    if (mask.containsOnly(backend.helpers.jsFixedArrayClass) ||
        mask.containsOnly(backend.helpers.jsUnmodifiableArrayClass) ||
        mask.containsOnlyString(closedWorld) ||
        backend.isTypedArray(mask)) {
      return true;
    }
    return false;
  }

  TypeMask inferredIndexType(ir.ForInStatement forInStatement) {
    return TypeMaskFactory.inferredTypeForSelector(
        new Selector.index(), typeOfIterator(forInStatement), _compiler);
  }

  TypeMask inferredTypeOf(ir.Member node) {
    return TypeMaskFactory.inferredTypeForElement(getElement(node), _compiler);
  }

  TypeMask selectorTypeOf(Selector selector, TypeMask mask) {
    return TypeMaskFactory.inferredTypeForSelector(selector, mask, _compiler);
  }

  ConstantValue getConstantFor(ir.Node node) {
    ConstantValue constantValue =
        _backend.constants.getConstantValueForNode(getNode(node), elements);
    assert(invariant(getNode(node), constantValue != null,
        message: 'No constant computed for $node'));
    return constantValue;
  }

  bool isIntercepted(ir.Node node) {
    Selector selector = getSelector(node);
    return _backend.isInterceptedSelector(selector);
  }

  bool isInterceptedSelector(Selector selector) {
    return _backend.isInterceptedSelector(selector);
  }

  JumpTarget getTargetDefinition(ir.Node node) =>
      elements.getTargetDefinition(getNode(node));

  ir.Procedure get mapLiteralConstructor =>
      kernel.functions[_backend.helpers.mapLiteralConstructor];

  ir.Procedure get mapLiteralConstructorEmpty =>
      kernel.functions[_backend.helpers.mapLiteralConstructorEmpty];

  Element get jsIndexableLength => _backend.helpers.jsIndexableLength;

  ir.Procedure get checkConcurrentModificationError =>
      kernel.functions[_backend.helpers.checkConcurrentModificationError];

  TypeMask get checkConcurrentModificationErrorReturnType =>
      TypeMaskFactory.inferredReturnTypeForElement(
          _backend.helpers.checkConcurrentModificationError, _compiler);

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

  DartType visitType(ir.DartType type) => type.accept(this);

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
    return new FunctionType.synthesized(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.keys.toList(),
        visitTypes(node.namedParameters.values.toList()));
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
