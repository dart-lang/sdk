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


class MockClassElement extends TypedMock implements ClassElement {
  final ElementKind kind = ElementKind.CLASS;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockCompilationUnitElement extends TypedMock implements
    CompilationUnitElement {
  final ElementKind kind = ElementKind.COMPILATION_UNIT;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockConstructorElement extends TypedMock implements ConstructorElement {
  final kind = ElementKind.CONSTRUCTOR;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockElement extends StringTypedMock implements Element {
  MockElement([String name = '<element>']) : super(name);

  @override
  String get displayName => _toString;

  @override
  String get name => _toString;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockFieldElement extends TypedMock implements FieldElement {
  final ElementKind kind = ElementKind.FIELD;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockFunctionElement extends TypedMock implements FunctionElement {
  final ElementKind kind = ElementKind.FUNCTION;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockFunctionTypeAliasElement extends TypedMock implements
    FunctionTypeAliasElement {
  final ElementKind kind = ElementKind.FUNCTION_TYPE_ALIAS;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockHtmlElement extends TypedMock implements HtmlElement {
  final ElementKind kind = ElementKind.HTML;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockImportElement extends TypedMock implements ImportElement {
  final ElementKind kind = ElementKind.IMPORT;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLibraryElement extends TypedMock implements LibraryElement {
  final ElementKind kind = ElementKind.LIBRARY;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLocalVariableElement extends TypedMock implements LocalVariableElement
    {
  final ElementKind kind = ElementKind.LOCAL_VARIABLE;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLogger extends TypedMock implements Logger {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockMethodElement extends StringTypedMock implements MethodElement {
  final kind = ElementKind.METHOD;
  MockMethodElement([String name = 'method']) : super(name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockParameterElement extends TypedMock implements ParameterElement {
  final ElementKind kind = ElementKind.PARAMETER;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockPropertyAccessorElement extends TypedMock implements
    PropertyAccessorElement {
  final ElementKind kind;
  MockPropertyAccessorElement(this.kind);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockSource extends StringTypedMock implements Source {
  MockSource([String name = 'mocked.dart']) : super(name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockTopLevelVariableElement extends TypedMock implements
    TopLevelVariableElement {
  final ElementKind kind = ElementKind.TOP_LEVEL_VARIABLE;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockTypeParameterElement extends TypedMock implements TypeParameterElement
    {
  final ElementKind kind = ElementKind.TYPE_PARAMETER;
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
