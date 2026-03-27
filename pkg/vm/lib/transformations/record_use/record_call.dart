// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/kernel/record_use.dart' show isBeingRecorded;
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use.dart';
import 'package:vm/transformations/record_use/record_use.dart';

/// Record calls and their constant arguments. Currently tracks
/// * static or top-level method calls through [recordStaticInvocation]
/// * tear-offs through [recordConstantExpression]
///
/// The result of adding calls can be fetched from [callsForMethod].
class CallRecorder {
  /// Keep track of the calls which are recorded, to easily add newly found
  /// ones.
  final Map<DefinitionWithStaticCalls, List<CallReference>> callsForMethod = {};

  /// A function to look up the loading unit for a reference.
  final LoadingUnitLookup _loadingUnitLookup;

  /// Whether to save line and column info as well as the URI.
  //TODO(mosum): add verbose mode to enable this
  bool exactLocation = false;

  CallRecorder(this._loadingUnitLookup);

  /// Will record a static invocation if it is annotated with `@RecordUse`.
  void recordStaticInvocation(ast.StaticInvocation node) {
    if (isBeingRecorded(node.target)) {
      // Collect the (int, bool, double, or String) arguments passed in the call.
      final createCallReference = _createCallReference(node);
      _addToUsage(node.target, createCallReference);
    }
  }

  /// Will record a static get if it is annotated with `@RecordUse`.
  void recordStaticGet(ast.StaticGet node) {
    final target = node.target;
    if (target is ast.Procedure && isBeingRecorded(target)) {
      _addToUsage(
        target,
        CallWithArguments(
          positionalArguments: [],
          namedArguments: {},
          loadingUnit: _loadingUnitLookup(node),
        ),
      );
    }
  }

  /// Will record a static set if it is annotated with `@RecordUse`.
  void recordStaticSet(ast.StaticSet node) {
    final target = node.target;
    if (target is ast.Procedure && isBeingRecorded(target)) {
      _addToUsage(
        target,
        CallWithArguments(
          positionalArguments: [evaluateExpression(node.value)],
          namedArguments: {},
          loadingUnit: _loadingUnitLookup(node),
        ),
      );
    }
  }

  /// Will record a tear-off if the target is annotated with `@RecordUse`.
  void recordStaticTearOff(ast.StaticTearOff node) {
    if (isBeingRecorded(node.target)) {
      _addToUsage(
        node.target,
        CallTearoff(loadingUnit: _loadingUnitLookup(node)),
      );
    }
  }

  /// Will record a tear-off if the target is annotated with `@RecordUse`.
  void recordConstantExpression(ast.ConstantExpression node) {
    final constant = node.constant;
    if (constant is ast.StaticTearOffConstant) {
      if (isTearOffLowering(constant.target)) return;
      if (isBeingRecorded(constant.target)) {
        _addToUsage(
          constant.target,
          CallTearoff(loadingUnit: _loadingUnitLookup(node)),
        );
      }
    }
  }

  /// Collect the name and definition location of the invocation. This is
  /// shared across multiple calls to the same method.
  void _addToUsage(ast.Procedure target, CallReference call) {
    final identifier =
        definitionFromMember(target) as DefinitionWithStaticCalls;
    // TODO: Merge loading units if an identical CallReference already exists.
    callsForMethod.update(
      identifier,
      (usage) => usage..add(call),
      ifAbsent: () => [call],
    );
  }

  CallReference _createCallReference(ast.StaticInvocation node) {
    final target = node.target;

    final isTearOffLowering = isExtensionMemberTearOff(target);
    final bool hasReceiver =
        (target.function.positionalParameters.isNotEmpty &&
            isExtensionThisName(
              target.function.positionalParameters[0].name,
            )) ||
        isTearOffLowering;

    // Record the artificial `this` argument for extension methods as a
    // receiver.
    MaybeConstant? receiver =
        (hasReceiver && node.arguments.positional.isNotEmpty)
        ? evaluateExpression(node.arguments.positional[0])
        : null;

    if (isTearOffLowering) {
      return CallTearoff(
        loadingUnit: _loadingUnitLookup(node),
        receiver: receiver,
      );
    }

    final int argumentStart = receiver != null ? 1 : 0;

    final positionalArguments = node.arguments.positional
        .skip(argumentStart)
        .map((argument) => evaluateExpression(argument))
        .toList();

    final namedArguments = {
      for (final argument in node.arguments.named)
        argument.name: evaluateExpression(argument.value),
    };

    // Fill up with the default values
    for (final parameter in node.target.function.namedParameters) {
      final initializer = parameter.initializer;
      final name = parameter.name;
      if (initializer != null &&
          name != null &&
          !namedArguments.containsKey(name)) {
        namedArguments[name] = evaluateExpression(initializer);
      }
    }
    for (
      var i = positionalArguments.length;
      i < node.target.function.positionalParameters.length;
      i++
    ) {
      final parameter = node.target.function.positionalParameters[i];
      final initializer = parameter.initializer;
      if (initializer != null) {
        positionalArguments.add(evaluateExpression(initializer));
      }
    }

    return CallWithArguments(
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
      loadingUnit: _loadingUnitLookup(node),
      receiver: receiver,
    );
  }
}

MaybeConstant evaluateExpression(ast.Expression expression) {
  if (expression is ast.BasicLiteral) {
    return evaluateLiteral(expression);
  } else if (expression is ast.ConstantExpression) {
    return evaluateConstant(expression.constant);
  } else if (expression is ast.VariableGet &&
      expression.variable.initializer != null) {
    return evaluateExpression(expression.variable.initializer!);
  } else {
    return const NonConstant();
  }
}

DefinitionWithMembers definitionFromClass(ast.Class cls) {
  final library = Library(cls.enclosingLibrary.importUri.toString());
  if (cls.isEnum) return Enum(cls.name, library);
  if (cls.isMixinDeclaration) return Mixin(cls.name, library);
  return Class(cls.name, library);
}

Definition definitionFromMember(ast.Member target) {
  final enclosingLibrary = target.enclosingLibrary;
  final library = Library(enclosingLibrary.importUri.toString());
  final isExtensionMember =
      target is ast.Procedure &&
      (target.isExtensionMember || target.isExtensionTypeMember);

  if (isExtensionMember) {
    final isTearOffLowering = isExtensionMemberTearOff(target);
    final String qualifiedExtensionName =
        extractQualifiedNameFromExtensionMethodName(target.name.text)!;
    final List<String> parts = qualifiedExtensionName.split('.');
    final bool hasReceiver =
        (target.function.positionalParameters.isNotEmpty &&
            isExtensionThisName(
              target.function.positionalParameters[0].name,
            )) ||
        isTearOffLowering;

    final DefinitionWithMembers parent = target.isExtensionMember
        ? (hasUnnamedExtensionNamePrefix(target.name.text)
              ? Extension.unnamed(library)
              : Extension(parts[0], library))
        : ExtensionType(parts[0], library);

    final memberName = parts[1];
    return _createMember(target, parent, memberName, isInstance: hasReceiver);
  }

  final parentNode = target.parent;
  final ScopeWithMembers parent = parentNode is ast.Class
      ? definitionFromClass(parentNode)
      : library;

  return _createMember(
    target,
    parent,
    target.name.text,
    isInstance: target is ast.Procedure ? !target.isStatic : false,
  );
}

Definition _createMember(
  ast.Member target,
  ScopeWithMembers parent,
  String name, {
  required bool isInstance,
}) => switch (target) {
  ast.Procedure p
      when p.kind == ast.ProcedureKind.Operator ||
          isExtensionMemberOperator(p) =>
    Operator(name, parent as DefinitionWithMembers),
  ast.Procedure p when p.kind == ast.ProcedureKind.Method => Method(
    name,
    parent,
    isInstanceMember: isInstance,
  ),
  ast.Procedure p when p.kind == ast.ProcedureKind.Getter => Getter(
    name,
    parent,
    isInstanceMember: isInstance,
  ),
  ast.Procedure p when p.kind == ast.ProcedureKind.Setter => Setter(
    name,
    parent,
    isInstanceMember: isInstance,
  ),
  ast.Procedure p when p.kind == ast.ProcedureKind.Factory =>
    name.isEmpty
        ? Constructor.unnamed(parent as DefinitionWithMembers)
        : Constructor(name, parent as DefinitionWithMembers),
  ast.Constructor _ =>
    name.isEmpty
        ? Constructor.unnamed(parent as DefinitionWithMembers)
        : Constructor(name, parent as DefinitionWithMembers),
  _ => throw UnsupportedError('Unsupported member type: $target'),
};
