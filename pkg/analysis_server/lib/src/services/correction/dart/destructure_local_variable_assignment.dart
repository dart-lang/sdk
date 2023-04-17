// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class DestructureLocalVariableAssignment extends CorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.DESTRUCTURE_LOCAL_VARIABLE_ASSIGNMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! VariableDeclaration) return;
    var element = node.declaredElement;
    if (element == null) return;
    var type = element.type;
    if (type is! RecordType) return;

    var excluded = <String>{};
    var offset = node.offset;

    var scopedNameFinder = ScopedNameFinder(offset);
    node.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals);

    var variables = <RecordField>[];
    for (var i = 1; i <= type.positionalFields.length; ++i) {
      var varName = '\$$i';
      if (excluded.contains(varName)) {
        varName = getIndexedVariableName(i, excluded) ?? varName;
      }
      variables.add(PositionalField(varName));
      excluded.add(varName);
    }

    for (var namedField in type.namedFields) {
      var name = namedField.name;
      if (!excluded.contains(name)) {
        variables.add(NamedField(field: name));
      } else {
        var suggestions = getVariableNameSuggestionsForText(name, excluded);
        if (suggestions.isEmpty) return;
        var suggestion = suggestions.first;
        variables.add(NamedField(field: name, variable: suggestion));
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.entity(node.name), (builder) {
        builder.write('(');
        for (var (i, variable) in variables.indexed) {
          if (i > 0) {
            builder.write(', ');
          }
          variable.write(builder, 'VAR_$i');
        }
        builder.write(')');
      });
    });
  }

  static String? getIndexedVariableName(int index, Set<String> excluded) {
    for (var c = 97 /* a */; c < 0x7A; ++c) {
      var name = '\$$index${String.fromCharCode(c)}';
      if (!excluded.contains(name)) return name;
    }
    return null;
  }
}

class NamedField extends RecordField {
  final String field;
  final String? variable;
  NamedField({required this.field, this.variable});

  @override
  void write(EditBuilder builder, String groupName) {
    var variable = this.variable;
    var suggestions = <String>[];
    if (variable == null) {
      variable = ':$field';
      suggestions.add('$field: $wildCard');
    } else {
      builder.write('$field: ');
      suggestions.add(wildCard);
    }
    // Make sure the variable proposal is first.
    suggestions.insert(0, variable);
    builder.addSimpleLinkedEdit(groupName, variable,
        kind: LinkedEditSuggestionKind.VARIABLE, suggestions: suggestions);
  }
}

class PositionalField extends RecordField {
  final String variable;
  PositionalField(this.variable);

  @override
  void write(EditBuilder builder, String groupName) {
    builder.addSimpleLinkedEdit(groupName, variable,
        kind: LinkedEditSuggestionKind.VARIABLE,
        suggestions: [variable, wildCard]);
  }
}

abstract class RecordField {
  final wildCard = '_';
  void write(EditBuilder builder, String groupName);
}
