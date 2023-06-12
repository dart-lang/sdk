// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveAbstract extends CorrectionProducerWithDiagnostic {
  @override
  bool canBeAppliedInBulk;

  @override
  bool canBeAppliedToFile;

  /// Initialize a newly created instance that can't apply bulk and in-file
  /// fixes.
  RemoveAbstract()
      : canBeAppliedInBulk = false,
        canBeAppliedToFile = false;

  /// Initialize a newly created instance that can apply bulk and in-file fixes.
  RemoveAbstract.bulkFixable()
      : canBeAppliedInBulk = true,
        canBeAppliedToFile = true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_ABSTRACT;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_ABSTRACT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    final parent = node.parent;
    final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (node is VariableDeclaration) {
      await _compute(classDeclaration, node.declaredElement, builder);
    } else if (node is SimpleIdentifier &&
        parent is ConstructorFieldInitializer) {
      await _compute(classDeclaration, node.staticElement, builder);
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
          if (variable.declaredElement == fieldElement) {
            var abstractKeyword = member.abstractKeyword;
            if (abstractKeyword != null) {
              await builder.addDartFileEdit(file, (builder) {
                builder.addDeletion(range.startOffsetEndOffset(
                    abstractKeyword.offset, abstractKeyword.next!.offset));
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
