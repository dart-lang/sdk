// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_loader;

import 'package:kernel/ast.dart' show Class, Component, DartType, Library;

import '../builder/class_builder.dart';
import '../builder/library_builder.dart';
import '../builder/type_builder.dart';

import '../fasta_codes.dart'
    show SummaryTemplate, Template, templateDillOutlineSummary;

import '../kernel/type_builder_computer.dart' show TypeBuilderComputer;

import '../loader.dart' show Loader;

import '../problems.dart' show unhandled;

import '../source/source_loader.dart' show SourceLoader;

import '../target_implementation.dart' show TargetImplementation;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_target.dart' show DillTarget;

class DillLoader extends Loader {
  SourceLoader currentSourceLoader;

  DillLoader(TargetImplementation target) : super(target);

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateDillOutlineSummary;

  /// Append compiled libraries from the given [component]. If the [filter] is
  /// provided, append only libraries whose [Uri] is accepted by the [filter].
  List<DillLibraryBuilder> appendLibraries(Component component,
      {bool filter(Uri uri), int byteCount: 0}) {
    List<Library> componentLibraries = component.libraries;
    List<Uri> requestedLibraries = <Uri>[];
    List<Uri> requestedLibrariesFileUri = <Uri>[];
    DillTarget target = this.target;
    for (int i = 0; i < componentLibraries.length; i++) {
      Library library = componentLibraries[i];
      Uri uri = library.importUri;
      if (filter == null || filter(library.importUri)) {
        libraries.add(library);
        target.addLibrary(library);
        requestedLibraries.add(uri);
        requestedLibrariesFileUri.add(library.fileUri);
      }
    }
    List<DillLibraryBuilder> result = <DillLibraryBuilder>[];
    for (int i = 0; i < requestedLibraries.length; i++) {
      result.add(read(requestedLibraries[i], -1,
          fileUri: requestedLibrariesFileUri[i]));
    }
    target.uriToSource.addAll(component.uriToSource);
    this.byteCount += byteCount;
    return result;
  }

  /// Append single compiled library.
  ///
  /// Note that as this only takes a library, no new sources is added to the
  /// uriToSource map.
  DillLibraryBuilder appendLibrary(Library library) {
    // Add to list of libraries in the loader, used for e.g. linking.
    libraries.add(library);

    // Weird interaction begins.
    DillTarget target = this.target;
    // Create dill library builder (adds it to a map where it's fetched
    // again momentarily).
    target.addLibrary(library);
    // Set up the dill library builder (fetch it from the map again, add it to
    // another map and setup some auxiliary things).
    return read(library.importUri, -1, fileUri: library.fileUri);
  }

  Future<Null> buildOutline(DillLibraryBuilder builder) async {
    if (builder.library == null) {
      unhandled("null", "builder.library", 0, builder.fileUri);
    }
    builder.markAsReadyToBuild();
  }

  Future<Null> buildBody(DillLibraryBuilder builder) {
    return buildOutline(builder);
  }

  void finalizeExports({bool suppressFinalizationErrors: false}) {
    builders.forEach((Uri uri, LibraryBuilder builder) {
      DillLibraryBuilder library = builder;
      library.markAsReadyToFinalizeExports(
          suppressFinalizationErrors: suppressFinalizationErrors);
    });
  }

  @override
  ClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    Library kernelLibrary = cls.enclosingLibrary;
    LibraryBuilder library = builders[kernelLibrary.importUri];
    if (library == null) {
      library = currentSourceLoader?.builders[kernelLibrary.importUri];
    }
    return library.lookupLocalMember(cls.name, required: true);
  }

  @override
  TypeBuilder computeTypeBuilder(DartType type) {
    return type.accept(new TypeBuilderComputer(this));
  }
}
