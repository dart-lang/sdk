// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/utilities/extensions/map.dart';
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
    switch (type) {
      case RecordType():
        await computeRecordPattern(type, node, builder);
      case InterfaceType():
        await computeObjectPattern(type, node, builder);
    }
  }

  Future<void> computeObjectPattern(InterfaceType type,
      VariableDeclaration node, ChangeBuilder builder) async {
    // todo(pq): share reference checking w/ record computation

    var variableElement = node.declaredElement;
    if (variableElement is! LocalVariableElement) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    var (:objectReferences, :propertyReferences) =
        variableElement.findReferencesIn(function);
    if (objectReferences.isNotEmpty) return;

    var scopedNameFinder = ScopedNameFinder(node.offset);
    node.accept(scopedNameFinder);
    var namesInScope = <String>{};
    namesInScope.addAll(scopedNameFinder.locals);

    var varMap = <ObjectFieldName, List<AstNode>>{};

    for (var propertyReference in propertyReferences.entries) {
      var excludes = utils.findPossibleLocalVariableConflicts(node.offset);
      excludes.addAll(namesInScope);

      var references = propertyReference.value;
      for (var reference in references) {
        if (reference.inSetterContext) return;
        excludes
            .addAll(utils.findPossibleLocalVariableConflicts(reference.offset));
      }

      var fieldName = ObjectFieldName.forName(propertyReference.key, excludes);
      if (fieldName == null) return;

      varMap[fieldName] = references;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.entity(node.name), (builder) {
        builder.write('${type.element.name}(');
        if (varMap.isEmpty) {
          builder.selectHere();
        } else {
          for (var (i, entry) in varMap.entries.indexed) {
            if (i > 0) {
              builder.write(', ');
            }
            var fieldName = entry.key;
            fieldName.write(builder);
          }
        }
        builder.write(')');
      });

      for (var entry in varMap.entries) {
        var varName = entry.key.varName;
        var references = entry.value;
        for (var reference in references) {
          builder.addReplacement(range.entity(reference), (builder) {
            builder.addLinkedEdit(varName, (builder) {
              builder.write(varName);
            });
          });
        }
      }
    });
  }

  Future<void> computeRecordPattern(
      RecordType type, VariableDeclaration node, ChangeBuilder builder) async {
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

class ObjectFieldName {
  final String varName;
  final String fieldName;
  ObjectFieldName._(this.varName, this.fieldName);

  bool get isDefault => varName == fieldName;

  void write(EditBuilder builder) {
    var suggestions = <String>[];
    if (isDefault) {
      builder.write(':');
    } else {
      builder.write('$fieldName: ');
    }
    suggestions.add(varName);
    builder.addSimpleLinkedEdit(varName, varName,
        kind: LinkedEditSuggestionKind.VARIABLE, suggestions: suggestions);
  }

  static ObjectFieldName? forName(String name, Set<String> excludes) {
    var suggestions = getVariableNameSuggestionsForText(name, excludes);
    var suggestion = suggestions.firstOrNull;
    if (suggestion == null) return null;
    return ObjectFieldName._(suggestion, name);
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

class _ReferenceFinder extends RecursiveAstVisitor<void> {
  final objectReferences = <AstNode>[];
  final propertyReferences = <String, List<AstNode>>{};

  final VariableElement? element;
  _ReferenceFinder(this.element);

  ({
    List<AstNode> objectReferences,
    Map<String, List<AstNode>> propertyReferences
  }) findReferences(FunctionBody target) {
    target.accept(this);
    return (
      objectReferences: objectReferences,
      propertyReferences: propertyReferences
    );
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == element) {
      var parent = node.parent;
      switch (parent) {
        case PrefixedIdentifier(:var identifier):
          propertyReferences.add(identifier.name, parent);
        case PropertyAccess(:var propertyName):
          propertyReferences.add(propertyName.name, parent);
        case _:
          objectReferences.add(node);
      }
    }
    super.visitSimpleIdentifier(node);
  }
}

extension on VariableElement {
  ({
    List<AstNode> objectReferences,
    Map<String, List<AstNode>> propertyReferences
  }) findReferencesIn(FunctionBody target) =>
      _ReferenceFinder(this).findReferences(target);
}

extension on AstNode {
  bool get inSetterContext {
    var node = this;
    if (node is PrefixedIdentifier) node = node.identifier;
    if (node is PropertyAccess) node = node.propertyName;
    return (node is SimpleIdentifier) ? node.inSetterContext() : false;
  }
}
