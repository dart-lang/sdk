// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import '../combinator.dart' show
    Combinator;

import '../errors.dart' show
    InputError;

import '../export.dart' show
    Export;

import '../loader.dart' show
    Loader;

import 'builder.dart' show
    Builder,
    InvalidTypeBuilder,
    TypeBuilder;

import 'scope.dart' show
   Scope;

abstract class LibraryBuilder<T extends TypeBuilder, R> extends Builder {
  final List<Export> exporters = <Export>[];

  final List<InputError> compileTimeErrors = <InputError>[];

  LibraryBuilder partOfLibrary;

  Loader get loader;

  Uri get uri;

  Map<String, Builder> get members;

  // TODO(ahe): Move this to SourceLibraryBuilder.
  Scope get scope;

  Map<String, Builder> get exports;

  Builder addBuilder(String name, Builder builder);

  void addExporter(LibraryBuilder exporter, List<Combinator> combinators) {
    exporters.add(new Export(exporter, this, combinators));
  }

  void addCompileTimeError(int charOffset, Object message) {
    InputError error = new InputError(uri, charOffset, message);
    compileTimeErrors.add(error);
    print(error.format());
  }

  bool addToExportScope(String name, Builder member);

  void addToScope(String name, Builder member);

  InvalidTypeBuilder buildAmbiguousBuilder(
      String name, Builder builder, Builder other);

  int finishStaticInvocations() => 0;
}
