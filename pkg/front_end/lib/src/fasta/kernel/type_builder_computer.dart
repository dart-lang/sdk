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
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VoidType;

import '../kernel/kernel_builder.dart'
    show
        DynamicTypeBuilder,
        KernelClassBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        VoidTypeBuilder;

import '../loader.dart' show Loader;

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

  KernelTypeBuilder visitFunctionType(FunctionType node) {
    throw "Not implemented";
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
