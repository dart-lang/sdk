// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_class_builder;

import 'package:kernel/ast.dart' show
    Class,
    DartType,
    ExpressionStatement,
    InterfaceType,
    Member,
    StringLiteral,
    Supertype,
    Throw;

import '../errors.dart' show
    internalError;

import 'kernel_builder.dart' show
    Builder,
    ClassBuilder,
    ConstructorReferenceBuilder,
    KernelProcedureBuilder,
    KernelTypeBuilder,
    LibraryBuilder,
    MetadataBuilder,
    ProcedureBuilder,
    TypeVariableBuilder,
    computeDefaultTypeArguments;

import 'redirecting_factory_body.dart' show
    RedirectingFactoryBody;

abstract class KernelClassBuilder
    extends ClassBuilder<KernelTypeBuilder, InterfaceType> {
  KernelClassBuilder(
      List<MetadataBuilder> metadata, int modifiers,
      String name, List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype, List<KernelTypeBuilder> interfaces,
      Map<String, Builder> members, List<KernelTypeBuilder> types,
      LibraryBuilder parent)
      : super(metadata, modifiers, name, typeVariables, supertype, interfaces,
          members, types, parent);

  Class get cls;

  Class get target => cls;

  /// [arguments] have already been built.
  InterfaceType buildTypesWithBuiltArguments(List<DartType> arguments) {
    return arguments == null
        ? cls.rawType
        : new InterfaceType(cls,
            // TODO(ahe): Not sure what to do if `arguments.length !=
            // cls.typeParameters.length`.
            computeDefaultTypeArguments(cls.typeParameters, arguments));
  }

  InterfaceType buildType(List<KernelTypeBuilder> arguments) {
    List<DartType> typeArguments;
    if (arguments != null) {
      typeArguments = <DartType>[];
      for (KernelTypeBuilder builder in arguments) {
        DartType type = builder.build();
        if (type == null) {
          internalError("Bad type: ${builder.runtimeType}");
        }
        typeArguments.add(type);
      }
    }
    return buildTypesWithBuiltArguments(typeArguments);
  }

  Supertype buildSupertype(List<KernelTypeBuilder> arguments) {
    List<DartType> typeArguments;
    if (arguments != null) {
      typeArguments = <DartType>[];
      for (KernelTypeBuilder builder in arguments) {
        DartType type = builder.build();
        if (type == null) {
          internalError("Bad type: ${builder.runtimeType}");
        }
        typeArguments.add(type);
      }
      return new Supertype(cls, typeArguments);
    } else {
      return cls.asRawSupertype;
    }
  }

  int resolveConstructors(LibraryBuilder library) {
    int count = super.resolveConstructors(library);
    if (count != 0) {
      members.forEach((String name, Builder builder) {
        if (builder is KernelProcedureBuilder && builder.isFactory) {
          // Compute the immediate redirection target, not the effective.
          ConstructorReferenceBuilder redirectionTarget =
              builder.redirectionTarget;
          if (redirectionTarget != null) {
            assert(builder.actualBody == null);
            Builder targetBuilder = redirectionTarget.target;
            if (targetBuilder is ProcedureBuilder) {
              Member target = targetBuilder.target;
              builder.body = new RedirectingFactoryBody(target);
            } else {
              // TODO(ahe): Throw NSM error. This requires access to core
              // types.
              String message =
                  "Missing constructor: ${redirectionTarget.fullNameForErrors}";
              print(message);
              builder.body = new ExpressionStatement(
                  new Throw(new StringLiteral(message)));
            }
          }
        }
      });
    }
    return count;
  }
}
