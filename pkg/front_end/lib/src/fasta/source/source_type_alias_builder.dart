// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_type_alias_builder;

import 'package:kernel/ast.dart'
    show
        DartType,
        DynamicType,
        InvalidType,
        TypeParameter,
        Typedef,
        TypedefType,
        VariableDeclaration,
        getAsTypeArguments;

import 'package:kernel/type_algebra.dart'
    show FreshTypeParameters, getFreshTypeParameters;

import '../fasta_codes.dart'
    show noLength, templateCyclicTypedef, templateTypeArgumentMismatch;

import '../problems.dart' show unhandled;

import '../builder/class_builder.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceTypeAliasBuilder extends TypeAliasBuilderImpl {
  final TypeBuilder type;

  final List<TypeVariableBuilder> _typeVariables;

  /// The [Typedef] built by this builder.
  final Typedef typedef;

  DartType thisType;

  SourceTypeAliasBuilder(List<MetadataBuilder> metadata, String name,
      this._typeVariables, this.type, LibraryBuilder parent, int charOffset,
      {Typedef typedef, Typedef referenceFrom})
      : typedef = typedef ??
            (new Typedef(name, null,
                typeParameters: TypeVariableBuilder.typeParametersFromBuilders(
                    _typeVariables),
                fileUri: parent.library.fileUri,
                reference: referenceFrom?.reference)
              ..fileOffset = charOffset),
        super(metadata, name, parent, charOffset);

  @override
  List<TypeVariableBuilder> get typeVariables => _typeVariables;

  @override
  int varianceAt(int index) => typeVariables[index].parameter.variance;

  @override
  bool get fromDill => false;

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  @override
  bool get isNullAlias {
    TypeDeclarationBuilder typeDeclarationBuilder = type.declaration;
    return typeDeclarationBuilder is ClassBuilder &&
        typeDeclarationBuilder.isNullClass;
  }

  Typedef build(SourceLibraryBuilder libraryBuilder) {
    typedef.type ??= buildThisType();

    TypeBuilder type = this.type;
    if (type is FunctionTypeBuilder) {
      List<TypeParameter> typeParameters =
          new List<TypeParameter>.filled(type.typeVariables?.length ?? 0, null);
      for (int i = 0; i < typeParameters.length; ++i) {
        TypeVariableBuilder typeVariable = type.typeVariables[i];
        typeParameters[i] = typeVariable.parameter;
      }
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(typeParameters);
      for (int i = 0; i < freshTypeParameters.freshTypeParameters.length; i++) {
        TypeParameter typeParameter =
            freshTypeParameters.freshTypeParameters[i];
        typedef.typeParametersOfFunctionType
            .add(typeParameter..parent = typedef);
      }

      if (type.formals != null) {
        for (FormalParameterBuilder formal in type.formals) {
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
    } else if (type != null) {
      unhandled("${type.fullNameForErrors}", "build", charOffset, fileUri);
    }

    return typedef;
  }

  DartType buildThisType() {
    if (thisType != null) {
      if (identical(thisType, cyclicTypeAliasMarker)) {
        library.addProblem(templateCyclicTypedef.withArguments(name),
            charOffset, noLength, fileUri);
        return const InvalidType();
      }
      return thisType;
    }
    // It is a compile-time error for an alias (typedef) to refer to itself. We
    // detect cycles by detecting recursive calls to this method using an
    // instance of InvalidType that isn't identical to `const InvalidType()`.
    thisType = cyclicTypeAliasMarker;
    TypeBuilder type = this.type;
    if (type != null) {
      DartType builtType =
          type.build(library, thisTypedefType(typedef, library));
      if (builtType != null) {
        if (typeVariables != null) {
          for (TypeVariableBuilder tv in typeVariables) {
            // Follow bound in order to find all cycles
            tv.bound?.build(library);
          }
        }
        return thisType = builtType;
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
        new List<DartType>.filled(typedef.typeParameters.length, null);
    for (int i = 0; i < bounds.length; ++i) {
      bounds[i] = typedef.typeParameters[i].bound;
      if (bounds[i] == null) {
        typedef.typeParameters[i].bound = const DynamicType();
      }
    }
    List<DartType> asTypeArguments =
        getAsTypeArguments(typedef.typeParameters, clientLibrary.library);
    TypedefType result =
        new TypedefType(typedef, clientLibrary.nonNullable, asTypeArguments);
    for (int i = 0; i < bounds.length; ++i) {
      if (bounds[i] == null) {
        // If the bound is not assigned yet, put the corresponding
        // type-parameter type into the list for the nullability re-computation.
        // At this point, [parent] should be a [SourceLibraryBuilder] because
        // otherwise it's a compiled library loaded from a dill file, and the
        // bounds should have been assigned.
        SourceLibraryBuilder parentLibrary = parent;
        parentLibrary.pendingNullabilities.add(asTypeArguments[i]);
      }
    }
    return result;
  }

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result =
          new List<DartType>.filled(typeVariables.length, null, growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeVariables[i].defaultType.build(library);
      }
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
              .message,
          "buildTypeArguments",
          -1,
          null);
    }

    // arguments.length == typeVariables.length
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
  }
}
