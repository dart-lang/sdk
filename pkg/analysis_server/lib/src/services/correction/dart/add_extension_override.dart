// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddExtensionOverride extends MultiCorrectionProducer {
  AddExtensionOverride({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var node = this.node;
    if (node is! SimpleIdentifier) return const [];
    var parent = node.parent;
    if (parent is! PropertyAccess) return const [];
    var target = parent.target;
    if (target == null) return const [];
    var dartFixContext = context.dartFixContext;
    if (dartFixContext == null) return const [];

    var libraryFragment = dartFixContext.resolvedResult.unit.declaredElement!;
    var libraryElement = libraryFragment.library;

    var nodeName = Name(libraryElement.source.uri, node.name);
    var extensions = libraryFragment.accessibleExtensions
        .havingMemberWithBaseName(nodeName);
    var producers = <ResolvedCorrectionProducer>[];
    for (var extension in extensions) {
      var name = extension.extension.name;
      if (name != null) {
        producers.add(_AddOverride(target, name, context: context));
      }
    }
    return producers;
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddExtensionOverride] producer.
class _AddOverride extends ResolvedCorrectionProducer {
  /// The expression around which to add the override.
  final Expression _expression;

  /// The extension name to be inserted.
  final String _name;

  _AddOverride(this._expression, this._name, {required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [_name];

  @override
  FixKind get fixKind => DartFixKind.ADD_EXTENSION_OVERRIDE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var needsParentheses = _expression is! ParenthesizedExpression;
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(_expression.offset, (builder) {
        builder.write(_name);
        if (needsParentheses) {
          builder.write('(');
        }
      });
      if (needsParentheses) {
        builder.addSimpleInsertion(_expression.end, ')');
      }
    });
  }
}
