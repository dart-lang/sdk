// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_enum_builder;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show ShadowClass;

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
        ProcedureKind,
        ReturnStatement,
        StaticGet,
        StringLiteral,
        SuperInitializer,
        ThisExpression,
        TreeNode,
        VariableGet;

import '../fasta_codes.dart'
    show
        messageNoUnnamedConstructorInObject,
        noLength,
        templateDuplicatedName,
        templateEnumConstantSameNameAsEnclosing;

import '../modifier.dart' show constMask, finalMask, staticMask;

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

import 'metadata_collector.dart';

class KernelEnumBuilder extends SourceClassBuilder
    implements EnumBuilder<KernelTypeBuilder, InterfaceType> {
  final List<Object> constantNamesAndOffsetsAndDocs;

  final KernelNamedTypeBuilder intType;

  final KernelNamedTypeBuilder stringType;

  final KernelNamedTypeBuilder objectType;

  final KernelNamedTypeBuilder listType;

  KernelEnumBuilder.internal(
      List<MetadataBuilder> metadata,
      String name,
      Scope scope,
      Scope constructors,
      ShadowClass cls,
      this.constantNamesAndOffsetsAndDocs,
      this.intType,
      this.listType,
      this.objectType,
      this.stringType,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, 0, name, null, null, null, scope, constructors, parent,
            null, charOffset, TreeNode.noOffset, cls);

  factory KernelEnumBuilder(
      MetadataCollector metadataCollector,
      List<MetadataBuilder> metadata,
      String name,
      List<Object> constantNamesAndOffsetsAndDocs,
      KernelLibraryBuilder parent,
      int charOffset,
      int charEndOffset) {
    constantNamesAndOffsetsAndDocs ??= const <Object>[];
    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    KernelTypeBuilder intType = new KernelNamedTypeBuilder("int", null);
    KernelTypeBuilder stringType = new KernelNamedTypeBuilder("String", null);
    KernelNamedTypeBuilder objectType =
        new KernelNamedTypeBuilder("Object", null);
    ShadowClass cls = new ShadowClass(name: name);
    Map<String, MemberBuilder> members = <String, MemberBuilder>{};
    Map<String, MemberBuilder> constructors = <String, MemberBuilder>{};
    KernelNamedTypeBuilder selfType = new KernelNamedTypeBuilder(name, null);
    KernelTypeBuilder listType =
        new KernelNamedTypeBuilder("List", <KernelTypeBuilder>[selfType]);

    /// metadata class E {
    ///   final int index;
    ///   final String _name;
    ///   const E(this.index, this._name);
    ///   static const E id0 = const E(0, 'E.id0');
    ///   ...
    ///   static const E idn-1 = const E(n - 1, 'E.idn-1');
    ///   static const List<E> values = const <E>[id0, ..., idn-1];
    ///   String toString() => _name;
    /// }

    members["index"] = new KernelFieldBuilder(
        null, intType, "index", finalMask, parent, charOffset, null, true);
    members["_name"] = new KernelFieldBuilder(
        null, stringType, "_name", finalMask, parent, charOffset, null, true);
    KernelConstructorBuilder constructorBuilder = new KernelConstructorBuilder(
        null,
        constMask,
        null,
        "",
        null,
        <FormalParameterBuilder>[
          new KernelFormalParameterBuilder(
              null, 0, intType, "index", true, parent, charOffset),
          new KernelFormalParameterBuilder(
              null, 0, stringType, "_name", true, parent, charOffset)
        ],
        parent,
        charOffset,
        charOffset,
        charEndOffset);
    constructors[""] = constructorBuilder;
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
    for (int i = 0; i < constantNamesAndOffsetsAndDocs.length; i += 3) {
      String name = constantNamesAndOffsetsAndDocs[i];
      int charOffset = constantNamesAndOffsetsAndDocs[i + 1];
      String documentationComment = constantNamesAndOffsetsAndDocs[i + 2];
      if (members.containsKey(name)) {
        parent.addCompileTimeError(templateDuplicatedName.withArguments(name),
            charOffset, noLength, parent.fileUri);
        constantNamesAndOffsetsAndDocs[i] = null;
        continue;
      }
      if (name == className) {
        parent.addCompileTimeError(
            templateEnumConstantSameNameAsEnclosing.withArguments(name),
            charOffset,
            noLength,
            parent.fileUri);
        constantNamesAndOffsetsAndDocs[i] = null;
        continue;
      }
      KernelFieldBuilder fieldBuilder = new KernelFieldBuilder(null, selfType,
          name, constMask | staticMask, parent, charOffset, null, true);
      metadataCollector?.setDocumentationComment(
          fieldBuilder.target, documentationComment);
      members[name] = fieldBuilder;
    }
    KernelEnumBuilder enumBuilder = new KernelEnumBuilder.internal(
        metadata,
        name,
        new Scope(members, null, parent.scope, "enum $name",
            isModifiable: false),
        new Scope(constructors, null, null, "constructors",
            isModifiable: false),
        cls,
        constantNamesAndOffsetsAndDocs,
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
    ShadowClass.setBuilder(cls, enumBuilder);
    return enumBuilder;
  }

  KernelTypeBuilder get mixedInType => null;

  InterfaceType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    return cls.rawType;
  }

  @override
  Class build(KernelLibraryBuilder libraryBuilder, LibraryBuilder coreLibrary) {
    cls.isEnum = true;
    intType.resolveIn(coreLibrary.scope, charOffset, fileUri);
    stringType.resolveIn(coreLibrary.scope, charOffset, fileUri);
    objectType.resolveIn(coreLibrary.scope, charOffset, fileUri);
    listType.resolveIn(coreLibrary.scope, charOffset, fileUri);

    KernelFieldBuilder indexFieldBuilder = this["index"];
    Field indexField = indexFieldBuilder.build(libraryBuilder);
    KernelFieldBuilder nameFieldBuilder = this["_name"];
    Field nameField = nameFieldBuilder.build(libraryBuilder);
    KernelProcedureBuilder toStringBuilder = this["toString"];
    toStringBuilder.body = new ReturnStatement(
        new DirectPropertyGet(new ThisExpression(), nameField));
    List<Expression> values = <Expression>[];
    for (int i = 0; i < constantNamesAndOffsetsAndDocs.length; i += 3) {
      String name = constantNamesAndOffsetsAndDocs[i];
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
            new VariableGet(constructor.function.positionalParameters[0]))
          ..parent = constructor);
    constructor.initializers.insert(
        1,
        new FieldInitializer(nameField,
            new VariableGet(constructor.function.positionalParameters[1]))
          ..parent = constructor);
    KernelClassBuilder objectClass = objectType.builder;
    MemberBuilder superConstructor = objectClass.findConstructorOrFactory(
        "", charOffset, fileUri, libraryBuilder);
    if (superConstructor == null || !superConstructor.isConstructor) {
      // TODO(ahe): Ideally, we would also want to check that [Object]'s
      // unnamed constructor requires no arguments. But that information isn't
      // always available at this point, and it's not really a situation that
      // can happen unless you start modifying the SDK sources.
      addCompileTimeError(messageNoUnnamedConstructorInObject, -1, noLength);
    } else {
      constructor.initializers.add(
          new SuperInitializer(superConstructor.target, new Arguments.empty())
            ..parent = constructor);
    }
    int index = 0;
    for (int i = 0; i < constantNamesAndOffsetsAndDocs.length; i += 3) {
      String constant = constantNamesAndOffsetsAndDocs[i];
      if (constant != null) {
        KernelFieldBuilder field = this[constant];
        field.build(libraryBuilder);
        Arguments arguments = new Arguments(<Expression>[
          new IntLiteral(index++),
          new StringLiteral("$name.$constant")
        ]);
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
