// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Keeps track of the set of non-synthetic child elements of an element,
/// yielding them one at a time in response to "get" method calls.
class ElementWalker {
  /// The element whose child elements are being walked.
  final Element element;

  List<PropertyAccessorElement> _accessors;
  int _accessorIndex = 0;
  List<ClassElement> _classes;
  int _classIndex = 0;
  List<ConstructorElement> _constructors;
  int _constructorIndex = 0;
  List<ClassElement> _enums;
  int _enumIndex = 0;
  List<ExtensionElement> _extensions;
  int _extensionIndex = 0;
  List<ExecutableElement> _functions;
  int _functionIndex = 0;
  List<ClassElement> _mixins;
  int _mixinIndex = 0;
  List<ParameterElement> _parameters;
  int _parameterIndex = 0;
  List<TypeAliasElement> _typedefs;
  int _typedefIndex = 0;
  List<TypeParameterElement> _typeParameters;
  int _typeParameterIndex = 0;
  List<VariableElement> _variables;
  int _variableIndex = 0;

  /// Creates an [ElementWalker] which walks the child elements of a class
  /// element.
  ElementWalker.forClass(ClassElement element)
      : element = element,
        _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _constructors = element.isMixinApplication
            ? null
            : element.constructors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forCompilationUnit(CompilationUnitElement element)
      : element = element,
        _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _classes = element.types,
        _enums = element.enums,
        _extensions = element.extensions,
        _functions = element.functions,
        _mixins = element.mixins,
        _typedefs = element.typeAliases,
        _variables = element.topLevelVariables.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forExecutable(ExecutableElement element)
      : element = element,
        _functions = const <ExecutableElement>[],
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of an extension
  /// element.
  ElementWalker.forExtension(ExtensionElement element)
      : element = element,
        _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forGenericFunctionType(GenericFunctionTypeElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element defined using a generic function type.
  ElementWalker.forGenericTypeAlias(TypeAliasElement element)
      : element = element,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a parameter
  /// element.
  ElementWalker.forParameter(ParameterElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forTypedef(FunctionTypeAliasElementImpl element)
      : element = element,
        _parameters = element.function.parameters,
        _typeParameters = element.typeParameters;

  void consumeLocalElements() {
    _functionIndex = _functions.length;
  }

  void consumeParameters() {
    _parameterIndex = _parameters.length;
  }

  /// Returns the next non-synthetic child of [element] which is an accessor;
  /// throws an [IndexError] if there are no more.
  PropertyAccessorElement getAccessor() => _accessors[_accessorIndex++];

  /// Returns the next non-synthetic child of [element] which is a class; throws
  /// an [IndexError] if there are no more.
  ClassElement getClass() => _classes[_classIndex++];

  /// Returns the next non-synthetic child of [element] which is a constructor;
  /// throws an [IndexError] if there are no more.
  ConstructorElement getConstructor() => _constructors[_constructorIndex++];

  /// Returns the next non-synthetic child of [element] which is an enum; throws
  /// an [IndexError] if there are no more.
  ClassElement getEnum() => _enums[_enumIndex++];

  ExtensionElement getExtension() => _extensions[_extensionIndex++];

  /// Returns the next non-synthetic child of [element] which is a top level
  /// function, method, or local function; throws an [IndexError] if there are
  /// no more.
  ExecutableElement getFunction() => _functions[_functionIndex++];

  /// Returns the next non-synthetic child of [element] which is a mixin; throws
  /// an [IndexError] if there are no more.
  ClassElement getMixin() => _mixins[_mixinIndex++];

  /// Returns the next non-synthetic child of [element] which is a parameter;
  /// throws an [IndexError] if there are no more.
  ParameterElement getParameter() => _parameters[_parameterIndex++];

  /// Returns the next non-synthetic child of [element] which is a typedef;
  /// throws an [IndexError] if there are no more.
  TypeAliasElement getTypedef() => _typedefs[_typedefIndex++];

  /// Returns the next non-synthetic child of [element] which is a type
  /// parameter; throws an [IndexError] if there are no more.
  TypeParameterElement getTypeParameter() =>
      _typeParameters[_typeParameterIndex++];

  /// Returns the next non-synthetic child of [element] which is a top level
  /// variable, field, or local variable; throws an [IndexError] if there are no
  /// more.
  VariableElement getVariable() => _variables[_variableIndex++];

  /// Verifies that all non-synthetic children of [element] have been obtained
  /// from their corresponding "get" method calls; if not, throws a
  /// [StateError].
  void validate() {
    void check(List<Element> elements, int index) {
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

  static bool _isNotSynthetic(Element e) => !e.isSynthetic;
}
