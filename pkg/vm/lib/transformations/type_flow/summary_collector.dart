// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Creation of type flow summaries out of kernel AST.
library vm.transformations.type_flow.summary_collector;

import 'dart:core' hide Type;

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/ast.dart' as ast show Statement, StatementVisitor;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/type_algebra.dart' show Substitution;

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

  @override
  void visitCreateConcreteType(CreateConcreteType expr) {
    for (int i = 0; i < expr.flattenedTypeArgs.length; ++i) {
      expr.flattenedTypeArgs[i] =
          _normalizeExpr(expr.flattenedTypeArgs[i], true);
      if (_inLoop) return;
    }
  }

  @override
  void visitCreateRuntimeType(CreateRuntimeType expr) {
    for (int i = 0; i < expr.flattenedTypeArgs.length; ++i) {
      expr.flattenedTypeArgs[i] =
          _normalizeExpr(expr.flattenedTypeArgs[i], true);
      if (_inLoop) return;
    }
  }

  @override
  void visitTypeCheck(TypeCheck expr) {
    expr.arg = _normalizeExpr(expr.arg, true);
    if (_inLoop) return;
    expr.type = _normalizeExpr(expr.type, true);
  }

  @override
  void visitExtract(Extract expr) {
    expr.arg = _normalizeExpr(expr.arg, true);
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

enum FieldSummaryType { kFieldGuard, kInitializer }

/// Create a type flow summary for a member from the kernel AST.
class SummaryCollector extends RecursiveVisitor<TypeExpr> {
  final Target target;
  final TypeEnvironment _environment;
  final EntryPointsListener _entryPointsListener;
  final NativeCodeOracle _nativeCodeOracle;
  final GenericInterfacesInfo _genericInterfacesInfo;

  final Map<TreeNode, Call> callSites = <TreeNode, Call>{};
  final _FallthroughDetector _fallthroughDetector = new _FallthroughDetector();

  Summary _summary;
  Map<VariableDeclaration, Join> _variableJoins;
  Map<VariableDeclaration, TypeExpr> _variables;
  Join _returnValue;
  Parameter _receiver;
  ConstantAllocationCollector constantAllocationCollector;
  RuntimeTypeTranslator _translator;

  // Currently only used for factory constructors.
  Map<TypeParameter, TypeExpr> _fnTypeVariables;

  SummaryCollector(this.target, this._environment, this._entryPointsListener,
      this._nativeCodeOracle, this._genericInterfacesInfo) {
    assertx(_genericInterfacesInfo != null);
    constantAllocationCollector = new ConstantAllocationCollector(this);
  }

  Summary createSummary(Member member,
      {fieldSummaryType: FieldSummaryType.kInitializer}) {
    debugPrint("===== ${member} =====");
    assertx(!member.isAbstract);

    _variableJoins = <VariableDeclaration, Join>{};
    _variables = <VariableDeclaration, TypeExpr>{};
    _returnValue = null;
    _receiver = null;

    final hasReceiver = hasReceiverArg(member);

    if (member is Field) {
      if (hasReceiver) {
        final int numArgs =
            fieldSummaryType == FieldSummaryType.kInitializer ? 1 : 2;
        _summary = new Summary(
            parameterCount: numArgs, positionalParameterCount: numArgs);
        // TODO(alexmarkov): subclass cone
        _receiver = _declareParameter(
            "this", member.enclosingClass.rawType, null,
            isReceiver: true);
        _environment.thisType = member.enclosingClass?.thisType;
      } else {
        _summary = new Summary();
      }

      _translator = new RuntimeTypeTranslator(
          _summary, _receiver, null, _genericInterfacesInfo);

      if (fieldSummaryType == FieldSummaryType.kInitializer) {
        assertx(member.initializer != null);
        _summary.result = _visit(member.initializer);
      } else {
        Parameter valueParam = _declareParameter("value", member.type, null);
        TypeExpr runtimeType = _translator.translate(member.type);
        final check = new TypeCheck(valueParam, runtimeType, null);
        _summary.add(check);
        _summary.result = check;
      }
    } else {
      FunctionNode function = member.function;

      final numTypeParameters = numTypeParams(member);
      final firstParamIndex = (hasReceiver ? 1 : 0) + numTypeParameters;

      _summary = new Summary(
          parameterCount: firstParamIndex +
              function.positionalParameters.length +
              function.namedParameters.length,
          positionalParameterCount:
              firstParamIndex + function.positionalParameters.length,
          requiredParameterCount:
              firstParamIndex + function.requiredParameterCount);

      if (numTypeParameters > 0) {
        _fnTypeVariables = <TypeParameter, TypeExpr>{};
        for (int i = 0; i < numTypeParameters; ++i) {
          _fnTypeVariables[function.typeParameters[i]] =
              _declareParameter(function.typeParameters[i].name, null, null);
        }
      }

      if (hasReceiver) {
        // TODO(alexmarkov): subclass cone
        _receiver = _declareParameter(
            "this", member.enclosingClass.rawType, null,
            isReceiver: true);
        _environment.thisType = member.enclosingClass?.thisType;
      }

      _translator = new RuntimeTypeTranslator(
          _summary, _receiver, _fnTypeVariables, _genericInterfacesInfo);

      // Handle forwarding stubs. We need to check types against the types of
      // the forwarding stub's target, [member.forwardingStubSuperTarget].
      FunctionNode useTypesFrom = member.function;
      if (member is Procedure &&
          member.isForwardingStub &&
          member.forwardingStubSuperTarget != null) {
        final target = member.forwardingStubSuperTarget;
        if (target is Field) {
          useTypesFrom = FunctionNode(null, positionalParameters: [
            VariableDeclaration("value", type: target.type)
          ]);
        } else {
          useTypesFrom = member.forwardingStubSuperTarget.function;
        }
      }

      for (int i = 0; i < function.positionalParameters.length; ++i) {
        _declareParameter(
            function.positionalParameters[i].name,
            function.positionalParameters[i].isGenericCovariantImpl
                ? null
                : useTypesFrom.positionalParameters[i].type,
            function.positionalParameters[i].initializer);
      }
      for (int i = 0; i < function.namedParameters.length; ++i) {
        _declareParameter(
            function.namedParameters[i].name,
            function.namedParameters[i].isGenericCovariantImpl
                ? null
                : useTypesFrom.namedParameters[i].type,
            function.namedParameters[i].initializer);
      }

      int count = firstParamIndex;
      for (int i = 0; i < function.positionalParameters.length; ++i) {
        Join v = _declareVariable(function.positionalParameters[i],
            useTypeCheck:
                function.positionalParameters[i].isGenericCovariantImpl,
            checkType: useTypesFrom.positionalParameters[i].type);
        v.values.add(_summary.statements[count++]);
      }
      for (int i = 0; i < function.namedParameters.length; ++i) {
        Join v = _declareVariable(function.namedParameters[i],
            useTypeCheck: function.namedParameters[i].isGenericCovariantImpl,
            checkType: useTypesFrom.namedParameters[i].type);
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

    final numTypeParameters = numTypeParams(member);
    for (int i = 0; i < numTypeParameters; ++i) {
      args.add(const AnyType());
    }

    if (hasReceiverArg(member)) {
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

  Args<TypeExpr> _visitArguments(TypeExpr receiver, Arguments arguments,
      {bool passTypeArguments: false}) {
    final args = <TypeExpr>[];
    if (passTypeArguments) {
      for (var type in arguments.types) {
        args.add(_translator.translate(type));
      }
    }
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
    Type staticType;
    if (type != null) {
      staticType = isReceiver ? new ConeType(type) : new Type.fromStatic(type);
    }
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

  Join _declareVariable(VariableDeclaration decl,
      {bool addInitType: false,
      bool useTypeCheck: false,
      DartType checkType: null}) {
    final type = checkType ?? decl.type;
    Join join = new Join(decl.name, type);
    _summary.add(join);
    _variableJoins[decl] = join;

    TypeExpr variable = join;
    if (useTypeCheck) {
      TypeExpr runtimeType = _translator.translate(type);
      variable = new TypeCheck(variable, runtimeType, decl);
      _summary.add(variable);
      _summary.add(new Use(variable));
    }

    _variables[decl] = variable;

    if (decl.initializer != null) {
      TypeExpr initType = _visit(decl.initializer);
      if (addInitType) {
        join.values.add(initType);
      }
    }

    return join;
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
    } else if (arg is Join || arg is Call || arg is TypeCheck) {
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

  Type _cachedSymbolType;
  Type get _symbolType =>
      _cachedSymbolType ??= new Type.cone(_environment.symbolType);

  Type _cachedNullType;
  Type get _nullType => _cachedNullType ??= new Type.nullable(new Type.empty());

  Class get _superclass => _environment.thisType.classNode.superclass;

  Type _intLiteralType(int value) {
    Class concreteClass =
        target.concreteIntLiteralClass(_environment.coreTypes, value);
    return concreteClass != null
        ? _entryPointsListener.addAllocatedClass(concreteClass)
        : _intType;
  }

  Type _stringLiteralType(String value) {
    Class concreteClass =
        target.concreteStringLiteralClass(_environment.coreTypes, value);
    return concreteClass != null
        ? _entryPointsListener.addAllocatedClass(concreteClass)
        : _stringType;
  }

  void _handleNestedFunctionNode(FunctionNode node) {
    final oldReturn = _returnValue;
    final oldVariableJoins = _variableJoins;
    final oldVariables = _variables;
    _returnValue = null;
    _variableJoins = <VariableDeclaration, Join>{};
    _variableJoins.addAll(oldVariableJoins);
    _variables = <VariableDeclaration, TypeExpr>{};
    _variables.addAll(oldVariables);

    // Approximate parameters of nested functions with static types.
    // TODO(sjindel/tfa): Use TypeCheck for closure parameters.
    node.positionalParameters.forEach(_declareVariableWithStaticType);
    node.namedParameters.forEach(_declareVariableWithStaticType);

    _visit(node.body);

    _returnValue = oldReturn;
    _variableJoins = oldVariableJoins;
    _variables = oldVariables;
  }

  @override
  defaultTreeNode(TreeNode node) =>
      throw 'Unexpected node ${node.runtimeType}: $node at ${node.location}';

  @override
  TypeExpr visitAsExpression(AsExpression node) {
    TypeExpr operand = _visit(node.operand);
    Type type = new Type.fromStatic(node.type);

    TypeExpr result = _makeNarrow(operand, type);

    TypeExpr runtimeType = _translator.translate(node.type);
    if (runtimeType is Statement) {
      result = new TypeCheck(operand, runtimeType, /*parameter=*/ null);
      _summary.add(result);
    }

    return result;
  }

  @override
  TypeExpr visitBoolLiteral(BoolLiteral node) {
    return _boolType;
  }

  @override
  TypeExpr visitIntLiteral(IntLiteral node) {
    return _intLiteralType(node.value);
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
    ConcreteType klass =
        _entryPointsListener.addAllocatedClass(node.constructedType.classNode);
    TypeExpr receiver =
        _translator.instantiateConcreteType(klass, node.arguments.types);
    final args = _visitArguments(receiver, node.arguments);
    _makeCall(node, new DirectSelector(node.target), args);
    return receiver;
  }

  @override
  TypeExpr visitDirectMethodInvocation(DirectMethodInvocation node) {
    final receiver = _visit(node.receiver);
    final args = _visitArguments(receiver, node.arguments);
    final target = node.target;
    assertx(target is! Field);
    assertx(!target.isGetter && !target.isSetter);
    if (receiver is ThisExpression) {
      _entryPointsListener.recordMemberCalledViaThis(target);
    } else {
      // Conservatively record direct invocations with non-this receiver
      // as being done via interface selectors.
      _entryPointsListener.recordMemberCalledViaInterfaceSelector(target);
    }
    return _makeCall(node, new DirectSelector(target), args);
  }

  @override
  TypeExpr visitDirectPropertyGet(DirectPropertyGet node) {
    final receiver = _visit(node.receiver);
    final args = new Args<TypeExpr>([receiver]);
    final target = node.target;
    // No need to record this invocation as performed via this or via interface
    // selector as PropertyGet invocations are not tracked at all.
    return _makeCall(
        node, new DirectSelector(target, callKind: CallKind.PropertyGet), args);
  }

  @override
  TypeExpr visitDirectPropertySet(DirectPropertySet node) {
    final receiver = _visit(node.receiver);
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([receiver, value]);
    final target = node.target;
    assertx((target is Field) || ((target is Procedure) && target.isSetter));
    if (receiver is ThisExpression) {
      _entryPointsListener.recordMemberCalledViaThis(target);
    } else {
      // Conservatively record direct invocations with non-this receiver
      // as being done via interface selectors.
      _entryPointsListener.recordMemberCalledViaInterfaceSelector(target);
    }
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
    Class concreteClass =
        target.concreteListLiteralClass(_environment.coreTypes);
    if (concreteClass != null) {
      return _translator.instantiateConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass),
          [node.typeArgument]);
    }
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
    Class concreteClass =
        target.concreteMapLiteralClass(_environment.coreTypes);
    if (concreteClass != null) {
      return _translator.instantiateConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass),
          [node.keyType, node.valueType]);
    }
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
          (node.receiver is ThisExpression)
              ? new VirtualSelector(target, callKind: CallKind.PropertyGet)
              : new InterfaceSelector(target, callKind: CallKind.PropertyGet),
          new Args<TypeExpr>([receiver]));
      _makeCall(
          null, DynamicSelector.kCall, new Args.withReceiver(args, fieldValue));
      return _staticType(node);
    } else {
      // TODO(alexmarkov): overloaded arithmetic operators
      return _makeCall(
          node,
          (node.receiver is ThisExpression)
              ? new VirtualSelector(target)
              : new InterfaceSelector(target),
          args);
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
    return _makeCall(
        node,
        (node.receiver is ThisExpression)
            ? new VirtualSelector(target, callKind: CallKind.PropertyGet)
            : new InterfaceSelector(target, callKind: CallKind.PropertyGet),
        args);
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
      _makeCall(
          node,
          (node.receiver is ThisExpression)
              ? new VirtualSelector(target, callKind: CallKind.PropertySet)
              : new InterfaceSelector(target, callKind: CallKind.PropertySet),
          args);
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
        // Call via field/getter.
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
        _entryPointsListener.recordMemberCalledViaThis(target);
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
      return _makeCall(node,
          new DirectSelector(target, callKind: CallKind.PropertyGet), args);
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
      _entryPointsListener.recordMemberCalledViaThis(target);
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
    return _makeCall(
        node, new DirectSelector(target, callKind: CallKind.PropertyGet), args);
  }

  @override
  TypeExpr visitStaticInvocation(StaticInvocation node) {
    final args = _visitArguments(null, node.arguments,
        passTypeArguments: node.target.isFactory);
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
    return _stringLiteralType(node.value);
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
    final v = _variables[node.variable];
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
    Join v = _variableJoins[node.variable];
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

class RuntimeTypeTranslator extends DartTypeVisitor<TypeExpr> {
  final Summary summary;
  final Map<TypeParameter, TypeExpr> functionTypeVariables;
  final Map<DartType, TypeExpr> typesCache = <DartType, TypeExpr>{};
  final TypeExpr receiver;
  final GenericInterfacesInfo genericInterfacesInfo;

  RuntimeTypeTranslator(this.summary, this.receiver, this.functionTypeVariables,
      this.genericInterfacesInfo) {}

  // Create a type translator which can be used only for types with no free type
  // variables.
  RuntimeTypeTranslator.forClosedTypes(this.genericInterfacesInfo)
      : summary = null,
        functionTypeVariables = null,
        receiver = null {}

  TypeExpr instantiateConcreteType(ConcreteType type, List<DartType> typeArgs) {
    if (typeArgs.isEmpty) return type;

    // This function is very similar to 'visitInterfaceType', but with
    // many small differences.
    final klass = type.classNode;
    final substitution = Substitution.fromPairs(klass.typeParameters, typeArgs);
    final flattenedTypeArgs =
        genericInterfacesInfo.flattenedTypeArgumentsFor(klass);
    final flattenedTypeExprs = new List<TypeExpr>(flattenedTypeArgs.length);

    bool createConcreteType = true;
    bool allAnyType = true;
    for (int i = 0; i < flattenedTypeArgs.length; ++i) {
      final typeExpr =
          translate(substitution.substituteType(flattenedTypeArgs[i]));
      if (typeExpr != const AnyType()) allAnyType = false;
      if (typeExpr is Statement) createConcreteType = false;
      flattenedTypeExprs[i] = typeExpr;
    }

    if (allAnyType) return type;

    if (createConcreteType) {
      return new ConcreteType(type.classId, type.classNode,
          new List<Type>.from(flattenedTypeExprs));
    } else {
      final instantiate = new CreateConcreteType(type, flattenedTypeExprs);
      summary.add(instantiate);
      return instantiate;
    }
  }

  // Creates a TypeExpr representing the set of types which can flow through a
  // given DartType.
  //
  // Will return AnyType, RuntimeType or Statement.
  TypeExpr translate(DartType type) {
    final cached = typesCache[type];
    if (cached != null) return cached;

    // During type translation, loops can arise via super-bounded types:
    //
    //   class A<T> extends Comparable<A<T>> {}
    //
    // Creating the factored type arguments of A will lead to an infinite loop.
    // We break such loops by inserting an 'AnyType' in place of the currently
    // processed type, ensuring we try to build 'A<T>' in the process of
    // building 'A<T>'.
    typesCache[type] = const AnyType();
    final result = type.accept(this);
    assertx(result is AnyType || result is RuntimeType || result is Statement);
    typesCache[type] = result;
    return result;
  }

  @override
  TypeExpr defaultDartType(DartType node) => const AnyType();

  @override
  TypeExpr visitDynamicType(DynamicType type) => new RuntimeType(type, null);
  @override
  TypeExpr visitVoidType(VoidType type) => new RuntimeType(type, null);
  @override
  TypeExpr visitBottomType(BottomType type) => new RuntimeType(type, null);

  @override
  visitTypedefType(TypedefType node) => translate(node.unalias);

  @override
  visitInterfaceType(InterfaceType type) {
    if (type.typeArguments.isEmpty) return new RuntimeType(type, null);

    final substitution = Substitution.fromPairs(
        type.classNode.typeParameters, type.typeArguments);
    final flattenedTypeArgs =
        genericInterfacesInfo.flattenedTypeArgumentsFor(type.classNode);
    final flattenedTypeExprs = new List<TypeExpr>(flattenedTypeArgs.length);

    bool createRuntimeType = true;
    for (var i = 0; i < flattenedTypeArgs.length; ++i) {
      final typeExpr =
          translate(substitution.substituteType(flattenedTypeArgs[i]));
      if (typeExpr == const AnyType()) return const AnyType();
      if (typeExpr is! RuntimeType) createRuntimeType = false;
      flattenedTypeExprs[i] = typeExpr;
    }

    if (createRuntimeType) {
      return new RuntimeType(new InterfaceType(type.classNode),
          new List<RuntimeType>.from(flattenedTypeExprs));
    } else {
      final instantiate =
          new CreateRuntimeType(type.classNode, flattenedTypeExprs);
      summary.add(instantiate);
      return instantiate;
    }
  }

  @override
  visitTypeParameterType(TypeParameterType type) {
    if (functionTypeVariables != null) {
      final result = functionTypeVariables[type.parameter];
      if (result != null) return result;
    }
    if (type.parameter.parent is! Class) return const AnyType();
    final interfaceClass = type.parameter.parent as Class;
    assertx(receiver != null);
    final extract = new Extract(receiver, interfaceClass,
        interfaceClass.typeParameters.indexOf(type.parameter));
    summary.add(extract);
    return extract;
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
    return new ConcreteType(classId, c, null);
  }

  @override
  void recordMemberCalledViaInterfaceSelector(Member target) {}

  @override
  void recordMemberCalledViaThis(Member target) {}
}

class CreateAllSummariesVisitor extends RecursiveVisitor<Null> {
  final TypeEnvironment _environment;
  final SummaryCollector _summaryCollector;

  CreateAllSummariesVisitor(
      Target target, this._environment, GenericInterfacesInfo hierarchy)
      : _summaryCollector = new SummaryCollector(
            target,
            _environment,
            new EmptyEntryPointsListener(),
            new NativeCodeOracle(null, null),
            hierarchy);

  @override
  defaultMember(Member m) {
    if (!m.isAbstract && !(m is Field && m.initializer == null)) {
      _summaryCollector.createSummary(m);
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
    return summaryCollector._intLiteralType(constant.value);
  }

  @override
  Type visitDoubleConstant(DoubleConstant constant) {
    return summaryCollector._doubleType;
  }

  @override
  Type visitStringConstant(StringConstant constant) {
    return summaryCollector._stringLiteralType(constant.value);
  }

  @override
  visitSymbolConstant(SymbolConstant constant) {
    return summaryCollector._symbolType;
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
    Class concreteClass = summaryCollector.target
        .concreteConstListLiteralClass(summaryCollector._environment.coreTypes);
    return concreteClass != null
        ? summaryCollector._entryPointsListener.addAllocatedClass(concreteClass)
        : new Type.cone(constant.getType(summaryCollector._environment));
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
