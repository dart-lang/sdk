// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/operators.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/util.dart';

/// Visitor that converts string literals and concatenations of string literals
/// into the string value.
class Stringifier extends ir.ExpressionVisitor<String> {
  @override
  String visitStringLiteral(ir.StringLiteral node) => node.value;

  @override
  String visitStringConcatenation(ir.StringConcatenation node) {
    StringBuffer sb = new StringBuffer();
    for (ir.Expression expression in node.expressions) {
      String value = expression.accept(this);
      if (value == null) return null;
      sb.write(value);
    }
    return sb.toString();
  }
}

/// Visitor that converts a kernel constant expression into a
/// [ConstantExpression].
class Constantifier extends ir.ExpressionVisitor<ConstantExpression> {
  final bool requireConstant;
  final IrToElementMap elementMap;
  ir.TreeNode failNode;
  final Map<ir.VariableDeclaration, ConstantExpression> _initializerLocals =
      <ir.VariableDeclaration, ConstantExpression>{};

  Constantifier(this.elementMap, {this.requireConstant: true});

  CommonElements get _commonElements => elementMap.commonElements;

  ConstantExpression visit(ir.Expression node) {
    ConstantExpression constant = node.accept(this);
    if (constant == null && requireConstant) {
      // TODO(johnniwinther): Support contextual error messages.
      elementMap.reporter.reportErrorMessage(
          computeSourceSpanFromTreeNode(failNode ?? node),
          MessageKind.NOT_A_COMPILE_TIME_CONSTANT);
      return new ErroneousConstantExpression();
    }
    return constant;
  }

  @override
  ConstantExpression defaultExpression(ir.Expression node) {
    if (requireConstant) {
      failNode ??= node;
    }
    return null;
  }

  List<ConstantExpression> _computeList(List<ir.Expression> expressions) {
    List<ConstantExpression> list = <ConstantExpression>[];
    for (ir.Expression expression in expressions) {
      ConstantExpression constant = visit(expression);
      if (constant == null) return null;
      list.add(constant);
    }
    return list;
  }

  List<ConstantExpression> _computeArguments(ir.Arguments node) {
    List<ConstantExpression> arguments = <ConstantExpression>[];
    for (ir.Expression argument in node.positional) {
      ConstantExpression constant = visit(argument);
      if (constant == null) return null;
      arguments.add(constant);
    }
    for (ir.NamedExpression argument in node.named) {
      ConstantExpression constant = visit(argument.value);
      if (constant == null) return null;
      arguments.add(constant);
    }
    return arguments;
  }

  ConstructedConstantExpression _computeConstructorInvocation(
      ir.Constructor target,
      ir.Arguments arguments,
      // TODO(johnniwinther): Remove this when correct type arguments are passed
      // through [arguments]. Current [ir.RedirectingInitializer] doesn't have
      // any type arguments.
      List<ir.DartType> types) {
    List<ConstantExpression> expressions = _computeArguments(arguments);
    if (expressions == null) return null;
    return new ConstructedConstantExpression(
        elementMap.createInterfaceType(target.enclosingClass, types),
        elementMap.getConstructor(target),
        elementMap.getCallStructure(arguments),
        expressions);
  }

  @override
  ConstantExpression visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (!node.isConst) return null;
    return _computeConstructorInvocation(
        node.target, node.arguments, node.arguments.types);
  }

  @override
  ConstantExpression visitVariableGet(ir.VariableGet node) {
    ConstantExpression constant = _initializerLocals[node.variable];
    if (constant != null) {
      return constant;
    }
    if (node.variable.parent is ir.FunctionNode) {
      ir.FunctionNode function = node.variable.parent;
      int index = function.positionalParameters.indexOf(node.variable);
      if (index != -1) {
        return new PositionalArgumentReference(index);
      } else {
        assert(function.namedParameters.contains(node.variable));
        return new NamedArgumentReference(node.variable.name);
      }
    } else if (node.variable.isConst) {
      return visit(node.variable.initializer);
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitStaticGet(ir.StaticGet node) {
    ir.Member target = node.target;
    if (target is ir.Field && target.isConst) {
      return new FieldConstantExpression(elementMap.getField(node.target));
    } else if (target is ir.Procedure &&
        target.kind == ir.ProcedureKind.Method) {
      FunctionEntity function = elementMap.getMethod(node.target);
      DartType type = elementMap.getFunctionType(node.target.function);
      return new FunctionConstantExpression(function, type);
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitNullLiteral(ir.NullLiteral node) {
    return new NullConstantExpression();
  }

  @override
  ConstantExpression visitBoolLiteral(ir.BoolLiteral node) {
    return new BoolConstantExpression(node.value);
  }

  @override
  ConstantExpression visitIntLiteral(ir.IntLiteral node) {
    return new IntConstantExpression(
        new BigInt.from(node.value).toUnsigned(64));
  }

  @override
  ConstantExpression visitDoubleLiteral(ir.DoubleLiteral node) {
    return new DoubleConstantExpression(node.value);
  }

  @override
  ConstantExpression visitStringLiteral(ir.StringLiteral node) {
    return new StringConstantExpression(node.value);
  }

  @override
  ConstantExpression visitSymbolLiteral(ir.SymbolLiteral node) {
    return new SymbolConstantExpression(node.value);
  }

  @override
  ConstantExpression visitStringConcatenation(ir.StringConcatenation node) {
    List<ConstantExpression> expressions = _computeList(node.expressions);
    if (expressions == null) return null;
    return new ConcatenateConstantExpression(expressions);
  }

  @override
  ConstantExpression visitMapLiteral(ir.MapLiteral node) {
    if (!node.isConst) {
      return defaultExpression(node);
    }
    DartType keyType = elementMap.getDartType(node.keyType);
    DartType valueType = elementMap.getDartType(node.valueType);
    List<ConstantExpression> keys = <ConstantExpression>[];
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.MapEntry entry in node.entries) {
      ConstantExpression key = visit(entry.key);
      if (key == null) return null;
      keys.add(key);
      ConstantExpression value = visit(entry.value);
      if (value == null) return null;
      values.add(value);
    }
    return new MapConstantExpression(
        _commonElements.mapType(keyType, valueType), keys, values);
  }

  @override
  ConstantExpression visitSetLiteral(ir.SetLiteral node) {
    if (!node.isConst) {
      return defaultExpression(node);
    }
    DartType elementType = elementMap.getDartType(node.typeArgument);
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.Expression expression in node.expressions) {
      ConstantExpression value = visit(expression);
      if (value == null) return null;
      values.add(value);
    }
    return new SetConstantExpression(
        _commonElements.setType(elementType), values);
  }

  @override
  ConstantExpression visitListLiteral(ir.ListLiteral node) {
    if (!node.isConst) {
      return defaultExpression(node);
    }
    DartType elementType = elementMap.getDartType(node.typeArgument);
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.Expression expression in node.expressions) {
      ConstantExpression value = visit(expression);
      if (value == null) return null;
      values.add(value);
    }
    return new ListConstantExpression(
        _commonElements.listType(elementType), values);
  }

  @override
  ConstantExpression visitTypeLiteral(ir.TypeLiteral node) {
    String name;
    DartType type = elementMap.getDartType(node.type);
    if (type.isDynamic) {
      name = 'dynamic';
    } else if (type is InterfaceType) {
      name = type.element.name;
    } else if (type.isTypedef) {
      // TODO(johnniwinther): Compute a name for the type literal? It is only
      // used in error messages in the old SSA builder.
      name = '?';
    } else if (node.type is ir.FunctionType) {
      ir.FunctionType functionType = node.type;
      assert(functionType.typedef != null);
      type = elementMap.getTypedefType(functionType.typedef);
      name = functionType.typedef.name;
    } else {
      return defaultExpression(node);
    }
    return new TypeConstantExpression(type, name);
  }

  @override
  ConstantExpression visitAsExpression(ir.AsExpression node) {
    ConstantExpression expression = visit(node.operand);
    if (expression == null) return null;
    DartType type = elementMap.getDartType(node.type);
    return new AsConstantExpression(expression, type);
  }

  @override
  ConstantExpression visitInstantiation(ir.Instantiation node) {
    List<DartType> typeArguments =
        node.typeArguments.map(elementMap.getDartType).toList();
    for (DartType typeArgument in typeArguments) {
      if (typeArgument.containsTypeVariables) {
        return null;
      }
    }
    ConstantExpression expression = visit(node.expression);
    if (expression == null) return null;
    return new InstantiationConstantExpression(typeArguments, expression);
  }

  @override
  ConstantExpression visitNot(ir.Not node) {
    ConstantExpression expression = visit(node.operand);
    if (expression == null) return null;
    return new UnaryConstantExpression(UnaryOperator.NOT, expression);
  }

  @override
  ConstantExpression visitConditionalExpression(ir.ConditionalExpression node) {
    ConstantExpression condition = visit(node.condition);
    if (condition == null) return null;
    ConstantExpression trueExp = visit(node.then);
    if (trueExp == null) return null;
    ConstantExpression falseExp = visit(node.otherwise);
    if (falseExp == null) return null;
    return new ConditionalConstantExpression(condition, trueExp, falseExp);
  }

  @override
  ConstantExpression visitPropertyGet(ir.PropertyGet node) {
    if (node.name.name != 'length') {
      failNode ??= node;
      return null;
    }
    ConstantExpression receiver = visit(node.receiver);
    if (receiver == null) return null;
    return new StringLengthConstantExpression(receiver);
  }

  @override
  ConstantExpression visitMethodInvocation(ir.MethodInvocation node) {
    // Method invocations are generally not constant expressions but unary
    // and binary expressions are encoded as method invocations in kernel.
    if (node.arguments.named.isNotEmpty) {
      return defaultExpression(node);
    }
    if (node.arguments.positional.length == 0) {
      UnaryOperator operator;
      if (node.name.name == UnaryOperator.NEGATE.selectorName) {
        operator = UnaryOperator.NEGATE;
      } else {
        operator = UnaryOperator.parse(node.name.name);
      }
      if (operator != null) {
        ConstantExpression expression = visit(node.receiver);
        if (expression == null) return null;
        return new UnaryConstantExpression(operator, expression);
      }
    }
    if (node.arguments.positional.length == 1) {
      BinaryOperator operator = BinaryOperator.parse(node.name.name);
      if (operator != null) {
        ConstantExpression left = visit(node.receiver);
        if (left == null) return null;
        ConstantExpression right = visit(node.arguments.positional.single);
        if (right == null) return null;
        return new BinaryConstantExpression(left, operator, right);
      }
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitStaticInvocation(ir.StaticInvocation node) {
    MemberEntity member = elementMap.getMember(node.target);
    if (member == _commonElements.identicalFunction) {
      if (node.arguments.positional.length == 2 &&
          node.arguments.named.isEmpty) {
        ConstantExpression left = visit(node.arguments.positional[0]);
        if (left == null) return null;
        ConstantExpression right = visit(node.arguments.positional[1]);
        if (right == null) return null;
        return new IdenticalConstantExpression(left, right);
      }
    } else if (member.name == 'fromEnvironment' &&
        node.arguments.positional.length == 1) {
      ConstantExpression name = visit(node.arguments.positional.single);
      if (name == null) return null;
      ConstantExpression defaultValue;
      if (node.arguments.named.length == 1) {
        if (node.arguments.named.single.name != 'defaultValue') {
          return defaultExpression(node);
        }
        defaultValue = visit(node.arguments.named.single.value);
        if (defaultValue == null) return null;
      }
      if (member.enclosingClass == _commonElements.boolClass) {
        return new BoolFromEnvironmentConstantExpression(name, defaultValue);
      } else if (member.enclosingClass == _commonElements.intClass) {
        return new IntFromEnvironmentConstantExpression(name, defaultValue);
      } else if (member.enclosingClass == _commonElements.stringClass) {
        return new StringFromEnvironmentConstantExpression(name, defaultValue);
      }
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitLogicalExpression(ir.LogicalExpression node) {
    BinaryOperator operator = BinaryOperator.parse(node.operator);
    if (operator != null &&
        BinaryConstantExpression.potentialOperator(operator)) {
      ConstantExpression left = visit(node.left);
      if (left == null) return null;
      ConstantExpression right = visit(node.right);
      if (right == null) return null;
      return new BinaryConstantExpression(left, operator, right);
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitLet(ir.Let node) {
    ir.Expression body = node.body;
    if (body is ir.ConditionalExpression) {
      ir.Expression condition = body.condition;
      if (condition is ir.MethodInvocation) {
        ir.Expression receiver = condition.receiver;
        ir.Expression otherwise = body.otherwise;
        if (condition.name.name == BinaryOperator.EQ.name &&
            receiver is ir.VariableGet &&
            condition.arguments.positional.single is ir.NullLiteral &&
            otherwise is ir.VariableGet) {
          if (receiver.variable == node.variable &&
              otherwise.variable == node.variable) {
            // We have <left> ?? <right> encoded as:
            //    let #1 = <left> in #1 == null ? <right> : #1
            ConstantExpression left = visit(node.variable.initializer);
            if (left == null) return null;
            ConstantExpression right = visit(body.then);
            if (right == null) return null;
            // TODO(johnniwinther): Remove [IF_NULL] binary constant expression
            // when the resolver is removed; then we no longer need the
            // expressions to be structurally equivalence for equivalence
            // testing.
            return new BinaryConstantExpression(
                left, BinaryOperator.IF_NULL, right);
          }
        }
      }
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitBlockExpression(ir.BlockExpression node) {
    return defaultExpression(node);
  }

  /// Compute the [ConstantConstructor] corresponding to the const constructor
  /// [node].
  ConstantConstructor computeConstantConstructor(ir.Constructor node) {
    assert(node.isConst);
    ir.Class cls = node.enclosingClass;
    InterfaceType type = elementMap.getThisType(elementMap.getClass(cls));

    Map<dynamic, ConstantExpression> defaultValues =
        <dynamic, ConstantExpression>{};
    int parameterIndex = 0;
    for (ir.VariableDeclaration parameter
        in node.function.positionalParameters) {
      if (parameterIndex >= node.function.requiredParameterCount) {
        ConstantExpression defaultValue;
        if (parameter.initializer != null) {
          defaultValue = visit(parameter.initializer);
        } else {
          defaultValue = new NullConstantExpression();
        }
        if (defaultValue == null) return null;
        defaultValues[parameterIndex] = defaultValue;
      }
      parameterIndex++;
    }
    for (ir.VariableDeclaration parameter in node.function.namedParameters) {
      ConstantExpression defaultValue = visit(parameter.initializer);
      if (defaultValue == null) return null;
      defaultValues[parameter.name] = defaultValue;
    }

    bool isRedirecting = node.initializers.length == 1 &&
        node.initializers.single is ir.RedirectingInitializer;

    Map<FieldEntity, ConstantExpression> fieldMap =
        <FieldEntity, ConstantExpression>{};

    void registerField(ir.Field field, ConstantExpression constant) {
      fieldMap[elementMap.getField(field)] = constant;
    }

    if (!isRedirecting) {
      for (ir.Field field in cls.fields) {
        if (field.isStatic) continue;
        if (field.initializer != null) {
          registerField(field, visit(field.initializer));
        }
      }
    }

    ConstructedConstantExpression superConstructorInvocation;
    List<AssertConstantExpression> assertions = <AssertConstantExpression>[];
    for (ir.Initializer initializer in node.initializers) {
      if (initializer is ir.FieldInitializer) {
        registerField(initializer.field, visit(initializer.value));
      } else if (initializer is ir.SuperInitializer) {
        superConstructorInvocation = _computeConstructorInvocation(
            initializer.target,
            initializer.arguments,
            initializer.arguments.types);
      } else if (initializer is ir.RedirectingInitializer) {
        superConstructorInvocation = _computeConstructorInvocation(
            initializer.target,
            initializer.arguments,
            node.enclosingClass.thisType.typeArguments);
      } else if (initializer is ir.AssertInitializer) {
        ConstantExpression condition = visit(initializer.statement.condition);
        ConstantExpression message = initializer.statement.message != null
            ? visit(initializer.statement.message)
            : null;
        assertions.add(new AssertConstantExpression(condition, message));
      } else if (initializer is ir.InvalidInitializer) {
        String constructorName = '${cls.name}.${node.name}';
        elementMap.reporter.reportErrorMessage(
            computeSourceSpanFromTreeNode(initializer),
            MessageKind.INVALID_CONSTANT_CONSTRUCTOR,
            {'constructorName': constructorName});
        return new ErroneousConstantConstructor();
      } else if (initializer is ir.LocalInitializer) {
        ir.VariableDeclaration variable = initializer.variable;
        ConstantExpression constant = visit(variable.initializer);
        if (constant != null) {
          _initializerLocals[variable] = constant;
        } else {
          // TODO(johnniwinther): Use [_ErroneousInitializerVisitor] in
          // `ssa/builder_kernel.dart` to identify erroneous initializer.
          String constructorName = '${cls.name}.${node.name}';
          elementMap.reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(initializer),
              MessageKind.INVALID_CONSTANT_CONSTRUCTOR,
              {'constructorName': constructorName});
          return new ErroneousConstantConstructor();
        }
      } else {
        throw new UnsupportedError(
            'Unexpected initializer $initializer (${initializer.runtimeType})');
      }
    }
    if (isRedirecting) {
      return new RedirectingGenerativeConstantConstructor(
          defaultValues, superConstructorInvocation);
    } else {
      return new GenerativeConstantConstructor(type, defaultValues, fieldMap,
          assertions, superConstructorInvocation);
    }
  }
}

/// Visitor that converts kernel dart types into [DartType].
class DartTypeConverter extends ir.DartTypeVisitor<DartType> {
  final IrToElementMap elementMap;
  final Map<ir.TypeParameter, DartType> currentFunctionTypeParameters =
      <ir.TypeParameter, DartType>{};
  bool topLevel = true;

  DartTypeConverter(this.elementMap);

  DartType convert(ir.DartType type) {
    topLevel = true;
    return type.accept(this);
  }

  /// Visit a inner type.
  DartType visitType(ir.DartType type) {
    topLevel = false;
    return type.accept(this);
  }

  InterfaceType visitSupertype(ir.Supertype node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
    return new InterfaceType(cls, visitTypes(node.typeArguments));
  }

  List<DartType> visitTypes(List<ir.DartType> types) {
    topLevel = false;
    return new List.generate(
        types.length, (int index) => types[index].accept(this));
  }

  @override
  DartType visitTypeParameterType(ir.TypeParameterType node) {
    DartType typeParameter = currentFunctionTypeParameters[node.parameter];
    if (typeParameter != null) {
      return typeParameter;
    }
    if (node.parameter.parent is ir.Typedef) {
      // Typedefs are only used in type literals so we never need their type
      // variables.
      return const DynamicType();
    }
    return new TypeVariableType(elementMap.getTypeVariable(node.parameter));
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    int index = 0;
    List<FunctionTypeVariable> typeVariables;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      FunctionTypeVariable typeVariable = new FunctionTypeVariable(index);
      currentFunctionTypeParameters[typeParameter] = typeVariable;
      typeVariables ??= <FunctionTypeVariable>[];
      typeVariables.add(typeVariable);
      index++;
    }
    if (typeVariables != null) {
      for (int index = 0; index < typeVariables.length; index++) {
        typeVariables[index].bound =
            node.typeParameters[index].bound.accept(this);
      }
    }

    FunctionType type = new FunctionType(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.map((n) => n.name).toList(),
        node.namedParameters.map((n) => visitType(n.type)).toList(),
        typeVariables ?? const <FunctionTypeVariable>[]);
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      currentFunctionTypeParameters.remove(typeParameter);
    }
    return type;
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
    if (cls.name == 'FutureOr' &&
        cls.library == elementMap.commonElements.asyncLibrary) {
      return new FutureOrType(visitTypes(node.typeArguments).single);
    }
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
    // Root uses such a `o is Unresolved` and `o as Unresolved` must be special
    // cased in the builder, nested invalid types are treated as `dynamic`.
    return const DynamicType();
  }

  @override
  DartType visitBottomType(ir.BottomType node) {
    return elementMap.commonElements.nullType;
  }
}

class ConstantValuefier extends ir.ComputeOnceConstantVisitor<ConstantValue> {
  final IrToElementMap elementMap;

  ConstantValuefier(this.elementMap);

  @override
  ConstantValue defaultConstant(ir.Constant node) {
    throw new UnsupportedError(
        "Unexpected constant $node (${node.runtimeType}).");
  }

  @override
  ConstantValue visitUnevaluatedConstant(ir.UnevaluatedConstant node) {
    throw new UnsupportedError("Unexpected unevaluated constant $node.");
  }

  @override
  ConstantValue visitTypeLiteralConstant(ir.TypeLiteralConstant node) {
    return constant_system.createType(
        elementMap.commonElements, elementMap.getDartType(node.type));
  }

  @override
  ConstantValue visitTearOffConstant(ir.TearOffConstant node) {
    FunctionEntity function = elementMap.getMethod(node.procedure);
    DartType type = elementMap.getFunctionType(node.procedure.function);
    return new FunctionConstantValue(function, type);
  }

  @override
  ConstantValue visitPartialInstantiationConstant(
      ir.PartialInstantiationConstant node) {
    List<DartType> typeArguments = [];
    for (ir.DartType type in node.types) {
      typeArguments.add(elementMap.getDartType(type));
    }
    FunctionConstantValue function = visitConstant(node.tearOffConstant);
    return new InstantiationConstantValue(typeArguments, function);
  }

  @override
  ConstantValue visitInstanceConstant(ir.InstanceConstant node) {
    InterfaceType type =
        elementMap.createInterfaceType(node.classNode, node.typeArguments);
    Map<FieldEntity, ConstantValue> fields = {};
    node.fieldValues.forEach((ir.Reference reference, ir.Constant value) {
      FieldEntity field = elementMap.getField(reference.asField);
      fields[field] = visitConstant(value);
    });
    return new ConstructedConstantValue(type, fields);
  }

  @override
  ConstantValue visitListConstant(ir.ListConstant node) {
    List<ConstantValue> elements = [];
    for (ir.Constant element in node.entries) {
      elements.add(visitConstant(element));
    }
    DartType type = elementMap.commonElements
        .listType(elementMap.getDartType(node.typeArgument));
    return constant_system.createList(type, elements);
  }

  @override
  ConstantValue visitSetConstant(ir.SetConstant node) {
    List<ConstantValue> elements = [];
    for (ir.Constant element in node.entries) {
      elements.add(visitConstant(element));
    }
    DartType type = elementMap.commonElements
        .setType(elementMap.getDartType(node.typeArgument));
    return constant_system.createSet(elementMap.commonElements, type, elements);
  }

  @override
  ConstantValue visitMapConstant(ir.MapConstant node) {
    List<ConstantValue> keys = [];
    List<ConstantValue> values = [];
    for (ir.ConstantMapEntry element in node.entries) {
      keys.add(visitConstant(element.key));
      values.add(visitConstant(element.value));
    }
    DartType type = elementMap.commonElements.mapType(
        elementMap.getDartType(node.keyType),
        elementMap.getDartType(node.valueType));
    return constant_system.createMap(
        elementMap.commonElements, type, keys, values);
  }

  @override
  ConstantValue visitSymbolConstant(ir.SymbolConstant node) {
    return constant_system.createSymbol(elementMap.commonElements, node.name);
  }

  @override
  ConstantValue visitStringConstant(ir.StringConstant node) {
    return constant_system.createString(node.value);
  }

  @override
  ConstantValue visitDoubleConstant(ir.DoubleConstant node) {
    return constant_system.createDouble(node.value);
  }

  @override
  ConstantValue visitIntConstant(ir.IntConstant node) {
    return constant_system.createIntFromInt(node.value);
  }

  @override
  ConstantValue visitBoolConstant(ir.BoolConstant node) {
    return constant_system.createBool(node.value);
  }

  @override
  ConstantValue visitNullConstant(ir.NullConstant node) {
    return constant_system.createNull();
  }
}
