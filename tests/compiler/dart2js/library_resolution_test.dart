// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that relative URIs are resolved against the canonical name of a
/// library. This only matters for dart:-libraries, so this test mocks up two
/// dart:-libraries.

import "dart:io";

import "dart:async";

import "memory_source_file_helper.dart";

import "package:async_helper/async_helper.dart";

import 'package:expect/expect.dart' show
    Expect;

import 'package:compiler/src/elements/elements.dart' show
    LibraryElement;

import 'package:compiler/src/dart2jslib.dart' show
    MessageKind;

import 'package:_internal/libraries.dart' show
    DART2JS_PLATFORM,
    LibraryInfo;

const LibraryInfo mock1LibraryInfo = const LibraryInfo(
    "mock1.dart",
    category: "Shared",
    documented: false,
    platforms: DART2JS_PLATFORM);

const LibraryInfo mock2LibraryInfo = const LibraryInfo(
    "mock2.dart",
    category: "Shared",
    documented: false,
    platforms: DART2JS_PLATFORM);

class CustomCompiler extends Compiler {
  final Map<String, LibraryInfo> customLibraryInfo;

  CustomCompiler(
      this.customLibraryInfo,
      provider,
      outputProvider,
      handler,
      libraryRoot,
      packageRoot,
      options,
      environment)
      : super(
          provider,
          outputProvider,
          handler,
          libraryRoot,
          packageRoot,
          options,
          environment);

  LibraryInfo lookupLibraryInfo(String name) {
    if (name == "m_o_c_k_1") return mock1LibraryInfo;
    if (name == "m_o_c_k_2") return mock2LibraryInfo;
    return super.lookupLibraryInfo(name);
  }
}

main() {
  Uri sdkRoot = Uri.base.resolve("sdk/");
  Uri packageRoot = Uri.base.resolve(Platform.packageRoot);

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  outputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }

  Future wrappedProvider(Uri uri) {
    if (uri == sdkRoot.resolve('lib/mock1.dart')) {
      return provider.readStringFromUri(Uri.parse('memory:mock1.dart'));
    }
    if (uri == sdkRoot.resolve('lib/mock2.dart')) {
      return provider.readStringFromUri(Uri.parse('memory:mock2.dart'));
    }
    return provider.readStringFromUri(uri);
  }

  String expectedMessage =
      MessageKind.LIBRARY_NOT_FOUND.message(
          {'resolvedUri': 'dart:mock2.dart'}).computeMessage();

  int actualMessageCount = 0;

  wrappedHandler(
      Uri uri, int begin, int end, String message, kind) {
    if (message == expectedMessage) {
      actualMessageCount++;
    } else {
      return handler(uri, begin, end, message, kind);
    }
  }

  checkLibrary(LibraryElement library) {
    Expect.equals(1, actualMessageCount);
  }

  Compiler compiler = new CustomCompiler(
      {},
      wrappedProvider,
      outputProvider,
      wrappedHandler,
      sdkRoot,
      packageRoot,
      [],
      {});

  asyncStart();
  compiler.libraryLoader.loadLibrary(Uri.parse("dart:m_o_c_k_1"))
      .then(checkLibrary)
      .then(asyncSuccess);
}

const Map MEMORY_SOURCE_FILES = const {
  "mock1.dart": "library mock1; import 'mock2.dart';",
  "mock2.dart": "library mock2;",
};
