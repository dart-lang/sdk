// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_class_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        Constructor,
        DartType,
        Expression,
        ExpressionStatement,
        Field,
        FunctionNode,
        InterfaceType,
        ListLiteral,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        StaticGet,
        StringLiteral,
        Supertype,
        Throw,
        VariableDeclaration;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import '../errors.dart' show internalError;

import '../messages.dart' show warning;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

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
  InterfaceType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    assert(arguments == null || cls.typeParameters.length == arguments.length);
    return arguments == null ? cls.rawType : new InterfaceType(cls, arguments);
  }

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    List<DartType> typeArguments = <DartType>[];
    for (KernelTypeBuilder builder in arguments) {
      DartType type = builder.build(library);
      if (type == null) {
        internalError("Bad type: ${builder.runtimeType}");
      }
      typeArguments.add(type);
    }
    return computeDefaultTypeArguments(
        library, cls.typeParameters, typeArguments);
  }

  InterfaceType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    List<DartType> typeArguments;
    if (arguments != null) {
      typeArguments = buildTypeArguments(library, arguments);
    }
    return buildTypesWithBuiltArguments(library, typeArguments);
  }

  Supertype buildSupertype(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    if (arguments != null) {
      return new Supertype(cls, buildTypeArguments(library, arguments));
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

  void checkOverrides(ClassHierarchy hierarchy) {
    hierarchy.forEachOverridePair(cls, checkOverride);
  }

  void checkOverride(
      Member declaredMember, Member interfaceMember, bool isSetter) {
    if (declaredMember is Constructor || interfaceMember is Constructor) {
      internalError(
          "Constructor in override check.", fileUri, declaredMember.fileOffset);
    }
    if (declaredMember is Procedure && interfaceMember is Procedure) {
      if (declaredMember.kind == ProcedureKind.Method &&
          interfaceMember.kind == ProcedureKind.Method) {
        checkMethodOverride(declaredMember, interfaceMember);
        return;
      }
    }
    // TODO(ahe): Handle other cases: accessors, operators, and fields.
  }

  void checkMethodOverride(
      Procedure declaredMember, Procedure interfaceMember) {
    if (declaredMember.enclosingClass != cls) {
      // TODO(ahe): Include these checks as well, but the message needs to
      // explain that [declaredMember] is inherited.
      return;
    }
    assert(declaredMember.kind == ProcedureKind.Method);
    assert(interfaceMember.kind == ProcedureKind.Method);
    FunctionNode declaredFunction = declaredMember.function;
    FunctionNode interfaceFunction = interfaceMember.function;
    if (declaredFunction.typeParameters?.length !=
        interfaceFunction.typeParameters?.length) {
      addWarning(
          declaredMember.fileOffset,
          "Declared type variables of '$name::${declaredMember.name.name}' "
          "doesn't match those on overridden method "
          "'${interfaceMember.enclosingClass.name}::"
          "${interfaceMember.name.name}'.");
    }
    if (declaredFunction.positionalParameters.length <
            interfaceFunction.requiredParameterCount ||
        declaredFunction.positionalParameters.length <
            interfaceFunction.positionalParameters.length) {
      addWarning(
          declaredMember.fileOffset,
          "The method '$name::${declaredMember.name.name}' has fewer "
          "positional arguments than those of overridden method "
          "'${interfaceMember.enclosingClass.name}::"
          "${interfaceMember.name.name}'.");
    }
    if (interfaceFunction.requiredParameterCount <
        declaredFunction.requiredParameterCount) {
      addWarning(
          declaredMember.fileOffset,
          "The method '$name::${declaredMember.name.name}' has more "
          "required arguments than those of overridden method "
          "'${interfaceMember.enclosingClass.name}::"
          "${interfaceMember.name.name}'.");
    }
    if (declaredFunction.namedParameters.isEmpty &&
        interfaceFunction.namedParameters.isEmpty) {
      return;
    }
    if (declaredFunction.namedParameters.length <
        interfaceFunction.namedParameters.length) {
      addWarning(
          declaredMember.fileOffset,
          "The method '$name::${declaredMember.name.name}' has fewer named "
          "arguments than those of overridden method "
          "'${interfaceMember.enclosingClass.name}::"
          "${interfaceMember.name.name}'.");
    }
    Iterator<VariableDeclaration> declaredNamedParameters =
        declaredFunction.namedParameters.iterator;
    Iterator<VariableDeclaration> interfaceNamedParameters =
        interfaceFunction.namedParameters.iterator;
    outer:
    while (declaredNamedParameters.moveNext() &&
        interfaceNamedParameters.moveNext()) {
      while (declaredNamedParameters.current.name !=
          interfaceNamedParameters.current.name) {
        if (!declaredNamedParameters.moveNext()) {
          addWarning(
              declaredMember.fileOffset,
              "The method '$name::${declaredMember.name.name}' doesn't have "
              "the named parameter '${interfaceNamedParameters.current.name}' "
              "of overriden method '${interfaceMember.enclosingClass.name}::"
              "${interfaceMember.name.name}'.");
          break outer;
        }
      }
    }
  }
}
