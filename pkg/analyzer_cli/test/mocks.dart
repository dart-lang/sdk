// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.mocks;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:typed_mock/typed_mock.dart';

class MockAnalysisError extends TypedMock implements AnalysisError {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAnalysisErrorInfo extends TypedMock implements AnalysisErrorInfo {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCommandLineOptions extends TypedMock implements CommandLineOptions {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockErrorCode extends TypedMock implements ErrorCode {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockErrorType extends TypedMock implements ErrorType {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLineInfo extends TypedMock implements LineInfo {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLineInfo_Location extends TypedMock implements LineInfo_Location {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSource extends TypedMock implements Source {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
