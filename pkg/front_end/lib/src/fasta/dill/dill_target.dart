// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Class;

import 'dill_loader.dart' show DillLoader;

import '../errors.dart' show inputError, internalError;

import '../target_implementation.dart' show TargetImplementation;

import '../ticker.dart' show Ticker;

import '../translate_uri.dart' show TranslateUri;

import '../kernel/kernel_builder.dart' show ClassBuilder, KernelClassBuilder;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillTarget extends TargetImplementation {
  bool isLoaded = false;
  DillLoader loader;

  DillTarget(Ticker ticker, TranslateUri uriTranslator)
      : super(ticker, uriTranslator) {
    loader = new DillLoader(this);
  }

  void addSourceInformation(
      Uri uri, List<int> lineStarts, List<int> sourceCode) {
    internalError("Unsupported operation.");
  }

  void read(Uri uri) {
    if (loader.input == null) {
      loader.input = uri;
    } else {
      inputError(uri, -1, "Can only read one dill file.");
    }
  }

  Future<Null> writeProgram(Uri uri) {
    return internalError("not implemented.");
  }

  Future<Null> writeOutline(Uri uri) async {
    if (loader.input == null) return null;
    await loader.buildOutlines();
    isLoaded = true;
    return null;
  }

  DillLibraryBuilder createLibraryBuilder(Uri uri, Uri fileUri) {
    return new DillLibraryBuilder(uri, loader);
  }

  void addDirectSupertype(ClassBuilder cls, Set<ClassBuilder> set) {}

  List<ClassBuilder> collectAllClasses() {
    return null;
  }

  void breakCycle(ClassBuilder cls) {}

  Class get objectClass {
    KernelClassBuilder builder = loader.coreLibrary.exports["Object"];
    return builder.cls;
  }
}
