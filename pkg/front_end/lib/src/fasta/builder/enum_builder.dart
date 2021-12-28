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
        InstanceAccessKind,
        InstanceGet,
        IntLiteral,
        InterfaceType,
        ListLiteral,
        Name,
        ProcedureKind,
        Reference,
        ReturnStatement,
        StaticGet,
        StringConcatenation,
        StringLiteral,
        SuperInitializer,
        ThisExpression;
import 'package:kernel/core_types.dart';

import 'package:kernel/reference_from_index.dart' show IndexedClass;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        messageNoUnnamedConstructorInObject,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateDuplicatedDeclarationSyntheticCause,
        templateEnumConstantSameNameAsEnclosing;

import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/kernel_helper.dart';

import '../util/helpers.dart';

import '../modifier.dart' show constMask, hasInitializerMask, staticMask;

import '../scope.dart';

import '../source/name_scheme.dart';
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
  final List<EnumConstantInfo?>? enumConstantInfos;

  final NamedTypeBuilder intType;

  final NamedTypeBuilder stringType;

  final NamedTypeBuilder objectType;

  final NamedTypeBuilder listType;

  EnumBuilder.internal(
      List<MetadataBuilder>? metadata,
      String name,
      Scope scope,
      ConstructorScope constructors,
      Class cls,
      this.enumConstantInfos,
      this.intType,
      this.listType,
      this.objectType,
      TypeBuilder enumType,
      this.stringType,
      SourceLibraryBuilder parent,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      IndexedClass? referencesFromIndexed)
      : super(
            metadata,
            0,
            name,
            /* typeVariable = */ null,
            enumType,
            /* interfaces = */ null,
            /* onTypes = */ null,
            scope,
            constructors,
            parent,
            /* constructorReferences = */ null,
            startCharOffset,
            charOffset,
            charEndOffset,
            referencesFromIndexed,
            cls: cls);

  factory EnumBuilder(
      List<MetadataBuilder>? metadata,
      String name,
      List<EnumConstantInfo?>? enumConstantInfos,
      SourceLibraryBuilder parent,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      IndexedClass? referencesFromIndexed,
      Scope scope,
      ConstructorScope constructorScope) {
    assert(enumConstantInfos == null || enumConstantInfos.isNotEmpty);

    Uri fileUri = parent.fileUri;

    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    NamedTypeBuilder intType = new NamedTypeBuilder(
        "int",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess:
            // If "int" resolves to an instance type variable then that we would
            // allowed (the types that we are adding are in instance context
            // after all) but it would be unexpected and we would like an
            // assertion failure, since "int" was meant to be `int` from
            // `dart:core`.
            // TODO(johnniwinther): Add a more robust way of creating named
            // typed builders for dart:core types. This might be needed for the
            // enhanced enums feature where enums can actually declare type
            // variables.
            InstanceTypeVariableAccessState.Unexpected);
    NamedTypeBuilder stringType = new NamedTypeBuilder(
        "String",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    NamedTypeBuilder objectType = new NamedTypeBuilder(
        "Object",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    NamedTypeBuilder enumType = new NamedTypeBuilder(
        "_Enum",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    Class cls = new Class(
        name: name,
        reference: referencesFromIndexed?.cls.reference,
        fileUri: fileUri);
    Map<String, MemberBuilder> members = <String, MemberBuilder>{};
    Map<String, MemberBuilder> setters = <String, MemberBuilder>{};
    Map<String, MemberBuilder> constructors = <String, MemberBuilder>{};
    NamedTypeBuilder selfType = new NamedTypeBuilder(
        name,
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    NamedTypeBuilder listType = new NamedTypeBuilder(
        "List",
        const NullabilityBuilder.omitted(),
        <TypeBuilder>[selfType],
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

    // metadata class E extends _Enum {
    //   const E(int index, String name) : super(index, name);
    //   static const E id0 = const E(0, 'id0');
    //   ...
    //   static const E id${n-1} = const E(n - 1, 'idn-1');
    //   static const List<E> values = const <E>[id0, ..., id${n-1}];
    //   String toString() {
    //     return "E.${_Enum::_name}";
    //   }
    // }

    NameScheme staticFieldNameScheme = new NameScheme(
        isInstanceMember: false,
        className: name,
        isExtensionMember: false,
        extensionName: null,
        libraryReference: referencesFromIndexed != null
            ? referencesFromIndexed.library.reference
            : parent.library.reference);

    NameScheme procedureNameScheme = new NameScheme(
        isInstanceMember: true,
        className: name,
        isExtensionMember: false,
        extensionName: null,
        libraryReference: referencesFromIndexed != null
            ? referencesFromIndexed.library.reference
            : parent.library.reference);

    Reference? constructorReference;
    Reference? tearOffReference;
    Reference? toStringReference;
    Reference? valuesFieldReference;
    Reference? valuesGetterReference;
    Reference? valuesSetterReference;
    if (referencesFromIndexed != null) {
      constructorReference =
          referencesFromIndexed.lookupConstructorReference(new Name(""));
      tearOffReference = referencesFromIndexed.lookupGetterReference(
          constructorTearOffName("", referencesFromIndexed.library));
      toStringReference =
          referencesFromIndexed.lookupGetterReference(new Name("toString"));
      Name valuesName = new Name("values");
      valuesFieldReference =
          referencesFromIndexed.lookupFieldReference(valuesName);
      valuesGetterReference =
          referencesFromIndexed.lookupGetterReference(valuesName);
      valuesSetterReference =
          referencesFromIndexed.lookupSetterReference(valuesName);
    }

    SourceConstructorBuilder constructorBuilder = new SourceConstructorBuilder(
        /* metadata = */ null,
        constMask,
        /* returnType = */ null,
        "",
        /* typeParameters = */ null,
        <FormalParameterBuilder>[
          new FormalParameterBuilder(
              null, 0, intType, "index", parent, charOffset),
          new FormalParameterBuilder(
              null, 0, stringType, "name", parent, charOffset)
        ],
        parent,
        charOffset,
        charOffset,
        charOffset,
        charEndOffset,
        constructorReference,
        tearOffReference,
        forAbstractClassOrEnum: true);
    constructors[""] = constructorBuilder;
    FieldBuilder valuesBuilder = new SourceFieldBuilder(
        /* metadata = */ null,
        listType,
        "values",
        constMask | staticMask | hasInitializerMask,
        /* isTopLevel = */ false,
        parent,
        charOffset,
        charOffset,
        staticFieldNameScheme,
        fieldReference: valuesFieldReference,
        fieldGetterReference: valuesGetterReference,
        fieldSetterReference: valuesSetterReference);
    members["values"] = valuesBuilder;
    ProcedureBuilder toStringBuilder = new SourceProcedureBuilder(
        /* metadata = */ null,
        0,
        stringType,
        "toString",
        /* typeVariables = */ null,
        /* formals = */ null,
        ProcedureKind.Method,
        parent,
        charOffset,
        charOffset,
        charOffset,
        charEndOffset,
        toStringReference,
        /* tearOffReference = */ null,
        AsyncMarker.Sync,
        procedureNameScheme,
        isExtensionMember: false,
        isInstanceMember: true);
    members["toString"] = toStringBuilder;
    constructorBuilder.registerInitializedField(valuesBuilder);
    String className = name;
    if (enumConstantInfos != null) {
      for (int i = 0; i < enumConstantInfos.length; i++) {
        EnumConstantInfo enumConstantInfo = enumConstantInfos[i]!;
        List<MetadataBuilder>? metadata = enumConstantInfo.metadata;
        String name = enumConstantInfo.name;
        MemberBuilder? existing = members[name];
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
        Reference? fieldReference;
        Reference? getterReference;
        Reference? setterReference;
        if (referencesFromIndexed != null) {
          Name nameName = new Name(name, referencesFromIndexed.library);
          fieldReference = referencesFromIndexed.lookupFieldReference(nameName);
          getterReference =
              referencesFromIndexed.lookupGetterReference(nameName);
          setterReference =
              referencesFromIndexed.lookupSetterReference(nameName);
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
            staticFieldNameScheme,
            fieldReference: fieldReference,
            fieldGetterReference: getterReference,
            fieldSetterReference: setterReference);
        members[name] = fieldBuilder..next = existing;
      }
    }
    final int startCharOffsetComputed =
        metadata == null ? startCharOffset : metadata.first.charOffset;
    scope.forEachLocalMember((name, member) {
      members[name] = member as MemberBuilder;
    });
    scope.forEachLocalSetter((name, member) {
      setters[name] = member;
    });
    EnumBuilder enumBuilder = new EnumBuilder.internal(
        metadata,
        name,
        new Scope(
            local: members,
            setters: setters,
            parent: parent.scope,
            debugName: "enum $name",
            isModifiable: false),
        constructorScope..local.addAll(constructors),
        cls,
        enumConstantInfos,
        intType,
        listType,
        objectType,
        enumType,
        stringType,
        parent,
        startCharOffsetComputed,
        charOffset,
        charEndOffset,
        referencesFromIndexed);

    void setParent(String name, MemberBuilder? builder) {
      while (builder != null) {
        builder.parent = enumBuilder;
        builder = builder.next as MemberBuilder?;
      }
    }

    members.forEach(setParent);
    constructors.forEach(setParent);
    selfType.bind(enumBuilder);
    return enumBuilder;
  }

  @override
  TypeBuilder? get mixedInTypeBuilder => null;

  @override
  InterfaceType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments) {
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
    TypeBuilder supertypeBuilder = this.supertypeBuilder!;
    supertypeBuilder.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    listType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);

    List<Expression> values = <Expression>[];
    if (enumConstantInfos != null) {
      for (EnumConstantInfo? enumConstantInfo in enumConstantInfos!) {
        if (enumConstantInfo != null) {
          Builder declaration = firstMemberNamed(enumConstantInfo.name)!;
          if (declaration.isField) {
            SourceFieldBuilder fieldBuilder = declaration as SourceFieldBuilder;
            fieldBuilder.build(libraryBuilder);
            values.add(new StaticGet(fieldBuilder.field));
          }
        }
      }
    }
    SourceFieldBuilder valuesBuilder =
        firstMemberNamed("values") as SourceFieldBuilder;
    valuesBuilder.build(libraryBuilder);
    SourceConstructorBuilder constructorBuilder =
        constructorScopeBuilder[""] as SourceConstructorBuilder;
    Constructor constructor = constructorBuilder.build(libraryBuilder);
    ClassBuilder objectClass = objectType.declaration as ClassBuilder;
    ClassBuilder enumClass = supertypeBuilder.declaration as ClassBuilder;
    MemberBuilder? superConstructor = enumClass.findConstructorOrFactory(
        "", charOffset, fileUri, libraryBuilder);
    if (superConstructor == null || !superConstructor.isConstructor) {
      // TODO(ahe): Ideally, we would also want to check that [Object]'s
      // unnamed constructor requires no arguments. But that information isn't
      // always available at this point, and it's not really a situation that
      // can happen unless you start modifying the SDK sources.
      // (We should add a correct message. We no longer depend on Object here.)
      library.addProblem(messageNoUnnamedConstructorInObject,
          objectClass.charOffset, objectClass.name.length, objectClass.fileUri);
    } else {
      constructor.initializers.add(new SuperInitializer(
          superConstructor.member as Constructor,
          new Arguments.forwarded(constructor.function, libraryBuilder.library))
        ..parent = constructor);
    }
    return super.build(libraryBuilder, coreLibrary);
  }

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder libraryBuilder,
      CoreTypes coreTypes,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    List<Expression> values = <Expression>[];
    if (enumConstantInfos != null) {
      for (EnumConstantInfo? enumConstantInfo in enumConstantInfos!) {
        if (enumConstantInfo != null) {
          Builder declaration = firstMemberNamed(enumConstantInfo.name)!;
          if (declaration.isField) {
            SourceFieldBuilder fieldBuilder = declaration as SourceFieldBuilder;
            fieldBuilder.build(libraryBuilder);
            values.add(new StaticGet(fieldBuilder.field));
          }
        }
      }
    }
    SourceFieldBuilder valuesBuilder =
        firstMemberNamed("values") as SourceFieldBuilder;
    valuesBuilder.buildBody(
        coreTypes,
        new ListLiteral(values,
            typeArgument: rawType(library.nonNullable), isConst: true));
    SourceConstructorBuilder constructorBuilder =
        constructorScopeBuilder[""] as SourceConstructorBuilder;
    Constructor constructor = constructorBuilder.constructor;
    int index = 0;
    if (enumConstantInfos != null) {
      for (EnumConstantInfo? enumConstantInfo in enumConstantInfos!) {
        if (enumConstantInfo != null) {
          String constant = enumConstantInfo.name;
          Builder declaration = firstMemberNamed(constant)!;
          FieldBuilder field;
          if (declaration.isField) {
            field = declaration as FieldBuilder;
          } else {
            continue;
          }
          Arguments arguments = new Arguments(<Expression>[
            new IntLiteral(index++),
            new StringLiteral(constant),
          ]);
          field.buildBody(coreTypes,
              new ConstructorInvocation(constructor, arguments, isConst: true));
        }
      }
    }

    ProcedureBuilder toStringBuilder =
        firstMemberNamed("toString") as ProcedureBuilder;

    TypeBuilder supertypeBuilder = this.supertypeBuilder!;
    ClassBuilder enumClass = supertypeBuilder.declaration as ClassBuilder;
    MemberBuilder? nameFieldBuilder =
        enumClass.lookupLocalMember("_name") as MemberBuilder?;
    if (nameFieldBuilder != null) {
      Field nameField = nameFieldBuilder.member as Field;

      toStringBuilder.body = new ReturnStatement(new StringConcatenation([
        new StringLiteral("${cls.demangledName}."),
        new InstanceGet.byReference(
            InstanceAccessKind.Instance, new ThisExpression(), nameField.name,
            interfaceTargetReference: nameField.getterReference,
            resultType: nameField.getterType),
      ]));
    } else {}

    super.buildOutlineExpressions(
        library, coreTypes, delayedActionPerformers, synthesizedFunctionNodes);
  }

  @override
  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder library) {
    return null;
  }
}

class EnumConstantInfo {
  final List<MetadataBuilder>? metadata;
  final String name;
  final int charOffset;
  const EnumConstantInfo(this.metadata, this.name, this.charOffset);
}
