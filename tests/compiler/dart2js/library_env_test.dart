// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that 'dart:' libraries have their corresponding dart.library.X
/// environment variable set.

import "dart:io";

import "dart:async";

import "memory_source_file_helper.dart";

import "package:async_helper/async_helper.dart";

import 'package:expect/expect.dart' show
    Expect;

import 'package:compiler/src/elements/elements.dart' show
    LibraryElement;

import 'package:compiler/src/null_compiler_output.dart' show
    NullCompilerOutput;

import 'package:compiler/compiler_new.dart' show
    CompilerInput,
    CompilerDiagnostics;

import 'package:sdk_library_metadata/libraries.dart' show
    DART2JS_PLATFORM,
    LibraryInfo;

const LibraryInfo mock1LibraryInfo = const LibraryInfo(
    "mock1.dart",
    category: "Client",
    documented: false,
    platforms: DART2JS_PLATFORM);

const LibraryInfo mock2LibraryInfo = const LibraryInfo(
    "mock2.dart",
    category: "Server",
    documented: false,
    platforms: DART2JS_PLATFORM);

const LibraryInfo mock3LibraryInfo = const LibraryInfo(
    "mock3.dart",
    category: "Shared",
    documented: false,
    platforms: DART2JS_PLATFORM);

class DummyCompilerInput implements CompilerInput {
  const DummyCompilerInput();

  readFromUri(uri) {
    throw "should not be needed";
  }
}

class DummyCompilerDiagnostics implements CompilerDiagnostics {
  const DummyCompilerDiagnostics();

  report(code, uri, begin, end, text, kind) {
    throw "should not be needed";
  }
}

class CustomCompiler extends Compiler {
  CustomCompiler(
      options,
      environment)
      : super(
          const DummyCompilerInput(),
          const NullCompilerOutput(),
          const DummyCompilerDiagnostics(),
          Uri.base.resolve("sdk/"),
          null,
          options,
          environment);

  LibraryInfo lookupLibraryInfo(String name) {
    if (name == "mock.client") return mock1LibraryInfo;
    if (name == "mock.server") return mock2LibraryInfo;
    if (name == "mock.shared") return mock3LibraryInfo;
    return super.lookupLibraryInfo(name);
  }
}

main() {
  Compiler compiler = new CustomCompiler(
      [],
      {});

  // Core libraries are always present.
  Expect.equals("true", compiler.fromEnvironment("dart.library.collection"));
  // Non-existing entries in the environment return 'null'.
  Expect.isNull(compiler.fromEnvironment("not in env"));
  // Check for client libraries (default if there are no flags to the compiler).
  Expect.equals("true", compiler.fromEnvironment("dart.library.mock.client"));
  Expect.equals("true", compiler.fromEnvironment("dart.library.html"));
  // Check for shared libraries..
  Expect.equals("true", compiler.fromEnvironment("dart.library.mock.shared"));
  // Check server libraries are not present.
  Expect.equals(null, compiler.fromEnvironment("dart.library.mock.server"));
  Expect.equals(null, compiler.fromEnvironment("dart.library.io"));

  compiler = new CustomCompiler(
      ['--categories=Server'],
      {});

  // Core libraries are always present.
  Expect.equals("true", compiler.fromEnvironment("dart.library.collection"));
  // Non-existing entries in the environment return 'null'.
  Expect.isNull(compiler.fromEnvironment("not in env"));
  // Check client libraries are not present.
  Expect.equals(null, compiler.fromEnvironment("dart.library.mock.client"));
  Expect.equals(null, compiler.fromEnvironment("dart.library.html"));
  // Check for shared libraries..
  Expect.equals("true", compiler.fromEnvironment("dart.library.mock.shared"));
  // Check for server libraries.
  Expect.equals("true", compiler.fromEnvironment("dart.library.mock.server"));
  Expect.equals("true", compiler.fromEnvironment("dart.library.io"));

  // Check that user-defined env-variables win.
  compiler = new CustomCompiler(
      [],
      {'dart.library.collection': "false",
       'dart.library.mock.client': "foo"});
  Expect.equals("false", compiler.fromEnvironment("dart.library.collection"));
  Expect.equals("foo", compiler.fromEnvironment("dart.library.mock.client"));
}
