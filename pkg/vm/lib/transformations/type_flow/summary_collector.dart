// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Creation of type flow summaries out of kernel AST.

import 'dart:core' hide Type;

import 'package:front_end/src/api_prototype/static_weak_references.dart'
    show StaticWeakReferences;
import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/ast.dart' as ast show Statement, StatementVisitor;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClosedWorldClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, SubtypeCheckMode, TypeEnvironment;
import 'package:kernel/type_algebra.dart' show Substitution;

import 'calls.dart';
import 'native_code.dart';
import 'protobuf_handler.dart' show ProtobufHandler;
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
  final TypesBuilder _typesBuilder;
  Set<Statement> _processed = new Set<Statement>();
  Set<Statement> _pending = new Set<Statement>();
  bool _inLoop = false;

  _SummaryNormalizer(this._summary, this._typesBuilder);

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
      if (st is Call || st is TypeCheck || st is NarrowNotNull) {
        _normalizeExpr(st, false);
      } else if (st is Use) {
        _normalizeExpr(st.arg, true);
      }
    }

    _summary.result = _normalizeExpr(_summary.result, true);
  }

  TypeExpr _normalizeExpr(TypeExpr st, bool isResultUsed) {
    assert(!_inLoop);
    assert(st is! Use);
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
          } else {
            final first = st.values.first;
            if (first is Type) {
              bool allMatch = true;
              for (int i = 1; i < n; ++i) {
                if (first != st.values[i]) {
                  allMatch = false;
                  break;
                }
              }
              if (allMatch) {
                return first;
              }
            }
          }
        } else if (st is NarrowNotNull) {
          // This pattern may appear after approximations during summary
          // normalization, so it's not enough to handle it in
          // _makeNarrowNotNull.
          final arg = st.arg;
          if (arg is Type) {
            return st.handleArgument(arg);
          }
        } else if (st is Narrow) {
          // This pattern may appear after approximations during summary
          // normalization (so it's not enough to handle it in _makeNarrow).
          final arg = st.arg;
          if (st.type is AnyType) {
            if (arg is Type) {
              return (arg is NullableType) ? arg.baseType : arg;
            }
            if (arg is Call && arg.isInstanceCreation) {
              return arg;
            }
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
      assert(st is Type);
      return st;
    }
  }

  TypeExpr _handleLoop(Statement st) {
    if (st is Join) {
      // Approximate Join with static type.
      _inLoop = false;
      debugPrint("Approximated ${st} with ${st.staticType}");
      Statistics.joinsApproximatedToBreakLoops++;
      return _typesBuilder.fromStaticType(st.staticType, true);
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

  @override
  void visitApplyNullability(ApplyNullability expr) {
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
    return function.body!.accept(this);
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
  bool visitIfStatement(IfStatement node) {
    final otherwise = node.otherwise;
    if (otherwise == null) return true;
    return node.then.accept(this) || otherwise.accept(this);
  }

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

/// Collects sets of captured variables, as well as variables
/// modified in loops and try blocks.
class _VariablesInfoCollector extends RecursiveVisitor {
  /// Maps declared variables to their declaration index.
  final Map<VariableDeclaration, int> varIndex = <VariableDeclaration, int>{};

  /// Variable declarations.
  final List<VariableDeclaration> varDeclarations = <VariableDeclaration>[];

  /// Set of captured variables.
  Set<VariableDeclaration>? captured;

  /// Set of variables which were modified for each loop, switch statement
  /// and try block statement. Doesn't include captured variables and
  /// variables declared inside the statement's body.
  final Map<ast.Statement, Set<int>> modifiedSets = <ast.Statement, Set<int>>{};

  /// Number of variables at function entry.
  int numVariablesAtFunctionEntry = 0;

  /// Active loops, switch statements and try blocks.
  List<ast.Statement>? activeStatements;

  /// Number of variables at entry of active statements.
  List<int>? numVariablesAtActiveStatements;

  _VariablesInfoCollector(Member member) {
    member.accept(this);
  }

  int get numVariables => varDeclarations.length;

  bool isCaptured(VariableDeclaration variable) {
    final captured = this.captured;
    return captured != null && captured.contains(variable);
  }

  Set<int> getModifiedVariables(ast.Statement st) {
    return modifiedSets[st] ?? const <int>{};
  }

  void _visitFunction(LocalFunction node) {
    final savedActiveStatements = activeStatements;
    activeStatements = null;
    final savedNumVariablesAtActiveStatements = numVariablesAtActiveStatements;
    numVariablesAtActiveStatements = null;
    final savedNumVariablesAtFunctionEntry = numVariablesAtFunctionEntry;
    numVariablesAtFunctionEntry = numVariables;

    final function = node.function;
    function.accept(this);

    activeStatements = savedActiveStatements;
    numVariablesAtActiveStatements = savedNumVariablesAtActiveStatements;
    numVariablesAtFunctionEntry = savedNumVariablesAtFunctionEntry;
  }

  bool _isDeclaredBefore(int variableIndex, int entryDeclarationCounter) =>
      variableIndex < entryDeclarationCounter;

  void _captureVariable(VariableDeclaration variable) {
    (captured ??= <VariableDeclaration>{}).add(variable);
  }

  void _useVariable(VariableDeclaration variable, bool isVarAssignment) {
    final index = varIndex[variable]!;
    if (_isDeclaredBefore(index, numVariablesAtFunctionEntry)) {
      _captureVariable(variable);
      return;
    }
    final activeStatements = this.activeStatements;
    if (isVarAssignment && activeStatements != null) {
      for (int i = activeStatements.length - 1; i >= 0; --i) {
        if (_isDeclaredBefore(index, numVariablesAtActiveStatements![i])) {
          final st = activeStatements[i];
          (modifiedSets[st] ??= <int>{}).add(index);
        } else {
          break;
        }
      }
    }
  }

  void _startCollectingModifiedVariables(ast.Statement node) {
    (activeStatements ??= <ast.Statement>[]).add(node);
    (numVariablesAtActiveStatements ??= <int>[]).add(numVariables);
  }

  void _endCollectingModifiedVariables() {
    activeStatements!.removeLast();
    numVariablesAtActiveStatements!.removeLast();
  }

  @override
  visitConstructor(Constructor node) {
    // Need to visit parameters before initializers.
    visitList(node.function.positionalParameters, this);
    visitList(node.function.namedParameters, this);
    visitList(node.initializers, this);
    node.function.body?.accept(this);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    node.variable.accept(this);
    _visitFunction(node);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _visitFunction(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    final int index = numVariables;
    varDeclarations.add(node);
    varIndex[node] = index;
    node.visitChildren(this);
  }

  @override
  visitVariableGet(VariableGet node) {
    node.visitChildren(this);
    _useVariable(node.variable, false);
  }

  @override
  visitVariableSet(VariableSet node) {
    node.visitChildren(this);
    _useVariable(node.variable, true);
  }

  @override
  visitTryCatch(TryCatch node) {
    _startCollectingModifiedVariables(node);
    node.body.accept(this);
    _endCollectingModifiedVariables();
    visitList(node.catches, this);
  }

  @override
  visitTryFinally(TryFinally node) {
    _startCollectingModifiedVariables(node);
    node.body.accept(this);
    _endCollectingModifiedVariables();
    node.finalizer.accept(this);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    _startCollectingModifiedVariables(node);
    node.visitChildren(this);
    _endCollectingModifiedVariables();
  }

  @override
  visitDoStatement(DoStatement node) {
    _startCollectingModifiedVariables(node);
    node.visitChildren(this);
    _endCollectingModifiedVariables();
  }

  @override
  visitForStatement(ForStatement node) {
    visitList(node.variables, this);
    _startCollectingModifiedVariables(node);
    node.condition?.accept(this);
    node.body.accept(this);
    visitList(node.updates, this);
    _endCollectingModifiedVariables();
  }

  @override
  visitForInStatement(ForInStatement node) {
    node.iterable.accept(this);
    _startCollectingModifiedVariables(node);
    node.variable.accept(this);
    node.body.accept(this);
    _endCollectingModifiedVariables();
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    _startCollectingModifiedVariables(node);
    visitList(node.cases, this);
    _endCollectingModifiedVariables();
  }
}

Iterable<Name> getSelectors(ClassHierarchy hierarchy, Class cls,
        {bool setters = false}) =>
    hierarchy
        .getInterfaceMembers(cls, setters: setters)
        .map((Member m) => m.name);

enum FieldSummaryType { kFieldGuard, kInitializer }

/// Create a type flow summary for a member from the kernel AST.
class SummaryCollector extends RecursiveResultVisitor<TypeExpr?> {
  final Target target;
  final TypeEnvironment _environment;
  final ClosedWorldClassHierarchy _hierarchy;
  final EntryPointsListener _entryPointsListener;
  final TypesBuilder _typesBuilder;
  final NativeCodeOracle _nativeCodeOracle;
  final GenericInterfacesInfo _genericInterfacesInfo;
  final ProtobufHandler? _protobufHandler;

  final Map<TreeNode, Call> callSites = <TreeNode, Call>{};
  final Map<AsExpression, TypeCheck> explicitCasts =
      <AsExpression, TypeCheck>{};
  final Map<IsExpression, TypeCheck> isTests = <IsExpression, TypeCheck>{};
  final Map<TreeNode, NarrowNotNull> nullTests = <TreeNode, NarrowNotNull>{};
  final _FallthroughDetector _fallthroughDetector = new _FallthroughDetector();
  final Set<Name> _nullMethodsAndGetters = <Name>{};
  final Set<Name> _nullSetters = <Name>{};

  Summary _summary = Summary('<unused>');
  late _VariablesInfoCollector _variablesInfo;

  // Current value of each variable. May contain null if variable is not
  // declared yet, or EmptyType if current location is unreachable
  // (e.g. after return or throw).
  List<TypeExpr?> _variableValues = const <TypeExpr?>[];

  // Contains Joins which accumulate all values of certain variables.
  // Used only when all variable values should be merged regardless of control
  // flow. Such accumulating joins are used for
  // 1. captured variables, as closures may potentially see any value;
  // 2. variables modified inside try blocks (while in the try block), as
  // catch can potentially see any value assigned to a variable inside try
  // block.
  // If _variableCells[i] != null, then all values are accumulated in the
  // _variableCells[i]. _variableValues[i] does not change and remains equal
  // to _variableCells[i].
  List<Join?> _variableCells = const <Join?>[];

  // Counts number of Joins inserted for each variable. Only used to set
  // readable names for such joins (foo_0, foo_1 etc.)
  List<int> _variableVersions = const <int>[];

  // State of variables after corresponding LabeledStatement.
  // Used to collect states from BreakStatements.
  Map<LabeledStatement, List<TypeExpr?>>? _variableValuesAfterLabeledStatements;

  // Joins corresponding to variables on entry to switch cases.
  // Used to propagate state from ContinueSwitchStatement to a target case.
  Map<SwitchCase, List<Join?>>? _joinsAtSwitchCases;

  // Join which accumulates all return values.
  Join? _returnValue;

  Parameter? _receiver;
  late ConstantAllocationCollector constantAllocationCollector;
  late RuntimeTypeTranslatorImpl _translator;
  StaticTypeContext? _staticTypeContext;

  // Currently only used for factory constructors.
  Map<TypeParameter, TypeExpr>? _fnTypeVariables;

  SummaryCollector(
      this.target,
      this._environment,
      this._hierarchy,
      this._entryPointsListener,
      this._typesBuilder,
      this._nativeCodeOracle,
      this._genericInterfacesInfo,
      this._protobufHandler) {
    constantAllocationCollector = new ConstantAllocationCollector(this);
    _nullMethodsAndGetters.addAll(getSelectors(
        _hierarchy, _environment.coreTypes.deprecatedNullClass,
        setters: false));
    _nullSetters.addAll(getSelectors(
        _hierarchy, _environment.coreTypes.deprecatedNullClass,
        setters: true));
  }

  Summary createSummary(Member member,
      {fieldSummaryType = FieldSummaryType.kInitializer}) {
    final String summaryName =
        "${member}${fieldSummaryType == FieldSummaryType.kFieldGuard ? " (guard)" : ""}";
    debugPrint("===== $summaryName =====");
    assert(!member.isAbstract);

    _protobufHandler?.beforeSummaryCreation(member);

    _staticTypeContext = new StaticTypeContext(member, _environment);
    _variablesInfo = new _VariablesInfoCollector(member);
    _variableValues =
        new List<TypeExpr?>.filled(_variablesInfo.numVariables, null);
    _variableCells = new List<Join?>.filled(_variablesInfo.numVariables, null);
    _variableVersions = new List<int>.filled(_variablesInfo.numVariables, 0);
    _variableValuesAfterLabeledStatements = null;
    _joinsAtSwitchCases = null;
    _returnValue = null;
    _receiver = null;

    final hasReceiver = hasReceiverArg(member);

    if (member is Field) {
      if (hasReceiver) {
        final int numArgs =
            fieldSummaryType == FieldSummaryType.kInitializer ? 1 : 2;
        _summary = new Summary(summaryName,
            parameterCount: numArgs, positionalParameterCount: numArgs);
        // TODO(alexmarkov): subclass cone
        _receiver = _declareParameter("this",
            _environment.coreTypes.legacyRawType(member.enclosingClass!), null,
            isReceiver: true);
      } else {
        _summary = new Summary(summaryName);
      }

      _translator = new RuntimeTypeTranslatorImpl(_environment.coreTypes,
          _summary, _receiver, null, _genericInterfacesInfo);

      if (fieldSummaryType == FieldSummaryType.kInitializer) {
        _summary.result = _visit(member.initializer!);
      } else {
        final Parameter valueParam =
            _declareParameter("value", member.type, null);
        _summary.result = _typeCheck(valueParam, member.type, member);
      }
    } else {
      final FunctionNode function = member.function!;

      final numTypeParameters = numTypeParams(member);
      final firstParamIndex = (hasReceiver ? 1 : 0) + numTypeParameters;

      _summary = new Summary(summaryName,
          parameterCount: firstParamIndex +
              function.positionalParameters.length +
              function.namedParameters.length,
          positionalParameterCount:
              firstParamIndex + function.positionalParameters.length,
          requiredParameterCount:
              firstParamIndex + function.requiredParameterCount);

      if (numTypeParameters > 0) {
        _fnTypeVariables = <TypeParameter, TypeExpr>{
          for (TypeParameter tp in function.typeParameters)
            tp: _declareParameter(tp.name!, null, null)
        };
      }

      if (hasReceiver) {
        // TODO(alexmarkov): subclass cone
        _receiver = _declareParameter("this",
            _environment.coreTypes.legacyRawType(member.enclosingClass!), null,
            isReceiver: true);
      }

      _translator = new RuntimeTypeTranslatorImpl(_environment.coreTypes,
          _summary, _receiver, _fnTypeVariables, _genericInterfacesInfo);

      // Handle forwarding stubs. We need to check types against the types of
      // the forwarding stub's target, [member.concreteForwardingStubTarget].
      FunctionNode useTypesFrom = function;
      if (member is Procedure && member.isForwardingStub) {
        final target = member.concreteForwardingStubTarget;
        if (target != null) {
          if (target is Field) {
            useTypesFrom = FunctionNode(null, positionalParameters: [
              VariableDeclaration("value",
                  type: target.type, isSynthesized: true)
            ]);
          } else {
            useTypesFrom = target.function!;
          }
        }
      }

      for (int i = 0; i < function.positionalParameters.length; ++i) {
        final decl = function.positionalParameters[i];
        _declareParameter(
            decl.name!,
            _useTypeCheckForParameter(decl)
                ? null
                : useTypesFrom.positionalParameters[i].type,
            decl.initializer);
      }
      for (int i = 0; i < function.namedParameters.length; ++i) {
        final decl = function.namedParameters[i];
        _declareParameter(
            decl.name!,
            _useTypeCheckForParameter(decl)
                ? null
                : useTypesFrom.namedParameters[i].type,
            decl.initializer);
      }

      int count = firstParamIndex;
      for (int i = 0; i < function.positionalParameters.length; ++i) {
        final decl = function.positionalParameters[i];
        final type = useTypesFrom.positionalParameters[i].type;
        TypeExpr param = _summary.statements[count++];
        if (_useTypeCheckForParameter(decl)) {
          param = _typeCheck(param, type, decl);
        }
        _declareVariable(decl, param);
      }
      for (int i = 0; i < function.namedParameters.length; ++i) {
        final decl = function.namedParameters[i];
        final type = useTypesFrom.namedParameters[i].type;
        TypeExpr param = _summary.statements[count++];
        if (_useTypeCheckForParameter(decl)) {
          param = _typeCheck(param, type, decl);
        }
        _declareVariable(decl, param);
      }
      assert(count == _summary.parameterCount);

      _returnValue = new Join("%result", function.returnType);
      _summary.add(_returnValue!);

      if (member is Constructor) {
        // Make sure instance field initializers are visited.
        for (var f in member.enclosingClass.members) {
          if ((f is Field) &&
              !f.isStatic &&
              !f.isLate &&
              (f.initializer != null)) {
            _entryPointsListener.addRawCall(
                new DirectSelector(f, callKind: CallKind.FieldInitializer));
          }
        }
        member.initializers.forEach(_visitWithoutResult);
      }

      if (function.body == null) {
        TypeExpr type = _nativeCodeOracle.handleNativeProcedure(
            member, _entryPointsListener, _typesBuilder, _translator);
        if (type is! ConcreteType && type is! Statement) {
          // Runtime type could be more precise than static type, so
          // calculate intersection.
          final typeCheck = _typeCheck(type, function.returnType, function);
          _returnValue!.values.add(typeCheck);
        } else {
          _returnValue!.values.add(type);
        }
      } else {
        _visitWithoutResult(function.body!);

        if (_fallthroughDetector.controlCanFallThrough(function)) {
          _returnValue!.values.add(_nullType);
        }
      }

      if (member.name.text == '==') {
        // In addition to what is returned from the function body,
        // operator == performs implicit comparison with null
        // and returns bool.
        _returnValue!.values.add(_boolType);
      }

      switch (function.asyncMarker) {
        case AsyncMarker.Async:
          final Class? concreteClass =
              target.concreteAsyncResultClass(_environment.coreTypes);
          _summary.result = (concreteClass != null)
              ? _entryPointsListener
                  .addAllocatedClass(concreteClass)
                  .cls
                  .concreteType
              : _typesBuilder.fromStaticType(function.returnType, false);
          break;
        case AsyncMarker.AsyncStar:
          _summary.result =
              _typesBuilder.fromStaticType(function.returnType, false);
          break;
        case AsyncMarker.SyncStar:
          final Class? concreteClass =
              target.concreteSyncStarResultClass(_environment.coreTypes);
          _summary.result = (concreteClass != null)
              ? _entryPointsListener
                  .addAllocatedClass(concreteClass)
                  .cls
                  .concreteType
              : _typesBuilder.fromStaticType(function.returnType, false);
          break;
        default:
          _summary.result = _returnValue!;
      }
    }

    member.annotations.forEach(_visit);
    member.enclosingClass?.annotations.forEach(_visit);
    member.enclosingLibrary.annotations.forEach(_visit);

    _staticTypeContext = null;

    debugPrint("------------ SUMMARY ------------");
    debugPrint(_summary);
    debugPrint("---------------------------------");

    new _SummaryNormalizer(_summary, _typesBuilder).normalize();

    debugPrint("---------- NORM SUMMARY ---------");
    debugPrint(_summary);
    debugPrint("---------------------------------");

    Statistics.summariesCreated++;

    return _summary;
  }

  bool _useTypeCheckForParameter(VariableDeclaration decl) {
    return decl.isCovariantByDeclaration || decl.isCovariantByClass;
  }

  Args<Type> rawArguments(Selector selector) {
    final member = selector.member!;
    final List<Type> args = <Type>[];
    final List<String> names = <String>[];

    final numTypeParameters = numTypeParams(member);
    for (int i = 0; i < numTypeParameters; ++i) {
      args.add(const UnknownType());
    }

    if (hasReceiverArg(member)) {
      assert(member.enclosingClass != null);
      final receiver =
          new ConeType(_typesBuilder.getTFClass(member.enclosingClass!));
      args.add(receiver);
    }

    switch (selector.callKind) {
      case CallKind.Method:
        if (member is! Field) {
          final function = member.function!;

          final int paramCount = function.positionalParameters.length +
              function.namedParameters.length;
          for (int i = 0; i < paramCount; i++) {
            args.add(new Type.nullableAny());
          }

          if (function.namedParameters.isNotEmpty) {
            for (var param in function.namedParameters) {
              names.add(param.name!);
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
      case CallKind.SetFieldInConstructor:
        args.add(new Type.nullableAny());
        break;

      case CallKind.FieldInitializer:
        break;
    }

    return new Args<Type>(args, names: names);
  }

  TypeExpr _visit(Expression node) => node.accept(this)!;

  void _visitWithoutResult(TreeNode node) {
    node.accept(this);
  }

  Args<TypeExpr> _visitArguments(TypeExpr? receiver, Arguments arguments,
      {bool passTypeArguments = false}) {
    final List<TypeExpr> args = <TypeExpr>[];
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
        args.add(map[name]!);
      }
      return new Args<TypeExpr>(args, names: names);
    } else {
      return new Args<TypeExpr>(args);
    }
  }

  Parameter _declareParameter(
      String name, DartType? type, Expression? initializer,
      {bool isReceiver = false}) {
    Type? staticType;
    if (type != null) {
      staticType = _typesBuilder.fromStaticType(type, !isReceiver);
    }
    final param = new Parameter(name, staticType);
    _summary.add(param);
    assert(param.index < _summary.parameterCount);
    if (param.index >= _summary.requiredParameterCount) {
      if (initializer != null) {
        if (initializer is ConstantExpression) {
          param.defaultValue =
              constantAllocationCollector.typeFor(initializer.constant);
        } else if (initializer is BasicLiteral ||
            initializer is SymbolLiteral ||
            initializer is TypeLiteral) {
          param.defaultValue = _visit(initializer) as Type;
        } else {
          throw 'Unexpected parameter $name default value ${initializer.runtimeType} $initializer';
        }
      } else {
        param.defaultValue = _nullType;
      }
    } else {
      assert(initializer == null);
    }
    return param;
  }

  void _declareVariable(VariableDeclaration decl, TypeExpr initialValue) {
    final int varIndex = _variablesInfo.varIndex[decl]!;
    assert(_variablesInfo.varDeclarations[varIndex] == decl);
    assert(_variableValues[varIndex] == null);
    if (_variablesInfo.isCaptured(decl)) {
      final join = _makeJoin(varIndex, initialValue);
      _variableCells[varIndex] = join;
      _variableValues[varIndex] = join;
    } else {
      _variableValues[varIndex] = initialValue;
    }
  }

  void _writeVariable(VariableDeclaration variable, TypeExpr value) {
    final int varIndex = _variablesInfo.varIndex[variable]!;
    final Join? join = _variableCells[varIndex];
    if (join != null) {
      join.values.add(value);
    } else {
      _variableValues[varIndex] = value;
    }
  }

  List<TypeExpr?> _cloneVariableValues(List<TypeExpr?> values) =>
      new List<TypeExpr?>.from(values);

  List<TypeExpr?> _makeEmptyVariableValues() {
    final values =
        new List<TypeExpr?>.filled(_variablesInfo.numVariables, null);
    for (int i = 0; i < values.length; ++i) {
      if (_variableCells[i] != null) {
        values[i] = _variableValues[i];
      } else if (_variableValues[i] != null) {
        values[i] = const EmptyType();
      }
    }
    return values;
  }

  Join _makeJoin(int varIndex, TypeExpr value) {
    final VariableDeclaration variable =
        _variablesInfo.varDeclarations[varIndex];
    final name = '${variable.name}_${_variableVersions[varIndex]++}';
    final Join join = new Join(name, variable.type);
    _summary.add(join);
    join.values.add(value);
    return join;
  }

  void _mergeVariableValues(List<TypeExpr?> dst, List<TypeExpr?> src) {
    assert(dst.length == src.length);
    for (int i = 0; i < dst.length; ++i) {
      final TypeExpr? dstValue = dst[i];
      final TypeExpr? srcValue = src[i];
      if (identical(dstValue, srcValue)) {
        continue;
      }
      if (dstValue == null || srcValue == null) {
        dst[i] = null;
      } else if (dstValue is EmptyType) {
        dst[i] = srcValue;
      } else if (dstValue is Join && dstValue.values.contains(srcValue)) {
        continue;
      } else if (srcValue is EmptyType) {
        continue;
      } else if (srcValue is Join && srcValue.values.contains(dstValue)) {
        dst[i] = srcValue;
      } else {
        final Join join = _makeJoin(i, dstValue);
        join.values.add(srcValue);
        dst[i] = join;
      }
    }
  }

  void _copyVariableValues(List<TypeExpr?> dst, List<TypeExpr?> src) {
    assert(dst.length == src.length);
    for (int i = 0; i < dst.length; ++i) {
      dst[i] = src[i];
    }
  }

  bool _isIdenticalState(List<TypeExpr?> state1, List<TypeExpr?> state2) {
    assert(state1.length == state2.length);
    for (int i = 0; i < state1.length; ++i) {
      if (!identical(state1[i], state2[i])) {
        return false;
      }
    }
    return true;
  }

  List<Join?> _insertJoinsForModifiedVariables(ast.Statement node, bool isTry) {
    final List<Join?> joins =
        new List<Join?>.filled(_variablesInfo.numVariables, null);
    for (var i in _variablesInfo.getModifiedVariables(node)) {
      if (_variableCells[i] != null) {
        assert(_variableCells[i] == _variableValues[i]);
      } else {
        final join = _makeJoin(i, _variableValues[i]!);
        joins[i] = join;
        _variableValues[i] = join;
        if (isTry) {
          // Inside try blocks all values of modified variables are merged,
          // as catch can potentially see any value (in case exception
          // is thrown after each assignment).
          _variableCells[i] = join;
        }
      }
    }
    return joins;
  }

  /// Stops accumulating values in [joins] by removing them from
  /// _variableCells.
  void _restoreVariableCellsAfterTry(List<Join?> joins) {
    for (int i = 0; i < joins.length; ++i) {
      if (joins[i] != null) {
        assert(_variableCells[i] == joins[i]);
        _variableCells[i] = null;
      }
    }
  }

  void _mergeVariableValuesToJoins(List<TypeExpr?> values, List<Join?> joins) {
    for (int i = 0; i < joins.length; ++i) {
      final join = joins[i];
      final value = values[i];
      if (join != null &&
          !identical(join, value) &&
          !identical(join.values.first, value)) {
        join.values.add(value!);
      }
    }
  }

  TypeCheck _typeCheck(TypeExpr value, DartType type, TreeNode node,
      [SubtypeTestKind kind = SubtypeTestKind.Subtype]) {
    final TypeExpr runtimeType = _translator.translate(type);
    final bool canBeNull = (kind == SubtypeTestKind.IsTest)
        ? _canBeNullAfterSuccessfulIsCheck(type)
        : true;
    final typeCheck = new TypeCheck(value, runtimeType, node,
        _typesBuilder.fromStaticType(type, canBeNull), kind);
    _summary.add(typeCheck);
    return typeCheck;
  }

  // TODO(alexmarkov): Avoid declaring variables with static types.
  void _declareVariableWithStaticType(VariableDeclaration decl) {
    final initializer = decl.initializer;
    if (initializer != null) {
      _visit(initializer);
    }
    _declareVariable(decl, _typesBuilder.fromStaticType(decl.type, true));
  }

  Call _makeCall(TreeNode node, Selector selector, Args<TypeExpr> args,
      {bool isInstanceCreation = false}) {
    Type? staticResultType = null;
    Member? target;
    if (selector is DirectSelector) {
      target = selector.member;
    } else if (selector is InterfaceSelector) {
      target = selector.member;
    }
    if (target is Procedure &&
        target.function.returnType is TypeParameterType &&
        node is Expression) {
      staticResultType = _staticType(node);
    }
    Call call = new Call(selector, args, staticResultType, isInstanceCreation);
    _summary.add(call);
    callSites[node] = call;
    return call;
  }

  TypeExpr _makeNarrow(TypeExpr arg, Type type) {
    if (arg is Narrow) {
      if (arg.type == type) {
        return arg;
      }
      if (type == const AnyType() && arg.type is! NullableType) {
        return arg;
      }
    } else if (arg is Type) {
      if ((arg is NullableType) && (arg.baseType == const AnyType())) {
        return type;
      }
      if (type == const AnyType()) {
        return (arg is NullableType) ? arg.baseType : arg;
      }
    } else if (arg is Call && arg.isInstanceCreation && type is AnyType) {
      return arg;
    }
    if (type is NullableType && type.baseType == const AnyType()) {
      return arg;
    }
    Narrow narrow = new Narrow(arg, type);
    _summary.add(narrow);
    return narrow;
  }

  bool _canBeNullAfterSuccessfulIsCheck(DartType type) {
    // 'x is type' can succeed for null if type is
    //  - a top type (dynamic, void, Object? or Object*)
    //  - nullable (including Null)
    //  - a type parameter (it can be instantiated with Null)
    //  - legacy Never
    //  - a FutureOr of the above
    final nullability = type.nullability;
    return _environment.isTop(type) ||
        nullability == Nullability.nullable ||
        type is TypeParameterType ||
        (type is NeverType && nullability == Nullability.legacy) ||
        (type is FutureOrType &&
            _canBeNullAfterSuccessfulIsCheck(type.typeArgument));
  }

  TypeExpr _makeNarrowNotNull(TreeNode node, TypeExpr arg) {
    assert(node is NullCheck || node is EqualsNull);
    if (arg is NarrowNotNull) {
      nullTests[node] = arg;
      return arg;
    } else if (arg is Narrow) {
      if (arg.type is! NullableType) {
        nullTests[node] = NarrowNotNull.alwaysNotNull;
        return arg;
      }
    } else if (arg is Type) {
      if (arg is NullableType) {
        final baseType = arg.baseType;
        if (baseType is EmptyType) {
          nullTests[node] = NarrowNotNull.alwaysNull;
        } else {
          nullTests[node] = NarrowNotNull.unknown;
        }
        return baseType;
      } else {
        nullTests[node] = NarrowNotNull.alwaysNotNull;
        return arg;
      }
    }
    final narrow = NarrowNotNull(arg);
    nullTests[node] = narrow;
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
      assert(arg is Type || arg is Parameter);
    }
  }

  DartType _staticDartType(Expression node) =>
      node.getStaticType(_staticTypeContext!);

  Type _staticType(Expression node) =>
      _typesBuilder.fromStaticType(_staticDartType(node), true);

  late final ConcreteType _boolType =
      _entryPointsListener.addAllocatedClass(_environment.coreTypes.boolClass);

  late final ConcreteType _boolTrue =
      ConcreteType(_boolType.cls, null, BoolConstant(true));

  late final ConcreteType _boolFalse =
      ConcreteType(_boolType.cls, null, BoolConstant(false));

  late final Type _doubleType =
      ConeType(_typesBuilder.getTFClass(_environment.coreTypes.doubleClass));

  late final Type _intType =
      ConeType(_typesBuilder.getTFClass(_environment.coreTypes.intClass));

  late final Type _stringType =
      ConeType(_typesBuilder.getTFClass(_environment.coreTypes.stringClass));

  late final Type _symbolType =
      ConeType(_typesBuilder.getTFClass(_environment.coreTypes.symbolClass));

  late final Type _typeType =
      ConeType(_typesBuilder.getTFClass(_environment.coreTypes.typeClass));

  late final Type _nullType = Type.nullable(const EmptyType());

  Class get _superclass => _staticTypeContext!.thisType!.classNode.superclass!;

  Type _boolLiteralType(bool value) => value ? _boolTrue : _boolFalse;

  Type _intLiteralType(int value, Constant? constant) {
    final Class? concreteClass =
        target.concreteIntLiteralClass(_environment.coreTypes, value);
    if (concreteClass != null) {
      constant ??= IntConstant(value);
      return new ConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass).cls,
          null,
          constant);
    }
    return _intType;
  }

  Type _doubleLiteralType(double value, Constant? constant) {
    final Class? concreteClass =
        target.concreteDoubleLiteralClass(_environment.coreTypes, value);
    if (concreteClass != null) {
      constant ??= DoubleConstant(value);
      return new ConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass).cls,
          null,
          constant);
    }
    return _doubleType;
  }

  Type _stringLiteralType(String value, Constant? constant) {
    final Class? concreteClass =
        target.concreteStringLiteralClass(_environment.coreTypes, value);
    if (concreteClass != null) {
      constant ??= StringConstant(value);
      return new ConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass).cls,
          null,
          constant);
    }
    return _stringType;
  }

  void _handleNestedFunctionNode(FunctionNode node) {
    final savedReturn = _returnValue;
    _returnValue = null;
    final savedVariableValues = _variableValues;
    _variableValues = _makeEmptyVariableValues();

    // Approximate parameters of nested functions with static types.
    // TODO(sjindel/tfa): Use TypeCheck for closure parameters.
    node.positionalParameters.forEach(_declareVariableWithStaticType);
    node.namedParameters.forEach(_declareVariableWithStaticType);

    _visitWithoutResult(node.body!);

    _variableValues = savedVariableValues;
    _returnValue = savedReturn;
  }

  // Tests subtypes ignoring any nullabilities.
  bool _isSubtype(DartType subtype, DartType supertype) => _environment
      .isSubtypeOf(subtype, supertype, SubtypeCheckMode.ignoringNullabilities);

  static final Name _equalsName = new Name('==');
  final _cachedHasOverriddenEquals = <Class, bool>{};

  bool _hasOverriddenEquals(DartType type) {
    if (type is InterfaceType) {
      final Class cls = type.classNode;
      final cachedResult = _cachedHasOverriddenEquals[cls];
      if (cachedResult != null) {
        return cachedResult;
      }
      for (Class c
          in _hierarchy.computeSubtypesInformation().getSubtypesOf(cls)) {
        if (!c.isAbstract) {
          final candidate = _hierarchy.getDispatchTarget(c, _equalsName)!;
          assert(!candidate.isAbstract);
          if (candidate != _environment.coreTypes.objectEquals) {
            _cachedHasOverriddenEquals[cls] = true;
            return true;
          }
        }
      }
      _cachedHasOverriddenEquals[cls] = false;
      return false;
    }
    return true;
  }

  // Visits bool expression and updates trueState and falseState with
  // variable values in case of `true` and `false` outcomes.
  // On entry _variableValues, trueState and falseState should be the same.
  // On exit _variableValues is null, so caller should explicitly pick
  // either trueState or falseState.
  void _visitCondition(
      Expression node, List<TypeExpr?> trueState, List<TypeExpr?> falseState) {
    assert(_isIdenticalState(_variableValues, trueState));
    assert(_isIdenticalState(_variableValues, falseState));
    if (node is Not) {
      _visitCondition(node.operand, falseState, trueState);
      _variableValues = const <TypeExpr?>[]; // Should not be used.
      return;
    } else if (node is LogicalExpression) {
      final isOR = (node.operatorEnum == LogicalExpressionOperator.OR);
      _visitCondition(node.left, trueState, falseState);
      if (isOR) {
        // expr1 || expr2
        _variableValues = _cloneVariableValues(falseState);
        final trueStateAfterRHS = _cloneVariableValues(_variableValues);
        _visitCondition(node.right, trueStateAfterRHS, falseState);
        _mergeVariableValues(trueState, trueStateAfterRHS);
      } else {
        // expr1 && expr2
        _variableValues = _cloneVariableValues(trueState);
        final falseStateAfterRHS = _cloneVariableValues(_variableValues);
        _visitCondition(node.right, trueState, falseStateAfterRHS);
        _mergeVariableValues(falseState, falseStateAfterRHS);
      }
      _variableValues = const <TypeExpr?>[]; // Should not be used.
      return;
    } else if (node is VariableGet ||
        (node is AsExpression && node.operand is VariableGet)) {
      // 'x' or 'x as{TypeError} core::bool', where x is a variable.
      _addUse(_visit(node));
      final variableGet =
          (node is AsExpression ? node.operand : node) as VariableGet;
      final int varIndex = _variablesInfo.varIndex[variableGet.variable]!;
      if (_variableCells[varIndex] == null) {
        trueState[varIndex] = _boolTrue;
        falseState[varIndex] = _boolFalse;
      }
      _variableValues = const <TypeExpr?>[]; // Should not be used.
      return;
    } else if (node is EqualsCall && node.left is VariableGet) {
      final lhs = node.left as VariableGet;
      final rhs = node.right;
      if ((rhs is IntLiteral &&
              _isSubtype(lhs.variable.type,
                  _environment.coreTypes.intLegacyRawType)) ||
          (rhs is StringLiteral &&
              _isSubtype(lhs.variable.type,
                  _environment.coreTypes.stringLegacyRawType)) ||
          (rhs is ConstantExpression &&
              !_hasOverriddenEquals(lhs.variable.type))) {
        // 'x == c', where x is a variable and c is a constant.
        _addUse(_visit(node));
        final int varIndex = _variablesInfo.varIndex[lhs.variable]!;
        if (_variableCells[varIndex] == null) {
          trueState[varIndex] = _visit(rhs);
        }
        _variableValues = const <TypeExpr?>[]; // Should not be used.
        return;
      }
    } else if (node is EqualsNull && node.expression is VariableGet) {
      final lhs = node.expression as VariableGet;
      // 'x == null', where x is a variable.
      final expr = _visit(lhs);
      _makeCall(node, DirectSelector(_environment.coreTypes.objectEquals),
          Args<TypeExpr>([expr, _nullType]));
      final narrowedNotNull = _makeNarrowNotNull(node, expr);
      final int varIndex = _variablesInfo.varIndex[lhs.variable]!;
      if (_variableCells[varIndex] == null) {
        trueState[varIndex] = _nullType;
        falseState[varIndex] = narrowedNotNull;
      }
      _variableValues = const <TypeExpr?>[]; // Should not be used.
      return;
    } else if (node is IsExpression && node.operand is VariableGet) {
      // Handle 'x is T', where x is a variable.
      final operand = node.operand as VariableGet;
      final TypeCheck typeCheck =
          _typeCheck(_visit(operand), node.type, node, SubtypeTestKind.IsTest);
      isTests[node] = typeCheck;
      final int varIndex = _variablesInfo.varIndex[operand.variable]!;
      if (_variableCells[varIndex] == null) {
        trueState[varIndex] = typeCheck;
      }
      _variableValues = const <TypeExpr?>[]; // Should not be used.
      return;
    }
    _addUse(_visit(node));
    _copyVariableValues(trueState, _variableValues);
    _copyVariableValues(falseState, _variableValues);
    _variableValues = const <TypeExpr?>[]; // Should not be used.
  }

  void _updateReceiverAfterCall(
      TreeNode receiverNode, TypeExpr receiverValue, Name selector,
      {bool isSetter = false}) {
    if (receiverNode is VariableGet) {
      final nullSelectors = isSetter ? _nullSetters : _nullMethodsAndGetters;
      if (!nullSelectors.contains(selector)) {
        final int varIndex = _variablesInfo.varIndex[receiverNode.variable]!;
        if (_variableCells[varIndex] == null) {
          _variableValues[varIndex] =
              _makeNarrow(receiverValue, const AnyType());
        }
      }
    }
  }

  late final Procedure unsafeCast = _environment.coreTypes.index
      .getTopLevelProcedure('dart:_internal', 'unsafeCast');

  @override
  defaultTreeNode(TreeNode node) =>
      throw 'Unexpected node ${node.runtimeType}: $node at ${node.location}';

  @override
  TypeExpr visitAsExpression(AsExpression node) {
    final operandNode = node.operand;
    final TypeExpr operand = _visit(operandNode);
    final TypeCheck result = _typeCheck(operand, node.type, node);
    explicitCasts[node] = result;
    if (operandNode is VariableGet) {
      final int varIndex = _variablesInfo.varIndex[operandNode.variable]!;
      if (_variableCells[varIndex] == null) {
        _variableValues[varIndex] = result;
      }
    }
    return result;
  }

  @override
  TypeExpr visitNullCheck(NullCheck node) {
    final operandNode = node.operand;
    final TypeExpr result = _makeNarrowNotNull(node, _visit(operandNode));
    if (operandNode is VariableGet) {
      final int varIndex = _variablesInfo.varIndex[operandNode.variable]!;
      if (_variableCells[varIndex] == null) {
        _variableValues[varIndex] = result;
      }
    }
    return result;
  }

  @override
  TypeExpr visitBoolLiteral(BoolLiteral node) {
    return _boolLiteralType(node.value);
  }

  @override
  TypeExpr visitIntLiteral(IntLiteral node) {
    return _intLiteralType(node.value, null);
  }

  @override
  TypeExpr visitDoubleLiteral(DoubleLiteral node) {
    return _doubleLiteralType(node.value, null);
  }

  @override
  TypeExpr visitConditionalExpression(ConditionalExpression node) {
    final trueState = _cloneVariableValues(_variableValues);
    final falseState = _cloneVariableValues(_variableValues);
    _visitCondition(node.condition, trueState, falseState);

    final Join v = new Join(null, _staticDartType(node));
    _summary.add(v);

    _variableValues = trueState;
    v.values.add(_visit(node.then));
    final stateAfter = _variableValues;

    _variableValues = falseState;
    v.values.add(_visit(node.otherwise));

    _mergeVariableValues(stateAfter, _variableValues);
    _variableValues = stateAfter;
    return _makeNarrow(v, _staticType(node));
  }

  @override
  TypeExpr visitConstructorInvocation(ConstructorInvocation node) {
    ConcreteType klass =
        _typesBuilder.getTFClass(node.constructedType.classNode).concreteType;
    TypeExpr receiver =
        _translator.instantiateConcreteType(klass, node.arguments.types);
    final args = _visitArguments(receiver, node.arguments);
    return _makeCall(node, new DirectSelector(node.target), args,
        isInstanceCreation: true);
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
    return const EmptyType();
  }

  @override
  TypeExpr visitIsExpression(IsExpression node) {
    final operandNode = node.operand;
    final TypeExpr operand = _visit(operandNode);
    final TypeCheck typeCheck =
        _typeCheck(operand, node.type, node, SubtypeTestKind.IsTest);
    isTests[node] = typeCheck;
    return _boolType;
  }

  @override
  TypeExpr visitLet(Let node) {
    _declareVariable(node.variable, _visit(node.variable.initializer!));
    return _visit(node.body);
  }

  @override
  TypeExpr visitBlockExpression(BlockExpression node) {
    _visitWithoutResult(node.body);
    return _visit(node.value);
  }

  @override
  TypeExpr visitListLiteral(ListLiteral node) {
    node.expressions.forEach(_visit);
    Class? concreteClass =
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
    final trueState = _cloneVariableValues(_variableValues);
    final falseState = _cloneVariableValues(_variableValues);
    _visitCondition(node, trueState, falseState);
    _variableValues = trueState;
    _mergeVariableValues(_variableValues, falseState);
    return _boolType;
  }

  @override
  TypeExpr visitMapLiteral(MapLiteral node) {
    for (var entry in node.entries) {
      _visit(entry.key);
      _visit(entry.value);
    }
    Class? concreteClass =
        target.concreteMapLiteralClass(_environment.coreTypes);
    if (concreteClass != null) {
      return _translator.instantiateConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass),
          [node.keyType, node.valueType]);
    }
    return _staticType(node);
  }

  @override
  TypeExpr visitSetLiteral(SetLiteral node) {
    for (var expression in node.expressions) {
      _visit(expression);
    }
    Class? concreteClass =
        target.concreteSetLiteralClass(_environment.coreTypes);
    if (concreteClass != null) {
      return _translator.instantiateConcreteType(
          _entryPointsListener.addAllocatedClass(concreteClass),
          [node.typeArgument]);
    }
    return _staticType(node);
  }

  @override
  TypeExpr visitRecordLiteral(RecordLiteral node) {
    final recordShape = RecordShape(node.recordType);
    final Type receiver = _typesBuilder.getRecordType(recordShape, true);
    for (int i = 0; i < node.positional.length; ++i) {
      final Field f =
          _entryPointsListener.getRecordPositionalField(recordShape, i);
      final TypeExpr value = _visit(node.positional[i]);
      final args = Args<TypeExpr>([receiver, value]);
      _makeCall(node,
          DirectSelector(f, callKind: CallKind.SetFieldInConstructor), args);
    }
    for (var expr in node.named) {
      final Field f =
          _entryPointsListener.getRecordNamedField(recordShape, expr.name);
      final TypeExpr value = _visit(expr.value);
      final args = Args<TypeExpr>([receiver, value]);
      _makeCall(node,
          DirectSelector(f, callKind: CallKind.SetFieldInConstructor), args);
    }
    callSites.remove(node);
    return receiver;
  }

  @override
  TypeExpr visitRecordIndexGet(RecordIndexGet node) {
    final receiver = _visit(node.receiver);
    final Field field = _entryPointsListener.getRecordPositionalField(
        RecordShape(node.receiverType), node.index);
    final args = Args<TypeExpr>([receiver]);
    return _makeCall(
        node, DirectSelector(field, callKind: CallKind.PropertyGet), args);
  }

  @override
  TypeExpr visitRecordNameGet(RecordNameGet node) {
    final receiver = _visit(node.receiver);
    final Field field = _entryPointsListener.getRecordNamedField(
        RecordShape(node.receiverType), node.name);
    final args = Args<TypeExpr>([receiver]);
    return _makeCall(
        node, DirectSelector(field, callKind: CallKind.PropertyGet), args);
  }

  @override
  TypeExpr visitInstanceInvocation(InstanceInvocation node) {
    final receiverNode = node.receiver;
    final receiver = _visit(receiverNode);
    final args = _visitArguments(receiver, node.arguments);
    final target = node.interfaceTarget;
    if (receiverNode is ConstantExpression && node.name.text == '[]') {
      Constant constant = receiverNode.constant;
      if (constant is ListConstant) {
        return _handleIndexingIntoListConstant(constant);
      }
    }
    assert(!target.isGetter);
    // TODO(alexmarkov): overloaded arithmetic operators
    final result = _makeCall(
        node,
        (node.receiver is ThisExpression)
            ? new VirtualSelector(target)
            : new InterfaceSelector(target),
        args);
    _updateReceiverAfterCall(receiverNode, receiver, node.name);
    return result;
  }

  TypeExpr _handleIndexingIntoListConstant(ListConstant list) {
    final elementTypes = new Set<Type>();
    for (var element in list.entries) {
      elementTypes.add(constantAllocationCollector.typeFor(element));
    }
    switch (elementTypes.length) {
      case 0:
        return const EmptyType();
      case 1:
        return elementTypes.single;
      default:
        final join = new Join(null, list.typeArgument);
        join.values.addAll(elementTypes);
        _summary.add(join);
        return join;
    }
  }

  @override
  TypeExpr visitDynamicInvocation(DynamicInvocation node) {
    final receiverNode = node.receiver;
    final receiver = _visit(receiverNode);
    final args = _visitArguments(receiver, node.arguments);
    final result =
        _makeCall(node, new DynamicSelector(CallKind.Method, node.name), args);
    _updateReceiverAfterCall(receiverNode, receiver, node.name);
    return result;
  }

  @override
  TypeExpr visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    _visitArguments(null, node.arguments);
    return _staticType(node);
  }

  @override
  TypeExpr visitFunctionInvocation(FunctionInvocation node) {
    final receiverNode = node.receiver;
    final receiver = _visit(receiverNode);
    _visitArguments(receiver, node.arguments);
    final result = _staticType(node);
    _updateReceiverAfterCall(receiverNode, receiver, Name('call'));
    return result;
  }

  @override
  TypeExpr visitEqualsCall(EqualsCall node) {
    _addUse(_visit(node.left));
    _addUse(_visit(node.right));
    final target = node.interfaceTarget;
    // 'operator==' is a very popular method which can be called
    // with a huge number of combinations of argument types.
    // These invocations can be sensitive to changes in the set of allocated
    // classes, causing a large number of invalidated invocations.
    // In order to speed up the analysis, arguments of 'operator=='
    // are approximated eagerly to static types during summary construction.
    return _makeCall(
        node,
        (node.left is ThisExpression)
            ? new VirtualSelector(target)
            : new InterfaceSelector(target),
        Args<TypeExpr>([_staticType(node.left), _staticType(node.right)]));
  }

  @override
  TypeExpr visitEqualsNull(EqualsNull node) {
    final arg = _visit(node.expression);
    _makeNarrowNotNull(node, arg);
    // 'operator==' is a very popular method which can be called
    // with a huge number of combinations of argument types.
    // These invocations can be sensitive to changes in the set of allocated
    // classes, causing a large number of invalidated invocations.
    // In order to speed up the analysis, arguments of 'operator=='
    // are approximated eagerly to static types during summary construction.
    _makeCall(node, DirectSelector(_environment.coreTypes.objectEquals),
        Args<TypeExpr>([_staticType(node.expression), _nullType]));
    return _boolType;
  }

  TypeExpr _handlePropertyGet(
      TreeNode node, Expression receiverNode, Member? target, Name selector) {
    var receiver = _visit(receiverNode);
    var args = new Args<TypeExpr>([receiver]);
    TypeExpr result;
    if (target == null) {
      result = _makeCall(
          node, new DynamicSelector(CallKind.PropertyGet, selector), args);
    } else {
      result = _makeCall(
          node,
          (receiverNode is ThisExpression)
              ? new VirtualSelector(target, callKind: CallKind.PropertyGet)
              : new InterfaceSelector(target, callKind: CallKind.PropertyGet),
          args);
    }
    _updateReceiverAfterCall(receiverNode, receiver, selector);
    return result;
  }

  @override
  TypeExpr visitInstanceGet(InstanceGet node) {
    return _handlePropertyGet(
        node, node.receiver, node.interfaceTarget, node.name);
  }

  @override
  TypeExpr visitInstanceTearOff(InstanceTearOff node) {
    return _handlePropertyGet(
        node, node.receiver, node.interfaceTarget, node.name);
  }

  @override
  TypeExpr visitFunctionTearOff(FunctionTearOff node) {
    return _handlePropertyGet(node, node.receiver, null, Name('call'));
  }

  @override
  TypeExpr visitDynamicGet(DynamicGet node) {
    return _handlePropertyGet(node, node.receiver, null, node.name);
  }

  @override
  TypeExpr visitInstanceSet(InstanceSet node) {
    var receiver = _visit(node.receiver);
    var value = _visit(node.value);
    var args = new Args<TypeExpr>([receiver, value]);
    final target = node.interfaceTarget;
    assert((target is Field) || ((target is Procedure) && target.isSetter));
    _makeCall(
        node,
        (node.receiver is ThisExpression)
            ? new VirtualSelector(target, callKind: CallKind.PropertySet)
            : new InterfaceSelector(target, callKind: CallKind.PropertySet),
        args);
    _updateReceiverAfterCall(node.receiver, receiver, node.name,
        isSetter: true);
    return value;
  }

  @override
  TypeExpr visitDynamicSet(DynamicSet node) {
    var receiver = _visit(node.receiver);
    var value = _visit(node.value);
    var args = new Args<TypeExpr>([receiver, value]);
    _makeCall(node, new DynamicSelector(CallKind.PropertySet, node.name), args);
    _updateReceiverAfterCall(node.receiver, receiver, node.name,
        isSetter: true);
    return value;
  }

  @override
  TypeExpr visitSuperMethodInvocation(SuperMethodInvocation node) {
    assert(kPartialMixinResolution);
    assert(_receiver != null, "Should have receiver. Node: $node");
    final args = _visitArguments(_receiver, node.arguments);
    // Re-resolve target due to partial mixin resolution.
    final target = _hierarchy.getDispatchTarget(_superclass, node.name);
    if (target == null) {
      return const EmptyType();
    } else {
      assert(target is Procedure && !target.isGetter);
      _entryPointsListener.recordMemberCalledViaThis(target);
      return _makeCall(node, new DirectSelector(target), args);
    }
  }

  @override
  TypeExpr visitSuperPropertyGet(SuperPropertyGet node) {
    assert(kPartialMixinResolution);
    final args = new Args<TypeExpr>([_receiver!]);
    // Re-resolve target due to partial mixin resolution.
    final target = _hierarchy.getDispatchTarget(_superclass, node.name);
    if (target == null) {
      return const EmptyType();
    } else {
      return _makeCall(node,
          new DirectSelector(target, callKind: CallKind.PropertyGet), args);
    }
  }

  @override
  TypeExpr visitSuperPropertySet(SuperPropertySet node) {
    assert(kPartialMixinResolution);
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([_receiver!, value]);
    // Re-resolve target due to partial mixin resolution.
    final target =
        _hierarchy.getDispatchTarget(_superclass, node.name, setter: true);
    if (target != null) {
      assert((target is Field) || ((target is Procedure) && target.isSetter));
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
    _variableValues = _makeEmptyVariableValues();
    return const EmptyType();
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
    if (StaticWeakReferences.isWeakReference(node)) {
      // Do not visit this StaticInvocation and its arguments as
      // they are weakly reachable.
      return _staticType(node);
    }
    final args = _visitArguments(null, node.arguments,
        passTypeArguments: node.target.isFactory);
    final target = node.target;
    assert((target is! Field) && !target.isGetter && !target.isSetter);
    if (target == _environment.coreTypes.identicalProcedure) {
      assert(args.values.length == 2 && args.names.isEmpty);
      // 'identical' is a very popular method which can be called
      // with a huge number of combinations of argument types.
      // Those invocations can be sensitive to changes in the set of allocated
      // classes, causing a large number of invalidated invocations.
      // In order to speed up the analysis, invocations of 'identical'
      // are approximated eagerly during summary construction.
      _makeCall(node, new DirectSelector(target),
          Args<TypeExpr>([Type.nullableAny(), Type.nullableAny()]));
      return _boolType;
    }
    TypeExpr result = _makeCall(node, new DirectSelector(target), args);
    if (target == unsafeCast) {
      // Async transformation inserts unsafeCasts to make sure
      // kernel is correctly typed. Instead of using the result of unsafeCast
      // (which is an opaque native function), we can use its argument narrowed
      // by the casted type.
      final arg = args.values.single;
      result = _makeNarrow(
          arg, _typesBuilder.fromStaticType(node.arguments.types.single, true));
    }
    return result;
  }

  @override
  TypeExpr visitStaticSet(StaticSet node) {
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([value]);
    final target = node.target;
    assert((target is Field) || (target is Procedure) && target.isSetter);
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
    return _stringLiteralType(node.value, null);
  }

  @override
  TypeExpr visitSymbolLiteral(SymbolLiteral node) {
    return _staticType(node);
  }

  @override
  TypeExpr visitThisExpression(ThisExpression node) {
    return _receiver!;
  }

  @override
  TypeExpr visitThrow(Throw node) {
    _visit(node.expression);
    _variableValues = _makeEmptyVariableValues();
    return const EmptyType();
  }

  @override
  TypeExpr visitTypeLiteral(TypeLiteral node) {
    return _typeType;
  }

  @override
  TypeExpr visitVariableGet(VariableGet node) {
    final v = _variableValues[_variablesInfo.varIndex[node.variable]!];
    if (v == null) {
      throw 'Unable to find variable ${node.variable} at ${node.location}';
    }
    return v;
  }

  @override
  TypeExpr visitVariableSet(VariableSet node) {
    final TypeExpr value = _visit(node.value);
    _writeVariable(node.variable, value);
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
  TypeExpr? visitAssertStatement(AssertStatement node) {
    if (!kRemoveAsserts) {
      _addUse(_visit(node.condition));
      final message = node.message;
      if (message != null) {
        _visit(message);
      }
    }
    return null;
  }

  @override
  TypeExpr? visitBlock(Block node) {
    node.statements.forEach(_visitWithoutResult);
    return null;
  }

  @override
  TypeExpr? visitAssertBlock(AssertBlock node) {
    if (!kRemoveAsserts) {
      node.statements.forEach(_visitWithoutResult);
    }
    return null;
  }

  @override
  TypeExpr? visitBreakStatement(BreakStatement node) {
    var afterLabels = _variableValuesAfterLabeledStatements;
    if (afterLabels == null) {
      _variableValuesAfterLabeledStatements =
          afterLabels = <LabeledStatement, List<TypeExpr?>>{};
    }
    final state = afterLabels[node.target];
    if (state != null) {
      _mergeVariableValues(state, _variableValues);
    } else {
      afterLabels[node.target] = _variableValues;
    }
    _variableValues = _makeEmptyVariableValues();
    return null;
  }

  @override
  TypeExpr? visitContinueSwitchStatement(ContinueSwitchStatement node) {
    _mergeVariableValuesToJoins(
        _variableValues, _joinsAtSwitchCases![node.target]!);
    _variableValues = _makeEmptyVariableValues();
    return null;
  }

  @override
  TypeExpr? visitDoStatement(DoStatement node) {
    final List<Join?> joins = _insertJoinsForModifiedVariables(node, false);
    _visitWithoutResult(node.body);
    final trueState = _cloneVariableValues(_variableValues);
    final falseState = _cloneVariableValues(_variableValues);
    _visitCondition(node.condition, trueState, falseState);
    _mergeVariableValuesToJoins(trueState, joins);
    // Kernel represents 'break;' as a BreakStatement referring to a
    // LabeledStatement. We are therefore guaranteed to always have the
    // condition be false after the 'do/while'.
    // Any break would jump to the LabeledStatement outside the do/while.
    _variableValues = falseState;
    return null;
  }

  @override
  TypeExpr? visitEmptyStatement(EmptyStatement node) => null;

  @override
  TypeExpr? visitExpressionStatement(ExpressionStatement node) {
    _visit(node.expression);
    return null;
  }

  @override
  TypeExpr? visitForInStatement(ForInStatement node) {
    _visit(node.iterable);
    // TODO(alexmarkov): try to infer more precise type from 'iterable'
    _declareVariableWithStaticType(node.variable);

    final List<Join?> joins = _insertJoinsForModifiedVariables(node, false);
    final stateAfterLoop = _cloneVariableValues(_variableValues);
    _visitWithoutResult(node.body);
    _mergeVariableValuesToJoins(_variableValues, joins);
    _variableValues = stateAfterLoop;
    return null;
  }

  @override
  TypeExpr? visitForStatement(ForStatement node) {
    node.variables.forEach(visitVariableDeclaration);
    final List<Join?> joins = _insertJoinsForModifiedVariables(node, false);
    final trueState = _cloneVariableValues(_variableValues);
    final falseState = _cloneVariableValues(_variableValues);
    if (node.condition != null) {
      _visitCondition(node.condition!, trueState, falseState);
    }
    _variableValues = trueState;
    _visitWithoutResult(node.body);
    node.updates.forEach(_visit);
    _mergeVariableValuesToJoins(_variableValues, joins);
    // Kernel represents 'break;' as a BreakStatement referring to a
    // LabeledStatement. We are therefore guaranteed to always have the
    // condition be false after the 'for'.
    // Any break would jump to the LabeledStatement outside the 'for'.
    _variableValues = falseState;
    return null;
  }

  @override
  TypeExpr? visitFunctionDeclaration(FunctionDeclaration node) {
    // TODO(alexmarkov): support function types.
    node.variable.annotations.forEach(_visit);
    _declareVariableWithStaticType(node.variable);
    _handleNestedFunctionNode(node.function);
    return null;
  }

  @override
  TypeExpr? visitIfStatement(IfStatement node) {
    final trueState = _cloneVariableValues(_variableValues);
    final falseState = _cloneVariableValues(_variableValues);
    _visitCondition(node.condition, trueState, falseState);

    _variableValues = trueState;
    _visitWithoutResult(node.then);
    final stateAfter = _variableValues;

    _variableValues = falseState;
    if (node.otherwise != null) {
      _visitWithoutResult(node.otherwise!);
    }

    _mergeVariableValues(stateAfter, _variableValues);
    _variableValues = stateAfter;
    return null;
  }

  @override
  TypeExpr? visitLabeledStatement(LabeledStatement node) {
    _visitWithoutResult(node.body);
    final state = _variableValuesAfterLabeledStatements?.remove(node);
    if (state != null) {
      _mergeVariableValues(_variableValues, state);
    }
    return null;
  }

  @override
  TypeExpr? visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    TypeExpr ret = (expression != null) ? _visit(expression) : _nullType;
    _returnValue?.values.add(ret);
    _variableValues = _makeEmptyVariableValues();
    return null;
  }

  @override
  TypeExpr? visitSwitchStatement(SwitchStatement node) {
    _visit(node.expression);
    // Insert joins at each case in case there are 'continue' statements.
    final stateOnEntry = _variableValues;
    final variableValuesAtCaseEntry = <SwitchCase, List<TypeExpr?>>{};
    Map<SwitchCase, List<Join?>>? joinsAtSwitchCases = _joinsAtSwitchCases;
    if (joinsAtSwitchCases == null) {
      _joinsAtSwitchCases = joinsAtSwitchCases = <SwitchCase, List<Join?>>{};
    }
    for (var switchCase in node.cases) {
      _variableValues = _cloneVariableValues(stateOnEntry);
      joinsAtSwitchCases[switchCase] =
          _insertJoinsForModifiedVariables(node, false);
      variableValuesAtCaseEntry[switchCase] = _variableValues;
    }
    bool hasDefault = false;
    for (var switchCase in node.cases) {
      _variableValues = variableValuesAtCaseEntry[switchCase]!;
      switchCase.expressions.forEach(_visit);
      _visitWithoutResult(switchCase.body);
      hasDefault = hasDefault || switchCase.isDefault;
    }
    if (!hasDefault) {
      _mergeVariableValues(_variableValues, stateOnEntry);
    }
    return null;
  }

  @override
  TypeExpr? visitTryCatch(TryCatch node) {
    final joins = _insertJoinsForModifiedVariables(node, true);
    final stateAfterTry = _cloneVariableValues(_variableValues);
    _visitWithoutResult(node.body);
    _restoreVariableCellsAfterTry(joins);
    List<TypeExpr?>? stateAfterCatch;
    for (var catchClause in node.catches) {
      _variableValues = _cloneVariableValues(stateAfterTry);
      if (catchClause.exception != null) {
        _declareVariableWithStaticType(catchClause.exception!);
      }
      if (catchClause.stackTrace != null) {
        _declareVariableWithStaticType(catchClause.stackTrace!);
      }
      _visitWithoutResult(catchClause.body);
      if (stateAfterCatch == null) {
        stateAfterCatch = _variableValues;
      } else {
        _mergeVariableValues(stateAfterCatch, _variableValues);
      }
    }
    _variableValues = stateAfterTry;
    _mergeVariableValues(_variableValues, stateAfterCatch!);
    return null;
  }

  @override
  TypeExpr? visitTryFinally(TryFinally node) {
    final joins = _insertJoinsForModifiedVariables(node, true);
    final stateAfterTry = _cloneVariableValues(_variableValues);
    _visitWithoutResult(node.body);
    _restoreVariableCellsAfterTry(joins);
    _variableValues = stateAfterTry;
    _visitWithoutResult(node.finalizer);
    return null;
  }

  @override
  TypeExpr? visitVariableDeclaration(VariableDeclaration node) {
    node.annotations.forEach(_visit);
    final initializer = node.initializer;
    final TypeExpr initialValue = initializer == null
        ? ((node.type.nullability == Nullability.nonNullable || node.isLate)
            ? const EmptyType()
            : _nullType)
        : _visit(initializer);
    _declareVariable(node, initialValue);
    return null;
  }

  @override
  TypeExpr? visitWhileStatement(WhileStatement node) {
    final List<Join?> joins = _insertJoinsForModifiedVariables(node, false);
    final trueState = _cloneVariableValues(_variableValues);
    final falseState = _cloneVariableValues(_variableValues);
    _visitCondition(node.condition, trueState, falseState);
    _variableValues = trueState;
    _visitWithoutResult(node.body);
    _mergeVariableValuesToJoins(_variableValues, joins);
    // Kernel represents 'break;' as a BreakStatement referring to a
    // LabeledStatement. We are therefore guaranteed to always have the
    // condition be false after the 'while'.
    // Any break would jump to the LabeledStatement outside the while.
    _variableValues = falseState;
    return null;
  }

  @override
  TypeExpr? visitYieldStatement(YieldStatement node) {
    _visit(node.expression);
    return null;
  }

  @override
  TypeExpr? visitFieldInitializer(FieldInitializer node) {
    final value = _visit(node.value);
    final args = new Args<TypeExpr>([_receiver!, value]);
    _makeCall(
        node,
        new DirectSelector(node.field,
            callKind: CallKind.SetFieldInConstructor),
        args);
    return null;
  }

  @override
  TypeExpr? visitRedirectingInitializer(RedirectingInitializer node) {
    final args = _visitArguments(_receiver, node.arguments);
    _makeCall(node, new DirectSelector(node.target), args);
    return null;
  }

  @override
  TypeExpr? visitSuperInitializer(SuperInitializer node) {
    final args = _visitArguments(_receiver, node.arguments);

    Constructor? target = null;
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
    _makeCall(node, new DirectSelector(target!), args);
    return null;
  }

  @override
  TypeExpr? visitLocalInitializer(LocalInitializer node) {
    visitVariableDeclaration(node.variable);
    return null;
  }

  @override
  TypeExpr? visitAssertInitializer(AssertInitializer node) {
    if (!kRemoveAsserts) {
      _visitWithoutResult(node.statement);
    }
    return null;
  }

  @override
  TypeExpr? visitInvalidInitializer(InvalidInitializer node) {
    return null;
  }

  @override
  TypeExpr visitConstantExpression(ConstantExpression node) {
    return constantAllocationCollector.typeFor(node.constant);
  }

  @override
  TypeExpr visitAwaitExpression(AwaitExpression node) {
    _visit(node.operand);
    return _staticType(node);
  }
}

class RuntimeTypeTranslatorImpl extends DartTypeVisitor<TypeExpr>
    implements RuntimeTypeTranslator {
  final CoreTypes coreTypes;
  final Summary? summary;
  final Map<TypeParameter, TypeExpr>? functionTypeVariables;
  final Map<DartType, TypeExpr> typesCache = <DartType, TypeExpr>{};
  final TypeExpr? receiver;
  final GenericInterfacesInfo genericInterfacesInfo;

  RuntimeTypeTranslatorImpl(this.coreTypes, this.summary, this.receiver,
      this.functionTypeVariables, this.genericInterfacesInfo) {}

  // Create a type translator which can be used only for types with no free type
  // variables.
  RuntimeTypeTranslatorImpl.forClosedTypes(
      this.coreTypes, this.genericInterfacesInfo)
      : summary = null,
        functionTypeVariables = null,
        receiver = null {}

  TypeExpr instantiateConcreteType(ConcreteType type, List<DartType> typeArgs) {
    if (typeArgs.isEmpty) return type;

    // This function is very similar to 'visitInterfaceType', but with
    // many small differences.
    final klass = type.cls.classNode;
    final substitution = Substitution.fromPairs(klass.typeParameters, typeArgs);
    final flattenedTypeArgs =
        genericInterfacesInfo.flattenedTypeArgumentsFor(klass);
    final flattenedTypeExprs = <TypeExpr>[];

    bool createConcreteType = true;
    bool allUnknown = true;
    for (int i = 0; i < flattenedTypeArgs.length; ++i) {
      final typeExpr =
          translate(substitution.substituteType(flattenedTypeArgs[i]));
      if (typeExpr is! UnknownType) allUnknown = false;
      if (typeExpr is Statement) createConcreteType = false;
      flattenedTypeExprs.add(typeExpr);
    }

    if (allUnknown) return type;

    if (createConcreteType) {
      return new ConcreteType(
          type.cls, new List<Type>.from(flattenedTypeExprs));
    } else {
      final instantiate = new CreateConcreteType(type.cls, flattenedTypeExprs);
      summary!.add(instantiate);
      return instantiate;
    }
  }

  // Creates a TypeExpr representing the set of types which can flow through a
  // given DartType.
  //
  // Will return UnknownType, RuntimeType or Statement.
  TypeExpr translate(DartType type) {
    final cached = typesCache[type];
    if (cached != null) return cached;

    // During type translation, loops can arise via super-bounded types:
    //
    //   class A<T> extends Comparable<A<T>> {}
    //
    // Creating the factored type arguments of A will lead to an infinite loop.
    // We break such loops by inserting an 'UnknownType' in place of the currently
    // processed type, ensuring we try to build 'A<T>' in the process of
    // building 'A<T>'.
    typesCache[type] = const UnknownType();
    final result = type.accept(this);
    assert(
        result is UnknownType || result is RuntimeType || result is Statement);
    typesCache[type] = result;
    return result;
  }

  @override
  TypeExpr defaultDartType(DartType node) => const UnknownType();

  @override
  TypeExpr visitDynamicType(DynamicType type) => new RuntimeType(type, null);
  @override
  TypeExpr visitVoidType(VoidType type) => new RuntimeType(type, null);
  @override
  TypeExpr visitNeverType(NeverType type) => new RuntimeType(type, null);

  @override
  visitTypedefType(TypedefType node) => translate(node.unalias);

  @override
  visitInterfaceType(InterfaceType type) {
    if (type.typeArguments.isEmpty) return new RuntimeType(type, null);

    final substitution = Substitution.fromPairs(
        type.classNode.typeParameters, type.typeArguments);
    final flattenedTypeArgs =
        genericInterfacesInfo.flattenedTypeArgumentsFor(type.classNode);
    final flattenedTypeExprs = <TypeExpr>[];

    bool createRuntimeType = true;
    for (var i = 0; i < flattenedTypeArgs.length; ++i) {
      final typeExpr =
          translate(substitution.substituteType(flattenedTypeArgs[i]));
      if (typeExpr == const UnknownType()) return const UnknownType();
      if (typeExpr is! RuntimeType) createRuntimeType = false;
      flattenedTypeExprs.add(typeExpr);
    }

    if (createRuntimeType) {
      return new RuntimeType(
          new InterfaceType(type.classNode, type.nullability),
          new List<RuntimeType>.from(flattenedTypeExprs));
    } else {
      final instantiate = new CreateRuntimeType(
          type.classNode, type.nullability, flattenedTypeExprs);
      summary!.add(instantiate);
      return instantiate;
    }
  }

  @override
  visitFutureOrType(FutureOrType type) {
    final typeArg = translate(type.typeArgument);
    if (typeArg == const UnknownType()) return const UnknownType();
    if (typeArg is RuntimeType) {
      return new RuntimeType(
          new FutureOrType(const DynamicType(), type.nullability),
          <RuntimeType>[typeArg]);
    } else {
      final instantiate = new CreateRuntimeType(
          coreTypes.deprecatedFutureOrClass,
          type.nullability,
          <TypeExpr>[typeArg]);
      summary!.add(instantiate);
      return instantiate;
    }
  }

  @override
  visitTypeParameterType(TypeParameterType type) {
    final functionTypeVariables = this.functionTypeVariables;
    if (functionTypeVariables != null) {
      final result = functionTypeVariables[type.parameter];
      if (result != null) {
        final nullability = type.nullability;
        if (nullability != Nullability.nonNullable &&
            nullability != Nullability.undetermined) {
          final applyNullability = ApplyNullability(result, nullability);
          summary!.add(applyNullability);
          return applyNullability;
        }
        return result;
      }
    }
    if (type.parameter.parent is! Class) return const UnknownType();
    final interfaceClass = type.parameter.parent as Class;
    // Undetermined nullability is equivalent to nonNullable when
    // instantiating type parameter, so convert it right away.
    Nullability nullability = type.nullability;
    if (nullability == Nullability.undetermined) {
      nullability = Nullability.nonNullable;
    }
    final extract = new Extract(receiver!, interfaceClass,
        interfaceClass.typeParameters.indexOf(type.parameter), nullability);
    summary!.add(extract);
    return extract;
  }
}

class ConstantAllocationCollector extends ConstantVisitor<Type> {
  final SummaryCollector summaryCollector;

  final Map<Constant, Type> constants = <Constant, Type>{};

  ConstantAllocationCollector(this.summaryCollector);

  // Ensures the transitive graph of [constant] got scanned for potential
  // allocations and field types.  Returns the [Type] of this constant.
  Type typeFor(Constant constant) {
    return constants.putIfAbsent(constant, () => constant.accept(this));
  }

  Type _getStaticType(Constant constant) =>
      summaryCollector._typesBuilder.fromStaticType(
          constant.getType(summaryCollector._staticTypeContext!), false);

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
    return summaryCollector._boolLiteralType(constant.value);
  }

  @override
  Type visitIntConstant(IntConstant constant) {
    return summaryCollector._intLiteralType(constant.value, constant);
  }

  @override
  Type visitDoubleConstant(DoubleConstant constant) {
    return summaryCollector._doubleLiteralType(constant.value, constant);
  }

  @override
  Type visitStringConstant(StringConstant constant) {
    return summaryCollector._stringLiteralType(constant.value, constant);
  }

  @override
  visitSymbolConstant(SymbolConstant constant) {
    return summaryCollector._symbolType;
  }

  @override
  Type visitListConstant(ListConstant constant) {
    for (final Constant entry in constant.entries) {
      typeFor(entry);
    }
    final Class? concreteClass = summaryCollector.target
        .concreteConstListLiteralClass(summaryCollector._environment.coreTypes);
    if (concreteClass != null) {
      return new ConcreteType(
          summaryCollector._entryPointsListener
              .addAllocatedClass(concreteClass)
              .cls,
          null,
          constant);
    }
    return _getStaticType(constant);
  }

  @override
  Type visitMapConstant(MapConstant constant) {
    for (final entry in constant.entries) {
      typeFor(entry.key);
      typeFor(entry.value);
    }
    final Class? concreteClass = summaryCollector.target
        .concreteConstMapLiteralClass(summaryCollector._environment.coreTypes);
    if (concreteClass != null) {
      return new ConcreteType(
          summaryCollector._entryPointsListener
              .addAllocatedClass(concreteClass)
              .cls,
          null,
          constant);
    }
    return _getStaticType(constant);
  }

  @override
  Type visitSetConstant(SetConstant constant) {
    for (final entry in constant.entries) {
      typeFor(entry);
    }
    final Class? concreteClass = summaryCollector.target
        .concreteConstSetLiteralClass(summaryCollector._environment.coreTypes);
    if (concreteClass != null) {
      return new ConcreteType(
          summaryCollector._entryPointsListener
              .addAllocatedClass(concreteClass)
              .cls,
          null,
          constant);
    }
    return _getStaticType(constant);
  }

  @override
  Type visitRecordConstant(RecordConstant constant) {
    final epl = summaryCollector._entryPointsListener;
    final recordShape = RecordShape(constant.recordType);
    final Type receiver =
        summaryCollector._typesBuilder.getRecordType(recordShape, true);
    for (int i = 0; i < constant.positional.length; ++i) {
      final Field f = epl.getRecordPositionalField(recordShape, i);
      final Type value = typeFor(constant.positional[i]);
      epl.addFieldUsedInConstant(f, receiver, value);
    }
    constant.named.forEach((String fieldName, Constant fieldValue) {
      final Field f = epl.getRecordNamedField(recordShape, fieldName);
      final Type value = typeFor(fieldValue);
      epl.addFieldUsedInConstant(f, receiver, value);
    });
    return receiver;
  }

  @override
  Type visitInstanceConstant(InstanceConstant constant) {
    final resultClass = summaryCollector._entryPointsListener
        .addAllocatedClass(constant.classNode);
    constant.fieldValues.forEach((Reference fieldReference, Constant value) {
      summaryCollector._entryPointsListener.addFieldUsedInConstant(
          fieldReference.asField, resultClass, typeFor(value));
    });
    return new ConcreteType(resultClass.cls, null, constant);
  }

  Type _visitTearOffConstant(TearOffConstant constant) {
    final Member member = constant.target;
    summaryCollector._entryPointsListener
        .addRawCall(new DirectSelector(member));
    if (member is Constructor) {
      summaryCollector._entryPointsListener
          .addAllocatedClass(member.enclosingClass);
    }
    summaryCollector._entryPointsListener.recordTearOff(member);
    return _getStaticType(constant);
  }

  @override
  Type visitStaticTearOffConstant(StaticTearOffConstant constant) =>
      _visitTearOffConstant(constant);

  @override
  Type visitConstructorTearOffConstant(ConstructorTearOffConstant constant) =>
      _visitTearOffConstant(constant);

  @override
  Type visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant constant) =>
      _visitTearOffConstant(constant);

  @override
  Type visitInstantiationConstant(InstantiationConstant constant) {
    constant.tearOffConstant.accept(this);
    return _getStaticType(constant);
  }

  @override
  Type visitTypeLiteralConstant(TypeLiteralConstant constant) {
    return summaryCollector._typeType;
  }
}
