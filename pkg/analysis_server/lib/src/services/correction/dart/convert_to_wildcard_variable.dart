// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToWildcardVariable extends ResolvedCorrectionProducer {
  @override
  final CorrectionApplicability applicability;

  @override
  final FixKind? multiFixKind;

  ConvertToWildcardVariable({required super.context})
    : multiFixKind = null,
      applicability = .singleLocation;

  ConvertToWildcardVariable.automatically({required super.context})
    : multiFixKind = DartFixKind.convertToWildcardVariableMulti,
      applicability = .automatically;

  @override
  FixKind get fixKind => DartFixKind.convertToWildcardVariable;

  bool get wildcardVariablesEnabled =>
      libraryElement2.featureSet.isEnabled(Feature.wildcard_variables);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!wildcardVariablesEnabled) return;

    var node = this.node;

    if (node is FormalParameter) {
      await computeVariableConversion(builder, node.name!);
      return;
    }

    if (node is DeclaredVariablePatternImpl &&
        node.fieldNameWithImplicitName == null) {
      await computeVariableConversion(builder, node.name);
      return;
    }

    if (node is! VariableDeclaration) return;

    var nameToken = node.name;
    var element = node.declaredFragment?.element;
    if (element is! LocalVariableElement) {
      return;
    }

    List<AstNode>? references;
    var root = node.thisOrAncestorOfType<Block>();
    if (root != null) {
      references = findLocalElementReferences(root, element);
    }
    if (references == null) return;

    // Only assigned variable patterns can be safely converted to wildcards.
    if (references.any((r) => r is! AssignedVariablePattern)) return;

    var sourceRanges = {range.token(nameToken), ...references.map(range.node)};
    await builder.addDartFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addSimpleReplacement(sourceRange, '_');
      }
    });
  }

  Future<void> computeVariableConversion(
    ChangeBuilder builder,
    Token name,
  ) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(name), '_');
    });
  }
}
