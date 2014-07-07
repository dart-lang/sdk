// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.mocks;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';


class MockAnalysisContext extends StringTypedMock implements AnalysisContext {
  MockAnalysisContext(String name) : super(name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockCompilationUnitElement extends TypedMock implements
    CompilationUnitElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockElement extends StringTypedMock implements Element {
  MockElement([String name = '<element>']) : super(name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockHtmlElement extends TypedMock implements HtmlElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLibraryElement extends TypedMock implements LibraryElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLogger extends TypedMock implements Logger {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockSource extends StringTypedMock implements Source {
  MockSource([String name = 'mocked.dart']) : super(name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class StringTypedMock extends TypedMock {
  String _toString;

  StringTypedMock(this._toString);

  @override
  String toString() {
    if (_toString != null) {
      return _toString;
    }
    return super.toString();
  }
}
