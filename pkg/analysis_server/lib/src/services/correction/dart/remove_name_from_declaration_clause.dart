// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveNameFromDeclarationClause extends CorrectionProducer {
  String _fixMessage = '';

  @override
  List<Object> get fixArguments => [_fixMessage];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var type = node.parent;
    if (type == null) {
      return;
    }
    var clause = type.parent;

    // TODO(srawlins): Handle ExtendsClause from various diagnostics.

    if (clause == null) {
      return;
    }

    NodeList<NamedType> nameList;
    String clauseName;
    if (clause is ImplementsClause) {
      clauseName = 'implements';
      nameList = clause.interfaces;
    } else if (clause is OnClause) {
      clauseName = 'on';
      nameList = clause.superclassConstraints;
    } else if (clause is WithClause) {
      clauseName = 'with';
      nameList = clause.mixinTypes;
    } else {
      return;
    }

    if (nameList.length == 1) {
      // Delete the whole clause.
      _fixMessage = "Remove '$clauseName' clause";
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.deletionRange(clause));
      });
    } else {
      _fixMessage = "Remove name from '$clauseName' clause";
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.nodeInList(nameList, type));
      });
    }
  }
}
