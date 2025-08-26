// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';

/// Keeps track of the set of non-synthetic child fragments of a fragment,
/// yielding them one at a time in response to "get" method calls.
class ElementWalker {
  /// The fragment whose child fragments are being walked.
  final FragmentImpl fragment;
  String? libraryFilePath;
  String? unitFilePath;

  List<ClassFragmentImpl>? _classes;
  int _classIndex = 0;
  List<ConstructorFragmentImpl>? _constructors;
  int _constructorIndex = 0;
  List<EnumFragmentImpl>? _enums;
  int _enumIndex = 0;
  List<ExtensionFragmentImpl>? _extensions;
  int _extensionIndex = 0;
  List<ExtensionTypeFragmentImpl>? _extensionTypes;
  int _extensionTypeIndex = 0;
  List<ExecutableFragmentImpl>? _functions;
  int _functionIndex = 0;
  List<GetterFragmentImpl>? _getters;
  int _getterIndex = 0;
  List<MixinFragmentImpl>? _mixins;
  int _mixinIndex = 0;
  List<FormalParameterFragmentImpl>? _parameters;
  int _parameterIndex = 0;
  List<SetterFragmentImpl>? _setters;
  int _setterIndex = 0;
  List<TypeAliasFragmentImpl>? _typedefs;
  int _typedefIndex = 0;
  List<TypeParameterFragmentImpl>? _typeParameters;
  int _typeParameterIndex = 0;
  List<VariableFragmentImpl>? _variables;
  int _variableIndex = 0;

  /// Creates an [ElementWalker] which walks the child elements of a class
  /// element.
  ElementWalker.forClass(ClassFragmentImpl this.fragment)
    : _constructors = fragment.isMixinApplication
          ? null
          : fragment.constructors.where(_isNotSynthetic).toList(),
      _functions = fragment.methods,
      _getters = fragment.getters.where(_isNotSynthetic).toList(),
      _setters = fragment.setters.where(_isNotSynthetic).toList(),
      _typeParameters = fragment.typeParameters,
      _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forCompilationUnit(
    LibraryFragmentImpl this.fragment, {
    this.libraryFilePath,
    this.unitFilePath,
  }) : _classes = fragment.classes,
       _enums = fragment.enums,
       _extensions = fragment.extensions,
       _extensionTypes = fragment.extensionTypes,
       _functions = fragment.functions,
       _getters = fragment.getters.where(_isNotSynthetic).toList(),
       _mixins = fragment.mixins,
       _setters = fragment.setters.where(_isNotSynthetic).toList(),
       _typedefs = fragment.typeAliases,
       _variables = fragment.topLevelVariables.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a enum
  /// element.
  ElementWalker.forEnum(EnumFragmentImpl this.fragment)
    : _constructors = fragment.constructors.where(_isNotSynthetic).toList(),
      _functions = fragment.methods,
      _getters = fragment.getters.where(_isNotSynthetic).toList(),
      _setters = fragment.setters.where(_isNotSynthetic).toList(),
      _typeParameters = fragment.typeParameters,
      _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forExecutable(ExecutableFragmentImpl this.fragment)
    : _functions = const <ExecutableFragmentImpl>[],
      _parameters = fragment.formalParameters,
      _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of an extension
  /// element.
  ElementWalker.forExtension(ExtensionFragmentImpl this.fragment)
    : _functions = fragment.methods,
      _getters = fragment.getters.where(_isNotSynthetic).toList(),
      _setters = fragment.setters.where(_isNotSynthetic).toList(),
      _typeParameters = fragment.typeParameters,
      _variables = fragment.fields.where(_isNotSynthetic).toList();

  ElementWalker.forExtensionType(ExtensionTypeFragmentImpl this.fragment)
    : _constructors = fragment.constructors,
      _functions = fragment.methods,
      _getters = fragment.getters.where(_isNotSynthetic).toList(),
      _setters = fragment.setters.where(_isNotSynthetic).toList(),
      _typeParameters = fragment.typeParameters,
      _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forGenericFunctionType(
    GenericFunctionTypeFragmentImpl this.fragment,
  ) : _parameters = fragment.formalParameters,
      _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element defined using a generic function type.
  ElementWalker.forGenericTypeAlias(TypeAliasFragmentImpl this.fragment)
    : _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a mixin
  /// element.
  ElementWalker.forMixin(MixinFragmentImpl this.fragment)
    : _constructors = fragment.constructors.where(_isNotSynthetic).toList(),
      _functions = fragment.methods,
      _getters = fragment.getters.where(_isNotSynthetic).toList(),
      _setters = fragment.setters.where(_isNotSynthetic).toList(),
      _typeParameters = fragment.typeParameters,
      _variables = fragment.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a parameter
  /// element.
  ElementWalker.forParameter(FormalParameterFragmentImpl this.fragment)
    : _parameters = fragment.formalParameters,
      _typeParameters = fragment.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forTypedef(TypeAliasFragmentImpl this.fragment)
    : _parameters = (fragment.aliasedElement as GenericFunctionTypeFragmentImpl)
          .formalParameters,
      _typeParameters = fragment.typeParameters;

  void consumeLocalElements() {
    _functionIndex = _functions!.length;
  }

  void consumeParameters() {
    _parameterIndex = _parameters!.length;
  }

  /// Returns the next non-synthetic child of [fragment] which is a class;
  /// throws an [IndexError] if there are no more.
  ClassFragmentImpl getClass() {
    return _classes![_classIndex++];
  }

  /// Returns the next non-synthetic child of [fragment] which is a constructor;
  /// throws an [IndexError] if there are no more.
  ConstructorFragmentImpl getConstructor() =>
      _constructors![_constructorIndex++];

  /// Returns the next non-synthetic child of [fragment] which is an enum;
  /// throws an [IndexError] if there are no more.
  EnumFragmentImpl getEnum() => _enums![_enumIndex++];

  ExtensionFragmentImpl getExtension() => _extensions![_extensionIndex++];

  ExtensionTypeFragmentImpl getExtensionType() =>
      _extensionTypes![_extensionTypeIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a top level
  /// function, method, or local function; throws an [IndexError] if there are
  /// no more.
  ExecutableFragmentImpl getFunction() => _functions![_functionIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a getter;
  /// throws an [IndexError] if there are no more.
  GetterFragmentImpl getGetter() {
    return _getters![_getterIndex++];
  }

  /// Returns the next non-synthetic child of [fragment] which is a mixin;
  /// throws an [IndexError] if there are no more.
  MixinFragmentImpl getMixin() => _mixins![_mixinIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a parameter;
  /// throws an [IndexError] if there are no more.
  FormalParameterFragmentImpl getParameter() => _parameters![_parameterIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a setter;
  /// throws an [IndexError] if there are no more.
  SetterFragmentImpl getSetter() {
    return _setters![_setterIndex++];
  }

  /// Returns the next non-synthetic child of [fragment] which is a typedef;
  /// throws an [IndexError] if there are no more.
  TypeAliasFragmentImpl getTypedef() => _typedefs![_typedefIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a type
  /// parameter; throws an [IndexError] if there are no more.
  TypeParameterFragmentImpl getTypeParameter() =>
      _typeParameters![_typeParameterIndex++];

  /// Returns the next non-synthetic child of [fragment] which is a top level
  /// variable, field, or local variable; throws an [IndexError] if there are no
  /// more.
  VariableFragmentImpl getVariable() {
    return _variables![_variableIndex++];
  }

  /// Verifies that all non-synthetic children of [fragment] have been obtained
  /// from their corresponding "get" method calls; if not, throws a
  /// [StateError].
  void validate() {
    void check(List<FragmentImpl>? elements, int index) {
      if (elements != null && elements.length != index) {
        throw StateError(
          'Unmatched ${elements[index].runtimeType} ${elements[index]}',
        );
      }
    }

    check(_classes, _classIndex);
    check(_constructors, _constructorIndex);
    check(_enums, _enumIndex);
    check(_functions, _functionIndex);
    check(_getters, _getterIndex);
    check(_parameters, _parameterIndex);
    check(_setters, _setterIndex);
    check(_typedefs, _typedefIndex);
    check(_typeParameters, _typeParameterIndex);
    check(_variables, _variableIndex);
  }

  static bool _isNotSynthetic(FragmentImpl e) => !e.isSynthetic;
}
