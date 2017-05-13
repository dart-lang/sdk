// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as analyzer;
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart' as analyzer;
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/exception/exception.dart' as analyzer;
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/src/dart/element/element.dart' as analyzer;
import 'package:analyzer/src/error/codes.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/abstract_context.dart';

void main() {
  defineReflectiveTests(AnalyzerConverterTest);
}

@reflectiveTest
class AnalyzerConverterTest extends AbstractContextTest {
  AnalyzerConverter converter = new AnalyzerConverter();
  analyzer.Source source;
  String testFile;

  /**
   * Assert that the given [pluginError] matches the given [analyzerError].
   */
  void assertError(
      plugin.AnalysisError pluginError, analyzer.AnalysisError analyzerError,
      {analyzer.ErrorSeverity severity,
      int startColumn: -1,
      int startLine: -1}) {
    analyzer.ErrorCode errorCode = analyzerError.errorCode;
    expect(pluginError, isNotNull);
    plugin.Location location = pluginError.location;
    expect(pluginError.code, errorCode.name.toLowerCase());
    expect(pluginError.correction, errorCode.correction);
    expect(location, isNotNull);
    expect(location.file, analyzerError.source.fullName);
    expect(location.length, analyzerError.length);
    expect(location.offset, analyzerError.offset);
    expect(location.startColumn, startColumn);
    expect(location.startLine, startLine);
    expect(pluginError.message, errorCode.message);
    expect(pluginError.severity,
        converter.convertErrorSeverity(severity ?? errorCode.errorSeverity));
    expect(pluginError.type, converter.convertErrorType(errorCode.type));
  }

  analyzer.AnalysisError createError(int offset) => new analyzer.AnalysisError(
      source, offset, 5, analyzer.CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT);

  @override
  void setUp() {
    super.setUp();
    source = provider
        .newFile(provider.convertPath('/foo/bar.dart'), '')
        .createSource();
    testFile = provider.convertPath('/test.dart');
  }

  test_convertAnalysisError_lineInfo_noSeverity() {
    analyzer.AnalysisError analyzerError = createError(13);
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);

    assertError(
        converter.convertAnalysisError(analyzerError, lineInfo: lineInfo),
        analyzerError,
        startColumn: 4,
        startLine: 2);
  }

  test_convertAnalysisError_lineInfo_severity() {
    analyzer.AnalysisError analyzerError = createError(13);
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;

    assertError(
        converter.convertAnalysisError(analyzerError,
            lineInfo: lineInfo, severity: severity),
        analyzerError,
        startColumn: 4,
        startLine: 2,
        severity: severity);
  }

  test_convertAnalysisError_noLineInfo_noSeverity() {
    analyzer.AnalysisError analyzerError = createError(11);

    assertError(converter.convertAnalysisError(analyzerError), analyzerError);
  }

  test_convertAnalysisError_noLineInfo_severity() {
    analyzer.AnalysisError analyzerError = createError(11);
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;

    assertError(
        converter.convertAnalysisError(analyzerError, severity: severity),
        analyzerError,
        severity: severity);
  }

  test_convertAnalysisErrors_lineInfo_noOptions() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);

    List<plugin.AnalysisError> pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors, lineInfo: lineInfo);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0],
        startColumn: 4, startLine: 2);
    assertError(pluginErrors[1], analyzerErrors[1],
        startColumn: 6, startLine: 3);
  }

  test_convertAnalysisErrors_lineInfo_options() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;
    analyzer.AnalysisOptionsImpl options = new analyzer.AnalysisOptionsImpl();
    options.errorProcessors = [
      new analyzer.ErrorProcessor(analyzerErrors[0].errorCode.name, severity)
    ];

    List<plugin.AnalysisError> pluginErrors = converter.convertAnalysisErrors(
        analyzerErrors,
        lineInfo: lineInfo,
        options: options);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0],
        startColumn: 4, startLine: 2, severity: severity);
    assertError(pluginErrors[1], analyzerErrors[1],
        startColumn: 6, startLine: 3, severity: severity);
  }

  test_convertAnalysisErrors_noLineInfo_noOptions() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(11),
      createError(25)
    ];

    List<plugin.AnalysisError> pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0]);
    assertError(pluginErrors[1], analyzerErrors[1]);
  }

  test_convertAnalysisErrors_noLineInfo_options() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;
    analyzer.AnalysisOptionsImpl options = new analyzer.AnalysisOptionsImpl();
    options.errorProcessors = [
      new analyzer.ErrorProcessor(analyzerErrors[0].errorCode.name, severity)
    ];

    List<plugin.AnalysisError> pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors, options: options);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0], severity: severity);
    assertError(pluginErrors[1], analyzerErrors[1], severity: severity);
  }

  test_convertElement_class() async {
    analyzer.Source source = addSource(
        testFile,
        '''
@deprecated
abstract class _A {}
class B<K, V> {}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    {
      analyzer.ClassElement engineElement = findElementInUnit(unit, '_A');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.CLASS);
      expect(element.name, '_A');
      expect(element.typeParameters, isNull);
      {
        plugin.Location location = element.location;
        expect(location.file, testFile);
        expect(location.offset, 27);
        expect(location.length, '_A'.length);
        expect(location.startLine, 2);
        expect(location.startColumn, 16);
      }
      expect(element.parameters, isNull);
      expect(
          element.flags,
          plugin.Element.FLAG_ABSTRACT |
              plugin.Element.FLAG_DEPRECATED |
              plugin.Element.FLAG_PRIVATE);
    }
    {
      analyzer.ClassElement engineElement = findElementInUnit(unit, 'B');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.CLASS);
      expect(element.name, 'B');
      expect(element.typeParameters, '<K, V>');
      expect(element.flags, 0);
    }
  }

  test_convertElement_constructor() async {
    analyzer.Source source = addSource(
        testFile,
        '''
class A {
  const A.myConstructor(int a, [String b]);
}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.ConstructorElement engineElement =
        findElementInUnit(unit, 'myConstructor');
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.CONSTRUCTOR);
    expect(element.name, 'myConstructor');
    expect(element.typeParameters, isNull);
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 20);
      expect(location.length, 'myConstructor'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 11);
    }
    expect(element.parameters, '(int a, [String b])');
    expect(element.returnType, 'A');
    expect(element.flags, plugin.Element.FLAG_CONST);
  }

  void test_convertElement_dynamic() {
    var engineElement = analyzer.DynamicElementImpl.instance;
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.UNKNOWN);
    expect(element.name, 'dynamic');
    expect(element.location, isNull);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  test_convertElement_enum() async {
    analyzer.Source source = addSource(
        testFile,
        '''
@deprecated
enum _E1 { one, two }
enum E2 { three, four }''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    {
      analyzer.ClassElement engineElement = findElementInUnit(unit, '_E1');
      expect(engineElement.isDeprecated, isTrue);
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM);
      expect(element.name, '_E1');
      expect(element.typeParameters, isNull);
      {
        plugin.Location location = element.location;
        expect(location.file, testFile);
        expect(location.offset, 17);
        expect(location.length, '_E1'.length);
        expect(location.startLine, 2);
        expect(location.startColumn, 6);
      }
      expect(element.parameters, isNull);
      expect(
          element.flags,
          (engineElement.isDeprecated ? plugin.Element.FLAG_DEPRECATED : 0) |
              plugin.Element.FLAG_PRIVATE);
    }
    {
      analyzer.ClassElement engineElement = findElementInUnit(unit, 'E2');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM);
      expect(element.name, 'E2');
      expect(element.typeParameters, isNull);
      expect(element.flags, 0);
    }
  }

  test_convertElement_enumConstant() async {
    analyzer.Source source = addSource(
        testFile,
        '''
@deprecated
enum _E1 { one, two }
enum E2 { three, four }''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    {
      analyzer.FieldElement engineElement = findElementInUnit(unit, 'one');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM_CONSTANT);
      expect(element.name, 'one');
      {
        plugin.Location location = element.location;
        expect(location.file, testFile);
        expect(location.offset, 23);
        expect(location.length, 'one'.length);
        expect(location.startLine, 2);
        expect(location.startColumn, 12);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, '_E1');
      // TODO(danrubel) determine why enum constant is not marked as deprecated
      //analyzer.ClassElement classElement = engineElement.enclosingElement;
      //expect(classElement.isDeprecated, isTrue);
      expect(
          element.flags,
          // Element.FLAG_DEPRECATED |
          plugin.Element.FLAG_CONST | plugin.Element.FLAG_STATIC);
    }
    {
      analyzer.FieldElement engineElement = findElementInUnit(unit, 'three');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM_CONSTANT);
      expect(element.name, 'three');
      {
        plugin.Location location = element.location;
        expect(location.file, testFile);
        expect(location.offset, 44);
        expect(location.length, 'three'.length);
        expect(location.startLine, 3);
        expect(location.startColumn, 11);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, 'E2');
      expect(element.flags,
          plugin.Element.FLAG_CONST | plugin.Element.FLAG_STATIC);
    }
    {
      analyzer.FieldElement engineElement = findElementInUnit(unit, 'index');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.FIELD);
      expect(element.name, 'index');
      {
        plugin.Location location = element.location;
        expect(location.file, testFile);
        expect(location.offset, -1);
        expect(location.length, 'index'.length);
        expect(location.startLine, 1);
        expect(location.startColumn, 0);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, 'int');
      expect(element.flags, plugin.Element.FLAG_FINAL);
    }
    {
      analyzer.FieldElement engineElement = findElementInUnit(unit, 'values');
      // create notification Element
      plugin.Element element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.FIELD);
      expect(element.name, 'values');
      {
        plugin.Location location = element.location;
        expect(location.file, testFile);
        expect(location.offset, -1);
        expect(location.length, 'values'.length);
        expect(location.startLine, 1);
        expect(location.startColumn, 0);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, 'List<E2>');
      expect(element.flags,
          plugin.Element.FLAG_CONST | plugin.Element.FLAG_STATIC);
    }
  }

  test_convertElement_field() async {
    analyzer.Source source = addSource(
        testFile,
        '''
class A {
  static const myField = 42;
}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.FieldElement engineElement = findElementInUnit(unit, 'myField');
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.FIELD);
    expect(element.name, 'myField');
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 25);
      expect(location.length, 'myField'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 16);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, 'dynamic');
    expect(
        element.flags, plugin.Element.FLAG_CONST | plugin.Element.FLAG_STATIC);
  }

  test_convertElement_functionTypeAlias() async {
    analyzer.Source source = addSource(
        testFile,
        '''
typedef int F<T>(String x);
''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.FunctionTypeAliasElement engineElement =
        findElementInUnit(unit, 'F');
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element.name, 'F');
    expect(element.typeParameters, '<T>');
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 12);
      expect(location.length, 'F'.length);
      expect(location.startLine, 1);
      expect(location.startColumn, 13);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, 'int');
    expect(element.flags, 0);
  }

  test_convertElement_getter() async {
    analyzer.Source source = addSource(
        testFile,
        '''
class A {
  String get myGetter => 42;
}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.PropertyAccessorElement engineElement =
        findElementInUnit(unit, 'myGetter', analyzer.ElementKind.GETTER);
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.GETTER);
    expect(element.name, 'myGetter');
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 23);
      expect(location.length, 'myGetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 14);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, 'String');
    expect(element.flags, 0);
  }

  test_convertElement_method() async {
    analyzer.Source source = addSource(
        testFile,
        '''
class A {
  static List<String> myMethod(int a, {String b, int c}) {
    return null;
  }
}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.MethodElement engineElement = findElementInUnit(unit, 'myMethod');
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.METHOD);
    expect(element.name, 'myMethod');
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 32);
      expect(location.length, 'myGetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 23);
    }
    expect(element.parameters, '(int a, {String b, int c})');
    expect(element.returnType, 'List<String>');
    expect(element.flags, plugin.Element.FLAG_STATIC);
  }

  test_convertElement_setter() async {
    analyzer.Source source = addSource(
        testFile,
        '''
class A {
  set mySetter(String x) {}
}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.FieldElement engineFieldElement =
        findElementInUnit(unit, 'mySetter', analyzer.ElementKind.FIELD);
    analyzer.PropertyAccessorElement engineElement = engineFieldElement.setter;
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.SETTER);
    expect(element.name, 'mySetter');
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 16);
      expect(location.length, 'mySetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 7);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  void test_convertElementKind() {
    expect(converter.convertElementKind(analyzer.ElementKind.CLASS),
        plugin.ElementKind.CLASS);
    expect(converter.convertElementKind(analyzer.ElementKind.COMPILATION_UNIT),
        plugin.ElementKind.COMPILATION_UNIT);
    expect(converter.convertElementKind(analyzer.ElementKind.CONSTRUCTOR),
        plugin.ElementKind.CONSTRUCTOR);
    expect(converter.convertElementKind(analyzer.ElementKind.FIELD),
        plugin.ElementKind.FIELD);
    expect(converter.convertElementKind(analyzer.ElementKind.FUNCTION),
        plugin.ElementKind.FUNCTION);
    expect(
        converter.convertElementKind(analyzer.ElementKind.FUNCTION_TYPE_ALIAS),
        plugin.ElementKind.FUNCTION_TYPE_ALIAS);
    expect(converter.convertElementKind(analyzer.ElementKind.GETTER),
        plugin.ElementKind.GETTER);
    expect(converter.convertElementKind(analyzer.ElementKind.LABEL),
        plugin.ElementKind.LABEL);
    expect(converter.convertElementKind(analyzer.ElementKind.LIBRARY),
        plugin.ElementKind.LIBRARY);
    expect(converter.convertElementKind(analyzer.ElementKind.LOCAL_VARIABLE),
        plugin.ElementKind.LOCAL_VARIABLE);
    expect(converter.convertElementKind(analyzer.ElementKind.METHOD),
        plugin.ElementKind.METHOD);
    expect(converter.convertElementKind(analyzer.ElementKind.PARAMETER),
        plugin.ElementKind.PARAMETER);
    expect(converter.convertElementKind(analyzer.ElementKind.SETTER),
        plugin.ElementKind.SETTER);
    expect(
        converter.convertElementKind(analyzer.ElementKind.TOP_LEVEL_VARIABLE),
        plugin.ElementKind.TOP_LEVEL_VARIABLE);
    expect(converter.convertElementKind(analyzer.ElementKind.TYPE_PARAMETER),
        plugin.ElementKind.TYPE_PARAMETER);
  }

  test_convertErrorSeverity() {
    for (analyzer.ErrorSeverity severity in analyzer.ErrorSeverity.values) {
      if (severity != analyzer.ErrorSeverity.NONE) {
        expect(converter.convertErrorSeverity(severity), isNotNull,
            reason: severity.name);
      }
    }
  }

  test_convertErrorType() {
    for (analyzer.ErrorType type in analyzer.ErrorType.values) {
      expect(converter.convertErrorType(type), isNotNull, reason: type.name);
    }
  }

  test_fromElement_LABEL() async {
    analyzer.Source source = addSource(
        testFile,
        '''
main() {
myLabel:
  while (true) {
    break myLabel;
  }
}''');
    analyzer.CompilationUnit unit = await resolveLibraryUnit(source);
    analyzer.LabelElement engineElement = findElementInUnit(unit, 'myLabel');
    // create notification Element
    plugin.Element element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.LABEL);
    expect(element.name, 'myLabel');
    {
      plugin.Location location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 9);
      expect(location.length, 'myLabel'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 1);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }
}
