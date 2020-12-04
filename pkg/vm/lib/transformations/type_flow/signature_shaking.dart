// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/external_name.dart';
import 'package:kernel/type_environment.dart';

import 'analysis.dart';
import 'table_selector_assigner.dart';
import 'types.dart';
import 'utils.dart';
import '../protobuf_aware_treeshaker/transformer.dart'
    show excludePositionalParametersFromSignatureShaking;
import '../../metadata/procedure_attributes.dart';

/// Transform parameters from optional to required when they are always passed,
/// and remove parameters which are never passed or never used.
///
/// Signatures of static functions are considered on their own. Instance methods
/// are grouped by table selector ID and thus can cover several implementations.
///
/// Definitions:
/// - A parameter is checked if it requires a runtime check, either because it
///   is covariant or it is non-nullable and sound null safety is not enabled.
///   If sound null safety is not enabled, the analysis currently conservatively
///   assumes that null assertions are enabled. If we add a flag for null
///   assertions to gen_kernel, this flag can form part of the definition.
/// - A parameter is used if it is mentioned in the body (or, for constructors,
///   an initializer) of any implementation, or it is checked. An occurrence as
///   an argument to a call (a use dependency) is only considered a use if the
///   corresponding target parameter is used.
/// - A parameter can be eliminated if either:
///   1. it is not used,
///   2. it is never passed and is not written to in any implementation, or
///   3. it is a constant (though not necessarily the same constant) in every
///      implementation and is neither written to nor checked.
/// - A function is eligible if it is not external and is guaranteed to not be
///   called with an unknown call signature.
///
/// All eligible signatures are transformed such that they contain, in order:
/// 1. All positional parameters that are always passed and can't be
///    eliminated, as required positional parameters.
/// 2. All named parameters that are always passed and can't be eliminated,
///    as required positional parameters, alphabetically by name.
/// 3. All positional parameters that are not always passed and can't be
///    eliminated, as positional parameters, each one required iff it was
///    originally required.
/// 4. All named parameters that are not always passed and can't be
///    eliminated, as named parameters in alphabetical order.
class SignatureShaker {
  final TypeFlowAnalysis typeFlowAnalysis;
  final TableSelectorAssigner tableSelectorAssigner;

  final Map<Member, _ProcedureInfo> _memberInfo = {};
  final Map<int, _ProcedureInfo> _selectorInfo = {};

  SignatureShaker(this.typeFlowAnalysis, this.tableSelectorAssigner);

  _ProcedureInfo _infoForMember(Member member) {
    if (!(member is Procedure &&
            (member.kind == ProcedureKind.Method ||
                member.kind == ProcedureKind.Factory) ||
        member is Constructor)) {
      return null;
    }
    if (member.isInstanceMember) {
      final selectorId = tableSelectorAssigner.methodOrSetterSelectorId(member);
      assert(selectorId != ProcedureAttributesMetadata.kInvalidSelectorId);
      return _selectorInfo.putIfAbsent(selectorId, () => _ProcedureInfo());
    } else {
      return _memberInfo.putIfAbsent(member, () => _ProcedureInfo());
    }
  }

  void transformComponent(Component component) {
    _Collect(this).visitComponent(component);
    _resolveUseDependencies();
    _Transform(this).visitComponent(component);
  }

  void _resolveUseDependencies() {
    List<_ParameterInfo> worklist = [];
    for (_ProcedureInfo info in _memberInfo.values) {
      _addUseDependenciesForProcedure(info, worklist);
    }
    for (_ProcedureInfo info in _selectorInfo.values) {
      _addUseDependenciesForProcedure(info, worklist);
    }
    while (worklist.isNotEmpty) {
      _ParameterInfo param = worklist.removeLast();
      for (_ParameterInfo dependencyParam in param.useDependencies) {
        if (!dependencyParam.isRead) {
          dependencyParam.isRead = true;
          if (dependencyParam.useDependencies != null) {
            worklist.add(dependencyParam);
          }
        }
      }
    }
  }

  void _addUseDependenciesForProcedure(
      _ProcedureInfo info, List<_ParameterInfo> worklist) {
    for (_ParameterInfo param in info.positional) {
      _addUseDependenciesForParameter(param, worklist);
    }
    for (_ParameterInfo param in info.named.values) {
      _addUseDependenciesForParameter(param, worklist);
    }
  }

  void _addUseDependenciesForParameter(
      _ParameterInfo param, List<_ParameterInfo> worklist) {
    if ((param.isUsed || !param.info.eligible) &&
        param.useDependencies != null) {
      worklist.add(param);
    }
  }
}

class _ProcedureInfo {
  final List<_ParameterInfo> positional = [];
  final Map<String, _ParameterInfo> named = {};
  int callCount = 0;
  bool eligible = true;

  /// Whether positional parameters can be eliminated from this member. Some
  /// protobuf methods require these parameters to be preserved for the
  /// protobuf-aware tree shaker to function.
  bool canEliminatePositional = true;

  _ParameterInfo ensurePositional(int i) {
    if (positional.length <= i) {
      assert(positional.length == i);
      positional.add(_ParameterInfo(this, i));
    }
    return positional[i];
  }

  _ParameterInfo ensureNamed(String name) {
    return named.putIfAbsent(name, () => _ParameterInfo(this, null));
  }

  bool transformNeeded(FunctionNode function) {
    return positional.any((param) =>
            param.canBeEliminated ||
            (param.isAlwaysPassed &&
                param.index >= function.requiredParameterCount)) ||
        named.values
            .any((param) => param.canBeEliminated || param.isAlwaysPassed);
  }
}

class _ParameterInfo {
  final _ProcedureInfo info;
  final int index;

  int passCount = 0;
  bool isRead = false;
  bool isWritten = false;
  bool isChecked = false;
  bool isConstant = true;

  /// List of parameter variables which were passed as arguments via this
  /// parameter. When this parameter is considered used, all [useDependencies]
  /// parameters should be transitively marked as read.
  List<_ParameterInfo> useDependencies = null;

  _ParameterInfo(this.info, this.index);

  bool get isNamed => index == null;

  bool get isUsed => isRead || isWritten || isChecked;

  bool get isAlwaysPassed => passCount == info.callCount;

  bool get isNeverPassed => passCount == 0;

  bool get canBeEliminated =>
      (!isUsed || (isNeverPassed || isConstant && !isChecked) && !isWritten) &&
      (isNamed || info.canEliminatePositional);

  void observeParameter(
      Member member, VariableDeclaration param, SignatureShaker shaker) {
    final Type type = shaker.typeFlowAnalysis.argumentType(member, param);

    // A parameter is considered constant if the TFA has inferred it to have a
    // constant value in every implementation. The constant value inferred does
    // not have to be the same across implementations, as it is specialized in
    // each implementation individually.
    if (!(type is ConcreteType && type.constant != null ||
        type is NullableType && type.baseType is EmptyType)) {
      isConstant = false;
    }

    // Covariant parameters have implicit type checks, which count as reads.
    // When run in weak mode with null assertions enabled, parameters with
    // non-nullable types have implicit null checks, which count as reads.
    if ((param.isCovariant || param.isGenericCovariantImpl) ||
        (!shaker.typeFlowAnalysis.target.flags.enableNullSafety &&
            param.type.nullability == Nullability.nonNullable &&
            (type == null || type is NullableType))) {
      isChecked = true;
    }
  }
}

class _Collect extends RecursiveVisitor<void> {
  final SignatureShaker shaker;

  /// Parameters of the current function.
  final Map<VariableDeclaration, _ParameterInfo> localParameters = {};

  /// Set of [VariableGet] nodes corresponding to parameters in the current
  /// function which are passed as arguments to eligible calls. They are tracked
  /// via [_ParameterInfo.useDependencies] and not marked as read immediately.
  final Set<VariableGet> useDependencies = {};

  _Collect(this.shaker);

  void enterFunction(Member member) {
    final _ProcedureInfo info = shaker._infoForMember(member);
    if (info == null) return;

    localParameters.clear();
    useDependencies.clear();
    final FunctionNode fun = member.function;
    for (int i = 0; i < fun.positionalParameters.length; i++) {
      final VariableDeclaration param = fun.positionalParameters[i];
      localParameters[param] = info.ensurePositional(i)
        ..observeParameter(member, param, shaker);
    }
    for (VariableDeclaration param in fun.namedParameters) {
      localParameters[param] = info.ensureNamed(param.name)
        ..observeParameter(member, param, shaker);
    }

    if (shaker.typeFlowAnalysis.isCalledDynamically(member) ||
        shaker.typeFlowAnalysis.isTearOffTaken(member) ||
        shaker.typeFlowAnalysis.nativeCodeOracle
            .isMemberReferencedFromNativeCode(member) ||
        shaker.typeFlowAnalysis.nativeCodeOracle.isRecognized(member) ||
        getExternalName(member) != null) {
      info.eligible = false;
    }

    if (excludePositionalParametersFromSignatureShaking(member)) {
      info.canEliminatePositional = false;
    }
  }

  @override
  void visitProcedure(Procedure node) {
    enterFunction(node);
    super.visitProcedure(node);
  }

  @override
  void visitConstructor(Constructor node) {
    enterFunction(node);
    super.visitConstructor(node);
  }

  @override
  void visitVariableGet(VariableGet node) {
    // Variable reads marked as use dependencies are not considered reads
    // immediately. Their status as a read or not will be computed after all use
    // dependencies have been collected.
    localParameters[node.variable]?.isRead |= !useDependencies.contains(node);
    super.visitVariableGet(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    localParameters[node.variable]?.isWritten = true;
    super.visitVariableSet(node);
  }

  void addUseDependency(Expression arg, _ParameterInfo param) {
    if (arg is VariableGet) {
      _ParameterInfo localParam = localParameters[arg.variable];
      if (localParam != null && !localParam.isUsed) {
        // This is a parameter passed as an argument. Mark it as a use
        // dependency.
        param.useDependencies ??= [];
        param.useDependencies.add(localParam);
        useDependencies.add(arg);
      }
    }
  }

  void collectCall(Member member, Arguments args) {
    final _ProcedureInfo info = shaker._infoForMember(member);
    if (info == null) return;

    for (int i = 0; i < args.positional.length; i++) {
      _ParameterInfo param = info.ensurePositional(i);
      param.passCount++;
      addUseDependency(args.positional[i], param);
    }
    for (NamedExpression named in args.named) {
      _ParameterInfo param = info.ensureNamed(named.name);
      param.passCount++;
      addUseDependency(named.value, param);
    }
    info.callCount++;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    collectCall(node.interfaceTarget, node.arguments);
    super.visitMethodInvocation(node);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    collectCall(node.interfaceTarget, node.arguments);
    super.visitSuperMethodInvocation(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    collectCall(node.target, node.arguments);
    super.visitStaticInvocation(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    collectCall(node.target, node.arguments);
    super.visitConstructorInvocation(node);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    collectCall(node.target, node.arguments);
    super.visitRedirectingInitializer(node);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    collectCall(node.target, node.arguments);
    super.visitSuperInitializer(node);
  }
}

class _Transform extends RecursiveVisitor<void> {
  final SignatureShaker shaker;

  StaticTypeContext typeContext;
  final Map<VariableDeclaration, Constant> eliminatedParams = {};
  final Set<VariableDeclaration> unusedParams = {};
  final List<LocalInitializer> addedInitializers = [];

  _Transform(this.shaker);

  void eliminateUsedParameter(
      Member member, _ParameterInfo param, VariableDeclaration variable) {
    Constant value;
    if (param.isConstant) {
      Type type = shaker.typeFlowAnalysis.argumentType(member, variable);
      if (type is ConcreteType) {
        assert(type.constant != null);
        value = type.constant;
      } else {
        assert(type is NullableType && type.baseType is EmptyType);
        value = NullConstant();
      }
    } else {
      value = (variable.initializer as ConstantExpression)?.constant ??
          NullConstant();
    }
    eliminatedParams[variable] = value;
  }

  void transformMemberSignature(Member member) {
    typeContext =
        StaticTypeContext(member, shaker.typeFlowAnalysis.environment);
    eliminatedParams.clear();
    unusedParams.clear();

    final _ProcedureInfo info = shaker._infoForMember(member);
    if (info == null || !info.eligible || info.callCount == 0) return;

    final FunctionNode function = member.function;

    if (!info.transformNeeded(function)) return;

    final List<VariableDeclaration> positional = [];
    final List<VariableDeclaration> named = [];
    // 1. All positional parameters that are always passed and can't be
    //    eliminated, as required positional parameters.
    int firstNotAlwaysPassed = function.positionalParameters.length;
    for (int i = 0; i < function.positionalParameters.length; i++) {
      final _ParameterInfo param = info.positional[i];
      if (!param.isAlwaysPassed) {
        firstNotAlwaysPassed = i;
        break;
      }
      final VariableDeclaration variable = function.positionalParameters[i];
      if (param.isUsed) {
        if (param.canBeEliminated) {
          eliminateUsedParameter(member, param, variable);
        } else {
          positional.add(variable);
          variable.initializer = null;
        }
      } else {
        unusedParams.add(variable);
      }
    }
    // 2. All named parameters that are always passed and can't be eliminated,
    //    as required positional parameters, alphabetically by name.
    final List<VariableDeclaration> sortedNamed = function.namedParameters
        .toList()
          ..sort((var1, var2) => var1.name.compareTo(var2.name));
    for (VariableDeclaration variable in sortedNamed) {
      final _ParameterInfo param = info.named[variable.name];
      if (param.isAlwaysPassed) {
        if (param.isUsed) {
          if (param.canBeEliminated) {
            eliminateUsedParameter(member, param, variable);
          } else {
            variable.initializer = null;
            variable.isRequired = false;
            positional.add(variable);
          }
        } else {
          unusedParams.add(variable);
        }
      }
    }
    int requiredParameterCount = positional.length;
    // 3. All positional parameters that are not always passed and can't be
    //    eliminated, as positional parameters, each one required iff it was
    //    originally required.
    for (int i = firstNotAlwaysPassed;
        i < function.positionalParameters.length;
        i++) {
      final _ParameterInfo param = info.positional[i];
      assert(!param.isAlwaysPassed);
      final VariableDeclaration variable = function.positionalParameters[i];
      if (param.isUsed) {
        if (param.canBeEliminated) {
          eliminateUsedParameter(member, param, variable);
        } else if (!param.isAlwaysPassed) {
          positional.add(variable);
          if (i < function.requiredParameterCount) {
            // The parameter is required, but it is not always passed. This is
            // possible if the method is overridden by a method which makes the
            // parameter optional.
            assert(variable.initializer == null);
            requiredParameterCount++;
          }
        }
      } else {
        unusedParams.add(variable);
      }
    }
    // 4. All named parameters that are not always passed and can't be
    //    eliminated, as named parameters in alphabetical order.
    for (VariableDeclaration variable in sortedNamed) {
      final _ParameterInfo param = info.named[variable.name];
      if (!param.isAlwaysPassed) {
        if (param.isUsed) {
          if (param.canBeEliminated) {
            eliminateUsedParameter(member, param, variable);
          } else {
            named.add(variable);
          }
        } else {
          unusedParams.add(variable);
        }
      }
    }

    assert(requiredParameterCount <= positional.length);
    function.requiredParameterCount = requiredParameterCount;
    function.positionalParameters = positional;
    function.namedParameters = named;

    shaker.typeFlowAnalysis.adjustFunctionParameters(member);
  }

  @override
  void visitVariableGet(VariableGet node) {
    Constant constantValue = eliminatedParams[node.variable];
    if (constantValue != null) {
      node.replaceWith(ConstantExpression(constantValue));
    }
  }

  @override
  void visitConstructor(Constructor node) {
    transformMemberSignature(node);
    super.visitConstructor(node);
    if (addedInitializers.isNotEmpty) {
      // Insert hoisted constructor arguments before this/super initializer.
      assert(node.initializers.last is RedirectingInitializer ||
          node.initializers.last is SuperInitializer);
      node.initializers
          .insertAll(node.initializers.length - 1, addedInitializers.reversed);
      addedInitializers.clear();
    }
  }

  @override
  void visitProcedure(Procedure node) {
    transformMemberSignature(node);
    super.visitProcedure(node);
  }

  static void forEachArgumentRev(Arguments args, _ProcedureInfo info,
      void Function(Expression, _ParameterInfo) fun) {
    for (int i = args.named.length - 1; i >= 0; i--) {
      final NamedExpression namedExp = args.named[i];
      fun(namedExp.value, info.named[namedExp.name]);
    }
    for (int i = args.positional.length - 1; i >= 0; i--) {
      fun(args.positional[i], info.positional[i]);
    }
  }

  void transformCall(
      Member target, TreeNode call, Expression receiver, Arguments args) {
    final _ProcedureInfo info = shaker._infoForMember(target);
    if (info == null || !info.eligible) return;

    bool transformNeeded = false;
    bool hoistingNeeded = false;
    forEachArgumentRev(args, info, (Expression arg, _ParameterInfo param) {
      assert(!param.isNeverPassed);
      if (param.canBeEliminated || param.isNamed && param.isAlwaysPassed) {
        transformNeeded = true;
        if (mayHaveSideEffects(arg)) {
          hoistingNeeded = true;
        }
      }
    });

    if (!transformNeeded) return;

    bool isUnusedParam(Expression exp) {
      return exp is VariableGet && unusedParams.contains(exp.variable);
    }

    Map<Expression, VariableDeclaration> hoisted = {};
    if (hoistingNeeded) {
      if (call is Initializer) {
        final Constructor constructor = call.parent;
        forEachArgumentRev(args, info, (Expression arg, _ParameterInfo param) {
          if (mayHaveOrSeeSideEffects(arg) && !isUnusedParam(arg)) {
            VariableDeclaration argVar = VariableDeclaration(null,
                initializer: arg,
                type: arg.getStaticType(typeContext),
                isFinal: true);
            addedInitializers
                .add(LocalInitializer(argVar)..parent = constructor);
            hoisted[arg] = argVar;
          }
        });
      } else {
        final TreeNode parent = call.parent;
        Expression current = call;
        forEachArgumentRev(args, info, (Expression arg, _ParameterInfo param) {
          if (mayHaveOrSeeSideEffects(arg) && !isUnusedParam(arg)) {
            VariableDeclaration argVar = VariableDeclaration(null,
                initializer: arg,
                type: arg.getStaticType(typeContext),
                isFinal: true);
            current = Let(argVar, current);
            hoisted[arg] = argVar;
          }
        });
        if (receiver != null && mayHaveOrSeeSideEffects(receiver)) {
          assert(!isUnusedParam(receiver));
          assert(receiver.parent == call);
          final VariableDeclaration receiverVar = VariableDeclaration(null,
              initializer: receiver,
              type: receiver.getStaticType(typeContext),
              isFinal: true);
          current = Let(receiverVar, current);
          call.replaceChild(receiver, VariableGet(receiverVar));
        }

        parent.replaceChild(call, current);
      }
    }

    Expression getMaybeHoistedArg(Expression arg) {
      final variable = hoisted[arg];
      if (variable == null) return arg;
      return VariableGet(variable);
    }

    final List<Expression> positional = [];
    final List<NamedExpression> named = [];
    // 1. All positional parameters that are always passed and can't be
    //    eliminated, as required positional parameters.
    for (int i = 0; i < args.positional.length; i++) {
      final _ParameterInfo param = info.positional[i];
      final Expression arg = args.positional[i];
      if (param.isAlwaysPassed && !param.canBeEliminated) {
        positional.add(getMaybeHoistedArg(arg));
      }
    }
    // 2. All named parameters that are always passed and can't be eliminated,
    //    as required positional parameters, alphabetically by name.
    final List<NamedExpression> sortedNamed = args.named.toList()
      ..sort((var1, var2) => var1.name.compareTo(var2.name));
    for (NamedExpression arg in sortedNamed) {
      final _ParameterInfo param = info.named[arg.name];
      if (param.isAlwaysPassed && !param.canBeEliminated) {
        positional.add(getMaybeHoistedArg(arg.value));
      }
    }
    // 3. All positional parameters that are not always passed and can't be
    //    eliminated, as positional parameters, each one required iff it was
    //    originally required.
    for (int i = 0; i < args.positional.length; i++) {
      final _ParameterInfo param = info.positional[i];
      final Expression arg = args.positional[i];
      if (!param.isAlwaysPassed && !param.canBeEliminated) {
        positional.add(getMaybeHoistedArg(arg));
      }
    }
    // 4. All named parameters that are not always passed and can't be
    //    eliminated, as named parameters in alphabetical order.
    //    (Arguments are kept in original order.)
    for (NamedExpression arg in args.named) {
      final _ParameterInfo param = info.named[arg.name];
      if (!param.isAlwaysPassed && !param.canBeEliminated) {
        arg.value = getMaybeHoistedArg(arg.value)..parent = arg;
        named.add(arg);
      }
    }

    args.replaceWith(Arguments(positional, named: named, types: args.types));
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    transformCall(node.interfaceTarget, node, node.receiver, node.arguments);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    super.visitSuperMethodInvocation(node);
    transformCall(node.interfaceTarget, node, null, node.arguments);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);
    transformCall(node.target, node, null, node.arguments);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    super.visitConstructorInvocation(node);
    transformCall(node.target, node, null, node.arguments);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    super.visitRedirectingInitializer(node);
    transformCall(node.target, node, null, node.arguments);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    super.visitSuperInitializer(node);
    transformCall(node.target, node, null, node.arguments);
  }
}
