// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.mocks;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/pub.dart';
import 'package:mockito/mockito.dart';

class CollectingSink extends MockIOSink {
  final StringBuffer buffer = new StringBuffer();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => buffer.toString();

  String trim() => toString().trim();
  @override
  write(obj) {
    buffer.write(obj);
  }

  @override
  writeln([Object obj = ""]) {
    buffer.writeln(obj);
  }
}

class MockAnalysisError extends Mock implements AnalysisError {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAnalysisErrorInfo extends Mock implements AnalysisErrorInfo {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockErrorCode extends Mock implements ErrorCode {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockErrorType extends Mock implements ErrorType {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFile extends Mock implements File {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockIOSink extends Mock implements IOSink {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLineInfo extends Mock implements LineInfo {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLineInfo_Location extends Mock implements LineInfo_Location {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLinter extends Mock implements DartLinter {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLinterOptions extends Mock implements LinterOptions {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPubVisitor extends Mock implements PubspecVisitor {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockReporter extends Mock implements Reporter {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRule extends Mock implements LintRule {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSource extends Mock implements Source {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
