// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Creation of type flow summaries out of kernel AST.
library vm.transformations.type_flow.summary_collector;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/ast.dart' as ast show Statement, StatementVisitor;
import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'calls.dart';
import 'native_code.dart';
import 'summary.dart';
import 'types.dart';
import 'utils.dart';

/// Summary collector relies on either full or partial mixin resolution.
/// Currently VmTarget.performModularTransformationsOnLibraries performs
/// partial mixin resolution.
const bool kPartialMixinResolution = true;

/// Normalizes and optimizes summary after it is created.
/// More specifically:
/// * Breaks loops between statements.
/// * Removes unused statements (except parameters and calls).
/// * Eliminates joins with a single input.
class _SummaryNormalizer extends StatementVisitor {
  final Summary _summary;
  Set<Statement> _processed = new Set<Statement>();
  Set<Statement> _pending = new Set<Statement>();
  bool _inLoop = false;

  _SummaryNormalizer(this._summary);

  void normalize() {
    final List<Statement> statements = _summary.statements;
    _summary.reset();

    for (int i = 0; i < _summary.positionalParameterCount; i++) {
      _processed.add(statements[i]);
      _summary.add(statements[i]);
    }

    // Sort named parameters.
    // TODO(dartbug.com/32292): make sure parameters are sorted in kernel AST
    // and remove this sorting.
    if (_summary.positionalParameterCount < _summary.parameterCount) {
      List<Statement> namedParams = statements.sublist(
          _summary.positionalParameterCount, _summary.parameterCount);
      namedParams.sort((Statement s1, Statement s2) =>
          (s1 as Parameter).name.compareTo((s2 as Parameter).name));
      namedParams.forEach((Statement st) {
        _processed.add(st);
        _summary.add(st);
      });
    }

    for (Statement st in statements) {
      if (st is Call) {
        _normalizeExpr(st, false);
      } else if (st is Use) {
        _normalizeExpr(st.arg, true);
      }
    }

    _summary.result = _normalizeExpr(_summary.result, true);
  }

  TypeExpr _normalizeExpr(TypeExpr st, bool isResultUsed) {
    assertx(!_inLoop);
    assertx(st is! Use);
    if (st is Statement) {
      if (isResultUsed && (st is Call)) {
        st.setResultUsed();
      }
      if (_processed.contains(st)) {
        return st;
      }
      if (_pending.add(st)) {
        st.accept(this);
        _pending.remove(st);

        if (_inLoop) {
          return _handleLoop(st);
        }

        if (st is Join) {
          final n = st.values.length;
          if (n == 0) {
            return const EmptyType();
          } else if (n == 1) {
            return st.values.single;
          }
        }

        _processed.add(st);
        _summary.add(st);
        return st;
      } else {
        // Cyclic expression.
        return _handleLoop(st);
      }
    } else {
      assertx(st is Type);
      return st;
    }
  }

  TypeExpr _handleLoop(Statement st) {
    if (st is Join) {
      // Approximate Join with static type.
      _inLoop = false;
      debugPrint("Approximated ${st} with ${st.staticType}");
      Statistics.joinsApproximatedToBreakLoops++;
      return new Type.fromStatic(st.staticType);
    } else {
      // Step back until Join is found.
      _inLoop = true;
      return st;
    }
  }

  @override
  void visitNarrow(Narrow expr) {
    expr.arg = _normalizeExpr(expr.arg, true);
  }

  @override
  void visitJoin(Join expr) {
    for (int i = 0; i < expr.values.length; i++) {
      expr.values[i] = _normalizeExpr(expr.values[i], true);

      if (_inLoop) {
        return;
      }
    }
  }

  @override
  void visitUse(Use expr) {
    throw '\'Use\' statement should not be referenced: $expr';
  }

  @override
  void visitCall(Call expr) {
    for (int i = 0; i < expr.args.values.length; i++) {
      expr.args.values[i] = _normalizeExpr(expr.args.values[i], true);

      if (_inLoop) {
        return;
      }
    }
  }
}

/// Detects whether the control flow can pass through the function body and
/// reach its end. Returns 'false' if it can prove that control never reaches
/// the end. Otherwise, conservatively returns 'true'.
class _FallthroughDetector extends ast.StatementVisitor<bool> {
  // This fallthrough detector does not build control flow graph nor detect if
  // a function has unreachable code. For simplicity, it assumes that all
  // statements are reachable, so it just inspects the last statements of a
  // function and checks if control can fall through them or not.

  bool controlCanFallThrough(FunctionNode function) {
    return function.body.accept(this);
  }

  @override
  bool defaultStatement(ast.Statement node) =>
      throw "Unexpected statement of type ${node.runtimeType}";

  @override
  bool visitExpressionStatement(ExpressionStatement node) =>
      (node.expression is! Throw) && (node.expression is! Rethrow);

  @override
  bool visitBlock(Block node) =>
      node.statements.isEmpty || node.statements.last.accept(this);

  @override
  bool visitEmptyStatement(EmptyStatement node) => true;

  @override
  bool visitAssertStatement(AssertStatement node) => true;

  @override
  bool visitLabeledStatement(LabeledStatement node) => true;

  @override
  bool visitBreakStatement(BreakStatement node) => false;

  @override
  bool visitWhileStatement(WhileStatement node) => true;

  @override
  bool visitDoStatement(DoStatement node) => true;

  @override
  bool visitForStatement(ForStatement node) => true;

  @override
  bool visitForInStatement(ForInStatement node) => true;

  @override
  bool visitSwitchStatement(SwitchStatement node) => true;

  @override
  bool visitContinueSwitchStatement(ContinueSwitchStatement node) => false;

  @override
  bool visitIfStatement(IfStatement node) =>
      node.then == null ||
      node.otherwise == null ||
      node.then.accept(this) ||
      node.otherwise.accept(this);

  @override
  bool visitReturnStatement(ReturnStatement node) => false;

  @override
  bool visitTryCatch(TryCatch node) =>
      node.body.accept(this) ||
      node.catches.any((Catch catch_) => catch_.body.accept(this));

  @override
  bool visitTryFinally(TryFinally node) =>
      node.body.accept(this) && node.finalizer.accept(this);

  @override
  bool visitYieldStatement(YieldStatement node) => true;

  @override
  bool visitVariableDeclaration(VariableDeclaration node) => true;

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) => true;
}

/// Create a type flow summary for a member from the kernel AST.
class SummaryCollector extends RecursiveVisitor<TypeExpr> {
  final TypeEnvironment _environment;
  final EntryPointsListener _entryPointsListener;
  final NativeCodeOracle _nativeCodeOracle;

  final Map<TreeNode, Call> callSites = <TreeNode, Call>{};
  final _FallthroughDetector _fallthroughDetector = new _FallthroughDetector();

  Summary _summary;
  Map<VariableDeclaration, Join> _variables;
  Join _returnValue;
  Parameter _receiver;
  ConstantAllocationCollector constantAllocationCollector;

  SummaryCollector(
      this._environment, this._entryPointsListener, this._nativeCodeOracle) {
    constantAllocationCollector = new ConstantAllocationCollector(this);
  }

  Summary createSummary(Member member) {
    debugPrint("===== ${member} =====");
    assertx(!member.isAbstract);

    _variables = <VariableDeclaration, Join>{};
    _returnValue = null;
    _receiver = null;

    if (member is Field) {
      _summary = new Summary();

      assertx(member.initializer != null);
      _summary.result = _visit(member.initializer);
    } else {
      FunctionNode function = member.function;

      final hasReceiver = hasReceiverArg(member);
      final firstParamIndex = hasReceiver ? 1 : 0;

      _summary = new Summary(
          parameterCount: firstParamIndex +
              function.positionalParameters.length +
              function.namedParameters.length,
          positionalParameterCount:
              firstParamIndex + function.positionalParameters.length,
          requiredParameterCount:
              firstParamIndex + function.requiredParameterCount);

      if (hasReceiver) {
        // TODO(alexmarkov): subclass cone
        _receiver = _declareParameter(
            "this", member.enclosingClass.rawType, null,
            isReceiver: true);
        _environment.thisType = member.enclosingClass?.thisType;
      }

      for (VariableDeclaration param in function.positionalParameters) {
        _declareParameter(param.name, param.type, param.initializer);
      }
      for (VariableDeclaration param in function.namedParameters) {
        _declareParameter(param.name, param.type, param.initializer);
      }

      int count = firstParamIndex;
      for (VariableDeclaration param in function.positionalParameters) {
        Join v = _declareVariable(param);
        v.values.add(_summary.statements[count++]);
      }
      for (VariableDeclaration param in function.namedParameters) {
        Join v = _declareVariable(param);
        v.values.add(_summary.statements[count++]);
      }
      assertx(count == _summary.parameterCount);

      _returnValue = new Join("%result", function.returnType);
      _summary.add(_returnValue);

      if (member is Constructor) {
        // Make sure instance field initializers are visited.
        for (var f in member.enclosingClass.members) {
          if ((f is Field) && !f.isStatic && (f.initializer != null)) {
            _entryPointsListener.addRawCall(
                new DirectSelector(f, callKind: CallKind.FieldInitializer));
          }
        }
        member.initializers.forEach(_visit);
      }

      if (function.body == null) {
        Type type = _nativeCodeOracle.handleNativeProcedure(
            member, _entryPointsListener);
        _returnValue.values.add(type);
      } else {
        _visit(function.body);

        if (_fallthroughDetector.controlCanFallThrough(function)) {
          _returnValue.values.add(_nullType);
        }
      }

      _summary.result = _returnValue;
      _environment.thisType = null;
    }

    debugPrint("------------ SUMMARY ------------");
    debugPrint(_summary);
    debugPrint("---------------------------------");

    new _SummaryNormalizer(_summary).normalize();

    debugPrint("---------- NORM SUMMARY ---------");
    debugPrint(_summary);
    debugPrint("---------------------------------");

    Statistics.summariesCreated++;

    return _summary;
  }

  Args<Type> rawArguments(Selector selector) {
    final member = selector.member;
    assertx(member != null);

    final List<Type> args = <Type>[];
    final List<String> names = <String>[];

    if (hasReceiverArg(member) &&
        (selector.callKind != CallKind.FieldInitializer)) {
      assertx(member.enclosingClass != null);
      Type receiver = new Type.cone(member.enclosingClass.rawType);
      args.add(receiver);
    }

    switch (selector.callKind) {
      case CallKind.Method:
        if (member is! Field) {
          final function = member.function;
          assertx(function != null);

          final int paramCount = function.positionalParameters.length +
              function.namedParameters.length;
          for (int i = 0; i < paramCount; i++) {
            args.add(new Type.nullableAny());
          }

          if (function.namedParameters.isNotEmpty) {
            for (var param in function.namedParameters) {
              names.add(param.name);
            }
            // TODO(dartbug.com/32292): make sure parameters are sorted in
            // kernel AST and remove this sorting.
            names.sort();
          }
        }
        break;

      case CallKind.PropertyGet:
        break;

      case CallKind.PropertySet:
        args.add(new Type.nullableAny());
        break;

      case CallKind.FieldInitializer:
        break;
    }

    return new Args<Type>(args, names: names);
  }

  TypeExpr _visit(TreeNode node) => node.accept(this);

  Args<TypeExpr> _visitArguments(TypeExpr receiver, Arguments arguments) {
    final args = <TypeExpr>[];
    if (receiver != null) {
      args.add(receiver);
    }
    for (Expression arg in arguments.positional) {
      args.add(_visit(arg));
    }
    if (arguments.named.isNotEmpty) {
      final names = <String>[];
      final map = <String, TypeExpr>{};
      for (NamedExpression arg in arguments.named) {
        final name = arg.name;
        names.add(name);
        map[name] = _visit(arg.value);
      }
      names.sort();
      for (var name in names) {
        args.add(map[name]);
      }
      return new Args<TypeExpr>(args, names: names);
    } else {
      return new Args<TypeExpr>(args);
    }
  }

  Parameter _declareParameter(
      String name, DartType type, Expression initializer,
      {bool isReceiver: false}) {
    Type staticType =
        isReceiver ? new ConeType(type) : new Type.fromStatic(type);
    final param = new Parameter(name, staticType);
    _summary.add(param);
    assertx(param.index < _summary.parameterCount);
    if (param.index >= _summary.requiredParameterCount) {
      if (initializer != null) {
        if (initializer is ConstantExpression) {
          param.defaultValue =
              constantAllocationCollector.typeFor(initializer.constant);
        } else {
          param.defaultValue =
              new Type.fromStatic(initializer.getStaticType(_environment));
        }
      } else {
        param.defaultValue = _nullType;
      }
    } else {
      assertx(initializer == null);
    }
    return param;
  }

  Join _declareVariable(VariableDeclaration decl, {bool addInitType: false}) {
    Join v = new Join(decl.name, decl.type);
    _summary.add(v);
    _variables[decl] = v;
    if (decl.initializer != null) {
      TypeExpr initType = _visit(decl.initializer);
      if (addInitType) {
        v.values.add(initType);
      }
    }
    return v;
  }

  // TODO(alexmarkov): Avoid declaring variables with static types.
  void _declareVariableWithStaticType(VariableDeclaration decl) {
    Join v = _declareVariable(decl);
    v.values.add(new Type.fromStatic(v.staticType));
  }

  Call _makeCall(TreeNode node, Selector selector, Args<TypeExpr> args) {
    Call call = new Call(selector, args);
    _summary.add(call);
    if (node != null) {
      callSites[node] = call;
    }
    return call;
  }

  TypeExpr _makeNarrow(TypeExpr arg, Type type) {
    if (arg is Type) {
      // TODO(alexmarkov): more constant folding
      if ((arg is NullableType) && (arg.baseType == const AnyType())) {
        debugPrint("Optimized _Narrow of dynamic");
        return type;
      }
    }
    Narrow narrow = new Narrow(arg, type);
    _summary.add(narrow);
    return narrow;
  }

  // Add an artificial use of given expression in order to make it possible to
  // infer its type even if it is not used in a summary.
  void _addUse(TypeExpr arg) {
    if (arg is Narrow) {
      _addUse(arg.arg);
    } else if (arg is Join || arg is Call) {
      _summary.add(new Use(arg));
    } else {
      assertx(arg is Type || arg is Parameter);
    }
  }

  Type _staticType(Expression node) =>
      new Type.fromStatic(node.getStaticType(_environment));

  Type _cachedBoolType;
  Type get _boolType =>
      _cachedBoolType ??= new Type.cone(_environment.boolType);

  Type _cachedDoubleType;
  Type get _doubleType =>
      _cachedDoubleType ??= new Type.cone(_environment.doubleType);

  Type _cachedIntType;
  Type get _intType => _cachedIntType ??= new Type.cone(_environment.intType);

  Type _cachedStringType;
  Type get _stringType =>
      _cachedStringType ??= new Type.cone(_environment.stringType);

  Type _cachedNullType;
  Type get _nullType => _cachedNullType ??= new Type.nullable(new Type.empty());

  Class get _superclass => _environment.thisType.classNode.superclass;

  void _handleNestedFunctionNode(FunctionNode node) {
    var oldReturn = _returnValue;
    var oldVariables = _variables;
    _returnValue = null;
    _variables = <VariableDeclaration, Join>{};
    _variables.addAll(oldVariables);

    // Approximate parameters of nested functions with static types.
    node.positionalParameters.forEach(_declareVariableWithStaticType);
    node.namedParameters.forEach(_declareVariableWithStaticType);

    _visit(node.body);

    _returnValue = oldReturn;
    _variables = oldVariables;
  }

  @override
  defaultTreeNode(TreeNode node) =>
      throw 'Unexpected node ${node.runtimeType}: $node at ${node.location}';

  @override
  TypeExpr visitAsExpression(AsExpression node) {
    TypeExpr operand = _visit(node.operand);
    Type type = new Type.fromStatic(node.type);
    return _makeNarrow(operand, type);
  }

  @override
  TypeExpr visitBoolLiteral(BoolLiteral node) {
    return _boolType;
  }

  @override
  TypeExpr visitIntLiteral(IntLiteral node) {
    return _intType;
  }

  @override
  TypeExpr visitDoubleLiteral(DoubleLiteral node) {
    return _doubleType;
  }

  @override
  TypeExpr visitConditionalExpression(ConditionalExpression node) {
    _addUse(_visit(node.condition));

    Join v = new Join(null, node.getStaticType(_environment));
    _summary.add(v);
    v.values.add(_visit(node.then));
    v.values.add(_visit(node.otherwise));
    return _makeNarrow(v, _staticType(node));
  }

  @override
  TypeExpr visitConstructorInvocation(ConstructorInvocation node) {
    final receiver =
        _entryPointsListener.addAllocatedClass(node.constructedType.classNode);

    final args = _visitArguments(receiver, node.arguments);
    _makeCall(node, new DirectSelector(node.target), args);
    return receiver;
  }

  @override
  TypeExpr visitDirectMethodInvocation(DirectMethodInvocation node) {
    final receiver = _visit(node.receiver);
    final args = _visitArguments(receiver, node.arguments);
    assertx(node.target is! Field);
    assertx(!node.target.isGetter && !node.target.isSetter);
    return _makeCall(node, new DirectSelector(node.target), args);
  }

  @override
  TypeExpr visitDirectPropertyGet(DirectPropertyGet node) {
    final receiver = _visit(node.receiver);
    final args = new Args<TypeExpr>([receiver]);
    final target = node.target;
    if ((target is Field) || ((target is Procedure) && target.isGetter)) {
      return _makeCall(node,
          new DirectSelector(target, callKind: CallKind.PropertyGet), args);
    } else {
      // Tear-off.
      // TODO(alexmarkov): Consider cleaning up this code as it duplicates
      // processing in DirectInvocation.
      // TODO(alexmarkov): capture receiver type
      _entryPointsListener.addRawCall(new DirectSelector(target));
      return _staticType(node);
    }
  }

  @override
  TypeExpr visitDirectPropertySet(DirectPropertySet node) {
    final receiver = _visit(node.receiver);
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([receiver, value]);
    final target = node.target;
    assertx((target is Field) || ((target is Procedure) && target.isSetter));
    _makeCall(
        node, new DirectSelector(target, callKind: CallKind.PropertySet), args);
    return value;
  }

  @override
  TypeExpr visitFunctionExpression(FunctionExpression node) {
    _handleNestedFunctionNode(node.function);
    // TODO(alexmarkov): support function types.
    // return _concreteType(node.function.functionType);
    return _staticType(node);
  }

  @override
  visitInstantiation(Instantiation node) {
    _visit(node.expression);
    // TODO(alexmarkov): support generic & function types.
    return _staticType(node);
  }

  @override
  TypeExpr visitInvalidExpression(InvalidExpression node) {
    return new Type.empty();
  }

  @override
  TypeExpr visitIsExpression(IsExpression node) {
    _visit(node.operand);
    return _boolType;
  }

  @override
  TypeExpr visitLet(Let node) {
    _declareVariable(node.variable, addInitType: true);
    return _visit(node.body);
  }

  @override
  TypeExpr visitListLiteral(ListLiteral node) {
    node.expressions.forEach(_visit);
    // TODO(alexmarkov): concrete type
    return _staticType(node);
  }

  @override
  TypeExpr visitLogicalExpression(LogicalExpression node) {
    _addUse(_visit(node.left));
    _addUse(_visit(node.right));
    return _boolType;
  }

  @override
  TypeExpr visitMapLiteral(MapLiteral node) {
    for (var entry in node.entries) {
      _visit(entry.key);
      _visit(entry.value);
    }
    // TODO(alexmarkov): concrete type
    return _staticType(node);
  }

  @override
  TypeExpr visitMethodInvocation(MethodInvocation node) {
    final receiver = _visit(node.receiver);
    final args = _visitArguments(receiver, node.arguments);
    final target = node.interfaceTarget;
    if (target == null) {
      if (node.name.name == '==') {
        assertx(args.values.length == 2);
        if ((args.values[0] == _nullType) || (args.values[1] == _nullType)) {
          return _boolType;
        }
        _makeCall(node, new DynamicSelector(CallKind.Method, node.name), args);
        return new Type.nullable(_boolType);
      }
      if (node.name.name == 'call') {
        final recvType = node.receiver.getStaticType(_environment);
        if ((recvType is FunctionType) ||
            (recvType == _environment.rawFunctionType)) {
          // Call to a Function.
          return _staticType(node);
        }
      }
      return _makeCall(
          node, new DynamicSelector(CallKind.Method, node.name), args);
    }
    if ((target is Field) || ((target is Procedure) && target.isGetter)) {
      // Call via field.
      final fieldValue = _makeCall(
          node,
          new InterfaceSelector(target, callKind: CallKind.PropertyGet),
          new Args<TypeExpr>([receiver]));
      _makeCall(
          null, DynamicSelector.kCall, new Args.withReceiver(args, fieldValue));
      return _staticType(node);
    } else {
      // TODO(alexmarkov): overloaded arithmetic operators
      return _makeCall(node, new InterfaceSelector(target), args);
    }
  }

  @override
  TypeExpr visitPropertyGet(PropertyGet node) {
    var receiver = _visit(node.receiver);
    var args = new Args<TypeExpr>([receiver]);
    final target = node.interfaceTarget;
    if (target == null) {
      return _makeCall(
          node, new DynamicSelector(CallKind.PropertyGet, node.name), args);
    }
    if ((target is Field) || ((target is Procedure) && target.isGetter)) {
      return _makeCall(node,
          new InterfaceSelector(target, callKind: CallKind.PropertyGet), args);
    } else {
      // Tear-off.
      // TODO(alexmarkov): capture receiver type
      _entryPointsListener.addRawCall(new InterfaceSelector(target));
      return _staticType(node);
    }
  }

  @override
  TypeExpr visitPropertySet(PropertySet node) {
    var receiver = _visit(node.receiver);
    var value = _visit(node.value);
    var args = new Args<TypeExpr>([receiver, value]);
    final target = node.interfaceTarget;
    if (target == null) {
      _makeCall(
          node, new DynamicSelector(CallKind.PropertySet, node.name), args);
    } else {
      assertx((target is Field) || ((target is Procedure) && target.isSetter));
      _makeCall(node,
          new InterfaceSelector(target, callKind: CallKind.PropertySet), args);
    }
    return value;
  }

  @override
  TypeExpr visitSuperMethodInvocation(SuperMethodInvocation node) {
    assertx(kPartialMixinResolution);
    assertx(_receiver != null, details: node);
    final args = _visitArguments(_receiver, node.arguments);
    // Re-resolve target due to partial mixin resolution.
    final target =
        _environment.hierarchy.getDispatchTarget(_superclass, node.name);
    if (target == null) {
      return new Type.empty();
    } else {
      if ((target is Field) || ((target is Procedure) && target.isGetter)) {
        // Call via field.
        // TODO(alexmarkov): Consider cleaning up this code as it duplicates
        // processing in DirectInvocation.
        final fieldValue = _makeCall(
            node,
            new DirectSelector(target, callKind: CallKind.PropertyGet),
            new Args<TypeExpr>([_receiver]));
        _makeCall(null, DynamicSelector.kCall,
            new Args.withReceiver(args, fieldValue));
        return _staticType(node);
      } else {
        return _makeCall(node, new DirectSelector(target), args);
      }
    }
  }

  @override
  TypeExpr visitSuperPropertyGet(SuperPropertyGet node) {
    assertx(kPartialMixinResolution);
    assertx(_receiver != null, details: node);
    final args = new Args<TypeExpr>([_receiver]);
    // Re-resolve target due to partial mixin resolution.
    final target =
        _environment.hierarchy.getDispatchTarget(_superclass, node.name);
    if (target == null) {
      return new Type.empty();
    } else {
      if ((target is Field) || ((target is Procedure) && target.isGetter)) {
        return _makeCall(node,
            new DirectSelector(target, callKind: CallKind.PropertyGet), args);
      } else {
        // Tear-off.
        // TODO(alexmarkov): Consider cleaning up this code as it duplicates
        // processing in DirectInvocation.
        // TODO(alexmarkov): capture receiver type
        _entryPointsListener.addRawCall(new DirectSelector(target));
        return _staticType(node);
      }
    }
  }

  @override
  TypeExpr visitSuperPropertySet(SuperPropertySet node) {
    assertx(kPartialMixinResolution);
    assertx(_receiver != null, details: node);
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([_receiver, value]);
    // Re-resolve target due to partial mixin resolution.
    final target = _environment.hierarchy
        .getDispatchTarget(_superclass, node.name, setter: true);
    if (target != null) {
      assertx((target is Field) || ((target is Procedure) && target.isSetter));
      _makeCall(node,
          new DirectSelector(target, callKind: CallKind.PropertySet), args);
    }
    return value;
  }

  @override
  TypeExpr visitNot(Not node) {
    _addUse(_visit(node.operand));
    return _boolType;
  }

  @override
  TypeExpr visitNullLiteral(NullLiteral node) {
    return _nullType;
  }

  @override
  TypeExpr visitRethrow(Rethrow node) {
    return new Type.empty();
  }

  @override
  TypeExpr visitStaticGet(StaticGet node) {
    final args = new Args<TypeExpr>(const <TypeExpr>[]);
    final target = node.target;
    if ((target is Field) || (target is Procedure) && target.isGetter) {
      return _makeCall(node,
          new DirectSelector(target, callKind: CallKind.PropertyGet), args);
    } else {
      // Tear-off.
      _entryPointsListener.addRawCall(new DirectSelector(target));
      return _staticType(node);
    }
  }

  @override
  TypeExpr visitStaticInvocation(StaticInvocation node) {
    final args = _visitArguments(null, node.arguments);
    final target = node.target;
    assertx((target is! Field) && !target.isGetter && !target.isSetter);
    return _makeCall(node, new DirectSelector(target), args);
  }

  @override
  TypeExpr visitStaticSet(StaticSet node) {
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([value]);
    final target = node.target;
    assertx((target is Field) || (target is Procedure) && target.isSetter);
    _makeCall(
        node, new DirectSelector(target, callKind: CallKind.PropertySet), args);
    return value;
  }

  @override
  TypeExpr visitStringConcatenation(StringConcatenation node) {
    node.expressions.forEach(_visit);
    return _stringType;
  }

  @override
  TypeExpr visitStringLiteral(StringLiteral node) {
    return _stringType;
  }

  @override
  TypeExpr visitSymbolLiteral(SymbolLiteral node) {
    return _staticType(node);
  }

  @override
  TypeExpr visitThisExpression(ThisExpression node) {
    assertx(_receiver != null, details: node);
    return _receiver;
  }

  @override
  TypeExpr visitThrow(Throw node) {
    _visit(node.expression);
    return new Type.empty();
  }

  @override
  TypeExpr visitTypeLiteral(TypeLiteral node) {
    return new Type.cone(_environment.typeType);
  }

  @override
  TypeExpr visitVariableGet(VariableGet node) {
    Join v = _variables[node.variable];
    if (v == null) {
      throw 'Unable to find variable ${node.variable}';
    }

    if ((node.promotedType != null) &&
        (node.promotedType != const DynamicType())) {
      return _makeNarrow(v, new Type.cone(node.promotedType));
    }

    return v;
  }

  @override
  TypeExpr visitVariableSet(VariableSet node) {
    Join v = _variables[node.variable];
    assertx(v != null, details: node);

    TypeExpr value = _visit(node.value);
    v.values.add(value);
    return value;
  }

  @override
  TypeExpr visitLoadLibrary(LoadLibrary node) {
    return _staticType(node);
  }

  @override
  TypeExpr visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return _staticType(node);
  }

  @override
  TypeExpr visitAssertStatement(AssertStatement node) {
    if (!kRemoveAsserts) {
      _addUse(_visit(node.condition));
      if (node.message != null) {
        _visit(node.message);
      }
    }
    return null;
  }

  @override
  TypeExpr visitBlock(Block node) {
    node.statements.forEach(_visit);
    return null;
  }

  @override
  TypeExpr visitAssertBlock(AssertBlock node) {
    if (!kRemoveAsserts) {
      node.statements.forEach(_visit);
    }
    return null;
  }

  @override
  TypeExpr visitBreakStatement(BreakStatement node) => null;

  @override
  TypeExpr visitContinueSwitchStatement(ContinueSwitchStatement node) => null;

  @override
  TypeExpr visitDoStatement(DoStatement node) {
    _visit(node.body);
    _visit(node.condition);
    return null;
  }

  @override
  TypeExpr visitEmptyStatement(EmptyStatement node) => null;

  @override
  TypeExpr visitExpressionStatement(ExpressionStatement node) {
    _visit(node.expression);
    return null;
  }

  @override
  TypeExpr visitForInStatement(ForInStatement node) {
    _visit(node.iterable);
    // TODO(alexmarkov): try to infer more precise type from 'iterable'
    _declareVariableWithStaticType(node.variable);
    _visit(node.body);
    return null;
  }

  @override
  TypeExpr visitForStatement(ForStatement node) {
    node.variables.forEach(visitVariableDeclaration);
    if (node.condition != null) {
      _addUse(_visit(node.condition));
    }
    node.updates.forEach(_visit);
    _visit(node.body);
    return null;
  }

  @override
  TypeExpr visitFunctionDeclaration(FunctionDeclaration node) {
    Join v = _declareVariable(node.variable);
    // TODO(alexmarkov): support function types.
    // v.values.add(_concreteType(node.function.functionType));
    v.values.add(new Type.fromStatic(v.staticType));
    _handleNestedFunctionNode(node.function);
    return null;
  }

  @override
  TypeExpr visitIfStatement(IfStatement node) {
    _addUse(_visit(node.condition));
    _visit(node.then);
    if (node.otherwise != null) {
      _visit(node.otherwise);
    }
    return null;
  }

  @override
  TypeExpr visitLabeledStatement(LabeledStatement node) {
    _visit(node.body);
    return null;
  }

  @override
  TypeExpr visitReturnStatement(ReturnStatement node) {
    TypeExpr ret =
        (node.expression != null) ? _visit(node.expression) : _nullType;
    if (_returnValue != null) {
      _returnValue.values.add(ret);
    }
    return null;
  }

  @override
  TypeExpr visitSwitchStatement(SwitchStatement node) {
    _visit(node.expression);
    for (var switchCase in node.cases) {
      switchCase.expressions.forEach(_visit);
      _visit(switchCase.body);
    }
    return null;
  }

  @override
  TypeExpr visitTryCatch(TryCatch node) {
    _visit(node.body);
    for (var catchClause in node.catches) {
      if (catchClause.exception != null) {
        _declareVariableWithStaticType(catchClause.exception);
      }
      if (catchClause.stackTrace != null) {
        _declareVariableWithStaticType(catchClause.stackTrace);
      }
      _visit(catchClause.body);
    }
    return null;
  }

  @override
  TypeExpr visitTryFinally(TryFinally node) {
    _visit(node.body);
    _visit(node.finalizer);
    return null;
  }

  @override
  TypeExpr visitVariableDeclaration(VariableDeclaration node) {
    final v = _declareVariable(node, addInitType: true);
    if (node.initializer == null) {
      v.values.add(_nullType);
    }
    return null;
  }

  @override
  TypeExpr visitWhileStatement(WhileStatement node) {
    _addUse(_visit(node.condition));
    _visit(node.body);
    return null;
  }

  @override
  TypeExpr visitYieldStatement(YieldStatement node) {
    _visit(node.expression);
    return null;
  }

  @override
  TypeExpr visitFieldInitializer(FieldInitializer node) {
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([_receiver, value]);
    _makeCall(node,
        new DirectSelector(node.field, callKind: CallKind.PropertySet), args);
    return null;
  }

  @override
  TypeExpr visitRedirectingInitializer(RedirectingInitializer node) {
    final args = _visitArguments(_receiver, node.arguments);
    _makeCall(node, new DirectSelector(node.target), args);
    return null;
  }

  @override
  TypeExpr visitSuperInitializer(SuperInitializer node) {
    final args = _visitArguments(_receiver, node.arguments);

    Constructor target = null;
    if (kPartialMixinResolution) {
      // Re-resolve target due to partial mixin resolution.
      for (var replacement in _superclass.constructors) {
        if (node.target.name == replacement.name) {
          target = replacement;
          break;
        }
      }
    } else {
      target = node.target;
    }
    assertx(target != null);
    _makeCall(node, new DirectSelector(target), args);
    return null;
  }

  @override
  TypeExpr visitLocalInitializer(LocalInitializer node) {
    visitVariableDeclaration(node.variable);
    return null;
  }

  @override
  TypeExpr visitAssertInitializer(AssertInitializer node) {
    if (!kRemoveAsserts) {
      _visit(node.statement);
    }
    return null;
  }

  @override
  TypeExpr visitInvalidInitializer(InvalidInitializer node) {
    return null;
  }

  @override
  TypeExpr visitConstantExpression(ConstantExpression node) {
    return constantAllocationCollector.typeFor(node.constant);
  }
}

class EmptyEntryPointsListener implements EntryPointsListener {
  final Map<Class, IntClassId> _classIds = <Class, IntClassId>{};
  int _classIdCounter = 0;

  @override
  void addRawCall(Selector selector) {}

  @override
  void addDirectFieldAccess(Field field, Type value) {}

  @override
  ConcreteType addAllocatedClass(Class c) {
    final classId = (_classIds[c] ??= new IntClassId(++_classIdCounter));
    return new ConcreteType(classId, c.rawType);
  }
}

class CreateAllSummariesVisitor extends RecursiveVisitor<Null> {
  final TypeEnvironment _environment;
  final SummaryCollector _summaryColector;

  CreateAllSummariesVisitor(this._environment)
      : _summaryColector = new SummaryCollector(_environment,
            new EmptyEntryPointsListener(), new NativeCodeOracle(null, null));

  @override
  defaultMember(Member m) {
    if (!m.isAbstract && !(m is Field && m.initializer == null)) {
      _summaryColector.createSummary(m);
    }
  }
}

class ConstantAllocationCollector extends ConstantVisitor<Type> {
  final SummaryCollector summaryCollector;

  final Map<Constant, Type> constants = <Constant, Type>{};

  ConstantAllocationCollector(this.summaryCollector);

  // Ensures the transtive graph of [constant] got scanned for potential
  // allocations and field types.  Returns the [Type] of this constant.
  Type typeFor(Constant constant) {
    return constants.putIfAbsent(constant, () => constant.accept(this));
  }

  @override
  defaultConstant(Constant constant) {
    throw 'There is no support for constant "$constant" in TFA yet!';
  }

  @override
  Type visitNullConstant(NullConstant constant) {
    return summaryCollector._nullType;
  }

  @override
  Type visitBoolConstant(BoolConstant constant) {
    return summaryCollector._boolType;
  }

  @override
  Type visitIntConstant(IntConstant constant) {
    return summaryCollector._intType;
  }

  @override
  Type visitDoubleConstant(DoubleConstant constant) {
    return summaryCollector._doubleType;
  }

  @override
  Type visitStringConstant(StringConstant constant) {
    return summaryCollector._stringType;
  }

  @override
  Type visitMapConstant(MapConstant node) {
    throw 'The kernel2kernel constants transformation desugars const maps!';
  }

  @override
  Type visitListConstant(ListConstant constant) {
    for (final Constant entry in constant.entries) {
      typeFor(entry);
    }
    return new Type.cone(constant.getType(summaryCollector._environment));
  }

  @override
  Type visitInstanceConstant(InstanceConstant constant) {
    final resultType =
        summaryCollector._entryPointsListener.addAllocatedClass(constant.klass);
    constant.fieldValues.forEach((Reference fieldReference, Constant value) {
      summaryCollector._entryPointsListener
          .addDirectFieldAccess(fieldReference.asField, typeFor(value));
    });
    return resultType;
  }

  @override
  Type visitTearOffConstant(TearOffConstant constant) {
    final Procedure procedure = constant.procedure;
    summaryCollector._entryPointsListener
        .addRawCall(new DirectSelector(procedure));
    return new Type.cone(constant.getType(summaryCollector._environment));
  }

  @override
  Type visitPartialInstantiationConstant(
      PartialInstantiationConstant constant) {
    constant.tearOffConstant.accept(this);
    return new Type.cone(constant.getType(summaryCollector._environment));
  }

  @override
  Type visitTypeLiteralConstant(TypeLiteralConstant constant) {
    return new Type.cone(constant.getType(summaryCollector._environment));
  }
}
