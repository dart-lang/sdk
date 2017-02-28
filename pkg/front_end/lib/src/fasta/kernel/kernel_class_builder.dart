// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_class_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        Expression,
        ExpressionStatement,
        Field,
        InterfaceType,
        ListLiteral,
        Member,
        Name,
        StaticGet,
        StringLiteral,
        Supertype,
        Throw;

import '../errors.dart' show internalError;

import '../messages.dart' show warning;

import 'kernel_builder.dart'
    show
        Builder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        KernelLibraryBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder,
        ProcedureBuilder,
        TypeVariableBuilder,
        computeDefaultTypeArguments;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

abstract class KernelClassBuilder
    extends ClassBuilder<KernelTypeBuilder, InterfaceType> {
  KernelClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      Map<String, Builder> members,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            members, parent, charOffset);

  Class get cls;

  Class get target => cls;

  /// [arguments] have already been built.
  InterfaceType buildTypesWithBuiltArguments(List<DartType> arguments) {
    return arguments == null
        ? cls.rawType
        : new InterfaceType(
            cls,
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

  int resolveConstructors(KernelLibraryBuilder library) {
    int count = super.resolveConstructors(library);
    if (count != 0) {
      // Copy keys to avoid concurrent modification error.
      List<String> names = members.keys.toList();
      for (String name in names) {
        Builder builder = members[name];
        if (builder is KernelProcedureBuilder && builder.isFactory) {
          // Compute the immediate redirection target, not the effective.
          ConstructorReferenceBuilder redirectionTarget =
              builder.redirectionTarget;
          if (redirectionTarget != null) {
            assert(builder.actualBody == null);
            Builder targetBuilder = redirectionTarget.target;
            addRedirectingConstructor(builder, library);
            if (targetBuilder is ProcedureBuilder) {
              Member target = targetBuilder.target;
              builder.body = new RedirectingFactoryBody(target);
            } else if (targetBuilder is DillMemberBuilder) {
              builder.body = new RedirectingFactoryBody(targetBuilder.member);
            } else {
              // TODO(ahe): Throw NSM error. This requires access to core
              // types.
              String message = "Redirection constructor target not found: "
                  "${redirectionTarget.fullNameForErrors}";
              warning(library.fileUri, -1, message);
              builder.body = new ExpressionStatement(
                  new Throw(new StringLiteral(message)));
            }
          }
        }
      }
    }
    return count;
  }

  void addRedirectingConstructor(
      KernelProcedureBuilder constructor, KernelLibraryBuilder library) {
    // Add a new synthetic field to this class for representing factory
    // constructors. This is used to support resolving such constructors in
    // source code.
    //
    // The synthetic field looks like this:
    //
    //     final _redirecting# = [c1, ..., cn];
    //
    // Where each c1 ... cn are an instance of [StaticGet] whose target is
    // [constructor.target].
    //
    // TODO(ahe): Generate the correct factory body instead.
    DillMemberBuilder constructorsField =
        members.putIfAbsent("_redirecting#", () {
      ListLiteral literal = new ListLiteral(<Expression>[]);
      Name name = new Name("_redirecting#", library.library);
      Field field = new Field(name,
          isStatic: true,
          initializer: literal,
          fileUri: cls.fileUri)..fileOffset = cls.fileOffset;
      cls.addMember(field);
      return new DillMemberBuilder(field, this);
    });
    Field field = constructorsField.target;
    ListLiteral literal = field.initializer;
    literal.expressions
        .add(new StaticGet(constructor.target)..parent = literal);
  }
}
