// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/ast_to_ir_types.dart';
import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/flow_graph_builder.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/local_variable.dart';
import 'package:cfg/ir/source_position.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart' show StaticTypeContext;

/// Translates kernel AST to the flow graph.
///
/// Not implemented yet:
///  - non-regular functions;
///  - parameter type checks;
///  - closures (including tear-offs and calls);
///  - captured variables;
///  - late variables;
///  - stack overflow/interrupt checks;
///  - assert statements;
///  - async/async*/sync*/await/yield/yield*;
///  - record access and literals;
///  - deferred libraries.
///
class AstToIr extends ast.RecursiveVisitor {
  final CFunction function;
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final FunctionRegistry functionRegistry;
  final RecognizedMethods recognizedMethods;
  final FlowGraphBuilder builder;
  final bool enableAsserts;
  late final AstToIrTypes _typeTranslator;
  late final LocalVariableIndexer localVarIndexer;
  late final StaticTypeContext _staticTypeContext = StaticTypeContext(
    function.member,
    GlobalContext.instance.typeEnvironment,
  );

  Map<ast.LabeledStatement, JoinBlock>? labeledStatements;
  Map<ast.SwitchCase, JoinBlock>? switchCases;
  Map<ast.TryFinally, List<FinallyBlock>>? finallyBlocks;
  TypeParameters? typeParameters;

  AstToIr(
    this.function,
    this.functionRegistry,
    this.recognizedMethods, {
    required this.enableAsserts,
  }) : coreTypes = GlobalContext.instance.coreTypes,
       hierarchy = GlobalContext.instance.classHierarchy,
       builder = FlowGraphBuilder(function) {
    assert(!function.member.isAbstract);
    _typeTranslator = GlobalContext.instance.astToIrTypes;
    localVarIndexer = LocalVariableIndexer(
      builder,
      coreTypes,
      _typeTranslator,
      function,
    );
  }

  /// Create [FlowGraph] for the body of the [function].
  FlowGraph buildFlowGraph() {
    for (final param in localVarIndexer.parameters) {
      builder.addParameter(param);
    }
    if (function.hasClassTypeParameters) {
      builder.addLoadLocal(localVarIndexer.receiver);
      typeParameters = builder.addTypeParameters(receiver: builder.pop());
    } else if (function.hasFunctionTypeParameters) {
      typeParameters = builder.addTypeParameters();
    }
    final member = function.member;
    switch (function) {
      case ImplicitFieldGetter():
        _buildImplicitGetter(member as ast.Field);
      case ImplicitFieldSetter():
        _buildImplicitSetter(member as ast.Field);
      case FieldInitializerFunction():
        _translateNode((member as ast.Field).initializer!);
        if (builder.hasOpenBlock) {
          builder.addReturn();
        }
      case RegularFunction() || GetterFunction() || SetterFunction():
        _translateNode(member.function?.body);
      case GenerativeConstructor():
        _translateConstructorInitializers(member as ast.Constructor);
        _translateNode(member.function.body);
      case LocalFunction() || TearOffFunction():
        throw 'Unimplemented buildFlowGraph for ${function.runtimeType}';
    }
    if (builder.hasOpenBlock) {
      builder.addNullConstant();
      builder.addReturn();
    }
    return builder.done();
  }

  void _buildImplicitGetter(ast.Field node) {
    final field = CField(node);
    if (node.isStatic) {
      builder.addLoadStaticField(
        field,
        checkInitialized: field.isLate || field.hasInitializer,
      );
    } else {
      builder.addLoadLocal(localVarIndexer.receiver);
      builder.addLoadInstanceField(field, checkInitialized: field.isLate);
    }
    builder.addReturn();
  }

  void _buildImplicitSetter(ast.Field node) {
    final field = CField(node);
    if (node.isStatic) {
      builder.addLoadLocal(localVarIndexer.parameters.last);
      builder.addStoreStaticField(
        field,
        checkNotInitialized: field.isLate && field.isFinal,
      );
    } else {
      builder.addLoadLocal(localVarIndexer.receiver);
      builder.addLoadLocal(localVarIndexer.parameters.last);
      builder.addStoreInstanceField(
        field,
        checkNotInitialized: field.isLate && field.isFinal,
      );
    }
  }

  void _translateNode(ast.TreeNode? node) {
    if (node == null) {
      return;
    }
    if (!builder.hasOpenBlock) {
      switch (node) {
        case ast.Expression():
          _handleUnreachableExpression(0);
          return;
        case ast.Statement():
          return;
        default:
          throw 'Unexpected ${node.runtimeType} $node';
      }
    }
    final savedSourcePosition = builder.currentSourcePosition;
    builder.currentSourcePosition = SourcePosition(node.fileOffset);
    node.accept(this);
    builder.currentSourcePosition = savedSourcePosition;
  }

  void _translateNodes(List<ast.TreeNode> nodes) {
    for (final node in nodes) {
      _translateNode(node);
    }
  }

  void _translateConstructorInitializers(ast.Constructor node) {
    var isRedirecting = false;
    final initializedFields = <ast.Field>{};
    for (final initializer in node.initializers) {
      if (initializer is ast.RedirectingInitializer) {
        isRedirecting = true;
      } else if (initializer is ast.FieldInitializer) {
        initializedFields.add(initializer.field);
      }
    }

    if (!isRedirecting) {
      for (final field in node.enclosingClass.fields) {
        if (!field.isStatic) {
          if (field.isLate) {
            if (!initializedFields.contains(field)) {
              throw 'Unimplemented: _initLateInstanceField';
            }
          } else {
            final fieldInitializer = field.initializer;
            if (fieldInitializer != null) {
              if (initializedFields.contains(field)) {
                // Do not store a value into the field as it is going to be
                // overwritten by initializers list.
                _translateNode(fieldInitializer);
                builder.pop();
                if (!builder.hasOpenBlock) return;
              } else {
                builder.addLoadLocal(localVarIndexer.receiver);
                _translateNode(fieldInitializer);
                if (!builder.hasOpenBlock) {
                  builder.drop(2);
                  return;
                }
                builder.addStoreInstanceField(CField(field));
              }
            }
          }
        }
      }
    }

    _translateNodes(node.initializers);
  }

  /// If this expression is unreachable, then maintain expression stack
  /// balance without appending IR instructions and return `true`.
  bool _handleUnreachableExpression(int inputCount) {
    if (!builder.hasOpenBlock) {
      builder.drop(inputCount);
      builder.addNullConstant();
      return true;
    }
    return false;
  }

  /// Translate [receiver] and [arguments] expressions.
  /// Returns number of arguments pushed onto expression stack.
  /// Use [_handleUnreachableExpression] after calling this method in case
  /// any of the argument expressions ended control flow.
  int _translateArguments(ast.Expression? receiver, ast.Arguments arguments) {
    assert(builder.hasOpenBlock);
    var inputCount = 0;
    if (arguments.types.isNotEmpty) {
      builder.addTypeArguments(
        arguments.types,
        typeParameters: _typeParametersForTypes(arguments.types),
      );
      ++inputCount;
    }
    if (receiver != null) {
      _translateNode(receiver);
      ++inputCount;
    }
    _translateNodes(arguments.positional);
    inputCount += arguments.positional.length;
    for (final namedExpr in arguments.named) {
      _translateNode(namedExpr.value);
    }
    inputCount += arguments.named.length;
    return inputCount;
  }

  ArgumentsShape _translateArgumentsShape(
    int implicitArgs,
    ast.Arguments args,
  ) => functionRegistry.getArgumentsShape(
    implicitArgs + args.positional.length,
    types: args.types.length,
    named: args.named.map((ne) => ne.name).toList(),
  );

  CType _staticType(ast.Expression node) =>
      _typeTranslator.translate(node.getStaticType(_staticTypeContext));

  List<CType> _argumentTypes(ast.Expression? receiver, ast.Arguments args) => [
    if (receiver != null) _staticType(receiver),
    for (final arg in args.positional) _staticType(arg),
    for (final arg in args.named) _staticType(arg.value),
  ];

  /// Joins control flow from the given [blocks].
  ///
  /// If [needNewJoinBlock], then the result is a new [JoinBlock] even
  /// if there was only one block in [blocks].
  Block _joinBlocks(List<Block> blocks, {bool needNewJoinBlock = false}) {
    assert(blocks.isNotEmpty);
    if (blocks.length == 1 && !needNewJoinBlock) {
      return blocks.single;
    }
    final join = builder.newJoinBlock();
    for (final block in blocks) {
      assert(block.next == null);
      builder.startBlock(block);
      builder.addGoto(join);
    }
    return join;
  }

  /// Translates given [condition] and returns a pair of
  /// (true blocks, false blocks).
  (List<Block>, List<Block>) _translateConditionForControl(
    ast.Expression condition,
  ) {
    switch (condition) {
      case ast.Not():
        var (trueBlocks, falseBlocks) = _translateConditionForControl(
          condition.operand,
        );
        return (falseBlocks, trueBlocks);
      case ast.LogicalExpression():
        var (leftTrue, leftFalse) = _translateConditionForControl(
          condition.left,
        );
        switch (condition.operatorEnum) {
          case ast.LogicalExpressionOperator.AND:
            if (leftTrue.isEmpty) {
              return ([], leftFalse);
            }
            builder.startBlock(_joinBlocks(leftTrue));
            var (rightTrue, rightFalse) = _translateConditionForControl(
              condition.right,
            );
            return (rightTrue, [...leftFalse, ...rightFalse]);
          case ast.LogicalExpressionOperator.OR:
            if (leftFalse.isEmpty) {
              return (leftTrue, []);
            }
            builder.startBlock(_joinBlocks(leftFalse));
            var (rightTrue, rightFalse) = _translateConditionForControl(
              condition.right,
            );
            return ([...leftTrue, ...rightTrue], rightFalse);
        }
      case _:
        _translateNode(condition);
        if (!builder.hasOpenBlock) {
          builder.pop();
          return ([], []);
        }
        final trueBlock = builder.newTargetBlock();
        final falseBlock = builder.newTargetBlock();
        builder.addBranch(trueBlock, falseBlock);
        return ([trueBlock], [falseBlock]);
    }
  }

  bool _hasTypeParameterReferences(ast.DartType type) =>
      type.accept(const _FindTypeParameters());

  TypeParameters? _typeParametersForType(ast.DartType type) {
    if (typeParameters != null && _hasTypeParameterReferences(type)) {
      return typeParameters;
    }
    return null;
  }

  TypeParameters? _typeParametersForTypes(List<ast.DartType> types) {
    if (typeParameters != null) {
      for (final type in types) {
        if (_hasTypeParameterReferences(type)) {
          return typeParameters;
        }
      }
    }
    return null;
  }

  @override
  void defaultTreeNode(ast.Node node) =>
      throw 'Unsupported node ${node.runtimeType}';

  @override
  void visitIntLiteral(ast.IntLiteral node) {
    builder.addIntConstant(node.value);
  }

  @override
  void visitBoolLiteral(ast.BoolLiteral node) {
    builder.addBoolConstant(node.value);
  }

  @override
  void visitDoubleLiteral(ast.DoubleLiteral node) {
    builder.addConstant(ConstantValue.fromDouble(node.value));
  }

  @override
  void visitStringLiteral(ast.StringLiteral node) {
    builder.addConstant(ConstantValue.fromString(node.value));
  }

  @override
  void visitNullLiteral(ast.NullLiteral node) {
    builder.addNullConstant();
  }

  @override
  void visitTypeLiteral(ast.TypeLiteral node) {
    final typeParameters = _typeParametersForType(node.type);
    if (typeParameters != null) {
      builder.addTypeLiteral(node.type, typeParameters: typeParameters);
    } else {
      builder.addConstant(ConstantValue(ast.TypeLiteralConstant(node.type)));
    }
  }

  @override
  void visitListLiteral(ast.ListLiteral node) {
    assert(!node.isConst);
    final inputCount = node.expressions.length + 1;
    builder.addTypeArguments([
      node.typeArgument,
    ], typeParameters: _typeParametersForType(node.typeArgument));
    _translateNodes(node.expressions);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addAllocateListLiteral(_staticType(node), inputCount);
  }

  @override
  void visitMapLiteral(ast.MapLiteral node) {
    assert(!node.isConst);
    final inputCount = (node.entries.length << 1) + 1;
    final typeArgs = <ast.DartType>[node.keyType, node.valueType];
    builder.addTypeArguments(
      typeArgs,
      typeParameters: _typeParametersForTypes(typeArgs),
    );
    for (final entry in node.entries) {
      _translateNode(entry.key);
      _translateNode(entry.value);
    }
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addAllocateMapLiteral(_staticType(node), inputCount);
  }

  @override
  void visitConstantExpression(ast.ConstantExpression node) {
    builder.addConstant(ConstantValue(node.constant));
  }

  @override
  void visitReturnStatement(ast.ReturnStatement node) {
    final expr = node.expression;
    if (expr != null) {
      _translateNode(expr);
    } else {
      builder.addNullConstant();
    }
    final value = builder.pop();
    _generateNonLocalControlTransfer(node, null, () {
      builder.push(value);
      builder.addReturn();
    });
  }

  @override
  void visitBlock(ast.Block node) {
    _translateNodes(node.statements);
  }

  @override
  void visitAssertBlock(ast.AssertBlock node) {
    if (enableAsserts) {
      _translateNodes(node.statements);
    }
  }

  @override
  void visitAssertStatement(ast.AssertStatement node) {
    if (!enableAsserts) {
      return;
    }
    throw 'unimplemented';
  }

  @override
  void visitEmptyStatement(ast.EmptyStatement node) {
    // no-op
  }

  @override
  void visitBlockExpression(ast.BlockExpression node) {
    _translateNodes(node.body.statements);
    _translateNode(node.value);
  }

  @override
  void visitExpressionStatement(ast.ExpressionStatement node) {
    _translateNode(node.expression);
    builder.pop();
  }

  @override
  void visitStaticInvocation(ast.StaticInvocation node) {
    assert(!node.isConst);
    final args = node.arguments;
    final target = functionRegistry.getFunction(node.target);
    final inputCount = _translateArguments(null, args);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addDirectCall(
      target,
      inputCount,
      _translateArgumentsShape(0, args),
      _staticType(node),
    );
  }

  @override
  void visitStaticGet(ast.StaticGet node) {
    final member = node.target;
    if (member is ast.Field) {
      final field = CField(member);
      builder.addLoadStaticField(
        field,
        checkInitialized: field.isLate || field.hasInitializer,
      );
    } else {
      final target = functionRegistry.getFunction(node.target, isGetter: true);
      builder.addDirectCall(
        target,
        0,
        functionRegistry.getArgumentsShape(0),
        _staticType(node),
      );
    }
  }

  @override
  void visitStaticSet(ast.StaticSet node) {
    _translateNode(node.value);
    if (_handleUnreachableExpression(1)) return;
    final value = builder.stackTop;
    final member = node.target;
    if (member is ast.Field) {
      final field = CField(member);
      builder.addStoreStaticField(
        field,
        checkNotInitialized: field.isLate && field.isFinal,
      );
    } else {
      final target = functionRegistry.getFunction(node.target, isSetter: true);
      builder.addDirectCall(
        target,
        1,
        functionRegistry.getArgumentsShape(1),
        const TopType(const ast.VoidType()),
      );
      builder.pop();
    }
    builder.push(value);
  }

  @override
  void visitInstanceInvocation(ast.InstanceInvocation node) {
    final args = node.arguments;
    final interfaceTarget = functionRegistry.getFunction(node.interfaceTarget);
    final inputCount = _translateArguments(node.receiver, args);
    if (_handleUnreachableExpression(inputCount)) return;
    final matcher = recognizedMethods.instanceInvocations[node.interfaceTarget];
    if (matcher != null) {
      final snippet = matcher.match(_argumentTypes(node.receiver, args));
      if (snippet != null) {
        snippet(builder);
        return;
      }
    }
    builder.addInterfaceCall(
      interfaceTarget,
      inputCount,
      _translateArgumentsShape(1, args),
      _staticType(node),
    );
  }

  @override
  void visitInstanceGet(ast.InstanceGet node) {
    final interfaceTarget = functionRegistry.getFunction(
      node.interfaceTarget,
      isGetter: true,
    );
    _translateNode(node.receiver);
    if (_handleUnreachableExpression(1)) return;
    final matcher = recognizedMethods.instanceGetters[node.interfaceTarget];
    if (matcher != null) {
      final snippet = matcher.match([_staticType(node.receiver)]);
      if (snippet != null) {
        snippet(builder);
        return;
      }
    }
    builder.addInterfaceCall(
      interfaceTarget,
      1,
      functionRegistry.getArgumentsShape(1),
      _staticType(node),
    );
  }

  @override
  void visitInstanceSet(ast.InstanceSet node) {
    final interfaceTarget = functionRegistry.getFunction(
      node.interfaceTarget,
      isSetter: true,
    );
    _translateNode(node.receiver);
    _translateNode(node.value);
    if (_handleUnreachableExpression(2)) return;
    final value = builder.stackTop;
    builder.addInterfaceCall(
      interfaceTarget,
      2,
      functionRegistry.getArgumentsShape(2),
      const TopType(const ast.VoidType()),
    );
    builder.pop();
    builder.push(value);
  }

  @override
  void visitInstanceTearOff(ast.InstanceTearOff node) {
    final interfaceTarget = functionRegistry.getFunction(
      node.interfaceTarget,
      isTearOff: true,
    );
    _translateNode(node.receiver);
    if (_handleUnreachableExpression(1)) return;
    builder.addInterfaceCall(
      interfaceTarget,
      1,
      functionRegistry.getArgumentsShape(1),
      _staticType(node),
    );
  }

  @override
  void visitEqualsCall(ast.EqualsCall node) {
    _translateNode(node.left);
    _translateNode(node.right);
    if (_handleUnreachableExpression(2)) return;
    final interfaceTarget = functionRegistry.getFunction(node.interfaceTarget);
    final matcher = recognizedMethods.instanceInvocations[node.interfaceTarget];
    if (matcher != null) {
      final snippet = matcher.match([
        _staticType(node.left),
        _staticType(node.right),
      ]);
      if (snippet != null) {
        snippet(builder);
        return;
      }
    }
    builder.addInterfaceCall(
      interfaceTarget,
      2,
      functionRegistry.getArgumentsShape(2),
      const BoolType(),
    );
  }

  @override
  void visitEqualsNull(ast.EqualsNull node) {
    _translateNode(node.expression);
    if (_handleUnreachableExpression(1)) return;
    builder.addNullConstant();
    builder.addComparison(ComparisonOpcode.equal);
  }

  @override
  void visitDynamicInvocation(ast.DynamicInvocation node) {
    final args = node.arguments;
    final inputCount = _translateArguments(node.receiver, args);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addDynamicCall(
      node.name,
      DynamicCallKind.method,
      inputCount,
      _translateArgumentsShape(1, args),
    );
  }

  @override
  void visitDynamicGet(ast.DynamicGet node) {
    _translateNode(node.receiver);
    if (_handleUnreachableExpression(1)) return;
    builder.addDynamicCall(
      node.name,
      DynamicCallKind.getter,
      1,
      functionRegistry.getArgumentsShape(1),
    );
  }

  @override
  void visitDynamicSet(ast.DynamicSet node) {
    _translateNode(node.receiver);
    _translateNode(node.value);
    if (_handleUnreachableExpression(2)) return;
    final value = builder.stackTop;
    builder.addDynamicCall(
      node.name,
      DynamicCallKind.setter,
      2,
      functionRegistry.getArgumentsShape(2),
    );
    builder.pop();
    builder.push(value);
  }

  @override
  void visitThisExpression(ast.ThisExpression node) {
    builder.addLoadLocal(localVarIndexer.receiver);
  }

  @override
  void visitVariableDeclaration(ast.VariableDeclaration node) {
    if (node.isLate) throw 'unimplemented';
    if (node.isConst) return;
    final local = localVarIndexer.variableForDeclaration(node);
    final initializer = node.initializer;
    if (initializer != null) {
      _translateNode(initializer);
      if (!builder.hasOpenBlock) {
        builder.pop();
        return;
      }
      builder.addStoreLocal(local);
    } else if (node.type.nullability == ast.Nullability.nullable) {
      builder.addNullConstant();
      builder.addStoreLocal(local);
    }
  }

  @override
  void visitVariableGet(ast.VariableGet node) {
    final variable = node.variable;
    if (variable.isLate) throw 'unimplemented';
    if (variable.isConst) {
      builder.addConstant(
        ConstantValue(
          (variable.initializer as ast.ConstantExpression).constant,
        ),
      );
      return;
    }
    final local = localVarIndexer.variableForDeclaration(variable);
    builder.addLoadLocal(local);
    final promotedType = node.promotedType;
    if (promotedType != null) {
      final promotedCType = _typeTranslator.translate(promotedType);
      if (promotedCType is! TopType && promotedCType != local.type) {
        builder.addTypeCast(
          promotedCType,
          typeParameters: _typeParametersForType(promotedType),
          isChecked: false,
        );
      }
    }
  }

  @override
  void visitVariableSet(ast.VariableSet node) {
    final variable = node.variable;
    if (variable.isLate) throw 'unimplemented';
    _translateNode(node.value);
    if (_handleUnreachableExpression(1)) return;
    final local = localVarIndexer.variableForDeclaration(variable);
    builder.addStoreLocal(local, leaveValueOnStack: true);
  }

  @override
  void visitIfStatement(ast.IfStatement node) {
    var (thenBlocks, otherwiseBlocks) = _translateConditionForControl(
      node.condition,
    );
    if (thenBlocks.isEmpty && otherwiseBlocks.isEmpty) {
      assert(!builder.hasOpenBlock);
      return;
    }

    final elsePart = node.otherwise;
    JoinBlock? join;
    if (elsePart == null && otherwiseBlocks.isNotEmpty) {
      join = _joinBlocks(otherwiseBlocks, needNewJoinBlock: true) as JoinBlock;
    }

    if (thenBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(thenBlocks));
      _translateNode(node.then);
      if (builder.hasOpenBlock) {
        join ??= builder.newJoinBlock();
        builder.addGoto(join);
      }
    }

    if (elsePart != null && otherwiseBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(otherwiseBlocks));
      _translateNode(elsePart);
      if (builder.hasOpenBlock) {
        join ??= builder.newJoinBlock();
        builder.addGoto(join);
      }
    }

    if (join != null) {
      builder.startBlock(join);
    }
  }

  @override
  void visitWhileStatement(ast.WhileStatement node) {
    final join = builder.newJoinBlock();
    builder.addGoto(join);
    builder.startBlock(join);

    final (trueBlocks, falseBlocks) = _translateConditionForControl(
      node.condition,
    );

    if (trueBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(trueBlocks));
      _translateNode(node.body);
      if (builder.hasOpenBlock) {
        builder.addGoto(join);
      }
    }

    if (falseBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(falseBlocks));
    }
  }

  @override
  void visitDoStatement(ast.DoStatement node) {
    final join = builder.newJoinBlock();
    builder.addGoto(join);
    builder.startBlock(join);

    _translateNode(node.body);
    if (!builder.hasOpenBlock) return;

    final (trueBlocks, falseBlocks) = _translateConditionForControl(
      node.condition,
    );

    for (final block in trueBlocks) {
      builder.startBlock(block);
      builder.addGoto(join);
    }

    if (falseBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(falseBlocks));
    }
  }

  @override
  void visitForStatement(ast.ForStatement node) {
    _translateNodes(node.variables);
    if (!builder.hasOpenBlock) return;

    final join = builder.newJoinBlock();
    builder.addGoto(join);
    builder.startBlock(join);

    final condition = node.condition;
    Block? done;
    if (condition != null) {
      final (trueBlocks, falseBlocks) = _translateConditionForControl(
        condition,
      );
      if (falseBlocks.isNotEmpty) {
        done = _joinBlocks(falseBlocks);
      }
      if (trueBlocks.isNotEmpty) {
        builder.startBlock(_joinBlocks(trueBlocks));
      }
    }

    _translateNode(node.body);

    for (var update in node.updates) {
      _translateNode(update);
      builder.pop();
    }

    if (builder.hasOpenBlock) {
      builder.addGoto(join);
    }

    if (done != null) {
      builder.startBlock(done);
    }
  }

  @override
  void visitForInStatement(ast.ForInStatement node) =>
      throw 'Should be lowered';

  @override
  void visitLabeledStatement(ast.LabeledStatement node) {
    final labeledStatements = this.labeledStatements ??=
        <ast.LabeledStatement, JoinBlock>{};
    JoinBlock? join;
    try {
      _translateNode(node.body);
    } finally {
      join = labeledStatements.remove(node);
    }
    if (join != null) {
      if (builder.hasOpenBlock) {
        builder.addGoto(join);
      }
      builder.startBlock(join);
    }
  }

  @override
  void visitBreakStatement(ast.BreakStatement node) {
    _generateNonLocalControlTransfer(node, node.target, () {
      final targetBlock = (labeledStatements![node.target] ??= builder
          .newJoinBlock());
      builder.addGoto(targetBlock);
    });
  }

  void _generateSwitchComparison(
    Definition value,
    ast.Expression caseExpression,
  ) {
    _translateNode(caseExpression);
    // TODO(alexmarkov): use proper devirtualization to specialize ==.
    final interfaceTarget = (builder.stackTop.type is IntType)
        ? coreTypes.index.getProcedure('dart:core', 'num', '==')
        : coreTypes.objectEquals;
    builder.push(value);
    final matcher = recognizedMethods.instanceInvocations[interfaceTarget];
    if (matcher != null) {
      final snippet = matcher.match([_staticType(caseExpression), value.type]);
      if (snippet != null) {
        snippet(builder);
        return;
      }
    }
    builder.addInterfaceCall(
      functionRegistry.getFunction(interfaceTarget),
      2,
      functionRegistry.getArgumentsShape(2),
      const BoolType(),
    );
  }

  @override
  void visitSwitchStatement(ast.SwitchStatement node) {
    _translateNode(node.expression);
    final value = builder.pop();

    final switchCases = this.switchCases ??= <ast.SwitchCase, JoinBlock>{};
    final caseBlocks = List<JoinBlock>.generate(
      node.cases.length,
      (_) => builder.newJoinBlock(),
    );

    for (var i = 0; i < node.cases.length; i++) {
      final switchCase = node.cases[i];
      final caseBlock = caseBlocks[i];
      switchCases[switchCase] = caseBlock;

      if (switchCase.isDefault) {
        assert(i == node.cases.length - 1);
        builder.addGoto(caseBlock);
      } else {
        final savedSourcePosition = builder.currentSourcePosition;
        for (var i = 0; i < switchCase.expressions.length; ++i) {
          builder.currentSourcePosition = SourcePosition(
            switchCase.expressionOffsets[i],
          );
          _generateSwitchComparison(value, switchCase.expressions[i]);

          final trueBlock = builder.newTargetBlock();
          final falseBlock = builder.newTargetBlock();
          builder.addBranch(trueBlock, falseBlock);

          builder.startBlock(trueBlock);
          builder.addGoto(caseBlock);

          builder.startBlock(falseBlock);
        }
        builder.currentSourcePosition = savedSourcePosition;
      }
    }

    JoinBlock? done;
    if (builder.hasOpenBlock) {
      done = builder.newJoinBlock();
      builder.addGoto(done);
    }

    for (var i = 0; i < node.cases.length; i++) {
      final switchCase = node.cases[i];
      final caseBlock = caseBlocks[i];

      builder.startBlock(caseBlock);
      _translateNode(switchCase.body);

      if (builder.hasOpenBlock) {
        assert(i == node.cases.length - 1);
        if (done != null) {
          builder.addGoto(done);
        }
      }
    }

    node.cases.forEach(switchCases.remove);

    if (done != null) {
      builder.startBlock(done);
    }
  }

  @override
  void visitContinueSwitchStatement(ast.ContinueSwitchStatement node) {
    final targetBlock = switchCases?[node.target];
    if (targetBlock == null) {
      throw 'Target block ${node.target} was not registered for continue-switch $node';
    }
    _generateNonLocalControlTransfer(node, node.target.parent!, () {
      builder.addGoto(targetBlock);
    });
  }

  @override
  void visitTryCatch(ast.TryCatch node) {
    final tryBody = builder.newTargetBlock();
    final catchBlock = builder.newCatchBlock();
    builder.addTryEntry(tryBody, catchBlock);

    builder.enterTryBlock(catchBlock);
    builder.startBlock(tryBody);

    _translateNode(node.body);

    JoinBlock? done;
    if (builder.hasOpenBlock) {
      done = builder.newJoinBlock();
      builder.addGoto(done);
    }
    builder.leaveTryBlock();

    builder.startBlock(catchBlock);

    final exceptionLocal = localVarIndexer.exceptionVariable(node);
    final stackTraceLocal = localVarIndexer.stackTraceVariable(node);
    builder.addParameter(exceptionLocal);
    builder.addParameter(stackTraceLocal);

    final savedSourcePosition = builder.currentSourcePosition;
    for (final catchClause in node.catches) {
      builder.currentSourcePosition = SourcePosition(catchClause.fileOffset);

      TargetBlock? next;
      final guardType = catchClause.guard;
      final guardCType = _typeTranslator.translate(guardType);
      // Exception objects are guaranteed to be non-nullable, so
      // non-nullable Object is also a catch-all type.
      if (guardCType is! TopType && guardCType is! ObjectType) {
        builder.addLoadLocal(exceptionLocal);
        builder.addTypeTest(
          guardCType,
          typeParameters: _typeParametersForType(guardType),
        );

        final catchBody = builder.newTargetBlock();
        next = builder.newTargetBlock();
        builder.addBranch(catchBody, next);

        builder.startBlock(catchBody);
      }

      if (catchClause.exception != null) {
        builder.addLoadLocal(exceptionLocal);
        builder.addStoreLocal(
          localVarIndexer.variableForDeclaration(catchClause.exception!),
        );
      }

      if (catchClause.stackTrace != null) {
        builder.addLoadLocal(stackTraceLocal);
        builder.addStoreLocal(
          localVarIndexer.variableForDeclaration(catchClause.stackTrace!),
        );
      }

      _translateNode(catchClause.body);

      if (builder.hasOpenBlock) {
        done ??= builder.newJoinBlock();
        builder.addGoto(done);
      }

      if (next != null) {
        builder.startBlock(next);
      }
    }
    builder.currentSourcePosition = savedSourcePosition;

    if (builder.hasOpenBlock) {
      builder.addLoadLocal(exceptionLocal);
      builder.addLoadLocal(stackTraceLocal);
      builder.addRethrow();
    }

    if (done != null) {
      builder.startBlock(done);
    }
  }

  @override
  void visitTryFinally(ast.TryFinally node) {
    final finallyBlocks = this.finallyBlocks ??=
        <ast.TryFinally, List<FinallyBlock>>{};
    finallyBlocks[node] = <FinallyBlock>[];

    final tryBody = builder.newTargetBlock();
    final catchBlock = builder.newCatchBlock();
    builder.addTryEntry(tryBody, catchBlock);

    builder.enterTryBlock(catchBlock);
    builder.startBlock(tryBody);

    _translateNode(node.body);

    if (builder.hasOpenBlock) {
      final normalContinuation = FinallyBlock(builder, () {
        // Do nothing (fall through).
      });
      finallyBlocks[node]!.add(normalContinuation);
      final entryBlock = normalContinuation.entryBlock = builder.newJoinBlock();
      builder.addGoto(entryBlock);
    }

    builder.leaveTryBlock();
    final collectedFinallyBlocks = finallyBlocks.remove(node)!;

    builder.startBlock(catchBlock);

    final exceptionLocal = localVarIndexer.exceptionVariable(node);
    final stackTraceLocal = localVarIndexer.stackTraceVariable(node);
    builder.addParameter(exceptionLocal);
    builder.addParameter(stackTraceLocal);

    _translateNode(node.finalizer);

    if (builder.hasOpenBlock) {
      builder.addLoadLocal(exceptionLocal);
      builder.addLoadLocal(stackTraceLocal);
      builder.addRethrow();
    }

    for (var finallyBlock in collectedFinallyBlocks) {
      final entryBlock = finallyBlock.entryBlock;
      if (entryBlock == null) {
        continue;
      }
      builder.startBlock(entryBlock);
      _translateNode(node.finalizer);
      if (builder.hasOpenBlock) {
        finallyBlock.generateContinuation();
      }
    }
  }

  /// Returns the list of try-finally blocks between [from] and [to],
  /// ordered from inner to outer. If [to] is null, returns all enclosing
  /// try-finally blocks up to the function boundary.
  List<ast.TryFinally> _getEnclosingTryFinallyBlocks(
    ast.TreeNode from,
    ast.TreeNode? to,
  ) {
    final blocks = <ast.TryFinally>[];
    ast.TreeNode? node = from;
    for (;;) {
      if (node == to) {
        return blocks;
      }
      if (node == null || node is ast.FunctionNode || node is ast.Member) {
        if (to == null) {
          return blocks;
        } else {
          throw 'Unable to find node $to up from $from';
        }
      }
      // Inspect parent as we only need try-finally blocks enclosing [node]
      // in the body, and not in the finally-block.
      final parent = node.parent;
      if (parent is ast.TryFinally && parent.body == node) {
        blocks.add(parent);
      }
      node = parent;
    }
  }

  /// Appends chained [FinallyBlock]s to each try-finally in the given
  /// list [tryFinallyBlocks] (ordered from inner to outer).
  /// [continuation] is invoked to generate control transfer following
  /// the last finally block.
  void _addFinallyBlocks(
    List<ast.TryFinally> tryFinallyBlocks,
    void Function() continuation,
  ) {
    if (!builder.hasOpenBlock) {
      return;
    }
    // Add finally blocks to all try-finally from outer to inner.
    // The outermost finally block should generate continuation, each inner
    // finally block should proceed to a corresponding outer block.
    for (var tryFinally in tryFinallyBlocks.reversed) {
      final finallyBlock = FinallyBlock(builder, continuation);
      finallyBlocks![tryFinally]!.add(finallyBlock);

      continuation = () {
        final nextFinally = finallyBlock.entryBlock = builder.newJoinBlock();
        builder.addGoto(nextFinally);
      };
    }

    // Generate Goto to the innermost finally (or to the original
    // continuation if there are no try-finally blocks).
    continuation();
  }

  /// Generates non-local transfer from inner node [from] into the outer
  /// node, executing finally blocks on the way out. [to] can be null,
  /// in such case all enclosing finally blocks are executed.
  /// [continuation] is invoked to generate control transfer following
  /// the last finally block.
  void _generateNonLocalControlTransfer(
    ast.TreeNode from,
    ast.TreeNode? to,
    void Function() continuation,
  ) {
    _addFinallyBlocks(_getEnclosingTryFinallyBlocks(from, to), continuation);
  }

  @override
  void visitThrow(ast.Throw node) {
    _translateNode(node.expression);
    if (_handleUnreachableExpression(1)) return;
    builder.addThrow();
    // Maintain expression stack balance.
    builder.addNullConstant();
  }

  @override
  void visitRethrow(ast.Rethrow node) {
    ast.TryCatch tryCatch;
    for (var parent = node.parent; ; parent = parent.parent) {
      if (parent is ast.Catch) {
        tryCatch = parent.parent as ast.TryCatch;
        break;
      }
      if (parent == null ||
          parent is ast.FunctionNode ||
          parent is ast.Member) {
        throw 'Unable to find enclosing catch for $node';
      }
    }
    final exceptionLocal = localVarIndexer.exceptionVariable(tryCatch);
    final stackTraceLocal = localVarIndexer.stackTraceVariable(tryCatch);
    builder.addLoadLocal(exceptionLocal);
    builder.addLoadLocal(stackTraceLocal);
    builder.addRethrow();
    // Maintain expression stack balance.
    builder.addNullConstant();
  }

  @override
  void visitNullCheck(ast.NullCheck node) {
    _translateNode(node.operand);
    if (_handleUnreachableExpression(1)) return;
    builder.addNullCheck();
  }

  @override
  void visitIsExpression(ast.IsExpression node) {
    _translateNode(node.operand);
    if (_handleUnreachableExpression(1)) return;

    final type = _typeTranslator.translate(node.type);
    if (type is TopType) {
      builder.pop();
      builder.addBoolConstant(true);
    } else {
      builder.addTypeTest(
        type,
        typeParameters: _typeParametersForType(node.type),
      );
    }
  }

  @override
  void visitAsExpression(ast.AsExpression node) {
    _translateNode(node.operand);
    if (_handleUnreachableExpression(1)) return;

    final type = _typeTranslator.translate(node.type);
    if (type is TopType) {
      return;
    }
    builder.addTypeCast(
      type,
      typeParameters: _typeParametersForType(node.type),
      isChecked: !node.isUnchecked,
    );
  }

  @override
  void visitConditionalExpression(ast.ConditionalExpression node) {
    final (trueBlocks, falseBlocks) = _translateConditionForControl(
      node.condition,
    );
    if (trueBlocks.isEmpty && falseBlocks.isEmpty) {
      assert(!builder.hasOpenBlock);
      return;
    }
    JoinBlock? joinBlock;
    final tempVar = builder.declareLocalVariable(
      '#temp',
      null,
      _typeTranslator.translate(node.staticType),
    );

    if (trueBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(trueBlocks));
      _translateNode(node.then);
      if (builder.hasOpenBlock) {
        builder.addStoreLocal(tempVar);
        joinBlock ??= builder.newJoinBlock();
        builder.addGoto(joinBlock);
      }
    }

    if (falseBlocks.isNotEmpty) {
      builder.startBlock(_joinBlocks(falseBlocks));
      _translateNode(node.otherwise);
      if (builder.hasOpenBlock) {
        builder.addStoreLocal(tempVar);
        joinBlock ??= builder.newJoinBlock();
        builder.addGoto(joinBlock);
      }
    }

    if (joinBlock != null) {
      builder.startBlock(joinBlock);
      builder.addLoadLocal(tempVar);
    }
  }

  @override
  void visitLet(ast.Let node) {
    _translateNode(node.variable);
    _translateNode(node.body);
  }

  @override
  void visitFieldInitializer(ast.FieldInitializer node) {
    builder.addLoadLocal(localVarIndexer.receiver);
    _translateNode(node.value);
    if (!builder.hasOpenBlock) {
      builder.drop(2);
      return;
    }
    builder.addStoreInstanceField(CField(node.field));
  }

  @override
  void visitRedirectingInitializer(ast.RedirectingInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    final target = functionRegistry.getFunction(node.target);
    final inputCount = _translateArguments(ast.ThisExpression(), args);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addDirectCall(
      target,
      inputCount,
      _translateArgumentsShape(1, args),
      const TopType(const ast.VoidType()),
    );
    builder.pop();
  }

  @override
  void visitSuperInitializer(ast.SuperInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    // Re-resolve target due to partial mixin resolution.
    ast.Member? targetMember;
    for (final constr
        in function.member.enclosingClass!.superclass!.constructors) {
      if (node.target.name == constr.name) {
        targetMember = constr;
        break;
      }
    }
    final target = functionRegistry.getFunction(targetMember!);
    final inputCount = _translateArguments(ast.ThisExpression(), args);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addDirectCall(
      target,
      inputCount,
      _translateArgumentsShape(1, args),
      const TopType(const ast.VoidType()),
    );
    builder.pop();
  }

  @override
  void visitLocalInitializer(ast.LocalInitializer node) {
    _translateNode(node.variable);
  }

  @override
  void visitAssertInitializer(ast.AssertInitializer node) {
    _translateNode(node.statement);
  }

  @override
  void visitSuperMethodInvocation(ast.SuperMethodInvocation node) {
    final args = node.arguments;
    final targetMember = hierarchy.getDispatchTarget(
      function.member.enclosingClass!.superclass!,
      node.name,
    );
    final target = functionRegistry.getFunction(targetMember!);
    final inputCount = _translateArguments(ast.ThisExpression(), args);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addDirectCall(
      target,
      inputCount,
      _translateArgumentsShape(1, args),
      _staticType(node),
    );
  }

  @override
  void visitSuperPropertyGet(ast.SuperPropertyGet node) {
    final targetMember = hierarchy.getDispatchTarget(
      function.member.enclosingClass!.superclass!,
      node.name,
    );
    final target = functionRegistry.getFunction(targetMember!, isGetter: true);
    builder.addLoadLocal(localVarIndexer.receiver);
    builder.addDirectCall(
      target,
      1,
      functionRegistry.getArgumentsShape(1),
      _staticType(node),
    );
  }

  @override
  void visitSuperPropertySet(ast.SuperPropertySet node) {
    final targetMember = hierarchy.getDispatchTarget(
      function.member.enclosingClass!.superclass!,
      node.name,
      setter: true,
    );
    final target = functionRegistry.getFunction(targetMember!, isSetter: true);
    builder.addLoadLocal(localVarIndexer.receiver);
    _translateNode(node.value);
    if (_handleUnreachableExpression(2)) return;
    final value = builder.stackTop;
    builder.addDirectCall(
      target,
      2,
      functionRegistry.getArgumentsShape(2),
      const TopType(const ast.VoidType()),
    );
    builder.pop();
    builder.push(value);
  }

  @override
  void visitConstructorInvocation(ast.ConstructorInvocation node) {
    assert(!node.isConst);

    final args = node.arguments;
    final target = functionRegistry.getFunction(node.target);
    Definition? typeArguments;
    if (args.types.isNotEmpty) {
      builder.addTypeArguments(
        args.types,
        typeParameters: _typeParametersForTypes(args.types),
      );
      typeArguments = builder.pop();
    }
    final instance = builder.addAllocateObject(
      _typeTranslator.translate(node.constructedType),
      typeArguments: typeArguments,
    );
    final argsWithoutTypes = ast.Arguments(args.positional, named: args.named);
    final inputCount = _translateArguments(null, argsWithoutTypes);
    if (_handleUnreachableExpression(inputCount + 1)) return;
    builder.addDirectCall(
      target,
      inputCount + 1,
      _translateArgumentsShape(1, argsWithoutTypes),
      const TopType(const ast.VoidType()),
    );
    builder.pop();
    builder.push(instance);
  }

  @override
  void visitStringConcatenation(ast.StringConcatenation node) {
    final inputCount = node.expressions.length;
    _translateNodes(node.expressions);
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addStringInterpolation(inputCount);
  }

  void _translateClosure(ast.LocalFunction node, CType type) {
    final closureFunction =
        functionRegistry.getFunction(function.member, localFunction: node)
            as ClosureFunction;
    // TODO: pass captured contexts and type parameters.
    builder.addAllocateClosure(closureFunction, type, 0);
  }

  @override
  void visitFunctionExpression(ast.FunctionExpression node) {
    _translateClosure(node, _staticType(node));
  }

  @override
  void visitFunctionDeclaration(ast.FunctionDeclaration node) {
    final local = localVarIndexer.variableForDeclaration(node.variable);
    _translateClosure(node, local.type);
    builder.addStoreLocal(local);
  }

  @override
  void visitFunctionInvocation(ast.FunctionInvocation node) {
    final args = node.arguments;
    final inputCount = _translateArguments(node.receiver, args);
    if (_handleUnreachableExpression(inputCount)) return;
    if (node.kind == ast.FunctionAccessKind.FunctionType) {
      builder.addClosureCall(
        inputCount,
        _translateArgumentsShape(1, args),
        _staticType(node),
      );
    } else {
      builder.addDynamicCall(
        ast.Name.callName,
        DynamicCallKind.method,
        inputCount,
        _translateArgumentsShape(1, args),
      );
    }
  }

  @override
  void visitLocalFunctionInvocation(ast.LocalFunctionInvocation node) {
    final args = node.arguments;
    final inputCount = _translateArguments(
      ast.VariableGet(node.variable),
      args,
    );
    if (_handleUnreachableExpression(inputCount)) return;
    builder.addClosureCall(
      inputCount,
      _translateArgumentsShape(1, args),
      _staticType(node),
    );
  }

  /// Translate logical expression (!x, x || y, x && y) for value.
  void _translateConditionForValue(ast.Expression node) {
    // Created lazily, only if there are extra edges with true/false results.
    JoinBlock? done;
    late final resultVar = builder.declareLocalVariable(
      '#temp',
      null,
      const BoolType(),
    );

    void addExtraEdges(bool result, List<Block> blocks) {
      for (final block in blocks) {
        builder.startBlock(block);
        builder.addBoolConstant(result);
        builder.addStoreLocal(resultVar);
        builder.addGoto(done ??= builder.newJoinBlock());
      }
    }

    var negated = false;
    for (ast.Expression? expr = node; expr != null;) {
      switch (expr) {
        case ast.Not():
          negated = !negated;
          expr = expr.operand;
          break;
        case ast.LogicalExpression():
          var (leftTrue, leftFalse) = _translateConditionForControl(expr.left);
          var op = expr.operatorEnum;
          if (negated) {
            op = switch (op) {
              .AND => .OR,
              .OR => .AND,
            };
            final tmp = leftTrue;
            leftTrue = leftFalse;
            leftFalse = tmp;
          }
          switch (op) {
            case .AND:
              addExtraEdges(false, leftFalse);
              if (leftTrue.isEmpty) {
                expr = null;
                break;
              }
              builder.startBlock(_joinBlocks(leftTrue));
              expr = expr.right;
            case .OR:
              addExtraEdges(true, leftTrue);
              if (leftFalse.isEmpty) {
                expr = null;
                break;
              }
              builder.startBlock(_joinBlocks(leftFalse));
              expr = expr.right;
          }
          break;
        case _:
          _translateNode(expr);
          if (builder.hasOpenBlock) {
            if (negated) {
              builder.addUnaryBoolOp(UnaryBoolOpcode.not);
            }
            if (done != null) {
              builder.addStoreLocal(resultVar);
              builder.addGoto(done!);
            }
          } else {
            builder.drop(1);
          }
          expr = null;
          break;
      }
    }

    if (done != null) {
      builder.startBlock(done!);
      builder.addLoadLocal(resultVar);
    } else {
      _handleUnreachableExpression(0);
    }
  }

  @override
  void visitNot(ast.Not node) {
    _translateConditionForValue(node);
  }

  @override
  void visitLogicalExpression(ast.LogicalExpression node) {
    _translateConditionForValue(node);
  }
}

/// Mapping between AST nodes and CFG IR [LocalVariable].
class LocalVariableIndexer {
  final FlowGraphBuilder builder;
  final CoreTypes coreTypes;
  final AstToIrTypes typeTranslator;
  final Map<ast.VariableDeclaration, LocalVariable> _declaredVariables = {};
  final Map<ast.TreeNode, LocalVariable> _exceptionVariables = {};
  final Map<ast.TreeNode, LocalVariable> _stackTraceVariables = {};

  final List<LocalVariable> parameters = [];
  LocalVariable get receiver => parameters[0];

  LocalVariableIndexer(
    this.builder,
    this.coreTypes,
    this.typeTranslator,
    CFunction function,
  ) {
    if (function.hasReceiverParameter) {
      final cls = function.member.enclosingClass!;
      parameters.add(
        builder.declareLocalVariable(
          'this',
          null,
          typeTranslator.translate(
            cls.getThisType(coreTypes, ast.Nullability.nonNullable),
          ),
        ),
      );
    }
    if (function.hasClosureParameter) {
      parameters.add(
        builder.declareLocalVariable(
          '#closure',
          null,
          typeTranslator.translate(coreTypes.functionNonNullableRawType),
        ),
      );
    }
    if (function is ImplicitFieldSetter) {
      parameters.add(
        builder.declareLocalVariable('#value', null, function.valueType),
      );
    }
    ast.FunctionNode? functionNode = switch (function) {
      LocalFunction() => function.localFunction.function,
      _ => function.member.function,
    };
    if (functionNode != null) {
      for (final v in functionNode.positionalParameters) {
        parameters.add(variableForDeclaration(v));
      }
      for (final v in functionNode.namedParameters) {
        parameters.add(variableForDeclaration(v));
      }
    }
    assert(parameters.length == function.numberOfParameters);
  }

  LocalVariable variableForDeclaration(ast.VariableDeclaration declaration) =>
      _declaredVariables[declaration] ??= builder.declareLocalVariable(
        declaration.name ?? '#temp',
        declaration,
        typeTranslator.translate(declaration.type),
      );

  LocalVariable exceptionVariable(ast.TreeNode tryBlock) {
    assert(tryBlock is ast.TryCatch || tryBlock is ast.TryFinally);
    return _exceptionVariables[tryBlock] ??= builder.declareLocalVariable(
      '#exception',
      null,
      const ObjectType(),
    );
  }

  LocalVariable stackTraceVariable(ast.TreeNode tryBlock) {
    assert(tryBlock is ast.TryCatch || tryBlock is ast.TryFinally);
    return _stackTraceVariables[tryBlock] ??= builder.declareLocalVariable(
      '#stackTrace',
      null,
      StaticType(coreTypes.stackTraceNonNullableRawType),
    );
  }
}

/// A pending request to generate IR for a finally block.
///
/// Used to implement non-local control transfers (such as `break`,
/// `continue` or `return`).
///
/// These requests are fullfilled in [AstToIr.visitTryFinally] when
/// leaving a try-finally block in order to ensure correct AST scoping.
class FinallyBlock {
  /// Entry basic block for the finally block.
  /// Created only when finally block is reachable.
  JoinBlock? entryBlock;

  /// Generate continuation code after the finally block.
  final void Function() generateContinuation;

  FinallyBlock(FlowGraphBuilder builder, this.generateContinuation);
}

/// Look up references to free type parameters.
class _FindTypeParameters
    with ast.DartTypeVisitorExperimentExclusionMixin<bool>
    implements ast.DartTypeVisitor<bool> {
  const _FindTypeParameters();

  @override
  bool visitFunctionType(ast.FunctionType node) {
    if (node.returnType.accept(this)) return true;
    for (final param in node.positionalParameters) {
      if (param.accept(this)) return true;
    }
    for (final namedParam in node.namedParameters) {
      if (namedParam.type.accept(this)) return true;
    }
    for (final typeParam in node.typeParameters) {
      if (typeParam.bound.accept(this)) return true;
      if (typeParam.defaultType.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(ast.InterfaceType node) {
    for (final type in node.typeArguments) {
      if (type.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(ast.TypedefType node) {
    for (final type in node.typeArguments) {
      if (type.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypeParameterType(ast.TypeParameterType node) => true;

  @override
  bool visitStructuralParameterType(ast.StructuralParameterType node) => false;

  @override
  bool visitIntersectionType(ast.IntersectionType node) {
    return node.left.accept(this) || node.right.accept(this);
  }

  @override
  bool visitExtensionType(ast.ExtensionType node) {
    for (final type in node.typeArguments) {
      if (type.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitRecordType(ast.RecordType node) {
    for (final type in node.positional) {
      if (type.accept(this)) return true;
    }
    for (final namedType in node.named) {
      if (namedType.type.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitFutureOrType(ast.FutureOrType node) =>
      node.typeArgument.accept(this);

  @override
  bool visitInvalidType(ast.InvalidType node) => false;

  @override
  bool visitNeverType(ast.NeverType node) => false;

  @override
  bool visitNullType(ast.NullType node) => false;

  @override
  bool visitVoidType(ast.VoidType node) => false;

  @override
  bool visitDynamicType(ast.DynamicType node) => false;

  @override
  bool visitAuxiliaryType(ast.AuxiliaryType node) =>
      throw 'Unsupported type ${node.runtimeType} $node';
}
