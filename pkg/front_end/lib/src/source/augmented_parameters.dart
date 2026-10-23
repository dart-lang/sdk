// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/messages.dart';
import '../base/uri_offset.dart';
import '../builder/formal_parameter_builder.dart';
import '../codes/diagnostic.dart' as diag;

/// Helper class for handling augmentation of parameters.
///
/// It groups corresponding parameters from different fragment to allow for
/// checking and distributing properties, such as default values, across
/// parameters.
class AugmentedParameters {
  final List<_Parameter> _parameters = [];
  final List<_PositionalParameter> _positionalParameters = [];
  final Map<String, _NamedParameter> _namedParameters = {};

  /// Registers [formals] as the declared parameter for a fragment.
  ///
  /// [isImplementation] is `true` if the fragment is considered the
  /// implementation.
  void registerParameters(
    List<FormalParameterBuilder>? formals, {
    required bool isImplementation,
  }) {
    if (formals != null) {
      int index = 0;
      for (FormalParameterBuilder formal in formals) {
        switch (formal.kind) {
          case FormalParameterKind.optionalPositional:
          case FormalParameterKind.requiredPositional:
            if (index < _positionalParameters.length) {
              _positionalParameters[index].addFormalParameterBuilder(
                formal,
                isImplementation: isImplementation,
              );
            } else {
              _PositionalParameter parameter = new _PositionalParameter(
                index: index,
                builder: formal,
              );
              _positionalParameters.add(parameter);
              _parameters.add(parameter);
            }
            index++;
          case FormalParameterKind.optionalNamed:
          case FormalParameterKind.requiredNamed:
            String name = formal.name;
            if (formal.isDuplicate) {
              // Don't match duplicate named parameter with other parameter to
              // avoid cascading failure due to default values and types across
              // parameters with the same name.
              _parameters.add(new _NamedParameter(name: name, builder: formal));
            } else {
              _NamedParameter? namedParameter = _namedParameters[name];
              if (namedParameter != null) {
                namedParameter.addFormalParameterBuilder(
                  formal,
                  isImplementation: isImplementation,
                );
              } else {
                namedParameter = new _NamedParameter(
                  name: name,
                  builder: formal,
                );
                _namedParameters[name] = namedParameter;
                _parameters.add(namedParameter);
              }
            }
        }
      }
    }
  }

  void processOutlineExpressions(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment, {
    required bool isAbstract,
    required bool isExternal,
    required LibraryFeatures libraryFeatures,
  }) {
    for (_Parameter parameter in _parameters) {
      parameter.processOutlineExpressions(
        problemReporting: problemReporting,
        typeEnvironment: typeEnvironment,
        isAbstract: isAbstract,
        isExternal: isExternal,
        libraryFeatures: libraryFeatures,
      );
    }
  }
}

abstract class _Parameter {
  final List<FormalParameterBuilder> _builders = [];
  FormalParameterBuilder _implementation;

  new({required FormalParameterBuilder builder}) : _implementation = builder {
    _builders.add(builder);
  }

  void addFormalParameterBuilder(
    FormalParameterBuilder builder, {
    required bool isImplementation,
  }) {
    _builders.add(builder);
    if (isImplementation) {
      _implementation = builder;
    }
  }

  void processOutlineExpressions({
    required ProblemReporting problemReporting,
    required TypeEnvironment typeEnvironment,
    required bool isAbstract,
    required bool isExternal,
    required LibraryFeatures libraryFeatures,
  }) {
    FormalParameterBuilder introductoryFormal = _builders.first;
    if (introductoryFormal.isOptional) {
      FormalParameterBuilder? formalWithDefaultValue;
      for (int i = 0; i < _builders.length; i++) {
        FormalParameterBuilder formal = _builders[i];
        if (formal.hasDeclaredDefaultValue) {
          if (formalWithDefaultValue != null &&
              // TODO(johnniwinther): Report this on patches.
              libraryFeatures.augmentations.isEnabled) {
            problemReporting.addProblem2(
              diag.defaultValueAlreadySpecifiedInAugmentationChain,
              formal.uriOffset,
              context: [
                diag.defaultValueAlreadySpecifiedInAugmentationChainCause
                    .withLocation2(formalWithDefaultValue.uriOffset),
              ],
            );
          }
          formalWithDefaultValue = formal;
        }
      }
      // TODO(johnniwinther): Check that the parameter types match.
      if (!(isAbstract || isExternal) &&
          _implementation.variable.type.isPotentiallyNonNullable &&
          formalWithDefaultValue == null) {
        problemReporting.addProblem2(
          diag.optionalNonNullableWithoutInitializerError.withArguments(
            parameterName: _implementation.name,
            parameterType: _implementation.variable.type,
          ),
          _implementation.uriOffset,
        );
        for (int i = 0; i < _builders.length; i++) {
          _builders[i].variable.hasErroneousDefaultValue = true;
        }
      }
      if (formalWithDefaultValue != null) {
        Expression? defaultValue =
            formalWithDefaultValue.variable.inferredDefaultValue;
        if (defaultValue != null) {
          for (FormalParameterBuilder builder in _builders) {
            if (builder != formalWithDefaultValue) {
              builder.variable.setInferredDefaultValue(defaultValue);
            }
          }
        }
      }
    }
  }
}

class _PositionalParameter({required final int index, required super.builder})
    extends _Parameter {}

class _NamedParameter({required final String name, required super.builder})
    extends _Parameter;
