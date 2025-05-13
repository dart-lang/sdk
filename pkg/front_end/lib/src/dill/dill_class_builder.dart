// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/loader.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import 'dill_library_builder.dart' show DillLibraryBuilder;
import 'dill_member_builder.dart';
import 'dill_type_parameter_builder.dart';

mixin DillClassMemberAccessMixin implements ClassMemberAccess {
  DeclarationNameSpace get nameSpace;

  @override
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>() =>
      nameSpace.filteredConstructorIterator<T>(includeDuplicates: false);

  @override
  Iterator<T> fullMemberIterator<T extends NamedBuilder>() =>
      nameSpace.filteredIterator<T>(includeDuplicates: false);
}

class DillClassBuilder extends ClassBuilderImpl
    with DillClassMemberAccessMixin {
  @override
  final DillLibraryBuilder parent;

  @override
  final Class cls;

  final MutableDeclarationNameSpace _nameSpace;

  List<NominalParameterBuilder>? _typeParameters;

  TypeBuilder? _supertypeBuilder;

  List<TypeBuilder>? _interfaceBuilders;

  DillClassBuilder(this.cls, this.parent)
      : _nameSpace = new DillDeclarationNameSpace();

  @override
  int get fileOffset => cls.fileOffset;

  @override
  String get name => cls.name;

  @override
  Uri get fileUri => cls.fileUri;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  bool get isEnum => cls.isEnum;

  @override
  DillLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as DillLibraryBuilder;

  @override
  bool get isMixinClass => cls.isMixinClass;

  @override
  bool get isMixinDeclaration => cls.isMixinDeclaration;

  @override
  bool get isSealed => cls.isSealed;

  @override
  bool get isBase => cls.isBase;

  @override
  bool get isInterface => cls.isInterface;

  @override
  bool get isFinal => cls.isFinal;

  @override
  bool get isAbstract => cls.isAbstract;

  @override
  bool get isNamedMixinApplication => cls.isMixinApplication;

  @override
  List<NominalParameterBuilder>? get typeParameters {
    List<NominalParameterBuilder>? typeParameters = _typeParameters;
    if (typeParameters == null && cls.typeParameters.isNotEmpty) {
      typeParameters = _typeParameters = computeTypeParameterBuilders(
          cls.typeParameters, libraryBuilder.loader);
    }
    return typeParameters;
  }

  @override
  TypeBuilder? get supertypeBuilder {
    TypeBuilder? supertype = _supertypeBuilder;
    if (supertype == null) {
      Supertype? targetSupertype = cls.supertype;
      if (targetSupertype == null) return null;
      _supertypeBuilder =
          supertype = computeTypeBuilder(libraryBuilder, targetSupertype);
    }
    return supertype;
  }

  void addField(Field field) {
    DillFieldBuilder builder =
        new DillFieldBuilder(field, libraryBuilder, this);
    String name = field.name.text;
    _nameSpace.addLocalMember(name, builder, setter: false);
  }

  void addConstructor(Constructor constructor, Procedure? constructorTearOff) {
    DillConstructorBuilder builder = new DillConstructorBuilder(
        constructor, constructorTearOff, libraryBuilder, this);
    String name = constructor.name.text;
    _nameSpace.addConstructor(name, builder);
  }

  void addFactory(Procedure factory, Procedure? factoryTearOff) {
    String name = factory.name.text;
    _nameSpace.addConstructor(name,
        new DillFactoryBuilder(factory, factoryTearOff, libraryBuilder, this));
  }

  void addProcedure(Procedure procedure) {
    String name = procedure.name.text;
    switch (procedure.kind) {
      case ProcedureKind.Factory:
        // Coverage-ignore(suite): Not run.
        throw new UnsupportedError("Use addFactory for adding factories");
      case ProcedureKind.Setter:
        _nameSpace.addLocalMember(
            name, new DillSetterBuilder(procedure, libraryBuilder, this),
            setter: true);
        break;
      case ProcedureKind.Getter:
        _nameSpace.addLocalMember(
            name, new DillGetterBuilder(procedure, libraryBuilder, this),
            setter: false);
        break;
      case ProcedureKind.Operator:
        _nameSpace.addLocalMember(
            name, new DillOperatorBuilder(procedure, libraryBuilder, this),
            setter: false);
        break;
      case ProcedureKind.Method:
        _nameSpace.addLocalMember(
            name, new DillMethodBuilder(procedure, libraryBuilder, this),
            setter: false);
        break;
    }
  }

  @override
  int get typeParametersCount => cls.typeParameters.length;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    // For performance reasons, [typeParameters] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      // TODO(johnniwinther): Use i2b here when needed.
      return new List<DartType>.generate(cls.typeParameters.length,
          (int i) => cls.typeParameters[i].defaultType,
          growable: true);
    }

    // [arguments] != null
    return new List<DartType>.generate(
        arguments.length,
        (int i) =>
            arguments[i].buildAliased(library, TypeUse.typeArgument, hierarchy),
        growable: true);
  }

  /// Returns true if this class is the result of applying a mixin to its
  /// superclass.
  @override
  bool get isMixinApplication => cls.isMixinApplication;

  @override
  // Coverage-ignore(suite): Not run.
  bool get declaresConstConstructor => cls.hasConstConstructor;

  @override
  TypeBuilder? get mixedInTypeBuilder {
    return computeTypeBuilder(libraryBuilder, cls.mixedInType);
  }

  @override
  List<TypeBuilder>? get interfaceBuilders {
    if (cls.implementedTypes.isEmpty) return null;
    List<TypeBuilder>? interfaceBuilders = _interfaceBuilders;
    if (interfaceBuilders == null) {
      interfaceBuilders = _interfaceBuilders = new List<TypeBuilder>.generate(
          cls.implementedTypes.length,
          (int i) =>
              computeTypeBuilder(libraryBuilder, cls.implementedTypes[i])!,
          growable: false);
    }
    return interfaceBuilders;
  }

  void clearCachedValues() {
    _supertypeBuilder = null;
    _interfaceBuilders = null;
    _typeParameters = null;
  }

  @override
  Reference get reference => cls.reference;
}

TypeBuilder? computeTypeBuilder(
    DillLibraryBuilder library, Supertype? supertype) {
  return supertype == null
      ? null
      : library.loader.computeTypeBuilder(supertype.asInterfaceType);
}

List<DillNominalParameterBuilder>? computeTypeParameterBuilders(
    List<TypeParameter>? typeParameters, Loader loader) {
  if (typeParameters == null || typeParameters.length == 0) return null;
  return <DillNominalParameterBuilder>[
    for (TypeParameter typeParameter in typeParameters)
      new DillNominalParameterBuilder(typeParameter, loader: loader)
  ];
}
