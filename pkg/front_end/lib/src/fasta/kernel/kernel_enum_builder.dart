// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_enum_builder;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Class,
        Constructor,
        ConstructorInvocation,
        DirectPropertyGet,
        Expression,
        Field,
        FieldInitializer,
        IntLiteral,
        InterfaceType,
        ListLiteral,
        MapEntry,
        MapLiteral,
        MethodInvocation,
        ProcedureKind,
        ReturnStatement,
        StaticGet,
        StringLiteral,
        SuperInitializer,
        ThisExpression,
        VariableGet;

import '../modifier.dart' show constMask, finalMask, staticMask;

import '../names.dart' show indexGetName;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import 'kernel_builder.dart'
    show
        Builder,
        EnumBuilder,
        FormalParameterBuilder,
        KernelClassBuilder,
        KernelConstructorBuilder,
        KernelFieldBuilder,
        KernelFormalParameterBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        Scope;

class KernelEnumBuilder extends SourceClassBuilder
    implements EnumBuilder<KernelTypeBuilder, InterfaceType> {
  final List<Object> constantNamesAndOffsets;

  final MapLiteral toStringMap;

  final KernelNamedTypeBuilder intType;

  final KernelNamedTypeBuilder stringType;

  final KernelNamedTypeBuilder objectType;

  final KernelNamedTypeBuilder listType;

  KernelEnumBuilder.internal(
      List<MetadataBuilder> metadata,
      String name,
      Scope scope,
      Scope constructors,
      Class cls,
      this.constantNamesAndOffsets,
      this.toStringMap,
      this.intType,
      this.listType,
      this.objectType,
      this.stringType,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, 0, name, null, null, null, scope, constructors, parent,
            null, charOffset, cls);

  factory KernelEnumBuilder(
      List<MetadataBuilder> metadata,
      String name,
      List<Object> constantNamesAndOffsets,
      KernelLibraryBuilder parent,
      int charOffset,
      int charEndOffset) {
    constantNamesAndOffsets ??= const <Object>[];
    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    KernelTypeBuilder intType =
        new KernelNamedTypeBuilder("int", null, charOffset, parent.fileUri);
    KernelTypeBuilder stringType =
        new KernelNamedTypeBuilder("String", null, charOffset, parent.fileUri);
    KernelNamedTypeBuilder objectType =
        new KernelNamedTypeBuilder("Object", null, charOffset, parent.fileUri);
    Class cls = new Class(name: name);
    Map<String, MemberBuilder> members = <String, MemberBuilder>{};
    Map<String, MemberBuilder> constructors = <String, MemberBuilder>{};
    KernelNamedTypeBuilder selfType =
        new KernelNamedTypeBuilder(name, null, charOffset, parent.fileUri);
    KernelTypeBuilder listType = new KernelNamedTypeBuilder(
        "List", <KernelTypeBuilder>[selfType], charOffset, parent.fileUri);

    /// From Dart Programming Language Specification 4th Edition/December 2015:
    ///     metadata class E {
    ///       final int index;
    ///       const E(this.index);
    ///       static const E id0 = const E(0);
    ///       ...
    ///       static const E idn-1 = const E(n - 1);
    ///       static const List<E> values = const <E>[id0, ..., idn-1];
    ///       String toString() => { 0: ‘E.id0’, . . ., n-1: ‘E.idn-1’}[index]
    ///     }
    members["index"] = new KernelFieldBuilder(
        null, intType, "index", finalMask, parent, charOffset, null, true);
    KernelConstructorBuilder constructorBuilder = new KernelConstructorBuilder(
        null,
        constMask,
        null,
        "",
        null,
        <FormalParameterBuilder>[
          new KernelFormalParameterBuilder(
              null, 0, intType, "index", true, parent, charOffset)
        ],
        parent,
        charOffset,
        charOffset,
        charEndOffset);
    constructors[""] = constructorBuilder;
    int index = 0;
    List<MapEntry> toStringEntries = <MapEntry>[];
    KernelFieldBuilder valuesBuilder = new KernelFieldBuilder(null, listType,
        "values", constMask | staticMask, parent, charOffset, null, true);
    members["values"] = valuesBuilder;
    KernelProcedureBuilder toStringBuilder = new KernelProcedureBuilder(
        null,
        0,
        stringType,
        "toString",
        null,
        null,
        ProcedureKind.Method,
        parent,
        charOffset,
        charOffset,
        charEndOffset);
    members["toString"] = toStringBuilder;
    String className = name;
    for (int i = 0; i < constantNamesAndOffsets.length; i += 2) {
      String name = constantNamesAndOffsets[i];
      int charOffset = constantNamesAndOffsets[i + 1];
      if (members.containsKey(name)) {
        parent.deprecated_addCompileTimeError(
            charOffset, "Duplicated name: '$name'.");
        constantNamesAndOffsets[i] = null;
        continue;
      }
      if (name == className) {
        parent.deprecated_addCompileTimeError(
            charOffset,
            "Name of enum constant '$name' can't be the same as the enum's "
            "own name.");
        constantNamesAndOffsets[i] = null;
        continue;
      }
      KernelFieldBuilder fieldBuilder = new KernelFieldBuilder(null, selfType,
          name, constMask | staticMask, parent, charOffset, null, true);
      members[name] = fieldBuilder;
      toStringEntries.add(new MapEntry(
          new IntLiteral(index), new StringLiteral("$className.$name")));
      index++;
    }
    MapLiteral toStringMap = new MapLiteral(toStringEntries, isConst: true);
    KernelEnumBuilder enumBuilder = new KernelEnumBuilder.internal(
        metadata,
        name,
        new Scope(members, null, parent.scope, isModifiable: false),
        new Scope(constructors, null, null, isModifiable: false),
        cls,
        constantNamesAndOffsets,
        toStringMap,
        intType,
        listType,
        objectType,
        stringType,
        parent,
        charOffset);
    // TODO(sigmund): dynamic should be `covariant MemberBuilder`.
    void setParent(String name, dynamic b) {
      MemberBuilder builder = b;
      builder.parent = enumBuilder;
    }

    members.forEach(setParent);
    constructors.forEach(setParent);
    selfType.bind(enumBuilder);
    return enumBuilder;
  }

  KernelTypeBuilder get mixedInType => null;

  InterfaceType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    return cls.rawType;
  }

  @override
  Class build(KernelLibraryBuilder libraryBuilder, LibraryBuilder coreLibrary) {
    if (constantNamesAndOffsets.isEmpty) {
      libraryBuilder.deprecated_addCompileTimeError(
          -1, "An enum declaration can't be empty.");
    }
    intType.resolveIn(coreLibrary.scope);
    stringType.resolveIn(coreLibrary.scope);
    objectType.resolveIn(coreLibrary.scope);
    listType.resolveIn(coreLibrary.scope);
    toStringMap.keyType = intType.build(libraryBuilder);
    toStringMap.valueType = stringType.build(libraryBuilder);
    KernelFieldBuilder indexFieldBuilder = this["index"];
    Field indexField = indexFieldBuilder.build(libraryBuilder);
    KernelProcedureBuilder toStringBuilder = this["toString"];
    toStringBuilder.body = new ReturnStatement(new MethodInvocation(
        toStringMap,
        indexGetName,
        new Arguments(<Expression>[
          new DirectPropertyGet(new ThisExpression(), indexField)
        ])));
    List<Expression> values = <Expression>[];
    for (int i = 0; i < constantNamesAndOffsets.length; i += 2) {
      String name = constantNamesAndOffsets[i];
      if (name != null) {
        KernelFieldBuilder builder = this[name];
        values.add(new StaticGet(builder.build(libraryBuilder)));
      }
    }
    KernelFieldBuilder valuesBuilder = this["values"];
    valuesBuilder.build(libraryBuilder);
    valuesBuilder.initializer =
        new ListLiteral(values, typeArgument: cls.rawType, isConst: true);
    KernelConstructorBuilder constructorBuilder = constructorScopeBuilder[""];
    Constructor constructor = constructorBuilder.build(libraryBuilder);
    constructor.initializers.insert(
        0,
        new FieldInitializer(indexField,
            new VariableGet(constructor.function.positionalParameters.single))
          ..parent = constructor);
    KernelClassBuilder objectClass = objectType.builder;
    MemberBuilder superConstructor = objectClass.findConstructorOrFactory(
        "", charOffset, fileUri, libraryBuilder);
    if (superConstructor == null || !superConstructor.isConstructor) {
      // TODO(ahe): Ideally, we would also want to check that [Object]'s
      // unnamed constructor requires no arguments. But that information isn't
      // always available at this point, and it's not really a situation that
      // can happen unless you start modifying the SDK sources.
      deprecated_addCompileTimeError(
          -1, "'Object' has no unnamed constructor.");
    } else {
      constructor.initializers.add(
          new SuperInitializer(superConstructor.target, new Arguments.empty())
            ..parent = constructor);
    }
    int index = 0;
    for (int i = 0; i < constantNamesAndOffsets.length; i += 2) {
      String constant = constantNamesAndOffsets[i];
      if (constant != null) {
        KernelFieldBuilder field = this[constant];
        field.build(libraryBuilder);
        Arguments arguments =
            new Arguments(<Expression>[new IntLiteral(index++)]);
        field.initializer =
            new ConstructorInvocation(constructor, arguments, isConst: true);
      }
    }
    return super.build(libraryBuilder, coreLibrary);
  }

  @override
  Builder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder library) {
    return null;
  }
}
