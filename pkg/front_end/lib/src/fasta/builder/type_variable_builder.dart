// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_variable_builder;

import 'package:kernel/ast.dart'
    show DartType, Nullability, TypeParameter, TypeParameterType;
import 'package:kernel/class_hierarchy.dart';

import '../fasta_codes.dart'
    show
        templateInternalProblemUnfinishedTypeVariable,
        templateTypeArgumentsOnTypeVariable;
import '../kernel/body_builder_context.dart';
import '../scope.dart';
import '../source/source_library_builder.dart';
import '../uris.dart';
import '../util/helpers.dart';
import 'builder.dart';
import 'class_builder.dart';
import 'formal_parameter_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
import 'record_type_builder.dart';
import 'type_alias_builder.dart';
import 'type_builder.dart';
import 'type_declaration_builder.dart';

enum TypeVariableKind {
  /// A type variable declared on a function, method, local function or
  /// function type.
  function,

  /// A type variable declared on a class, mixin or enum.
  classMixinOrEnum,

  /// A type variable declared on an extension or an extension type.
  extensionOrExtensionType,

  /// A type variable on an extension instance member synthesized from an
  /// extension type variable.
  extensionSynthesized,

  /// A type variable builder created from a kernel node.
  fromKernel,
}

class TypeVariableBuilder extends TypeDeclarationBuilderImpl {
  /// Sentinel value used to indicate that the variable has no name. This is
  /// used for error recovery.
  static const String noNameSentinel = 'no name sentinel';

  TypeBuilder? bound;

  TypeBuilder? defaultType;

  final TypeParameter actualParameter;

  TypeVariableBuilder? actualOrigin;

  final TypeVariableKind kind;

  @override
  final Uri? fileUri;

  TypeVariableBuilder(
      String name, Builder? compilationUnit, int charOffset, this.fileUri,
      {this.bound,
      required this.kind,
      int? variableVariance,
      List<MetadataBuilder>? metadata})
      : actualParameter =
            new TypeParameter(name == noNameSentinel ? null : name, null)
              ..fileOffset = charOffset
              ..variance = variableVariance,
        super(metadata, 0, name, compilationUnit, charOffset);

  TypeVariableBuilder.fromKernel(TypeParameter parameter)
      : actualParameter = parameter,
        // TODO(johnniwinther): Do we need to support synthesized type
        //  parameters from kernel?
        kind = TypeVariableKind.fromKernel,
        fileUri = null,
        super(null, 0, parameter.name ?? '', null, parameter.fileOffset);

  @override
  bool get isTypeVariable => true;

  @override
  String get debugName => "TypeVariableBuilder";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound!.printOn(buffer);
    }
    return buffer;
  }

  @override
  String toString() => "${printOn(new StringBuffer())}";

  @override
  TypeVariableBuilder get origin => actualOrigin ?? this;

  /// The [TypeParameter] built by this builder.
  TypeParameter get parameter => origin.actualParameter;

  int get variance => parameter.variance;

  void set variance(int value) {
    parameter.variance = value;
  }

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    if (arguments != null) {
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    bool needsPostUpdate = nullabilityBuilder.isOmitted &&
            identical(parameter.bound, TypeParameter.unsetBoundSentinel) ||
        library is SourceLibraryBuilder &&
            library.hasPendingNullability(parameter.bound);
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      if (needsPostUpdate) {
        nullability = Nullability.legacy;
      } else {
        nullability = library.isNonNullableByDefault
            ? TypeParameterType.computeNullabilityFromBound(parameter)
            : Nullability.legacy;
      }
    } else {
      nullability = nullabilityBuilder.build(library);
    }
    TypeParameterType type = buildAliasedTypeWithBuiltArguments(
        library, nullability, null, typeUse, fileUri, charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
    if (needsPostUpdate) {
      if (library is SourceLibraryBuilder) {
        library.registerPendingNullability(
            this.fileUri!, this.charOffset, type);
      } else {
        library.addProblem(
            templateInternalProblemUnfinishedTypeVariable.withArguments(
                name, library.importUri),
            this.charOffset,
            name.length,
            this.fileUri);
      }
    }
    return type;
  }

  @override
  TypeParameterType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    if (arguments != null) {
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri? fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    return new TypeParameterType(parameter, nullability);
  }

  void finish(SourceLibraryBuilder library, ClassBuilder object,
      TypeBuilder dynamicType) {
    if (isPatch) return;
    DartType objectType = object.buildAliasedType(
        library,
        library.nullableBuilder,
        /* arguments = */ null,
        TypeUse.typeParameterBound,
        fileUri ?? missingUri,
        charOffset,
        /* hierarchy = */ null,
        hasExplicitTypeArguments: false);
    if (identical(parameter.bound, TypeParameter.unsetBoundSentinel)) {
      parameter.bound =
          bound?.build(library, TypeUse.typeParameterBound) ?? objectType;
    }
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    if (identical(
        parameter.defaultType, TypeParameter.unsetDefaultTypeSentinel)) {
      parameter.defaultType = defaultType?.build(
              library, TypeUse.typeParameterDefaultType) ??
          (bound != null && parameter.bound == objectType
              ? objectType
              : dynamicType.build(library, TypeUse.typeParameterDefaultType));
    }
  }

  @override
  void applyPatch(covariant TypeVariableBuilder patch) {
    patch.actualOrigin = this;
  }

  TypeVariableBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(cstefantsova): Figure out if using [charOffset] here is a good
    // idea.  An alternative is to use the offset of the node the cloned type
    // variable is declared on.
    return new TypeVariableBuilder(name, parent!, charOffset, fileUri,
        bound: bound?.clone(newTypes, contextLibrary, contextDeclaration),
        variableVariance: variance,
        kind: kind);
  }

  void buildOutlineExpressions(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      Scope scope) {
    MetadataBuilder.buildAnnotations(parameter, metadata, bodyBuilderContext,
        libraryBuilder, fileUri!, scope);
  }

  @override
  bool operator ==(Object other) {
    return other is TypeVariableBuilder && parameter == other.parameter;
  }

  @override
  int get hashCode => parameter.hashCode;

  static List<TypeParameter>? typeParametersFromBuilders(
      List<TypeVariableBuilder>? builders) {
    if (builders == null) return null;
    return new List<TypeParameter>.generate(
        builders.length, (int i) => builders[i].parameter,
        growable: true);
  }
}

List<TypeVariableBuilder> sortTypeVariablesTopologically(
    Iterable<TypeVariableBuilder> typeVariables) {
  Set<TypeVariableBuilder> unhandled = new Set<TypeVariableBuilder>.identity()
    ..addAll(typeVariables);
  List<TypeVariableBuilder> result = <TypeVariableBuilder>[];
  while (unhandled.isNotEmpty) {
    TypeVariableBuilder rootVariable = unhandled.first;
    unhandled.remove(rootVariable);
    if (rootVariable.bound != null) {
      _sortTypeVariablesTopologicallyFromRoot(
          rootVariable.bound!, unhandled, result);
    }
    result.add(rootVariable);
  }
  return result;
}

void _sortTypeVariablesTopologicallyFromRoot(TypeBuilder root,
    Set<TypeVariableBuilder> unhandled, List<TypeVariableBuilder> result) {
  List<TypeVariableBuilder>? foundTypeVariables;
  List<TypeBuilder>? internalDependents;

  switch (root) {
    case NamedTypeBuilder(:TypeDeclarationBuilder? declaration):
      if (declaration is ClassBuilder) {
        foundTypeVariables = declaration.typeVariables;
      } else if (declaration is TypeAliasBuilder) {
        foundTypeVariables = declaration.typeVariables;
        internalDependents = <TypeBuilder>[declaration.type];
      } else if (declaration is TypeVariableBuilder) {
        foundTypeVariables = <TypeVariableBuilder>[declaration];
      }
    case FunctionTypeBuilder(
        :List<TypeVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      foundTypeVariables = typeVariables;
      if (formals != null) {
        internalDependents = <TypeBuilder>[];
        for (ParameterBuilder formal in formals) {
          internalDependents.add(formal.type);
        }
      }
      if (returnType is! OmittedTypeBuilder) {
        (internalDependents ??= <TypeBuilder>[]).add(returnType);
      }
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      if (positionalFields != null) {
        internalDependents = <TypeBuilder>[];
        for (RecordTypeFieldBuilder field in positionalFields) {
          internalDependents.add(field.type);
        }
      }
      if (namedFields != null) {
        internalDependents ??= <TypeBuilder>[];
        for (RecordTypeFieldBuilder field in namedFields) {
          internalDependents.add(field.type);
        }
      }
    case OmittedTypeBuilder():
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
  }

  if (foundTypeVariables != null && foundTypeVariables.isNotEmpty) {
    for (TypeVariableBuilder variable in foundTypeVariables) {
      if (unhandled.contains(variable)) {
        unhandled.remove(variable);
        if (variable.bound != null) {
          _sortTypeVariablesTopologicallyFromRoot(
              variable.bound!, unhandled, result);
        }
        result.add(variable);
      }
    }
  }
  if (internalDependents != null && internalDependents.isNotEmpty) {
    for (TypeBuilder type in internalDependents) {
      _sortTypeVariablesTopologicallyFromRoot(type, unhandled, result);
    }
  }
}
