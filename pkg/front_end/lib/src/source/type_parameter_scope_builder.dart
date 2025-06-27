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
  final String displayName;
  final bool isAugment;
  final bool inPatch;
  final bool inLibrary;
  final bool isStatic;

  _Declaration(this.kind,
      {required this.displayName,
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

  /// Reports that [declaration] conflicts with this declaration.
  void reportDuplicateDeclaration(
      ProblemReporting problemReporting, _Declaration declaration);

  void reportConstructorConflict(
      ProblemReporting problemReporting, _Declaration declaration);
}

mixin _DeclarationReportingMixin implements _Declaration {
  @override
  void reportDuplicateDeclaration(
      ProblemReporting problemReporting, _Declaration declaration) {
    // TODO(johnniwinther): Mark [declaration] as a duplicate so we don't
    //  report duplicates on duplicates.
    _reportDuplicateDeclaration(problemReporting,
        name: displayName,
        existingUriOffset: uriOffset,
        newUriOffset: declaration.uriOffset,
        existingKind: _getExistingKindForDuplicate(declaration),
        newIsSetter: declaration is _PropertyDeclaration &&
            declaration.propertyKind == _PropertyKind.Setter);
  }

  _ExistingKind _getExistingKindForDuplicate(_Declaration declaration) =>
      _ExistingKind.Getable;

  void _reportDuplicateDeclaration(
    ProblemReporting problemReporting, {
    required String name,
    required UriOffsetLength existingUriOffset,
    required UriOffsetLength newUriOffset,
    required _ExistingKind existingKind,
    required bool newIsSetter,
  }) {
    switch (existingKind) {
      case _ExistingKind.Getable:
        if (newIsSetter) {
          problemReporting.addProblem2(
              templateSetterConflictsWithDeclaration.withArguments(name),
              newUriOffset,
              context: [
                templateSetterConflictsWithDeclarationCause
                    .withArguments(name)
                    .withLocation2(existingUriOffset)
              ]);
          return;
        }
        break;
      case _ExistingKind.ExplicitSetter:
        if (!newIsSetter) {
          problemReporting.addProblem2(
              templateDeclarationConflictsWithSetter.withArguments(name),
              newUriOffset,
              context: <LocatedMessage>[
                templateDeclarationConflictsWithSetterCause
                    .withArguments(name)
                    .withLocation2(existingUriOffset)
              ]);
          return;
        }
        break;
      case _ExistingKind.ImplicitSetter:
        problemReporting.addProblem2(
            templateConflictsWithImplicitSetter.withArguments(name),
            newUriOffset,
            context: [
              templateConflictsWithImplicitSetterCause
                  .withArguments(name)
                  .withLocation2(existingUriOffset)
            ]);
        return;
    }

    problemReporting.addProblem2(
        templateDuplicatedDeclaration.withArguments(name), newUriOffset,
        context: <LocatedMessage>[
          templateDuplicatedDeclarationCause
              .withArguments(name)
              .withLocation2(existingUriOffset)
        ]);
  }
}

mixin _FragmentDeclarationMixin implements _Declaration {
  Fragment get _fragment;

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  String toString() => _fragment.toString();
}

abstract class _NonConstructorDeclaration extends _Declaration {
  _NonConstructorDeclaration(super.kind,
      {required super.displayName,
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

  @override
  void reportConstructorConflict(
      ProblemReporting problemReporting, _Declaration constructorDeclaration) {
    if (constructorDeclaration.kind == _DeclarationKind.Constructor) {
      // Example:
      //
      //    class A {
      //      static int get foo => 42;
      //      A.foo();
      //    }
      //
      problemReporting.addProblem2(
          templateConstructorConflictsWithMember.withArguments(displayName),
          constructorDeclaration.uriOffset,
          context: [
            templateConstructorConflictsWithMemberCause
                .withArguments(displayName)
                .withLocation2(uriOffset)
          ]);
    } else {
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
          templateFactoryConflictsWithMember.withArguments(displayName),
          constructorDeclaration.uriOffset,
          context: [
            templateFactoryConflictsWithMemberCause
                .withArguments(displayName)
                .withLocation2(uriOffset)
          ]);
    }
  }
}

abstract class _PropertyDeclaration extends _NonConstructorDeclaration {
  final _PropertyKind propertyKind;
  final _PropertyDeclarations declarations;

  @override
  final UriOffsetLength uriOffset;

  _PropertyDeclaration(
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required this.propertyKind,
      required this.declarations,
      required this.uriOffset,
      super.isStatic})
      : super(_DeclarationKind.Property);

  void reportStaticInstanceConflict(
      ProblemReporting problemReporting, _PropertyDeclaration declaration) {
    if (isStatic) {
      problemReporting.addProblem2(
          templateInstanceConflictsWithStatic.withArguments(displayName),
          declaration.uriOffset,
          context: [
            templateInstanceConflictsWithStaticCause
                .withArguments(displayName)
                .withLocation2(uriOffset)
          ]);
    } else {
      problemReporting.addProblem2(
          templateStaticConflictsWithInstance.withArguments(displayName),
          declaration.uriOffset,
          context: [
            templateStaticConflictsWithInstanceCause
                .withArguments(displayName)
                .withLocation2(uriOffset)
          ]);
    }
  }
}

class _FieldDeclaration extends _PropertyDeclaration
    with _DeclarationReportingMixin {
  _FieldDeclaration(
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.propertyKind,
      required super.declarations,
      required super.uriOffset,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forField(this);

  @override
  _ExistingKind _getExistingKindForDuplicate(_Declaration declaration) {
    bool newIsSetter = declaration is _PropertyDeclaration &&
        declaration.propertyKind == _PropertyKind.Setter;
    return newIsSetter ? _ExistingKind.ImplicitSetter : _ExistingKind.Getable;
  }
}

class _GetterDeclaration extends _PropertyDeclaration
    with _DeclarationReportingMixin {
  _GetterDeclaration(
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.propertyKind,
      required super.declarations,
      required super.uriOffset,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forGetter(this);
}

class _SetterDeclaration extends _PropertyDeclaration
    with _DeclarationReportingMixin {
  _SetterDeclaration(
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.propertyKind,
      required super.declarations,
      required super.uriOffset,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forSetter(this);

  @override
  _ExistingKind _getExistingKindForDuplicate(_Declaration declaration) {
    return _ExistingKind.ExplicitSetter;
  }
}

mixin _StandardFragmentDeclarationMixin implements _StandardDeclaration {
  @override
  Fragment get _fragment;
}

abstract class _StandardDeclaration extends _NonConstructorDeclaration {
  // TODO(johnniwinther): Remove this.
  Fragment get _fragment;

  _StandardDeclaration(super.kind,
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      super.isStatic});
}

class _StandardFragmentDeclaration extends _StandardDeclaration
    with
        _DeclarationReportingMixin,
        _FragmentDeclarationMixin,
        _StandardFragmentDeclarationMixin {
  @override
  final Fragment _fragment;

  _StandardFragmentDeclaration(super.kind, this._fragment,
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      super.isStatic});

  @override
  _PreBuilder _createPreBuilder() => new _DeclarationPreBuilder(this);
}

sealed class _ConstructorDeclaration extends _Declaration {
  final bool isConst;

  @override
  final UriOffsetLength uriOffset;

  _ConstructorDeclaration(super.kind,
      {required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required this.isConst,
      required this.uriOffset});

  @override
  void registerPreBuilder(
      ProblemReporting problemReporting,
      List<_PreBuilder> nonConstructorPreBuilders,
      List<_PreBuilder> constructorPreBuilders) {
    _addPreBuilder(
        problemReporting, constructorPreBuilders, nonConstructorPreBuilders);
  }
}

class _GenerativeConstructorDeclaration extends _ConstructorDeclaration
    with _DeclarationReportingMixin {
  final String _name;
  final ConstructorDeclaration _declaration;

  _GenerativeConstructorDeclaration(this._declaration,
      {required String name,
      required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.isConst,
      required super.uriOffset})
      : _name = name,
        super(_DeclarationKind.Constructor);

  @override
  _PreBuilder _createPreBuilder() =>
      new _GenerativeConstructorPreBuilder(_name, this);

  @override
  // Coverage-ignore(suite): Not run.
  void reportConstructorConflict(ProblemReporting problemReporting,
      _Declaration nonConstructorDeclaration) {
    // Example:
    //
    //    class A {
    //      A.foo();
    //      static void foo() {}
    //    }
    //
    problemReporting.addProblem2(
        templateMemberConflictsWithConstructor.withArguments(displayName),
        nonConstructorDeclaration.uriOffset,
        context: [
          templateMemberConflictsWithConstructorCause
              .withArguments(displayName)
              .withLocation2(uriOffset)
        ]);
  }
}

class _FactoryConstructorDeclaration extends _ConstructorDeclaration
    with _DeclarationReportingMixin {
  final String _name;
  final FactoryDeclaration _declaration;

  _FactoryConstructorDeclaration(this._declaration,
      {required String name,
      required super.displayName,
      required super.isAugment,
      required super.inPatch,
      required super.inLibrary,
      required super.isConst,
      required super.uriOffset})
      : _name = name,
        super(_DeclarationKind.Factory);

  @override
  _PreBuilder _createPreBuilder() =>
      new _FactoryConstructorPreBuilder(_name, this);

  @override
  // Coverage-ignore(suite): Not run.
  void reportConstructorConflict(ProblemReporting problemReporting,
      _Declaration nonConstructorDeclaration) {
    // Example:
    //
    //    class A {
    //      factory A.foo() => throw '';
    //      static void foo() {}
    //    }
    //
    problemReporting.addProblem2(
        templateMemberConflictsWithFactory.withArguments(displayName),
        nonConstructorDeclaration.uriOffset,
        context: [
          templateMemberConflictsWithFactoryCause
              .withArguments(displayName)
              .withLocation2(uriOffset)
        ]);
  }
}

class _BuilderFactory {
  final ProblemReporting _problemReporting;
  final SourceLoader _loader;
  final _BuilderRegistry _builderRegistry;
  final SourceLibraryBuilder _enclosingLibraryBuilder;
  final DeclarationBuilder? _declarationBuilder;
  final List<NominalParameterBuilder> _unboundNominalParameters;
  final Map<SourceClassBuilder, TypeBuilder> _mixinApplications;
  final IndexedLibrary? _indexedLibrary;
  final ContainerType _containerType;
  final IndexedContainer? _indexedContainer;
  final ContainerName? _containerName;
  final bool _inLibrary;

  _BuilderFactory(
      {required ProblemReporting problemReporting,
      required SourceLoader loader,
      required _BuilderRegistry builderRegistry,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      DeclarationBuilder? declarationBuilder,
      required List<NominalParameterBuilder> unboundNominalParameters,
      required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
      required IndexedLibrary? indexedLibrary,
      required ContainerType containerType,
      IndexedContainer? indexedContainer,
      ContainerName? containerName})
      : _containerName = containerName,
        _indexedContainer = indexedContainer,
        _containerType = containerType,
        _indexedLibrary = indexedLibrary,
        _mixinApplications = mixinApplications,
        _unboundNominalParameters = unboundNominalParameters,
        _declarationBuilder = declarationBuilder,
        _enclosingLibraryBuilder = enclosingLibraryBuilder,
        _builderRegistry = builderRegistry,
        _loader = loader,
        _problemReporting = problemReporting,
        _inLibrary = declarationBuilder == null;

  void computeBuildersFromFragments(String name, List<Fragment> fragments) {
    List<_PreBuilder> nonConstructorPreBuilders = [];
    List<_PreBuilder> constructorPreBuilders = [];
    List<Fragment> unnamedFragments = [];

    for (Fragment fragment in fragments) {
      _Declaration? declaration = _createDeclarationFromFragment(fragment,
          inLibrary: _inLibrary, unnamedFragments: unnamedFragments);

      declaration?.registerPreBuilder(
          _problemReporting, nonConstructorPreBuilders, constructorPreBuilders);
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
        _createTypedefBuilder(fragment);
      case ClassFragment():
        _createClassBuilder(fragment, augmentations);
      case MixinFragment():
        _createMixinBuilder(fragment);
      case NamedMixinApplicationFragment():
        _createNamedMixinApplicationBuilder(fragment);
      case EnumFragment():
        _createEnumBuilder(fragment);
      case ExtensionFragment():
        _createExtensionBuilder(fragment, augmentations);
      case ExtensionTypeFragment():
        _createExtensionTypeBuilder(fragment);
      case MethodFragment():
        _createMethodBuilder(fragment, augmentations);
      // Coverage-ignore(suite): Not run.
      case ConstructorFragment():
      case PrimaryConstructorFragment():
      case FactoryFragment():
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
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case EnumFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Enum, fragment,
          displayName: fragment.name,
          // TODO(johnniwinther): Support enum augmentations.
          isAugment: false,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case ExtensionTypeFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.ExtensionType,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case MethodFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Method,
          fragment,
          displayName: fragment.name,
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
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case NamedMixinApplicationFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.NamedMixinApplication,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case TypedefFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Typedef, fragment,
          displayName: fragment.name,
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
            displayName: fragment.name,
            isAugment: fragment.modifiers.isAugment,
            inPatch: fragment.enclosingCompilationUnit.isPatch,
            inLibrary: true,
          );
        } else {
          unnamedFragments.add(fragment);
          return null;
        }
      case FactoryFragment():
        return new _FactoryConstructorDeclaration(
          new FactoryDeclarationImpl(fragment),
          name: fragment.name,
          displayName: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          isConst: fragment.modifiers.isConst,
          uriOffset: fragment.uriOffset,
        );
      case ConstructorFragment():
        return new _GenerativeConstructorDeclaration(
          new RegularConstructorDeclaration(fragment),
          name: fragment.name,
          displayName: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          isConst: fragment.modifiers.isConst,
          uriOffset: fragment.uriOffset,
        );
      case PrimaryConstructorFragment():
        return new _GenerativeConstructorDeclaration(
          new PrimaryConstructorDeclaration(fragment),
          name: fragment.name,
          displayName: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          isConst: fragment.modifiers.isConst,
          uriOffset: fragment.uriOffset,
        );
      case FieldFragment():
        RegularFieldDeclaration declaration =
            new RegularFieldDeclaration(fragment);
        return new _FieldDeclaration(
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: fragment.hasSetter
              ? _PropertyKind.Field
              : _PropertyKind.FinalField,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
              field: declaration,
              getter: declaration,
              setter: fragment.hasSetter ? declaration : null),
        );
      case PrimaryConstructorFieldFragment():
        PrimaryConstructorFieldDeclaration declaration =
            new PrimaryConstructorFieldDeclaration(fragment);
        return new _FieldDeclaration(
          displayName: fragment.name,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: false,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: false,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
              field: declaration, getter: declaration),
        );
      case GetterFragment():
        return new _GetterDeclaration(
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Getter,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
              getter: new RegularGetterDeclaration(fragment)),
        );
      case SetterFragment():
        return new _SetterDeclaration(
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Setter,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
              setter: new RegularSetterDeclaration(fragment)),
        );
      case EnumElementFragment():
        EnumElementDeclaration declaration =
            new EnumElementDeclaration(fragment);
        return new _FieldDeclaration(
          displayName: fragment.name,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: true,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
              field: declaration, getter: declaration),
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
        name: name,
        uriOffset: uriOffset,
        fieldDeclaration: fieldDeclaration,
        getterDeclaration: getterDeclaration,
        getterAugmentations: getterAugmentationDeclarations ?? const [],
        setterDeclaration: setterDeclaration,
        setterAugmentations: setterAugmentationDeclarations ?? const [],
        isStatic: isStatic,
        inPatch: inPatch);
  }

  void _createTypedefBuilder(TypedefFragment fragment) {
    List<SourceNominalParameterBuilder>? nominalParameters =
        createNominalParameterBuilders(
            fragment.typeParameters, _unboundNominalParameters);
    if (nominalParameters != null) {
      for (SourceNominalParameterBuilder typeParameter in nominalParameters) {
        typeParameter.varianceCalculationValue =
            VarianceCalculationValue.pending;
      }
    }
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, nominalParameters,
        ownerName: fragment.name, allowNameConflict: true);

    Reference? reference = _indexedLibrary?.lookupTypedef(fragment.name);
    SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
        name: fragment.name,
        enclosingLibraryBuilder: _enclosingLibraryBuilder,
        fileUri: fragment.fileUri,
        fileOffset: fragment.nameOffset,
        fragment: fragment,
        reference: reference);
    if (reference != null) {
      _loader.buildersCreatedWithReferences[reference] = typedefBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: typedefBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createClassBuilder(
      ClassFragment fragment, List<Fragment>? augmentations) {
    String name = fragment.name;
    DeclarationNameSpaceBuilder nameSpaceBuilder =
        fragment.toDeclarationNameSpaceBuilder();
    ClassDeclaration introductoryDeclaration =
        new RegularClassDeclaration(fragment);
    List<SourceNominalParameterBuilder>? nominalParameters =
        createNominalParameterBuilders(
            fragment.typeParameters, _unboundNominalParameters);
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, nominalParameters,
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
          _problemReporting.addProblem(messagePatchClassTypeParametersMismatch,
              augmentation.nameOffset, name.length, augmentation.fileUri,
              context: [
                messagePatchClassOrigin.withLocation(
                    fragment.fileUri, fragment.nameOffset, name.length)
              ]);

          // Error recovery. Create fresh type parameters for the
          // augmentation.
          augmentation.nominalParameterNameSpace.addTypeParameters(
              _problemReporting,
              createNominalParameterBuilders(
                  augmentation.typeParameters, _unboundNominalParameters),
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
              _problemReporting, nominalParameters,
              ownerName: augmentation.name, allowNameConflict: false);
        }
      }
    }
    IndexedClass? indexedClass = _indexedLibrary?.lookupIndexedClass(name);
    SourceClassBuilder classBuilder = new SourceClassBuilder(
        modifiers: modifiers,
        name: name,
        typeParameters: fragment.typeParameters?.builders,
        typeParameterScope: fragment.typeParameterScope,
        nameSpaceBuilder: nameSpaceBuilder,
        libraryBuilder: _enclosingLibraryBuilder,
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
      _loader.buildersCreatedWithReferences[indexedClass.reference] =
          classBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: classBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createMixinBuilder(MixinFragment fragment) {
    IndexedClass? indexedClass =
        _indexedLibrary?.lookupIndexedClass(fragment.name);
    createNominalParameterBuilders(
        fragment.typeParameters, _unboundNominalParameters);
    List<SourceNominalParameterBuilder>? typeParameters =
        fragment.typeParameters?.builders;
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: fragment.name, allowNameConflict: false);
    SourceClassBuilder mixinBuilder = new SourceClassBuilder(
        modifiers: fragment.modifiers,
        name: fragment.name,
        typeParameters: typeParameters,
        typeParameterScope: fragment.typeParameterScope,
        nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
        libraryBuilder: _enclosingLibraryBuilder,
        fileUri: fragment.fileUri,
        nameOffset: fragment.nameOffset,
        indexedClass: indexedClass,
        introductory: new MixinDeclaration(fragment));
    fragment.builder = mixinBuilder;
    fragment.bodyScope.declarationBuilder = mixinBuilder;
    if (indexedClass != null) {
      _loader.buildersCreatedWithReferences[indexedClass.reference] =
          mixinBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: mixinBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createNamedMixinApplicationBuilder(
      NamedMixinApplicationFragment fragment) {
    List<TypeBuilder> mixins = fragment.mixins.toList();
    TypeBuilder mixin = mixins.removeLast();
    ClassDeclaration classDeclaration =
        new NamedMixinApplication(fragment, mixins);

    String name = fragment.name;

    IndexedClass? referencesFromIndexedClass =
        _indexedLibrary?.lookupIndexedClass(name);

    createNominalParameterBuilders(
        fragment.typeParameters, _unboundNominalParameters);
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, fragment.typeParameters?.builders,
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
        libraryBuilder: _enclosingLibraryBuilder,
        fileUri: fragment.fileUri,
        nameOffset: fragment.nameOffset,
        indexedClass: referencesFromIndexedClass,
        mixedInTypeBuilder: mixin,
        introductory: classDeclaration);
    _mixinApplications[classBuilder] = mixin;
    fragment.builder = classBuilder;
    if (referencesFromIndexedClass != null) {
      _loader.buildersCreatedWithReferences[
          referencesFromIndexedClass.reference] = classBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: classBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createEnumBuilder(EnumFragment fragment) {
    IndexedClass? indexedClass =
        _indexedLibrary?.lookupIndexedClass(fragment.name);
    createNominalParameterBuilders(
        fragment.typeParameters, _unboundNominalParameters);
    List<SourceNominalParameterBuilder>? typeParameters =
        fragment.typeParameters?.builders;
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: fragment.name, allowNameConflict: false);
    SourceEnumBuilder enumBuilder = new SourceEnumBuilder(
        name: fragment.name,
        typeParameters: typeParameters,
        underscoreEnumTypeBuilder: _loader.target.underscoreEnumType,
        interfaceBuilders: fragment.interfaces,
        enumElements: fragment.enumElements,
        libraryBuilder: _enclosingLibraryBuilder,
        fileUri: fragment.fileUri,
        startOffset: fragment.startOffset,
        nameOffset: fragment.nameOffset,
        endOffset: fragment.endOffset,
        indexedClass: indexedClass,
        typeParameterScope: fragment.typeParameterScope,
        nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
        classDeclaration:
            new EnumDeclaration(fragment, _loader.target.underscoreEnumType));
    fragment.builder = enumBuilder;
    fragment.bodyScope.declarationBuilder = enumBuilder;
    if (indexedClass != null) {
      _loader.buildersCreatedWithReferences[indexedClass.reference] =
          enumBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: enumBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createExtensionBuilder(
      ExtensionFragment fragment, List<Fragment>? augmentations) {
    DeclarationNameSpaceBuilder nameSpaceBuilder =
        fragment.toDeclarationNameSpaceBuilder();
    List<SourceNominalParameterBuilder>? nominalParameters =
        createNominalParameterBuilders(
            fragment.typeParameters, _unboundNominalParameters);
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, nominalParameters,
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
          _problemReporting.addProblem(
              messagePatchExtensionTypeParametersMismatch,
              augmentation.nameOrExtensionOffset,
              nameLength,
              augmentation.fileUri,
              context: [
                messagePatchExtensionOrigin.withLocation(fragment.fileUri,
                    fragment.nameOrExtensionOffset, nameLength)
              ]);

          // Error recovery. Create fresh type parameters for the
          // augmentation.
          augmentation.nominalParameterNameSpace.addTypeParameters(
              _problemReporting,
              createNominalParameterBuilders(
                  augmentation.typeParameters, _unboundNominalParameters),
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
              _problemReporting, nominalParameters,
              ownerName: augmentation.name, allowNameConflict: false);
        }
      }
      augmentations.clear();
    }
    Reference? reference;
    if (!fragment.extensionName.isUnnamedExtension) {
      reference = _indexedLibrary?.lookupExtension(fragment.name);
    }
    SourceExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
        enclosingLibraryBuilder: _enclosingLibraryBuilder,
        fileUri: fragment.fileUri,
        startOffset: fragment.startOffset,
        nameOffset: fragment.nameOrExtensionOffset,
        endOffset: fragment.endOffset,
        introductory: fragment,
        augmentations: augmentationFragments,
        nameSpaceBuilder: nameSpaceBuilder,
        reference: reference);
    if (reference != null) {
      _loader.buildersCreatedWithReferences[reference] = extensionBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: extensionBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createExtensionTypeBuilder(ExtensionTypeFragment fragment) {
    IndexedContainer? indexedContainer =
        _indexedLibrary?.lookupIndexedExtensionTypeDeclaration(fragment.name);
    List<PrimaryConstructorFieldFragment> primaryConstructorFields =
        fragment.primaryConstructorFields;
    PrimaryConstructorFieldFragment? representationFieldFragment;
    if (primaryConstructorFields.isNotEmpty) {
      representationFieldFragment = primaryConstructorFields.first;
    }
    createNominalParameterBuilders(
        fragment.typeParameters, _unboundNominalParameters);
    fragment.nominalParameterNameSpace.addTypeParameters(
        _problemReporting, fragment.typeParameters?.builders,
        ownerName: fragment.name, allowNameConflict: false);
    SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
        new SourceExtensionTypeDeclarationBuilder(
            name: fragment.name,
            enclosingLibraryBuilder: _enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            fragment: fragment,
            indexedContainer: indexedContainer,
            representationFieldFragment: representationFieldFragment);
    if (indexedContainer?.reference != null) {
      _loader.buildersCreatedWithReferences[indexedContainer!.reference] =
          extensionTypeDeclarationBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: extensionTypeDeclarationBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingCompilationUnit.isPatch);
  }

  void _createPropertyBuilder({
    required String name,
    required UriOffsetLength uriOffset,
    required FieldDeclaration? fieldDeclaration,
    required GetterDeclaration? getterDeclaration,
    required List<GetterDeclaration> getterAugmentations,
    required SetterDeclaration? setterDeclaration,
    required List<SetterDeclaration> setterAugmentations,
    required bool isStatic,
    required bool inPatch,
  }) {
    bool isInstanceMember =
        _containerType != ContainerType.Library && !isStatic;

    bool fieldIsLateWithLowering = false;
    if (fieldDeclaration != null) {
      fieldIsLateWithLowering = fieldDeclaration.isLate &&
          (_loader.target.backendTarget.isLateFieldLoweringEnabled(
                  hasInitializer: fieldDeclaration.hasInitializer,
                  isFinal: fieldDeclaration.isFinal,
                  isStatic: !isInstanceMember) ||
              (_loader.target.backendTarget.useStaticFieldLowering &&
                  !isInstanceMember));
    }

    PropertyEncodingStrategy propertyEncodingStrategy =
        new PropertyEncodingStrategy(_declarationBuilder,
            isInstanceMember: isInstanceMember);

    NameScheme nameScheme = new NameScheme(
        isInstanceMember: isInstanceMember,
        containerName: _containerName,
        containerType: _containerType,
        libraryName: _indexedLibrary != null
            ? new LibraryName(_indexedLibrary.reference)
            : _enclosingLibraryBuilder.libraryName);
    IndexedContainer? indexedContainer = _indexedContainer ?? _indexedLibrary;

    PropertyReferences references = new PropertyReferences(
        name, nameScheme, indexedContainer,
        fieldIsLateWithLowering: fieldIsLateWithLowering);

    SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder(
        fileUri: uriOffset.fileUri,
        fileOffset: uriOffset.fileOffset,
        name: name,
        libraryBuilder: _enclosingLibraryBuilder,
        declarationBuilder: _declarationBuilder,
        fieldDeclaration: fieldDeclaration,
        getterDeclaration: getterDeclaration,
        getterAugmentations: getterAugmentations,
        setterDeclaration: setterDeclaration,
        setterAugmentations: setterAugmentations,
        isStatic: isStatic,
        nameScheme: nameScheme,
        references: references);

    fieldDeclaration?.createFieldEncoding(propertyBuilder);

    getterDeclaration?.createGetterEncoding(_problemReporting, propertyBuilder,
        propertyEncodingStrategy, _unboundNominalParameters);
    for (GetterDeclaration augmentation in getterAugmentations) {
      augmentation.createGetterEncoding(_problemReporting, propertyBuilder,
          propertyEncodingStrategy, _unboundNominalParameters);
    }

    setterDeclaration?.createSetterEncoding(_problemReporting, propertyBuilder,
        propertyEncodingStrategy, _unboundNominalParameters);
    for (SetterDeclaration augmentation in setterAugmentations) {
      augmentation.createSetterEncoding(_problemReporting, propertyBuilder,
          propertyEncodingStrategy, _unboundNominalParameters);
    }

    references.registerReference(_loader, propertyBuilder);

    _builderRegistry.registerBuilder(
        declaration: propertyBuilder, uriOffset: uriOffset, inPatch: inPatch);
  }

  void _createMethodBuilder(
      MethodFragment fragment, List<Fragment>? augmentations) {
    String name = fragment.name;
    final bool isInstanceMember =
        _containerType != ContainerType.Library && !fragment.modifiers.isStatic;

    createNominalParameterBuilders(
        fragment.declaredTypeParameters, _unboundNominalParameters);

    MethodEncodingStrategy encodingStrategy = new MethodEncodingStrategy(
        _declarationBuilder,
        isInstanceMember: isInstanceMember);

    ProcedureKind kind =
        fragment.isOperator ? ProcedureKind.Operator : ProcedureKind.Method;

    final bool isExtensionMember = _containerType == ContainerType.Extension;
    final bool isExtensionTypeMember =
        _containerType == ContainerType.ExtensionType;

    NameScheme nameScheme = new NameScheme(
        containerName: _containerName,
        containerType: _containerType,
        isInstanceMember: isInstanceMember,
        libraryName: _indexedLibrary != null
            ? new LibraryName(_indexedLibrary.library.reference)
            : _enclosingLibraryBuilder.libraryName);

    Reference? procedureReference;
    Reference? tearOffReference;
    IndexedContainer? indexedContainer = _indexedContainer ?? _indexedLibrary;

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
            augmentation.declaredTypeParameters, _unboundNominalParameters);

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
        libraryBuilder: _enclosingLibraryBuilder,
        declarationBuilder: _declarationBuilder,
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
    introductoryDeclaration.createEncoding(_problemReporting, methodBuilder,
        encodingStrategy, _unboundNominalParameters);
    for (MethodDeclaration augmentation in augmentationDeclarations) {
      augmentation.createEncoding(_problemReporting, methodBuilder,
          encodingStrategy, _unboundNominalParameters);
    }

    if (procedureReference != null) {
      _loader.buildersCreatedWithReferences[procedureReference] = methodBuilder;
    }
    _builderRegistry.registerBuilder(
        declaration: methodBuilder,
        uriOffset: fragment.uriOffset,
        inPatch: fragment.enclosingDeclaration?.isPatch ??
            fragment.enclosingCompilationUnit.isPatch);
  }

  void _createConstructorBuilderFromDeclarations(
      ConstructorDeclaration constructorDeclaration,
      List<ConstructorDeclaration> augmentationDeclarations,
      {required String name,
      required UriOffsetLength uriOffset,
      required bool isConst,
      required bool inPatch}) {
    NameScheme nameScheme = new NameScheme(
        isInstanceMember: false,
        containerName: _containerName,
        containerType: _containerType,
        libraryName: _indexedLibrary != null
            ? new LibraryName(_indexedLibrary.library.reference)
            : _enclosingLibraryBuilder.libraryName);

    ConstructorEncodingStrategy encodingStrategy =
        new ConstructorEncodingStrategy(_declarationBuilder!);

    ConstructorReferences constructorReferences = new ConstructorReferences(
        name: name,
        nameScheme: nameScheme,
        indexedContainer: _indexedContainer,
        loader: _loader,
        declarationBuilder: _declarationBuilder);

    SourceConstructorBuilder constructorBuilder = new SourceConstructorBuilder(
        name: name,
        libraryBuilder: _enclosingLibraryBuilder,
        declarationBuilder: _declarationBuilder,
        fileUri: uriOffset.fileUri,
        fileOffset: uriOffset.fileOffset,
        constructorReferences: constructorReferences,
        nameScheme: nameScheme,
        introductory: constructorDeclaration,
        augmentations: augmentationDeclarations,
        isConst: isConst);
    constructorReferences.registerReference(_loader, constructorBuilder);

    constructorDeclaration.createEncoding(
        problemReporting: _problemReporting,
        loader: _loader,
        declarationBuilder: _declarationBuilder,
        constructorBuilder: constructorBuilder,
        unboundNominalParameters: _unboundNominalParameters,
        encodingStrategy: encodingStrategy);
    for (ConstructorDeclaration augmentation in augmentationDeclarations) {
      augmentation.createEncoding(
          problemReporting: _problemReporting,
          loader: _loader,
          declarationBuilder: _declarationBuilder,
          constructorBuilder: constructorBuilder,
          unboundNominalParameters: _unboundNominalParameters,
          encodingStrategy: encodingStrategy);
    }
    _builderRegistry.registerBuilder(
        declaration: constructorBuilder,
        uriOffset: uriOffset,
        inPatch: inPatch);
  }

  void _createFactoryBuilderFromDeclarations(
      FactoryDeclaration introductory, List<FactoryDeclaration> augmentations,
      {required String name,
      required bool isConst,
      required UriOffsetLength uriOffset,
      required bool inPatch}) {
    FactoryEncodingStrategy encodingStrategy =
        new FactoryEncodingStrategy(_declarationBuilder!);

    NameScheme nameScheme = new NameScheme(
        containerName: _containerName,
        containerType: _containerType,
        isInstanceMember: false,
        libraryName: _indexedLibrary != null
            ? new LibraryName(_indexedLibrary.library.reference)
            : _enclosingLibraryBuilder.libraryName);

    FactoryReferences factoryReferences = new FactoryReferences(
        name: name,
        nameScheme: nameScheme,
        indexedContainer: _indexedContainer,
        loader: _loader,
        declarationBuilder: _declarationBuilder);

    bool isRedirectingFactory = introductory.isRedirectingFactory;
    for (FactoryDeclaration augmentation in augmentations) {
      if (augmentation.isRedirectingFactory) {
        isRedirectingFactory = true;
      }
    }

    SourceFactoryBuilder factoryBuilder = new SourceFactoryBuilder(
        name: name,
        libraryBuilder: _enclosingLibraryBuilder,
        declarationBuilder: _declarationBuilder,
        fileUri: uriOffset.fileUri,
        fileOffset: uriOffset.fileOffset,
        factoryReferences: factoryReferences,
        nameScheme: nameScheme,
        introductory: introductory,
        augmentations: augmentations,
        isConst: isConst);
    if (isRedirectingFactory) {
      (_enclosingLibraryBuilder.redirectingFactoryBuilders ??= [])
          .add(factoryBuilder);
    }
    introductory.createEncoding(
        problemReporting: _problemReporting,
        declarationBuilder: _declarationBuilder,
        factoryBuilder: factoryBuilder,
        unboundNominalParameters: _unboundNominalParameters,
        encodingStrategy: encodingStrategy);
    for (FactoryDeclaration augmentation in augmentations) {
      augmentation.createEncoding(
          problemReporting: _problemReporting,
          declarationBuilder: _declarationBuilder,
          factoryBuilder: factoryBuilder,
          unboundNominalParameters: _unboundNominalParameters,
          encodingStrategy: encodingStrategy);
    }

    factoryReferences.registerReference(_loader, factoryBuilder);
    _builderRegistry.registerBuilder(
        declaration: factoryBuilder, uriOffset: uriOffset, inPatch: inPatch);
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
  _PropertyDeclaration? _getterDeclaration;
  _PropertyDeclaration? _setterDeclaration;
  List<GetterDeclaration> _getterAugmentations = [];
  List<SetterDeclaration> _setterAugmentations = [];

  // TODO(johnniwinther): Report error if [getter] is augmenting.
  _PropertyPreBuilder.forGetter(_PropertyDeclaration getter)
      : isStatic = getter.isStatic,
        inPatch = getter.inPatch,
        name = getter.displayName,
        uriOffset = getter.uriOffset,
        _getterDeclaration = getter {
    _PropertyDeclarations declarations = getter.declarations;
    assert(declarations.field == null,
        "Unexpected field declaration from getter ${getter}.");
    assert(declarations.getter != null,
        "Unexpected getter declaration from getter ${getter}.");
    assert(declarations.setter == null,
        "Unexpected setter declaration from getter ${getter}.");
  }

  // TODO(johnniwinther): Report error if [setter] is augmenting.
  _PropertyPreBuilder.forSetter(_PropertyDeclaration setter)
      : isStatic = setter.isStatic,
        inPatch = setter.inPatch,
        name = setter.displayName,
        uriOffset = setter.uriOffset,
        _setterDeclaration = setter {
    _PropertyDeclarations declarations = setter.declarations;
    assert(declarations.field == null,
        "Unexpected field declaration from setter ${setter}.");
    assert(declarations.getter == null,
        "Unexpected getter declaration from setter ${setter}.");
    assert(declarations.setter != null,
        "Unexpected setter declaration from setter ${setter}.");
  }

  // TODO(johnniwinther): Report error if [field] is augmenting.
  _PropertyPreBuilder.forField(_PropertyDeclaration field)
      : isStatic = field.isStatic,
        inPatch = field.inPatch,
        name = field.displayName,
        uriOffset = field.uriOffset,
        _getterDeclaration = field,
        _setterDeclaration =
            field.propertyKind == _PropertyKind.Field ? field : null {
    _PropertyDeclarations declarations = field.declarations;
    assert(declarations.field != null,
        "Unexpected field declaration from field ${field}.");
    assert(declarations.getter != null,
        "Unexpected getter declaration from field ${field}.");
    assert(
        (declarations.setter != null) ==
            (_getterDeclaration!.propertyKind == _PropertyKind.Field),
        "Unexpected setter declaration from field ${field}.");
  }

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _Declaration declaration) {
    if (declaration is! _PropertyDeclaration) {
      if (_getterDeclaration != null) {
        // Example:
        //
        //    int get foo => 42;
        //    void foo() {}
        //
        _getterDeclaration!
            .reportDuplicateDeclaration(problemReporting, declaration);
      } else {
        assert(_setterDeclaration != null);
        // Example:
        //
        //    void set foo(_) {}
        //    void foo() {}
        //
        _setterDeclaration!
            .reportDuplicateDeclaration(problemReporting, declaration);
      }
      return false;
    }

    _PropertyKind? propertyKind = declaration.propertyKind;
    switch (propertyKind) {
      case _PropertyKind.Getter:
        if (_getterDeclaration == null) {
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
            // Examples:
            //
            //    class A {
            //      void set foo(_) {}
            //      static int get foo => 42;
            //    }
            //
            // and
            //
            //    class A {
            //      static void set foo(_) {}
            //      int get foo => 42;
            //    }
            //
            _setterDeclaration!
                .reportStaticInstanceConflict(problemReporting, declaration);
            return false;
          } else {
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
                declarations.field == null,
                "Unexpected field declaration from getter "
                "${declaration}.");
            assert(
                declarations.setter == null,
                "Unexpected setter declaration from getter "
                "${declaration}.");
            _getterDeclaration = declaration;
            return true;
          }
        } else {
          if (declaration.isAugment) {
            // Example:
            //
            //    int get foo => 42;
            //    augment int get foo => 87;
            //
            _PropertyDeclarations declarations = declaration.declarations;
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
            _getterDeclaration!
                .reportDuplicateDeclaration(problemReporting, declaration);
            return false;
          }
        }
      case _PropertyKind.Setter:
        if (_setterDeclaration == null) {
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
            // Examples:
            //
            //    class A {
            //      int get foo => 42;
            //      static void set foo(_) {}
            //    }
            //
            // and
            //
            //    class A {
            //      static int get foo => 42;
            //      void set foo(_) {}
            //    }
            //
            _getterDeclaration!
                .reportStaticInstanceConflict(problemReporting, declaration);
            return false;
          } else {
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
                declarations.field == null,
                "Unexpected field declaration from setter "
                "${declaration}.");
            assert(
                declarations.getter == null,
                "Unexpected getter declaration from setter "
                "${declaration}.");
            _setterDeclaration = declaration;
            return true;
          }
        } else {
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment void set foo(_) {}
            //
            _PropertyDeclarations declarations = declaration.declarations;
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
            // Examples:
            //
            //    int? foo;
            //    void set foo(_) {}
            //
            // and
            //
            //    void set foo(_) {}
            //    void set foo(_) {}
            //
            _setterDeclaration!
                .reportDuplicateDeclaration(problemReporting, declaration);
            return false;
          }
        }
      case _PropertyKind.Field:
        if (_getterDeclaration == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    int? foo;
          //
          assert(_getterDeclaration == null && _setterDeclaration != null);
          // We have an explicit setter.
          _setterDeclaration!
              .reportDuplicateDeclaration(problemReporting, declaration);
          return false;
        } else if (_setterDeclaration != null) {
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
          assert(_getterDeclaration != null && _setterDeclaration != null);
          // We have both getter and setter
          if (declaration.isAugment) {
            // Coverage-ignore-block(suite): Not run.
            if (_getterDeclaration!.propertyKind == declaration.propertyKind) {
              // Example:
              //
              //    int foo = 42;
              //    augment int foo = 87;
              //
              _PropertyDeclarations declarations = declaration.declarations;
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
            _getterDeclaration!
                .reportDuplicateDeclaration(problemReporting, declaration);
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
          assert(_getterDeclaration != null && _setterDeclaration == null);
          _getterDeclaration!
              .reportDuplicateDeclaration(problemReporting, declaration);
          return false;
        }
      case _PropertyKind.FinalField:
        if (_getterDeclaration == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    final int foo = 42;
          //
          assert(_getterDeclaration == null && _setterDeclaration != null);
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
            // Examples:
            //
            //    class A {
            //      void set foo(_) {}
            //      static final int foo = 42;
            //    }
            //
            // and
            //
            //    class A {
            //      static void set foo(_) {}
            //      final int foo = 42;
            //    }
            //
            _setterDeclaration!
                .reportStaticInstanceConflict(problemReporting, declaration);
            return false;
          } else {
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
                declarations.setter == null,
                "Unexpected setter declaration from field "
                "${declaration}.");
            _getterDeclaration = declaration;
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
            if (_getterDeclaration!.propertyKind == declaration.propertyKind) {
              // Example:
              //
              //    final int foo = 42;
              //    augment final int foo = 87;
              //
              _PropertyDeclarations declarations = declaration.declarations;
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
            _getterDeclaration!
                .reportDuplicateDeclaration(problemReporting, declaration);
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
      if (_getterDeclaration != null) {
        // Examples:
        //
        //    class A {
        //      static int get foo => 42;
        //      A.foo();
        //    }
        //
        // and
        //
        //    class A {
        //      static int get foo => 42;
        //      factory A.foo() => throw '';
        //    }
        //
        _getterDeclaration!.reportConstructorConflict(
            problemReporting, constructorDeclaration);
      } else {
        // Coverage-ignore-block(suite): Not run.
        // Examples:
        //
        //    class A {
        //      static void set foo(_) {}
        //      A.foo();
        //    }
        //
        // and
        //
        //    class A {
        //      static void set foo(_) {}
        //      factory A.foo() => throw '';
        //    }
        //
        _setterDeclaration!.reportConstructorConflict(
            problemReporting, constructorDeclaration);
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
        fieldDeclaration: _getterDeclaration?.declarations.field,
        getterDeclaration: _getterDeclaration?.declarations.getter,
        getterAugmentationDeclarations: _getterAugmentations,
        setterDeclaration: _setterDeclaration?.declarations.setter,
        setterAugmentationDeclarations: _setterAugmentations);
  }
}

/// [_PreBuilder] for generative and factory constructors.
sealed class _ConstructorPreBuilder<T extends _ConstructorDeclaration>
    extends _PreBuilder {
  final T _declaration;
  final List<T> _augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  _ConstructorPreBuilder(this._declaration);

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _Declaration declaration) {
    if (declaration.isAugment) {
      if (declaration is T && declaration.kind == _declaration.kind) {
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
      _declaration.reportDuplicateDeclaration(problemReporting, declaration);
      return false;
    }
  }

  @override
  void checkFragment(ProblemReporting problemReporting,
      _Declaration nonConstructorDeclaration) {
    // Check conflict with non-constructor.
    if (nonConstructorDeclaration.isStatic) {
      // Coverage-ignore-block(suite): Not run.
      // Examples:
      //
      //    class A {
      //      A.foo();
      //      static void foo() {}
      //    }
      //
      // and
      //
      //    class A {
      //      factory A.foo() => throw '';
      //      static void foo() {}
      //    }
      //
      _declaration.reportConstructorConflict(
          problemReporting, nonConstructorDeclaration);
    }
  }
}

class _GenerativeConstructorPreBuilder
    extends _ConstructorPreBuilder<_GenerativeConstructorDeclaration> {
  final String _name;

  _GenerativeConstructorPreBuilder(this._name, super._declaration);

  @override
  void createBuilders(_BuilderFactory builderFactory) {
    builderFactory._createConstructorBuilderFromDeclarations(
        _declaration._declaration,
        _augmentations.map((a) => a._declaration).toList(),
        name: _name,
        uriOffset: _declaration.uriOffset,
        isConst: _declaration.isConst,
        inPatch: _declaration.inPatch);
  }
}

class _FactoryConstructorPreBuilder
    extends _ConstructorPreBuilder<_FactoryConstructorDeclaration> {
  final String _name;

  _FactoryConstructorPreBuilder(this._name, super._declaration);

  @override
  void createBuilders(_BuilderFactory builderFactory) {
    builderFactory._createFactoryBuilderFromDeclarations(
        _declaration._declaration,
        _augmentations.map((a) => a._declaration).toList(),
        name: _name,
        uriOffset: _declaration.uriOffset,
        isConst: _declaration.isConst,
        inPatch: _declaration.inPatch);
  }
}

/// [_PreBuilder] for non-constructor, non-property declarations.
class _DeclarationPreBuilder extends _PreBuilder {
  final _StandardDeclaration _declaration;
  final List<_StandardDeclaration> _augmentations = [];

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
        _augmentations.add(declaration as _StandardDeclaration);
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
      // Examples:
      //
      //    class Foo {}
      //    set Foo(_) {}
      //
      // and
      //
      //    class Foo {}
      //    class Foo {}
      //
      _declaration.reportDuplicateDeclaration(problemReporting, declaration);
      return false;
    }
  }

  @override
  void checkFragment(
      ProblemReporting problemReporting, _Declaration constructorDeclaration) {
    // Check conflict with constructor.
    if (_declaration.isStatic) {
      // Examples:
      //
      //    class A {
      //      static void foo() {}
      //      A.foo();
      //    }
      //
      // and
      //
      //    class A {
      //      static void foo() {}
      //      factory A.foo() => throw '';
      //    }
      //
      _declaration.reportConstructorConflict(
          problemReporting, constructorDeclaration);
    }
  }

  @override
  void createBuilders(_BuilderFactory builderFactory) {
    builderFactory.createBuilder(_declaration._fragment,
        augmentations: _augmentations.map((f) => f._fragment).toList());
  }
}

/// Reports an error if [declaration] is augmenting.
///
/// This is called when the first [_PreBuilder] is created, meaning that the
/// augmentation didn't correspond to an introductory declaration.
void _checkAugmentation(
    ProblemReporting problemReporting, _Declaration declaration) {
  if (declaration.isAugment) {
    Message message;
    switch (declaration.kind) {
      case _DeclarationKind.Class:
        message = declaration.inPatch
            ? templateUnmatchedPatchClass.withArguments(declaration.displayName)
            :
            // Coverage-ignore(suite): Not run.
            templateUnmatchedAugmentationClass
                .withArguments(declaration.displayName);
      case _DeclarationKind.Constructor:
      case _DeclarationKind.Factory:
      case _DeclarationKind.Method:
      case _DeclarationKind.Property:
        if (declaration.inLibrary) {
          message = declaration.inPatch
              ? templateUnmatchedPatchLibraryMember
                  .withArguments(declaration.displayName)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationLibraryMember
                  .withArguments(declaration.displayName);
        } else {
          message = declaration.inPatch
              ? templateUnmatchedPatchClassMember
                  .withArguments(declaration.displayName)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationClassMember
                  .withArguments(declaration.displayName);
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
        message = declaration.inPatch
            ? templateUnmatchedPatchDeclaration
                .withArguments(declaration.displayName)
            :
            // Coverage-ignore(suite): Not run.
            templateUnmatchedAugmentationDeclaration
                .withArguments(declaration.displayName);
    }
    problemReporting.addProblem2(message, declaration.uriOffset);
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

class _PropertyDeclarations {
  final FieldDeclaration? field;
  final GetterDeclaration? getter;
  final SetterDeclaration? setter;

  _PropertyDeclarations({this.field, this.getter, this.setter});
}

enum _ExistingKind {
  Getable,
  ExplicitSetter,
  ImplicitSetter,
}
