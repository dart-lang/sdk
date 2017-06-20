// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Remove this library when all constant constructors are
// computed during resolution.
library dart2js.constants.constant_constructors;

import '../common.dart';
import '../elements/elements.dart';
import '../elements/operators.dart';
import '../elements/resolution_types.dart';
import '../resolution/semantic_visitor.dart';
import '../resolution/send_resolver.dart' show DeclarationResolverMixin;
import '../resolution/send_structure.dart';
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import 'constructors.dart';
import 'expressions.dart';

ConstantConstructor computeConstantConstructor(ResolvedAst resolvedAst) {
  ConstantConstructorComputer visitor =
      new ConstantConstructorComputer(resolvedAst.elements);
  return resolvedAst.node.accept(visitor);
}

class ConstantConstructorComputer extends SemanticVisitor
    with
        SemanticDeclarationResolvedMixin,
        DeclarationResolverMixin,
        GetBulkMixin,
        SetBulkMixin,
        ErrorBulkMixin,
        InvokeBulkMixin,
        IndexSetBulkMixin,
        CompoundBulkMixin,
        SetIfNullBulkMixin,
        UnaryBulkMixin,
        BaseBulkMixin,
        BinaryBulkMixin,
        PrefixBulkMixin,
        PostfixBulkMixin,
        NewBulkMixin,
        InitializerBulkMixin,
        FunctionBulkMixin,
        VariableBulkMixin
    implements SemanticDeclarationVisitor, SemanticSendVisitor {
  final Map<FieldElement, ConstantExpression> fieldMap =
      <FieldElement, ConstantExpression>{};
  final Map<dynamic /*int|String*/, ConstantExpression> defaultValues =
      <dynamic /*int|String*/, ConstantExpression>{};

  ConstantConstructorComputer(TreeElements elements) : super(elements);

  SemanticDeclarationVisitor get declVisitor => this;

  SemanticSendVisitor get sendVisitor => this;

  ClassElement get currentClass => currentConstructor.enclosingClass;

  ConstructorElement get currentConstructor => elements.analyzedElement;

  apply(Node node, [_]) => node.accept(this);

  visitNode(Node node) {
    internalError(node, 'Unhandled node $node: ${node.toDebugString()}');
  }

  @override
  bulkHandleNode(Node node, String template, _) {
    internalError(node, template.replaceFirst('#', '$node'));
  }

  internalError(Spannable node, String message) {
    throw new UnsupportedError(message);
  }

  ConstantConstructor visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      _) {
    applyParameters(parameters, _);
    ConstructedConstantExpression constructorInvocation =
        applyInitializers(node, _);
    constructor.enclosingClass.forEachInstanceField((_, FieldElement field) {
      if (!fieldMap.containsKey(field)) {
        fieldMap[field] = field.constant;
      }
    });
    return new GenerativeConstantConstructor(
        currentClass.thisType, defaultValues, fieldMap, constructorInvocation);
  }

  ConstantConstructor visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      _) {
    applyParameters(parameters, _);
    ConstructedConstantExpression constructorInvocation =
        applyInitializers(node, _);
    return new RedirectingGenerativeConstantConstructor(
        defaultValues, constructorInvocation);
  }

  ConstantConstructor visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      ResolutionInterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      _) {
    List<String> argumentNames = [];
    List<ConstantExpression> arguments = [];
    int index = 0;
    for (ParameterElement parameter in constructor.parameters) {
      if (parameter.isNamed) {
        String name = parameter.name;
        argumentNames.add(name);
        arguments.add(new NamedArgumentReference(name));
      } else {
        arguments.add(new PositionalArgumentReference(index));
      }
      index++;
    }
    CallStructure callStructure = new CallStructure(index, argumentNames);

    return new RedirectingFactoryConstantConstructor(
        new ConstructedConstantExpression(
            redirectionType, redirectionTarget, callStructure, arguments));
  }

  @override
  visitFactoryConstructorDeclaration(FunctionExpression node,
      ConstructorElement constructor, NodeList parameters, Node body, _) {
    // TODO(johnniwinther): Handle constant constructors with errors.
    internalError(node, "Factory constructor cannot be constant: $node.");
  }

  applyParameters(NodeList parameters, _) {
    computeParameterStructures(parameters).forEach((s) => s.dispatch(this, _));
  }

  visitParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, int index, _) {
    // Do nothing.
  }

  visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    assert(defaultValue != null, failedAt(node));
    defaultValues[index] = defaultValue;
  }

  visitNamedParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, ConstantExpression defaultValue, _) {
    assert(defaultValue != null, failedAt(node));
    String name = parameter.name;
    defaultValues[name] = defaultValue;
  }

  visitInitializingFormalDeclaration(VariableDefinitions node, Node definition,
      InitializingFormalElement parameter, int index, _) {
    fieldMap[parameter.fieldElement] = new PositionalArgumentReference(index);
  }

  visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    assert(defaultValue != null, failedAt(node));
    defaultValues[index] = defaultValue;
    fieldMap[parameter.fieldElement] = new PositionalArgumentReference(index);
  }

  visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    assert(defaultValue != null, failedAt(node));
    String name = parameter.name;
    defaultValues[name] = defaultValue;
    fieldMap[parameter.fieldElement] = new NamedArgumentReference(name);
  }

  /// Apply this visitor to the constructor [initializers].
  ConstructedConstantExpression applyInitializers(
      FunctionExpression constructor, _) {
    ConstructedConstantExpression constructorInvocation;
    InitializersStructure initializers =
        computeInitializersStructure(constructor);
    for (InitializerStructure structure in initializers.initializers) {
      if (structure.isConstructorInvoke) {
        constructorInvocation = structure.dispatch(this, _);
      } else {
        structure.dispatch(this, _);
      }
    }
    return constructorInvocation;
  }

  visitFieldInitializer(SendSet node, FieldElement field, Node initializer, _) {
    fieldMap[field] = apply(initializer);
  }

  visitParameterGet(Send node, ParameterElement parameter, _) {
    if (parameter.isNamed) {
      return new NamedArgumentReference(parameter.name);
    } else {
      return new PositionalArgumentReference(
          parameter.functionDeclaration.parameters.indexOf(parameter));
    }
  }

  ConstructedConstantExpression visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    List<ConstantExpression> argumentExpression =
        arguments.nodes.map((a) => apply(a)).toList();
    return new ConstructedConstantExpression(
        type, superConstructor, callStructure, argumentExpression);
  }

  ConstructedConstantExpression visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      _) {
    return new ConstructedConstantExpression(type, superConstructor,
        CallStructure.NO_ARGS, const <ConstantExpression>[]);
  }

  ConstructedConstantExpression visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    List<ConstantExpression> argumentExpression =
        arguments.nodes.map((a) => apply(a)).toList();
    return new ConstructedConstantExpression(currentClass.thisType,
        thisConstructor, callStructure, argumentExpression);
  }

  @override
  ConstantExpression visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, _) {
    return new BinaryConstantExpression(apply(left), operator, apply(right));
  }

  @override
  ConstantExpression visitEquals(Send node, Node left, Node right, _) {
    return new BinaryConstantExpression(
        apply(left), BinaryOperator.EQ, apply(right));
  }

  @override
  ConstantExpression visitNotEquals(Send node, Node left, Node right, _) {
    return new BinaryConstantExpression(
        apply(left), BinaryOperator.NOT_EQ, apply(right));
  }

  @override
  ConstantExpression visitUnary(
      Send node, UnaryOperator operator, Node expression, _) {
    return new UnaryConstantExpression(operator, apply(expression));
  }

  @override
  ConstantExpression visitStaticFieldGet(Send node, FieldElement field, _) {
    return new FieldConstantExpression(field);
  }

  @override
  ConstantExpression visitTopLevelFunctionGet(
      Send node, MethodElement method, _) {
    return new FunctionConstantExpression(method, method.type);
  }

  @override
  ConstantExpression visitTopLevelFieldGet(Send node, FieldElement field, _) {
    return new FieldConstantExpression(field);
  }

  @override
  ConstantExpression visitLiteralInt(LiteralInt node) {
    return new IntConstantExpression(node.value);
  }

  @override
  ConstantExpression visitLiteralDouble(LiteralDouble node) {
    return new DoubleConstantExpression(node.value);
  }

  @override
  ConstantExpression visitLiteralBool(LiteralBool node) {
    return new BoolConstantExpression(node.value);
  }

  @override
  ConstantExpression visitLiteralNull(LiteralNull node) {
    return new NullConstantExpression();
  }

  @override
  ConstantExpression visitLiteralString(LiteralString node) {
    return new StringConstantExpression(node.dartString.slowToString());
  }

  @override
  ConstantExpression visitConditional(Conditional node) {
    return new ConditionalConstantExpression(apply(node.condition),
        apply(node.thenExpression), apply(node.elseExpression));
  }

  @override
  ConstantExpression visitParenthesizedExpression(
      ParenthesizedExpression node) {
    return apply(node.expression);
  }

  @override
  ConstantExpression visitTopLevelFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    if (function.name != 'identical' || !function.library.isDartCore) {
      throw new UnsupportedError("Unexpected function call: $function");
    }
    return new IdenticalConstantExpression(
        apply(arguments.nodes.head), apply(arguments.nodes.tail.head));
  }

  @override
  ConstantExpression visitNamedArgument(NamedArgument node) {
    return apply(node.expression);
  }

  @override
  ConstantExpression visitIfNull(Send node, Node left, Node right, _) {
    return new BinaryConstantExpression(
        apply(left), BinaryOperator.IF_NULL, apply(right));
  }
}
