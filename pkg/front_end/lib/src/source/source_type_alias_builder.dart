// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_type_alias_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/invalid_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart'
    show templateCyclicTypedef, templateTypeArgumentMismatch;
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/kernel_helper.dart';
import '../fasta/problems.dart' show unhandled;
import '../fasta/scope.dart';
import '../util/helpers.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceTypeAliasBuilder extends TypeAliasBuilderImpl {
  @override
  TypeBuilder type;

  final List<NominalVariableBuilder>? _typeVariables;

  /// The [Typedef] built by this builder.
  @override
  final Typedef typedef;

  @override
  DartType? thisType;

  @override
  Map<Name, Procedure>? tearOffs;

  SourceTypeAliasBuilder(
      List<MetadataBuilder>? metadata,
      String name,
      this._typeVariables,
      this.type,
      SourceLibraryBuilder parent,
      int charOffset,
      {Typedef? typedef,
      Typedef? referenceFrom})
      : typedef = typedef ??
            (new Typedef(name, null,
                typeParameters:
                    NominalVariableBuilder.typeParametersFromBuilders(
                        _typeVariables),
                fileUri: parent.fileUri,
                reference: referenceFrom?.reference)
              ..fileOffset = charOffset),
        super(metadata, name, parent, charOffset);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  List<NominalVariableBuilder>? get typeVariables => _typeVariables;

  @override
  bool get fromDill => false;

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  Typedef build() {
    buildThisType();
    if (_checkCyclicTypedefDependency(type, this, {this})) {
      typedef.type = new InvalidType();
      type = new InvalidTypeBuilderImpl(fileUri, charOffset);
    }
    if (typeVariables != null) {
      for (TypeVariableBuilderBase typeVariable in typeVariables!) {
        if (_checkCyclicTypedefDependency(typeVariable.bound, this, {this})) {
          // The bound is erroneous and should be set to [InvalidType].
          typeVariable.parameterBound = new InvalidType();
          typeVariable.parameterDefaultType = new InvalidType();
          typeVariable.bound = new InvalidTypeBuilderImpl(fileUri, charOffset);
          typeVariable.defaultType =
              new InvalidTypeBuilderImpl(fileUri, charOffset);
          // The typedef itself can't be used without proper bounds of its type
          // variables, so we set it to mean [InvalidType] too.
          typedef.type = new InvalidType();
          type = new InvalidTypeBuilderImpl(fileUri, charOffset);
        }
      }
    }
    return typedef;
  }

  @override
  TypeBuilder? unalias(List<TypeBuilder>? typeArguments,
      {Set<TypeAliasBuilder>? usedTypeAliasBuilders,
      List<TypeBuilder>? unboundTypes,
      List<StructuralVariableBuilder>? unboundTypeVariables}) {
    build();
    return super.unalias(typeArguments,
        usedTypeAliasBuilders: usedTypeAliasBuilders,
        unboundTypes: unboundTypes,
        unboundTypeVariables: unboundTypeVariables);
  }

  bool _checkCyclicTypedefDependency(
      TypeBuilder? typeBuilder,
      TypeAliasBuilder rootTypeAliasBuilder,
      Set<TypeAliasBuilder> seenTypeAliasBuilders) {
    switch (typeBuilder) {
      case NamedTypeBuilder(
          :TypeDeclarationBuilder? declaration,
          typeArguments: List<TypeBuilder>? arguments
        ):
        if (declaration is TypeAliasBuilder) {
          bool declarationSeenFirstTime =
              !seenTypeAliasBuilders.contains(declaration);
          if (declaration == rootTypeAliasBuilder) {
            for (TypeAliasBuilder seenTypeAliasBuilder in {
              ...seenTypeAliasBuilders,
              declaration
            }) {
              seenTypeAliasBuilder.libraryBuilder.addProblem(
                  templateCyclicTypedef
                      .withArguments(seenTypeAliasBuilder.name),
                  seenTypeAliasBuilder.charOffset,
                  seenTypeAliasBuilder.name.length,
                  seenTypeAliasBuilder.fileUri);
            }
            return true;
          } else {
            if (declarationSeenFirstTime) {
              if (_checkCyclicTypedefDependency(
                  declaration.type,
                  rootTypeAliasBuilder,
                  {...seenTypeAliasBuilders, declaration})) {
                return true;
              }
              if (declaration.typeVariables != null) {
                for (TypeVariableBuilderBase typeVariable
                    in declaration.typeVariables!) {
                  if (_checkCyclicTypedefDependency(
                      typeVariable.bound,
                      rootTypeAliasBuilder,
                      {...seenTypeAliasBuilders, declaration})) {
                    return true;
                  }
                }
              }
            }
          }
        }
        if (arguments != null) {
          for (TypeBuilder typeArgument in arguments) {
            if (_checkCyclicTypedefDependency(
                typeArgument, rootTypeAliasBuilder, seenTypeAliasBuilders)) {
              return true;
            }
          }
        } else if (declaration != null && declaration.typeVariablesCount > 0) {
          List<TypeVariableBuilderBase>? typeParameters;
          switch (declaration) {
            case ClassBuilder():
              typeParameters = declaration.typeVariables;
            case TypeAliasBuilder():
              typeParameters = declaration.typeVariables;
            case ExtensionTypeDeclarationBuilder():
              typeParameters = declaration.typeParameters;
            case BuiltinTypeDeclarationBuilder():
            case InvalidTypeDeclarationBuilder():
            case OmittedTypeDeclarationBuilder():
            case ExtensionBuilder():
            case TypeVariableBuilderBase():
          }
          if (typeParameters != null) {
            for (int i = 0; i < typeParameters.length; i++) {
              TypeVariableBuilderBase typeParameter = typeParameters[i];
              if (_checkCyclicTypedefDependency(typeParameter.defaultType!,
                  rootTypeAliasBuilder, seenTypeAliasBuilders)) {
                return true;
              }
            }
          }
        }
      case FunctionTypeBuilder(
          :List<StructuralVariableBuilder>? typeVariables,
          :List<ParameterBuilder>? formals,
          :TypeBuilder returnType
        ):
        if (_checkCyclicTypedefDependency(
            returnType, rootTypeAliasBuilder, seenTypeAliasBuilders)) {
          return true;
        }
        if (formals != null) {
          for (ParameterBuilder formal in formals) {
            if (_checkCyclicTypedefDependency(
                formal.type, rootTypeAliasBuilder, seenTypeAliasBuilders)) {
              return true;
            }
          }
        }
        if (typeVariables != null) {
          for (StructuralVariableBuilder typeVariable in typeVariables) {
            TypeBuilder? bound = typeVariable.bound;
            if (_checkCyclicTypedefDependency(
                bound, rootTypeAliasBuilder, seenTypeAliasBuilders)) {
              return true;
            }
          }
        }
      case RecordTypeBuilder(
          :List<RecordTypeFieldBuilder>? positionalFields,
          :List<RecordTypeFieldBuilder>? namedFields
        ):
        if (positionalFields != null) {
          for (RecordTypeFieldBuilder field in positionalFields) {
            if (_checkCyclicTypedefDependency(
                field.type, rootTypeAliasBuilder, seenTypeAliasBuilders)) {
              return true;
            }
          }
        }
        if (namedFields != null) {
          for (RecordTypeFieldBuilder field in namedFields) {
            if (_checkCyclicTypedefDependency(
                field.type, rootTypeAliasBuilder, seenTypeAliasBuilders)) {
              return true;
            }
          }
        }
      case OmittedTypeBuilder():
      case FixedTypeBuilder():
      case InvalidTypeBuilder():
      case null:
    }
    return false;
  }

  @override
  DartType buildThisType() {
    if (thisType != null) {
      if (identical(thisType, pendingTypeAliasMarker)) {
        thisType = cyclicTypeAliasMarker;
        // Cyclic type alias. The error is reported elsewhere.
        return const InvalidType();
      } else if (identical(thisType, cyclicTypeAliasMarker)) {
        return const InvalidType();
      }
      return thisType!;
    }
    // It is a compile-time error for an alias (typedef) to refer to itself. We
    // detect cycles by detecting recursive calls to this method using an
    // instance of InvalidType that isn't identical to `const InvalidType()`.
    thisType = pendingTypeAliasMarker;
    DartType builtType = type.build(libraryBuilder, TypeUse.typedefAlias);
    if (typeVariables != null) {
      for (NominalVariableBuilder tv in typeVariables!) {
        // Follow bound in order to find all cycles
        tv.bound?.build(libraryBuilder, TypeUse.typeParameterBound);
      }
    }
    if (identical(thisType, cyclicTypeAliasMarker)) {
      builtType = const InvalidType();
    }
    return thisType = typedef.type ??= builtType;
  }

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      // TODO(johnniwinther): Use i2b here when needed.
      List<DartType> result = new List<DartType>.generate(
          typeVariables!.length,
          (int i) => typeVariables![i]
              .defaultType!
              // TODO(johnniwinther): Using [libraryBuilder] here instead of
              // [library] preserves the nullability of the original
              // declaration. We legacy erase it later, but should we legacy
              // erase it now also?
              .buildAliased(
                  libraryBuilder, TypeUse.defaultTypeAsTypeArgument, hierarchy),
          growable: true);
      return result;
    }

    if (arguments != null && arguments.length != typeVariablesCount) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariablesCount)
              .problemMessage,
          "buildTypeArguments",
          -1,
          null);
    }

    // arguments.length == typeVariables.length
    return new List<DartType>.generate(
        arguments!.length,
        (int i) =>
            arguments[i].buildAliased(library, TypeUse.typeArgument, hierarchy),
        growable: true);
  }

  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new TypedefBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    MetadataBuilder.buildAnnotations(
        typedef,
        metadata,
        createBodyBuilderContext(
            inOutlineBuildingPhase: true,
            inMetadata: true,
            inConstFields: false),
        libraryBuilder,
        fileUri,
        libraryBuilder.scope);
    if (typeVariables != null) {
      for (int i = 0; i < typeVariables!.length; i++) {
        typeVariables![i].buildOutlineExpressions(
            libraryBuilder,
            createBodyBuilderContext(
                inOutlineBuildingPhase: true,
                inMetadata: true,
                inConstFields: false),
            classHierarchy,
            delayedActionPerformers,
            computeTypeParameterScope(libraryBuilder.scope));
      }
    }
    _tearOffDependencies?.forEach((Procedure tearOff, Member target) {
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          target, tearOff,
          libraryBuilder: libraryBuilder));
    });
  }

  Scope computeTypeParameterScope(Scope parent) {
    if (typeVariables == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (NominalVariableBuilder variable in typeVariables!) {
      local[variable.name] = variable;
    }
    return new Scope(
        kind: ScopeKind.typeParameters,
        local: local,
        parent: parent,
        debugName: "type parameter",
        isModifiable: false);
  }

  Map<Procedure, Member>? _tearOffDependencies;

  DelayedDefaultValueCloner? buildTypedefTearOffs(
      SourceLibraryBuilder libraryBuilder, void Function(Procedure) f) {
    TypeDeclarationBuilder? declaration = unaliasDeclaration(null);
    DartType? targetType = typedef.type;
    DelayedDefaultValueCloner? delayedDefaultValueCloner;
    switch (declaration) {
      case ClassBuilder():
        if (targetType is InterfaceType &&
            typedef.typeParameters.isNotEmpty &&
            !isProperRenameForTypeDeclaration(
                libraryBuilder.loader.typeEnvironment,
                typedef,
                libraryBuilder.library)) {
          tearOffs = {};
          _tearOffDependencies = {};
          NameIterator<MemberBuilder> iterator =
              declaration.fullConstructorNameIterator();
          while (iterator.moveNext()) {
            String constructorName = iterator.name;
            MemberBuilder builder = iterator.current;
            Member? target = builder.invokeTarget;
            if (target != null) {
              if (target is Procedure && target.isRedirectingFactory) {
                target = builder.readTarget!;
              }
              Class targetClass = target.enclosingClass!;
              if (target is Constructor && targetClass.isAbstract) {
                continue;
              }
              Name targetName =
                  new Name(constructorName, declaration.libraryBuilder.library);
              Reference? tearOffReference;
              if (libraryBuilder.indexedLibrary != null) {
                Name tearOffName = new Name(
                    typedefTearOffName(name, constructorName),
                    libraryBuilder.indexedLibrary!.library);
                tearOffReference = libraryBuilder.indexedLibrary!
                    .lookupGetterReference(tearOffName);
              }

              Procedure tearOff = tearOffs![targetName] =
                  createTypedefTearOffProcedure(
                      name,
                      constructorName,
                      libraryBuilder,
                      target.fileUri,
                      target.fileOffset,
                      tearOffReference);
              _tearOffDependencies![tearOff] = target;

              delayedDefaultValueCloner = buildTypedefTearOffProcedure(
                  tearOff: tearOff,
                  declarationConstructor: target,
                  // TODO(johnniwinther): Handle augmented constructors.
                  implementationConstructor: target,
                  enclosingTypeDeclaration: declaration.cls,
                  typeParameters: typedef.typeParameters,
                  typeArguments: targetType.typeArguments,
                  libraryBuilder: libraryBuilder);
              f(tearOff);
            }
          }
        }
      case ExtensionTypeDeclarationBuilder():
        if (targetType is ExtensionType &&
            typedef.typeParameters.isNotEmpty &&
            !isProperRenameForTypeDeclaration(
                libraryBuilder.loader.typeEnvironment,
                typedef,
                libraryBuilder.library)) {
          tearOffs = {};
          _tearOffDependencies = {};
          NameIterator<MemberBuilder> iterator =
              declaration.fullConstructorNameIterator();
          while (iterator.moveNext()) {
            String constructorName = iterator.name;
            MemberBuilder builder = iterator.current;
            Member? target = builder.invokeTarget;
            if (target != null) {
              if (target is Procedure && target.isRedirectingFactory) {
                target = builder.readTarget!;
              }
              Name targetName =
                  new Name(constructorName, declaration.libraryBuilder.library);
              Reference? tearOffReference;
              if (libraryBuilder.indexedLibrary != null) {
                Name tearOffName = new Name(
                    typedefTearOffName(name, constructorName),
                    libraryBuilder.indexedLibrary!.library);
                tearOffReference = libraryBuilder.indexedLibrary!
                    .lookupGetterReference(tearOffName);
              }

              Procedure tearOff = tearOffs![targetName] =
                  createTypedefTearOffProcedure(
                      name,
                      constructorName,
                      libraryBuilder,
                      target.fileUri,
                      target.fileOffset,
                      tearOffReference);
              _tearOffDependencies![tearOff] = target;

              delayedDefaultValueCloner = buildTypedefTearOffProcedure(
                  tearOff: tearOff,
                  declarationConstructor: target,
                  // TODO(johnniwinther): Handle augmented constructors.
                  implementationConstructor: target,
                  enclosingTypeDeclaration:
                      declaration.extensionTypeDeclaration,
                  typeParameters: typedef.typeParameters,
                  typeArguments: targetType.typeArguments,
                  libraryBuilder: libraryBuilder);
              f(tearOff);
            }
          }
        }
      case TypeAliasBuilder():
      case NominalVariableBuilder():
      case StructuralVariableBuilder():
      case ExtensionBuilder():
      case InvalidTypeDeclarationBuilder():
      case BuiltinTypeDeclarationBuilder():
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
      case null:
    }

    return delayedDefaultValueCloner;
  }
}
