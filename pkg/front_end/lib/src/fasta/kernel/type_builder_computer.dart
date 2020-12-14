// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder_computer;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;

import 'package:kernel/ast.dart'
    show
        BottomType,
        Class,
        DartType,
        DartTypeVisitor,
        DynamicType,
        FunctionType,
        FutureOrType,
        InterfaceType,
        InvalidType,
        Library,
        NamedType,
        NeverType,
        NullType,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        Typedef,
        TypedefType,
        VoidType;

import '../builder/class_builder.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/future_or_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/null_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/void_type_declaration_builder.dart';

import '../loader.dart' show Loader;

class TypeBuilderComputer implements DartTypeVisitor<TypeBuilder> {
  final Loader loader;

  const TypeBuilderComputer(this.loader);

  @override
  TypeBuilder defaultDartType(DartType node) {
    throw "Unsupported";
  }

  @override
  TypeBuilder visitInvalidType(InvalidType node) {
    throw "Not implemented";
  }

  @override
  TypeBuilder visitDynamicType(DynamicType node) {
    // 'dynamic' is always nullable.
    return new NamedTypeBuilder(
        "dynamic",
        const NullabilityBuilder.nullable(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(new DynamicTypeDeclarationBuilder(
          const DynamicType(), loader.coreLibrary, -1));
  }

  @override
  TypeBuilder visitVoidType(VoidType node) {
    // 'void' is always nullable.
    return new NamedTypeBuilder(
        "void",
        const NullabilityBuilder.nullable(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(new VoidTypeDeclarationBuilder(
          const VoidType(), loader.coreLibrary, -1));
  }

  @override
  TypeBuilder visitBottomType(BottomType node) {
    throw "Not implemented";
  }

  @override
  TypeBuilder visitNeverType(NeverType node) {
    return new NamedTypeBuilder(
        "Never",
        new NullabilityBuilder.fromNullability(node.nullability),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(new NeverTypeDeclarationBuilder(node, loader.coreLibrary, -1));
  }

  @override
  TypeBuilder visitNullType(NullType node) {
    return new NamedTypeBuilder(
        "Null",
        new NullabilityBuilder.nullable(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(new NullTypeDeclarationBuilder(node, loader.coreLibrary, -1));
  }

  @override
  TypeBuilder visitInterfaceType(InterfaceType node) {
    ClassBuilder cls =
        loader.computeClassBuilderFromTargetClass(node.classNode);
    List<TypeBuilder> arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<TypeBuilder>.filled(kernelArguments.length, null);
      for (int i = 0; i < kernelArguments.length; i++) {
        arguments[i] = kernelArguments[i].accept(this);
      }
    }
    return new NamedTypeBuilder(
        cls.name,
        new NullabilityBuilder.fromNullability(node.nullability),
        arguments,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(cls);
  }

  @override
  TypeBuilder visitFutureOrType(FutureOrType node) {
    TypeBuilder argument = node.typeArgument.accept(this);
    return new NamedTypeBuilder(
        "FutureOr",
        new NullabilityBuilder.fromNullability(node.nullability),
        [argument],
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(new FutureOrTypeDeclarationBuilder(node, loader.coreLibrary, -1));
  }

  @override
  TypeBuilder visitFunctionType(FunctionType node) {
    TypeBuilder returnType = node.returnType.accept(this);
    // We could compute the type variables here. However, the current
    // implementation of [visitTypeParameterType] is sufficient.
    List<TypeVariableBuilder> typeVariables = null;
    List<DartType> positionalParameters = node.positionalParameters;
    List<NamedType> namedParameters = node.namedParameters;
    List<FormalParameterBuilder> formals =
        new List<FormalParameterBuilder>.filled(
            positionalParameters.length + namedParameters.length, null);
    for (int i = 0; i < positionalParameters.length; i++) {
      TypeBuilder type = positionalParameters[i].accept(this);
      FormalParameterKind kind = FormalParameterKind.mandatory;
      if (i >= node.requiredParameterCount) {
        kind = FormalParameterKind.optionalPositional;
      }
      formals[i] = new FormalParameterBuilder(
          /* metadata = */ null,
          /* modifiers = */ 0,
          type,
          /* name = */ null,
          /* compilationUnit = */ null,
          /* charOffset = */ TreeNode.noOffset)
        ..kind = kind;
    }
    for (int i = 0; i < namedParameters.length; i++) {
      NamedType parameter = namedParameters[i];
      TypeBuilder type = parameter.type.accept(this);
      formals[i + positionalParameters.length] = new FormalParameterBuilder(
          /* metadata = */ null,
          /* modifiers = */ 0,
          type,
          parameter.name,
          /* compilationUnit = */ null,
          /* charOffset = */ TreeNode.noOffset)
        ..kind = FormalParameterKind.optionalNamed;
    }
    return new FunctionTypeBuilder(
        returnType,
        typeVariables,
        formals,
        new NullabilityBuilder.fromNullability(node.nullability),
        /* fileUri = */ null,
        /* charOffset = */ TreeNode.noOffset);
  }

  TypeBuilder visitTypeParameterType(TypeParameterType node) {
    TypeParameter parameter = node.parameter;
    TreeNode kernelClassOrTypeDef = parameter.parent;
    Library kernelLibrary;
    if (kernelClassOrTypeDef is Class) {
      kernelLibrary = kernelClassOrTypeDef.enclosingLibrary;
    } else if (kernelClassOrTypeDef is Typedef) {
      kernelLibrary = kernelClassOrTypeDef.enclosingLibrary;
    }
    LibraryBuilder library = loader.builders[kernelLibrary.importUri];
    return new NamedTypeBuilder(
        parameter.name,
        new NullabilityBuilder.fromNullability(node.nullability),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(new TypeVariableBuilder.fromKernel(parameter, library));
  }

  TypeBuilder visitTypedefType(TypedefType node) {
    throw "Not implemented";
  }
}
