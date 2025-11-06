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

/// The boolean value indicates whether the field is required.
/// The string value is the field/parameter name.
typedef _FieldRecord = ({bool isRequired, String parameter});

class AddFieldFormalParameters extends ResolvedCorrectionProducer {
  final _Style _style;

  bool _useRequired = false;

  @override
  final FixKind fixKind;

  AddFieldFormalParameters({required super.context})
    : _style = _Style.base,
      fixKind = DartFixKind.addInitializingFormalParameters;

  AddFieldFormalParameters.requiredNamed({required super.context})
    : _style = _Style.requiredNamed,
      fixKind = DartFixKind.addInitializingFormalNamesParameters;

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

    var classNode = constructor.parent;
    if (classNode is! ClassDeclaration) {
      return;
    }

    var superType = classNode.declaredFragment!.element.supertype;
    if (superType == null) {
      return;
    }

    // Compute uninitialized final fields.
    var fields = ErrorVerifier.computeNotInitializedFields(constructor);
    fields.retainWhere((FieldElement field) => field.isFinal);
    fields.sort(
      (a, b) => a.firstFragment.nameOffset! - b.firstFragment.nameOffset!,
    );

    // Prepare the last required parameter.
    FormalParameter? lastRequiredParameter;
    FormalParameter? firstNamedParameter;
    for (var parameter in parameters) {
      if (parameter.isRequiredPositional) {
        lastRequiredParameter = parameter;
      } else if (_style == _Style.base) {
        break;
      } else if (parameter.isOptionalPositional) {
        // If there are optional positional parameters, we can't add required
        // named parameters.
        return;
      } else if (parameter.isNamed) {
        firstNamedParameter = parameter;
        break;
      }
    }

    if (_style == _Style.requiredNamed) {
      _useRequired = true;
    }

    var fieldsRecords = fields.map(_parameterForField).toList();
    var requiredFirst = getCodeStyleOptions(
      unitResult.file,
    ).requiredNamedParametersFirst;
    if (requiredFirst) {
      fieldsRecords.sort((a, b) {
        if (a.isRequired && !b.isRequired) {
          return -1;
        } else if (!a.isRequired && b.isRequired) {
          return 1;
        }
        return a.parameter.compareTo(b.parameter);
      });
    }
    var requiredParameters = fieldsRecords.where((r) => r.isRequired);
    var optionalParameters = fieldsRecords
        .where((r) => !r.isRequired)
        .map((r) => r.parameter);
    var fieldParametersCode = fieldsRecords.map((r) => r.parameter).join(', ');
    await builder.addDartFileEdit(file, (builder) {
      if (firstNamedParameter != null &&
          requiredFirst &&
          requiredParameters.isNotEmpty) {
        builder.addSimpleInsertion(
          firstNamedParameter.offset,
          '${requiredParameters.map((r) => r.parameter).join(', ')}, ',
        );
        if (optionalParameters.isNotEmpty) {
          fieldParametersCode = optionalParameters.join(', ');
        } else {
          return; // No optional parameters to add.
        }
      }
      if (_style == _Style.requiredNamed) {
        var lastParameter = parameters.lastOrNull;
        if (lastParameter != null) {
          var write = ', ';
          if (!lastParameter.isNamed) {
            write += '{$fieldParametersCode}';
          } else {
            write += fieldParametersCode;
          }
          builder.addSimpleInsertion(parameters.last.end, write);
        }
      } else if (lastRequiredParameter != null) {
        return builder.addSimpleInsertion(
          lastRequiredParameter.end,
          ', $fieldParametersCode',
        );
      } else {
        var offset = constructor.parameters.leftParenthesis.end;
        if (parameters.isNotEmpty) {
          fieldParametersCode += ', ';
        }
        builder.addSimpleInsertion(offset, fieldParametersCode);
      }
    });
  }

  _FieldRecord _parameterForField(FieldElement field) {
    var prefix = '';
    var isRequired = false;
    if (typeSystem.isPotentiallyNonNullable(field.type) && _useRequired) {
      isRequired = true;
      prefix = 'required ';
    }
    return (isRequired: isRequired, parameter: '${prefix}this.${field.name}');
  }
}

enum _Style { base, requiredNamed }
