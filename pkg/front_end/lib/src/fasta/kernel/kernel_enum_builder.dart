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
        ProcedureKind,
        ReturnStatement,
        StaticGet,
        StringLiteral,
        SuperInitializer,
        ThisExpression,
        VariableGet;

import 'kernel_shadow_ast.dart' show ShadowClass;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        messageNoUnnamedConstructorInObject,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateDuplicatedDeclarationSyntheticCause,
        templateEnumConstantSameNameAsEnclosing;

import '../modifier.dart'
    show
        constMask,
        finalMask,
        hasInitializerMask,
        initializingFormalMask,
        staticMask;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import 'kernel_builder.dart'
    show
        Declaration,
        EnumBuilder,
        EnumConstantInfo,
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
  @override
  final List<EnumConstantInfo> enumConstantInfos;

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
      this.enumConstantInfos,
      this.intType,
      this.listType,
      this.objectType,
      this.stringType,
      LibraryBuilder parent,
      int startCharOffset,
      int charOffset,
      int charEndOffset)
      : super(metadata, 0, name, null, null, null, scope, constructors, parent,
            null, startCharOffset, charOffset, charEndOffset,
            cls: cls);

  factory KernelEnumBuilder(
      MetadataCollector metadataCollector,
      List<MetadataBuilder> metadata,
      String name,
      List<EnumConstantInfo> enumConstantInfos,
      KernelLibraryBuilder parent,
      int startCharOffset,
      int charOffset,
      int charEndOffset) {
    assert(enumConstantInfos == null || enumConstantInfos.isNotEmpty);
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

    members["index"] = new KernelFieldBuilder(null, intType, "index",
        finalMask | hasInitializerMask, parent, charOffset, charOffset);
    members["_name"] = new KernelFieldBuilder(null, stringType, "_name",
        finalMask | hasInitializerMask, parent, charOffset, charOffset);
    KernelConstructorBuilder constructorBuilder = new KernelConstructorBuilder(
        null,
        constMask,
        null,
        "",
        null,
        <FormalParameterBuilder>[
          new KernelFormalParameterBuilder(null, initializingFormalMask,
              intType, "index", parent, charOffset),
          new KernelFormalParameterBuilder(null, initializingFormalMask,
              stringType, "_name", parent, charOffset)
        ],
        parent,
        charOffset,
        charOffset,
        charOffset,
        charEndOffset);
    constructors[""] = constructorBuilder;
    KernelFieldBuilder valuesBuilder = new KernelFieldBuilder(
        null,
        listType,
        "values",
        constMask | staticMask | hasInitializerMask,
        parent,
        charOffset,
        charOffset);
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
        charOffset,
        charEndOffset);
    members["toString"] = toStringBuilder;
    String className = name;
    if (enumConstantInfos != null) {
      for (int i = 0; i < enumConstantInfos.length; i++) {
        EnumConstantInfo enumConstantInfo = enumConstantInfos[i];
        List<MetadataBuilder> metadata = enumConstantInfo.metadata;
        String name = enumConstantInfo.name;
        String documentationComment = enumConstantInfo.documentationComment;
        MemberBuilder existing = members[name];
        if (existing != null) {
          // The existing declaration is synthetic if it has the same
          // charOffset as the enclosing enum.
          bool isSynthetic = existing.charOffset == charOffset;
          List<LocatedMessage> context = isSynthetic
              ? <LocatedMessage>[
                  templateDuplicatedDeclarationSyntheticCause
                      .withArguments(name)
                      .withLocation(
                          parent.fileUri, charOffset, className.length)
                ]
              : <LocatedMessage>[
                  templateDuplicatedDeclarationCause
                      .withArguments(name)
                      .withLocation(
                          parent.fileUri, existing.charOffset, name.length)
                ];
          parent.addProblem(templateDuplicatedDeclaration.withArguments(name),
              enumConstantInfo.charOffset, name.length, parent.fileUri,
              context: context);
          enumConstantInfos[i] = null;
        } else if (name == className) {
          parent.addProblem(
              templateEnumConstantSameNameAsEnclosing.withArguments(name),
              enumConstantInfo.charOffset,
              name.length,
              parent.fileUri);
        }
        KernelFieldBuilder fieldBuilder = new KernelFieldBuilder(
            metadata,
            selfType,
            name,
            constMask | staticMask | hasInitializerMask,
            parent,
            enumConstantInfo.charOffset,
            enumConstantInfo.charOffset);
        metadataCollector?.setDocumentationComment(
            fieldBuilder.target, documentationComment);
        members[name] = fieldBuilder..next = existing;
      }
    }
    final int startCharOffsetComputed =
        metadata == null ? startCharOffset : metadata.first.charOffset;
    KernelEnumBuilder enumBuilder = new KernelEnumBuilder.internal(
        metadata,
        name,
        new Scope(members, null, parent.scope, "enum $name",
            isModifiable: false),
        new Scope(constructors, null, null, name, isModifiable: false),
        cls,
        enumConstantInfos,
        intType,
        listType,
        objectType,
        stringType,
        parent,
        startCharOffsetComputed,
        charOffset,
        charEndOffset);
    void setParent(String name, MemberBuilder builder) {
      do {
        builder.parent = enumBuilder;
        builder = builder.next;
      } while (builder != null);
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
    intType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    stringType.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    objectType.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    listType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);

    KernelFieldBuilder indexFieldBuilder = firstMemberNamed("index");
    Field indexField = indexFieldBuilder.build(libraryBuilder);
    KernelFieldBuilder nameFieldBuilder = firstMemberNamed("_name");
    Field nameField = nameFieldBuilder.build(libraryBuilder);
    KernelProcedureBuilder toStringBuilder = firstMemberNamed("toString");
    toStringBuilder.body = new ReturnStatement(
        new DirectPropertyGet(new ThisExpression(), nameField));
    List<Expression> values = <Expression>[];
    if (enumConstantInfos != null) {
      for (EnumConstantInfo enumConstantInfo in enumConstantInfos) {
        if (enumConstantInfo != null) {
          Declaration declaration = firstMemberNamed(enumConstantInfo.name);
          if (declaration.isField) {
            KernelFieldBuilder field = declaration;
            values.add(new StaticGet(field.build(libraryBuilder)));
          }
        }
      }
    }
    KernelFieldBuilder valuesBuilder = firstMemberNamed("values");
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
    KernelClassBuilder objectClass = objectType.declaration;
    MemberBuilder superConstructor = objectClass.findConstructorOrFactory(
        "", charOffset, fileUri, libraryBuilder);
    if (superConstructor == null || !superConstructor.isConstructor) {
      // TODO(ahe): Ideally, we would also want to check that [Object]'s
      // unnamed constructor requires no arguments. But that information isn't
      // always available at this point, and it's not really a situation that
      // can happen unless you start modifying the SDK sources.
      library.addProblem(messageNoUnnamedConstructorInObject,
          objectClass.charOffset, objectClass.name.length, objectClass.fileUri);
    } else {
      constructor.initializers.add(
          new SuperInitializer(superConstructor.target, new Arguments.empty())
            ..parent = constructor);
    }
    int index = 0;
    if (enumConstantInfos != null) {
      for (EnumConstantInfo enumConstantInfo in enumConstantInfos) {
        if (enumConstantInfo != null) {
          String constant = enumConstantInfo.name;
          Declaration declaration = firstMemberNamed(constant);
          KernelFieldBuilder field;
          if (declaration.isField) {
            field = declaration;
          } else {
            continue;
          }
          Arguments arguments = new Arguments(<Expression>[
            new IntLiteral(index++),
            new StringLiteral("$name.$constant")
          ]);
          field.initializer =
              new ConstructorInvocation(constructor, arguments, isConst: true);
        }
      }
    }
    return super.build(libraryBuilder, coreLibrary);
  }

  @override
  Declaration findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder library) {
    return null;
  }
}
