// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Verifier for initializing fields in constructors.
class ConstructorFieldsVerifier {
  final TypeSystemImpl typeSystem;
  final Map<InstanceElement, _Interface> _interfaces = Map.identity();

  ConstructorFieldsVerifier({required this.typeSystem});

  void addConstructors(
    DiagnosticReporter diagnosticReporter,
    InterfaceElement element,
    List<ClassMember> members,
  ) {
    var interfaceFields = _forInterface(element);
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
      node: node,
      fragment: fragment,
    );

    if (!fragment.isAugmentation) {
      constructorState.updateWithParameters(node);
    }

    constructorState.updateWithInitializers(diagnosticReporter, node);
  }

  _Interface _forInterface(InterfaceElement element) {
    if (_interfaces[element] case var result?) {
      return result;
    }

    var fieldMap = <FieldElement, _InitState>{};

    for (var field in element.fields) {
      if (field.isSynthetic) {
        continue;
      }
      if (element is EnumElement && field.name == 'index') {
        continue;
      }
      fieldMap[field] = field.hasInitializer
          ? _InitState.initInDeclaration
          : _InitState.notInit;
    }

    return _interfaces[element] = _Interface(
      typeSystem: typeSystem,
      element: element,
      fields: fieldMap,
    );
  }
}

class _Constructor {
  final TypeSystemImpl typeSystem;
  final DiagnosticReporter diagnosticReporter;
  final ConstructorDeclaration node;
  final ConstructorElement element;
  final Map<FieldElement, _InitState> fields;

  /// Set to `true` if the constructor redirects.
  bool hasRedirectingConstructorInvocation = false;

  _Constructor({
    required this.typeSystem,
    required this.diagnosticReporter,
    required this.node,
    required this.element,
    required this.fields,
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

      if (field.isFinal) {
        notInitFinalFields.add(_Field(field, name));
      } else if (typeSystem.isPotentiallyNonNullable(field.type)) {
        notInitNonNullableFields.add(_Field(field, name));
      }
    });

    reportNotInitializedFinal(notInitFinalFields);
    reportNotInitializedNonNullable(notInitNonNullableFields);
  }

  void reportNotInitializedFinal(List<_Field> notInitFinalFields) {
    if (notInitFinalFields.isEmpty) {
      return;
    }

    var names = notInitFinalFields.map((f) => f.name).toList();
    names.sort();

    if (names.length == 1) {
      diagnosticReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.finalNotInitializedConstructor1,
        arguments: names,
      );
    } else if (names.length == 2) {
      diagnosticReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.finalNotInitializedConstructor2,
        arguments: names,
      );
    } else {
      diagnosticReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.finalNotInitializedConstructor3Plus,
        arguments: [names[0], names[1], names.length - 2],
      );
    }
  }

  void reportNotInitializedNonNullable(List<_Field> notInitNonNullableFields) {
    if (notInitNonNullableFields.isEmpty) {
      return;
    }

    var names = notInitNonNullableFields.map((f) => f.name).toList();
    names.sort();

    for (var name in names) {
      diagnosticReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.notInitializedNonNullableInstanceFieldConstructor,
        arguments: [name],
      );
    }
  }

  void updateWithInitializers(
    DiagnosticReporter diagnosticReporter,
    ConstructorDeclaration node,
  ) {
    for (var initializer in node.initializers) {
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
            if (fieldElement.isFinal || fieldElement.isConst) {
              diagnosticReporter.atNode(
                fieldName,
                CompileTimeErrorCode
                    .fieldInitializedInInitializerAndDeclaration,
              );
            }
          } else if (state == _InitState.initInFieldFormal) {
            diagnosticReporter.atNode(
              fieldName,
              CompileTimeErrorCode.fieldInitializedInParameterAndInitializer,
            );
          } else if (state == _InitState.initInInitializer) {
            diagnosticReporter.atNode(
              fieldName,
              CompileTimeErrorCode.fieldInitializedByMultipleInitializers,
              arguments: [fieldElement.displayName],
            );
          }
        }
      }
    }
  }

  void updateWithParameters(ConstructorDeclaration node) {
    var formalParameters = node.parameters.parameters;
    for (var formalParameter in formalParameters) {
      formalParameter = formalParameter.notDefault;
      if (formalParameter is FieldFormalParameterImpl) {
        var parameterFragment = formalParameter.declaredFragment!;
        var fieldElement = parameterFragment.element.field;
        if (fieldElement == null) {
          continue;
        }
        _InitState? state = fields[fieldElement];
        if (state == _InitState.notInit) {
          fields[fieldElement] = _InitState.initInFieldFormal;
        } else if (state == _InitState.initInDeclaration) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            diagnosticReporter.atToken(
              formalParameter.name,
              CompileTimeErrorCode.finalInitializedInDeclarationAndConstructor,
              arguments: [fieldElement.displayName],
            );
          }
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

  /// [_InitState.notInit] or [_InitState.initInDeclaration] for each field
  /// in [element]. This map works as the initial state for
  /// [_Constructor].
  final Map<FieldElement, _InitState> fields;

  final Map<ConstructorElement, _Constructor> constructors = Map.identity();

  _Interface({
    required this.typeSystem,
    required this.element,
    required this.fields,
  });

  _Constructor forConstructor({
    required DiagnosticReporter diagnosticReporter,
    required ConstructorDeclaration node,
    required ConstructorFragment fragment,
  }) {
    var element = fragment.element;
    return constructors[element] ??= _Constructor(
      typeSystem: typeSystem,
      diagnosticReporter: diagnosticReporter,
      node: node,
      element: element,
      fields: {...fields},
    );
  }
}
