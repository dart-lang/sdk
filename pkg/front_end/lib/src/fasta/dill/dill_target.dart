// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Class;

import 'package:kernel/target/targets.dart' show getTarget;

import '../errors.dart' show internalError;
import '../kernel/kernel_builder.dart' show ClassBuilder;
import '../target_implementation.dart' show TargetImplementation;
import '../ticker.dart' show Ticker;
import '../translate_uri.dart' show TranslateUri;
import 'dill_library_builder.dart' show DillLibraryBuilder;
import 'dill_loader.dart' show DillLoader;

class DillTarget extends TargetImplementation {
  bool isLoaded = false;
  DillLoader loader;

  DillTarget(
      Ticker ticker, TranslateUri uriTranslator, String backendTargetName)
      : super(ticker, uriTranslator, getTarget(backendTargetName, null)) {
    loader = new DillLoader(this);
  }

  void addSourceInformation(
      Uri uri, List<int> lineStarts, List<int> sourceCode) {
    internalError("Unsupported operation.");
  }

  void read(Uri uri) {
    internalError("Unsupported operation.");
  }

  @override
  Future<Null> buildProgram() {
    return internalError("not implemented.");
  }

  @override
  Future<Null> buildOutlines() async {
    if (loader.libraries.isNotEmpty) {
      await loader.buildOutlines();
    }
    isLoaded = true;
  }

  DillLibraryBuilder createLibraryBuilder(Uri uri, Uri fileUri) {
    return new DillLibraryBuilder(uri, loader);
  }

  void addDirectSupertype(ClassBuilder cls, Set<ClassBuilder> set) {}

  List<ClassBuilder> collectAllClasses() {
    return null;
  }

  void breakCycle(ClassBuilder cls) {}

  Class get objectClass => loader.coreLibrary["Object"].target;
}
