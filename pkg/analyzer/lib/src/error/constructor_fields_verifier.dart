// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Verifier for initializing fields in constructors.
class ConstructorFieldsVerifier {
  final TypeSystemImpl typeSystem;
  final Map<InstanceElement, _Interface> _interfaces = Map.identity();

  ConstructorFieldsVerifier({required this.typeSystem});

  void addConstructors(
    DiagnosticReporter diagnosticReporter,
    InterfaceElement element,
    List<ClassMember> members,
    ClassNamePartImpl primaryConstructor,
  ) {
    var interfaceFields = _forInterface(element);
    if (primaryConstructor is PrimaryConstructorDeclarationImpl) {
      _addPrimaryConstructor(
        diagnosticReporter: diagnosticReporter,
        interfaceFields: interfaceFields,
        primaryConstructor: primaryConstructor,
      );
    }
    var constructors = members.whereType<ConstructorDeclarationImpl>();
    for (var constructor in constructors) {
      _addConstructor(
        diagnosticReporter: diagnosticReporter,
        interfaceFields: interfaceFields,
        node: constructor,
      );
    }
  }

  void report() {
    for (var interface in _interfaces.values) {
      for (var constructor in interface.constructors.values) {
        constructor.report();
      }
    }
  }

  void _addConstructor({
    required DiagnosticReporter diagnosticReporter,
    required _Interface interfaceFields,
    required ConstructorDeclarationImpl node,
  }) {
    if (node.factoryKeyword != null ||
        node.redirectedConstructor != null ||
        node.externalKeyword != null) {
      return;
    }

    var fragment = node.declaredFragment!;
    var constructorState = interfaceFields.forConstructor(
      diagnosticReporter: diagnosticReporter,
      element: fragment.element,
      errorRange: node.errorRange,
      isPrimary: false,
    );
    constructorState.secondaryConstructors.add(node);

    if (!fragment.isAugmentation) {
      constructorState.updateWithParameters(node.parameters.parameters);
    }

    constructorState.updateWithInitializers(
      diagnosticReporter,
      node.initializers,
    );
  }

  void _addPrimaryConstructor({
    required DiagnosticReporter diagnosticReporter,
    required _Interface interfaceFields,
    required PrimaryConstructorDeclarationImpl primaryConstructor,
  }) {
    var fragment = primaryConstructor.declaredFragment!;
    var constructorState = interfaceFields.forConstructor(
      diagnosticReporter: diagnosticReporter,
      element: fragment.element,
      errorRange: primaryConstructor.errorRange,
      isPrimary: true,
    );
    constructorState.primaryConstructors.add(primaryConstructor);

    constructorState.updateWithParameters(
      primaryConstructor.formalParameters.parameters,
    );

    var body = primaryConstructor.body;
    if (body != null) {
      constructorState.updateWithInitializers(
        diagnosticReporter,
        body.initializers,
      );
    }
  }

  _Interface _forInterface(InterfaceElement element) {
    if (_interfaces[element] case var result?) {
      return result;
    }

    var fieldMap = <FieldElement, _InitState>{};
    var fieldNameCounts = <String, int>{};

    for (var field in element.fields) {
      if (field.isOriginGetterSetter) {
        continue;
      }
      if (element is EnumElement && field.name == 'index') {
        continue;
      }
      fieldMap[field] = field.hasInitializer
          ? _InitState.initInDeclaration
          : _InitState.notInit;
      if (field.name case var name?) {
        fieldNameCounts.update(name, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    return _interfaces[element] = _Interface(
      typeSystem: typeSystem,
      element: element,
      fields: fieldMap,
      duplicateFieldNames: {
        for (var entry in fieldNameCounts.entries)
          if (entry.value > 1) entry.key,
      },
    );
  }
}

class _Constructor {
  final TypeSystemImpl typeSystem;
  final DiagnosticReporter diagnosticReporter;
  final SourceRange errorRange;
  final Map<FieldElement, _InitState> fields;
  final Set<String> duplicateFieldNames;
  final bool isPrimary;
  final List<PrimaryConstructorDeclarationImpl> primaryConstructors = [];
  final List<ConstructorDeclarationImpl> secondaryConstructors = [];

  /// Set to `true` if the constructor redirects.
  bool hasRedirectingConstructorInvocation = false;

  _Constructor({
    required this.typeSystem,
    required this.diagnosticReporter,
    required this.errorRange,
    required this.fields,
    required this.duplicateFieldNames,
    required this.isPrimary,
  });

  void report() {
    if (hasRedirectingConstructorInvocation) {
      return;
    }

    // Prepare lists of not initialized fields.
    var notInitFinalFields = <_Field>[];
    var notInitNonNullableFields = <_Field>[];
    fields.forEach((field, state) {
      if (state != _InitState.notInit) return;
      if (field.isLate) return;
      if (field.isAbstract || field.isExternal) return;
      if (field.isStatic) return;

      var name = field.name;
      if (name == null) return;
      if (duplicateFieldNames.contains(name)) return;

      if (field.isFinal) {
        notInitFinalFields.add(_Field(field, name));
      } else if (typeSystem.isPotentiallyNonNullable(field.type)) {
        notInitNonNullableFields.add(_Field(field, name));
      }
    });

    var allNotInitialized = <FieldElement>[
      for (var f in notInitFinalFields) f.element,
      for (var f in notInitNonNullableFields) f.element,
    ];
    for (var node in primaryConstructors) {
      node.notInitializedFields = allNotInitialized;
    }
    for (var node in secondaryConstructors) {
      node.notInitializedFields = allNotInitialized;
    }

    reportNotInitializedFinal(notInitFinalFields);
    reportNotInitializedNonNullable(notInitNonNullableFields);
  }

  void reportNotInitializedFinal(List<_Field> notInitFinalFields) {
    if (notInitFinalFields.isEmpty) {
      return;
    }

    var names = notInitFinalFields.map((f) => f.name).toList();
    names.sort();

    diagnosticReporter.report(
      switch (names) {
        // `names` can't be empty since its based on `notInitFinalFields`, which
        // is not empty (see `if` test above).
        [] => throw StateError('unexpectedly empty name list'),
        [var name] => diag.finalNotInitializedConstructor1.withArguments(
          name: name,
        ),
        [var name1, var name2] =>
          diag.finalNotInitializedConstructor2.withArguments(
            name1: name1,
            name2: name2,
          ),
        [var name1, var name2, ...var remaining] =>
          diag.finalNotInitializedConstructor3Plus.withArguments(
            name1: name1,
            name2: name2,
            remainingCount: remaining.length,
          ),
      }.atSourceRange(errorRange),
    );
  }

  void reportNotInitializedNonNullable(List<_Field> notInitNonNullableFields) {
    if (notInitNonNullableFields.isEmpty) {
      return;
    }

    var names = notInitNonNullableFields.map((f) => f.name).toList();
    names.sort();

    for (var name in names) {
      diagnosticReporter.report(
        diag.notInitializedNonNullableInstanceFieldConstructor
            .withArguments(name: name)
            .atSourceRange(errorRange),
      );
    }
  }

  void updateWithInitializers(
    DiagnosticReporter diagnosticReporter,
    NodeList<ConstructorInitializer> initializers,
  ) {
    for (var initializer in initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        hasRedirectingConstructorInvocation = true;
      }
      if (initializer is ConstructorFieldInitializer) {
        var fieldName = initializer.fieldName;
        var fieldElement = fieldName.element;
        if (fieldElement is FieldElement) {
          var state = fields[fieldElement];
          if (state == _InitState.notInit) {
            fields[fieldElement] = _InitState.initInInitializer;
          } else if (state == _InitState.initInDeclaration) {
            if (isPrimary) {
              diagnosticReporter.report(
                diag.fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor
                    .at(fieldName),
              );
            } else if (fieldElement.isFinal || fieldElement.isConst) {
              diagnosticReporter.report(
                diag.fieldInitializedInInitializerAndDeclaration.at(fieldName),
              );
            }
            fields[fieldElement] = _InitState.initInInitializer;
          } else if (state == _InitState.initInFieldFormal) {
            diagnosticReporter.report(
              diag.fieldInitializedInParameterAndInitializer.at(fieldName),
            );
          } else if (state == _InitState.initInInitializer) {
            diagnosticReporter.report(
              diag.fieldInitializedByMultipleInitializers
                  .withArguments(name: fieldElement.displayName)
                  .at(fieldName),
            );
          }
        }
      }
    }
  }

  void updateWithParameters(NodeList<FormalParameter> formalParameters) {
    for (var formalParameter in formalParameters) {
      formalParameter = formalParameter.notDefault;
      var parameterFragment = formalParameter.declaredFragment!;
      var parameterElement = parameterFragment.element;
      if (parameterElement is FieldFormalParameterElement) {
        var fieldElement = parameterElement.field;
        if (fieldElement == null) {
          continue;
        }
        _InitState? state = fields[fieldElement];
        if (state == _InitState.notInit) {
          fields[fieldElement] = _InitState.initInFieldFormal;
        } else if (state == _InitState.initInDeclaration) {
          if (isPrimary) {
            if (formalParameter.name case var name?) {
              diagnosticReporter.report(
                diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor
                    .at(name),
              );
            }
          } else if (fieldElement.isFinal || fieldElement.isConst) {
            if (formalParameter.name case var name?) {
              diagnosticReporter.report(
                diag.finalInitializedInDeclarationAndConstructor
                    .withArguments(name: fieldElement.displayName)
                    .at(name),
              );
            }
          }
          fields[fieldElement] = _InitState.initInFieldFormal;
        } else if (state == _InitState.initInFieldFormal) {
          // Reported in DuplicateDefinitionVerifier._checkDuplicateIdentifier
        }
      }
    }
  }
}

/// The field with a non `null` name.
class _Field {
  final FieldElement element;
  final String name;

  _Field(this.element, this.name);
}

/// The four states of a field initialization state through a constructor
/// signature, not initialized, initialized in the field declaration,
/// initialized in the field formal, and finally, initialized in the
/// initializers list.
enum _InitState {
  /// The field is declared without an initializer.
  notInit,

  /// The field is declared with an initializer.
  initInDeclaration,

  /// The field is initialized in a field formal parameter of the constructor
  /// being verified.
  initInFieldFormal,

  /// The field is initialized in the list of initializers of the constructor
  /// being verified.
  initInInitializer,
}

class _Interface {
  final TypeSystemImpl typeSystem;
  final InterfaceElement element;
  final Set<String> duplicateFieldNames;

  /// [_InitState.notInit] or [_InitState.initInDeclaration] for each field
  /// in [element]. This map works as the initial state for
  /// [_Constructor].
  final Map<FieldElement, _InitState> fields;

  final Map<ConstructorElement, _Constructor> constructors = Map.identity();

  _Interface({
    required this.typeSystem,
    required this.element,
    required this.fields,
    required this.duplicateFieldNames,
  });

  _Constructor forConstructor({
    required DiagnosticReporter diagnosticReporter,
    required SourceRange errorRange,
    required ConstructorElement element,
    required bool isPrimary,
  }) {
    return constructors[element] ??= _Constructor(
      typeSystem: typeSystem,
      diagnosticReporter: diagnosticReporter,
      errorRange: errorRange,
      fields: {...fields},
      duplicateFieldNames: duplicateFieldNames,
      isPrimary: isPrimary,
    );
  }
}
