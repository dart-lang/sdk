// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class AddFieldFormalParameters extends ResolvedCorrectionProducer {
  static final _charAfterUnderscore = RegExp('[^_]');

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

    if (constructor.parent is! BlockClassBody &&
        constructor.parent is! EnumBody) {
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
    List<FormalParameter> parameters = constructor.parameters.parameters;
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

      // Insert the "{" to begin the named parameters if needed.
      var addCurlyBraces =
          firstNamedParameter == null && _style == _Style.requiredNamed;
      var parametersAtCurly = getCodeStyleOptions(
        unitResult.file,
      ).requiredNamedParametersFirst;

      if (addCurlyBraces && !parametersAtCurly) {
        var curlyOpen = lastRequiredPositionalParameter == null ? '{' : ', {';
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

      var mappedFields = fields.map(
        (field) => (field, isRequired: _isFieldRequired(field)),
      );
      if (parametersAtCurly) {
        mappedFields.sorted((r1, r2) {
          return r1.isRequired == r2.isRequired ? 0 : (r1.isRequired ? -1 : 1);
        });
      }

      // The fields that have to be explicitly initialized in the constructor
      // initializer list.
      var initializers = <({String publicName, FieldElement field})>[];

      var requiredFirst =
          firstNamedParameter != null &&
          firstNamedParameter.isRequiredNamed &&
          parametersAtCurly;
      builder.addInsertion(insertOffset, (builder) {
        var addComma = switch (_style) {
          _Style.base => lastRequiredPositionalParameter != null,
          _Style.requiredNamed => !parametersAtCurly && !addCurlyBraces,
        };

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

          var publicName = correspondingPublicName(field.displayName);
          if (_canUseInitializingFormal(field, publicName)) {
            builder.write('this.${field.name}');
          } else {
            if (publicName == null) {
              var nameIndex = field.displayName.indexOf(_charAfterUnderscore);
              // Like we do for closures suggesting p0, p1, etc.
              publicName = 'p${field.displayName.substring(nameIndex)}';
            }

            builder.writeType(field.type);
            builder.write(' $publicName');
            initializers.add((field: field, publicName: publicName));
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

      // If we need to add any explicit initializers, add them.
      if (initializers.isNotEmpty) {
        var colonOffset =
            constructor.separator?.end ??
            constructor.parameters.rightParenthesis.end;
        builder.addInsertion(colonOffset, (builder) {
          if (constructor.separator == null) {
            builder.write(' :');
          }
          var writeComma = false;
          for (var (:field, :publicName) in initializers) {
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

  /// Whether [field] can be initialized using an initializing formal.
  ///
  /// If not, it is initialized in the constructor initializer list.
  bool _canUseInitializingFormal(FieldElement field, String? publicName) {
    switch (_style) {
      case _Style.base:
        return true; // Can always use for positional parameters.

      case _Style.requiredNamed:
        // Can always use for public names.
        if (!field.isPrivate) {
          return true;
        }

        // Can use them for private named parameters, if there is a public name.
        return isEnabled(Feature.private_named_parameters) &&
            publicName != null;
    }
  }

  bool _isFieldRequired(FieldElement field) => switch (_style) {
    _Style.base => false,
    _Style.requiredNamed => typeSystem.isPotentiallyNonNullable(field.type),
  };
}

enum _Style { base, requiredNamed }
