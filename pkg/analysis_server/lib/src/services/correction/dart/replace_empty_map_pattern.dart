// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceEmptyMapPattern extends ResolvedCorrectionProducer {
  final _Style _style;

  /// Initializes a newly created correction producer to create an object
  /// pattern that will match any map.
  ReplaceEmptyMapPattern.any({required super.context}) : _style = _Style.any;

  /// Initializes a newly created correction producer to create an object
  /// pattern that will match an empty map.
  ReplaceEmptyMapPattern.empty({required super.context})
    : _style = _Style.empty;

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => _style.fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    if (targetNode is MapPattern) {
      var typeArguments = targetNode.typeArguments;
      if (typeArguments == null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.node(targetNode), replacement(''));
        });
      } else {
        var text = utils.getNodeText(typeArguments);
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(
            range.node(targetNode),
            replacement(text),
          );
        });
      }
    }
  }

  /// Return the replacement for the map pattern.
  String replacement(String typeArguments) =>
      _style == _Style.any
          ? 'Map$typeArguments()'
          : 'Map$typeArguments(isEmpty: true)';
}

/// An indication of the style of replacement being offered.
enum _Style {
  any(DartFixKind.MATCH_ANY_MAP),
  empty(DartFixKind.MATCH_EMPTY_MAP);

  final FixKind fixKind;

  const _Style(this.fixKind);
}
