// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_class_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../modifier.dart' show abstractMask, namedMixinApplicationMask;
import '../problems.dart' show unimplemented;
import '../scope.dart';
import 'dill_library_builder.dart' show DillLibraryBuilder;
import 'dill_member_builder.dart';

class DillClassBuilder extends ClassBuilderImpl {
  @override
  final Class cls;

  DillClassBuilder(Class cls, DillLibraryBuilder parent)
      : cls = cls,
        super(
            null,
            computeModifiers(cls),
            cls.name,
            null,
            null,
            null,
            null,
            new Scope(
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "class ${cls.name}",
                isModifiable: false),
            new ConstructorScope(cls.name, <String, MemberBuilder>{}),
            parent,
            cls.fileOffset);

  @override
  bool get isEnum => cls.isEnum;

  @override
  DillClassBuilder get origin => this;

  @override
  DillLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as DillLibraryBuilder;

  @override
  bool get isMacro => cls.isMacro;

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
  bool get isAugmentation => false;

  @override
  List<TypeVariableBuilder>? get typeVariables {
    List<TypeVariableBuilder>? typeVariables = super.typeVariables;
    if (typeVariables == null && cls.typeParameters.isNotEmpty) {
      typeVariables = super.typeVariables =
          computeTypeVariableBuilders(libraryBuilder, cls.typeParameters);
    }
    return typeVariables;
  }

  @override
  Uri get fileUri => cls.fileUri;

  @override
  TypeBuilder? get supertypeBuilder {
    TypeBuilder? supertype = super.supertypeBuilder;
    if (supertype == null) {
      Supertype? targetSupertype = cls.supertype;
      if (targetSupertype == null) return null;
      super.supertypeBuilder =
          supertype = computeTypeBuilder(libraryBuilder, targetSupertype);
    }
    return supertype;
  }

  void addField(Field field) {
    DillFieldBuilder builder = new DillFieldBuilder(field, this);
    String name = field.name.text;
    scope.addLocalMember(name, builder, setter: false);
  }

  void addConstructor(Constructor constructor, Procedure? constructorTearOff) {
    DillConstructorBuilder builder =
        new DillConstructorBuilder(constructor, constructorTearOff, this);
    String name = constructor.name.text;
    constructorScope.addLocalMember(name, builder);
  }

  void addFactory(Procedure factory, Procedure? factoryTearOff) {
    String name = factory.name.text;
    constructorScope.addLocalMember(
        name, new DillFactoryBuilder(factory, factoryTearOff, this));
  }

  void addProcedure(Procedure procedure) {
    String name = procedure.name.text;
    switch (procedure.kind) {
      case ProcedureKind.Factory:
        throw new UnsupportedError("Use addFactory for adding factories");
      case ProcedureKind.Setter:
        scope.addLocalMember(name, new DillSetterBuilder(procedure, this),
            setter: true);
        break;
      case ProcedureKind.Getter:
        scope.addLocalMember(name, new DillGetterBuilder(procedure, this),
            setter: false);
        break;
      case ProcedureKind.Operator:
        scope.addLocalMember(name, new DillOperatorBuilder(procedure, this),
            setter: false);
        break;
      case ProcedureKind.Method:
        scope.addLocalMember(name, new DillMethodBuilder(procedure, this),
            setter: false);
        break;
    }
  }

  @override
  int get typeVariablesCount => cls.typeParameters.length;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    // For performance reasons, [typeVariables] aren't restored from [target].
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
  bool get declaresConstConstructor => cls.hasConstConstructor;

  @override
  TypeBuilder? get mixedInTypeBuilder {
    return computeTypeBuilder(libraryBuilder, cls.mixedInType);
  }

  @override
  void set mixedInTypeBuilder(TypeBuilder? mixin) {
    unimplemented("mixedInType=", -1, null);
  }

  @override
  List<TypeBuilder>? get interfaceBuilders {
    if (cls.implementedTypes.isEmpty) return null;
    if (super.interfaceBuilders == null) {
      List<TypeBuilder> result = new List<TypeBuilder>.generate(
          cls.implementedTypes.length,
          (int i) =>
              computeTypeBuilder(libraryBuilder, cls.implementedTypes[i])!,
          growable: false);
      super.interfaceBuilders = result;
    }
    return super.interfaceBuilders;
  }

  @override
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>() =>
      constructorScope.filteredIterator<T>(
          includeAugmentations: true, includeDuplicates: false);

  @override
  NameIterator<T> fullConstructorNameIterator<T extends MemberBuilder>() =>
      constructorScope.filteredNameIterator<T>(
          includeAugmentations: true, includeDuplicates: false);

  @override
  Iterator<T> fullMemberIterator<T extends Builder>() =>
      scope.filteredIterator<T>(
          includeAugmentations: true, includeDuplicates: false);

  @override
  NameIterator<T> fullMemberNameIterator<T extends Builder>() =>
      scope.filteredNameIterator<T>(
          includeAugmentations: true, includeDuplicates: false);

  void clearCachedValues() {
    supertypeBuilder = null;
    interfaceBuilders = null;
  }
}

int computeModifiers(Class cls) {
  int modifiers = 0;
  if (cls.isAbstract) {
    modifiers |= abstractMask;
  }
  // ignore: unnecessary_null_comparison
  if (cls.isMixinApplication && cls.name != null) {
    modifiers |= namedMixinApplicationMask;
  }
  return modifiers;
}

TypeBuilder? computeTypeBuilder(
    DillLibraryBuilder library, Supertype? supertype) {
  return supertype == null
      ? null
      : library.loader.computeTypeBuilder(supertype.asInterfaceType);
}

List<TypeVariableBuilder>? computeTypeVariableBuilders(
    LibraryBuilder library, List<TypeParameter>? typeParameters) {
  if (typeParameters == null || typeParameters.length == 0) return null;
  return new List.generate(typeParameters.length,
      (int i) => new TypeVariableBuilder.fromKernel(typeParameters[i], library),
      growable: false);
}
