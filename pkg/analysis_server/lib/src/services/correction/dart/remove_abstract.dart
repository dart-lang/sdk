// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveAbstract extends CorrectionProducerWithDiagnostic {
  @override
  final CorrectionApplicability applicability;

  /// Initialize a newly created instance that can't apply bulk and in-file
  /// fixes.
  RemoveAbstract({required super.context})
    : applicability = CorrectionApplicability.singleLocation;

  /// Initialize a newly created instance that can apply bulk and in-file fixes.
  RemoveAbstract.bulkFixable({required super.context})
    : applicability = CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeAbstract;

  @override
  FixKind get multiFixKind => DartFixKind.removeAbstractMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    var parent = node.parent;
    var classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (node is VariableDeclaration) {
      var fieldElement = node.declaredFragment?.element;
      await _compute(classDeclaration, fieldElement, builder);
    } else if (node is SimpleIdentifier &&
        parent is ConstructorFieldInitializer) {
      await _compute(classDeclaration, node.element, builder);
    } else if (node is CompilationUnitMember) {
      await _computeAbstractClassMember(builder);
    }
  }

  Future<void> _compute(
    ClassDeclaration? classDeclaration,
    Element? fieldElement,
    ChangeBuilder builder,
  ) async {
    if (classDeclaration == null) return;

    for (var member in classDeclaration.members) {
      if (member is FieldDeclaration) {
        var fields = member.fields;
        var variables = fields.variables;
        if (variables.length > 1 &&
            fields.type?.type?.nullabilitySuffix !=
                NullabilitySuffix.question) {
          continue;
        }
        for (var variable in variables) {
          if (variable.declaredFragment?.element == fieldElement) {
            var abstractKeyword = member.abstractKeyword;
            if (abstractKeyword != null) {
              await builder.addDartFileEdit(file, (builder) {
                builder.addDeletion(
                  range.startOffsetEndOffset(
                    abstractKeyword.offset,
                    abstractKeyword.next!.offset,
                  ),
                );
              });
            }
            break;
          }
        }
      }
    }
  }

  Future<void> _computeAbstractClassMember(ChangeBuilder builder) async {
    // 'abstract' keyword does not exist in AST
    var offset = diagnostic.problemMessage.offset;
    var content = unitResult.content;
    var i = offset + 'abstract '.length;
    while (content[i].trim().isEmpty) {
      i++;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(offset, i - offset));
    });
  }
}
