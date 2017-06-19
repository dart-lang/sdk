// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that relative URIs are resolved against the canonical name of a
/// library. This only matters for dart:-libraries, so this test mocks up two
/// dart:-libraries.

import "dart:async";

import "memory_source_file_helper.dart";

import "package:async_helper/async_helper.dart";

import 'package:expect/expect.dart' show Expect;

import 'package:compiler/compiler_new.dart';

import 'package:compiler/src/diagnostics/messages.dart'
    show MessageKind, MessageTemplate;

import 'package:compiler/src/library_loader.dart' show LoadedLibraries;

import 'package:compiler/src/null_compiler_output.dart' show NullCompilerOutput;

import 'package:compiler/src/old_to_new_api.dart'
    show LegacyCompilerDiagnostics, LegacyCompilerInput;
import 'package:compiler/src/options.dart' show CompilerOptions;

Uri sdkRoot = Uri.base.resolve("sdk/");
Uri mock1LibraryUri = sdkRoot.resolve("lib/mock1.dart");
Uri mock2LibraryUri = sdkRoot.resolve("lib/mock2.dart");

class CustomCompiler extends CompilerImpl {
  CustomCompiler(provider, handler, libraryRoot, packageConfig)
      : super(
            provider,
            const NullCompilerOutput(),
            handler,
            new CompilerOptions(
                libraryRoot: libraryRoot, packageConfig: packageConfig));
}

main() async {
  Uri packageConfig = Uri.base.resolve('.packages');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Future wrappedProvider(Uri uri) async {
    if (uri == mock1LibraryUri) {
      uri = Uri.parse('memory:mock1.dart');
    }
    if (uri == mock2LibraryUri) {
      uri = Uri.parse('memory:mock2.dart');
    }
    Input input = await provider.readBytesFromUri(uri, InputKind.utf8);
    return input.data;
  }

  String expectedMessage = MessageTemplate
      .TEMPLATES[MessageKind.LIBRARY_NOT_FOUND]
      .message({'resolvedUri': 'dart:mock2.dart'}).computeMessage();

  int actualMessageCount = 0;

  wrappedHandler(Uri uri, int begin, int end, String message, kind) {
    if (message == expectedMessage) {
      actualMessageCount++;
    } else {
      return handler(uri, begin, end, message, kind);
    }
  }

  checkLibraries(LoadedLibraries libraries) {
    Expect.equals(1, actualMessageCount);
  }

  CompilerImpl compiler = new CustomCompiler(
      new LegacyCompilerInput(wrappedProvider),
      new LegacyCompilerDiagnostics(wrappedHandler),
      sdkRoot,
      packageConfig);

  asyncStart();
  await compiler.setupSdk();
  // TODO(het): Find cleaner way to do this
  compiler.resolvedUriTranslator.sdkLibraries['m_o_c_k_1'] = mock1LibraryUri;
  compiler.resolvedUriTranslator.sdkLibraries['m_o_c_k_2'] = mock2LibraryUri;
  var libraries =
      await compiler.libraryLoader.loadLibrary(Uri.parse("dart:m_o_c_k_1"));
  await checkLibraries(libraries);
  asyncSuccess(null);
}

const Map MEMORY_SOURCE_FILES = const {
  "mock1.dart": "library mock1; import 'mock2.dart';",
  "mock2.dart": "library mock2;",
};
