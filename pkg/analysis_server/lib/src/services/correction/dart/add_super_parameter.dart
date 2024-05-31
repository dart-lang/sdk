// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class AddSuperParameter extends ResolvedCorrectionProducer {
  int _missingCount = 0;

  AddSuperParameter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_missingCount == 1 ? '' : 's'];

  @override
  FixKind get fixKind => DartFixKind.ADD_SUPER_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.featureSet.isEnabled(Feature.super_parameters)) {
      return;
    }
    var constructorDeclaration = node.parent;
    if (constructorDeclaration is! ConstructorDeclaration) return;
    var classDeclaration = constructorDeclaration.parent;
    if (classDeclaration is! ClassDeclaration) return;
    var superUnnamedConstructor =
        classDeclaration.declaredElement?.supertype?.element.unnamedConstructor;
    if (superUnnamedConstructor == null) return;
    var superParameters = superUnnamedConstructor.parameters;
    var parameters = constructorDeclaration.parameters.parameters;
    var missingNamedParameters = <ParameterElement>[];
    var superPositionalParameters = <ParameterElement>[];
    for (var superParameter in superParameters) {
      if (superParameter.isRequired) {
        var name = superParameter.name;
        if (superParameter.isNamed) {
          if (!parameters.any((parameter) => parameter.name?.lexeme == name)) {
            missingNamedParameters.add(superParameter);
          }
        } else {
          superPositionalParameters.add(superParameter);
        }
      }
    }

    var arePositionalOrdered = true;
    FormalParameter? lastPositionalParameter;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        if (parameter is! SuperFormalParameter ||
            i >= superPositionalParameters.length ||
            parameter.name.lexeme != superPositionalParameters[i].name) {
          arePositionalOrdered = false;
          break;
        }
        lastPositionalParameter = parameter;
      }
    }

    var missingPositionalParameters = <ParameterElement>[];
    if (arePositionalOrdered) {
      var index = lastPositionalParameter == null
          ? 0
          : parameters.indexOf(lastPositionalParameter) + 1;
      missingPositionalParameters = superPositionalParameters.sublist(index);
    }

    _missingCount =
        missingPositionalParameters.length + missingNamedParameters.length;

    if (parameters.isEmpty) {
      var offset = constructorDeclaration.parameters.leftParenthesis.end;
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(offset, (builder) {
          _writePositional(builder, missingPositionalParameters,
              needsInitialComma: false);

          if (missingNamedParameters.isNotEmpty) {
            _writeNamed(
              builder,
              missingNamedParameters,
              needsInitialComma: missingPositionalParameters.isNotEmpty,
            );
          }
        });
      });
    } else {
      var lastNamedParameter =
          parameters.lastWhereOrNull((parameter) => parameter.isNamed);
      if (missingPositionalParameters.isNotEmpty) {
        var offset = lastPositionalParameter == null
            ? constructorDeclaration.parameters.leftParenthesis.end
            : lastPositionalParameter.end;

        await builder.addDartFileEdit(file, (builder) {
          builder.addInsertion(offset, (builder) {
            _writePositional(builder, missingPositionalParameters,
                needsInitialComma: lastPositionalParameter != null);
            if (lastPositionalParameter == null && lastNamedParameter != null) {
              builder.write(', ');
            }
          });
        });
      }

      if (missingNamedParameters.isNotEmpty) {
        SourceRange replacementRange;
        if (lastNamedParameter != null) {
          replacementRange = SourceRange(lastNamedParameter.end, 0);
        } else if (lastPositionalParameter != null) {
          replacementRange = range.endStart(lastPositionalParameter,
              constructorDeclaration.parameters.rightParenthesis);
        } else {
          replacementRange = SourceRange(
              constructorDeclaration.parameters.leftParenthesis.end, 0);
        }

        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(replacementRange, (builder) {
            _writeNamed(
              builder,
              missingNamedParameters,
              needsInitialComma: true,
              lastNamedParameter: lastNamedParameter,
            );
          });
        });
      }
    }
  }

  void _writeNamed(
    DartEditBuilder builder,
    List<ParameterElement> parameters, {
    FormalParameter? lastNamedParameter,
    required bool needsInitialComma,
  }) {
    var firstParameter = true;
    void writeComma() {
      if (firstParameter) {
        firstParameter = false;
      } else {
        builder.write(', ');
      }
    }

    if (needsInitialComma) {
      builder.write(', ');
    }
    if (lastNamedParameter == null) {
      builder.write('{');
    }
    for (var parameter in parameters) {
      writeComma();
      _writeParameter(builder, parameter);
    }
    if (lastNamedParameter == null) {
      builder.write('}');
    }
  }

  void _writeParameter(DartEditBuilder builder, ParameterElement parameter) {
    var parameterName = parameter.displayName;

    if (parameter.isRequiredNamed) {
      builder.write('required ');
    }

    builder.write('super.');
    builder.write(parameterName);
  }

  void _writePositional(
    DartEditBuilder builder,
    List<ParameterElement> parameters, {
    required bool needsInitialComma,
  }) {
    var firstParameter = true;
    void writeComma() {
      if (firstParameter && !needsInitialComma) {
        firstParameter = false;
      } else {
        builder.write(', ');
      }
    }

    for (var parameter in parameters) {
      writeComma();
      _writeParameter(builder, parameter);
    }
  }
}
