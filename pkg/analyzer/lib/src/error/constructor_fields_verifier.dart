// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Verifier for initializing fields in constructors.
class ConstructorFieldsVerifier {
  final TypeSystemImpl typeSystem;
  final Map<AugmentedInstanceElement, _Interface> _interfaces = Map.identity();

  ConstructorFieldsVerifier({
    required this.typeSystem,
  });

  void addConstructors(
    ErrorReporter errorReporter,
    AugmentedInstanceElement augmented,
    List<ClassMember> members,
  ) {
    var interfaceFields = _forInterface(augmented);
    var constructors = members.whereType<ConstructorDeclarationImpl>();
    for (var constructor in constructors) {
      _addConstructor(
        errorReporter: errorReporter,
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
    required ErrorReporter errorReporter,
    required _Interface interfaceFields,
    required ConstructorDeclarationImpl node,
  }) {
    if (node.factoryKeyword != null ||
        node.redirectedConstructor != null ||
        node.externalKeyword != null) {
      return;
    }

    var element = node.declaredElement!;
    var constructorState = interfaceFields.forConstructor(
      errorReporter: errorReporter,
      node: node,
      element: element,
    );
    if (constructorState == null) {
      return;
    }

    if (!element.isAugmentation) {
      constructorState.updateWithParameters(node);
    }

    constructorState.updateWithInitializers(errorReporter, node);
  }

  _Interface _forInterface(AugmentedInstanceElement augmented) {
    if (_interfaces[augmented] case var result?) {
      return result;
    }

    var fieldMap = <FieldElement, _InitState>{};

    for (var field in augmented.fields) {
      if (field.isSynthetic) {
        continue;
      }
      if (augmented is AugmentedEnumElement && field.name == 'index') {
        continue;
      }
      fieldMap[field] = field.hasInitializer
          ? _InitState.initInDeclaration
          : _InitState.notInit;
    }

    return _interfaces[augmented] = _Interface(
      typeSystem: typeSystem,
      augmented: augmented,
      fields: fieldMap,
    );
  }
}

class _Constructor {
  final TypeSystemImpl typeSystem;
  final ErrorReporter errorReporter;
  final ConstructorDeclaration node;
  final ConstructorElementImpl element;
  final Map<FieldElement, _InitState> fields;

  /// Set to `true` if the constructor redirects.
  bool hasRedirectingConstructorInvocation = false;

  _Constructor({
    required this.typeSystem,
    required this.errorReporter,
    required this.node,
    required this.element,
    required this.fields,
  });

  void report() {
    if (hasRedirectingConstructorInvocation) {
      return;
    }

    // Prepare lists of not initialized fields.
    var notInitFinalFields = <FieldElement>[];
    var notInitNonNullableFields = <FieldElement>[];
    fields.forEach((FieldElement field, _InitState state) {
      if (state != _InitState.notInit) return;
      if (field.isLate) return;
      if (field.isAbstract || field.isExternal) return;
      if (field.isStatic) return;

      if (field.isFinal) {
        notInitFinalFields.add(field);
      } else if (typeSystem.isPotentiallyNonNullable(field.type)) {
        notInitNonNullableFields.add(field);
      }
    });

    reportNotInitializedFinal(node, notInitFinalFields);
    reportNotInitializedNonNullable(node, notInitNonNullableFields);
  }

  void reportNotInitializedFinal(
    ConstructorDeclaration node,
    List<FieldElement> notInitFinalFields,
  ) {
    if (notInitFinalFields.isEmpty) {
      return;
    }

    var names = notInitFinalFields.map((item) => item.name).toList();
    names.sort();

    if (names.length == 1) {
      errorReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1,
        arguments: names,
      );
    } else if (names.length == 2) {
      errorReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2,
        arguments: names,
      );
    } else {
      errorReporter.atNode(
        node.returnType,
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS,
        arguments: [names[0], names[1], names.length - 2],
      );
    }
  }

  void reportNotInitializedNonNullable(
    ConstructorDeclaration node,
    List<FieldElement> notInitNonNullableFields,
  ) {
    if (notInitNonNullableFields.isEmpty) {
      return;
    }

    var names = notInitNonNullableFields.map((f) => f.name).toList();
    names.sort();

    for (var name in names) {
      errorReporter.atNode(
        node.returnType,
        CompileTimeErrorCode
            .NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR,
        arguments: [name],
      );
    }
  }

  void updateWithInitializers(
    ErrorReporter errorReporter,
    ConstructorDeclaration node,
  ) {
    for (var initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        hasRedirectingConstructorInvocation = true;
      }
      if (initializer is ConstructorFieldInitializer) {
        SimpleIdentifier fieldName = initializer.fieldName;
        var element = fieldName.staticElement;
        if (element is FieldElement) {
          var state = fields[element];
          if (state == _InitState.notInit) {
            fields[element] = _InitState.initInInitializer;
          } else if (state == _InitState.initInDeclaration) {
            if (element.isFinal || element.isConst) {
              errorReporter.atNode(
                fieldName,
                CompileTimeErrorCode
                    .FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
              );
            }
          } else if (state == _InitState.initInFieldFormal) {
            errorReporter.atNode(
              fieldName,
              CompileTimeErrorCode
                  .FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
            );
          } else if (state == _InitState.initInInitializer) {
            errorReporter.atNode(
              fieldName,
              CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
              arguments: [element.displayName],
            );
          }
        }
      }
    }
  }

  void updateWithParameters(
    ConstructorDeclaration node,
  ) {
    var formalParameters = node.parameters.parameters;
    for (var parameter in formalParameters) {
      parameter = parameter.notDefault;
      if (parameter is FieldFormalParameter) {
        var fieldElement =
            (parameter.declaredElement as FieldFormalParameterElementImpl)
                .field;
        if (fieldElement == null) {
          continue;
        }
        _InitState? state = fields[fieldElement];
        if (state == _InitState.notInit) {
          fields[fieldElement] = _InitState.initInFieldFormal;
        } else if (state == _InitState.initInDeclaration) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            errorReporter.atToken(
              parameter.name,
              CompileTimeErrorCode
                  .FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
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
  final AugmentedInstanceElement augmented;

  /// [_InitState.notInit] or [_InitState.initInDeclaration] for each field
  /// in [augmented]. This map works as the initial state for
  /// [_Constructor].
  final Map<FieldElement, _InitState> fields;

  final Map<ConstructorElementImpl, _Constructor> constructors = Map.identity();

  _Interface({
    required this.typeSystem,
    required this.augmented,
    required this.fields,
  });

  _Constructor? forConstructor({
    required ErrorReporter errorReporter,
    required ConstructorDeclaration node,
    required ConstructorElementImpl element,
  }) {
    var declaration = element.augmentedDeclaration;
    if (declaration == null) {
      return null;
    }

    return constructors[declaration] ??= _Constructor(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
      node: node,
      element: declaration,
      fields: {...fields},
    );
  }
}
