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

import 'package:expect/expect.dart' show Expect;

import 'package:compiler/src/diagnostics/messages.dart'
    show MessageKind, MessageTemplate;

import 'package:compiler/src/elements/elements.dart' show LibraryElement;

import 'package:compiler/src/null_compiler_output.dart' show NullCompilerOutput;

import 'package:compiler/src/old_to_new_api.dart'
    show LegacyCompilerDiagnostics, LegacyCompilerInput;

Uri sdkRoot = Uri.base.resolve("sdk/");
Uri mock1LibraryUri = sdkRoot.resolve("lib/mock1.dart");
Uri mock2LibraryUri = sdkRoot.resolve("lib/mock2.dart");

class CustomCompiler extends CompilerImpl {
  CustomCompiler(provider, handler, libraryRoot,
      packageRoot, options, environment)
      : super(provider, const NullCompilerOutput(), handler, libraryRoot,
            packageRoot, options, environment);

  Uri lookupLibraryUri(String libraryName) {
    if (libraryName == "m_o_c_k_1") return mock1LibraryUri;
    if (libraryName == "m_o_c_k_2") return mock2LibraryUri;
    return super.lookupLibraryUri(libraryName);
  }
}

main() async {
  Uri packageRoot = Uri.base.resolve(Platform.packageRoot);

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Future wrappedProvider(Uri uri) {
    if (uri == mock1LibraryUri) {
      return provider.readStringFromUri(Uri.parse('memory:mock1.dart'));
    }
    if (uri == mock2LibraryUri) {
      return provider.readStringFromUri(Uri.parse('memory:mock2.dart'));
    }
    return provider.readStringFromUri(uri);
  }

  String expectedMessage = MessageTemplate.TEMPLATES[
          MessageKind.LIBRARY_NOT_FOUND]
      .message({'resolvedUri': 'dart:mock2.dart'}).computeMessage();

  int actualMessageCount = 0;

  wrappedHandler(Uri uri, int begin, int end, String message, kind) {
    if (message == expectedMessage) {
      actualMessageCount++;
    } else {
      return handler(uri, begin, end, message, kind);
    }
  }

  checkLibrary(LibraryElement library) {
    Expect.equals(1, actualMessageCount);
  }

  CompilerImpl compiler = new CustomCompiler(
      new LegacyCompilerInput(wrappedProvider),
      new LegacyCompilerDiagnostics(wrappedHandler),
      sdkRoot,
      packageRoot,
      [],
      {});

  asyncStart();
  await compiler.setupSdk();
  var library =
      await compiler.libraryLoader.loadLibrary(Uri.parse("dart:m_o_c_k_1"));
  await checkLibrary(library);
  asyncSuccess(null);
}

const Map MEMORY_SOURCE_FILES = const {
  "mock1.dart": "library mock1; import 'mock2.dart';",
  "mock2.dart": "library mock2;",
};
