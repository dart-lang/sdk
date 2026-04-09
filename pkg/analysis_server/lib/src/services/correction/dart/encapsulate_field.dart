// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Information about the declaration of a field, whether it be an
/// explicit field declaration or a declaring parameter.
typedef _DeclarationInfo = ({
  bool isFinal,
  Comment? documentationComment,
  CompilationUnitMember interfaceDeclaration,
  FieldDeclaration? fieldDeclaration,
  FieldElement fieldElement,
  NodeList<Annotation>? metadata,
  Token nameToken,
  TypeAnnotation? type,
});

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
    var fieldInfo = _findFieldDeclaration() ?? _findDeclaringParameter();
    if (fieldInfo == null) {
      return;
    }

    var (
      :nameToken,
      :fieldDeclaration,
      :fieldElement,
      :metadata,
      :interfaceDeclaration,
      :isFinal,
      :type,
      :documentationComment,
    ) = fieldInfo;

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
    ClassNamePart? namePart;
    switch (interfaceDeclaration) {
      case ClassDeclaration():
        classMembers = interfaceDeclaration.body.members;
        parentElement = interfaceDeclaration.declaredFragment!.element;
        namePart = interfaceDeclaration.namePart;
      case MixinDeclaration():
        classMembers = interfaceDeclaration.body.members;
        parentElement = interfaceDeclaration.declaredFragment!.element;
      default:
        return;
    }

    await builder.addDartFileEdit(file, (builder) {
      // Update the field declaration if there is one (if this is a declaring
      // parameter, there will not be).
      if (fieldDeclaration != null) {
        _updateFieldDeclaration(builder, fieldDeclaration, nameToken, name);
      }

      _updateReferencesInConstructors(
        builder,
        classMembers,
        fieldElement,
        name,
        namePart,
        type,
      );

      // Write getter and setter.
      builder.insertIntoUnitMember(
        interfaceDeclaration,
        lastMemberFilter: fieldDeclaration != null
            ? (existingMember) => existingMember == fieldDeclaration
            : null,
        // Suppress indenting, because it's handled in writeHeader() which
        // we call multiple times and therefore must be consistent.
        indent: false,
        (builder) {
          String? docCode;
          if (documentationComment != null) {
            docCode = utils.getNodeText(documentationComment);
          }

          void writeHeader(bool preserveOverride) {
            if (docCode != null) {
              builder
                ..writeIndent()
                ..writeln(docCode);
            }

            if (metadata != null) {
              for (var annotation in metadata) {
                var elementAnnotation = annotation.elementAnnotation;
                if (elementAnnotation == null ||
                    !elementAnnotation.isOverride ||
                    preserveOverride) {
                  var nodeRange = range.node(annotation);
                  var rangeText = utils.getRangeText(nodeRange);
                  builder
                    ..writeIndent()
                    ..writeln(rangeText);
                }
              }
            }
          }

          // Write getter.
          var overriddenGetters = parentElement.getOverridden(Name(null, name));
          writeHeader(overriddenGetters != null);
          builder
            ..writeIndent()
            ..writeGetterDeclaration(
              name,
              returnType: type?.type,
              bodyWriter: () => builder.write('=> _$name;'),
            );

          // Write setter.
          if (isFinal) {
            return;
          }
          var overriddenSetters = parentElement.getOverridden(
            Name(null, '$name='),
          );
          builder
            ..writeln()
            ..writeln();
          writeHeader(overriddenSetters != null);
          builder
            ..writeIndent()
            ..writeSetterDeclaration(
              name,
              parameterName: 'value',
              parameterType: type?.type,
              bodyWriter: () {
                builder
                  ..writeln('{')
                  ..writeIndent(2)
                  ..writeln('_$name = value;')
                  ..writeIndent()
                  ..write('}');
              },
            );
        },
      );
    });
  }

  /// Finds information about a declaring parameter that declares the field at
  /// [node].
  _DeclarationInfo? _findDeclaringParameter() {
    var parameterDeclaration = node
        .thisOrAncestorOfType<SimpleFormalParameterImpl>();
    if (parameterDeclaration == null) {
      return null;
    }

    var nameToken = parameterDeclaration.name;
    if (nameToken == null) {
      return null;
    }

    var parent = parameterDeclaration
        .thisOrAncestorOfType<PrimaryConstructorDeclaration>()
        ?.parent;
    if (parent is! CompilationUnitMember) {
      return null;
    }

    var fieldFragment = parameterDeclaration.declaredFragment;
    if (fieldFragment is! FieldFormalParameterFragmentImpl) {
      return null;
    }

    var fieldElement = fieldFragment.element.field;
    if (fieldElement == null) {
      return null;
    }

    return (
      documentationComment: null,
      fieldDeclaration: null,
      fieldElement: fieldElement,
      interfaceDeclaration: parent,
      isFinal: parameterDeclaration.isFinal,
      metadata: null,
      nameToken: nameToken,
      type: parameterDeclaration.type,
    );
  }

  /// Finds information about the declaration declaring the field at [node].
  _DeclarationInfo? _findFieldDeclaration() {
    var fieldDeclaration = node.thisOrAncestorOfType<FieldDeclaration>();
    if (fieldDeclaration == null) {
      return null;
    }

    // not interesting for static
    if (fieldDeclaration.isStatic) {
      return null;
    }
    // has a parse error
    var variableList = fieldDeclaration.fields;
    if (variableList.keyword == null && variableList.type == null) {
      return null;
    }
    // should have exactly one field
    var fields = variableList.variables;
    if (fields.length != 1) {
      return null;
    }
    var field = fields.single;

    var parent = fieldDeclaration.parent?.parent;
    if (parent is! CompilationUnitMember) {
      return null;
    }

    var fieldFragment = field.declaredFragment;
    if (fieldFragment is! FieldFragment) {
      return null;
    }

    return (
      nameToken: field.name,
      fieldDeclaration: fieldDeclaration,
      fieldElement: fieldFragment.element,
      metadata: fieldDeclaration.metadata,
      interfaceDeclaration: parent,
      isFinal: variableList.isFinal,
      type: variableList.type,
      documentationComment: fieldDeclaration.documentationComment,
    );
  }

  /// Updates a field declaration, removing any `final` keyword and adding a
  /// leading underscore to the name to make it private.
  void _updateFieldDeclaration(
    DartFileEditBuilder builder,
    FieldDeclaration fieldDeclaration,
    Token nameToken,
    String name,
  ) {
    var variableList = fieldDeclaration.fields;

    // Remove all annotations from the field.
    var metadata = fieldDeclaration.metadata;
    if (metadata.isNotEmpty) {
      var nodeRange = range.startEnd(metadata.first, metadata.last);
      var linesRange = utils.getLinesRange(nodeRange);
      builder.addDeletion(linesRange);
    }
    // rename field
    builder.addSimpleReplacement(range.token(nameToken), '_$name');
    // Remove final keyword from the declaration.
    if (variableList.finalKeyword case var finalKeyword?) {
      builder.addSimpleReplacement(
        range.startStart(finalKeyword, finalKeyword.next!),
        '',
      );
    }
  }

  void _updateReferencesInConstructor(
    DartFileEditBuilder builder,
    FieldElement fieldElement,
    String name,
    TypeAnnotation? type, {
    required FormalParameterList parameters,
    required Token? separator,
    required NodeList<ConstructorInitializer>? initializers,
  }) {
    // Update any field formal parameter that refers to the field.
    for (var parameter in parameters.parameters) {
      var identifier = parameter.name;
      if (identifier == null) continue;

      var parameterElement = parameter.declaredFragment?.element;
      if (parameterElement is! FieldFormalParameterElement) continue;
      if (parameterElement.field != fieldElement) continue;

      // If the parameter is named and we're in a library that doesn't allow
      // private named parameters, then keep the public name for the parameter
      // and initialize the field from it in the initializer list.
      if (parameter.isNamed && !isEnabled(Feature.private_named_parameters)) {
        var normalParam = parameter.notDefault;
        if (normalParam is FieldFormalParameter) {
          var start = normalParam.thisKeyword;
          builder.addReplacement(range.startEnd(start, normalParam.period), (
            builder,
          ) {
            if (type != null) {
              builder
                ..writeType(type.type)
                ..write(' ');
            }
          });

          var previous = separator ?? parameters;
          var replacement = initializers != null && initializers.isEmpty
              ? ' : _$name = $name'
              : ' _$name = $name,';
          builder.addSimpleInsertion(previous.end, replacement);
        }
      } else {
        // Rename the parameter.
        builder.addSimpleReplacement(range.token(identifier), '_$name');
      }

      // Change `final` to `var` in declaring parameters.
      if (parameter.notDefault case SimpleFormalParameterImpl(
        finalOrVarKeyword: var finalKeyword?,
        isFinal: true,
      )) {
        builder.addSimpleReplacement(range.token(finalKeyword), 'var');
      }
    }

    // If the field already has an explicit initializer, update its name.
    if (initializers != null) {
      for (var initializer in initializers) {
        if (initializer is ConstructorFieldInitializer &&
            initializer.fieldName.element == fieldElement) {
          builder.addSimpleReplacement(
            range.node(initializer.fieldName),
            '_$name',
          );
        }
      }
    }
  }

  void _updateReferencesInConstructors(
    DartFileEditBuilder builder,
    List<ClassMember> classMembers,
    FieldElement fieldElement,
    String name,
    ClassNamePart? namePart,
    TypeAnnotation? type,
  ) {
    // Handle primary constructors as this field might come from a declaring
    // parameter.
    if (namePart is PrimaryConstructorDeclaration) {
      _updateReferencesInConstructor(
        builder,
        fieldElement,
        name,
        type,
        parameters: namePart.formalParameters,
        separator: namePart.body?.colon,
        initializers: namePart.body?.initializers,
      );
    }

    for (var constructor in classMembers) {
      if (constructor is ConstructorDeclaration) {
        _updateReferencesInConstructor(
          builder,
          fieldElement,
          name,
          type,
          parameters: constructor.parameters,
          separator: constructor.separator,
          initializers: constructor.initializers,
        );
      }
    }
  }
}
