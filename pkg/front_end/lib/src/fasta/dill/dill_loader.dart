// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_loader;

import 'dart:async' show Future;

import 'dart:io' show File;

import 'package:kernel/kernel.dart' show loadProgramFromBinary;

import 'package:kernel/ast.dart' show Library, Program;

import '../loader.dart' show Loader;

import '../target_implementation.dart' show TargetImplementation;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillLoader extends Loader<Library> {
  Uri input;

  Program program;

  DillLoader(TargetImplementation target) : super(target);

  DillLibraryBuilder read(Uri uri, [Uri fileUri]) => super.read(uri, fileUri);

  Future<Null> buildOutline(DillLibraryBuilder builder) async {
    if (program == null) {
      byteCount = await new File.fromUri(input).length();
      setProgram(await loadProgramFromBinary(input.toFilePath()));
    }
    builder.library.classes.forEach(builder.addClass);
    builder.library.procedures.forEach(builder.addMember);
    builder.library.fields.forEach(builder.addMember);
  }

  Future<Null> buildBody(DillLibraryBuilder builder) {
    return buildOutline(builder);
  }

  void setProgram(Program program) {
    assert(input != null);
    this.program = program;
    program.unbindCanonicalNames();
    for (Library library in program.libraries) {
      read(library.importUri).library = library;
    }
  }
}
