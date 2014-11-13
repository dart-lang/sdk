// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.all_the_rest_test;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/html_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'parser_test.dart';
import 'resolver_test.dart';
import 'test_support.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AngularCompilationUnitBuilderTest);
  runReflectiveTests(AngularHtmlUnitResolverTest);
  runReflectiveTests(AngularHtmlUnitUtilsTest);
  runReflectiveTests(ConstantEvaluatorTest);
  runReflectiveTests(ConstantFinderTest);
  runReflectiveTests(ConstantValueComputerTest);
  runReflectiveTests(ConstantVisitorTest);
  runReflectiveTests(ContentCacheTest);
  runReflectiveTests(DartObjectImplTest);
  runReflectiveTests(DartUriResolverTest);
  runReflectiveTests(DeclaredVariablesTest);
  runReflectiveTests(DirectoryBasedDartSdkTest);
  runReflectiveTests(DirectoryBasedSourceContainerTest);
  runReflectiveTests(ElementBuilderTest);
  runReflectiveTests(ElementLocatorTest);
  runReflectiveTests(EnumMemberBuilderTest);
  runReflectiveTests(ErrorReporterTest);
  runReflectiveTests(ErrorSeverityTest);
  runReflectiveTests(ExitDetectorTest);
  runReflectiveTests(FileBasedSourceTest);
  runReflectiveTests(FileUriResolverTest);
  runReflectiveTests(HtmlParserTest);
  runReflectiveTests(HtmlTagInfoBuilderTest);
  runReflectiveTests(HtmlUnitBuilderTest);
  runReflectiveTests(HtmlWarningCodeTest);
  runReflectiveTests(ReferenceFinderTest);
  runReflectiveTests(SDKLibrariesReaderTest);
  runReflectiveTests(SourceFactoryTest);
  runReflectiveTests(ToSourceVisitorTest);
  runReflectiveTests(UriKindTest);
  runReflectiveTests(StringScannerTest);
}

abstract class AbstractScannerTest {
  ht.AbstractScanner newScanner(String input);

  void test_tokenize_attribute() {
    _tokenize(
        "<html bob=\"one two\">",
        <Object>[
            ht.TokenType.LT,
            "html",
            "bob",
            ht.TokenType.EQ,
            "\"one two\"",
            ht.TokenType.GT]);
  }

  void test_tokenize_comment() {
    _tokenize("<!-- foo -->", <Object>["<!-- foo -->"]);
  }

  void test_tokenize_comment_incomplete() {
    _tokenize("<!-- foo", <Object>["<!-- foo"]);
  }

  void test_tokenize_comment_with_gt() {
    _tokenize("<!-- foo > -> -->", <Object>["<!-- foo > -> -->"]);
  }

  void test_tokenize_declaration() {
    _tokenize(
        "<! foo ><html>",
        <Object>["<! foo >", ht.TokenType.LT, "html", ht.TokenType.GT]);
  }

  void test_tokenize_declaration_malformed() {
    _tokenize(
        "<! foo /><html>",
        <Object>["<! foo />", ht.TokenType.LT, "html", ht.TokenType.GT]);
  }

  void test_tokenize_directive_incomplete() {
    _tokenize2("<? \nfoo", <Object>["<? \nfoo"], <int>[0, 4]);
  }

  void test_tokenize_directive_xml() {
    _tokenize(
        "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>",
        <Object>["<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"]);
  }

  void test_tokenize_directives_incomplete_with_newline() {
    _tokenize2("<! \nfoo", <Object>["<! \nfoo"], <int>[0, 4]);
  }

  void test_tokenize_empty() {
    _tokenize("", <Object>[]);
  }

  void test_tokenize_lt() {
    _tokenize("<", <Object>[ht.TokenType.LT]);
  }

  void test_tokenize_script_embedded_tags() {
    _tokenize(
        "<script> <p></p></script>",
        <Object>[
            ht.TokenType.LT,
            "script",
            ht.TokenType.GT,
            " <p></p>",
            ht.TokenType.LT_SLASH,
            "script",
            ht.TokenType.GT]);
  }

  void test_tokenize_script_embedded_tags2() {
    _tokenize(
        "<script> <p></p><</script>",
        <Object>[
            ht.TokenType.LT,
            "script",
            ht.TokenType.GT,
            " <p></p><",
            ht.TokenType.LT_SLASH,
            "script",
            ht.TokenType.GT]);
  }

  void test_tokenize_script_embedded_tags3() {
    _tokenize(
        "<script> <p></p></</script>",
        <Object>[
            ht.TokenType.LT,
            "script",
            ht.TokenType.GT,
            " <p></p></",
            ht.TokenType.LT_SLASH,
            "script",
            ht.TokenType.GT]);
  }

  void test_tokenize_script_partial() {
    _tokenize(
        "<script> <p> ",
        <Object>[ht.TokenType.LT, "script", ht.TokenType.GT, " <p> "]);
  }

  void test_tokenize_script_partial2() {
    _tokenize(
        "<script> <p> <",
        <Object>[ht.TokenType.LT, "script", ht.TokenType.GT, " <p> <"]);
  }

  void test_tokenize_script_partial3() {
    _tokenize(
        "<script> <p> </",
        <Object>[ht.TokenType.LT, "script", ht.TokenType.GT, " <p> </"]);
  }

  void test_tokenize_script_ref() {
    _tokenize(
        "<script source='some.dart'/> <p>",
        <Object>[
            ht.TokenType.LT,
            "script",
            "source",
            ht.TokenType.EQ,
            "'some.dart'",
            ht.TokenType.SLASH_GT,
            " ",
            ht.TokenType.LT,
            "p",
            ht.TokenType.GT]);
  }

  void test_tokenize_script_with_newline() {
    _tokenize2(
        "<script> <p>\n </script>",
        <Object>[
            ht.TokenType.LT,
            "script",
            ht.TokenType.GT,
            " <p>\n ",
            ht.TokenType.LT_SLASH,
            "script",
            ht.TokenType.GT],
        <int>[0, 13]);
  }

  void test_tokenize_spaces_and_newlines() {
    ht.Token token = _tokenize2(
        " < html \n bob = 'joe\n' >\n <\np > one \r\n two <!-- \rfoo --> </ p > </ html > ",
        <Object>[
            " ",
            ht.TokenType.LT,
            "html",
            "bob",
            ht.TokenType.EQ,
            "'joe\n'",
            ht.TokenType.GT,
            "\n ",
            ht.TokenType.LT,
            "p",
            ht.TokenType.GT,
            " one \r\n two ",
            "<!-- \rfoo -->",
            " ",
            ht.TokenType.LT_SLASH,
            "p",
            ht.TokenType.GT,
            " ",
            ht.TokenType.LT_SLASH,
            "html",
            ht.TokenType.GT,
            " "],
        <int>[0, 9, 21, 25, 28, 38, 49]);
    token = token.next;
    expect(token.offset, 1);
    token = token.next;
    expect(token.offset, 3);
    token = token.next;
    expect(token.offset, 10);
  }

  void test_tokenize_string() {
    _tokenize(
        "<p bob=\"foo\">",
        <Object>[
            ht.TokenType.LT,
            "p",
            "bob",
            ht.TokenType.EQ,
            "\"foo\"",
            ht.TokenType.GT]);
  }

  void test_tokenize_string_partial() {
    _tokenize(
        "<p bob=\"foo",
        <Object>[ht.TokenType.LT, "p", "bob", ht.TokenType.EQ, "\"foo"]);
  }

  void test_tokenize_string_single_quote() {
    _tokenize(
        "<p bob='foo'>",
        <Object>[
            ht.TokenType.LT,
            "p",
            "bob",
            ht.TokenType.EQ,
            "'foo'",
            ht.TokenType.GT]);
  }

  void test_tokenize_string_single_quote_partial() {
    _tokenize(
        "<p bob='foo",
        <Object>[ht.TokenType.LT, "p", "bob", ht.TokenType.EQ, "'foo"]);
  }

  void test_tokenize_tag_begin_end() {
    _tokenize(
        "<html></html>",
        <Object>[
            ht.TokenType.LT,
            "html",
            ht.TokenType.GT,
            ht.TokenType.LT_SLASH,
            "html",
            ht.TokenType.GT]);
  }

  void test_tokenize_tag_begin_only() {
    ht.Token token =
        _tokenize("<html>", <Object>[ht.TokenType.LT, "html", ht.TokenType.GT]);
    token = token.next;
    expect(token.offset, 1);
  }

  void test_tokenize_tag_incomplete_with_special_characters() {
    _tokenize("<br-a_b", <Object>[ht.TokenType.LT, "br-a_b"]);
  }

  void test_tokenize_tag_self_contained() {
    _tokenize("<br/>", <Object>[ht.TokenType.LT, "br", ht.TokenType.SLASH_GT]);
  }

  void test_tokenize_tags_wellformed() {
    _tokenize(
        "<html><p>one two</p></html>",
        <Object>[
            ht.TokenType.LT,
            "html",
            ht.TokenType.GT,
            ht.TokenType.LT,
            "p",
            ht.TokenType.GT,
            "one two",
            ht.TokenType.LT_SLASH,
            "p",
            ht.TokenType.GT,
            ht.TokenType.LT_SLASH,
            "html",
            ht.TokenType.GT]);
  }

  /**
   * Given an object representing an expected token, answer the expected token type.
   *
   * @param count the token count for error reporting
   * @param expected the object representing an expected token
   * @return the expected token type
   */
  ht.TokenType _getExpectedTokenType(int count, Object expected) {
    if (expected is ht.TokenType) {
      return expected;
    }
    if (expected is String) {
      String lexeme = expected;
      if (lexeme.startsWith("\"") || lexeme.startsWith("'")) {
        return ht.TokenType.STRING;
      }
      if (lexeme.startsWith("<!--")) {
        return ht.TokenType.COMMENT;
      }
      if (lexeme.startsWith("<!")) {
        return ht.TokenType.DECLARATION;
      }
      if (lexeme.startsWith("<?")) {
        return ht.TokenType.DIRECTIVE;
      }
      if (_isTag(lexeme)) {
        return ht.TokenType.TAG;
      }
      return ht.TokenType.TEXT;
    }
    fail("Unknown expected token $count: ${expected != null ? expected.runtimeType : "null"}");
    return null;
  }

  bool _isTag(String lexeme) {
    if (lexeme.length == 0 || !Character.isLetter(lexeme.codeUnitAt(0))) {
      return false;
    }
    for (int index = 1; index < lexeme.length; index++) {
      int ch = lexeme.codeUnitAt(index);
      if (!Character.isLetterOrDigit(ch) && ch != 0x2D && ch != 0x5F) {
        return false;
      }
    }
    return true;
  }

  ht.Token _tokenize(String input, List<Object> expectedTokens) =>
      _tokenize2(input, expectedTokens, <int>[0]);
  ht.Token _tokenize2(String input, List<Object> expectedTokens,
      List<int> expectedLineStarts) {
    ht.AbstractScanner scanner = newScanner(input);
    scanner.passThroughElements = <String>["script"];
    int count = 0;
    ht.Token firstToken = scanner.tokenize();
    ht.Token token = firstToken;
    ht.Token previousToken = token.previous;
    expect(previousToken.type == ht.TokenType.EOF, isTrue);
    expect(previousToken.previous, same(previousToken));
    expect(previousToken.offset, -1);
    expect(previousToken.next, same(token));
    expect(token.offset, 0);
    while (token.type != ht.TokenType.EOF) {
      if (count == expectedTokens.length) {
        fail("too many parsed tokens");
      }
      Object expected = expectedTokens[count];
      ht.TokenType expectedTokenType = _getExpectedTokenType(count, expected);
      expect(token.type, same(expectedTokenType), reason: "token $count");
      if (expectedTokenType.lexeme != null) {
        expect(token.lexeme, expectedTokenType.lexeme, reason: "token $count");
      } else {
        expect(token.lexeme, expected, reason: "token $count");
      }
      count++;
      previousToken = token;
      token = token.next;
      expect(token.previous, same(previousToken));
    }
    expect(token.next, same(token));
    expect(token.offset, input.length);
    if (count != expectedTokens.length) {
      expect(false, isTrue, reason: "not enough parsed tokens");
    }
    List<int> lineStarts = scanner.lineStarts;
    bool success = expectedLineStarts.length == lineStarts.length;
    if (success) {
      for (int i = 0; i < lineStarts.length; i++) {
        if (expectedLineStarts[i] != lineStarts[i]) {
          success = false;
          break;
        }
      }
    }
    if (!success) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Expected line starts ");
      for (int start in expectedLineStarts) {
        buffer.write(start);
        buffer.write(", ");
      }
      buffer.write(" but found ");
      for (int start in lineStarts) {
        buffer.write(start);
        buffer.write(", ");
      }
      fail(buffer.toString());
    }
    return firstToken;
  }
}


class AngularCompilationUnitBuilderTest extends AngularTest {
  void test_Decorator() {
    String mainContent = _createAngularSource(r'''
@Decorator(selector: '[my-dir]',
             map: const {
               'my-dir' : '=>myPropA',
               '.' : '&myPropB',
             })
class MyDirective {
  set myPropA(value) {}
  set myPropB(value) {}
  @NgTwoWay('my-prop-c')
  String myPropC;
}''');
    resolveMainSourceNoErrors(mainContent);
    // prepare AngularDirectiveElement
    ClassElement classElement = mainUnitElement.getType("MyDirective");
    AngularDecoratorElement directive =
        getAngularElement(classElement, (e) => e is AngularDecoratorElement);
    expect(directive, isNotNull);
    // verify
    expect(directive.name, null);
    expect(directive.nameOffset, -1);
    _assertHasAttributeSelector(directive.selector, "my-dir");
    // verify properties
    List<AngularPropertyElement> properties = directive.properties;
    expect(properties, hasLength(3));
    _assertProperty(
        properties[0],
        "my-dir",
        findMainOffset("my-dir' :"),
        AngularPropertyKind.ONE_WAY,
        "myPropA",
        findMainOffset("myPropA'"));
    _assertProperty(
        properties[1],
        ".",
        findMainOffset(".' :"),
        AngularPropertyKind.CALLBACK,
        "myPropB",
        findMainOffset("myPropB'"));
    _assertProperty(
        properties[2],
        "my-prop-c",
        findMainOffset("my-prop-c'"),
        AngularPropertyKind.TWO_WAY,
        "myPropC",
        -1);
  }

  void test_Decorator_bad_cannotParseSelector() {
    String mainContent = _createAngularSource(r'''
@Decorator(selector: '~bad-selector',
             map: const {
               'my-dir' : '=>myPropA',
               '.' : '&myPropB',
             })
class MyDirective {
  set myPropA(value) {}
  set myPropB(value) {}
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.CANNOT_PARSE_SELECTOR]);
  }

  void test_Decorator_bad_missingSelector() {
    String mainContent = _createAngularSource(r'''
@Decorator(/*selector: '[my-dir]',*/
             map: const {
               'my-dir' : '=>myPropA',
               '.' : '&myPropB',
             })
class MyDirective {
  set myPropA(value) {}
  set myPropB(value) {}
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.MISSING_SELECTOR]);
  }

  void test_Formatter() {
    String mainContent = _createAngularSource(r'''
@Formatter(name: 'myFilter')
class MyFilter {
  call(p1, p2) {}
}''');
    resolveMainSourceNoErrors(mainContent);
    // prepare AngularFilterElement
    ClassElement classElement = mainUnitElement.getType("MyFilter");
    AngularFormatterElement filter =
        getAngularElement(classElement, (e) => e is AngularFormatterElement);
    expect(filter, isNotNull);
    // verify
    expect(filter.name, "myFilter");
    expect(filter.nameOffset, AngularTest.findOffset(mainContent, "myFilter'"));
  }

  void test_Formatter_missingName() {
    String mainContent = _createAngularSource(r'''
@Formatter()
class MyFilter {
  call(p1, p2) {}
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.MISSING_NAME]);
    // no filter
    ClassElement classElement = mainUnitElement.getType("MyFilter");
    AngularFormatterElement filter =
        getAngularElement(classElement, (e) => e is AngularFormatterElement);
    expect(filter, isNull);
  }

  void test_NgComponent_bad_cannotParseSelector() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: '~myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.CANNOT_PARSE_SELECTOR]);
  }

  void test_NgComponent_bad_missingSelector() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', /*selector: 'myComp',*/
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.MISSING_SELECTOR]);
  }

  /**
   *
   * https://code.google.com/p/dart/issues/detail?id=16346
   */
  void test_NgComponent_bad_notHtmlTemplate() {
    contextHelper.addSource("/my_template", "");
    contextHelper.addSource("/my_styles.css", "");
    addMainSource(
        _createAngularSource(r'''
@NgComponent(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template', cssUrl: 'my_styles.css')
class MyComponent {
}'''));
    contextHelper.runTasks();
  }

  void test_NgComponent_bad_properties_invalidBinding() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {'name' : '?field'})
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.INVALID_PROPERTY_KIND]);
  }

  void test_NgComponent_bad_properties_nameNotStringLiteral() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {null : 'field'})
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.INVALID_PROPERTY_NAME]);
  }

  void test_NgComponent_bad_properties_noSuchField() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {'name' : '=>field'})
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.INVALID_PROPERTY_FIELD]);
  }

  void test_NgComponent_bad_properties_notMapLiteral() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: null)
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.INVALID_PROPERTY_MAP]);
  }

  void test_NgComponent_bad_properties_specNotStringLiteral() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {'name' : null})
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.INVALID_PROPERTY_SPEC]);
  }

  void test_NgComponent_no_cssUrl() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html'/*, cssUrl: 'my_styles.css'*/)
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // no CSS
    expect(component.styleUri, null);
    expect(component.styleUriOffset, -1);
  }

  void test_NgComponent_no_publishAs() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(/*publishAs: 'ctrl',*/ selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // no name
    expect(component.name, null);
    expect(component.nameOffset, -1);
  }

  void test_NgComponent_no_templateUrl() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             /*templateUrl: 'my_template.html',*/ cssUrl: 'my_styles.css')
class MyComponent {
}''');
    resolveMainSource(mainContent);
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // no template
    expect(component.templateUri, null);
    expect(component.templateSource, null);
    expect(component.templateUriOffset, -1);
  }

  /**
   * https://code.google.com/p/dart/issues/detail?id=19023
   */
  void test_NgComponent_notAngular() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = r'''
class Component {
  const Component(a, b);
}

@Component('foo', 42)
class MyComponent {
}''';
    resolveMainSource(mainContent);
    assertNoMainErrors();
  }

  void test_NgComponent_properties_fieldFromSuper() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    resolveMainSourceNoErrors(
        _createAngularSource(r'''
class MySuper {
  var myPropA;
}



@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {
               'prop-a' : '@myPropA'
             })
class MyComponent extends MySuper {
}'''));
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // verify
    List<AngularPropertyElement> properties = component.properties;
    expect(properties, hasLength(1));
    _assertProperty(
        properties[0],
        "prop-a",
        findMainOffset("prop-a' :"),
        AngularPropertyKind.ATTR,
        "myPropA",
        findMainOffset("myPropA'"));
  }

  void test_NgComponent_properties_fromFields() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    resolveMainSourceNoErrors(
        _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
  @NgAttr('prop-a')
  var myPropA;
  @NgCallback('prop-b')
  var myPropB;
  @NgOneWay('prop-c')
  var myPropC;
  @NgOneWayOneTime('prop-d')
  var myPropD;
  @NgTwoWay('prop-e')
  var myPropE;
}'''));
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // verify
    List<AngularPropertyElement> properties = component.properties;
    expect(properties, hasLength(5));
    _assertProperty(
        properties[0],
        "prop-a",
        findMainOffset("prop-a')"),
        AngularPropertyKind.ATTR,
        "myPropA",
        -1);
    _assertProperty(
        properties[1],
        "prop-b",
        findMainOffset("prop-b')"),
        AngularPropertyKind.CALLBACK,
        "myPropB",
        -1);
    _assertProperty(
        properties[2],
        "prop-c",
        findMainOffset("prop-c')"),
        AngularPropertyKind.ONE_WAY,
        "myPropC",
        -1);
    _assertProperty(
        properties[3],
        "prop-d",
        findMainOffset("prop-d')"),
        AngularPropertyKind.ONE_WAY_ONE_TIME,
        "myPropD",
        -1);
    _assertProperty(
        properties[4],
        "prop-e",
        findMainOffset("prop-e')"),
        AngularPropertyKind.TWO_WAY,
        "myPropE",
        -1);
  }

  void test_NgComponent_properties_fromMap() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    resolveMainSourceNoErrors(
        _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {
               'prop-a' : '@myPropA',
               'prop-b' : '&myPropB',
               'prop-c' : '=>myPropC',
               'prop-d' : '=>!myPropD',
               'prop-e' : '<=>myPropE'
             })
class MyComponent {
  var myPropA;
  var myPropB;
  var myPropC;
  var myPropD;
  var myPropE;
}'''));
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // verify
    List<AngularPropertyElement> properties = component.properties;
    expect(properties, hasLength(5));
    _assertProperty(
        properties[0],
        "prop-a",
        findMainOffset("prop-a' :"),
        AngularPropertyKind.ATTR,
        "myPropA",
        findMainOffset("myPropA'"));
    _assertProperty(
        properties[1],
        "prop-b",
        findMainOffset("prop-b' :"),
        AngularPropertyKind.CALLBACK,
        "myPropB",
        findMainOffset("myPropB'"));
    _assertProperty(
        properties[2],
        "prop-c",
        findMainOffset("prop-c' :"),
        AngularPropertyKind.ONE_WAY,
        "myPropC",
        findMainOffset("myPropC'"));
    _assertProperty(
        properties[3],
        "prop-d",
        findMainOffset("prop-d' :"),
        AngularPropertyKind.ONE_WAY_ONE_TIME,
        "myPropD",
        findMainOffset("myPropD'"));
    _assertProperty(
        properties[4],
        "prop-e",
        findMainOffset("prop-e' :"),
        AngularPropertyKind.TWO_WAY,
        "myPropE",
        findMainOffset("myPropE'"));
  }

  void test_NgComponent_properties_no() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
}''');
    resolveMainSourceNoErrors(mainContent);
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // verify
    expect(component.name, "ctrl");
    expect(component.nameOffset, AngularTest.findOffset(mainContent, "ctrl'"));
    _assertIsTagSelector(component.selector, "myComp");
    expect(component.templateUri, "my_template.html");
    expect(component.templateUriOffset, AngularTest.findOffset(mainContent, "my_template.html'"));
    expect(component.styleUri, "my_styles.css");
    expect(component.styleUriOffset, AngularTest.findOffset(mainContent, "my_styles.css'"));
    expect(component.properties, hasLength(0));
  }

  void test_NgComponent_scopeProperties() {
    contextHelper.addSource("/my_template.html", "");
    contextHelper.addSource("/my_styles.css", "");
    String mainContent = _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
  MyComponent(Scope scope) {
    scope.context['boolProp'] = true;
    scope.context['intProp'] = 42;
    scope.context['stringProp'] = 'foo';
    // duplicate is ignored
    scope.context['boolProp'] = true;
    // LHS is not an IndexExpression
    var v1;
    v1 = 1;
    // LHS is not a Scope access
    var v2;
    v2['name'] = 2;
  }
}''');
    resolveMainSourceNoErrors(mainContent);
    // prepare AngularComponentElement
    ClassElement classElement = mainUnitElement.getType("MyComponent");
    AngularComponentElement component =
        getAngularElement(classElement, (e) => e is AngularComponentElement);
    expect(component, isNotNull);
    // verify
    List<AngularScopePropertyElement> scopeProperties =
        component.scopeProperties;
    expect(scopeProperties, hasLength(3));
    {
      AngularScopePropertyElement property = scopeProperties[0];
      expect(findMainElement2("boolProp"), same(property));
      expect(property.name, "boolProp");
      expect(property.nameOffset, AngularTest.findOffset(mainContent, "boolProp'"));
      expect(property.type.name, "bool");
    }
    {
      AngularScopePropertyElement property = scopeProperties[1];
      expect(findMainElement2("intProp"), same(property));
      expect(property.name, "intProp");
      expect(property.nameOffset, AngularTest.findOffset(mainContent, "intProp'"));
      expect(property.type.name, "int");
    }
    {
      AngularScopePropertyElement property = scopeProperties[2];
      expect(findMainElement2("stringProp"), same(property));
      expect(property.name, "stringProp");
      expect(property.nameOffset, AngularTest.findOffset(mainContent, "stringProp'"));
      expect(property.type.name, "String");
    }
  }

  void test_NgController() {
    String mainContent = _createAngularSource(r'''
@Controller(publishAs: 'ctrl', selector: '[myApp]')
class MyController {
}''');
    resolveMainSourceNoErrors(mainContent);
    // prepare AngularControllerElement
    ClassElement classElement = mainUnitElement.getType("MyController");
    AngularControllerElement controller =
        getAngularElement(classElement, (e) => e is AngularControllerElement);
    expect(controller, isNotNull);
    // verify
    expect(controller.name, "ctrl");
    expect(controller.nameOffset, AngularTest.findOffset(mainContent, "ctrl'"));
    _assertHasAttributeSelector(controller.selector, "myApp");
  }

  void test_NgController_cannotParseSelector() {
    String mainContent = _createAngularSource(r'''
@Controller(publishAs: 'ctrl', selector: '~unknown')
class MyController {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.CANNOT_PARSE_SELECTOR]);
  }

  void test_NgController_missingPublishAs() {
    String mainContent = _createAngularSource(r'''
@Controller(selector: '[myApp]')
class MyController {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.MISSING_PUBLISH_AS]);
  }

  void test_NgController_missingSelector() {
    String mainContent = _createAngularSource(r'''
@Controller(publishAs: 'ctrl')
class MyController {
}''');
    resolveMainSource(mainContent);
    // has error
    assertMainErrors([AngularCode.MISSING_SELECTOR]);
  }

  void test_NgController_noAnnotationArguments() {
    String mainContent =
        _createAngularSource(r'''
@NgController
class MyController {
}''');
    resolveMainSource(mainContent);
  }

  void test_bad_notConstructorAnnotation() {
    String mainContent = r'''
const MY_ANNOTATION = null;
@MY_ANNOTATION()
class MyFilter {
}''';
    resolveMainSource(mainContent);
    // prepare AngularFilterElement
    ClassElement classElement = mainUnitElement.getType("MyFilter");
    AngularFormatterElement filter =
        getAngularElement(classElement, (e) => e is AngularFormatterElement);
    expect(filter, isNull);
  }

  void test_getElement_SimpleStringLiteral_withToolkitElement() {
    SimpleStringLiteral literal = AstFactory.string2("foo");
    Element element = new AngularScopePropertyElementImpl("foo", 0, null);
    literal.toolkitElement = element;
    expect(AngularCompilationUnitBuilder.getElement(literal, -1), same(element));
  }

  void test_getElement_component_name() {
    resolveMainSource(
        _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {}'''));
    SimpleStringLiteral node =
        _findMainNode("ctrl'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // find AngularComponentElement
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularComponentElement,
        AngularComponentElement,
        element);
  }

  void test_getElement_component_property_fromFieldAnnotation() {
    resolveMainSource(
        _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {
  @NgOneWay('prop')
  var field;
}'''));
    // prepare node
    SimpleStringLiteral node =
        _findMainNode("prop'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // prepare Element
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    expect(element, isNotNull);
    // check AngularPropertyElement
    AngularPropertyElement property = element as AngularPropertyElement;
    expect(property.name, "prop");
  }

  void test_getElement_component_property_fromMap() {
    resolveMainSource(
        _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
             map: const {
               'prop' : '@field',
             })
class MyComponent {
  var field;
}'''));
    // AngularPropertyElement
    {
      SimpleStringLiteral node =
          _findMainNode("prop'", (n) => n is SimpleStringLiteral);
      int offset = node.offset;
      // prepare Element
      Element element = AngularCompilationUnitBuilder.getElement(node, offset);
      expect(element, isNotNull);
      // check AngularPropertyElement
      AngularPropertyElement property = element as AngularPropertyElement;
      expect(property.name, "prop");
    }
    // FieldElement
    {
      SimpleStringLiteral node =
          _findMainNode("@field'", (n) => n is SimpleStringLiteral);
      int offset = node.offset;
      // prepare Element
      Element element = AngularCompilationUnitBuilder.getElement(node, offset);
      expect(element, isNotNull);
      // check FieldElement
      FieldElement field = element as FieldElement;
      expect(field.name, "field");
    }
  }

  void test_getElement_component_selector() {
    resolveMainSource(
        _createAngularSource(r'''
@Component(publishAs: 'ctrl', selector: 'myComp',
             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')
class MyComponent {}'''));
    SimpleStringLiteral node =
        _findMainNode("myComp'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // find AngularSelectorElement
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularSelectorElement,
        AngularSelectorElement,
        element);
  }

  void test_getElement_controller_name() {
    resolveMainSource(
        _createAngularSource(r'''
@Controller(publishAs: 'ctrl', selector: '[myApp]')
class MyController {
}'''));
    SimpleStringLiteral node =
        _findMainNode("ctrl'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // find AngularControllerElement
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularControllerElement,
        AngularControllerElement,
        element);
  }

  void test_getElement_directive_property() {
    resolveMainSource(
        _createAngularSource(r'''
@Decorator(selector: '[my-dir]',
             map: const {
               'my-dir' : '=>field'
             })
class MyDirective {
  set field(value) {}
}'''));
    // prepare node
    SimpleStringLiteral node =
        _findMainNode("my-dir'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // prepare Element
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    expect(element, isNotNull);
    // check AngularPropertyElement
    AngularPropertyElement property = element as AngularPropertyElement;
    expect(property.name, "my-dir");
  }

  void test_getElement_directive_selector() {
    resolveMainSource(
        _createAngularSource(r'''
@Decorator(selector: '[my-dir]')
class MyDirective {}'''));
    SimpleStringLiteral node =
        _findMainNode("my-dir]'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // find AngularSelectorElement
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularSelectorElement,
        AngularSelectorElement,
        element);
  }

  void test_getElement_filter_name() {
    resolveMainSource(
        _createAngularSource(r'''
@Formatter(name: 'myFilter')
class MyFilter {
  call(p1, p2) {}
}'''));
    SimpleStringLiteral node =
        _findMainNode("myFilter'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // find FilterElement
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularFormatterElement,
        AngularFormatterElement,
        element);
  }

  void test_getElement_noClassDeclaration() {
    resolveMainSource("var foo = 'bar';");
    SimpleStringLiteral node =
        _findMainNode("bar'", (n) => n is SimpleStringLiteral);
    Element element = AngularCompilationUnitBuilder.getElement(node, 0);
    expect(element, isNull);
  }

  void test_getElement_noClassElement() {
    resolveMainSource(r'''
class A {
  const A(p);
}

@A('bar')
class B {}''');
    SimpleStringLiteral node =
        _findMainNode("bar'", (n) => n is SimpleStringLiteral);
    // reset B element
    ClassDeclaration classDeclaration =
        node.getAncestor((node) => node is ClassDeclaration);
    classDeclaration.name.staticElement = null;
    // class is not resolved - no element
    Element element = AngularCompilationUnitBuilder.getElement(node, 0);
    expect(element, isNull);
  }

  void test_getElement_noNode() {
    Element element = AngularCompilationUnitBuilder.getElement(null, 0);
    expect(element, isNull);
  }

  void test_getElement_notFound() {
    resolveMainSource(r'''
class MyComponent {
  var str = 'some string';
}''');
    // prepare node
    SimpleStringLiteral node =
        _findMainNode("some string'", (n) => n is SimpleStringLiteral);
    int offset = node.offset;
    // no Element
    Element element = AngularCompilationUnitBuilder.getElement(node, offset);
    expect(element, isNull);
  }

  void test_parseSelector_hasAttribute() {
    AngularSelectorElement selector =
        AngularCompilationUnitBuilder.parseSelector(42, "[name]");
    _assertHasAttributeSelector(selector, "name");
    expect(selector.nameOffset, 42 + 1);
  }

  void test_parseSelector_hasClass() {
    AngularSelectorElement selector =
        AngularCompilationUnitBuilder.parseSelector(42, ".my-class");
    AngularHasClassSelectorElementImpl classSelector =
        selector as AngularHasClassSelectorElementImpl;
    expect(classSelector.name, "my-class");
    expect(classSelector.toString(), ".my-class");
    expect(selector.nameOffset, 42 + 1);
    // test apply()
    {
      ht.XmlTagNode node =
          HtmlFactory.tagNode("div", [HtmlFactory.attribute("class", "one two")]);
      expect(classSelector.apply(node), isFalse);
    }
    {
      ht.XmlTagNode node = HtmlFactory.tagNode(
          "div",
          [HtmlFactory.attribute("class", "one my-class two")]);
      expect(classSelector.apply(node), isTrue);
    }
  }

  void test_parseSelector_isTag() {
    AngularSelectorElement selector =
        AngularCompilationUnitBuilder.parseSelector(42, "name");
    _assertIsTagSelector(selector, "name");
    expect(selector.nameOffset, 42);
  }

  void test_parseSelector_isTag_hasAttribute() {
    AngularSelectorElement selector =
        AngularCompilationUnitBuilder.parseSelector(42, "tag[attr]");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IsTagHasAttributeSelectorElementImpl,
        IsTagHasAttributeSelectorElementImpl,
        selector);
    expect(selector.name, "tag[attr]");
    expect(selector.nameOffset, -1);
    expect((selector as IsTagHasAttributeSelectorElementImpl).tagName, "tag");
    expect((selector as IsTagHasAttributeSelectorElementImpl).attributeName, "attr");
  }

  void test_parseSelector_unknown() {
    AngularSelectorElement selector =
        AngularCompilationUnitBuilder.parseSelector(0, "~unknown");
    expect(selector, isNull);
  }

  void test_view() {
    contextHelper.addSource("/wrong.html", "");
    contextHelper.addSource("/my_templateA.html", "");
    contextHelper.addSource("/my_templateB.html", "");
    String mainContent = _createAngularSource(r'''
class MyRouteInitializer {
  init(ViewFactory view, foo) {
    foo.view('wrong.html');   // has target
    foo();                    // less than one argument
    foo('wrong.html', 'bar'); // more than one argument
    foo('wrong' + '.html');   // not literal
    foo('wrong.html');        // not ViewFactory
    view('my_templateA.html');
    view('my_templateB.html');
  }
}''');
    resolveMainSourceNoErrors(mainContent);
    // prepare AngularViewElement(s)
    List<AngularViewElement> views = mainUnitElement.angularViews;
    expect(views, hasLength(2));
    {
      AngularViewElement view = views[0];
      expect(view.templateUri, "my_templateA.html");
      expect(view.name, null);
      expect(view.nameOffset, -1);
      expect(view.templateUriOffset, AngularTest.findOffset(mainContent, "my_templateA.html'"));
    }
    {
      AngularViewElement view = views[1];
      expect(view.templateUri, "my_templateB.html");
      expect(view.name, null);
      expect(view.nameOffset, -1);
      expect(view.templateUriOffset, AngularTest.findOffset(mainContent, "my_templateB.html'"));
    }
  }

  void _assertProperty(AngularPropertyElement property, String expectedName,
      int expectedNameOffset, AngularPropertyKind expectedKind,
      String expectedFieldName, int expectedFieldOffset) {
    expect(property.name, expectedName);
    expect(property.nameOffset, expectedNameOffset);
    expect(property.propertyKind, same(expectedKind));
    expect(property.field.name, expectedFieldName);
    expect(property.fieldNameOffset, expectedFieldOffset);
  }

  /**
   * Find [AstNode] of the given type in [mainUnit].
   */
  AstNode _findMainNode(String search, Predicate<AstNode> predicate) {
    return EngineTestCase.findNode(mainUnit, mainContent, search, predicate);
  }

  static AngularElement getAngularElement(Element element,
      Predicate<Element> predicate) {
    List<ToolkitObjectElement> toolkitObjects = null;
    if (element is ClassElement) {
      ClassElement classElement = element;
      toolkitObjects = classElement.toolkitObjects;
    }
    if (element is LocalVariableElement) {
      LocalVariableElement variableElement = element;
      toolkitObjects = variableElement.toolkitObjects;
    }
    if (toolkitObjects != null) {
      for (ToolkitObjectElement toolkitObject in toolkitObjects) {
        if (predicate(toolkitObject)) {
          return toolkitObject as AngularElement;
        }
      }
    }
    return null;
  }

  static void _assertHasAttributeSelector(AngularSelectorElement selector,
      String name) {
    EngineTestCase.assertInstanceOf(
        (obj) => obj is HasAttributeSelectorElementImpl,
        HasAttributeSelectorElementImpl,
        selector);
    expect((selector as HasAttributeSelectorElementImpl).name, name);
  }

  static void _assertIsTagSelector(AngularSelectorElement selector,
      String name) {
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularTagSelectorElementImpl,
        AngularTagSelectorElementImpl,
        selector);
    expect((selector as AngularTagSelectorElementImpl).name, name);
  }

  static String _createAngularSource(String code) {
    return "import 'angular.dart';\n" + code;
  }
}


class AngularHtmlUnitResolverTest extends AngularTest {
  void test_NgComponent_resolveTemplateFile() {
    addMainSource(r'''
import 'angular.dart';

@Component(
    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
  String field;
}''');
    contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    addIndexSource2(
        "/my_template.html",
        r'''
<div>
  {{ctrl.field}}
</div>''');
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    resolveIndex();
    assertNoErrors();
    assertResolvedIdentifier2("ctrl.", "MyComponent");
    assertResolvedIdentifier2("field}}", "String");
  }

  void test_NgComponent_updateDartFile() {
    Source componentSource = contextHelper.addSource(
        "/my_component.dart",
        r'''
library my.component;
import 'angular.dart';
@Component(selector: 'myComponent')
class MyComponent {
}''');
    contextHelper.addSource(
        "/my_module.dart",
        r'''
library my.module;
import 'my_component.dart';''');
    addMainSource(r'''
library main;
import 'my_module.dart';''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController("<myComponent/>"));
    // "myComponent" tag was resolved
    {
      ht.XmlTagNode tagNode =
          ht.HtmlUnitUtils.getTagNode(indexUnit, findOffset2("myComponent"));
      AngularSelectorElement tagElement =
          tagNode.element as AngularSelectorElement;
      expect(tagElement, isNotNull);
      expect(tagElement.name, "myComponent");
    }
    // replace "myComponent" with "myComponent2"
    // in my_component.dart and index.html
    {
      context.setContents(
          componentSource,
          _getSourceContent(componentSource).replaceAll("myComponent", "myComponent2"));
      indexContent =
          _getSourceContent(indexSource).replaceAll("myComponent", "myComponent2");
      context.setContents(indexSource, indexContent);
    }
    contextHelper.runTasks();
    resolveIndex();
    // "myComponent2" tag should be resolved
    {
      ht.XmlTagNode tagNode =
          ht.HtmlUnitUtils.getTagNode(indexUnit, findOffset2("myComponent2"));
      AngularSelectorElement tagElement =
          tagNode.element as AngularSelectorElement;
      expect(tagElement, isNotNull);
      expect(tagElement.name, "myComponent2");
    }
  }

  void test_NgComponent_use_resolveAttributes() {
    contextHelper.addSource(
        "/my_template.html",
        r'''
    <div>
      {{ctrl.field}}
    </div>''');
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent', // selector
    map: const {'attrA' : '=>setA', 'attrB' : '@setB'})
class MyComponent {
  set setA(value) {}
  set setB(value) {}
}''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<input type='text' ng-model='someModel'/>
<myComponent attrA='someModel' attrB='bbb'/>'''));
    // "attrA" attribute expression was resolved
    expect(findIdentifier("someModel"), isNotNull);
    // "myComponent" tag was resolved
    ht.XmlTagNode tagNode =
        ht.HtmlUnitUtils.getTagNode(indexUnit, findOffset2("myComponent"));
    AngularSelectorElement tagElement =
        tagNode.element as AngularSelectorElement;
    expect(tagElement, isNotNull);
    expect(tagElement.name, "myComponent");
    expect(tagElement.nameOffset, findMainOffset("myComponent', // selector"));
    // "attrA" attribute was resolved
    {
      ht.XmlAttributeNode node =
          ht.HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("attrA='"));
      AngularPropertyElement element = node.element as AngularPropertyElement;
      expect(element, isNotNull);
      expect(element.name, "attrA");
      expect(element.field.name, "setA");
    }
    // "attrB" attribute was resolved, even if it @binding
    {
      ht.XmlAttributeNode node =
          ht.HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("attrB='"));
      AngularPropertyElement element = node.element as AngularPropertyElement;
      expect(element, isNotNull);
      expect(element.name, "attrB");
      expect(element.field.name, "setB");
    }
  }

  void test_NgDirective_noAttribute() {
    addMainSource(r'''

import 'angular.dart';

@NgDirective(selector: '[my-directive]', map: const {'foo': '=>input'})
class MyDirective {
  set input(value) {}
}''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<div my-directive>
</div>'''));
  }

  void test_NgDirective_noExpression() {
    addMainSource(r'''

import 'angular.dart';

@NgDirective(selector: '[my-directive]', map: const {'.': '=>input'})
class MyDirective {
  set input(value) {}
}''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<div my-directive>
</div>'''));
  }

  void test_NgDirective_resolvedExpression() {
    addMainSource(r'''

import 'angular.dart';

@Decorator(selector: '[my-directive]')
class MyDirective {
  @NgOneWay('my-property')
  String condition;
}''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<input type='text' ng-model='name'>
<div my-directive my-property='name != null'>
</div>'''));
    resolveMainNoErrors();
    // "my-directive" attribute was resolved
    {
      AngularSelectorElement selector =
          findMainElement(ElementKind.ANGULAR_SELECTOR, "my-directive");
      ht.XmlAttributeNode attrNodeSelector =
          ht.HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("my-directive"));
      expect(attrNodeSelector, isNotNull);
      expect(attrNodeSelector.element, same(selector));
    }
    // "my-property" attribute was resolved
    {
      ht.XmlAttributeNode attrNodeProperty =
          ht.HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("my-property='"));
      AngularPropertyElement propertyElement =
          attrNodeProperty.element as AngularPropertyElement;
      expect(propertyElement, isNotNull);
      expect(propertyElement.propertyKind, same(AngularPropertyKind.ONE_WAY));
      expect(propertyElement.field.name, "condition");
    }
    // "name" expression was resolved
    expect(findIdentifier("name != null"), isNotNull);
  }

  void test_NgDirective_resolvedExpression_attrString() {
    addMainSource(r'''

import 'angular.dart';

@NgDirective(selector: '[my-directive])
class MyDirective {
  @NgAttr('my-property')
  String property;
}''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<input type='text' ng-model='name'>
<div my-directive my-property='name != null'>
</div>'''));
    resolveMain();
    // @NgAttr means "string attribute", which we don't parse
    expect(findIdentifierMaybe("name != null"), isNull);
  }

  void test_NgDirective_resolvedExpression_dotAsName() {
    addMainSource(r'''

import 'angular.dart';

@Decorator(
    selector: '[my-directive]',
    map: const {'.' : '=>condition'})
class MyDirective {
  set condition(value) {}
}''');
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<input type='text' ng-model='name'>
<div my-directive='name != null'>
</div>'''));
    // "name" attribute was resolved
    expect(findIdentifier("name != null"), isNotNull);
  }

  void fail_analysisContext_changeDart_invalidateApplication() {
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
}''');
    contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    addIndexSource2(
        "/my_template.html",
        r'''
<div>
  {{ctrl.noMethod()}}
</div>''');
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    // there are some errors in my_template.html
    {
      List<AnalysisError> errors = context.getErrors(indexSource).errors;
      expect(errors.length != 0, isTrue);
    }
    // change main.dart, there are no MyComponent anymore
    context.setContents(mainSource, "");
    // ...errors in my_template.html should be removed
    {
      List<AnalysisError> errors = context.getErrors(indexSource).errors;
      expect(errors, isEmpty);
      expect(errors.length == 0, isTrue);
    }
  }

  void test_analysisContext_changeEntryPoint_clearAngularErrors_inDart() {
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'no-such-template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
}''');
    Source entrySource = contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    // there are some errors in MyComponent
    {
      List<AnalysisError> errors = context.getErrors(mainSource).errors;
      expect(errors.length != 0, isTrue);
    }
    // make entry-point.html non-Angular
    context.setContents(entrySource, "<html/>");
    // ...errors in MyComponent should be removed
    {
      List<AnalysisError> errors = context.getErrors(mainSource).errors;
      expect(errors.length == 0, isTrue);
    }
  }

  void test_analysisContext_changeEntryPoint_clearAngularErrors_inTemplate() {
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
}''');
    Source entrySource = contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    addIndexSource2(
        "/my_template.html",
        r'''
<div>
  {{ctrl.noMethod()}}
</div>''');
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    // there are some errors in my_template.html
    {
      List<AnalysisError> errors = context.getErrors(indexSource).errors;
      expect(errors.length != 0, isTrue);
    }
    // make entry-point.html non-Angular
    context.setContents(entrySource, "<html/>");
    // ...errors in my_template.html should be removed
    {
      List<AnalysisError> errors = context.getErrors(indexSource).errors;
      expect(errors.length == 0, isTrue);
    }
  }

  void test_analysisContext_removeEntryPoint_clearAngularErrors_inDart() {
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'no-such-template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
}''');
    Source entrySource = contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    // there are some errors in MyComponent
    {
      List<AnalysisError> errors = context.getErrors(mainSource).errors;
      expect(errors.length != 0, isTrue);
    }
    // remove entry-point.html
    {
      ChangeSet changeSet = new ChangeSet();
      changeSet.removedSource(entrySource);
      context.applyChanges(changeSet);
    }
    // ...errors in MyComponent should be removed
    {
      List<AnalysisError> errors = context.getErrors(mainSource).errors;
      expect(errors.length == 0, isTrue);
    }
  }

  void test_contextProperties() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithAngular(r'''
<div>
  {{$id}}
  {{$parent}}
  {{$root}}
</div>'''));
    assertResolvedIdentifier("\$id");
    assertResolvedIdentifier("\$parent");
    assertResolvedIdentifier("\$root");
  }

  void test_getAngularElement_isAngular() {
    // prepare local variable "name" in compilation unit
    CompilationUnitElementImpl unit =
        ElementFactory.compilationUnit("test.dart");
    FunctionElementImpl function = ElementFactory.functionElement("main");
    unit.functions = <FunctionElement>[function];
    LocalVariableElementImpl local =
        ElementFactory.localVariableElement2("name");
    function.localVariables = <LocalVariableElement>[local];
    // set AngularElement
    AngularElement angularElement = new AngularControllerElementImpl("ctrl", 0);
    local.toolkitObjects = <AngularElement>[angularElement];
    expect(AngularHtmlUnitResolver.getAngularElement(local), same(angularElement));
  }

  void test_getAngularElement_notAngular() {
    Element element = ElementFactory.localVariableElement2("name");
    expect(AngularHtmlUnitResolver.getAngularElement(element), isNull);
  }

  void test_getAngularElement_notLocal() {
    Element element = ElementFactory.classElement2("Test");
    expect(AngularHtmlUnitResolver.getAngularElement(element), isNull);
  }

  /**
   * Test that we resolve "ng-click" expression.
   */
  void test_ngClick() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r"<button ng-click='ctrl.doSomething($event)'/>"));
    assertResolvedIdentifier("doSomething");
  }

  /**
   * Test that we resolve "ng-if" expression.
   */
  void test_ngIf() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController("<div ng-if='ctrl.field != null'/>"));
    assertResolvedIdentifier("field");
  }

  void test_ngModel_modelAfterUsage() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<h3>Hello {{name}}!</h3>
<input type='text' ng-model='name'>'''));
    assertResolvedIdentifier2("name}}!", "String");
    assertResolvedIdentifier2("name'>", "String");
  }

  void test_ngModel_modelBeforeUsage() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<input type='text' ng-model='name'>
<h3>Hello {{name}}!</h3>'''));
    assertResolvedIdentifier2("name}}!", "String");
    Element element = assertResolvedIdentifier2("name'>", "String");
    expect(element.name, "name");
    expect(element.nameOffset, findOffset2("name'>"));
  }

  void test_ngModel_notIdentifier() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController("<input type='text' ng-model='ctrl.field'>"));
    assertResolvedIdentifier2("field'>", "String");
  }

  /**
   * Test that we resolve "ng-mouseout" expression.
   */
  void test_ngMouseOut() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r"<button ng-mouseout='ctrl.doSomething($event)'/>"));
    assertResolvedIdentifier("doSomething");
  }

  void fail_ngRepeat_additionalVariables() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='name in ctrl.names'>
  {{$index}} {{$first}} {{$middle}} {{$last}} {{$even}} {{$odd}}
</li>'''));
    assertResolvedIdentifier2("\$index", "int");
    assertResolvedIdentifier2("\$first", "bool");
    assertResolvedIdentifier2("\$middle", "bool");
    assertResolvedIdentifier2("\$last", "bool");
    assertResolvedIdentifier2("\$even", "bool");
    assertResolvedIdentifier2("\$odd", "bool");
  }

  void fail_ngRepeat_bad_expectedIdentifier() {
    addMyController();
    resolveIndex2(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='name + 42 in ctrl.names'>
</li>'''));
    assertErrors(indexSource, [AngularCode.INVALID_REPEAT_ITEM_SYNTAX]);
  }

  void fail_ngRepeat_bad_expectedIn() {
    addMyController();
    resolveIndex2(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='name : ctrl.names'>
</li>'''));
    assertErrors(indexSource, [AngularCode.INVALID_REPEAT_SYNTAX]);
  }

  void fail_ngRepeat_filters_filter_literal() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='item in ctrl.items | filter:42:null'/>
</li>'''));
    // filter "filter" is resolved
    Element filterElement = assertResolvedIdentifier("filter");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularFormatterElement,
        AngularFormatterElement,
        filterElement);
  }

  void fail_ngRepeat_filters_filter_propertyMap() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='item in ctrl.items | filter:{name:null, done:false}'/>
</li>'''));
    assertResolvedIdentifier2("name:", "String");
    assertResolvedIdentifier2("done:", "bool");
  }

  void fail_ngRepeat_filters_missingColon() {
    addMyController();
    resolveIndex2(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:'' true"/>
</li>'''));
    assertErrors(indexSource, [AngularCode.MISSING_FORMATTER_COLON]);
  }

  void fail_ngRepeat_filters_noArgs() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy"/>
</li>'''));
    // filter "orderBy" is resolved
    Element filterElement = assertResolvedIdentifier("orderBy");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularFormatterElement,
        AngularFormatterElement,
        filterElement);
  }

  void fail_ngRepeat_filters_orderBy_emptyString() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:'':true"/>
</li>'''));
    // filter "orderBy" is resolved
    Element filterElement = assertResolvedIdentifier("orderBy");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularFormatterElement,
        AngularFormatterElement,
        filterElement);
  }

  void fail_ngRepeat_filters_orderBy_propertyList() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:['name', 'done']"/>
</li>'''));
    assertResolvedIdentifier2("name'", "String");
    assertResolvedIdentifier2("done'", "bool");
  }

  void fail_ngRepeat_filters_orderBy_propertyName() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:'name'"/>
</li>'''));
    assertResolvedIdentifier2("name'", "String");
  }

  void fail_ngRepeat_filters_orderBy_propertyName_minus() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:'-name'"/>
</li>'''));
    assertResolvedIdentifier2("name'", "String");
  }

  void fail_ngRepeat_filters_orderBy_propertyName_plus() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:'+name'"/>
</li>'''));
    assertResolvedIdentifier2("name'", "String");
  }

  void fail_ngRepeat_filters_orderBy_propertyName_untypedItems() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.untypedItems | orderBy:'name'"/>
</li>'''));
    assertResolvedIdentifier2("name'", "dynamic");
  }

  void fail_ngRepeat_filters_two() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat="item in ctrl.items | orderBy:'+' | orderBy:'-'"/>
</li>'''));
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularFormatterElement,
        AngularFormatterElement,
        assertResolvedIdentifier("orderBy:'+'"));
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularFormatterElement,
        AngularFormatterElement,
        assertResolvedIdentifier("orderBy:'-'"));
  }

  void fail_ngRepeat_resolvedExpressions() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='name in ctrl.names'>
  {{name}}
</li>'''));
    assertResolvedIdentifier2("name in", "String");
    assertResolvedIdentifier2("ctrl.", "MyController");
    assertResolvedIdentifier2("names'", "List<String>");
    assertResolvedIdentifier2("name}}", "String");
  }

  void fail_ngRepeat_trackBy() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController(r'''
<li ng-repeat='name in ctrl.names track by name.length'/>
</li>'''));
    assertResolvedIdentifier2("length'", "int");
  }

  /**
   * Test that we resolve "ng-show" expression.
   */
  void test_ngShow() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController("<div ng-show='ctrl.field != null'/>"));
    assertResolvedIdentifier("field");
  }

  void test_notResolved_noDartScript() {
    resolveIndex2(r'''
<html ng-app>
  <body>
    <div my-marker>
      {{ctrl.field}}
    </div>
  </body>
</html>''');
    assertNoErrors();
    // Angular is not initialized, so "ctrl" is not parsed
    Expression expression =
        ht.HtmlUnitUtils.getExpression(indexUnit, findOffset2("ctrl"));
    expect(expression, isNull);
  }

  void test_notResolved_notAngular() {
    resolveIndex2(r'''
<html no-ng-app>
  <body>
    <div my-marker>
      {{ctrl.field}}
    </div>
  </body>
</html>''');
    assertNoErrors();
    // Angular is not initialized, so "ctrl" is not parsed
    Expression expression =
        ht.HtmlUnitUtils.getExpression(indexUnit, findOffset2("ctrl"));
    expect(expression, isNull);
  }

  void test_notResolved_wrongControllerMarker() {
    addMyController();
    addIndexSource(r'''
<html ng-app>
  <body>
    <div not-my-marker>
      {{ctrl.field}}
    </div>
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''');
    contextHelper.runTasks();
    resolveIndex();
    // no errors, because we decided to ignore them at the moment
    assertNoErrors();
    // "ctrl" is not resolved
    SimpleIdentifier identifier = findIdentifier("ctrl");
    expect(identifier.bestElement, isNull);
  }

  void test_resolveExpression_evenWithout_ngBootstrap() {
    resolveMainSource(r'''

import 'angular.dart';

@Controller(
    selector: '[my-controller]',
    publishAs: 'ctrl')
class MyController {
  String field;
}''');
    _resolveIndexNoErrors(r'''
<html ng-app>
  <body>
    <div my-controller>
      {{ctrl.field}}
    </div>
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''');
    assertResolvedIdentifier2("ctrl.", "MyController");
  }

  void test_resolveExpression_ignoreUnresolved() {
    resolveMainSource(r'''

import 'angular.dart';

@Controller(
    selector: '[my-controller]',
    publishAs: 'ctrl')
class MyController {
  Map map;
  Object obj;
}''');
    resolveIndex2(r'''
<html ng-app>
  <body>
    <div my-controller>
      {{ctrl.map.property}}
      {{ctrl.obj.property}}
      {{invisibleScopeProperty}}
    </div>
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''');
    assertNoErrors();
    // "ctrl.map" and "ctrl.obj" are resolved
    assertResolvedIdentifier2("map", "Map<dynamic, dynamic>");
    assertResolvedIdentifier2("obj", "Object");
    // ...but not "invisibleScopeProperty"
    {
      SimpleIdentifier identifier = findIdentifier("invisibleScopeProperty");
      expect(identifier.bestElement, isNull);
    }
  }

  void test_resolveExpression_inAttribute() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController("<button title='{{ctrl.field}}'></button>"));
    assertResolvedIdentifier2("ctrl", "MyController");
  }

  void test_resolveExpression_ngApp_onBody() {
    addMyController();
    _resolveIndexNoErrors(r'''
<html>
  <body ng-app>
    <div my-controller>
      {{ctrl.field}}
    </div>
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''');
    assertResolvedIdentifier2("ctrl", "MyController");
  }

  void test_resolveExpression_withFormatter() {
    addMyController();
    _resolveIndexNoErrors(
        AngularTest.createHtmlWithMyController("{{ctrl.field | uppercase}}"));
    assertResolvedIdentifier2("ctrl", "MyController");
    assertResolvedIdentifier("uppercase");
  }

  void test_resolveExpression_withFormatter_missingColon() {
    addMyController();
    resolveIndex2(
        AngularTest.createHtmlWithMyController("{{ctrl.field | uppercase, lowercase}}"));
    assertErrors(indexSource, [AngularCode.MISSING_FORMATTER_COLON]);
  }

  void test_resolveExpression_withFormatter_notSimpleIdentifier() {
    addMyController();
    resolveIndex2(
        AngularTest.createHtmlWithMyController("{{ctrl.field | not.supported}}"));
    assertErrors(indexSource, [AngularCode.INVALID_FORMATTER_NAME]);
  }

  void test_scopeProperties() {
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
  String field;
  MyComponent(Scope scope) {
    scope.context['scopeProperty'] = 'abc';
  }
}
''');
    contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    addIndexSource2(
        "/my_template.html",
        r'''
<div>
  {{scopeProperty}}
</div>''');
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    resolveIndex();
    assertNoErrors();
    // "scopeProperty" is resolved
    Element element = assertResolvedIdentifier2("scopeProperty}}", "String");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularScopePropertyElement,
        AngularScopePropertyElement,
        AngularHtmlUnitResolver.getAngularElement(element));
  }

  void test_scopeProperties_hideWithComponent() {
    addMainSource(r'''

import 'angular.dart';

@Component(
    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',
    publishAs: 'ctrl',
    selector: 'myComponent')
class MyComponent {
}

void setScopeProperties(Scope scope) {
  scope.context['ctrl'] = 1;
}
''');
    contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    addIndexSource2(
        "/my_template.html",
        r'''
<div>
  {{ctrl}}
</div>''');
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    resolveIndex();
    assertNoErrors();
    // "ctrl" is resolved
    LocalVariableElement element =
        assertResolvedIdentifier("ctrl}}") as LocalVariableElement;
    List<ToolkitObjectElement> toolkitObjects = element.toolkitObjects;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularComponentElement,
        AngularComponentElement,
        toolkitObjects[0]);
  }

  void test_view_resolveTemplateFile() {
    addMainSource(r'''

import 'angular.dart';

@Controller(
    selector: '[my-controller]',
    publishAs: 'ctrl')
class MyController {
  String field;
}

class MyRouteInitializer {
  init(ViewFactory view) {
    view('my_template.html');
  }
}''');
    contextHelper.addSource(
        "/entry-point.html",
        AngularTest.createHtmlWithAngular(''));
    addIndexSource2(
        "/my_template.html",
        r'''
<div my-controller>
  {{ctrl.field}}
</div>''');
    contextHelper.addSource("/my_styles.css", "");
    contextHelper.runTasks();
    resolveIndex();
    assertNoErrors();
    assertResolvedIdentifier2("ctrl.", "MyController");
    assertResolvedIdentifier2("field}}", "String");
  }

  String _getSourceContent(Source source) {
    return context.getContents(source).data.toString();
  }

  void _resolveIndexNoErrors(String content) {
    resolveIndex2(content);
    assertNoErrors();
    verify([indexSource]);
  }
}


/**
 * Tests for [HtmlUnitUtils] for Angular HTMLs.
 */
class AngularHtmlUnitUtilsTest extends AngularTest {
  void test_getElementToOpen_controller() {
    addMyController();
    _resolveSimpleCtrlFieldHtml();
    // prepare expression
    int offset = indexContent.indexOf("ctrl");
    Expression expression = ht.HtmlUnitUtils.getExpression(indexUnit, offset);
    // get element
    Element element = ht.HtmlUnitUtils.getElementToOpen(indexUnit, expression);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AngularControllerElement,
        AngularControllerElement,
        element);
    expect(element.name, "ctrl");
  }

  void test_getElementToOpen_field() {
    addMyController();
    _resolveSimpleCtrlFieldHtml();
    // prepare expression
    int offset = indexContent.indexOf("field");
    Expression expression = ht.HtmlUnitUtils.getExpression(indexUnit, offset);
    // get element
    Element element = ht.HtmlUnitUtils.getElementToOpen(indexUnit, expression);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement,
        element);
    expect(element.name, "field");
  }

  void test_getElement_forExpression() {
    addMyController();
    _resolveSimpleCtrlFieldHtml();
    // prepare expression
    int offset = indexContent.indexOf("ctrl");
    Expression expression = ht.HtmlUnitUtils.getExpression(indexUnit, offset);
    // get element
    Element element = ht.HtmlUnitUtils.getElement(expression);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is VariableElement,
        VariableElement,
        element);
    expect(element.name, "ctrl");
  }

  void test_getElement_forExpression_null() {
    Element element = ht.HtmlUnitUtils.getElement(null);
    expect(element, isNull);
  }

  void test_getElement_forOffset() {
    addMyController();
    _resolveSimpleCtrlFieldHtml();
    // no expression
    {
      Element element = ht.HtmlUnitUtils.getElementAtOffset(indexUnit, 0);
      expect(element, isNull);
    }
    // has expression at offset
    {
      int offset = indexContent.indexOf("field");
      Element element = ht.HtmlUnitUtils.getElementAtOffset(indexUnit, offset);
      EngineTestCase.assertInstanceOf(
          (obj) => obj is PropertyAccessorElement,
          PropertyAccessorElement,
          element);
      expect(element.name, "field");
    }
  }

  void test_getEnclosingTagNode() {
    resolveIndex2(r'''
<html>
  <body ng-app>
    <badge name='abc'> 123 </badge>
  </body>
</html>''');
    // no unit
    expect(ht.HtmlUnitUtils.getEnclosingTagNode(null, 0), isNull);
    // wrong offset
    expect(ht.HtmlUnitUtils.getEnclosingTagNode(indexUnit, -1), isNull);
    // valid offset
    ht.XmlTagNode expected = _getEnclosingTagNode("<badge");
    expect(expected, isNotNull);
    expect(expected.tag, "badge");
    expect(_getEnclosingTagNode("badge"), same(expected));
    expect(_getEnclosingTagNode("name="), same(expected));
    expect(_getEnclosingTagNode("123"), same(expected));
    expect(_getEnclosingTagNode("/badge"), same(expected));
  }

  void test_getExpression() {
    addMyController();
    _resolveSimpleCtrlFieldHtml();
    // try offset without expression
    expect(ht.HtmlUnitUtils.getExpression(indexUnit, 0), isNull);
    // try offset with expression
    int offset = indexContent.indexOf("ctrl");
    expect(ht.HtmlUnitUtils.getExpression(indexUnit, offset), isNotNull);
    expect(ht.HtmlUnitUtils.getExpression(indexUnit, offset + 1), isNotNull);
    expect(ht.HtmlUnitUtils.getExpression(indexUnit, offset + 2), isNotNull);
    expect(ht.HtmlUnitUtils.getExpression(indexUnit, offset + "ctrl.field".length), isNotNull);
    // try without unit
    expect(ht.HtmlUnitUtils.getExpression(null, offset), isNull);
  }

  void test_getTagNode() {
    resolveIndex2(r'''
<html>
  <body ng-app>
    <badge name='abc'> 123 </badge> done
  </body>
</html>''');
    // no unit
    expect(ht.HtmlUnitUtils.getTagNode(null, 0), isNull);
    // wrong offset
    expect(ht.HtmlUnitUtils.getTagNode(indexUnit, -1), isNull);
    // on tag name
    ht.XmlTagNode expected = _getTagNode("badge name=");
    expect(expected, isNotNull);
    expect(expected.tag, "badge");
    expect(_getTagNode("badge"), same(expected));
    expect(_getTagNode(" name="), same(expected));
    expect(_getTagNode("adge name="), same(expected));
    expect(_getTagNode("badge>"), same(expected));
    expect(_getTagNode("adge>"), same(expected));
    expect(_getTagNode("> done"), same(expected));
    // in tag node, but not on the name token
    expect(_getTagNode("name="), isNull);
    expect(_getTagNode("123"), isNull);
  }

  ht.XmlTagNode _getEnclosingTagNode(String search) {
    return ht.HtmlUnitUtils.getEnclosingTagNode(
        indexUnit,
        indexContent.indexOf(search));
  }

  ht.XmlTagNode _getTagNode(String search) {
    return ht.HtmlUnitUtils.getTagNode(indexUnit, indexContent.indexOf(search));
  }

  void _resolveSimpleCtrlFieldHtml() {
    resolveIndex2(r'''
<html>
  <body ng-app>
    <div my-controller>
      {{ctrl.field}}
    </div>
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''');
  }
}


abstract class AngularTest extends EngineTestCase {
  AnalysisContextHelper contextHelper = new AnalysisContextHelper();

  AnalysisContext context;

  String mainContent;

  Source mainSource;

  CompilationUnit mainUnit;

  CompilationUnitElement mainUnitElement;
  String indexContent;
  Source indexSource;
  ht.HtmlUnit indexUnit;
  HtmlElement indexHtmlUnit;
  CompilationUnitElement indexDartUnitElement;
  /**
   * Fills [indexContent] and [indexSource].
   */
  void addIndexSource(String content) {
    addIndexSource2("/index.html", content);
  }
  /**
   * Fills [indexContent] and [indexSource].
   */
  void addIndexSource2(String name, String content) {
    indexContent = content;
    indexSource = contextHelper.addSource(name, indexContent);
  }
  /**
   * Fills [mainContent] and [mainSource].
   */
  void addMainSource(String content) {
    mainContent = content;
    mainSource = contextHelper.addSource("/main.dart", content);
  }
  void addMyController() {
    resolveMainSource(r'''

import 'angular.dart';

class Item {
  String name;
  bool done;
}

@Controller(
    selector: '[my-controller]',
    publishAs: 'ctrl')
class MyController {
  String field;
  List<String> names;
  List<Item> items;
  var untypedItems;
  doSomething(event) {}
}''');
  }
  /**
   * Assert that the number of errors reported against the given source matches the number of errors
   * that are given and that they have the expected error codes. The order in which the errors were
   * gathered is ignored.
   *
   * @param source the source against which the errors should have been reported
   * @param expectedErrorCodes the error codes of the errors that should have been reported
   * @throws AnalysisException if the reported errors could not be computed
   * @throws AssertionFailedError if a different number of errors have been reported than were
   *           expected
   */
  void assertErrors(Source source, [List<ErrorCode> expectedErrorCodes = ErrorCode.EMPTY_LIST]) {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    AnalysisErrorInfo errorsInfo = context.getErrors(source);
    for (AnalysisError error in errorsInfo.errors) {
      errorListener.onError(error);
    }
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  void assertMainErrors(List<ErrorCode> expectedErrorCodes) {
    assertErrors(mainSource, expectedErrorCodes);
  }

  /**
   * Assert that no errors have been reported against the [indexSource].
   */
  void assertNoErrors() {
    assertErrors(indexSource);
  }

  void assertNoErrors2(Source source) {
    assertErrors(source);
  }

  /**
   * Assert that no errors have been reported against the [mainSource].
   */
  void assertNoMainErrors() {
    assertErrors(mainSource);
  }

  /**
   * Checks that [indexHtmlUnit] has [SimpleIdentifier] with given name, resolved to
   * not `null` [Element].
   */
  Element assertResolvedIdentifier(String name) {
    SimpleIdentifier identifier = findIdentifier(name);
    // check Element
    Element element = identifier.bestElement;
    expect(element, isNotNull);
    // return Element for further analysis
    return element;
  }

  Element assertResolvedIdentifier2(String name, String expectedTypeName) {
    SimpleIdentifier identifier = findIdentifier(name);
    // check Element
    Element element = identifier.bestElement;
    expect(element, isNotNull);
    // check Type
    DartType type = identifier.bestType;
    expect(type, isNotNull);
    expect(type.toString(), expectedTypeName);
    // return Element for further analysis
    return element;
  }

  /**
   * @return [AstNode] which has required offset and type.
   */
  AstNode findExpression(int offset, Predicate<AstNode> predicate) {
    Expression expression = ht.HtmlUnitUtils.getExpression(indexUnit, offset);
    return expression != null ? expression.getAncestor(predicate) : null;
  }

  /**
   * Returns the [SimpleIdentifier] at the given search pattern. Fails if not found.
   */
  SimpleIdentifier findIdentifier(String search) {
    SimpleIdentifier identifier = findIdentifierMaybe(search);
    expect(identifier, isNotNull, reason: "$search in $indexContent");
    // check that offset/length of the identifier is valid
    {
      int offset = identifier.offset;
      int end = identifier.end;
      String contentStr = indexContent.substring(offset, end);
      expect(contentStr, identifier.name);
    }
    // done
    return identifier;
  }

  /**
   * Returns the [SimpleIdentifier] at the given search pattern, or `null` if not found.
   */
  SimpleIdentifier findIdentifierMaybe(String search) {
    return findExpression(
        findOffset2(search),
        (node) => node is SimpleIdentifier);
  }

  /**
   * Returns [Element] from [indexDartUnitElement].
   */
  Element findIndexElement(String name) {
    return findElement2(indexDartUnitElement, name);
  }

  /**
   * Returns [Element] from [mainUnitElement].
   */
  Element findMainElement(ElementKind kind, String name) {
    return findElement(mainUnitElement, kind, name);
  }

  /**
   * Returns [Element] from [mainUnitElement].
   */
  Element findMainElement2(String name) => findElement2(mainUnitElement, name);

  /**
   * @return the offset of given <code>search</code> string in [mainContent]. Fails test if
   *         not found.
   */
  int findMainOffset(String search) => findOffset(mainContent, search);

  /**
   * @return the offset of given <code>search</code> string in [indexContent]. Fails test if
   *         not found.
   */
  int findOffset2(String search) => findOffset(indexContent, search);

  /**
   * Resolves [indexSource].
   */
  void resolveIndex() {
    indexUnit = context.resolveHtmlUnit(indexSource);
    indexHtmlUnit = indexUnit.element;
    indexDartUnitElement = indexHtmlUnit.angularCompilationUnit;
  }

  void resolveIndex2(String content) {
    addIndexSource(content);
    contextHelper.runTasks();
    resolveIndex();
  }

  /**
   * Resolves [mainSource].
   */
  void resolveMain() {
    mainUnit = contextHelper.resolveDefiningUnit(mainSource);
    mainUnitElement = mainUnit.element;
  }

  /**
   * Resolves [mainSource].
   */
  void resolveMainNoErrors() {
    resolveMain();
    assertNoErrors2(mainSource);
  }

  void resolveMainSource(String content) {
    addMainSource(content);
    resolveMain();
  }

  void resolveMainSourceNoErrors(String content) {
    resolveMainSource(content);
    assertNoErrors2(mainSource);
  }

  @override
  void setUp() {
    super.setUp();
    _configureForAngular(contextHelper);
    context = contextHelper.context;
  }

  @override
  void tearDown() {
    contextHelper = null;
    context = null;
    // main
    mainContent = null;
    mainSource = null;
    mainUnit = null;
    mainUnitElement = null;
    // index
    indexContent = null;
    indexSource = null;
    indexUnit = null;
    indexHtmlUnit = null;
    indexDartUnitElement = null;
    // super
    super.tearDown();
  }

  /**
   * Verify that all of the identifiers in the HTML units associated with the given sources have
   * been resolved.
   *
   * @param sources the sources identifying the compilation units to be verified
   * @throws Exception if the contents of the compilation unit cannot be accessed
   */
  void verify(List<Source> sources) {
    ResolutionVerifier verifier = new ResolutionVerifier();
    for (Source source in sources) {
      ht.HtmlUnit htmlUnit = context.getResolvedHtmlUnit(source);
      htmlUnit.accept(new ExpressionVisitor_AngularTest_verify(verifier));
    }
    verifier.assertResolved();
  }

  void _configureForAngular(AnalysisContextHelper contextHelper) {
    contextHelper.addSource(
        "/angular.dart",
        r'''
library angular;

class Scope {
  Map context;
}

class Formatter {
  final String name;
  const Formatter({this.name});
}

class Directive {
  const Directive({
    selector,
    children,
    visibility,
    module,
    map,
    exportedExpressions,
    exportedExpressionAttrs
  });
}

class Decorator {
  const Decorator({
    children/*: Directive.COMPILE_CHILDREN*/,
    map,
    selector,
    module,
    visibility,
    exportedExpressions,
    exportedExpressionAttrs
  });
}

class Controller {
  const Controller({
    children,
    publishAs,
    map,
    selector,
    visibility,
    publishTypes,
    exportedExpressions,
    exportedExpressionAttrs
  });
}

class NgAttr {
  const NgAttr(String name);
}
class NgCallback {
  const NgCallback(String name);
}
class NgOneWay {
  const NgOneWay(String name);
}
class NgOneWayOneTime {
  const NgOneWayOneTime(String name);
}
class NgTwoWay {
  const NgTwoWay(String name);
}

class Component extends Directive {
  const Component({
    this.template,
    this.templateUrl,
    this.cssUrl,
    this.applyAuthorStyles,
    this.resetStyleInheritance,
    publishAs,
    module,
    map,
    selector,
    visibility,
    exportExpressions,
    exportExpressionAttrs
  }) : super(selector: selector,
             children: null/*NgAnnotation.COMPILE_CHILDREN*/,
             visibility: visibility,
             map: map,
             module: module,
             exportExpressions: exportExpressions,
             exportExpressionAttrs: exportExpressionAttrs);
}

@Decorator(selector: '[ng-click]', map: const {'ng-click': '&onEvent'})
@Decorator(selector: '[ng-mouseout]', map: const {'ng-mouseout': '&onEvent'})
class NgEventDirective {
  set onEvent(value) {}
}

@Decorator(selector: '[ng-if]', map: const {'ng-if': '=>condition'})
class NgIfDirective {
  set condition(value) {}
}

@Decorator(selector: '[ng-show]', map: const {'ng-show': '=>show'})
class NgShowDirective {
  set show(value) {}
}

@Formatter(name: 'filter')
class FilterFormatter {}

@Formatter(name: 'orderBy')
class OrderByFilter {}

@Formatter(name: 'uppercase')
class UppercaseFilter {}

class ViewFactory {
  call(String templateUrl) => null;
}

class Module {
  install(Module m) {}
  type(Type t) {}
  value(Type t, value) {}
}

class Injector {}

Injector ngBootstrap({
        Module module: null,
        List<Module> modules: null,
        /*dom.Element*/ element: null,
        String selector: '[ng-app]',
        /*Injector*/ injectorFactory/*(List<Module> modules): _defaultInjectorFactory*/}) {}
''');
  }

  /**
   * Creates an HTML content that has Angular marker and script with
   * the "main.dart" reference.
   */
  static String createHtmlWithAngular(String innerCode) {
    String source = '''
<html ng-app>
  <body>
$innerCode
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''';
    return source;
  }

  /**
   * Creates an HTML content that has Angular marker, script with "main.dart" reference and
   * "MyController" injected.
   */
  static String createHtmlWithMyController(String innerHtml) {
    String source = '''
<html ng-app>
  <body>
    <div my-controller>
$innerHtml
    </div>
    <script type='application/dart' src='main.dart'></script>
  </body>
</html>''';
    return source;
  }

  /**
   * Finds an [Element] with the given names inside of the given root [Element].
   *
   * TODO(scheglov) maybe move this method to Element
   *
   * @param root the root [Element] to start searching from
   * @param kind the kind of the [Element] to find, if `null` then any kind
   * @param name the name of an [Element] to find
   * @return the found [Element] or `null` if not found
   */
  static Element findElement(Element root, ElementKind kind, String name) {
    _AngularTest_findElement visitor = new _AngularTest_findElement(kind, name);
    root.accept(visitor);
    return visitor.result;
  }

  /**
   * Finds an [Element] with the given names inside of the given root [Element].
   *
   * @param root the root [Element] to start searching from
   * @param name the name of an [Element] to find
   * @return the found [Element] or `null` if not found
   */
  static Element findElement2(Element root, String name) {
    return findElement(root, null, name);
  }

  /**
   * @return the offset of given <code>search</code> string in <code>content</code>. Fails test if
   *         not found.
   */
  static int findOffset(String content, String search) {
    int offset = content.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }
}


class ConstantEvaluatorTest extends ResolverTestCase {
  void fail_constructor() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_class() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_function() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_static() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_staticMethod() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_topLevel() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_typeParameter() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_plus_string_string() {
    _assertValue4("ab", "'a' + 'b'");
  }

  void fail_prefixedIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_stringLength_complex() {
    _assertValue3(6, "('qwe' + 'rty').length");
  }

  void fail_stringLength_simple() {
    _assertValue3(6, "'Dvorak'.length");
  }

  void test_bitAnd_int_int() {
    _assertValue3(74 & 42, "74 & 42");
  }

  void test_bitNot() {
    _assertValue3(~42, "~42");
  }

  void test_bitOr_int_int() {
    _assertValue3(74 | 42, "74 | 42");
  }

  void test_bitXor_int_int() {
    _assertValue3(74 ^ 42, "74 ^ 42");
  }
  void test_divide_double_double() {
    _assertValue2(3.2 / 2.3, "3.2 / 2.3");
  }

  void test_divide_double_double_byZero() {
    EvaluationResult result = _getExpressionValue("3.2 / 0.0");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.doubleValue.isInfinite, isTrue);
  }

  void test_divide_int_int() {
    _assertValue3(1, "3 / 2");
  }

  void test_divide_int_int_byZero() {
    EvaluationResult result = _getExpressionValue("3 / 0");
    expect(result.isValid, isTrue);
  }

  void test_equal_boolean_boolean() {
    _assertValue(false, "true == false");
  }

  void test_equal_int_int() {
    _assertValue(false, "2 == 3");
  }

  void test_equal_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a == 3");
    expect(result.isValid, isFalse);
  }

  void test_equal_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 == a");
    expect(result.isValid, isFalse);
  }

  void test_equal_string_string() {
    _assertValue(false, "'a' == 'b'");
  }

  void test_greaterThanOrEqual_int_int() {
    _assertValue(false, "2 >= 3");
  }

  void test_greaterThan_int_int() {
    _assertValue(false, "2 > 3");
  }

  void test_leftShift_int_int() {
    _assertValue3(64, "16 << 2");
  }
  void test_lessThanOrEqual_int_int() {
    _assertValue(true, "2 <= 3");
  }

  void test_lessThan_int_int() {
    _assertValue(true, "2 < 3");
  }

  void test_literal_boolean_false() {
    _assertValue(false, "false");
  }

  void test_literal_boolean_true() {
    _assertValue(true, "true");
  }

  void test_literal_list() {
    EvaluationResult result = _getExpressionValue("const ['a', 'b', 'c']");
    expect(result.isValid, isTrue);
  }

  void test_literal_map() {
    EvaluationResult result =
        _getExpressionValue("const {'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    expect(result.isValid, isTrue);
  }

  void test_literal_null() {
    EvaluationResult result = _getExpressionValue("null");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.isNull, isTrue);
  }

  void test_literal_number_double() {
    _assertValue2(3.45, "3.45");
  }

  void test_literal_number_integer() {
    _assertValue3(42, "42");
  }

  void test_literal_string_adjacent() {
    _assertValue4("abcdef", "'abc' 'def'");
  }

  void test_literal_string_interpolation_invalid() {
    EvaluationResult result = _getExpressionValue("'a\${f()}c'");
    expect(result.isValid, isFalse);
  }

  void test_literal_string_interpolation_valid() {
    _assertValue4("a3c", "'a\${3}c'");
  }

  void test_literal_string_simple() {
    _assertValue4("abc", "'abc'");
  }

  void test_logicalAnd() {
    _assertValue(false, "true && false");
  }

  void test_logicalNot() {
    _assertValue(false, "!true");
  }

  void test_logicalOr() {
    _assertValue(true, "true || false");
  }

  void test_minus_double_double() {
    _assertValue2(3.2 - 2.3, "3.2 - 2.3");
  }

  void test_minus_int_int() {
    _assertValue3(1, "3 - 2");
  }

  void test_negated_boolean() {
    EvaluationResult result = _getExpressionValue("-true");
    expect(result.isValid, isFalse);
  }

  void test_negated_double() {
    _assertValue2(-42.3, "-42.3");
  }

  void test_negated_integer() {
    _assertValue3(-42, "-42");
  }

  void test_notEqual_boolean_boolean() {
    _assertValue(true, "true != false");
  }

  void test_notEqual_int_int() {
    _assertValue(true, "2 != 3");
  }

  void test_notEqual_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a != 3");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 != a");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_string_string() {
    _assertValue(true, "'a' != 'b'");
  }

  void test_parenthesizedExpression() {
    _assertValue4("a", "('a')");
  }

  void test_plus_double_double() {
    _assertValue2(2.3 + 3.2, "2.3 + 3.2");
  }

  void test_plus_int_int() {
    _assertValue3(5, "2 + 3");
  }

  void test_remainder_double_double() {
    _assertValue2(3.2 % 2.3, "3.2 % 2.3");
  }

  void test_remainder_int_int() {
    _assertValue3(2, "8 % 3");
  }

  void test_rightShift() {
    _assertValue3(16, "64 >> 2");
  }

  void test_times_double_double() {
    _assertValue2(2.3 * 3.2, "2.3 * 3.2");
  }

  void test_times_int_int() {
    _assertValue3(6, "2 * 3");
  }

  void test_truncatingDivide_double_double() {
    _assertValue3(1, "3.2 ~/ 2.3");
  }

  void test_truncatingDivide_int_int() {
    _assertValue3(3, "10 ~/ 3");
  }

  void _assertValue(bool expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value.type.name, "bool");
    expect(value.boolValue, expectedValue);
  }

  void _assertValue2(double expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.doubleValue, expectedValue);
  }

  void _assertValue3(int expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "int");
    expect(value.intValue, expectedValue);
  }

  void _assertValue4(String expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value, isNotNull);
    ParameterizedType type = value.type;
    expect(type, isNotNull);
    expect(type.name, "String");
    expect(value.stringValue, expectedValue);
  }

  EvaluationResult _getExpressionValue(String contents) {
    Source source = addSource("var x = $contents;");
    LibraryElement library = resolve(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember declaration = declarations[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration,
        declaration);
    NodeList<VariableDeclaration> variables =
        (declaration as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    ConstantEvaluator evaluator = new ConstantEvaluator(
        source,
        (analysisContext as AnalysisContextImpl).typeProvider);
    return evaluator.evaluate(variables[0].initializer);
  }
}


class ConstantFinderTest extends EngineTestCase {
  AstNode _node;

  void test_visitConstructorDeclaration_const() {
    ConstructorElement element = _setupConstructorDeclaration("A", true);
    expect(_findConstantDeclarations()[element], same(_node));
  }

  void test_visitConstructorDeclaration_nonConst() {
    _setupConstructorDeclaration("A", false);
    expect(_findConstantDeclarations().isEmpty, isTrue);
  }

  void test_visitInstanceCreationExpression_const() {
    _setupInstanceCreationExpression("A", true);
    expect(_findConstructorInvocations().contains(_node), isTrue);
  }

  void test_visitInstanceCreationExpression_nonConst() {
    _setupInstanceCreationExpression("A", false);
    expect(_findConstructorInvocations().isEmpty, isTrue);
  }

  void test_visitVariableDeclaration_const() {
    VariableElement element = _setupVariableDeclaration("v", true, true);
    expect(_findVariableDeclarations()[element], same(_node));
  }

  void test_visitVariableDeclaration_noInitializer() {
    _setupVariableDeclaration("v", true, false);
    expect(_findVariableDeclarations().isEmpty, isTrue);
  }

  void test_visitVariableDeclaration_nonConst() {
    _setupVariableDeclaration("v", false, true);
    expect(_findVariableDeclarations().isEmpty, isTrue);
  }

  Map<ConstructorElement, ConstructorDeclaration> _findConstantDeclarations() {
    ConstantFinder finder = new ConstantFinder();
    _node.accept(finder);
    Map<ConstructorElement, ConstructorDeclaration> constructorMap =
        finder.constructorMap;
    expect(constructorMap, isNotNull);
    return constructorMap;
  }

  List<InstanceCreationExpression> _findConstructorInvocations() {
    ConstantFinder finder = new ConstantFinder();
    _node.accept(finder);
    List<InstanceCreationExpression> constructorInvocations =
        finder.constructorInvocations;
    expect(constructorInvocations, isNotNull);
    return constructorInvocations;
  }

  Map<VariableElement, VariableDeclaration> _findVariableDeclarations() {
    ConstantFinder finder = new ConstantFinder();
    _node.accept(finder);
    Map<VariableElement, VariableDeclaration> variableMap = finder.variableMap;
    expect(variableMap, isNotNull);
    return variableMap;
  }

  ConstructorElement _setupConstructorDeclaration(String name, bool isConst) {
    Keyword constKeyword = isConst ? Keyword.CONST : null;
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            constKeyword,
            null,
            null,
            name,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    ClassElement classElement = ElementFactory.classElement2(name);
    ConstructorElement element =
        ElementFactory.constructorElement(classElement, name, isConst);
    constructorDeclaration.element = element;
    _node = constructorDeclaration;
    return element;
  }

  void _setupInstanceCreationExpression(String name, bool isConst) {
    _node = AstFactory.instanceCreationExpression2(
        isConst ? Keyword.CONST : null,
        AstFactory.typeName3(AstFactory.identifier3(name)));
  }

  VariableElement _setupVariableDeclaration(String name, bool isConst,
      bool isInitialized) {
    VariableDeclaration variableDeclaration = isInitialized ?
        AstFactory.variableDeclaration2(name, AstFactory.integer(0)) :
        AstFactory.variableDeclaration(name);
    SimpleIdentifier identifier = variableDeclaration.name;
    VariableElement element = ElementFactory.localVariableElement(identifier);
    identifier.staticElement = element;
    AstFactory.variableDeclarationList2(
        isConst ? Keyword.CONST : null,
        [variableDeclaration]);
    _node = variableDeclaration;
    return element;
  }
}


class ConstantValueComputerTest extends ResolverTestCase {
  void test_computeValues_cycle() {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    Source librarySource = addSource(r'''
const int a = c;
const int b = a;
const int c = b;''');
    LibraryElement libraryElement = resolve(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    analysisContext.computeErrors(librarySource);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(3));
    _validate(false, (members[0] as TopLevelVariableDeclaration).variables);
    _validate(false, (members[1] as TopLevelVariableDeclaration).variables);
    _validate(false, (members[2] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_dependentVariables() {
    Source librarySource = addSource(r'''
const int b = a;
const int a = 0;''');
    LibraryElement libraryElement = resolve(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(2));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (members[1] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_empty() {
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.computeValues();
  }

  void test_computeValues_multipleSources() {
    Source librarySource = addNamedSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
const int c = b;
const int a = 0;''');
    Source partSource = addNamedSource(
        "/part.dart",
        r'''
part of lib;
const int b = a;
const int d = c;''');
    LibraryElement libraryElement = resolve(librarySource);
    CompilationUnit libraryUnit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(libraryUnit, isNotNull);
    CompilationUnit partUnit =
        analysisContext.resolveCompilationUnit(partSource, libraryElement);
    expect(partUnit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(libraryUnit);
    computer.add(partUnit);
    computer.computeValues();
    NodeList<CompilationUnitMember> libraryMembers = libraryUnit.declarations;
    expect(libraryMembers, hasLength(2));
    _validate(
        true,
        (libraryMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(
        true,
        (libraryMembers[1] as TopLevelVariableDeclaration).variables);
    NodeList<CompilationUnitMember> partMembers = libraryUnit.declarations;
    expect(partMembers, hasLength(2));
    _validate(true, (partMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (partMembers[1] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_singleVariable() {
    Source librarySource = addSource("const int a = 0;");
    LibraryElement libraryElement = resolve(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(1));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
  }

  void test_dependencyOnConstructor() {
    // x depends on "const A()"
    _assertProperDependencies(r'''
class A {
  const A();
}
const x = const A();''');
  }

  void test_dependencyOnConstructorArgument() {
    // "const A(x)" depends on x
    _assertProperDependencies(r'''
class A {
  const A(this.next);
  final A next;
}
const A x = const A(null);
const A y = const A(x);''');
  }

  void test_dependencyOnConstructorArgument_unresolvedConstructor() {
    // "const A.a(x)" depends on x even if the constructor A.a can't be found.
    _assertProperDependencies(r'''
class A {
}
const int x = 1;
const A y = const A.a(x);''',
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
  }

  void test_dependencyOnConstructorInitializer() {
    // "const A()" depends on x
    _assertProperDependencies(r'''
const int x = 1;
class A {
  const A() : v = x;
  final int v;
}''');
  }

  void test_dependencyOnExplicitSuperConstructor() {
    // b depends on B() depends on A()
    _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(5);
}
const B b = const B();''');
  }

  void test_dependencyOnExplicitSuperConstructorParameters() {
    // b depends on B() depends on i
    _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(i);
}
const B b = const B();
const int i = 5;''');
  }

  void test_dependencyOnFactoryRedirect() {
    // a depends on A.foo() depends on A.bar()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  factory const A.foo() = A.bar;
  const A.bar();
}''');
  }

  void test_dependencyOnFactoryRedirectWithTypeParams() {
    _assertProperDependencies(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
  }

  void test_dependencyOnImplicitSuperConstructor() {
    // b depends on B() depends on A()
    _assertProperDependencies(r'''
class A {
  const A() : x = 5;
  final int x;
}
class B extends A {
  const B();
}
const B b = const B();''');
  }

  void test_dependencyOnNonFactoryRedirect() {
    // a depends on A.foo() depends on A.bar()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  const A.bar();
}''');
  }

  void test_dependencyOnNonFactoryRedirect_arg() {
    // a depends on A.foo() depends on b
    _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar(b);
  const A.bar(x) : y = x;
  final int y;
}''');
  }

  void test_dependencyOnNonFactoryRedirect_defaultValue() {
    // a depends on A.foo() depends on A.bar() depends on b
    _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar();
  const A.bar([x = b]) : y = x;
  final int y;
}''');
  }

  void test_dependencyOnNonFactoryRedirect_toMissing() {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // missing.
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
}''',
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR]);
  }

  void test_dependencyOnNonFactoryRedirect_toNonConst() {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // non-const.
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  A.bar();
}''');
  }

  void test_dependencyOnNonFactoryRedirect_unnamed() {
    // a depends on A.foo() depends on A()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this();
  const A();
}''');
  }

  void test_dependencyOnOptionalParameterDefault() {
    // a depends on A() depends on B()
    _assertProperDependencies(r'''
class A {
  const A([x = const B()]) : b = x;
  final B b;
}
class B {
  const B();
}
const A a = const A();''');
  }

  void test_dependencyOnVariable() {
    // x depends on y
    _assertProperDependencies(r'''
const x = y + 1;
const y = 2;''');
  }

  void test_fromEnvironment_bool_default_false() {
    expect(_assertValidBool(_check_fromEnvironment_bool(null, "false")), false);
  }

  void test_fromEnvironment_bool_default_overridden() {
    expect(_assertValidBool(_check_fromEnvironment_bool("false", "true")), false);
  }

  void test_fromEnvironment_bool_default_parseError() {
    expect(_assertValidBool(_check_fromEnvironment_bool("parseError", "true")), true);
  }

  void test_fromEnvironment_bool_default_true() {
    expect(_assertValidBool(_check_fromEnvironment_bool(null, "true")), true);
  }

  void test_fromEnvironment_bool_false() {
    expect(_assertValidBool(_check_fromEnvironment_bool("false", null)), false);
  }

  void test_fromEnvironment_bool_parseError() {
    expect(_assertValidBool(_check_fromEnvironment_bool("parseError", null)), false);
  }

  void test_fromEnvironment_bool_true() {
    expect(_assertValidBool(_check_fromEnvironment_bool("true", null)), true);
  }

  void test_fromEnvironment_bool_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_bool(null, null));
  }

  void test_fromEnvironment_int_default_overridden() {
    expect(_assertValidInt(_check_fromEnvironment_int("234", "123")), 234);
  }

  void test_fromEnvironment_int_default_parseError() {
    expect(_assertValidInt(_check_fromEnvironment_int("parseError", "123")), 123);
  }

  void test_fromEnvironment_int_default_undeclared() {
    expect(_assertValidInt(_check_fromEnvironment_int(null, "123")), 123);
  }

  void test_fromEnvironment_int_ok() {
    expect(_assertValidInt(_check_fromEnvironment_int("234", null)), 234);
  }

  void test_fromEnvironment_int_parseError() {
    _assertValidNull(_check_fromEnvironment_int("parseError", null));
  }

  void test_fromEnvironment_int_parseError_nullDefault() {
    _assertValidNull(_check_fromEnvironment_int("parseError", "null"));
  }

  void test_fromEnvironment_int_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_int(null, null));
  }

  void test_fromEnvironment_int_undeclared_nullDefault() {
    _assertValidNull(_check_fromEnvironment_int(null, "null"));
  }

  void test_fromEnvironment_string_default_overridden() {
    expect(_assertValidString(_check_fromEnvironment_string("abc", "'def'")), "abc");
  }

  void test_fromEnvironment_string_default_undeclared() {
    expect(_assertValidString(_check_fromEnvironment_string(null, "'def'")), "def");
  }

  void test_fromEnvironment_string_empty() {
    expect(_assertValidString(_check_fromEnvironment_string("", null)), "");
  }

  void test_fromEnvironment_string_ok() {
    expect(_assertValidString(_check_fromEnvironment_string("abc", null)), "abc");
  }

  void test_fromEnvironment_string_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_string(null, null));
  }

  void test_fromEnvironment_string_undeclared_nullDefault() {
    _assertValidNull(_check_fromEnvironment_string(null, "null"));
  }

  void test_instanceCreationExpression_computedField() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(4, 5);
class A {
  const A(int i, int j) : k = 2 * i + j;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 13);
  }

  void
      test_instanceCreationExpression_computedField_namedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(false, true, true);
  }

  void
      test_instanceCreationExpression_computedField_namedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(false, true, false);
  }

  void
      test_instanceCreationExpression_computedField_unnamedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(false, false, true);
  }

  void
      test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(false, false, false);
  }

  void test_instanceCreationExpression_computedField_usesConstConstructor() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : b = const B(4);
  final int b;
}
class B {
  const B(this.k);
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fieldsOfA = _assertType(result, "A");
    expect(fieldsOfA, hasLength(1));
    Map<String, DartObjectImpl> fieldsOfB =
        _assertFieldType(fieldsOfA, "b", "B");
    expect(fieldsOfB, hasLength(1));
    _assertIntField(fieldsOfB, "k", 4);
  }

  void test_instanceCreationExpression_computedField_usesStaticConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : k = i + B.bar;
  final int k;
}
class B {
  static const bar = 4;
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  void test_instanceCreationExpression_computedField_usesToplevelConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
const bar = 4;
class A {
  const A(int i) : k = i + bar;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  void test_instanceCreationExpression_explicitSuper() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const B(4, 5);
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B(int x, this.y) : super(x * 2);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 5);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 8);
  }

  void test_instanceCreationExpression_fieldFormalParameter() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(42);
class A {
  int x;
  const A(this.x)
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 42);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(true, true, true);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(true, true, false);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(true, false, true);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(true, false, false);
  }

  void test_instanceCreationExpression_implicitSuper() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const B(4);
class A {
  const A() : x = 3;
  final int x;
}
class B extends A {
  const B(this.y);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 4);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 3);
  }

  void test_instanceCreationExpression_nonFactoryRedirect() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields = _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "A");
    _assertIntField(aFields, 'x', 5);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_arg() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1(1);
class A {
  const A.a1(x) : this.a2(x + 100);
  const A.a2(x) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields = _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "A");
    _assertIntField(aFields, 'y', 111);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_cycle() {
    // It is an error to have a cycle in non-factory redirects; however, we
    // need to make sure that even if the error occurs, attempting to evaluate
    // the constant will terminate.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const A() : this.b();
  const A.b() : this();
}''');
    _assertValidUnknown(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_nonFactoryRedirect_defaultArg() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2([x = 100]) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields = _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "A");
    _assertIntField(aFields, 'y', 110);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_toMissing() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "A");
  }

  void test_instanceCreationExpression_nonFactoryRedirect_toNonConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  A.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "A");
  }

  void test_instanceCreationExpression_nonFactoryRedirect_unnamed() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this();
  const A() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields = _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "A");
    _assertIntField(aFields, 'x', 5);
  }

  void test_instanceCreationExpression_redirect() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = B;
}
class B implements A {
  const B();
}''');
    _assertType(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"),
        "B");
  }

  void test_instanceCreationExpression_redirectWithTypeParams() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  void test_instanceCreationExpression_redirectWithTypeSubstitution() {
    // To evaluate the redirection of A<int>,
    // A's template argument (T=int) must be substituted
    // into B's template argument (B<U> where U=T) to get B<int>.
    CompilationUnit compilationUnit = resolveSource(r'''
class A<T> {
  const factory A(var a) = B<T>;
}

class B<U> implements A {
  final U x;
  const B(this.x);
}

const A<int> a = const A<int>(10);''');
    EvaluationResultImpl result =
        _evaluateInstanceCreationExpression(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  void test_instanceCreationExpression_redirect_cycle() {
    // It is an error to have a cycle in factory redirects; however, we need
    // to make sure that even if the error occurs, attempting to evaluate the
    // constant will terminate.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  const factory A.b() = A;
}''');
    _assertValidUnknown(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirect_extern() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  external const factory A();
}''');
    _assertValidUnknown(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirect_nonConst() {
    // It is an error for a const factory constructor redirect to a non-const
    // constructor; however, we need to make sure that even if the error
    // attempting to evaluate the constant won't cause a crash.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  A.b();
}''');
    _assertValidUnknown(
        _evaluateInstanceCreationExpression(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_symbol() {
    CompilationUnit compilationUnit =
        resolveSource("const foo = const Symbol('a');");
    EvaluationResultImpl evaluationResult =
        _evaluateInstanceCreationExpression(compilationUnit, "foo");
    expect(evaluationResult.value, isNotNull);
    DartObjectImpl value = evaluationResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.value, "a");
  }

  void test_instanceCreationExpression_withSupertypeParams_explicit() {
    _checkInstanceCreation_withSupertypeParams(true);
  }

  void test_instanceCreationExpression_withSupertypeParams_implicit() {
    _checkInstanceCreation_withSupertypeParams(false);
  }

  void test_instanceCreationExpression_withTypeParams() {
    CompilationUnit compilationUnit = resolveSource(r'''
class C<E> {
  const C();
}
const c_int = const C<int>();
const c_num = const C<num>();''');
    EvaluationResultImpl c_int =
        _evaluateInstanceCreationExpression(compilationUnit, "c_int");
    _assertType(c_int, "C<int>");
    DartObjectImpl c_int_value = c_int.value;
    EvaluationResultImpl c_num =
        _evaluateInstanceCreationExpression(compilationUnit, "c_num");
    _assertType(c_num, "C<num>");
    DartObjectImpl c_num_value = c_num.value;
    expect(c_int_value == c_num_value, isFalse);
  }

  void test_isValidSymbol() {
    expect(ConstantValueComputer.isValidPublicSymbol(""), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo.bar"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo\$"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo\$bar"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("iff"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("gif"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("if\$"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("\$if"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo="), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo.bar="), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("foo.+"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("void"), isTrue);
    expect(ConstantValueComputer.isValidPublicSymbol("_foo"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("_foo.bar"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("foo._bar"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("if"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("if.foo"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("foo.if"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("foo=.bar"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("foo."), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("+.foo"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("void.foo"), isFalse);
    expect(ConstantValueComputer.isValidPublicSymbol("foo.void"), isFalse);
  }

  void test_symbolLiteral_void() {
    CompilationUnit compilationUnit =
        resolveSource("const voidSymbol = #void;");
    VariableDeclaration voidSymbol =
        findTopLevelDeclaration(compilationUnit, "voidSymbol");
    EvaluationResultImpl voidSymbolResult =
        (voidSymbol.element as VariableElementImpl).evaluationResult;
    DartObjectImpl value = voidSymbolResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.value, "void");
  }

  Map<String, DartObjectImpl> _assertFieldType(Map<String,
      DartObjectImpl> fields, String fieldName, String expectedType) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.displayName, expectedType);
    return field.fields;
  }

  void _assertIntField(Map<String, DartObjectImpl> fields, String fieldName,
      int expectedValue) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.name, "int");
    expect(field.intValue, expectedValue);
  }

  void _assertNullField(Map<String, DartObjectImpl> fields, String fieldName) {
    DartObjectImpl field = fields[fieldName];
    expect(field.isNull, isTrue);
  }

  void _assertProperDependencies(String sourceText,
      [List<ErrorCode> expectedErrorCodes = ErrorCode.EMPTY_LIST]) {
    Source source = addSource(sourceText);
    LibraryElement element = resolve(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, element);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    assertErrors(source, expectedErrorCodes);
  }

  Map<String, DartObjectImpl> _assertType(EvaluationResultImpl result,
      String typeName) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type.displayName, typeName);
    return value.fields;
  }

  bool _assertValidBool(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.boolType);
    bool boolValue = value.boolValue;
    expect(boolValue, isNotNull);
    return boolValue;
  }

  int _assertValidInt(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.intType);
    return value.intValue;
  }

  void _assertValidNull(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.nullType);
  }

  String _assertValidString(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.stringType);
    return value.stringValue;
  }

  void _assertValidUnknown(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.isUnknown, isTrue);
  }

  void _checkInstanceCreationOptionalParams(bool isFieldFormal, bool isNamed,
      bool hasDefault) {
    String fieldName = "j";
    String paramName = isFieldFormal ? fieldName : "i";
    String formalParam =
        "${isFieldFormal ? "this." : "int "}$paramName${hasDefault ? " = 3" : ""}";
    CompilationUnit compilationUnit = resolveSource("""
const x = const A();
const y = const A(${isNamed ? '$paramName: ' : ''}10);
class A {
  const A(${isNamed ? "{$formalParam}" : "[$formalParam]"})${isFieldFormal ? "" : " : $fieldName = $paramName"};
  final int $fieldName;
}""");
    EvaluationResultImpl x =
        _evaluateInstanceCreationExpression(compilationUnit, "x");
    Map<String, DartObjectImpl> fieldsOfX = _assertType(x, "A");
    expect(fieldsOfX, hasLength(1));
    if (hasDefault) {
      _assertIntField(fieldsOfX, fieldName, 3);
    } else {
      _assertNullField(fieldsOfX, fieldName);
    }
    EvaluationResultImpl y =
        _evaluateInstanceCreationExpression(compilationUnit, "y");
    Map<String, DartObjectImpl> fieldsOfY = _assertType(y, "A");
    expect(fieldsOfY, hasLength(1));
    _assertIntField(fieldsOfY, fieldName, 10);
  }

  void _checkInstanceCreation_withSupertypeParams(bool isExplicit) {
    String superCall = isExplicit ? " : super()" : "";
    CompilationUnit compilationUnit = resolveSource("""
class A<T> {
  const A();
}
class B<T, U> extends A<T> {
  const B()$superCall;
}
class C<T, U> extends A<U> {
  const C()$superCall;
}
const b_int_num = const B<int, num>();
const c_int_num = const C<int, num>();""");
    EvaluationResultImpl b_int_num =
        _evaluateInstanceCreationExpression(compilationUnit, "b_int_num");
    Map<String, DartObjectImpl> b_int_num_fields =
        _assertType(b_int_num, "B<int, num>");
    _assertFieldType(b_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<int>");
    EvaluationResultImpl c_int_num =
        _evaluateInstanceCreationExpression(compilationUnit, "c_int_num");
    Map<String, DartObjectImpl> c_int_num_fields =
        _assertType(c_int_num, "C<int, num>");
    _assertFieldType(c_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<num>");
  }

  EvaluationResultImpl _check_fromEnvironment_bool(String valueInEnvironment,
      String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
                "const $varName = const bool.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateInstanceCreationExpression(compilationUnit, varName);
  }

  EvaluationResultImpl _check_fromEnvironment_int(String valueInEnvironment,
      String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
                "const $varName = const int.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateInstanceCreationExpression(compilationUnit, varName);
  }

  EvaluationResultImpl _check_fromEnvironment_string(String valueInEnvironment,
      String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
                "const $varName = const String.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateInstanceCreationExpression(compilationUnit, varName);
  }

  EvaluationResultImpl
      _evaluateInstanceCreationExpression(CompilationUnit compilationUnit,
      String name) {
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);
    return (expression as InstanceCreationExpression).evaluationResult;
  }

  ConstantValueComputer _makeConstantValueComputer() {
    return new ValidatingConstantValueComputer(
        analysisContext2.typeProvider,
        analysisContext2.declaredVariables);
  }

  void _validate(bool shouldBeValid, VariableDeclarationList declarationList) {
    for (VariableDeclaration declaration in declarationList.variables) {
      VariableElementImpl element = declaration.element as VariableElementImpl;
      expect(element, isNotNull);
      EvaluationResultImpl result = element.evaluationResult;
      if (shouldBeValid) {
        expect(result.value, isNotNull);
      } else {
        expect(result.value, isNull);
      }
    }
  }
}


class ConstantValueComputerTest_ValidatingConstantVisitor extends
    ConstantVisitor {
  final DirectedGraph<AstNode> _referenceGraph;
  final AstNode _nodeBeingEvaluated;

  ConstantValueComputerTest_ValidatingConstantVisitor(TypeProvider typeProvider,
      this._referenceGraph, this._nodeBeingEvaluated, ErrorReporter errorReporter)
      : super.con1(typeProvider, errorReporter);

  @override
  void beforeGetEvaluationResult(AstNode node) {
    super.beforeGetEvaluationResult(node);
    // If we are getting the evaluation result for a node in the graph,
    // make sure we properly recorded the dependency.
    if (_referenceGraph.nodes.contains(node)) {
      expect(_referenceGraph.containsPath(_nodeBeingEvaluated, node), isTrue);
    }
  }
}


class ConstantVisitorTest extends ResolverTestCase {
  void test_visitConditionalExpression_false() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(false),
        thenExpression,
        elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(
        0,
        expression.accept(
            new ConstantVisitor.con1(new TestTypeProvider(), errorReporter)));
    errorListener.assertNoErrors();
  }

  void test_visitConditionalExpression_instanceCreation_invalidFieldInitializer() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    LibraryElementImpl libraryElement = ElementFactory.library(null, "lib");
    String className = "C";
    ClassElementImpl classElement = ElementFactory.classElement2(className);
    (libraryElement.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(
            classElement,
            null,
            true,
            [typeProvider.intType]);
    constructorElement.parameters[0] =
        new FieldFormalParameterElementImpl(AstFactory.identifier3("x"));
    InstanceCreationExpression expression =
        AstFactory.instanceCreationExpression2(
            Keyword.CONST,
            AstFactory.typeName4(className),
            [AstFactory.integer(0)]);
    expression.staticElement = constructorElement;
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    expression.accept(new ConstantVisitor.con1(typeProvider, errorReporter));
    errorListener.assertErrorsWithCodes(
        [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_nonBooleanCondition() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    NullLiteral conditionExpression = AstFactory.nullLiteral();
    ConditionalExpression expression = AstFactory.conditionalExpression(
        conditionExpression,
        thenExpression,
        elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = expression.accept(
        new ConstantVisitor.con1(new TestTypeProvider(), errorReporter));
    expect(result, isNull);
    errorListener.assertErrorsWithCodes(
        [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  void test_visitConditionalExpression_nonConstantElse() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.identifier3("x");
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true),
        thenExpression,
        elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = expression.accept(
        new ConstantVisitor.con1(new TestTypeProvider(), errorReporter));
    expect(result, isNull);
    errorListener.assertErrorsWithCodes(
        [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_nonConstantThen() {
    Expression thenExpression = AstFactory.identifier3("x");
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true),
        thenExpression,
        elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = expression.accept(
        new ConstantVisitor.con1(new TestTypeProvider(), errorReporter));
    expect(result, isNull);
    errorListener.assertErrorsWithCodes(
        [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_true() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true),
        thenExpression,
        elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(
        1,
        expression.accept(
            new ConstantVisitor.con1(new TestTypeProvider(), errorReporter)));
    errorListener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_inEnvironment() {
    CompilationUnit compilationUnit =
        resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["b"] = six;
    _assertValue(6, _evaluateConstant(compilationUnit, "a", environment));
  }

  void test_visitSimpleIdentifier_notInEnvironment() {
    CompilationUnit compilationUnit =
        resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["c"] = six;
    _assertValue(3, _evaluateConstant(compilationUnit, "a", environment));
  }

  void test_visitSimpleIdentifier_withoutEnvironment() {
    CompilationUnit compilationUnit =
        resolveSource(r'''
const a = b;
const b = 3;''');
    _assertValue(3, _evaluateConstant(compilationUnit, "a", null));
  }

  void _assertValue(int expectedValue, DartObjectImpl result) {
    expect(result, isNotNull);
    expect(result.type.name, "int");
    expect(result.intValue, expectedValue);
  }

  NonExistingSource _dummySource() {
    return new NonExistingSource("foo.dart", UriKind.FILE_URI);
  }

  DartObjectImpl _evaluateConstant(CompilationUnit compilationUnit, String name,
      Map<String, DartObjectImpl> lexicalEnvironment) {
    Source source = compilationUnit.element.source;
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    DartObjectImpl result = expression.accept(
        new ConstantVisitor.con2(typeProvider, lexicalEnvironment, errorReporter));
    errorListener.assertNoErrors();
    return result;
  }
}


class ContentCacheTest {
  void test_setContents() {
    Source source = new TestSource();
    ContentCache cache = new ContentCache();
    expect(cache.getContents(source), isNull);
    expect(cache.getModificationStamp(source), isNull);
    String contents = "library lib;";
    expect(cache.setContents(source, contents), isNull);
    expect(cache.getContents(source), contents);
    expect(cache.getModificationStamp(source), isNotNull);
    expect(cache.setContents(source, contents), contents);
    expect(cache.setContents(source, null), contents);
    expect(cache.getContents(source), isNull);
    expect(cache.getModificationStamp(source), isNull);
    expect(cache.setContents(source, null), isNull);
  }
}


class DartObjectImplTest extends EngineTestCase {
  TypeProvider _typeProvider = new TestTypeProvider();

  void fail_add_knownString_knownString() {
    fail("New constant semantics are not yet enabled");
    _assertAdd(_stringValue("ab"), _stringValue("a"), _stringValue("b"));
  }

  void fail_add_knownString_unknownString() {
    fail("New constant semantics are not yet enabled");
    _assertAdd(_stringValue(null), _stringValue("a"), _stringValue(null));
  }

  void fail_add_unknownString_knownString() {
    fail("New constant semantics are not yet enabled");
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue("b"));
  }
  void fail_add_unknownString_unknownString() {
    fail("New constant semantics are not yet enabled");
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue(null));
  }

  void test_add_knownDouble_knownDouble() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_add_knownDouble_knownInt() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _intValue(2));
  }

  void test_add_knownDouble_unknownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_add_knownDouble_unknownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_add_knownInt_knownInt() {
    _assertAdd(_intValue(3), _intValue(1), _intValue(2));
  }

  void test_add_knownInt_knownString() {
    _assertAdd(null, _intValue(1), _stringValue("2"));
  }

  void test_add_knownInt_unknownDouble() {
    _assertAdd(_doubleValue(null), _intValue(1), _doubleValue(null));
  }

  void test_add_knownInt_unknownInt() {
    _assertAdd(_intValue(null), _intValue(1), _intValue(null));
  }

  void test_add_knownString_knownInt() {
    _assertAdd(null, _stringValue("1"), _intValue(2));
  }

  void test_add_unknownDouble_knownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_add_unknownDouble_knownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_add_unknownInt_knownDouble() {
    _assertAdd(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_add_unknownInt_knownInt() {
    _assertAdd(_intValue(null), _intValue(null), _intValue(2));
  }
  void test_bitAnd_knownInt_knownInt() {
    _assertBitAnd(_intValue(2), _intValue(6), _intValue(3));
  }

  void test_bitAnd_knownInt_knownString() {
    _assertBitAnd(null, _intValue(6), _stringValue("3"));
  }

  void test_bitAnd_knownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitAnd_knownString_knownInt() {
    _assertBitAnd(null, _stringValue("6"), _intValue(3));
  }

  void test_bitAnd_unknownInt_knownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitAnd_unknownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitNot_knownInt() {
    _assertBitNot(_intValue(-4), _intValue(3));
  }

  void test_bitNot_knownString() {
    _assertBitNot(null, _stringValue("6"));
  }

  void test_bitNot_unknownInt() {
    _assertBitNot(_intValue(null), _intValue(null));
  }

  void test_bitOr_knownInt_knownInt() {
    _assertBitOr(_intValue(7), _intValue(6), _intValue(3));
  }

  void test_bitOr_knownInt_knownString() {
    _assertBitOr(null, _intValue(6), _stringValue("3"));
  }

  void test_bitOr_knownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitOr_knownString_knownInt() {
    _assertBitOr(null, _stringValue("6"), _intValue(3));
  }

  void test_bitOr_unknownInt_knownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitOr_unknownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitXor_knownInt_knownInt() {
    _assertBitXor(_intValue(5), _intValue(6), _intValue(3));
  }

  void test_bitXor_knownInt_knownString() {
    _assertBitXor(null, _intValue(6), _stringValue("3"));
  }

  void test_bitXor_knownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitXor_knownString_knownInt() {
    _assertBitXor(null, _stringValue("6"), _intValue(3));
  }

  void test_bitXor_unknownInt_knownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitXor_unknownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_concatenate_knownInt_knownString() {
    _assertConcatenate(null, _intValue(2), _stringValue("def"));
  }

  void test_concatenate_knownString_knownInt() {
    _assertConcatenate(null, _stringValue("abc"), _intValue(3));
  }

  void test_concatenate_knownString_knownString() {
    _assertConcatenate(
        _stringValue("abcdef"),
        _stringValue("abc"),
        _stringValue("def"));
  }

  void test_concatenate_knownString_unknownString() {
    _assertConcatenate(
        _stringValue(null),
        _stringValue("abc"),
        _stringValue(null));
  }

  void test_concatenate_unknownString_knownString() {
    _assertConcatenate(
        _stringValue(null),
        _stringValue(null),
        _stringValue("def"));
  }

  void test_divide_knownDouble_knownDouble() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_divide_knownDouble_knownInt() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _intValue(2));
  }

  void test_divide_knownDouble_unknownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_divide_knownDouble_unknownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_divide_knownInt_knownInt() {
    _assertDivide(_intValue(3), _intValue(6), _intValue(2));
  }

  void test_divide_knownInt_knownString() {
    _assertDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_divide_knownInt_unknownDouble() {
    _assertDivide(_doubleValue(null), _intValue(6), _doubleValue(null));
  }

  void test_divide_knownInt_unknownInt() {
    _assertDivide(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_divide_knownString_knownInt() {
    _assertDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_divide_unknownDouble_knownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownDouble_knownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_divide_unknownInt_knownDouble() {
    _assertDivide(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownInt_knownInt() {
    _assertDivide(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_equalEqual_bool_false() {
    _assertEqualEqual(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_equalEqual_bool_true() {
    _assertEqualEqual(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_equalEqual_bool_unknown() {
    _assertEqualEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_equalEqual_double_false() {
    _assertEqualEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_equalEqual_double_true() {
    _assertEqualEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_equalEqual_double_unknown() {
    _assertEqualEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_equalEqual_int_false() {
    _assertEqualEqual(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_equalEqual_int_true() {
    _assertEqualEqual(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_equalEqual_int_unknown() {
    _assertEqualEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_equalEqual_list_empty() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_list_false() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_map_empty() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_map_false() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_null() {
    _assertEqualEqual(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_equalEqual_string_false() {
    _assertEqualEqual(
        _boolValue(false),
        _stringValue("abc"),
        _stringValue("def"));
  }

  void test_equalEqual_string_true() {
    _assertEqualEqual(
        _boolValue(true),
        _stringValue("abc"),
        _stringValue("abc"));
  }

  void test_equalEqual_string_unknown() {
    _assertEqualEqual(
        _boolValue(null),
        _stringValue(null),
        _stringValue("def"));
  }

  void test_equals_list_false_differentSizes() {
    expect(_listValue([_boolValue(true)]) ==
            _listValue([_boolValue(true), _boolValue(false)]), isFalse);
  }

  void test_equals_list_false_sameSize() {
    expect(_listValue([_boolValue(true)]) == _listValue([_boolValue(false)]), isFalse);
  }

  void test_equals_list_true_empty() {
    expect(_listValue(), _listValue());
  }

  void test_equals_list_true_nonEmpty() {
    expect(_listValue([_boolValue(true)]), _listValue([_boolValue(true)]));
  }

  void test_equals_map_true_empty() {
    expect(_mapValue(), _mapValue());
  }

  void test_equals_symbol_false() {
    expect(_symbolValue("a") == _symbolValue("b"), isFalse);
  }

  void test_equals_symbol_true() {
    expect(_symbolValue("a"), _symbolValue("a"));
  }

  void test_getValue_bool_false() {
    expect(_boolValue(false).value, false);
  }

  void test_getValue_bool_true() {
    expect(_boolValue(true).value, true);
  }

  void test_getValue_bool_unknown() {
    expect(_boolValue(null).value, isNull);
  }

  void test_getValue_double_known() {
    double value = 2.3;
    expect(_doubleValue(value).value, value);
  }

  void test_getValue_double_unknown() {
    expect(_doubleValue(null).value, isNull);
  }

  void test_getValue_int_known() {
    int value = 23;
    expect(_intValue(value).value, value);
  }

  void test_getValue_int_unknown() {
    expect(_intValue(null).value, isNull);
  }

  void test_getValue_list_empty() {
    Object result = _listValue().value;
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(0));
  }

  void test_getValue_list_valid() {
    Object result = _listValue([_intValue(23)]).value;
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(1));
  }

  void test_getValue_map_empty() {
    Object result = _mapValue().value;
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(0));
  }

  void test_getValue_map_valid() {
    Object result =
        _mapValue([_stringValue("key"), _stringValue("value")]).value;
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(1));
  }

  void test_getValue_null() {
    expect(_nullValue().value, isNull);
  }

  void test_getValue_string_known() {
    String value = "twenty-three";
    expect(_stringValue(value).value, value);
  }

  void test_getValue_string_unknown() {
    expect(_stringValue(null).value, isNull);
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false),
        _doubleValue(1.0),
        _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true),
        _doubleValue(2.0),
        _doubleValue(1.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false),
        _doubleValue(1.0),
        _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true),
        _doubleValue(2.0),
        _intValue(1));
  }

  void test_greaterThanOrEqual_knownDouble_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null),
        _doubleValue(1.0),
        _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownDouble_unknownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null),
        _doubleValue(1.0),
        _intValue(null));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_false() {
    _assertGreaterThanOrEqual(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_true() {
    _assertGreaterThanOrEqual(_boolValue(true), _intValue(2), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownString() {
    _assertGreaterThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThanOrEqual_knownInt_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null),
        _intValue(1),
        _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownInt_unknownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThanOrEqual_knownString_knownInt() {
    _assertGreaterThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownDouble_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null),
        _doubleValue(null),
        _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownDouble_knownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null),
        _doubleValue(null),
        _intValue(2));
  }

  void test_greaterThanOrEqual_unknownInt_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null),
        _intValue(null),
        _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownInt_knownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_greaterThan_knownDouble_knownDouble_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThan_knownDouble_knownDouble_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThan_knownDouble_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThan_knownDouble_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThan_knownDouble_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThan_knownDouble_unknownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThan_knownInt_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThan_knownInt_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _intValue(2), _intValue(1));
  }

  void test_greaterThan_knownInt_knownString() {
    _assertGreaterThan(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThan_knownInt_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThan_knownInt_unknownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThan_knownString_knownInt() {
    _assertGreaterThan(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThan_unknownDouble_knownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownDouble_knownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThan_unknownInt_knownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownInt_knownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_hasExactValue_bool_false() {
    expect(_boolValue(false).hasExactValue, isTrue);
  }

  void test_hasExactValue_bool_true() {
    expect(_boolValue(true).hasExactValue, isTrue);
  }

  void test_hasExactValue_bool_unknown() {
    expect(_boolValue(null).hasExactValue, isTrue);
  }

  void test_hasExactValue_double_known() {
    expect(_doubleValue(2.3).hasExactValue, isTrue);
  }

  void test_hasExactValue_double_unknown() {
    expect(_doubleValue(null).hasExactValue, isTrue);
  }

  void test_hasExactValue_dynamic() {
    expect(_dynamicValue().hasExactValue, isFalse);
  }

  void test_hasExactValue_int_known() {
    expect(_intValue(23).hasExactValue, isTrue);
  }

  void test_hasExactValue_int_unknown() {
    expect(_intValue(null).hasExactValue, isTrue);
  }

  void test_hasExactValue_list_empty() {
    expect(_listValue().hasExactValue, isTrue);
  }

  void test_hasExactValue_list_invalid() {
    expect(_dynamicValue().hasExactValue, isFalse);
  }

  void test_hasExactValue_list_valid() {
    expect(_listValue([_intValue(23)]).hasExactValue, isTrue);
  }

  void test_hasExactValue_map_empty() {
    expect(_mapValue().hasExactValue, isTrue);
  }

  void test_hasExactValue_map_invalidKey() {
    expect(_mapValue([_dynamicValue(), _stringValue("value")]).hasExactValue, isFalse);
  }

  void test_hasExactValue_map_invalidValue() {
    expect(_mapValue([_stringValue("key"), _dynamicValue()]).hasExactValue, isFalse);
  }

  void test_hasExactValue_map_valid() {
    expect(_mapValue([_stringValue("key"), _stringValue("value")]).hasExactValue, isTrue);
  }

  void test_hasExactValue_null() {
    expect(_nullValue().hasExactValue, isTrue);
  }

  void test_hasExactValue_num() {
    expect(_numValue().hasExactValue, isFalse);
  }

  void test_hasExactValue_string_known() {
    expect(_stringValue("twenty-three").hasExactValue, isTrue);
  }

  void test_hasExactValue_string_unknown() {
    expect(_stringValue(null).hasExactValue, isTrue);
  }

  void test_identical_bool_false() {
    _assertIdentical(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_identical_bool_true() {
    _assertIdentical(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_identical_bool_unknown() {
    _assertIdentical(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_identical_double_false() {
    _assertIdentical(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_identical_double_true() {
    _assertIdentical(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_identical_double_unknown() {
    _assertIdentical(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_identical_int_false() {
    _assertIdentical(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_identical_int_true() {
    _assertIdentical(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_identical_int_unknown() {
    _assertIdentical(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_identical_list_empty() {
    _assertIdentical(_boolValue(true), _listValue(), _listValue());
  }

  void test_identical_list_false() {
    _assertIdentical(_boolValue(false), _listValue(),
        _listValue([_intValue(3)]));
  }

  void test_identical_map_empty() {
    _assertIdentical(_boolValue(true), _mapValue(), _mapValue());
  }

  void test_identical_map_false() {
    _assertIdentical(_boolValue(false), _mapValue(),
        _mapValue([_intValue(1), _intValue(2)]));
  }

  void test_identical_null() {
    _assertIdentical(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_identical_string_false() {
    _assertIdentical(
        _boolValue(false),
        _stringValue("abc"),
        _stringValue("def"));
  }

  void test_identical_string_true() {
    _assertIdentical(
        _boolValue(true),
        _stringValue("abc"),
        _stringValue("abc"));
  }

  void test_identical_string_unknown() {
    _assertIdentical(
        _boolValue(null),
        _stringValue(null),
        _stringValue("def"));
  }

  void test_integerDivide_knownDouble_knownDouble() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_integerDivide_knownDouble_knownInt() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _intValue(2));
  }

  void test_integerDivide_knownDouble_unknownDouble() {
    _assertIntegerDivide(
        _intValue(null),
        _doubleValue(6.0),
        _doubleValue(null));
  }

  void test_integerDivide_knownDouble_unknownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_integerDivide_knownInt_knownInt() {
    _assertIntegerDivide(_intValue(3), _intValue(6), _intValue(2));
  }

  void test_integerDivide_knownInt_knownString() {
    _assertIntegerDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_integerDivide_knownInt_unknownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _doubleValue(null));
  }

  void test_integerDivide_knownInt_unknownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_integerDivide_knownString_knownInt() {
    _assertIntegerDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_integerDivide_unknownDouble_knownDouble() {
    _assertIntegerDivide(
        _intValue(null),
        _doubleValue(null),
        _doubleValue(2.0));
  }

  void test_integerDivide_unknownDouble_knownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(null), _intValue(2));
  }

  void test_integerDivide_unknownInt_knownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownInt_knownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_isBoolNumStringOrNull_bool_false() {
    expect(_boolValue(false).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_true() {
    expect(_boolValue(true).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_unknown() {
    expect(_boolValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_known() {
    expect(_doubleValue(2.3).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_unknown() {
    expect(_doubleValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_dynamic() {
    expect(_dynamicValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_known() {
    expect(_intValue(23).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_unknown() {
    expect(_intValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_list() {
    expect(_listValue().isBoolNumStringOrNull, isFalse);
  }

  void test_isBoolNumStringOrNull_null() {
    expect(_nullValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_num() {
    expect(_numValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_known() {
    expect(_stringValue("twenty-three").isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_unknown() {
    expect(_stringValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_false() {
    _assertLessThanOrEqual(
        _boolValue(false),
        _doubleValue(2.0),
        _doubleValue(1.0));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_true() {
    _assertLessThanOrEqual(
        _boolValue(true),
        _doubleValue(1.0),
        _doubleValue(2.0));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_unknownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null),
        _doubleValue(1.0),
        _doubleValue(null));
  }

  void test_lessThanOrEqual_knownDouble_unknownInt() {
    _assertLessThanOrEqual(
        _boolValue(null),
        _doubleValue(1.0),
        _intValue(null));
  }

  void test_lessThanOrEqual_knownInt_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThanOrEqual_knownInt_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThanOrEqual_knownInt_knownString() {
    _assertLessThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThanOrEqual_knownInt_unknownDouble() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownInt_unknownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThanOrEqual_knownString_knownInt() {
    _assertLessThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThanOrEqual_unknownDouble_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null),
        _doubleValue(null),
        _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownDouble_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_unknownInt_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null),
        _intValue(null),
        _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownInt_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_lessThan_knownDouble_knownDouble_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThan_knownDouble_knownDouble_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThan_knownDouble_knownInt_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThan_knownDouble_knownInt_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThan_knownDouble_unknownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThan_knownDouble_unknownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThan_knownInt_knownInt_false() {
    _assertLessThan(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThan_knownInt_knownInt_true() {
    _assertLessThan(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThan_knownInt_knownString() {
    _assertLessThan(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThan_knownInt_unknownDouble() {
    _assertLessThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThan_knownInt_unknownInt() {
    _assertLessThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThan_knownString_knownInt() {
    _assertLessThan(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThan_unknownDouble_knownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownDouble_knownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThan_unknownInt_knownDouble() {
    _assertLessThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownInt_knownInt() {
    _assertLessThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_logicalAnd_false_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalAnd_false_null() {
    try {
      _assertLogicalAnd(_boolValue(false), _boolValue(false), _nullValue());
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_false_string() {
    try {
      _assertLogicalAnd(
          _boolValue(false),
          _boolValue(false),
          _stringValue("false"));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_false_true() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_logicalAnd_null_false() {
    try {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_null_true() {
    try {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_string_false() {
    try {
      _assertLogicalAnd(
          _boolValue(false),
          _stringValue("true"),
          _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_string_true() {
    try {
      _assertLogicalAnd(
          _boolValue(false),
          _stringValue("false"),
          _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_true_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(true), _boolValue(false));
  }

  void test_logicalAnd_true_null() {
    _assertLogicalAnd(null, _boolValue(true), _nullValue());
  }

  void test_logicalAnd_true_string() {
    try {
      _assertLogicalAnd(
          _boolValue(false),
          _boolValue(true),
          _stringValue("true"));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalAnd_true_true() {
    _assertLogicalAnd(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_logicalNot_false() {
    _assertLogicalNot(_boolValue(true), _boolValue(false));
  }

  void test_logicalNot_null() {
    _assertLogicalNot(null, _nullValue());
  }

  void test_logicalNot_string() {
    try {
      _assertLogicalNot(_boolValue(true), _stringValue(null));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalNot_true() {
    _assertLogicalNot(_boolValue(false), _boolValue(true));
  }

  void test_logicalNot_unknown() {
    _assertLogicalNot(_boolValue(null), _boolValue(null));
  }

  void test_logicalOr_false_false() {
    _assertLogicalOr(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalOr_false_null() {
    _assertLogicalOr(null, _boolValue(false), _nullValue());
  }

  void test_logicalOr_false_string() {
    try {
      _assertLogicalOr(
          _boolValue(false),
          _boolValue(false),
          _stringValue("false"));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_false_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_logicalOr_null_false() {
    try {
      _assertLogicalOr(_boolValue(false), _nullValue(), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_null_true() {
    try {
      _assertLogicalOr(_boolValue(true), _nullValue(), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_string_false() {
    try {
      _assertLogicalOr(
          _boolValue(false),
          _stringValue("true"),
          _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_string_true() {
    try {
      _assertLogicalOr(
          _boolValue(true),
          _stringValue("false"),
          _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_true_false() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(false));
  }

  void test_logicalOr_true_null() {
    try {
      _assertLogicalOr(_boolValue(true), _boolValue(true), _nullValue());
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_true_string() {
    try {
      _assertLogicalOr(
          _boolValue(true),
          _boolValue(true),
          _stringValue("true"));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_logicalOr_true_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_minus_knownDouble_knownDouble() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _doubleValue(3.0));
  }

  void test_minus_knownDouble_knownInt() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _intValue(3));
  }

  void test_minus_knownDouble_unknownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _doubleValue(null));
  }

  void test_minus_knownDouble_unknownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _intValue(null));
  }

  void test_minus_knownInt_knownInt() {
    _assertMinus(_intValue(1), _intValue(4), _intValue(3));
  }

  void test_minus_knownInt_knownString() {
    _assertMinus(null, _intValue(4), _stringValue("3"));
  }

  void test_minus_knownInt_unknownDouble() {
    _assertMinus(_doubleValue(null), _intValue(4), _doubleValue(null));
  }

  void test_minus_knownInt_unknownInt() {
    _assertMinus(_intValue(null), _intValue(4), _intValue(null));
  }

  void test_minus_knownString_knownInt() {
    _assertMinus(null, _stringValue("4"), _intValue(3));
  }

  void test_minus_unknownDouble_knownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownDouble_knownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_minus_unknownInt_knownDouble() {
    _assertMinus(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownInt_knownInt() {
    _assertMinus(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_negated_double_known() {
    _assertNegated(_doubleValue(2.0), _doubleValue(-2.0));
  }

  void test_negated_double_unknown() {
    _assertNegated(_doubleValue(null), _doubleValue(null));
  }

  void test_negated_int_known() {
    _assertNegated(_intValue(-3), _intValue(3));
  }

  void test_negated_int_unknown() {
    _assertNegated(_intValue(null), _intValue(null));
  }

  void test_negated_string() {
    _assertNegated(null, _stringValue(null));
  }

  void test_notEqual_bool_false() {
    _assertNotEqual(_boolValue(false), _boolValue(true), _boolValue(true));
  }

  void test_notEqual_bool_true() {
    _assertNotEqual(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_notEqual_bool_unknown() {
    _assertNotEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_notEqual_double_false() {
    _assertNotEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_notEqual_double_true() {
    _assertNotEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_notEqual_double_unknown() {
    _assertNotEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_notEqual_int_false() {
    _assertNotEqual(_boolValue(false), _intValue(5), _intValue(5));
  }

  void test_notEqual_int_true() {
    _assertNotEqual(_boolValue(true), _intValue(-5), _intValue(5));
  }

  void test_notEqual_int_unknown() {
    _assertNotEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_notEqual_null() {
    _assertNotEqual(_boolValue(false), _nullValue(), _nullValue());
  }

  void test_notEqual_string_false() {
    _assertNotEqual(
        _boolValue(false),
        _stringValue("abc"),
        _stringValue("abc"));
  }

  void test_notEqual_string_true() {
    _assertNotEqual(_boolValue(true), _stringValue("abc"), _stringValue("def"));
  }

  void test_notEqual_string_unknown() {
    _assertNotEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_performToString_bool_false() {
    _assertPerformToString(_stringValue("false"), _boolValue(false));
  }

  void test_performToString_bool_true() {
    _assertPerformToString(_stringValue("true"), _boolValue(true));
  }

  void test_performToString_bool_unknown() {
    _assertPerformToString(_stringValue(null), _boolValue(null));
  }

  void test_performToString_double_known() {
    _assertPerformToString(_stringValue("2.0"), _doubleValue(2.0));
  }

  void test_performToString_double_unknown() {
    _assertPerformToString(_stringValue(null), _doubleValue(null));
  }

  void test_performToString_int_known() {
    _assertPerformToString(_stringValue("5"), _intValue(5));
  }

  void test_performToString_int_unknown() {
    _assertPerformToString(_stringValue(null), _intValue(null));
  }

  void test_performToString_null() {
    _assertPerformToString(_stringValue("null"), _nullValue());
  }

  void test_performToString_string_known() {
    _assertPerformToString(_stringValue("abc"), _stringValue("abc"));
  }

  void test_performToString_string_unknown() {
    _assertPerformToString(_stringValue(null), _stringValue(null));
  }

  void test_remainder_knownDouble_knownDouble() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _doubleValue(2.0));
  }

  void test_remainder_knownDouble_knownInt() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _intValue(2));
  }

  void test_remainder_knownDouble_unknownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(7.0), _doubleValue(null));
  }

  void test_remainder_knownDouble_unknownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_remainder_knownInt_knownInt() {
    _assertRemainder(_intValue(1), _intValue(7), _intValue(2));
  }

  void test_remainder_knownInt_knownString() {
    _assertRemainder(null, _intValue(7), _stringValue("2"));
  }

  void test_remainder_knownInt_unknownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(7), _doubleValue(null));
  }

  void test_remainder_knownInt_unknownInt() {
    _assertRemainder(_intValue(null), _intValue(7), _intValue(null));
  }

  void test_remainder_knownString_knownInt() {
    _assertRemainder(null, _stringValue("7"), _intValue(2));
  }

  void test_remainder_unknownDouble_knownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownDouble_knownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_remainder_unknownInt_knownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownInt_knownInt() {
    _assertRemainder(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_shiftLeft_knownInt_knownInt() {
    _assertShiftLeft(_intValue(48), _intValue(6), _intValue(3));
  }

  void test_shiftLeft_knownInt_knownString() {
    _assertShiftLeft(null, _intValue(6), _stringValue(null));
  }

  void test_shiftLeft_knownInt_tooLarge() {
    _assertShiftLeft(
        _intValue(null),
        _intValue(6),
        new DartObjectImpl(_typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftLeft_knownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_shiftLeft_knownString_knownInt() {
    _assertShiftLeft(null, _stringValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_knownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_shiftRight_knownInt_knownInt() {
    _assertShiftRight(_intValue(6), _intValue(48), _intValue(3));
  }

  void test_shiftRight_knownInt_knownString() {
    _assertShiftRight(null, _intValue(48), _stringValue(null));
  }

  void test_shiftRight_knownInt_tooLarge() {
    _assertShiftRight(
        _intValue(null),
        _intValue(48),
        new DartObjectImpl(_typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftRight_knownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(48), _intValue(null));
  }

  void test_shiftRight_knownString_knownInt() {
    _assertShiftRight(null, _stringValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_knownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_stringLength_int() {
    try {
      _assertStringLength(_intValue(null), _intValue(0));
      fail("Expected EvaluationException");
    } on EvaluationException catch (exception) {
    }
  }

  void test_stringLength_knownString() {
    _assertStringLength(_intValue(3), _stringValue("abc"));
  }

  void test_stringLength_unknownString() {
    _assertStringLength(_intValue(null), _stringValue(null));
  }

  void test_times_knownDouble_knownDouble() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _doubleValue(3.0));
  }

  void test_times_knownDouble_knownInt() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _intValue(3));
  }

  void test_times_knownDouble_unknownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _doubleValue(null));
  }

  void test_times_knownDouble_unknownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _intValue(null));
  }

  void test_times_knownInt_knownInt() {
    _assertTimes(_intValue(6), _intValue(2), _intValue(3));
  }

  void test_times_knownInt_knownString() {
    _assertTimes(null, _intValue(2), _stringValue("3"));
  }

  void test_times_knownInt_unknownDouble() {
    _assertTimes(_doubleValue(null), _intValue(2), _doubleValue(null));
  }

  void test_times_knownInt_unknownInt() {
    _assertTimes(_intValue(null), _intValue(2), _intValue(null));
  }

  void test_times_knownString_knownInt() {
    _assertTimes(null, _stringValue("2"), _intValue(3));
  }

  void test_times_unknownDouble_knownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_times_unknownDouble_knownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_times_unknownInt_knownDouble() {
    _assertTimes(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_times_unknownInt_knownInt() {
    _assertTimes(_intValue(null), _intValue(null), _intValue(3));
  }

  /**
   * Assert that the result of adding the left and right operands is the expected value, or that the
   * operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertAdd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.add(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.add(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-anding the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitAnd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitAnd(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.bitAnd(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the bit-not of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.bitNot(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = operand.bitNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-oring the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitOr(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitOr(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.bitOr(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-xoring the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitXor(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitXor(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.bitXor(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of concatenating the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertConcatenate(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.concatenate(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.concatenate(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of dividing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertDivide(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.divide(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.divide(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands for equality is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertEqualEqual(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.equalEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.equalEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertGreaterThan(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.greaterThan(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.greaterThan(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertGreaterThanOrEqual(DartObjectImpl expected,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands using
   * identical() is the expected value.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   */
  void _assertIdentical(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    DartObjectImpl result =
        leftOperand.isIdentical(_typeProvider, rightOperand);
    expect(result, isNotNull);
    expect(result, expected);
  }

  void _assertInstanceOfObjectArray(Object result) {
    // TODO(scheglov) implement
  }

  /**
   * Assert that the result of dividing the left and right operands as integers is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertIntegerDivide(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.integerDivide(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.integerDivide(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLessThan(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.lessThan(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.lessThan(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLessThanOrEqual(DartObjectImpl expected,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-anding the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalAnd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.logicalAnd(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.logicalAnd(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the logical-not of the operand is the expected value, or that the operation throws
   * an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.logicalNot(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = operand.logicalNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-oring the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalOr(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.logicalOr(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.logicalOr(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of subtracting the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertMinus(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.minus(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.minus(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the negation of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertNegated(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.negated(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = operand.negated(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands for inequality is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertNotEqual(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.notEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.notEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that converting the operand to a string is the expected value, or that the operation
   * throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertPerformToString(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.performToString(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = operand.performToString(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of taking the remainder of the left and right operands is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertRemainder(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.remainder(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.remainder(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertShiftLeft(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.shiftLeft(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.shiftLeft(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertShiftRight(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.shiftRight(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result =
          leftOperand.shiftRight(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the length of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertStringLength(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.stringLength(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = operand.stringLength(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertTimes(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.times(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException catch (exception) {
      }
    } else {
      DartObjectImpl result = leftOperand.times(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  DartObjectImpl _boolValue(bool value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.boolType,
          BoolState.UNKNOWN_VALUE);
    } else if (identical(value, false)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.FALSE_STATE);
    } else if (identical(value, true)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.TRUE_STATE);
    }
    fail("Invalid boolean value used in test");
    return null;
  }

  DartObjectImpl _doubleValue(double value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.doubleType,
          DoubleState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.doubleType,
          new DoubleState(value));
    }
  }

  DartObjectImpl _dynamicValue() {
    return new DartObjectImpl(
        _typeProvider.nullType,
        DynamicState.DYNAMIC_STATE);
  }

  DartObjectImpl _intValue(int value) {
    if (value == null) {
      return new DartObjectImpl(_typeProvider.intType, IntState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(_typeProvider.intType, new IntState(value));
    }
  }

  DartObjectImpl _listValue([List<DartObjectImpl> elements = DartObjectImpl.EMPTY_LIST]) {
    return new DartObjectImpl(_typeProvider.listType, new ListState(elements));
  }

  DartObjectImpl _mapValue([List<DartObjectImpl> keyElementPairs = DartObjectImpl.EMPTY_LIST]) {
    Map<DartObjectImpl, DartObjectImpl> map =
        new Map<DartObjectImpl, DartObjectImpl>();
    int count = keyElementPairs.length;
    for (int i = 0; i < count; ) {
      map[keyElementPairs[i++]] = keyElementPairs[i++];
    }
    return new DartObjectImpl(_typeProvider.mapType, new MapState(map));
  }

  DartObjectImpl _nullValue() {
    return new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
  }

  DartObjectImpl _numValue() {
    return new DartObjectImpl(_typeProvider.nullType, NumState.UNKNOWN_VALUE);
  }

  DartObjectImpl _stringValue(String value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.stringType,
          StringState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.stringType,
          new StringState(value));
    }
  }

  DartObjectImpl _symbolValue(String value) {
    return new DartObjectImpl(_typeProvider.symbolType, new SymbolState(value));
  }
}


class DartUriResolverTest {
  void test_creation() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    expect(new DartUriResolver(sdk), isNotNull);
  }

  void test_isDartUri_null_scheme() {
    Uri uri = parseUriWithException("foo.dart");
    expect('', uri.scheme);
    expect(DartUriResolver.isDartUri(uri), isFalse);
  }

  void test_resolve_dart() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNotNull);
  }

  void test_resolve_dart_nonExistingLibrary() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result = resolver.resolveAbsolute(parseUriWithException("dart:cor"));
    expect(result, isNull);
  }

  void test_resolve_nonDart() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result =
        resolver.resolveAbsolute(parseUriWithException("package:some/file.dart"));
    expect(result, isNull);
  }
}


class DeclaredVariablesTest extends EngineTestCase {
  void test_getBool_false() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "false");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.boolValue, false);
  }

  void test_getBool_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "not true");
    _assertNullDartObject(
        typeProvider,
        variables.getBool(typeProvider, variableName));
  }

  void test_getBool_true() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "true");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.boolValue, true);
  }

  void test_getBool_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(typeProvider.boolType,
        variables.getBool(typeProvider, variableName));
  }

  void test_getInt_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "four score and seven years");
    _assertNullDartObject(
        typeProvider,
        variables.getInt(typeProvider, variableName));
  }

  void test_getInt_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(typeProvider.intType,
        variables.getInt(typeProvider, variableName));
  }

  void test_getInt_valid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "23");
    DartObject object = variables.getInt(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.intValue, 23);
  }

  void test_getString_defined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    String value = "value";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, value);
    DartObject object = variables.getString(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.stringValue, value);
  }

  void test_getString_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(typeProvider.stringType,
        variables.getString(typeProvider, variableName));
  }

  void _assertNullDartObject(TestTypeProvider typeProvider, DartObject result) {
    expect(result.type, typeProvider.nullType);
  }

  void _assertUnknownDartObject(ParameterizedType expectedType,
                                DartObject result) {
    expect((result as DartObjectImpl).isUnknown, isTrue);
    expect(result.type, expectedType);
  }
}


class DirectoryBasedDartSdkTest {
  void fail_getDocFileFor() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile docFile = sdk.getDocFileFor("html");
    expect(docFile, isNotNull);
  }

  void test_creation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    expect(sdk, isNotNull);
  }

  void test_fromFile_invalid() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    expect(sdk.fromFileUri(new JavaFile("/not/in/the/sdk.dart").toURI()), isNull);
  }

  void test_fromFile_library() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(
        new JavaFile.relative(
            new JavaFile.relative(sdk.libraryDirectory, "core"),
            "core.dart").toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core");
  }

  void test_fromFile_part() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(
        new JavaFile.relative(
            new JavaFile.relative(sdk.libraryDirectory, "core"),
            "num.dart").toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core/num.dart");
  }

  void test_getDart2JsExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.dart2JsExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getDartFmtExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.dartFmtExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.directory;
    expect(directory, isNotNull);
    expect(directory.exists(), isTrue);
  }

  void test_getDocDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.docDirectory;
    expect(directory, isNotNull);
  }

  void test_getLibraryDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.libraryDirectory;
    expect(directory, isNotNull);
    expect(directory.exists(), isTrue);
  }

  void test_getPubExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.pubExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getSdkVersion() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    String version = sdk.sdkVersion;
    expect(version, isNotNull);
    expect(version.length > 0, isTrue);
  }

  void test_getVmExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.vmExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  DirectoryBasedDartSdk _createDartSdk() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull, reason: "No SDK configured; set the property 'com.google.dart.sdk' on the command line");
    return new DirectoryBasedDartSdk(sdkDirectory);
  }
}


class DirectoryBasedSourceContainerTest {
  void test_contains() {
    JavaFile dir = FileUtilities2.createFile("/does/not/exist");
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist/some.dart");
    JavaFile file2 =
        FileUtilities2.createFile("/does/not/exist/folder/some2.dart");
    JavaFile file3 = FileUtilities2.createFile("/does/not/exist3/some3.dart");
    FileBasedSource source1 = new FileBasedSource.con1(file1);
    FileBasedSource source2 = new FileBasedSource.con1(file2);
    FileBasedSource source3 = new FileBasedSource.con1(file3);
    DirectoryBasedSourceContainer container =
        new DirectoryBasedSourceContainer.con1(dir);
    expect(container.contains(source1), isTrue);
    expect(container.contains(source2), isTrue);
    expect(container.contains(source3), isFalse);
  }
}


class ElementBuilderTest extends EngineTestCase {
  void test_visitCatchClause() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String exceptionParameterName = "e";
    String stackParameterName = "s";
    CatchClause clause =
        AstFactory.catchClause2(exceptionParameterName, stackParameterName);
    clause.accept(builder);
    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(2));
    VariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.isSynthetic, isFalse);
    expect(exceptionVariable.isConst, isFalse);
    expect(exceptionVariable.isFinal, isFalse);
    expect(exceptionVariable.initializer, isNull);
    VariableElement stackVariable = variables[1];
    expect(stackVariable, isNotNull);
    expect(stackVariable.name, stackParameterName);
    expect(stackVariable.isSynthetic, isFalse);
    expect(stackVariable.isConst, isFalse);
    expect(stackVariable.isFinal, isFalse);
    expect(stackVariable.initializer, isNull);
  }

  void test_visitClassDeclaration_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        Keyword.ABSTRACT,
        className,
        null,
        null,
        null,
        null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isTrue);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration =
        AstFactory.classDeclaration(null, className, null, null, null, null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_parameterized() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    String firstVariableName = "E";
    String secondVariableName = "F";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([firstVariableName, secondVariableName]),
        null,
        null,
        null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstVariableName);
    expect(typeParameters[1].name, secondVariableName);
    expect(type.isAbstract, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_withMembers() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    String typeParameterName = "E";
    String fieldName = "f";
    String methodName = "m";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([typeParameterName]),
        null,
        null,
        null,
        [
            AstFactory.fieldDeclaration2(
                false,
                null,
                [AstFactory.variableDeclaration(fieldName)]),
            AstFactory.methodDeclaration2(
                null,
                null,
                null,
                null,
                AstFactory.identifier3(methodName),
                AstFactory.formalParameterList(),
                AstFactory.blockFunctionBody2())]);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    expect(type.isAbstract, isFalse);
    expect(type.isSynthetic, isFalse);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
    List<FieldElement> fields = type.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, fieldName);
    List<MethodElement> methods = type.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
  }

  void test_visitClassTypeAlias() {
    // class B {}
    // class M {}
    // class C = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstFactory.classTypeAlias('C', null, null,
        AstFactory.typeName(classB, []), withClause, null);
    alias.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(alias.element, same(type));
    expect(type.name, equals('C'));
    expect(type.isAbstract, isFalse);
    expect(type.isSynthetic, isFalse);
    expect(type.typeParameters, isEmpty);
    expect(type.fields, isEmpty);
    expect(type.methods, isEmpty);
  }

  void test_visitClassTypeAlias_abstract() {
    // class B {}
    // class M {}
    // abstract class C = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias('C', null,
        Keyword.ABSTRACT, AstFactory.typeName(classB, []), withClause, null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.isAbstract, isTrue);
  }

  void test_visitClassTypeAlias_typeParams() {
    // class B {}
    // class M {}
    // class C<T> = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElementImpl classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias('C',
        AstFactory.typeParameterList(['T']), null,
        AstFactory.typeName(classB, []), withClause, null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.typeParameters, hasLength(1));
    expect(type.typeParameters[0].name, equals('T'));
  }

  void test_visitConstructorDeclaration_factory() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            Keyword.FACTORY,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isFactory, isTrue);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_named() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            constructorName,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, constructorName);
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.name.staticElement, same(constructor));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitConstructorDeclaration_unnamed() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitEnumDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String enumName = "E";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2(enumName, ["ONE"]);
    enumDeclaration.accept(builder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    ClassElement enumElement = enums[0];
    expect(enumElement, isNotNull);
    expect(enumElement.name, enumName);
  }

  void test_visitFieldDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String firstFieldName = "x";
    String secondFieldName = "y";
    FieldDeclaration fieldDeclaration = AstFactory.fieldDeclaration2(
        false,
        null,
        [
            AstFactory.variableDeclaration(firstFieldName),
            AstFactory.variableDeclaration(secondFieldName)]);
    fieldDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(2));
    FieldElement firstField = fields[0];
    expect(firstField, isNotNull);
    expect(firstField.name, firstFieldName);
    expect(firstField.initializer, isNull);
    expect(firstField.isConst, isFalse);
    expect(firstField.isFinal, isFalse);
    expect(firstField.isSynthetic, isFalse);
    FieldElement secondField = fields[1];
    expect(secondField, isNotNull);
    expect(secondField.name, secondFieldName);
    expect(secondField.initializer, isNull);
    expect(secondField.isConst, isFalse);
    expect(secondField.isFinal, isFalse);
    expect(secondField.isSynthetic, isFalse);
  }

  void test_visitFieldFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter =
        AstFactory.fieldFormalParameter(null, null, parameterName);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(0));
  }

  void test_visitFieldFormalParameter_funtionTyped() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter = AstFactory.fieldFormalParameter(
        null,
        null,
        parameterName,
        AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("a")]));
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(1));
  }

  void test_visitFormalParameterList() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String firstParameterName = "a";
    String secondParameterName = "b";
    FormalParameterList parameterList = AstFactory.formalParameterList(
        [
            AstFactory.simpleFormalParameter3(firstParameterName),
            AstFactory.simpleFormalParameter3(secondParameterName)]);
    parameterList.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
  }

  void test_visitFunctionDeclaration_getter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.GET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
    declaration.accept(builder);
    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    expect(accessor.name, functionName);
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.isGetter, isTrue);
    expect(accessor.isSetter, isFalse);
    expect(accessor.isSynthetic, isFalse);
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement,
        variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_plain() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
    declaration.accept(builder);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.isSynthetic, isFalse);
  }

  void test_visitFunctionDeclaration_setter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.SET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
    declaration.accept(builder);
    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    expect(accessor.name, "$functionName=");
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.isGetter, isFalse);
    expect(accessor.isSetter, isTrue);
    expect(accessor.isSynthetic, isFalse);
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement,
        variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionExpression() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    FunctionExpression expression = AstFactory.functionExpression2(
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    expression.accept(builder);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(expression.element, same(function));
    expect(function.isSynthetic, isFalse);
  }

  void test_visitFunctionTypeAlias() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    String parameterName = "E";
    FunctionTypeAlias aliasNode = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList([parameterName]),
        null);
    aliasNode.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, parameterName);
  }

  void test_visitFunctionTypedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstFactory.functionTypedFormalParameter(null, parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    {
      SourceRange visibleRange = parameter.visibleRange;
      expect(100, visibleRange.offset);
      expect(110, visibleRange.end);
    }
  }

  void test_visitLabeledStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String labelName = "l";
    LabeledStatement statement = AstFactory.labeledStatement(
        [AstFactory.label2(labelName)],
        AstFactory.breakStatement());
    statement.accept(builder);
    List<LabelElement> labels = holder.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
    expect(label.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.isAbstract, isTrue);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_getter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.isAbstract, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.isAbstract, isTrue);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_external() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.isAbstract, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_operator() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "+";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        Keyword.OPERATOR,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("addend")]),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(1));
    expect(method.isAbstract, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_setter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.isAbstract, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.isAbstract, isTrue);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_external() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.isAbstract, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_static() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        Keyword.STATIC,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isStatic, isTrue);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_withMembers() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    String parameterName = "p";
    String localVariableName = "v";
    String labelName = "l";
    String exceptionParameterName = "e";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(
            [AstFactory.simpleFormalParameter3(parameterName)]),
        AstFactory.blockFunctionBody2([
            AstFactory.variableDeclarationStatement2(
                Keyword.VAR,
                [AstFactory.variableDeclaration(localVariableName)]),
            AstFactory.tryStatement2(
                AstFactory.block([AstFactory.labeledStatement(
                    [AstFactory.label2(labelName)],
                    AstFactory.returnStatement())]),
                [AstFactory.catchClause(exceptionParameterName)])]));
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
    expect(method.isAbstract, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
    List<VariableElement> parameters = method.parameters;
    expect(parameters, hasLength(1));
    VariableElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    List<VariableElement> localVariables = method.localVariables;
    expect(localVariables, hasLength(2));
    VariableElement firstVariable = localVariables[0];
    VariableElement secondVariable = localVariables[1];
    expect(firstVariable, isNotNull);
    expect(secondVariable, isNotNull);
    expect((firstVariable.name == localVariableName &&
            secondVariable.name == exceptionParameterName) ||
            (firstVariable.name == exceptionParameterName &&
                secondVariable.name == localVariableName), isTrue);
    List<LabelElement> labels = method.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
  }

  void test_visitNamedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3(parameterName),
        AstFactory.identifier3("42"));
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.NAMED);
    {
      SourceRange visibleRange = parameter.visibleRange;
      expect(100, visibleRange.offset);
      expect(110, visibleRange.end);
    }
    expect(parameter.defaultValueCode, "42");
    FunctionElement initializer = parameter.initializer;
    expect(initializer, isNotNull);
    expect(initializer.isSynthetic, isTrue);
  }

  void test_visitSimpleFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter =
        AstFactory.simpleFormalParameter3(parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    {
      SourceRange visibleRange = parameter.visibleRange;
      expect(100, visibleRange.offset);
      expect(110, visibleRange.end);
    }
  }

  void test_visitTypeAlias_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, null, null);
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
  }

  void test_visitTypeAlias_withFormalParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    String firstParameterName = "x";
    String secondParameterName = "y";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(),
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3(firstParameterName),
                AstFactory.simpleFormalParameter3(secondParameterName)]));
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters, hasLength(0));
  }

  void test_visitTypeAlias_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    String firstTypeParameterName = "A";
    String secondTypeParameterName = "B";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList([firstTypeParameterName, secondTypeParameterName]),
        AstFactory.formalParameterList());
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, isNotNull);
    expect(parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstTypeParameterName);
    expect(typeParameters[1].name, secondTypeParameterName);
  }

  void test_visitTypeParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "E";
    TypeParameter typeParameter = AstFactory.typeParameter(parameterName);
    typeParameter.accept(builder);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameterElement = typeParameters[0];
    expect(typeParameterElement, isNotNull);
    expect(typeParameterElement.name, parameterName);
    expect(typeParameterElement.bound, isNull);
    expect(typeParameterElement.isSynthetic, isFalse);
  }

  void test_visitVariableDeclaration_inConstructor() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    //
    // C() {var v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    ConstructorDeclaration constructor = AstFactory.constructorDeclaration2(
        null,
        null,
        AstFactory.identifier3("C"),
        "C",
        AstFactory.formalParameterList(),
        null,
        AstFactory.blockFunctionBody2([statement]));
    constructor.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    List<LocalVariableElement> variableElements =
        constructors[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_inMethod() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    //
    // m() {var v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    MethodDeclaration constructor = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    constructor.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_localNestedInField() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    //
    // var f = () {var v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    Expression initializer = AstFactory.functionExpression2(
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    String fieldName = "f";
    VariableDeclaration field =
        AstFactory.variableDeclaration2(fieldName, initializer);
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [field]);
    fieldDeclaration.accept(builder);
    List<FieldElement> variables = holder.fields;
    expect(variables, hasLength(1));
    FieldElement fieldElement = variables[0];
    expect(fieldElement, isNotNull);
    FunctionElement initializerElement = fieldElement.initializer;
    expect(initializerElement, isNotNull);
    List<FunctionElement> functionElements = initializerElement.functions;
    expect(functionElements, hasLength(1));
    List<LocalVariableElement> variableElements =
        functionElements[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.name, variableName);
    expect(variableElement.isConst, isFalse);
    expect(variableElement.isFinal, isFalse);
    expect(variableElement.isSynthetic, isFalse);
  }

  void test_visitVariableDeclaration_noInitializer() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(null, [variableDeclaration]);
    variableDeclaration.accept(builder);
    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNotNull);
  }

  void _useParameterInMethod(FormalParameter formalParameter, int blockOffset,
      int blockEnd) {
    Block block = AstFactory.block();
    block.leftBracket.offset = blockOffset;
    block.rightBracket.offset = blockEnd - 1;
    BlockFunctionBody body = AstFactory.blockFunctionBody(block);
    AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("main"),
        AstFactory.formalParameterList([formalParameter]),
        body);
  }
}


class ElementLocatorTest extends ResolverTestCase {
  void fail_locate_ExportDirective() {
    AstNode id = _findNodeIn("export", "export 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ImportElement,
        ImportElement,
        element);
  }

  void fail_locate_Identifier_libraryDirective() {
    AstNode id = _findNodeIn("foo", "library foo.bar;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement,
        LibraryElement,
        element);
  }

  void fail_locate_Identifier_partOfDirective() {
    // Can't resolve the library element without the library declaration.
    //    AstNode id = findNodeIn("foo", "part of foo.bar;");
    //    Element element = ElementLocator.locate(id);
    //    assertInstanceOf(LibraryElement.class, element);
    fail("Test this case");
  }

  @override
  void reset() {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.hint = false;
    resetWithOptions(analysisOptions);
  }

  void test_locateWithOffset_BinaryExpression() {
    AstNode id = _findNodeIn("+", "var x = 3 + 4;");
    Element element = ElementLocator.locateWithOffset(id, 0);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locateWithOffset_StringLiteral() {
    AstNode id = _findNodeIn("abc", "var x = 'abc';");
    Element element = ElementLocator.locateWithOffset(id, 1);
    expect(element, isNull);
  }

  void test_locate_AssignmentExpression() {
    AstNode id =
        _findNodeIn("+=", r'''
int x = 0;
void main() {
  x += 1;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_BinaryExpression() {
    AstNode id = _findNodeIn("+", "var x = 3 + 4;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_ClassDeclaration() {
    AstNode id = _findNodeIn("class", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement,
        ClassElement,
        element);
  }

  void test_locate_CompilationUnit() {
    CompilationUnit cu = _resolveContents("// only comment");
    expect(cu.element, isNotNull);
    Element element = ElementLocator.locate(cu);
    expect(element, same(cu.element));
  }

  void test_locate_ConstructorDeclaration() {
    AstNode id =
        _findNodeIndexedIn("bar", 0, r'''
class A {
  A.bar() {}
}''');
    ConstructorDeclaration declaration =
        id.getAncestor((node) => node is ConstructorDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement,
        ConstructorElement,
        element);
  }

  void test_locate_FunctionDeclaration() {
    AstNode id = _findNodeIn("f", "int f() => 3;");
    FunctionDeclaration declaration =
        id.getAncestor((node) => node is FunctionDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement,
        FunctionElement,
        element);
  }

  void
      test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter() {
    AstNode id = _findNodeIndexedIn(
        "Class",
        2,
        r'''
class Class {
  const Class.name();
}
void main(@Class.name() parameter) {
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement,
        ClassElement,
        element);
  }

  void
      test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter() {
    AstNode id = _findNodeIndexedIn(
        "Class",
        2,
        r'''
class Class {
  const Class();
}
void main(@Class() parameter) {
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement,
        ConstructorElement,
        element);
  }

  void test_locate_Identifier_className() {
    AstNode id = _findNodeIn("A", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement,
        ClassElement,
        element);
  }

  void test_locate_Identifier_constructor_named() {
    AstNode id =
        _findNodeIndexedIn("bar", 0, r'''
class A {
  A.bar() {}
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement,
        ConstructorElement,
        element);
  }

  void test_locate_Identifier_constructor_unnamed() {
    AstNode id = _findNodeIndexedIn("A", 1, r'''
class A {
  A() {}
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement,
        ConstructorElement,
        element);
  }

  void test_locate_Identifier_fieldName() {
    AstNode id = _findNodeIn("x", "class A { var x; }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldElement,
        FieldElement,
        element);
  }

  void test_locate_Identifier_propertAccess() {
    AstNode id =
        _findNodeIn("length", r'''
void main() {
 int x = 'foo'.length;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement,
        element);
  }

  void test_locate_ImportDirective() {
    AstNode id = _findNodeIn("import", "import 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ImportElement,
        ImportElement,
        element);
  }

  void test_locate_IndexExpression() {
    AstNode id = _findNodeIndexedIn(
        "\\[",
        1,
        r'''
void main() {
  List x = [1, 2];
  var y = x[0];
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_InstanceCreationExpression() {
    AstNode node =
        _findNodeIndexedIn("A(", 0, r'''
class A {}
void main() {
 new A();
}''');
    Element element = ElementLocator.locate(node);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement,
        ConstructorElement,
        element);
  }

  void test_locate_InstanceCreationExpression_type_prefixedIdentifier() {
    // prepare: new pref.A()
    SimpleIdentifier identifier = AstFactory.identifier3("A");
    PrefixedIdentifier prefixedIdentifier =
        AstFactory.identifier4("pref", identifier);
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression2(
            Keyword.NEW,
            AstFactory.typeName3(prefixedIdentifier));
    // set ClassElement
    ClassElement classElement = ElementFactory.classElement2("A");
    identifier.staticElement = classElement;
    // set ConstructorElement
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classElement, null);
    creation.constructorName.staticElement = constructorElement;
    // verify that "A" is resolved to ConstructorElement
    Element element = ElementLocator.locate(identifier);
    expect(element, same(classElement));
  }

  void test_locate_InstanceCreationExpression_type_simpleIdentifier() {
    // prepare: new A()
    SimpleIdentifier identifier = AstFactory.identifier3("A");
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression2(
            Keyword.NEW,
            AstFactory.typeName3(identifier));
    // set ClassElement
    ClassElement classElement = ElementFactory.classElement2("A");
    identifier.staticElement = classElement;
    // set ConstructorElement
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classElement, null);
    creation.constructorName.staticElement = constructorElement;
    // verify that "A" is resolved to ConstructorElement
    Element element = ElementLocator.locate(identifier);
    expect(element, same(classElement));
  }

  void test_locate_LibraryDirective() {
    AstNode id = _findNodeIn("library", "library foo;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement,
        LibraryElement,
        element);
  }

  void test_locate_MethodDeclaration() {
    AstNode id = _findNodeIn("m", r'''
class A {
  void m() {}
}''');
    MethodDeclaration declaration =
        id.getAncestor((node) => node is MethodDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_MethodInvocation_method() {
    AstNode id = _findNodeIndexedIn(
        "bar",
        1,
        r'''
class A {
  int bar() => 42;
}
void main() {
 var f = new A().bar();
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_MethodInvocation_topLevel() {
    String code =
        r'''
foo(x) {}
void main() {
 foo(0);
}''';
    CompilationUnit cu = _resolveContents(code);
    int offset = code.indexOf('foo(0)');
    AstNode node = new NodeLocator.con1(offset).searchWithin(cu);
    MethodInvocation invocation =
        node.getAncestor((n) => n is MethodInvocation);
    Element element = ElementLocator.locate(invocation);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement,
        FunctionElement,
        element);
  }

  void test_locate_PostfixExpression() {
    AstNode id = _findNodeIn("++", "int addOne(int x) => x++;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_PrefixExpression() {
    AstNode id = _findNodeIn("++", "int addOne(int x) => ++x;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement,
        MethodElement,
        element);
  }

  void test_locate_PrefixedIdentifier() {
    AstNode id =
        _findNodeIn("int", r'''
import 'dart:core' as core;
core.int value;''');
    PrefixedIdentifier identifier =
        id.getAncestor((node) => node is PrefixedIdentifier);
    Element element = ElementLocator.locate(identifier);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement,
        ClassElement,
        element);
  }

  void test_locate_StringLiteral_exportUri() {
    addNamedSource("/foo.dart", "library foo;");
    AstNode id = _findNodeIn("'foo.dart'", "export 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement,
        LibraryElement,
        element);
  }

  void test_locate_StringLiteral_expression() {
    AstNode id = _findNodeIn("abc", "var x = 'abc';");
    Element element = ElementLocator.locate(id);
    expect(element, isNull);
  }

  void test_locate_StringLiteral_importUri() {
    addNamedSource("/foo.dart", "library foo; class A {}");
    AstNode id =
        _findNodeIn("'foo.dart'", "import 'foo.dart'; class B extends A {}");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement,
        LibraryElement,
        element);
  }

  void test_locate_StringLiteral_partUri() {
    addNamedSource("/foo.dart", "part of app;");
    AstNode id = _findNodeIn("'foo.dart'", "library app; part 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is CompilationUnitElement,
        CompilationUnitElement,
        element);
  }

  void test_locate_VariableDeclaration() {
    AstNode id = _findNodeIn("x", "var x = 'abc';");
    VariableDeclaration declaration =
        id.getAncestor((node) => node is VariableDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement,
        element);
  }

  /**
   * Find the first AST node matching a pattern in the resolved AST for the given source.
   *
   * [nodePattern] the (unique) pattern used to identify the node of interest.
   * [code] the code to resolve.
   * Returns the matched node in the resolved AST for the given source lines.
   */
  AstNode _findNodeIn(String nodePattern, String code) {
    return _findNodeIndexedIn(nodePattern, 0, code);
  }

  /**
   * Find the AST node matching the given indexed occurrence of a pattern in the resolved AST for
   * the given source.
   *
   * [nodePattern] the pattern used to identify the node of interest.
   * [index] the index of the pattern match of interest.
   * [code] the code to resolve.
   * Returns the matched node in the resolved AST for the given source lines
   */
  AstNode _findNodeIndexedIn(String nodePattern, int index,
                             String code) {
    CompilationUnit cu = _resolveContents(code);
    int start = _getOffsetOfMatch(code, nodePattern, index);
    int end = start + nodePattern.length;
    return new NodeLocator.con2(start, end).searchWithin(cu);
  }

  int _getOffsetOfMatch(String contents, String pattern, int matchIndex) {
    if (matchIndex == 0) {
      return contents.indexOf(pattern);
    }
    JavaPatternMatcher matcher =
        new JavaPatternMatcher(new RegExp(pattern), contents);
    int count = 0;
    while (matcher.find()) {
      if (count == matchIndex) {
        return matcher.start();
      }
      ++count;
    }
    return -1;
  }

  /**
   * Parse, resolve and verify the given source lines to produce a fully
   * resolved AST.
   *
   * [code] the code to resolve.
   *
   * Returns the result of resolving the AST structure representing the content
   * of the source.
   *
   * Throws if source cannot be verified.
   */
  CompilationUnit _resolveContents(String code) {
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    return analysisContext.resolveCompilationUnit(source, library);
  }
}


class EnumMemberBuilderTest extends EngineTestCase {
  void test_visitEnumDeclaration_multiple() {
    String firstName = "ONE";
    String secondName = "TWO";
    String thirdName = "THREE";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2("E", [firstName, secondName, thirdName]);

    ClassElement enumElement = _buildElement(enumDeclaration);
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(5));

    FieldElement constant = fields[2];
    expect(constant, isNotNull);
    expect(constant.name, firstName);
    expect(constant.isStatic, isTrue);
    _assertGetter(constant);

    constant = fields[3];
    expect(constant, isNotNull);
    expect(constant.name, secondName);
    expect(constant.isStatic, isTrue);
    _assertGetter(constant);

    constant = fields[4];
    expect(constant, isNotNull);
    expect(constant.name, thirdName);
    expect(constant.isStatic, isTrue);
    _assertGetter(constant);
  }

  void test_visitEnumDeclaration_single() {
    String firstName = "ONE";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2("E", [firstName]);

    ClassElement enumElement = _buildElement(enumDeclaration);
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(3));

    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, "index");
    expect(field.isStatic, isFalse);
    expect(field.isSynthetic, isTrue);
    _assertGetter(field);

    field = fields[1];
    expect(field, isNotNull);
    expect(field.name, "values");
    expect(field.isStatic, isTrue);
    expect(field.isSynthetic, isTrue);
    _assertGetter(field);

    FieldElement constant = fields[2];
    expect(constant, isNotNull);
    expect(constant.name, firstName);
    expect(constant.isStatic, isTrue);
    _assertGetter(constant);
  }

  void _assertGetter(FieldElement field) {
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.variable, same(field));
    expect(getter.type, isNotNull);
  }

  ClassElement _buildElement(EnumDeclaration enumDeclaration) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder elementBuilder = new ElementBuilder(holder);
    enumDeclaration.accept(elementBuilder);
    EnumMemberBuilder memberBuilder =
        new EnumMemberBuilder(new TestTypeProvider());
    enumDeclaration.accept(memberBuilder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    return enums[0];
  }
}


class ErrorReporterTest extends EngineTestCase {
  /**
   * Create a type with the given name in a compilation unit with the given name.
   *
   * @param fileName the name of the compilation unit containing the class
   * @param typeName the name of the type to be created
   * @return the type that was created
   */
  InterfaceType createType(String fileName, String typeName) {
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit(fileName);
    ClassElementImpl element = ElementFactory.classElement2(typeName);
    unit.types = <ClassElement>[element];
    return element.type;
  }

  void test_creation() {
    GatheringErrorListener listener = new GatheringErrorListener();
    TestSource source = new TestSource();
    expect(new ErrorReporter(listener, source), isNotNull);
  }

  void test_reportTypeErrorForNode_differentNames() {
    DartType firstType = createType("/test1.dart", "A");
    DartType secondType = createType("/test2.dart", "B");
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") < 0, isTrue);
  }

  void test_reportTypeErrorForNode_sameName() {
    String typeName = "A";
    DartType firstType = createType("/test1.dart", typeName);
    DartType secondType = createType("/test2.dart", typeName);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") >= 0, isTrue);
  }
}


class ErrorSeverityTest extends EngineTestCase {
  void test_max_error_error() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.ERROR), same(ErrorSeverity.ERROR));
  }

  void test_max_error_none() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.NONE), same(ErrorSeverity.ERROR));
  }

  void test_max_error_warning() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.WARNING), same(ErrorSeverity.ERROR));
  }

  void test_max_none_error() {
    expect(ErrorSeverity.NONE.max(ErrorSeverity.ERROR), same(ErrorSeverity.ERROR));
  }

  void test_max_none_none() {
    expect(ErrorSeverity.NONE.max(ErrorSeverity.NONE), same(ErrorSeverity.NONE));
  }

  void test_max_none_warning() {
    expect(ErrorSeverity.NONE.max(ErrorSeverity.WARNING), same(ErrorSeverity.WARNING));
  }

  void test_max_warning_error() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.ERROR), same(ErrorSeverity.ERROR));
  }

  void test_max_warning_none() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.NONE), same(ErrorSeverity.WARNING));
  }

  void test_max_warning_warning() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.WARNING), same(ErrorSeverity.WARNING));
  }
}


class ExitDetectorTest extends ParserTestCase {
  void fail_doStatement_continue_with_label() {
    _assertFalse("{ x: do { continue x; } while(true); }");
  }

  void fail_whileStatement_continue_with_label() {
    _assertFalse("{ x: while (true) { continue x; } }");
  }

  void fail_whileStatement_doStatement_scopeRequired() {
    _assertTrue("{ while (true) { x: do { continue x; } while(true); }");
  }

  void test_asExpression() {
    _assertFalse("a as Object;");
  }

  void test_asExpression_throw() {
    _assertTrue("throw '' as Object;");
  }

  void test_assertStatement() {
    _assertFalse("assert(a);");
  }

  void test_assertStatement_throw() {
    _assertTrue("assert((throw 0));");
  }

  void test_assignmentExpression() {
    _assertFalse("v = 1;");
  }

  void test_assignmentExpression_lhs_throw() {
    _assertTrue("a[throw ''] = 0;");
  }

  void test_assignmentExpression_rhs_throw() {
    _assertTrue("v = throw '';");
  }

  void test_binaryExpression_and() {
    _assertFalse("a && b;");
  }

  void test_binaryExpression_and_lhs() {
    _assertTrue("throw '' && b;");
  }

  void test_binaryExpression_and_rhs() {
    _assertTrue("a && (throw '');");
  }

  void test_binaryExpression_and_rhs2() {
    _assertTrue("false && (throw '');");
  }

  void test_binaryExpression_and_rhs3() {
    _assertFalse("true && (throw '');");
  }

  void test_binaryExpression_or() {
    _assertFalse("a || b;");
  }

  void test_binaryExpression_or_lhs() {
    _assertTrue("throw '' || b;");
  }

  void test_binaryExpression_or_rhs() {
    _assertTrue("a || (throw '');");
  }

  void test_binaryExpression_or_rhs2() {
    _assertTrue("true || (throw '');");
  }

  void test_binaryExpression_or_rhs3() {
    _assertFalse("false || (throw '');");
  }

  void test_block_empty() {
    _assertFalse("{}");
  }

  void test_block_noReturn() {
    _assertFalse("{ int i = 0; }");
  }

  void test_block_return() {
    _assertTrue("{ return 0; }");
  }

  void test_block_returnNotLast() {
    _assertTrue("{ return 0; throw 'a'; }");
  }

  void test_block_throwNotLast() {
    _assertTrue("{ throw 0; x = null; }");
  }

  void test_cascadeExpression_argument() {
    _assertTrue("a..b(throw '');");
  }

  void test_cascadeExpression_index() {
    _assertTrue("a..[throw ''];");
  }

  void test_cascadeExpression_target() {
    _assertTrue("throw ''..b();");
  }

  void test_conditional_ifElse_bothThrows() {
    _assertTrue("c ? throw '' : throw '';");
  }

  void test_conditional_ifElse_elseThrows() {
    _assertFalse("c ? i : throw '';");
  }

  void test_conditional_ifElse_noThrow() {
    _assertFalse("c ? i : j;");
  }

  void test_conditional_ifElse_thenThrow() {
    _assertFalse("c ? throw '' : j;");
  }

  void test_creation() {
    expect(new ExitDetector(), isNotNull);
  }

  void test_doStatement_throwCondition() {
    _assertTrue("{ do {} while (throw ''); }");
  }

  void test_doStatement_true_break() {
    _assertFalse("{ do { break; } while (true); }");
  }

  void test_doStatement_true_continue() {
    _assertTrue("{ do { continue; } while (true); }");
  }

  void test_doStatement_true_if_return() {
    _assertTrue("{ do { if (true) {return null;} } while (true); }");
  }

  void test_doStatement_true_noBreak() {
    _assertTrue("{ do {} while (true); }");
  }

  void test_doStatement_true_return() {
    _assertTrue("{ do { return null; } while (true);  }");
  }

  void test_emptyStatement() {
    _assertFalse(";");
  }

  void test_forEachStatement() {
    _assertFalse("for (element in list) {}");
  }

  void test_forEachStatement_throw() {
    _assertTrue("for (element in throw '') {}");
  }

  void test_forStatement_condition() {
    _assertTrue("for (; throw 0;) {}");
  }

  void test_forStatement_implicitTrue() {
    _assertTrue("for (;;) {}");
  }

  void test_forStatement_implicitTrue_break() {
    _assertFalse("for (;;) { break; }");
  }

  void test_forStatement_initialization() {
    _assertTrue("for (i = throw 0;;) {}");
  }

  void test_forStatement_true() {
    _assertTrue("for (; true; ) {}");
  }

  void test_forStatement_true_break() {
    _assertFalse("{ for (; true; ) { break; } }");
  }

  void test_forStatement_true_continue() {
    _assertTrue("{ for (; true; ) { continue; } }");
  }

  void test_forStatement_true_if_return() {
    _assertTrue("{ for (; true; ) { if (true) {return null;} } }");
  }

  void test_forStatement_true_noBreak() {
    _assertTrue("{ for (; true; ) {} }");
  }

  void test_forStatement_updaters() {
    _assertTrue("for (;; i++, throw 0) {}");
  }

  void test_forStatement_variableDeclaration() {
    _assertTrue("for (int i = throw 0;;) {}");
  }

  void test_functionExpression() {
    _assertFalse("(){};");
  }

  void test_functionExpressionInvocation() {
    _assertFalse("f(g);");
  }

  void test_functionExpressionInvocation_argumentThrows() {
    _assertTrue("f(throw '');");
  }

  void test_functionExpressionInvocation_targetThrows() {
    _assertTrue("throw ''(g);");
  }

  void test_functionExpression_bodyThrows() {
    _assertFalse("(int i) => throw '';");
  }

  void test_identifier_prefixedIdentifier() {
    _assertFalse("a.b;");
  }

  void test_identifier_simpleIdentifier() {
    _assertFalse("a;");
  }

  void test_ifElse_bothReturn() {
    _assertTrue("if (c) return 0; else return 1;");
  }

  void test_ifElse_elseReturn() {
    _assertFalse("if (c) i++; else return 1;");
  }

  void test_ifElse_noReturn() {
    _assertFalse("if (c) i++; else j++;");
  }

  void test_ifElse_thenReturn() {
    _assertFalse("if (c) return 0; else j++;");
  }

  void test_if_false_else_return() {
    _assertTrue("if (false) {} else { return 0; }");
  }

  void test_if_false_noReturn() {
    _assertFalse("if (false) {}");
  }

  void test_if_false_return() {
    _assertFalse("if (false) { return 0; }");
  }

  void test_if_noReturn() {
    _assertFalse("if (c) i++;");
  }

  void test_if_return() {
    _assertFalse("if (c) return 0;");
  }

  void test_if_true_noReturn() {
    _assertFalse("if (true) {}");
  }

  void test_if_true_return() {
    _assertTrue("if (true) { return 0; }");
  }

  void test_indexExpression() {
    _assertFalse("a[b];");
  }

  void test_indexExpression_index() {
    _assertTrue("a[throw ''];");
  }

  void test_indexExpression_target() {
    _assertTrue("throw ''[b];");
  }

  void test_instanceCreationExpression() {
    _assertFalse("new A(b);");
  }

  void test_instanceCreationExpression_argumentThrows() {
    _assertTrue("new A(throw '');");
  }

  void test_isExpression() {
    _assertFalse("A is B;");
  }

  void test_isExpression_throws() {
    _assertTrue("throw '' is B;");
  }

  void test_labeledStatement() {
    _assertFalse("label: a;");
  }

  void test_labeledStatement_throws() {
    _assertTrue("label: throw '';");
  }

  void test_literal_String() {
    _assertFalse("'str';");
  }

  void test_literal_boolean() {
    _assertFalse("true;");
  }

  void test_literal_double() {
    _assertFalse("1.1;");
  }

  void test_literal_integer() {
    _assertFalse("1;");
  }

  void test_literal_null() {
    _assertFalse("null;");
  }

  void test_methodInvocation() {
    _assertFalse("a.b(c);");
  }

  void test_methodInvocation_argument() {
    _assertTrue("a.b(throw '');");
  }

  void test_methodInvocation_target() {
    _assertTrue("throw ''.b(c);");
  }

  void test_parenthesizedExpression() {
    _assertFalse("(a);");
  }

  void test_parenthesizedExpression_throw() {
    _assertTrue("(throw '');");
  }

  void test_propertyAccess() {
    _assertFalse("new Object().a;");
  }

  void test_propertyAccess_throws() {
    _assertTrue("(throw '').a;");
  }

  void test_rethrow() {
    _assertTrue("rethrow;");
  }

  void test_return() {
    _assertTrue("return 0;");
  }

  void test_superExpression() {
    _assertFalse("super.a;");
  }

  void test_switch_allReturn() {
    _assertTrue("switch (i) { case 0: return 0; default: return 1; }");
  }

  void test_switch_defaultWithNoStatements() {
    _assertFalse("switch (i) { case 0: return 0; default: }");
  }

  void test_switch_fallThroughToNotReturn() {
    _assertFalse("switch (i) { case 0: case 1: break; default: return 1; }");
  }

  void test_switch_fallThroughToReturn() {
    _assertTrue("switch (i) { case 0: case 1: return 0; default: return 1; }");
  }

  void test_switch_noDefault() {
    _assertFalse("switch (i) { case 0: return 0; }");
  }

  void test_switch_nonReturn() {
    _assertFalse("switch (i) { case 0: i++; default: return 1; }");
  }

  void test_thisExpression() {
    _assertFalse("this.a;");
  }

  void test_throwExpression() {
    _assertTrue("throw new Object();");
  }

  void test_tryStatement_noReturn() {
    _assertFalse("try {} catch (e, s) {} finally {}");
  }

  void test_tryStatement_return_catch() {
    _assertFalse("try {} catch (e, s) { return 1; } finally {}");
  }

  void test_tryStatement_return_finally() {
    _assertTrue("try {} catch (e, s) {} finally { return 1; }");
  }

  void test_tryStatement_return_try() {
    _assertTrue("try { return 1; } catch (e, s) {} finally {}");
  }

  void test_variableDeclarationStatement_noInitializer() {
    _assertFalse("int i;");
  }

  void test_variableDeclarationStatement_noThrow() {
    _assertFalse("int i = 0;");
  }

  void test_variableDeclarationStatement_throw() {
    _assertTrue("int i = throw new Object();");
  }

  void test_whileStatement_false_nonReturn() {
    _assertFalse("{ while (false) {} }");
  }

  void test_whileStatement_throwCondition() {
    _assertTrue("{ while (throw '') {} }");
  }

  void test_whileStatement_true_break() {
    _assertFalse("{ while (true) { break; } }");
  }

  void test_whileStatement_true_continue() {
    _assertTrue("{ while (true) { continue; } }");
  }

  void test_whileStatement_true_if_return() {
    _assertTrue("{ while (true) { if (true) {return null;} } }");
  }

  void test_whileStatement_true_noBreak() {
    _assertTrue("{ while (true) {} }");
  }

  void test_whileStatement_true_return() {
    _assertTrue("{ while (true) { return null; } }");
  }

  void test_whileStatement_true_throw() {
    _assertTrue("{ while (true) { throw ''; } }");
  }

  void _assertFalse(String source) {
    _assertHasReturn(false, source);
  }

  void _assertHasReturn(bool expectedResult, String source) {
    ExitDetector detector = new ExitDetector();
    Statement statement = ParserTestCase.parseStatement(source);
    expect(statement.accept(detector), same(expectedResult));
  }

  void _assertTrue(String source) {
    _assertHasReturn(true, source);
  }
}


class ExpressionVisitor_AngularTest_verify extends ExpressionVisitor {
  ResolutionVerifier verifier;

  ExpressionVisitor_AngularTest_verify(this.verifier);

  @override
  void visitExpression(Expression expression) {
    expression.accept(verifier);
  }
}


class FileBasedSourceTest {
  void test_equals_false_differentFiles() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist1.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist2.dart");
    FileBasedSource source1 = new FileBasedSource.con1(file1);
    FileBasedSource source2 = new FileBasedSource.con1(file2);
    expect(source1 == source2, isFalse);
  }

  void test_equals_false_null() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist1.dart");
    FileBasedSource source1 = new FileBasedSource.con1(file);
    expect(source1 == null, isFalse);
  }

  void test_equals_true() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource.con1(file1);
    FileBasedSource source2 = new FileBasedSource.con1(file2);
    expect(source1 == source2, isTrue);
  }

  void test_getEncoding() {
    SourceFactory factory = new SourceFactory([new FileUriResolver()]);
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(factory.fromEncoding(source.encoding), source);
  }

  void test_getFullName() {
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(source.fullName, file.getAbsolutePath());
  }

  void test_getShortName() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(source.shortName, "exist.dart");
  }

  void test_hashCode() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource.con1(file1);
    FileBasedSource source2 = new FileBasedSource.con1(file2);
    expect(source2.hashCode, source1.hashCode);
  }

  void test_isInSystemLibrary_contagious() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    SourceFactory factory = new SourceFactory([resolver]);
    // resolve dart:core
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNotNull);
    expect(result.isInSystemLibrary, isTrue);
    // system libraries reference only other system libraries
    Source partSource = factory.resolveUri(result, "num.dart");
    expect(partSource, isNotNull);
    expect(partSource.isInSystemLibrary, isTrue);
  }

  void test_isInSystemLibrary_false() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isFalse);
  }

  void test_issue14500() {
    // see https://code.google.com/p/dart/issues/detail?id=14500
    FileBasedSource source = new FileBasedSource.con1(
        FileUtilities2.createFile("/some/packages/foo:bar.dart"));
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
  }

  void test_resolveRelative_dart_fileName() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("dart:test"), file);
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/lib.dart");
  }

  void test_resolveRelative_dart_filePath() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("dart:test"), file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/c/lib.dart");
  }

  void test_resolveRelative_dart_filePathWithParent() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("dart:test/b/test.dart"), file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/c/lib.dart");
  }

  void test_resolveRelative_file_fileName() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/lib.dart");
  }

  void test_resolveRelative_file_filePath() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/c/lib.dart");
  }

  void test_resolveRelative_file_filePathWithParent() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter, which I
      // believe is not consistent across all machines that might run this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource.con1(file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/c/lib.dart");
  }

  void test_resolveRelative_package_fileName() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("package:b/test.dart"), file);
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:b/lib.dart");
  }

  void test_resolveRelative_package_fileNameWithoutPackageName() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("package:test.dart"), file);
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:lib.dart");
  }

  void test_resolveRelative_package_filePath() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("package:b/test.dart"), file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:b/c/lib.dart");
  }

  void test_resolveRelative_package_filePathWithParent() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("package:a/b/test.dart"), file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:a/c/lib.dart");
  }

  void test_system() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source =
        new FileBasedSource.con2(parseUriWithException("dart:core"), file);
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isTrue);
  }
}


class FileUriResolverTest {
  void test_creation() {
    expect(new FileUriResolver(), isNotNull);
  }

  void test_resolve_file() {
    UriResolver resolver = new FileUriResolver();
    Source result =
        resolver.resolveAbsolute(parseUriWithException("file:/does/not/exist.dart"));
    expect(result, isNotNull);
    expect(result.fullName, FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath());
  }

  void test_resolve_nonFile() {
    UriResolver resolver = new FileUriResolver();
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNull);
  }
}


class HtmlParserTest extends EngineTestCase {
  /**
   * The name of the 'script' tag in an HTML file.
   */
  static String _TAG_SCRIPT = "script";
  void fail_parse_scriptWithComment() {
    String scriptBody = r'''
      /**
       *     <editable-label bind-value="dartAsignableValue">
       *     </editable-label>
       */
      class Foo {}''';
    ht.HtmlUnit htmlUnit = parse("""
<html>
  <body>
    <script type='application/dart'>
$scriptBody
    </script>
  </body>
</html>""");
    _validate(
        htmlUnit,
        [
            _t4(
                "html",
                [
                    _t4(
                        "body",
                        [_t("script", _a(["type", "'application/dart'"]), scriptBody)])])]);
  }
  ht.HtmlUnit parse(String contents) {
//    TestSource source =
//        new TestSource.con1(FileUtilities2.createFile("/test.dart"), contents);
    ht.AbstractScanner scanner = new ht.StringScanner(null, contents);
    scanner.passThroughElements = <String>[_TAG_SCRIPT];
    ht.Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ht.HtmlUnit unit =
        new ht.HtmlParser(null, errorListener).parse(token, lineInfo);
    errorListener.assertNoErrors();
    return unit;
  }
  void test_parse_attribute() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
    _validate(
        htmlUnit,
        [_t4("html", [_t("body", _a(["foo", "\"sdfsdf\""]), "")])]);
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.attributes[0].text, "sdfsdf");
  }
  void test_parse_attribute_EOF() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"");
    _validate(
        htmlUnit,
        [_t4("html", [_t("body", _a(["foo", "\"sdfsdf\""]), "")])]);
  }
  void test_parse_attribute_EOF_missing_quote() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsd");
    _validate(
        htmlUnit,
        [_t4("html", [_t("body", _a(["foo", "\"sdfsd"]), "")])]);
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.attributes[0].text, "sdfsd");
  }
  void test_parse_attribute_extra_quote() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"\"></body></html>");
    _validate(
        htmlUnit,
        [_t4("html", [_t("body", _a(["foo", "\"sdfsdf\""]), "")])]);
  }
  void test_parse_attribute_single_quote() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo='sdfsdf'></body></html>");
    _validate(
        htmlUnit,
        [_t4("html", [_t("body", _a(["foo", "'sdfsdf'"]), "")])]);
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.attributes[0].text, "sdfsdf");
  }
  void test_parse_comment_embedded() {
    ht.HtmlUnit htmlUnit = parse("<html <!-- comment -->></html>");
    _validate(htmlUnit, [_t3("html", "")]);
  }
  void test_parse_comment_first() {
    ht.HtmlUnit htmlUnit = parse("<!-- comment --><html></html>");
    _validate(htmlUnit, [_t3("html", "")]);
  }
  void test_parse_comment_in_content() {
    ht.HtmlUnit htmlUnit = parse("<html><!-- comment --></html>");
    _validate(htmlUnit, [_t3("html", "<!-- comment -->")]);
  }
  void test_parse_content() {
    ht.HtmlUnit htmlUnit = parse("<html>\n<p a=\"b\">blat \n </p>\n</html>");
    // ht.XmlTagNode.getContent() does not include whitespace
    // between '<' and '>' at this time
    _validate(
        htmlUnit,
        [
            _t3(
                "html",
                "\n<pa=\"b\">blat \n </p>\n",
                [_t("p", _a(["a", "\"b\""]), "blat \n ")])]);
  }
  void test_parse_content_none() {
    ht.HtmlUnit htmlUnit = parse("<html><p/>blat<p/></html>");
    _validate(
        htmlUnit,
        [_t3("html", "<p/>blat<p/>", [_t3("p", ""), _t3("p", "")])]);
  }
  void test_parse_declaration() {
    ht.HtmlUnit htmlUnit = parse("<!DOCTYPE html>\n\n<html><p></p></html>");
    _validate(htmlUnit, [_t4("html", [_t3("p", "")])]);
  }
  void test_parse_directive() {
    ht.HtmlUnit htmlUnit = parse("<?xml ?>\n\n<html><p></p></html>");
    _validate(htmlUnit, [_t4("html", [_t3("p", "")])]);
  }
  void test_parse_getAttribute() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.getAttribute("foo").text, "sdfsdf");
    expect(bodyNode.getAttribute("bar"), null);
    expect(bodyNode.getAttribute(null), null);
  }
  void test_parse_getAttributeText() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.getAttributeText("foo"), "sdfsdf");
    expect(bodyNode.getAttributeText("bar"), null);
    expect(bodyNode.getAttributeText(null), null);
  }
  void test_parse_headers() {
    String code = r'''
<html>
  <body>
    <h2>000</h2>
    <div>
      111
    </div>
  </body>
</html>''';
    ht.HtmlUnit htmlUnit = parse(code);
    _validate(
        htmlUnit,
        [_t4("html", [_t4("body", [_t3("h2", "000"), _t4("div")])])]);
  }
  void test_parse_script() {
    ht.HtmlUnit htmlUnit =
        parse("<html><script >here is <p> some</script></html>");
    _validate(htmlUnit, [_t4("html", [_t3("script", "here is <p> some")])]);
  }
  void test_parse_self_closing() {
    ht.HtmlUnit htmlUnit = parse("<html>foo<br>bar</html>");
    _validate(htmlUnit, [_t3("html", "foo<br>bar", [_t3("br", "")])]);
  }
  void test_parse_self_closing_declaration() {
    ht.HtmlUnit htmlUnit = parse("<!DOCTYPE html><html>foo</html>");
    _validate(htmlUnit, [_t3("html", "foo")]);
  }
  XmlValidator_Attributes _a(List<String> keyValuePairs) =>
      new XmlValidator_Attributes(keyValuePairs);
  XmlValidator_Tag _t(String tag, XmlValidator_Attributes attributes,
      String content, [List<XmlValidator_Tag> children = XmlValidator_Tag.EMPTY_LIST]) =>
      new XmlValidator_Tag(tag, attributes, content, children);
  XmlValidator_Tag _t3(String tag, String content,
      [List<XmlValidator_Tag> children = XmlValidator_Tag.EMPTY_LIST]) =>
      new XmlValidator_Tag(tag, new XmlValidator_Attributes(), content, children);
  XmlValidator_Tag _t4(String tag, [List<XmlValidator_Tag> children = XmlValidator_Tag.EMPTY_LIST]) =>
      new XmlValidator_Tag(tag, new XmlValidator_Attributes(), null, children);
  void _validate(ht.HtmlUnit htmlUnit, List<XmlValidator_Tag> expectedTags) {
    XmlValidator validator = new XmlValidator();
    validator.expectTags(expectedTags);
    htmlUnit.accept(validator);
    validator.assertValid();
  }
}


class HtmlTagInfoBuilderTest extends HtmlParserTest {
  void test_builder() {
    HtmlTagInfoBuilder builder = new HtmlTagInfoBuilder();
    ht.HtmlUnit unit = parse(r'''
<html>
  <body>
    <div id="x"></div>
    <p class='c'></p>
    <div class='c'></div>
  </body>
</html>''');
    unit.accept(builder);
    HtmlTagInfo info = builder.getTagInfo();
    expect(info, isNotNull);
    List<String> allTags = info.allTags;
    expect(allTags, hasLength(4));
    expect(info.getTagWithId("x"), "div");
    List<String> tagsWithClass = info.getTagsWithClass("c");
    expect(tagsWithClass, hasLength(2));
  }
}


class HtmlUnitBuilderTest extends EngineTestCase {
  AnalysisContextImpl _context;
  @override
  void setUp() {
    _context = AnalysisContextFactory.contextWithCore();
  }
  @override
  void tearDown() {
    _context = null;
    super.tearDown();
  }
  void test_embedded_script() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart">foo=2;</script>
</html>''');
    _validate(element, [_s(_l([_v("foo")]))]);
  }
  void test_embedded_script_no_content() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart"></script>
</html>''');
    _validate(element, [_s(_l())]);
  }
  void test_external_script() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart" src="other.dart"/>
</html>''');
    _validate(element, [_s2("other.dart")]);
  }
  void test_external_script_no_source() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart"/>
</html>''');
    _validate(element, [_s2(null)]);
  }
  void test_external_script_with_content() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart" src="other.dart">blat=2;</script>
</html>''');
    _validate(element, [_s2("other.dart")]);
  }
  void test_no_scripts() {
    HtmlElementImpl element = _build(r'''
<!DOCTYPE html>
<html><p></p></html>''');
    _validate(element, []);
  }
  void test_two_dart_scripts() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart">bar=2;</script>
<script type="application/dart" src="other.dart"/>
<script src="dart.js"/>
</html>''');
    _validate(element, [_s(_l([_v("bar")])), _s2("other.dart")]);
  }
  HtmlElementImpl _build(String contents) {
    TestSource source = new TestSource(
        FileUtilities2.createFile("/test.html").getAbsolutePath(),
        contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    HtmlUnitBuilder builder = new HtmlUnitBuilder(_context);
    return builder.buildHtmlElement(
        source,
        _context.getModificationStamp(source),
        _context.parseHtmlUnit(source));
  }
  HtmlUnitBuilderTest_ExpectedLibrary
      _l([List<HtmlUnitBuilderTest_ExpectedVariable> expectedVariables = HtmlUnitBuilderTest_ExpectedVariable.EMPTY_LIST]) =>
      new HtmlUnitBuilderTest_ExpectedLibrary(this, expectedVariables);
  _ExpectedScript _s(HtmlUnitBuilderTest_ExpectedLibrary expectedLibrary) =>
      new _ExpectedScript.con1(expectedLibrary);
  _ExpectedScript _s2(String scriptSourcePath) =>
      new _ExpectedScript.con2(scriptSourcePath);
  HtmlUnitBuilderTest_ExpectedVariable _v(String varName) =>
      new HtmlUnitBuilderTest_ExpectedVariable(varName);
  void _validate(HtmlElementImpl element,
      List<_ExpectedScript> expectedScripts) {
    expect(element.context, same(_context));
    List<HtmlScriptElement> scripts = element.scripts;
    expect(scripts, isNotNull);
    expect(scripts, hasLength(expectedScripts.length));
    for (int scriptIndex = 0; scriptIndex < scripts.length; scriptIndex++) {
      expectedScripts[scriptIndex]._validate(scriptIndex, scripts[scriptIndex]);
    }
  }
}


class HtmlUnitBuilderTest_ExpectedLibrary {
  final HtmlUnitBuilderTest HtmlUnitBuilderTest_this;
  final List<HtmlUnitBuilderTest_ExpectedVariable> _expectedVariables;
  HtmlUnitBuilderTest_ExpectedLibrary(this.HtmlUnitBuilderTest_this,
      [this._expectedVariables = HtmlUnitBuilderTest_ExpectedVariable.EMPTY_LIST]);
  void _validate(int scriptIndex, EmbeddedHtmlScriptElementImpl script) {
    LibraryElement library = script.scriptLibrary;
    expect(library, isNotNull, reason: "script $scriptIndex");
    expect(script.context, same(HtmlUnitBuilderTest_this._context), reason: "script $scriptIndex");
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull, reason: "script $scriptIndex");
    List<TopLevelVariableElement> variables = unit.topLevelVariables;
    expect(variables, hasLength(_expectedVariables.length));
    for (int index = 0; index < variables.length; index++) {
      _expectedVariables[index].validate(scriptIndex, variables[index]);
    }
    expect(library.enclosingElement, same(script), reason: "script $scriptIndex");
  }
}


class HtmlUnitBuilderTest_ExpectedVariable {
  final String _expectedName;
  static const List<HtmlUnitBuilderTest_ExpectedVariable> EMPTY_LIST
      = const <HtmlUnitBuilderTest_ExpectedVariable>[];
  HtmlUnitBuilderTest_ExpectedVariable(this._expectedName);
  void validate(int scriptIndex, TopLevelVariableElement variable) {
    expect(variable, isNotNull, reason: "script $scriptIndex");
    expect(variable.name, _expectedName, reason: "script $scriptIndex");
  }
}


/**
 * Instances of the class `HtmlWarningCodeTest` test the generation of HTML warning codes.
 */
class HtmlWarningCodeTest extends EngineTestCase {
  /**
   * The source factory used to create the sources to be resolved.
   */
  SourceFactory _sourceFactory;

  /**
   * The analysis context used to resolve the HTML files.
   */
  AnalysisContextImpl _context;

  /**
   * The contents of the 'test.html' file.
   */
  String _contents;

  /**
   * The list of reported errors.
   */
  List<AnalysisError> _errors;
  @override
  void setUp() {
    _sourceFactory = new SourceFactory([new FileUriResolver()]);
    _context = new AnalysisContextImpl();
    _context.sourceFactory = _sourceFactory;
  }

  @override
  void tearDown() {
    _sourceFactory = null;
    _context = null;
    _contents = null;
    _errors = null;
    super.tearDown();
  }

  void test_invalidUri() {
    _verify(r'''
<html>
<script type='application/dart' src='ht:'/>
</html>''',
        [HtmlWarningCode.INVALID_URI]);
    _assertErrorLocation2(_errors[0], "ht:");
  }

  void test_uriDoesNotExist() {
    _verify(r'''
<html>
<script type='application/dart' src='other.dart'/>
</html>''',
        [HtmlWarningCode.URI_DOES_NOT_EXIST]);
    _assertErrorLocation2(_errors[0], "other.dart");
  }

  void _assertErrorLocation(AnalysisError error, int expectedOffset,
      int expectedLength) {
    expect(error.offset, expectedOffset, reason: error.toString());
    expect(error.length, expectedLength, reason: error.toString());
  }

  void _assertErrorLocation2(AnalysisError error, String expectedString) {
    _assertErrorLocation(
        error,
        _contents.indexOf(expectedString),
        expectedString.length);
  }

  void _verify(String contents, List<ErrorCode> expectedErrorCodes) {
    this._contents = contents;
    TestSource source = new TestSource(
        FileUtilities2.createFile("/test.html").getAbsolutePath(),
        contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    HtmlUnitBuilder builder = new HtmlUnitBuilder(_context);
    builder.buildHtmlElement(
        source,
        _context.getModificationStamp(source),
        _context.parseHtmlUnit(source));
    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll2(builder.errorListener);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
    _errors = errorListener.errors;
  }
}


/**
 * Instances of the class `MockDartSdk` implement a [DartSdk].
 */
class MockDartSdk implements DartSdk {
  @override
  AnalysisContext get context => null;

  @override
  List<SdkLibrary> get sdkLibraries => null;

  @override
  String get sdkVersion => null;

  @override
  List<String> get uris => null;

  @override
  Source fromFileUri(Uri uri) => null;

  @override
  SdkLibrary getSdkLibrary(String dartUri) => null;

  @override
  Source mapDartUri(String dartUri) => null;
}


class ReferenceFinderTest extends EngineTestCase {
  DirectedGraph<AstNode> _referenceGraph;
  Map<VariableElement, VariableDeclaration> _variableDeclarationMap;
  Map<ConstructorElement, ConstructorDeclaration> _constructorDeclarationMap;
  VariableDeclaration _head;
  AstNode _tail;
  @override
  void setUp() {
    _referenceGraph = new DirectedGraph<AstNode>();
    _variableDeclarationMap =
        new HashMap<VariableElement, VariableDeclaration>();
    _constructorDeclarationMap =
        new HashMap<ConstructorElement, ConstructorDeclaration>();
    _head = AstFactory.variableDeclaration("v1");
  }
  void test_visitInstanceCreationExpression_const() {
    _visitNode(_makeTailConstructor("A", true, true, true));
    _assertOneArc(_tail);
  }
  void test_visitInstanceCreationExpression_nonConstDeclaration() {
    // In the source:
    //   const x = const A();
    // x depends on "const A()" even if the A constructor
    // isn't declared as const.
    _visitNode(_makeTailConstructor("A", false, true, true));
    _assertOneArc(_tail);
  }
  void test_visitInstanceCreationExpression_nonConstUsage() {
    _visitNode(_makeTailConstructor("A", true, false, true));
    _assertNoArcs();
  }
  void test_visitInstanceCreationExpression_notInMap() {
    // In the source:
    //   const x = const A();
    // x depends on "const A()" even if the AST for the A constructor
    // isn't available.
    _visitNode(_makeTailConstructor("A", true, true, false));
    _assertOneArc(_tail);
  }
  void test_visitSimpleIdentifier_const() {
    _visitNode(_makeTailVariable("v2", true, true));
    _assertOneArc(_tail);
  }
  void test_visitSimpleIdentifier_nonConst() {
    _visitNode(_makeTailVariable("v2", false, true));
    _assertNoArcs();
  }
  void test_visitSimpleIdentifier_notInMap() {
    _visitNode(_makeTailVariable("v2", true, false));
    _assertNoArcs();
  }
  void test_visitSuperConstructorInvocation_const() {
    _visitNode(_makeTailSuperConstructorInvocation("A", true, true));
    _assertOneArc(_tail);
  }
  void test_visitSuperConstructorInvocation_nonConst() {
    _visitNode(_makeTailSuperConstructorInvocation("A", false, true));
    _assertNoArcs();
  }
  void test_visitSuperConstructorInvocation_notInMap() {
    _visitNode(_makeTailSuperConstructorInvocation("A", true, false));
    _assertNoArcs();
  }
  void test_visitSuperConstructorInvocation_unresolved() {
    SuperConstructorInvocation superConstructorInvocation =
        AstFactory.superConstructorInvocation();
    _tail = superConstructorInvocation;
    _visitNode(superConstructorInvocation);
    _assertNoArcs();
  }
  void _assertNoArcs() {
    Set<AstNode> tails = _referenceGraph.getTails(_head);
    expect(tails, hasLength(0));
  }
  void _assertOneArc(AstNode tail) {
    Set<AstNode> tails = _referenceGraph.getTails(_head);
    expect(tails, hasLength(1));
    expect(tails.first, same(tail));
  }
  ReferenceFinder _createReferenceFinder(AstNode source) =>
      new ReferenceFinder(
          source,
          _referenceGraph,
          _variableDeclarationMap,
          _constructorDeclarationMap);
  InstanceCreationExpression _makeTailConstructor(String name,
      bool isConstDeclaration, bool isConstUsage, bool inMap) {
    List<ConstructorInitializer> initializers =
        new List<ConstructorInitializer>();
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration(
            AstFactory.identifier3(name),
            null,
            AstFactory.formalParameterList(),
            initializers);
    if (isConstDeclaration) {
      constructorDeclaration.constKeyword = new KeywordToken(Keyword.CONST, 0);
    }
    ClassElementImpl classElement = ElementFactory.classElement2(name);
    SimpleIdentifier identifier = AstFactory.identifier3(name);
    TypeName type = AstFactory.typeName3(identifier);
    InstanceCreationExpression instanceCreationExpression =
        AstFactory.instanceCreationExpression2(
            isConstUsage ? Keyword.CONST : Keyword.NEW,
            type);
    _tail = instanceCreationExpression;
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(classElement, name, isConstDeclaration);
    if (inMap) {
      _constructorDeclarationMap[constructorElement] = constructorDeclaration;
    }
    instanceCreationExpression.staticElement = constructorElement;
    return instanceCreationExpression;
  }
  SuperConstructorInvocation _makeTailSuperConstructorInvocation(String name,
      bool isConst, bool inMap) {
    List<ConstructorInitializer> initializers =
        new List<ConstructorInitializer>();
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration(
            AstFactory.identifier3(name),
            null,
            AstFactory.formalParameterList(),
            initializers);
    _tail = constructorDeclaration;
    if (isConst) {
      constructorDeclaration.constKeyword = new KeywordToken(Keyword.CONST, 0);
    }
    ClassElementImpl classElement = ElementFactory.classElement2(name);
    SuperConstructorInvocation superConstructorInvocation =
        AstFactory.superConstructorInvocation();
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(classElement, name, isConst);
    if (inMap) {
      _constructorDeclarationMap[constructorElement] = constructorDeclaration;
    }
    superConstructorInvocation.staticElement = constructorElement;
    return superConstructorInvocation;
  }
  SimpleIdentifier _makeTailVariable(String name, bool isConst, bool inMap) {
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration(name);
    _tail = variableDeclaration;
    VariableElementImpl variableElement =
        ElementFactory.localVariableElement2(name);
    variableElement.const3 = isConst;
    AstFactory.variableDeclarationList2(
        isConst ? Keyword.CONST : Keyword.VAR,
        [variableDeclaration]);
    if (inMap) {
      _variableDeclarationMap[variableElement] = variableDeclaration;
    }
    SimpleIdentifier identifier = AstFactory.identifier3(name);
    identifier.staticElement = variableElement;
    return identifier;
  }
  void _visitNode(AstNode node) {
    node.accept(_createReferenceFinder(_head));
  }
}


class SDKLibrariesReaderTest extends EngineTestCase {
  void test_readFrom_dart2js() {
    LibraryMap libraryMap = new SdkLibrariesReader(
        true).readFromFile(
            FileUtilities2.createFile("/libs.dart"),
            r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    category: 'First',
    documented: true,
    platforms: VM_PLATFORM,
    dart2jsPath: 'first/first_dart2js.dart'),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 1);
    SdkLibrary first = libraryMap.getLibrary("dart:first");
    expect(first, isNotNull);
    expect(first.category, "First");
    expect(first.path, "first/first_dart2js.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
  }
  void test_readFrom_empty() {
    LibraryMap libraryMap = new SdkLibrariesReader(
        false).readFromFile(FileUtilities2.createFile("/libs.dart"), "");
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 0);
  }
  void test_readFrom_normal() {
    LibraryMap libraryMap = new SdkLibrariesReader(
        false).readFromFile(
            FileUtilities2.createFile("/libs.dart"),
            r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    category: 'First',
    documented: true,
    platforms: VM_PLATFORM),

  'second' : const LibraryInfo(
    'second/second.dart',
    category: 'Second',
    documented: false,
    implementation: true,
    platforms: 0),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 2);
    SdkLibrary first = libraryMap.getLibrary("dart:first");
    expect(first, isNotNull);
    expect(first.category, "First");
    expect(first.path, "first/first.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
    SdkLibrary second = libraryMap.getLibrary("dart:second");
    expect(second, isNotNull);
    expect(second.category, "Second");
    expect(second.path, "second/second.dart");
    expect(second.shortName, "dart:second");
    expect(second.isDart2JsLibrary, false);
    expect(second.isDocumented, false);
    expect(second.isImplementation, true);
    expect(second.isVmLibrary, false);
  }
}


class SourceFactoryTest {
  void test_creation() {
    expect(new SourceFactory([]), isNotNull);
  }
  void test_fromEncoding_invalidUri() {
    SourceFactory factory = new SourceFactory([]);
    try {
      factory.fromEncoding("<:&%>");
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
    }
  }
  void test_fromEncoding_noResolver() {
    SourceFactory factory = new SourceFactory([]);
    try {
      factory.fromEncoding("foo:/does/not/exist.dart");
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
    }
  }
  void test_fromEncoding_valid() {
    String encoding = "file:///does/not/exist.dart";
    SourceFactory factory = new SourceFactory(
        [new UriResolver_SourceFactoryTest_test_fromEncoding_valid(encoding)]);
    expect(factory.fromEncoding(encoding), isNotNull);
  }
  void test_resolveUri_absolute() {
    UriResolver_absolute resolver = new UriResolver_absolute();
    SourceFactory factory =
        new SourceFactory([resolver]);
    factory.resolveUri(null, "dart:core");
    expect(resolver.invoked, isTrue);
  }
  void test_resolveUri_nonAbsolute_absolute() {
    SourceFactory factory =
        new SourceFactory([new UriResolver_nonAbsolute_absolute()]);
    String absolutePath = "/does/not/matter.dart";
    Source containingSource =
        new FileBasedSource.con1(FileUtilities2.createFile("/does/not/exist.dart"));
    Source result = factory.resolveUri(containingSource, absolutePath);
    expect(result.fullName, FileUtilities2.createFile(absolutePath).getAbsolutePath());
  }
  void test_resolveUri_nonAbsolute_relative() {
    SourceFactory factory =
        new SourceFactory([new UriResolver_nonAbsolute_relative()]);
    Source containingSource =
        new FileBasedSource.con1(FileUtilities2.createFile("/does/not/have.dart"));
    Source result = factory.resolveUri(containingSource, "exist.dart");
    expect(result.fullName, FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath());
  }
  void test_restoreUri() {
    JavaFile file1 = FileUtilities2.createFile("/some/file1.dart");
    JavaFile file2 = FileUtilities2.createFile("/some/file2.dart");
    Source source1 = new FileBasedSource.con1(file1);
    Source source2 = new FileBasedSource.con1(file2);
    Uri expected1 = parseUriWithException("file:///my_file.dart");
    SourceFactory factory =
        new SourceFactory([new UriResolver_restoreUri(source1, expected1)]);
    expect(factory.restoreUri(source1), same(expected1));
    expect(factory.restoreUri(source2), same(null));
  }
}


class StringScannerTest extends AbstractScannerTest {
  @override
  ht.AbstractScanner newScanner(String input) {
    return new ht.StringScanner(null, input);
  }
}


/**
 * Instances of the class `ToSourceVisitorTest`
 */
class ToSourceVisitorTest extends EngineTestCase {
  void fail_visitHtmlScriptTagNode_attributes_content() {
    _assertSource(
        "<script type='application/dart'>f() {}</script>",
        HtmlFactory.scriptTagWithContent(
            "f() {}",
            [HtmlFactory.attribute("type", "'application/dart'")]));
  }

  void fail_visitHtmlScriptTagNode_noAttributes_content() {
    _assertSource(
        "<script>f() {}</script>",
        HtmlFactory.scriptTagWithContent("f() {}"));
  }

  void test_visitHtmlScriptTagNode_attributes_noContent() {
    _assertSource(
        "<script type='application/dart'/>",
        HtmlFactory.scriptTag([HtmlFactory.attribute("type", "'application/dart'")]));
  }

  void test_visitHtmlScriptTagNode_noAttributes_noContent() {
    _assertSource("<script/>", HtmlFactory.scriptTag());
  }

  void test_visitHtmlUnit_empty() {
    _assertSource("", new ht.HtmlUnit(null, new List<ht.XmlTagNode>(), null));
  }

  void test_visitHtmlUnit_nonEmpty() {
    _assertSource(
        "<html/>",
        new ht.HtmlUnit(null, [HtmlFactory.tagNode("html")], null));
  }

  void test_visitXmlAttributeNode() {
    _assertSource("x=y", HtmlFactory.attribute("x", "y"));
  }

  /**
   * Assert that a `ToSourceVisitor` will produce the expected source when visiting the given
   * node.
   *
   * @param expectedSource the source string that the visitor is expected to produce
   * @param node the AST node being visited to produce the actual source
   */
  void _assertSource(String expectedSource, ht.XmlNode node) {
    PrintStringWriter writer = new PrintStringWriter();
    node.accept(new ht.ToSourceVisitor(writer));
    expect(writer.toString(), expectedSource);
  }
}


class UriKindTest {
  void test_fromEncoding() {
    expect(UriKind.fromEncoding(0x64), same(UriKind.DART_URI));
    expect(UriKind.fromEncoding(0x66), same(UriKind.FILE_URI));
    expect(UriKind.fromEncoding(0x70), same(UriKind.PACKAGE_URI));
    expect(UriKind.fromEncoding(0x58), same(null));
  }

  void test_getEncoding() {
    expect(UriKind.DART_URI.encoding, 0x64);
    expect(UriKind.FILE_URI.encoding, 0x66);
    expect(UriKind.PACKAGE_URI.encoding, 0x70);
  }
}


class UriResolver_SourceFactoryTest_test_fromEncoding_valid extends UriResolver
    {
  String encoding;

  UriResolver_SourceFactoryTest_test_fromEncoding_valid(this.encoding);

  @override
  Source resolveAbsolute(Uri uri) {
    if (uri.toString() == encoding) {
      return new TestSource();
    }
    return null;
  }
}


class UriResolver_absolute extends UriResolver {
  bool invoked = false;

  UriResolver_absolute();

  @override
  Source resolveAbsolute(Uri uri) {
    invoked = true;
    return null;
  }
}


class UriResolver_nonAbsolute_absolute extends UriResolver {
  @override
  Source resolveAbsolute(Uri uri) {
    return new FileBasedSource.con2(uri, new JavaFile.fromUri(uri));
  }
}


class UriResolver_nonAbsolute_relative extends UriResolver {
  @override
  Source resolveAbsolute(Uri uri) {
    return new FileBasedSource.con2(uri, new JavaFile.fromUri(uri));
  }
}


class UriResolver_restoreUri extends UriResolver {
  Source source1;

  Uri expected1;

  UriResolver_restoreUri(this.source1, this.expected1);

  @override
  Source resolveAbsolute(Uri uri) => null;

  @override
  Uri restoreAbsolute(Source source) {
    if (identical(source, source1)) {
      return expected1;
    }
    return null;
  }
}


class ValidatingConstantValueComputer extends ConstantValueComputer {
  AstNode _nodeBeingEvaluated;
  ValidatingConstantValueComputer(TypeProvider typeProvider,
      DeclaredVariables declaredVariables)
      : super(typeProvider, declaredVariables);

  @override
  void beforeComputeValue(AstNode constNode) {
    super.beforeComputeValue(constNode);
    _nodeBeingEvaluated = constNode;
  }

  @override
  void beforeGetConstantInitializers(ConstructorElement constructor) {
    super.beforeGetConstantInitializers(constructor);
    // If we are getting the constant initializers for a node in the graph,
    // make sure we properly recorded the dependency.
    ConstructorDeclaration node = findConstructorDeclaration(constructor);
    if (node != null && referenceGraph.nodes.contains(node)) {
      expect(referenceGraph.containsPath(_nodeBeingEvaluated, node), isTrue);
    }
  }

  @override
  void beforeGetParameterDefault(ParameterElement parameter) {
    super.beforeGetParameterDefault(parameter);
    // Find the ConstructorElement and figure out which
    // parameter we're talking about.
    ConstructorElement constructor =
        parameter.getAncestor((element) => element is ConstructorElement);
    int parameterIndex;
    List<ParameterElement> parameters = constructor.parameters;
    int numParameters = parameters.length;
    for (parameterIndex = 0; parameterIndex < numParameters; parameterIndex++) {
      if (identical(parameters[parameterIndex], parameter)) {
        break;
      }
    }
    expect(parameterIndex < numParameters, isTrue);
    // If we are getting the default parameter for a constructor in the graph,
    // make sure we properly recorded the dependency on the parameter.
    ConstructorDeclaration constructorNode =
        constructorDeclarationMap[constructor];
    if (constructorNode != null) {
      FormalParameter parameterNode =
          constructorNode.parameters.parameters[parameterIndex];
      expect(referenceGraph.nodes.contains(parameterNode), isTrue);
      expect(referenceGraph.containsPath(_nodeBeingEvaluated, parameterNode), isTrue);
    }
  }

  @override
  ConstantVisitor createConstantVisitor(ErrorReporter errorReporter) {
    return new ConstantValueComputerTest_ValidatingConstantVisitor(
        typeProvider,
        referenceGraph,
        _nodeBeingEvaluated,
        errorReporter);
  }
}


/**
 * Instances of `XmlValidator` traverse an [XmlNode] structure and validate the node
 * hierarchy.
 */
class XmlValidator extends ht.RecursiveXmlVisitor<Object> {
  /**
   * A list containing the errors found while traversing the AST structure.
   */
  List<String> _errors = new List<String>();
  /**
   * The tags to expect when visiting or `null` if tags should not be checked.
   */
  List<XmlValidator_Tag> _expectedTagsInOrderVisited;
  /**
   * The current index into the [expectedTagsInOrderVisited] array.
   */
  int _expectedTagsIndex = 0;
  /**
   * The key/value pairs to expect when visiting or `null` if attributes should not be
   * checked.
   */
  List<String> _expectedAttributeKeyValuePairs;
  /**
   * The current index into the [expectedAttributeKeyValuePairs].
   */
  int _expectedAttributeIndex = 0;
  /**
   * Assert that no errors were found while traversing any of the AST structures that have been
   * visited.
   */
  void assertValid() {
    while (_expectedTagsIndex < _expectedTagsInOrderVisited.length) {
      String expectedTag =
          _expectedTagsInOrderVisited[_expectedTagsIndex++]._tag;
      _errors.add("Expected to visit node with tag: $expectedTag");
    }
    if (!_errors.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Invalid XML structure:");
      for (String message in _errors) {
        buffer.writeln();
        buffer.write("   ");
        buffer.write(message);
      }
      fail(buffer.toString());
    }
  }
  /**
   * Set the tags to be expected when visiting
   *
   * @param expectedTags the expected tags
   */
  void expectTags(List<XmlValidator_Tag> expectedTags) {
    // Flatten the hierarchy into expected order in which the tags are visited
    List<XmlValidator_Tag> expected = new List<XmlValidator_Tag>();
    _expectTags(expected, expectedTags);
    this._expectedTagsInOrderVisited = expected;
  }
  @override
  Object visitHtmlUnit(ht.HtmlUnit node) {
    if (node.parent != null) {
      _errors.add("HtmlUnit should not have a parent");
    }
    if (node.endToken.type != ht.TokenType.EOF) {
      _errors.add("HtmlUnit end token should be of type EOF");
    }
    _validateNode(node);
    return super.visitHtmlUnit(node);
  }
  @override
  Object visitXmlAttributeNode(ht.XmlAttributeNode actual) {
    if (actual.parent is! ht.XmlTagNode) {
      _errors.add(
          "Expected ${actual.runtimeType} to have parent of type XmlTagNode");
    }
    String actualName = actual.name;
    String actualValue = actual.valueToken.lexeme;
    if (_expectedAttributeIndex < _expectedAttributeKeyValuePairs.length) {
      String expectedName =
          _expectedAttributeKeyValuePairs[_expectedAttributeIndex];
      if (expectedName != actualName) {
        _errors.add(
            "Expected ${_expectedTagsIndex - 1} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${_expectedAttributeIndex ~/ 2} to have name: $expectedName but found: $actualName");
      }
      String expectedValue =
          _expectedAttributeKeyValuePairs[_expectedAttributeIndex + 1];
      if (expectedValue != actualValue) {
        _errors.add(
            "Expected ${_expectedTagsIndex - 1} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${_expectedAttributeIndex ~/ 2} to have value: $expectedValue but found: $actualValue");
      }
    } else {
      _errors.add(
          "Unexpected ${_expectedTagsIndex - 1} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${_expectedAttributeIndex ~/ 2} name: $actualName value: $actualValue");
    }
    _expectedAttributeIndex += 2;
    _validateNode(actual);
    return super.visitXmlAttributeNode(actual);
  }
  @override
  Object visitXmlTagNode(ht.XmlTagNode actual) {
    if (!(actual.parent is ht.HtmlUnit || actual.parent is ht.XmlTagNode)) {
      _errors.add(
          "Expected ${actual.runtimeType} to have parent of type HtmlUnit or XmlTagNode");
    }
    if (_expectedTagsInOrderVisited != null) {
      String actualTag = actual.tag;
      if (_expectedTagsIndex < _expectedTagsInOrderVisited.length) {
        XmlValidator_Tag expected =
            _expectedTagsInOrderVisited[_expectedTagsIndex];
        if (expected._tag != actualTag) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} but found: $actualTag");
        }
        _expectedAttributeKeyValuePairs = expected._attributes._keyValuePairs;
        int expectedAttributeCount =
            _expectedAttributeKeyValuePairs.length ~/
            2;
        int actualAttributeCount = actual.attributes.length;
        if (expectedAttributeCount != actualAttributeCount) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} to have $expectedAttributeCount attributes but found $actualAttributeCount");
        }
        _expectedAttributeIndex = 0;
        _expectedTagsIndex++;
        expect(actual.attributeEnd, isNotNull);
        expect(actual.contentEnd, isNotNull);
        int count = 0;
        ht.Token token = actual.attributeEnd.next;
        ht.Token lastToken = actual.contentEnd;
        while (!identical(token, lastToken)) {
          token = token.next;
          if (++count > 1000) {
            fail("Expected $_expectedTagsIndex tag: ${expected._tag} to have a sequence of tokens from getAttributeEnd() to getContentEnd()");
            break;
          }
        }
        if (actual.attributeEnd.type == ht.TokenType.GT) {
          if (ht.HtmlParser.SELF_CLOSING.contains(actual.tag)) {
            expect(actual.closingTag, isNull);
          } else {
            expect(actual.closingTag, isNotNull);
          }
        } else if (actual.attributeEnd.type == ht.TokenType.SLASH_GT) {
          expect(actual.closingTag, isNull);
        } else {
          fail("Unexpected attribute end token: ${actual.attributeEnd.lexeme}");
        }
        if (expected._content != null && expected._content != actual.content) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} to have content '${expected._content}' but found '${actual.content}'");
        }
        if (expected._children.length != actual.tagNodes.length) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} to have ${expected._children.length} children but found ${actual.tagNodes.length}");
        } else {
          for (int index = 0; index < expected._children.length; index++) {
            String expectedChildTag = expected._children[index]._tag;
            String actualChildTag = actual.tagNodes[index].tag;
            if (expectedChildTag != actualChildTag) {
              _errors.add(
                  "Expected $_expectedTagsIndex tag: ${expected._tag} child $index to have tag: $expectedChildTag but found: $actualChildTag");
            }
          }
        }
      } else {
        _errors.add("Visited unexpected tag: $actualTag");
      }
    }
    _validateNode(actual);
    return super.visitXmlTagNode(actual);
  }
  /**
   * Append the specified tags to the array in depth first order
   *
   * @param expected the array to which the tags are added (not `null`)
   * @param expectedTags the expected tags to be added (not `null`, contains no `null`s)
   */
  void _expectTags(List<XmlValidator_Tag> expected,
      List<XmlValidator_Tag> expectedTags) {
    for (XmlValidator_Tag tag in expectedTags) {
      expected.add(tag);
      _expectTags(expected, tag._children);
    }
  }
  void _validateNode(ht.XmlNode node) {
    if (node.beginToken == null) {
      _errors.add("No begin token for ${node.runtimeType}");
    }
    if (node.endToken == null) {
      _errors.add("No end token for ${node.runtimeType}");
    }
    int nodeStart = node.offset;
    int nodeLength = node.length;
    if (nodeStart < 0 || nodeLength < 0) {
      _errors.add("No source info for ${node.runtimeType}");
    }
    ht.XmlNode parent = node.parent;
    if (parent != null) {
      int nodeEnd = nodeStart + nodeLength;
      int parentStart = parent.offset;
      int parentEnd = parentStart + parent.length;
      if (nodeStart < parentStart) {
        _errors.add(
            "Invalid source start ($nodeStart) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
      if (nodeEnd > parentEnd) {
        _errors.add(
            "Invalid source end ($nodeEnd) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
    }
  }
}


class XmlValidator_Attributes {
  final List<String> _keyValuePairs;
  XmlValidator_Attributes([this._keyValuePairs = StringUtilities.EMPTY_ARRAY]);
}


class XmlValidator_Tag {
  final String _tag;
  final XmlValidator_Attributes _attributes;
  final String _content;
  final List<XmlValidator_Tag> _children;
  static const List<XmlValidator_Tag> EMPTY_LIST = const <XmlValidator_Tag>[];
  XmlValidator_Tag(this._tag, this._attributes, this._content, [this._children = EMPTY_LIST]);
}


class _AngularTest_findElement extends GeneralizingElementVisitor<Object> {
  final ElementKind kind;

  final String name;

  Element result;

  _AngularTest_findElement(this.kind, this.name);

  @override
  Object visitElement(Element element) {
    if ((kind == null || element.kind == kind) && name == element.name) {
      result = element;
    }
    return super.visitElement(element);
  }
}


class _ExpectedScript {
  String _expectedExternalScriptName;
  HtmlUnitBuilderTest_ExpectedLibrary _expectedLibrary;
  _ExpectedScript.con1(HtmlUnitBuilderTest_ExpectedLibrary expectedLibrary) {
    this._expectedExternalScriptName = null;
    this._expectedLibrary = expectedLibrary;
  }
  _ExpectedScript.con2(String expectedExternalScriptPath) {
    this._expectedExternalScriptName = expectedExternalScriptPath;
    this._expectedLibrary = null;
  }
  void _validate(int scriptIndex, HtmlScriptElement script) {
    if (_expectedLibrary != null) {
      _validateEmbedded(scriptIndex, script);
    } else {
      _validateExternal(scriptIndex, script);
    }
  }
  void _validateEmbedded(int scriptIndex, HtmlScriptElement script) {
    if (script is! EmbeddedHtmlScriptElementImpl) {
      fail("Expected script $scriptIndex to be embedded, but found ${script != null ? script.runtimeType : "null"}");
    }
    EmbeddedHtmlScriptElementImpl embeddedScript =
        script as EmbeddedHtmlScriptElementImpl;
    _expectedLibrary._validate(scriptIndex, embeddedScript);
  }
  void _validateExternal(int scriptIndex, HtmlScriptElement script) {
    if (script is! ExternalHtmlScriptElementImpl) {
      fail("Expected script $scriptIndex to be external with src=$_expectedExternalScriptName but found ${script != null ? script.runtimeType : "null"}");
    }
    ExternalHtmlScriptElementImpl externalScript =
        script as ExternalHtmlScriptElementImpl;
    Source scriptSource = externalScript.scriptSource;
    if (_expectedExternalScriptName == null) {
      expect(scriptSource, isNull, reason: "script $scriptIndex");
    } else {
      expect(scriptSource, isNotNull, reason: "script $scriptIndex");
      String actualExternalScriptName = scriptSource.shortName;
      expect(actualExternalScriptName, _expectedExternalScriptName, reason: "script $scriptIndex");
    }
  }
}
