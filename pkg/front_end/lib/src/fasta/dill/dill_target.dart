// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Library;

import 'package:kernel/target/targets.dart' show Target;

import '../kernel/kernel_builder.dart' show ClassBuilder;

import '../problems.dart' show unsupported;

import '../target_implementation.dart' show TargetImplementation;

import '../ticker.dart' show Ticker;

import '../uri_translator.dart' show UriTranslator;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_loader.dart' show DillLoader;

class DillTarget extends TargetImplementation {
  final Map<Uri, DillLibraryBuilder> libraryBuilders =
      <Uri, DillLibraryBuilder>{};

  bool isLoaded = false;

  DillLoader loader;

  DillTarget(Ticker ticker, UriTranslator uriTranslator, Target backendTarget)
      : super(ticker, uriTranslator, backendTarget) {
    loader = new DillLoader(this);
  }

  @override
  void addSourceInformation(
      Uri importUri, Uri fileUri, List<int> lineStarts, List<int> sourceCode) {
    unsupported("addSourceInformation", -1, null);
  }

  @override
  Future<Null> buildComponent() {
    return new Future<Null>.sync(() => unsupported("buildComponent", -1, null));
  }

  @override
  Future<Null> buildOutlines() async {
    if (loader.libraries.isNotEmpty) {
      await loader.buildOutlines();
      loader.finalizeExports();
    }
    isLoaded = true;
  }

  @override
  DillLibraryBuilder createLibraryBuilder(Uri uri, Uri fileUri, origin) {
    assert(origin == null);
    return libraryBuilders.remove(uri);
  }

  @override
  void breakCycle(ClassBuilder cls) {}

  void addLibrary(Library library) {
    libraryBuilders[library.importUri] =
        new DillLibraryBuilder(library, loader);
  }
}
