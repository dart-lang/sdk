// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveNameFromDeclarationClause extends ResolvedCorrectionProducer {
  String _fixMessage = '';

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_fixMessage];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var type = node;
    var clause = type.parent;

    if (clause == null) {
      return;
    }

    NodeList<NamedType> nameList;
    String clauseName;
    if (clause is ExtendsClause) {
      await _delete(builder, clause, 'extends');
      return;
    } else if (clause is ImplementsClause) {
      clauseName = 'implements';
      nameList = clause.interfaces;
    } else if (clause is MixinOnClause) {
      clauseName = 'on';
      nameList = clause.superclassConstraints;
    } else if (clause is WithClause) {
      clauseName = 'with';
      nameList = clause.mixinTypes;
    } else {
      return;
    }

    if (nameList.length == 1) {
      await _delete(builder, clause, clauseName);
    } else {
      _fixMessage = "Remove name from '$clauseName' clause";
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.nodeInList(nameList, type));
      });
    }
  }

  Future<void> _delete(
      ChangeBuilder builder, AstNode clause, String clauseName) async {
    _fixMessage = "Remove '$clauseName' clause";
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.deletionRange(clause));
    });
  }
}
