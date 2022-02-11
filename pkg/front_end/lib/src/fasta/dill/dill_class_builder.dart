// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_class_builder;

import 'package:kernel/ast.dart';

import '../builder/class_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';

import '../scope.dart';

import '../problems.dart' show unimplemented;

import '../modifier.dart' show abstractMask, namedMixinApplicationMask;

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
  DillLibraryBuilder get library => super.library as DillLibraryBuilder;

  @override
  bool get isMacro => cls.isMacro;

  @override
  List<TypeVariableBuilder>? get typeVariables {
    List<TypeVariableBuilder>? typeVariables = super.typeVariables;
    if (typeVariables == null && cls.typeParameters.isNotEmpty) {
      typeVariables = super.typeVariables =
          computeTypeVariableBuilders(library, cls.typeParameters);
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
          supertype = computeTypeBuilder(library, targetSupertype);
    }
    return supertype;
  }

  void addField(Field field) {
    DillFieldBuilder builder = new DillFieldBuilder(field, this);
    String name = field.name.text;
    scopeBuilder.addMember(name, builder);
  }

  void addConstructor(Constructor constructor, Procedure? constructorTearOff) {
    DillConstructorBuilder builder =
        new DillConstructorBuilder(constructor, constructorTearOff, this);
    String name = constructor.name.text;
    constructorScopeBuilder.addMember(name, builder);
  }

  void addFactory(Procedure factory, Procedure? factoryTearOff) {
    String name = factory.name.text;
    constructorScopeBuilder.addMember(
        name, new DillFactoryBuilder(factory, factoryTearOff, this));
  }

  void addProcedure(Procedure procedure) {
    String name = procedure.name.text;
    switch (procedure.kind) {
      case ProcedureKind.Factory:
        throw new UnsupportedError("Use addFactory for adding factories");
      case ProcedureKind.Setter:
        scopeBuilder.addSetter(name, new DillSetterBuilder(procedure, this));
        break;
      case ProcedureKind.Getter:
        scopeBuilder.addMember(name, new DillGetterBuilder(procedure, this));
        break;
      case ProcedureKind.Operator:
        scopeBuilder.addMember(name, new DillOperatorBuilder(procedure, this));
        break;
      case ProcedureKind.Method:
        scopeBuilder.addMember(name, new DillMethodBuilder(procedure, this));
        break;
    }
  }

  @override
  int get typeVariablesCount => cls.typeParameters.length;

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder>? arguments) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      return new List<DartType>.generate(cls.typeParameters.length,
          (int i) => cls.typeParameters[i].defaultType,
          growable: true);
    }

    // [arguments] != null
    return new List<DartType>.generate(
        arguments.length, (int i) => arguments[i].build(library),
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
    return computeTypeBuilder(library, cls.mixedInType);
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
          (int i) => computeTypeBuilder(library, cls.implementedTypes[i])!,
          growable: false);
      super.interfaceBuilders = result;
    }
    return super.interfaceBuilders;
  }

  @override
  void forEachConstructor(void Function(String, MemberBuilder) f,
      {bool includeInjectedConstructors: false}) {
    constructors.forEach(f);
  }

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
