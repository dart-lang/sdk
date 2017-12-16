// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_loader;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Library, Program, Source;

import '../fasta_codes.dart'
    show SummaryTemplate, Template, templateDillOutlineSummary;

import '../kernel/kernel_builder.dart' show LibraryBuilder;

import '../loader.dart' show Loader;

import '../problems.dart' show unhandled;

import '../target_implementation.dart' show TargetImplementation;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillLoader extends Loader<Library> {
  /// Source targets are compiled against these binary libraries.
  final libraries = <Library>[];

  /// Sources for all appended programs.
  final Map<Uri, Source> uriToSource = <Uri, Source>{};

  DillLoader(TargetImplementation target) : super(target);

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateDillOutlineSummary;

  /// Append compiled libraries from the given [program]. If the [filter] is
  /// provided, append only libraries whose [Uri] is accepted by the [filter].
  List<DillLibraryBuilder> appendLibraries(Program program,
      {bool filter(Uri uri), int byteCount: 0}) {
    var builders = <DillLibraryBuilder>[];
    for (Library library in program.libraries) {
      if (filter == null || filter(library.importUri)) {
        libraries.add(library);
        DillLibraryBuilder builder = read(library.importUri, -1);
        builder.library = library;
        builders.add(builder);
      }
    }
    uriToSource.addAll(program.uriToSource);
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
}
