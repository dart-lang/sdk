// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/utilities/package_config_file_builder.dart';

/// A common interface that can be implemented by a set of base classes to
/// allow tests to be written to run in different configurations
/// (LSP and LSP-over-Legacy, and in-process and out-of-process).
///
/// Implementations should use the appropriate APIs for the given server, for
/// example a test running against LSP will send a `textDocument/didOpen`
/// notification from [openFile] whereas when using the legacy server (even for
/// LSP-over-Legacy tests) will send an `analysis.updateContent` request.
abstract interface class SharedTestInterface {
  /// A future that completes when the current analysis completes.
  ///
  /// If there is no analysis in progress, completes immediately.
  Future<void> get currentAnalysis;

  /// Sets whether the test should fail if error diagnostics are generated.
  ///
  /// This is used to avoid accidentally including invalid code in tests but can
  /// be overridden for tests that are deliberately testing invalid code.
  set failTestOnErrorDiagnostic(bool value);

  /// Gets the full normalized path of the test project folder.
  String get projectFolderPath;

  /// Gets the full normalized file path of the `pubspec.yaml` in the test
  /// project.
  String get pubspecFilePath;

  /// Gets a file:/// URI for [pubspecFilePath].
  Uri get pubspecFileUri;

  /// Gets the full normalized file path of a file named "test.dart" in the test
  /// project.
  String get testFilePath;

  /// Gets a file:/// URI for [testFilePath];
  Uri get testFileUri;

  /// The name of the test package (and the folder where the package lives).
  ///
  /// For legacy tests, this is currently 'test' but for LSP it is 'my_project'
  /// because using 'test' in the path triggers some different behaviour (for
  /// example in snippets that are different for test folders).
  String get testPackageName;

  /// Tells the server that file with [uri] has been closed and any overlay
  /// should be removed.
  Future<void> closeFile(Uri uri);

  /// Creates a file at [filePath] with the given [content].
  void createFile(String filePath, String content);

  /// Performs standard initialization of the server, including starting
  /// the server (an external process for integration tests) and sending any
  /// initialization/analysis roots, and waiting for initial analysis to
  /// complete.
  Future<void> initializeServer();

  /// Tells the server that the file with [uri] has been opened and has the
  /// given [content].
  Future<void> openFile(Uri uri, String content, {int version = 1});

  /// Tells the server that the file with [uri] has had it's content replaced
  /// with [content].
  Future<void> replaceFile(int newVersion, Uri uri, String content);

  FutureOr<void> setUp();

  /// Writes a package_config.json for the package under test (considered
  /// 'package:test').
  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
    bool pedantic = false,
  });
}
