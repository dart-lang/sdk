// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/problems.dart' show unhandled;
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/invalid_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart'
    show codeCyclicTypedef, codeTypeArgumentMismatch;
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart';
import 'source_type_parameter_builder.dart';

class SourceTypeAliasBuilder extends TypeAliasBuilderImpl {
  @override
  final SourceLibraryBuilder parent;

  @override
  final int fileOffset;

  @override
  final String name;

  @override
  final Uri fileUri;

  late TypeBuilder _type;

  final Reference _reference;

  Typedef? _typedef;

  @override
  DartType? thisType;

  @override
  Map<Name, Procedure>? tearOffs;

  /// The `typedef` declaration that introduces this typedef. Subsequent
  /// typedefs of the same name must be augmentations.
  // TODO(johnniwinther): Add [_augmentations] field.
  final TypedefFragment _introductory;

  SourceTypeAliasBuilder({
    required this.name,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required this.fileUri,
    required int fileOffset,
    required TypedefFragment fragment,
    required Reference? reference,
  }) : fileOffset = fileOffset,
       parent = enclosingLibraryBuilder,
       _reference = reference ?? new Reference(),
       _introductory = fragment,
       _type = fragment.type {
    _introductory.builder = this;
  }

  @override
  TypeBuilder get type => _type;

  /// The [Typedef] built by this builder.
  @override
  Typedef get typedef {
    assert(
      _typedef != null,
      "Typedef node has not been created yet for $this.",
    );
    return _typedef!;
  }

  @override
  Reference get reference => _reference;

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  List<SourceNominalParameterBuilder>? get typeParameters =>
      _introductory.typeParameters?.builders;

  @override
  bool get fromDill => false;

  @override
  int get typeParametersCount => typeParameters?.length ?? 0;

  bool _hasCheckedForCyclicDependency = false;

  void _breakCyclicDependency() {
    if (_hasCheckedForCyclicDependency) return;
    _typedef = new Typedef(
      name,
      null,
      typeParameters: SourceNominalParameterBuilder.typeParametersFromBuilders(
        typeParameters,
      ),
      fileUri: fileUri,
      reference: _reference,
    )..fileOffset = fileOffset;
    if (_checkCyclicTypedefDependency(type, this, {this})) {
      typedef.type = new InvalidType();
      _type = new InvalidTypeBuilderImpl(fileUri, fileOffset);
    }
    if (typeParameters != null) {
      for (TypeParameterBuilder typeParameter in typeParameters!) {
        if (_checkCyclicTypedefDependency(typeParameter.bound, this, {this})) {
          // The bound is erroneous and should be set to [InvalidType].
          typeParameter.parameterBound = new InvalidType();
          typeParameter.parameterDefaultType = new InvalidType();
          typeParameter.bound = new InvalidTypeBuilderImpl(fileUri, fileOffset);
          typeParameter.defaultType = new InvalidTypeBuilderImpl(
            fileUri,
            fileOffset,
          );
          // The typedef itself can't be used without proper bounds of its type
          // variables, so we set it to mean [InvalidType] too.
          typedef.type = new InvalidType();
          _type = new InvalidTypeBuilderImpl(fileUri, fileOffset);
        }
      }
    }
    _hasCheckedForCyclicDependency = true;
  }

  Typedef build() {
    buildThisType();
    return typedef;
  }

  @override
  TypeBuilder? unalias(
    List<TypeBuilder>? typeArguments, {
    Set<TypeAliasBuilder>? usedTypeAliasBuilders,
  }) {
    _breakCyclicDependency();
    return super.unalias(
      typeArguments,
      usedTypeAliasBuilders: usedTypeAliasBuilders,
    );
  }

  bool _checkCyclicTypedefDependency(
    TypeBuilder? typeBuilder,
    TypeAliasBuilder rootTypeAliasBuilder,
    Set<TypeAliasBuilder> seenTypeAliasBuilders,
  ) {
    switch (typeBuilder) {
      case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        typeArguments: List<TypeBuilder>? arguments,
      ):
        if (declaration is TypeAliasBuilder) {
          bool declarationSeenFirstTime = !seenTypeAliasBuilders.contains(
            declaration,
          );
          if (declaration == rootTypeAliasBuilder) {
            for (TypeAliasBuilder seenTypeAliasBuilder in {
              ...seenTypeAliasBuilders,
              declaration,
            }) {
              seenTypeAliasBuilder.libraryBuilder.addProblem(
                codeCyclicTypedef.withArgumentsOld(seenTypeAliasBuilder.name),
                seenTypeAliasBuilder.fileOffset,
                seenTypeAliasBuilder.name.length,
                seenTypeAliasBuilder.fileUri,
              );
            }
            return true;
          } else {
            if (declarationSeenFirstTime) {
              if (_checkCyclicTypedefDependency(
                declaration.type,
                rootTypeAliasBuilder,
                {...seenTypeAliasBuilders, declaration},
              )) {
                return true;
              }
              if (declaration.typeParameters != null) {
                for (TypeParameterBuilder typeParameter
                    in declaration.typeParameters!) {
                  if (_checkCyclicTypedefDependency(
                    typeParameter.bound,
                    rootTypeAliasBuilder,
                    {...seenTypeAliasBuilders, declaration},
                  )) {
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
              typeArgument,
              rootTypeAliasBuilder,
              seenTypeAliasBuilders,
            )) {
              return true;
            }
          }
        } else if (declaration != null && declaration.typeParametersCount > 0) {
          List<TypeParameterBuilder>? typeParameters;
          switch (declaration) {
            case ClassBuilder():
              typeParameters = declaration.typeParameters;
            case TypeAliasBuilder():
              typeParameters = declaration.typeParameters;
            // Coverage-ignore(suite): Not run.
            case ExtensionTypeDeclarationBuilder():
              typeParameters = declaration.typeParameters;
            // Coverage-ignore(suite): Not run.
            case BuiltinTypeDeclarationBuilder():
            case InvalidBuilder():
            case ExtensionBuilder():
            case TypeParameterBuilder():
          }
          if (typeParameters != null) {
            for (int i = 0; i < typeParameters.length; i++) {
              TypeParameterBuilder typeParameter = typeParameters[i];
              if (_checkCyclicTypedefDependency(
                typeParameter.defaultType!,
                rootTypeAliasBuilder,
                seenTypeAliasBuilders,
              )) {
                return true;
              }
            }
          }
        }
      case FunctionTypeBuilder(
        typeParameters: List<StructuralParameterBuilder>? typeParameters,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType,
      ):
        if (_checkCyclicTypedefDependency(
          returnType,
          rootTypeAliasBuilder,
          seenTypeAliasBuilders,
        )) {
          return true;
        }
        if (formals != null) {
          for (ParameterBuilder formal in formals) {
            if (_checkCyclicTypedefDependency(
              formal.type,
              rootTypeAliasBuilder,
              seenTypeAliasBuilders,
            )) {
              return true;
            }
          }
        }
        if (typeParameters != null) {
          for (StructuralParameterBuilder typeParameter in typeParameters) {
            TypeBuilder? bound = typeParameter.bound;
            if (_checkCyclicTypedefDependency(
              bound,
              rootTypeAliasBuilder,
              seenTypeAliasBuilders,
            )) {
              return true;
            }
          }
        }
      case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields,
      ):
        if (positionalFields != null) {
          for (RecordTypeFieldBuilder field in positionalFields) {
            if (_checkCyclicTypedefDependency(
              field.type,
              rootTypeAliasBuilder,
              seenTypeAliasBuilders,
            )) {
              return true;
            }
          }
        }
        if (namedFields != null) {
          for (RecordTypeFieldBuilder field in namedFields) {
            if (_checkCyclicTypedefDependency(
              field.type,
              rootTypeAliasBuilder,
              seenTypeAliasBuilders,
            )) {
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
    _breakCyclicDependency();
    if (thisType != null) {
      if (identical(thisType, pendingTypeAliasMarker)) {
        // Coverage-ignore-block(suite): Not run.
        thisType = cyclicTypeAliasMarker;
        assert(
          libraryBuilder.loader.assertProblemReportedElsewhere(
            "SourceTypeAliasBuilder.buildThisType",
            expectedPhase: CompilationPhaseForProblemReporting.outline,
          ),
        );
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
    if (typeParameters != null) {
      for (NominalParameterBuilder tv in typeParameters!) {
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
  List<DartType> buildAliasedTypeArguments(
    LibraryBuilder library,
    List<TypeBuilder>? arguments,
    ClassHierarchyBase? hierarchy,
  ) {
    if (arguments == null && typeParameters == null) {
      return <DartType>[];
    }

    if (arguments == null && typeParameters != null) {
      // TODO(johnniwinther): Use i2b here when needed.
      List<DartType> result = new List<DartType>.generate(
        typeParameters!.length,
        (int i) =>
            typeParameters![i].defaultType!
            // TODO(johnniwinther): Using [libraryBuilder] here instead of
            // [library] preserves the nullability of the original
            // declaration. We legacy erase it later, but should we legacy
            // erase it now also?
            .buildAliased(
              libraryBuilder,
              TypeUse.defaultTypeAsTypeArgument,
              hierarchy,
            ),
        growable: true,
      );
      return result;
    }

    if (arguments != null && arguments.length != typeParametersCount) {
      // Coverage-ignore-block(suite): Not run.
      assert(
        libraryBuilder.loader.assertProblemReportedElsewhere(
          "SourceTypeAliasBuilder.buildAliasedTypeArguments: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return unhandled(
        codeTypeArgumentMismatch
            .withArgumentsOld(typeParametersCount)
            .problemMessage,
        "buildTypeArguments",
        -1,
        null,
      );
    }

    // arguments.length == typeParameters.length
    return new List<DartType>.generate(
      arguments!.length,
      (int i) =>
          arguments[i].buildAliased(library, TypeUse.typeArgument, hierarchy),
      growable: true,
    );
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new TypedefBodyBuilderContext(this);
  }

  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    MetadataBuilder.buildAnnotations(
      annotatable: typedef,
      annotatableFileUri: typedef.fileUri,
      metadata: _introductory.metadata,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      scope: _introductory.enclosingScope,
    );
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }
    _tearOffDependencies?.forEach((Procedure tearOff, Member target) {
      delayedDefaultValueCloners.add(
        new DelayedDefaultValueCloner(
          target,
          tearOff,
          libraryBuilder: libraryBuilder,
        ),
      );
    });
  }

  int computeDefaultType(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportNonSimplicityIssues(this, typeParameters);
    hasErrors |= context.reportInboundReferenceIssuesForType(type);
    int count = context.computeDefaultTypesForVariables(
      typeParameters,
      inErrorRecovery: hasErrors,
    );
    context.recursivelyReportGenericFunctionTypesAsBoundsForType(type);
    return count;
  }

  Map<Procedure, Member>? _tearOffDependencies;

  DelayedDefaultValueCloner? buildTypedefTearOffs(
    SourceLibraryBuilder libraryBuilder,
    void Function(Procedure) f,
  ) {
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
              libraryBuilder.library,
            )) {
          tearOffs = {};
          _tearOffDependencies = {};
          Iterator<MemberBuilder> iterator = declaration
              .filteredConstructorsIterator(includeDuplicates: false);
          while (iterator.moveNext()) {
            MemberBuilder builder = iterator.current;
            String constructorName = builder.name;
            Member? target = builder.invokeTarget;
            if (target != null) {
              if (target is Procedure && target.isRedirectingFactory) {
                target = builder.readTarget!;
              }
              Class targetClass = target.enclosingClass!;
              if (target is Constructor && targetClass.isAbstract) {
                continue;
              }
              Name targetName = new Name(
                constructorName,
                declaration.libraryBuilder.library,
              );
              Reference? tearOffReference;
              if (libraryBuilder.indexedLibrary != null) {
                Name tearOffName = new Name(
                  typedefTearOffName(name, constructorName),
                  libraryBuilder.indexedLibrary!.library,
                );
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
                    tearOffReference,
                  );
              _tearOffDependencies![tearOff] = target;

              delayedDefaultValueCloner = buildTypedefTearOffProcedure(
                tearOff: tearOff,
                declarationConstructor: target,
                // TODO(johnniwinther): Handle augmented constructors.
                implementationConstructor: target,
                enclosingTypeDeclaration: declaration.cls,
                typeParameters: typedef.typeParameters,
                typeArguments: targetType.typeArguments,
                libraryBuilder: libraryBuilder,
              );
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
              libraryBuilder.library,
            )) {
          tearOffs = {};
          _tearOffDependencies = {};
          Iterator<MemberBuilder> iterator = declaration
              .filteredConstructorsIterator(includeDuplicates: false);
          while (iterator.moveNext()) {
            MemberBuilder builder = iterator.current;
            String constructorName = builder.name;
            Member? target = builder.invokeTarget;
            if (target != null) {
              if (target is Procedure && target.isRedirectingFactory) {
                target = builder.readTarget!;
              }
              Name targetName = new Name(
                constructorName,
                declaration.libraryBuilder.library,
              );
              Reference? tearOffReference;
              if (libraryBuilder.indexedLibrary != null) {
                Name tearOffName = new Name(
                  typedefTearOffName(name, constructorName),
                  libraryBuilder.indexedLibrary!.library,
                );
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
                    tearOffReference,
                  );
              _tearOffDependencies![tearOff] = target;

              delayedDefaultValueCloner = buildTypedefTearOffProcedure(
                tearOff: tearOff,
                declarationConstructor: target,
                // TODO(johnniwinther): Handle augmented constructors.
                implementationConstructor: target,
                enclosingTypeDeclaration: declaration.extensionTypeDeclaration,
                typeParameters: typedef.typeParameters,
                typeArguments: targetType.typeArguments,
                libraryBuilder: libraryBuilder,
              );
              f(tearOff);
            }
          }
        }
      case TypeAliasBuilder():
      case NominalParameterBuilder():
      case StructuralParameterBuilder():
      case ExtensionBuilder():
      case InvalidBuilder():
      case BuiltinTypeDeclarationBuilder():
      case null:
    }

    return delayedDefaultValueCloner;
  }
}
