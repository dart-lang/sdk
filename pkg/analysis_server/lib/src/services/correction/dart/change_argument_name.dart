// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeArgumentName extends MultiCorrectionProducer {
  /// The maximum Levenshtein distance between the existing name and a possible
  /// replacement before the replacement is deemed to not be worth offering.
  static const _maxDistance = 4;

  ChangeArgumentName({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var namedContext = _getNamedParameterNames();
    if (namedContext == null) {
      return const [];
    }

    var names = namedContext.names;
    if (names.isEmpty) {
      return const [];
    }

    var currentNameNode = namedContext.nameToken;
    var currentName = currentNameNode.lexeme;

    var producers = <ResolvedCorrectionProducer>[];
    for (var proposedName in names) {
      var distance = _computeDistance(currentName, proposedName);
      if (distance <= _maxDistance) {
        // TODO(brianwilkerson): Create a way to use the distance as part of the
        //  computation of the priority (so that closer names sort first).
        producers.add(
          _ChangeName(currentNameNode, proposedName, context: context),
        );
      }
    }
    return producers;
  }

  int _computeDistance(String current, String proposal) {
    if ((current == 'child' && proposal == 'children') ||
        (current == 'children' && proposal == 'child')) {
      // Special case handling for 'child' and 'children' is unnecessary if
      // `maxDistance >= 3`, but is included to prevent regression in case the
      // value is changed to improve results.
      return 1;
    }
    return levenshtein(current, proposal, _maxDistance, caseSensitive: false);
  }

  _NamedArgumentContext? _getNamedParameterNames() {
    var node = this.node;
    NamedArgument? namedArgument;
    if (node is NamedArgument) {
      namedArgument = node;
    } else if (node.parent case NamedArgument parent) {
      namedArgument = parent;
    }
    if (namedArgument != null) {
      var argumentList = namedArgument.parent;
      if (argumentList is ArgumentList) {
        var parameters = ExecutableParameters.forInvocation(
          sessionHelper,
          argumentList.parent,
        );
        if (parameters != null) {
          return _NamedArgumentContext(
            namedArgument.name,
            parameters.namedNames,
          );
        }
      }
    }
    return null;
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [ChangeArgumentName] producer.
class _ChangeName extends ResolvedCorrectionProducer {
  /// The name of the argument being changed.
  final Token _argumentName;

  /// The name to which the argument name will be changed.
  final String _proposedName;

  _ChangeName(this._argumentName, this._proposedName, {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_proposedName];

  @override
  FixKind get fixKind => DartFixKind.changeArgumentName;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(_argumentName), _proposedName);
    });
  }
}

class _NamedArgumentContext {
  final Token nameToken;
  final List<String> names;

  _NamedArgumentContext(this.nameToken, this.names);
}
