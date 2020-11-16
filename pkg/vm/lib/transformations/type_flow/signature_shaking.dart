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
import '../../metadata/procedure_attributes.dart';

/// Transform parameters from optional to required when they are always passed,
/// and remove parameters which are never passed or never used.
///
/// Signatures of static functions are considered on their own. Instance methods
/// are grouped by table selector ID and thus can cover several implementations.
///
/// Definitions:
/// - A parameter is used if it is mentioned in the body (or, for constructors,
///   an initializer) of any implementation.
/// - A parameter can be eliminated if either:
///   1. it is not used; or
///   2. it is never passed and is not written to in any implementation.
/// - A function is eligible if it is not external and is guaranteed to not be
///   called with an unknown call signature.
///
/// All eligible signatures are transformed such that they contain, in order:
/// 1. All used positional parameters that are always passed, as required
///    positional parameters.
/// 2. All used named parameters that are always passed, as required positional
///    parameters, alphabetically by name.
/// 3. All used positional parameters that are not always passed and can't be
///    eliminated, as positional parameters, each one required iff it was
///    originally required.
/// 4. All used named parameters that are not always passed and can't be
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
    _Transform(this).visitComponent(component);
  }
}

class _ProcedureInfo {
  final List<_ParameterInfo> positional = [];
  final Map<String, _ParameterInfo> named = {};
  int callCount = 0;
  bool eligible = true;

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

  _ParameterInfo(this.info, this.index);

  bool get isNamed => index == null;

  bool get isUsed => isRead || isWritten;

  bool get isAlwaysPassed => passCount == info.callCount;

  bool get isNeverPassed => passCount == 0;

  bool get canBeEliminated => !isUsed || isNeverPassed && !isWritten;

  void observeImplicitChecks(
      Member member, VariableDeclaration param, SignatureShaker shaker) {
    if (param.isCovariant || param.isGenericCovariantImpl) {
      // Covariant parameters have implicit type checks, which count as reads.
      isRead = true;
    } else if (param.type.nullability == Nullability.nonNullable) {
      // When run in weak mode with null assertions enabled, parameters with
      // non-nullable types have implicit null checks, which count as reads.
      Type type = shaker.typeFlowAnalysis.argumentType(member, param);
      if (type == null || type is NullableType) {
        // TFA can't guarantee that the value isn't null. Preserve check.
        isRead = true;
      }
    }
  }
}

class _Collect extends RecursiveVisitor<void> {
  final SignatureShaker shaker;

  final Map<VariableDeclaration, _ParameterInfo> localParameters = {};

  _Collect(this.shaker);

  void enterFunction(Member member) {
    final _ProcedureInfo info = shaker._infoForMember(member);
    if (info == null) return;

    localParameters.clear();
    final FunctionNode fun = member.function;
    for (int i = 0; i < fun.positionalParameters.length; i++) {
      final VariableDeclaration param = fun.positionalParameters[i];
      localParameters[param] = info.ensurePositional(i)
        ..observeImplicitChecks(member, param, shaker);
    }
    for (VariableDeclaration param in fun.namedParameters) {
      localParameters[param] = info.ensureNamed(param.name)
        ..observeImplicitChecks(member, param, shaker);
    }

    if (shaker.typeFlowAnalysis.isCalledDynamically(member) ||
        shaker.typeFlowAnalysis.isTearOffTaken(member) ||
        shaker.typeFlowAnalysis.nativeCodeOracle
            .isMemberReferencedFromNativeCode(member) ||
        shaker.typeFlowAnalysis.nativeCodeOracle.isRecognized(member) ||
        getExternalName(member) != null) {
      info.eligible = false;
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
    localParameters[node.variable]?.isRead = true;
    super.visitVariableGet(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    localParameters[node.variable]?.isWritten = true;
    super.visitVariableSet(node);
  }

  void collectCall(Member member, Arguments args) {
    final _ProcedureInfo info = shaker._infoForMember(member);
    if (info == null) return;

    for (int i = 0; i < args.positional.length; i++) {
      info.ensurePositional(i).passCount++;
    }
    for (NamedExpression named in args.named) {
      info.ensureNamed(named.name).passCount++;
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
  final Set<VariableDeclaration> eliminatedParams = {};
  final List<LocalInitializer> addedInitializers = [];

  _Transform(this.shaker);

  void transformMemberSignature(Member member) {
    typeContext =
        StaticTypeContext(member, shaker.typeFlowAnalysis.environment);
    eliminatedParams.clear();

    final _ProcedureInfo info = shaker._infoForMember(member);
    if (info == null || !info.eligible || info.callCount == 0) return;

    final FunctionNode function = member.function;

    if (!info.transformNeeded(function)) return;

    final List<VariableDeclaration> positional = [];
    final List<VariableDeclaration> named = [];
    // 1. All used positional parameters that are always passed, as required
    //    positional parameters.
    for (int i = 0; i < function.positionalParameters.length; i++) {
      final _ParameterInfo param = info.positional[i];
      if (!param.isAlwaysPassed) break;
      if (param.isUsed) {
        final VariableDeclaration variable = function.positionalParameters[i];
        positional.add(variable);
        variable.initializer = null;
      }
    }
    // 2. All used named parameters that are always passed, as required
    //    positional parameters, alphabetically by name.
    final List<VariableDeclaration> sortedNamed = function.namedParameters
        .toList()
          ..sort((var1, var2) => var1.name.compareTo(var2.name));
    for (VariableDeclaration variable in sortedNamed) {
      final _ParameterInfo param = info.named[variable.name];
      if (param.isUsed && param.isAlwaysPassed) {
        variable.initializer = null;
        variable.isRequired = false;
        positional.add(variable);
      }
    }
    int requiredParameterCount = positional.length;
    // 3. All used positional parameters that are not always passed and can't be
    //    eliminated, as positional parameters, each one required iff it was
    //    originally required.
    for (int i = 0; i < function.positionalParameters.length; i++) {
      final _ParameterInfo param = info.positional[i];
      if (param.isUsed) {
        final VariableDeclaration variable = function.positionalParameters[i];
        if (param.canBeEliminated) {
          assert(variable.initializer == null ||
              variable.initializer is ConstantExpression);
          eliminatedParams.add(variable);
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
      }
    }
    // 4. All used named parameters that are not always passed and can't be
    //    eliminated, as named parameters in alphabetical order.
    for (VariableDeclaration variable in sortedNamed) {
      final _ParameterInfo param = info.named[variable.name];
      if (param.isUsed) {
        if (param.canBeEliminated) {
          assert(variable.initializer == null ||
              variable.initializer is ConstantExpression);
          eliminatedParams.add(variable);
        } else if (!param.isAlwaysPassed) {
          named.add(variable);
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
    if (eliminatedParams.contains(node.variable)) {
      final ConstantExpression initializer = node.variable.initializer;
      node.replaceWith(
          ConstantExpression(initializer?.constant ?? NullConstant()));
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
      if (!param.isUsed || param.isNamed && param.isAlwaysPassed) {
        transformNeeded = true;
        if (mayHaveSideEffects(arg)) {
          hoistingNeeded = true;
        }
      }
    });

    if (!transformNeeded) return;

    Map<Expression, VariableDeclaration> hoisted = {};
    if (hoistingNeeded) {
      if (call is Initializer) {
        final Constructor constructor = call.parent;
        forEachArgumentRev(args, info, (Expression arg, _ParameterInfo param) {
          if (mayHaveOrSeeSideEffects(arg)) {
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
          if (mayHaveOrSeeSideEffects(arg)) {
            VariableDeclaration argVar = VariableDeclaration(null,
                initializer: arg,
                type: arg.getStaticType(typeContext),
                isFinal: true);
            current = Let(argVar, current);
            hoisted[arg] = argVar;
          }
        });
        if (receiver != null && mayHaveOrSeeSideEffects(receiver)) {
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
    // 1. All used positional parameters that are always passed, as required
    //    positional parameters.
    for (int i = 0; i < args.positional.length; i++) {
      final _ParameterInfo param = info.positional[i];
      final Expression arg = args.positional[i];
      if (param.isUsed && param.isAlwaysPassed) {
        positional.add(getMaybeHoistedArg(arg));
      }
    }
    // 2. All used named parameters that are always passed, as required
    //    positional parameters, alphabetically by name.
    final List<NamedExpression> sortedNamed = args.named.toList()
      ..sort((var1, var2) => var1.name.compareTo(var2.name));
    for (NamedExpression arg in sortedNamed) {
      final _ParameterInfo param = info.named[arg.name];
      if (param.isUsed && param.isAlwaysPassed) {
        positional.add(getMaybeHoistedArg(arg.value));
      }
    }
    // 3. All used positional parameters that are not always passed and can't be
    //    eliminated, as positional parameters, each one required iff it was
    //    originally required.
    for (int i = 0; i < args.positional.length; i++) {
      final _ParameterInfo param = info.positional[i];
      final Expression arg = args.positional[i];
      if (param.isUsed && !param.isAlwaysPassed) {
        positional.add(getMaybeHoistedArg(arg));
      }
    }
    // 4. All used named parameters that are not always passed and can't be
    //    eliminated, as named parameters in alphabetical order.
    //    (Arguments are kept in original order.)
    for (NamedExpression arg in args.named) {
      final _ParameterInfo param = info.named[arg.name];
      if (param.isUsed && !param.isAlwaysPassed) {
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
