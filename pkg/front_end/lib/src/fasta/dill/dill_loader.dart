// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_loader;

import 'dart:async' show Future;

import 'package:kernel/ast.dart'
    show
        BottomType,
        Class,
        Component,
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

import '../fasta_codes.dart'
    show SummaryTemplate, Template, templateDillOutlineSummary;

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

import '../problems.dart' show unhandled;

import '../target_implementation.dart' show TargetImplementation;

import 'dill_class_builder.dart' show DillClassBuilder;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_target.dart' show DillTarget;

class DillLoader extends Loader<Library> {
  DillLoader(TargetImplementation target) : super(target);

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateDillOutlineSummary;

  /// Append compiled libraries from the given [component]. If the [filter] is
  /// provided, append only libraries whose [Uri] is accepted by the [filter].
  List<DillLibraryBuilder> appendLibraries(Component component,
      {bool filter(Uri uri), int byteCount: 0}) {
    List<Library> componentLibraries = component.libraries;
    List<Uri> requestedLibraries = <Uri>[];
    DillTarget target = this.target;
    for (int i = 0; i < componentLibraries.length; i++) {
      Library library = componentLibraries[i];
      Uri uri = library.importUri;
      if (filter == null || filter(library.importUri)) {
        libraries.add(library);
        target.addLibrary(library);
        requestedLibraries.add(uri);
      }
    }
    List<DillLibraryBuilder> result = <DillLibraryBuilder>[];
    for (int i = 0; i < requestedLibraries.length; i++) {
      result.add(read(requestedLibraries[i], -1));
    }
    target.uriToSource.addAll(component.uriToSource);
    this.byteCount += byteCount;
    return result;
  }

  Future<Null> buildOutline(DillLibraryBuilder builder) async {
    if (builder.library == null) {
      unhandled("null", "builder.library", 0, builder.fileUri);
    }
    builder.library.classes.forEach(builder.addClass);
    builder.library.procedures.forEach(builder.addMember);
    builder.library.typedefs.forEach(builder.addTypedef);
    builder.library.fields.forEach(builder.addMember);
  }

  Future<Null> buildBody(DillLibraryBuilder builder) {
    return buildOutline(builder);
  }

  void finalizeExports() {
    builders.forEach((Uri uri, LibraryBuilder builder) {
      DillLibraryBuilder library = builder;
      library.finalizeExports();
    });
  }

  @override
  KernelClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    Library kernelLibrary = cls.enclosingLibrary;
    LibraryBuilder library = builders[kernelLibrary.importUri];
    return library[cls.name];
  }

  KernelTypeBuilder computeTypeBuilder(DartType type) {
    return type.accept(new TypeBuilderComputer(this));
  }
}

class TypeBuilderComputer implements DartTypeVisitor<KernelTypeBuilder> {
  final DillLoader loader;

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
    DillClassBuilder cls =
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
    DillLibraryBuilder library = loader.builders[kernelLibrary.importUri];
    return new KernelNamedTypeBuilder(parameter.name, null)
      ..bind(new KernelTypeVariableBuilder.fromKernel(parameter, library));
  }

  KernelTypeBuilder visitTypedefType(TypedefType node) {
    throw "Not implemented";
  }
}
