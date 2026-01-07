// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/diagnostic/diagnostic_message.dart';
import 'package:analyzer_cli/src/options.dart';

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

class MockDiagnostic implements Diagnostic {
  @override
  MockSource source;

  @override
  MockErrorCode diagnosticCode;

  @override
  int offset;

  @override
  String message;

  @override
  int length = 3;

  MockDiagnostic(this.source, this.diagnosticCode, this.offset, this.message);

  @override
  List<DiagnosticMessage> get contextMessages => const [];

  @override
  String? get correction => null;

  @override
  String? get correctionMessage => null;

  @override
  MockErrorCode get errorCode => diagnosticCode;

  @override
  DiagnosticMessage get problemMessage => DiagnosticMessageImpl(
    filePath: source.fullName,
    length: length,
    message: message,
    offset: offset,
    url: null,
  );

  @override
  Severity get severity => Severity.error;
}

class MockErrorCode implements DiagnosticCode {
  @override
  DiagnosticType type;

  @override
  DiagnosticSeverity severity;

  @override
  String lowerCaseName;

  @override
  String? url;

  MockErrorCode(this.type, this.severity, this.lowerCaseName);

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
  String get lowerCaseUniqueName {
    throw StateError('Unexpected invocation of lowerCaseUniqueName');
  }

  @override
  String get problemMessage {
    throw StateError('Unexpected invocation of message');
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

  @override
  int lineNumberDifference(int offset1, int offset2) {
    throw StateError('Unexpected invocation of lineNumberDifference');
  }

  @override
  bool onSameLine(int offset1, int offset2) {
    throw StateError('Unexpected invocation of onSameLine');
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
