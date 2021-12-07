// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeArgumentName extends MultiCorrectionProducer {
  /// The maximum Levenshtein distance between the existing name and a possible
  /// replacement before the replacement is deemed to not be worth offering.
  static const _maxDistance = 4;

  @override
  Stream<CorrectionProducer> get producers async* {
    var namedContext = _getNamedParameterNames();
    if (namedContext == null) {
      return;
    }

    var names = namedContext.names;
    if (names.isEmpty) {
      return;
    }

    var currentNameNode = namedContext.identifier;
    var currentName = currentNameNode.name;

    for (var proposedName in names) {
      var distance = _computeDistance(currentName, proposedName);
      if (distance <= _maxDistance) {
        // TODO(brianwilkerson) Create a way to use the distance as part of the
        //  computation of the priority (so that closer names sort first).
        yield _ChangeName(currentNameNode, proposedName);
      }
    }
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

  _NamedExpressionContext? _getNamedParameterNames() {
    final node = this.node;
    var namedExpression = node.parent?.parent;
    if (node is SimpleIdentifier &&
        namedExpression is NamedExpression &&
        namedExpression.name == node.parent) {
      var argumentList = namedExpression.parent;
      if (argumentList is ArgumentList) {
        var parameters = ExecutableParameters.forInvocation(
            sessionHelper, argumentList.parent);
        if (parameters != null) {
          return _NamedExpressionContext(node, parameters.namedNames);
        }
      }
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ChangeArgumentName newInstance() => ChangeArgumentName();
}

/// A correction processor that can make one of the possible change computed by
/// the [ChangeArgumentName] producer.
class _ChangeName extends CorrectionProducer {
  /// The name of the argument being changed.
  final SimpleIdentifier _argumentName;

  /// The name to which the argument name will be changed.
  final String _proposedName;

  _ChangeName(this._argumentName, this._proposedName);

  @override
  List<Object> get fixArguments => [_proposedName];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_ARGUMENT_NAME;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(_argumentName), _proposedName);
    });
  }
}

class _NamedExpressionContext {
  final SimpleIdentifier identifier;
  final List<String> names;

  _NamedExpressionContext(this.identifier, this.names);
}
