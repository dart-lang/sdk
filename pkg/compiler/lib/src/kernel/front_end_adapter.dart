// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper classes and methods to adapt between `package:compiler` and
/// `package:front_end` APIs.
library compiler.kernel.front_end_adapter;

import 'dart:async';

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import '../../compiler.dart' as api;

import '../common.dart';
import '../io/source_file.dart';

/// A front-ends's [FileSystem] that uses dart2js's [api.CompilerInput].
class CompilerFileSystem implements fe.FileSystem {
  final api.CompilerInput inputProvider;

  CompilerFileSystem(this.inputProvider);

  @override
  fe.FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('data')) {
      return fe.DataFileSystemEntity(Uri.base.resolveUri(uri));
    } else {
      return _CompilerFileSystemEntity(uri, this);
    }
  }
}

class _CompilerFileSystemEntity implements fe.FileSystemEntity {
  @override
  final Uri uri;
  final CompilerFileSystem fs;

  _CompilerFileSystemEntity(this.uri, this.fs);

  @override
  Future<String> readAsString() async {
    api.Input input;
    try {
      input = await fs.inputProvider
          .readFromUri(uri, inputKind: api.InputKind.UTF8);
    } catch (e) {
      throw fe.FileSystemException(uri, '$e');
    }
    if (input == null) throw fe.FileSystemException(uri, "File not found");
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
      throw fe.FileSystemException(uri, '$e');
    }
    if (input == null) throw fe.FileSystemException(uri, "File not found");
    return input.data;
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

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

  @override
  Future<bool> existsAsyncIfPossible() => exists();
}

/// Report a [message] received from the front-end, using dart2js's
/// [DiagnosticReporter].
void reportFrontEndMessage(
    DiagnosticReporter reporter, fe.DiagnosticMessage message) {
  Spannable _getSpannable(fe.DiagnosticMessage message) {
    Uri uri = fe.getMessageUri(message);
    int offset = fe.getMessageCharOffset(message);
    int length = fe.getMessageLength(message);
    if (uri != null && offset != -1) {
      return SourceSpan(uri, offset, offset + length);
    } else {
      return NO_LOCATION_SPANNABLE;
    }
  }

  DiagnosticMessage _convertMessage(fe.DiagnosticMessage message) {
    Spannable span = _getSpannable(message);
    String text = fe.getMessageHeaderText(message);
    return reporter.createMessage(span, MessageKind.GENERIC, {'text': text});
  }

  List<fe.DiagnosticMessage> relatedInformation =
      fe.getMessageRelatedInformation(message);
  DiagnosticMessage mainMessage = _convertMessage(message);
  List<DiagnosticMessage> infos = relatedInformation != null
      ? relatedInformation.map(_convertMessage).toList()
      : const [];
  switch (message.severity) {
    case fe.Severity.internalProblem:
      throw mainMessage.message.computeMessage();
    case fe.Severity.error:
      reporter.reportError(mainMessage, infos);
      break;
    case fe.Severity.warning:
      reporter.reportWarning(mainMessage, infos);
      break;
    case fe.Severity.info:
      reporter.reportInfo(mainMessage, infos);
      break;
    default:
      throw UnimplementedError('unhandled severity ${message.severity}');
  }
}
