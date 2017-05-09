// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' as ir;

import "../elements/elements.dart"
    show
        AstElement,
        ConstructorElement,
        Element,
        ErroneousElement,
        FunctionElement,
        MethodElement;
import "../elements/operators.dart"
    show AssignmentOperator, BinaryOperator, IncDecOperator, UnaryOperator;
import "../elements/resolution_types.dart"
    show ResolutionDartType, ResolutionInterfaceType;
import "../tree/tree.dart" show Expression, NewExpression, Node, NodeList, Send;
import "../universe/call_structure.dart" show CallStructure;
import "../universe/selector.dart" show Selector;
import 'accessors.dart';
import "kernel.dart" show Kernel;

abstract class UnresolvedVisitor {
  Kernel get kernel;

  // Implemented in KernelVisitor
  AstElement get currentElement;
  bool get isVoidContext;
  ir.Arguments buildArguments(NodeList arguments);
  ir.TreeNode visitForValue(Expression node);
  void associateCompoundComponents(Accessor accessor, Node node);

  // TODO(ahe): Delete this method.
  ir.InvalidExpression handleUnresolved(Node node);

  /// Similar to [Kernel.functionToIr] but returns null if [function] is a
  /// synthetic function created for error recovery.
  ir.Member possiblyErroneousFunctionToIr(FunctionElement function) {
    return kernel.isSyntheticError(function)
        ? null
        : kernel.functionToIr(function);
  }

  /// Throws a [NoSuchMethodError] corresponding to a call to
  /// [receiver].[memberName] with the arguments [callArguments].
  ///
  /// The exception object is built by calling [exceptionBuilder]. This should
  /// take the same arguments as the default constructor to [NoSuchMethodError],
  /// but the method itself may encode additional details about the call than
  /// is possible through the public interface of NoSuchMethodError.
  ///
  /// Note that [callArguments] are the arguments as they occur in the attempted
  /// call in user code -- they are not the arguments to [exceptionBuilder].
  ///
  /// If [candidateTarget] is given, it will provide the expected parameter
  /// names.
  ir.Expression buildThrowNoSuchMethodError(ir.Procedure exceptionBuilder,
      ir.Expression receiver, String memberName, ir.Arguments callArguments,
      [Element candidateTarget]) {
    ir.Expression memberNameArg =
        markSynthetic(new ir.SymbolLiteral(memberName));
    ir.Expression positional =
        markSynthetic(new ir.ListLiteral(callArguments.positional));
    ir.Expression named =
        markSynthetic(new ir.MapLiteral(callArguments.named.map((e) {
      return new ir.MapEntry(
          markSynthetic(new ir.SymbolLiteral(e.name)), e.value);
    }).toList()));
    if (candidateTarget is FunctionElement) {
      // Ensure [candidateTarget] has been resolved.
      possiblyErroneousFunctionToIr(candidateTarget);
    }
    ir.Expression existingArguments;
    if (candidateTarget is FunctionElement &&
        !kernel.isSyntheticError(candidateTarget) &&
        candidateTarget.hasFunctionSignature) {
      List<ir.Expression> existingArgumentsList = <ir.Expression>[];
      candidateTarget.functionSignature.forEachParameter((param) {
        existingArgumentsList
            .add(markSynthetic(new ir.StringLiteral(param.name)));
      });
      existingArguments =
          markSynthetic(new ir.ListLiteral(existingArgumentsList));
    } else {
      existingArguments = new ir.NullLiteral();
    }
    ir.Expression construction = markSynthetic(new ir.StaticInvocation(
        exceptionBuilder,
        new ir.Arguments(<ir.Expression>[
          receiver,
          memberNameArg,
          positional,
          named,
          existingArguments
        ])));
    return new ir.Throw(construction);
  }

  ir.Expression markSynthetic(ir.Expression expression) {
    kernel.syntheticNodes.add(expression);
    return expression;
  }

  /// Throws a NoSuchMethodError for an unresolved getter named [name].
  ir.Expression buildThrowUnresolvedGetter(String name,
      [ir.Procedure exceptionBuilder]) {
    // TODO(asgerf): We should remove this fallback, but in some cases we do
    //   not get sufficient information to determine exactly what kind of
    //   getter it is.
    exceptionBuilder ??= kernel.getGenericNoSuchMethodBuilder();
    return buildThrowNoSuchMethodError(
        exceptionBuilder, new ir.NullLiteral(), name, new ir.Arguments.empty());
  }

  ir.Expression buildThrowUnresolvedSetter(String name, ir.Expression argument,
      [ir.Procedure exceptionBuilder]) {
    // TODO(asgerf): We should remove this fallback, but in some cases we do
    //   not get sufficient information to determine exactly what kind of
    //   setter it is.
    exceptionBuilder ??= kernel.getGenericNoSuchMethodBuilder();
    return buildThrowNoSuchMethodError(exceptionBuilder, new ir.NullLiteral(),
        name, new ir.Arguments(<ir.Expression>[argument]));
  }

  ir.Expression buildThrowUnresolvedSuperGetter(String name) {
    // TODO(sra): This is incorrect when the superclass defines noSuchMethod.
    return buildThrowNoSuchMethodError(kernel.getUnresolvedSuperGetterBuilder(),
        new ir.ThisExpression(), name, new ir.Arguments.empty());
  }

  ir.Expression buildThrowUnresolvedSuperSetter(
      String name, ir.Expression argument) {
    return buildThrowNoSuchMethodError(
        kernel.getUnresolvedSuperSetterBuilder(),
        new ir.ThisExpression(),
        name,
        new ir.Arguments(<ir.Expression>[argument]));
  }

  ir.Expression buildThrowSingleArgumentError(
      ir.Procedure exceptionBuilder, String errorMessage) {
    return new ir.Throw(new ir.StaticInvocation(exceptionBuilder,
        new ir.Arguments(<ir.Expression>[new ir.StringLiteral(errorMessage)])));
  }

  SuperIndexAccessor buildUnresolvedSuperIndexAccessor(
      Node index, Element element) {
    ir.Member member = possiblyErroneousFunctionToIr(element);
    return new SuperIndexAccessor(this, visitForValue(index), member, member);
  }

  SuperPropertyAccessor buildUnresolvedSuperPropertyAccessor(
      String name, Element getter) {
    return new SuperPropertyAccessor(this, kernel.irName(name, currentElement),
        getter == null ? null : possiblyErroneousFunctionToIr(getter), null);
  }

  ir.Expression visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      ErroneousElement element,
      ResolutionDartType type,
      NodeList arguments,
      Selector selector,
      _) {
    // TODO(asgerf): The VM includes source information as part of the error
    //   message.  We could do the same when we add source maps.
    return buildThrowSingleArgumentError(
        kernel.getMalformedTypeErrorBuilder(), element.message);
  }

  ir.Expression visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      ResolutionDartType type,
      NodeList arguments,
      Selector selector,
      _) {
    ir.Expression receiver = new ir.TypeLiteral(kernel.interfaceTypeToIr(type));
    String methodName =
        node.send.selector != null ? '${node.send.selector}' : type.name;
    return buildThrowNoSuchMethodError(kernel.getUnresolvedConstructorBuilder(),
        receiver, methodName, buildArguments(arguments), constructor);
  }

  ir.Expression visitUnresolvedCompound(
      Send node, Element element, AssignmentOperator operator, Node rhs, _) {
    return buildThrowUnresolvedGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedGet(Send node, Element element, _) {
    return buildThrowUnresolvedGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedInvoke(
      Send node, Element element, NodeList arguments, Selector selector, _) {
    // TODO(asgerf): Should we use a type literal as receiver for unresolved
    //   static invocations?
    return buildThrowNoSuchMethodError(kernel.getGenericNoSuchMethodBuilder(),
        new ir.NullLiteral(), element.name, buildArguments(arguments), element);
  }

  ir.Expression visitUnresolvedPostfix(
      Send node, Element element, IncDecOperator operator, _) {
    return buildThrowUnresolvedGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedPrefix(
      Send node, Element element, IncDecOperator operator, _) {
    return buildThrowUnresolvedGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    // The body of the factory will throw an error.
    return new ir.StaticInvocation(
        possiblyErroneousFunctionToIr(constructor), buildArguments(arguments));
  }

  ir.Expression visitUnresolvedSet(Send node, Element element, Node rhs, _) {
    return buildThrowUnresolvedSetter('${node.selector}', visitForValue(rhs));
  }

  ir.Expression visitUnresolvedSetIfNull(
      Send node, Element element, Node rhs, _) {
    return buildThrowUnresolvedGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedStaticGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedStaticGetterBuilder());
  }

  ir.Expression visitUnresolvedStaticGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedStaticGetterBuilder());
  }

  ir.Expression visitUnresolvedStaticGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedStaticGetterBuilder());
  }

  ir.Expression visitUnresolvedStaticGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedStaticGetterBuilder());
  }

  ir.Expression visitUnresolvedStaticSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildThrowUnresolvedSetter('${node.selector}', visitForValue(rhs),
        kernel.getUnresolvedStaticSetterBuilder());
  }

  ir.Expression visitUnresolvedStaticSetterPostfix(Send node,
      MethodElement getter, Element element, IncDecOperator operator, _) {
    var accessor = new ClassStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    var result = accessor.buildPostfixIncrement(
        new ir.Name(operator.selectorName),
        voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression visitUnresolvedStaticSetterPrefix(Send node,
      MethodElement getter, Element element, IncDecOperator operator, _) {
    var accessor = new ClassStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    var result = accessor.buildPrefixIncrement(
        new ir.Name(operator.selectorName),
        voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression visitUnresolvedStaticSetterSetIfNull(
      Send node, MethodElement getter, Element element, Node rhs, _) {
    var accessor = new ClassStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    return accessor.buildNullAwareAssignment(visitForValue(rhs), null,
        voidContext: isVoidContext);
  }

  ir.Expression visitUnresolvedSuperBinary(
      Send node, Element element, BinaryOperator operator, Node argument, _) {
    // TODO(sra): This is incorrect when the superclass defines noSuchMethod.
    return buildThrowNoSuchMethodError(
        kernel.getUnresolvedSuperMethodBuilder(),
        new ir.ThisExpression(),
        operator.selectorName,
        new ir.Arguments(<ir.Expression>[visitForValue(argument)]));
  }

  ir.Expression visitUnresolvedSuperCompound(
      Send node, Element element, AssignmentOperator operator, Node rhs, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperCompoundIndexSet(Send node, Element element,
      Node index, AssignmentOperator operator, Node rhs, _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildCompoundAssignment(
            new ir.Name(operator.selectorName), visitForValue(rhs));
  }

  ir.Expression visitUnresolvedSuperGet(Send node, Element element, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterCompoundIndexSet(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterIndexPostfix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterIndexPrefix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperIndex(
      Send node, Element element, Node index, _) {
    return buildUnresolvedSuperIndexAccessor(index, element).buildSimpleRead();
  }

  ir.Expression visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, _) {
    return buildUnresolvedSuperIndexAccessor(index, element).buildSimpleRead();
  }

  ir.Expression visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, _) {
    return buildUnresolvedSuperIndexAccessor(index, element).buildSimpleRead();
  }

  ir.Expression visitUnresolvedSuperIndexSet(
      Send node, Element element, Node index, Node rhs, _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildAssignment(visitForValue(rhs));
  }

  ir.Expression visitUnresolvedSuperInvoke(
      Send node, Element element, NodeList arguments, Selector selector, _) {
    // TODO(asgerf): Should really invoke 'super.noSuchMethod'.
    return buildThrowNoSuchMethodError(kernel.getUnresolvedSuperMethodBuilder(),
        new ir.ThisExpression(), '${node.selector}', buildArguments(arguments));
  }

  ir.Expression visitUnresolvedSuperPostfix(
      Send node, Element element, IncDecOperator operator, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperPrefix(
      Send node, Element element, IncDecOperator operator, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperSetIfNull(
      Send node, Element element, Node rhs, _) {
    return buildThrowUnresolvedSuperGetter('${node.selector}');
  }

  ir.Expression visitUnresolvedSuperSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildUnresolvedSuperPropertyAccessor('${node.selector}', getter)
        .buildCompoundAssignment(
            new ir.Name(operator.selectorName), visitForValue(rhs));
  }

  ir.Expression visitUnresolvedSuperSetterCompoundIndexSet(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildCompoundAssignment(
            new ir.Name(operator.selectorName), visitForValue(rhs));
  }

  ir.Expression visitUnresolvedSuperSetterIndexPostfix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildPostfixIncrement(new ir.Name(operator.selectorName));
  }

  ir.Expression visitUnresolvedSuperSetterIndexPrefix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildPrefixIncrement(new ir.Name(operator.selectorName));
  }

  ir.Expression visitUnresolvedSuperSetterPostfix(Send node,
      MethodElement getter, Element element, IncDecOperator operator, _) {
    return buildUnresolvedSuperPropertyAccessor('${node.selector}', getter)
        .buildPostfixIncrement(new ir.Name(operator.selectorName));
  }

  ir.Expression visitUnresolvedSuperSetterPrefix(Send node,
      MethodElement getter, Element element, IncDecOperator operator, _) {
    return buildUnresolvedSuperPropertyAccessor('${node.selector}', getter)
        .buildPrefixIncrement(new ir.Name(operator.selectorName));
  }

  ir.Expression visitUnresolvedSuperSetterSetIfNull(
      Send node, MethodElement getter, Element element, Node rhs, _) {
    return buildUnresolvedSuperPropertyAccessor('${node.selector}', getter)
        .buildNullAwareAssignment(visitForValue(rhs), null);
  }

  ir.Expression visitUnresolvedSuperUnary(
      Send node, UnaryOperator operator, Element element, _) {
    // TODO(asgerf): Should really call 'super.noSuchMethod'.
    return buildThrowNoSuchMethodError(
        kernel.getUnresolvedSuperMethodBuilder(),
        new ir.ThisExpression(),
        operator.selectorName,
        new ir.Arguments.empty());
  }

  ir.Expression visitUnresolvedTopLevelGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedTopLevelGetterBuilder());
  }

  ir.Expression visitUnresolvedTopLevelGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedTopLevelGetterBuilder());
  }

  ir.Expression visitUnresolvedTopLevelGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedTopLevelGetterBuilder());
  }

  ir.Expression visitUnresolvedTopLevelGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, _) {
    return buildThrowUnresolvedGetter(
        '${node.selector}', kernel.getUnresolvedTopLevelGetterBuilder());
  }

  ir.Expression visitUnresolvedTopLevelSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    var accessor = new TopLevelStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    var result = accessor.buildCompoundAssignment(
        new ir.Name(operator.selectorName), visitForValue(rhs),
        voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression visitUnresolvedTopLevelSetterPostfix(Send node,
      MethodElement getter, Element element, IncDecOperator operator, _) {
    var accessor = new TopLevelStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    var result = accessor.buildPostfixIncrement(
        new ir.Name(operator.selectorName),
        voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression visitUnresolvedTopLevelSetterPrefix(Send node,
      MethodElement getter, Element element, IncDecOperator operator, _) {
    var accessor = new TopLevelStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    var result = accessor.buildPrefixIncrement(
        new ir.Name(operator.selectorName),
        voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression visitUnresolvedTopLevelSetterSetIfNull(
      Send node, MethodElement getter, Element element, Node rhs, _) {
    var accessor = new TopLevelStaticAccessor(
        this, getter.name, possiblyErroneousFunctionToIr(getter), null);
    return accessor.buildNullAwareAssignment(visitForValue(rhs), null,
        voidContext: isVoidContext);
  }

  ir.Expression visitUnresolvedSuperGetterIndexSetIfNull(Send node,
      Element element, MethodElement setter, Node index, Node rhs, _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildNullAwareAssignment(visitForValue(rhs), null);
  }

  ir.Expression visitUnresolvedSuperSetterIndexSetIfNull(Send node,
      MethodElement getter, Element element, Node index, Node rhs, _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildNullAwareAssignment(visitForValue(rhs), null);
  }

  ir.Expression visitUnresolvedSuperIndexSetIfNull(
      Send node, Element element, Node index, Node rhs, _) {
    return buildUnresolvedSuperIndexAccessor(index, element)
        .buildNullAwareAssignment(visitForValue(rhs), null);
  }

  ir.Expression visitUnresolvedSuperSet(
      Send node, Element element, Node rhs, _) {
    return buildThrowUnresolvedSuperSetter(
        '${node.selector}', visitForValue(rhs));
  }
}
