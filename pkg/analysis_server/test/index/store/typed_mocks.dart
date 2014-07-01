// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.store.typed_mocks;

import 'package:analysis_server/src/index/store/codec.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/index.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';


class MockAnalysisContext extends TypedMock implements AnalysisContext {
  String _name;
  MockAnalysisContext(this._name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  String toString() => _name;
}


class MockClassElement extends TypedMock implements ClassElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockCompilationUnitElement extends TypedMock implements
    CompilationUnitElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockConstructorElement extends TypedMock implements ConstructorElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockContextCodec extends TypedMock implements ContextCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockDartType extends StringTypedMock implements DartType {
  MockDartType([String toString]) : super(toString);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockElement extends TypedMock implements Element {
  String _name;
  MockElement([this._name = '<element>']);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  String toString() => _name;
}


class MockElementCodec extends TypedMock implements ElementCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockFieldElement extends TypedMock implements FieldElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockHtmlElement extends TypedMock implements HtmlElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockInstrumentedAnalysisContextImpl extends TypedMock implements
    InstrumentedAnalysisContextImpl {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLibraryElement extends TypedMock implements LibraryElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLocation extends TypedMock implements Location {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLogger extends TypedMock implements Logger {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockMethodElement extends TypedMock implements MethodElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockParameterElement extends StringTypedMock implements ParameterElement {
  MockParameterElement([String toString]) : super(toString);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockPropertyAccessorElement extends TypedMock implements
    PropertyAccessorElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockRelationshipCodec extends TypedMock implements RelationshipCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockSource extends TypedMock implements Source {
  String _name;
  MockSource(this._name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  String toString() => _name;
}


class SourceMock extends TypedMock implements Source {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class StringTypedMock extends TypedMock {
  String _toString;

  StringTypedMock(this._toString);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    if (_toString != null) {
      return _toString;
    }
    return super.toString();
  }
}
