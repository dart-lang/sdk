// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_cli/src/options.dart';

class MockAnalysisError implements AnalysisError {
  @override
  MockSource source;

  @override
  MockErrorCode errorCode;

  @override
  int offset;

  @override
  String message;

  @override
  int length = 3;

  MockAnalysisError(this.source, this.errorCode, this.offset, this.message);

  @override
  List<DiagnosticMessage> get contextMessages => const [];

  @override
  String? get correction => null;

  @override
  String? get correctionMessage => null;

  @override
  Object? get data => throw UnimplementedError();

  @override
  DiagnosticMessage get problemMessage => DiagnosticMessageImpl(
      filePath: source.fullName,
      length: length,
      message: message,
      offset: offset,
      url: null);

  @override
  Severity get severity => Severity.error;
}

class MockAnalysisErrorInfo implements AnalysisErrorInfo {
  @override
  LineInfo lineInfo;

  @override
  List<AnalysisError> errors;

  MockAnalysisErrorInfo(this.lineInfo, this.errors);
}

class MockCommandLineOptions implements CommandLineOptions {
  bool enableTypeChecks = false;
  @override
  bool jsonFormat = false;
  @override
  bool machineFormat = false;
  @override
  bool verbose = false;
  @override
  bool color = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockErrorCode implements ErrorCode {
  @override
  ErrorType type;

  @override
  ErrorSeverity errorSeverity;

  @override
  String name;

  @override
  String? url;

  MockErrorCode(this.type, this.errorSeverity, this.name);

  @override
  String get correctionMessage {
    throw StateError('Unexpected invocation of correction');
  }

  @override
  bool get hasPublishedDocs => false;

  @override
  bool get isIgnorable => true;

  @override
  bool get isUnresolvedIdentifier => false;

  @override
  String get problemMessage {
    throw StateError('Unexpected invocation of message');
  }

  @override
  String get uniqueName {
    throw StateError('Unexpected invocation of uniqueName');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLineInfo implements LineInfo {
  CharacterLocation? defaultLocation;

  MockLineInfo({this.defaultLocation});

  @override
  int get lineCount {
    throw StateError('Unexpected invocation of lineCount');
  }

  @override
  List<int> get lineStarts {
    throw StateError('Unexpected invocation of lineStarts');
  }

  @override
  CharacterLocation getLocation(int offset) {
    if (defaultLocation != null) {
      return defaultLocation!;
    }
    throw StateError('Unexpected invocation of getLocation');
  }

  @override
  int getOffsetOfLine(int lineNumber) {
    throw StateError('Unexpected invocation of getOffsetOfLine');
  }

  @override
  int getOffsetOfLineAfter(int offset) {
    throw StateError('Unexpected invocation of getOffsetOfLineAfter');
  }
}

class MockSource implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  MockSource(this.fullName, this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
