// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fragment/constructor/encoding.dart';
import 'package:front_end/src/fragment/factory/encoding.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../fragment/factory/declaration.dart';
import '../fragment/field/declaration.dart';
import '../fragment/fragment.dart';
import '../fragment/getter/declaration.dart';
import '../fragment/method/declaration.dart';
import '../fragment/method/encoding.dart';
import '../fragment/setter/declaration.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_member_builder.dart';
import 'source_method_builder.dart';
import 'source_property_builder.dart';
import 'source_type_alias_builder.dart';
import 'source_type_parameter_builder.dart';

enum _PropertyKind {
  Getter,
  Setter,
  Field,
  FinalField,
}

enum _DeclarationKind {
  Constructor,
  Factory,
  Class,
  Mixin,
  NamedMixinApplication,
  Enum,
  Extension,
  ExtensionType,
  Typedef,
  Method,
  Property,
}

abstract class _Declaration {
  final _DeclarationKind kind;
  final Fragment _fragment;
  final String name;
  final bool isAugment;
  final bool inPatch;
  final bool inLibrary;
  final bool isStatic;

  _Declaration(this.kind, this._fragment,
      {required this.name,
      required this.isAugment,
      required this.inPatch,
      required this.inLibrary,
      this.isStatic = true});

  UriOffsetLength get uriOffset;

  /// Adds this declaration to [thesePreBuilders] and checks it against the
  /// [otherPreBuilders].
  ///
  /// If this declaration can be absorbed into an existing declaration in
  /// [thesePreBuilders], it is added to the corresponding [_PreBuilder].
  /// Otherwise a new [_PreBuilder] is created and added to [thesePreBuilders].
  void _addPreBuilder(ProblemReporting problemReporting,
      List<_PreBuilder> thesePreBuilders, List<_PreBuilder> otherPreBuilders) {
    for (_PreBuilder existingPreBuilder in thesePreBuilders) {
      if (existingPreBuilder.absorbFragment(problemReporting, this)) {
        return;
      }
    }
    _checkAugmentation(problemReporting, this);
    thesePreBuilders.add(_createPreBuilder());
    if (otherPreBuilders.isNotEmpty) {
      otherPreBuilders.first.checkFragment(problemReporting, this);
    }
  }

  /// Creates the [_PreBuilder] for this [_Declaration].
  ///
  /// This is called for the declarations that aren't absorbed into a
  /// pre-existing declaration.
  _PreBuilder _createPreBuilder();

  void registerPreBuilder(
      ProblemReporting problemReporting,
      List<_PreBuilder> nonConstructorPreBuilders,
      List<_PreBuilder> constructorPreBuilders);
}

mixin _FragmentDeclarationMixin implements _Declaration {
  @override
  Fragment get _fragment;

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  String toString() => _fragment.toString();
}

abstract class _NonConstructorDeclaration extends _Declaration {
  _NonConstructorDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      super.isStatic});

  @override
  void registerPreBuilder(
      ProblemReporting problemReporting,
      List<_PreBuilder> nonConstructorPreBuilders,
      List<_PreBuilder> constructorPreBuilders) {
    _addPreBuilder(
        problemReporting, nonConstructorPreBuilders, constructorPreBuilders);
  }
}

mixin _PropertyFragmentDeclarationMixin implements _PropertyDeclaration {
  @override
  Fragment get _fragment;

  @override
  _PropertyDeclarations createDeclarations() {
    Fragment fragment = _fragment;
    switch (fragment) {
      case FieldFragment():
        RegularFieldDeclaration declaration =
            new RegularFieldDeclaration(fragment);
        return new _PropertyDeclarations(
            field: declaration,
            getter: declaration,
            setter: fragment.hasSetter ? declaration : null);
      case PrimaryConstructorFieldFragment():
        PrimaryConstructorFieldDeclaration declaration =
            new PrimaryConstructorFieldDeclaration(fragment);
        return new _PropertyDeclarations(
            field: declaration, getter: declaration);
      case EnumElementFragment():
        EnumElementDeclaration declaration =
            new EnumElementDeclaration(fragment);
        return new _PropertyDeclarations(
            field: declaration, getter: declaration);
      case GetterFragment():
        return new _PropertyDeclarations(
            getter: new RegularGetterDeclaration(fragment));
      case SetterFragment():
        return new _PropertyDeclarations(
            setter: new RegularSetterDeclaration(fragment));
      // Coverage-ignore(suite): Not run.
      default:
        throw new UnsupportedError("Unexpected property fragment $fragment");
    }
  }
}

abstract class _PropertyDeclaration extends _NonConstructorDeclaration {
  final _PropertyKind propertyKind;

  _PropertyDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required this.propertyKind,
      super.isStatic});

  _PropertyDeclarations createDeclarations();
}

class _FieldDeclaration extends _PropertyDeclaration
    with _FragmentDeclarationMixin, _PropertyFragmentDeclarationMixin {
  _FieldDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.propertyKind,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forField(this);
}

class _GetterDeclaration extends _PropertyDeclaration
    with _FragmentDeclarationMixin, _PropertyFragmentDeclarationMixin {
  _GetterDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.propertyKind,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forGetter(this);
}

class _SetterDeclaration extends _PropertyDeclaration
    with _FragmentDeclarationMixin, _PropertyFragmentDeclarationMixin {
  _SetterDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.propertyKind,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forSetter(this);
}

mixin _StandardFragmentDeclarationMixin implements _StandardDeclaration {
  @override
  Fragment get _fragment;
}

abstract class _StandardDeclaration extends _NonConstructorDeclaration {
  _StandardDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _DeclarationPreBuilder(this);
}

class _StandardFragmentDeclaration extends _StandardDeclaration
    with _FragmentDeclarationMixin, _StandardFragmentDeclarationMixin {
  _StandardFragmentDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      super.isStatic});
}

mixin _ConstructorFragmentDeclarationMixin implements _ConstructorDeclaration {
  @override
  Fragment get _fragment;
}

abstract class _ConstructorDeclaration extends _Declaration {
  _ConstructorDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary});

  @override
  _PreBuilder _createPreBuilder() => new _ConstructorPreBuilder(this);

  @override
  void registerPreBuilder(
      ProblemReporting problemReporting,
      List<_PreBuilder> nonConstructorPreBuilders,
      List<_PreBuilder> constructorPreBuilders) {
    _addPreBuilder(
        problemReporting, constructorPreBuilders, nonConstructorPreBuilders);
  }
}

class _ConstructorFragmentDeclaration extends _ConstructorDeclaration
    with _FragmentDeclarationMixin, _ConstructorFragmentDeclarationMixin {
  _ConstructorFragmentDeclaration(super.kind, super.fragment,
      {required super.name,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary});
}

class _BuilderFactory {
  final ProblemReporting problemReporting;
  final SourceLoader loader;
  final _BuilderRegistry builderRegistry;
  final SourceLibraryBuilder enclosingLibraryBuilder;
  final DeclarationBuilder? declarationBuilder;
  final List<NominalParameterBuilder> unboundNominalParameters;
  final Map<SourceClassBuilder, TypeBuilder> mixinApplications;
  final IndexedLibrary? indexedLibrary;
  final ContainerType containerType;
  final IndexedContainer? indexedContainer;
  final ContainerName? containerName;
  final bool inLibrary;

  _BuilderFactory(
      {required this.problemReporting,
      required this.loader,
      required this.builderRegistry,
      required this.enclosingLibraryBuilder,
      this.declarationBuilder,
      required this.unboundNominalParameters,
      required this.mixinApplications,
      required this.indexedLibrary,
      required this.containerType,
      this.indexedContainer,
      this.containerName})
      : inLibrary = declarationBuilder == null;

  void computeBuildersFromFragments(String name, List<Fragment> fragments) {
    List<_PreBuilder> nonConstructorPreBuilders = [];
    List<_PreBuilder> constructorPreBuilders = [];
    List<Fragment> unnamedFragments = [];

    for (Fragment fragment in fragments) {
      _Declaration? declaration = _createDeclarationFromFragment(fragment,
          inLibrary: inLibrary, unnamedFragments: unnamedFragments);

      declaration?.registerPreBuilder(
          problemReporting, nonConstructorPreBuilders, constructorPreBuilders);
    }

    for (_PreBuilder preBuilder in nonConstructorPreBuilders) {
      preBuilder.createBuilders(this);
    }
    for (_PreBuilder preBuilder in constructorPreBuilders) {
      preBuilder.createBuilders(this);
    }
    for (Fragment fragment in unnamedFragments) {
      createBuilder(fragment);
    }
  }

  void createBuilder(Fragment fragment, {List<Fragment>? augmentations}) {
    switch (fragment) {
      case TypedefFragment():
        _createTypedefBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary);
      case ClassFragment():
        _createClassBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary);
      case MixinFragment():
        _createMixinBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary);
      case NamedMixinApplicationFragment():
        _createNamedMixinApplicationBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            mixinApplications: mixinApplications,
            indexedLibrary: indexedLibrary);
      case EnumFragment():
        _createEnumBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary);
      case ExtensionFragment():
        _createExtensionBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary);
      case ExtensionTypeFragment():
        _createExtensionTypeBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary);
      case MethodFragment():
        _createMethodBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName);
      case ConstructorFragment():
        _createConstructorBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName);
      case PrimaryConstructorFragment():
        _createPrimaryConstructorBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName);
      case FactoryFragment():
        _createFactoryBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            builderRegistry: builderRegistry,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName);
      // Coverage-ignore(suite): Not run.
      case FieldFragment():
      case PrimaryConstructorFieldFragment():
      case GetterFragment():
      case SetterFragment():
      case EnumElementFragment():
        throw new UnsupportedError('Unexpected fragment $fragment.');
    }
    if (augmentations != null) {
      for (Fragment augmentation in augmentations) {
        // Coverage-ignore-block(suite): Not run.
        createBuilder(augmentation);
      }
    }
  }

  _Declaration? _createDeclarationFromFragment(Fragment fragment,
      {required bool inLibrary, required List<Fragment> unnamedFragments}) {
    switch (fragment) {
      case ClassFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Class,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case EnumFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Enum, fragment,
          name: fragment.name,
          // TODO(johnniwinther): Support enum augmentations.
          isAugment: false,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case ExtensionTypeFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.ExtensionType,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case MethodFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Method,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
        );
      case MixinFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Mixin,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case NamedMixinApplicationFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.NamedMixinApplication,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case TypedefFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Typedef, fragment,
          name: fragment.name,
          // TODO(johnniwinther): Support typedef augmentations.
          isAugment: false,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case ExtensionFragment():
        if (!fragment.isUnnamed) {
          return new _StandardFragmentDeclaration(
            _DeclarationKind.Extension,
            fragment,
            name: fragment.name,
            isAugment: fragment.modifiers.isAugment,
            inPatch: fragment.enclosingCompilationUnit.isPatch,
            inLibrary: true,
          );
        } else {
          unnamedFragments.add(fragment);
          return null;
        }
      case FactoryFragment():
        return new _ConstructorFragmentDeclaration(
          _DeclarationKind.Factory,
          fragment,
          name: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
        );
      case ConstructorFragment():
        return new _ConstructorFragmentDeclaration(
          _DeclarationKind.Constructor,
          fragment,
          name: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
        );
      case PrimaryConstructorFragment():
        return new _ConstructorFragmentDeclaration(
          _DeclarationKind.Constructor,
          fragment,
          name: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
        );
      case FieldFragment():
        return new _FieldDeclaration(
          _DeclarationKind.Property,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: fragment.hasSetter
              ? _PropertyKind.Field
              : _PropertyKind.FinalField,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
        );
      case PrimaryConstructorFieldFragment():
        return new _FieldDeclaration(
          _DeclarationKind.Property,
          fragment,
          name: fragment.name,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: false,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: false,
        );
      case GetterFragment():
        return new _GetterDeclaration(
          _DeclarationKind.Property,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Getter,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
        );
      case SetterFragment():
        return new _SetterDeclaration(
          _DeclarationKind.Property,
          fragment,
          name: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Setter,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
        );
      case EnumElementFragment():
        return new _FieldDeclaration(
          _DeclarationKind.Property,
          fragment,
          name: fragment.name,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: true,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
        );
    }
  }

  void createProperty(
      {required String name,
      required UriOffsetLength uriOffset,
      FieldDeclaration? fieldDeclaration,
      GetterDeclaration? getterDeclaration,
      List<GetterDeclaration>? getterAugmentationDeclarations,
      SetterDeclaration? setterDeclaration,
      List<SetterDeclaration>? setterAugmentationDeclarations,
      required bool isStatic,
      required bool inPatch}) {
    _createPropertyBuilder(
        problemReporting: problemReporting,
        loader: loader,
        builderRegistry: builderRegistry,
        name: name,
        uriOffset: uriOffset,
        enclosingLibraryBuilder: enclosingLibraryBuilder,
        declarationBuilder: declarationBuilder,
        unboundNominalParameters: unboundNominalParameters,
        fieldDeclaration: fieldDeclaration,
        getterDeclaration: getterDeclaration,
        getterAugmentations: getterAugmentationDeclarations ?? const [],
        setterDeclaration: setterDeclaration,
        setterAugmentations: setterAugmentationDeclarations ?? const [],
        containerName: containerName,
        containerType: containerType,
        indexedLibrary: indexedLibrary,
        indexedContainer: indexedContainer,
        isStatic: isStatic,
        inPatch: inPatch);
  }
}

/// A [_PreBuilder] is a precursor to a [Builder] with subclasses for
/// properties, constructors, and other declarations.
sealed class _PreBuilder {
  /// Tries to include [declaration] in this [_PreBuilder].
  ///
  /// If [declaration] can be absorbed, `true` is returned. Otherwise an error
  /// is reported and `false` is returned.
  bool absorbFragment(
      ProblemReporting problemReporting, _Declaration declaration);

  /// Checks with [declaration] conflicts with this [_PreBuilder].
  ///
  /// This is called between constructors and non-constructors which do not
  /// occupy the same name space but can only co-exist if the non-constructor
  /// is not static.
  void checkFragment(
      ProblemReporting problemReporting, _Declaration declaration);

  /// Creates [Builder]s for the fragments absorbed into this [_PreBuilder],
  /// using [createBuilder] to create a [Builder] for a single [Fragment].
  ///
  /// If `conflictingSetter` is `true`, the created [Builder] must be marked
  /// as a conflicting setter. This is needed to ensure that we don't create
  /// conflicting AST nodes: Normally we only create [Builder]s for
  /// non-duplicate declarations, but because setters are store in a separate
  /// map the [NameSpace], they are not directly marked as duplicate if they
  /// do not conflict with other setters.
  void createBuilders(_BuilderFactory builderFactory);
}

/// [_PreBuilder] for properties, i.e. fields, getters and setters.
class _PropertyPreBuilder extends _PreBuilder {
  final bool inPatch;
  final String name;
  final UriOffsetLength uriOffset;
  final bool isStatic;
  FieldDeclaration? _field;
  GetterDeclaration? _getter;
  _PropertyKind? _getterPropertyKind;
  SetterDeclaration? _setter;
  _PropertyKind? _setterPropertyKind;
  List<GetterDeclaration> _getterAugmentations = [];
  List<SetterDeclaration> _setterAugmentations = [];

  // TODO(johnniwinther): Report error if [getter] is augmenting.
  _PropertyPreBuilder.forGetter(_PropertyDeclaration getter)
      : isStatic = getter.isStatic,
        inPatch = getter.inPatch,
        name = getter.name,
        uriOffset = getter.uriOffset,
        _getterPropertyKind = getter.propertyKind {
    _PropertyDeclarations declarations = getter.createDeclarations();
    assert(declarations.field == null,
        "Unexpected field declaration from getter ${getter}.");
    assert(declarations.getter != null,
        "Unexpected getter declaration from getter ${getter}.");
    assert(declarations.setter == null,
        "Unexpected setter declaration from getter ${getter}.");
    _getter = declarations.getter;
  }

  // TODO(johnniwinther): Report error if [setter] is augmenting.
  _PropertyPreBuilder.forSetter(_PropertyDeclaration setter)
      : isStatic = setter.isStatic,
        inPatch = setter.inPatch,
        name = setter.name,
        uriOffset = setter.uriOffset,
        _setterPropertyKind = setter.propertyKind {
    _PropertyDeclarations declarations = setter.createDeclarations();
    assert(declarations.field == null,
        "Unexpected field declaration from setter ${setter}.");
    assert(declarations.getter == null,
        "Unexpected getter declaration from setter ${setter}.");
    assert(declarations.setter != null,
        "Unexpected setter declaration from setter ${setter}.");
    _setter = declarations.setter;
  }

  // TODO(johnniwinther): Report error if [field] is augmenting.
  _PropertyPreBuilder.forField(_PropertyDeclaration field)
      : isStatic = field.isStatic,
        inPatch = field.inPatch,
        name = field.name,
        uriOffset = field.uriOffset,
        _getterPropertyKind = field.propertyKind {
    _PropertyDeclarations declarations = field.createDeclarations();
    assert(declarations.field != null,
        "Unexpected field declaration from field ${field}.");
    assert(declarations.getter != null,
        "Unexpected getter declaration from field ${field}.");
    assert(
        (declarations.setter != null) ==
            (_getterPropertyKind == _PropertyKind.Field),
        "Unexpected setter declaration from field ${field}.");
    _field = declarations.field;
    _getter = declarations.getter;
    _setter = declarations.setter;

    if (_getterPropertyKind == _PropertyKind.Field) {
      _setterPropertyKind = field.propertyKind;
    }
  }

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _Declaration declaration) {
    if (declaration is! _PropertyDeclaration) {
      if (_getter != null) {
        // Example:
        //
        //    int get foo => 42;
        //    void foo() {}
        //
        problemReporting.addProblem2(
            templateDuplicatedDeclaration.withArguments(name),
            declaration.uriOffset,
            context: <LocatedMessage>[
              templateDuplicatedDeclarationCause
                  .withArguments(name)
                  .withLocation2(_getter!.uriOffset)
            ]);
      } else {
        assert(_setter != null);
        // Example:
        //
        //    void set foo(_) {}
        //    void foo() {}
        //
        problemReporting.addProblem2(
            templateDeclarationConflictsWithSetter.withArguments(name),
            declaration.uriOffset,
            context: <LocatedMessage>[
              templateDeclarationConflictsWithSetterCause
                  .withArguments(name)
                  .withLocation2(_setter!.uriOffset)
            ]);
      }
      return false;
    }
    _PropertyKind? propertyKind = declaration.propertyKind;

    switch (propertyKind) {
      case _PropertyKind.Getter:
        if (_getter == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    int get foo => 42;
          //
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment int get foo => 42;
            //
            // TODO(johnniwinther): Report error.
          }
          if (declaration.isStatic != isStatic) {
            if (declaration.isStatic) {
              // Coverage-ignore-block(suite): Not run.
              // Example:
              //
              //    class A {
              //      void set foo(_) {}
              //      static int get foo => 42;
              //    }
              //
              problemReporting.addProblem2(
                  templateStaticConflictsWithInstance.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateStaticConflictsWithInstanceCause
                        .withArguments(name)
                        .withLocation2(_setter!.uriOffset)
                  ]);
            } else {
              // Example:
              //
              //    class A {
              //      static void set foo(_) {}
              //      int get foo => 42;
              //    }
              //
              problemReporting.addProblem2(
                  templateInstanceConflictsWithStatic.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateInstanceConflictsWithStaticCause
                        .withArguments(name)
                        .withLocation2(_setter!.uriOffset)
                  ]);
            }
            return false;
          } else {
            _PropertyDeclarations declarations =
                declaration.createDeclarations();
            assert(
                declarations.field == null,
                "Unexpected field declaration from getter "
                "${declaration}.");
            assert(
                declarations.setter == null,
                "Unexpected setter declaration from getter "
                "${declaration}.");
            _getter = declarations.getter;
            assert(_getterPropertyKind == null,
                "Unexpected setter property kind for $_setter");
            _getterPropertyKind == propertyKind;
            return true;
          }
        } else {
          if (declaration.isAugment) {
            // Example:
            //
            //    int get foo => 42;
            //    augment int get foo => 87;
            //
            _PropertyDeclarations declarations =
                declaration.createDeclarations();
            assert(
                declarations.field == null,
                "Unexpected field declaration from getter "
                "${declaration}.");
            assert(
                declarations.setter == null,
                "Unexpected setter declaration from getter "
                "${declaration}.");
            _getterAugmentations.add(declarations.getter!);
            return true;
          } else {
            // Example:
            //
            //    int get foo => 42;
            //    int get foo => 87;
            //
            problemReporting.addProblem2(
                templateDuplicatedDeclaration.withArguments(name),
                declaration.uriOffset,
                context: <LocatedMessage>[
                  templateDuplicatedDeclarationCause
                      .withArguments(name)
                      .withLocation2(_getter!.uriOffset)
                ]);
            return false;
          }
        }
      case _PropertyKind.Setter:
        if (_setter == null) {
          // Examples:
          //
          //    int get foo => 42;
          //    void set foo(_) {}
          //
          //    final int bar = 42;
          //    void set bar(_) {}
          //
          if (declaration.isAugment) {
            // Example:
            //
            //    int get foo => 42;
            //    augment void set foo(_) {}
            //
            // TODO(johnniwinther): Report error.
          }
          if (declaration.isStatic != isStatic) {
            if (declaration.isStatic) {
              // Example:
              //
              //    class A {
              //      int get foo => 42;
              //      static void set foo(_) {}
              //    }
              //
              problemReporting.addProblem2(
                  templateStaticConflictsWithInstance.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateStaticConflictsWithInstanceCause
                        .withArguments(name)
                        .withLocation2(_getter!.uriOffset)
                  ]);
              return false;
            } else {
              // Example:
              //
              //    class A {
              //      static int get foo => 42;
              //      void set foo(_) {}
              //    }
              //
              problemReporting.addProblem2(
                  templateInstanceConflictsWithStatic.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateInstanceConflictsWithStaticCause
                        .withArguments(name)
                        .withLocation2(_getter!.uriOffset)
                  ]);
              return false;
            }
          } else {
            _PropertyDeclarations declarations =
                declaration.createDeclarations();
            assert(
                declarations.field == null,
                "Unexpected field declaration from setter "
                "${declaration}.");
            assert(
                declarations.getter == null,
                "Unexpected getter declaration from setter "
                "${declaration}.");
            _setter = declarations.setter;
            assert(_setterPropertyKind == null,
                "Unexpected setter property kind for $_getter");
            _setterPropertyKind == propertyKind;
            return true;
          }
        } else {
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment void set foo(_) {}
            //
            _PropertyDeclarations declarations =
                declaration.createDeclarations();
            assert(
                declarations.field == null,
                "Unexpected field declaration from setter "
                "${declaration}.");
            assert(
                declarations.getter == null,
                "Unexpected getter declaration from setter "
                "${declaration}.");
            _setterAugmentations.add(declarations.setter!);
            return true;
          } else {
            if (_setterPropertyKind == _PropertyKind.Field) {
              // Example:
              //
              //    int? foo;
              //    void set foo(_) {}
              //
              problemReporting.addProblem2(
                  templateConflictsWithImplicitSetter.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateConflictsWithImplicitSetterCause
                        .withArguments(name)
                        .withLocation2(_setter!.uriOffset)
                  ]);
              return false;
            } else {
              // Example:
              //
              //    void set foo(_) {}
              //    void set foo(_) {}
              //
              problemReporting.addProblem2(
                  templateDuplicatedDeclaration.withArguments(name),
                  declaration.uriOffset,
                  context: <LocatedMessage>[
                    templateDuplicatedDeclarationCause
                        .withArguments(name)
                        .withLocation2(_setter!.uriOffset)
                  ]);
              return false;
            }
          }
        }
      case _PropertyKind.Field:
        if (_getter == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    int? foo;
          //
          assert(_getter == null && _setter != null);
          // We have an explicit setter.
          problemReporting.addProblem2(
              templateConflictsWithSetter.withArguments(name),
              declaration.uriOffset,
              context: [
                templateConflictsWithSetterCause
                    .withArguments(name)
                    .withLocation2(_setter!.uriOffset)
              ]);
          return false;
        } else if (_setter != null) {
          // Examples:
          //
          //    int? foo;
          //    int? foo;
          //
          //    int get bar => 42;
          //    void set bar(_) {}
          //    int bar = 87;
          //
          //    final int baz = 42;
          //    void set baz(_) {}
          //    int baz = 87;
          //
          assert(_getter != null && _setter != null);
          // We have both getter and setter
          if (declaration.isAugment) {
            // Coverage-ignore-block(suite): Not run.
            if (_getterPropertyKind == declaration.propertyKind) {
              // Example:
              //
              //    int foo = 42;
              //    augment int foo = 87;
              //
              _PropertyDeclarations declarations =
                  declaration.createDeclarations();
              // TODO(johnniwinther): Handle field augmentation.
              _getterAugmentations.add(declarations.getter!);
              _setterAugmentations.add(declarations.setter!);
              return true;
            } else {
              // Example:
              //
              //    final int foo = 42;
              //    void set foo(_) {}
              //    augment int foo = 87;
              //
              // TODO(johnniwinther): Report error.
              // TODO(johnniwinther): Should the augment be absorbed in this
              //  case, as an erroneous augmentation?
              return false;
            }
          } else {
            // Examples:
            //
            //    int? foo;
            //    int? foo;
            //
            //    int? get bar => null;
            //    void set bar(_) {}
            //    int? bar;
            //
            problemReporting.addProblem2(
                templateDuplicatedDeclaration.withArguments(name),
                declaration.uriOffset,
                context: <LocatedMessage>[
                  templateDuplicatedDeclarationCause
                      .withArguments(name)
                      .withLocation2(_getter!.uriOffset)
                ]);

            return false;
          }
        } else {
          // Examples:
          //
          //    int get foo => 42;
          //    int? foo;
          //
          //    final int bar = 42;
          //    int? bar;
          //
          assert(_getter != null && _setter == null);
          problemReporting.addProblem2(
              templateDuplicatedDeclaration.withArguments(name),
              declaration.uriOffset,
              context: <LocatedMessage>[
                templateDuplicatedDeclarationCause
                    .withArguments(name)
                    .withLocation2(_getter!.uriOffset)
              ]);
          return false;
        }
      case _PropertyKind.FinalField:
        if (_getter == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    final int foo = 42;
          //
          assert(_getter == null && _setter != null);
          // We have an explicit setter.
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment final int foo = 42;
            //
            // TODO(johnniwinther): Report error.
          }
          if (declaration.isStatic != isStatic) {
            // Coverage-ignore-block(suite): Not run.
            if (declaration.isStatic) {
              // Example:
              //
              //    class A {
              //      void set foo(_) {}
              //      static final int foo = 42;
              //    }
              //
              problemReporting.addProblem2(
                  templateStaticConflictsWithInstance.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateStaticConflictsWithInstanceCause
                        .withArguments(name)
                        .withLocation2(_setter!.uriOffset)
                  ]);
              return false;
            } else {
              // Example:
              //
              //    class A {
              //      static void set foo(_) {}
              //      final int foo = 42;
              //    }
              //
              problemReporting.addProblem2(
                  templateInstanceConflictsWithStatic.withArguments(name),
                  declaration.uriOffset,
                  context: [
                    templateInstanceConflictsWithStaticCause
                        .withArguments(name)
                        .withLocation2(_setter!.uriOffset)
                  ]);
              return false;
            }
          } else {
            _PropertyDeclarations declarations =
                declaration.createDeclarations();
            assert(
                declarations.setter == null,
                "Unexpected setter declaration from field "
                "${declaration}.");
            _field = declarations.field;
            _getter = declarations.getter;
            assert(
                _getterPropertyKind == null,
                "Unexpected getter property kind $_getterPropertyKind for "
                "$_setter.");
            _getterPropertyKind = propertyKind;
            return true;
          }
        } else {
          // Examples:
          //
          //    final int foo = 42;
          //    final int foo = 87;
          //
          //    int get bar => 42;
          //    final int bar = 87;
          //
          if (declaration.isAugment) {
            // Coverage-ignore-block(suite): Not run.
            if (_getterPropertyKind == declaration.propertyKind) {
              // Example:
              //
              //    final int foo = 42;
              //    augment final int foo = 87;
              //
              _PropertyDeclarations declarations =
                  declaration.createDeclarations();
              assert(
                  declarations.setter == null,
                  "Unexpected setter declaration from final field "
                  "${declaration}.");
              // TODO(johnniwinther): Handle field augmentation.
              _getterAugmentations.add(declarations.getter!);
              return true;
            } else {
              // Example:
              //
              //    int foo = 42;
              //    augment final int foo = 87;
              //
              // TODO(johnniwinther): Report error.
              // TODO(johnniwinther): Should the augment be absorbed in this
              //  case, as an erroneous augmentation?
              return false;
            }
          } else {
            // Examples:
            //
            //    final int foo = 42;
            //    final int foo = 87;
            //
            //    int get bar => 42;
            //    final int bar = 87;
            //
            problemReporting.addProblem2(
                templateDuplicatedDeclaration.withArguments(name),
                declaration.uriOffset,
                context: <LocatedMessage>[
                  templateDuplicatedDeclarationCause
                      .withArguments(name)
                      .withLocation2(_getter!.uriOffset)
                ]);
            return false;
          }
        }
    }
  }

  @override
  void checkFragment(
      ProblemReporting problemReporting, _Declaration constructorDeclaration) {
    // Check conflict with constructor.
    if (isStatic) {
      if (_getter != null) {
        if (constructorDeclaration.kind == _DeclarationKind.Constructor) {
          // Example:
          //
          //    class A {
          //      static int get foo => 42;
          //      A.foo();
          //    }
          //
          problemReporting.addProblem2(
              templateConstructorConflictsWithMember.withArguments(name),
              constructorDeclaration.uriOffset,
              context: [
                templateConstructorConflictsWithMemberCause
                    .withArguments(name)
                    .withLocation2(_getter!.uriOffset)
              ]);
        } else {
          // Coverage-ignore-block(suite): Not run.
          assert(constructorDeclaration.kind == _DeclarationKind.Factory,
              "Unexpected constructor kind $constructorDeclaration");
          // Example:
          //
          //    class A {
          //      static int get foo => 42;
          //      factory A.foo() => throw '';
          //    }
          //
          problemReporting.addProblem2(
              templateFactoryConflictsWithMember.withArguments(name),
              constructorDeclaration.uriOffset,
              context: [
                templateFactoryConflictsWithMemberCause
                    .withArguments(name)
                    .withLocation2(_getter!.uriOffset)
              ]);
        }
      } else {
        // Coverage-ignore-block(suite): Not run.
        if (constructorDeclaration.kind == _DeclarationKind.Constructor) {
          // Example:
          //
          //    class A {
          //      static void set foo(_) {}
          //      A.foo();
          //    }
          //
          problemReporting.addProblem2(
              templateConstructorConflictsWithMember.withArguments(name),
              constructorDeclaration.uriOffset,
              context: [
                templateConstructorConflictsWithMemberCause
                    .withArguments(name)
                    .withLocation2(_setter!.uriOffset)
              ]);
        } else {
          assert(constructorDeclaration.kind == _DeclarationKind.Factory,
              "Unexpected constructor kind $constructorDeclaration");
          // Example:
          //
          //    class A {
          //      static void set foo(_) {}
          //      factory A.foo() => throw '';
          //    }
          //
          problemReporting.addProblem2(
              templateFactoryConflictsWithMember.withArguments(name),
              constructorDeclaration.uriOffset,
              context: [
                templateFactoryConflictsWithMemberCause
                    .withArguments(name)
                    .withLocation2(_setter!.uriOffset)
              ]);
        }
      }
    }
  }

  @override
  void createBuilders(_BuilderFactory builderFactory) {
    builderFactory.createProperty(
        name: name,
        inPatch: inPatch,
        isStatic: isStatic,
        uriOffset: uriOffset,
        fieldDeclaration: _field,
        getterDeclaration: _getter,
        getterAugmentationDeclarations: _getterAugmentations,
        setterDeclaration: _setter,
        setterAugmentationDeclarations: _setterAugmentations);
  }
}

/// [_PreBuilder] for generative and factory constructors.
class _ConstructorPreBuilder extends _PreBuilder {
  final _ConstructorDeclaration _declaration;
  final List<_ConstructorDeclaration> _augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  _ConstructorPreBuilder(this._declaration);

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _Declaration declaration) {
    if (declaration.isAugment) {
      if (declaration is _ConstructorDeclaration &&
          declaration.kind == _declaration.kind) {
        // Example:
        //
        //    class A {
        //      A();
        //      augment A();
        //    }
        //
        _augmentations.add(declaration);
        return true;
      } else {
        // Example:
        //
        //    class A {
        //      A();
        //      augment void A() {}
        //    }
        //
        // TODO(johnniwinther): Report augmentation conflict.
        return false;
      }
    } else {
      // Example:
      //
      //    class A {
      //      A();
      //      A();
      //    }
      //
      problemReporting.addProblem2(
          templateDuplicatedDeclaration.withArguments(declaration.name),
          declaration.uriOffset,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(_declaration.name)
                .withLocation2(_declaration.uriOffset)
          ]);
      return false;
    }
  }

  @override
  void checkFragment(ProblemReporting problemReporting,
      _Declaration nonConstructorDeclaration) {
    // Check conflict with non-constructor.
    if (nonConstructorDeclaration.isStatic) {
      // Coverage-ignore-block(suite): Not run.
      if (_declaration.kind == _DeclarationKind.Constructor) {
        // Example:
        //
        //    class A {
        //      A.foo();
        //      static void foo() {}
        //    }
        //
        problemReporting.addProblem2(
            templateMemberConflictsWithConstructor
                .withArguments(_declaration.name),
            nonConstructorDeclaration.uriOffset,
            context: [
              templateMemberConflictsWithConstructorCause
                  .withArguments(_declaration.name)
                  .withLocation2(_declaration.uriOffset)
            ]);
      } else {
        assert(_declaration.kind == _DeclarationKind.Factory,
            "Unexpected constructor kind $_declaration");
        // Example:
        //
        //    class A {
        //      factory A.foo() => throw '';
        //      static void foo() {}
        //    }
        //
        problemReporting.addProblem2(
            templateMemberConflictsWithFactory.withArguments(_declaration.name),
            nonConstructorDeclaration.uriOffset,
            context: [
              templateMemberConflictsWithFactoryCause
                  .withArguments(_declaration.name)
                  .withLocation2(_declaration.uriOffset)
            ]);
      }
    }
  }

  @override
  void createBuilders(_BuilderFactory builderFactory) {
    builderFactory.createBuilder(_declaration._fragment,
        augmentations: _augmentations.map((f) => f._fragment).toList());
  }
}

/// [_PreBuilder] for non-constructor, non-property declarations.
class _DeclarationPreBuilder extends _PreBuilder {
  final _Declaration _declaration;
  final List<_Declaration> _augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  _DeclarationPreBuilder(this._declaration);

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _Declaration declaration) {
    if (declaration.isAugment) {
      if (declaration.kind == _declaration.kind) {
        // Example:
        //
        //    class Foo {}
        //    augment class Foo {}
        //
        _augmentations.add(declaration);
        return true;
      } else {
        // Example:
        //
        //    class Foo {}
        //    augment extension Foo {}
        //
        // TODO(johnniwinther): Report augmentation conflict.
        return false;
      }
    } else {
      if (declaration is _PropertyDeclaration &&
          declaration.propertyKind == _PropertyKind.Setter) {
        // Example:
        //
        //    class Foo {}
        //    set Foo(_) {}
        //
        problemReporting.addProblem2(
            templateSetterConflictsWithDeclaration
                .withArguments(_declaration.name),
            declaration.uriOffset,
            context: [
              templateSetterConflictsWithDeclarationCause
                  .withArguments(_declaration.name)
                  .withLocation2(_declaration.uriOffset)
            ]);
      } else {
        // Example:
        //
        //    class Foo {}
        //    class Foo {}
        //
        problemReporting.addProblem2(
            templateDuplicatedDeclaration.withArguments(declaration.name),
            declaration.uriOffset,
            context: <LocatedMessage>[
              templateDuplicatedDeclarationCause
                  .withArguments(_declaration.name)
                  .withLocation2(_declaration.uriOffset)
            ]);
      }
      return false;
    }
  }

  @override
  void checkFragment(
      ProblemReporting problemReporting, _Declaration constructorDeclaration) {
    // Check conflict with constructor.
    if (_declaration.isStatic) {
      if (constructorDeclaration.kind == _DeclarationKind.Constructor) {
        // Example:
        //
        //    class A {
        //      static void foo() {}
        //      A.foo();
        //    }
        //
        problemReporting.addProblem2(
            templateConstructorConflictsWithMember
                .withArguments(_declaration.name),
            constructorDeclaration.uriOffset,
            context: [
              templateConstructorConflictsWithMemberCause
                  .withArguments(_declaration.name)
                  .withLocation2(_declaration.uriOffset)
            ]);
      } else {
        assert(constructorDeclaration.kind == _DeclarationKind.Factory,
            "Unexpected constructor kind $constructorDeclaration");
        // Example:
        //
        //    class A {
        //      static void foo() {}
        //      factory A.foo() => throw '';
        //    }
        //
        problemReporting.addProblem2(
            templateFactoryConflictsWithMember.withArguments(_declaration.name),
            constructorDeclaration.uriOffset,
            context: [
              templateFactoryConflictsWithMemberCause
                  .withArguments(_declaration.name)
                  .withLocation2(_declaration.uriOffset)
            ]);
      }
    }
  }

  @override
  void createBuilders(_BuilderFactory builderFactory) {
    builderFactory.createBuilder(_declaration._fragment,
        augmentations: _augmentations.map((f) => f._fragment).toList());
  }
}

/// Reports an error if [fragmentName] is augmenting.
///
/// This is called when the first [_PreBuilder] is created, meaning that the
/// augmentation didn't correspond to an introductory declaration.
void _checkAugmentation(
    ProblemReporting problemReporting, _Declaration fragmentName) {
  if (fragmentName.isAugment) {
    Message message;
    switch (fragmentName.kind) {
      case _DeclarationKind.Class:
        message = fragmentName.inPatch
            ? templateUnmatchedPatchClass.withArguments(fragmentName.name)
            :
            // Coverage-ignore(suite): Not run.
            templateUnmatchedAugmentationClass.withArguments(fragmentName.name);
      case _DeclarationKind.Constructor:
      case _DeclarationKind.Factory:
      case _DeclarationKind.Method:
      case _DeclarationKind.Property:
        if (fragmentName.inLibrary) {
          message = fragmentName.inPatch
              ? templateUnmatchedPatchLibraryMember
                  .withArguments(fragmentName.name)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationLibraryMember
                  .withArguments(fragmentName.name);
        } else {
          message = fragmentName.inPatch
              ? templateUnmatchedPatchClassMember
                  .withArguments(fragmentName.name)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationClassMember
                  .withArguments(fragmentName.name);
        }
      case _DeclarationKind.Mixin:
      case _DeclarationKind.NamedMixinApplication:
      case _DeclarationKind.Enum:
      case _DeclarationKind.Extension:
      // Coverage-ignore(suite): Not run.
      case _DeclarationKind.ExtensionType:
      // Coverage-ignore(suite): Not run.
      case _DeclarationKind.Typedef:
        // TODO(johnniwinther): Specialize more messages.
        message = fragmentName.inPatch
            ? templateUnmatchedPatchDeclaration.withArguments(fragmentName.name)
            :
            // Coverage-ignore(suite): Not run.
            templateUnmatchedAugmentationDeclaration
                .withArguments(fragmentName.name);
    }
    problemReporting.addProblem2(message, fragmentName.uriOffset);
  }
}

class LibraryNameSpaceBuilder {
  List<Fragment> _fragments = [];

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  void includeBuilders(LibraryNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
  }

  MutableNameSpace toNameSpace({
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required IndexedLibrary? indexedLibrary,
    required ProblemReporting problemReporting,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required List<NamedBuilder> memberBuilders,
  }) {
    _LibraryBuilderRegistry builderRegistry = new _LibraryBuilderRegistry(
        problemReporting: problemReporting,
        enclosingLibraryBuilder: enclosingLibraryBuilder,
        memberBuilders: memberBuilders);

    Map<String, List<Fragment>> fragmentsByName = {};
    for (Fragment fragment in _fragments) {
      (fragmentsByName[fragment.name] ??= []).add(fragment);
    }

    _BuilderFactory builderFactory = new _BuilderFactory(
        loader: enclosingLibraryBuilder.loader,
        builderRegistry: builderRegistry,
        problemReporting: problemReporting,
        enclosingLibraryBuilder: enclosingLibraryBuilder,
        unboundNominalParameters: unboundNominalParameters,
        mixinApplications: mixinApplications,
        indexedLibrary: indexedLibrary,
        containerType: ContainerType.Library);

    for (MapEntry<String, List<Fragment>> entry in fragmentsByName.entries) {
      builderFactory.computeBuildersFromFragments(entry.key, entry.value);
    }
    return new SourceLibraryNameSpace(
        content: builderRegistry.content,
        extensions: builderRegistry.extensions);
  }
}

abstract class _BuilderRegistry {
  void registerBuilder(
      {required NamedBuilder declaration,
      required UriOffsetLength uriOffset,
      required bool inPatch});
}

class _LibraryBuilderRegistry implements _BuilderRegistry {
  final Map<String, LookupResult> content = {};
  final Set<ExtensionBuilder> extensions = {};
  final ProblemReporting problemReporting;
  final SourceLibraryBuilder enclosingLibraryBuilder;
  final List<NamedBuilder> memberBuilders;

  _LibraryBuilderRegistry(
      {required this.problemReporting,
      required this.enclosingLibraryBuilder,
      required this.memberBuilders});

  bool _allowInjectedPublicMember(
      SourceLibraryBuilder enclosingLibraryBuilder, Builder newBuilder) {
    return enclosingLibraryBuilder.importUri.isScheme("dart") &&
        enclosingLibraryBuilder.importUri.path.startsWith("_");
  }

  @override
  void registerBuilder(
      {required NamedBuilder declaration,
      required UriOffsetLength uriOffset,
      required bool inPatch}) {
    String name = declaration.name;

    assert(declaration.next == null,
        "Unexpected declaration.next ${declaration.next} on $declaration");

    memberBuilders.add(declaration);

    if (declaration is SourceExtensionBuilder &&
        declaration.isUnnamedExtension) {
      extensions.add(declaration);
      return;
    }

    if (declaration is MemberBuilder || declaration is TypeDeclarationBuilder) {
      // Expected.
    } else {
      // Coverage-ignore-block(suite): Not run.
      // Prefix builders are added when computing the import scope.
      assert(declaration is! PrefixBuilder,
          "Unexpected prefix builder $declaration.");
      unhandled("${declaration.runtimeType}", "addBuilder",
          uriOffset.fileOffset, uriOffset.fileUri);
    }

    assert(
        !(declaration is FunctionBuilder &&
            // Coverage-ignore(suite): Not run.
            (declaration is ConstructorBuilder ||
                declaration is FactoryBuilder)),
        "Unexpected constructor in library: $declaration.");

    if (inPatch &&
        !name.startsWith('_') &&
        !_allowInjectedPublicMember(enclosingLibraryBuilder, declaration)) {
      problemReporting.addProblem2(
          templatePatchInjectionFailed.withArguments(
              name, enclosingLibraryBuilder.importUri),
          uriOffset);
    }

    LookupResult? existingResult = content[name];
    NamedBuilder? existing = existingResult?.getable ?? existingResult?.setable;

    assert(
        existing != declaration, "Unexpected existing declaration $existing");

    if (declaration.next != null &&
        // Coverage-ignore(suite): Not run.
        declaration.next != existing) {
      unexpected(
          "${declaration.next!.fileUri}@${declaration.next!.fileOffset}",
          "${existing?.fileUri}@${existing?.fileOffset}",
          declaration.fileOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (declaration is SourceExtensionBuilder && !declaration.isDuplicate) {
      // We add the extension declaration to the extension scope only if its
      // name is unique. Only the first of duplicate extensions is accessible
      // by name or by resolution and the remaining are dropped for the
      // output.
      extensions.add(declaration);
    }
    content[name] = declaration as LookupResult;
  }
}

class NominalParameterScope extends AbstractTypeParameterScope {
  final NominalParameterNameSpace _nameSpace;

  NominalParameterScope(super._parent, this._nameSpace);

  @override
  TypeParameterBuilder? getTypeParameter(String name) =>
      _nameSpace.getTypeParameter(name);
}

class NominalParameterNameSpace {
  Map<String, SourceNominalParameterBuilder> _typeParametersByName = {};

  SourceNominalParameterBuilder? getTypeParameter(String name) =>
      _typeParametersByName[name];

  void addTypeParameters(ProblemReporting _problemReporting,
      List<SourceNominalParameterBuilder>? typeParameters,
      {required String? ownerName, required bool allowNameConflict}) {
    if (typeParameters == null || typeParameters.isEmpty) return;
    for (SourceNominalParameterBuilder tv in typeParameters) {
      SourceNominalParameterBuilder? existing = _typeParametersByName[tv.name];
      if (tv.isWildcard) continue;
      if (existing != null) {
        if (existing.kind == TypeParameterKind.extensionSynthesized) {
          // The type parameter from the extension is shadowed by the type
          // parameter from the member. Rename the shadowed type parameter.
          existing.parameter.name = '#${existing.name}';
          _typeParametersByName[tv.name] = tv;
        } else {
          _problemReporting.addProblem(messageTypeParameterDuplicatedName,
              tv.fileOffset, tv.name.length, tv.fileUri,
              context: [
                templateTypeParameterDuplicatedNameCause
                    .withArguments(tv.name)
                    .withLocation(existing.fileUri, existing.fileOffset,
                        existing.name.length)
              ]);
        }
      } else {
        _typeParametersByName[tv.name] = tv;
        // Only classes and extension types and type parameters can't have the
        // same name. See
        // [#29555](https://github.com/dart-lang/sdk/issues/29555) and
        // [#54602](https://github.com/dart-lang/sdk/issues/54602).
        if (tv.name == ownerName && !allowNameConflict) {
          _problemReporting.addProblem(messageTypeParameterSameNameAsEnclosing,
              tv.fileOffset, tv.name.length, tv.fileUri);
        }
      }
    }
  }
}

enum DeclarationFragmentKind {
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
}

abstract class DeclarationFragmentImpl implements DeclarationFragment {
  final Uri fileUri;

  /// The scope in which the declaration is declared.
  ///
  /// This is the scope of the enclosing compilation unit and it's used for
  /// resolving metadata on the declaration.
  final LookupScope enclosingScope;

  final LookupScope typeParameterScope;
  final DeclarationBuilderScope bodyScope;
  final List<Fragment> _fragments = [];

  @override
  final List<TypeParameterFragment>? typeParameters;

  final NominalParameterNameSpace nominalParameterNameSpace;

  final LibraryFragment enclosingCompilationUnit;

  DeclarationFragmentImpl({
    required this.fileUri,
    required this.typeParameters,
    required this.enclosingScope,
    required this.typeParameterScope,
    required NominalParameterNameSpace nominalParameterNameSpace,
    required this.enclosingCompilationUnit,
  })  : nominalParameterNameSpace = nominalParameterNameSpace,
        bodyScope = new DeclarationBuilderScope(typeParameterScope);

  String get name;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  DeclarationBuilder get builder;

  UriOffsetLength get uriOffset;

  void addPrimaryConstructorField(PrimaryConstructorFieldFragment fragment) {
    throw new UnsupportedError(
        "Unexpected primary constructor field in $this.");
  }

  void addEnumElement(EnumElementFragment fragment) {
    throw new UnsupportedError("Unexpected enum element in $this.");
  }

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder() {
    return new DeclarationNameSpaceBuilder._(
        name, nominalParameterNameSpace, _fragments);
  }
}

class DeclarationNameSpaceBuilder {
  final String _name;
  final NominalParameterNameSpace? _nominalParameterNameSpace;
  final List<Fragment> _fragments;

  DeclarationNameSpaceBuilder.empty()
      : _name = '',
        _nominalParameterNameSpace = null,
        _fragments = const [];

  DeclarationNameSpaceBuilder._(
      this._name, this._nominalParameterNameSpace, this._fragments);

  void includeBuilders(DeclarationNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
    other._fragments.clear();
  }

  void checkTypeParameterConflict(ProblemReporting _problemReporting,
      String name, Builder member, Uri fileUri) {
    if (_nominalParameterNameSpace != null) {
      NominalParameterBuilder? tv =
          _nominalParameterNameSpace.getTypeParameter(name);
      if (tv != null) {
        _problemReporting.addProblem(
            templateConflictsWithTypeParameter.withArguments(name),
            member.fileOffset,
            name.length,
            fileUri,
            context: [
              messageConflictsWithTypeParameterCause.withLocation(
                  tv.fileUri!, tv.fileOffset, name.length)
            ]);
      }
    }
  }

  MutableDeclarationNameSpace buildNameSpace(
      {required SourceLoader loader,
      required ProblemReporting problemReporting,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required IndexedLibrary? indexedLibrary,
      required IndexedContainer? indexedContainer,
      required ContainerType containerType,
      required ContainerName containerName,
      required List<SourceMemberBuilder> constructorBuilders,
      required List<SourceMemberBuilder> memberBuilders}) {
    List<NominalParameterBuilder> unboundNominalParameters = [];

    _DeclarationBuilderRegistry builderRegistry =
        new _DeclarationBuilderRegistry(
            problemReporting: problemReporting,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationName: _name,
            constructorBuilders: constructorBuilders,
            memberBuilders: memberBuilders);

    Map<String, List<Fragment>> fragmentsByName = {};
    for (Fragment fragment in _fragments) {
      (fragmentsByName[fragment.name] ??= []).add(fragment);
    }

    _BuilderFactory builderFactory = new _BuilderFactory(
        loader: loader,
        problemReporting: problemReporting,
        enclosingLibraryBuilder: enclosingLibraryBuilder,
        builderRegistry: builderRegistry,
        declarationBuilder: declarationBuilder,
        unboundNominalParameters: unboundNominalParameters,
        // TODO(johnniwinther): Avoid passing this:
        mixinApplications: const {},
        indexedLibrary: indexedLibrary,
        indexedContainer: indexedContainer,
        containerType: containerType,
        containerName: containerName);
    for (MapEntry<String, List<Fragment>> entry in fragmentsByName.entries) {
      builderFactory.computeBuildersFromFragments(entry.key, entry.value);
    }

    void checkConflicts(String name, Builder member) {
      checkTypeParameterConflict(
          problemReporting, name, member, member.fileUri!);
    }

    builderRegistry.content.forEach((String name, LookupResult lookupResult) {
      NamedBuilder member = (lookupResult.getable ?? lookupResult.setable)!;
      checkTypeParameterConflict(
          problemReporting, name, member, member.fileUri!);
    });
    builderRegistry.constructors.forEach(checkConflicts);

    enclosingLibraryBuilder
        .registerUnboundNominalParameters(unboundNominalParameters);

    return new SourceDeclarationNameSpace(
        content: builderRegistry.content,
        constructors: builderRegistry.constructors);
  }
}

class _DeclarationBuilderRegistry implements _BuilderRegistry {
  final Map<String, LookupResult> content = {};
  final Map<String, MemberBuilder> constructors = {};
  final ProblemReporting problemReporting;
  final SourceLibraryBuilder enclosingLibraryBuilder;
  final String declarationName;
  final List<SourceMemberBuilder> constructorBuilders;
  final List<SourceMemberBuilder> memberBuilders;

  _DeclarationBuilderRegistry(
      {required this.problemReporting,
      required this.enclosingLibraryBuilder,
      required this.declarationName,
      required this.constructorBuilders,
      required this.memberBuilders});

  bool _allowInjectedPublicMember(
      SourceLibraryBuilder enclosingLibraryBuilder, Builder newBuilder) {
    if (enclosingLibraryBuilder.importUri.isScheme("dart") &&
        enclosingLibraryBuilder.importUri.path.startsWith("_")) {
      return true;
    }
    if (newBuilder.isStatic) {
      return declarationName.startsWith('_');
    }
    // TODO(johnniwinther): Restrict the use of injected public class members.
    return true;
  }

  @override
  void registerBuilder(
      {required NamedBuilder declaration,
      required UriOffsetLength uriOffset,
      required bool inPatch}) {
    String name = declaration.name;

    assert(declaration.next == null,
        "Unexpected declaration.next ${declaration.next} on $declaration");

    bool isConstructor =
        declaration is ConstructorBuilder || declaration is FactoryBuilder;
    if (!isConstructor && name == declarationName) {
      problemReporting.addProblem2(messageMemberWithSameNameAsClass, uriOffset);
    }
    if (isConstructor) {
      constructorBuilders.add(declaration as SourceMemberBuilder);
    } else {
      memberBuilders.add(declaration as SourceMemberBuilder);
    }

    if (inPatch &&
        !name.startsWith('_') &&
        !_allowInjectedPublicMember(enclosingLibraryBuilder, declaration)) {
      // TODO(johnniwinther): Test adding a no-name constructor in the
      //  patch, either as an injected or duplicated constructor.
      problemReporting.addProblem2(
          templatePatchInjectionFailed.withArguments(
              name, enclosingLibraryBuilder.importUri),
          uriOffset);
    }

    if (isConstructor) {
      NamedBuilder? existing = constructors[name];

      assert(
          existing != declaration, "Unexpected existing declaration $existing");

      if (declaration.next != null &&
          // Coverage-ignore(suite): Not run.
          declaration.next != existing) {
        unexpected(
            "${declaration.next!.fileUri}@${declaration.next!.fileOffset}",
            "${existing?.fileUri}@${existing?.fileOffset}",
            declaration.fileOffset,
            declaration.fileUri);
      }
      declaration.next = existing;
      constructors[name] = declaration as MemberBuilder;
    } else {
      LookupResult? existingResult = content[name];
      NamedBuilder? existing =
          existingResult?.getable ?? existingResult?.setable;

      assert(
          existing != declaration, "Unexpected existing declaration $existing");

      if (declaration.next != null &&
          // Coverage-ignore(suite): Not run.
          declaration.next != existing) {
        unexpected(
            "${declaration.next!.fileUri}@${declaration.next!.fileOffset}",
            "${existing?.fileUri}@${existing?.fileOffset}",
            declaration.fileOffset,
            declaration.fileUri);
      }
      declaration.next = existing;
      content[name] = declaration as LookupResult;
    }
  }
}

enum TypeScopeKind {
  library,
  declarationTypeParameters,
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
  memberTypeParameters,
  functionTypeParameters,
  unnamedMixinApplication,
}

class TypeScope {
  final TypeScopeKind kind;

  List<NamedTypeBuilder> _unresolvedNamedTypes = [];

  List<TypeScope> _childScopes = [];

  final LookupScope lookupScope;

  TypeScope(this.kind, this.lookupScope, [TypeScope? parent]) {
    parent?._childScopes.add(this);
  }

  void registerUnresolvedNamedType(NamedTypeBuilder namedTypeBuilder) {
    _unresolvedNamedTypes.add(namedTypeBuilder);
  }

  int resolveTypes(ProblemReporting problemReporting) {
    int typeCount = _unresolvedNamedTypes.length;
    if (_unresolvedNamedTypes.isNotEmpty) {
      for (NamedTypeBuilder namedTypeBuilder in _unresolvedNamedTypes) {
        namedTypeBuilder.resolveIn(lookupScope, namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!, problemReporting);
      }
      _unresolvedNamedTypes.clear();
    }
    for (TypeScope childScope in _childScopes) {
      typeCount += childScope.resolveTypes(problemReporting);
    }
    return typeCount;
  }

  // Coverage-ignore(suite): Not run.
  bool get isEmpty => _unresolvedNamedTypes.isEmpty && _childScopes.isEmpty;

  @override
  String toString() => 'TypeScope($kind,$_unresolvedNamedTypes)';
}

List<SourceNominalParameterBuilder>? createNominalParameterBuilders(
    List<TypeParameterFragment>? fragments,
    List<NominalParameterBuilder> unboundNominalParameters) {
  if (fragments == null) return null;
  List<SourceNominalParameterBuilder> list = [];
  for (TypeParameterFragment fragment in fragments) {
    list.add(createNominalParameterBuilder(fragment, unboundNominalParameters));
  }
  return list;
}

SourceNominalParameterBuilder createNominalParameterBuilder(
    TypeParameterFragment fragment,
    List<NominalParameterBuilder> unboundNominalParameters) {
  SourceNominalParameterBuilder builder = new SourceNominalParameterBuilder(
      new RegularNominalParameterDeclaration(fragment),
      bound: fragment.bound,
      variableVariance: fragment.variance);

  unboundNominalParameters.add(builder);
  fragment.builder = builder;
  return builder;
}

void _createTypedefBuilder(TypedefFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  List<SourceNominalParameterBuilder>? nominalParameters =
      createNominalParameterBuilders(
          fragment.typeParameters, unboundNominalParameters);
  if (nominalParameters != null) {
    for (SourceNominalParameterBuilder typeParameter in nominalParameters) {
      typeParameter.varianceCalculationValue = VarianceCalculationValue.pending;
    }
  }
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, nominalParameters,
      ownerName: fragment.name, allowNameConflict: true);

  Reference? reference = indexedLibrary?.lookupTypedef(fragment.name);
  SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
      name: fragment.name,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      fragment: fragment,
      reference: reference);
  if (reference != null) {
    loader.buildersCreatedWithReferences[reference] = typedefBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: typedefBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createClassBuilder(ClassFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  String name = fragment.name;
  DeclarationNameSpaceBuilder nameSpaceBuilder =
      fragment.toDeclarationNameSpaceBuilder();
  ClassDeclaration introductoryDeclaration =
      new RegularClassDeclaration(fragment);
  List<SourceNominalParameterBuilder>? nominalParameters =
      createNominalParameterBuilders(
          fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, nominalParameters,
      ownerName: fragment.name, allowNameConflict: false);

  Modifiers modifiers = fragment.modifiers;
  List<ClassDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    int introductoryTypeParameterCount = fragment.typeParameters?.length ?? 0;
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ClassFragment].
      augmentation as ClassFragment;

      // TODO(johnniwinther): Check that other modifiers are consistent.
      if (augmentation.modifiers.declaresConstConstructor) {
        modifiers |= Modifiers.DeclaresConstConstructor;
      }
      augmentationDeclarations.add(new RegularClassDeclaration(augmentation));
      nameSpaceBuilder
          .includeBuilders(augmentation.toDeclarationNameSpaceBuilder());

      int augmentationTypeParameterCount =
          augmentation.typeParameters?.length ?? 0;
      if (introductoryTypeParameterCount != augmentationTypeParameterCount) {
        problemReporting.addProblem(messagePatchClassTypeParametersMismatch,
            augmentation.nameOffset, name.length, augmentation.fileUri,
            context: [
              messagePatchClassOrigin.withLocation(
                  fragment.fileUri, fragment.nameOffset, name.length)
            ]);

        // Error recovery. Create fresh type parameters for the
        // augmentation.
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting,
            createNominalParameterBuilders(
                augmentation.typeParameters, unboundNominalParameters),
            ownerName: augmentation.name,
            allowNameConflict: false);
      } else if (augmentation.typeParameters != null) {
        for (int index = 0; index < introductoryTypeParameterCount; index++) {
          SourceNominalParameterBuilder nominalParameterBuilder =
              nominalParameters![index];
          TypeParameterFragment typeParameterFragment =
              augmentation.typeParameters![index];
          nominalParameterBuilder.addAugmentingDeclaration(
              new RegularNominalParameterDeclaration(typeParameterFragment));
          typeParameterFragment.builder = nominalParameterBuilder;
        }
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting, nominalParameters,
            ownerName: augmentation.name, allowNameConflict: false);
      }
    }
  }
  IndexedClass? indexedClass = indexedLibrary?.lookupIndexedClass(name);
  SourceClassBuilder classBuilder = new SourceClassBuilder(
      modifiers: modifiers,
      name: name,
      typeParameters: fragment.typeParameters?.builders,
      typeParameterScope: fragment.typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: indexedClass,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations);
  fragment.builder = classBuilder;
  fragment.bodyScope.declarationBuilder = classBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      augmentation as ClassFragment;
      augmentation.builder = classBuilder;
      augmentation.bodyScope.declarationBuilder = classBuilder;
    }
    augmentations.clear();
  }
  if (indexedClass != null) {
    loader.buildersCreatedWithReferences[indexedClass.reference] = classBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: classBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createMixinBuilder(MixinFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  IndexedClass? indexedClass =
      indexedLibrary?.lookupIndexedClass(fragment.name);
  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  List<SourceNominalParameterBuilder>? typeParameters =
      fragment.typeParameters?.builders;
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, typeParameters,
      ownerName: fragment.name, allowNameConflict: false);
  SourceClassBuilder mixinBuilder = new SourceClassBuilder(
      modifiers: fragment.modifiers,
      name: fragment.name,
      typeParameters: typeParameters,
      typeParameterScope: fragment.typeParameterScope,
      nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: indexedClass,
      introductory: new MixinDeclaration(fragment));
  fragment.builder = mixinBuilder;
  fragment.bodyScope.declarationBuilder = mixinBuilder;
  if (indexedClass != null) {
    loader.buildersCreatedWithReferences[indexedClass.reference] = mixinBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: mixinBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createNamedMixinApplicationBuilder(NamedMixinApplicationFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required IndexedLibrary? indexedLibrary}) {
  List<TypeBuilder> mixins = fragment.mixins.toList();
  TypeBuilder mixin = mixins.removeLast();
  ClassDeclaration classDeclaration =
      new NamedMixinApplication(fragment, mixins);

  String name = fragment.name;

  IndexedClass? referencesFromIndexedClass;
  if (indexedLibrary != null) {
    referencesFromIndexedClass = indexedLibrary.lookupIndexedClass(name);
  }

  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, fragment.typeParameters?.builders,
      ownerName: name, allowNameConflict: false);
  LookupScope typeParameterScope = TypeParameterScope.fromList(
      fragment.enclosingScope, fragment.typeParameters?.builders);
  DeclarationNameSpaceBuilder nameSpaceBuilder =
      new DeclarationNameSpaceBuilder.empty();
  SourceClassBuilder classBuilder = new SourceClassBuilder(
      modifiers: fragment.modifiers | Modifiers.NamedMixinApplication,
      name: name,
      typeParameters: fragment.typeParameters?.builders,
      typeParameterScope: typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: referencesFromIndexedClass,
      mixedInTypeBuilder: mixin,
      introductory: classDeclaration);
  mixinApplications[classBuilder] = mixin;
  fragment.builder = classBuilder;
  if (referencesFromIndexedClass != null) {
    loader.buildersCreatedWithReferences[referencesFromIndexedClass.reference] =
        classBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: classBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createEnumBuilder(EnumFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  IndexedClass? indexedClass =
      indexedLibrary?.lookupIndexedClass(fragment.name);
  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  List<SourceNominalParameterBuilder>? typeParameters =
      fragment.typeParameters?.builders;
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, typeParameters,
      ownerName: fragment.name, allowNameConflict: false);
  SourceEnumBuilder enumBuilder = new SourceEnumBuilder(
      name: fragment.name,
      typeParameters: typeParameters,
      underscoreEnumTypeBuilder: loader.target.underscoreEnumType,
      interfaceBuilders: fragment.interfaces,
      enumElements: fragment.enumElements,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      startOffset: fragment.startOffset,
      nameOffset: fragment.nameOffset,
      endOffset: fragment.endOffset,
      indexedClass: indexedClass,
      typeParameterScope: fragment.typeParameterScope,
      nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
      classDeclaration:
          new EnumDeclaration(fragment, loader.target.underscoreEnumType));
  fragment.builder = enumBuilder;
  fragment.bodyScope.declarationBuilder = enumBuilder;
  if (indexedClass != null) {
    loader.buildersCreatedWithReferences[indexedClass.reference] = enumBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: enumBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createExtensionBuilder(
    ExtensionFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  DeclarationNameSpaceBuilder nameSpaceBuilder =
      fragment.toDeclarationNameSpaceBuilder();
  List<SourceNominalParameterBuilder>? nominalParameters =
      createNominalParameterBuilders(
          fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, nominalParameters,
      ownerName: fragment.name, allowNameConflict: false);

  List<ExtensionFragment> augmentationFragments = [];
  if (augmentations != null) {
    int introductoryTypeParameterCount = fragment.typeParameters?.length ?? 0;
    int nameLength = fragment.isUnnamed ? noLength : fragment.name.length;

    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ExtensionFragment].
      augmentation as ExtensionFragment;

      augmentationFragments.add(augmentation);
      nameSpaceBuilder
          .includeBuilders(augmentation.toDeclarationNameSpaceBuilder());

      int augmentationTypeParameterCount =
          augmentation.typeParameters?.length ?? 0;
      if (introductoryTypeParameterCount != augmentationTypeParameterCount) {
        problemReporting.addProblem(
            messagePatchExtensionTypeParametersMismatch,
            augmentation.nameOrExtensionOffset,
            nameLength,
            augmentation.fileUri,
            context: [
              messagePatchExtensionOrigin.withLocation(
                  fragment.fileUri, fragment.nameOrExtensionOffset, nameLength)
            ]);

        // Error recovery. Create fresh type parameters for the
        // augmentation.
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting,
            createNominalParameterBuilders(
                augmentation.typeParameters, unboundNominalParameters),
            ownerName: augmentation.name,
            allowNameConflict: false);
      } else if (augmentation.typeParameters != null) {
        for (int index = 0; index < introductoryTypeParameterCount; index++) {
          SourceNominalParameterBuilder nominalParameterBuilder =
              nominalParameters![index];
          TypeParameterFragment typeParameterFragment =
              augmentation.typeParameters![index];
          nominalParameterBuilder.addAugmentingDeclaration(
              new RegularNominalParameterDeclaration(typeParameterFragment));
          typeParameterFragment.builder = nominalParameterBuilder;
        }
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting, nominalParameters,
            ownerName: augmentation.name, allowNameConflict: false);
      }
    }
    augmentations.clear();
  }
  Reference? reference;
  if (!fragment.extensionName.isUnnamedExtension) {
    reference = indexedLibrary?.lookupExtension(fragment.name);
  }
  SourceExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      startOffset: fragment.startOffset,
      nameOffset: fragment.nameOrExtensionOffset,
      endOffset: fragment.endOffset,
      introductory: fragment,
      augmentations: augmentationFragments,
      nameSpaceBuilder: nameSpaceBuilder,
      reference: reference);
  if (reference != null) {
    loader.buildersCreatedWithReferences[reference] = extensionBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: extensionBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createExtensionTypeBuilder(ExtensionTypeFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  IndexedContainer? indexedContainer =
      indexedLibrary?.lookupIndexedExtensionTypeDeclaration(fragment.name);
  List<PrimaryConstructorFieldFragment> primaryConstructorFields =
      fragment.primaryConstructorFields;
  PrimaryConstructorFieldFragment? representationFieldFragment;
  if (primaryConstructorFields.isNotEmpty) {
    representationFieldFragment = primaryConstructorFields.first;
  }
  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, fragment.typeParameters?.builders,
      ownerName: fragment.name, allowNameConflict: false);
  SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
      new SourceExtensionTypeDeclarationBuilder(
          name: fragment.name,
          enclosingLibraryBuilder: enclosingLibraryBuilder,
          constructorReferences: fragment.constructorReferences,
          fileUri: fragment.fileUri,
          startOffset: fragment.startOffset,
          nameOffset: fragment.nameOffset,
          endOffset: fragment.endOffset,
          fragment: fragment,
          indexedContainer: indexedContainer,
          representationFieldFragment: representationFieldFragment);
  if (indexedContainer?.reference != null) {
    loader.buildersCreatedWithReferences[indexedContainer!.reference] =
        extensionTypeDeclarationBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: extensionTypeDeclarationBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

void _createPropertyBuilder({
  required ProblemReporting problemReporting,
  required SourceLoader loader,
  required _BuilderRegistry builderRegistry,
  required String name,
  required UriOffsetLength uriOffset,
  required SourceLibraryBuilder enclosingLibraryBuilder,
  required DeclarationBuilder? declarationBuilder,
  required List<NominalParameterBuilder> unboundNominalParameters,
  required FieldDeclaration? fieldDeclaration,
  required GetterDeclaration? getterDeclaration,
  required List<GetterDeclaration> getterAugmentations,
  required SetterDeclaration? setterDeclaration,
  required List<SetterDeclaration> setterAugmentations,
  required ContainerName? containerName,
  required ContainerType containerType,
  required IndexedLibrary? indexedLibrary,
  required IndexedContainer? indexedContainer,
  required bool isStatic,
  required bool inPatch,
}) {
  bool isInstanceMember = containerType != ContainerType.Library && !isStatic;

  bool fieldIsLateWithLowering = false;
  if (fieldDeclaration != null) {
    fieldIsLateWithLowering = fieldDeclaration.isLate &&
        (loader.target.backendTarget.isLateFieldLoweringEnabled(
                hasInitializer: fieldDeclaration.hasInitializer,
                isFinal: fieldDeclaration.isFinal,
                isStatic: !isInstanceMember) ||
            (loader.target.backendTarget.useStaticFieldLowering &&
                !isInstanceMember));
  }

  PropertyEncodingStrategy propertyEncodingStrategy =
      new PropertyEncodingStrategy(declarationBuilder,
          isInstanceMember: isInstanceMember);

  NameScheme nameScheme = new NameScheme(
      isInstanceMember: isInstanceMember,
      containerName: containerName,
      containerType: containerType,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.reference)
          : enclosingLibraryBuilder.libraryName);
  indexedContainer ??= indexedLibrary;

  PropertyReferences references = new PropertyReferences(
      name, nameScheme, indexedContainer,
      fieldIsLateWithLowering: fieldIsLateWithLowering);

  SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder(
      fileUri: uriOffset.fileUri,
      fileOffset: uriOffset.fileOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      fieldDeclaration: fieldDeclaration,
      getterDeclaration: getterDeclaration,
      getterAugmentations: getterAugmentations,
      setterDeclaration: setterDeclaration,
      setterAugmentations: setterAugmentations,
      isStatic: isStatic,
      nameScheme: nameScheme,
      references: references);

  fieldDeclaration?.createFieldEncoding(propertyBuilder);

  getterDeclaration?.createGetterEncoding(problemReporting, propertyBuilder,
      propertyEncodingStrategy, unboundNominalParameters);
  for (GetterDeclaration augmentation in getterAugmentations) {
    augmentation.createGetterEncoding(problemReporting, propertyBuilder,
        propertyEncodingStrategy, unboundNominalParameters);
  }

  setterDeclaration?.createSetterEncoding(problemReporting, propertyBuilder,
      propertyEncodingStrategy, unboundNominalParameters);
  for (SetterDeclaration augmentation in setterAugmentations) {
    augmentation.createSetterEncoding(problemReporting, propertyBuilder,
        propertyEncodingStrategy, unboundNominalParameters);
  }

  references.registerReference(loader, propertyBuilder);

  builderRegistry.registerBuilder(
      declaration: propertyBuilder, uriOffset: uriOffset, inPatch: inPatch);
}

void _createMethodBuilder(
    MethodFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  final bool isInstanceMember =
      containerType != ContainerType.Library && !fragment.modifiers.isStatic;

  createNominalParameterBuilders(
      fragment.declaredTypeParameters, unboundNominalParameters);

  MethodEncodingStrategy encodingStrategy = new MethodEncodingStrategy(
      declarationBuilder,
      isInstanceMember: isInstanceMember);

  ProcedureKind kind =
      fragment.isOperator ? ProcedureKind.Operator : ProcedureKind.Method;

  final bool isExtensionMember = containerType == ContainerType.Extension;
  final bool isExtensionTypeMember =
      containerType == ContainerType.ExtensionType;

  NameScheme nameScheme = new NameScheme(
      containerName: containerName,
      containerType: containerType,
      isInstanceMember: isInstanceMember,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);

  Reference? procedureReference;
  Reference? tearOffReference;
  indexedContainer ??= indexedLibrary;

  if (indexedContainer != null) {
    Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
    procedureReference = indexedContainer.lookupGetterReference(nameToLookup);
    if ((isExtensionMember || isExtensionTypeMember) &&
        kind == ProcedureKind.Method) {
      tearOffReference = indexedContainer.lookupGetterReference(
          nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name);
    }
  }

  Modifiers modifiers = fragment.modifiers;
  MethodDeclaration introductoryDeclaration =
      new MethodDeclarationImpl(fragment);

  List<MethodDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [MethodFragment].
      augmentation as MethodFragment;

      augmentationDeclarations.add(new MethodDeclarationImpl(augmentation));

      createNominalParameterBuilders(
          augmentation.declaredTypeParameters, unboundNominalParameters);

      if (!(augmentation.modifiers.isAbstract ||
          augmentation.modifiers.isExternal)) {
        modifiers -= Modifiers.Abstract;
        modifiers -= Modifiers.External;
      }
    }
  }

  SourceMethodBuilder methodBuilder = new SourceMethodBuilder(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      isStatic: modifiers.isStatic,
      modifiers: modifiers,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations,
      nameScheme: nameScheme,
      reference: procedureReference,
      tearOffReference: tearOffReference);
  fragment.builder = methodBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [MethodFragment].
      augmentation as MethodFragment;

      augmentation.builder = methodBuilder;
    }
    augmentations.clear();
  }
  introductoryDeclaration.createEncoding(problemReporting, methodBuilder,
      encodingStrategy, unboundNominalParameters);
  for (MethodDeclaration augmentation in augmentationDeclarations) {
    augmentation.createEncoding(problemReporting, methodBuilder,
        encodingStrategy, unboundNominalParameters);
  }

  if (procedureReference != null) {
    loader.buildersCreatedWithReferences[procedureReference] = methodBuilder;
  }
  builderRegistry.registerBuilder(
      declaration: methodBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingDeclaration?.isPatch ??
          fragment.enclosingCompilationUnit.isPatch);
}

void _createConstructorBuilder(
    ConstructorFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  bool isConst = fragment.modifiers.isConst;

  ConstructorDeclaration constructorDeclaration =
      new RegularConstructorDeclaration(fragment);

  List<ConstructorDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ConstructorFragment].
      augmentation as ConstructorFragment;

      augmentationDeclarations
          .add(new RegularConstructorDeclaration(augmentation));
    }
    augmentations.clear();
  }

  return _createConstructorBuilderFromDeclarations(
      constructorDeclaration, augmentationDeclarations,
      problemReporting: problemReporting,
      loader: loader,
      builderRegistry: builderRegistry,
      name: name,
      uriOffset: fragment.uriOffset,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      unboundNominalParameters: unboundNominalParameters,
      indexedLibrary: indexedLibrary,
      containerType: containerType,
      indexedContainer: indexedContainer,
      containerName: containerName,
      isConst: isConst,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

void _createConstructorBuilderFromDeclarations(
    ConstructorDeclaration constructorDeclaration,
    List<ConstructorDeclaration> augmentationDeclarations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required String name,
    required UriOffsetLength uriOffset,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName,
    required bool isConst,
    required bool inPatch}) {
  NameScheme nameScheme = new NameScheme(
      isInstanceMember: false,
      containerName: containerName,
      containerType: containerType,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);

  ConstructorEncodingStrategy encodingStrategy =
      new ConstructorEncodingStrategy(declarationBuilder!);

  ConstructorReferences constructorReferences = new ConstructorReferences(
      name: name,
      nameScheme: nameScheme,
      indexedContainer: indexedContainer,
      loader: loader,
      declarationBuilder: declarationBuilder);

  SourceConstructorBuilder constructorBuilder = new SourceConstructorBuilder(
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      fileUri: uriOffset.fileUri,
      fileOffset: uriOffset.fileOffset,
      constructorReferences: constructorReferences,
      nameScheme: nameScheme,
      introductory: constructorDeclaration,
      augmentations: augmentationDeclarations,
      isConst: isConst);
  constructorReferences.registerReference(loader, constructorBuilder);

  constructorDeclaration.createEncoding(
      problemReporting: problemReporting,
      loader: loader,
      declarationBuilder: declarationBuilder,
      constructorBuilder: constructorBuilder,
      unboundNominalParameters: unboundNominalParameters,
      encodingStrategy: encodingStrategy);
  for (ConstructorDeclaration augmentation in augmentationDeclarations) {
    augmentation.createEncoding(
        problemReporting: problemReporting,
        loader: loader,
        declarationBuilder: declarationBuilder,
        constructorBuilder: constructorBuilder,
        unboundNominalParameters: unboundNominalParameters,
        encodingStrategy: encodingStrategy);
  }
  builderRegistry.registerBuilder(
      declaration: constructorBuilder, uriOffset: uriOffset, inPatch: inPatch);
}

void _createPrimaryConstructorBuilder(PrimaryConstructorFragment fragment,
    {required ProblemReporting problemReporting,
    required _BuilderRegistry builderRegistry,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;

  ConstructorDeclaration constructorDeclaration =
      new PrimaryConstructorDeclaration(fragment);

  return _createConstructorBuilderFromDeclarations(
      constructorDeclaration, const [],
      problemReporting: problemReporting,
      loader: loader,
      builderRegistry: builderRegistry,
      name: name,
      uriOffset: fragment.uriOffset,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      unboundNominalParameters: unboundNominalParameters,
      indexedLibrary: indexedLibrary,
      containerType: containerType,
      indexedContainer: indexedContainer,
      containerName: containerName,
      isConst: fragment.modifiers.isConst,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

void _createFactoryBuilder(
    FactoryFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required _BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  bool isConst = fragment.modifiers.isConst;

  FactoryEncodingStrategy encodingStrategy =
      new FactoryEncodingStrategy(declarationBuilder!);

  NameScheme nameScheme = new NameScheme(
      containerName: containerName,
      containerType: containerType,
      isInstanceMember: false,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);

  FactoryReferences factoryReferences = new FactoryReferences(
      name: name,
      nameScheme: nameScheme,
      indexedContainer: indexedContainer,
      loader: loader,
      declarationBuilder: declarationBuilder);

  FactoryDeclaration introductoryDeclaration =
      new FactoryDeclarationImpl(fragment);

  bool isRedirectingFactory = fragment.redirectionTarget != null;
  List<FactoryDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [FactoryFragment].
      augmentation as FactoryFragment;

      augmentationDeclarations.add(new FactoryDeclarationImpl(augmentation));

      isRedirectingFactory |= augmentation.redirectionTarget != null;
    }
    augmentations.clear();
  }

  SourceFactoryBuilder factoryBuilder = new SourceFactoryBuilder(
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      fileUri: fragment.fileUri,
      fileOffset: fragment.fullNameOffset,
      factoryReferences: factoryReferences,
      nameScheme: nameScheme,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations,
      isConst: isConst);
  if (isRedirectingFactory) {
    (enclosingLibraryBuilder.redirectingFactoryBuilders ??= [])
        .add(factoryBuilder);
  }
  introductoryDeclaration.createEncoding(
      problemReporting: problemReporting,
      declarationBuilder: declarationBuilder,
      factoryBuilder: factoryBuilder,
      unboundNominalParameters: unboundNominalParameters,
      encodingStrategy: encodingStrategy);
  for (FactoryDeclaration augmentationDeclaration in augmentationDeclarations) {
    augmentationDeclaration.createEncoding(
        problemReporting: problemReporting,
        declarationBuilder: declarationBuilder,
        factoryBuilder: factoryBuilder,
        unboundNominalParameters: unboundNominalParameters,
        encodingStrategy: encodingStrategy);
  }

  factoryReferences.registerReference(loader, factoryBuilder);
  builderRegistry.registerBuilder(
      declaration: factoryBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

class _PropertyDeclarations {
  final FieldDeclaration? field;
  final GetterDeclaration? getter;
  final SetterDeclaration? setter;

  _PropertyDeclarations({this.field, this.getter, this.setter});
}
