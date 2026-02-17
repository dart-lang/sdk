// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/kernel/record_use.dart' show isBeingRecorded;
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/transformations/record_use/record_use.dart';

/// Record calls and their constant arguments. Currently tracks
/// * static or top-level method calls through [recordStaticInvocation]
/// * tear-offs through [recordConstantExpression]
///
/// The result of adding calls can be fetched from [callsForMethod].
class CallRecorder {
  /// Keep track of the calls which are recorded, to easily add newly found
  /// ones.
  final Map<Definition, List<CallReference>> callsForMethod = {};

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

  /// Will record a tear-off if the target is annotated with `@RecordUse`.
  void recordConstantExpression(ast.ConstantExpression node) {
    final constant = node.constant;
    if (constant is ast.StaticTearOffConstant) {
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
    final identifier = _definitionFromMember(target);
    callsForMethod.update(
      identifier,
      (usage) => usage..add(call),
      ifAbsent: () => [call],
    );
  }

  CallReference _createCallReference(ast.StaticInvocation node) {
    // Get rid of the artificial `this` argument for extension methods.
    final int argumentStart;
    if (node.target.isExtensionMember || node.target.isExtensionTypeMember) {
      argumentStart = 1;
    } else {
      argumentStart = 0;
    }

    final positionalArguments =
        node.arguments.positional
            .skip(argumentStart)
            .map((argument) => _evaluateLiteral(argument))
            .toList();

    final namedArguments = {
      for (final argument in node.arguments.named)
        argument.name: _evaluateLiteral(argument.value),
    };

    // Fill up with the default values
    for (final parameter in node.target.function.namedParameters) {
      final initializer = parameter.initializer;
      final name = parameter.name;
      if (initializer != null &&
          name != null &&
          !namedArguments.containsKey(name)) {
        namedArguments[name] = _evaluateLiteral(initializer);
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
        positionalArguments.add(_evaluateLiteral(initializer));
      }
    }

    return CallWithArguments(
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
      loadingUnit: _loadingUnitLookup(node),
    );
  }

  MaybeConstant _evaluateLiteral(ast.Expression expression) {
    if (expression is ast.BasicLiteral) {
      return evaluateLiteral(expression);
    } else if (expression is ast.ConstantExpression) {
      return evaluateConstant(expression.constant);
    } else if (expression is ast.VariableGet &&
        expression.variable.initializer != null) {
      return _evaluateLiteral(expression.variable.initializer!);
    } else {
      return const NonConstant();
    }
  }

  Definition _definitionFromMember(ast.Member target) {
    final enclosingLibrary = target.enclosingLibrary;
    final importUri = enclosingLibrary.importUri.toString();

    return Definition(importUri, [
      if (target.enclosingClass?.name != null) Name(target.enclosingClass!.name),
      Name(target.name.text),
    ]);
  }
}
