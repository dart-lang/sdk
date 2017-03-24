// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_enum_builder;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
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
        ThisExpression,
        VariableGet;

import '../errors.dart' show inputError;

import '../modifier.dart' show constMask, finalMask, staticMask;

import "../source/source_class_builder.dart" show SourceClassBuilder;

import 'kernel_builder.dart'
    show
        Builder,
        EnumBuilder,
        FormalParameterBuilder,
        KernelConstructorBuilder,
        KernelFieldBuilder,
        KernelFormalParameterBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder;

import '../names.dart' show indexGetName;

class KernelEnumBuilder extends SourceClassBuilder
    implements EnumBuilder<KernelTypeBuilder, InterfaceType> {
  final List<Object> constantNamesAndOffsets;

  final MapLiteral toStringMap;

  final KernelTypeBuilder intType;

  final KernelTypeBuilder stringType;

  KernelEnumBuilder.internal(
      List<MetadataBuilder> metadata,
      String name,
      Map<String, Builder> members,
      Class cls,
      this.constantNamesAndOffsets,
      this.toStringMap,
      this.intType,
      this.stringType,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, 0, name, null, null, null, members, parent, null,
            charOffset, cls);

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
    KernelTypeBuilder intType = parent.addType(
        new KernelNamedTypeBuilder("int", null, charOffset, parent.fileUri));
    KernelTypeBuilder stringType = parent.addType(
        new KernelNamedTypeBuilder("String", null, charOffset, parent.fileUri));
    Class cls = new Class(name: name);
    Map<String, Builder> members = <String, Builder>{};
    KernelNamedTypeBuilder selfType =
        new KernelNamedTypeBuilder(name, null, charOffset, parent.fileUri);
    KernelTypeBuilder listType = parent.addType(new KernelNamedTypeBuilder(
        "List", <KernelTypeBuilder>[selfType], charOffset, parent.fileUri));

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
        null, intType, "index", finalMask, parent, charOffset);
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
    members[""] = constructorBuilder;
    int index = 0;
    List<MapEntry> toStringEntries = <MapEntry>[];
    KernelFieldBuilder valuesBuilder = new KernelFieldBuilder(
        null, listType, "values", constMask | staticMask, parent, charOffset);
    members["values"] = valuesBuilder;
    KernelProcedureBuilder toStringBuilder = new KernelProcedureBuilder(
        null,
        0,
        stringType,
        "toString",
        null,
        null,
        AsyncMarker.Sync,
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
        inputError(null, null, "Duplicated name: $name");
        continue;
      }
      KernelFieldBuilder fieldBuilder = new KernelFieldBuilder(
          null, selfType, name, constMask | staticMask, parent, charOffset);
      members[name] = fieldBuilder;
      toStringEntries.add(new MapEntry(
          new IntLiteral(index), new StringLiteral("$className.$name")));
      index++;
    }
    MapLiteral toStringMap = new MapLiteral(toStringEntries, isConst: true);
    KernelEnumBuilder enumBuilder = new KernelEnumBuilder.internal(
        metadata,
        name,
        members,
        cls,
        constantNamesAndOffsets,
        toStringMap,
        intType,
        stringType,
        parent,
        charOffset);
    // TODO(sigmund): dynamic should be `covariant MemberBuilder`.
    members.forEach((String name, dynamic b) {
      MemberBuilder builder = b;
      builder.parent = enumBuilder;
    });
    selfType.builder = enumBuilder;
    return enumBuilder;
  }

  KernelTypeBuilder get mixedInType => null;

  InterfaceType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    return cls.rawType;
  }

  Class build(KernelLibraryBuilder libraryBuilder) {
    if (constantNamesAndOffsets.isEmpty) {
      libraryBuilder.addCompileTimeError(
          -1, "An enum declaration can't be empty.");
    }
    toStringMap.keyType = intType.build(libraryBuilder);
    toStringMap.valueType = stringType.build(libraryBuilder);
    KernelFieldBuilder indexFieldBuilder = members["index"];
    Field indexField = indexFieldBuilder.build(libraryBuilder);
    KernelProcedureBuilder toStringBuilder = members["toString"];
    toStringBuilder.body = new ReturnStatement(new MethodInvocation(
        toStringMap,
        indexGetName,
        new Arguments(<Expression>[
          new DirectPropertyGet(new ThisExpression(), indexField)
        ])));
    List<Expression> values = <Expression>[];
    for (int i = 0; i < constantNamesAndOffsets.length; i += 2) {
      String name = constantNamesAndOffsets[i];
      KernelFieldBuilder builder = members[name];
      values.add(new StaticGet(builder.build(libraryBuilder)));
    }
    KernelFieldBuilder valuesBuilder = members["values"];
    valuesBuilder.build(libraryBuilder);
    valuesBuilder.initializer =
        new ListLiteral(values, typeArgument: cls.rawType, isConst: true);
    KernelConstructorBuilder constructorBuilder = members[""];
    Constructor constructor = constructorBuilder.build(libraryBuilder);
    constructor.initializers.insert(
        0,
        new FieldInitializer(indexField,
            new VariableGet(constructor.function.positionalParameters.single))
          ..parent = constructor);
    int index = 0;
    for (int i = 0; i < constantNamesAndOffsets.length; i += 2) {
      String constant = constantNamesAndOffsets[i];
      KernelFieldBuilder field = members[constant];
      field.build(libraryBuilder);
      Arguments arguments =
          new Arguments(<Expression>[new IntLiteral(index++)]);
      field.initializer =
          new ConstructorInvocation(constructor, arguments, isConst: true);
    }
    return super.build(libraryBuilder);
  }

  Builder findConstructorOrFactory(String name) => null;
}
