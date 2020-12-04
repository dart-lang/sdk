// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/src/dart/element/element.dart' as analyzer;
import 'package:analyzer/src/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/src/error/codes.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/abstract_context.dart';

void main() {
  defineReflectiveTests(AnalyzerConverterTest);
}

@reflectiveTest
class AnalyzerConverterTest extends AbstractContextTest {
  AnalyzerConverter converter = AnalyzerConverter();
  analyzer.Source source;
  String testFile;

  /// Assert that the given [pluginError] matches the given [analyzerError].
  void assertError(
      plugin.AnalysisError pluginError, analyzer.AnalysisError analyzerError,
      {analyzer.ErrorSeverity severity,
      int startColumn = -1,
      int startLine = -1}) {
    var errorCode = analyzerError.errorCode;
    expect(pluginError, isNotNull);
    var location = pluginError.location;
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

  analyzer.AnalysisError createError(int offset, {String contextMessage}) {
    var contextMessages = <analyzer.DiagnosticMessageImpl>[];
    if (contextMessage != null) {
      contextMessages.add(analyzer.DiagnosticMessageImpl(
          filePath: source.fullName,
          offset: 53,
          length: 7,
          message: contextMessage));
    }
    return analyzer.AnalysisError(
        source,
        offset,
        5,
        analyzer.CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT,
        null,
        contextMessages);
  }

  @override
  void setUp() {
    super.setUp();
    source = newFile('/foo/bar.dart').createSource();
    testFile = convertPath('$testPackageRootPath/lib/test.dart');
  }

  void test_convertAnalysisError_contextMessages() {
    var analyzerError = createError(13, contextMessage: 'here');
    var lineInfo = analyzer.LineInfo([0, 10, 20]);
    var severity = analyzer.ErrorSeverity.WARNING;

    var pluginError = converter.convertAnalysisError(analyzerError,
        lineInfo: lineInfo, severity: severity);
    assertError(pluginError, analyzerError,
        startColumn: 4, startLine: 2, severity: severity);
    expect(pluginError.contextMessages, hasLength(1));
    var message = pluginError.contextMessages[0];
    expect(message.message, 'here');
    expect(message.location.offset, 53);
    expect(message.location.length, 7);
  }

  void test_convertAnalysisError_lineInfo_noSeverity() {
    var analyzerError = createError(13);
    var lineInfo = analyzer.LineInfo([0, 10, 20]);

    assertError(
        converter.convertAnalysisError(analyzerError, lineInfo: lineInfo),
        analyzerError,
        startColumn: 4,
        startLine: 2);
  }

  void test_convertAnalysisError_lineInfo_severity() {
    var analyzerError = createError(13);
    var lineInfo = analyzer.LineInfo([0, 10, 20]);
    var severity = analyzer.ErrorSeverity.WARNING;

    assertError(
        converter.convertAnalysisError(analyzerError,
            lineInfo: lineInfo, severity: severity),
        analyzerError,
        startColumn: 4,
        startLine: 2,
        severity: severity);
  }

  void test_convertAnalysisError_noLineInfo_noSeverity() {
    var analyzerError = createError(11);

    assertError(converter.convertAnalysisError(analyzerError), analyzerError);
  }

  void test_convertAnalysisError_noLineInfo_severity() {
    var analyzerError = createError(11);
    var severity = analyzer.ErrorSeverity.WARNING;

    assertError(
        converter.convertAnalysisError(analyzerError, severity: severity),
        analyzerError,
        severity: severity);
  }

  void test_convertAnalysisErrors_lineInfo_noOptions() {
    var analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    var lineInfo = analyzer.LineInfo([0, 10, 20]);

    var pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors, lineInfo: lineInfo);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0],
        startColumn: 4, startLine: 2);
    assertError(pluginErrors[1], analyzerErrors[1],
        startColumn: 6, startLine: 3);
  }

  void test_convertAnalysisErrors_lineInfo_options() {
    var analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    var lineInfo = analyzer.LineInfo([0, 10, 20]);
    var severity = analyzer.ErrorSeverity.WARNING;
    var options = analyzer.AnalysisOptionsImpl();
    options.errorProcessors = [
      analyzer.ErrorProcessor(analyzerErrors[0].errorCode.name, severity)
    ];

    var pluginErrors = converter.convertAnalysisErrors(analyzerErrors,
        lineInfo: lineInfo, options: options);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0],
        startColumn: 4, startLine: 2, severity: severity);
    assertError(pluginErrors[1], analyzerErrors[1],
        startColumn: 6, startLine: 3, severity: severity);
  }

  void test_convertAnalysisErrors_noLineInfo_noOptions() {
    var analyzerErrors = <analyzer.AnalysisError>[
      createError(11),
      createError(25)
    ];

    var pluginErrors = converter.convertAnalysisErrors(analyzerErrors);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0]);
    assertError(pluginErrors[1], analyzerErrors[1]);
  }

  void test_convertAnalysisErrors_noLineInfo_options() {
    var analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    var severity = analyzer.ErrorSeverity.WARNING;
    var options = analyzer.AnalysisOptionsImpl();
    options.errorProcessors = [
      analyzer.ErrorProcessor(analyzerErrors[0].errorCode.name, severity)
    ];

    var pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors, options: options);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0], severity: severity);
    assertError(pluginErrors[1], analyzerErrors[1], severity: severity);
  }

  Future<void> test_convertElement_class() async {
    addSource(testFile, '''
@deprecated
abstract class _A {}
class B<K, V> {}''');
    var unit = (await resolveFile(testFile))?.unit;
    {
      var engineElement =
          findElementInUnit(unit, '_A') as analyzer.ClassElement;
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.CLASS);
      expect(element.name, '_A');
      expect(element.typeParameters, isNull);
      {
        var location = element.location;
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
      var engineElement = findElementInUnit(unit, 'B') as analyzer.ClassElement;
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.CLASS);
      expect(element.name, 'B');
      expect(element.typeParameters, '<K, V>');
      expect(element.flags, 0);
    }
  }

  Future<void> test_convertElement_constructor() async {
    addSource(testFile, '''
class A {
  const A.myConstructor(int a, [String b]);
}''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'myConstructor') as analyzer.ConstructorElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.CONSTRUCTOR);
    expect(element.name, 'myConstructor');
    expect(element.typeParameters, isNull);
    {
      var location = element.location;
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
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.UNKNOWN);
    expect(element.name, 'dynamic');
    expect(element.location, isNull);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  Future<void> test_convertElement_enum() async {
    addSource(testFile, '''
@deprecated
enum _E1 { one, two }
enum E2 { three, four }''');
    var unit = (await resolveFile(testFile))?.unit;
    {
      var engineElement =
          findElementInUnit(unit, '_E1') as analyzer.ClassElement;
      expect(engineElement.hasDeprecated, isTrue);
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM);
      expect(element.name, '_E1');
      expect(element.typeParameters, isNull);
      {
        var location = element.location;
        expect(location.file, testFile);
        expect(location.offset, 17);
        expect(location.length, '_E1'.length);
        expect(location.startLine, 2);
        expect(location.startColumn, 6);
      }
      expect(element.parameters, isNull);
      expect(
          element.flags,
          (engineElement.hasDeprecated ? plugin.Element.FLAG_DEPRECATED : 0) |
              plugin.Element.FLAG_PRIVATE);
    }
    {
      var engineElement =
          findElementInUnit(unit, 'E2') as analyzer.ClassElement;
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM);
      expect(element.name, 'E2');
      expect(element.typeParameters, isNull);
      expect(element.flags, 0);
    }
  }

  Future<void> test_convertElement_enumConstant() async {
    addSource(testFile, '''
@deprecated
enum _E1 { one, two }
enum E2 { three, four }''');
    var unit = (await resolveFile(testFile))?.unit;
    {
      var engineElement =
          findElementInUnit(unit, 'one') as analyzer.FieldElement;
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM_CONSTANT);
      expect(element.name, 'one');
      {
        var location = element.location;
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
      var engineElement =
          findElementInUnit(unit, 'three') as analyzer.FieldElement;
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.ENUM_CONSTANT);
      expect(element.name, 'three');
      {
        var location = element.location;
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
      var engineElement = unit.declaredElement.enums[1].getField('index');
      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.FIELD);
      expect(element.name, 'index');
      {
        var location = element.location;
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
      var engineElement = unit.declaredElement.enums[1].getField('values');

      // create notification Element
      var element = converter.convertElement(engineElement);
      expect(element.kind, plugin.ElementKind.FIELD);
      expect(element.name, 'values');
      {
        var location = element.location;
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

  Future<void> test_convertElement_field() async {
    addSource(testFile, '''
class A {
  static const myField = 42;
}''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'myField') as analyzer.FieldElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.FIELD);
    expect(element.name, 'myField');
    {
      var location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 25);
      expect(location.length, 'myField'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 16);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, 'int');
    expect(
        element.flags, plugin.Element.FLAG_CONST | plugin.Element.FLAG_STATIC);
  }

  Future<void> test_convertElement_functionTypeAlias() async {
    addSource(testFile, '''
typedef int F<T>(String x);
''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'F') as analyzer.FunctionTypeAliasElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element.name, 'F');
    expect(element.typeParameters, '<T>');
    {
      var location = element.location;
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

  Future<void> test_convertElement_genericTypeAlias_function() async {
    addSource(testFile, '''
typedef F<T> = int Function(String x);
''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'F') as analyzer.FunctionTypeAliasElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element.name, 'F');
    expect(element.typeParameters, '<T>');
    {
      var location = element.location;
      expect(location.file, testFile);
      expect(location.offset, 8);
      expect(location.length, 'F'.length);
      expect(location.startLine, 1);
      expect(location.startColumn, 9);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, 'int');
    expect(element.flags, 0);
  }

  Future<void> test_convertElement_getter() async {
    addSource(testFile, '''
class A {
  String get myGetter => 42;
}''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'myGetter', analyzer.ElementKind.GETTER)
            as analyzer.PropertyAccessorElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.GETTER);
    expect(element.name, 'myGetter');
    {
      var location = element.location;
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

  Future<void> test_convertElement_method() async {
    addSource(testFile, '''
class A {
  static List<String> myMethod(int a, {String b, int c}) {
    return null;
  }
}''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'myMethod') as analyzer.MethodElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.METHOD);
    expect(element.name, 'myMethod');
    {
      var location = element.location;
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

  Future<void> test_convertElement_setter() async {
    addSource(testFile, '''
class A {
  set mySetter(String x) {}
}''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'mySetter', analyzer.ElementKind.SETTER)
            as analyzer.PropertyAccessorElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.SETTER);
    expect(element.name, 'mySetter');
    {
      var location = element.location;
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

  void test_convertErrorSeverity() {
    for (var severity in analyzer.ErrorSeverity.values) {
      if (severity != analyzer.ErrorSeverity.NONE) {
        expect(converter.convertErrorSeverity(severity), isNotNull,
            reason: severity.name);
      }
    }
  }

  void test_convertErrorType() {
    for (var type in analyzer.ErrorType.values) {
      expect(converter.convertErrorType(type), isNotNull, reason: type.name);
    }
  }

  Future<void> test_fromElement_LABEL() async {
    addSource(testFile, '''
main() {
myLabel:
  while (true) {
    break myLabel;
  }
}''');
    var unit = (await resolveFile(testFile))?.unit;
    var engineElement =
        findElementInUnit(unit, 'myLabel') as analyzer.LabelElement;
    // create notification Element
    var element = converter.convertElement(engineElement);
    expect(element.kind, plugin.ElementKind.LABEL);
    expect(element.name, 'myLabel');
    {
      var location = element.location;
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
