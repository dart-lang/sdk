// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:front_end/src/kernel/record_use.dart' as recordUse;
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/metadata/loading_units.dart';
import 'package:vm/transformations/record_use/record_use.dart';

/// Record calls and their constant arguments. Currently tracks
/// * static or top-level method calls through [recordStaticInvocation]
/// * tear-offs through [recordConstantExpression]
///
/// The result of adding calls can be fetched from [foundCalls].
class CallRecorder {
  /// The collection of recorded calls found so far.
  Iterable<Usage<CallReference>> get foundCalls => _callsForMethod.values;

  /// Keep track of the calls which are recorded, to easily add newly found
  /// ones.
  final Map<ast.Procedure, Usage<CallReference>> _callsForMethod = {};

  /// The ordered list of loading units to retrieve the loading unit index from.
  final List<LoadingUnit> _loadingUnits;

  /// The source uri to base relative URIs off of.
  final Uri _source;

  CallRecorder(this._source, this._loadingUnits);

  /// Will record a static invocation if it is annotated with `@RecordUse`.
  void recordStaticInvocation(ast.StaticInvocation node) {
    final annotations = recordUse.findRecordUseAnnotation(node.target);
    if (annotations.isNotEmpty) {
      final call = _getCall(node.target);

      // Collect the (int, bool, double, or String) arguments passed in the call.
      call.references.add(_createCallReference(node));
    }
  }

  /// Will record a tear-off if the target is annotated with `@RecordUse`.
  void recordConstantExpression(ast.ConstantExpression node) {
    final constant = node.constant;
    if (constant is ast.StaticTearOffConstant) {
      final hasRecordUseAnnotation =
          recordUse.findRecordUseAnnotation(constant.target).isNotEmpty;
      if (hasRecordUseAnnotation) {
        _recordTearOff(constant, node);
      }
    }
  }

  void _recordTearOff(
    ast.StaticTearOffConstant constant,
    ast.ConstantExpression node,
  ) {
    final call = _getCall(constant.target);
    final reference = _collectTearOff(constant, node);
    call.references.add(reference);
  }

  /// Record a tear off as a call with all non-const arguments.
  CallReference _collectTearOff(
    ast.StaticTearOffConstant constant,
    ast.TreeNode node,
  ) {
    final function = constant.target.function;
    final nonConstArguments = NonConstArguments(
      named:
          function.namedParameters.map((parameter) => parameter.name!).toList(),
      positional: List.generate(
        function.positionalParameters.length,
        (index) => index,
      ),
    );
    return CallReference(
      location: node.location!.recordLocation(_source),
      arguments: Arguments(nonConstArguments: nonConstArguments),
    );
  }

  /// Collect the name and definition location of the invocation. This is
  /// shared across multiple calls to the same method.
  Usage _getCall(ast.Procedure target) {
    final definition = _definitionFromMember(target);
    return _callsForMethod[target] ??=
        Usage(definition: definition, references: []);
  }

  CallReference _createCallReference(ast.StaticInvocation node) {
    // Get rid of the artificial `this` argument for extension methods.
    final int argumentStart;
    if (node.target.isExtensionMember || node.target.isExtensionTypeMember) {
      argumentStart = 1;
    } else {
      argumentStart = 0;
    }

    final positionalArguments = node.arguments.positional
        .skip(argumentStart)
        .mapIndexed((i, argument) => MapEntry(i, _evaluateLiteral(argument)));
    final namedArguments = node.arguments.named.map(
      (argument) => MapEntry(argument.name, _evaluateLiteral(argument.value)),
    );

    // Group by the evaluated literal - if it exists, the argument was const.
    final positionalGrouped = _groupByNull(positionalArguments);
    final namedGrouped = _groupByNull(namedArguments);

    return CallReference(
      location: node.location!.recordLocation(_source),
      loadingUnit: loadingUnitForNode(node, _loadingUnits).toString(),
      arguments: Arguments(
        constArguments: ConstArguments(
          positional: positionalGrouped[false] != null
              ? Map.fromEntries(positionalGrouped[false]!
                  .map((e) => MapEntry(e.key, e.value!)))
              : null,
          named: namedGrouped[false] != null
              ? Map.fromEntries(
                  namedGrouped[false]!.map((e) => MapEntry(e.key, e.value!)))
              : null,
        ),
        nonConstArguments: NonConstArguments(
          positional: positionalGrouped[true]?.map((e) => e.key).toList(),
          named: namedGrouped[true]?.map((e) => e.key).toList(),
        ),
      ),
    );
  }

  Map<bool, List<MapEntry<T, Constant?>>> _groupByNull<T>(
          Iterable<MapEntry<T, Constant?>> arguments) =>
      groupBy(arguments, (entry) => entry.value == null);

  Constant? _evaluateLiteral(ast.Expression expression) {
    if (expression is ast.BasicLiteral) {
      return evaluateLiteral(expression);
    } else if (expression is ast.ConstantExpression) {
      return evaluateConstant(expression.constant);
    } else {
      return null;
    }
  }

  Definition _definitionFromMember(ast.Member target) {
    final enclosingLibrary = target.enclosingLibrary;
    String file = getImportUri(enclosingLibrary, _source);

    return Definition(
      identifier: Identifier(
        importUri: file,
        parent: target.enclosingClass?.name,
        name: target.name.text,
      ),
      location: target.location!.recordLocation(_source),
      loadingUnit:
          loadingUnitForNode(enclosingLibrary, _loadingUnits).toString(),
    );
  }
}
