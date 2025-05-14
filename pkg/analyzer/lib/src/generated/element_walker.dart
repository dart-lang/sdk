// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';

/// Keeps track of the set of non-synthetic child fragments of a fragment,
/// yielding them one at a time in response to "get" method calls.
class ElementWalker {
  /// The fragment whose child fragments are being walked.
  final ElementImpl fragment;
  String? libraryFilePath;
  String? unitFilePath;

  List<PropertyAccessorElementImpl>? _accessors;
  int _accessorIndex = 0;
  List<ClassElementImpl>? _classes;
  int _classIndex = 0;
  List<ConstructorElementImpl>? _constructors;
  int _constructorIndex = 0;
  List<EnumElementImpl>? _enums;
  int _enumIndex = 0;
  List<ExtensionElementImpl>? _extensions;
  int _extensionIndex = 0;
  List<ExtensionTypeElementImpl>? _extensionTypes;
  int _extensionTypeIndex = 0;
  List<ExecutableElementImpl>? _functions;
  int _functionIndex = 0;
  List<MixinElementImpl>? _mixins;
  int _mixinIndex = 0;
  List<ParameterElementImpl>? _parameters;
  int _parameterIndex = 0;
  List<TypeAliasElementImpl>? _typedefs;
  int _typedefIndex = 0;
  List<TypeParameterElementImpl>? _typeParameters;
  int _typeParameterIndex = 0;
  List<VariableElementImpl>? _variables;
  int _variableIndex = 0;

  /// Creates an [ElementWalker] which walks the child elements of a class
  /// element.
  ElementWalker.forClass(ClassElementImpl this.fragment)
      : _accessors = fragment.accessors.where(_isNotSynthetic).toList(),
        _constructors = fragment.isMixinApplication
            ? null
            : fragment.constructors.where(_isNotSynthetic).toList(),
        _functions = fragment.methods,
        _typeParameters = fragment.typeParameters,
        _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forCompilationUnit(CompilationUnitElementImpl this.fragment,
      {this.libraryFilePath, this.unitFilePath})
      : _accessors = fragment.accessors.where(_isNotSynthetic).toList(),
        _classes = fragment.classes,
        _enums = fragment.enums,
        _extensions = fragment.extensions,
        _extensionTypes = fragment.extensionTypes,
        _functions = fragment.functions,
        _mixins = fragment.mixins,
        _typedefs = fragment.typeAliases,
        _variables = fragment.topLevelVariables.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a enum
  /// element.
  ElementWalker.forEnum(EnumElementImpl this.fragment)
      : _accessors = fragment.accessors.where(_isNotSynthetic).toList(),
        _constructors = fragment.constructors.where(_isNotSynthetic).toList(),
        _functions = fragment.methods,
        _typeParameters = fragment.typeParameters,
        _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forExecutable(ExecutableElementImpl this.fragment)
      : _functions = const <ExecutableElementImpl>[],
        _parameters = fragment.parameters,
        _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of an extension
  /// element.
  ElementWalker.forExtension(ExtensionElementImpl this.fragment)
      : _accessors = fragment.accessors.where(_isNotSynthetic).toList(),
        _functions = fragment.methods,
        _typeParameters = fragment.typeParameters,
        _variables = fragment.fields.where(_isNotSynthetic).toList();

  ElementWalker.forExtensionType(ExtensionTypeElementImpl this.fragment)
      : _accessors = fragment.accessors.where(_isNotSynthetic).toList(),
        _constructors = fragment.constructors,
        _functions = fragment.methods,
        _typeParameters = fragment.typeParameters,
        _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forGenericFunctionType(
      GenericFunctionTypeElementImpl this.fragment)
      : _parameters = fragment.parameters,
        _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element defined using a generic function type.
  ElementWalker.forGenericTypeAlias(TypeAliasElementImpl this.fragment)
      : _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a mixin
  /// element.
  ElementWalker.forMixin(MixinElementImpl this.fragment)
      : _accessors = fragment.accessors.where(_isNotSynthetic).toList(),
        _constructors = fragment.constructors.where(_isNotSynthetic).toList(),
        _functions = fragment.methods,
        _typeParameters = fragment.typeParameters,
        _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a parameter
  /// element.
  ElementWalker.forParameter(ParameterElementImpl this.fragment)
      : _parameters = fragment.parameters,
        _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forTypedef(TypeAliasElementImpl this.fragment)
      : _parameters =
            (fragment.aliasedElement as GenericFunctionTypeElementImpl)
                .parameters,
        _typeParameters = fragment.typeParameters;

  void consumeLocalElements() {
    _functionIndex = _functions!.length;
  }

  void consumeParameters() {
    _parameterIndex = _parameters!.length;
  }

  /// Returns the next non-synthetic child of [fragment] which is an accessor;
  /// throws an [IndexError] if there are no more.
  PropertyAccessorElementImpl getAccessor() {
    return _accessors![_accessorIndex++];
  }

  /// Returns the next non-synthetic child of [fragment] which is a class;
  /// throws an [IndexError] if there are no more.
  ClassElementImpl getClass() {
    return _classes![_classIndex++];
  }

  /// Returns the next non-synthetic child of [fragment] which is a constructor;
  /// throws an [IndexError] if there are no more.
  ConstructorElementImpl getConstructor() =>
      _constructors![_constructorIndex++];

  /// Returns the next non-synthetic child of [fragment] which is an enum;
  /// throws an [IndexError] if there are no more.
  EnumElementImpl getEnum() => _enums![_enumIndex++];

  ExtensionElementImpl getExtension() => _extensions![_extensionIndex++];

  ExtensionTypeElementImpl getExtensionType() =>
      _extensionTypes![_extensionTypeIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a top level
  /// function, method, or local function; throws an [IndexError] if there are
  /// no more.
  ExecutableElementImpl getFunction() => _functions![_functionIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a mixin;
  /// throws an [IndexError] if there are no more.
  MixinElementImpl getMixin() => _mixins![_mixinIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a parameter;
  /// throws an [IndexError] if there are no more.
  ParameterElementImpl getParameter() => _parameters![_parameterIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a typedef;
  /// throws an [IndexError] if there are no more.
  TypeAliasElementImpl getTypedef() => _typedefs![_typedefIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a type
  /// parameter; throws an [IndexError] if there are no more.
  TypeParameterElementImpl getTypeParameter() =>
      _typeParameters![_typeParameterIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a top level
  /// variable, field, or local variable; throws an [IndexError] if there are no
  /// more.
  VariableElementImpl getVariable() {
    return _variables![_variableIndex++];
  }

  /// Verifies that all non-synthetic children of [fragment] have been obtained
  /// from their corresponding "get" method calls; if not, throws a
  /// [StateError].
  void validate() {
    void check(List<ElementImpl>? elements, int index) {
      if (elements != null && elements.length != index) {
        throw StateError(
            'Unmatched ${elements[index].runtimeType} ${elements[index]}');
      }
    }

    check(_accessors, _accessorIndex);
    check(_classes, _classIndex);
    check(_constructors, _constructorIndex);
    check(_enums, _enumIndex);
    check(_functions, _functionIndex);
    check(_parameters, _parameterIndex);
    check(_typedefs, _typedefIndex);
    check(_typeParameters, _typeParameterIndex);
    check(_variables, _variableIndex);
  }

  static bool _isNotSynthetic(ElementImpl e) => !e.isSynthetic;
}
