// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.constructors;

import '../elements/elements.dart';
import 'expressions.dart';
import 'values.dart';
import '../dart_types.dart';
import '../resolution/resolution.dart';
import '../resolution/operators.dart';
import '../resolution/semantic_visitor.dart';
import '../resolution/send_structure.dart';
import '../dart2jslib.dart';
import '../tree/tree.dart';

ConstantConstructor computeConstantConstructor(ResolvedAst resolvedAst) {
  ConstantConstructorComputer visitor =
      new ConstantConstructorComputer(resolvedAst.elements);
  return resolvedAst.node.accept(visitor);
}

class ConstantConstructorComputer extends SemanticVisitor
    with SemanticDeclarationResolvedMixin,
         DeclarationResolverMixin,
         GetBulkMixin,
         SetBulkMixin,
         ErrorBulkMixin,
         InvokeBulkMixin,
         IndexSetBulkMixin,
         CompoundBulkMixin,
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
  final Map<dynamic/*int|String*/, ConstantExpression> defaultValues =
      <dynamic/*int|String*/, ConstantExpression>{};

  ConstantConstructorComputer(TreeElements elements)
      : super(elements);

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
    internalError(node, template.replaceFirst('#' , '$node'));
  }

  internalError(Node node, String message) {
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
        applyInitializers(initializers, _);
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
        applyInitializers(initializers, _);
    return new RedirectingGenerativeConstantConstructor(
        defaultValues, constructorInvocation);
  }

  ConstantConstructor visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      InterfaceType redirectionType,
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
        new ConstructedConstantExpression(null,
            redirectionType,
            redirectionTarget,
            callStructure,
            arguments));
  }

  @override
  visitFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      Node body, _) {
    // TODO(johnniwinther): Handle constant constructors with errors.
    internalError(node, "Factory constructor cannot be constant.");
  }

  applyParameters(NodeList parameters, _) {
    computeParameterStructures(parameters).forEach((s) => s.dispatch(this, _));
  }

  visitParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      int index,
      _) {
    // Do nothing.
  }

  visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    assert(invariant(node, defaultValue != null));
    defaultValues[index] = defaultValue;
  }

  visitNamedParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      _) {
    assert(invariant(node, defaultValue != null));
    String name = parameter.name;
    defaultValues[name] = defaultValue;
  }

  visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      int index,
      _) {
    fieldMap[parameter.fieldElement] = new PositionalArgumentReference(index);
  }

  visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    assert(invariant(node, defaultValue != null));
    defaultValues[index] = defaultValue;
    fieldMap[parameter.fieldElement] = new PositionalArgumentReference(index);
  }

  visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    assert(invariant(node, defaultValue != null));
    String name = parameter.name;
    defaultValues[name] = defaultValue;
    fieldMap[parameter.fieldElement] = new NamedArgumentReference(name);
  }

  /// Apply this visitor to the constructor [initializers].
  ConstructedConstantExpression applyInitializers(NodeList initializers, _) {
    ConstructedConstantExpression constructorInvocation;
    if (initializers != null) {
      for (Node initializer in initializers) {
        InitializerStructure structure =
            computeInitializerStructure(initializer);
        if (structure is SuperConstructorInvokeStructure ||
            structure is ThisConstructorInvokeStructure) {
          constructorInvocation = structure.dispatch(this, initializer, _);
        } else {
          structure.dispatch(this, initializer, _);
        }
      }
    }
    if (constructorInvocation == null && !currentClass.isObject) {
      constructorInvocation =
          new ConstructedConstantExpression(null,
              currentClass.supertype,
              currentClass.superclass.lookupDefaultConstructor(),
              CallStructure.NO_ARGS,
              const <ConstantExpression>[]);
    }
    return constructorInvocation;
  }

  visitFieldInitializer(
      SendSet node,
      FieldElement field,
      Node initializer,
      _) {
    fieldMap[field] = apply(initializer);
  }

  visitParameterGet(
      Send node,
      ParameterElement parameter,
      _) {
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
      InterfaceType type,
      NodeList arguments,
      Selector selector,
      _) {
    List<ConstantExpression> argumentExpression =
        arguments.nodes.map((a) => apply(a)).toList();
    return new ConstructedConstantExpression(null,
        type,
        superConstructor,
        selector.callStructure,
        argumentExpression);
  }

  ConstructedConstantExpression visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      Selector selector,
      _) {
    List<ConstantExpression> argumentExpression =
        arguments.nodes.map((a) => apply(a)).toList();
    return new ConstructedConstantExpression(null,
        currentClass.thisType,
        thisConstructor,
        selector.callStructure,
        argumentExpression);
  }

  @override
  ConstantExpression visitBinary(
      Send node,
      Node left,
      BinaryOperator operator,
      Node right,
      _) {
    return new BinaryConstantExpression(null,
        apply(left), operator, apply(right));
  }


  @override
  ConstantExpression visitUnary(
      Send node,
      UnaryOperator operator,
      Node expression,
      _) {
    return new UnaryConstantExpression(null,
        operator, apply(expression));
  }

  @override
  ConstantExpression visitStaticFieldGet(
      Send node,
      FieldElement field,
      _) {
    return new VariableConstantExpression(null, field);
  }

  @override
  ConstantExpression visitTopLevelFieldGet(
      Send node,
      FieldElement field,
      _) {
    return new VariableConstantExpression(null, field);
  }

  @override
  ConstantExpression visitLiteralInt(LiteralInt node) {
    return new IntConstantExpression(
        node.value, new IntConstantValue(node.value));
  }

  @override
  ConstantExpression visitLiteralBool(LiteralBool node) {
    return new BoolConstantExpression(node.value, null);
  }

  @override
  ConstantExpression visitLiteralNull(LiteralNull node) {
    return new NullConstantExpression(new NullConstantValue());
  }

  @override
  ConstantExpression visitLiteralString(LiteralString node) {
    return new StringConstantExpression(node.dartString.slowToString(), null);
  }

  @override
  ConstantExpression visitConditional(Conditional node) {
    return new ConditionalConstantExpression(null,
        apply(node.condition),
        apply(node.thenExpression),
        apply(node.elseExpression));
  }

  @override
  ConstantExpression visitParenthesizedExpression(ParenthesizedExpression node) {
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
        null, apply(arguments.nodes.head), apply(arguments.nodes.tail.head));
  }

  @override
  ConstantExpression visitNamedArgument(NamedArgument node) {
    return apply(node.expression);
  }
}