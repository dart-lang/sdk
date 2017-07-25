// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper classes and methods to adapt between `package:compiler` and
/// `package:front_end` APIs.
library compiler.kernel.front_end_adapter;

import 'dart:async';

import 'package:front_end/front_end.dart' as fe;

import '../../compiler_new.dart' as api;

import '../common.dart';
import '../io/source_file.dart';

/// A front-ends's [FileSystem] that uses dart2js's [api.CompilerInput].
class CompilerFileSystem implements fe.FileSystem {
  final api.CompilerInput inputProvider;

  CompilerFileSystem(this.inputProvider);

  @override
  fe.FileSystemEntity entityForUri(Uri uri) =>
      new _CompilerFileSystemEntity(uri, this);
}

class _CompilerFileSystemEntity implements fe.FileSystemEntity {
  final Uri uri;
  final CompilerFileSystem fs;

  _CompilerFileSystemEntity(this.uri, this.fs);

  @override
  Future<String> readAsString() async {
    api.Input input;
    try {
      input = await fs.inputProvider
          .readFromUri(uri, inputKind: api.InputKind.utf8);
    } catch (e) {
      throw new fe.FileSystemException(uri, '$e');
    }
    if (input == null) throw new fe.FileSystemException(uri, "File not found");
    // TODO(sigmund): technically someone could provide dart2js with an input
    // that is not a SourceFile. Note that this assumption is also done in the
    // (non-kernel) ScriptLoader.
    SourceFile file = input as SourceFile;
    return file.slowText();
  }

  @override
  Future<List<int>> readAsBytes() async {
    api.Input input;
    try {
      input = await fs.inputProvider
          .readFromUri(uri, inputKind: api.InputKind.binary);
    } catch (e) {
      throw new fe.FileSystemException(uri, '$e');
    }
    if (input == null) throw new fe.FileSystemException(uri, "File not found");
    return input.data;
  }

  @override
  Future<bool> exists() async {
    try {
      api.Input input = await fs.inputProvider
          .readFromUri(uri, inputKind: api.InputKind.binary);
      return input != null;
    } catch (e) {
      return false;
    }
  }
}

/// Report a [message] received from the front-end, using dart2js's
/// [DiagnosticReporter].
void reportFrontEndMessage(
    DiagnosticReporter reporter, fe.CompilationMessage message) {
  // TODO(sigmund): translate message kinds using message.dart2jsCode
  MessageKind kind = MessageKind.GENERIC;
  switch (message.severity) {
    case fe.Severity.error:
    case fe.Severity.internalProblem:
      reporter.reportErrorMessage(
          NO_LOCATION_SPANNABLE, kind, {'text': message.message});
      break;
    case fe.Severity.warning:
      reporter.reportWarningMessage(
          NO_LOCATION_SPANNABLE, kind, {'text': message.message});
      break;
    case fe.Severity.nit:
      reporter.reportHintMessage(
          NO_LOCATION_SPANNABLE, kind, {'text': message.message});
      break;
    default:
      throw new UnimplementedError('unhandled severity ${message.severity}');
  }
}
