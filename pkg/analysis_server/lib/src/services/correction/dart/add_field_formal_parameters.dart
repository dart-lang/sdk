// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class AddFieldFormalParameters extends ResolvedCorrectionProducer {
  static final _charAfterUnderscore = RegExp('[^_]');

  static final _startsWithNumber = RegExp('^[0-9]');

  final _Style _style;

  @override
  final FixKind fixKind;

  AddFieldFormalParameters({required super.context})
    : _style = _Style.base,
      fixKind = DartFixKind.addInitializingFormalParameters;

  AddFieldFormalParameters.requiredNamed({required super.context})
    : _style = _Style.requiredNamed,
      fixKind = DartFixKind.addInitializingFormalNamedParameters;
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructor = node.parent;
    if (node is! SimpleIdentifier || constructor is! ConstructorDeclaration) {
      return;
    }
    List<FormalParameter> parameters = constructor.parameters.parameters;

    var instanceNodeDeclaration = constructor.parent;
    if (instanceNodeDeclaration is! NamedCompilationUnitMember ||
        instanceNodeDeclaration is TypeAlias ||
        instanceNodeDeclaration is FunctionDeclaration) {
      return;
    }

    // Compute uninitialized final fields.
    var fields = ErrorVerifier.computeNotInitializedFields(constructor)
        .where((field) => field.isFinal)
        .map((field) {
          var nameOffset = field.firstFragment.nameOffset;
          return nameOffset != null ? (field, nameOffset) : null;
        })
        .nonNulls
        .sortedBy((pair) => pair.$2)
        .map((pair) => pair.$1)
        .toList();

    if (fields.isEmpty) {
      assert(false, 'How can this trigger with no fields?');
      return;
    }

    // Prepare the last required parameter.
    FormalParameter? lastRequiredPositionalParameter;
    FormalParameter? firstNamedParameter;
    var containsOptionalPositional = false;
    for (var parameter in parameters) {
      if (parameter.isRequiredPositional) {
        lastRequiredPositionalParameter = parameter;
      } else if (parameter.isOptionalPositional) {
        if (_style == _Style.requiredNamed) {
          // If there are optional positional parameters, we can't add required
          // named parameters.
          return;
        } else {
          containsOptionalPositional = true;
        }
      } else if (parameter.isNamed) {
        firstNamedParameter = parameter;
        break;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      var insertOffset =
          (lastRequiredPositionalParameter ??
                  constructor.parameters.leftParenthesis)
              .end;
      var mappedFields = fields.map(
        (field) => (field, isRequired: _isFieldRequired(field)),
      );
      var initializer = <({String publicName, FieldElement field})>[];
      var addCurlyBraces =
          firstNamedParameter == null && _style == _Style.requiredNamed;
      var parametersAtCurly = getCodeStyleOptions(
        unitResult.file,
      ).requiredNamedParametersFirst;
      var curlyOpen = lastRequiredPositionalParameter == null ? '{' : ', {';
      if (addCurlyBraces && !parametersAtCurly) {
        builder.addSimpleInsertion(insertOffset, curlyOpen);
      }
      if (!addCurlyBraces && _style == _Style.requiredNamed) {
        if (parametersAtCurly) {
          insertOffset = firstNamedParameter!.offset;
        } else {
          insertOffset =
              parameters.lastOrNull?.end ??
              constructor.parameters.rightParenthesis.offset;
        }
      }
      if (parametersAtCurly) {
        mappedFields.sorted((r1, r2) {
          return r1.isRequired == r2.isRequired ? 0 : (r1.isRequired ? -1 : 1);
        });
      }
      var requiredFirst =
          firstNamedParameter != null &&
          firstNamedParameter.isRequiredNamed &&
          parametersAtCurly;
      builder.addInsertion(insertOffset, (builder) {
        var addComma = _style == _Style.base
            ? lastRequiredPositionalParameter != null
            : !parametersAtCurly && !addCurlyBraces;
        for (var (field, :isRequired) in mappedFields) {
          // If we have a required named parameter already, don't add
          // non-required parameters yet.
          if (requiredFirst && !isRequired) {
            continue;
          }
          if (addComma) {
            builder.write(', ');
          }
          addComma = true;
          if (isRequired) {
            builder.write('required ');
          }
          if (field.isPrivate) {
            var nameIndex = field.displayName.indexOf(_charAfterUnderscore);
            var publicName = field.displayName.substring(nameIndex);
            if (_startsWithNumber.hasMatch(publicName)) {
              // Like we do for closures suggesting p0, p1, etc.
              publicName = 'p$publicName';
            }
            builder.writeType(field.type);
            builder.write(' $publicName');
            initializer.add((field: field, publicName: publicName));
          } else {
            builder.write('this.${field.name}');
          }
        }
        if (_style == _Style.base
            ? containsOptionalPositional || firstNamedParameter != null
            : firstNamedParameter != null && parametersAtCurly) {
          builder.write(', ');
        }
      });
      insertOffset =
          parameters.lastOrNull?.end ??
          constructor.parameters.rightParenthesis.offset;
      if (requiredFirst) {
        builder.addInsertion(insertOffset, (builder) {
          for (var (field, :isRequired) in mappedFields) {
            if (isRequired) {
              continue;
            }
            builder.write(', this.${field.name}');
          }
        });
      }
      if (addCurlyBraces) {
        builder.addSimpleInsertion(insertOffset, '}');
      }

      if (initializer.isNotEmpty) {
        var colonOffset =
            constructor.separator?.end ??
            constructor.parameters.rightParenthesis.end;
        builder.addInsertion(colonOffset, (builder) {
          if (constructor.separator == null) {
            builder.write(' :');
          }
          var writeComma = false;
          for (var (:field, :publicName) in initializer) {
            if (writeComma) {
              builder.write(',');
            }
            writeComma = true;
            builder.write(' ${field.name} = $publicName');
          }
          if (constructor.initializers.isNotEmpty) {
            builder.write(',');
          }
        });
      }
    });
  }

  bool _isFieldRequired(FieldElement field) =>
      _style == _Style.requiredNamed &&
      typeSystem.isPotentiallyNonNullable(field.type);
}

enum _Style { base, requiredNamed }
