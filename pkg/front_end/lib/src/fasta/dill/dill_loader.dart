// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_loader;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Library, Program;

import '../loader.dart' show Loader;
import '../target_implementation.dart' show TargetImplementation;
import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillLoader extends Loader<Library> {
  /// Source targets are compiled against these binary libraries.
  final libraries = <Library>[];

  DillLoader(TargetImplementation target) : super(target);

  /// Append compiled libraries from the given [program]. If the [filter] is
  /// provided, append only libraries whose [Uri] is accepted by the [filter].
  void appendLibraries(Program program, [bool filter(Uri uri)]) {
    for (Library library in program.libraries) {
      if (filter == null || filter(library.importUri)) {
        libraries.add(library);
        read(library.importUri).library = library;
      }
    }
  }

  Future<Null> buildBody(DillLibraryBuilder builder) {
    return buildOutline(builder);
  }

  Future<Null> buildOutline(DillLibraryBuilder builder) async {
    builder.library.classes.forEach(builder.addClass);
    builder.library.procedures.forEach(builder.addMember);
    builder.library.typedefs.forEach(builder.addTypedef);
    builder.library.fields.forEach(builder.addMember);
  }

  DillLibraryBuilder read(Uri uri, [Uri fileUri]) => super.read(uri, fileUri);
}
