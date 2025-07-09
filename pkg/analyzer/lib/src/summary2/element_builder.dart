// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/invokes_super_self.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
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
            // TODO(scheglov): should be a flag on the element instead
            (executable.firstFragment as ExecutableFragmentImpl)
                .isExtensionTypeMember = true;
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
            _handleTypeAliasFragment(libraryFragment, lastFragment, fragment);
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
        return fragment.element.variable3.ifTypeOrNull();
      case SetterFragmentImpl():
        return fragment.element.variable3.ifTypeOrNull();
    }
    return null;
  }

  void _handleClassFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    ClassFragmentImpl fragment,
  ) {
    assert(!fragment.isSynthetic);
    libraryFragment.addClass(fragment);

    if (fragment.isAugmentation && lastFragment is ClassFragmentImpl) {
      lastFragment.addFragment(fragment);
      return;
    }

    var element = ClassElementImpl(
      _addTopReference('@class', fragment.name),
      fragment,
    );
    libraryElement.addClass(element);
    libraryBuilder.declare(element, element.reference);
  }

  void _handleEnumFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    EnumFragmentImpl fragment,
  ) {
    assert(!fragment.isSynthetic);
    libraryFragment.addEnum(fragment);

    if (fragment.isAugmentation && lastFragment is EnumFragmentImpl) {
      lastFragment.addFragment(fragment);
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
    assert(!fragment.isSynthetic);
    libraryFragment.addExtension(fragment);

    if (fragment.isAugmentation && lastFragment is ExtensionFragmentImpl) {
      lastFragment.addFragment(fragment);
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
    assert(!fragment.isSynthetic);
    libraryFragment.addExtensionType(fragment);

    if (fragment.isAugmentation && lastFragment is ExtensionTypeFragmentImpl) {
      lastFragment.addFragment(fragment);
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
    FragmentImpl? lastFieldFragment,
    FieldFragmentImpl fieldFragment,
  ) {
    var instanceFragment =
        fieldFragment.enclosingFragment as InstanceFragmentImpl;
    instanceFragment.addField(fieldFragment);

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
      var getterFragment =
          GetterFragmentImpl(
              name: fieldFragment.name,
              nameOffset: fieldFragment.nameOffset,
            )
            ..isSynthetic = true
            ..isAbstract = fieldFragment.isAbstract
            ..isStatic = fieldFragment.isStatic;
      instanceFragment.addGetter(getterFragment);

      var getterElement = GetterElementImpl(
        _addInstanceReference(instanceElement, '@getter', fieldFragment.name),
        getterFragment,
      );
      instanceElement.addGetter(getterElement);

      fieldElement.getter2 = getterElement;
      getterElement.variable3 = fieldElement;
    }

    if (fieldFragment.hasSetter) {
      var setterFragment =
          SetterFragmentImpl(
              name: fieldFragment.name,
              nameOffset: fieldFragment.nameOffset,
            )
            ..isSynthetic = true
            ..isAbstract = fieldFragment.isAbstract
            ..isStatic = fieldFragment.isStatic;
      instanceFragment.addSetter(setterFragment);

      var valueFragment = FormalParameterFragmentImpl(
        // TODO(scheglov): replace with null
        name: '_${fieldFragment.name ?? ''}',
        nameOffset: fieldFragment.nameOffset,
        nameOffset2: null,
        parameterKind: ParameterKind.REQUIRED,
      );
      valueFragment.isExplicitlyCovariant = fieldFragment.isCovariant;
      setterFragment.parameters = [valueFragment];

      var setterElement = SetterElementImpl(
        _addInstanceReference(instanceElement, '@setter', fieldFragment.name),
        setterFragment,
      );
      instanceElement.addSetter(setterElement);

      FormalParameterElementImpl(valueFragment);

      fieldElement.setter2 = setterElement;
      setterElement.variable3 = fieldElement;
    }
  }

  void _handleInstanceGetterFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    GetterFragmentImpl getterFragment,
  ) {
    assert(!getterFragment.isSynthetic);

    var instanceFragment =
        getterFragment.enclosingFragment as InstanceFragmentImpl;
    instanceFragment.addGetter(getterFragment);

    var lastFieldElement = _fieldElement(lastFragment);
    var lastGetterFragment = lastFieldElement?.getter2?.lastFragment;

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

    // If `getter` is already set, this is a compile-time error.
    // Reset to `null`, so create a new variable.
    if (lastFieldElement != null) {
      if (lastFieldElement.getter2 != null) {
        lastFieldElement = null;
      }
    }

    if (lastFieldElement == null) {
      var fieldFragment =
          FieldFragmentImpl(name: getterFragment.name, nameOffset: -1)
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

    getterElement.variable3 = lastFieldElement;
    lastFieldElement.getter2 = getterElement;
  }

  void _handleInstanceMethodFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    MethodFragmentImpl fragment,
  ) {
    var instanceFragment = fragment.enclosingFragment as InstanceFragmentImpl;
    instanceFragment.addMethod(fragment);

    if (lastFragment is MethodFragmentImpl && fragment.isAugmentation) {
      lastFragment.addFragment(fragment);
    } else {
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
  }

  void _handleInstanceSetterFragment(
    InstanceElementImpl instanceElement,
    FragmentImpl? lastFragment,
    SetterFragmentImpl setterFragment,
  ) {
    assert(!setterFragment.isSynthetic);

    var instanceFragment =
        setterFragment.enclosingFragment as InstanceFragmentImpl;
    instanceFragment.addSetter(setterFragment);

    var lastFieldElement = _fieldElement(lastFragment);
    var lastSetterFragment = lastFieldElement?.setter2?.lastFragment;

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
      if (lastFieldElement.setter2 != null) {
        lastFieldElement = null;
      }
    }

    if (lastFieldElement == null) {
      var fieldFragment =
          FieldFragmentImpl(name: setterFragment.name, nameOffset: -1)
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

    setterElement.variable3 = lastFieldElement;
    lastFieldElement.setter2 = setterElement;
  }

  void _handleMixinFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    MixinFragmentImpl fragment,
  ) {
    assert(!fragment.isSynthetic);
    libraryFragment.addMixin(fragment);

    if (fragment.isAugmentation && lastFragment is MixinFragmentImpl) {
      lastFragment.addFragment(fragment);
      return;
    }

    var element = MixinElementImpl(
      _addTopReference('@mixin', fragment.name),
      fragment,
    );
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
    assert(!getterFragment.isSynthetic);
    libraryFragment.addGetter(getterFragment);

    var lastVariableElement = _topLevelVariableElement(lastFragment);
    var lastGetterFragment = lastVariableElement?.getter2?.lastFragment;

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
      if (lastVariableElement.getter2 != null) {
        lastVariableElement = null;
      }
    }

    if (lastVariableElement == null) {
      var variableFragment = TopLevelVariableFragmentImpl(
        name: getterFragment.name,
        nameOffset: -1,
      )..isSynthetic = true;
      libraryFragment.addTopLevelVariable(variableFragment);

      lastVariableElement = TopLevelVariableElementImpl(
        _addTopReference('@topLevelVariable', getterFragment.name),
        variableFragment,
      );
      libraryElement.addTopLevelVariable(lastVariableElement);
    }

    getterElement.variable3 = lastVariableElement;
    lastVariableElement.getter2 = getterElement;
  }

  void _handleTopLevelSetterFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    SetterFragmentImpl setterFragment,
  ) {
    assert(!setterFragment.isSynthetic);
    libraryFragment.addSetter(setterFragment);

    var lastVariableElement = _topLevelVariableElement(lastFragment);
    var lastSetterFragment = lastVariableElement?.setter2?.lastFragment;

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
      if (lastVariableElement.setter2 != null) {
        lastVariableElement = null;
      }
    }

    if (lastVariableElement == null) {
      var variableFragment = TopLevelVariableFragmentImpl(
        name: setterFragment.name,
        nameOffset: -1,
      )..isSynthetic = true;
      libraryFragment.addTopLevelVariable(variableFragment);

      lastVariableElement = TopLevelVariableElementImpl(
        _addTopReference('@topLevelVariable', setterFragment.name),
        variableFragment,
      );
      libraryElement.addTopLevelVariable(lastVariableElement);
    }

    setterElement.variable3 = lastVariableElement;
    lastVariableElement.setter2 = setterElement;
  }

  void _handleTopLevelVariableFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastVariableFragment,
    TopLevelVariableFragmentImpl variableFragment,
  ) {
    assert(!variableFragment.isSynthetic);
    libraryFragment.addTopLevelVariable(variableFragment);

    if (variableFragment.isAugmentation &&
        lastVariableFragment is TopLevelVariableFragmentImpl) {
      lastVariableFragment.addFragment(variableFragment);
      return;
    }

    var variableElement = TopLevelVariableElementImpl(
      _addTopReference('@topLevelVariable', variableFragment.name),
      variableFragment,
    );
    libraryElement.addTopLevelVariable(variableElement);

    {
      var getterFragment =
          GetterFragmentImpl(
              name: variableFragment.name,
              nameOffset: variableFragment.nameOffset,
            )
            ..isSynthetic = true
            ..isStatic = true;
      libraryFragment.addGetter(getterFragment);

      var getterElement = GetterElementImpl(
        _addTopReference('@getter', variableFragment.name),
        getterFragment,
      );
      libraryElement.addGetter(getterElement);
      libraryBuilder.declare(getterElement, getterElement.reference);

      variableElement.getter2 = getterElement;
      getterElement.variable3 = variableElement;
    }

    if (variableFragment.hasSetter) {
      var setterFragment =
          SetterFragmentImpl(
              name: variableFragment.name,
              nameOffset: variableFragment.nameOffset,
            )
            ..isSynthetic = true
            ..isStatic = true;
      libraryFragment.addSetter(setterFragment);

      var valueFragment = FormalParameterFragmentImpl(
        // TODO(scheglov): replace with null
        name: '_${variableFragment.name ?? ''}',
        nameOffset: variableFragment.nameOffset,
        nameOffset2: null,
        parameterKind: ParameterKind.REQUIRED,
      );
      setterFragment.parameters = [valueFragment];

      var setterElement = SetterElementImpl(
        _addTopReference('@setter', variableFragment.name),
        setterFragment,
      );
      libraryElement.addSetter(setterElement);
      libraryBuilder.declare(setterElement, setterElement.reference);

      FormalParameterElementImpl(valueFragment);

      variableElement.setter2 = setterElement;
      setterElement.variable3 = variableElement;
    }
  }

  void _handleTypeAliasFragment(
    LibraryFragmentImpl libraryFragment,
    FragmentImpl? lastFragment,
    TypeAliasFragmentImpl fragment,
  ) {
    libraryFragment.addTypeAlias(fragment);

    if (lastFragment is TypeAliasFragmentImpl && fragment.isAugmentation) {
      lastFragment.addFragment(fragment);
    } else {
      var element = TypeAliasElementImpl(
        _addTopReference('@typeAlias', fragment.name),
        fragment,
      );
      libraryElement.typeAliases.add(element);
      libraryBuilder.declare(element, element.reference);
    }
  }

  TopLevelVariableElementImpl? _topLevelVariableElement(
    FragmentImpl? fragment,
  ) {
    switch (fragment) {
      case TopLevelVariableFragmentImpl():
        return fragment.element;
      case GetterFragmentImpl():
        return fragment.element.variable3.ifTypeOrNull();
      case SetterFragmentImpl():
        return fragment.element.variable3.ifTypeOrNull();
    }
    return null;
  }
}

class FragmentBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final LibraryFragmentImpl _unitElement;

  var _exportDirectiveIndex = 0;
  var _importDirectiveIndex = 0;
  var _partDirectiveIndex = 0;

  _EnclosingContext _enclosingContext;
  int _nextUnnamedId = 0;

  FragmentBuilder({
    required LibraryBuilder libraryBuilder,
    required LibraryFragmentImpl unitElement,
  }) : _libraryBuilder = libraryBuilder,
       _unitElement = unitElement,
       _enclosingContext = _EnclosingContext(
         instanceElementBuilder: null,
         fragment: unitElement,
       );

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationFragments(CompilationUnit unit) {
    unit.declarations.accept(this);
  }

  /// Builds exports and imports, metadata into [_unitElement].
  void buildDirectives(CompilationUnitImpl unit) {
    unit.directives.accept(this);
  }

  /// Updates metadata and documentation for [_libraryBuilder].
  ///
  /// This method must be invoked after [buildDirectives].
  void buildLibraryMetadata(CompilationUnitImpl unit) {
    var libraryElement = _libraryBuilder.element;

    // Prefer the actual library directive.
    var libraryDirective =
        unit.directives.whereType<LibraryDirectiveImpl>().firstOrNull;
    if (libraryDirective != null) {
      libraryDirective.element = libraryElement;
      libraryElement.documentationComment = getCommentNodeRawText(
        libraryDirective.documentationComment,
      );
      libraryElement.metadata = _buildMetadata(libraryDirective.metadata);
      return;
    }

    // Otherwise use the first directive.
    var firstDirective = unit.directives.firstOrNull;
    if (firstDirective != null) {
      libraryElement.documentationComment = getCommentNodeRawText(
        firstDirective.documentationComment,
      );
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
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var nameToken = node.name;

    var fragmentName = _getFragmentName(nameToken);
    var fragment = ClassFragmentImpl(
      name: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
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
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.members.accept(this);
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

    var fragment = ClassFragmentImpl(
      name: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
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
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
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
    var nameNode = node.name ?? node.returnType;
    var name = node.name?.lexeme ?? '';
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    var nameOffset = nameNode.offset;

    String fragmentName;
    int? fragmentNameOffset;
    if ((node.period, node.name) case (var _?, var name?)) {
      fragmentName = _getFragmentName(name) ?? 'new';
      fragmentNameOffset = _getFragmentNameOffset(name);
    } else {
      fragmentName = 'new';
    }

    var fragment = ConstructorFragmentImpl(
      name: fragmentName,
      nameOffset: nameOffset,
    );
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isConst = node.constKeyword != null;
    fragment.isExternal = node.externalKeyword != null;
    fragment.isFactory = node.factoryKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    fragment.typeName = node.returnType.name;
    fragment.typeNameOffset = node.returnType.offset;
    fragment.periodOffset = node.period?.offset;
    fragment.nameEnd = nameNode.end;
    fragment.nameOffset2 = fragmentNameOffset;
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    if (fragment.isConst || fragment.isFactory) {
      fragment.constantInitializers = node.initializers;
    }

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var reference = Reference.root(); // TODO(scheglov): remove this
    var parentFragment = _enclosingContext.fragment;
    _libraryBuilder.addFragmentChild(parentFragment, fragment);
    (parentFragment as InterfaceFragmentImpl).addConstructor(fragment);

    _buildExecutableElementChildren(
      reference: reference,
      fragment: fragment,
      formalParameters: node.parameters,
    );
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var nameToken = node.name;
    var nameOffset = nameToken.offset;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = EnumFragmentImpl(
      name: fragmentName,
      nameOffset: nameOffset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );

    // Build fields for all enum constants.
    var constants = node.constants;
    var valuesElements = <SimpleIdentifierImpl>[];
    var valuesNames = <String>{};
    for (var i = 0; i < constants.length; ++i) {
      var constant = constants[i];
      var nameToken = constant.name;
      var name = nameToken.lexeme;
      var field =
          FieldFragmentImpl(
              name: _getFragmentName(nameToken),
              nameOffset: constant.name.offset,
            )
            ..hasImplicitType = true
            ..hasInitializer = true
            ..isAugmentation = constant.augmentKeyword != null
            ..isConst = true
            ..isEnumConstant = true
            ..isStatic = true;
      field.nameOffset2 = _getFragmentNameOffset(nameToken);
      _setCodeRange(field, constant);
      _setDocumentation(field, constant);
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
          name:
              constructorName != null
                  ? SimpleIdentifierImpl(
                    token: StringToken(TokenType.STRING, constructorName, -1),
                  )
                  : null,
        ),
        argumentList:
            constantArguments != null
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

      field.enclosingElement = fragment;
      _libraryBuilder.addFragmentChild(fragment, field);

      AstNodeImpl.linkNodeTokens(initializer);
      field.constantInitializer = initializer;

      valuesElements.add(
        SimpleIdentifierImpl(token: StringToken(TokenType.STRING, name, -1)),
      );
      valuesNames.add(name);
    }

    // Build the 'values' field.
    var valuesField =
        FieldFragmentImpl(name: 'values', nameOffset: -1)
          ..hasEnclosingTypeParameterReference = false
          ..isConst = true
          ..isStatic = true
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

    valuesField.enclosingElement = fragment;
    _libraryBuilder.addFragmentChild(fragment, valuesField);

    _libraryBuilder.implicitEnumNodes[fragment] = ImplicitEnumNodes(
      element: fragment,
      valuesTypeNode: valuesTypeNode,
      valuesNode: variableDeclaration,
      valuesElement: valuesField,
      valuesNames: valuesNames,
      valuesInitializer: initializer,
    );

    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.members.accept(this);
    });

    fragment.typeParameters = holder.typeParameters;
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var index = _exportDirectiveIndex++;
    var exportElement = _unitElement.libraryExports[index];
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
    var nameOffset = nameToken?.offset ?? -1;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ExtensionFragmentImpl(
      name: fragmentName,
      nameOffset: nameOffset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.members.accept(this);
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
    var nameToken = node.name;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = ExtensionTypeFragmentImpl(
      name: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _builtRepresentationDeclaration(
        extensionNode: node,
        representation: node.representation,
        extensionFragment: fragment,
      );
      node.members.accept(this);
    });

    fragment.typeParameters = holder.typeParameters;

    node.implementsClause?.accept(this);
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    var metadata = _buildMetadata(node.metadata);
    for (var variable in node.fields.variables) {
      var nameToken = variable.name;
      var nameOffset = nameToken.offset;

      var fragment = FieldFragmentImpl(
        name: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.hasInitializer = variable.initializer != null;
      fragment.isAbstract = node.abstractKeyword != null;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isConst = node.fields.isConst;
      fragment.isCovariant = node.covariantKeyword != null;
      fragment.isExternal = node.externalKeyword != null;
      fragment.isFinal = node.fields.isFinal;
      fragment.isLate = node.fields.isLate;
      fragment.isStatic = node.isStatic;
      fragment.metadata = metadata;
      _setCodeRange(fragment, variable);
      _setDocumentation(fragment, node);

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

      var parentFragment = _enclosingContext.fragment;
      fragment.enclosingElement = parentFragment;
      _libraryBuilder.addFragmentChild(parentFragment, fragment);
    }
    _buildType(node.fields.type);
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken.offset.nullIfNegative;

    var fragment = FieldFormalParameterFragmentImpl(
      nameOffset: nameOffset2 ?? -1,
      name: name2,
      nameOffset2: nameOffset2,
      parameterKind: node.kind,
    );
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(null, fragment);

    if (node.parent case DefaultFormalParameterImpl parent) {
      fragment.constantInitializer = parent.defaultValue;
    }

    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.hasImplicitType = node.type == null && node.parameters == null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.type);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;
    var name2 = _getFragmentName(nameToken);

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    ExecutableFragmentImpl executableFragment;
    if (node.isGetter) {
      var getterFragment = GetterFragmentImpl(
        name: name2,
        nameOffset: nameOffset,
      );
      getterFragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      getterFragment.isAugmentation = node.augmentKeyword != null;
      getterFragment.isStatic = true;

      getterFragment.enclosingElement = _unitElement;
      executableFragment = getterFragment;

      _libraryBuilder.addTopFragment(_unitElement, getterFragment);
    } else if (node.isSetter) {
      var setterFragment = SetterFragmentImpl(
        name: name2,
        nameOffset: nameOffset,
      );
      setterFragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      setterFragment.isAugmentation = node.augmentKeyword != null;
      setterFragment.isStatic = true;

      setterFragment.enclosingElement = _unitElement;
      executableFragment = setterFragment;

      _libraryBuilder.addTopFragment(_unitElement, setterFragment);
    } else {
      var fragment = TopLevelFunctionFragmentImpl(
        name: name2,
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = true;
      executableFragment = fragment;

      _enclosingContext.addFunction(name, fragment);

      _libraryBuilder.addTopFragment(_unitElement, fragment);
    }

    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.isAsynchronous = body.isAsynchronous;
    executableFragment.isExternal = node.externalKeyword != null;
    executableFragment.isGenerator = body.isGenerator;
    executableFragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(executableFragment, node);
    _setDocumentation(executableFragment, node);

    node.declaredFragment = executableFragment;
    _linker.elementNodes[executableFragment] = node;

    _buildExecutableElementChildren(
      reference: Reference.root(), // TODO(scheglov): remove this
      fragment: executableFragment,
      formalParameters: functionExpression.parameters,
      typeParameters: functionExpression.typeParameters,
    );

    _buildType(node.returnType);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    var fragment = TypeAliasFragmentImpl(
      name: name2,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isFunctionTypeAliasBased = true;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    var aliasedElement = GenericFunctionTypeFragmentImpl.forOffset(
      nameToken.offset,
    );
    aliasedElement.parameters = holder.parameters;

    fragment.typeParameters = holder.typeParameters;
    fragment.aliasedElement = aliasedElement;
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken.offset.nullIfNegative;

    var fragment = FormalParameterFragmentImpl(
      nameOffset: nameOffset2 ?? -1,
      name: name2,
      nameOffset2: nameOffset2,
      parameterKind: node.kind,
    );
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(null, fragment);

    if (node.parent case DefaultFormalParameterImpl parent) {
      fragment.constantInitializer = parent.defaultValue;
    }

    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      fragment.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var fragment = GenericFunctionTypeFragmentImpl.forOffset(node.offset);
    _unitElement.encloseElement(fragment);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      fragment.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);

    var fragment = TypeAliasFragmentImpl(
      name: name2,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
    });
    fragment.typeParameters = holder.typeParameters;

    var typeNode = node.type;
    typeNode.accept(this);

    if (typeNode is GenericFunctionTypeImpl) {
      fragment.aliasedElement = typeNode.declaredFragment!;
    }
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var index = _importDirectiveIndex++;
    var importElement = _unitElement.libraryImports[index];
    importElement.metadata = _buildMetadata(node.metadata);
    node.libraryImport = importElement;
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {}

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    Reference reference;
    ExecutableFragmentImpl executableFragment;
    if (node.isGetter) {
      var fragment = GetterFragmentImpl(
        name: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = node.isStatic;

      // `class Enum {}` in `dart:core` declares `int get index` as abstract.
      // But the specification says that practically a different class
      // implementing `Enum` is used as a superclass, so `index` should be
      // considered to have non-abstract implementation.
      if (_enclosingContext.isDartCoreEnum && name == 'index') {
        fragment.isAbstract = false;
      }

      reference = Reference.root(); // TODO(scheglov): remove this
      var parentFragment = _enclosingContext.fragment;
      fragment.enclosingElement = parentFragment;
      _libraryBuilder.addFragmentChild(parentFragment, fragment);

      executableFragment = fragment;
    } else if (node.isSetter) {
      var fragment = SetterFragmentImpl(
        name: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = node.isStatic;

      reference = Reference.root(); // TODO(scheglov): remove this
      var parentFragment = _enclosingContext.fragment;
      fragment.enclosingElement = parentFragment;
      _libraryBuilder.addFragmentChild(parentFragment, fragment);

      executableFragment = fragment;
    } else {
      var isUnaryMinus = false;
      if (nameToken.lexeme == '-') {
        var parameters = node.parameters;
        isUnaryMinus = parameters != null && parameters.parameters.isEmpty;
      }

      if (isUnaryMinus) {
        name = 'unary-';
      }

      var fragment = MethodFragmentImpl(
        name: _getFragmentName(nameToken),
        nameOffset: nameOffset,
      );
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = node.isStatic;

      reference = Reference.root(); // TODO(scheglov): remove this
      var parentFragment = _enclosingContext.fragment;
      fragment.enclosingElement = parentFragment;
      _libraryBuilder.addFragmentChild(parentFragment, fragment);

      executableFragment = fragment;
    }
    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.invokesSuperSelf = node.invokesSuperSelf;
    executableFragment.isAsynchronous = node.body.isAsynchronous;
    executableFragment.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableFragment.isGenerator = node.body.isGenerator;
    executableFragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(executableFragment, node);
    _setDocumentation(executableFragment, node);

    node.declaredFragment = executableFragment;
    _linker.elementNodes[executableFragment] = node;

    _buildExecutableElementChildren(
      reference: reference,
      fragment: executableFragment,
      formalParameters: node.parameters,
      typeParameters: node.typeParameters,
    );

    _buildType(node.returnType);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var nameToken = node.name;
    var fragmentName = _getFragmentName(nameToken);

    var fragment = MixinFragmentImpl(
      name: fragmentName,
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;

    _libraryBuilder.addTopFragment(_unitElement, fragment);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.members.accept(this);
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
  void visitPartDirective(covariant PartDirectiveImpl node) {
    var index = _partDirectiveIndex++;
    var partElement = _unitElement.parts[index];
    partElement.metadata = _buildMetadata(node.metadata);
    node.partInclude = partElement;
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    var libraryElement = _libraryBuilder.element;
    libraryElement.hasPartOfDirective = true;
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
    var nameOffset2 = nameToken?.offset;

    var fragment = FormalParameterFragmentImpl(
      nameOffset: nameOffset2 ?? -1,
      name: name2,
      nameOffset2: nameOffset2,
      parameterKind: node.kind,
    );
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(null, fragment);

    if (_enclosingContext.hasDefaultFormalParameters) {
      if (node.parent case DefaultFormalParameterImpl parent) {
        fragment.constantInitializer = parent.defaultValue;
      }
    }

    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.hasImplicitType = node.type == null;
    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    _buildType(node.type);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    var nameToken = node.name;
    var name2 = _getFragmentName(nameToken);
    var nameOffset2 = nameToken.offset.nullIfNegative;

    var fragment = SuperFormalParameterFragmentImpl(
      nameOffset: nameOffset2 ?? -1,
      name: name2,
      nameOffset2: nameOffset2,
      parameterKind: node.kind,
    );
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addParameter(null, fragment);

    if (node.parent case DefaultFormalParameterImpl parent) {
      fragment.constantInitializer = parent.defaultValue;
    }

    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.hasImplicitType = node.type == null && node.parameters == null;
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.type);
  }

  @override
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var metadata = _buildMetadata(node.metadata);
    for (var variable in node.variables.variables) {
      var nameToken = variable.name;
      var nameOffset = nameToken.offset;
      var name2 = _getFragmentName(nameToken);

      var fragment = TopLevelVariableFragmentImpl(
        name: name2,
        nameOffset: nameOffset,
      );

      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.hasInitializer = variable.initializer != null;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isConst = node.variables.isConst;
      fragment.isExternal = node.externalKeyword != null;
      fragment.isFinal = node.variables.isFinal;
      fragment.isLate = node.variables.isLate;
      fragment.metadata = metadata;
      if (fragment.isConst) {
        fragment.constantInitializer = variable.initializer;
      }
      _setCodeRange(fragment, variable);
      _setDocumentation(fragment, node);

      if (node.variables.type == null) {
        fragment.hasImplicitType = true;
      }

      var refName = fragment.name ?? '${_nextUnnamedId++}';
      _enclosingContext.addTopLevelVariable(refName, fragment);

      _libraryBuilder.addTopFragment(_unitElement, fragment);

      _linker.elementNodes[fragment] = variable;
      variable.declaredFragment = fragment;
    }

    _buildType(node.variables.type);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var fragment = TypeParameterFragmentImpl(
      name: _getFragmentName(nameToken),
      nameOffset: nameToken.offset,
    );
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.metadata = _buildMetadata(node.metadata);
    _setCodeRange(fragment, node);

    node.declaredFragment = fragment;
    _linker.elementNodes[fragment] = node;
    _enclosingContext.addTypeParameter(name, fragment);

    _buildType(node.bound);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  void _buildExecutableElementChildren({
    required Reference reference,
    required ExecutableFragmentImpl fragment,
    FormalParameterList? formalParameters,
    TypeParameterList? typeParameters,
  }) {
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
      hasDefaultFormalParameters: true,
    );
    _withEnclosing(holder, () {
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.parameters = holder.parameters;
      }
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });
  }

  MetadataImpl _buildMetadata(List<Annotation> nodeList) {
    var annotations = _buildAnnotationsWithUnit(_unitElement, nodeList);
    return MetadataImpl(annotations);
  }

  // TODO(scheglov): Maybe inline?
  void _buildType(TypeAnnotation? node) {
    node?.accept(this);
  }

  void _builtRepresentationDeclaration({
    required ExtensionTypeFragmentImpl extensionFragment,
    required ExtensionTypeDeclarationImpl extensionNode,
    required RepresentationDeclarationImpl representation,
  }) {
    var fieldNameToken = representation.fieldName;

    var fieldFragment = FieldFragmentImpl(
      name: _getFragmentName(fieldNameToken),
      nameOffset: fieldNameToken.offset,
    );
    fieldFragment.nameOffset2 = _getFragmentNameOffset(fieldNameToken);
    fieldFragment.isFinal = true;
    fieldFragment.metadata = _buildMetadata(representation.fieldMetadata);

    var fieldBeginToken =
        representation.fieldMetadata.beginToken ?? representation.fieldType;
    var fieldCodeRangeOffset = fieldBeginToken.offset;
    var fieldCodeRangeLength = fieldNameToken.end - fieldCodeRangeOffset;
    fieldFragment.setCodeRange(fieldCodeRangeOffset, fieldCodeRangeLength);

    representation.fieldFragment = fieldFragment;
    _linker.elementNodes[fieldFragment] = representation;

    fieldFragment.enclosingElement = extensionFragment;
    _libraryBuilder.addFragmentChild(extensionFragment, fieldFragment);

    var nameOffset2 = fieldNameToken.offset.nullIfNegative;

    var formalParameterElement =
        FieldFormalParameterFragmentImpl(
            nameOffset: nameOffset2 ?? -1,
            name: _getFragmentName(fieldNameToken),
            nameOffset2: nameOffset2,
            parameterKind: ParameterKind.REQUIRED,
          )
          ..field = fieldFragment
          ..hasImplicitType = true;
    formalParameterElement.nameOffset2 = _getFragmentNameOffset(fieldNameToken);
    formalParameterElement.setCodeRange(
      fieldCodeRangeOffset,
      fieldCodeRangeLength,
    );

    {
      int? periodOffset;
      int nameOffset;
      int? nameEnd;
      var constructorNameNode = representation.constructorName;
      if (constructorNameNode != null) {
        var nameToken = constructorNameNode.name;
        periodOffset = constructorNameNode.period.offset;
        nameOffset = nameToken.offset;
        nameEnd = nameToken.end;
      } else {
        nameOffset = extensionNode.name.offset;
        nameEnd = extensionNode.name.end;
      }

      String constructorFragmentName;
      int? constructorFragmentOffset;
      if (representation.constructorName case var constructorName?) {
        constructorFragmentName = constructorName.name.lexeme;
        constructorFragmentOffset = constructorName.name.offset;
      } else {
        constructorFragmentName = 'new';
      }

      var constructorFragment =
          ConstructorFragmentImpl(
              name: constructorFragmentName,
              nameOffset: nameOffset,
            )
            ..isAugmentation = extensionNode.augmentKeyword != null
            ..isConst = extensionNode.constKeyword != null
            ..periodOffset = periodOffset
            ..nameEnd = nameEnd
            ..parameters = [formalParameterElement];
      constructorFragment.typeName = extensionFragment.name;
      constructorFragment.typeNameOffset = extensionFragment.nameOffset2;
      constructorFragment.nameOffset2 = constructorFragmentOffset;
      _setCodeRange(constructorFragment, representation);

      representation.constructorFragment = constructorFragment;
      _linker.elementNodes[constructorFragment] = representation;

      _libraryBuilder.addFragmentChild(extensionFragment, constructorFragment);
      extensionFragment.addConstructor(constructorFragment);
    }

    representation.fieldType.accept(this);
  }

  String? _getFragmentName(Token? nameToken) {
    if (nameToken == null || nameToken.isSynthetic) {
      return null;
    }
    return nameToken.lexeme;
  }

  int? _getFragmentNameOffset(Token? nameToken) {
    if (nameToken == null || nameToken.isSynthetic) {
      return null;
    }
    return nameToken.offset;
  }

  /// Make the given [context] be the current one while running [f].
  void _withEnclosing(_EnclosingContext context, void Function() f) {
    var previousContext = _enclosingContext;
    _enclosingContext = context;
    try {
      f();
    } finally {
      _enclosingContext = previousContext;
    }
  }

  static List<ElementAnnotationImpl> _buildAnnotationsWithUnit(
    LibraryFragmentImpl unitElement,
    List<Annotation> nodeList,
  ) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotationImpl>[];
    }

    return List<ElementAnnotationImpl>.generate(length, (index) {
      var ast = nodeList[index] as AnnotationImpl;
      var element = ElementAnnotationImpl(unitElement);
      element.annotationAst = ast;
      ast.elementAnnotation = element;
      return element;
    }, growable: false);
  }

  static void _setCodeRange(FragmentImpl element, AstNode node) {
    var parent = node.parent;
    if (node is FormalParameter && parent is DefaultFormalParameter) {
      node = parent;
    }

    if (node is VariableDeclaration && parent is VariableDeclarationList) {
      var fieldDeclaration = parent.parent;
      if (fieldDeclaration != null && parent.variables.first == node) {
        var offset = fieldDeclaration.offset;
        element.setCodeRange(offset, node.end - offset);
        return;
      }
    }

    element.setCodeRange(node.offset, node.length);
  }

  static void _setDocumentation(FragmentImpl element, AnnotatedNode node) {
    element.documentationComment = getCommentNodeRawText(
      node.documentationComment,
    );
  }
}

class _EnclosingContext {
  final Object? instanceElementBuilder; // TODO(scheglov): remove it
  final FragmentImpl fragment;
  final List<ClassFragmentImpl> _classes = [];
  final List<ConstructorFragmentImpl> _constructors = [];
  final List<EnumFragmentImpl> _enums = [];
  final List<ExtensionFragmentImpl> _extensions = [];
  final List<ExtensionTypeFragmentImpl> _extensionTypes = [];
  final List<FieldFragmentImpl> _fields = [];
  final List<TopLevelFunctionFragmentImpl> _functions = [];
  final List<MethodFragmentImpl> _methods = [];
  final List<MixinFragmentImpl> _mixins = [];
  final List<FormalParameterFragmentImpl> _parameters = [];

  // TODO(scheglov): Use getters / setters instead.
  final List<PropertyAccessorFragmentImpl> _propertyAccessors = [];
  final List<TopLevelVariableFragmentImpl> _topLevelVariables = [];
  final List<TypeAliasFragmentImpl> _typeAliases = [];
  final List<TypeParameterFragmentImpl> _typeParameters = [];

  /// Not all optional formal parameters can have default values.
  /// For example, formal parameters of methods can, but formal parameters
  /// of function types - not. This flag specifies if we should store
  /// the default value into [FormalParameterFragmentImpl]s.
  final bool hasDefaultFormalParameters;

  _EnclosingContext({
    required this.instanceElementBuilder,
    required this.fragment,
    this.hasDefaultFormalParameters = false,
  });

  List<ClassFragmentImpl> get classes {
    return _classes.toFixedList();
  }

  List<ConstructorFragmentImpl> get constructors {
    return _constructors.toFixedList();
  }

  List<EnumFragmentImpl> get enums {
    return _enums.toFixedList();
  }

  List<ExtensionFragmentImpl> get extensions {
    return _extensions.toFixedList();
  }

  List<ExtensionTypeFragmentImpl> get extensionTypes {
    return _extensionTypes.toFixedList();
  }

  List<FieldFragmentImpl> get fields {
    return _fields.toFixedList();
  }

  List<TopLevelFunctionFragmentImpl> get functions {
    return _functions.toFixedList();
  }

  List<GetterFragmentImpl> get getters {
    return _propertyAccessors.whereType<GetterFragmentImpl>().toFixedList();
  }

  bool get isDartCoreEnum {
    var fragment = this.fragment;
    return fragment is ClassFragmentImpl && fragment.isDartCoreEnum;
  }

  List<MethodFragmentImpl> get methods {
    return _methods.toFixedList();
  }

  List<MixinFragmentImpl> get mixins {
    return _mixins.toFixedList();
  }

  List<FormalParameterFragmentImpl> get parameters {
    return _parameters.toFixedList();
  }

  List<SetterFragmentImpl> get setters {
    return _propertyAccessors.whereType<SetterFragmentImpl>().toFixedList();
  }

  List<TopLevelVariableFragmentImpl> get topLevelVariables {
    return _topLevelVariables.toFixedList();
  }

  List<TypeAliasFragmentImpl> get typeAliases {
    return _typeAliases.toFixedList();
  }

  List<TypeParameterFragmentImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  Reference addClass(String name, ClassFragmentImpl element) {
    _classes.add(element);
    var containerName =
        element.isAugmentation ? '@classAugmentation' : '@class';
    return _addReference(containerName, name, element);
  }

  Reference addConstructor(ConstructorFragmentImpl element) {
    _constructors.add(element);

    var containerName =
        element.isAugmentation ? '@constructorAugmentation' : '@constructor';
    var referenceName = element.name;
    return _addReference(containerName, referenceName, element);
  }

  Reference addEnum(String name, EnumFragmentImpl element) {
    _enums.add(element);
    var containerName = element.isAugmentation ? '@enumAugmentation' : '@enum';
    return _addReference(containerName, name, element);
  }

  Reference addExtension(String name, ExtensionFragmentImpl element) {
    _extensions.add(element);
    var containerName =
        element.isAugmentation ? '@extensionAugmentation' : '@extension';
    return _addReference(containerName, name, element);
  }

  Reference addExtensionType(String name, ExtensionTypeFragmentImpl element) {
    _extensionTypes.add(element);
    var containerName =
        element.isAugmentation
            ? '@extensionTypeAugmentation'
            : '@extensionType';
    return _addReference(containerName, name, element);
  }

  Reference addField(String name, FieldFragmentImpl element) {
    _fields.add(element);
    var containerName =
        element.isAugmentation ? '@fieldAugmentation' : '@field';
    return _addReference(containerName, name, element);
  }

  void addFieldSynthetic(Reference reference, FieldFragmentImpl element) {
    _fields.add(element);
    _bindReference(reference, element);
  }

  void addFunction(String name, TopLevelFunctionFragmentImpl element) {
    _functions.add(element);
  }

  Reference addGetter(String name, PropertyAccessorFragmentImpl element) {
    _propertyAccessors.add(element);
    var containerName =
        element.isAugmentation ? '@getterAugmentation' : '@getter';
    return _addReference(containerName, name, element);
  }

  Reference addMethod(String name, MethodFragmentImpl element) {
    _methods.add(element);
    var containerName =
        element.isAugmentation ? '@methodAugmentation' : '@method';
    return _addReference(containerName, name, element);
  }

  Reference addMixin(String name, MixinFragmentImpl element) {
    _mixins.add(element);
    var containerName =
        element.isAugmentation ? '@mixinAugmentation' : '@mixin';
    return _addReference(containerName, name, element);
  }

  void addParameter(String? name, FormalParameterFragmentImpl element) {
    _parameters.add(element);
  }

  void addPropertyAccessorSynthetic(PropertyAccessorFragmentImpl element) {
    _propertyAccessors.add(element);
  }

  Reference addSetter(String name, PropertyAccessorFragmentImpl element) {
    _propertyAccessors.add(element);
    var containerName =
        element.isAugmentation ? '@setterAugmentation' : '@setter';
    return _addReference(containerName, name, element);
  }

  void addTopLevelVariable(String name, TopLevelVariableFragmentImpl element) {
    _topLevelVariables.add(element);
  }

  void addTopLevelVariableSynthetic(
    Reference reference,
    TopLevelVariableFragmentImpl element,
  ) {
    _topLevelVariables.add(element);
    _bindReference(reference, element);
  }

  Reference addTypeAlias(String name, TypeAliasFragmentImpl element) {
    _typeAliases.add(element);
    var containerName =
        element.isAugmentation ? '@typeAliasAugmentation' : '@typeAlias';
    return _addReference(containerName, name, element);
  }

  void addTypeParameter(String name, TypeParameterFragmentImpl fragment) {
    _typeParameters.add(fragment);
    this.fragment.encloseElement(fragment);
  }

  Reference _addReference(
    String containerName,
    String name,
    FragmentImpl element,
  ) {
    // TODO(scheglov): remove this method
    throw StateError('Should not be used');
  }

  void _bindReference(Reference reference, FragmentImpl fragment) {
    // TODO(scheglov): remove this method
    throw StateError('Should not be used');
  }
}
