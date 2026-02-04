// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/invokes_super_self.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';

class ElementBuilder {
  final LibraryBuilder libraryBuilder;

  ElementBuilder({required this.libraryBuilder});

  LibraryElementImpl get libraryElement => libraryBuilder.element;

  void buildElements({
    required Map<LibraryFragmentImpl, List<FragmentImpl>> topFragments,
    required Map<FragmentImpl, List<FragmentImpl>> parentChildFragments,
  }) {
    _buildTopFragments(topFragments);
    _buildInstanceElementMembers(parentChildFragments);
  }

  /// The [kind] is for example `@method`.
  Reference _addInstanceReference(
    InstanceElementImpl element,
    String kind,
    String? name,
  ) {
    var refName = libraryBuilder.getReferenceName(name);
    return element.reference!.getChild(kind).addChild(refName);
  }

  /// The [kind] is for example `@topLevelVariable`.
  Reference _addTopReference(String kind, String? name) {
    var refName = libraryBuilder.getReferenceName(name);
    return libraryBuilder.reference.getChild(kind).addChild(refName);
  }

  void _buildInstanceElementMembers(
    Map<FragmentImpl, List<FragmentImpl>> parentChildFragments,
  ) {
    var elementChildFragments =
        Map<InstanceElementImpl, List<FragmentImpl>>.identity();

    for (var entry in parentChildFragments.entries) {
      var element = entry.key.element;
      if (element is InstanceElementImpl) {
        (elementChildFragments[element] ??= []).addAll(entry.value);
      }
    }

    for (var instanceEntry in elementChildFragments.entries) {
      var instanceElement = instanceEntry.key;
      var lastFragments = <String?, FragmentImpl>{};
      for (var fragment in instanceEntry.value) {
        var lastFragment = lastFragments[fragment.name];
        switch (fragment) {
          case FieldFragmentImpl():
            _handleInstanceFieldFragment(
              instanceElement,
              lastFragment,
              fragment,
            );
          case GetterFragmentImpl():
            _handleInstanceGetterFragment(
              instanceElement,
              lastFragment,
              fragment,
            );
          case SetterFragmentImpl():
            _handleInstanceSetterFragment(
              instanceElement,
              lastFragment,
              fragment,
            );
          case MethodFragmentImpl():
            _handleInstanceMethodFragment(
              instanceElement,
              lastFragment,
              fragment,
            );
          case ConstructorFragmentImpl():
            _handleInstanceConstructorFragment(
              instanceElement as InterfaceElementImpl,
              lastFragment,
              fragment,
            );
          default:
            throw UnimplementedError('${fragment.runtimeType}');
        }
        lastFragments[fragment.name] = fragment;
      }

      // Mark extension type members.
      if (instanceElement is ExtensionTypeElementImpl) {
        for (var executable in instanceElement.children) {
          if (executable case ExecutableElementImpl executable) {
            executable.isExtensionTypeMember = true;
          }
        }
      }
    }
  }

  void _buildTopFragments(
    Map<LibraryFragmentImpl, List<FragmentImpl>> topFragments,
  ) {
    var lastFragments = <String?, FragmentImpl>{};
    for (var libraryFragmentEntry in topFragments.entries) {
      var libraryFragment = libraryFragmentEntry.key;
      for (var fragment in libraryFragmentEntry.value) {
        var lastFragment = lastFragments[fragment.name];
        switch (fragment) {
          case ClassFragmentImpl():
            _handleClassFragment(libraryFragment, lastFragment, fragment);
          case EnumFragmentImpl():
            _handleEnumFragment(libraryFragment, lastFragment, fragment);
          case ExtensionFragmentImpl():
            _handleExtensionFragment(libraryFragment, lastFragment, fragment);
          case ExtensionTypeFragmentImpl():
            _handleExtensionTypeFragment(
              libraryFragment,
              lastFragment,
              fragment,
            );
          case GetterFragmentImpl():
            _handleTopLevelGetterFragment(
              libraryFragment,
              lastFragment,
              fragment,
            );
          case MixinFragmentImpl():
            _handleMixinFragment(libraryFragment, lastFragment, fragment);
          case SetterFragmentImpl():
            _handleTopLevelSetterFragment(
              libraryFragment,
              lastFragment,
              fragment,
            );
          case TopLevelFunctionFragmentImpl():
            _handleTopLevelFunctionFragment(
              libraryFragment,
              lastFragment,
              fragment,
            );
          case TopLevelVariableFragmentImpl():
            _handleTopLevelVariableFragment(
              libraryFragment,
              lastFragment,
              fragment,
            );
          case TypeAliasFragmentImpl():
            _handleTypeAliasFragment(libraryFragment, fragment);
          default:
            throw UnimplementedError('${fragment.runtimeType}');
        }
        lastFragments[fragment.name] = fragment;
      }
    }
  }

  FieldElementImpl? _fieldElement(FragmentImpl? fragment) {
    switch (fragment) {
      case FieldFragmentImpl():
        return fragment.element;
      case GetterFragmentImpl():
        return fragment.element.variable.tryCast();
      case SetterFragmentImpl():
        return fragment.element.variable.tryCast();
    }
    return null;
  }

  void _handleClassFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    ClassFragmentImpl fragment,
  ) {
    libraryFragment.addClass(fragment);

    if (fragment.isAugmentation && lastFragment is ClassFragmentImpl) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );
      return;
    }

    var element = ClassElementImpl(
      _addTopReference('@class', fragment.name),
      fragment,
    );

    for (var typeParameterFragment in fragment.typeParameters) {
      // Side effect: set element for the fragment.
      TypeParameterElementImpl(firstFragment: typeParameterFragment);
    }

    libraryElement.addClass(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleEnumFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    EnumFragmentImpl fragment,
  ) {
    libraryFragment.addEnum(fragment);

    if (fragment.isAugmentation && lastFragment is EnumFragmentImpl) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      return;
    }

    var element = EnumElementImpl(
      _addTopReference('@enum', fragment.name),
      fragment,
    );

    libraryElement.addEnum(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleExtensionFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    ExtensionFragmentImpl fragment,
  ) {
    libraryFragment.addExtension(fragment);

    if (fragment.isAugmentation && lastFragment is ExtensionFragmentImpl) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      return;
    }

    var element = ExtensionElementImpl(
      _addTopReference('@extension', fragment.name),
      fragment,
    );
    libraryElement.addExtension(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleExtensionTypeFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    ExtensionTypeFragmentImpl fragment,
  ) {
    libraryFragment.addExtensionType(fragment);

    if (fragment.isAugmentation && lastFragment is ExtensionTypeFragmentImpl) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      return;
    }

    var element = ExtensionTypeElementImpl(
      _addTopReference('@extensionType', fragment.name),
      fragment,
    );
    libraryElement.addExtensionType(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleInstanceConstructorFragment(
    InterfaceElementImpl interfaceElement,
    FragmentImpl? lastFragment,
    ConstructorFragmentImpl fragment,
  ) {
    var interfaceFragment = fragment.enclosingFragment;
    interfaceFragment.addConstructor(fragment);

    if (fragment.isAugmentation && lastFragment is ConstructorFragmentImpl) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      fragment.formalParameters = _linkFormalParameters(
        previousFragments: lastFragment.formalParameters,
        currentFragments: fragment.formalParameters,
      );

      return;
    }

    var element = ConstructorElementImpl(
      name: fragment.name,
      reference: _addInstanceReference(
        interfaceElement,
        '@constructor',
        fragment.name,
      ),
      firstFragment: fragment,
    );

    interfaceElement.addConstructor(element);
  }

  void _handleInstanceFieldFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    FieldFragmentImpl fieldFragment,
  ) {
    var instanceFragment = fieldFragment.enclosingFragment;

    // Move elements of `values` from augmentation to the first fragment.
    if (fieldFragment.name == 'values' &&
        instanceFragment is EnumFragmentImpl &&
        instanceFragment.previousFragment != null) {
      var implicitsMap = libraryBuilder.implicitEnumNodes;
      var augmentationImplicit = implicitsMap.remove(instanceFragment)!;
      var firstFragment = instanceFragment.element.firstFragment;
      var firstImplicit = implicitsMap[firstFragment]!;
      firstImplicit.valuesInitializer.addElements(
        augmentationImplicit.valuesInitializer.elements,
      );
      return;
    }

    instanceFragment.addField(fieldFragment);

    var lastFieldElement = _fieldElement(lastFragment);
    var lastFieldFragment = lastFieldElement?.lastFragment;

    if (fieldFragment.isAugmentation &&
        lastFieldFragment is FieldFragmentImpl) {
      lastFieldFragment.addFragment(fieldFragment);
      return;
    }

    var fieldElement = FieldElementImpl(
      reference: _addInstanceReference(
        instanceElement,
        '@field',
        fieldFragment.name,
      ),
      firstFragment: fieldFragment,
    );
    instanceElement.addField(fieldElement);

    {
      var getterFragment = GetterFragmentImpl(name: fieldFragment.name)
        ..isOriginVariable = true
        ..isSynthetic = true
        ..isAbstract = fieldFragment.isAbstract
        ..isStatic = fieldFragment.isStatic;
      instanceFragment.addGetter(getterFragment);

      var getterElement = GetterElementImpl(
        _addInstanceReference(instanceElement, '@getter', fieldFragment.name),
        getterFragment,
      );
      instanceElement.addGetter(getterElement);

      fieldElement.getter = getterElement;
      getterElement.variable = fieldElement;
    }

    if (fieldFragment.hasSetter) {
      var setterFragment = SetterFragmentImpl(name: fieldFragment.name)
        ..isOriginVariable = true
        ..isSynthetic = true
        ..isAbstract = fieldFragment.isAbstract
        ..isStatic = fieldFragment.isStatic;
      instanceFragment.addSetter(setterFragment);

      var valueFragment = FormalParameterFragmentImpl(
        name: 'value',
        nameOffset: null,
        parameterKind: ParameterKind.REQUIRED,
      );
      valueFragment.isExplicitlyCovariant = fieldFragment.isExplicitlyCovariant;
      setterFragment.formalParameters = [valueFragment];

      var setterElement = SetterElementImpl(
        _addInstanceReference(instanceElement, '@setter', fieldFragment.name),
        setterFragment,
      );
      instanceElement.addSetter(setterElement);

      FormalParameterElementImpl(valueFragment);

      fieldElement.setter = setterElement;
      setterElement.variable = fieldElement;
    }
  }

  void _handleInstanceGetterFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    GetterFragmentImpl getterFragment,
  ) {
    assert(getterFragment.isOriginDeclaration);

    var instanceFragment =
        getterFragment.enclosingFragment as InstanceFragmentImpl;
    instanceFragment.addGetter(getterFragment);

    var lastFieldElement = _fieldElement(lastFragment);
    var lastGetterFragment = lastFieldElement?.getter?.lastFragment;

    if (getterFragment.isAugmentation && lastGetterFragment != null) {
      lastGetterFragment.addFragment(getterFragment);
      return;
    }

    // Not augmentation, create new element.
    var getterElement = GetterElementImpl(
      _addInstanceReference(instanceElement, '@getter', getterFragment.name),
      getterFragment,
    );
    instanceElement.addGetter(getterElement);

    // `class Enum {}` in `dart:core` declares `int get index` as abstract.
    // But the specification says that practically a different class
    // implementing `Enum` is used as a superclass, so `index` should be
    // considered to have non-abstract implementation.
    if (instanceElement is ClassElementImpl &&
        instanceElement.isDartCoreEnum &&
        getterFragment.name == 'index') {
      getterFragment.isAbstract = false;
    }

    // If `getter` is already set, this is a compile-time error.
    // Reset to `null`, so create a new variable.
    if (lastFieldElement != null) {
      if (lastFieldElement.getter != null) {
        lastFieldElement = null;
      }
    }

    if (lastFieldElement == null) {
      var fieldFragment = FieldFragmentImpl(name: getterFragment.name)
        ..isOriginGetterSetter = true
        ..isSynthetic = true
        ..isStatic = getterFragment.isStatic;
      instanceFragment.addField(fieldFragment);

      lastFieldElement = FieldElementImpl(
        reference: _addInstanceReference(
          instanceElement,
          '@field',
          getterFragment.name,
        ),

        firstFragment: fieldFragment,
      );
      instanceElement.addField(lastFieldElement);
    }

    getterElement.variable = lastFieldElement;
    lastFieldElement.getter = getterElement;
  }

  void _handleInstanceMethodFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    MethodFragmentImpl fragment,
  ) {
    var instanceFragment = fragment.enclosingFragment;
    instanceFragment.addMethod(fragment);

    if (lastFragment is MethodFragmentImpl && fragment.isAugmentation) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      fragment.formalParameters = _linkFormalParameters(
        previousFragments: lastFragment.formalParameters,
        currentFragments: fragment.formalParameters,
      );

      return;
    }

    for (var typeParameterFragment in fragment.typeParameters) {
      // Side effect: set element for the fragment.
      TypeParameterElementImpl(firstFragment: typeParameterFragment);
    }

    instanceElement.addMethod(
      MethodElementImpl(
        name: fragment.name,
        reference: _addInstanceReference(
          instanceElement,
          '@method',
          fragment.lookupName,
        ),
        firstFragment: fragment,
      ),
    );
  }

  void _handleInstanceSetterFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    SetterFragmentImpl setterFragment,
  ) {
    assert(setterFragment.isOriginDeclaration);

    var instanceFragment =
        setterFragment.enclosingFragment as InstanceFragmentImpl;
    instanceFragment.addSetter(setterFragment);

    var lastFieldElement = _fieldElement(lastFragment);
    var lastSetterFragment = lastFieldElement?.setter?.lastFragment;

    if (setterFragment.isAugmentation && lastSetterFragment != null) {
      lastSetterFragment.addFragment(setterFragment);
      return;
    }

    // Not augmentation, create new element.
    var setterElement = SetterElementImpl(
      _addInstanceReference(instanceElement, '@setter', setterFragment.name),
      setterFragment,
    );
    instanceElement.addSetter(setterElement);

    // If `setter` is already set, this is a compile-time error.
    // Reset to `null`, so create a new variable.
    if (lastFieldElement != null) {
      if (lastFieldElement.setter != null) {
        lastFieldElement = null;
      }
    }

    if (lastFieldElement == null) {
      var fieldFragment = FieldFragmentImpl(name: setterFragment.name)
        ..isOriginGetterSetter = true
        ..isSynthetic = true
        ..isStatic = setterFragment.isStatic;
      instanceFragment.addField(fieldFragment);

      lastFieldElement = FieldElementImpl(
        reference: _addInstanceReference(
          instanceElement,
          '@field',
          setterFragment.name,
        ),
        firstFragment: fieldFragment,
      );
      instanceElement.addField(lastFieldElement);
    }

    setterElement.variable = lastFieldElement;
    lastFieldElement.setter = setterElement;
  }

  void _handleMixinFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    MixinFragmentImpl fragment,
  ) {
    libraryFragment.addMixin(fragment);
    if (fragment.isAugmentation && lastFragment is MixinFragmentImpl) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      return;
    }

    var element = MixinElementImpl(
      _addTopReference('@mixin', fragment.name),
      fragment,
    );

    for (var typeParameterFragment in fragment.typeParameters) {
      // Side effect: set element for the fragment.
      TypeParameterElementImpl(firstFragment: typeParameterFragment);
    }

    libraryElement.addMixin(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleTopLevelFunctionFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    TopLevelFunctionFragmentImpl fragment,
  ) {
    libraryFragment.addFunction(fragment);

    if (lastFragment is TopLevelFunctionFragmentImpl &&
        fragment.isAugmentation) {
      lastFragment.addFragment(fragment);

      _linkTypeParameters(
        lastFragments: lastFragment.typeParameters,
        fragments: fragment.typeParameters,
        add: fragment.addTypeParameter,
      );

      fragment.formalParameters = _linkFormalParameters(
        previousFragments: lastFragment.formalParameters,
        currentFragments: fragment.formalParameters,
      );
      return;
    }

    var element = TopLevelFunctionElementImpl(
      _addTopReference('@function', fragment.name),
      fragment,
    );
    libraryElement.addTopLevelFunction(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleTopLevelGetterFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    GetterFragmentImpl getterFragment,
  ) {
    assert(getterFragment.isOriginDeclaration);
    libraryFragment.addGetter(getterFragment);

    var lastVariableElement = _topLevelVariableElement(lastFragment);
    var lastGetterFragment = lastVariableElement?.getter?.lastFragment;

    if (getterFragment.isAugmentation && lastGetterFragment != null) {
      lastGetterFragment.addFragment(getterFragment);
      return;
    }

    // Not augmentation, create new element.
    var getterElement = GetterElementImpl(
      _addTopReference('@getter', getterFragment.name),
      getterFragment,
    );
    libraryElement.addGetter(getterElement);
    libraryBuilder.declare(getterElement, getterElement.reference);

    // If `getter` is already set, this is a compile-time error.
    // Reset to `null`, so create a new variable.
    if (lastVariableElement != null) {
      if (lastVariableElement.getter != null) {
        lastVariableElement = null;
      }
    }

    if (lastVariableElement == null) {
      var variableFragment =
          TopLevelVariableFragmentImpl(name: getterFragment.name)
            ..isOriginGetterSetter = true
            ..isSynthetic = true;
      libraryFragment.addTopLevelVariable(variableFragment);

      lastVariableElement = TopLevelVariableElementImpl(
        _addTopReference('@topLevelVariable', getterFragment.name),
        variableFragment,
      );
      libraryElement.addTopLevelVariable(lastVariableElement);
    }

    getterElement.variable = lastVariableElement;
    lastVariableElement.getter = getterElement;
  }

  void _handleTopLevelSetterFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    SetterFragmentImpl setterFragment,
  ) {
    assert(setterFragment.isOriginDeclaration);
    libraryFragment.addSetter(setterFragment);

    var lastVariableElement = _topLevelVariableElement(lastFragment);
    var lastSetterFragment = lastVariableElement?.setter?.lastFragment;

    if (setterFragment.isAugmentation &&
        lastSetterFragment is SetterFragmentImpl) {
      lastSetterFragment.addFragment(setterFragment);
      return;
    }

    // Not augmentation, create new element.
    var setterElement = SetterElementImpl(
      _addTopReference('@setter', setterFragment.name),
      setterFragment,
    );
    libraryElement.addSetter(setterElement);
    libraryBuilder.declare(setterElement, setterElement.reference);

    // If `setter` is already set, this is a compile-time error.
    // Reset to `null`, so create a new variable.
    if (lastVariableElement != null) {
      if (lastVariableElement.setter != null) {
        lastVariableElement = null;
      }
    }

    if (lastVariableElement == null) {
      var variableFragment =
          TopLevelVariableFragmentImpl(name: setterFragment.name)
            ..isOriginGetterSetter = true
            ..isSynthetic = true;
      libraryFragment.addTopLevelVariable(variableFragment);

      lastVariableElement = TopLevelVariableElementImpl(
        _addTopReference('@topLevelVariable', setterFragment.name),
        variableFragment,
      );
      libraryElement.addTopLevelVariable(lastVariableElement);
    }

    setterElement.variable = lastVariableElement;
    lastVariableElement.setter = setterElement;
  }

  void _handleTopLevelVariableFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    TopLevelVariableFragmentImpl variableFragment,
  ) {
    assert(variableFragment.isOriginDeclaration);
    libraryFragment.addTopLevelVariable(variableFragment);

    var lastVariableElement = _topLevelVariableElement(lastFragment);

    if (variableFragment.isAugmentation && lastVariableElement != null) {
      lastVariableElement.lastFragment.addFragment(variableFragment);
      return;
    }

    var variableElement = TopLevelVariableElementImpl(
      _addTopReference('@topLevelVariable', variableFragment.name),
      variableFragment,
    );
    libraryElement.addTopLevelVariable(variableElement);

    {
      var getterFragment = GetterFragmentImpl(name: variableFragment.name)
        ..isOriginVariable = true
        ..isSynthetic = true
        ..isStatic = true;
      libraryFragment.addGetter(getterFragment);

      var getterElement = GetterElementImpl(
        _addTopReference('@getter', variableFragment.name),
        getterFragment,
      );
      libraryElement.addGetter(getterElement);
      libraryBuilder.declare(getterElement, getterElement.reference);

      variableElement.getter = getterElement;
      getterElement.variable = variableElement;
    }

    if (variableFragment.hasSetter) {
      var setterFragment = SetterFragmentImpl(name: variableFragment.name)
        ..isOriginVariable = true
        ..isSynthetic = true
        ..isStatic = true;
      libraryFragment.addSetter(setterFragment);

      var valueFragment = FormalParameterFragmentImpl(
        name: 'value',
        nameOffset: null,
        parameterKind: ParameterKind.REQUIRED,
      );
      setterFragment.formalParameters = [valueFragment];

      var setterElement = SetterElementImpl(
        _addTopReference('@setter', variableFragment.name),
        setterFragment,
      );
      libraryElement.addSetter(setterElement);
      libraryBuilder.declare(setterElement, setterElement.reference);

      FormalParameterElementImpl(valueFragment);

      variableElement.setter = setterElement;
      setterElement.variable = variableElement;
    }
  }

  void _handleTypeAliasFragment(
    LibraryFragmentImpl libraryFragment,
    TypeAliasFragmentImpl fragment,
  ) {
    libraryFragment.addTypeAlias(fragment);

    var element = TypeAliasElementImpl(
      _addTopReference('@typeAlias', fragment.name),
      fragment,
    );
    libraryElement.typeAliases.add(element);
    libraryBuilder.declare(element, element.reference);
  }

  List<FormalParameterFragmentImpl> _linkFormalParameters({
    required List<FormalParameterFragmentImpl> previousFragments,
    required List<FormalParameterFragmentImpl> currentFragments,
  }) {
    int getPositionalSize(List<FormalParameterFragmentImpl> fragments) {
      return fragments.takeWhile((f) => f.isPositional).length;
    }

    FormalParameterFragmentImpl createFragment(
      FormalParameterFragmentImpl previousParameter,
    ) {
      switch (previousParameter) {
        case FieldFormalParameterFragmentImpl():
          return FieldFormalParameterFragmentImpl(
            name: previousParameter.name,
            nameOffset: null,
            parameterKind: previousParameter.parameterKind,
            privateName: previousParameter.privateName,
          )..isSynthetic = true;
        case SuperFormalParameterFragmentImpl():
          return SuperFormalParameterFragmentImpl(
            name: previousParameter.name,
            nameOffset: null,
            parameterKind: previousParameter.parameterKind,
          )..isSynthetic = true;
        default:
          return FormalParameterFragmentImpl(
            name: previousParameter.name,
            nameOffset: null,
            parameterKind: previousParameter.parameterKind,
          )..isSynthetic = true;
      }
    }

    var currentPositionalSize = getPositionalSize(currentFragments);
    var resultPositional = currentFragments.sublist(0, currentPositionalSize);
    var currentNamed = currentFragments.sublist(currentPositionalSize);

    var previousPositionalSize = getPositionalSize(previousFragments);
    var previousPositional = previousFragments.sublist(
      0,
      previousPositionalSize,
    );
    var previousNamed = previousFragments.sublist(previousPositionalSize);

    // Trim extra positional parameters.
    if (previousPositionalSize < currentPositionalSize) {
      resultPositional.length = previousPositional.length;
    }

    // Synthesize missing positional parameters.
    if (previousPositional.length > resultPositional.length) {
      for (var i = currentPositionalSize; i < previousPositionalSize; i++) {
        var previousParameter = previousPositional[i];
        resultPositional.add(createFragment(previousParameter));
      }
    }

    for (var i = 0; i < resultPositional.length; i++) {
      previousPositional[i].addFragment(resultPositional[i]);
    }

    var resultNamed = <FormalParameterFragmentImpl>[];
    var previousNamedMap = <String, List<FormalParameterFragmentImpl>>{};
    for (var previousParameter in previousNamed) {
      (previousNamedMap[previousParameter.name!] ??=
              <FormalParameterFragmentImpl>[])
          .add(previousParameter);
    }

    // Link common formal parameters between previous and current fragments.
    for (var currentParameter in currentNamed) {
      var previousParameters = previousNamedMap[currentParameter.name];
      if (previousParameters != null && previousParameters.isNotEmpty) {
        var previousParameter = previousParameters.removeAt(0);
        previousParameter.addFragment(currentParameter);
        resultNamed.add(currentParameter);
      }
    }

    // Synthesize missing named parameters.
    for (var previousParameters in previousNamedMap.values) {
      for (var previousParameter in previousParameters) {
        var parameter = createFragment(previousParameter);
        previousParameter.addFragment(parameter);
        resultNamed.add(parameter);
      }
    }

    return [...resultPositional, ...resultNamed];
  }

  void _linkTypeParameters({
    required List<TypeParameterFragmentImpl> lastFragments,
    required List<TypeParameterFragmentImpl> fragments,
    required void Function(TypeParameterFragmentImpl) add,
  }) {
    // Trim extra type parameters.
    if (lastFragments.length < fragments.length) {
      fragments.length = lastFragments.length;
    }

    // Synthesize missing type parameters.
    if (lastFragments.length > fragments.length) {
      for (var i = fragments.length; i < lastFragments.length; i++) {
        add(
          TypeParameterFragmentImpl(name: lastFragments[i].name)
            ..isSynthetic = true,
        );
      }
    }

    for (var i = 0; i < lastFragments.length; i++) {
      lastFragments[i].addFragment(fragments[i]);
    }
  }

  TopLevelVariableElementImpl? _topLevelVariableElement(
    FragmentImpl? fragment,
  ) {
    switch (fragment) {
      case TopLevelVariableFragmentImpl():
        return fragment.element;
      case GetterFragmentImpl():
        return fragment.element.variable.tryCast();
      case SetterFragmentImpl():
        return fragment.element.variable.tryCast();
    }
    return null;
  }
}

class FragmentBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final LibraryFragmentImpl _libraryFragment;

  var _exportDirectiveIndex = 0;
  var _importDirectiveIndex = 0;
  var _partDirectiveIndex = 0;

  _EnclosingContext _enclosingContext;

  FragmentBuilder({
    required LibraryBuilder libraryBuilder,
    required LibraryFragmentImpl libraryFragment,
  }) : _libraryBuilder = libraryBuilder,
       _libraryFragment = libraryFragment,
       _enclosingContext = _EnclosingContext(fragment: libraryFragment);

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationFragments(CompilationUnit unit) {
    unit.declarations.accept(this);
  }

  /// Builds exports and imports, metadata into [_libraryFragment].
  void buildDirectives(CompilationUnitImpl unit) {
    unit.directives.accept(this);
  }

  /// Updates metadata and documentation for [_libraryBuilder].
  ///
  /// This method must be invoked after [buildDirectives].
  void buildLibraryMetadata(CompilationUnitImpl unit) {
    var libraryElement = _libraryBuilder.element;

    // Prefer the actual library directive.
    var libraryDirective = unit.directives
        .whereType<LibraryDirectiveImpl>()
        .firstOrNull;
    if (libraryDirective != null) {
      libraryDirective.element = libraryElement;
      libraryElement.metadata = _buildMetadata(libraryDirective.metadata);
      return;
    }

    // Otherwise use the first directive.
    var firstDirective = unit.directives.firstOrNull;
    if (firstDirective != null) {
      MetadataImpl? firstDirectiveMetadata;
      switch (firstDirective) {
        case ExportDirectiveImpl():
          firstDirectiveMetadata = firstDirective.libraryExport?.metadata;
        case ImportDirectiveImpl():
          firstDirectiveMetadata = firstDirective.libraryImport?.metadata;
        case PartDirectiveImpl():
          firstDirectiveMetadata = firstDirective.partInclude?.metadata;
        case LibraryDirectiveImpl():
          // Impossible, since there is no library directive.
          break;
        case PartOfDirectiveImpl():
          // Can only occur in erroneous code (this is the defining
          // compilation unit)
          break;
      }
      if (firstDirectiveMetadata != null) {
        libraryElement.metadata = firstDirectiveMetadata;
      }
    }
  }

  @override
  void visitBlockClassBody(BlockClassBody node) {
    node.members.accept(this);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var nameToken = node.namePart.typeName;
    var fragmentName = _getFragmentName(nameToken);
    var fragment = ClassFragmentImpl(name: fragmentName);
    fragment.isAbstract = node.abstractKeyword != null;
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.isFinal = node.finalKeyword != null;
    fragment.isInterface = node.interfaceKeyword != null;
    fragment.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      fragment.isAbstract = true;
      fragment.isSealed = true;
    }
    fragment.hasExtendsClause = node.extendsClause != null;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      node.namePart.accept(this);
      node.body.accept(this);
    });
    fragment.typeParameters = holder.typeParameters;

    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var nameToken = node.name;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ClassFragmentImpl(name: fragmentName);
    fragment.isAbstract = node.abstractKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.isFinal = node.finalKeyword != null;
    fragment.isInterface = node.interfaceKeyword != null;
    fragment.isMixinApplication = true;
    fragment.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      fragment.isAbstract = true;
      fragment.isSealed = true;
    }
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    node.superclass.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragmentName = _getFragmentName(node.name) ?? 'new';
    var fragment = ConstructorFragmentImpl(name: fragmentName);
    fragment.isOriginDeclaration = true;
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isConst = node.constKeyword != null;
    fragment.isExternal = node.externalKeyword != null;
    fragment.isFactory = node.factoryKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    fragment.typeName = node.typeName?.name;

    if (fragment.isConst || fragment.isFactory) {
      fragment.constantInitializers = node.initializers;
    }

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _addChildFragment(fragment);

    _buildExecutableElementChildren(
      fragment: fragment,
      formalParameters: node.parameters,
    );
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {}

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var nameToken = node.namePart.typeName;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = EnumFragmentImpl(name: fragmentName);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      // Build fields for all enum constants.
      var constants = node.body.constants;
      var valuesElements = <SimpleIdentifierImpl>[];
      var valuesNames = <String>{};
      for (var i = 0; i < constants.length; ++i) {
        var constant = constants[i];
        var nameToken = constant.name;
        var name = nameToken.lexeme;
        var field = FieldFragmentImpl(name: _getFragmentName(nameToken))
          ..hasImplicitType = true
          ..hasInitializer = true
          ..isAugmentation = constant.augmentKeyword != null
          ..isConst = true
          ..isEnumConstant = true
          ..isOriginDeclaration = true
          ..isStatic = true;
        field.metadata = _buildMetadata(constant.metadata);

        var constantArguments = constant.arguments;
        var constructorSelector = constantArguments?.constructorSelector;
        var constructorName = constructorSelector?.name.name;

        var initializer = InstanceCreationExpressionImpl(
          keyword: null,
          constructorName: ConstructorNameImpl(
            type: NamedTypeImpl(
              importPrefix: null,
              name: StringToken(TokenType.STRING, fragment.name ?? '', -1),
              typeArguments: constantArguments?.typeArguments,
              question: null,
            ),
            period: constructorName != null ? Tokens.period() : null,
            name: constructorName != null
                ? SimpleIdentifierImpl(
                    token: StringToken(TokenType.STRING, constructorName, -1),
                  )
                : null,
          ),
          argumentList: constantArguments != null
              ? constantArguments.argumentList
              : ArgumentListImpl(
                  leftParenthesis: Tokens.openParenthesis(),
                  arguments: [],
                  rightParenthesis: Tokens.closeParenthesis(),
                ),
          typeArguments: null,
        );

        var variableDeclaration = VariableDeclarationImpl(
          comment: null,
          metadata: [],
          name: StringToken(TokenType.STRING, name, -1),
          equals: Tokens.eq(),
          initializer: initializer,
        );
        constant.declaredFragment = field;
        variableDeclaration.declaredFragment = field;
        VariableDeclarationListImpl(
          comment: null,
          metadata: null,
          lateKeyword: null,
          keyword: null,
          type: null,
          variables: [variableDeclaration],
        );
        _linker.elementNodes[field] = variableDeclaration;

        _addChildFragment(field);

        AstNodeImpl.linkNodeTokens(initializer);
        field.constantInitializer = initializer;

        valuesElements.add(
          SimpleIdentifierImpl(token: StringToken(TokenType.STRING, name, -1)),
        );
        valuesNames.add(name);
      }

      // Build the 'values' field.
      var valuesField = FieldFragmentImpl(name: 'values')
        ..isConst = true
        ..isStatic = true
        ..isOriginEnumValues = true
        ..isSynthetic = true;
      var initializer = ListLiteralImpl(
        constKeyword: null,
        typeArguments: null,
        leftBracket: Tokens.openSquareBracket(),
        elements: valuesElements,
        rightBracket: Tokens.closeSquareBracket(),
      );
      AstNodeImpl.linkNodeTokens(initializer);
      valuesField.constantInitializer = initializer;

      var variableDeclaration = VariableDeclarationImpl(
        comment: null,
        metadata: [],
        name: StringToken(TokenType.STRING, 'values', -1),
        equals: Tokens.eq(),
        initializer: initializer,
      );
      var valuesTypeNode = NamedTypeImpl(
        importPrefix: null,
        name: StringToken(TokenType.STRING, 'List', -1),
        typeArguments: TypeArgumentListImpl(
          leftBracket: Tokens.lt(),
          arguments: [
            NamedTypeImpl(
              importPrefix: null,
              name: StringToken(TokenType.STRING, fragment.name ?? '', -1),
              typeArguments: null,
              question: null,
            ),
          ],
          rightBracket: Tokens.gt(),
        ),
        question: null,
      );
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword: Tokens.const_(),
        variables: [variableDeclaration],
        type: valuesTypeNode,
      );
      _linker.elementNodes[valuesField] = variableDeclaration;

      _addChildFragment(valuesField);

      _libraryBuilder.implicitEnumNodes[fragment] = ImplicitEnumNodes(
        fragment: fragment,
        valuesTypeNode: valuesTypeNode,
        valuesNode: variableDeclaration,
        valuesFragment: valuesField,
        valuesNames: valuesNames,
        valuesInitializer: initializer,
      );

      node.namePart.accept(this);
      node.body.members.accept(this);
    });

    fragment.typeParameters = holder.typeParameters;
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var index = _exportDirectiveIndex++;
    var exportElement = _libraryFragment.libraryExports[index];
    exportElement.metadata = _buildMetadata(node.metadata);
    node.libraryExport = exportElement;
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var nameToken = node.name;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ExtensionFragmentImpl(name: fragmentName);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.body.members.accept(this);
    });
    fragment.typeParameters = holder.typeParameters;

    node.onClause?.accept(this);
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    node.extendedType.accept(this);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var nameToken = node.primaryConstructor.typeName;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ExtensionTypeFragmentImpl(name: fragmentName);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      node.primaryConstructor.accept(this);
      node.body.accept(this);
    });

    fragment.typeParameters = holder.typeParameters;

    node.implementsClause?.accept(this);
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    var metadata = _buildMetadata(node.metadata);
    for (var variable in node.fields.variables) {
      var nameToken = variable.name;

      var fragment = FieldFragmentImpl(name: _getFragmentName(nameToken));
      fragment.hasInitializer = variable.initializer != null;
      fragment.isAbstract = node.abstractKeyword != null;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isConst = node.fields.isConst;
      fragment.isExplicitlyCovariant = node.covariantKeyword != null;
      fragment.isExternal = node.externalKeyword != null;
      fragment.isFinal = node.fields.isFinal;
      fragment.isLate = node.fields.isLate;
      fragment.isOriginDeclaration = true;
      fragment.isStatic = node.isStatic;
      fragment.metadata = metadata;

      if (variable.initializer case var initializer?) {
        if (node.fields.isConst) {
          fragment.constantInitializer = initializer;
        } else if (node.fields.isFinal && !node.isStatic) {
          fragment.constantInitializer = initializer;
          _libraryBuilder.finalInstanceFields.add(fragment);
        }
      }

      if (node.fields.type == null) {
        fragment.hasImplicitType = true;
      }

      variable.declaredFragment = fragment;
      _linker.elementNodes[fragment] = variable;

      _addChildFragment(fragment);
    }
    node.fields.type?.accept(this);
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    // If this is a private named parameter, then use the corresponding public
    // name as the element name and store the original private name separately.
    String? privateName;
    if (name2 != null &&
        node.isNamed &&
        _libraryBuilder.element.featureSet.isEnabled(
          Feature.private_named_parameters,
        )) {
      var publicName = correspondingPublicName(name2);
      if (publicName != null) {
        privateName = name2;
        name2 = publicName;
      }
    }

    var fragment = FieldFormalParameterFragmentImpl(
      name: name2,
      nameOffset: null,
      parameterKind: node.kind,
      privateName: privateName,
    );
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(fragment);

    if (node.parent case DefaultFormalParameterImpl parent) {
      fragment.constantInitializer = parent.defaultValue;
    }

    fragment.hasImplicitType = node.type == null && node.parameters == null;
    fragment.isOriginDeclaration = true;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.formalParameters = holder.formalParameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    node.type?.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    ExecutableFragmentImpl executableFragment;
    if (node.isGetter) {
      var getterFragment = GetterFragmentImpl(name: name2);
      getterFragment.isAugmentation = node.augmentKeyword != null;
      getterFragment.isOriginDeclaration = true;
      getterFragment.isStatic = true;

      getterFragment.enclosingFragment = _libraryFragment;
      executableFragment = getterFragment;

      _libraryBuilder.addTopFragment(_libraryFragment, getterFragment);
    } else if (node.isSetter) {
      var setterFragment = SetterFragmentImpl(name: name2);
      setterFragment.isAugmentation = node.augmentKeyword != null;
      setterFragment.isOriginDeclaration = true;
      setterFragment.isStatic = true;

      setterFragment.enclosingFragment = _libraryFragment;
      executableFragment = setterFragment;

      _libraryBuilder.addTopFragment(_libraryFragment, setterFragment);
    } else {
      var fragment = TopLevelFunctionFragmentImpl(name: name2);
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isOriginDeclaration = true;
      fragment.isStatic = true;
      executableFragment = fragment;

      _libraryBuilder.addTopFragment(_libraryFragment, fragment);
    }

    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.isAsynchronous = body.isAsynchronous;
    executableFragment.isExternal = node.externalKeyword != null;
    executableFragment.isGenerator = body.isGenerator;
    executableFragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = executableFragment;
    _linker.elementNodes[executableFragment] = node;

    _buildExecutableElementChildren(
      fragment: executableFragment,
      formalParameters: functionExpression.parameters,
      typeParameters: functionExpression.typeParameters,
    );

    node.returnType?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    var fragment = TypeAliasFragmentImpl(
      name: name2,
      firstTokenOffset: node.offset,
    );
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    fragment.typeParameters = holder.typeParameters;
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    FormalParameterFragmentImpl fragment;
    if (_linker.getDeclaringFormalInfo(node) case var declaring?) {
      fragment = declaring.formalFragment;
    } else {
      fragment = FormalParameterFragmentImpl(
        name: name2,
        nameOffset: null,
        parameterKind: node.kind,
      );
    }
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(fragment);

    if (node.parent case DefaultFormalParameterImpl parent) {
      fragment.constantInitializer = parent.defaultValue;
    }

    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    fragment.isOriginDeclaration = true;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      fragment.formalParameters = holder.formalParameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    node.returnType?.accept(this);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var fragment = GenericFunctionTypeFragmentImpl();
    _libraryFragment.encloseElement(fragment);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      fragment.formalParameters = holder.formalParameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    node.returnType?.accept(this);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    var fragment = TypeAliasFragmentImpl(
      name: name2,
      firstTokenOffset: node.offset,
    );
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
    });
    fragment.typeParameters = holder.typeParameters;
    node.type.accept(this);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var index = _importDirectiveIndex++;
    var importElement = _libraryFragment.libraryImports[index];
    importElement.metadata = _buildMetadata(node.metadata);
    node.libraryImport = importElement;
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {}

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var nameToken = node.name;

    ExecutableFragmentImpl executableFragment;
    if (node.isGetter) {
      var fragment = GetterFragmentImpl(name: _getFragmentName(nameToken));
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isOriginDeclaration = true;
      fragment.isStatic = node.isStatic;
      _addChildFragment(fragment);
      executableFragment = fragment;
    } else if (node.isSetter) {
      var fragment = SetterFragmentImpl(name: _getFragmentName(nameToken));
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isOriginDeclaration = true;
      fragment.isStatic = node.isStatic;
      _addChildFragment(fragment);
      executableFragment = fragment;
    } else {
      var fragment = MethodFragmentImpl(name: _getFragmentName(nameToken));
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isOriginDeclaration = true;
      fragment.isStatic = node.isStatic;
      _addChildFragment(fragment);
      executableFragment = fragment;
    }
    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.invokesSuperSelf = node.invokesSuperSelf;
    executableFragment.isAsynchronous = node.body.isAsynchronous;
    executableFragment.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableFragment.isGenerator = node.body.isGenerator;
    executableFragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = executableFragment;
    _linker.elementNodes[executableFragment] = node;

    _buildExecutableElementChildren(
      fragment: executableFragment,
      formalParameters: node.parameters,
      typeParameters: node.typeParameters,
    );

    node.returnType?.accept(this);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var nameToken = node.name;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = MixinFragmentImpl(name: fragmentName);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_libraryFragment, fragment);

    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.body.members.accept(this);
    });
    fragment.typeParameters = holder.typeParameters;

    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.typeArguments?.accept(this);
  }

  @override
  void visitNameWithTypeParameters(NameWithTypeParameters node) {
    node.typeParameters?.accept(this);
  }

  @override
  void visitPartDirective(covariant PartDirectiveImpl node) {
    var index = _partDirectiveIndex++;
    var partElement = _libraryFragment.parts[index];
    partElement.metadata = _buildMetadata(node.metadata);
    node.partInclude = partElement;
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {}

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    // We copy initializers in [visitPrimaryConstructorDeclaration].
  }

  @override
  void visitPrimaryConstructorDeclaration(
    covariant PrimaryConstructorDeclarationImpl node,
  ) {
    node.typeParameters?.accept(this);

    var fragmentName = 'new';
    if (node.constructorName?.name case var nameToken?) {
      fragmentName = _getFragmentName(nameToken) ?? 'new';
    }

    var parent = node.parent;
    var isAugmentation =
        parent is ExtensionTypeDeclarationImpl && parent.augmentKeyword != null;

    var fragment = ConstructorFragmentImpl(name: fragmentName);
    fragment.isAugmentation = isAugmentation;
    fragment.isOriginDeclaration = true;
    fragment.isConst =
        node.constKeyword != null || parent is EnumDeclarationImpl;
    fragment.isPrimary = true;
    fragment.typeName = node.typeName.lexeme;

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _addChildFragment(fragment);

    if (node.body case var body?) {
      fragment.metadata = _buildMetadata(body.metadata);
      if (fragment.isConst) {
        fragment.constantInitializers = body.initializers;
      }
    }

    // Handle declaring formal parameters.
    var formalParameters = node.formalParameters.parameters;

    var isFirstFormalExtensionTypeRepresentation = false;
    if (parent is ExtensionTypeDeclarationImpl) {
      var firstFormalParameter = formalParameters.firstOrNull?.notDefault;
      isFirstFormalExtensionTypeRepresentation =
          firstFormalParameter is SimpleFormalParameterImpl ||
          firstFormalParameter is FunctionTypedFormalParameterImpl;

      if (!isFirstFormalExtensionTypeRepresentation) {
        var fieldFragment = FieldFragmentImpl(name: null);
        fieldFragment.isAugmentation = isAugmentation;
        fieldFragment.isFinal = true;
        fieldFragment.isOriginExtensionTypeRecoveryRepresentation = true;
        _addChildFragment(fieldFragment);
      }
    }
    for (var (i, formalParameter) in formalParameters.indexed) {
      var isExtensionTypeRepresentation =
          i == 0 && isFirstFormalExtensionTypeRepresentation;
      if (formalParameter.finalOrVarKeyword != null ||
          isExtensionTypeRepresentation) {
        var name = _getFragmentName(formalParameter.name);
        var fieldFragment = FieldFragmentImpl(name: name);
        fieldFragment.isAugmentation = isAugmentation;
        fieldFragment.isFinal =
            formalParameter.isFinal || isExtensionTypeRepresentation;
        fieldFragment.isOriginDeclaringFormalParameter = true;
        if (!isExtensionTypeRepresentation) {
          fieldFragment.isSynthetic = true;
        }
        fieldFragment.hasImplicitType = !formalParameter.isExplicitlyTyped;
        _linker.elementNodes[fieldFragment] = formalParameter;
        _addChildFragment(fieldFragment);

        var formalParameterName = name;
        String? formalParameterPrivateName;
        if (formalParameterName != null &&
            formalParameter.isNamed &&
            _libraryBuilder.element.featureSet.isEnabled(
              Feature.private_named_parameters,
            )) {
          var publicName = correspondingPublicName(formalParameterName);
          if (publicName != null) {
            formalParameterPrivateName = formalParameterName;
            formalParameterName = publicName;
          }
        }

        var formalFragment = FieldFormalParameterFragmentImpl(
          name: formalParameterName,
          nameOffset: null,
          parameterKind: formalParameter.kind,
          privateName: formalParameterPrivateName,
        );
        formalFragment.isDeclaring = true;

        _linker.declaringFormalParameters[formalParameter] =
            DeclaringFormalParameterInfo(
              node: formalParameter,
              fieldFragment: fieldFragment,
              formalFragment: formalFragment,
            );
      }
    }

    _buildExecutableElementChildren(
      fragment: fragment,
      formalParameters: node.formalParameters,
    );
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    node.positionalFields.accept(this);
    node.namedFields?.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.fields.accept(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    FormalParameterFragmentImpl fragment;
    if (_linker.getDeclaringFormalInfo(node) case var declaring?) {
      fragment = declaring.formalFragment;
    } else {
      fragment = FormalParameterFragmentImpl(
        name: name2,
        nameOffset: null,
        parameterKind: node.kind,
      );
    }
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(fragment);

    if (_enclosingContext.hasDefaultFormalParameters) {
      if (node.parent case DefaultFormalParameterImpl parent) {
        fragment.constantInitializer = parent.defaultValue;
      }
    }

    fragment.hasImplicitType = node.type == null;
    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    fragment.isOriginDeclaration = true;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;

    node.type?.accept(this);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    var fragment = SuperFormalParameterFragmentImpl(
      name: name2,
      nameOffset: null,
      parameterKind: node.kind,
    );
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(fragment);

    if (node.parent case DefaultFormalParameterImpl parent) {
      fragment.constantInitializer = parent.defaultValue;
    }

    fragment.hasImplicitType = node.type == null && node.parameters == null;
    fragment.isOriginDeclaration = true;
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(fragment: fragment);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.formalParameters = holder.formalParameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    node.type?.accept(this);
  }

  @override
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var metadata = _buildMetadata(node.metadata);
    for (var variable in node.variables.variables) {
      var nameToken = variable.name;
      var name2 = _getFragmentName(nameToken);

      var fragment = TopLevelVariableFragmentImpl(name: name2);

      fragment.hasInitializer = variable.initializer != null;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isConst = node.variables.isConst;
      fragment.isExternal = node.externalKeyword != null;
      fragment.isFinal = node.variables.isFinal;
      fragment.isLate = node.variables.isLate;
      fragment.isOriginDeclaration = true;
      fragment.metadata = metadata;
      if (fragment.isConst) {
        fragment.constantInitializer = variable.initializer;
      }

      if (node.variables.type == null) {
        fragment.hasImplicitType = true;
      }

      _libraryBuilder.addTopFragment(_libraryFragment, fragment);

      _linker.elementNodes[fragment] = variable;
      variable.declaredFragment = fragment;
    }

    node.variables.type?.accept(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var nameToken = node.name;

    var fragment = TypeParameterFragmentImpl(name: _getFragmentName(nameToken));
    fragment.metadata = _buildMetadata(node.metadata);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addTypeParameter(fragment);

    node.bound?.accept(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  void _addChildFragment(FragmentImpl child) {
    var parent = _enclosingContext.fragment;
    _libraryBuilder.addChildFragment(parent, child);
  }

  void _buildExecutableElementChildren({
    required ExecutableFragmentImpl fragment,
    FormalParameterList? formalParameters,
    TypeParameterList? typeParameters,
  }) {
    var holder = _EnclosingContext(
      fragment: fragment,
      hasDefaultFormalParameters: true,
    );
    _withEnclosing(holder, () {
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.formalParameters = holder.formalParameters;
      }
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });
  }

  MetadataImpl _buildMetadata(List<AnnotationImpl> nodeList) {
    var length = nodeList.length;
    if (length == 0) return MetadataImpl(const []);
    return MetadataImpl(
      List.generate(
        length,
        (index) => ElementAnnotationImpl(_libraryFragment, nodeList[index]),
        growable: false,
      ),
    );
  }

  String? _getFragmentName(Token? nameToken) {
    if (nameToken == null || nameToken.isSynthetic) {
      return null;
    }
    return nameToken.lexeme;
  }

  void _withEnclosing(_EnclosingContext context, void Function() f) {
    var previous = _enclosingContext;
    _enclosingContext = context;
    try {
      f();
    } finally {
      _enclosingContext = previous;
    }
  }
}

class _EnclosingContext {
  final FragmentImpl fragment;
  final bool hasDefaultFormalParameters;

  final List<FormalParameterFragmentImpl> formalParameters = [];
  final List<TypeParameterFragmentImpl> typeParameters = [];

  _EnclosingContext({
    required this.fragment,
    this.hasDefaultFormalParameters = false,
  });

  void addParameter(FormalParameterFragmentImpl fragment) {
    formalParameters.add(fragment);
  }

  void addTypeParameter(TypeParameterFragmentImpl fragment) {
    typeParameters.add(fragment);
  }
}

extension _FormalParameterImplExtension on FormalParameterImpl {
  FormalParameterImpl get selfOrParentDefault {
    return parent.tryCast<DefaultFormalParameterImpl>() ?? this;
  }
}

extension _LinkerExtension on Linker {
  DeclaringFormalParameterInfo? getDeclaringFormalInfo(
    FormalParameterImpl node,
  ) {
    return declaringFormalParameters[node.selfOrParentDefault];
  }
}
