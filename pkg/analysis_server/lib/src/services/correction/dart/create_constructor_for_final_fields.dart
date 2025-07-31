// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// The boolean value indicates whether the field is required.
/// The string value is the field/parameter name.
typedef _FieldRecord = (bool, String);

class CreateConstructorForFinalFields extends ResolvedCorrectionProducer {
  final _Style _style;

  CreateConstructorForFinalFields.requiredNamed({required super.context})
    : _style = _Style.requiredNamed;

  CreateConstructorForFinalFields.requiredPositional({required super.context})
    : _style = _Style.requiredPositional;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _style.fixKind;

  FieldDeclaration? get _errorFieldDeclaration {
    if (node is VariableDeclaration) {
      var fieldDeclaration = node.parent?.parent;
      return fieldDeclaration?.ifTypeOrNull();
    }
    return null;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var fieldDeclaration = _errorFieldDeclaration;
    if (fieldDeclaration == null) {
      return;
    }

    var container = fieldDeclaration.parent;
    if (container is! NamedCompilationUnitMember) {
      return;
    }

    InterfaceType? superType;
    _FixContext fixContext;
    switch (container) {
      case ClassDeclaration():
        superType = container.declaredFragment?.element.supertype;
        if (superType == null) {
          return;
        }
        fixContext = _FixContext(
          builder: builder,
          containerName: container.name.lexeme,
          superType: superType,
          variableLists: container.members.interestingVariableLists,
        );
      case EnumDeclaration():
        superType = container.declaredFragment?.element.supertype;
        if (superType == null) {
          return;
        }
        fixContext = _FixContext(
          builder: builder,
          containerName: container.name.lexeme,
          superType: superType,
          variableLists: container.members.interestingVariableLists,
        );
      case _:
        return;
    }

    var requiredNamedParametersFirst =
        getCodeStyleOptions(unitResult.file).requiredNamedParametersFirst;

    if (superType.isExactlyStatelessWidgetType ||
        superType.isExactlyStatefulWidgetType) {
      await _forFlutterWidget(
        fixContext: fixContext,
        classDeclaration: container,
        requiredNamedParametersFirst: requiredNamedParametersFirst,
      );
    } else {
      await _notFlutterWidget(
        fixContext: fixContext,
        containerDeclaration: container,
        isConst: container is EnumDeclaration,
        requiredNamedParametersFirst: requiredNamedParametersFirst,
      );
    }
  }

  List<_Field>? _fieldsToWrite(
    Iterable<VariableDeclarationList> variableLists,
  ) {
    var result = <_Field>[];
    for (var variableList in variableLists) {
      var type = variableList.type?.type;
      var hasNonNullableType =
          type != null && typeSystem.isPotentiallyNonNullable(type);

      for (var field in variableList.variables) {
        var typeAnnotation = variableList.type;
        if (typeAnnotation == null) {
          return null;
        }
        if (field.initializer == null) {
          var fieldName = field.name.lexeme;
          var namedFormalParameterName = _Field.computeNamedFormalParameterName(
            fieldName,
          );
          if (namedFormalParameterName == null) {
            return null;
          }
          result.add(
            _Field(
              typeAnnotation: typeAnnotation,
              fieldName: fieldName,
              namedFormalParameterName: namedFormalParameterName,
              hasNonNullableType: hasNonNullableType,
            ),
          );
        }
      }
    }
    return result;
  }

  Future<void> _forFlutterWidget({
    required _FixContext fixContext,
    required NamedCompilationUnitMember classDeclaration,
    required bool requiredNamedParametersFirst,
  }) async {
    if (unit.featureSet.isEnabled(Feature.super_parameters)) {
      await _forFlutterWithSuperParameters(
        fixContext: fixContext,
        classDeclaration: classDeclaration,
        requiredNamedParametersFirst: requiredNamedParametersFirst,
      );
    } else {
      await _forFlutterWithoutSuperParameters(
        fixContext: fixContext,
        classDeclaration: classDeclaration,
        requiredNamedParametersFirst: requiredNamedParametersFirst,
      );
    }
  }

  Future<void> _forFlutterWithoutSuperParameters({
    required _FixContext fixContext,
    required NamedCompilationUnitMember classDeclaration,
    required bool requiredNamedParametersFirst,
  }) async {
    var keyClass = await sessionHelper.getFlutterClass('Key');
    if (keyClass == null) {
      return;
    }

    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.insertConstructor(classDeclaration, (builder) {
        // TODO(srawlins): Replace this block with `writeConstructorDeclaration`
        // and `parameterWriter`.
        builder.write('const ');
        builder.write(fixContext.containerName);
        builder.write('({');
        if (!requiredNamedParametersFirst) {
          builder.writeType(
            keyClass.instantiate(
              typeArguments: const [],
              nullabilitySuffix: NullabilitySuffix.question,
            ),
          );
          builder.write(' key');
        }
        var fieldsForInitializers = <_Field>[];

        _writeFlutterParameters(
          builder: builder,
          variableLists: fixContext.variableLists,
          fieldsForInitializers: fieldsForInitializers,
          requiredNamedParametersFirst: requiredNamedParametersFirst,
        );

        if (requiredNamedParametersFirst) {
          builder.write(', ');
          builder.writeType(
            keyClass.instantiate(
              typeArguments: const [],
              nullabilitySuffix: NullabilitySuffix.question,
            ),
          );
          builder.write(' key');
        }

        builder.write('}) : ');
        if (fieldsForInitializers.isNotEmpty) {
          builder.write('${_getInitalizersString(fieldsForInitializers)}, ');
        }
        builder.write('super(key: key);');
      });
    });
  }

  Future<void> _forFlutterWithSuperParameters({
    required _FixContext fixContext,
    required NamedCompilationUnitMember classDeclaration,
    required bool requiredNamedParametersFirst,
  }) async {
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.insertConstructor(classDeclaration, (builder) {
        // TODO(srawlins): Replace this block with `writeConstructorDeclaration`
        // and `parameterWriter`.
        builder.write('const ');
        builder.write(fixContext.containerName);
        builder.write('({');
        if (!requiredNamedParametersFirst) {
          builder.write('super.key');
        }

        var fieldsForInitializers = <_Field>[];
        _writeFlutterParameters(
          builder: builder,
          variableLists: fixContext.variableLists,
          fieldsForInitializers: fieldsForInitializers,
          requiredNamedParametersFirst: requiredNamedParametersFirst,
        );
        if (requiredNamedParametersFirst) {
          builder.write(', super.key');
        }

        builder.write('})');
        if (fieldsForInitializers.isNotEmpty) {
          builder.write(' : ${_getInitalizersString(fieldsForInitializers)}');
        }
        builder.write(';');
      });
    });
  }

  String _getInitalizersString(List<_Field> fieldsForInitializers) =>
      fieldsForInitializers
          .map((field) {
            return '${field.fieldName} = ${field.namedFormalParameterName}';
          })
          .join(', ');

  Future<void> _notFlutterNamed({
    required _FixContext fixContext,
    required NamedCompilationUnitMember containerDeclaration,
    required bool isConst,
    required List<_Field> fields,
    required bool requiredNamedParametersFirst,
  }) async {
    var fieldsForInitializers = <_Field>[];

    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.insertConstructor(containerDeclaration, (builder) {
        // TODO(srawlins): Replace this block with `writeConstructorDeclaration`
        // and `parameterWriter`.
        if (isConst) {
          builder.write('const ');
        }
        builder.write(fixContext.containerName);
        builder.write('({');
        var parameters = <_FieldRecord>[];
        var buffer = StringBuffer();
        var superNamed = fixContext.superNamed;
        if (superNamed != null) {
          for (var formalParameter in superNamed) {
            buffer.clear();
            var required = false;
            if (formalParameter.isRequiredNamed) {
              required = true;
              buffer.write('required ');
            }
            buffer.write('super.');
            buffer.write(formalParameter.name!);
            parameters.add((required, buffer.toString()));
          }
        }
        for (var field in fields) {
          buffer.clear();
          if (field.namedFormalParameterName == field.fieldName) {
            buffer.write('required this.');
            buffer.write(field.fieldName);
          } else {
            buffer.write('required ');
            buffer.write(utils.getNodeText(field.typeAnnotation));
            buffer.write(' ');
            buffer.write(field.namedFormalParameterName);
            fieldsForInitializers.add(field);
          }
          parameters.add((true, buffer.toString()));
        }

        if (requiredNamedParametersFirst) {
          parameters.sort((a, b) {
            if (a.$1 == b.$1) {
              return 0;
            } else if (a.$1) {
              return -1;
            } else {
              return 1;
            }
          });
        }

        var hasWritten = false;
        for (var parameter in parameters) {
          if (hasWritten) {
            builder.write(', ');
          }
          builder.write(parameter.$2);
          hasWritten = true;
        }

        builder.write('})');

        if (fieldsForInitializers.isNotEmpty) {
          builder.write(' : ${_getInitalizersString(fieldsForInitializers)}');
        }

        builder.write(';');
      });
    });
  }

  Future<void> _notFlutterRequiredPositional({
    required _FixContext fixContext,
    required NamedCompilationUnitMember containerDeclaration,
    required bool isConst,
    required List<_Field> fields,
  }) async {
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.insertConstructor(containerDeclaration, (builder) {
        // TODO(srawlins): Replace this block with `writeConstructorDeclaration`
        // and `parameterWriter`.
        if (isConst) {
          builder.write('const ');
        }
        builder.write(fixContext.containerName);
        builder.write('(');
        var hasWritten = false;
        for (var field in fields) {
          if (hasWritten) {
            builder.write(', ');
          }
          builder.write('this.');
          builder.write(field.fieldName);
          hasWritten = true;
        }
        builder.write(');');
      });
    });
  }

  Future<void> _notFlutterWidget({
    required _FixContext fixContext,
    required NamedCompilationUnitMember containerDeclaration,
    required bool isConst,
    required bool requiredNamedParametersFirst,
  }) async {
    var fields = _fieldsToWrite(fixContext.variableLists);
    if (fields == null) {
      return;
    }

    switch (_style) {
      case _Style.requiredNamed:
        await _notFlutterNamed(
          fixContext: fixContext,
          containerDeclaration: containerDeclaration,
          isConst: isConst,
          fields: fields,
          requiredNamedParametersFirst: requiredNamedParametersFirst,
        );
      case _Style.requiredPositional:
        await _notFlutterRequiredPositional(
          fixContext: fixContext,
          containerDeclaration: containerDeclaration,
          isConst: isConst,
          fields: fields,
        );
    }
  }

  void _writeFlutterParameters({
    required DartEditBuilder builder,
    required Iterable<VariableDeclarationList> variableLists,
    required List<_Field> fieldsForInitializers,
    required bool requiredNamedParametersFirst,
  }) {
    var fields = _fieldsToWrite(variableLists);
    if (fields == null) {
      return;
    }

    var childrenLast = fields.stablePartition((field) => !field.isChild);

    var parameters = <_FieldRecord>[];
    var buffer = StringBuffer();
    for (var field in childrenLast) {
      var required = false;
      buffer.clear();
      if (field.hasNonNullableType) {
        required = true;
        buffer.write('required ');
      }
      if (field.namedFormalParameterName == field.fieldName) {
        buffer.write('this.');
        buffer.write(field.fieldName);
      } else {
        buffer.write(utils.getNodeText(field.typeAnnotation));
        buffer.write(' ');
        buffer.write(field.namedFormalParameterName);
        fieldsForInitializers.add(field);
      }
      parameters.add((required, buffer.toString()));
    }
    if (requiredNamedParametersFirst) {
      parameters.sort((a, b) {
        if (a.$1 == b.$1) {
          return 0;
        } else if (a.$1) {
          return -1;
        } else {
          return 1;
        }
      });
    }
    // If this is false, then key is added first.
    var isFirst = requiredNamedParametersFirst;
    for (var parameter in parameters) {
      if (isFirst) {
        isFirst = false;
      } else {
        builder.write(', ');
      }
      builder.write(parameter.$2);
    }
  }
}

class _Field {
  final TypeAnnotation typeAnnotation;
  final String fieldName;
  final String namedFormalParameterName;
  final bool hasNonNullableType;

  _Field({
    required this.typeAnnotation,
    required this.fieldName,
    required this.namedFormalParameterName,
    required this.hasNonNullableType,
  });

  bool get isChild {
    return const {'child', 'children'}.contains(fieldName);
  }

  /// Returns the name for the corresponding named formal parameters, or
  /// `null` if such name cannot be computed, so that the quick fix cannot
  /// be computed.
  static String? computeNamedFormalParameterName(String fieldName) {
    var result = fieldName;
    while (true) {
      if (result.isEmpty) {
        return null;
      } else if (result.startsWith('_')) {
        result = result.substring(1);
      } else {
        return result;
      }
    }
  }
}

class _FixContext {
  final ChangeBuilder builder;
  final String containerName;
  final InterfaceType superType;
  final Iterable<VariableDeclarationList> variableLists;

  _FixContext({
    required this.builder,
    required this.containerName,
    required this.superType,
    required this.variableLists,
  });

  List<FormalParameterElement>? get superNamed {
    var superConstructor = superType.constructors.singleOrNull;
    if (superConstructor != null) {
      var superAll = superConstructor.formalParameters;
      var superNamed = superAll.where((e) => e.isNamed).toList();
      return superNamed.length == superAll.length ? superNamed : null;
    }
    return null;
  }
}

enum _Style {
  requiredNamed(
    fixKind: DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS_REQUIRED_NAMED,
  ),
  requiredPositional(fixKind: DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);

  final FixKind fixKind;

  const _Style({required this.fixKind});
}

extension on List<ClassMember> {
  Iterable<VariableDeclarationList> get interestingVariableLists =>
      whereType<FieldDeclaration>()
          .map((e) => e.fields)
          .where((e) => e.isFinal && !e.isLate)
          .toList();
}
