// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/reference_from_index.dart';

import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import 'name_scheme.dart';
import 'source_builder_factory.dart';
import 'source_class_builder.dart';
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_procedure_builder.dart';
import 'source_type_alias_builder.dart';

class _Added {
  final Fragment fragment;

  _Added(this.fragment);

  void getAddBuilders(
      {required ProblemReporting problemReporting,
      required SourceLoader loader,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      DeclarationBuilder? declarationBuilder,
      required List<NominalParameterBuilder> unboundNominalVariables,
      required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
      required List<_AddBuilder> builders,
      required IndexedLibrary? indexedLibrary,
      required ContainerType containerType,
      IndexedContainer? indexedContainer,
      ContainerName? containerName}) {
    Fragment fragment = this.fragment;
    switch (fragment) {
      case TypedefFragment():
        Reference? reference = indexedLibrary?.lookupTypedef(fragment.name);
        SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
            name: fragment.name,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            fileOffset: fragment.fileOffset,
            fragment: fragment,
            reference: reference);
        builders.add(new _AddBuilder(fragment.name, typedefBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (reference != null) {
          loader.buildersCreatedWithReferences[reference] = typedefBuilder;
        }
      case ClassFragment():
        IndexedClass? indexedClass =
            indexedLibrary?.lookupIndexedClass(fragment.name);
        SourceClassBuilder classBuilder = new SourceClassBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            supertypeBuilder: BuilderFactoryImpl.applyMixins(
                unboundNominalVariables: unboundNominalVariables,
                compilationUnitScope: fragment.compilationUnitScope,
                problemReporting: problemReporting,
                objectTypeBuilder: loader.target.objectType,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                fileUri: fragment.fileUri,
                indexedLibrary: indexedLibrary,
                supertype: fragment.supertype,
                mixinApplicationBuilder: fragment.mixins,
                mixinApplications: mixinApplications,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                subclassName: fragment.name,
                isMixinDeclaration: false,
                typeParameters: fragment.typeParameters,
                modifiers: Modifiers.empty,
                addBuilder: (String name, Builder declaration, int charOffset,
                    {Reference? getterReference}) {
                  if (getterReference != null) {
                    loader.buildersCreatedWithReferences[getterReference] =
                        declaration;
                  }
                  builders.add(new _AddBuilder(
                      name, declaration, fragment.fileUri, charOffset));
                }),
            interfaceBuilders: fragment.interfaces,
            onTypes: null,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            isMixinDeclaration: false);
        fragment.builder = classBuilder;
        fragment.bodyScope.declarationBuilder = classBuilder;
        builders.add(new _AddBuilder(fragment.name, classBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (indexedClass != null) {
          loader.buildersCreatedWithReferences[indexedClass.reference] =
              classBuilder;
        }
      case MixinFragment():
        IndexedClass? indexedClass =
            indexedLibrary?.lookupIndexedClass(fragment.name);
        SourceClassBuilder mixinBuilder = new SourceClassBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            supertypeBuilder: BuilderFactoryImpl.applyMixins(
                unboundNominalVariables: unboundNominalVariables,
                compilationUnitScope: fragment.compilationUnitScope,
                problemReporting: problemReporting,
                objectTypeBuilder: loader.target.objectType,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                fileUri: fragment.fileUri,
                indexedLibrary: indexedLibrary,
                supertype: fragment.supertype,
                mixinApplicationBuilder: fragment.mixins,
                mixinApplications: mixinApplications,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                subclassName: fragment.name,
                isMixinDeclaration: true,
                typeParameters: fragment.typeParameters,
                modifiers: Modifiers.empty,
                addBuilder: (String name, Builder declaration, int charOffset,
                    {Reference? getterReference}) {
                  if (getterReference != null) {
                    loader.buildersCreatedWithReferences[getterReference] =
                        declaration;
                  }
                  builders.add(new _AddBuilder(
                      name, declaration, fragment.fileUri, charOffset));
                }),
            interfaceBuilders: fragment.interfaces,
            // TODO(johnniwinther): Add the `on` clause types of a mixin
            //  declaration here.
            onTypes: null,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            isMixinDeclaration: true);
        fragment.builder = mixinBuilder;
        fragment.bodyScope.declarationBuilder = mixinBuilder;
        builders.add(new _AddBuilder(fragment.name, mixinBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (indexedClass != null) {
          loader.buildersCreatedWithReferences[indexedClass.reference] =
              mixinBuilder;
        }
      case NamedMixinApplicationFragment():
        BuilderFactoryImpl.applyMixins(
            unboundNominalVariables: unboundNominalVariables,
            compilationUnitScope: fragment.compilationUnitScope,
            problemReporting: problemReporting,
            objectTypeBuilder: loader.target.objectType,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            indexedLibrary: indexedLibrary,
            supertype: fragment.supertype,
            mixinApplicationBuilder: fragment.mixins,
            mixinApplications: mixinApplications,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            subclassName: fragment.name,
            isMixinDeclaration: false,
            metadata: fragment.metadata,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            modifiers: fragment.modifiers,
            interfaces: fragment.interfaces,
            addBuilder: (String name, Builder declaration, int charOffset,
                {Reference? getterReference}) {
              if (getterReference != null) {
                loader.buildersCreatedWithReferences[getterReference] =
                    declaration;
              }
              builders.add(new _AddBuilder(
                  name, declaration, fragment.fileUri, charOffset));
            });

      case EnumFragment():
        IndexedClass? indexedClass =
            indexedLibrary?.lookupIndexedClass(fragment.name);
        SourceEnumBuilder enumBuilder = new SourceEnumBuilder(
            metadata: fragment.metadata,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            underscoreEnumTypeBuilder: loader.target.underscoreEnumType,
            supertypeBuilder: BuilderFactoryImpl.applyMixins(
                unboundNominalVariables: unboundNominalVariables,
                compilationUnitScope: fragment.compilationUnitScope,
                problemReporting: problemReporting,
                objectTypeBuilder: loader.target.objectType,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                fileUri: fragment.fileUri,
                indexedLibrary: indexedLibrary,
                supertype: loader.target.underscoreEnumType,
                mixinApplicationBuilder: fragment.supertypeBuilder,
                mixinApplications: mixinApplications,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                subclassName: fragment.name,
                isMixinDeclaration: false,
                typeParameters: fragment.typeParameters,
                modifiers: Modifiers.empty,
                addBuilder: (String name, Builder declaration, int charOffset,
                    {Reference? getterReference}) {
                  if (getterReference != null) {
                    loader.buildersCreatedWithReferences[getterReference] =
                        declaration;
                  }
                  builders.add(new _AddBuilder(
                      name, declaration, fragment.fileUri, charOffset));
                }),
            interfaceBuilders: fragment.interfaces,
            enumConstantInfos: fragment.enumConstantInfos,
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder());
        fragment.builder = enumBuilder;
        fragment.bodyScope.declarationBuilder = enumBuilder;
        builders.add(new _AddBuilder(
            fragment.name, enumBuilder, fragment.fileUri, fragment.fileOffset));
        if (indexedClass != null) {
          loader.buildersCreatedWithReferences[indexedClass.reference] =
              enumBuilder;
        }
      case ExtensionFragment():
        Reference? reference;
        if (!fragment.extensionName.isUnnamedExtension) {
          reference = indexedLibrary?.lookupExtension(fragment.name);
        }
        SourceExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOrExtensionOffset,
            endOffset: fragment.endOffset,
            fragment: fragment,
            reference: reference);
        builders.add(new _AddBuilder(fragment.name, extensionBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (reference != null) {
          loader.buildersCreatedWithReferences[reference] = extensionBuilder;
        }
      case ExtensionTypeFragment():
        IndexedContainer? indexedContainer = indexedLibrary
            ?.lookupIndexedExtensionTypeDeclaration(fragment.name);
        List<FieldFragment>? primaryConstructorFields =
            fragment.primaryConstructorFields;
        FieldFragment? representationFieldFragment;
        if (primaryConstructorFields != null &&
            primaryConstructorFields.isNotEmpty) {
          representationFieldFragment = primaryConstructorFields.first;
        }
        SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
            new SourceExtensionTypeDeclarationBuilder(
                name: fragment.name,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                constructorReferences: fragment.constructorReferences,
                fileUri: fragment.fileUri,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                fragment: fragment,
                indexedContainer: indexedContainer,
                representationFieldFragment: representationFieldFragment);
        builders.add(new _AddBuilder(
            fragment.name,
            extensionTypeDeclarationBuilder,
            fragment.fileUri,
            fragment.fileOffset));
      case FieldFragment():
        String name = fragment.name;

        final bool fieldIsLateWithLowering = fragment.modifiers.isLate &&
            (loader.target.backendTarget.isLateFieldLoweringEnabled(
                    hasInitializer: fragment.modifiers.hasInitializer,
                    isFinal: fragment.modifiers.isFinal,
                    isStatic:
                        fragment.isTopLevel || fragment.modifiers.isStatic) ||
                (loader.target.backendTarget.useStaticFieldLowering &&
                    // Coverage-ignore(suite): Not run.
                    (fragment.modifiers.isStatic || fragment.isTopLevel)));

        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;
        final bool isExtensionMember = containerType == ContainerType.Extension;
        final bool isExtensionTypeMember =
            containerType == ContainerType.ExtensionType;

        NameScheme nameScheme = new NameScheme(
            isInstanceMember: isInstanceMember,
            containerName: containerName,
            containerType: containerType,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.reference)
                : enclosingLibraryBuilder.libraryName);
        indexedContainer ??= indexedLibrary;

        Reference? fieldReference;
        Reference? fieldGetterReference;
        Reference? fieldSetterReference;
        Reference? lateIsSetFieldReference;
        Reference? lateIsSetGetterReference;
        Reference? lateIsSetSetterReference;
        Reference? lateGetterReference;
        Reference? lateSetterReference;
        if (indexedContainer != null) {
          if ((isExtensionMember || isExtensionTypeMember) &&
              isInstanceMember &&
              fragment.modifiers.isExternal) {
            /// An external extension (type) instance field is special. It is
            /// treated as an external getter/setter pair and is therefore
            /// encoded as a pair of top level methods using the extension
            /// instance member naming convention.
            fieldGetterReference = indexedContainer.lookupGetterReference(
                nameScheme
                    .getProcedureMemberName(ProcedureKind.Getter, name)
                    .name);
            fieldSetterReference = indexedContainer.lookupGetterReference(
                nameScheme
                    .getProcedureMemberName(ProcedureKind.Setter, name)
                    .name);
          } else if (isExtensionTypeMember && isInstanceMember) {
            Name nameToLookup = nameScheme
                .getFieldMemberName(FieldNameType.RepresentationField, name,
                    isSynthesized: true)
                .name;
            fieldGetterReference =
                indexedContainer.lookupGetterReference(nameToLookup);
          } else {
            Name nameToLookup = nameScheme
                .getFieldMemberName(FieldNameType.Field, name,
                    isSynthesized: fieldIsLateWithLowering)
                .name;
            fieldReference =
                indexedContainer.lookupFieldReference(nameToLookup);
            fieldGetterReference =
                indexedContainer.lookupGetterReference(nameToLookup);
            fieldSetterReference =
                indexedContainer.lookupSetterReference(nameToLookup);
          }

          if (fieldIsLateWithLowering) {
            Name lateIsSetName = nameScheme
                .getFieldMemberName(FieldNameType.IsSetField, name,
                    isSynthesized: fieldIsLateWithLowering)
                .name;
            lateIsSetFieldReference =
                indexedContainer.lookupFieldReference(lateIsSetName);
            lateIsSetGetterReference =
                indexedContainer.lookupGetterReference(lateIsSetName);
            lateIsSetSetterReference =
                indexedContainer.lookupSetterReference(lateIsSetName);
            lateGetterReference = indexedContainer.lookupGetterReference(
                nameScheme
                    .getFieldMemberName(FieldNameType.Getter, name,
                        isSynthesized: fieldIsLateWithLowering)
                    .name);
            lateSetterReference = indexedContainer.lookupSetterReference(
                nameScheme
                    .getFieldMemberName(FieldNameType.Setter, name,
                        isSynthesized: fieldIsLateWithLowering)
                    .name);
          }
        }
        SourceFieldBuilder fieldBuilder = new SourceFieldBuilder(
            fragment.metadata,
            fragment.type,
            name,
            fragment.modifiers,
            fragment.isTopLevel,
            enclosingLibraryBuilder,
            declarationBuilder,
            fragment.fileUri,
            fragment.charOffset,
            fragment.charEndOffset,
            nameScheme,
            fieldReference: fieldReference,
            fieldGetterReference: fieldGetterReference,
            fieldSetterReference: fieldSetterReference,
            lateIsSetFieldReference: lateIsSetFieldReference,
            lateIsSetGetterReference: lateIsSetGetterReference,
            lateIsSetSetterReference: lateIsSetSetterReference,
            lateGetterReference: lateGetterReference,
            lateSetterReference: lateSetterReference,
            initializerToken: fragment.initializerToken,
            constInitializerToken: fragment.constInitializerToken);
        fragment.builder = fieldBuilder;
        builders.add(new _AddBuilder(fragment.name, fieldBuilder,
            fragment.fileUri, fragment.charOffset));
        if (fieldGetterReference != null) {
          loader.buildersCreatedWithReferences[fieldGetterReference] =
              fieldBuilder;
        }
        if (fieldSetterReference != null) {
          loader.buildersCreatedWithReferences[fieldSetterReference] =
              fieldBuilder;
        }
      case GetterFragment():
        String name = fragment.name;

        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: isInstanceMember,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        indexedContainer ??= indexedLibrary;

        bool isAugmentation = enclosingLibraryBuilder.isAugmenting &&
            fragment.modifiers.isAugment;

        ProcedureKind kind = ProcedureKind.Getter;
        if (indexedContainer != null && !isAugmentation) {
          Name nameToLookup =
              nameScheme.getProcedureMemberName(kind, name).name;
          procedureReference =
              indexedContainer.lookupGetterReference(nameToLookup);
        }

        SourceProcedureBuilder procedureBuilder = new SourceProcedureBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            returnType: fragment.returnType,
            name: name,
            typeParameters: fragment.typeParameters,
            formals: fragment.formals,
            kind: kind,
            libraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            // TODO(johnniwinther): Avoid formals offset on getter.
            formalsOffset: fragment.formalsOffset,
            endOffset: fragment.endOffset,
            procedureReference: procedureReference,
            tearOffReference: null,
            asyncModifier: fragment.asyncModifier,
            nameScheme: nameScheme,
            nativeMethodName: fragment.nativeMethodName);
        fragment.builder = procedureBuilder;
        builders.add(new _AddBuilder(fragment.name, procedureBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              procedureBuilder;
        }
      case SetterFragment():
        String name = fragment.name;

        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;
        final bool isExtensionMember = containerType == ContainerType.Extension;
        final bool isExtensionTypeMember =
            containerType == ContainerType.ExtensionType;

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: isInstanceMember,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        indexedContainer ??= indexedLibrary;

        bool isAugmentation = enclosingLibraryBuilder.isAugmenting &&
            fragment.modifiers.isAugment;

        ProcedureKind kind = ProcedureKind.Setter;
        if (indexedContainer != null && !isAugmentation) {
          Name nameToLookup =
              nameScheme.getProcedureMemberName(kind, name).name;
          if ((isExtensionMember || isExtensionTypeMember) &&
              isInstanceMember) {
            // Extension (type) instance setters are encoded as methods.
            procedureReference =
                indexedContainer.lookupGetterReference(nameToLookup);
          } else {
            procedureReference =
                indexedContainer.lookupSetterReference(nameToLookup);
          }
        }

        SourceProcedureBuilder procedureBuilder = new SourceProcedureBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            returnType: fragment.returnType,
            name: name,
            typeParameters: fragment.typeParameters,
            formals: fragment.formals,
            kind: kind,
            libraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            formalsOffset: fragment.formalsOffset,
            endOffset: fragment.endOffset,
            procedureReference: procedureReference,
            tearOffReference: null,
            asyncModifier: fragment.asyncModifier,
            nameScheme: nameScheme,
            nativeMethodName: fragment.nativeMethodName);
        fragment.builder = procedureBuilder;
        builders.add(new _AddBuilder(fragment.name, procedureBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              procedureBuilder;
        }
      case MethodFragment():
        String name = fragment.name;
        ProcedureKind kind = fragment.kind;
        assert(kind == ProcedureKind.Method || kind == ProcedureKind.Operator);

        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;
        final bool isExtensionMember = containerType == ContainerType.Extension;
        final bool isExtensionTypeMember =
            containerType == ContainerType.ExtensionType;

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: isInstanceMember,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        Reference? tearOffReference;
        indexedContainer ??= indexedLibrary;

        bool isAugmentation = enclosingLibraryBuilder.isAugmenting &&
            fragment.modifiers.isAugment;
        if (indexedContainer != null && !isAugmentation) {
          Name nameToLookup =
              nameScheme.getProcedureMemberName(kind, name).name;
          procedureReference =
              indexedContainer.lookupGetterReference(nameToLookup);
          if ((isExtensionMember || isExtensionTypeMember) &&
              kind == ProcedureKind.Method) {
            tearOffReference = indexedContainer.lookupGetterReference(nameScheme
                .getProcedureMemberName(ProcedureKind.Getter, name)
                .name);
          }
        }

        SourceProcedureBuilder procedureBuilder = new SourceProcedureBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            returnType: fragment.returnType,
            name: name,
            typeParameters: fragment.typeParameters,
            formals: fragment.formals,
            kind: kind,
            libraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            formalsOffset: fragment.formalsOffset,
            endOffset: fragment.endOffset,
            procedureReference: procedureReference,
            tearOffReference: tearOffReference,
            asyncModifier: fragment.asyncModifier,
            nameScheme: nameScheme,
            nativeMethodName: fragment.nativeMethodName);
        fragment.builder = procedureBuilder;
        builders.add(new _AddBuilder(fragment.name, procedureBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              procedureBuilder;
        }
      case ConstructorFragment():
        String name = fragment.name;

        NameScheme nameScheme = new NameScheme(
            isInstanceMember: false,
            containerName: containerName,
            containerType: containerType,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? constructorReference;
        Reference? tearOffReference;

        if (indexedContainer != null) {
          constructorReference = indexedContainer.lookupConstructorReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedContainer.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }

        AbstractSourceConstructorBuilder constructorBuilder;
        if (declarationBuilder is SourceExtensionTypeDeclarationBuilder) {
          constructorBuilder = new SourceExtensionTypeConstructorBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: name,
              typeParameters: fragment.typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.nameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        } else {
          constructorBuilder = new DeclaredSourceConstructorBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: fragment.name,
              typeParameters: fragment.typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder!,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.nameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        }
        fragment.builder = constructorBuilder;
        builders.add(new _AddBuilder(fragment.name, constructorBuilder,
            fragment.fileUri, fragment.nameOffset));

        // TODO(johnniwinther): There is no way to pass the tear off reference
        //  here.
        if (constructorReference != null) {
          loader.buildersCreatedWithReferences[constructorReference] =
              constructorBuilder;
        }
      case PrimaryConstructorFragment():
        String name = fragment.name;

        NameScheme nameScheme = new NameScheme(
            isInstanceMember: false,
            containerName: containerName,
            containerType: containerType,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? constructorReference;
        Reference? tearOffReference;

        if (indexedContainer != null) {
          constructorReference = indexedContainer.lookupConstructorReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedContainer.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }

        AbstractSourceConstructorBuilder constructorBuilder;
        if (declarationBuilder is SourceExtensionTypeDeclarationBuilder) {
          constructorBuilder = new SourceExtensionTypeConstructorBuilder(
              metadata: null,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: name,
              typeParameters: fragment.typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.fileOffset,
              formalsOffset: fragment.formalsOffset,
              // TODO(johnniwinther): Provide `endOffset`.
              endOffset: fragment.formalsOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        } else {
          // Coverage-ignore-block(suite): Not run.
          constructorBuilder = new DeclaredSourceConstructorBuilder(
              metadata: null,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: fragment.name,
              typeParameters: fragment.typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder!,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.fileOffset,
              formalsOffset: fragment.formalsOffset,
              // TODO(johnniwinther): Provide `endOffset`.
              endOffset: fragment.formalsOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        }
        fragment.builder = constructorBuilder;
        builders.add(new _AddBuilder(fragment.name, constructorBuilder,
            fragment.fileUri, fragment.fileOffset));

        // TODO(johnniwinther): There is no way to pass the tear off reference
        //  here.
        if (constructorReference != null) {
          loader.buildersCreatedWithReferences[constructorReference] =
              constructorBuilder;
        }
      case FactoryFragment():
        String name = fragment.name;

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: false,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        Reference? tearOffReference;
        if (indexedContainer != null) {
          procedureReference = indexedContainer.lookupConstructorReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedContainer.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }
        // Coverage-ignore(suite): Not run.
        else if (indexedLibrary != null) {
          procedureReference = indexedLibrary.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedLibrary.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }

        SourceFactoryBuilder factoryBuilder;
        if (fragment.redirectionTarget != null) {
          factoryBuilder = new RedirectingFactoryBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: name,
              typeParameters: fragment.typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder!,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              nameOffset: fragment.nameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              procedureReference: procedureReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName,
              redirectionTarget: fragment.redirectionTarget!);
          (enclosingLibraryBuilder.redirectingFactoryBuilders ??= [])
              .add(factoryBuilder as RedirectingFactoryBuilder);
        } else {
          factoryBuilder = new SourceFactoryBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: name,
              typeParameters: fragment.typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder!,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              nameOffset: fragment.nameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              procedureReference: procedureReference,
              tearOffReference: tearOffReference,
              asyncModifier: fragment.asyncModifier,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName);
        }
        fragment.builder = factoryBuilder;
        builders.add(new _AddBuilder(fragment.name, factoryBuilder,
            fragment.fileUri, fragment.nameOffset));
        // TODO(johnniwinther): There is no way to pass the tear off reference
        //  here.
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              factoryBuilder;
        }
    }
  }
}

class LibraryNameSpaceBuilder {
  final Map<String, List<Builder>> augmentations = {};

  final Map<String, List<Builder>> setterAugmentations = {};

  List<_Added> _added = [];

  void addFragment(Fragment fragment) {
    _added.add(new _Added(fragment));
  }

  void includeBuilders(LibraryNameSpaceBuilder other) {
    _added.addAll(other._added);
  }

  NameSpace toNameSpace({
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required IndexedLibrary? indexedLibrary,
    required ProblemReporting problemReporting,
    required List<NominalParameterBuilder> unboundNominalVariables,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
  }) {
    Map<String, Builder> getables = {};

    Map<String, MemberBuilder> setables = {};

    Set<ExtensionBuilder> extensions = {};

    NameSpace nameSpace = new NameSpaceImpl(
        getables: getables, setables: setables, extensions: extensions);

    void _addBuilder(
        String name, Builder declaration, Uri fileUri, int charOffset) {
      if (declaration is SourceExtensionBuilder &&
          declaration.isUnnamedExtension) {
        extensions.add(declaration);
        return;
      }

      if (declaration is MemberBuilder ||
          declaration is TypeDeclarationBuilder) {
        // Expected.
      } else {
        // Coverage-ignore-block(suite): Not run.
        // Prefix builders are added when computing the import scope.
        assert(declaration is! PrefixBuilder,
            "Unexpected prefix builder $declaration.");
        unhandled(
            "${declaration.runtimeType}", "addBuilder", charOffset, fileUri);
      }

      assert(
          !(declaration is FunctionBuilder &&
              (declaration.isConstructor || declaration.isFactory)),
          "Unexpected constructor in library: $declaration.");

      Map<String, Builder> members = declaration.isSetter ? setables : getables;

      Builder? existing = members[name];

      if (existing == declaration) return;

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
      if (isDuplicatedDeclaration(existing, declaration)) {
        String fullName = name;
        problemReporting.addProblem(
            templateDuplicatedDeclaration.withArguments(fullName),
            charOffset,
            fullName.length,
            declaration.fileUri!,
            context: <LocatedMessage>[
              templateDuplicatedDeclarationCause
                  .withArguments(fullName)
                  .withLocation(
                      existing!.fileUri!, existing.fileOffset, fullName.length)
            ]);
      } else if (declaration.isExtension) {
        // We add the extension declaration to the extension scope only if its
        // name is unique. Only the first of duplicate extensions is accessible
        // by name or by resolution and the remaining are dropped for the
        // output.
        extensions.add(declaration as SourceExtensionBuilder);
      } else if (declaration.isAugment) {
        if (existing != null) {
          if (declaration.isSetter) {
            (setterAugmentations[name] ??= []).add(declaration);
          } else {
            (augmentations[name] ??= []).add(declaration);
          }
        } else {
          // TODO(cstefantsova): Report an error.
        }
      }
      members[name] = declaration;
    }

    for (_Added added in _added) {
      List<_AddBuilder> addBuilders = [];
      added.getAddBuilders(
          loader: enclosingLibraryBuilder.loader,
          problemReporting: problemReporting,
          enclosingLibraryBuilder: enclosingLibraryBuilder,
          unboundNominalVariables: unboundNominalVariables,
          mixinApplications: mixinApplications,
          builders: addBuilders,
          indexedLibrary: indexedLibrary,
          containerType: ContainerType.Library);
      for (_AddBuilder addBuilder in addBuilders) {
        _addBuilder(addBuilder.name, addBuilder.declaration, addBuilder.fileUri,
            addBuilder.charOffset);
      }
    }
    return nameSpace;
  }
}

class NominalParameterScope extends AbstractTypeParameterScope {
  final NominalParameterNameSpace _nameSpace;

  NominalParameterScope(super._parent, this._nameSpace);

  @override
  Builder? getTypeParameter(String name) => _nameSpace.getTypeParameter(name);
}

class NominalParameterNameSpace {
  Map<String, NominalParameterBuilder> _typeParametersByName = {};

  NominalParameterBuilder? getTypeParameter(String name) =>
      _typeParametersByName[name];

  void addTypeParameters(ProblemReporting _problemReporting,
      List<NominalParameterBuilder>? typeParameters,
      {required String? ownerName, required bool allowNameConflict}) {
    if (typeParameters == null || typeParameters.isEmpty) return;
    for (NominalParameterBuilder tv in typeParameters) {
      NominalParameterBuilder? existing = _typeParametersByName[tv.name];
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
                    .withLocation(existing.fileUri!, existing.fileOffset,
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

abstract class DeclarationFragment {
  final Uri fileUri;
  final LookupScope typeParameterScope;
  final DeclarationBuilderScope bodyScope = new DeclarationBuilderScope();
  final List<_Added> _added = [];

  List<FieldFragment>? primaryConstructorFields;

  final List<NominalParameterBuilder>? typeParameters;

  final NominalParameterNameSpace _nominalParameterNameSpace;

  DeclarationFragment(this.fileUri, this.typeParameters,
      this.typeParameterScope, this._nominalParameterNameSpace);

  String get name;

  int get fileOffset;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  DeclarationBuilder get builder;

  void addPrimaryConstructorField(FieldFragment builder) {
    (primaryConstructorFields ??= []).add(builder);
  }

  void addFragment(Fragment fragment) {
    _added.add(new _Added(fragment));
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder() {
    return new DeclarationNameSpaceBuilder._(
        name, _nominalParameterNameSpace, _added);
  }
}

class _AddBuilder {
  final String name;
  final Builder declaration;
  final Uri fileUri;
  final int charOffset;

  _AddBuilder(this.name, this.declaration, this.fileUri, this.charOffset);
}

class DeclarationNameSpaceBuilder {
  final String _name;
  final NominalParameterNameSpace? _nominalParameterNameSpace;
  final List<_Added> _added;

  DeclarationNameSpaceBuilder.empty()
      : _name = '',
        _nominalParameterNameSpace = null,
        _added = const [];

  DeclarationNameSpaceBuilder._(
      this._name, this._nominalParameterNameSpace, this._added);

  void _addBuilder(
      ProblemReporting problemReporting,
      Map<String, Builder> getables,
      Map<String, MemberBuilder> setables,
      Map<String, MemberBuilder> constructors,
      _AddBuilder addBuilder) {
    String name = addBuilder.name;
    Builder declaration = addBuilder.declaration;
    Uri fileUri = addBuilder.fileUri;
    int charOffset = addBuilder.charOffset;

    bool isConstructor = declaration is FunctionBuilder &&
        (declaration.isConstructor || declaration.isFactory);
    if (!isConstructor && name == _name) {
      problemReporting.addProblem(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Builder> members = isConstructor
        ? constructors
        : (declaration.isSetter ? setables : getables);

    Builder? existing = members[name];

    if (existing == declaration) return;

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
    if (isDuplicatedDeclaration(existing, declaration)) {
      String fullName = name;
      if (isConstructor) {
        if (name.isEmpty) {
          fullName = _name;
        } else {
          fullName = "${_name}.$name";
        }
      }
      problemReporting.addProblem(
          templateDuplicatedDeclaration.withArguments(fullName),
          charOffset,
          fullName.length,
          declaration.fileUri!,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing!.fileUri!, existing.fileOffset, fullName.length)
          ]);
    } else if (declaration.isAugment) {
      // Coverage-ignore-block(suite): Not run.
      if (existing != null) {
        if (declaration.isSetter) {
          // TODO(johnniwinther): Collection augment setables.
        } else {
          // TODO(johnniwinther): Collection augment getables.
        }
      } else {
        // TODO(cstefantsova): Report an error.
      }
    }
    members[name] = declaration;
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

  DeclarationNameSpace buildNameSpace(
      {required SourceLoader loader,
      required ProblemReporting problemReporting,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required IndexedLibrary? indexedLibrary,
      required IndexedContainer? indexedContainer,
      required ContainerType containerType,
      required ContainerName containerName,
      bool includeConstructors = true}) {
    Map<String, Builder> getables = {};
    Map<String, MemberBuilder> setables = {};
    Map<String, MemberBuilder> constructors = {};

    for (_Added added in _added) {
      List<_AddBuilder> addBuilders = [];
      added.getAddBuilders(
          loader: loader,
          problemReporting: problemReporting,
          enclosingLibraryBuilder: enclosingLibraryBuilder,
          declarationBuilder: declarationBuilder,
          builders: addBuilders,
          // TODO(johnniwinther): Avoid passing these:
          unboundNominalVariables: const [],
          mixinApplications: const {},
          indexedLibrary: indexedLibrary,
          indexedContainer: indexedContainer,
          containerType: containerType,
          containerName: containerName);
      for (_AddBuilder addBuilder in addBuilders) {
        _addBuilder(
            problemReporting, getables, setables, constructors, addBuilder);
      }
    }

    void checkConflicts(String name, Builder member) {
      checkTypeParameterConflict(
          problemReporting, name, member, member.fileUri!);
    }

    getables.forEach(checkConflicts);
    setables.forEach(checkConflicts);
    constructors.forEach(checkConflicts);

    return new DeclarationNameSpaceImpl(
        getables: getables,
        setables: setables,
        // TODO(johnniwinther): Handle constructors in extensions consistently.
        // Currently they are not part of the name space but still processed
        // for instance when inferring redirecting factories.
        constructors: includeConstructors ? constructors : null);
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

class DeclarationBuilderScope implements LookupScope {
  DeclarationBuilder? _declarationBuilder;

  DeclarationBuilderScope();

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _declarationBuilder?.scope.forEachExtension(f);
  }

  void set declarationBuilder(DeclarationBuilder value) {
    assert(_declarationBuilder == null,
        "declarationBuilder has already been set.");
    _declarationBuilder = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ScopeKind get kind =>
      _declarationBuilder?.scope.kind ?? ScopeKind.declaration;

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    return _declarationBuilder?.scope.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    return _declarationBuilder?.scope.lookupSetable(name, charOffset, fileUri);
  }
}

bool isDuplicatedDeclaration(Builder? existing, Builder other) {
  if (existing == null) return false;
  if (other.isAugment) return false;
  Builder? next = existing.next;
  if (next == null) {
    if (existing.isGetter && other.isSetter) return false;
    if (existing.isSetter && other.isGetter) return false;
  } else {
    if (next is ClassBuilder && !next.isMixinApplication) return true;
  }
  if (existing is ClassBuilder && other is ClassBuilder) {
    // We allow multiple mixin applications with the same name. An
    // alternative is to share these mixin applications. This situation can
    // happen if you have `class A extends Object with Mixin {}` and `class B
    // extends Object with Mixin {}` in the same library.
    return !existing.isMixinApplication ||
        // Coverage-ignore(suite): Not run.
        !other.isMixinApplication;
  }
  return true;
}
