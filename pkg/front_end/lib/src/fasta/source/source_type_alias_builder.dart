// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_type_alias_builder;

import 'package:front_end/src/fasta/kernel/expression_generator_helper.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import 'package:kernel/type_algebra.dart'
    show FreshTypeParameters, getFreshTypeParameters;

import 'package:kernel/type_environment.dart';

import '../fasta_codes.dart'
    show noLength, templateCyclicTypedef, templateTypeArgumentMismatch;

import '../problems.dart' show unhandled;
import '../scope.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';

import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/kernel_helper.dart';

import '../util/helpers.dart';

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceTypeAliasBuilder extends TypeAliasBuilderImpl {
  @override
  final TypeBuilder? type;

  final List<TypeVariableBuilder>? _typeVariables;

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
                typeParameters: TypeVariableBuilder.typeParametersFromBuilders(
                    _typeVariables),
                fileUri: parent.library.fileUri,
                reference: referenceFrom?.reference)
              ..fileOffset = charOffset),
        super(metadata, name, parent, charOffset);

  @override
  SourceLibraryBuilder get library => super.library as SourceLibraryBuilder;

  @override
  List<TypeVariableBuilder>? get typeVariables => _typeVariables;

  @override
  int varianceAt(int index) => typeVariables![index].parameter.variance;

  @override
  bool get fromDill => false;

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  @override
  bool get isNullAlias {
    TypeDeclarationBuilder? typeDeclarationBuilder = type?.declaration;
    return typeDeclarationBuilder is ClassBuilder &&
        typeDeclarationBuilder.isNullClass;
  }

  Typedef build(SourceLibraryBuilder libraryBuilder) {
    typedef.type ??= buildThisType();

    TypeBuilder? type = this.type;
    if (type is FunctionTypeBuilder) {
      List<TypeParameter> typeParameters = new List<TypeParameter>.generate(
          type.typeVariables?.length ?? 0,
          (int i) => type.typeVariables![i].parameter,
          growable: false);
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(typeParameters);
      for (int i = 0; i < freshTypeParameters.freshTypeParameters.length; i++) {
        TypeParameter typeParameter =
            freshTypeParameters.freshTypeParameters[i];
        typedef.typeParametersOfFunctionType
            .add(typeParameter..parent = typedef);
      }

      if (type.formals != null) {
        for (FormalParameterBuilder formal in type.formals!) {
          VariableDeclaration parameter = formal.build(libraryBuilder, 0);
          parameter.type = freshTypeParameters.substitute(parameter.type);
          if (formal.isNamed) {
            typedef.namedParameters.add(parameter);
          } else {
            typedef.positionalParameters.add(parameter);
          }
          parameter.parent = typedef;
        }
      }
    } else if (type is NamedTypeBuilder || type is FixedTypeBuilder) {
      // No error, but also no additional setup work.
      // ignore: unnecessary_null_comparison
    } else if (type != null) {
      unhandled("${type.fullNameForErrors}", "build", charOffset, fileUri);
    }

    return typedef;
  }

  @override
  DartType buildThisType() {
    if (thisType != null) {
      if (identical(thisType, pendingTypeAliasMarker)) {
        thisType = cyclicTypeAliasMarker;
        library.addProblem(templateCyclicTypedef.withArguments(name),
            charOffset, noLength, fileUri);
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
    TypeBuilder? type = this.type;
    // ignore: unnecessary_null_comparison
    if (type != null) {
      DartType builtType =
          type.build(library, origin: thisTypedefType(typedef, library));
      // ignore: unnecessary_null_comparison
      if (builtType != null) {
        if (typeVariables != null) {
          for (TypeVariableBuilder tv in typeVariables!) {
            // Follow bound in order to find all cycles
            tv.bound?.build(library);
          }
        }
        if (identical(thisType, cyclicTypeAliasMarker)) {
          return thisType = const InvalidType();
        } else {
          return thisType = builtType;
        }
      } else {
        return thisType = const InvalidType();
      }
    }
    return thisType = const InvalidType();
  }

  TypedefType thisTypedefType(Typedef typedef, LibraryBuilder clientLibrary) {
    // At this point the bounds of `typedef.typeParameters` may not be assigned
    // yet, so [getAsTypeArguments] may crash trying to compute the nullability
    // of the created types from the bounds.  To avoid that, we use "dynamic"
    // for the bound of all boundless variables and add them to the list for
    // being recomputed later, when the bounds are assigned.
    List<DartType> bounds =
        new List<DartType>.generate(typedef.typeParameters.length, (int i) {
      DartType bound = typedef.typeParameters[i].bound;
      if (identical(bound, TypeParameter.unsetBoundSentinel)) {
        typedef.typeParameters[i].bound = const DynamicType();
      }
      return bound;
    }, growable: false);
    for (int i = 0; i < bounds.length; ++i) {}
    List<DartType> asTypeArguments =
        getAsTypeArguments(typedef.typeParameters, clientLibrary.library);
    TypedefType result =
        new TypedefType(typedef, clientLibrary.nonNullable, asTypeArguments);
    for (int i = 0; i < bounds.length; ++i) {
      if (identical(bounds[i], TypeParameter.unsetBoundSentinel)) {
        // If the bound is not assigned yet, put the corresponding
        // type-parameter type into the list for the nullability re-computation.
        // At this point, [parent] should be a [SourceLibraryBuilder] because
        // otherwise it's a compiled library loaded from a dill file, and the
        // bounds should have been assigned.
        library.registerPendingNullability(
            _typeVariables![i].fileUri!,
            _typeVariables![i].charOffset,
            asTypeArguments[i] as TypeParameterType);
      }
    }
    return result;
  }

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder>? arguments) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result = new List<DartType>.generate(typeVariables!.length,
          (int i) => typeVariables![i].defaultType!.build(library),
          growable: true);
      if (library is SourceLibraryBuilder) {
        library.inferredTypes.addAll(result);
      }
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
        arguments!.length, (int i) => arguments[i].build(library),
        growable: true);
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    library.checkBoundsInTypeParameters(
        typeEnvironment, typedef.typeParameters, fileUri);
    library.checkBoundsInType(
        typedef.type!, typeEnvironment, fileUri, type?.charOffset ?? charOffset,
        allowSuperBounded: false);
  }

  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    MetadataBuilder.buildAnnotations(
        typedef, metadata, library, null, null, fileUri, library.scope);
    if (typeVariables != null) {
      for (int i = 0; i < typeVariables!.length; i++) {
        typeVariables![i].buildOutlineExpressions(
            library,
            null,
            null,
            classHierarchy,
            delayedActionPerformers,
            computeTypeParameterScope(library.scope));
      }
    }
    _tearOffDependencies?.forEach((Procedure tearOff, Member target) {
      InterfaceType targetType = typedef.type as InterfaceType;
      synthesizedFunctionNodes.add(new SynthesizedFunctionNode(
          new Map<TypeParameter, DartType>.fromIterables(
              target.enclosingClass!.typeParameters, targetType.typeArguments),
          target.function!,
          tearOff.function));
    });
  }

  Scope computeTypeParameterScope(Scope parent) {
    if (typeVariables == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (TypeVariableBuilder variable in typeVariables!) {
      local[variable.name] = variable;
    }
    return new Scope(
        local: local,
        parent: parent,
        debugName: "type parameter",
        isModifiable: false);
  }

  Map<Procedure, Member>? _tearOffDependencies;

  void buildTypedefTearOffs(
      SourceLibraryBuilder library, void Function(Procedure) f) {
    TypeDeclarationBuilder? declaration = unaliasDeclaration(null);
    DartType? targetType = typedef.type;
    if (declaration is ClassBuilder &&
        targetType is InterfaceType &&
        typedef.typeParameters.isNotEmpty &&
        !isProperRenameForClass(
            library.loader.typeEnvironment, typedef, library.library)) {
      tearOffs = {};
      _tearOffDependencies = {};
      declaration
          .forEachConstructor((String constructorName, MemberBuilder builder) {
        Member? target = builder.invokeTarget;
        if (target != null) {
          if (target is Procedure && target.isRedirectingFactory) {
            target = builder.readTarget!;
          }
          Name targetName =
              new Name(constructorName, declaration.library.library);
          Reference? tearOffReference;
          if (library.referencesFromIndexed != null) {
            tearOffReference = library.referencesFromIndexed!
                .lookupGetterReference(typedefTearOffName(name, constructorName,
                    library.referencesFromIndexed!.library));
          }

          Procedure tearOff = tearOffs![targetName] =
              createTypedefTearOffProcedure(name, constructorName, library,
                  target.fileUri, target.fileOffset, tearOffReference);
          _tearOffDependencies![tearOff] = target;

          buildTypedefTearOffProcedure(tearOff, target, declaration.cls,
              typedef.typeParameters, targetType.typeArguments, library);
          f(tearOff);
        }
      });
    }
  }
}
