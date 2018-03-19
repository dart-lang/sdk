// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:mockito/mockito.dart';

class CollectingSink extends MockIOSink {
  final StringBuffer buffer = new StringBuffer();

  @override
  String toString() => buffer.toString();

  String trim() => toString().trim();
  @override
  write(obj) {
    buffer.write(obj);
  }

  @override
  writeln([Object obj = '']) {
    buffer.writeln(obj);
  }
}

class MockAnalysisError extends Mock implements AnalysisError {}

class MockAnalysisErrorInfo extends Mock implements AnalysisErrorInfo {}

class MockErrorCode extends Mock implements ErrorCode {}

class MockErrorSeverity extends Mock implements ErrorSeverity {}

class MockErrorType extends Mock implements ErrorType {}

class MockFile extends Mock implements File {}

class MockIOSink extends Mock implements IOSink {}

class MockLineInfo extends Mock implements LineInfo {}

// ignore: camel_case_types
class MockLineInfo_Location extends Mock implements LineInfo_Location {}

class MockLinter extends Mock implements DartLinter {}

class MockLinterOptions extends Mock implements LinterOptions {}

class MockPubVisitor extends Mock implements PubspecVisitor {}

class MockReporter implements Reporter {
  List<LinterException> exceptions = <LinterException>[];

  List<String> warnings = <String>[];

  MockReporter();

  @override
  void exception(LinterException exception) {
    exceptions.add(exception);
  }

  @override
  void warn(String message) {
    warnings.add(message);
  }
}

class MockRule extends Mock implements LintRule {}

class MockSource extends Mock implements Source {}
