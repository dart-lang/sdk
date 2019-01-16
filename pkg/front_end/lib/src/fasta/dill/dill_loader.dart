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
        Source,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VoidType;

import '../fasta_codes.dart'
    show SummaryTemplate, Template, templateDillOutlineSummary;

import '../compiler_context.dart' show CompilerContext;

import '../kernel/kernel_builder.dart'
    show
        DynamicTypeBuilder,
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

class DillLoader extends Loader<Library> {
  /// Source targets are compiled against these binary libraries.
  final libraries = <Library>[];

  /// Sources for all appended components.
  final Map<Uri, Source> uriToSource;

  DillLoader(TargetImplementation target)
      : uriToSource = CompilerContext.current.uriToSource,
        super(target);

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateDillOutlineSummary;

  /// Append compiled libraries from the given [component]. If the [filter] is
  /// provided, append only libraries whose [Uri] is accepted by the [filter].
  List<DillLibraryBuilder> appendLibraries(Component component,
      {bool filter(Uri uri), int byteCount: 0}) {
    var builders = <DillLibraryBuilder>[];
    for (Library library in component.libraries) {
      if (filter == null || filter(library.importUri)) {
        libraries.add(library);
        DillLibraryBuilder builder = read(library.importUri, -1);
        builder.library = library;
        builders.add(builder);
      }
    }
    uriToSource.addAll(component.uriToSource);
    this.byteCount += byteCount;
    return builders;
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
    return new KernelNamedTypeBuilder("dynamic", null)
      ..bind(new VoidTypeBuilder<KernelTypeBuilder, VoidType>(
          const VoidType(), loader.coreLibrary, -1));
  }

  KernelTypeBuilder visitBottomType(BottomType node) {
    throw "Not implemented";
  }

  KernelTypeBuilder visitInterfaceType(InterfaceType node) {
    Class kernelClass = node.classNode;
    Library kernelLibrary = kernelClass.enclosingLibrary;
    DillLibraryBuilder library = loader.builders[kernelLibrary.importUri];
    String name = kernelClass.name;
    DillClassBuilder cls = library[name];
    List<KernelTypeBuilder> arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<KernelTypeBuilder>(kernelArguments.length);
      for (int i = 0; i < kernelArguments.length; i++) {
        arguments[i] = kernelArguments[i].accept(this);
      }
    }
    return new KernelNamedTypeBuilder(name, arguments)..bind(cls);
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
