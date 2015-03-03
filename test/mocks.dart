// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.mocks;

import 'dart:io';

import 'package:linter/src/linter.dart';
import 'package:mockito/mockito.dart';
import 'package:linter/src/pub.dart';

class MockFile extends Mock implements File {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockIOSink extends Mock implements IOSink {
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

class MockPubVisitor extends Mock implements PubSpecVisitor {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRule extends Mock implements LintRule {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockReporter extends Mock implements Reporter {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}