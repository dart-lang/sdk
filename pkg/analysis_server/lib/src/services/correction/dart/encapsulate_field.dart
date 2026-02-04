// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class EncapsulateField extends ResolvedCorrectionProducer {
  EncapsulateField({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.encapsulateField;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // find FieldDeclaration
    var fieldDeclaration = node.thisOrAncestorOfType<FieldDeclaration>();
    if (fieldDeclaration == null) {
      return;
    }
    // not interesting for static
    if (fieldDeclaration.isStatic) {
      return;
    }
    // has a parse error
    var variableList = fieldDeclaration.fields;
    if (variableList.keyword == null && variableList.type == null) {
      return;
    }
    // should have exactly one field
    var fields = variableList.variables;
    if (fields.length != 1) {
      return;
    }
    var field = fields.first;
    var nameToken = field.name;
    var fieldFragment = field.declaredFragment as FieldFragment;
    var fieldElement = fieldFragment.element;
    // should have a public name
    var name = nameToken.lexeme;
    if (Identifier.isPrivateName(name)) {
      return;
    }
    // should be on the name
    if (nameToken != token) {
      return;
    }

    // Should be in a class or mixin.
    List<ClassMember> classMembers;
    InterfaceElement parentElement;
    var parent = fieldDeclaration.parent?.parent;
    switch (parent) {
      case ClassDeclaration():
        classMembers = parent.members2;
        parentElement = parent.declaredFragment!.element;
      case MixinDeclaration():
        classMembers = parent.body.members;
        parentElement = parent.declaredFragment!.element;
      default:
        return;
    }

    await builder.addDartFileEdit(file, (builder) {
      // Remove all annotations from the field.
      var metadata = fieldDeclaration.metadata;
      if (metadata.isNotEmpty) {
        var nodeRange = range.startEnd(metadata.first, metadata.last);
        var linesRange = utils.getLinesRange(nodeRange);
        builder.addDeletion(linesRange);
      }
      // rename field
      builder.addSimpleReplacement(range.token(nameToken), '_$name');
      // Write setter.
      if (variableList.finalKeyword case var finalKeyword?) {
        builder.addSimpleReplacement(
          range.startStart(
            finalKeyword,
            variableList.type ?? variableList.variables.first,
          ),
          '',
        );
      }

      String fieldTypeCode;
      var type = fieldDeclaration.fields.type;
      if (type == null) {
        fieldTypeCode = '';
      } else {
        fieldTypeCode = utils.getNodeText(type);
      }
      _updateReferencesInConstructors(
        builder,
        classMembers,
        fieldElement,
        name,
        fieldTypeCode,
      );

      // Write getter and setter.
      builder.addInsertion(fieldDeclaration.end, (builder) {
        String? docCode;
        var documentationComment = fieldDeclaration.documentationComment;
        if (documentationComment != null) {
          docCode = utils.getNodeText(documentationComment);
        }

        var typeCode = '';
        var typeAnnotation = variableList.type;
        if (typeAnnotation != null) {
          typeCode = '${utils.getNodeText(typeAnnotation)} ';
        }

        void writeHeader(bool preserveOverride) {
          builder.writeln();
          builder.writeln();
          if (docCode != null) {
            builder.write('  ');
            builder.writeln(docCode);
          }

          for (var annotation in metadata) {
            var elementAnnotation = annotation.elementAnnotation;
            if (elementAnnotation == null ||
                !elementAnnotation.isOverride ||
                preserveOverride) {
              var nodeRange = range.node(annotation);
              var rangeText = utils.getRangeText(nodeRange);
              builder.writeln('  $rangeText');
            }
          }
        }

        // Write getter.
        var overriddenGetters = parentElement.getOverridden(Name(null, name));
        writeHeader(overriddenGetters != null);
        builder.write('  ${typeCode}get $name => _$name;');

        // Write setter.
        if (variableList.isFinal) {
          return;
        }
        var overriddenSetters = parentElement.getOverridden(
          Name(null, '$name='),
        );
        writeHeader(overriddenSetters != null);
        builder.writeln('  set $name(${typeCode}value) {');
        builder.writeln('    _$name = value;');
        builder.write('  }');
      });
    });
  }

  void _updateReferencesInConstructor(
    DartFileEditBuilder builder,
    ConstructorDeclaration constructor,
    FieldElement fieldElement,
    String name,
    String fieldTypeCode,
  ) {
    // Update any field formal parameter that refers to the field.
    for (var parameter in constructor.parameters.parameters) {
      var identifier = parameter.name;
      if (identifier == null) continue;

      var parameterElement = parameter.declaredFragment?.element;
      // TODO(rnystrom): Also include declaring parameters here.
      if (parameterElement is! FieldFormalParameterElement) continue;
      if (parameterElement.field != fieldElement) continue;

      // If the parameter is named and we're in a library that doesn't allow
      // private named parameters, then keep the public name for the parameter
      // and initialize the field from it in the initializer list.
      if (parameter.isNamed && !isEnabled(Feature.private_named_parameters)) {
        var normalParam = parameter.notDefault;
        if (normalParam is FieldFormalParameter) {
          var start = normalParam.thisKeyword;
          builder.addSimpleReplacement(
            range.startEnd(start, normalParam.period),
            fieldTypeCode.isNotEmpty ? '$fieldTypeCode ' : '',
          );

          var previous = constructor.separator ?? constructor.parameters;
          var replacement = constructor.initializers.isEmpty
              ? ' : _$name = $name'
              : ' _$name = $name,';
          builder.addSimpleInsertion(previous.end, replacement);
        }
      } else {
        // Rename the parameter.
        builder.addSimpleReplacement(range.token(identifier), '_$name');
      }
    }

    // If the field already has an explicit initializer, update its name.
    for (var initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer &&
          initializer.fieldName.element == fieldElement) {
        builder.addSimpleReplacement(
          range.node(initializer.fieldName),
          '_$name',
        );
      }
    }
  }

  void _updateReferencesInConstructors(
    DartFileEditBuilder builder,
    List<ClassMember> classMembers,
    FieldElement fieldElement,
    String name,
    String fieldTypeCode,
  ) {
    for (var constructor in classMembers) {
      if (constructor is ConstructorDeclaration) {
        _updateReferencesInConstructor(
          builder,
          constructor,
          fieldElement,
          name,
          fieldTypeCode,
        );
      }
    }
  }
}
