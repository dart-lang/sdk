// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder_computer;

import 'package:kernel/ast.dart'
    show
        BottomType,
        Class,
        DartType,
        DartTypeVisitor,
        DynamicType,
        FunctionType,
        InterfaceType,
        InvalidType,
        Library,
        NamedType,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VoidType;

import '../kernel/kernel_builder.dart'
    show
        DynamicTypeBuilder,
        KernelClassBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionTypeBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        VoidTypeBuilder;

import '../loader.dart' show Loader;

import '../parser.dart' show FormalParameterKind;

class TypeBuilderComputer implements DartTypeVisitor<KernelTypeBuilder> {
  final Loader<Library> loader;

  const TypeBuilderComputer(this.loader);

  KernelTypeBuilder defaultDartType(DartType node) {
    throw "Unsupported";
  }

  KernelTypeBuilder visitInvalidType(InvalidType node) {
    throw "Not implemented";
  }

  KernelTypeBuilder visitDynamicType(DynamicType node) {
    return new KernelNamedTypeBuilder("dynamic", null)
      ..bind(new DynamicTypeBuilder<KernelTypeBuilder, DartType>(
          const DynamicType(), loader.coreLibrary, -1));
  }

  KernelTypeBuilder visitVoidType(VoidType node) {
    return new KernelNamedTypeBuilder("void", null)
      ..bind(new VoidTypeBuilder<KernelTypeBuilder, VoidType>(
          const VoidType(), loader.coreLibrary, -1));
  }

  KernelTypeBuilder visitBottomType(BottomType node) {
    throw "Not implemented";
  }

  KernelTypeBuilder visitInterfaceType(InterfaceType node) {
    KernelClassBuilder cls =
        loader.computeClassBuilderFromTargetClass(node.classNode);
    List<KernelTypeBuilder> arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<KernelTypeBuilder>(kernelArguments.length);
      for (int i = 0; i < kernelArguments.length; i++) {
        arguments[i] = kernelArguments[i].accept(this);
      }
    }
    return new KernelNamedTypeBuilder(cls.name, arguments)..bind(cls);
  }

  @override
  KernelTypeBuilder visitFunctionType(FunctionType node) {
    KernelTypeBuilder returnType = node.returnType.accept(this);
    // We could compute the type variables here. However, the current
    // implementation of [visitTypeParameterType] is suffient.
    List<KernelTypeVariableBuilder> typeVariables = null;
    List<DartType> positionalParameters = node.positionalParameters;
    List<NamedType> namedParameters = node.namedParameters;
    List<KernelFormalParameterBuilder> formals =
        new List<KernelFormalParameterBuilder>(
            positionalParameters.length + namedParameters.length);
    for (int i = 0; i < positionalParameters.length; i++) {
      KernelTypeBuilder type = positionalParameters[i].accept(this);
      FormalParameterKind kind = FormalParameterKind.mandatory;
      if (i >= node.requiredParameterCount) {
        kind = FormalParameterKind.optionalPositional;
      }
      formals[i] =
          new KernelFormalParameterBuilder(null, 0, type, null, null, -1)
            ..kind = kind;
    }
    for (int i = 0; i < namedParameters.length; i++) {
      NamedType parameter = namedParameters[i];
      KernelTypeBuilder type = positionalParameters[i].accept(this);
      formals[i + positionalParameters.length] =
          new KernelFormalParameterBuilder(
              null, 0, type, parameter.name, null, -1)
            ..kind = FormalParameterKind.optionalNamed;
    }

    return new KernelFunctionTypeBuilder(returnType, typeVariables, formals);
  }

  KernelTypeBuilder visitTypeParameterType(TypeParameterType node) {
    TypeParameter parameter = node.parameter;
    Class kernelClass = parameter.parent;
    Library kernelLibrary = kernelClass.enclosingLibrary;
    LibraryBuilder<KernelTypeBuilder, Library> library =
        loader.builders[kernelLibrary.importUri];
    return new KernelNamedTypeBuilder(parameter.name, null)
      ..bind(new KernelTypeVariableBuilder.fromKernel(parameter, library));
  }

  KernelTypeBuilder visitTypedefType(TypedefType node) {
    throw "Not implemented";
  }
}
