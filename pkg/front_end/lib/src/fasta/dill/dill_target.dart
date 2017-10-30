// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Class;

import 'package:kernel/target/targets.dart' show Target;

import '../kernel/kernel_builder.dart' show ClassBuilder;

import '../problems.dart' show unsupported;

import '../target_implementation.dart' show TargetImplementation;

import '../ticker.dart' show Ticker;

import '../uri_translator.dart' show UriTranslator;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_loader.dart' show DillLoader;

class DillTarget extends TargetImplementation {
  bool isLoaded = false;
  DillLoader loader;

  DillTarget(Ticker ticker, UriTranslator uriTranslator, Target backendTarget)
      : super(ticker, uriTranslator, backendTarget) {
    loader = new DillLoader(this);
  }

  void addSourceInformation(
      Uri uri, List<int> lineStarts, List<int> sourceCode) {
    unsupported("addSourceInformation", -1, null);
  }

  void read(Uri uri) {
    unsupported("read", -1, null);
  }

  @override
  Future<Null> buildProgram() {
    return new Future<Null>.sync(() => unsupported("buildProgram", -1, null));
  }

  @override
  Future<Null> buildOutlines() async {
    if (loader.libraries.isNotEmpty) {
      await loader.buildOutlines();
      loader.finalizeExports();
    }
    isLoaded = true;
  }

  DillLibraryBuilder createLibraryBuilder(Uri uri, Uri fileUri, origin) {
    assert(origin == null);
    return new DillLibraryBuilder(uri, loader);
  }

  void addDirectSupertype(ClassBuilder cls, Set<ClassBuilder> set) {}

  List<ClassBuilder> collectAllClasses() {
    return null;
  }

  void breakCycle(ClassBuilder cls) {}

  Class get objectClass => loader.coreLibrary["Object"].target;
}
