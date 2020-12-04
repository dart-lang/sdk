// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.enum_builder;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
        Class,
        Constructor,
        ConstructorInvocation,
        Expression,
        Field,
        FieldInitializer,
        IntLiteral,
        InterfaceType,
        ListLiteral,
        Procedure,
        ProcedureKind,
        PropertyGet,
        ReturnStatement,
        StaticGet,
        StringLiteral,
        SuperInitializer,
        ThisExpression,
        VariableGet;

import 'package:kernel/reference_from_index.dart' show IndexedClass;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        messageNoUnnamedConstructorInObject,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateDuplicatedDeclarationSyntheticCause,
        templateEnumConstantSameNameAsEnclosing;

import '../kernel/metadata_collector.dart';

import '../modifier.dart'
    show
        constMask,
        finalMask,
        hasInitializerMask,
        initializingFormalMask,
        staticMask;

import '../scope.dart';

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'builder.dart';
import 'class_builder.dart';
import 'constructor_builder.dart';
import 'field_builder.dart';
import 'formal_parameter_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'procedure_builder.dart';
import 'type_builder.dart';

class EnumBuilder extends SourceClassBuilder {
  final List<EnumConstantInfo> enumConstantInfos;

  final NamedTypeBuilder intType;

  final NamedTypeBuilder stringType;

  final NamedTypeBuilder objectType;

  final NamedTypeBuilder listType;

  EnumBuilder.internal(
      List<MetadataBuilder> metadata,
      String name,
      Scope scope,
      ConstructorScope constructors,
      Class cls,
      this.enumConstantInfos,
      this.intType,
      this.listType,
      this.objectType,
      this.stringType,
      LibraryBuilder parent,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      Class referencesFrom,
      IndexedClass referencesFromIndexed)
      : super(
            metadata,
            0,
            name,
            null,
            null,
            null,
            null,
            scope,
            constructors,
            parent,
            null,
            startCharOffset,
            charOffset,
            charEndOffset,
            referencesFrom,
            referencesFromIndexed,
            cls: cls);

  factory EnumBuilder(
      MetadataCollector metadataCollector,
      List<MetadataBuilder> metadata,
      String name,
      List<EnumConstantInfo> enumConstantInfos,
      SourceLibraryBuilder parent,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      Class referencesFrom,
      IndexedClass referencesFromIndexed) {
    assert(enumConstantInfos == null || enumConstantInfos.isNotEmpty);
    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    TypeBuilder intType = new NamedTypeBuilder(
        "int",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    TypeBuilder stringType = new NamedTypeBuilder(
        "String",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    NamedTypeBuilder objectType = new NamedTypeBuilder(
        "Object",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    Class cls = new Class(name: name, reference: referencesFrom?.reference);
    Map<String, MemberBuilder> members = <String, MemberBuilder>{};
    Map<String, MemberBuilder> constructors = <String, MemberBuilder>{};
    NamedTypeBuilder selfType = new NamedTypeBuilder(
        name,
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    TypeBuilder listType = new NamedTypeBuilder(
        "List",
        const NullabilityBuilder.omitted(),
        <TypeBuilder>[selfType],
        /* fileUri = */ null,
        /* charOffset = */ null);

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
    Constructor constructorReference;
    Procedure toStringReference;
    Field indexReference;
    Field _nameReference;
    Field valuesReference;
    if (referencesFrom != null) {
      constructorReference = referencesFromIndexed.lookupConstructor("");
      toStringReference =
          referencesFromIndexed.lookupProcedureNotSetter("toString");
      indexReference = referencesFromIndexed.lookupField("index");
      _nameReference = referencesFromIndexed.lookupField("_name");
      valuesReference = referencesFromIndexed.lookupField("values");
    }

    members["index"] = new SourceFieldBuilder(
        null,
        intType,
        "index",
        finalMask | hasInitializerMask,
        /* isTopLevel = */ false,
        parent,
        charOffset,
        charOffset,
        indexReference,
        null,
        null,
        null);
    members["_name"] = new SourceFieldBuilder(
        null,
        stringType,
        "_name",
        finalMask | hasInitializerMask,
        /* isTopLevel = */ false,
        parent,
        charOffset,
        charOffset,
        _nameReference,
        null,
        null,
        null);
    ConstructorBuilder constructorBuilder = new ConstructorBuilderImpl(
        null,
        constMask,
        null,
        "",
        null,
        <FormalParameterBuilder>[
          new FormalParameterBuilder(null, initializingFormalMask, intType,
              "index", parent, charOffset),
          new FormalParameterBuilder(null, initializingFormalMask, stringType,
              "_name", parent, charOffset)
        ],
        parent,
        charOffset,
        charOffset,
        charOffset,
        charEndOffset,
        constructorReference);
    constructors[""] = constructorBuilder;
    FieldBuilder valuesBuilder = new SourceFieldBuilder(
        null,
        listType,
        "values",
        constMask | staticMask | hasInitializerMask,
        /* isTopLevel = */ false,
        parent,
        charOffset,
        charOffset,
        valuesReference,
        null,
        null,
        null);
    members["values"] = valuesBuilder;
    constructorBuilder
      ..registerInitializedField(members["_name"])
      ..registerInitializedField(members["index"])
      ..registerInitializedField(valuesBuilder);
    ProcedureBuilder toStringBuilder = new SourceProcedureBuilder(
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
        charEndOffset,
        toStringReference,
        null,
        AsyncMarker.Sync,
        /* isExtensionInstanceMember = */ false);
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
        Field fieldReference;
        if (referencesFrom != null) {
          fieldReference = referencesFromIndexed.lookupField(name);
        }
        FieldBuilder fieldBuilder = new SourceFieldBuilder(
            metadata,
            selfType,
            name,
            constMask | staticMask | hasInitializerMask,
            /* isTopLevel = */ false,
            parent,
            enumConstantInfo.charOffset,
            enumConstantInfo.charOffset,
            fieldReference,
            null,
            null,
            null);
        metadataCollector?.setDocumentationComment(
            fieldBuilder.field, documentationComment);
        members[name] = fieldBuilder..next = existing;
      }
    }
    final int startCharOffsetComputed =
        metadata == null ? startCharOffset : metadata.first.charOffset;
    EnumBuilder enumBuilder = new EnumBuilder.internal(
        metadata,
        name,
        new Scope(
            local: members,
            parent: parent.scope,
            debugName: "enum $name",
            isModifiable: false),
        new ConstructorScope(name, constructors),
        cls,
        enumConstantInfos,
        intType,
        listType,
        objectType,
        stringType,
        parent,
        startCharOffsetComputed,
        charOffset,
        charEndOffset,
        referencesFrom,
        referencesFromIndexed);
    void setParent(String name, MemberBuilder builder) {
      do {
        builder.parent = enumBuilder;
        builder = builder.next;
      } while (builder != null);
    }

    members.forEach(setParent);
    constructors.forEach(setParent);
    selfType.bind(enumBuilder);
    return enumBuilder;
  }

  TypeBuilder get mixedInTypeBuilder => null;

  InterfaceType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    return rawType(nullabilityBuilder.build(library));
  }

  @override
  Class build(SourceLibraryBuilder libraryBuilder, LibraryBuilder coreLibrary) {
    cls.isEnum = true;
    intType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    stringType.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    objectType.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    listType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);

    SourceFieldBuilder indexFieldBuilder = firstMemberNamed("index");
    indexFieldBuilder.build(libraryBuilder);
    Field indexField = indexFieldBuilder.field;
    SourceFieldBuilder nameFieldBuilder = firstMemberNamed("_name");
    nameFieldBuilder.build(libraryBuilder);
    Field nameField = nameFieldBuilder.field;
    ProcedureBuilder toStringBuilder = firstMemberNamed("toString");
    toStringBuilder.body = new ReturnStatement(
        new PropertyGet(new ThisExpression(), nameField.name, nameField));
    List<Expression> values = <Expression>[];
    if (enumConstantInfos != null) {
      for (EnumConstantInfo enumConstantInfo in enumConstantInfos) {
        if (enumConstantInfo != null) {
          Builder declaration = firstMemberNamed(enumConstantInfo.name);
          if (declaration.isField) {
            SourceFieldBuilder fieldBuilder = declaration;
            fieldBuilder.build(libraryBuilder);
            values.add(new StaticGet(fieldBuilder.field));
          }
        }
      }
    }
    SourceFieldBuilder valuesBuilder = firstMemberNamed("values");
    valuesBuilder.build(libraryBuilder);
    valuesBuilder.buildBody(
        // TODO(johnniwinther): Create the bodies only when we have core types.
        null,
        new ListLiteral(values,
            typeArgument: rawType(library.nonNullable), isConst: true));
    ConstructorBuilderImpl constructorBuilder = constructorScopeBuilder[""];
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
    ClassBuilder objectClass = objectType.declaration;
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
          new SuperInitializer(superConstructor.member, new Arguments.empty())
            ..parent = constructor);
    }
    int index = 0;
    if (enumConstantInfos != null) {
      for (EnumConstantInfo enumConstantInfo in enumConstantInfos) {
        if (enumConstantInfo != null) {
          String constant = enumConstantInfo.name;
          Builder declaration = firstMemberNamed(constant);
          FieldBuilder field;
          if (declaration.isField) {
            field = declaration;
          } else {
            continue;
          }
          Arguments arguments = new Arguments(<Expression>[
            new IntLiteral(index++),
            new StringLiteral("$name.$constant")
          ]);
          field.buildBody(
              // TODO(johnniwinther): Create the bodies only when we have core
              //  types.
              null,
              new ConstructorInvocation(constructor, arguments, isConst: true));
        }
      }
    }
    return super.build(libraryBuilder, coreLibrary);
  }

  @override
  MemberBuilder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder library) {
    return null;
  }
}

class EnumConstantInfo {
  final List<MetadataBuilder> metadata;
  final String name;
  final int charOffset;
  final String documentationComment;
  const EnumConstantInfo(
      this.metadata, this.name, this.charOffset, this.documentationComment);
}
