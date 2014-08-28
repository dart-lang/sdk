// // Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
// // This code was auto-generated, is not intended to be edited, and is subject to
// // significant change. Please see the README file for more information.
// abstract class AbstractScannerTest extends JUnitTestCase {
//   void test_tokenize_attribute() {
//     _tokenize("<html bob=\"one two\">", <Object> [LT, "html", "bob", EQ, "\"one two\"", GT]);
//   }
//   void test_tokenize_comment() {
//     _tokenize("<!-- foo -->", <Object> ["<!-- foo -->"]);
//   }
//   void test_tokenize_comment_incomplete() {
//     _tokenize("<!-- foo", <Object> ["<!-- foo"]);
//   }
//   void test_tokenize_comment_with_gt() {
//     _tokenize("<!-- foo > -> -->", <Object> ["<!-- foo > -> -->"]);
//   }
//   void test_tokenize_declaration() {
//     _tokenize("<! foo ><html>", <Object> ["<! foo >", LT, "html", GT]);
//   }
//   void test_tokenize_declaration_malformed() {
//     _tokenize("<! foo /><html>", <Object> ["<! foo />", LT, "html", GT]);
//   }
//   void test_tokenize_directive_incomplete() {
//     _tokenize2("<? \nfoo", <Object> ["<? \nfoo"], <int> [0, 4]);
//   }
//   void test_tokenize_directive_xml() {
//     _tokenize("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", <Object> ["<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"]);
//   }
//   void test_tokenize_directives_incomplete_with_newline() {
//     _tokenize2("<! \nfoo", <Object> ["<! \nfoo"], <int> [0, 4]);
//   }
//   void test_tokenize_empty() {
//     _tokenize("", <Object> []);
//   }
//   void test_tokenize_lt() {
//     _tokenize("<", <Object> [LT]);
//   }
//   void test_tokenize_script_embedded_tags() {
//     _tokenize("<script> <p></p></script>", <Object> [LT, "script", GT, " <p></p>", LT_SLASH, "script", GT]);
//   }
//   void test_tokenize_script_embedded_tags2() {
//     _tokenize("<script> <p></p><</script>", <Object> [LT, "script", GT, " <p></p><", LT_SLASH, "script", GT]);
//   }
//   void test_tokenize_script_embedded_tags3() {
//     _tokenize("<script> <p></p></</script>", <Object> [LT, "script", GT, " <p></p></", LT_SLASH, "script", GT]);
//   }
//   void test_tokenize_script_partial() {
//     _tokenize("<script> <p> ", <Object> [LT, "script", GT, " <p> "]);
//   }
//   void test_tokenize_script_partial2() {
//     _tokenize("<script> <p> <", <Object> [LT, "script", GT, " <p> <"]);
//   }
//   void test_tokenize_script_partial3() {
//     _tokenize("<script> <p> </", <Object> [LT, "script", GT, " <p> </"]);
//   }
//   void test_tokenize_script_ref() {
//     _tokenize("<script source='some.dart'/> <p>", <Object> [
//         LT,
//         "script",
//         "source",
//         EQ,
//         "'some.dart'",
//         SLASH_GT,
//         " ",
//         LT,
//         "p",
//         GT]);
//   }
//   void test_tokenize_script_with_newline() {
//     _tokenize2("<script> <p>\n </script>", <Object> [LT, "script", GT, " <p>\n ", LT_SLASH, "script", GT], <int> [0, 13]);
//   }
//   void test_tokenize_spaces_and_newlines() {
//     Token token = _tokenize2(" < html \n bob = 'joe\n' >\n <\np > one \r\n two <!-- \rfoo --> </ p > </ html > ", <Object> [
//         " ",
//         LT,
//         "html",
//         "bob",
//         EQ,
//         "'joe\n'",
//         GT,
//         "\n ",
//         LT,
//         "p",
//         GT,
//         " one \r\n two ",
//         "<!-- \rfoo -->",
//         " ",
//         LT_SLASH,
//         "p",
//         GT,
//         " ",
//         LT_SLASH,
//         "html",
//         GT,
//         " "], <int> [0, 9, 21, 25, 28, 38, 49]);
//     token = token.next;
//     JUnitTestCase.assertEquals(1, token.offset);
//     token = token.next;
//     JUnitTestCase.assertEquals(3, token.offset);
//     token = token.next;
//     JUnitTestCase.assertEquals(10, token.offset);
//   }
//   void test_tokenize_string() {
//     _tokenize("<p bob=\"foo\">", <Object> [LT, "p", "bob", EQ, "\"foo\"", GT]);
//   }
//   void test_tokenize_string_partial() {
//     _tokenize("<p bob=\"foo", <Object> [LT, "p", "bob", EQ, "\"foo"]);
//   }
//   void test_tokenize_string_single_quote() {
//     _tokenize("<p bob='foo'>", <Object> [LT, "p", "bob", EQ, "'foo'", GT]);
//   }
//   void test_tokenize_string_single_quote_partial() {
//     _tokenize("<p bob='foo", <Object> [LT, "p", "bob", EQ, "'foo"]);
//   }
//   void test_tokenize_tag_begin_end() {
//     _tokenize("<html></html>", <Object> [LT, "html", GT, LT_SLASH, "html", GT]);
//   }
//   void test_tokenize_tag_begin_only() {
//     Token token = _tokenize("<html>", <Object> [LT, "html", GT]);
//     token = token.next;
//     JUnitTestCase.assertEquals(1, token.offset);
//   }
//   void test_tokenize_tag_incomplete_with_special_characters() {
//     _tokenize("<br-a_b", <Object> [LT, "br-a_b"]);
//   }
//   void test_tokenize_tag_self_contained() {
//     _tokenize("<br/>", <Object> [LT, "br", SLASH_GT]);
//   }
//   void test_tokenize_tags_wellformed() {
//     _tokenize("<html><p>one two</p></html>", <Object> [
//         LT,
//         "html",
//         GT,
//         LT,
//         "p",
//         GT,
//         "one two",
//         LT_SLASH,
//         "p",
//         GT,
//         LT_SLASH,
//         "html",
//         GT]);
//   }
//   AbstractScanner newScanner(String input);
//   /**
//    * Given an object representing an expected token, answer the expected token type.
//    *
//    * @param count the token count for error reporting
//    * @param expected the object representing an expected token
//    * @return the expected token type
//    */
//   TokenType _getExpectedTokenType(int count, Object expected) {
//     if (expected is TokenType) {
//       return expected as TokenType;
//     }
//     if (expected is String) {
//       String lexeme = expected as String;
//       if (lexeme.startsWith("\"") || lexeme.startsWith("'")) {
//         return TokenType.STRING;
//       }
//       if (lexeme.startsWith("<!--")) {
//         return TokenType.COMMENT;
//       }
//       if (lexeme.startsWith("<!")) {
//         return TokenType.DECLARATION;
//       }
//       if (lexeme.startsWith("<?")) {
//         return TokenType.DIRECTIVE;
//       }
//       if (_isTag(lexeme)) {
//         return TokenType.TAG;
//       }
//       return TokenType.TEXT;
//     }
//     JUnitTestCase.fail("Unknown expected token ${count}: ${(expected != null ? expected.runtimeType : "null")}");
//     return null;
//   }
//   bool _isTag(String lexeme) {
//     if (lexeme.length == 0 || !Character.isLetter(lexeme.codeUnitAt(0))) {
//       return false;
//     }
//     for (int index = 1; index < lexeme.length; index++) {
//       int ch = lexeme.codeUnitAt(index);
//       if (!Character.isLetterOrDigit(ch) && ch != 0x2D && ch != 0x5F) {
//         return false;
//       }
//     }
//     return true;
//   }
//   Token _tokenize(String input, List<Object> expectedTokens) => _tokenize2(input, expectedTokens, <int> [0]);
//   Token _tokenize2(String input, List<Object> expectedTokens, List<int> expectedLineStarts) {
//     AbstractScanner scanner = newScanner(input);
//     scanner.passThroughElements = <String> ["script"];
//     int count = 0;
//     Token firstToken = scanner.tokenize();
//     Token token = firstToken;
//     Token previousToken = token.previous;
//     JUnitTestCase.assertTrue(previousToken.type == TokenType.EOF);
//     JUnitTestCase.assertSame(previousToken, previousToken.previous);
//     JUnitTestCase.assertEquals(-1, previousToken.offset);
//     JUnitTestCase.assertSame(token, previousToken.next);
//     JUnitTestCase.assertEquals(0, token.offset);
//     while (token.type != TokenType.EOF) {
//       if (count == expectedTokens.length) {
//         JUnitTestCase.fail("too many parsed tokens");
//       }
//       Object expected = expectedTokens[count];
//       TokenType expectedTokenType = _getExpectedTokenType(count, expected);
//       JUnitTestCase.assertSameMsg("token ${count}", expectedTokenType, token.type);
//       if (expectedTokenType.lexeme != null) {
//         JUnitTestCase.assertEqualsMsg("token ${count}", expectedTokenType.lexeme, token.lexeme);
//       } else {
//         JUnitTestCase.assertEqualsMsg("token ${count}", expected, token.lexeme);
//       }
//       count++;
//       previousToken = token;
//       token = token.next;
//       JUnitTestCase.assertSame(previousToken, token.previous);
//     }
//     JUnitTestCase.assertSame(token, token.next);
//     JUnitTestCase.assertEquals(input.length, token.offset);
//     if (count != expectedTokens.length) {
//       JUnitTestCase.assertTrueMsg("not enough parsed tokens", false);
//     }
//     List<int> lineStarts = scanner.lineStarts;
//     bool success = expectedLineStarts.length == lineStarts.length;
//     if (success) {
//       for (int i = 0; i < lineStarts.length; i++) {
//         if (expectedLineStarts[i] != lineStarts[i]) {
//           success = false;
//           break;
//         }
//       }
//     }
//     if (!success) {
//       JavaStringBuilder msg = new JavaStringBuilder();
//       msg.append("Expected line starts ");
//       for (int start in expectedLineStarts) {
//         msg.append(start);
//         msg.append(", ");
//       }
//       msg.append(" but found ");
//       for (int start in lineStarts) {
//         msg.append(start);
//         msg.append(", ");
//       }
//       JUnitTestCase.fail(msg.toString());
//     }
//     return firstToken;
//   }
// }
// class AngularCompilationUnitBuilderTest extends AngularTest {
//   static AngularElement getAngularElement(Element element, Type angularElementType) {
//     List<ToolkitObjectElement> toolkitObjects = null;
//     if (element is ClassElement) {
//       ClassElement classElement = element as ClassElement;
//       toolkitObjects = classElement.toolkitObjects;
//     }
//     if (element is LocalVariableElement) {
//       LocalVariableElement variableElement = element as LocalVariableElement;
//       toolkitObjects = variableElement.toolkitObjects;
//     }
//     if (toolkitObjects != null) {
//       for (ToolkitObjectElement toolkitObject in toolkitObjects) {
//         if (isInstanceOf(toolkitObject, angularElementType)) {
//           return toolkitObject as AngularElement;
//         }
//       }
//     }
//     return null;
//   }
//   static void _assertHasAttributeSelector(AngularSelectorElement selector, String name) {
//     EngineTestCase.assertInstanceOf((obj) => obj is HasAttributeSelectorElementImpl, HasAttributeSelectorElementImpl, selector);
//     JUnitTestCase.assertEquals(name, (selector as HasAttributeSelectorElementImpl).name);
//   }
//   static void _assertIsTagSelector(AngularSelectorElement selector, String name) {
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularTagSelectorElementImpl, AngularTagSelectorElementImpl, selector);
//     JUnitTestCase.assertEquals(name, (selector as AngularTagSelectorElementImpl).name);
//   }
//   static String _createAngularSource(List<String> lines) {
//     String source = "import 'angular.dart';\n";
//     source += EngineTestCase.createSource(lines);
//     return source;
//   }
//   void test_bad_notConstructorAnnotation() {
//     String mainContent = EngineTestCase.createSource([
//         "const MY_ANNOTATION = null;",
//         "@MY_ANNOTATION()",
//         "class MyFilter {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // prepare AngularFilterElement
//     ClassElement classElement = mainUnitElement.getType("MyFilter");
//     AngularFormatterElement filter = getAngularElement(classElement, AngularFormatterElement);
//     JUnitTestCase.assertNull(filter);
//   }
//   void test_Decorator() {
//     String mainContent = _createAngularSource([
//         "@Decorator(selector: '[my-dir]',",
//         "             map: const {",
//         "               'my-dir' : '=>myPropA',",
//         "               '.' : '&myPropB',",
//         "             })",
//         "class MyDirective {",
//         "  set myPropA(value) {}",
//         "  set myPropB(value) {}",
//         "  @NgTwoWay('my-prop-c')",
//         "  String myPropC;",
//         "}"]);
//     resolveMainSourceNoErrors(mainContent);
//     // prepare AngularDirectiveElement
//     ClassElement classElement = mainUnitElement.getType("MyDirective");
//     AngularDecoratorElement directive = getAngularElement(classElement, AngularDecoratorElement);
//     JUnitTestCase.assertNotNull(directive);
//     // verify
//     JUnitTestCase.assertEquals(null, directive.name);
//     JUnitTestCase.assertEquals(-1, directive.nameOffset);
//     _assertHasAttributeSelector(directive.selector, "my-dir");
//     // verify properties
//     List<AngularPropertyElement> properties = directive.properties;
//     EngineTestCase.assertLength(3, properties);
//     _assertProperty(properties[0], "my-dir", findMainOffset("my-dir' :"), AngularPropertyKind.ONE_WAY, "myPropA", findMainOffset("myPropA'"));
//     _assertProperty(properties[1], ".", findMainOffset(".' :"), AngularPropertyKind.CALLBACK, "myPropB", findMainOffset("myPropB'"));
//     _assertProperty(properties[2], "my-prop-c", findMainOffset("my-prop-c'"), AngularPropertyKind.TWO_WAY, "myPropC", -1);
//   }
//   void test_Decorator_bad_cannotParseSelector() {
//     String mainContent = _createAngularSource([
//         "@Decorator(selector: '~bad-selector',",
//         "             map: const {",
//         "               'my-dir' : '=>myPropA',",
//         "               '.' : '&myPropB',",
//         "             })",
//         "class MyDirective {",
//         "  set myPropA(value) {}",
//         "  set myPropB(value) {}",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.CANNOT_PARSE_SELECTOR]);
//   }
//   void test_Decorator_bad_missingSelector() {
//     String mainContent = _createAngularSource([
//         "@Decorator(/*selector: '[my-dir]',*/",
//         "             map: const {",
//         "               'my-dir' : '=>myPropA',",
//         "               '.' : '&myPropB',",
//         "             })",
//         "class MyDirective {",
//         "  set myPropA(value) {}",
//         "  set myPropB(value) {}",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.MISSING_SELECTOR]);
//   }
//   void test_Formatter() {
//     String mainContent = _createAngularSource([
//         "@Formatter(name: 'myFilter')",
//         "class MyFilter {",
//         "  call(p1, p2) {}",
//         "}"]);
//     resolveMainSourceNoErrors(mainContent);
//     // prepare AngularFilterElement
//     ClassElement classElement = mainUnitElement.getType("MyFilter");
//     AngularFormatterElement filter = getAngularElement(classElement, AngularFormatterElement);
//     JUnitTestCase.assertNotNull(filter);
//     // verify
//     JUnitTestCase.assertEquals("myFilter", filter.name);
//     JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "myFilter'"), filter.nameOffset);
//   }
//   void test_Formatter_missingName() {
//     String mainContent = _createAngularSource([
//         "@Formatter()",
//         "class MyFilter {",
//         "  call(p1, p2) {}",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.MISSING_NAME]);
//     // no filter
//     ClassElement classElement = mainUnitElement.getType("MyFilter");
//     AngularFormatterElement filter = getAngularElement(classElement, AngularFormatterElement);
//     JUnitTestCase.assertNull(filter);
//   }
//   void test_getElement_component_name() {
//     resolveMainSource(_createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {}"]));
//     SimpleStringLiteral node = _findMainNode("ctrl'", SimpleStringLiteral);
//     int offset = node.offset;
//     // find AngularComponentElement
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularComponentElement, AngularComponentElement, element);
//   }
//   void test_getElement_component_property_fromFieldAnnotation() {
//     resolveMainSource(_createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "  @NgOneWay('prop')",
//         "  var field;",
//         "}"]));
//     // prepare node
//     SimpleStringLiteral node = _findMainNode("prop'", SimpleStringLiteral);
//     int offset = node.offset;
//     // prepare Element
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     JUnitTestCase.assertNotNull(element);
//     // check AngularPropertyElement
//     AngularPropertyElement property = element as AngularPropertyElement;
//     JUnitTestCase.assertEquals("prop", property.name);
//   }
//   void test_getElement_component_property_fromMap() {
//     resolveMainSource(_createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {",
//         "               'prop' : '@field',",
//         "             })",
//         "class MyComponent {",
//         "  var field;",
//         "}"]));
//     // AngularPropertyElement
//     {
//       SimpleStringLiteral node = _findMainNode("prop'", SimpleStringLiteral);
//       int offset = node.offset;
//       // prepare Element
//       Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//       JUnitTestCase.assertNotNull(element);
//       // check AngularPropertyElement
//       AngularPropertyElement property = element as AngularPropertyElement;
//       JUnitTestCase.assertEquals("prop", property.name);
//     }
//     // FieldElement
//     {
//       SimpleStringLiteral node = _findMainNode("@field'", SimpleStringLiteral);
//       int offset = node.offset;
//       // prepare Element
//       Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//       JUnitTestCase.assertNotNull(element);
//       // check FieldElement
//       FieldElement field = element as FieldElement;
//       JUnitTestCase.assertEquals("field", field.name);
//     }
//   }
//   void test_getElement_component_selector() {
//     resolveMainSource(_createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {}"]));
//     SimpleStringLiteral node = _findMainNode("myComp'", SimpleStringLiteral);
//     int offset = node.offset;
//     // find AngularSelectorElement
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularSelectorElement, AngularSelectorElement, element);
//   }
//   void test_getElement_controller_name() {
//     resolveMainSource(_createAngularSource([
//         "@Controller(publishAs: 'ctrl', selector: '[myApp]')",
//         "class MyController {",
//         "}"]));
//     SimpleStringLiteral node = _findMainNode("ctrl'", SimpleStringLiteral);
//     int offset = node.offset;
//     // find AngularControllerElement
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularControllerElement, AngularControllerElement, element);
//   }
//   void test_getElement_directive_property() {
//     resolveMainSource(_createAngularSource([
//         "@Decorator(selector: '[my-dir]',",
//         "             map: const {",
//         "               'my-dir' : '=>field'",
//         "             })",
//         "class MyDirective {",
//         "  set field(value) {}",
//         "}"]));
//     // prepare node
//     SimpleStringLiteral node = _findMainNode("my-dir'", SimpleStringLiteral);
//     int offset = node.offset;
//     // prepare Element
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     JUnitTestCase.assertNotNull(element);
//     // check AngularPropertyElement
//     AngularPropertyElement property = element as AngularPropertyElement;
//     JUnitTestCase.assertEquals("my-dir", property.name);
//   }
//   void test_getElement_directive_selector() {
//     resolveMainSource(_createAngularSource([
//         "@Decorator(selector: '[my-dir]')",
//         "class MyDirective {}"]));
//     SimpleStringLiteral node = _findMainNode("my-dir]'", SimpleStringLiteral);
//     int offset = node.offset;
//     // find AngularSelectorElement
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularSelectorElement, AngularSelectorElement, element);
//   }
//   void test_getElement_filter_name() {
//     resolveMainSource(_createAngularSource([
//         "@Formatter(name: 'myFilter')",
//         "class MyFilter {",
//         "  call(p1, p2) {}",
//         "}"]));
//     SimpleStringLiteral node = _findMainNode("myFilter'", SimpleStringLiteral);
//     int offset = node.offset;
//     // find FilterElement
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularFormatterElement, AngularFormatterElement, element);
//   }
//   void test_getElement_noClassDeclaration() {
//     resolveMainSource("var foo = 'bar';");
//     SimpleStringLiteral node = _findMainNode("bar'", SimpleStringLiteral);
//     Element element = AngularCompilationUnitBuilder.getElement(node, 0);
//     JUnitTestCase.assertNull(element);
//   }
//   void test_getElement_noClassElement() {
//     resolveMainSource(EngineTestCase.createSource([
//         "class A {",
//         "  const A(p);",
//         "}",
//         "",
//         "@A('bar')",
//         "class B {}"]));
//     SimpleStringLiteral node = _findMainNode("bar'", SimpleStringLiteral);
//     // reset B element
//     node.getAncestor((node) => node is ClassDeclaration).name.staticElement = null;
//     // class is not resolved - no element
//     Element element = AngularCompilationUnitBuilder.getElement(node, 0);
//     JUnitTestCase.assertNull(element);
//   }
//   void test_getElement_noNode() {
//     Element element = AngularCompilationUnitBuilder.getElement(null, 0);
//     JUnitTestCase.assertNull(element);
//   }
//   void test_getElement_notFound() {
//     resolveMainSource(EngineTestCase.createSource(["class MyComponent {", "  var str = 'some string';", "}"]));
//     // prepare node
//     SimpleStringLiteral node = _findMainNode("some string'", SimpleStringLiteral);
//     int offset = node.offset;
//     // no Element
//     Element element = AngularCompilationUnitBuilder.getElement(node, offset);
//     JUnitTestCase.assertNull(element);
//   }
//   void test_getElement_SimpleStringLiteral_withToolkitElement() {
//     SimpleStringLiteral literal = AstFactory.string2("foo");
//     Element element = new AngularScopePropertyElementImpl("foo", 0, null);
//     literal.toolkitElement = element;
//     JUnitTestCase.assertSame(element, AngularCompilationUnitBuilder.getElement(literal, -1));
//   }
//   void test_NgComponent_bad_cannotParseSelector() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: '~myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.CANNOT_PARSE_SELECTOR]);
//   }
//   void test_NgComponent_bad_missingSelector() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', /*selector: 'myComp',*/",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.MISSING_SELECTOR]);
//   }
//   /**
//    *
//    * https://code.google.com/p/dart/issues/detail?id=16346
//    */
//   void test_NgComponent_bad_notHtmlTemplate() {
//     contextHelper.addSource("/my_template", "");
//     contextHelper.addSource("/my_styles.css", "");
//     addMainSource(_createAngularSource([
//         "@NgComponent(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "}"]));
//     contextHelper.runTasks();
//   }
//   void test_NgComponent_bad_properties_invalidBinding() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {'name' : '?field'})",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.INVALID_PROPERTY_KIND]);
//   }
//   void test_NgComponent_bad_properties_nameNotStringLiteral() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {null : 'field'})",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.INVALID_PROPERTY_NAME]);
//   }
//   void test_NgComponent_bad_properties_noSuchField() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {'name' : '=>field'})",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.INVALID_PROPERTY_FIELD]);
//   }
//   void test_NgComponent_bad_properties_notMapLiteral() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: null)",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.INVALID_PROPERTY_MAP]);
//   }
//   void test_NgComponent_bad_properties_specNotStringLiteral() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {'name' : null})",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.INVALID_PROPERTY_SPEC]);
//   }
//   void test_NgComponent_no_cssUrl() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html'/*, cssUrl: 'my_styles.css'*/)",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // no CSS
//     JUnitTestCase.assertEquals(null, component.styleUri);
//     JUnitTestCase.assertEquals(-1, component.styleUriOffset);
//   }
//   void test_NgComponent_no_publishAs() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(/*publishAs: 'ctrl',*/ selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // no name
//     JUnitTestCase.assertEquals(null, component.name);
//     JUnitTestCase.assertEquals(-1, component.nameOffset);
//   }
//   void test_NgComponent_no_templateUrl() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             /*templateUrl: 'my_template.html',*/ cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // no template
//     JUnitTestCase.assertEquals(null, component.templateUri);
//     JUnitTestCase.assertEquals(null, component.templateSource);
//     JUnitTestCase.assertEquals(-1, component.templateUriOffset);
//   }
//   /**
//    *
//    * https://code.google.com/p/dart/issues/detail?id=19023
//    */
//   void test_NgComponent_notAngular() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = EngineTestCase.createSource([
//         "class Component {",
//         "  const Component(a, b);",
//         "}",
//         "",
//         "@Component('foo', 42)",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSource(mainContent);
//     assertNoMainErrors();
//   }
//   void test_NgComponent_properties_fieldFromSuper() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     resolveMainSourceNoErrors(_createAngularSource([
//         "class MySuper {",
//         "  var myPropA;",
//         "}",
//         "",
//         "",
//         "",
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {",
//         "               'prop-a' : '@myPropA'",
//         "             })",
//         "class MyComponent extends MySuper {",
//         "}"]));
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // verify
//     List<AngularPropertyElement> properties = component.properties;
//     EngineTestCase.assertLength(1, properties);
//     _assertProperty(properties[0], "prop-a", findMainOffset("prop-a' :"), AngularPropertyKind.ATTR, "myPropA", findMainOffset("myPropA'"));
//   }
//   void test_NgComponent_properties_fromFields() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     resolveMainSourceNoErrors(_createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "  @NgAttr('prop-a')",
//         "  var myPropA;",
//         "  @NgCallback('prop-b')",
//         "  var myPropB;",
//         "  @NgOneWay('prop-c')",
//         "  var myPropC;",
//         "  @NgOneWayOneTime('prop-d')",
//         "  var myPropD;",
//         "  @NgTwoWay('prop-e')",
//         "  var myPropE;",
//         "}"]));
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // verify
//     List<AngularPropertyElement> properties = component.properties;
//     EngineTestCase.assertLength(5, properties);
//     _assertProperty(properties[0], "prop-a", findMainOffset("prop-a')"), AngularPropertyKind.ATTR, "myPropA", -1);
//     _assertProperty(properties[1], "prop-b", findMainOffset("prop-b')"), AngularPropertyKind.CALLBACK, "myPropB", -1);
//     _assertProperty(properties[2], "prop-c", findMainOffset("prop-c')"), AngularPropertyKind.ONE_WAY, "myPropC", -1);
//     _assertProperty(properties[3], "prop-d", findMainOffset("prop-d')"), AngularPropertyKind.ONE_WAY_ONE_TIME, "myPropD", -1);
//     _assertProperty(properties[4], "prop-e", findMainOffset("prop-e')"), AngularPropertyKind.TWO_WAY, "myPropE", -1);
//   }
//   void test_NgComponent_properties_fromMap() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     resolveMainSourceNoErrors(_createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "             map: const {",
//         "               'prop-a' : '@myPropA',",
//         "               'prop-b' : '&myPropB',",
//         "               'prop-c' : '=>myPropC',",
//         "               'prop-d' : '=>!myPropD',",
//         "               'prop-e' : '<=>myPropE'",
//         "             })",
//         "class MyComponent {",
//         "  var myPropA;",
//         "  var myPropB;",
//         "  var myPropC;",
//         "  var myPropD;",
//         "  var myPropE;",
//         "}"]));
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // verify
//     List<AngularPropertyElement> properties = component.properties;
//     EngineTestCase.assertLength(5, properties);
//     _assertProperty(properties[0], "prop-a", findMainOffset("prop-a' :"), AngularPropertyKind.ATTR, "myPropA", findMainOffset("myPropA'"));
//     _assertProperty(properties[1], "prop-b", findMainOffset("prop-b' :"), AngularPropertyKind.CALLBACK, "myPropB", findMainOffset("myPropB'"));
//     _assertProperty(properties[2], "prop-c", findMainOffset("prop-c' :"), AngularPropertyKind.ONE_WAY, "myPropC", findMainOffset("myPropC'"));
//     _assertProperty(properties[3], "prop-d", findMainOffset("prop-d' :"), AngularPropertyKind.ONE_WAY_ONE_TIME, "myPropD", findMainOffset("myPropD'"));
//     _assertProperty(properties[4], "prop-e", findMainOffset("prop-e' :"), AngularPropertyKind.TWO_WAY, "myPropE", findMainOffset("myPropE'"));
//   }
//   void test_NgComponent_properties_no() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "}"]);
//     resolveMainSourceNoErrors(mainContent);
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // verify
//     JUnitTestCase.assertEquals("ctrl", component.name);
//     JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "ctrl'"), component.nameOffset);
//     _assertIsTagSelector(component.selector, "myComp");
//     JUnitTestCase.assertEquals("my_template.html", component.templateUri);
//     JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "my_template.html'"), component.templateUriOffset);
//     JUnitTestCase.assertEquals("my_styles.css", component.styleUri);
//     JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "my_styles.css'"), component.styleUriOffset);
//     EngineTestCase.assertLength(0, component.properties);
//   }
//   void test_NgComponent_scopeProperties() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     String mainContent = _createAngularSource([
//         "@Component(publishAs: 'ctrl', selector: 'myComp',",
//         "             templateUrl: 'my_template.html', cssUrl: 'my_styles.css')",
//         "class MyComponent {",
//         "  MyComponent(Scope scope) {",
//         "    scope.context['boolProp'] = true;",
//         "    scope.context['intProp'] = 42;",
//         "    scope.context['stringProp'] = 'foo';",
//         "    // duplicate is ignored",
//         "    scope.context['boolProp'] = true;",
//         "    // LHS is not an IndexExpression",
//         "    var v1;",
//         "    v1 = 1;",
//         "    // LHS is not a Scope access",
//         "    var v2;",
//         "    v2['name'] = 2;",
//         "  }",
//         "}"]);
//     resolveMainSourceNoErrors(mainContent);
//     // prepare AngularComponentElement
//     ClassElement classElement = mainUnitElement.getType("MyComponent");
//     AngularComponentElement component = getAngularElement(classElement, AngularComponentElement);
//     JUnitTestCase.assertNotNull(component);
//     // verify
//     List<AngularScopePropertyElement> scopeProperties = component.scopeProperties;
//     EngineTestCase.assertLength(3, scopeProperties);
//     {
//       AngularScopePropertyElement property = scopeProperties[0];
//       JUnitTestCase.assertSame(property, findMainElement2("boolProp"));
//       JUnitTestCase.assertEquals("boolProp", property.name);
//       JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "boolProp'"), property.nameOffset);
//       JUnitTestCase.assertEquals("bool", property.type.name);
//     }
//     {
//       AngularScopePropertyElement property = scopeProperties[1];
//       JUnitTestCase.assertSame(property, findMainElement2("intProp"));
//       JUnitTestCase.assertEquals("intProp", property.name);
//       JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "intProp'"), property.nameOffset);
//       JUnitTestCase.assertEquals("int", property.type.name);
//     }
//     {
//       AngularScopePropertyElement property = scopeProperties[2];
//       JUnitTestCase.assertSame(property, findMainElement2("stringProp"));
//       JUnitTestCase.assertEquals("stringProp", property.name);
//       JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "stringProp'"), property.nameOffset);
//       JUnitTestCase.assertEquals("String", property.type.name);
//     }
//   }
//   void test_NgController() {
//     String mainContent = _createAngularSource([
//         "@Controller(publishAs: 'ctrl', selector: '[myApp]')",
//         "class MyController {",
//         "}"]);
//     resolveMainSourceNoErrors(mainContent);
//     // prepare AngularControllerElement
//     ClassElement classElement = mainUnitElement.getType("MyController");
//     AngularControllerElement controller = getAngularElement(classElement, AngularControllerElement);
//     JUnitTestCase.assertNotNull(controller);
//     // verify
//     JUnitTestCase.assertEquals("ctrl", controller.name);
//     JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "ctrl'"), controller.nameOffset);
//     _assertHasAttributeSelector(controller.selector, "myApp");
//   }
//   void test_NgController_cannotParseSelector() {
//     String mainContent = _createAngularSource([
//         "@Controller(publishAs: 'ctrl', selector: '~unknown')",
//         "class MyController {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.CANNOT_PARSE_SELECTOR]);
//   }
//   void test_NgController_missingPublishAs() {
//     String mainContent = _createAngularSource([
//         "@Controller(selector: '[myApp]')",
//         "class MyController {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.MISSING_PUBLISH_AS]);
//   }
//   void test_NgController_missingSelector() {
//     String mainContent = _createAngularSource([
//         "@Controller(publishAs: 'ctrl')",
//         "class MyController {",
//         "}"]);
//     resolveMainSource(mainContent);
//     // has error
//     assertMainErrors([AngularCode.MISSING_SELECTOR]);
//   }
//   void test_NgController_noAnnotationArguments() {
//     String mainContent = _createAngularSource(["@NgController", "class MyController {", "}"]);
//     resolveMainSource(mainContent);
//   }
//   void test_parseSelector_hasAttribute() {
//     AngularSelectorElement selector = AngularCompilationUnitBuilder.parseSelector(42, "[name]");
//     _assertHasAttributeSelector(selector, "name");
//     JUnitTestCase.assertEquals(42 + 1, selector.nameOffset);
//   }
//   void test_parseSelector_hasClass() {
//     AngularSelectorElement selector = AngularCompilationUnitBuilder.parseSelector(42, ".my-class");
//     AngularHasClassSelectorElementImpl classSelector = selector as AngularHasClassSelectorElementImpl;
//     JUnitTestCase.assertEquals("my-class", classSelector.name);
//     JUnitTestCase.assertEquals(".my-class", classSelector.toString());
//     JUnitTestCase.assertEquals(42 + 1, selector.nameOffset);
//     // test apply()
//     {
//       XmlTagNode node = HtmlFactory.tagNode("div", [HtmlFactory.attribute("class", "one two")]);
//       JUnitTestCase.assertFalse(classSelector.apply(node));
//     }
//     {
//       XmlTagNode node = HtmlFactory.tagNode("div", [HtmlFactory.attribute("class", "one my-class two")]);
//       JUnitTestCase.assertTrue(classSelector.apply(node));
//     }
//   }
//   void test_parseSelector_isTag() {
//     AngularSelectorElement selector = AngularCompilationUnitBuilder.parseSelector(42, "name");
//     _assertIsTagSelector(selector, "name");
//     JUnitTestCase.assertEquals(42, selector.nameOffset);
//   }
//   void test_parseSelector_isTag_hasAttribute() {
//     AngularSelectorElement selector = AngularCompilationUnitBuilder.parseSelector(42, "tag[attr]");
//     EngineTestCase.assertInstanceOf((obj) => obj is IsTagHasAttributeSelectorElementImpl, IsTagHasAttributeSelectorElementImpl, selector);
//     JUnitTestCase.assertEquals("tag[attr]", selector.name);
//     JUnitTestCase.assertEquals(-1, selector.nameOffset);
//     JUnitTestCase.assertEquals("tag", (selector as IsTagHasAttributeSelectorElementImpl).tagName);
//     JUnitTestCase.assertEquals("attr", (selector as IsTagHasAttributeSelectorElementImpl).attributeName);
//   }
//   void test_parseSelector_unknown() {
//     AngularSelectorElement selector = AngularCompilationUnitBuilder.parseSelector(0, "~unknown");
//     JUnitTestCase.assertNull(selector);
//   }
//   void test_view() {
//     contextHelper.addSource("/wrong.html", "");
//     contextHelper.addSource("/my_templateA.html", "");
//     contextHelper.addSource("/my_templateB.html", "");
//     String mainContent = _createAngularSource([
//         "class MyRouteInitializer {",
//         "  init(ViewFactory view, foo) {",
//         "    foo.view('wrong.html');   // has target",
//         "    foo();                    // less than one argument",
//         "    foo('wrong.html', 'bar'); // more than one argument",
//         "    foo('wrong' + '.html');   // not literal",
//         "    foo('wrong.html');        // not ViewFactory",
//         "    view('my_templateA.html');",
//         "    view('my_templateB.html');",
//         "  }",
//         "}"]);
//     resolveMainSourceNoErrors(mainContent);
//     // prepare AngularViewElement(s)
//     List<AngularViewElement> views = mainUnitElement.angularViews;
//     EngineTestCase.assertLength(2, views);
//     {
//       AngularViewElement view = views[0];
//       JUnitTestCase.assertEquals("my_templateA.html", view.templateUri);
//       JUnitTestCase.assertEquals(null, view.name);
//       JUnitTestCase.assertEquals(-1, view.nameOffset);
//       JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "my_templateA.html'"), view.templateUriOffset);
//     }
//     {
//       AngularViewElement view = views[1];
//       JUnitTestCase.assertEquals("my_templateB.html", view.templateUri);
//       JUnitTestCase.assertEquals(null, view.name);
//       JUnitTestCase.assertEquals(-1, view.nameOffset);
//       JUnitTestCase.assertEquals(AngularTest.findOffset(mainContent, "my_templateB.html'"), view.templateUriOffset);
//     }
//   }
//   void _assertProperty(AngularPropertyElement property, String expectedName, int expectedNameOffset, AngularPropertyKind expectedKind, String expectedFieldName, int expectedFieldOffset) {
//     JUnitTestCase.assertEquals(expectedName, property.name);
//     JUnitTestCase.assertEquals(expectedNameOffset, property.nameOffset);
//     JUnitTestCase.assertSame(expectedKind, property.propertyKind);
//     JUnitTestCase.assertEquals(expectedFieldName, property.field.name);
//     JUnitTestCase.assertEquals(expectedFieldOffset, property.fieldNameOffset);
//   }
//   /**
//    * Find [AstNode] of the given type in [mainUnit].
//    */
//   AstNode _findMainNode(String search, Type clazz) => EngineTestCase.findNode(mainUnit, mainContent, search, predicate);
//   static dartSuite() {
//     _ut.group('AngularCompilationUnitBuilderTest', () {
//       _ut.test('test_Decorator', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_Decorator);
//       });
//       _ut.test('test_Decorator_bad_cannotParseSelector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_Decorator_bad_cannotParseSelector);
//       });
//       _ut.test('test_Decorator_bad_missingSelector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_Decorator_bad_missingSelector);
//       });
//       _ut.test('test_Formatter', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_Formatter);
//       });
//       _ut.test('test_Formatter_missingName', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_Formatter_missingName);
//       });
//       _ut.test('test_NgComponent_bad_cannotParseSelector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_cannotParseSelector);
//       });
//       _ut.test('test_NgComponent_bad_missingSelector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_missingSelector);
//       });
//       _ut.test('test_NgComponent_bad_notHtmlTemplate', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_notHtmlTemplate);
//       });
//       _ut.test('test_NgComponent_bad_properties_invalidBinding', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_properties_invalidBinding);
//       });
//       _ut.test('test_NgComponent_bad_properties_nameNotStringLiteral', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_properties_nameNotStringLiteral);
//       });
//       _ut.test('test_NgComponent_bad_properties_noSuchField', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_properties_noSuchField);
//       });
//       _ut.test('test_NgComponent_bad_properties_notMapLiteral', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_properties_notMapLiteral);
//       });
//       _ut.test('test_NgComponent_bad_properties_specNotStringLiteral', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_bad_properties_specNotStringLiteral);
//       });
//       _ut.test('test_NgComponent_no_cssUrl', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_no_cssUrl);
//       });
//       _ut.test('test_NgComponent_no_publishAs', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_no_publishAs);
//       });
//       _ut.test('test_NgComponent_no_templateUrl', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_no_templateUrl);
//       });
//       _ut.test('test_NgComponent_notAngular', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_notAngular);
//       });
//       _ut.test('test_NgComponent_properties_fieldFromSuper', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_properties_fieldFromSuper);
//       });
//       _ut.test('test_NgComponent_properties_fromFields', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_properties_fromFields);
//       });
//       _ut.test('test_NgComponent_properties_fromMap', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_properties_fromMap);
//       });
//       _ut.test('test_NgComponent_properties_no', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_properties_no);
//       });
//       _ut.test('test_NgComponent_scopeProperties', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgComponent_scopeProperties);
//       });
//       _ut.test('test_NgController', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgController);
//       });
//       _ut.test('test_NgController_cannotParseSelector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgController_cannotParseSelector);
//       });
//       _ut.test('test_NgController_missingPublishAs', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgController_missingPublishAs);
//       });
//       _ut.test('test_NgController_missingSelector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgController_missingSelector);
//       });
//       _ut.test('test_NgController_noAnnotationArguments', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_NgController_noAnnotationArguments);
//       });
//       _ut.test('test_bad_notConstructorAnnotation', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_bad_notConstructorAnnotation);
//       });
//       _ut.test('test_getElement_SimpleStringLiteral_withToolkitElement', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_SimpleStringLiteral_withToolkitElement);
//       });
//       _ut.test('test_getElement_component_name', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_component_name);
//       });
//       _ut.test('test_getElement_component_property_fromFieldAnnotation', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_component_property_fromFieldAnnotation);
//       });
//       _ut.test('test_getElement_component_property_fromMap', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_component_property_fromMap);
//       });
//       _ut.test('test_getElement_component_selector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_component_selector);
//       });
//       _ut.test('test_getElement_controller_name', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_controller_name);
//       });
//       _ut.test('test_getElement_directive_property', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_directive_property);
//       });
//       _ut.test('test_getElement_directive_selector', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_directive_selector);
//       });
//       _ut.test('test_getElement_filter_name', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_filter_name);
//       });
//       _ut.test('test_getElement_noClassDeclaration', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_noClassDeclaration);
//       });
//       _ut.test('test_getElement_noClassElement', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_noClassElement);
//       });
//       _ut.test('test_getElement_noNode', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_noNode);
//       });
//       _ut.test('test_getElement_notFound', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_getElement_notFound);
//       });
//       _ut.test('test_parseSelector_hasAttribute', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_parseSelector_hasAttribute);
//       });
//       _ut.test('test_parseSelector_hasClass', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_parseSelector_hasClass);
//       });
//       _ut.test('test_parseSelector_isTag', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_parseSelector_isTag);
//       });
//       _ut.test('test_parseSelector_isTag_hasAttribute', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_parseSelector_isTag_hasAttribute);
//       });
//       _ut.test('test_parseSelector_unknown', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_parseSelector_unknown);
//       });
//       _ut.test('test_view', () {
//         final __test = new AngularCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_view);
//       });
//     });
//   }
// }
// class AngularDartIndexContributorTest extends AngularTest {
//   IndexStore _store = mock(IndexStore);
//   AngularDartIndexContributor _index = new AngularDartIndexContributor(_store);
//   void test_component_propertyField() {
//     contextHelper.addSource("/my_template.html", "");
//     contextHelper.addSource("/my_styles.css", "");
//     resolveMainSourceNoErrors(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent', // selector",
//         "    map: const {",
//         "        'propAttr' : '@field', // attr",
//         "        'propOneWay' : '=>field', // one-way",
//         "        'propTwoWay' : '<=>field', // two-way",
//         "    })",
//         "class MyComponent {",
//         "  @NgOneWay('annProp')",
//         "  var field;",
//         "}",
//         "",
//         "main() {",
//         "  var module = new Module();",
//         "  module.type(MyComponent);",
//         "  ngBootstrap(module: module);",
//         "}"]));
//     FieldElement field = findMainElement2("field");
//     PropertyAccessorElement getter = field.getter;
//     PropertyAccessorElement setter = field.setter;
//     // index
//     mainUnit.accept(_index);
//     List<RecordedRelation> relations = captureRecordedRelations();
//     // @field
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("propAttr"), findMainOffset("field', // attr"), "field");
//       assertNoRecordedRelation(relations, getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//       assertRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//     // =>field
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("propOneWay"), findMainOffset("field', // one-way"), "field");
//       assertNoRecordedRelation(relations, getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//       assertRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//     // <=>field
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("propTwoWay"), findMainOffset("field', // two-way"), "field");
//       assertRecordedRelation(relations, getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//       assertRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//     // @NgOneWay('annProp') is ignore - no explicit field reference
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("annProp"), -1, "field");
//       assertNoRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//   }
//   void test_directive_propertyField() {
//     resolveMainSourceNoErrors(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Decorator(",
//         "    selector: '[my-directive]',",
//         "    map: const {",
//         "        'propAttr' : '@field', // attr",
//         "        'propOneWay' : '=>field', // one-way",
//         "        'propTwoWay' : '<=>field', // two-way",
//         "    })",
//         "class MyDirective {",
//         "  var field;",
//         "}",
//         "",
//         "main() {",
//         "  var module = new Module();",
//         "  module.type(MyDirective);",
//         "  ngBootstrap(module: module);",
//         "}"]));
//     FieldElement field = findMainElement2("field");
//     PropertyAccessorElement getter = field.getter;
//     PropertyAccessorElement setter = field.setter;
//     // index
//     mainUnit.accept(_index);
//     List<RecordedRelation> relations = captureRecordedRelations();
//     // @field
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("propAttr"), findMainOffset("field', // attr"), "field");
//       assertNoRecordedRelation(relations, getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//       assertRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//     // =>field
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("propOneWay"), findMainOffset("field', // one-way"), "field");
//       assertNoRecordedRelation(relations, getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//       assertRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//     // <=>field
//     {
//       ExpectedLocation location = new ExpectedLocation(findMainElement2("propTwoWay"), findMainOffset("field', // two-way"), "field");
//       assertRecordedRelation(relations, getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//       assertRecordedRelation(relations, setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//     }
//   }
//   List<RecordedRelation> captureRecordedRelations() => captureRelations(_store);
//   static dartSuite() {
//     _ut.group('AngularDartIndexContributorTest', () {
//       _ut.test('test_component_propertyField', () {
//         final __test = new AngularDartIndexContributorTest();
//         runJUnitTest(__test, __test.test_component_propertyField);
//       });
//       _ut.test('test_directive_propertyField', () {
//         final __test = new AngularDartIndexContributorTest();
//         runJUnitTest(__test, __test.test_directive_propertyField);
//       });
//     });
//   }
// }
// class AngularHtmlIndexContributorTest extends AngularTest {
//   IndexStore _store = mock(IndexStore);
//   AngularHtmlIndexContributor _index = new AngularHtmlIndexContributor(_store);
//   void test_expression_inAttribute() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController(["  <button title='{{ctrl.field}}'>Remove</button>", ""]));
//     // prepare elements
//     Element fieldGetter = (findMainElement2("field") as FieldElement).getter;
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, fieldGetter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, new ExpectedLocation(indexHtmlUnit, findOffset2("field}}"), "field"));
//   }
//   void test_expression_inContent() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController(["      {{ctrl.field}}", ""]));
//     // prepare elements
//     Element fieldGetter = (findMainElement2("field") as FieldElement).getter;
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, fieldGetter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, new ExpectedLocation(indexHtmlUnit, findOffset2("field}}"), "field"));
//   }
//   void test_expression_ngRepeat() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController([
//         "  <li ng-repeat='name in ctrl.names'>",
//         "    {{name}}",
//         "  </li>",
//         ""]));
//     // prepare elements
//     Element namesElement = (findMainElement2("names") as FieldElement).getter;
//     Element nameElement = findIndexElement("name");
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, namesElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, new ExpectedLocation(indexHtmlUnit, findOffset2("names'>"), "names"));
//     assertRecordedRelation(relations, nameElement, IndexConstants.IS_READ_BY, new ExpectedLocation(indexHtmlUnit, findOffset2("name}}"), "name"));
//   }
//   void test_Formatter_use() {
//     resolveMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Formatter(name: 'myFormatter')",
//         "class MyFormatter {",
//         "}",
//         "",
//         "class Item {",
//         "  String name;",
//         "  bool done;",
//         "}",
//         "",
//         "@Controller(",
//         "    selector: '[my-controller]',",
//         "    publishAs: 'ctrl')",
//         "class MyController {",
//         "  List<Item> items;",
//         "}"]));
//     resolveIndex2(AngularTest.createHtmlWithMyController([
//         "  <li ng-repeat=\"item in ctrl.items | myFormatter:true\">",
//         "  </li>",
//         ""]));
//     // prepare elements
//     AngularFormatterElement filterElement = findMainElement2("myFormatter");
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, filterElement, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("myFormatter:true"), "myFormatter"));
//   }
//   void test_NgComponent_templateFile() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "  String field;",
//         "}"]));
//     contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{ctrl.field}}", "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     resolveMain();
//     resolveIndex();
//     // prepare elements
//     AngularComponentElement componentElement = findMainElement2("ctrl");
//     FieldElement field = findMainElement2("field");
//     PropertyAccessorElement fieldGetter = field.getter;
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, componentElement, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("ctrl.field"), "ctrl"));
//     assertRecordedRelation(relations, fieldGetter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, new ExpectedLocation(indexHtmlUnit, findOffset2("field}}"), "field"));
//   }
//   void test_NgComponent_use() {
//     resolveMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent', // selector",
//         "    map: const {'attrA' : '=>setA', 'attrB' : '@setB'})",
//         "class MyComponent {",
//         "  set setA(value) {}",
//         "  set setB(value) {}",
//         "}"]));
//     resolveIndex2(AngularTest.createHtmlWithMyController([
//         "<myComponent attrA='null' attrB='str'/>",
//         "<myComponent>abcd</myComponent> with closing tag"]));
//     // prepare elements
//     AngularSelectorElement selectorElement = findMainElement2("myComponent");
//     AngularPropertyElement attrA = findMainElement2("attrA");
//     AngularPropertyElement attrB = findMainElement2("attrB");
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, selectorElement, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("myComponent attrA='null"), "myComponent"));
//     assertRecordedRelation(relations, attrA, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("attrA='null"), "attrA"));
//     assertRecordedRelation(relations, attrB, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("attrB='str"), "attrB"));
//     // with closing tag
//     assertRecordedRelation(relations, selectorElement, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("myComponent>abcd"), "myComponent"));
//     assertRecordedRelation(relations, selectorElement, IndexConstants.ANGULAR_CLOSING_TAG_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("myComponent> with closing tag"), "myComponent"));
//   }
//   void test_NgComponent_use_tagHasAttribute() {
//     resolveMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent[attr]', // selector",
//         "    map: const {'attr' : '=>setAttr'})",
//         "class MyComponent {",
//         "  set setAttr(value) {}",
//         "}"]));
//     resolveIndex2(AngularTest.createHtmlWithMyController(["<myComponent attr='null'/>"]));
//     // prepare elements
//     AngularSelectorElement selectorElement = findMainElement2("myComponent[attr]");
//     AngularPropertyElement attr = findMainElement2("attr");
//     JUnitTestCase.assertNotNull(selectorElement);
//     JUnitTestCase.assertNotNull(attr);
//     // index
//     indexUnit.accept(_index);
//     // verify
//     List<RecordedRelation> relations = captureRecordedRelations();
//     assertRecordedRelation(relations, selectorElement, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("myComponent attr='null"), "myComponent"));
//     assertRecordedRelation(relations, attr, IndexConstants.ANGULAR_REFERENCE, new ExpectedLocation(indexHtmlUnit, findOffset2("attr='null"), "attr"));
//   }
//   List<RecordedRelation> captureRecordedRelations() => captureRelations(_store);
//   static dartSuite() {
//     _ut.group('AngularHtmlIndexContributorTest', () {
//       _ut.test('test_Formatter_use', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_Formatter_use);
//       });
//       _ut.test('test_NgComponent_templateFile', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_NgComponent_templateFile);
//       });
//       _ut.test('test_NgComponent_use', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_NgComponent_use);
//       });
//       _ut.test('test_NgComponent_use_tagHasAttribute', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_NgComponent_use_tagHasAttribute);
//       });
//       _ut.test('test_expression_inAttribute', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_expression_inAttribute);
//       });
//       _ut.test('test_expression_inContent', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_expression_inContent);
//       });
//       _ut.test('test_expression_ngRepeat', () {
//         final __test = new AngularHtmlIndexContributorTest();
//         runJUnitTest(__test, __test.test_expression_ngRepeat);
//       });
//     });
//   }
// }
// class AngularHtmlUnitResolverTest extends AngularTest {
//   void test_analysisContext_changeDart_invalidateApplication() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "}"]));
//     contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{ctrl.noMethod()}}", "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     // there are some errors in my_template.html
//     {
//       List<AnalysisError> errors = context.getErrors(indexSource).errors;
//       JUnitTestCase.assertTrue(errors.length != 0);
//     }
//     // change main.dart, there are no MyComponent anymore
//     context.setContents(mainSource, "");
//     // ...errors in my_template.html should be removed
//     {
//       List<AnalysisError> errors = context.getErrors(indexSource).errors;
//       JUnitTestCase.assertTrue(errors.length == 0);
//     }
//   }
//   void test_analysisContext_changeEntryPoint_clearAngularErrors_inDart() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'no-such-template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "}"]));
//     Source entrySource = contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     // there are some errors in MyComponent
//     {
//       List<AnalysisError> errors = context.getErrors(mainSource).errors;
//       JUnitTestCase.assertTrue(errors.length != 0);
//     }
//     // make entry-point.html non-Angular
//     context.setContents(entrySource, "<html/>");
//     // ...errors in MyComponent should be removed
//     {
//       List<AnalysisError> errors = context.getErrors(mainSource).errors;
//       JUnitTestCase.assertTrue(errors.length == 0);
//     }
//   }
//   void test_analysisContext_changeEntryPoint_clearAngularErrors_inTemplate() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "}"]));
//     Source entrySource = contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{ctrl.noMethod()}}", "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     // there are some errors in my_template.html
//     {
//       List<AnalysisError> errors = context.getErrors(indexSource).errors;
//       JUnitTestCase.assertTrue(errors.length != 0);
//     }
//     // make entry-point.html non-Angular
//     context.setContents(entrySource, "<html/>");
//     // ...errors in my_template.html should be removed
//     {
//       List<AnalysisError> errors = context.getErrors(indexSource).errors;
//       JUnitTestCase.assertTrue(errors.length == 0);
//     }
//   }
//   void test_analysisContext_removeEntryPoint_clearAngularErrors_inDart() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'no-such-template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "}"]));
//     Source entrySource = contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     // there are some errors in MyComponent
//     {
//       List<AnalysisError> errors = context.getErrors(mainSource).errors;
//       JUnitTestCase.assertTrue(errors.length != 0);
//     }
//     // remove entry-point.html
//     {
//       ChangeSet changeSet = new ChangeSet();
//       changeSet.removedSource(entrySource);
//       context.applyChanges(changeSet);
//     }
//     // ...errors in MyComponent should be removed
//     {
//       List<AnalysisError> errors = context.getErrors(mainSource).errors;
//       JUnitTestCase.assertTrue(errors.length == 0);
//     }
//   }
//   void test_contextProperties() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithAngular([
//         "<div>",
//         "  {{\$id}}",
//         "  {{\$parent}}",
//         "  {{\$root}}",
//         "</div>"]));
//     assertResolvedIdentifier("\$id");
//     assertResolvedIdentifier("\$parent");
//     assertResolvedIdentifier("\$root");
//   }
//   void test_getAngularElement_isAngular() {
//     // prepare local variable "name" in compilation unit
//     CompilationUnitElementImpl unit = ElementFactory.compilationUnit("test.dart");
//     FunctionElementImpl function = ElementFactory.functionElement("main");
//     unit.functions = <FunctionElement> [function];
//     LocalVariableElementImpl local = ElementFactory.localVariableElement2("name");
//     function.localVariables = <LocalVariableElement> [local];
//     // set AngularElement
//     AngularElement angularElement = new AngularControllerElementImpl("ctrl", 0);
//     local.toolkitObjects = <AngularElement> [angularElement];
//     JUnitTestCase.assertSame(angularElement, AngularHtmlUnitResolver.getAngularElement(local));
//   }
//   void test_getAngularElement_notAngular() {
//     Element element = ElementFactory.localVariableElement2("name");
//     JUnitTestCase.assertNull(AngularHtmlUnitResolver.getAngularElement(element));
//   }
//   void test_getAngularElement_notLocal() {
//     Element element = ElementFactory.classElement2("Test", []);
//     JUnitTestCase.assertNull(AngularHtmlUnitResolver.getAngularElement(element));
//   }
//   /**
//    * Test that we resolve "ng-click" expression.
//    */
//   void test_ngClick() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<button ng-click='ctrl.doSomething(\$event)'/>"]));
//     assertResolvedIdentifier("doSomething");
//   }
//   void test_NgComponent_resolveTemplateFile() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "  String field;",
//         "}"]));
//     contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{ctrl.field}}", "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     resolveIndex();
//     assertNoErrors();
//     assertResolvedIdentifier2("ctrl.", "MyComponent");
//     assertResolvedIdentifier2("field}}", "String");
//   }
//   void test_NgComponent_updateDartFile() {
//     Source componentSource = contextHelper.addSource("/my_component.dart", EngineTestCase.createSource([
//         "library my.component;",
//         "import 'angular.dart';",
//         "@Component(selector: 'myComponent')",
//         "class MyComponent {",
//         "}"]));
//     contextHelper.addSource("/my_module.dart", EngineTestCase.createSource(["library my.module;", "import 'my_component.dart';"]));
//     addMainSource(EngineTestCase.createSource(["library main;", "import 'my_module.dart';"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<myComponent/>"]));
//     // "myComponent" tag was resolved
//     {
//       XmlTagNode tagNode = HtmlUnitUtils.getTagNode(indexUnit, findOffset2("myComponent"));
//       AngularSelectorElement tagElement = tagNode.element as AngularSelectorElement;
//       JUnitTestCase.assertNotNull(tagElement);
//       JUnitTestCase.assertEquals("myComponent", tagElement.name);
//     }
//     // replace "myComponent" with "myComponent2" in my_component.dart and index.html
//     {
//       context.setContents(componentSource, _getSourceContent(componentSource).replaceAll("myComponent", "myComponent2"));
//       indexContent = _getSourceContent(indexSource).replaceAll("myComponent", "myComponent2");
//       context.setContents(indexSource, indexContent);
//     }
//     contextHelper.runTasks();
//     resolveIndex();
//     // "myComponent2" tag should be resolved
//     {
//       XmlTagNode tagNode = HtmlUnitUtils.getTagNode(indexUnit, findOffset2("myComponent2"));
//       AngularSelectorElement tagElement = tagNode.element as AngularSelectorElement;
//       JUnitTestCase.assertNotNull(tagElement);
//       JUnitTestCase.assertEquals("myComponent2", tagElement.name);
//     }
//   }
//   void test_NgComponent_use_resolveAttributes() {
//     contextHelper.addSource("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{ctrl.field}}", "    </div>"]));
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent', // selector",
//         "    map: const {'attrA' : '=>setA', 'attrB' : '@setB'})",
//         "class MyComponent {",
//         "  set setA(value) {}",
//         "  set setB(value) {}",
//         "}"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<input type='text' ng-model='someModel'/>",
//         "<myComponent attrA='someModel' attrB='bbb'/>"]));
//     // "attrA" attribute expression was resolved
//     JUnitTestCase.assertNotNull(findIdentifier("someModel"));
//     // "myComponent" tag was resolved
//     XmlTagNode tagNode = HtmlUnitUtils.getTagNode(indexUnit, findOffset2("myComponent"));
//     AngularSelectorElement tagElement = tagNode.element as AngularSelectorElement;
//     JUnitTestCase.assertNotNull(tagElement);
//     JUnitTestCase.assertEquals("myComponent", tagElement.name);
//     JUnitTestCase.assertEquals(findMainOffset("myComponent', // selector"), tagElement.nameOffset);
//     // "attrA" attribute was resolved
//     {
//       XmlAttributeNode node = HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("attrA='"));
//       AngularPropertyElement element = node.element as AngularPropertyElement;
//       JUnitTestCase.assertNotNull(element);
//       JUnitTestCase.assertEquals("attrA", element.name);
//       JUnitTestCase.assertEquals("setA", element.field.name);
//     }
//     // "attrB" attribute was resolved, even if it @binding
//     {
//       XmlAttributeNode node = HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("attrB='"));
//       AngularPropertyElement element = node.element as AngularPropertyElement;
//       JUnitTestCase.assertNotNull(element);
//       JUnitTestCase.assertEquals("attrB", element.name);
//       JUnitTestCase.assertEquals("setB", element.field.name);
//     }
//   }
//   void test_NgDirective_noAttribute() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@NgDirective(selector: '[my-directive]', map: const {'foo': '=>input'})",
//         "class MyDirective {",
//         "  set input(value) {}",
//         "}"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<div my-directive>", "</div>"]));
//   }
//   void test_NgDirective_noExpression() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@NgDirective(selector: '[my-directive]', map: const {'.': '=>input'})",
//         "class MyDirective {",
//         "  set input(value) {}",
//         "}"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<div my-directive>", "</div>"]));
//   }
//   void test_NgDirective_resolvedExpression() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Decorator(selector: '[my-directive]')",
//         "class MyDirective {",
//         "  @NgOneWay('my-property')",
//         "  String condition;",
//         "}"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<input type='text' ng-model='name'>",
//         "<div my-directive my-property='name != null'>",
//         "</div>"]));
//     resolveMainNoErrors();
//     // "my-directive" attribute was resolved
//     {
//       AngularSelectorElement selector = findMainElement(ElementKind.ANGULAR_SELECTOR, "my-directive");
//       XmlAttributeNode attrNodeSelector = HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("my-directive"));
//       JUnitTestCase.assertNotNull(attrNodeSelector);
//       JUnitTestCase.assertSame(selector, attrNodeSelector.element);
//     }
//     // "my-property" attribute was resolved
//     {
//       XmlAttributeNode attrNodeProperty = HtmlUnitUtils.getAttributeNode(indexUnit, findOffset2("my-property='"));
//       AngularPropertyElement propertyElement = attrNodeProperty.element as AngularPropertyElement;
//       JUnitTestCase.assertNotNull(propertyElement);
//       JUnitTestCase.assertSame(AngularPropertyKind.ONE_WAY, propertyElement.propertyKind);
//       JUnitTestCase.assertEquals("condition", propertyElement.field.name);
//     }
//     // "name" expression was resolved
//     JUnitTestCase.assertNotNull(findIdentifier("name != null"));
//   }
//   void test_NgDirective_resolvedExpression_attrString() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@NgDirective(selector: '[my-directive])",
//         "class MyDirective {",
//         "  @NgAttr('my-property')",
//         "  String property;",
//         "}"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<input type='text' ng-model='name'>",
//         "<div my-directive my-property='name != null'>",
//         "</div>"]));
//     resolveMain();
//     // @NgAttr means "string attribute", which we don't parse
//     JUnitTestCase.assertNull(findIdentifierMaybe("name != null"));
//   }
//   void test_NgDirective_resolvedExpression_dotAsName() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Decorator(",
//         "    selector: '[my-directive]',",
//         "    map: const {'.' : '=>condition'})",
//         "class MyDirective {",
//         "  set condition(value) {}",
//         "}"]));
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<input type='text' ng-model='name'>",
//         "<div my-directive='name != null'>",
//         "</div>"]));
//     // "name" attribute was resolved
//     JUnitTestCase.assertNotNull(findIdentifier("name != null"));
//   }
//   /**
//    * Test that we resolve "ng-if" expression.
//    */
//   void test_ngIf() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<div ng-if='ctrl.field != null'/>"]));
//     assertResolvedIdentifier("field");
//   }
//   void test_ngModel_modelAfterUsage() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<h3>Hello {{name}}!</h3>",
//         "<input type='text' ng-model='name'>"]));
//     assertResolvedIdentifier2("name}}!", "String");
//     assertResolvedIdentifier2("name'>", "String");
//   }
//   void test_ngModel_modelBeforeUsage() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<input type='text' ng-model='name'>",
//         "<h3>Hello {{name}}!</h3>"]));
//     assertResolvedIdentifier2("name}}!", "String");
//     Element element = assertResolvedIdentifier2("name'>", "String");
//     JUnitTestCase.assertEquals("name", element.name);
//     JUnitTestCase.assertEquals(findOffset2("name'>"), element.nameOffset);
//   }
//   void test_ngModel_notIdentifier() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<input type='text' ng-model='ctrl.field'>"]));
//     assertResolvedIdentifier2("field'>", "String");
//   }
//   /**
//    * Test that we resolve "ng-mouseout" expression.
//    */
//   void test_ngMouseOut() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<button ng-mouseout='ctrl.doSomething(\$event)'/>"]));
//     assertResolvedIdentifier("doSomething");
//   }
//   void test_ngRepeat_additionalVariables() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat='name in ctrl.names'>",
//         "  {{\$index}} {{\$first}} {{\$middle}} {{\$last}} {{\$even}} {{\$odd}}",
//         "</li>"]));
//     assertResolvedIdentifier2("\$index", "int");
//     assertResolvedIdentifier2("\$first", "bool");
//     assertResolvedIdentifier2("\$middle", "bool");
//     assertResolvedIdentifier2("\$last", "bool");
//     assertResolvedIdentifier2("\$even", "bool");
//     assertResolvedIdentifier2("\$odd", "bool");
//   }
//   void test_ngRepeat_bad_expectedIdentifier() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController(["<li ng-repeat='name + 42 in ctrl.names'>", "</li>"]));
//     assertErrors(indexSource, [AngularCode.INVALID_REPEAT_ITEM_SYNTAX]);
//   }
//   void test_ngRepeat_bad_expectedIn() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController(["<li ng-repeat='name : ctrl.names'>", "</li>"]));
//     assertErrors(indexSource, [AngularCode.INVALID_REPEAT_SYNTAX]);
//   }
//   void test_ngRepeat_filters_filter_literal() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat='item in ctrl.items | filter:42:null'/>",
//         "</li>"]));
//     // filter "filter" is resolved
//     Element filterElement = assertResolvedIdentifier("filter");
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularFormatterElement, AngularFormatterElement, filterElement);
//   }
//   void test_ngRepeat_filters_filter_propertyMap() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat='item in ctrl.items | filter:{name:null, done:false}'/>",
//         "</li>"]));
//     assertResolvedIdentifier2("name:", "String");
//     assertResolvedIdentifier2("done:", "bool");
//   }
//   void test_ngRepeat_filters_missingColon() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:'' true\"/>",
//         "</li>"]));
//     assertErrors(indexSource, [AngularCode.MISSING_FORMATTER_COLON]);
//   }
//   void test_ngRepeat_filters_noArgs() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy\"/>",
//         "</li>"]));
//     // filter "orderBy" is resolved
//     Element filterElement = assertResolvedIdentifier("orderBy");
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularFormatterElement, AngularFormatterElement, filterElement);
//   }
//   void test_ngRepeat_filters_orderBy_emptyString() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:'':true\"/>",
//         "</li>"]));
//     // filter "orderBy" is resolved
//     Element filterElement = assertResolvedIdentifier("orderBy");
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularFormatterElement, AngularFormatterElement, filterElement);
//   }
//   void test_ngRepeat_filters_orderBy_propertyList() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:['name', 'done']\"/>",
//         "</li>"]));
//     assertResolvedIdentifier2("name'", "String");
//     assertResolvedIdentifier2("done'", "bool");
//   }
//   void test_ngRepeat_filters_orderBy_propertyName() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:'name'\"/>",
//         "</li>"]));
//     assertResolvedIdentifier2("name'", "String");
//   }
//   void test_ngRepeat_filters_orderBy_propertyName_minus() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:'-name'\"/>",
//         "</li>"]));
//     assertResolvedIdentifier2("name'", "String");
//   }
//   void test_ngRepeat_filters_orderBy_propertyName_plus() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:'+name'\"/>",
//         "</li>"]));
//     assertResolvedIdentifier2("name'", "String");
//   }
//   void test_ngRepeat_filters_orderBy_propertyName_untypedItems() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.untypedItems | orderBy:'name'\"/>",
//         "</li>"]));
//     assertResolvedIdentifier2("name'", "dynamic");
//   }
//   void test_ngRepeat_filters_two() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat=\"item in ctrl.items | orderBy:'+' | orderBy:'-'\"/>",
//         "</li>"]));
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularFormatterElement, AngularFormatterElement, assertResolvedIdentifier("orderBy:'+'"));
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularFormatterElement, AngularFormatterElement, assertResolvedIdentifier("orderBy:'-'"));
//   }
//   void test_ngRepeat_resolvedExpressions() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat='name in ctrl.names'>",
//         "  {{name}}",
//         "</li>"]));
//     assertResolvedIdentifier2("name in", "String");
//     assertResolvedIdentifier2("ctrl.", "MyController");
//     assertResolvedIdentifier2("names'", "List<String>");
//     assertResolvedIdentifier2("name}}", "String");
//   }
//   void test_ngRepeat_trackBy() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController([
//         "<li ng-repeat='name in ctrl.names track by name.length'/>",
//         "</li>"]));
//     assertResolvedIdentifier2("length'", "int");
//   }
//   /**
//    * Test that we resolve "ng-show" expression.
//    */
//   void test_ngShow() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<div ng-show='ctrl.field != null'/>"]));
//     assertResolvedIdentifier("field");
//   }
//   void test_notResolved_noDartScript() {
//     resolveIndex2(EngineTestCase.createSource([
//         "<html ng-app>",
//         "  <body>",
//         "    <div my-marker>",
//         "      {{ctrl.field}}",
//         "    </div>",
//         "  </body>",
//         "</html>"]));
//     assertNoErrors();
//     // Angular is not initialized, so "ctrl" is not parsed
//     Expression expression = HtmlUnitUtils.getExpression(indexUnit, findOffset2("ctrl"));
//     JUnitTestCase.assertNull(expression);
//   }
//   void test_notResolved_notAngular() {
//     resolveIndex2(EngineTestCase.createSource([
//         "<html no-ng-app>",
//         "  <body>",
//         "    <div my-marker>",
//         "      {{ctrl.field}}",
//         "    </div>",
//         "  </body>",
//         "</html>"]));
//     assertNoErrors();
//     // Angular is not initialized, so "ctrl" is not parsed
//     Expression expression = HtmlUnitUtils.getExpression(indexUnit, findOffset2("ctrl"));
//     JUnitTestCase.assertNull(expression);
//   }
//   void test_notResolved_wrongControllerMarker() {
//     addMyController();
//     addIndexSource(EngineTestCase.createSource([
//         "<html ng-app>",
//         "  <body>",
//         "    <div not-my-marker>",
//         "      {{ctrl.field}}",
//         "    </div>",
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]));
//     contextHelper.runTasks();
//     resolveIndex();
//     // no errors, because we decided to ignore them at the moment
//     assertNoErrors();
//     // "ctrl" is not resolved
//     SimpleIdentifier identifier = findIdentifier("ctrl");
//     JUnitTestCase.assertNull(identifier.bestElement);
//   }
//   void test_resolveExpression_evenWithout_ngBootstrap() {
//     resolveMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Controller(",
//         "    selector: '[my-controller]',",
//         "    publishAs: 'ctrl')",
//         "class MyController {",
//         "  String field;",
//         "}"]));
//     _resolveIndexNoErrors(EngineTestCase.createSource([
//         "<html ng-app>",
//         "  <body>",
//         "    <div my-controller>",
//         "      {{ctrl.field}}",
//         "    </div>",
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]));
//     assertResolvedIdentifier2("ctrl.", "MyController");
//   }
//   void test_resolveExpression_ignoreUnresolved() {
//     resolveMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Controller(",
//         "    selector: '[my-controller]',",
//         "    publishAs: 'ctrl')",
//         "class MyController {",
//         "  Map map;",
//         "  Object obj;",
//         "}"]));
//     resolveIndex2(EngineTestCase.createSource([
//         "<html ng-app>",
//         "  <body>",
//         "    <div my-controller>",
//         "      {{ctrl.map.property}}",
//         "      {{ctrl.obj.property}}",
//         "      {{invisibleScopeProperty}}",
//         "    </div>",
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]));
//     assertNoErrors();
//     // "ctrl.map" and "ctrl.obj" are resolved
//     assertResolvedIdentifier2("map", "Map<dynamic, dynamic>");
//     assertResolvedIdentifier2("obj", "Object");
//     // ...but not "invisibleScopeProperty"
//     {
//       SimpleIdentifier identifier = findIdentifier("invisibleScopeProperty");
//       JUnitTestCase.assertNull(identifier.bestElement);
//     }
//   }
//   void test_resolveExpression_inAttribute() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["<button title='{{ctrl.field}}'></button>"]));
//     assertResolvedIdentifier2("ctrl", "MyController");
//   }
//   void test_resolveExpression_ngApp_onBody() {
//     addMyController();
//     _resolveIndexNoErrors(EngineTestCase.createSource([
//         "<html>",
//         "  <body ng-app>",
//         "    <div my-controller>",
//         "      {{ctrl.field}}",
//         "    </div>",
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]));
//     assertResolvedIdentifier2("ctrl", "MyController");
//   }
//   void test_resolveExpression_withFilter() {
//     addMyController();
//     _resolveIndexNoErrors(AngularTest.createHtmlWithMyController(["{{ctrl.field | uppercase}}"]));
//     assertResolvedIdentifier2("ctrl", "MyController");
//     assertResolvedIdentifier("uppercase");
//   }
//   void test_resolveExpression_withFilter_notSimpleIdentifier() {
//     addMyController();
//     resolveIndex2(AngularTest.createHtmlWithMyController(["{{ctrl.field | not.supported}}"]));
//     assertErrors(indexSource, [AngularCode.INVALID_FORMATTER_NAME]);
//   }
//   void test_scopeProperties() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "  String field;",
//         "  MyComponent(Scope scope) {",
//         "    scope.context['scopeProperty'] = 'abc';",
//         "  }",
//         "}",
//         ""]));
//     contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{scopeProperty}}", "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     resolveIndex();
//     assertNoErrors();
//     // "scopeProperty" is resolved
//     Element element = assertResolvedIdentifier2("scopeProperty}}", "String");
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularScopePropertyElement, AngularScopePropertyElement, AngularHtmlUnitResolver.getAngularElement(element));
//   }
//   void test_scopeProperties_hideWithComponent() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Component(",
//         "    templateUrl: 'my_template.html', cssUrl: 'my_styles.css',",
//         "    publishAs: 'ctrl',",
//         "    selector: 'myComponent')",
//         "class MyComponent {",
//         "}",
//         "",
//         "void setScopeProperties(Scope scope) {",
//         "  scope.context['ctrl'] = 1;",
//         "}",
//         ""]));
//     contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource(["    <div>", "      {{ctrl}}", "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     resolveIndex();
//     assertNoErrors();
//     // "ctrl" is resolved
//     LocalVariableElement element = assertResolvedIdentifier("ctrl}}") as LocalVariableElement;
//     List<ToolkitObjectElement> toolkitObjects = element.toolkitObjects;
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularComponentElement, AngularComponentElement, toolkitObjects[0]);
//   }
//   void test_view_resolveTemplateFile() {
//     addMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "@Controller(",
//         "    selector: '[my-controller]',",
//         "    publishAs: 'ctrl')",
//         "class MyController {",
//         "  String field;",
//         "}",
//         "",
//         "class MyRouteInitializer {",
//         "  init(ViewFactory view) {",
//         "    view('my_template.html');",
//         "  }",
//         "}"]));
//     contextHelper.addSource("/entry-point.html", AngularTest.createHtmlWithAngular([]));
//     addIndexSource2("/my_template.html", EngineTestCase.createSource([
//         "    <div my-controller>",
//         "      {{ctrl.field}}",
//         "    </div>"]));
//     contextHelper.addSource("/my_styles.css", "");
//     contextHelper.runTasks();
//     resolveIndex();
//     assertNoErrors();
//     assertResolvedIdentifier2("ctrl.", "MyController");
//     assertResolvedIdentifier2("field}}", "String");
//   }
//   String _getSourceContent(Source source) => context.getContents(source).data.toString();
//   void _resolveIndexNoErrors(String content) {
//     resolveIndex2(content);
//     assertNoErrors();
//     verify([indexSource]);
//   }
//   static dartSuite() {
//     _ut.group('AngularHtmlUnitResolverTest', () {
//       _ut.test('test_NgComponent_resolveTemplateFile', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgComponent_resolveTemplateFile);
//       });
//       _ut.test('test_NgComponent_updateDartFile', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgComponent_updateDartFile);
//       });
//       _ut.test('test_NgComponent_use_resolveAttributes', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgComponent_use_resolveAttributes);
//       });
//       _ut.test('test_NgDirective_noAttribute', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgDirective_noAttribute);
//       });
//       _ut.test('test_NgDirective_noExpression', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgDirective_noExpression);
//       });
//       _ut.test('test_NgDirective_resolvedExpression', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgDirective_resolvedExpression);
//       });
//       _ut.test('test_NgDirective_resolvedExpression_attrString', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgDirective_resolvedExpression_attrString);
//       });
//       _ut.test('test_NgDirective_resolvedExpression_dotAsName', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_NgDirective_resolvedExpression_dotAsName);
//       });
//       _ut.test('test_analysisContext_changeDart_invalidateApplication', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_analysisContext_changeDart_invalidateApplication);
//       });
//       _ut.test('test_analysisContext_changeEntryPoint_clearAngularErrors_inDart', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_analysisContext_changeEntryPoint_clearAngularErrors_inDart);
//       });
//       _ut.test('test_analysisContext_changeEntryPoint_clearAngularErrors_inTemplate', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_analysisContext_changeEntryPoint_clearAngularErrors_inTemplate);
//       });
//       _ut.test('test_analysisContext_removeEntryPoint_clearAngularErrors_inDart', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_analysisContext_removeEntryPoint_clearAngularErrors_inDart);
//       });
//       _ut.test('test_contextProperties', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_contextProperties);
//       });
//       _ut.test('test_getAngularElement_isAngular', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_getAngularElement_isAngular);
//       });
//       _ut.test('test_getAngularElement_notAngular', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_getAngularElement_notAngular);
//       });
//       _ut.test('test_getAngularElement_notLocal', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_getAngularElement_notLocal);
//       });
//       _ut.test('test_ngClick', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngClick);
//       });
//       _ut.test('test_ngIf', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngIf);
//       });
//       _ut.test('test_ngModel_modelAfterUsage', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngModel_modelAfterUsage);
//       });
//       _ut.test('test_ngModel_modelBeforeUsage', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngModel_modelBeforeUsage);
//       });
//       _ut.test('test_ngModel_notIdentifier', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngModel_notIdentifier);
//       });
//       _ut.test('test_ngMouseOut', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngMouseOut);
//       });
//       _ut.test('test_ngRepeat_additionalVariables', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_additionalVariables);
//       });
//       _ut.test('test_ngRepeat_bad_expectedIdentifier', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_bad_expectedIdentifier);
//       });
//       _ut.test('test_ngRepeat_bad_expectedIn', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_bad_expectedIn);
//       });
//       _ut.test('test_ngRepeat_filters_filter_literal', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_filter_literal);
//       });
//       _ut.test('test_ngRepeat_filters_filter_propertyMap', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_filter_propertyMap);
//       });
//       _ut.test('test_ngRepeat_filters_missingColon', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_missingColon);
//       });
//       _ut.test('test_ngRepeat_filters_noArgs', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_noArgs);
//       });
//       _ut.test('test_ngRepeat_filters_orderBy_emptyString', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_orderBy_emptyString);
//       });
//       _ut.test('test_ngRepeat_filters_orderBy_propertyList', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_orderBy_propertyList);
//       });
//       _ut.test('test_ngRepeat_filters_orderBy_propertyName', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_orderBy_propertyName);
//       });
//       _ut.test('test_ngRepeat_filters_orderBy_propertyName_minus', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_orderBy_propertyName_minus);
//       });
//       _ut.test('test_ngRepeat_filters_orderBy_propertyName_plus', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_orderBy_propertyName_plus);
//       });
//       _ut.test('test_ngRepeat_filters_orderBy_propertyName_untypedItems', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_orderBy_propertyName_untypedItems);
//       });
//       _ut.test('test_ngRepeat_filters_two', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_filters_two);
//       });
//       _ut.test('test_ngRepeat_resolvedExpressions', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_resolvedExpressions);
//       });
//       _ut.test('test_ngRepeat_trackBy', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngRepeat_trackBy);
//       });
//       _ut.test('test_ngShow', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_ngShow);
//       });
//       _ut.test('test_notResolved_noDartScript', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_notResolved_noDartScript);
//       });
//       _ut.test('test_notResolved_notAngular', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_notResolved_notAngular);
//       });
//       _ut.test('test_notResolved_wrongControllerMarker', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_notResolved_wrongControllerMarker);
//       });
//       _ut.test('test_resolveExpression_evenWithout_ngBootstrap', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_resolveExpression_evenWithout_ngBootstrap);
//       });
//       _ut.test('test_resolveExpression_ignoreUnresolved', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_resolveExpression_ignoreUnresolved);
//       });
//       _ut.test('test_resolveExpression_inAttribute', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_resolveExpression_inAttribute);
//       });
//       _ut.test('test_resolveExpression_ngApp_onBody', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_resolveExpression_ngApp_onBody);
//       });
//       _ut.test('test_resolveExpression_withFilter', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_resolveExpression_withFilter);
//       });
//       _ut.test('test_resolveExpression_withFilter_notSimpleIdentifier', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_resolveExpression_withFilter_notSimpleIdentifier);
//       });
//       _ut.test('test_scopeProperties', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_scopeProperties);
//       });
//       _ut.test('test_scopeProperties_hideWithComponent', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_scopeProperties_hideWithComponent);
//       });
//       _ut.test('test_view_resolveTemplateFile', () {
//         final __test = new AngularHtmlUnitResolverTest();
//         runJUnitTest(__test, __test.test_view_resolveTemplateFile);
//       });
//     });
//   }
// }
// /**
//  * Tests for [HtmlUnitUtils] for Angular HTMLs.
//  */
// class AngularHtmlUnitUtilsTest extends AngularTest {
//   void test_getElement_forExpression() {
//     addMyController();
//     _resolveSimpleCtrlFieldHtml();
//     // prepare expression
//     int offset = indexContent.indexOf("ctrl");
//     Expression expression = HtmlUnitUtils.getExpression(indexUnit, offset);
//     // get element
//     Element element = HtmlUnitUtils.getElement(expression);
//     EngineTestCase.assertInstanceOf((obj) => obj is VariableElement, VariableElement, element);
//     JUnitTestCase.assertEquals("ctrl", element.name);
//   }
//   void test_getElement_forExpression_null() {
//     Element element = HtmlUnitUtils.getElement(null);
//     JUnitTestCase.assertNull(element);
//   }
//   void test_getElement_forOffset() {
//     addMyController();
//     _resolveSimpleCtrlFieldHtml();
//     // no expression
//     {
//       Element element = HtmlUnitUtils.getElementAtOffset(indexUnit, 0);
//       JUnitTestCase.assertNull(element);
//     }
//     // has expression at offset
//     {
//       int offset = indexContent.indexOf("field");
//       Element element = HtmlUnitUtils.getElementAtOffset(indexUnit, offset);
//       EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement, PropertyAccessorElement, element);
//       JUnitTestCase.assertEquals("field", element.name);
//     }
//   }
//   void test_getElementToOpen_controller() {
//     addMyController();
//     _resolveSimpleCtrlFieldHtml();
//     // prepare expression
//     int offset = indexContent.indexOf("ctrl");
//     Expression expression = HtmlUnitUtils.getExpression(indexUnit, offset);
//     // get element
//     Element element = HtmlUnitUtils.getElementToOpen(indexUnit, expression);
//     EngineTestCase.assertInstanceOf((obj) => obj is AngularControllerElement, AngularControllerElement, element);
//     JUnitTestCase.assertEquals("ctrl", element.name);
//   }
//   void test_getElementToOpen_field() {
//     addMyController();
//     _resolveSimpleCtrlFieldHtml();
//     // prepare expression
//     int offset = indexContent.indexOf("field");
//     Expression expression = HtmlUnitUtils.getExpression(indexUnit, offset);
//     // get element
//     Element element = HtmlUnitUtils.getElementToOpen(indexUnit, expression);
//     EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement, PropertyAccessorElement, element);
//     JUnitTestCase.assertEquals("field", element.name);
//   }
//   void test_getEnclosingTagNode() {
//     resolveIndex2(EngineTestCase.createSource([
//         "<html>",
//         "  <body ng-app>",
//         "    <badge name='abc'> 123 </badge>",
//         "  </body>",
//         "</html>"]));
//     // no unit
//     JUnitTestCase.assertNull(HtmlUnitUtils.getEnclosingTagNode(null, 0));
//     // wrong offset
//     JUnitTestCase.assertNull(HtmlUnitUtils.getEnclosingTagNode(indexUnit, -1));
//     // valid offset
//     XmlTagNode expected = _getEnclosingTagNode("<badge");
//     JUnitTestCase.assertNotNull(expected);
//     JUnitTestCase.assertEquals("badge", expected.tag);
//     JUnitTestCase.assertSame(expected, _getEnclosingTagNode("badge"));
//     JUnitTestCase.assertSame(expected, _getEnclosingTagNode("name="));
//     JUnitTestCase.assertSame(expected, _getEnclosingTagNode("123"));
//     JUnitTestCase.assertSame(expected, _getEnclosingTagNode("/badge"));
//   }
//   void test_getExpression() {
//     addMyController();
//     _resolveSimpleCtrlFieldHtml();
//     // try offset without expression
//     JUnitTestCase.assertNull(HtmlUnitUtils.getExpression(indexUnit, 0));
//     // try offset with expression
//     int offset = indexContent.indexOf("ctrl");
//     JUnitTestCase.assertNotNull(HtmlUnitUtils.getExpression(indexUnit, offset));
//     JUnitTestCase.assertNotNull(HtmlUnitUtils.getExpression(indexUnit, offset + 1));
//     JUnitTestCase.assertNotNull(HtmlUnitUtils.getExpression(indexUnit, offset + 2));
//     JUnitTestCase.assertNotNull(HtmlUnitUtils.getExpression(indexUnit, offset + "ctrl.field".length));
//     // try without unit
//     JUnitTestCase.assertNull(HtmlUnitUtils.getExpression(null, offset));
//   }
//   void test_getTagNode() {
//     resolveIndex2(EngineTestCase.createSource([
//         "<html>",
//         "  <body ng-app>",
//         "    <badge name='abc'> 123 </badge> done",
//         "  </body>",
//         "</html>"]));
//     // no unit
//     JUnitTestCase.assertNull(HtmlUnitUtils.getTagNode(null, 0));
//     // wrong offset
//     JUnitTestCase.assertNull(HtmlUnitUtils.getTagNode(indexUnit, -1));
//     // on tag name
//     XmlTagNode expected = _getTagNode("badge name=");
//     JUnitTestCase.assertNotNull(expected);
//     JUnitTestCase.assertEquals("badge", expected.tag);
//     JUnitTestCase.assertSame(expected, _getTagNode("badge"));
//     JUnitTestCase.assertSame(expected, _getTagNode(" name="));
//     JUnitTestCase.assertSame(expected, _getTagNode("adge name="));
//     JUnitTestCase.assertSame(expected, _getTagNode("badge>"));
//     JUnitTestCase.assertSame(expected, _getTagNode("adge>"));
//     JUnitTestCase.assertSame(expected, _getTagNode("> done"));
//     // in tag node, but not on the name token
//     JUnitTestCase.assertNull(_getTagNode("name="));
//     JUnitTestCase.assertNull(_getTagNode("123"));
//   }
//   XmlTagNode _getEnclosingTagNode(String search) => HtmlUnitUtils.getEnclosingTagNode(indexUnit, indexContent.indexOf(search));
//   XmlTagNode _getTagNode(String search) => HtmlUnitUtils.getTagNode(indexUnit, indexContent.indexOf(search));
//   void _resolveSimpleCtrlFieldHtml() {
//     resolveIndex2(EngineTestCase.createSource([
//         "<html>",
//         "  <body ng-app>",
//         "    <div my-controller>",
//         "      {{ctrl.field}}",
//         "    </div>",
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]));
//   }
//   static dartSuite() {
//     _ut.group('AngularHtmlUnitUtilsTest', () {
//       _ut.test('test_getElementToOpen_controller', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getElementToOpen_controller);
//       });
//       _ut.test('test_getElementToOpen_field', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getElementToOpen_field);
//       });
//       _ut.test('test_getElement_forExpression', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getElement_forExpression);
//       });
//       _ut.test('test_getElement_forExpression_null', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getElement_forExpression_null);
//       });
//       _ut.test('test_getElement_forOffset', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getElement_forOffset);
//       });
//       _ut.test('test_getEnclosingTagNode', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getEnclosingTagNode);
//       });
//       _ut.test('test_getExpression', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getExpression);
//       });
//       _ut.test('test_getTagNode', () {
//         final __test = new AngularHtmlUnitUtilsTest();
//         runJUnitTest(__test, __test.test_getTagNode);
//       });
//     });
//   }
// }
// abstract class AngularTest extends EngineTestCase {
//   /**
//    * Creates an HTML content that has Angular marker and script with "main.dart" reference.
//    */
//   static String createHtmlWithAngular(List<String> lines) {
//     String source = EngineTestCase.createSource(["<html ng-app>", "  <body>"]);
//     source += EngineTestCase.createSource(lines);
//     source += EngineTestCase.createSource([
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]);
//     return source;
//   }
//   /**
//    * Creates an HTML content that has Angular marker, script with "main.dart" reference and
//    * "MyController" injected.
//    */
//   static String createHtmlWithMyController(List<String> lines) {
//     String source = EngineTestCase.createSource(["<html ng-app>", "  <body>", "    <div my-controller>"]);
//     source += EngineTestCase.createSource(lines);
//     source += EngineTestCase.createSource([
//         "    </div>",
//         "    <script type='application/dart' src='main.dart'></script>",
//         "  </body>",
//         "</html>"]);
//     return source;
//   }
//   /**
//    * Finds an [Element] with the given names inside of the given root [Element].
//    *
//    * TODO(scheglov) maybe move this method to Element
//    *
//    * @param root the root [Element] to start searching from
//    * @param kind the kind of the [Element] to find, if `null` then any kind
//    * @param name the name of an [Element] to find
//    * @return the found [Element] or `null` if not found
//    */
//   static Element findElement(Element root, ElementKind kind, String name) {
//     List<Element> result = [null];
//     root.accept(new GeneralizingElementVisitor_AngularTest_findElement(kind, name, result));
//     return result[0] as Element;
//   }
//   /**
//    * Finds an [Element] with the given names inside of the given root [Element].
//    *
//    * @param root the root [Element] to start searching from
//    * @param name the name of an [Element] to find
//    * @return the found [Element] or `null` if not found
//    */
//   static Element findElement2(Element root, String name) => findElement(root, null, name);
//   /**
//    * @return the offset of given <code>search</code> string in <code>content</code>. Fails test if
//    *         not found.
//    */
//   static int findOffset(String content, String search) {
//     int offset = content.indexOf(search);
//     assertThat(offset).describedAs(content).isNotEqualTo(-1);
//     return offset;
//   }
//   AnalysisContextHelper contextHelper = new AnalysisContextHelper();
//   AnalysisContext context;
//   String mainContent;
//   Source mainSource;
//   CompilationUnit mainUnit;
//   CompilationUnitElement mainUnitElement;
//   String indexContent;
//   Source indexSource;
//   HtmlUnit indexUnit;
//   HtmlElement indexHtmlUnit;
//   CompilationUnitElement indexDartUnitElement;
//   /**
//    * Fills [indexContent] and [indexSource].
//    */
//   void addIndexSource(String content) {
//     addIndexSource2("/index.html", content);
//   }
//   /**
//    * Fills [indexContent] and [indexSource].
//    */
//   void addIndexSource2(String name, String content) {
//     indexContent = content;
//     indexSource = contextHelper.addSource(name, indexContent);
//   }
//   /**
//    * Fills [mainContent] and [mainSource].
//    */
//   void addMainSource(String content) {
//     mainContent = content;
//     mainSource = contextHelper.addSource("/main.dart", content);
//   }
//   void addMyController() {
//     resolveMainSource(EngineTestCase.createSource([
//         "",
//         "import 'angular.dart';",
//         "",
//         "class Item {",
//         "  String name;",
//         "  bool done;",
//         "}",
//         "",
//         "@Controller(",
//         "    selector: '[my-controller]',",
//         "    publishAs: 'ctrl')",
//         "class MyController {",
//         "  String field;",
//         "  List<String> names;",
//         "  List<Item> items;",
//         "  var untypedItems;",
//         "  doSomething(event) {}",
//         "}"]));
//   }
//   /**
//    * Assert that the number of errors reported against the given source matches the number of errors
//    * that are given and that they have the expected error codes. The order in which the errors were
//    * gathered is ignored.
//    *
//    * @param source the source against which the errors should have been reported
//    * @param expectedErrorCodes the error codes of the errors that should have been reported
//    * @throws AnalysisException if the reported errors could not be computed
//    * @throws AssertionFailedError if a different number of errors have been reported than were
//    *           expected
//    */
//   void assertErrors(Source source, List<ErrorCode> expectedErrorCodes) {
//     GatheringErrorListener errorListener = new GatheringErrorListener();
//     AnalysisErrorInfo errorsInfo = context.getErrors(source);
//     for (AnalysisError error in errorsInfo.errors) {
//       errorListener.onError(error);
//     }
//     errorListener.assertErrorsWithCodes(expectedErrorCodes);
//   }
//   void assertMainErrors(List<ErrorCode> expectedErrorCodes) {
//     assertErrors(mainSource, expectedErrorCodes);
//   }
//   /**
//    * Assert that no errors have been reported against the [indexSource].
//    */
//   void assertNoErrors() {
//     assertErrors(indexSource, []);
//   }
//   void assertNoErrors2(Source source) {
//     assertErrors(source, []);
//   }
//   /**
//    * Assert that no errors have been reported against the [mainSource].
//    */
//   void assertNoMainErrors() {
//     assertErrors(mainSource, []);
//   }
//   /**
//    * Checks that [indexHtmlUnit] has [SimpleIdentifier] with given name, resolved to
//    * not `null` [Element].
//    */
//   Element assertResolvedIdentifier(String name) {
//     SimpleIdentifier identifier = findIdentifier(name);
//     // check Element
//     Element element = identifier.bestElement;
//     JUnitTestCase.assertNotNull(element);
//     // return Element for further analysis
//     return element;
//   }
//   Element assertResolvedIdentifier2(String name, String expectedTypeName) {
//     SimpleIdentifier identifier = findIdentifier(name);
//     // check Element
//     Element element = identifier.bestElement;
//     JUnitTestCase.assertNotNull(element);
//     // check Type
//     DartType type = identifier.bestType;
//     JUnitTestCase.assertNotNull(type);
//     JUnitTestCase.assertEquals(expectedTypeName, type.toString());
//     // return Element for further analysis
//     return element;
//   }
//   /**
//    * @return [AstNode] which has required offset and type.
//    */
//   AstNode findExpression(int offset, Type clazz) {
//     Expression expression = HtmlUnitUtils.getExpression(indexUnit, offset);
//     return expression != null ? expression.getAncestor(predicate) : null;
//   }
//   /**
//    * Returns the [SimpleIdentifier] at the given search pattern. Fails if not found.
//    */
//   SimpleIdentifier findIdentifier(String search) {
//     SimpleIdentifier identifier = findIdentifierMaybe(search);
//     JUnitTestCase.assertNotNullMsg("${search} in ${indexContent}", identifier);
//     // check that offset/length of the identifier is valid
//     {
//       int offset = identifier.offset;
//       int end = identifier.end;
//       String contentStr = indexContent.substring(offset, end);
//       JUnitTestCase.assertEquals(identifier.name, contentStr);
//     }
//     // done
//     return identifier;
//   }
//   /**
//    * Returns the [SimpleIdentifier] at the given search pattern, or `null` if not found.
//    */
//   SimpleIdentifier findIdentifierMaybe(String search) => findExpression(findOffset2(search), SimpleIdentifier);
//   /**
//    * Returns [Element] from [indexDartUnitElement].
//    */
//   Element findIndexElement(String name) => findElement2(indexDartUnitElement, name);
//   /**
//    * Returns [Element] from [mainUnitElement].
//    */
//   Element findMainElement(ElementKind kind, String name) => findElement(mainUnitElement, kind, name);
//   /**
//    * Returns [Element] from [mainUnitElement].
//    */
//   Element findMainElement2(String name) => findElement2(mainUnitElement, name);
//   /**
//    * @return the offset of given <code>search</code> string in [mainContent]. Fails test if
//    *         not found.
//    */
//   int findMainOffset(String search) => findOffset(mainContent, search);
//   /**
//    * @return the offset of given <code>search</code> string in [indexContent]. Fails test if
//    *         not found.
//    */
//   int findOffset2(String search) => findOffset(indexContent, search);
//   /**
//    * Resolves [indexSource].
//    */
//   void resolveIndex() {
//     indexUnit = context.resolveHtmlUnit(indexSource);
//     indexHtmlUnit = indexUnit.element;
//     indexDartUnitElement = indexHtmlUnit.angularCompilationUnit;
//   }
//   void resolveIndex2(String content) {
//     addIndexSource(content);
//     contextHelper.runTasks();
//     resolveIndex();
//   }
//   /**
//    * Resolves [mainSource].
//    */
//   void resolveMain() {
//     mainUnit = contextHelper.resolveDefiningUnit(mainSource);
//     mainUnitElement = mainUnit.element;
//   }
//   /**
//    * Resolves [mainSource].
//    */
//   void resolveMainNoErrors() {
//     resolveMain();
//     assertNoErrors2(mainSource);
//   }
//   void resolveMainSource(String content) {
//     addMainSource(content);
//     resolveMain();
//   }
//   void resolveMainSourceNoErrors(String content) {
//     resolveMainSource(content);
//     assertNoErrors2(mainSource);
//   }
//   @override
//   void setUp() {
//     super.setUp();
//     _configureForAngular(contextHelper);
//     context = contextHelper.context;
//   }
//   @override
//   void tearDown() {
//     contextHelper = null;
//     context = null;
//     // main
//     mainContent = null;
//     mainSource = null;
//     mainUnit = null;
//     mainUnitElement = null;
//     // index
//     indexContent = null;
//     indexSource = null;
//     indexUnit = null;
//     indexHtmlUnit = null;
//     indexDartUnitElement = null;
//     // super
//     super.tearDown();
//   }
//   /**
//    * Verify that all of the identifiers in the HTML units associated with the given sources have
//    * been resolved.
//    *
//    * @param sources the sources identifying the compilation units to be verified
//    * @throws Exception if the contents of the compilation unit cannot be accessed
//    */
//   void verify(List<Source> sources) {
//     ResolutionVerifier verifier = new ResolutionVerifier();
//     for (Source source in sources) {
//       HtmlUnit htmlUnit = context.getResolvedHtmlUnit(source);
//       htmlUnit.accept(new ExpressionVisitor_AngularTest_verify(verifier));
//     }
//     verifier.assertResolved();
//   }
//   void _configureForAngular(AnalysisContextHelper contextHelper) {
//     contextHelper.addSource("/angular.dart", EngineTestCase.createSource([
//         "library angular;",
//         "",
//         "class Scope {",
//         "  Map context;",
//         "}",
//         "",
//         "class Formatter {",
//         "  final String name;",
//         "  const Formatter({this.name});",
//         "}",
//         "",
//         "class Directive {",
//         "  const Directive({",
//         "    selector,",
//         "    children,",
//         "    visibility,",
//         "    module,",
//         "    map,",
//         "    exportedExpressions,",
//         "    exportedExpressionAttrs",
//         "  });",
//         "}",
//         "",
//         "class Decorator {",
//         "  const Decorator({",
//         "    children/*: Directive.COMPILE_CHILDREN*/,",
//         "    map,",
//         "    selector,",
//         "    module,",
//         "    visibility,",
//         "    exportedExpressions,",
//         "    exportedExpressionAttrs",
//         "  });",
//         "}",
//         "",
//         "class Controller {",
//         "  const Controller({",
//         "    children,",
//         "    publishAs,",
//         "    map,",
//         "    selector,",
//         "    visibility,",
//         "    publishTypes,",
//         "    exportedExpressions,",
//         "    exportedExpressionAttrs",
//         "  });",
//         "}",
//         "",
//         "class NgAttr {",
//         "  const NgAttr(String name);",
//         "}",
//         "class NgCallback {",
//         "  const NgCallback(String name);",
//         "}",
//         "class NgOneWay {",
//         "  const NgOneWay(String name);",
//         "}",
//         "class NgOneWayOneTime {",
//         "  const NgOneWayOneTime(String name);",
//         "}",
//         "class NgTwoWay {",
//         "  const NgTwoWay(String name);",
//         "}",
//         "",
//         "class Component extends Directive {",
//         "  const Component({",
//         "    this.template,",
//         "    this.templateUrl,",
//         "    this.cssUrl,",
//         "    this.applyAuthorStyles,",
//         "    this.resetStyleInheritance,",
//         "    publishAs,",
//         "    module,",
//         "    map,",
//         "    selector,",
//         "    visibility,",
//         "    exportExpressions,",
//         "    exportExpressionAttrs",
//         "  }) : super(selector: selector,",
//         "             children: null/*NgAnnotation.COMPILE_CHILDREN*/,",
//         "             visibility: visibility,",
//         "             map: map,",
//         "             module: module,",
//         "             exportExpressions: exportExpressions,",
//         "             exportExpressionAttrs: exportExpressionAttrs);",
//         "}",
//         "",
//         "@Decorator(selector: '[ng-click]', map: const {'ng-click': '&onEvent'})",
//         "@Decorator(selector: '[ng-mouseout]', map: const {'ng-mouseout': '&onEvent'})",
//         "class NgEventDirective {",
//         "  set onEvent(value) {}",
//         "}",
//         "",
//         "@Decorator(selector: '[ng-if]', map: const {'ng-if': '=>condition'})",
//         "class NgIfDirective {",
//         "  set condition(value) {}",
//         "}",
//         "",
//         "@Decorator(selector: '[ng-show]', map: const {'ng-show': '=>show'})",
//         "class NgShowDirective {",
//         "  set show(value) {}",
//         "}",
//         "",
//         "@Formatter(name: 'filter')",
//         "class FilterFormatter {}",
//         "",
//         "@Formatter(name: 'orderBy')",
//         "class OrderByFilter {}",
//         "",
//         "@Formatter(name: 'uppercase')",
//         "class UppercaseFilter {}",
//         "",
//         "class ViewFactory {",
//         "  call(String templateUrl) => null;",
//         "}",
//         "",
//         "class Module {",
//         "  install(Module m) {}",
//         "  type(Type t) {}",
//         "  value(Type t, value) {}",
//         "}",
//         "",
//         "class Injector {}",
//         "",
//         "Injector ngBootstrap({",
//         "        Module module: null,",
//         "        List<Module> modules: null,",
//         "        /*dom.Element*/ element: null,",
//         "        String selector: '[ng-app]',",
//         "        /*Injector*/ injectorFactory/*(List<Module> modules): _defaultInjectorFactory*/}) {}",
//         ""]));
//   }
// }
// class ConstantEvaluatorTest extends ResolverTestCase {
//   void fail_constructor() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_identifier_class() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_identifier_function() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_identifier_static() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_identifier_staticMethod() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_identifier_topLevel() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_identifier_typeParameter() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_prefixedIdentifier_invalid() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_prefixedIdentifier_valid() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_propertyAccess_invalid() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_propertyAccess_valid() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_simpleIdentifier_invalid() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void fail_simpleIdentifier_valid() {
//     EvaluationResult result = _getExpressionValue("?");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals(null, value);
//   }
//   void test_bitAnd_int_int() {
//     _assertValue3(74 & 42, "74 & 42");
//   }
//   void test_bitNot() {
//     _assertValue3(~42, "~42");
//   }
//   void test_bitOr_int_int() {
//     _assertValue3(74 | 42, "74 | 42");
//   }
//   void test_bitXor_int_int() {
//     _assertValue3(74 ^ 42, "74 ^ 42");
//   }
//   void test_divide_double_double() {
//     _assertValue2(3.2 / 2.3, "3.2 / 2.3");
//   }
//   void test_divide_double_double_byZero() {
//     EvaluationResult result = _getExpressionValue("3.2 / 0.0");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals("double", value.type.name);
//     JUnitTestCase.assertTrue(value.doubleValue.isInfinite());
//   }
//   void test_divide_int_int() {
//     _assertValue3(1, "3 / 2");
//   }
//   void test_divide_int_int_byZero() {
//     EvaluationResult result = _getExpressionValue("3 / 0");
//     JUnitTestCase.assertTrue(result.isValid);
//   }
//   void test_equal_boolean_boolean() {
//     _assertValue(false, "true == false");
//   }
//   void test_equal_int_int() {
//     _assertValue(false, "2 == 3");
//   }
//   void test_equal_invalidLeft() {
//     EvaluationResult result = _getExpressionValue("a == 3");
//     JUnitTestCase.assertFalse(result.isValid);
//   }
//   void test_equal_invalidRight() {
//     EvaluationResult result = _getExpressionValue("2 == a");
//     JUnitTestCase.assertFalse(result.isValid);
//   }
//   void test_equal_string_string() {
//     _assertValue(false, "'a' == 'b'");
//   }
//   void test_greaterThan_int_int() {
//     _assertValue(false, "2 > 3");
//   }
//   void test_greaterThanOrEqual_int_int() {
//     _assertValue(false, "2 >= 3");
//   }
//   void test_leftShift_int_int() {
//     _assertValue3(64, "16 << 2");
//   }
//   void test_lessThan_int_int() {
//     _assertValue(true, "2 < 3");
//   }
//   void test_lessThanOrEqual_int_int() {
//     _assertValue(true, "2 <= 3");
//   }
//   void test_literal_boolean_false() {
//     _assertValue(false, "false");
//   }
//   void test_literal_boolean_true() {
//     _assertValue(true, "true");
//   }
//   void test_literal_list() {
//     EvaluationResult result = _getExpressionValue("const ['a', 'b', 'c']");
//     JUnitTestCase.assertTrue(result.isValid);
//   }
//   void test_literal_map() {
//     EvaluationResult result = _getExpressionValue("const {'a' : 'm', 'b' : 'n', 'c' : 'o'}");
//     JUnitTestCase.assertTrue(result.isValid);
//   }
//   void test_literal_null() {
//     EvaluationResult result = _getExpressionValue("null");
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertTrue(value.isNull);
//   }
//   void test_literal_number_double() {
//     _assertValue2(3.45, "3.45");
//   }
//   void test_literal_number_integer() {
//     _assertValue3(42, "42");
//   }
//   void test_literal_string_adjacent() {
//     _assertValue4("abcdef", "'abc' 'def'");
//   }
//   void test_literal_string_interpolation_invalid() {
//     EvaluationResult result = _getExpressionValue("'a\${f()}c'");
//     JUnitTestCase.assertFalse(result.isValid);
//   }
//   void test_literal_string_interpolation_valid() {
//     _assertValue4("a3c", "'a\${3}c'");
//   }
//   void test_literal_string_simple() {
//     _assertValue4("abc", "'abc'");
//   }
//   void test_logicalAnd() {
//     _assertValue(false, "true && false");
//   }
//   void test_logicalNot() {
//     _assertValue(false, "!true");
//   }
//   void test_logicalOr() {
//     _assertValue(true, "true || false");
//   }
//   void test_minus_double_double() {
//     _assertValue2(3.2 - 2.3, "3.2 - 2.3");
//   }
//   void test_minus_int_int() {
//     _assertValue3(1, "3 - 2");
//   }
//   void test_negated_boolean() {
//     EvaluationResult result = _getExpressionValue("-true");
//     JUnitTestCase.assertFalse(result.isValid);
//   }
//   void test_negated_double() {
//     _assertValue2(-42.3, "-42.3");
//   }
//   void test_negated_integer() {
//     _assertValue3(-42, "-42");
//   }
//   void test_notEqual_boolean_boolean() {
//     _assertValue(true, "true != false");
//   }
//   void test_notEqual_int_int() {
//     _assertValue(true, "2 != 3");
//   }
//   void test_notEqual_invalidLeft() {
//     EvaluationResult result = _getExpressionValue("a != 3");
//     JUnitTestCase.assertFalse(result.isValid);
//   }
//   void test_notEqual_invalidRight() {
//     EvaluationResult result = _getExpressionValue("2 != a");
//     JUnitTestCase.assertFalse(result.isValid);
//   }
//   void test_notEqual_string_string() {
//     _assertValue(true, "'a' != 'b'");
//   }
//   void test_parenthesizedExpression() {
//     _assertValue4("a", "('a')");
//   }
//   void test_plus_double_double() {
//     _assertValue2(2.3 + 3.2, "2.3 + 3.2");
//   }
//   void test_plus_int_int() {
//     _assertValue3(5, "2 + 3");
//   }
//   void test_remainder_double_double() {
//     _assertValue2(3.2 % 2.3, "3.2 % 2.3");
//   }
//   void test_remainder_int_int() {
//     _assertValue3(2, "8 % 3");
//   }
//   void test_rightShift() {
//     _assertValue3(16, "64 >> 2");
//   }
//   void test_times_double_double() {
//     _assertValue2(2.3 * 3.2, "2.3 * 3.2");
//   }
//   void test_times_int_int() {
//     _assertValue3(6, "2 * 3");
//   }
//   void test_truncatingDivide_double_double() {
//     _assertValue3(1, "3.2 ~/ 2.3");
//   }
//   void test_truncatingDivide_int_int() {
//     _assertValue3(3, "10 ~/ 3");
//   }
//   void _assertValue(bool expectedValue, String contents) {
//     EvaluationResult result = _getExpressionValue(contents);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals("bool", value.type.name);
//     JUnitTestCase.assertEquals(expectedValue, value.boolValue);
//   }
//   void _assertValue2(double expectedValue, String contents) {
//     EvaluationResult result = _getExpressionValue(contents);
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals("double", value.type.name);
//     JUnitTestCase.assertEqualsMsg(expectedValue, value.doubleValue, 0.0);
//   }
//   void _assertValue3(int expectedValue, String contents) {
//     EvaluationResult result = _getExpressionValue(contents);
//     JUnitTestCase.assertTrue(result.isValid);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals("int", value.type.name);
//     JUnitTestCase.assertEquals(expectedValue, value.intValue.longValue());
//   }
//   void _assertValue4(String expectedValue, String contents) {
//     EvaluationResult result = _getExpressionValue(contents);
//     DartObject value = result.value;
//     JUnitTestCase.assertEquals("String", value.type.name);
//     JUnitTestCase.assertEquals(expectedValue, value.stringValue);
//   }
//   EvaluationResult _getExpressionValue(String contents) {
//     Source source = addSource("var x = ${contents};");
//     LibraryElement library = resolve(source);
//     CompilationUnit unit = analysisContext.resolveCompilationUnit(source, library);
//     JUnitTestCase.assertNotNull(unit);
//     NodeList<CompilationUnitMember> declarations = unit.declarations;
//     EngineTestCase.assertSizeOfList(1, declarations);
//     CompilationUnitMember declaration = declarations[0];
//     EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, declaration);
//     NodeList<VariableDeclaration> variables = (declaration as TopLevelVariableDeclaration).variables.variables;
//     EngineTestCase.assertSizeOfList(1, variables);
//     ConstantEvaluator evaluator = new ConstantEvaluator(source, new TestTypeProvider());
//     return evaluator.evaluate(variables[0].initializer);
//   }
//   static dartSuite() {
//     _ut.group('ConstantEvaluatorTest', () {
//       _ut.test('test_bitAnd_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_bitAnd_int_int);
//       });
//       _ut.test('test_bitNot', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_bitNot);
//       });
//       _ut.test('test_bitOr_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_bitOr_int_int);
//       });
//       _ut.test('test_bitXor_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_bitXor_int_int);
//       });
//       _ut.test('test_divide_double_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_divide_double_double);
//       });
//       _ut.test('test_divide_double_double_byZero', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_divide_double_double_byZero);
//       });
//       _ut.test('test_divide_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_divide_int_int);
//       });
//       _ut.test('test_divide_int_int_byZero', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_divide_int_int_byZero);
//       });
//       _ut.test('test_equal_boolean_boolean', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_equal_boolean_boolean);
//       });
//       _ut.test('test_equal_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_equal_int_int);
//       });
//       _ut.test('test_equal_invalidLeft', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_equal_invalidLeft);
//       });
//       _ut.test('test_equal_invalidRight', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_equal_invalidRight);
//       });
//       _ut.test('test_equal_string_string', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_equal_string_string);
//       });
//       _ut.test('test_greaterThanOrEqual_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_int_int);
//       });
//       _ut.test('test_greaterThan_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_greaterThan_int_int);
//       });
//       _ut.test('test_leftShift_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_leftShift_int_int);
//       });
//       _ut.test('test_lessThanOrEqual_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_int_int);
//       });
//       _ut.test('test_lessThan_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_lessThan_int_int);
//       });
//       _ut.test('test_literal_boolean_false', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_boolean_false);
//       });
//       _ut.test('test_literal_boolean_true', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_boolean_true);
//       });
//       _ut.test('test_literal_list', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_list);
//       });
//       _ut.test('test_literal_map', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_map);
//       });
//       _ut.test('test_literal_null', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_null);
//       });
//       _ut.test('test_literal_number_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_number_double);
//       });
//       _ut.test('test_literal_number_integer', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_number_integer);
//       });
//       _ut.test('test_literal_string_adjacent', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_string_adjacent);
//       });
//       _ut.test('test_literal_string_interpolation_invalid', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_string_interpolation_invalid);
//       });
//       _ut.test('test_literal_string_interpolation_valid', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_string_interpolation_valid);
//       });
//       _ut.test('test_literal_string_simple', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_literal_string_simple);
//       });
//       _ut.test('test_logicalAnd', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_logicalAnd);
//       });
//       _ut.test('test_logicalNot', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_logicalNot);
//       });
//       _ut.test('test_logicalOr', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_logicalOr);
//       });
//       _ut.test('test_minus_double_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_minus_double_double);
//       });
//       _ut.test('test_minus_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_minus_int_int);
//       });
//       _ut.test('test_negated_boolean', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_negated_boolean);
//       });
//       _ut.test('test_negated_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_negated_double);
//       });
//       _ut.test('test_negated_integer', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_negated_integer);
//       });
//       _ut.test('test_notEqual_boolean_boolean', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_notEqual_boolean_boolean);
//       });
//       _ut.test('test_notEqual_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_notEqual_int_int);
//       });
//       _ut.test('test_notEqual_invalidLeft', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_notEqual_invalidLeft);
//       });
//       _ut.test('test_notEqual_invalidRight', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_notEqual_invalidRight);
//       });
//       _ut.test('test_notEqual_string_string', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_notEqual_string_string);
//       });
//       _ut.test('test_parenthesizedExpression', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_parenthesizedExpression);
//       });
//       _ut.test('test_plus_double_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_plus_double_double);
//       });
//       _ut.test('test_plus_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_plus_int_int);
//       });
//       _ut.test('test_remainder_double_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_remainder_double_double);
//       });
//       _ut.test('test_remainder_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_remainder_int_int);
//       });
//       _ut.test('test_rightShift', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_rightShift);
//       });
//       _ut.test('test_times_double_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_times_double_double);
//       });
//       _ut.test('test_times_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_times_int_int);
//       });
//       _ut.test('test_truncatingDivide_double_double', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_truncatingDivide_double_double);
//       });
//       _ut.test('test_truncatingDivide_int_int', () {
//         final __test = new ConstantEvaluatorTest();
//         runJUnitTest(__test, __test.test_truncatingDivide_int_int);
//       });
//     });
//   }
// }
// class ConstantFinderTest extends EngineTestCase {
//   AstNode _node;
//   void test_visitConstructorDeclaration_const() {
//     ConstructorElement element = _setupConstructorDeclaration("A", true);
//     JUnitTestCase.assertSame(_node, _findConstantDeclarations()[element]);
//   }
//   void test_visitConstructorDeclaration_nonConst() {
//     _setupConstructorDeclaration("A", false);
//     JUnitTestCase.assertTrue(_findConstantDeclarations().isEmpty);
//   }
//   void test_visitInstanceCreationExpression_const() {
//     _setupInstanceCreationExpression("A", true);
//     JUnitTestCase.assertTrue(_findConstructorInvocations().contains(_node));
//   }
//   void test_visitInstanceCreationExpression_nonConst() {
//     _setupInstanceCreationExpression("A", false);
//     JUnitTestCase.assertTrue(_findConstructorInvocations().isEmpty);
//   }
//   void test_visitVariableDeclaration_const() {
//     VariableElement element = _setupVariableDeclaration("v", true, true);
//     JUnitTestCase.assertSame(_node, _findVariableDeclarations()[element]);
//   }
//   void test_visitVariableDeclaration_noInitializer() {
//     _setupVariableDeclaration("v", true, false);
//     JUnitTestCase.assertTrue(_findVariableDeclarations().isEmpty);
//   }
//   void test_visitVariableDeclaration_nonConst() {
//     _setupVariableDeclaration("v", false, true);
//     JUnitTestCase.assertTrue(_findVariableDeclarations().isEmpty);
//   }
//   HashMap<ConstructorElement, ConstructorDeclaration> _findConstantDeclarations() {
//     ConstantFinder finder = new ConstantFinder();
//     _node.accept(finder);
//     HashMap<ConstructorElement, ConstructorDeclaration> constructorMap = finder.constructorMap;
//     JUnitTestCase.assertNotNull(constructorMap);
//     return constructorMap;
//   }
//   List<InstanceCreationExpression> _findConstructorInvocations() {
//     ConstantFinder finder = new ConstantFinder();
//     _node.accept(finder);
//     List<InstanceCreationExpression> constructorInvocations = finder.constructorInvocations;
//     JUnitTestCase.assertNotNull(constructorInvocations);
//     return constructorInvocations;
//   }
//   HashMap<VariableElement, VariableDeclaration> _findVariableDeclarations() {
//     ConstantFinder finder = new ConstantFinder();
//     _node.accept(finder);
//     HashMap<VariableElement, VariableDeclaration> variableMap = finder.variableMap;
//     JUnitTestCase.assertNotNull(variableMap);
//     return variableMap;
//   }
//   ConstructorElement _setupConstructorDeclaration(String name, bool isConst) {
//     Keyword constKeyword = isConst ? Keyword.CONST : null;
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration2(constKeyword, null, null, name, AstFactory.formalParameterList([]), null, AstFactory.blockFunctionBody2([]));
//     ClassElement classElement = ElementFactory.classElement2(name, []);
//     ConstructorElement element = ElementFactory.constructorElement(classElement, name, isConst, []);
//     constructorDeclaration.element = element;
//     _node = constructorDeclaration;
//     return element;
//   }
//   void _setupInstanceCreationExpression(String name, bool isConst) {
//     _node = AstFactory.instanceCreationExpression2(isConst ? Keyword.CONST : null, AstFactory.typeName3(AstFactory.identifier3(name), []), []);
//   }
//   VariableElement _setupVariableDeclaration(String name, bool isConst, bool isInitialized) {
//     VariableDeclaration variableDeclaration = isInitialized ? AstFactory.variableDeclaration2(name, AstFactory.integer(0)) : AstFactory.variableDeclaration(name);
//     SimpleIdentifier identifier = variableDeclaration.name;
//     VariableElement element = ElementFactory.localVariableElement(identifier);
//     identifier.staticElement = element;
//     AstFactory.variableDeclarationList2(isConst ? Keyword.CONST : null, [variableDeclaration]);
//     _node = variableDeclaration;
//     return element;
//   }
//   static dartSuite() {
//     _ut.group('ConstantFinderTest', () {
//       _ut.test('test_visitConstructorDeclaration_const', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitConstructorDeclaration_const);
//       });
//       _ut.test('test_visitConstructorDeclaration_nonConst', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitConstructorDeclaration_nonConst);
//       });
//       _ut.test('test_visitInstanceCreationExpression_const', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitInstanceCreationExpression_const);
//       });
//       _ut.test('test_visitInstanceCreationExpression_nonConst', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitInstanceCreationExpression_nonConst);
//       });
//       _ut.test('test_visitVariableDeclaration_const', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_const);
//       });
//       _ut.test('test_visitVariableDeclaration_noInitializer', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_noInitializer);
//       });
//       _ut.test('test_visitVariableDeclaration_nonConst', () {
//         final __test = new ConstantFinderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_nonConst);
//       });
//     });
//   }
// }
// class ConstantValueComputerTest extends ResolverTestCase {
//   void test_computeValues_cycle() {
//     TestLogger logger = new TestLogger();
//     AnalysisEngine.instance.logger = logger;
//     Source librarySource = addSource(EngineTestCase.createSource([
//         "const int a = c;",
//         "const int b = a;",
//         "const int c = b;"]));
//     LibraryElement libraryElement = resolve(librarySource);
//     CompilationUnit unit = analysisContext.resolveCompilationUnit(librarySource, libraryElement);
//     analysisContext.computeErrors(librarySource);
//     JUnitTestCase.assertNotNull(unit);
//     ConstantValueComputer computer = _makeConstantValueComputer();
//     computer.add(unit);
//     computer.computeValues();
//     NodeList<CompilationUnitMember> members = unit.declarations;
//     EngineTestCase.assertSizeOfList(3, members);
//     _validate(false, (members[0] as TopLevelVariableDeclaration).variables);
//     _validate(false, (members[1] as TopLevelVariableDeclaration).variables);
//     _validate(false, (members[2] as TopLevelVariableDeclaration).variables);
//   }
//   void test_computeValues_dependentVariables() {
//     Source librarySource = addSource(EngineTestCase.createSource(["const int b = a;", "const int a = 0;"]));
//     LibraryElement libraryElement = resolve(librarySource);
//     CompilationUnit unit = analysisContext.resolveCompilationUnit(librarySource, libraryElement);
//     JUnitTestCase.assertNotNull(unit);
//     ConstantValueComputer computer = _makeConstantValueComputer();
//     computer.add(unit);
//     computer.computeValues();
//     NodeList<CompilationUnitMember> members = unit.declarations;
//     EngineTestCase.assertSizeOfList(2, members);
//     _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
//     _validate(true, (members[1] as TopLevelVariableDeclaration).variables);
//   }
//   void test_computeValues_empty() {
//     ConstantValueComputer computer = _makeConstantValueComputer();
//     computer.computeValues();
//   }
//   void test_computeValues_multipleSources() {
//     Source librarySource = addNamedSource("/lib.dart", EngineTestCase.createSource([
//         "library lib;",
//         "part 'part.dart';",
//         "const int c = b;",
//         "const int a = 0;"]));
//     Source partSource = addNamedSource("/part.dart", EngineTestCase.createSource(["part of lib;", "const int b = a;", "const int d = c;"]));
//     LibraryElement libraryElement = resolve(librarySource);
//     CompilationUnit libraryUnit = analysisContext.resolveCompilationUnit(librarySource, libraryElement);
//     JUnitTestCase.assertNotNull(libraryUnit);
//     CompilationUnit partUnit = analysisContext.resolveCompilationUnit(partSource, libraryElement);
//     JUnitTestCase.assertNotNull(partUnit);
//     ConstantValueComputer computer = _makeConstantValueComputer();
//     computer.add(libraryUnit);
//     computer.add(partUnit);
//     computer.computeValues();
//     NodeList<CompilationUnitMember> libraryMembers = libraryUnit.declarations;
//     EngineTestCase.assertSizeOfList(2, libraryMembers);
//     _validate(true, (libraryMembers[0] as TopLevelVariableDeclaration).variables);
//     _validate(true, (libraryMembers[1] as TopLevelVariableDeclaration).variables);
//     NodeList<CompilationUnitMember> partMembers = libraryUnit.declarations;
//     EngineTestCase.assertSizeOfList(2, partMembers);
//     _validate(true, (partMembers[0] as TopLevelVariableDeclaration).variables);
//     _validate(true, (partMembers[1] as TopLevelVariableDeclaration).variables);
//   }
//   void test_computeValues_singleVariable() {
//     Source librarySource = addSource("const int a = 0;");
//     LibraryElement libraryElement = resolve(librarySource);
//     CompilationUnit unit = analysisContext.resolveCompilationUnit(librarySource, libraryElement);
//     JUnitTestCase.assertNotNull(unit);
//     ConstantValueComputer computer = _makeConstantValueComputer();
//     computer.add(unit);
//     computer.computeValues();
//     NodeList<CompilationUnitMember> members = unit.declarations;
//     EngineTestCase.assertSizeOfList(1, members);
//     _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
//   }
//   void test_dependencyOnConstructor() {
//     // x depends on "const A()"
//     _assertProperDependencies(EngineTestCase.createSource(["class A {", "  const A();", "}", "const x = const A();"]), []);
//   }
//   void test_dependencyOnConstructorArgument() {
//     // "const A(x)" depends on x
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "  const A(this.next);",
//         "  final A next;",
//         "}",
//         "const A x = const A(null);",
//         "const A y = const A(x);"]), []);
//   }
//   void test_dependencyOnConstructorArgument_unresolvedConstructor() {
//     // "const A.a(x)" depends on x even if the constructor A.a can't be found.
//     // TODO(paulberry): the error CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE is redundant and
//     // probably shouldn't be issued.
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "}",
//         "const int x = 1;",
//         "const A y = const A.a(x);"]), [
//         CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE,
//         CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
//   }
//   void test_dependencyOnConstructorInitializer() {
//     // "const A()" depends on x
//     _assertProperDependencies(EngineTestCase.createSource([
//         "const int x = 1;",
//         "class A {",
//         "  const A() : v = x;",
//         "  final int v;",
//         "}"]), []);
//   }
//   void test_dependencyOnExplicitSuperConstructor() {
//     // b depends on B() depends on A()
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "  const A(this.x);",
//         "  final int x;",
//         "}",
//         "class B extends A {",
//         "  const B() : super(5);",
//         "}",
//         "const B b = const B();"]), []);
//   }
//   void test_dependencyOnExplicitSuperConstructorParameters() {
//     // b depends on B() depends on i
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "  const A(this.x);",
//         "  final int x;",
//         "}",
//         "class B extends A {",
//         "  const B() : super(i);",
//         "}",
//         "const B b = const B();",
//         "const int i = 5;"]), []);
//   }
//   void test_dependencyOnFactoryRedirect() {
//     // a depends on A.foo() depends on A.bar()
//     _assertProperDependencies(EngineTestCase.createSource([
//         "const A a = const A.foo();",
//         "class A {",
//         "  factory const A.foo() = A.bar;",
//         "  const A.bar();",
//         "}"]), []);
//   }
//   void test_dependencyOnFactoryRedirectWithTypeParams() {
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "  const factory A(var a) = B<int>;",
//         "}",
//         "",
//         "class B<T> implements A {",
//         "  final T x;",
//         "  const B(this.x);",
//         "}",
//         "",
//         "const A a = const A(10);"]), []);
//   }
//   void test_dependencyOnImplicitSuperConstructor() {
//     // b depends on B() depends on A()
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "  const A() : x = 5;",
//         "  final int x;",
//         "}",
//         "class B extends A {",
//         "  const B();",
//         "}",
//         "const B b = const B();"]), []);
//   }
//   void test_dependencyOnOptionalParameterDefault() {
//     // a depends on A() depends on B()
//     _assertProperDependencies(EngineTestCase.createSource([
//         "class A {",
//         "  const A([x = const B()]) : b = x;",
//         "  final B b;",
//         "}",
//         "class B {",
//         "  const B();",
//         "}",
//         "const A a = const A();"]), []);
//   }
//   void test_dependencyOnVariable() {
//     // x depends on y
//     _assertProperDependencies(EngineTestCase.createSource(["const x = y + 1;", "const y = 2;"]), []);
//   }
//   void test_fromEnvironment_bool_default_false() {
//     JUnitTestCase.assertEquals(false, _assertValidBool(_check_fromEnvironment_bool(null, "false")));
//   }
//   void test_fromEnvironment_bool_default_overridden() {
//     JUnitTestCase.assertEquals(false, _assertValidBool(_check_fromEnvironment_bool("false", "true")));
//   }
//   void test_fromEnvironment_bool_default_parseError() {
//     JUnitTestCase.assertEquals(true, _assertValidBool(_check_fromEnvironment_bool("parseError", "true")));
//   }
//   void test_fromEnvironment_bool_default_true() {
//     JUnitTestCase.assertEquals(true, _assertValidBool(_check_fromEnvironment_bool(null, "true")));
//   }
//   void test_fromEnvironment_bool_false() {
//     JUnitTestCase.assertEquals(false, _assertValidBool(_check_fromEnvironment_bool("false", null)));
//   }
//   void test_fromEnvironment_bool_parseError() {
//     JUnitTestCase.assertEquals(false, _assertValidBool(_check_fromEnvironment_bool("parseError", null)));
//   }
//   void test_fromEnvironment_bool_true() {
//     JUnitTestCase.assertEquals(true, _assertValidBool(_check_fromEnvironment_bool("true", null)));
//   }
//   void test_fromEnvironment_bool_undeclared() {
//     _assertValidUnknown(_check_fromEnvironment_bool(null, null));
//   }
//   void test_fromEnvironment_int_default_overridden() {
//     JUnitTestCase.assertEquals(234, _assertValidInt(_check_fromEnvironment_int("234", "123")));
//   }
//   void test_fromEnvironment_int_default_parseError() {
//     JUnitTestCase.assertEquals(123, _assertValidInt(_check_fromEnvironment_int("parseError", "123")));
//   }
//   void test_fromEnvironment_int_default_undeclared() {
//     JUnitTestCase.assertEquals(123, _assertValidInt(_check_fromEnvironment_int(null, "123")));
//   }
//   void test_fromEnvironment_int_ok() {
//     JUnitTestCase.assertEquals(234, _assertValidInt(_check_fromEnvironment_int("234", null)));
//   }
//   void test_fromEnvironment_int_parseError() {
//     _assertValidNull(_check_fromEnvironment_int("parseError", null));
//   }
//   void test_fromEnvironment_int_parseError_nullDefault() {
//     _assertValidNull(_check_fromEnvironment_int("parseError", "null"));
//   }
//   void test_fromEnvironment_int_undeclared() {
//     _assertValidUnknown(_check_fromEnvironment_int(null, null));
//   }
//   void test_fromEnvironment_int_undeclared_nullDefault() {
//     _assertValidNull(_check_fromEnvironment_int(null, "null"));
//   }
//   void test_fromEnvironment_string_default_overridden() {
//     JUnitTestCase.assertEquals("abc", _assertValidString(_check_fromEnvironment_string("abc", "'def'")));
//   }
//   void test_fromEnvironment_string_default_undeclared() {
//     JUnitTestCase.assertEquals("def", _assertValidString(_check_fromEnvironment_string(null, "'def'")));
//   }
//   void test_fromEnvironment_string_empty() {
//     JUnitTestCase.assertEquals("", _assertValidString(_check_fromEnvironment_string("", null)));
//   }
//   void test_fromEnvironment_string_ok() {
//     JUnitTestCase.assertEquals("abc", _assertValidString(_check_fromEnvironment_string("abc", null)));
//   }
//   void test_fromEnvironment_string_undeclared() {
//     _assertValidUnknown(_check_fromEnvironment_string(null, null));
//   }
//   void test_fromEnvironment_string_undeclared_nullDefault() {
//     _assertValidNull(_check_fromEnvironment_string(null, "null"));
//   }
//   void test_instanceCreationExpression_computedField() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A(4, 5);",
//         "class A {",
//         "  const A(int i, int j) : k = 2 * i + j;",
//         "  final int k;",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "A");
//     EngineTestCase.assertSizeOfMap(1, fields);
//     _assertIntField(fields, "k", 13);
//   }
//   void test_instanceCreationExpression_computedField_namedOptionalWithDefault() {
//     _checkInstanceCreationOptionalParams(false, true, true);
//   }
//   void test_instanceCreationExpression_computedField_namedOptionalWithoutDefault() {
//     _checkInstanceCreationOptionalParams(false, true, false);
//   }
//   void test_instanceCreationExpression_computedField_unnamedOptionalWithDefault() {
//     _checkInstanceCreationOptionalParams(false, false, true);
//   }
//   void test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault() {
//     _checkInstanceCreationOptionalParams(false, false, false);
//   }
//   void test_instanceCreationExpression_computedField_usesConstConstructor() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A(3);",
//         "class A {",
//         "  const A(int i) : b = const B(4);",
//         "  final int b;",
//         "}",
//         "class B {",
//         "  const B(this.k);",
//         "  final int k;",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fieldsOfA = _assertType(result, "A");
//     EngineTestCase.assertSizeOfMap(1, fieldsOfA);
//     HashMap<String, DartObjectImpl> fieldsOfB = _assertFieldType(fieldsOfA, "b", "B");
//     EngineTestCase.assertSizeOfMap(1, fieldsOfB);
//     _assertIntField(fieldsOfB, "k", 4);
//   }
//   void test_instanceCreationExpression_computedField_usesStaticConst() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A(3);",
//         "class A {",
//         "  const A(int i) : k = i + B.bar;",
//         "  final int k;",
//         "}",
//         "class B {",
//         "  static const bar = 4;",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "A");
//     EngineTestCase.assertSizeOfMap(1, fields);
//     _assertIntField(fields, "k", 7);
//   }
//   void test_instanceCreationExpression_computedField_usesToplevelConst() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A(3);",
//         "const bar = 4;",
//         "class A {",
//         "  const A(int i) : k = i + bar;",
//         "  final int k;",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "A");
//     EngineTestCase.assertSizeOfMap(1, fields);
//     _assertIntField(fields, "k", 7);
//   }
//   void test_instanceCreationExpression_explicitSuper() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const B(4, 5);",
//         "class A {",
//         "  const A(this.x);",
//         "  final int x;",
//         "}",
//         "class B extends A {",
//         "  const B(int x, this.y) : super(x * 2);",
//         "  final int y;",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "B");
//     EngineTestCase.assertSizeOfMap(2, fields);
//     _assertIntField(fields, "y", 5);
//     HashMap<String, DartObjectImpl> superclassFields = _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
//     EngineTestCase.assertSizeOfMap(1, superclassFields);
//     _assertIntField(superclassFields, "x", 8);
//   }
//   void test_instanceCreationExpression_fieldFormalParameter() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A(42);",
//         "class A {",
//         "  int x;",
//         "  const A(this.x)",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "A");
//     EngineTestCase.assertSizeOfMap(1, fields);
//     _assertIntField(fields, "x", 42);
//   }
//   void test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault() {
//     _checkInstanceCreationOptionalParams(true, true, true);
//   }
//   void test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault() {
//     _checkInstanceCreationOptionalParams(true, true, false);
//   }
//   void test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault() {
//     _checkInstanceCreationOptionalParams(true, false, true);
//   }
//   void test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault() {
//     _checkInstanceCreationOptionalParams(true, false, false);
//   }
//   void test_instanceCreationExpression_implicitSuper() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const B(4);",
//         "class A {",
//         "  const A() : x(3);",
//         "  final int x;",
//         "}",
//         "class B extends A {",
//         "  const B(this.y);",
//         "  final int y;",
//         "}"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "B");
//     EngineTestCase.assertSizeOfMap(2, fields);
//     _assertIntField(fields, "y", 4);
//     HashMap<String, DartObjectImpl> superclassFields = _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
//     EngineTestCase.assertSizeOfMap(1, superclassFields);
//     _assertIntField(superclassFields, "x", 3);
//   }
//   void test_instanceCreationExpression_redirect() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A();",
//         "class A {",
//         "  const factory A() = B;",
//         "}",
//         "class B implements A {",
//         "  const B();",
//         "}"]));
//     _assertType(_evaluateInstanceCreationExpression(compilationUnit, "foo"), "B");
//   }
//   void test_instanceCreationExpression_redirect_cycle() {
//     // It is an error to have a cycle in factory redirects; however, we need
//     // to make sure that even if the error occurs, attempting to evaluate the
//     // constant will terminate.
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A();",
//         "class A {",
//         "  const factory A() = A.b;",
//         "  const factory A.b() = A;",
//         "}"]));
//     _assertValidUnknown(_evaluateInstanceCreationExpression(compilationUnit, "foo"));
//   }
//   void test_instanceCreationExpression_redirect_extern() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A();",
//         "class A {",
//         "  external const factory A();",
//         "}"]));
//     _assertValidUnknown(_evaluateInstanceCreationExpression(compilationUnit, "foo"));
//   }
//   void test_instanceCreationExpression_redirect_nonConst() {
//     // It is an error for a const factory constructor redirect to a non-const
//     // constructor; however, we need to make sure that even if the error
//     // attempting to evaluate the constant won't cause a crash.
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const foo = const A();",
//         "class A {",
//         "  const factory A() = A.b;",
//         "  A.b();",
//         "}"]));
//     _assertValidUnknown(_evaluateInstanceCreationExpression(compilationUnit, "foo"));
//   }
//   void test_instanceCreationExpression_redirectWithTypeParams() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "class A {",
//         "  const factory A(var a) = B<int>;",
//         "}",
//         "",
//         "class B<T> implements A {",
//         "  final T x;",
//         "  const B(this.x);",
//         "}",
//         "",
//         "const A a = const A(10);"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "a");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "B<int>");
//     EngineTestCase.assertSizeOfMap(1, fields);
//     _assertIntField(fields, "x", 10);
//   }
//   void test_instanceCreationExpression_redirectWithTypeSubstitution() {
//     // To evaluate the redirection of A<int>, A's template argument (T=int) must be substituted
//     // into B's template argument (B<U> where U=T) to get B<int>.
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "class A<T> {",
//         "  const factory A(var a) = B<T>;",
//         "}",
//         "",
//         "class B<U> implements A {",
//         "  final U x;",
//         "  const B(this.x);",
//         "}",
//         "",
//         "const A<int> a = const A<int>(10);"]));
//     EvaluationResultImpl result = _evaluateInstanceCreationExpression(compilationUnit, "a");
//     HashMap<String, DartObjectImpl> fields = _assertType(result, "B<int>");
//     EngineTestCase.assertSizeOfMap(1, fields);
//     _assertIntField(fields, "x", 10);
//   }
//   void test_instanceCreationExpression_symbol() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const foo = const Symbol('a');"]));
//     EvaluationResultImpl evaluationResult = _evaluateInstanceCreationExpression(compilationUnit, "foo");
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, evaluationResult);
//     DartObjectImpl value = (evaluationResult as ValidResult).value;
//     JUnitTestCase.assertEquals(typeProvider.symbolType, value.type);
//     JUnitTestCase.assertEquals("a", value.value);
//   }
//   void test_instanceCreationExpression_withSupertypeParams_explicit() {
//     _checkInstanceCreation_withSupertypeParams(true);
//   }
//   void test_instanceCreationExpression_withSupertypeParams_implicit() {
//     _checkInstanceCreation_withSupertypeParams(false);
//   }
//   void test_instanceCreationExpression_withTypeParams() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "class C<E> {",
//         "  const C();",
//         "}",
//         "const c_int = const C<int>();",
//         "const c_num = const C<num>();"]));
//     EvaluationResultImpl c_int = _evaluateInstanceCreationExpression(compilationUnit, "c_int");
//     _assertType(c_int, "C<int>");
//     DartObjectImpl c_int_value = (c_int as ValidResult).value;
//     EvaluationResultImpl c_num = _evaluateInstanceCreationExpression(compilationUnit, "c_num");
//     _assertType(c_num, "C<num>");
//     DartObjectImpl c_num_value = (c_num as ValidResult).value;
//     JUnitTestCase.assertFalse(c_int_value == c_num_value);
//   }
//   void test_isValidSymbol() {
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol(""));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo.bar"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo\$"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo\$bar"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("iff"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("gif"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("if\$"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("\$if"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo="));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo.bar="));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("foo.+"));
//     JUnitTestCase.assertTrue(ConstantValueComputer.isValidPublicSymbol("void"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("_foo"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("_foo.bar"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("foo._bar"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("if"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("if.foo"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("foo.if"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("foo=.bar"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("foo."));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("+.foo"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("void.foo"));
//     JUnitTestCase.assertFalse(ConstantValueComputer.isValidPublicSymbol("foo.void"));
//   }
//   void test_symbolLiteral_void() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const voidSymbol = #void;"]));
//     VariableDeclaration voidSymbol = findTopLevelDeclaration(compilationUnit, "voidSymbol");
//     EvaluationResultImpl voidSymbolResult = (voidSymbol.element as VariableElementImpl).evaluationResult;
//     DartObjectImpl value = (voidSymbolResult as ValidResult).value;
//     JUnitTestCase.assertEquals(typeProvider.symbolType, value.type);
//     JUnitTestCase.assertEquals("void", value.value);
//   }
//   HashMap<String, DartObjectImpl> _assertFieldType(HashMap<String, DartObjectImpl> fields, String fieldName, String expectedType) {
//     DartObjectImpl field = fields[fieldName];
//     JUnitTestCase.assertEquals(expectedType, field.type.displayName);
//     return field.fields;
//   }
//   void _assertIntField(HashMap<String, DartObjectImpl> fields, String fieldName, int expectedValue) {
//     DartObjectImpl field = fields[fieldName];
//     JUnitTestCase.assertEquals("int", field.type.name);
//     JUnitTestCase.assertEquals(expectedValue, field.intValue.longValue());
//   }
//   void _assertNullField(HashMap<String, DartObjectImpl> fields, String fieldName) {
//     DartObjectImpl field = fields[fieldName];
//     JUnitTestCase.assertTrue(field.isNull);
//   }
//   void _assertProperDependencies(String sourceText, List<ErrorCode> expectedErrorCodes) {
//     Source source = addSource(sourceText);
//     LibraryElement element = resolve(source);
//     CompilationUnit unit = analysisContext.resolveCompilationUnit(source, element);
//     JUnitTestCase.assertNotNull(unit);
//     ConstantValueComputer computer = _makeConstantValueComputer();
//     computer.add(unit);
//     computer.computeValues();
//     assertErrors(source, expectedErrorCodes);
//   }
//   HashMap<String, DartObjectImpl> _assertType(EvaluationResultImpl result, String typeName) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertEquals(typeName, value.type.displayName);
//     return value.fields;
//   }
//   bool _assertValidBool(EvaluationResultImpl result) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertEquals(typeProvider.boolType, value.type);
//     bool boolValue = value.boolValue;
//     JUnitTestCase.assertNotNull(boolValue);
//     return boolValue;
//   }
//   int _assertValidInt(EvaluationResultImpl result) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertEquals(typeProvider.intType, value.type);
//     return value.intValue;
//   }
//   void _assertValidNull(EvaluationResultImpl result) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertEquals(typeProvider.nullType, value.type);
//   }
//   String _assertValidString(EvaluationResultImpl result) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertEquals(typeProvider.stringType, value.type);
//     return value.stringValue;
//   }
//   void _assertValidUnknown(EvaluationResultImpl result) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertTrue(value.isUnknown);
//   }
//   EvaluationResultImpl _check_fromEnvironment_bool(String valueInEnvironment, String defaultExpr) {
//     String envVarName = "x";
//     String varName = "foo";
//     if (valueInEnvironment != null) {
//       analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
//     }
//     String defaultArg = defaultExpr == null ? "" : ", defaultValue: ${defaultExpr}";
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const ${varName} = const bool.fromEnvironment('${envVarName}'${defaultArg});"]));
//     return _evaluateInstanceCreationExpression(compilationUnit, varName);
//   }
//   EvaluationResultImpl _check_fromEnvironment_int(String valueInEnvironment, String defaultExpr) {
//     String envVarName = "x";
//     String varName = "foo";
//     if (valueInEnvironment != null) {
//       analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
//     }
//     String defaultArg = defaultExpr == null ? "" : ", defaultValue: ${defaultExpr}";
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const ${varName} = const int.fromEnvironment('${envVarName}'${defaultArg});"]));
//     return _evaluateInstanceCreationExpression(compilationUnit, varName);
//   }
//   EvaluationResultImpl _check_fromEnvironment_string(String valueInEnvironment, String defaultExpr) {
//     String envVarName = "x";
//     String varName = "foo";
//     if (valueInEnvironment != null) {
//       analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
//     }
//     String defaultArg = defaultExpr == null ? "" : ", defaultValue: ${defaultExpr}";
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const ${varName} = const String.fromEnvironment('${envVarName}'${defaultArg});"]));
//     return _evaluateInstanceCreationExpression(compilationUnit, varName);
//   }
//   void _checkInstanceCreation_withSupertypeParams(bool isExplicit) {
//     String superCall = isExplicit ? " : super()" : "";
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "class A<T> {",
//         "  const A();",
//         "}",
//         "class B<T, U> extends A<T> {",
//         "  const B()${superCall};",
//         "}",
//         "class C<T, U> extends A<U> {",
//         "  const C()${superCall};",
//         "}",
//         "const b_int_num = const B<int, num>();",
//         "const c_int_num = const C<int, num>();"]));
//     EvaluationResultImpl b_int_num = _evaluateInstanceCreationExpression(compilationUnit, "b_int_num");
//     HashMap<String, DartObjectImpl> b_int_num_fields = _assertType(b_int_num, "B<int, num>");
//     _assertFieldType(b_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<int>");
//     EvaluationResultImpl c_int_num = _evaluateInstanceCreationExpression(compilationUnit, "c_int_num");
//     HashMap<String, DartObjectImpl> c_int_num_fields = _assertType(c_int_num, "C<int, num>");
//     _assertFieldType(c_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<num>");
//   }
//   void _checkInstanceCreationOptionalParams(bool isFieldFormal, bool isNamed, bool hasDefault) {
//     String fieldName = "j";
//     String paramName = isFieldFormal ? fieldName : "i";
//     String formalParam = "${(isFieldFormal ? "this." : "int ")}${paramName}${(hasDefault ? " = 3" : "")}";
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource([
//         "const x = const A();",
//         "const y = const A(${(isNamed ? "${paramName}: " : "")}10);",
//         "class A {",
//         "  const A(${(isNamed ? "{${formalParam}}" : "[${formalParam}]")})${(isFieldFormal ? "" : " : ${fieldName} = ${paramName}")};",
//         "  final int ${fieldName};",
//         "}"]));
//     EvaluationResultImpl x = _evaluateInstanceCreationExpression(compilationUnit, "x");
//     HashMap<String, DartObjectImpl> fieldsOfX = _assertType(x, "A");
//     EngineTestCase.assertSizeOfMap(1, fieldsOfX);
//     if (hasDefault) {
//       _assertIntField(fieldsOfX, fieldName, 3);
//     } else {
//       _assertNullField(fieldsOfX, fieldName);
//     }
//     EvaluationResultImpl y = _evaluateInstanceCreationExpression(compilationUnit, "y");
//     HashMap<String, DartObjectImpl> fieldsOfY = _assertType(y, "A");
//     EngineTestCase.assertSizeOfMap(1, fieldsOfY);
//     _assertIntField(fieldsOfY, fieldName, 10);
//   }
//   EvaluationResultImpl _evaluateInstanceCreationExpression(CompilationUnit compilationUnit, String name) {
//     Expression expression = findTopLevelConstantExpression(compilationUnit, name);
//     return (expression as InstanceCreationExpression).evaluationResult;
//   }
//   ConstantValueComputer _makeConstantValueComputer() => new ConstantValueComputerTest_ValidatingConstantValueComputer(new TestTypeProvider(), analysisContext2.declaredVariables);
//   void _validate(bool shouldBeValid, VariableDeclarationList declarationList) {
//     for (VariableDeclaration declaration in declarationList.variables) {
//       VariableElementImpl element = declaration.element as VariableElementImpl;
//       JUnitTestCase.assertNotNull(element);
//       EvaluationResultImpl result = element.evaluationResult;
//       if (shouldBeValid) {
//         EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//         Object value = (result as ValidResult).value;
//         JUnitTestCase.assertNotNull(value);
//       } else {
//         EngineTestCase.assertInstanceOf((obj) => obj is ErrorResult, ErrorResult, result);
//       }
//     }
//   }
//   static dartSuite() {
//     _ut.group('ConstantValueComputerTest', () {
//       _ut.test('test_computeValues_cycle', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_computeValues_cycle);
//       });
//       _ut.test('test_computeValues_dependentVariables', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_computeValues_dependentVariables);
//       });
//       _ut.test('test_computeValues_empty', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_computeValues_empty);
//       });
//       _ut.test('test_computeValues_multipleSources', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_computeValues_multipleSources);
//       });
//       _ut.test('test_computeValues_singleVariable', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_computeValues_singleVariable);
//       });
//       _ut.test('test_dependencyOnConstructor', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnConstructor);
//       });
//       _ut.test('test_dependencyOnConstructorArgument', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnConstructorArgument);
//       });
//       _ut.test('test_dependencyOnConstructorArgument_unresolvedConstructor', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnConstructorArgument_unresolvedConstructor);
//       });
//       _ut.test('test_dependencyOnConstructorInitializer', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnConstructorInitializer);
//       });
//       _ut.test('test_dependencyOnExplicitSuperConstructor', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnExplicitSuperConstructor);
//       });
//       _ut.test('test_dependencyOnExplicitSuperConstructorParameters', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnExplicitSuperConstructorParameters);
//       });
//       _ut.test('test_dependencyOnFactoryRedirect', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnFactoryRedirect);
//       });
//       _ut.test('test_dependencyOnFactoryRedirectWithTypeParams', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnFactoryRedirectWithTypeParams);
//       });
//       _ut.test('test_dependencyOnImplicitSuperConstructor', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnImplicitSuperConstructor);
//       });
//       _ut.test('test_dependencyOnOptionalParameterDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnOptionalParameterDefault);
//       });
//       _ut.test('test_dependencyOnVariable', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_dependencyOnVariable);
//       });
//       _ut.test('test_fromEnvironment_bool_default_false', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_default_false);
//       });
//       _ut.test('test_fromEnvironment_bool_default_overridden', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_default_overridden);
//       });
//       _ut.test('test_fromEnvironment_bool_default_parseError', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_default_parseError);
//       });
//       _ut.test('test_fromEnvironment_bool_default_true', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_default_true);
//       });
//       _ut.test('test_fromEnvironment_bool_false', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_false);
//       });
//       _ut.test('test_fromEnvironment_bool_parseError', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_parseError);
//       });
//       _ut.test('test_fromEnvironment_bool_true', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_true);
//       });
//       _ut.test('test_fromEnvironment_bool_undeclared', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_bool_undeclared);
//       });
//       _ut.test('test_fromEnvironment_int_default_overridden', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_default_overridden);
//       });
//       _ut.test('test_fromEnvironment_int_default_parseError', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_default_parseError);
//       });
//       _ut.test('test_fromEnvironment_int_default_undeclared', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_default_undeclared);
//       });
//       _ut.test('test_fromEnvironment_int_ok', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_ok);
//       });
//       _ut.test('test_fromEnvironment_int_parseError', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_parseError);
//       });
//       _ut.test('test_fromEnvironment_int_parseError_nullDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_parseError_nullDefault);
//       });
//       _ut.test('test_fromEnvironment_int_undeclared', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_undeclared);
//       });
//       _ut.test('test_fromEnvironment_int_undeclared_nullDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_int_undeclared_nullDefault);
//       });
//       _ut.test('test_fromEnvironment_string_default_overridden', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_string_default_overridden);
//       });
//       _ut.test('test_fromEnvironment_string_default_undeclared', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_string_default_undeclared);
//       });
//       _ut.test('test_fromEnvironment_string_empty', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_string_empty);
//       });
//       _ut.test('test_fromEnvironment_string_ok', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_string_ok);
//       });
//       _ut.test('test_fromEnvironment_string_undeclared', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_string_undeclared);
//       });
//       _ut.test('test_fromEnvironment_string_undeclared_nullDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_fromEnvironment_string_undeclared_nullDefault);
//       });
//       _ut.test('test_instanceCreationExpression_computedField', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_namedOptionalWithDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_namedOptionalWithDefault);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_namedOptionalWithoutDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_namedOptionalWithoutDefault);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_unnamedOptionalWithDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_unnamedOptionalWithDefault);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_usesConstConstructor', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_usesConstConstructor);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_usesStaticConst', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_usesStaticConst);
//       });
//       _ut.test('test_instanceCreationExpression_computedField_usesToplevelConst', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_computedField_usesToplevelConst);
//       });
//       _ut.test('test_instanceCreationExpression_explicitSuper', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_explicitSuper);
//       });
//       _ut.test('test_instanceCreationExpression_fieldFormalParameter', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_fieldFormalParameter);
//       });
//       _ut.test('test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault);
//       });
//       _ut.test('test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault);
//       });
//       _ut.test('test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault);
//       });
//       _ut.test('test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault);
//       });
//       _ut.test('test_instanceCreationExpression_implicitSuper', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_implicitSuper);
//       });
//       _ut.test('test_instanceCreationExpression_redirect', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_redirect);
//       });
//       _ut.test('test_instanceCreationExpression_redirectWithTypeParams', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_redirectWithTypeParams);
//       });
//       _ut.test('test_instanceCreationExpression_redirectWithTypeSubstitution', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_redirectWithTypeSubstitution);
//       });
//       _ut.test('test_instanceCreationExpression_redirect_cycle', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_redirect_cycle);
//       });
//       _ut.test('test_instanceCreationExpression_redirect_extern', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_redirect_extern);
//       });
//       _ut.test('test_instanceCreationExpression_redirect_nonConst', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_redirect_nonConst);
//       });
//       _ut.test('test_instanceCreationExpression_symbol', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_symbol);
//       });
//       _ut.test('test_instanceCreationExpression_withSupertypeParams_explicit', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_withSupertypeParams_explicit);
//       });
//       _ut.test('test_instanceCreationExpression_withSupertypeParams_implicit', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_withSupertypeParams_implicit);
//       });
//       _ut.test('test_instanceCreationExpression_withTypeParams', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_withTypeParams);
//       });
//       _ut.test('test_isValidSymbol', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_isValidSymbol);
//       });
//       _ut.test('test_symbolLiteral_void', () {
//         final __test = new ConstantValueComputerTest();
//         runJUnitTest(__test, __test.test_symbolLiteral_void);
//       });
//     });
//   }
// }
// class ConstantValueComputerTest_ValidatingConstantValueComputer extends ConstantValueComputer {
//   AstNode _nodeBeingEvaluated;
//   ConstantValueComputerTest_ValidatingConstantValueComputer(TypeProvider typeProvider, DeclaredVariables declaredVariables) : super(typeProvider, declaredVariables);
//   @override
//   void beforeComputeValue(AstNode constNode) {
//     super.beforeComputeValue(constNode);
//     _nodeBeingEvaluated = constNode;
//   }
//   @override
//   void beforeGetConstantInitializers(ConstructorElement constructor) {
//     super.beforeGetConstantInitializers(constructor);
//     // If we are getting the constant initializers for a node in the graph, make sure we properly
//     // recorded the dependency.
//     ConstructorDeclaration node = findConstructorDeclaration(constructor);
//     if (node != null && referenceGraph.nodes.contains(node)) {
//       JUnitTestCase.assertTrue(referenceGraph.containsPath(_nodeBeingEvaluated, node));
//     }
//   }
//   @override
//   void beforeGetParameterDefault(ParameterElement parameter) {
//     super.beforeGetParameterDefault(parameter);
//     // Find the ConstructorElement and figure out which parameter we're talking about.
//     ConstructorElement constructor = parameter.getAncestor((element) => element is ConstructorElement);
//     int parameterIndex;
//     List<ParameterElement> parameters = constructor.parameters;
//     int numParameters = parameters.length;
//     for (parameterIndex = 0; parameterIndex < numParameters; parameterIndex++) {
//       if (identical(parameters[parameterIndex], parameter)) {
//         break;
//       }
//     }
//     JUnitTestCase.assertTrue(parameterIndex < numParameters);
//     // If we are getting the default parameter for a constructor in the graph, make sure we properly
//     // recorded the dependency on the parameter.
//     ConstructorDeclaration constructorNode = constructorDeclarationMap[constructor];
//     if (constructorNode != null) {
//       FormalParameter parameterNode = constructorNode.parameters.parameters[parameterIndex];
//       JUnitTestCase.assertTrue(referenceGraph.nodes.contains(parameterNode));
//       JUnitTestCase.assertTrue(referenceGraph.containsPath(_nodeBeingEvaluated, parameterNode));
//     }
//   }
//   @override
//   ConstantVisitor createConstantVisitor() => new ConstantValueComputerTest_ValidatingConstantVisitor(typeProvider, referenceGraph, _nodeBeingEvaluated);
// }
// class ConstantValueComputerTest_ValidatingConstantVisitor extends ConstantVisitor {
//   final DirectedGraph<AstNode> _referenceGraph;
//   final AstNode _nodeBeingEvaluated;
//   ConstantValueComputerTest_ValidatingConstantVisitor(TypeProvider typeProvider, this._referenceGraph, this._nodeBeingEvaluated) : super.con1(typeProvider);
//   @override
//   void beforeGetEvaluationResult(AstNode node) {
//     super.beforeGetEvaluationResult(node);
//     // If we are getting the evaluation result for a node in the graph, make sure we properly
//     // recorded the dependency.
//     if (_referenceGraph.nodes.contains(node)) {
//       JUnitTestCase.assertTrue(_referenceGraph.containsPath(_nodeBeingEvaluated, node));
//     }
//   }
// }
// class ConstantVisitorTest extends ResolverTestCase {
//   void test_visitConditionalExpression_false() {
//     Expression thenExpression = AstFactory.integer(1);
//     Expression elseExpression = AstFactory.integer(0);
//     ConditionalExpression expression = AstFactory.conditionalExpression(AstFactory.booleanLiteral(false), thenExpression, elseExpression);
//     _assertValue(0, expression.accept(new ConstantVisitor.con1(new TestTypeProvider())));
//   }
//   void test_visitConditionalExpression_instanceCreation_invalidFieldInitializer() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     LibraryElementImpl libraryElement = ElementFactory.library(null, "lib");
//     String className = "C";
//     ClassElementImpl classElement = ElementFactory.classElement2(className, []);
//     (libraryElement.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
//     ConstructorElementImpl constructorElement = ElementFactory.constructorElement(classElement, null, true, [typeProvider.intType]);
//     constructorElement.parameters[0] = new FieldFormalParameterElementImpl(AstFactory.identifier3("x"));
//     InstanceCreationExpression expression = AstFactory.instanceCreationExpression2(Keyword.CONST, AstFactory.typeName4(className, []), [AstFactory.integer(0)]);
//     expression.staticElement = constructorElement;
//     expression.accept(new ConstantVisitor.con1(typeProvider));
//   }
//   void test_visitConditionalExpression_nonBooleanCondition() {
//     Expression thenExpression = AstFactory.integer(1);
//     Expression elseExpression = AstFactory.integer(0);
//     ConditionalExpression expression = AstFactory.conditionalExpression(AstFactory.nullLiteral(), thenExpression, elseExpression);
//     EvaluationResultImpl result = expression.accept(new ConstantVisitor.con1(new TestTypeProvider()));
//     EngineTestCase.assertInstanceOf((obj) => obj is ErrorResult, ErrorResult, result);
//   }
//   void test_visitConditionalExpression_nonConstantElse() {
//     Expression thenExpression = AstFactory.integer(1);
//     Expression elseExpression = AstFactory.identifier3("x");
//     ConditionalExpression expression = AstFactory.conditionalExpression(AstFactory.booleanLiteral(true), thenExpression, elseExpression);
//     EvaluationResultImpl result = expression.accept(new ConstantVisitor.con1(new TestTypeProvider()));
//     EngineTestCase.assertInstanceOf((obj) => obj is ErrorResult, ErrorResult, result);
//   }
//   void test_visitConditionalExpression_nonConstantThen() {
//     Expression thenExpression = AstFactory.identifier3("x");
//     Expression elseExpression = AstFactory.integer(0);
//     ConditionalExpression expression = AstFactory.conditionalExpression(AstFactory.booleanLiteral(true), thenExpression, elseExpression);
//     EvaluationResultImpl result = expression.accept(new ConstantVisitor.con1(new TestTypeProvider()));
//     EngineTestCase.assertInstanceOf((obj) => obj is ErrorResult, ErrorResult, result);
//   }
//   void test_visitConditionalExpression_true() {
//     Expression thenExpression = AstFactory.integer(1);
//     Expression elseExpression = AstFactory.integer(0);
//     ConditionalExpression expression = AstFactory.conditionalExpression(AstFactory.booleanLiteral(true), thenExpression, elseExpression);
//     _assertValue(1, expression.accept(new ConstantVisitor.con1(new TestTypeProvider())));
//   }
//   void test_visitSimpleIdentifier_inEnvironment() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const a = b;", "const b = 3;"]));
//     HashMap<String, DartObjectImpl> environment = new HashMap<String, DartObjectImpl>();
//     DartObjectImpl six = new DartObjectImpl(typeProvider.intType, new IntState(6));
//     environment["b"] = six;
//     _assertValue(6, _evaluateConstant(compilationUnit, "a", environment));
//   }
//   void test_visitSimpleIdentifier_notInEnvironment() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const a = b;", "const b = 3;"]));
//     HashMap<String, DartObjectImpl> environment = new HashMap<String, DartObjectImpl>();
//     DartObjectImpl six = new DartObjectImpl(typeProvider.intType, new IntState(6));
//     environment["c"] = six;
//     _assertValue(3, _evaluateConstant(compilationUnit, "a", environment));
//   }
//   void test_visitSimpleIdentifier_withoutEnvironment() {
//     CompilationUnit compilationUnit = resolveSource(EngineTestCase.createSource(["const a = b;", "const b = 3;"]));
//     _assertValue(3, _evaluateConstant(compilationUnit, "a", null));
//   }
//   void _assertValue(int expectedValue, EvaluationResultImpl result) {
//     EngineTestCase.assertInstanceOf((obj) => obj is ValidResult, ValidResult, result);
//     DartObjectImpl value = (result as ValidResult).value;
//     JUnitTestCase.assertEquals("int", value.type.name);
//     JUnitTestCase.assertEquals(expectedValue, value.intValue.longValue());
//   }
//   EvaluationResultImpl _evaluateConstant(CompilationUnit compilationUnit, String name, HashMap<String, DartObjectImpl> lexicalEnvironment) {
//     Expression expression = findTopLevelConstantExpression(compilationUnit, name);
//     return expression.accept(new ConstantVisitor.con2(typeProvider, lexicalEnvironment));
//   }
//   static dartSuite() {
//     _ut.group('ConstantVisitorTest', () {
//       _ut.test('test_visitConditionalExpression_false', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitConditionalExpression_false);
//       });
//       _ut.test('test_visitConditionalExpression_instanceCreation_invalidFieldInitializer', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitConditionalExpression_instanceCreation_invalidFieldInitializer);
//       });
//       _ut.test('test_visitConditionalExpression_nonBooleanCondition', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitConditionalExpression_nonBooleanCondition);
//       });
//       _ut.test('test_visitConditionalExpression_nonConstantElse', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitConditionalExpression_nonConstantElse);
//       });
//       _ut.test('test_visitConditionalExpression_nonConstantThen', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitConditionalExpression_nonConstantThen);
//       });
//       _ut.test('test_visitConditionalExpression_true', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitConditionalExpression_true);
//       });
//       _ut.test('test_visitSimpleIdentifier_inEnvironment', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitSimpleIdentifier_inEnvironment);
//       });
//       _ut.test('test_visitSimpleIdentifier_notInEnvironment', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitSimpleIdentifier_notInEnvironment);
//       });
//       _ut.test('test_visitSimpleIdentifier_withoutEnvironment', () {
//         final __test = new ConstantVisitorTest();
//         runJUnitTest(__test, __test.test_visitSimpleIdentifier_withoutEnvironment);
//       });
//     });
//   }
// }
// class ContentCacheTest extends JUnitTestCase {
//   void test_setContents() {
//     Source source = new TestSource();
//     ContentCache cache = new ContentCache();
//     JUnitTestCase.assertNull(cache.getContents(source));
//     JUnitTestCase.assertNull(cache.getModificationStamp(source));
//     String contents = "library lib;";
//     JUnitTestCase.assertNull(cache.setContents(source, contents));
//     JUnitTestCase.assertEquals(contents, cache.getContents(source));
//     JUnitTestCase.assertNotNull(cache.getModificationStamp(source));
//     JUnitTestCase.assertEquals(contents, cache.setContents(source, contents));
//     JUnitTestCase.assertEquals(contents, cache.setContents(source, null));
//     JUnitTestCase.assertNull(cache.getContents(source));
//     JUnitTestCase.assertNull(cache.getModificationStamp(source));
//     JUnitTestCase.assertNull(cache.setContents(source, null));
//   }
//   static dartSuite() {
//     _ut.group('ContentCacheTest', () {
//       _ut.test('test_setContents', () {
//         final __test = new ContentCacheTest();
//         runJUnitTest(__test, __test.test_setContents);
//       });
//     });
//   }
// }
// class DartObjectImplTest extends EngineTestCase {
//   TypeProvider _typeProvider = new TestTypeProvider();
//   void test_add_invalid_knownInt() {
//     _assertAdd(null, _stringValue("1"), _intValue(2));
//   }
//   void test_add_knownDouble_knownDouble() {
//     _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _doubleValue(2.0));
//   }
//   void test_add_knownDouble_knownInt() {
//     _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _intValue(2));
//   }
//   void test_add_knownDouble_unknownDouble() {
//     _assertAdd(_doubleValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_add_knownDouble_unknownInt() {
//     _assertAdd(_doubleValue(null), _doubleValue(1.0), _intValue(null));
//   }
//   void test_add_knownInt_invalid() {
//     _assertAdd(null, _intValue(1), _stringValue("2"));
//   }
//   void test_add_knownInt_knownInt() {
//     _assertAdd(_intValue(3), _intValue(1), _intValue(2));
//   }
//   void test_add_knownInt_unknownDouble() {
//     _assertAdd(_doubleValue(null), _intValue(1), _doubleValue(null));
//   }
//   void test_add_knownInt_unknownInt() {
//     _assertAdd(_intValue(null), _intValue(1), _intValue(null));
//   }
//   void test_add_unknownDouble_knownDouble() {
//     _assertAdd(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_add_unknownDouble_knownInt() {
//     _assertAdd(_doubleValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_add_unknownInt_knownDouble() {
//     _assertAdd(_doubleValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_add_unknownInt_knownInt() {
//     _assertAdd(_intValue(null), _intValue(null), _intValue(2));
//   }
//   void test_bitAnd_invalid_knownInt() {
//     _assertBitAnd(null, _stringValue("6"), _intValue(3));
//   }
//   void test_bitAnd_knownInt_invalid() {
//     _assertBitAnd(null, _intValue(6), _stringValue("3"));
//   }
//   void test_bitAnd_knownInt_knownInt() {
//     _assertBitAnd(_intValue(2), _intValue(6), _intValue(3));
//   }
//   void test_bitAnd_knownInt_unknownInt() {
//     _assertBitAnd(_intValue(null), _intValue(6), _intValue(null));
//   }
//   void test_bitAnd_unknownInt_knownInt() {
//     _assertBitAnd(_intValue(null), _intValue(null), _intValue(3));
//   }
//   void test_bitAnd_unknownInt_unknownInt() {
//     _assertBitAnd(_intValue(null), _intValue(null), _intValue(null));
//   }
//   void test_bitNot_invalid() {
//     _assertBitNot(null, _stringValue("6"));
//   }
//   void test_bitNot_knownInt() {
//     _assertBitNot(_intValue(-4), _intValue(3));
//   }
//   void test_bitNot_unknownInt() {
//     _assertBitNot(_intValue(null), _intValue(null));
//   }
//   void test_bitOr_invalid_knownInt() {
//     _assertBitOr(null, _stringValue("6"), _intValue(3));
//   }
//   void test_bitOr_knownInt_invalid() {
//     _assertBitOr(null, _intValue(6), _stringValue("3"));
//   }
//   void test_bitOr_knownInt_knownInt() {
//     _assertBitOr(_intValue(7), _intValue(6), _intValue(3));
//   }
//   void test_bitOr_knownInt_unknownInt() {
//     _assertBitOr(_intValue(null), _intValue(6), _intValue(null));
//   }
//   void test_bitOr_unknownInt_knownInt() {
//     _assertBitOr(_intValue(null), _intValue(null), _intValue(3));
//   }
//   void test_bitOr_unknownInt_unknownInt() {
//     _assertBitOr(_intValue(null), _intValue(null), _intValue(null));
//   }
//   void test_bitXor_invalid_knownInt() {
//     _assertBitXor(null, _stringValue("6"), _intValue(3));
//   }
//   void test_bitXor_knownInt_invalid() {
//     _assertBitXor(null, _intValue(6), _stringValue("3"));
//   }
//   void test_bitXor_knownInt_knownInt() {
//     _assertBitXor(_intValue(5), _intValue(6), _intValue(3));
//   }
//   void test_bitXor_knownInt_unknownInt() {
//     _assertBitXor(_intValue(null), _intValue(6), _intValue(null));
//   }
//   void test_bitXor_unknownInt_knownInt() {
//     _assertBitXor(_intValue(null), _intValue(null), _intValue(3));
//   }
//   void test_bitXor_unknownInt_unknownInt() {
//     _assertBitXor(_intValue(null), _intValue(null), _intValue(null));
//   }
//   void test_concatenate_invalid_knownString() {
//     _assertConcatenate(null, _intValue(2), _stringValue("def"));
//   }
//   void test_concatenate_knownString_invalid() {
//     _assertConcatenate(null, _stringValue("abc"), _intValue(3));
//   }
//   void test_concatenate_knownString_knownString() {
//     _assertConcatenate(_stringValue("abcdef"), _stringValue("abc"), _stringValue("def"));
//   }
//   void test_concatenate_knownString_unknownString() {
//     _assertConcatenate(_stringValue(null), _stringValue("abc"), _stringValue(null));
//   }
//   void test_concatenate_unknownString_knownString() {
//     _assertConcatenate(_stringValue(null), _stringValue(null), _stringValue("def"));
//   }
//   void test_divide_invalid_knownInt() {
//     _assertDivide(null, _stringValue("6"), _intValue(2));
//   }
//   void test_divide_knownDouble_knownDouble() {
//     _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _doubleValue(2.0));
//   }
//   void test_divide_knownDouble_knownInt() {
//     _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _intValue(2));
//   }
//   void test_divide_knownDouble_unknownDouble() {
//     _assertDivide(_doubleValue(null), _doubleValue(6.0), _doubleValue(null));
//   }
//   void test_divide_knownDouble_unknownInt() {
//     _assertDivide(_doubleValue(null), _doubleValue(6.0), _intValue(null));
//   }
//   void test_divide_knownInt_invalid() {
//     _assertDivide(null, _intValue(6), _stringValue("2"));
//   }
//   void test_divide_knownInt_knownInt() {
//     _assertDivide(_intValue(3), _intValue(6), _intValue(2));
//   }
//   void test_divide_knownInt_unknownDouble() {
//     _assertDivide(_doubleValue(null), _intValue(6), _doubleValue(null));
//   }
//   void test_divide_knownInt_unknownInt() {
//     _assertDivide(_intValue(null), _intValue(6), _intValue(null));
//   }
//   void test_divide_unknownDouble_knownDouble() {
//     _assertDivide(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_divide_unknownDouble_knownInt() {
//     _assertDivide(_doubleValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_divide_unknownInt_knownDouble() {
//     _assertDivide(_doubleValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_divide_unknownInt_knownInt() {
//     _assertDivide(_intValue(null), _intValue(null), _intValue(2));
//   }
//   void test_equalEqual_bool_false() {
//     _assertEqualEqual(_boolValue(false), _boolValue(false), _boolValue(true));
//   }
//   void test_equalEqual_bool_true() {
//     _assertEqualEqual(_boolValue(true), _boolValue(true), _boolValue(true));
//   }
//   void test_equalEqual_bool_unknown() {
//     _assertEqualEqual(_boolValue(null), _boolValue(null), _boolValue(false));
//   }
//   void test_equalEqual_double_false() {
//     _assertEqualEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
//   }
//   void test_equalEqual_double_true() {
//     _assertEqualEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
//   }
//   void test_equalEqual_double_unknown() {
//     _assertEqualEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_equalEqual_int_false() {
//     _assertEqualEqual(_boolValue(false), _intValue(-5), _intValue(5));
//   }
//   void test_equalEqual_int_true() {
//     _assertEqualEqual(_boolValue(true), _intValue(5), _intValue(5));
//   }
//   void test_equalEqual_int_unknown() {
//     _assertEqualEqual(_boolValue(null), _intValue(null), _intValue(3));
//   }
//   void test_equalEqual_list_empty() {
//     _assertEqualEqual(null, _listValue([]), _listValue([]));
//   }
//   void test_equalEqual_list_false() {
//     _assertEqualEqual(null, _listValue([]), _listValue([]));
//   }
//   void test_equalEqual_map_empty() {
//     _assertEqualEqual(null, _mapValue([]), _mapValue([]));
//   }
//   void test_equalEqual_map_false() {
//     _assertEqualEqual(null, _mapValue([]), _mapValue([]));
//   }
//   void test_equalEqual_null() {
//     _assertEqualEqual(_boolValue(true), _nullValue(), _nullValue());
//   }
//   void test_equalEqual_string_false() {
//     _assertEqualEqual(_boolValue(false), _stringValue("abc"), _stringValue("def"));
//   }
//   void test_equalEqual_string_true() {
//     _assertEqualEqual(_boolValue(true), _stringValue("abc"), _stringValue("abc"));
//   }
//   void test_equalEqual_string_unknown() {
//     _assertEqualEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
//   }
//   void test_equals_list_false_differentSizes() {
//     JUnitTestCase.assertFalse(_listValue([_boolValue(true)]) == _listValue([_boolValue(true), _boolValue(false)]));
//   }
//   void test_equals_list_false_sameSize() {
//     JUnitTestCase.assertFalse(_listValue([_boolValue(true)]) == _listValue([_boolValue(false)]));
//   }
//   void test_equals_list_true_empty() {
//     JUnitTestCase.assertEquals(_listValue([]), _listValue([]));
//   }
//   void test_equals_list_true_nonEmpty() {
//     JUnitTestCase.assertEquals(_listValue([_boolValue(true)]), _listValue([_boolValue(true)]));
//   }
//   void test_equals_map_true_empty() {
//     JUnitTestCase.assertEquals(_mapValue([]), _mapValue([]));
//   }
//   void test_equals_symbol_false() {
//     JUnitTestCase.assertFalse(_symbolValue("a") == _symbolValue("b"));
//   }
//   void test_equals_symbol_true() {
//     JUnitTestCase.assertEquals(_symbolValue("a"), _symbolValue("a"));
//   }
//   void test_getValue_bool_false() {
//     JUnitTestCase.assertEquals(false, _boolValue(false).value);
//   }
//   void test_getValue_bool_true() {
//     JUnitTestCase.assertEquals(true, _boolValue(true).value);
//   }
//   void test_getValue_bool_unknown() {
//     JUnitTestCase.assertNull(_boolValue(null).value);
//   }
//   void test_getValue_double_known() {
//     double value = 2.3;
//     JUnitTestCase.assertEquals(value, _doubleValue(value).value);
//   }
//   void test_getValue_double_unknown() {
//     JUnitTestCase.assertNull(_doubleValue(null).value);
//   }
//   void test_getValue_int_known() {
//     int value = 23;
//     JUnitTestCase.assertEquals(value, _intValue(value).value);
//   }
//   void test_getValue_int_unknown() {
//     JUnitTestCase.assertNull(_intValue(null).value);
//   }
//   void test_getValue_list_empty() {
//     Object result = _listValue([]).value;
//     _assertInstanceOfObjectArray(result);
//     List<Object> array = result as List<Object>;
//     EngineTestCase.assertLength(0, array);
//   }
//   void test_getValue_list_valid() {
//     Object result = _listValue([_intValue(23)]).value;
//     _assertInstanceOfObjectArray(result);
//     List<Object> array = result as List<Object>;
//     EngineTestCase.assertLength(1, array);
//   }
//   void test_getValue_map_empty() {
//     Object result = _mapValue([]).value;
//     EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
//     Map map = result as Map;
//     EngineTestCase.assertSizeOfMap(0, map);
//   }
//   void test_getValue_map_valid() {
//     Object result = _mapValue([_stringValue("key"), _stringValue("value")]).value;
//     EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
//     Map map = result as Map;
//     EngineTestCase.assertSizeOfMap(1, map);
//   }
//   void test_getValue_null() {
//     JUnitTestCase.assertNull(_nullValue().value);
//   }
//   void test_getValue_string_known() {
//     String value = "twenty-three";
//     JUnitTestCase.assertEquals(value, _stringValue(value).value);
//   }
//   void test_getValue_string_unknown() {
//     JUnitTestCase.assertNull(_stringValue(null).value);
//   }
//   void test_greaterThan_invalid_knownInt() {
//     _assertGreaterThan(null, _stringValue("1"), _intValue(2));
//   }
//   void test_greaterThan_knownDouble_knownDouble_false() {
//     _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
//   }
//   void test_greaterThan_knownDouble_knownDouble_true() {
//     _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
//   }
//   void test_greaterThan_knownDouble_knownInt_false() {
//     _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _intValue(2));
//   }
//   void test_greaterThan_knownDouble_knownInt_true() {
//     _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _intValue(1));
//   }
//   void test_greaterThan_knownDouble_unknownDouble() {
//     _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_greaterThan_knownDouble_unknownInt() {
//     _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
//   }
//   void test_greaterThan_knownInt_invalid() {
//     _assertGreaterThan(null, _intValue(1), _stringValue("2"));
//   }
//   void test_greaterThan_knownInt_knownInt_false() {
//     _assertGreaterThan(_boolValue(false), _intValue(1), _intValue(2));
//   }
//   void test_greaterThan_knownInt_knownInt_true() {
//     _assertGreaterThan(_boolValue(true), _intValue(2), _intValue(1));
//   }
//   void test_greaterThan_knownInt_unknownDouble() {
//     _assertGreaterThan(_boolValue(null), _intValue(1), _doubleValue(null));
//   }
//   void test_greaterThan_knownInt_unknownInt() {
//     _assertGreaterThan(_boolValue(null), _intValue(1), _intValue(null));
//   }
//   void test_greaterThan_unknownDouble_knownDouble() {
//     _assertGreaterThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_greaterThan_unknownDouble_knownInt() {
//     _assertGreaterThan(_boolValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_greaterThan_unknownInt_knownDouble() {
//     _assertGreaterThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_greaterThan_unknownInt_knownInt() {
//     _assertGreaterThan(_boolValue(null), _intValue(null), _intValue(2));
//   }
//   void test_greaterThanOrEqual_invalid_knownInt() {
//     _assertGreaterThanOrEqual(null, _stringValue("1"), _intValue(2));
//   }
//   void test_greaterThanOrEqual_knownDouble_knownDouble_false() {
//     _assertGreaterThanOrEqual(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
//   }
//   void test_greaterThanOrEqual_knownDouble_knownDouble_true() {
//     _assertGreaterThanOrEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
//   }
//   void test_greaterThanOrEqual_knownDouble_knownInt_false() {
//     _assertGreaterThanOrEqual(_boolValue(false), _doubleValue(1.0), _intValue(2));
//   }
//   void test_greaterThanOrEqual_knownDouble_knownInt_true() {
//     _assertGreaterThanOrEqual(_boolValue(true), _doubleValue(2.0), _intValue(1));
//   }
//   void test_greaterThanOrEqual_knownDouble_unknownDouble() {
//     _assertGreaterThanOrEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_greaterThanOrEqual_knownDouble_unknownInt() {
//     _assertGreaterThanOrEqual(_boolValue(null), _doubleValue(1.0), _intValue(null));
//   }
//   void test_greaterThanOrEqual_knownInt_invalid() {
//     _assertGreaterThanOrEqual(null, _intValue(1), _stringValue("2"));
//   }
//   void test_greaterThanOrEqual_knownInt_knownInt_false() {
//     _assertGreaterThanOrEqual(_boolValue(false), _intValue(1), _intValue(2));
//   }
//   void test_greaterThanOrEqual_knownInt_knownInt_true() {
//     _assertGreaterThanOrEqual(_boolValue(true), _intValue(2), _intValue(2));
//   }
//   void test_greaterThanOrEqual_knownInt_unknownDouble() {
//     _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
//   }
//   void test_greaterThanOrEqual_knownInt_unknownInt() {
//     _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
//   }
//   void test_greaterThanOrEqual_unknownDouble_knownDouble() {
//     _assertGreaterThanOrEqual(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_greaterThanOrEqual_unknownDouble_knownInt() {
//     _assertGreaterThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_greaterThanOrEqual_unknownInt_knownDouble() {
//     _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_greaterThanOrEqual_unknownInt_knownInt() {
//     _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
//   }
//   void test_hasExactValue_bool_false() {
//     JUnitTestCase.assertTrue(_boolValue(false).hasExactValue);
//   }
//   void test_hasExactValue_bool_true() {
//     JUnitTestCase.assertTrue(_boolValue(true).hasExactValue);
//   }
//   void test_hasExactValue_bool_unknown() {
//     JUnitTestCase.assertTrue(_boolValue(null).hasExactValue);
//   }
//   void test_hasExactValue_double_known() {
//     JUnitTestCase.assertTrue(_doubleValue(2.3).hasExactValue);
//   }
//   void test_hasExactValue_double_unknown() {
//     JUnitTestCase.assertTrue(_doubleValue(null).hasExactValue);
//   }
//   void test_hasExactValue_dynamic() {
//     JUnitTestCase.assertFalse(_dynamicValue().hasExactValue);
//   }
//   void test_hasExactValue_int_known() {
//     JUnitTestCase.assertTrue(_intValue(23).hasExactValue);
//   }
//   void test_hasExactValue_int_unknown() {
//     JUnitTestCase.assertTrue(_intValue(null).hasExactValue);
//   }
//   void test_hasExactValue_list_empty() {
//     JUnitTestCase.assertTrue(_listValue([]).hasExactValue);
//   }
//   void test_hasExactValue_list_invalid() {
//     JUnitTestCase.assertFalse(_dynamicValue().hasExactValue);
//   }
//   void test_hasExactValue_list_valid() {
//     JUnitTestCase.assertTrue(_listValue([_intValue(23)]).hasExactValue);
//   }
//   void test_hasExactValue_map_empty() {
//     JUnitTestCase.assertTrue(_mapValue([]).hasExactValue);
//   }
//   void test_hasExactValue_map_invalidKey() {
//     JUnitTestCase.assertFalse(_mapValue([_dynamicValue(), _stringValue("value")]).hasExactValue);
//   }
//   void test_hasExactValue_map_invalidValue() {
//     JUnitTestCase.assertFalse(_mapValue([_stringValue("key"), _dynamicValue()]).hasExactValue);
//   }
//   void test_hasExactValue_map_valid() {
//     JUnitTestCase.assertTrue(_mapValue([_stringValue("key"), _stringValue("value")]).hasExactValue);
//   }
//   void test_hasExactValue_null() {
//     JUnitTestCase.assertTrue(_nullValue().hasExactValue);
//   }
//   void test_hasExactValue_num() {
//     JUnitTestCase.assertFalse(_numValue().hasExactValue);
//   }
//   void test_hasExactValue_string_known() {
//     JUnitTestCase.assertTrue(_stringValue("twenty-three").hasExactValue);
//   }
//   void test_hasExactValue_string_unknown() {
//     JUnitTestCase.assertTrue(_stringValue(null).hasExactValue);
//   }
//   void test_integerDivide_invalid_knownInt() {
//     _assertIntegerDivide(null, _stringValue("6"), _intValue(2));
//   }
//   void test_integerDivide_knownDouble_knownDouble() {
//     _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _doubleValue(2.0));
//   }
//   void test_integerDivide_knownDouble_knownInt() {
//     _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _intValue(2));
//   }
//   void test_integerDivide_knownDouble_unknownDouble() {
//     _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _doubleValue(null));
//   }
//   void test_integerDivide_knownDouble_unknownInt() {
//     _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _intValue(null));
//   }
//   void test_integerDivide_knownInt_invalid() {
//     _assertIntegerDivide(null, _intValue(6), _stringValue("2"));
//   }
//   void test_integerDivide_knownInt_knownInt() {
//     _assertIntegerDivide(_intValue(3), _intValue(6), _intValue(2));
//   }
//   void test_integerDivide_knownInt_unknownDouble() {
//     _assertIntegerDivide(_intValue(null), _intValue(6), _doubleValue(null));
//   }
//   void test_integerDivide_knownInt_unknownInt() {
//     _assertIntegerDivide(_intValue(null), _intValue(6), _intValue(null));
//   }
//   void test_integerDivide_unknownDouble_knownDouble() {
//     _assertIntegerDivide(_intValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_integerDivide_unknownDouble_knownInt() {
//     _assertIntegerDivide(_intValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_integerDivide_unknownInt_knownDouble() {
//     _assertIntegerDivide(_intValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_integerDivide_unknownInt_knownInt() {
//     _assertIntegerDivide(_intValue(null), _intValue(null), _intValue(2));
//   }
//   void test_isBoolNumStringOrNull_bool_false() {
//     JUnitTestCase.assertTrue(_boolValue(false).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_bool_true() {
//     JUnitTestCase.assertTrue(_boolValue(true).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_bool_unknown() {
//     JUnitTestCase.assertTrue(_boolValue(null).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_double_known() {
//     JUnitTestCase.assertTrue(_doubleValue(2.3).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_double_unknown() {
//     JUnitTestCase.assertTrue(_doubleValue(null).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_dynamic() {
//     JUnitTestCase.assertTrue(_dynamicValue().isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_int_known() {
//     JUnitTestCase.assertTrue(_intValue(23).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_int_unknown() {
//     JUnitTestCase.assertTrue(_intValue(null).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_list() {
//     JUnitTestCase.assertFalse(_listValue([]).isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_null() {
//     JUnitTestCase.assertTrue(_nullValue().isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_num() {
//     JUnitTestCase.assertTrue(_numValue().isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_string_known() {
//     JUnitTestCase.assertTrue(_stringValue("twenty-three").isBoolNumStringOrNull);
//   }
//   void test_isBoolNumStringOrNull_string_unknown() {
//     JUnitTestCase.assertTrue(_stringValue(null).isBoolNumStringOrNull);
//   }
//   void test_lessThan_invalid_knownInt() {
//     _assertLessThan(null, _stringValue("1"), _intValue(2));
//   }
//   void test_lessThan_knownDouble_knownDouble_false() {
//     _assertLessThan(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
//   }
//   void test_lessThan_knownDouble_knownDouble_true() {
//     _assertLessThan(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
//   }
//   void test_lessThan_knownDouble_knownInt_false() {
//     _assertLessThan(_boolValue(false), _doubleValue(2.0), _intValue(1));
//   }
//   void test_lessThan_knownDouble_knownInt_true() {
//     _assertLessThan(_boolValue(true), _doubleValue(1.0), _intValue(2));
//   }
//   void test_lessThan_knownDouble_unknownDouble() {
//     _assertLessThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_lessThan_knownDouble_unknownInt() {
//     _assertLessThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
//   }
//   void test_lessThan_knownInt_invalid() {
//     _assertLessThan(null, _intValue(1), _stringValue("2"));
//   }
//   void test_lessThan_knownInt_knownInt_false() {
//     _assertLessThan(_boolValue(false), _intValue(2), _intValue(1));
//   }
//   void test_lessThan_knownInt_knownInt_true() {
//     _assertLessThan(_boolValue(true), _intValue(1), _intValue(2));
//   }
//   void test_lessThan_knownInt_unknownDouble() {
//     _assertLessThan(_boolValue(null), _intValue(1), _doubleValue(null));
//   }
//   void test_lessThan_knownInt_unknownInt() {
//     _assertLessThan(_boolValue(null), _intValue(1), _intValue(null));
//   }
//   void test_lessThan_unknownDouble_knownDouble() {
//     _assertLessThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_lessThan_unknownDouble_knownInt() {
//     _assertLessThan(_boolValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_lessThan_unknownInt_knownDouble() {
//     _assertLessThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_lessThan_unknownInt_knownInt() {
//     _assertLessThan(_boolValue(null), _intValue(null), _intValue(2));
//   }
//   void test_lessThanOrEqual_invalid_knownInt() {
//     _assertLessThanOrEqual(null, _stringValue("1"), _intValue(2));
//   }
//   void test_lessThanOrEqual_knownDouble_knownDouble_false() {
//     _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
//   }
//   void test_lessThanOrEqual_knownDouble_knownDouble_true() {
//     _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
//   }
//   void test_lessThanOrEqual_knownDouble_knownInt_false() {
//     _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _intValue(1));
//   }
//   void test_lessThanOrEqual_knownDouble_knownInt_true() {
//     _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _intValue(2));
//   }
//   void test_lessThanOrEqual_knownDouble_unknownDouble() {
//     _assertLessThanOrEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_lessThanOrEqual_knownDouble_unknownInt() {
//     _assertLessThanOrEqual(_boolValue(null), _doubleValue(1.0), _intValue(null));
//   }
//   void test_lessThanOrEqual_knownInt_invalid() {
//     _assertLessThanOrEqual(null, _intValue(1), _stringValue("2"));
//   }
//   void test_lessThanOrEqual_knownInt_knownInt_false() {
//     _assertLessThanOrEqual(_boolValue(false), _intValue(2), _intValue(1));
//   }
//   void test_lessThanOrEqual_knownInt_knownInt_true() {
//     _assertLessThanOrEqual(_boolValue(true), _intValue(1), _intValue(2));
//   }
//   void test_lessThanOrEqual_knownInt_unknownDouble() {
//     _assertLessThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
//   }
//   void test_lessThanOrEqual_knownInt_unknownInt() {
//     _assertLessThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
//   }
//   void test_lessThanOrEqual_unknownDouble_knownDouble() {
//     _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_lessThanOrEqual_unknownDouble_knownInt() {
//     _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_lessThanOrEqual_unknownInt_knownDouble() {
//     _assertLessThanOrEqual(_boolValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_lessThanOrEqual_unknownInt_knownInt() {
//     _assertLessThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
//   }
//   void test_logicalAnd_false_false() {
//     _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(false));
//   }
//   void test_logicalAnd_false_null() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _boolValue(false), _nullValue());
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_false_string() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _boolValue(false), _stringValue("false"));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_false_true() {
//     _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(true));
//   }
//   void test_logicalAnd_null_false() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(false));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_null_true() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(true));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_string_false() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _stringValue("true"), _boolValue(false));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_string_true() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _stringValue("false"), _boolValue(true));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_true_false() {
//     _assertLogicalAnd(_boolValue(false), _boolValue(true), _boolValue(false));
//   }
//   void test_logicalAnd_true_null() {
//     _assertLogicalAnd(null, _boolValue(true), _nullValue());
//   }
//   void test_logicalAnd_true_string() {
//     try {
//       _assertLogicalAnd(_boolValue(false), _boolValue(true), _stringValue("true"));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalAnd_true_true() {
//     _assertLogicalAnd(_boolValue(true), _boolValue(true), _boolValue(true));
//   }
//   void test_logicalNot_false() {
//     _assertLogicalNot(_boolValue(true), _boolValue(false));
//   }
//   void test_logicalNot_null() {
//     _assertLogicalNot(null, _nullValue());
//   }
//   void test_logicalNot_string() {
//     try {
//       _assertLogicalNot(_boolValue(true), _stringValue(null));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalNot_true() {
//     _assertLogicalNot(_boolValue(false), _boolValue(true));
//   }
//   void test_logicalNot_unknown() {
//     _assertLogicalNot(_boolValue(null), _boolValue(null));
//   }
//   void test_logicalOr_false_false() {
//     _assertLogicalOr(_boolValue(false), _boolValue(false), _boolValue(false));
//   }
//   void test_logicalOr_false_null() {
//     _assertLogicalOr(null, _boolValue(false), _nullValue());
//   }
//   void test_logicalOr_false_string() {
//     try {
//       _assertLogicalOr(_boolValue(false), _boolValue(false), _stringValue("false"));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_false_true() {
//     _assertLogicalOr(_boolValue(true), _boolValue(false), _boolValue(true));
//   }
//   void test_logicalOr_null_false() {
//     try {
//       _assertLogicalOr(_boolValue(false), _nullValue(), _boolValue(false));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_null_true() {
//     try {
//       _assertLogicalOr(_boolValue(true), _nullValue(), _boolValue(true));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_string_false() {
//     try {
//       _assertLogicalOr(_boolValue(false), _stringValue("true"), _boolValue(false));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_string_true() {
//     try {
//       _assertLogicalOr(_boolValue(true), _stringValue("false"), _boolValue(true));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_true_false() {
//     _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(false));
//   }
//   void test_logicalOr_true_null() {
//     try {
//       _assertLogicalOr(_boolValue(true), _boolValue(true), _nullValue());
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_true_string() {
//     try {
//       _assertLogicalOr(_boolValue(true), _boolValue(true), _stringValue("true"));
//       JUnitTestCase.fail("Expected EvaluationException");
//     } on EvaluationException catch (exception) {
//     }
//   }
//   void test_logicalOr_true_true() {
//     _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(true));
//   }
//   void test_minus_invalid_knownInt() {
//     _assertMinus(null, _stringValue("4"), _intValue(3));
//   }
//   void test_minus_knownDouble_knownDouble() {
//     _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _doubleValue(3.0));
//   }
//   void test_minus_knownDouble_knownInt() {
//     _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _intValue(3));
//   }
//   void test_minus_knownDouble_unknownDouble() {
//     _assertMinus(_doubleValue(null), _doubleValue(4.0), _doubleValue(null));
//   }
//   void test_minus_knownDouble_unknownInt() {
//     _assertMinus(_doubleValue(null), _doubleValue(4.0), _intValue(null));
//   }
//   void test_minus_knownInt_invalid() {
//     _assertMinus(null, _intValue(4), _stringValue("3"));
//   }
//   void test_minus_knownInt_knownInt() {
//     _assertMinus(_intValue(1), _intValue(4), _intValue(3));
//   }
//   void test_minus_knownInt_unknownDouble() {
//     _assertMinus(_doubleValue(null), _intValue(4), _doubleValue(null));
//   }
//   void test_minus_knownInt_unknownInt() {
//     _assertMinus(_intValue(null), _intValue(4), _intValue(null));
//   }
//   void test_minus_unknownDouble_knownDouble() {
//     _assertMinus(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
//   }
//   void test_minus_unknownDouble_knownInt() {
//     _assertMinus(_doubleValue(null), _doubleValue(null), _intValue(3));
//   }
//   void test_minus_unknownInt_knownDouble() {
//     _assertMinus(_doubleValue(null), _intValue(null), _doubleValue(3.0));
//   }
//   void test_minus_unknownInt_knownInt() {
//     _assertMinus(_intValue(null), _intValue(null), _intValue(3));
//   }
//   void test_negated_double_known() {
//     _assertNegated(_doubleValue(2.0), _doubleValue(-2.0));
//   }
//   void test_negated_double_unknown() {
//     _assertNegated(_doubleValue(null), _doubleValue(null));
//   }
//   void test_negated_int_known() {
//     _assertNegated(_intValue(-3), _intValue(3));
//   }
//   void test_negated_int_unknown() {
//     _assertNegated(_intValue(null), _intValue(null));
//   }
//   void test_negated_string() {
//     _assertNegated(null, _stringValue(null));
//   }
//   void test_notEqual_bool_false() {
//     _assertNotEqual(_boolValue(false), _boolValue(true), _boolValue(true));
//   }
//   void test_notEqual_bool_true() {
//     _assertNotEqual(_boolValue(true), _boolValue(false), _boolValue(true));
//   }
//   void test_notEqual_bool_unknown() {
//     _assertNotEqual(_boolValue(null), _boolValue(null), _boolValue(false));
//   }
//   void test_notEqual_double_false() {
//     _assertNotEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(2.0));
//   }
//   void test_notEqual_double_true() {
//     _assertNotEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(4.0));
//   }
//   void test_notEqual_double_unknown() {
//     _assertNotEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
//   }
//   void test_notEqual_int_false() {
//     _assertNotEqual(_boolValue(false), _intValue(5), _intValue(5));
//   }
//   void test_notEqual_int_true() {
//     _assertNotEqual(_boolValue(true), _intValue(-5), _intValue(5));
//   }
//   void test_notEqual_int_unknown() {
//     _assertNotEqual(_boolValue(null), _intValue(null), _intValue(3));
//   }
//   void test_notEqual_null() {
//     _assertNotEqual(_boolValue(false), _nullValue(), _nullValue());
//   }
//   void test_notEqual_string_false() {
//     _assertNotEqual(_boolValue(false), _stringValue("abc"), _stringValue("abc"));
//   }
//   void test_notEqual_string_true() {
//     _assertNotEqual(_boolValue(true), _stringValue("abc"), _stringValue("def"));
//   }
//   void test_notEqual_string_unknown() {
//     _assertNotEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
//   }
//   void test_performToString_bool_false() {
//     _assertPerformToString(_stringValue("false"), _boolValue(false));
//   }
//   void test_performToString_bool_true() {
//     _assertPerformToString(_stringValue("true"), _boolValue(true));
//   }
//   void test_performToString_bool_unknown() {
//     _assertPerformToString(_stringValue(null), _boolValue(null));
//   }
//   void test_performToString_double_known() {
//     _assertPerformToString(_stringValue("2.0"), _doubleValue(2.0));
//   }
//   void test_performToString_double_unknown() {
//     _assertPerformToString(_stringValue(null), _doubleValue(null));
//   }
//   void test_performToString_int_known() {
//     _assertPerformToString(_stringValue("5"), _intValue(5));
//   }
//   void test_performToString_int_unknown() {
//     _assertPerformToString(_stringValue(null), _intValue(null));
//   }
//   void test_performToString_null() {
//     _assertPerformToString(_stringValue("null"), _nullValue());
//   }
//   void test_performToString_string_known() {
//     _assertPerformToString(_stringValue("abc"), _stringValue("abc"));
//   }
//   void test_performToString_string_unknown() {
//     _assertPerformToString(_stringValue(null), _stringValue(null));
//   }
//   void test_remainder_invalid_knownInt() {
//     _assertRemainder(null, _stringValue("7"), _intValue(2));
//   }
//   void test_remainder_knownDouble_knownDouble() {
//     _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _doubleValue(2.0));
//   }
//   void test_remainder_knownDouble_knownInt() {
//     _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _intValue(2));
//   }
//   void test_remainder_knownDouble_unknownDouble() {
//     _assertRemainder(_doubleValue(null), _doubleValue(7.0), _doubleValue(null));
//   }
//   void test_remainder_knownDouble_unknownInt() {
//     _assertRemainder(_doubleValue(null), _doubleValue(6.0), _intValue(null));
//   }
//   void test_remainder_knownInt_invalid() {
//     _assertRemainder(null, _intValue(7), _stringValue("2"));
//   }
//   void test_remainder_knownInt_knownInt() {
//     _assertRemainder(_intValue(1), _intValue(7), _intValue(2));
//   }
//   void test_remainder_knownInt_unknownDouble() {
//     _assertRemainder(_doubleValue(null), _intValue(7), _doubleValue(null));
//   }
//   void test_remainder_knownInt_unknownInt() {
//     _assertRemainder(_intValue(null), _intValue(7), _intValue(null));
//   }
//   void test_remainder_unknownDouble_knownDouble() {
//     _assertRemainder(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
//   }
//   void test_remainder_unknownDouble_knownInt() {
//     _assertRemainder(_doubleValue(null), _doubleValue(null), _intValue(2));
//   }
//   void test_remainder_unknownInt_knownDouble() {
//     _assertRemainder(_doubleValue(null), _intValue(null), _doubleValue(2.0));
//   }
//   void test_remainder_unknownInt_knownInt() {
//     _assertRemainder(_intValue(null), _intValue(null), _intValue(2));
//   }
//   void test_shiftLeft_invalid_knownInt() {
//     _assertShiftLeft(null, _stringValue(null), _intValue(3));
//   }
//   void test_shiftLeft_knownInt_invalid() {
//     _assertShiftLeft(null, _intValue(6), _stringValue(null));
//   }
//   void test_shiftLeft_knownInt_knownInt() {
//     _assertShiftLeft(_intValue(48), _intValue(6), _intValue(3));
//   }
//   void test_shiftLeft_knownInt_tooLarge() {
//     _assertShiftLeft(_intValue(null), _intValue(6), new DartObjectImpl(_typeProvider.intType, new IntState(Long.MAX_VALUE)));
//   }
//   void test_shiftLeft_knownInt_unknownInt() {
//     _assertShiftLeft(_intValue(null), _intValue(6), _intValue(null));
//   }
//   void test_shiftLeft_unknownInt_knownInt() {
//     _assertShiftLeft(_intValue(null), _intValue(null), _intValue(3));
//   }
//   void test_shiftLeft_unknownInt_unknownInt() {
//     _assertShiftLeft(_intValue(null), _intValue(null), _intValue(null));
//   }
//   void test_shiftRight_invalid_knownInt() {
//     _assertShiftRight(null, _stringValue(null), _intValue(3));
//   }
//   void test_shiftRight_knownInt_invalid() {
//     _assertShiftRight(null, _intValue(48), _stringValue(null));
//   }
//   void test_shiftRight_knownInt_knownInt() {
//     _assertShiftRight(_intValue(6), _intValue(48), _intValue(3));
//   }
//   void test_shiftRight_knownInt_tooLarge() {
//     _assertShiftRight(_intValue(null), _intValue(48), new DartObjectImpl(_typeProvider.intType, new IntState(Long.MAX_VALUE)));
//   }
//   void test_shiftRight_knownInt_unknownInt() {
//     _assertShiftRight(_intValue(null), _intValue(48), _intValue(null));
//   }
//   void test_shiftRight_unknownInt_knownInt() {
//     _assertShiftRight(_intValue(null), _intValue(null), _intValue(3));
//   }
//   void test_shiftRight_unknownInt_unknownInt() {
//     _assertShiftRight(_intValue(null), _intValue(null), _intValue(null));
//   }
//   void test_times_invalid_knownInt() {
//     _assertTimes(null, _stringValue("2"), _intValue(3));
//   }
//   void test_times_knownDouble_knownDouble() {
//     _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _doubleValue(3.0));
//   }
//   void test_times_knownDouble_knownInt() {
//     _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _intValue(3));
//   }
//   void test_times_knownDouble_unknownDouble() {
//     _assertTimes(_doubleValue(null), _doubleValue(2.0), _doubleValue(null));
//   }
//   void test_times_knownDouble_unknownInt() {
//     _assertTimes(_doubleValue(null), _doubleValue(2.0), _intValue(null));
//   }
//   void test_times_knownInt_invalid() {
//     _assertTimes(null, _intValue(2), _stringValue("3"));
//   }
//   void test_times_knownInt_knownInt() {
//     _assertTimes(_intValue(6), _intValue(2), _intValue(3));
//   }
//   void test_times_knownInt_unknownDouble() {
//     _assertTimes(_doubleValue(null), _intValue(2), _doubleValue(null));
//   }
//   void test_times_knownInt_unknownInt() {
//     _assertTimes(_intValue(null), _intValue(2), _intValue(null));
//   }
//   void test_times_unknownDouble_knownDouble() {
//     _assertTimes(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
//   }
//   void test_times_unknownDouble_knownInt() {
//     _assertTimes(_doubleValue(null), _doubleValue(null), _intValue(3));
//   }
//   void test_times_unknownInt_knownDouble() {
//     _assertTimes(_doubleValue(null), _intValue(null), _doubleValue(3.0));
//   }
//   void test_times_unknownInt_knownInt() {
//     _assertTimes(_intValue(null), _intValue(null), _intValue(3));
//   }
//   /**
//    * Assert that the result of adding the left and right operands is the expected value, or that the
//    * operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertAdd(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.add(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.add(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of bit-anding the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertBitAnd(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.bitAnd(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.bitAnd(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the bit-not of the operand is the expected value, or that the operation throws an
//    * exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param operand the operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertBitNot(DartObjectImpl expected, DartObjectImpl operand) {
//     if (expected == null) {
//       try {
//         operand.bitNot(_typeProvider);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = operand.bitNot(_typeProvider);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of bit-oring the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertBitOr(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.bitOr(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.bitOr(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of bit-xoring the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertBitXor(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.bitXor(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.bitXor(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of concatenating the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertConcatenate(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.concatenate(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.concatenate(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of dividing the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertDivide(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.divide(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.divide(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of comparing the left and right operands for equality is the expected
//    * value, or that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertEqualEqual(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.equalEqual(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.equalEqual(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of comparing the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertGreaterThan(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.greaterThan(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.greaterThan(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of comparing the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertGreaterThanOrEqual(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   void _assertInstanceOfObjectArray(Object result) {
//     // TODO(scheglov) implement
//   }
//   /**
//    * Assert that the result of dividing the left and right operands as integers is the expected
//    * value, or that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertIntegerDivide(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.integerDivide(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.integerDivide(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of comparing the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertLessThan(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.lessThan(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.lessThan(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of comparing the left and right operands is the expected value, or that
//    * the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertLessThanOrEqual(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of logical-anding the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertLogicalAnd(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.logicalAnd(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.logicalAnd(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the logical-not of the operand is the expected value, or that the operation throws
//    * an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param operand the operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertLogicalNot(DartObjectImpl expected, DartObjectImpl operand) {
//     if (expected == null) {
//       try {
//         operand.logicalNot(_typeProvider);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = operand.logicalNot(_typeProvider);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of logical-oring the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertLogicalOr(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.logicalOr(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.logicalOr(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of subtracting the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertMinus(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.minus(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.minus(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the negation of the operand is the expected value, or that the operation throws an
//    * exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param operand the operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertNegated(DartObjectImpl expected, DartObjectImpl operand) {
//     if (expected == null) {
//       try {
//         operand.negated(_typeProvider);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = operand.negated(_typeProvider);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of comparing the left and right operands for inequality is the expected
//    * value, or that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertNotEqual(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.notEqual(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.notEqual(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that converting the operand to a string is the expected value, or that the operation
//    * throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param operand the operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertPerformToString(DartObjectImpl expected, DartObjectImpl operand) {
//     if (expected == null) {
//       try {
//         operand.performToString(_typeProvider);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = operand.performToString(_typeProvider);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of taking the remainder of the left and right operands is the expected
//    * value, or that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertRemainder(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.remainder(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.remainder(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of multiplying the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertShiftLeft(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.shiftLeft(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.shiftLeft(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of multiplying the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertShiftRight(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.shiftRight(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.shiftRight(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   /**
//    * Assert that the result of multiplying the left and right operands is the expected value, or
//    * that the operation throws an exception if the expected value is `null`.
//    *
//    * @param expected the expected result of the operation
//    * @param leftOperand the left operand to the operation
//    * @param rightOperand the left operand to the operation
//    * @throws EvaluationException if the result is an exception when it should not be
//    */
//   void _assertTimes(DartObjectImpl expected, DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
//     if (expected == null) {
//       try {
//         leftOperand.times(_typeProvider, rightOperand);
//         JUnitTestCase.fail("Expected an EvaluationException");
//       } on EvaluationException catch (exception) {
//       }
//     } else {
//       DartObjectImpl result = leftOperand.times(_typeProvider, rightOperand);
//       JUnitTestCase.assertNotNull(result);
//       JUnitTestCase.assertEquals(expected, result);
//     }
//   }
//   DartObjectImpl _boolValue(bool value) {
//     if (value == null) {
//       return new DartObjectImpl(_typeProvider.boolType, BoolState.UNKNOWN_VALUE);
//     } else if (identical(value, false)) {
//       return new DartObjectImpl(_typeProvider.boolType, BoolState.FALSE_STATE);
//     } else if (identical(value, true)) {
//       return new DartObjectImpl(_typeProvider.boolType, BoolState.TRUE_STATE);
//     }
//     JUnitTestCase.fail("Invalid boolean value used in test");
//     return null;
//   }
//   DartObjectImpl _doubleValue(double value) {
//     if (value == null) {
//       return new DartObjectImpl(_typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
//     } else {
//       return new DartObjectImpl(_typeProvider.doubleType, new DoubleState(value));
//     }
//   }
//   DartObjectImpl _dynamicValue() => new DartObjectImpl(_typeProvider.nullType, DynamicState.DYNAMIC_STATE);
//   DartObjectImpl _intValue(int value) {
//     if (value == null) {
//       return new DartObjectImpl(_typeProvider.intType, IntState.UNKNOWN_VALUE);
//     } else {
//       return new DartObjectImpl(_typeProvider.intType, new IntState(value.longValue()));
//     }
//   }
//   DartObjectImpl _listValue(List<DartObjectImpl> elements) => new DartObjectImpl(_typeProvider.listType, new ListState(elements));
//   DartObjectImpl _mapValue(List<DartObjectImpl> keyElementPairs) {
//     HashMap<DartObjectImpl, DartObjectImpl> map = new HashMap<DartObjectImpl, DartObjectImpl>();
//     int count = keyElementPairs.length;
//     for (int i = 0; i < count;) {
//       map[keyElementPairs[i++]] = keyElementPairs[i++];
//     }
//     return new DartObjectImpl(_typeProvider.mapType, new MapState(map));
//   }
//   DartObjectImpl _nullValue() => new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
//   DartObjectImpl _numValue() => new DartObjectImpl(_typeProvider.nullType, NumState.UNKNOWN_VALUE);
//   DartObjectImpl _stringValue(String value) {
//     if (value == null) {
//       return new DartObjectImpl(_typeProvider.stringType, StringState.UNKNOWN_VALUE);
//     } else {
//       return new DartObjectImpl(_typeProvider.stringType, new StringState(value));
//     }
//   }
//   DartObjectImpl _symbolValue(String value) => new DartObjectImpl(_typeProvider.symbolType, new SymbolState(value));
//   static dartSuite() {
//     _ut.group('DartObjectImplTest', () {
//       _ut.test('test_add_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_invalid_knownInt);
//       });
//       _ut.test('test_add_knownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownDouble_knownDouble);
//       });
//       _ut.test('test_add_knownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownDouble_knownInt);
//       });
//       _ut.test('test_add_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownDouble_unknownDouble);
//       });
//       _ut.test('test_add_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownDouble_unknownInt);
//       });
//       _ut.test('test_add_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownInt_invalid);
//       });
//       _ut.test('test_add_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownInt_knownInt);
//       });
//       _ut.test('test_add_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownInt_unknownDouble);
//       });
//       _ut.test('test_add_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_knownInt_unknownInt);
//       });
//       _ut.test('test_add_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_unknownDouble_knownDouble);
//       });
//       _ut.test('test_add_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_unknownDouble_knownInt);
//       });
//       _ut.test('test_add_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_unknownInt_knownDouble);
//       });
//       _ut.test('test_add_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_add_unknownInt_knownInt);
//       });
//       _ut.test('test_bitAnd_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitAnd_invalid_knownInt);
//       });
//       _ut.test('test_bitAnd_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitAnd_knownInt_invalid);
//       });
//       _ut.test('test_bitAnd_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitAnd_knownInt_knownInt);
//       });
//       _ut.test('test_bitAnd_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitAnd_knownInt_unknownInt);
//       });
//       _ut.test('test_bitAnd_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitAnd_unknownInt_knownInt);
//       });
//       _ut.test('test_bitAnd_unknownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitAnd_unknownInt_unknownInt);
//       });
//       _ut.test('test_bitNot_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitNot_invalid);
//       });
//       _ut.test('test_bitNot_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitNot_knownInt);
//       });
//       _ut.test('test_bitNot_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitNot_unknownInt);
//       });
//       _ut.test('test_bitOr_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitOr_invalid_knownInt);
//       });
//       _ut.test('test_bitOr_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitOr_knownInt_invalid);
//       });
//       _ut.test('test_bitOr_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitOr_knownInt_knownInt);
//       });
//       _ut.test('test_bitOr_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitOr_knownInt_unknownInt);
//       });
//       _ut.test('test_bitOr_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitOr_unknownInt_knownInt);
//       });
//       _ut.test('test_bitOr_unknownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitOr_unknownInt_unknownInt);
//       });
//       _ut.test('test_bitXor_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitXor_invalid_knownInt);
//       });
//       _ut.test('test_bitXor_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitXor_knownInt_invalid);
//       });
//       _ut.test('test_bitXor_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitXor_knownInt_knownInt);
//       });
//       _ut.test('test_bitXor_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitXor_knownInt_unknownInt);
//       });
//       _ut.test('test_bitXor_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitXor_unknownInt_knownInt);
//       });
//       _ut.test('test_bitXor_unknownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_bitXor_unknownInt_unknownInt);
//       });
//       _ut.test('test_concatenate_invalid_knownString', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_concatenate_invalid_knownString);
//       });
//       _ut.test('test_concatenate_knownString_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_concatenate_knownString_invalid);
//       });
//       _ut.test('test_concatenate_knownString_knownString', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_concatenate_knownString_knownString);
//       });
//       _ut.test('test_concatenate_knownString_unknownString', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_concatenate_knownString_unknownString);
//       });
//       _ut.test('test_concatenate_unknownString_knownString', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_concatenate_unknownString_knownString);
//       });
//       _ut.test('test_divide_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_invalid_knownInt);
//       });
//       _ut.test('test_divide_knownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownDouble_knownDouble);
//       });
//       _ut.test('test_divide_knownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownDouble_knownInt);
//       });
//       _ut.test('test_divide_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownDouble_unknownDouble);
//       });
//       _ut.test('test_divide_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownDouble_unknownInt);
//       });
//       _ut.test('test_divide_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownInt_invalid);
//       });
//       _ut.test('test_divide_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownInt_knownInt);
//       });
//       _ut.test('test_divide_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownInt_unknownDouble);
//       });
//       _ut.test('test_divide_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_knownInt_unknownInt);
//       });
//       _ut.test('test_divide_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_unknownDouble_knownDouble);
//       });
//       _ut.test('test_divide_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_unknownDouble_knownInt);
//       });
//       _ut.test('test_divide_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_unknownInt_knownDouble);
//       });
//       _ut.test('test_divide_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_divide_unknownInt_knownInt);
//       });
//       _ut.test('test_equalEqual_bool_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_bool_false);
//       });
//       _ut.test('test_equalEqual_bool_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_bool_true);
//       });
//       _ut.test('test_equalEqual_bool_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_bool_unknown);
//       });
//       _ut.test('test_equalEqual_double_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_double_false);
//       });
//       _ut.test('test_equalEqual_double_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_double_true);
//       });
//       _ut.test('test_equalEqual_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_double_unknown);
//       });
//       _ut.test('test_equalEqual_int_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_int_false);
//       });
//       _ut.test('test_equalEqual_int_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_int_true);
//       });
//       _ut.test('test_equalEqual_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_int_unknown);
//       });
//       _ut.test('test_equalEqual_list_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_list_empty);
//       });
//       _ut.test('test_equalEqual_list_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_list_false);
//       });
//       _ut.test('test_equalEqual_map_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_map_empty);
//       });
//       _ut.test('test_equalEqual_map_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_map_false);
//       });
//       _ut.test('test_equalEqual_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_null);
//       });
//       _ut.test('test_equalEqual_string_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_string_false);
//       });
//       _ut.test('test_equalEqual_string_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_string_true);
//       });
//       _ut.test('test_equalEqual_string_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equalEqual_string_unknown);
//       });
//       _ut.test('test_equals_list_false_differentSizes', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_list_false_differentSizes);
//       });
//       _ut.test('test_equals_list_false_sameSize', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_list_false_sameSize);
//       });
//       _ut.test('test_equals_list_true_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_list_true_empty);
//       });
//       _ut.test('test_equals_list_true_nonEmpty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_list_true_nonEmpty);
//       });
//       _ut.test('test_equals_map_true_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_map_true_empty);
//       });
//       _ut.test('test_equals_symbol_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_symbol_false);
//       });
//       _ut.test('test_equals_symbol_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_equals_symbol_true);
//       });
//       _ut.test('test_getValue_bool_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_bool_false);
//       });
//       _ut.test('test_getValue_bool_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_bool_true);
//       });
//       _ut.test('test_getValue_bool_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_bool_unknown);
//       });
//       _ut.test('test_getValue_double_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_double_known);
//       });
//       _ut.test('test_getValue_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_double_unknown);
//       });
//       _ut.test('test_getValue_int_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_int_known);
//       });
//       _ut.test('test_getValue_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_int_unknown);
//       });
//       _ut.test('test_getValue_list_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_list_empty);
//       });
//       _ut.test('test_getValue_list_valid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_list_valid);
//       });
//       _ut.test('test_getValue_map_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_map_empty);
//       });
//       _ut.test('test_getValue_map_valid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_map_valid);
//       });
//       _ut.test('test_getValue_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_null);
//       });
//       _ut.test('test_getValue_string_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_string_known);
//       });
//       _ut.test('test_getValue_string_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_getValue_string_unknown);
//       });
//       _ut.test('test_greaterThanOrEqual_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_invalid_knownInt);
//       });
//       _ut.test('test_greaterThanOrEqual_knownDouble_knownDouble_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownDouble_knownDouble_false);
//       });
//       _ut.test('test_greaterThanOrEqual_knownDouble_knownDouble_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownDouble_knownDouble_true);
//       });
//       _ut.test('test_greaterThanOrEqual_knownDouble_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownDouble_knownInt_false);
//       });
//       _ut.test('test_greaterThanOrEqual_knownDouble_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownDouble_knownInt_true);
//       });
//       _ut.test('test_greaterThanOrEqual_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownDouble_unknownDouble);
//       });
//       _ut.test('test_greaterThanOrEqual_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownDouble_unknownInt);
//       });
//       _ut.test('test_greaterThanOrEqual_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownInt_invalid);
//       });
//       _ut.test('test_greaterThanOrEqual_knownInt_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownInt_knownInt_false);
//       });
//       _ut.test('test_greaterThanOrEqual_knownInt_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownInt_knownInt_true);
//       });
//       _ut.test('test_greaterThanOrEqual_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownInt_unknownDouble);
//       });
//       _ut.test('test_greaterThanOrEqual_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_knownInt_unknownInt);
//       });
//       _ut.test('test_greaterThanOrEqual_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_unknownDouble_knownDouble);
//       });
//       _ut.test('test_greaterThanOrEqual_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_unknownDouble_knownInt);
//       });
//       _ut.test('test_greaterThanOrEqual_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_unknownInt_knownDouble);
//       });
//       _ut.test('test_greaterThanOrEqual_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThanOrEqual_unknownInt_knownInt);
//       });
//       _ut.test('test_greaterThan_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_invalid_knownInt);
//       });
//       _ut.test('test_greaterThan_knownDouble_knownDouble_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownDouble_knownDouble_false);
//       });
//       _ut.test('test_greaterThan_knownDouble_knownDouble_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownDouble_knownDouble_true);
//       });
//       _ut.test('test_greaterThan_knownDouble_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownDouble_knownInt_false);
//       });
//       _ut.test('test_greaterThan_knownDouble_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownDouble_knownInt_true);
//       });
//       _ut.test('test_greaterThan_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownDouble_unknownDouble);
//       });
//       _ut.test('test_greaterThan_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownDouble_unknownInt);
//       });
//       _ut.test('test_greaterThan_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownInt_invalid);
//       });
//       _ut.test('test_greaterThan_knownInt_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownInt_knownInt_false);
//       });
//       _ut.test('test_greaterThan_knownInt_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownInt_knownInt_true);
//       });
//       _ut.test('test_greaterThan_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownInt_unknownDouble);
//       });
//       _ut.test('test_greaterThan_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_knownInt_unknownInt);
//       });
//       _ut.test('test_greaterThan_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_unknownDouble_knownDouble);
//       });
//       _ut.test('test_greaterThan_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_unknownDouble_knownInt);
//       });
//       _ut.test('test_greaterThan_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_unknownInt_knownDouble);
//       });
//       _ut.test('test_greaterThan_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_greaterThan_unknownInt_knownInt);
//       });
//       _ut.test('test_hasExactValue_bool_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_bool_false);
//       });
//       _ut.test('test_hasExactValue_bool_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_bool_true);
//       });
//       _ut.test('test_hasExactValue_bool_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_bool_unknown);
//       });
//       _ut.test('test_hasExactValue_double_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_double_known);
//       });
//       _ut.test('test_hasExactValue_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_double_unknown);
//       });
//       _ut.test('test_hasExactValue_dynamic', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_dynamic);
//       });
//       _ut.test('test_hasExactValue_int_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_int_known);
//       });
//       _ut.test('test_hasExactValue_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_int_unknown);
//       });
//       _ut.test('test_hasExactValue_list_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_list_empty);
//       });
//       _ut.test('test_hasExactValue_list_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_list_invalid);
//       });
//       _ut.test('test_hasExactValue_list_valid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_list_valid);
//       });
//       _ut.test('test_hasExactValue_map_empty', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_map_empty);
//       });
//       _ut.test('test_hasExactValue_map_invalidKey', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_map_invalidKey);
//       });
//       _ut.test('test_hasExactValue_map_invalidValue', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_map_invalidValue);
//       });
//       _ut.test('test_hasExactValue_map_valid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_map_valid);
//       });
//       _ut.test('test_hasExactValue_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_null);
//       });
//       _ut.test('test_hasExactValue_num', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_num);
//       });
//       _ut.test('test_hasExactValue_string_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_string_known);
//       });
//       _ut.test('test_hasExactValue_string_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_hasExactValue_string_unknown);
//       });
//       _ut.test('test_integerDivide_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_invalid_knownInt);
//       });
//       _ut.test('test_integerDivide_knownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownDouble_knownDouble);
//       });
//       _ut.test('test_integerDivide_knownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownDouble_knownInt);
//       });
//       _ut.test('test_integerDivide_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownDouble_unknownDouble);
//       });
//       _ut.test('test_integerDivide_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownDouble_unknownInt);
//       });
//       _ut.test('test_integerDivide_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownInt_invalid);
//       });
//       _ut.test('test_integerDivide_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownInt_knownInt);
//       });
//       _ut.test('test_integerDivide_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownInt_unknownDouble);
//       });
//       _ut.test('test_integerDivide_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_knownInt_unknownInt);
//       });
//       _ut.test('test_integerDivide_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_unknownDouble_knownDouble);
//       });
//       _ut.test('test_integerDivide_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_unknownDouble_knownInt);
//       });
//       _ut.test('test_integerDivide_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_unknownInt_knownDouble);
//       });
//       _ut.test('test_integerDivide_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_integerDivide_unknownInt_knownInt);
//       });
//       _ut.test('test_isBoolNumStringOrNull_bool_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_bool_false);
//       });
//       _ut.test('test_isBoolNumStringOrNull_bool_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_bool_true);
//       });
//       _ut.test('test_isBoolNumStringOrNull_bool_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_bool_unknown);
//       });
//       _ut.test('test_isBoolNumStringOrNull_double_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_double_known);
//       });
//       _ut.test('test_isBoolNumStringOrNull_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_double_unknown);
//       });
//       _ut.test('test_isBoolNumStringOrNull_dynamic', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_dynamic);
//       });
//       _ut.test('test_isBoolNumStringOrNull_int_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_int_known);
//       });
//       _ut.test('test_isBoolNumStringOrNull_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_int_unknown);
//       });
//       _ut.test('test_isBoolNumStringOrNull_list', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_list);
//       });
//       _ut.test('test_isBoolNumStringOrNull_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_null);
//       });
//       _ut.test('test_isBoolNumStringOrNull_num', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_num);
//       });
//       _ut.test('test_isBoolNumStringOrNull_string_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_string_known);
//       });
//       _ut.test('test_isBoolNumStringOrNull_string_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_isBoolNumStringOrNull_string_unknown);
//       });
//       _ut.test('test_lessThanOrEqual_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_invalid_knownInt);
//       });
//       _ut.test('test_lessThanOrEqual_knownDouble_knownDouble_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownDouble_knownDouble_false);
//       });
//       _ut.test('test_lessThanOrEqual_knownDouble_knownDouble_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownDouble_knownDouble_true);
//       });
//       _ut.test('test_lessThanOrEqual_knownDouble_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownDouble_knownInt_false);
//       });
//       _ut.test('test_lessThanOrEqual_knownDouble_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownDouble_knownInt_true);
//       });
//       _ut.test('test_lessThanOrEqual_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownDouble_unknownDouble);
//       });
//       _ut.test('test_lessThanOrEqual_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownDouble_unknownInt);
//       });
//       _ut.test('test_lessThanOrEqual_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownInt_invalid);
//       });
//       _ut.test('test_lessThanOrEqual_knownInt_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownInt_knownInt_false);
//       });
//       _ut.test('test_lessThanOrEqual_knownInt_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownInt_knownInt_true);
//       });
//       _ut.test('test_lessThanOrEqual_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownInt_unknownDouble);
//       });
//       _ut.test('test_lessThanOrEqual_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_knownInt_unknownInt);
//       });
//       _ut.test('test_lessThanOrEqual_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_unknownDouble_knownDouble);
//       });
//       _ut.test('test_lessThanOrEqual_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_unknownDouble_knownInt);
//       });
//       _ut.test('test_lessThanOrEqual_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_unknownInt_knownDouble);
//       });
//       _ut.test('test_lessThanOrEqual_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThanOrEqual_unknownInt_knownInt);
//       });
//       _ut.test('test_lessThan_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_invalid_knownInt);
//       });
//       _ut.test('test_lessThan_knownDouble_knownDouble_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownDouble_knownDouble_false);
//       });
//       _ut.test('test_lessThan_knownDouble_knownDouble_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownDouble_knownDouble_true);
//       });
//       _ut.test('test_lessThan_knownDouble_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownDouble_knownInt_false);
//       });
//       _ut.test('test_lessThan_knownDouble_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownDouble_knownInt_true);
//       });
//       _ut.test('test_lessThan_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownDouble_unknownDouble);
//       });
//       _ut.test('test_lessThan_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownDouble_unknownInt);
//       });
//       _ut.test('test_lessThan_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownInt_invalid);
//       });
//       _ut.test('test_lessThan_knownInt_knownInt_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownInt_knownInt_false);
//       });
//       _ut.test('test_lessThan_knownInt_knownInt_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownInt_knownInt_true);
//       });
//       _ut.test('test_lessThan_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownInt_unknownDouble);
//       });
//       _ut.test('test_lessThan_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_knownInt_unknownInt);
//       });
//       _ut.test('test_lessThan_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_unknownDouble_knownDouble);
//       });
//       _ut.test('test_lessThan_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_unknownDouble_knownInt);
//       });
//       _ut.test('test_lessThan_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_unknownInt_knownDouble);
//       });
//       _ut.test('test_lessThan_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_lessThan_unknownInt_knownInt);
//       });
//       _ut.test('test_logicalAnd_false_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_false_false);
//       });
//       _ut.test('test_logicalAnd_false_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_false_null);
//       });
//       _ut.test('test_logicalAnd_false_string', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_false_string);
//       });
//       _ut.test('test_logicalAnd_false_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_false_true);
//       });
//       _ut.test('test_logicalAnd_null_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_null_false);
//       });
//       _ut.test('test_logicalAnd_null_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_null_true);
//       });
//       _ut.test('test_logicalAnd_string_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_string_false);
//       });
//       _ut.test('test_logicalAnd_string_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_string_true);
//       });
//       _ut.test('test_logicalAnd_true_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_true_false);
//       });
//       _ut.test('test_logicalAnd_true_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_true_null);
//       });
//       _ut.test('test_logicalAnd_true_string', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_true_string);
//       });
//       _ut.test('test_logicalAnd_true_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalAnd_true_true);
//       });
//       _ut.test('test_logicalNot_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalNot_false);
//       });
//       _ut.test('test_logicalNot_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalNot_null);
//       });
//       _ut.test('test_logicalNot_string', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalNot_string);
//       });
//       _ut.test('test_logicalNot_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalNot_true);
//       });
//       _ut.test('test_logicalNot_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalNot_unknown);
//       });
//       _ut.test('test_logicalOr_false_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_false_false);
//       });
//       _ut.test('test_logicalOr_false_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_false_null);
//       });
//       _ut.test('test_logicalOr_false_string', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_false_string);
//       });
//       _ut.test('test_logicalOr_false_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_false_true);
//       });
//       _ut.test('test_logicalOr_null_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_null_false);
//       });
//       _ut.test('test_logicalOr_null_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_null_true);
//       });
//       _ut.test('test_logicalOr_string_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_string_false);
//       });
//       _ut.test('test_logicalOr_string_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_string_true);
//       });
//       _ut.test('test_logicalOr_true_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_true_false);
//       });
//       _ut.test('test_logicalOr_true_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_true_null);
//       });
//       _ut.test('test_logicalOr_true_string', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_true_string);
//       });
//       _ut.test('test_logicalOr_true_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_logicalOr_true_true);
//       });
//       _ut.test('test_minus_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_invalid_knownInt);
//       });
//       _ut.test('test_minus_knownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownDouble_knownDouble);
//       });
//       _ut.test('test_minus_knownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownDouble_knownInt);
//       });
//       _ut.test('test_minus_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownDouble_unknownDouble);
//       });
//       _ut.test('test_minus_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownDouble_unknownInt);
//       });
//       _ut.test('test_minus_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownInt_invalid);
//       });
//       _ut.test('test_minus_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownInt_knownInt);
//       });
//       _ut.test('test_minus_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownInt_unknownDouble);
//       });
//       _ut.test('test_minus_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_knownInt_unknownInt);
//       });
//       _ut.test('test_minus_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_unknownDouble_knownDouble);
//       });
//       _ut.test('test_minus_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_unknownDouble_knownInt);
//       });
//       _ut.test('test_minus_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_unknownInt_knownDouble);
//       });
//       _ut.test('test_minus_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_minus_unknownInt_knownInt);
//       });
//       _ut.test('test_negated_double_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_negated_double_known);
//       });
//       _ut.test('test_negated_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_negated_double_unknown);
//       });
//       _ut.test('test_negated_int_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_negated_int_known);
//       });
//       _ut.test('test_negated_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_negated_int_unknown);
//       });
//       _ut.test('test_negated_string', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_negated_string);
//       });
//       _ut.test('test_notEqual_bool_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_bool_false);
//       });
//       _ut.test('test_notEqual_bool_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_bool_true);
//       });
//       _ut.test('test_notEqual_bool_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_bool_unknown);
//       });
//       _ut.test('test_notEqual_double_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_double_false);
//       });
//       _ut.test('test_notEqual_double_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_double_true);
//       });
//       _ut.test('test_notEqual_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_double_unknown);
//       });
//       _ut.test('test_notEqual_int_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_int_false);
//       });
//       _ut.test('test_notEqual_int_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_int_true);
//       });
//       _ut.test('test_notEqual_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_int_unknown);
//       });
//       _ut.test('test_notEqual_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_null);
//       });
//       _ut.test('test_notEqual_string_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_string_false);
//       });
//       _ut.test('test_notEqual_string_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_string_true);
//       });
//       _ut.test('test_notEqual_string_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_notEqual_string_unknown);
//       });
//       _ut.test('test_performToString_bool_false', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_bool_false);
//       });
//       _ut.test('test_performToString_bool_true', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_bool_true);
//       });
//       _ut.test('test_performToString_bool_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_bool_unknown);
//       });
//       _ut.test('test_performToString_double_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_double_known);
//       });
//       _ut.test('test_performToString_double_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_double_unknown);
//       });
//       _ut.test('test_performToString_int_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_int_known);
//       });
//       _ut.test('test_performToString_int_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_int_unknown);
//       });
//       _ut.test('test_performToString_null', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_null);
//       });
//       _ut.test('test_performToString_string_known', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_string_known);
//       });
//       _ut.test('test_performToString_string_unknown', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_performToString_string_unknown);
//       });
//       _ut.test('test_remainder_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_invalid_knownInt);
//       });
//       _ut.test('test_remainder_knownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownDouble_knownDouble);
//       });
//       _ut.test('test_remainder_knownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownDouble_knownInt);
//       });
//       _ut.test('test_remainder_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownDouble_unknownDouble);
//       });
//       _ut.test('test_remainder_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownDouble_unknownInt);
//       });
//       _ut.test('test_remainder_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownInt_invalid);
//       });
//       _ut.test('test_remainder_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownInt_knownInt);
//       });
//       _ut.test('test_remainder_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownInt_unknownDouble);
//       });
//       _ut.test('test_remainder_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_knownInt_unknownInt);
//       });
//       _ut.test('test_remainder_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_unknownDouble_knownDouble);
//       });
//       _ut.test('test_remainder_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_unknownDouble_knownInt);
//       });
//       _ut.test('test_remainder_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_unknownInt_knownDouble);
//       });
//       _ut.test('test_remainder_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_remainder_unknownInt_knownInt);
//       });
//       _ut.test('test_shiftLeft_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_invalid_knownInt);
//       });
//       _ut.test('test_shiftLeft_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_knownInt_invalid);
//       });
//       _ut.test('test_shiftLeft_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_knownInt_knownInt);
//       });
//       _ut.test('test_shiftLeft_knownInt_tooLarge', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_knownInt_tooLarge);
//       });
//       _ut.test('test_shiftLeft_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_knownInt_unknownInt);
//       });
//       _ut.test('test_shiftLeft_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_unknownInt_knownInt);
//       });
//       _ut.test('test_shiftLeft_unknownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftLeft_unknownInt_unknownInt);
//       });
//       _ut.test('test_shiftRight_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_invalid_knownInt);
//       });
//       _ut.test('test_shiftRight_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_knownInt_invalid);
//       });
//       _ut.test('test_shiftRight_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_knownInt_knownInt);
//       });
//       _ut.test('test_shiftRight_knownInt_tooLarge', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_knownInt_tooLarge);
//       });
//       _ut.test('test_shiftRight_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_knownInt_unknownInt);
//       });
//       _ut.test('test_shiftRight_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_unknownInt_knownInt);
//       });
//       _ut.test('test_shiftRight_unknownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_shiftRight_unknownInt_unknownInt);
//       });
//       _ut.test('test_times_invalid_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_invalid_knownInt);
//       });
//       _ut.test('test_times_knownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownDouble_knownDouble);
//       });
//       _ut.test('test_times_knownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownDouble_knownInt);
//       });
//       _ut.test('test_times_knownDouble_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownDouble_unknownDouble);
//       });
//       _ut.test('test_times_knownDouble_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownDouble_unknownInt);
//       });
//       _ut.test('test_times_knownInt_invalid', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownInt_invalid);
//       });
//       _ut.test('test_times_knownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownInt_knownInt);
//       });
//       _ut.test('test_times_knownInt_unknownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownInt_unknownDouble);
//       });
//       _ut.test('test_times_knownInt_unknownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_knownInt_unknownInt);
//       });
//       _ut.test('test_times_unknownDouble_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_unknownDouble_knownDouble);
//       });
//       _ut.test('test_times_unknownDouble_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_unknownDouble_knownInt);
//       });
//       _ut.test('test_times_unknownInt_knownDouble', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_unknownInt_knownDouble);
//       });
//       _ut.test('test_times_unknownInt_knownInt', () {
//         final __test = new DartObjectImplTest();
//         runJUnitTest(__test, __test.test_times_unknownInt_knownInt);
//       });
//     });
//   }
// }
// class DartUriResolverTest extends JUnitTestCase {
//   void test_creation() {
//     JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
//     JUnitTestCase.assertNotNull(sdkDirectory);
//     DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
//     JUnitTestCase.assertNotNull(new DartUriResolver(sdk));
//   }
//   void test_isDartUri_null_scheme() {
//     Uri uri = parseUriWithException("foo.dart");
//     JUnitTestCase.assertNull(uri.scheme);
//     JUnitTestCase.assertFalse(DartUriResolver.isDartUri(uri));
//   }
//   void test_resolve_dart() {
//     JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
//     JUnitTestCase.assertNotNull(sdkDirectory);
//     DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
//     UriResolver resolver = new DartUriResolver(sdk);
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:core"));
//     JUnitTestCase.assertNotNull(result);
//   }
//   void test_resolve_dart_nonExistingLibrary() {
//     JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
//     JUnitTestCase.assertNotNull(sdkDirectory);
//     DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
//     UriResolver resolver = new DartUriResolver(sdk);
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:cor"));
//     JUnitTestCase.assertNull(result);
//   }
//   void test_resolve_nonDart() {
//     JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
//     JUnitTestCase.assertNotNull(sdkDirectory);
//     DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
//     UriResolver resolver = new DartUriResolver(sdk);
//     Source result = resolver.resolveAbsolute(parseUriWithException("package:some/file.dart"));
//     JUnitTestCase.assertNull(result);
//   }
//   static dartSuite() {
//     _ut.group('DartUriResolverTest', () {
//       _ut.test('test_creation', () {
//         final __test = new DartUriResolverTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_isDartUri_null_scheme', () {
//         final __test = new DartUriResolverTest();
//         runJUnitTest(__test, __test.test_isDartUri_null_scheme);
//       });
//       _ut.test('test_resolve_dart', () {
//         final __test = new DartUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_dart);
//       });
//       _ut.test('test_resolve_dart_nonExistingLibrary', () {
//         final __test = new DartUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_dart_nonExistingLibrary);
//       });
//       _ut.test('test_resolve_nonDart', () {
//         final __test = new DartUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_nonDart);
//       });
//     });
//   }
// }
// class DeclaredVariablesTest extends EngineTestCase {
//   void test_getBool_false() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     variables.define(variableName, "false");
//     DartObject object = variables.getBool(typeProvider, variableName);
//     JUnitTestCase.assertNotNull(object);
//     JUnitTestCase.assertEquals(false, object.boolValue);
//   }
//   void test_getBool_invalid() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     variables.define(variableName, "not true");
//     _assertNullDartObject(typeProvider, variables.getBool(typeProvider, variableName));
//   }
//   void test_getBool_true() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     variables.define(variableName, "true");
//     DartObject object = variables.getBool(typeProvider, variableName);
//     JUnitTestCase.assertNotNull(object);
//     JUnitTestCase.assertEquals(true, object.boolValue);
//   }
//   void test_getBool_undefined() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     _assertUnknownDartObject(variables.getBool(typeProvider, variableName));
//   }
//   void test_getInt_invalid() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     variables.define(variableName, "four score and seven years");
//     _assertNullDartObject(typeProvider, variables.getInt(typeProvider, variableName));
//   }
//   void test_getInt_undefined() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     _assertUnknownDartObject(variables.getInt(typeProvider, variableName));
//   }
//   void test_getInt_valid() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     variables.define(variableName, "23");
//     DartObject object = variables.getInt(typeProvider, variableName);
//     JUnitTestCase.assertNotNull(object);
//     JUnitTestCase.assertEquals(23, object.intValue);
//   }
//   void test_getString_defined() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     String value = "value";
//     DeclaredVariables variables = new DeclaredVariables();
//     variables.define(variableName, value);
//     DartObject object = variables.getString(typeProvider, variableName);
//     JUnitTestCase.assertNotNull(object);
//     JUnitTestCase.assertEquals(value, object.stringValue);
//   }
//   void test_getString_undefined() {
//     TestTypeProvider typeProvider = new TestTypeProvider();
//     String variableName = "var";
//     DeclaredVariables variables = new DeclaredVariables();
//     _assertUnknownDartObject(variables.getString(typeProvider, variableName));
//   }
//   void _assertNullDartObject(TestTypeProvider typeProvider, DartObject result) {
//     JUnitTestCase.assertEquals(typeProvider.nullType, result.type);
//   }
//   void _assertUnknownDartObject(DartObject result) {
//     JUnitTestCase.assertTrue((result as DartObjectImpl).isUnknown);
//   }
//   static dartSuite() {
//     _ut.group('DeclaredVariablesTest', () {
//       _ut.test('test_getBool_false', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getBool_false);
//       });
//       _ut.test('test_getBool_invalid', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getBool_invalid);
//       });
//       _ut.test('test_getBool_true', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getBool_true);
//       });
//       _ut.test('test_getBool_undefined', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getBool_undefined);
//       });
//       _ut.test('test_getInt_invalid', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getInt_invalid);
//       });
//       _ut.test('test_getInt_undefined', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getInt_undefined);
//       });
//       _ut.test('test_getInt_valid', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getInt_valid);
//       });
//       _ut.test('test_getString_defined', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getString_defined);
//       });
//       _ut.test('test_getString_undefined', () {
//         final __test = new DeclaredVariablesTest();
//         runJUnitTest(__test, __test.test_getString_undefined);
//       });
//     });
//   }
// }
// class DirectoryBasedDartSdkTest extends JUnitTestCase {
//   void fail_getDocFileFor() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile docFile = sdk.getDocFileFor("html");
//     JUnitTestCase.assertNotNull(docFile);
//   }
//   void test_creation() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JUnitTestCase.assertNotNull(sdk);
//   }
//   void test_fromFile_invalid() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JUnitTestCase.assertNull(sdk.fromFileUri(new JavaFile("/not/in/the/sdk.dart").toURI()));
//   }
//   void test_fromFile_library() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     Source source = sdk.fromFileUri(new JavaFile.relative(new JavaFile.relative(sdk.libraryDirectory, "core"), "core.dart").toURI());
//     JUnitTestCase.assertNotNull(source);
//     JUnitTestCase.assertTrue(source.isInSystemLibrary);
//     JUnitTestCase.assertEquals("dart:core", source.uri.toString());
//   }
//   void test_fromFile_part() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     Source source = sdk.fromFileUri(new JavaFile.relative(new JavaFile.relative(sdk.libraryDirectory, "core"), "num.dart").toURI());
//     JUnitTestCase.assertNotNull(source);
//     JUnitTestCase.assertTrue(source.isInSystemLibrary);
//     JUnitTestCase.assertEquals("dart:core/num.dart", source.uri.toString());
//   }
//   void test_getDart2JsExecutable() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile executable = sdk.dart2JsExecutable;
//     JUnitTestCase.assertNotNull(executable);
//     JUnitTestCase.assertTrue(executable.exists());
//     JUnitTestCase.assertTrue(executable.canExecute());
//   }
//   void test_getDartFmtExecutable() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile executable = sdk.dartFmtExecutable;
//     JUnitTestCase.assertNotNull(executable);
//     JUnitTestCase.assertTrue(executable.exists());
//     JUnitTestCase.assertTrue(executable.canExecute());
//   }
//   void test_getDirectory() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile directory = sdk.directory;
//     JUnitTestCase.assertNotNull(directory);
//     JUnitTestCase.assertTrue(directory.exists());
//   }
//   void test_getDocDirectory() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile directory = sdk.docDirectory;
//     JUnitTestCase.assertNotNull(directory);
//   }
//   void test_getLibraryDirectory() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile directory = sdk.libraryDirectory;
//     JUnitTestCase.assertNotNull(directory);
//     JUnitTestCase.assertTrue(directory.exists());
//   }
//   void test_getPubExecutable() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile executable = sdk.pubExecutable;
//     JUnitTestCase.assertNotNull(executable);
//     JUnitTestCase.assertTrue(executable.exists());
//     JUnitTestCase.assertTrue(executable.canExecute());
//   }
//   void test_getSdkVersion() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     String version = sdk.sdkVersion;
//     JUnitTestCase.assertNotNull(version);
//     JUnitTestCase.assertTrue(version.length > 0);
//   }
//   void test_getVmExecutable() {
//     DirectoryBasedDartSdk sdk = _createDartSdk();
//     JavaFile executable = sdk.vmExecutable;
//     JUnitTestCase.assertNotNull(executable);
//     JUnitTestCase.assertTrue(executable.exists());
//     JUnitTestCase.assertTrue(executable.canExecute());
//   }
//   DirectoryBasedDartSdk _createDartSdk() {
//     JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
//     JUnitTestCase.assertNotNullMsg("No SDK configured; set the property 'com.google.dart.sdk' on the command line", sdkDirectory);
//     return new DirectoryBasedDartSdk(sdkDirectory);
//   }
//   static dartSuite() {
//     _ut.group('DirectoryBasedDartSdkTest', () {
//       _ut.test('test_creation', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_fromFile_invalid', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_fromFile_invalid);
//       });
//       _ut.test('test_fromFile_library', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_fromFile_library);
//       });
//       _ut.test('test_fromFile_part', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_fromFile_part);
//       });
//       _ut.test('test_getDart2JsExecutable', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getDart2JsExecutable);
//       });
//       _ut.test('test_getDartFmtExecutable', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getDartFmtExecutable);
//       });
//       _ut.test('test_getDirectory', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getDirectory);
//       });
//       _ut.test('test_getDocDirectory', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getDocDirectory);
//       });
//       _ut.test('test_getLibraryDirectory', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getLibraryDirectory);
//       });
//       _ut.test('test_getPubExecutable', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getPubExecutable);
//       });
//       _ut.test('test_getSdkVersion', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getSdkVersion);
//       });
//       _ut.test('test_getVmExecutable', () {
//         final __test = new DirectoryBasedDartSdkTest();
//         runJUnitTest(__test, __test.test_getVmExecutable);
//       });
//     });
//   }
// }
// class DirectoryBasedSourceContainerTest extends JUnitTestCase {
//   void test_contains() {
//     JavaFile dir = FileUtilities2.createFile("/does/not/exist");
//     JavaFile file1 = FileUtilities2.createFile("/does/not/exist/some.dart");
//     JavaFile file2 = FileUtilities2.createFile("/does/not/exist/folder/some2.dart");
//     JavaFile file3 = FileUtilities2.createFile("/does/not/exist3/some3.dart");
//     FileBasedSource source1 = new FileBasedSource.con1(file1);
//     FileBasedSource source2 = new FileBasedSource.con1(file2);
//     FileBasedSource source3 = new FileBasedSource.con1(file3);
//     DirectoryBasedSourceContainer container = new DirectoryBasedSourceContainer.con1(dir);
//     JUnitTestCase.assertTrue(container.contains(source1));
//     JUnitTestCase.assertTrue(container.contains(source2));
//     JUnitTestCase.assertFalse(container.contains(source3));
//   }
//   static dartSuite() {
//     _ut.group('DirectoryBasedSourceContainerTest', () {
//       _ut.test('test_contains', () {
//         final __test = new DirectoryBasedSourceContainerTest();
//         runJUnitTest(__test, __test.test_contains);
//       });
//     });
//   }
// }
// class ElementBuilderTest extends EngineTestCase {
//   void test_visitCatchClause() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String exceptionParameterName = "e";
//     String stackParameterName = "s";
//     CatchClause clause = AstFactory.catchClause2(exceptionParameterName, stackParameterName, []);
//     clause.accept(builder);
//     List<LocalVariableElement> variables = holder.localVariables;
//     EngineTestCase.assertLength(2, variables);
//     VariableElement exceptionVariable = variables[0];
//     JUnitTestCase.assertNotNull(exceptionVariable);
//     JUnitTestCase.assertEquals(exceptionParameterName, exceptionVariable.name);
//     JUnitTestCase.assertFalse(exceptionVariable.isSynthetic);
//     JUnitTestCase.assertFalse(exceptionVariable.isConst);
//     JUnitTestCase.assertFalse(exceptionVariable.isFinal);
//     JUnitTestCase.assertNull(exceptionVariable.initializer);
//     VariableElement stackVariable = variables[1];
//     JUnitTestCase.assertNotNull(stackVariable);
//     JUnitTestCase.assertEquals(stackParameterName, stackVariable.name);
//     JUnitTestCase.assertFalse(stackVariable.isSynthetic);
//     JUnitTestCase.assertFalse(stackVariable.isConst);
//     JUnitTestCase.assertFalse(stackVariable.isFinal);
//     JUnitTestCase.assertNull(stackVariable.initializer);
//   }
//   void test_visitClassDeclaration_abstract() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "C";
//     ClassDeclaration classDeclaration = AstFactory.classDeclaration(Keyword.ABSTRACT, className, null, null, null, null, []);
//     classDeclaration.accept(builder);
//     List<ClassElement> types = holder.types;
//     EngineTestCase.assertLength(1, types);
//     ClassElement type = types[0];
//     JUnitTestCase.assertNotNull(type);
//     JUnitTestCase.assertEquals(className, type.name);
//     List<TypeParameterElement> typeParameters = type.typeParameters;
//     EngineTestCase.assertLength(0, typeParameters);
//     JUnitTestCase.assertTrue(type.isAbstract);
//     JUnitTestCase.assertFalse(type.isSynthetic);
//   }
//   void test_visitClassDeclaration_minimal() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "C";
//     ClassDeclaration classDeclaration = AstFactory.classDeclaration(null, className, null, null, null, null, []);
//     classDeclaration.accept(builder);
//     List<ClassElement> types = holder.types;
//     EngineTestCase.assertLength(1, types);
//     ClassElement type = types[0];
//     JUnitTestCase.assertNotNull(type);
//     JUnitTestCase.assertEquals(className, type.name);
//     List<TypeParameterElement> typeParameters = type.typeParameters;
//     EngineTestCase.assertLength(0, typeParameters);
//     JUnitTestCase.assertFalse(type.isAbstract);
//     JUnitTestCase.assertFalse(type.isSynthetic);
//   }
//   void test_visitClassDeclaration_parameterized() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "C";
//     String firstVariableName = "E";
//     String secondVariableName = "F";
//     ClassDeclaration classDeclaration = AstFactory.classDeclaration(null, className, AstFactory.typeParameterList([firstVariableName, secondVariableName]), null, null, null, []);
//     classDeclaration.accept(builder);
//     List<ClassElement> types = holder.types;
//     EngineTestCase.assertLength(1, types);
//     ClassElement type = types[0];
//     JUnitTestCase.assertNotNull(type);
//     JUnitTestCase.assertEquals(className, type.name);
//     List<TypeParameterElement> typeParameters = type.typeParameters;
//     EngineTestCase.assertLength(2, typeParameters);
//     JUnitTestCase.assertEquals(firstVariableName, typeParameters[0].name);
//     JUnitTestCase.assertEquals(secondVariableName, typeParameters[1].name);
//     JUnitTestCase.assertFalse(type.isAbstract);
//     JUnitTestCase.assertFalse(type.isSynthetic);
//   }
//   void test_visitClassDeclaration_withMembers() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "C";
//     String typeParameterName = "E";
//     String fieldName = "f";
//     String methodName = "m";
//     ClassDeclaration classDeclaration = AstFactory.classDeclaration(null, className, AstFactory.typeParameterList([typeParameterName]), null, null, null, [
//         AstFactory.fieldDeclaration2(false, null, [AstFactory.variableDeclaration(fieldName)]),
//         AstFactory.methodDeclaration2(null, null, null, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([]))]);
//     classDeclaration.accept(builder);
//     List<ClassElement> types = holder.types;
//     EngineTestCase.assertLength(1, types);
//     ClassElement type = types[0];
//     JUnitTestCase.assertNotNull(type);
//     JUnitTestCase.assertEquals(className, type.name);
//     JUnitTestCase.assertFalse(type.isAbstract);
//     JUnitTestCase.assertFalse(type.isSynthetic);
//     List<TypeParameterElement> typeParameters = type.typeParameters;
//     EngineTestCase.assertLength(1, typeParameters);
//     TypeParameterElement typeParameter = typeParameters[0];
//     JUnitTestCase.assertNotNull(typeParameter);
//     JUnitTestCase.assertEquals(typeParameterName, typeParameter.name);
//     List<FieldElement> fields = type.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(fieldName, field.name);
//     List<MethodElement> methods = type.methods;
//     EngineTestCase.assertLength(1, methods);
//     MethodElement method = methods[0];
//     JUnitTestCase.assertNotNull(method);
//     JUnitTestCase.assertEquals(methodName, method.name);
//   }
//   void test_visitConstructorDeclaration_factory() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "A";
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration2(null, Keyword.FACTORY, AstFactory.identifier3(className), null, AstFactory.formalParameterList([]), null, AstFactory.blockFunctionBody2([]));
//     constructorDeclaration.accept(builder);
//     List<ConstructorElement> constructors = holder.constructors;
//     EngineTestCase.assertLength(1, constructors);
//     ConstructorElement constructor = constructors[0];
//     JUnitTestCase.assertNotNull(constructor);
//     JUnitTestCase.assertTrue(constructor.isFactory);
//     JUnitTestCase.assertEquals("", constructor.name);
//     EngineTestCase.assertLength(0, constructor.functions);
//     EngineTestCase.assertLength(0, constructor.labels);
//     EngineTestCase.assertLength(0, constructor.localVariables);
//     EngineTestCase.assertLength(0, constructor.parameters);
//   }
//   void test_visitConstructorDeclaration_minimal() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "A";
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration2(null, null, AstFactory.identifier3(className), null, AstFactory.formalParameterList([]), null, AstFactory.blockFunctionBody2([]));
//     constructorDeclaration.accept(builder);
//     List<ConstructorElement> constructors = holder.constructors;
//     EngineTestCase.assertLength(1, constructors);
//     ConstructorElement constructor = constructors[0];
//     JUnitTestCase.assertNotNull(constructor);
//     JUnitTestCase.assertFalse(constructor.isFactory);
//     JUnitTestCase.assertEquals("", constructor.name);
//     EngineTestCase.assertLength(0, constructor.functions);
//     EngineTestCase.assertLength(0, constructor.labels);
//     EngineTestCase.assertLength(0, constructor.localVariables);
//     EngineTestCase.assertLength(0, constructor.parameters);
//   }
//   void test_visitConstructorDeclaration_named() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "A";
//     String constructorName = "c";
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration2(null, null, AstFactory.identifier3(className), constructorName, AstFactory.formalParameterList([]), null, AstFactory.blockFunctionBody2([]));
//     constructorDeclaration.accept(builder);
//     List<ConstructorElement> constructors = holder.constructors;
//     EngineTestCase.assertLength(1, constructors);
//     ConstructorElement constructor = constructors[0];
//     JUnitTestCase.assertNotNull(constructor);
//     JUnitTestCase.assertFalse(constructor.isFactory);
//     JUnitTestCase.assertEquals(constructorName, constructor.name);
//     EngineTestCase.assertLength(0, constructor.functions);
//     EngineTestCase.assertLength(0, constructor.labels);
//     EngineTestCase.assertLength(0, constructor.localVariables);
//     EngineTestCase.assertLength(0, constructor.parameters);
//     JUnitTestCase.assertSame(constructor, constructorDeclaration.name.staticElement);
//     JUnitTestCase.assertSame(constructor, constructorDeclaration.element);
//   }
//   void test_visitConstructorDeclaration_unnamed() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String className = "A";
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration2(null, null, AstFactory.identifier3(className), null, AstFactory.formalParameterList([]), null, AstFactory.blockFunctionBody2([]));
//     constructorDeclaration.accept(builder);
//     List<ConstructorElement> constructors = holder.constructors;
//     EngineTestCase.assertLength(1, constructors);
//     ConstructorElement constructor = constructors[0];
//     JUnitTestCase.assertNotNull(constructor);
//     JUnitTestCase.assertFalse(constructor.isFactory);
//     JUnitTestCase.assertEquals("", constructor.name);
//     EngineTestCase.assertLength(0, constructor.functions);
//     EngineTestCase.assertLength(0, constructor.labels);
//     EngineTestCase.assertLength(0, constructor.localVariables);
//     EngineTestCase.assertLength(0, constructor.parameters);
//     JUnitTestCase.assertSame(constructor, constructorDeclaration.element);
//   }
//   void test_visitEnumDeclaration() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String enumName = "E";
//     EnumDeclaration enumDeclaration = AstFactory.enumDeclaration2(enumName, ["ONE"]);
//     enumDeclaration.accept(builder);
//     List<ClassElement> enums = holder.enums;
//     EngineTestCase.assertLength(1, enums);
//     ClassElement enumElement = enums[0];
//     JUnitTestCase.assertNotNull(enumElement);
//     JUnitTestCase.assertEquals(enumName, enumElement.name);
//   }
//   void test_visitFieldDeclaration() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String firstFieldName = "x";
//     String secondFieldName = "y";
//     FieldDeclaration fieldDeclaration = AstFactory.fieldDeclaration2(false, null, [
//         AstFactory.variableDeclaration(firstFieldName),
//         AstFactory.variableDeclaration(secondFieldName)]);
//     fieldDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(2, fields);
//     FieldElement firstField = fields[0];
//     JUnitTestCase.assertNotNull(firstField);
//     JUnitTestCase.assertEquals(firstFieldName, firstField.name);
//     JUnitTestCase.assertNull(firstField.initializer);
//     JUnitTestCase.assertFalse(firstField.isConst);
//     JUnitTestCase.assertFalse(firstField.isFinal);
//     JUnitTestCase.assertFalse(firstField.isSynthetic);
//     FieldElement secondField = fields[1];
//     JUnitTestCase.assertNotNull(secondField);
//     JUnitTestCase.assertEquals(secondFieldName, secondField.name);
//     JUnitTestCase.assertNull(secondField.initializer);
//     JUnitTestCase.assertFalse(secondField.isConst);
//     JUnitTestCase.assertFalse(secondField.isFinal);
//     JUnitTestCase.assertFalse(secondField.isSynthetic);
//   }
//   void test_visitFieldFormalParameter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String parameterName = "p";
//     FieldFormalParameter formalParameter = AstFactory.fieldFormalParameter(null, null, parameterName);
//     formalParameter.accept(builder);
//     List<ParameterElement> parameters = holder.parameters;
//     EngineTestCase.assertLength(1, parameters);
//     ParameterElement parameter = parameters[0];
//     JUnitTestCase.assertNotNull(parameter);
//     JUnitTestCase.assertEquals(parameterName, parameter.name);
//     JUnitTestCase.assertNull(parameter.initializer);
//     JUnitTestCase.assertFalse(parameter.isConst);
//     JUnitTestCase.assertFalse(parameter.isFinal);
//     JUnitTestCase.assertFalse(parameter.isSynthetic);
//     JUnitTestCase.assertEquals(ParameterKind.REQUIRED, parameter.parameterKind);
//     EngineTestCase.assertLength(0, parameter.parameters);
//   }
//   void test_visitFieldFormalParameter_funtionTyped() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String parameterName = "p";
//     FieldFormalParameter formalParameter = AstFactory.fieldFormalParameter(null, null, parameterName, AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("a")]));
//     formalParameter.accept(builder);
//     List<ParameterElement> parameters = holder.parameters;
//     EngineTestCase.assertLength(1, parameters);
//     ParameterElement parameter = parameters[0];
//     JUnitTestCase.assertNotNull(parameter);
//     JUnitTestCase.assertEquals(parameterName, parameter.name);
//     JUnitTestCase.assertNull(parameter.initializer);
//     JUnitTestCase.assertFalse(parameter.isConst);
//     JUnitTestCase.assertFalse(parameter.isFinal);
//     JUnitTestCase.assertFalse(parameter.isSynthetic);
//     JUnitTestCase.assertEquals(ParameterKind.REQUIRED, parameter.parameterKind);
//     EngineTestCase.assertLength(1, parameter.parameters);
//   }
//   void test_visitFormalParameterList() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String firstParameterName = "a";
//     String secondParameterName = "b";
//     FormalParameterList parameterList = AstFactory.formalParameterList([
//         AstFactory.simpleFormalParameter3(firstParameterName),
//         AstFactory.simpleFormalParameter3(secondParameterName)]);
//     parameterList.accept(builder);
//     List<ParameterElement> parameters = holder.parameters;
//     EngineTestCase.assertLength(2, parameters);
//     JUnitTestCase.assertEquals(firstParameterName, parameters[0].name);
//     JUnitTestCase.assertEquals(secondParameterName, parameters[1].name);
//   }
//   void test_visitFunctionDeclaration_getter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String functionName = "f";
//     FunctionDeclaration declaration = AstFactory.functionDeclaration(null, Keyword.GET, functionName, AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([])));
//     declaration.accept(builder);
//     List<PropertyAccessorElement> accessors = holder.accessors;
//     EngineTestCase.assertLength(1, accessors);
//     PropertyAccessorElement accessor = accessors[0];
//     JUnitTestCase.assertNotNull(accessor);
//     JUnitTestCase.assertEquals(functionName, accessor.name);
//     JUnitTestCase.assertSame(accessor, declaration.element);
//     JUnitTestCase.assertSame(accessor, declaration.functionExpression.element);
//     JUnitTestCase.assertTrue(accessor.isGetter);
//     JUnitTestCase.assertFalse(accessor.isSetter);
//     JUnitTestCase.assertFalse(accessor.isSynthetic);
//     PropertyInducingElement variable = accessor.variable;
//     EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement, TopLevelVariableElement, variable);
//     JUnitTestCase.assertTrue(variable.isSynthetic);
//   }
//   void test_visitFunctionDeclaration_plain() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String functionName = "f";
//     FunctionDeclaration declaration = AstFactory.functionDeclaration(null, null, functionName, AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([])));
//     declaration.accept(builder);
//     List<FunctionElement> functions = holder.functions;
//     EngineTestCase.assertLength(1, functions);
//     FunctionElement function = functions[0];
//     JUnitTestCase.assertNotNull(function);
//     JUnitTestCase.assertEquals(functionName, function.name);
//     JUnitTestCase.assertSame(function, declaration.element);
//     JUnitTestCase.assertSame(function, declaration.functionExpression.element);
//     JUnitTestCase.assertFalse(function.isSynthetic);
//   }
//   void test_visitFunctionDeclaration_setter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String functionName = "f";
//     FunctionDeclaration declaration = AstFactory.functionDeclaration(null, Keyword.SET, functionName, AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([])));
//     declaration.accept(builder);
//     List<PropertyAccessorElement> accessors = holder.accessors;
//     EngineTestCase.assertLength(1, accessors);
//     PropertyAccessorElement accessor = accessors[0];
//     JUnitTestCase.assertNotNull(accessor);
//     JUnitTestCase.assertEquals("${functionName}=", accessor.name);
//     JUnitTestCase.assertSame(accessor, declaration.element);
//     JUnitTestCase.assertSame(accessor, declaration.functionExpression.element);
//     JUnitTestCase.assertFalse(accessor.isGetter);
//     JUnitTestCase.assertTrue(accessor.isSetter);
//     JUnitTestCase.assertFalse(accessor.isSynthetic);
//     PropertyInducingElement variable = accessor.variable;
//     EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement, TopLevelVariableElement, variable);
//     JUnitTestCase.assertTrue(variable.isSynthetic);
//   }
//   void test_visitFunctionExpression() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     FunctionExpression expression = AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([]));
//     expression.accept(builder);
//     List<FunctionElement> functions = holder.functions;
//     EngineTestCase.assertLength(1, functions);
//     FunctionElement function = functions[0];
//     JUnitTestCase.assertNotNull(function);
//     JUnitTestCase.assertSame(function, expression.element);
//     JUnitTestCase.assertFalse(function.isSynthetic);
//   }
//   void test_visitFunctionTypeAlias() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String aliasName = "F";
//     String parameterName = "E";
//     FunctionTypeAlias aliasNode = AstFactory.typeAlias(null, aliasName, AstFactory.typeParameterList([parameterName]), null);
//     aliasNode.accept(builder);
//     List<FunctionTypeAliasElement> aliases = holder.typeAliases;
//     EngineTestCase.assertLength(1, aliases);
//     FunctionTypeAliasElement alias = aliases[0];
//     JUnitTestCase.assertNotNull(alias);
//     JUnitTestCase.assertEquals(aliasName, alias.name);
//     EngineTestCase.assertLength(0, alias.parameters);
//     List<TypeParameterElement> typeParameters = alias.typeParameters;
//     EngineTestCase.assertLength(1, typeParameters);
//     TypeParameterElement typeParameter = typeParameters[0];
//     JUnitTestCase.assertNotNull(typeParameter);
//     JUnitTestCase.assertEquals(parameterName, typeParameter.name);
//   }
//   void test_visitFunctionTypedFormalParameter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String parameterName = "p";
//     FunctionTypedFormalParameter formalParameter = AstFactory.functionTypedFormalParameter(null, parameterName, []);
//     _useParameterInMethod(formalParameter, 100, 110);
//     formalParameter.accept(builder);
//     List<ParameterElement> parameters = holder.parameters;
//     EngineTestCase.assertLength(1, parameters);
//     ParameterElement parameter = parameters[0];
//     JUnitTestCase.assertNotNull(parameter);
//     JUnitTestCase.assertEquals(parameterName, parameter.name);
//     JUnitTestCase.assertNull(parameter.initializer);
//     JUnitTestCase.assertFalse(parameter.isConst);
//     JUnitTestCase.assertFalse(parameter.isFinal);
//     JUnitTestCase.assertFalse(parameter.isSynthetic);
//     JUnitTestCase.assertEquals(ParameterKind.REQUIRED, parameter.parameterKind);
//     JUnitTestCase.assertEquals(SourceRangeFactory.rangeStartEnd(100, 110), parameter.visibleRange);
//   }
//   void test_visitLabeledStatement() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String labelName = "l";
//     LabeledStatement statement = AstFactory.labeledStatement(AstFactory.list([AstFactory.label2(labelName)]), AstFactory.breakStatement());
//     statement.accept(builder);
//     List<LabelElement> labels = holder.labels;
//     EngineTestCase.assertLength(1, labels);
//     LabelElement label = labels[0];
//     JUnitTestCase.assertNotNull(label);
//     JUnitTestCase.assertEquals(labelName, label.name);
//     JUnitTestCase.assertFalse(label.isSynthetic);
//   }
//   void test_visitMethodDeclaration_abstract() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, null, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.emptyFunctionBody());
//     methodDeclaration.accept(builder);
//     List<MethodElement> methods = holder.methods;
//     EngineTestCase.assertLength(1, methods);
//     MethodElement method = methods[0];
//     JUnitTestCase.assertNotNull(method);
//     JUnitTestCase.assertEquals(methodName, method.name);
//     EngineTestCase.assertLength(0, method.functions);
//     EngineTestCase.assertLength(0, method.labels);
//     EngineTestCase.assertLength(0, method.localVariables);
//     EngineTestCase.assertLength(0, method.parameters);
//     JUnitTestCase.assertTrue(method.isAbstract);
//     JUnitTestCase.assertFalse(method.isStatic);
//     JUnitTestCase.assertFalse(method.isSynthetic);
//   }
//   void test_visitMethodDeclaration_getter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, Keyword.GET, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([]));
//     methodDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(methodName, field.name);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     JUnitTestCase.assertNull(field.setter);
//     PropertyAccessorElement getter = field.getter;
//     JUnitTestCase.assertNotNull(getter);
//     JUnitTestCase.assertFalse(getter.isAbstract);
//     JUnitTestCase.assertTrue(getter.isGetter);
//     JUnitTestCase.assertFalse(getter.isSynthetic);
//     JUnitTestCase.assertEquals(methodName, getter.name);
//     JUnitTestCase.assertEquals(field, getter.variable);
//     EngineTestCase.assertLength(0, getter.functions);
//     EngineTestCase.assertLength(0, getter.labels);
//     EngineTestCase.assertLength(0, getter.localVariables);
//     EngineTestCase.assertLength(0, getter.parameters);
//   }
//   void test_visitMethodDeclaration_getter_abstract() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, Keyword.GET, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.emptyFunctionBody());
//     methodDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(methodName, field.name);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     JUnitTestCase.assertNull(field.setter);
//     PropertyAccessorElement getter = field.getter;
//     JUnitTestCase.assertNotNull(getter);
//     JUnitTestCase.assertTrue(getter.isAbstract);
//     JUnitTestCase.assertTrue(getter.isGetter);
//     JUnitTestCase.assertFalse(getter.isSynthetic);
//     JUnitTestCase.assertEquals(methodName, getter.name);
//     JUnitTestCase.assertEquals(field, getter.variable);
//     EngineTestCase.assertLength(0, getter.functions);
//     EngineTestCase.assertLength(0, getter.labels);
//     EngineTestCase.assertLength(0, getter.localVariables);
//     EngineTestCase.assertLength(0, getter.parameters);
//   }
//   void test_visitMethodDeclaration_getter_external() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(null, null, Keyword.GET, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]));
//     methodDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(methodName, field.name);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     JUnitTestCase.assertNull(field.setter);
//     PropertyAccessorElement getter = field.getter;
//     JUnitTestCase.assertNotNull(getter);
//     JUnitTestCase.assertFalse(getter.isAbstract);
//     JUnitTestCase.assertTrue(getter.isGetter);
//     JUnitTestCase.assertFalse(getter.isSynthetic);
//     JUnitTestCase.assertEquals(methodName, getter.name);
//     JUnitTestCase.assertEquals(field, getter.variable);
//     EngineTestCase.assertLength(0, getter.functions);
//     EngineTestCase.assertLength(0, getter.labels);
//     EngineTestCase.assertLength(0, getter.localVariables);
//     EngineTestCase.assertLength(0, getter.parameters);
//   }
//   void test_visitMethodDeclaration_minimal() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, null, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([]));
//     methodDeclaration.accept(builder);
//     List<MethodElement> methods = holder.methods;
//     EngineTestCase.assertLength(1, methods);
//     MethodElement method = methods[0];
//     JUnitTestCase.assertNotNull(method);
//     JUnitTestCase.assertEquals(methodName, method.name);
//     EngineTestCase.assertLength(0, method.functions);
//     EngineTestCase.assertLength(0, method.labels);
//     EngineTestCase.assertLength(0, method.localVariables);
//     EngineTestCase.assertLength(0, method.parameters);
//     JUnitTestCase.assertFalse(method.isAbstract);
//     JUnitTestCase.assertFalse(method.isStatic);
//     JUnitTestCase.assertFalse(method.isSynthetic);
//   }
//   void test_visitMethodDeclaration_operator() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "+";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, null, Keyword.OPERATOR, AstFactory.identifier3(methodName), AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("addend")]), AstFactory.blockFunctionBody2([]));
//     methodDeclaration.accept(builder);
//     List<MethodElement> methods = holder.methods;
//     EngineTestCase.assertLength(1, methods);
//     MethodElement method = methods[0];
//     JUnitTestCase.assertNotNull(method);
//     JUnitTestCase.assertEquals(methodName, method.name);
//     EngineTestCase.assertLength(0, method.functions);
//     EngineTestCase.assertLength(0, method.labels);
//     EngineTestCase.assertLength(0, method.localVariables);
//     EngineTestCase.assertLength(1, method.parameters);
//     JUnitTestCase.assertFalse(method.isAbstract);
//     JUnitTestCase.assertFalse(method.isStatic);
//     JUnitTestCase.assertFalse(method.isSynthetic);
//   }
//   void test_visitMethodDeclaration_setter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, Keyword.SET, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([]));
//     methodDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(methodName, field.name);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     JUnitTestCase.assertNull(field.getter);
//     PropertyAccessorElement setter = field.setter;
//     JUnitTestCase.assertNotNull(setter);
//     JUnitTestCase.assertFalse(setter.isAbstract);
//     JUnitTestCase.assertTrue(setter.isSetter);
//     JUnitTestCase.assertFalse(setter.isSynthetic);
//     JUnitTestCase.assertEquals("${methodName}=", setter.name);
//     JUnitTestCase.assertEquals(methodName, setter.displayName);
//     JUnitTestCase.assertEquals(field, setter.variable);
//     EngineTestCase.assertLength(0, setter.functions);
//     EngineTestCase.assertLength(0, setter.labels);
//     EngineTestCase.assertLength(0, setter.localVariables);
//     EngineTestCase.assertLength(0, setter.parameters);
//   }
//   void test_visitMethodDeclaration_setter_abstract() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, Keyword.SET, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.emptyFunctionBody());
//     methodDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(methodName, field.name);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     JUnitTestCase.assertNull(field.getter);
//     PropertyAccessorElement setter = field.setter;
//     JUnitTestCase.assertNotNull(setter);
//     JUnitTestCase.assertTrue(setter.isAbstract);
//     JUnitTestCase.assertTrue(setter.isSetter);
//     JUnitTestCase.assertFalse(setter.isSynthetic);
//     JUnitTestCase.assertEquals("${methodName}=", setter.name);
//     JUnitTestCase.assertEquals(methodName, setter.displayName);
//     JUnitTestCase.assertEquals(field, setter.variable);
//     EngineTestCase.assertLength(0, setter.functions);
//     EngineTestCase.assertLength(0, setter.labels);
//     EngineTestCase.assertLength(0, setter.localVariables);
//     EngineTestCase.assertLength(0, setter.parameters);
//   }
//   void test_visitMethodDeclaration_setter_external() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(null, null, Keyword.SET, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]));
//     methodDeclaration.accept(builder);
//     List<FieldElement> fields = holder.fields;
//     EngineTestCase.assertLength(1, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals(methodName, field.name);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     JUnitTestCase.assertNull(field.getter);
//     PropertyAccessorElement setter = field.setter;
//     JUnitTestCase.assertNotNull(setter);
//     JUnitTestCase.assertFalse(setter.isAbstract);
//     JUnitTestCase.assertTrue(setter.isSetter);
//     JUnitTestCase.assertFalse(setter.isSynthetic);
//     JUnitTestCase.assertEquals("${methodName}=", setter.name);
//     JUnitTestCase.assertEquals(methodName, setter.displayName);
//     JUnitTestCase.assertEquals(field, setter.variable);
//     EngineTestCase.assertLength(0, setter.functions);
//     EngineTestCase.assertLength(0, setter.labels);
//     EngineTestCase.assertLength(0, setter.localVariables);
//     EngineTestCase.assertLength(0, setter.parameters);
//   }
//   void test_visitMethodDeclaration_static() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(Keyword.STATIC, null, null, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([]));
//     methodDeclaration.accept(builder);
//     List<MethodElement> methods = holder.methods;
//     EngineTestCase.assertLength(1, methods);
//     MethodElement method = methods[0];
//     JUnitTestCase.assertNotNull(method);
//     JUnitTestCase.assertEquals(methodName, method.name);
//     EngineTestCase.assertLength(0, method.functions);
//     EngineTestCase.assertLength(0, method.labels);
//     EngineTestCase.assertLength(0, method.localVariables);
//     EngineTestCase.assertLength(0, method.parameters);
//     JUnitTestCase.assertFalse(method.isAbstract);
//     JUnitTestCase.assertTrue(method.isStatic);
//     JUnitTestCase.assertFalse(method.isSynthetic);
//   }
//   void test_visitMethodDeclaration_withMembers() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String methodName = "m";
//     String parameterName = "p";
//     String localVariableName = "v";
//     String labelName = "l";
//     String exceptionParameterName = "e";
//     MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(null, null, null, null, AstFactory.identifier3(methodName), AstFactory.formalParameterList([AstFactory.simpleFormalParameter3(parameterName)]), AstFactory.blockFunctionBody2([
//         AstFactory.variableDeclarationStatement2(Keyword.VAR, [AstFactory.variableDeclaration(localVariableName)]),
//         AstFactory.tryStatement2(AstFactory.block([AstFactory.labeledStatement(AstFactory.list([AstFactory.label2(labelName)]), AstFactory.returnStatement())]), [AstFactory.catchClause(exceptionParameterName, [])])]));
//     methodDeclaration.accept(builder);
//     List<MethodElement> methods = holder.methods;
//     EngineTestCase.assertLength(1, methods);
//     MethodElement method = methods[0];
//     JUnitTestCase.assertNotNull(method);
//     JUnitTestCase.assertEquals(methodName, method.name);
//     JUnitTestCase.assertFalse(method.isAbstract);
//     JUnitTestCase.assertFalse(method.isStatic);
//     JUnitTestCase.assertFalse(method.isSynthetic);
//     List<VariableElement> parameters = method.parameters;
//     EngineTestCase.assertLength(1, parameters);
//     VariableElement parameter = parameters[0];
//     JUnitTestCase.assertNotNull(parameter);
//     JUnitTestCase.assertEquals(parameterName, parameter.name);
//     List<VariableElement> localVariables = method.localVariables;
//     EngineTestCase.assertLength(2, localVariables);
//     VariableElement firstVariable = localVariables[0];
//     VariableElement secondVariable = localVariables[1];
//     JUnitTestCase.assertNotNull(firstVariable);
//     JUnitTestCase.assertNotNull(secondVariable);
//     JUnitTestCase.assertTrue((firstVariable.name == localVariableName && secondVariable.name == exceptionParameterName) || (firstVariable.name == exceptionParameterName && secondVariable.name == localVariableName));
//     List<LabelElement> labels = method.labels;
//     EngineTestCase.assertLength(1, labels);
//     LabelElement label = labels[0];
//     JUnitTestCase.assertNotNull(label);
//     JUnitTestCase.assertEquals(labelName, label.name);
//   }
//   void test_visitNamedFormalParameter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String parameterName = "p";
//     DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(AstFactory.simpleFormalParameter3(parameterName), AstFactory.identifier3("b"));
//     _useParameterInMethod(formalParameter, 100, 110);
//     formalParameter.accept(builder);
//     List<ParameterElement> parameters = holder.parameters;
//     EngineTestCase.assertLength(1, parameters);
//     ParameterElement parameter = parameters[0];
//     JUnitTestCase.assertNotNull(parameter);
//     JUnitTestCase.assertEquals(parameterName, parameter.name);
//     JUnitTestCase.assertFalse(parameter.isConst);
//     JUnitTestCase.assertFalse(parameter.isFinal);
//     JUnitTestCase.assertFalse(parameter.isSynthetic);
//     JUnitTestCase.assertEquals(ParameterKind.NAMED, parameter.parameterKind);
//     JUnitTestCase.assertEquals(SourceRangeFactory.rangeStartEnd(100, 110), parameter.visibleRange);
//     FunctionElement initializer = parameter.initializer;
//     JUnitTestCase.assertNotNull(initializer);
//     JUnitTestCase.assertTrue(initializer.isSynthetic);
//   }
//   void test_visitSimpleFormalParameter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String parameterName = "p";
//     SimpleFormalParameter formalParameter = AstFactory.simpleFormalParameter3(parameterName);
//     _useParameterInMethod(formalParameter, 100, 110);
//     formalParameter.accept(builder);
//     List<ParameterElement> parameters = holder.parameters;
//     EngineTestCase.assertLength(1, parameters);
//     ParameterElement parameter = parameters[0];
//     JUnitTestCase.assertNotNull(parameter);
//     JUnitTestCase.assertEquals(parameterName, parameter.name);
//     JUnitTestCase.assertNull(parameter.initializer);
//     JUnitTestCase.assertFalse(parameter.isConst);
//     JUnitTestCase.assertFalse(parameter.isFinal);
//     JUnitTestCase.assertFalse(parameter.isSynthetic);
//     JUnitTestCase.assertEquals(ParameterKind.REQUIRED, parameter.parameterKind);
//     JUnitTestCase.assertEquals(SourceRangeFactory.rangeStartEnd(100, 110), parameter.visibleRange);
//   }
//   void test_visitTypeAlias_minimal() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String aliasName = "F";
//     TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, null, null);
//     typeAlias.accept(builder);
//     List<FunctionTypeAliasElement> aliases = holder.typeAliases;
//     EngineTestCase.assertLength(1, aliases);
//     FunctionTypeAliasElement alias = aliases[0];
//     JUnitTestCase.assertNotNull(alias);
//     JUnitTestCase.assertEquals(aliasName, alias.name);
//     JUnitTestCase.assertNotNull(alias.type);
//     JUnitTestCase.assertFalse(alias.isSynthetic);
//   }
//   void test_visitTypeAlias_withFormalParameters() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String aliasName = "F";
//     String firstParameterName = "x";
//     String secondParameterName = "y";
//     TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, AstFactory.typeParameterList([]), AstFactory.formalParameterList([
//         AstFactory.simpleFormalParameter3(firstParameterName),
//         AstFactory.simpleFormalParameter3(secondParameterName)]));
//     typeAlias.accept(builder);
//     List<FunctionTypeAliasElement> aliases = holder.typeAliases;
//     EngineTestCase.assertLength(1, aliases);
//     FunctionTypeAliasElement alias = aliases[0];
//     JUnitTestCase.assertNotNull(alias);
//     JUnitTestCase.assertEquals(aliasName, alias.name);
//     JUnitTestCase.assertNotNull(alias.type);
//     JUnitTestCase.assertFalse(alias.isSynthetic);
//     List<VariableElement> parameters = alias.parameters;
//     EngineTestCase.assertLength(2, parameters);
//     JUnitTestCase.assertEquals(firstParameterName, parameters[0].name);
//     JUnitTestCase.assertEquals(secondParameterName, parameters[1].name);
//     List<TypeParameterElement> typeParameters = alias.typeParameters;
//     JUnitTestCase.assertNotNull(typeParameters);
//     EngineTestCase.assertLength(0, typeParameters);
//   }
//   void test_visitTypeAlias_withTypeParameters() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String aliasName = "F";
//     String firstTypeParameterName = "A";
//     String secondTypeParameterName = "B";
//     TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, AstFactory.typeParameterList([firstTypeParameterName, secondTypeParameterName]), AstFactory.formalParameterList([]));
//     typeAlias.accept(builder);
//     List<FunctionTypeAliasElement> aliases = holder.typeAliases;
//     EngineTestCase.assertLength(1, aliases);
//     FunctionTypeAliasElement alias = aliases[0];
//     JUnitTestCase.assertNotNull(alias);
//     JUnitTestCase.assertEquals(aliasName, alias.name);
//     JUnitTestCase.assertNotNull(alias.type);
//     JUnitTestCase.assertFalse(alias.isSynthetic);
//     List<VariableElement> parameters = alias.parameters;
//     JUnitTestCase.assertNotNull(parameters);
//     EngineTestCase.assertLength(0, parameters);
//     List<TypeParameterElement> typeParameters = alias.typeParameters;
//     EngineTestCase.assertLength(2, typeParameters);
//     JUnitTestCase.assertEquals(firstTypeParameterName, typeParameters[0].name);
//     JUnitTestCase.assertEquals(secondTypeParameterName, typeParameters[1].name);
//   }
//   void test_visitTypeParameter() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String parameterName = "E";
//     TypeParameter typeParameter = AstFactory.typeParameter(parameterName);
//     typeParameter.accept(builder);
//     List<TypeParameterElement> typeParameters = holder.typeParameters;
//     EngineTestCase.assertLength(1, typeParameters);
//     TypeParameterElement typeParameterElement = typeParameters[0];
//     JUnitTestCase.assertNotNull(typeParameterElement);
//     JUnitTestCase.assertEquals(parameterName, typeParameterElement.name);
//     JUnitTestCase.assertNull(typeParameterElement.bound);
//     JUnitTestCase.assertFalse(typeParameterElement.isSynthetic);
//   }
//   void test_visitVariableDeclaration_inConstructor() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     //
//     // C() {var v;}
//     //
//     String variableName = "v";
//     VariableDeclaration variable = AstFactory.variableDeclaration2(variableName, null);
//     Statement statement = AstFactory.variableDeclarationStatement2(null, [variable]);
//     ConstructorDeclaration constructor = AstFactory.constructorDeclaration2(null, null, AstFactory.identifier3("C"), "C", AstFactory.formalParameterList([]), null, AstFactory.blockFunctionBody2([statement]));
//     constructor.accept(builder);
//     List<ConstructorElement> constructors = holder.constructors;
//     EngineTestCase.assertLength(1, constructors);
//     List<LocalVariableElement> variableElements = constructors[0].localVariables;
//     EngineTestCase.assertLength(1, variableElements);
//     LocalVariableElement variableElement = variableElements[0];
//     JUnitTestCase.assertEquals(variableName, variableElement.name);
//   }
//   void test_visitVariableDeclaration_inMethod() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     //
//     // m() {var v;}
//     //
//     String variableName = "v";
//     VariableDeclaration variable = AstFactory.variableDeclaration2(variableName, null);
//     Statement statement = AstFactory.variableDeclarationStatement2(null, [variable]);
//     MethodDeclaration constructor = AstFactory.methodDeclaration2(null, null, null, null, AstFactory.identifier3("m"), AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([statement]));
//     constructor.accept(builder);
//     List<MethodElement> methods = holder.methods;
//     EngineTestCase.assertLength(1, methods);
//     List<LocalVariableElement> variableElements = methods[0].localVariables;
//     EngineTestCase.assertLength(1, variableElements);
//     LocalVariableElement variableElement = variableElements[0];
//     JUnitTestCase.assertEquals(variableName, variableElement.name);
//   }
//   void test_visitVariableDeclaration_localNestedInField() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     //
//     // var f = () {var v;}
//     //
//     String variableName = "v";
//     VariableDeclaration variable = AstFactory.variableDeclaration2(variableName, null);
//     Statement statement = AstFactory.variableDeclarationStatement2(null, [variable]);
//     Expression initializer = AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.blockFunctionBody2([statement]));
//     String fieldName = "f";
//     VariableDeclaration field = AstFactory.variableDeclaration2(fieldName, initializer);
//     FieldDeclaration fieldDeclaration = AstFactory.fieldDeclaration2(false, null, [field]);
//     fieldDeclaration.accept(builder);
//     List<FieldElement> variables = holder.fields;
//     EngineTestCase.assertLength(1, variables);
//     FieldElement fieldElement = variables[0];
//     JUnitTestCase.assertNotNull(fieldElement);
//     FunctionElement initializerElement = fieldElement.initializer;
//     JUnitTestCase.assertNotNull(initializerElement);
//     List<FunctionElement> functionElements = initializerElement.functions;
//     EngineTestCase.assertLength(1, functionElements);
//     List<LocalVariableElement> variableElements = functionElements[0].localVariables;
//     EngineTestCase.assertLength(1, variableElements);
//     LocalVariableElement variableElement = variableElements[0];
//     JUnitTestCase.assertEquals(variableName, variableElement.name);
//     JUnitTestCase.assertFalse(variableElement.isConst);
//     JUnitTestCase.assertFalse(variableElement.isFinal);
//     JUnitTestCase.assertFalse(variableElement.isSynthetic);
//   }
//   void test_visitVariableDeclaration_noInitializer() {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder builder = new ElementBuilder(holder);
//     String variableName = "v";
//     VariableDeclaration variableDeclaration = AstFactory.variableDeclaration2(variableName, null);
//     AstFactory.variableDeclarationList2(null, [variableDeclaration]);
//     variableDeclaration.accept(builder);
//     List<TopLevelVariableElement> variables = holder.topLevelVariables;
//     EngineTestCase.assertLength(1, variables);
//     TopLevelVariableElement variable = variables[0];
//     JUnitTestCase.assertNotNull(variable);
//     JUnitTestCase.assertNull(variable.initializer);
//     JUnitTestCase.assertEquals(variableName, variable.name);
//     JUnitTestCase.assertFalse(variable.isConst);
//     JUnitTestCase.assertFalse(variable.isFinal);
//     JUnitTestCase.assertFalse(variable.isSynthetic);
//     JUnitTestCase.assertNotNull(variable.getter);
//     JUnitTestCase.assertNotNull(variable.setter);
//   }
//   void _useParameterInMethod(FormalParameter formalParameter, int blockOffset, int blockEnd) {
//     Block block = AstFactory.block([]);
//     block.leftBracket.offset = blockOffset;
//     block.rightBracket.offset = blockEnd - 1;
//     BlockFunctionBody body = AstFactory.blockFunctionBody(block);
//     AstFactory.methodDeclaration2(null, null, null, null, AstFactory.identifier3("main"), AstFactory.formalParameterList([formalParameter]), body);
//   }
//   static dartSuite() {
//     _ut.group('ElementBuilderTest', () {
//       _ut.test('test_visitCatchClause', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitCatchClause);
//       });
//       _ut.test('test_visitClassDeclaration_abstract', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitClassDeclaration_abstract);
//       });
//       _ut.test('test_visitClassDeclaration_minimal', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitClassDeclaration_minimal);
//       });
//       _ut.test('test_visitClassDeclaration_parameterized', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitClassDeclaration_parameterized);
//       });
//       _ut.test('test_visitClassDeclaration_withMembers', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitClassDeclaration_withMembers);
//       });
//       _ut.test('test_visitConstructorDeclaration_factory', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitConstructorDeclaration_factory);
//       });
//       _ut.test('test_visitConstructorDeclaration_minimal', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitConstructorDeclaration_minimal);
//       });
//       _ut.test('test_visitConstructorDeclaration_named', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitConstructorDeclaration_named);
//       });
//       _ut.test('test_visitConstructorDeclaration_unnamed', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitConstructorDeclaration_unnamed);
//       });
//       _ut.test('test_visitEnumDeclaration', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitEnumDeclaration);
//       });
//       _ut.test('test_visitFieldDeclaration', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFieldDeclaration);
//       });
//       _ut.test('test_visitFieldFormalParameter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFieldFormalParameter);
//       });
//       _ut.test('test_visitFieldFormalParameter_funtionTyped', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFieldFormalParameter_funtionTyped);
//       });
//       _ut.test('test_visitFormalParameterList', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFormalParameterList);
//       });
//       _ut.test('test_visitFunctionDeclaration_getter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFunctionDeclaration_getter);
//       });
//       _ut.test('test_visitFunctionDeclaration_plain', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFunctionDeclaration_plain);
//       });
//       _ut.test('test_visitFunctionDeclaration_setter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFunctionDeclaration_setter);
//       });
//       _ut.test('test_visitFunctionExpression', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFunctionExpression);
//       });
//       _ut.test('test_visitFunctionTypeAlias', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFunctionTypeAlias);
//       });
//       _ut.test('test_visitFunctionTypedFormalParameter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitFunctionTypedFormalParameter);
//       });
//       _ut.test('test_visitLabeledStatement', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitLabeledStatement);
//       });
//       _ut.test('test_visitMethodDeclaration_abstract', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_abstract);
//       });
//       _ut.test('test_visitMethodDeclaration_getter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_getter);
//       });
//       _ut.test('test_visitMethodDeclaration_getter_abstract', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_getter_abstract);
//       });
//       _ut.test('test_visitMethodDeclaration_getter_external', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_getter_external);
//       });
//       _ut.test('test_visitMethodDeclaration_minimal', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_minimal);
//       });
//       _ut.test('test_visitMethodDeclaration_operator', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_operator);
//       });
//       _ut.test('test_visitMethodDeclaration_setter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_setter);
//       });
//       _ut.test('test_visitMethodDeclaration_setter_abstract', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_setter_abstract);
//       });
//       _ut.test('test_visitMethodDeclaration_setter_external', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_setter_external);
//       });
//       _ut.test('test_visitMethodDeclaration_static', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_static);
//       });
//       _ut.test('test_visitMethodDeclaration_withMembers', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitMethodDeclaration_withMembers);
//       });
//       _ut.test('test_visitNamedFormalParameter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitNamedFormalParameter);
//       });
//       _ut.test('test_visitSimpleFormalParameter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitSimpleFormalParameter);
//       });
//       _ut.test('test_visitTypeAlias_minimal', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitTypeAlias_minimal);
//       });
//       _ut.test('test_visitTypeAlias_withFormalParameters', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitTypeAlias_withFormalParameters);
//       });
//       _ut.test('test_visitTypeAlias_withTypeParameters', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitTypeAlias_withTypeParameters);
//       });
//       _ut.test('test_visitTypeParameter', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitTypeParameter);
//       });
//       _ut.test('test_visitVariableDeclaration_inConstructor', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_inConstructor);
//       });
//       _ut.test('test_visitVariableDeclaration_inMethod', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_inMethod);
//       });
//       _ut.test('test_visitVariableDeclaration_localNestedInField', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_localNestedInField);
//       });
//       _ut.test('test_visitVariableDeclaration_noInitializer', () {
//         final __test = new ElementBuilderTest();
//         runJUnitTest(__test, __test.test_visitVariableDeclaration_noInitializer);
//       });
//     });
//   }
// }
// class ElementLocatorTest extends ResolverTestCase {
//   void fail_locate_ExportDirective() {
//     AstNode id = _findNodeIn("export", ["export 'dart:core';"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ImportElement, ImportElement, element);
//   }
//   void fail_locate_Identifier_libraryDirective() {
//     AstNode id = _findNodeIn("foo", ["library foo.bar;"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is LibraryElement, LibraryElement, element);
//   }
//   void fail_locate_Identifier_partOfDirective() {
//     // Can't resolve the library element without the library declaration.
//     //    AstNode id = findNodeIn("foo", "part of foo.bar;");
//     //    Element element = ElementLocator.locate(id);
//     //    assertInstanceOf(LibraryElement.class, element);
//     JUnitTestCase.fail("Test this case");
//   }
//   void test_locate_AssignmentExpression() {
//     AstNode id = _findNodeIn("+=", ["int x = 0;", "void main() {", "  x += 1;", "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_BinaryExpression() {
//     AstNode id = _findNodeIn("+", ["var x = 3 + 4;"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_ClassDeclaration() {
//     AstNode id = _findNodeIn("class", ["class A { }"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ClassElement, ClassElement, element);
//   }
//   void test_locate_CompilationUnit() {
//     CompilationUnit cu = _resolveContents(["// only comment"]);
//     JUnitTestCase.assertNotNull(cu.element);
//     Element element = ElementLocator.locate(cu);
//     JUnitTestCase.assertSame(cu.element, element);
//   }
//   void test_locate_ConstructorDeclaration() {
//     AstNode id = _findNodeIndexedIn("bar", 0, ["class A {", "  A.bar() {}", "}"]);
//     ConstructorDeclaration declaration = id.getAncestor((node) => node is ConstructorDeclaration);
//     Element element = ElementLocator.locate(declaration);
//     EngineTestCase.assertInstanceOf((obj) => obj is ConstructorElement, ConstructorElement, element);
//   }
//   void test_locate_FunctionDeclaration() {
//     AstNode id = _findNodeIn("f", ["int f() => 3;"]);
//     FunctionDeclaration declaration = id.getAncestor((node) => node is FunctionDeclaration);
//     Element element = ElementLocator.locate(declaration);
//     EngineTestCase.assertInstanceOf((obj) => obj is FunctionElement, FunctionElement, element);
//   }
//   void test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter() {
//     AstNode id = _findNodeIndexedIn("Class", 2, [
//         "class Class {",
//         "  const Class.name();",
//         "}",
//         "void main(@Class.name() parameter) {",
//         "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ClassElement, ClassElement, element);
//   }
//   void test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter() {
//     AstNode id = _findNodeIndexedIn("Class", 2, [
//         "class Class {",
//         "  const Class();",
//         "}",
//         "void main(@Class() parameter) {",
//         "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ConstructorElement, ConstructorElement, element);
//   }
//   void test_locate_Identifier_className() {
//     AstNode id = _findNodeIn("A", ["class A { }"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ClassElement, ClassElement, element);
//   }
//   void test_locate_Identifier_constructor_named() {
//     AstNode id = _findNodeIndexedIn("bar", 0, ["class A {", "  A.bar() {}", "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ConstructorElement, ConstructorElement, element);
//   }
//   void test_locate_Identifier_constructor_unnamed() {
//     AstNode id = _findNodeIndexedIn("A", 1, ["class A {", "  A() {}", "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ConstructorElement, ConstructorElement, element);
//   }
//   void test_locate_Identifier_fieldName() {
//     AstNode id = _findNodeIn("x", ["class A { var x; }"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is FieldElement, FieldElement, element);
//   }
//   void test_locate_Identifier_propertAccess() {
//     AstNode id = _findNodeIn("length", ["void main() {", " int x = 'foo'.length;", "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement, PropertyAccessorElement, element);
//   }
//   void test_locate_ImportDirective() {
//     AstNode id = _findNodeIn("import", ["import 'dart:core';"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is ImportElement, ImportElement, element);
//   }
//   void test_locate_IndexExpression() {
//     AstNode id = _findNodeIndexedIn("\\[", 1, [
//         "void main() {",
//         "  List x = [1, 2];",
//         "  var y = x[0];",
//         "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_InstanceCreationExpression() {
//     AstNode node = _findNodeIndexedIn("A(", 0, ["class A {}", "void main() {", " new A();", "}"]);
//     Element element = ElementLocator.locate(node);
//     EngineTestCase.assertInstanceOf((obj) => obj is ConstructorElement, ConstructorElement, element);
//   }
//   void test_locate_InstanceCreationExpression_type_prefixedIdentifier() {
//     // prepare: new pref.A()
//     SimpleIdentifier identifier = AstFactory.identifier3("A");
//     PrefixedIdentifier prefixedIdentifier = AstFactory.identifier4("pref", identifier);
//     InstanceCreationExpression creation = AstFactory.instanceCreationExpression2(Keyword.NEW, AstFactory.typeName3(prefixedIdentifier, []), []);
//     // set ConstructorElement
//     ClassElement classElement = ElementFactory.classElement2("A", []);
//     ConstructorElement constructorElement = ElementFactory.constructorElement2(classElement, null, []);
//     creation.constructorName.staticElement = constructorElement;
//     // verify that "A" is resolved to ConstructorElement
//     Element element = ElementLocator.locate(identifier);
//     JUnitTestCase.assertSame(constructorElement, element);
//   }
//   void test_locate_InstanceCreationExpression_type_simpleIdentifier() {
//     // prepare: new A()
//     SimpleIdentifier identifier = AstFactory.identifier3("A");
//     InstanceCreationExpression creation = AstFactory.instanceCreationExpression2(Keyword.NEW, AstFactory.typeName3(identifier, []), []);
//     // set ConstructorElement
//     ClassElement classElement = ElementFactory.classElement2("A", []);
//     ConstructorElement constructorElement = ElementFactory.constructorElement2(classElement, null, []);
//     creation.constructorName.staticElement = constructorElement;
//     // verify that "A" is resolved to ConstructorElement
//     Element element = ElementLocator.locate(identifier);
//     JUnitTestCase.assertSame(constructorElement, element);
//   }
//   void test_locate_LibraryDirective() {
//     AstNode id = _findNodeIn("library", ["library foo;"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is LibraryElement, LibraryElement, element);
//   }
//   void test_locate_MethodDeclaration() {
//     AstNode id = _findNodeIn("m", ["class A {", "  void m() {}", "}"]);
//     MethodDeclaration declaration = id.getAncestor((node) => node is MethodDeclaration);
//     Element element = ElementLocator.locate(declaration);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_MethodInvocation_method() {
//     AstNode id = _findNodeIndexedIn("bar", 1, [
//         "class A {",
//         "  int bar() => 42;",
//         "}",
//         "void main() {",
//         " var f = new A().bar();",
//         "}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_MethodInvocation_topLevel() {
//     String contents = EngineTestCase.createSource(["foo(x) {}", "void main() {", " foo(0);", "}"]);
//     CompilationUnit cu = _resolveContents([contents]);
//     MethodInvocation node = AbstractDartTest.findNode(cu, contents.indexOf("foo(0)"), MethodInvocation);
//     Element element = ElementLocator.locate(node);
//     EngineTestCase.assertInstanceOf((obj) => obj is FunctionElement, FunctionElement, element);
//   }
//   void test_locate_PostfixExpression() {
//     AstNode id = _findNodeIn("++", ["int addOne(int x) => x++;"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_PrefixedIdentifier() {
//     AstNode id = _findNodeIn("int", ["import 'dart:core' as core;", "core.int value;"]);
//     PrefixedIdentifier identifier = id.getAncestor((node) => node is PrefixedIdentifier);
//     Element element = ElementLocator.locate(identifier);
//     EngineTestCase.assertInstanceOf((obj) => obj is ClassElement, ClassElement, element);
//   }
//   void test_locate_PrefixExpression() {
//     AstNode id = _findNodeIn("++", ["int addOne(int x) => ++x;"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locate_StringLiteral_exportUri() {
//     addNamedSource("/foo.dart", "library foo;");
//     AstNode id = _findNodeIn("'foo.dart'", ["export 'foo.dart';"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is LibraryElement, LibraryElement, element);
//   }
//   void test_locate_StringLiteral_expression() {
//     AstNode id = _findNodeIn("abc", ["var x = 'abc';"]);
//     Element element = ElementLocator.locate(id);
//     JUnitTestCase.assertNull(element);
//   }
//   void test_locate_StringLiteral_importUri() {
//     addNamedSource("/foo.dart", "library foo; class A {}");
//     AstNode id = _findNodeIn("'foo.dart'", ["import 'foo.dart'; class B extends A {}"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is LibraryElement, LibraryElement, element);
//   }
//   void test_locate_StringLiteral_partUri() {
//     addNamedSource("/foo.dart", "part of app;");
//     AstNode id = _findNodeIn("'foo.dart'", ["library app; part 'foo.dart';"]);
//     Element element = ElementLocator.locate(id);
//     EngineTestCase.assertInstanceOf((obj) => obj is CompilationUnitElement, CompilationUnitElement, element);
//   }
//   void test_locate_VariableDeclaration() {
//     AstNode id = _findNodeIn("x", ["var x = 'abc';"]);
//     VariableDeclaration declaration = id.getAncestor((node) => node is VariableDeclaration);
//     Element element = ElementLocator.locate(declaration);
//     EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement, TopLevelVariableElement, element);
//   }
//   void test_locateWithOffset_BinaryExpression() {
//     AstNode id = _findNodeIn("+", ["var x = 3 + 4;"]);
//     Element element = ElementLocator.locateWithOffset(id, 0);
//     EngineTestCase.assertInstanceOf((obj) => obj is MethodElement, MethodElement, element);
//   }
//   void test_locateWithOffset_StringLiteral() {
//     AstNode id = _findNodeIn("abc", ["var x = 'abc';"]);
//     Element element = ElementLocator.locateWithOffset(id, 1);
//     JUnitTestCase.assertNull(element);
//   }
//   @override
//   void reset() {
//     AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
//     analysisOptions.hint = false;
//     resetWithOptions(analysisOptions);
//   }
//   /**
//    * Find the first AST node matching a pattern in the resolved AST for the given source.
//    *
//    * @param nodePattern the (unique) pattern used to identify the node of interest
//    * @param lines the lines to be merged into a single source string
//    * @return the matched node in the resolved AST for the given source lines
//    * @throws Exception if source cannot be verified
//    */
//   AstNode _findNodeIn(String nodePattern, List<String> lines) => _findNodeIndexedIn(nodePattern, 0, lines);
//   /**
//    * Find the AST node matching the given indexed occurrence of a pattern in the resolved AST for
//    * the given source.
//    *
//    * @param nodePattern the pattern used to identify the node of interest
//    * @param index the index of the pattern match of interest
//    * @param lines the lines to be merged into a single source string
//    * @return the matched node in the resolved AST for the given source lines
//    * @throws Exception if source cannot be verified
//    */
//   AstNode _findNodeIndexedIn(String nodePattern, int index, List<String> lines) {
//     String contents = EngineTestCase.createSource(lines);
//     CompilationUnit cu = _resolveContents([contents]);
//     int start = _getOffsetOfMatch(contents, nodePattern, index);
//     int end = start + nodePattern.length;
//     return new NodeLocator.con2(start, end).searchWithin(cu);
//   }
//   int _getOffsetOfMatch(String contents, String pattern, int matchIndex) {
//     if (matchIndex == 0) {
//       return contents.indexOf(pattern);
//     }
//     JavaPatternMatcher matcher = new JavaPatternMatcher(new RegExp(pattern), contents);
//     int count = 0;
//     while (matcher.find()) {
//       if (count == matchIndex) {
//         return matcher.start();
//       }
//       ++count;
//     }
//     return -1;
//   }
//   /**
//    * Parse, resolve and verify the given source lines to produce a fully resolved AST.
//    *
//    * @param lines the lines to be merged into a single source string
//    * @return the result of resolving the AST structure representing the content of the source
//    * @throws Exception if source cannot be verified
//    */
//   CompilationUnit _resolveContents(List<String> lines) {
//     Source source = addSource(EngineTestCase.createSource(lines));
//     LibraryElement library = resolve(source);
//     assertNoErrors(source);
//     verify([source]);
//     return analysisContext.resolveCompilationUnit(source, library);
//   }
//   static dartSuite() {
//     _ut.group('ElementLocatorTest', () {
//       _ut.test('test_locateWithOffset_BinaryExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locateWithOffset_BinaryExpression);
//       });
//       _ut.test('test_locateWithOffset_StringLiteral', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locateWithOffset_StringLiteral);
//       });
//       _ut.test('test_locate_AssignmentExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_AssignmentExpression);
//       });
//       _ut.test('test_locate_BinaryExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_BinaryExpression);
//       });
//       _ut.test('test_locate_ClassDeclaration', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_ClassDeclaration);
//       });
//       _ut.test('test_locate_CompilationUnit', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_CompilationUnit);
//       });
//       _ut.test('test_locate_ConstructorDeclaration', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_ConstructorDeclaration);
//       });
//       _ut.test('test_locate_FunctionDeclaration', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_FunctionDeclaration);
//       });
//       _ut.test('test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter);
//       });
//       _ut.test('test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter);
//       });
//       _ut.test('test_locate_Identifier_className', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_className);
//       });
//       _ut.test('test_locate_Identifier_constructor_named', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_constructor_named);
//       });
//       _ut.test('test_locate_Identifier_constructor_unnamed', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_constructor_unnamed);
//       });
//       _ut.test('test_locate_Identifier_fieldName', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_fieldName);
//       });
//       _ut.test('test_locate_Identifier_propertAccess', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_Identifier_propertAccess);
//       });
//       _ut.test('test_locate_ImportDirective', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_ImportDirective);
//       });
//       _ut.test('test_locate_IndexExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_IndexExpression);
//       });
//       _ut.test('test_locate_InstanceCreationExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_InstanceCreationExpression);
//       });
//       _ut.test('test_locate_InstanceCreationExpression_type_prefixedIdentifier', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_InstanceCreationExpression_type_prefixedIdentifier);
//       });
//       _ut.test('test_locate_InstanceCreationExpression_type_simpleIdentifier', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_InstanceCreationExpression_type_simpleIdentifier);
//       });
//       _ut.test('test_locate_LibraryDirective', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_LibraryDirective);
//       });
//       _ut.test('test_locate_MethodDeclaration', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_MethodDeclaration);
//       });
//       _ut.test('test_locate_MethodInvocation_method', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_MethodInvocation_method);
//       });
//       _ut.test('test_locate_MethodInvocation_topLevel', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_MethodInvocation_topLevel);
//       });
//       _ut.test('test_locate_PostfixExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_PostfixExpression);
//       });
//       _ut.test('test_locate_PrefixExpression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_PrefixExpression);
//       });
//       _ut.test('test_locate_PrefixedIdentifier', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_PrefixedIdentifier);
//       });
//       _ut.test('test_locate_StringLiteral_exportUri', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_StringLiteral_exportUri);
//       });
//       _ut.test('test_locate_StringLiteral_expression', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_StringLiteral_expression);
//       });
//       _ut.test('test_locate_StringLiteral_importUri', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_StringLiteral_importUri);
//       });
//       _ut.test('test_locate_StringLiteral_partUri', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_StringLiteral_partUri);
//       });
//       _ut.test('test_locate_VariableDeclaration', () {
//         final __test = new ElementLocatorTest();
//         runJUnitTest(__test, __test.test_locate_VariableDeclaration);
//       });
//     });
//   }
// }
// class EnumMemberBuilderTest extends EngineTestCase {
//   void test_visitEnumDeclaration_multiple() {
//     String firstName = "ONE";
//     String secondName = "TWO";
//     String thirdName = "THREE";
//     EnumDeclaration enumDeclaration = AstFactory.enumDeclaration2("E", [firstName, secondName, thirdName]);
//     ClassElement enumElement = _buildElement(enumDeclaration);
//     List<FieldElement> fields = enumElement.fields;
//     EngineTestCase.assertLength(5, fields);
//     FieldElement constant = fields[2];
//     JUnitTestCase.assertNotNull(constant);
//     JUnitTestCase.assertEquals(firstName, constant.name);
//     JUnitTestCase.assertTrue(constant.isStatic);
//     constant = fields[3];
//     JUnitTestCase.assertNotNull(constant);
//     JUnitTestCase.assertEquals(secondName, constant.name);
//     JUnitTestCase.assertTrue(constant.isStatic);
//     constant = fields[4];
//     JUnitTestCase.assertNotNull(constant);
//     JUnitTestCase.assertEquals(thirdName, constant.name);
//     JUnitTestCase.assertTrue(constant.isStatic);
//   }
//   void test_visitEnumDeclaration_single() {
//     String firstName = "ONE";
//     EnumDeclaration enumDeclaration = AstFactory.enumDeclaration2("E", [firstName]);
//     ClassElement enumElement = _buildElement(enumDeclaration);
//     List<FieldElement> fields = enumElement.fields;
//     EngineTestCase.assertLength(3, fields);
//     FieldElement field = fields[0];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals("index", field.name);
//     JUnitTestCase.assertFalse(field.isStatic);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     field = fields[1];
//     JUnitTestCase.assertNotNull(field);
//     JUnitTestCase.assertEquals("values", field.name);
//     JUnitTestCase.assertTrue(field.isStatic);
//     JUnitTestCase.assertTrue(field.isSynthetic);
//     FieldElement constant = fields[2];
//     JUnitTestCase.assertNotNull(constant);
//     JUnitTestCase.assertEquals(firstName, constant.name);
//     JUnitTestCase.assertTrue(constant.isStatic);
//   }
//   ClassElement _buildElement(EnumDeclaration enumDeclaration) {
//     ElementHolder holder = new ElementHolder();
//     ElementBuilder elementBuilder = new ElementBuilder(holder);
//     enumDeclaration.accept(elementBuilder);
//     EnumMemberBuilder memberBuilder = new EnumMemberBuilder(new TestTypeProvider());
//     enumDeclaration.accept(memberBuilder);
//     List<ClassElement> enums = holder.enums;
//     EngineTestCase.assertLength(1, enums);
//     return enums[0];
//   }
//   static dartSuite() {
//     _ut.group('EnumMemberBuilderTest', () {
//       _ut.test('test_visitEnumDeclaration_multiple', () {
//         final __test = new EnumMemberBuilderTest();
//         runJUnitTest(__test, __test.test_visitEnumDeclaration_multiple);
//       });
//       _ut.test('test_visitEnumDeclaration_single', () {
//         final __test = new EnumMemberBuilderTest();
//         runJUnitTest(__test, __test.test_visitEnumDeclaration_single);
//       });
//     });
//   }
// }
// class ErrorReporterTest extends EngineTestCase {
//   /**
//    * Create a type with the given name in a compilation unit with the given name.
//    *
//    * @param fileName the name of the compilation unit containing the class
//    * @param typeName the name of the type to be created
//    * @return the type that was created
//    */
//   InterfaceType createType(String fileName, String typeName) {
//     CompilationUnitElementImpl unit = ElementFactory.compilationUnit(fileName);
//     ClassElementImpl element = ElementFactory.classElement2(typeName, []);
//     unit.types = <ClassElement> [element];
//     return element.type;
//   }
//   void test_creation() {
//     GatheringErrorListener listener = new GatheringErrorListener();
//     TestSource source = new TestSource();
//     JUnitTestCase.assertNotNull(new ErrorReporter(listener, source));
//   }
//   void test_reportTypeErrorForNode_differentNames() {
//     DartType firstType = createType("/test1.dart", "A");
//     DartType secondType = createType("/test2.dart", "B");
//     GatheringErrorListener listener = new GatheringErrorListener();
//     ErrorReporter reporter = new ErrorReporter(listener, firstType.element.source);
//     reporter.reportTypeErrorForNode(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, AstFactory.identifier3("x"), [firstType, secondType]);
//     AnalysisError error = listener.errors[0];
//     JUnitTestCase.assertTrue(error.message.indexOf("(") < 0);
//   }
//   void test_reportTypeErrorForNode_sameName() {
//     String typeName = "A";
//     DartType firstType = createType("/test1.dart", typeName);
//     DartType secondType = createType("/test2.dart", typeName);
//     GatheringErrorListener listener = new GatheringErrorListener();
//     ErrorReporter reporter = new ErrorReporter(listener, firstType.element.source);
//     reporter.reportTypeErrorForNode(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, AstFactory.identifier3("x"), [firstType, secondType]);
//     AnalysisError error = listener.errors[0];
//     JUnitTestCase.assertTrue(error.message.indexOf("(") >= 0);
//   }
//   static dartSuite() {
//     _ut.group('ErrorReporterTest', () {
//       _ut.test('test_creation', () {
//         final __test = new ErrorReporterTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_reportTypeErrorForNode_differentNames', () {
//         final __test = new ErrorReporterTest();
//         runJUnitTest(__test, __test.test_reportTypeErrorForNode_differentNames);
//       });
//       _ut.test('test_reportTypeErrorForNode_sameName', () {
//         final __test = new ErrorReporterTest();
//         runJUnitTest(__test, __test.test_reportTypeErrorForNode_sameName);
//       });
//     });
//   }
// }
// class ErrorSeverityTest extends EngineTestCase {
//   void test_max_error_error() {
//     JUnitTestCase.assertSame(ErrorSeverity.ERROR, ERROR.max(ErrorSeverity.ERROR));
//   }
//   void test_max_error_none() {
//     JUnitTestCase.assertSame(ErrorSeverity.ERROR, ERROR.max(ErrorSeverity.NONE));
//   }
//   void test_max_error_warning() {
//     JUnitTestCase.assertSame(ErrorSeverity.ERROR, ERROR.max(ErrorSeverity.WARNING));
//   }
//   void test_max_none_error() {
//     JUnitTestCase.assertSame(ErrorSeverity.ERROR, NONE.max(ErrorSeverity.ERROR));
//   }
//   void test_max_none_none() {
//     JUnitTestCase.assertSame(ErrorSeverity.NONE, NONE.max(ErrorSeverity.NONE));
//   }
//   void test_max_none_warning() {
//     JUnitTestCase.assertSame(ErrorSeverity.WARNING, NONE.max(ErrorSeverity.WARNING));
//   }
//   void test_max_warning_error() {
//     JUnitTestCase.assertSame(ErrorSeverity.ERROR, WARNING.max(ErrorSeverity.ERROR));
//   }
//   void test_max_warning_none() {
//     JUnitTestCase.assertSame(ErrorSeverity.WARNING, WARNING.max(ErrorSeverity.NONE));
//   }
//   void test_max_warning_warning() {
//     JUnitTestCase.assertSame(ErrorSeverity.WARNING, WARNING.max(ErrorSeverity.WARNING));
//   }
//   static dartSuite() {
//     _ut.group('ErrorSeverityTest', () {
//       _ut.test('test_max_error_error', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_error_error);
//       });
//       _ut.test('test_max_error_none', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_error_none);
//       });
//       _ut.test('test_max_error_warning', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_error_warning);
//       });
//       _ut.test('test_max_none_error', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_none_error);
//       });
//       _ut.test('test_max_none_none', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_none_none);
//       });
//       _ut.test('test_max_none_warning', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_none_warning);
//       });
//       _ut.test('test_max_warning_error', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_warning_error);
//       });
//       _ut.test('test_max_warning_none', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_warning_none);
//       });
//       _ut.test('test_max_warning_warning', () {
//         final __test = new ErrorSeverityTest();
//         runJUnitTest(__test, __test.test_max_warning_warning);
//       });
//     });
//   }
// }
// class ExitDetectorTest extends ParserTestCase {
//   void fail_doStatement_continue_with_label() {
//     _assertFalse("{ x: do { continue x; } while(true); }");
//   }
//   void fail_whileStatement_continue_with_label() {
//     _assertFalse("{ x: while (true) { continue x; } }");
//   }
//   void fail_whileStatement_doStatement_scopeRequired() {
//     _assertTrue("{ while (true) { x: do { continue x; } while(true); }");
//   }
//   void test_asExpression() {
//     _assertFalse("a as Object;");
//   }
//   void test_asExpression_throw() {
//     _assertTrue("throw '' as Object;");
//   }
//   void test_assertStatement() {
//     _assertFalse("assert(a);");
//   }
//   void test_assertStatement_throw() {
//     _assertTrue("assert((throw 0));");
//   }
//   void test_assignmentExpression() {
//     _assertFalse("v = 1;");
//   }
//   void test_assignmentExpression_lhs_throw() {
//     _assertTrue("a[throw ''] = 0;");
//   }
//   void test_assignmentExpression_rhs_throw() {
//     _assertTrue("v = throw '';");
//   }
//   void test_binaryExpression_and() {
//     _assertFalse("a && b;");
//   }
//   void test_binaryExpression_and_lhs() {
//     _assertTrue("throw '' && b;");
//   }
//   void test_binaryExpression_and_rhs() {
//     _assertTrue("a && (throw '');");
//   }
//   void test_binaryExpression_and_rhs2() {
//     _assertTrue("false && (throw '');");
//   }
//   void test_binaryExpression_and_rhs3() {
//     _assertFalse("true && (throw '');");
//   }
//   void test_binaryExpression_or() {
//     _assertFalse("a || b;");
//   }
//   void test_binaryExpression_or_lhs() {
//     _assertTrue("throw '' || b;");
//   }
//   void test_binaryExpression_or_rhs() {
//     _assertTrue("a || (throw '');");
//   }
//   void test_binaryExpression_or_rhs2() {
//     _assertTrue("true || (throw '');");
//   }
//   void test_binaryExpression_or_rhs3() {
//     _assertFalse("false || (throw '');");
//   }
//   void test_block_empty() {
//     _assertFalse("{}");
//   }
//   void test_block_noReturn() {
//     _assertFalse("{ int i = 0; }");
//   }
//   void test_block_return() {
//     _assertTrue("{ return 0; }");
//   }
//   void test_block_returnNotLast() {
//     _assertTrue("{ return 0; throw 'a'; }");
//   }
//   void test_block_throwNotLast() {
//     _assertTrue("{ throw 0; x = null; }");
//   }
//   void test_cascadeExpression_argument() {
//     _assertTrue("a..b(throw '');");
//   }
//   void test_cascadeExpression_index() {
//     _assertTrue("a..[throw ''];");
//   }
//   void test_cascadeExpression_target() {
//     _assertTrue("throw ''..b();");
//   }
//   void test_conditional_ifElse_bothThrows() {
//     _assertTrue("c ? throw '' : throw '';");
//   }
//   void test_conditional_ifElse_elseThrows() {
//     _assertFalse("c ? i : throw '';");
//   }
//   void test_conditional_ifElse_noThrow() {
//     _assertFalse("c ? i : j;");
//   }
//   void test_conditional_ifElse_thenThrow() {
//     _assertFalse("c ? throw '' : j;");
//   }
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new ExitDetector());
//   }
//   void test_doStatement_throwCondition() {
//     _assertTrue("{ do {} while (throw ''); }");
//   }
//   void test_doStatement_true_break() {
//     _assertFalse("{ do { break; } while (true); }");
//   }
//   void test_doStatement_true_continue() {
//     _assertTrue("{ do { continue; } while (true); }");
//   }
//   void test_doStatement_true_if_return() {
//     _assertTrue("{ do { if (true) {return null;} } while (true); }");
//   }
//   void test_doStatement_true_noBreak() {
//     _assertTrue("{ do {} while (true); }");
//   }
//   void test_doStatement_true_return() {
//     _assertTrue("{ do { return null; } while (true);  }");
//   }
//   void test_emptyStatement() {
//     _assertFalse(";");
//   }
//   void test_forEachStatement() {
//     _assertFalse("for (element in list) {}");
//   }
//   void test_forEachStatement_throw() {
//     _assertTrue("for (element in throw '') {}");
//   }
//   void test_forStatement_condition() {
//     _assertTrue("for (; throw 0;) {}");
//   }
//   void test_forStatement_implicitTrue() {
//     _assertTrue("for (;;) {}");
//   }
//   void test_forStatement_implicitTrue_break() {
//     _assertFalse("for (;;) { break; }");
//   }
//   void test_forStatement_initialization() {
//     _assertTrue("for (i = throw 0;;) {}");
//   }
//   void test_forStatement_true() {
//     _assertTrue("for (; true; ) {}");
//   }
//   void test_forStatement_true_break() {
//     _assertFalse("{ for (; true; ) { break; } }");
//   }
//   void test_forStatement_true_continue() {
//     _assertTrue("{ for (; true; ) { continue; } }");
//   }
//   void test_forStatement_true_if_return() {
//     _assertTrue("{ for (; true; ) { if (true) {return null;} } }");
//   }
//   void test_forStatement_true_noBreak() {
//     _assertTrue("{ for (; true; ) {} }");
//   }
//   void test_forStatement_updaters() {
//     _assertTrue("for (;; i++, throw 0) {}");
//   }
//   void test_forStatement_variableDeclaration() {
//     _assertTrue("for (int i = throw 0;;) {}");
//   }
//   void test_functionExpression() {
//     _assertFalse("(){};");
//   }
//   void test_functionExpression_bodyThrows() {
//     _assertFalse("(int i) => throw '';");
//   }
//   void test_functionExpressionInvocation() {
//     _assertFalse("f(g);");
//   }
//   void test_functionExpressionInvocation_argumentThrows() {
//     _assertTrue("f(throw '');");
//   }
//   void test_functionExpressionInvocation_targetThrows() {
//     _assertTrue("throw ''(g);");
//   }
//   void test_identifier_prefixedIdentifier() {
//     _assertFalse("a.b;");
//   }
//   void test_identifier_simpleIdentifier() {
//     _assertFalse("a;");
//   }
//   void test_if_false_else_return() {
//     _assertTrue("if (false) {} else { return 0; }");
//   }
//   void test_if_false_noReturn() {
//     _assertFalse("if (false) {}");
//   }
//   void test_if_false_return() {
//     _assertFalse("if (false) { return 0; }");
//   }
//   void test_if_noReturn() {
//     _assertFalse("if (c) i++;");
//   }
//   void test_if_return() {
//     _assertFalse("if (c) return 0;");
//   }
//   void test_if_true_noReturn() {
//     _assertFalse("if (true) {}");
//   }
//   void test_if_true_return() {
//     _assertTrue("if (true) { return 0; }");
//   }
//   void test_ifElse_bothReturn() {
//     _assertTrue("if (c) return 0; else return 1;");
//   }
//   void test_ifElse_elseReturn() {
//     _assertFalse("if (c) i++; else return 1;");
//   }
//   void test_ifElse_noReturn() {
//     _assertFalse("if (c) i++; else j++;");
//   }
//   void test_ifElse_thenReturn() {
//     _assertFalse("if (c) return 0; else j++;");
//   }
//   void test_indexExpression() {
//     _assertFalse("a[b];");
//   }
//   void test_indexExpression_index() {
//     _assertTrue("a[throw ''];");
//   }
//   void test_indexExpression_target() {
//     _assertTrue("throw ''[b];");
//   }
//   void test_instanceCreationExpression() {
//     _assertFalse("new A(b);");
//   }
//   void test_instanceCreationExpression_argumentThrows() {
//     _assertTrue("new A(throw '');");
//   }
//   void test_isExpression() {
//     _assertFalse("A is B;");
//   }
//   void test_isExpression_throws() {
//     _assertTrue("throw '' is B;");
//   }
//   void test_labeledStatement() {
//     _assertFalse("label: a;");
//   }
//   void test_labeledStatement_throws() {
//     _assertTrue("label: throw '';");
//   }
//   void test_literal_boolean() {
//     _assertFalse("true;");
//   }
//   void test_literal_double() {
//     _assertFalse("1.1;");
//   }
//   void test_literal_integer() {
//     _assertFalse("1;");
//   }
//   void test_literal_null() {
//     _assertFalse("null;");
//   }
//   void test_literal_String() {
//     _assertFalse("'str';");
//   }
//   void test_methodInvocation() {
//     _assertFalse("a.b(c);");
//   }
//   void test_methodInvocation_argument() {
//     _assertTrue("a.b(throw '');");
//   }
//   void test_methodInvocation_target() {
//     _assertTrue("throw ''.b(c);");
//   }
//   void test_parenthesizedExpression() {
//     _assertFalse("(a);");
//   }
//   void test_parenthesizedExpression_throw() {
//     _assertTrue("(throw '');");
//   }
//   void test_propertyAccess() {
//     _assertFalse("new Object().a;");
//   }
//   void test_propertyAccess_throws() {
//     _assertTrue("(throw '').a;");
//   }
//   void test_rethrow() {
//     _assertTrue("rethrow;");
//   }
//   void test_return() {
//     _assertTrue("return 0;");
//   }
//   void test_superExpression() {
//     _assertFalse("super.a;");
//   }
//   void test_switch_allReturn() {
//     _assertTrue("switch (i) { case 0: return 0; default: return 1; }");
//   }
//   void test_switch_defaultWithNoStatements() {
//     _assertFalse("switch (i) { case 0: return 0; default: }");
//   }
//   void test_switch_fallThroughToNotReturn() {
//     _assertFalse("switch (i) { case 0: case 1: break; default: return 1; }");
//   }
//   void test_switch_fallThroughToReturn() {
//     _assertTrue("switch (i) { case 0: case 1: return 0; default: return 1; }");
//   }
//   void test_switch_noDefault() {
//     _assertFalse("switch (i) { case 0: return 0; }");
//   }
//   void test_switch_nonReturn() {
//     _assertFalse("switch (i) { case 0: i++; default: return 1; }");
//   }
//   void test_thisExpression() {
//     _assertFalse("this.a;");
//   }
//   void test_throwExpression() {
//     _assertTrue("throw new Object();");
//   }
//   void test_tryStatement_noReturn() {
//     _assertFalse("try {} catch (e, s) {} finally {}");
//   }
//   void test_tryStatement_return_catch() {
//     _assertFalse("try {} catch (e, s) { return 1; } finally {}");
//   }
//   void test_tryStatement_return_finally() {
//     _assertTrue("try {} catch (e, s) {} finally { return 1; }");
//   }
//   void test_tryStatement_return_try() {
//     _assertTrue("try { return 1; } catch (e, s) {} finally {}");
//   }
//   void test_variableDeclarationStatement_noInitializer() {
//     _assertFalse("int i;");
//   }
//   void test_variableDeclarationStatement_noThrow() {
//     _assertFalse("int i = 0;");
//   }
//   void test_variableDeclarationStatement_throw() {
//     _assertTrue("int i = throw new Object();");
//   }
//   void test_whileStatement_false_nonReturn() {
//     _assertFalse("{ while (false) {} }");
//   }
//   void test_whileStatement_throwCondition() {
//     _assertTrue("{ while (throw '') {} }");
//   }
//   void test_whileStatement_true_break() {
//     _assertFalse("{ while (true) { break; } }");
//   }
//   void test_whileStatement_true_continue() {
//     _assertTrue("{ while (true) { continue; } }");
//   }
//   void test_whileStatement_true_if_return() {
//     _assertTrue("{ while (true) { if (true) {return null;} } }");
//   }
//   void test_whileStatement_true_noBreak() {
//     _assertTrue("{ while (true) {} }");
//   }
//   void test_whileStatement_true_return() {
//     _assertTrue("{ while (true) { return null; } }");
//   }
//   void test_whileStatement_true_throw() {
//     _assertTrue("{ while (true) { throw ''; } }");
//   }
//   void _assertFalse(String source) {
//     _assertHasReturn(false, source);
//   }
//   void _assertHasReturn(bool expectedResult, String source) {
//     ExitDetector detector = new ExitDetector();
//     Statement statement = ParserTestCase.parseStatement(source, []);
//     JUnitTestCase.assertSame(expectedResult, statement.accept(detector));
//   }
//   void _assertTrue(String source) {
//     _assertHasReturn(true, source);
//   }
//   static dartSuite() {
//     _ut.group('ExitDetectorTest', () {
//       _ut.test('test_asExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_asExpression);
//       });
//       _ut.test('test_asExpression_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_asExpression_throw);
//       });
//       _ut.test('test_assertStatement', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_assertStatement);
//       });
//       _ut.test('test_assertStatement_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_assertStatement_throw);
//       });
//       _ut.test('test_assignmentExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_assignmentExpression);
//       });
//       _ut.test('test_assignmentExpression_lhs_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_assignmentExpression_lhs_throw);
//       });
//       _ut.test('test_assignmentExpression_rhs_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_assignmentExpression_rhs_throw);
//       });
//       _ut.test('test_binaryExpression_and', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_and);
//       });
//       _ut.test('test_binaryExpression_and_lhs', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_and_lhs);
//       });
//       _ut.test('test_binaryExpression_and_rhs', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_and_rhs);
//       });
//       _ut.test('test_binaryExpression_and_rhs2', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_and_rhs2);
//       });
//       _ut.test('test_binaryExpression_and_rhs3', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_and_rhs3);
//       });
//       _ut.test('test_binaryExpression_or', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_or);
//       });
//       _ut.test('test_binaryExpression_or_lhs', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_or_lhs);
//       });
//       _ut.test('test_binaryExpression_or_rhs', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_or_rhs);
//       });
//       _ut.test('test_binaryExpression_or_rhs2', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_or_rhs2);
//       });
//       _ut.test('test_binaryExpression_or_rhs3', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_binaryExpression_or_rhs3);
//       });
//       _ut.test('test_block_empty', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_block_empty);
//       });
//       _ut.test('test_block_noReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_block_noReturn);
//       });
//       _ut.test('test_block_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_block_return);
//       });
//       _ut.test('test_block_returnNotLast', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_block_returnNotLast);
//       });
//       _ut.test('test_block_throwNotLast', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_block_throwNotLast);
//       });
//       _ut.test('test_cascadeExpression_argument', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_cascadeExpression_argument);
//       });
//       _ut.test('test_cascadeExpression_index', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_cascadeExpression_index);
//       });
//       _ut.test('test_cascadeExpression_target', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_cascadeExpression_target);
//       });
//       _ut.test('test_conditional_ifElse_bothThrows', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_conditional_ifElse_bothThrows);
//       });
//       _ut.test('test_conditional_ifElse_elseThrows', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_conditional_ifElse_elseThrows);
//       });
//       _ut.test('test_conditional_ifElse_noThrow', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_conditional_ifElse_noThrow);
//       });
//       _ut.test('test_conditional_ifElse_thenThrow', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_conditional_ifElse_thenThrow);
//       });
//       _ut.test('test_creation', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_doStatement_throwCondition', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_doStatement_throwCondition);
//       });
//       _ut.test('test_doStatement_true_break', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_doStatement_true_break);
//       });
//       _ut.test('test_doStatement_true_continue', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_doStatement_true_continue);
//       });
//       _ut.test('test_doStatement_true_if_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_doStatement_true_if_return);
//       });
//       _ut.test('test_doStatement_true_noBreak', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_doStatement_true_noBreak);
//       });
//       _ut.test('test_doStatement_true_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_doStatement_true_return);
//       });
//       _ut.test('test_emptyStatement', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_emptyStatement);
//       });
//       _ut.test('test_forEachStatement', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forEachStatement);
//       });
//       _ut.test('test_forEachStatement_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forEachStatement_throw);
//       });
//       _ut.test('test_forStatement_condition', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_condition);
//       });
//       _ut.test('test_forStatement_implicitTrue', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_implicitTrue);
//       });
//       _ut.test('test_forStatement_implicitTrue_break', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_implicitTrue_break);
//       });
//       _ut.test('test_forStatement_initialization', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_initialization);
//       });
//       _ut.test('test_forStatement_true', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_true);
//       });
//       _ut.test('test_forStatement_true_break', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_true_break);
//       });
//       _ut.test('test_forStatement_true_continue', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_true_continue);
//       });
//       _ut.test('test_forStatement_true_if_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_true_if_return);
//       });
//       _ut.test('test_forStatement_true_noBreak', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_true_noBreak);
//       });
//       _ut.test('test_forStatement_updaters', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_updaters);
//       });
//       _ut.test('test_forStatement_variableDeclaration', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_forStatement_variableDeclaration);
//       });
//       _ut.test('test_functionExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_functionExpression);
//       });
//       _ut.test('test_functionExpressionInvocation', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_functionExpressionInvocation);
//       });
//       _ut.test('test_functionExpressionInvocation_argumentThrows', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_functionExpressionInvocation_argumentThrows);
//       });
//       _ut.test('test_functionExpressionInvocation_targetThrows', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_functionExpressionInvocation_targetThrows);
//       });
//       _ut.test('test_functionExpression_bodyThrows', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_functionExpression_bodyThrows);
//       });
//       _ut.test('test_identifier_prefixedIdentifier', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_identifier_prefixedIdentifier);
//       });
//       _ut.test('test_identifier_simpleIdentifier', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_identifier_simpleIdentifier);
//       });
//       _ut.test('test_ifElse_bothReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_ifElse_bothReturn);
//       });
//       _ut.test('test_ifElse_elseReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_ifElse_elseReturn);
//       });
//       _ut.test('test_ifElse_noReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_ifElse_noReturn);
//       });
//       _ut.test('test_ifElse_thenReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_ifElse_thenReturn);
//       });
//       _ut.test('test_if_false_else_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_false_else_return);
//       });
//       _ut.test('test_if_false_noReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_false_noReturn);
//       });
//       _ut.test('test_if_false_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_false_return);
//       });
//       _ut.test('test_if_noReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_noReturn);
//       });
//       _ut.test('test_if_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_return);
//       });
//       _ut.test('test_if_true_noReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_true_noReturn);
//       });
//       _ut.test('test_if_true_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_if_true_return);
//       });
//       _ut.test('test_indexExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_indexExpression);
//       });
//       _ut.test('test_indexExpression_index', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_indexExpression_index);
//       });
//       _ut.test('test_indexExpression_target', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_indexExpression_target);
//       });
//       _ut.test('test_instanceCreationExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression);
//       });
//       _ut.test('test_instanceCreationExpression_argumentThrows', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_instanceCreationExpression_argumentThrows);
//       });
//       _ut.test('test_isExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_isExpression);
//       });
//       _ut.test('test_isExpression_throws', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_isExpression_throws);
//       });
//       _ut.test('test_labeledStatement', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_labeledStatement);
//       });
//       _ut.test('test_labeledStatement_throws', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_labeledStatement_throws);
//       });
//       _ut.test('test_literal_String', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_literal_String);
//       });
//       _ut.test('test_literal_boolean', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_literal_boolean);
//       });
//       _ut.test('test_literal_double', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_literal_double);
//       });
//       _ut.test('test_literal_integer', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_literal_integer);
//       });
//       _ut.test('test_literal_null', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_literal_null);
//       });
//       _ut.test('test_methodInvocation', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_methodInvocation);
//       });
//       _ut.test('test_methodInvocation_argument', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_methodInvocation_argument);
//       });
//       _ut.test('test_methodInvocation_target', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_methodInvocation_target);
//       });
//       _ut.test('test_parenthesizedExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_parenthesizedExpression);
//       });
//       _ut.test('test_parenthesizedExpression_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_parenthesizedExpression_throw);
//       });
//       _ut.test('test_propertyAccess', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_propertyAccess);
//       });
//       _ut.test('test_propertyAccess_throws', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_propertyAccess_throws);
//       });
//       _ut.test('test_rethrow', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_rethrow);
//       });
//       _ut.test('test_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_return);
//       });
//       _ut.test('test_superExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_superExpression);
//       });
//       _ut.test('test_switch_allReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_switch_allReturn);
//       });
//       _ut.test('test_switch_defaultWithNoStatements', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_switch_defaultWithNoStatements);
//       });
//       _ut.test('test_switch_fallThroughToNotReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_switch_fallThroughToNotReturn);
//       });
//       _ut.test('test_switch_fallThroughToReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_switch_fallThroughToReturn);
//       });
//       _ut.test('test_switch_noDefault', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_switch_noDefault);
//       });
//       _ut.test('test_switch_nonReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_switch_nonReturn);
//       });
//       _ut.test('test_thisExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_thisExpression);
//       });
//       _ut.test('test_throwExpression', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_throwExpression);
//       });
//       _ut.test('test_tryStatement_noReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_tryStatement_noReturn);
//       });
//       _ut.test('test_tryStatement_return_catch', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_tryStatement_return_catch);
//       });
//       _ut.test('test_tryStatement_return_finally', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_tryStatement_return_finally);
//       });
//       _ut.test('test_tryStatement_return_try', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_tryStatement_return_try);
//       });
//       _ut.test('test_variableDeclarationStatement_noInitializer', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_variableDeclarationStatement_noInitializer);
//       });
//       _ut.test('test_variableDeclarationStatement_noThrow', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_variableDeclarationStatement_noThrow);
//       });
//       _ut.test('test_variableDeclarationStatement_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_variableDeclarationStatement_throw);
//       });
//       _ut.test('test_whileStatement_false_nonReturn', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_false_nonReturn);
//       });
//       _ut.test('test_whileStatement_throwCondition', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_throwCondition);
//       });
//       _ut.test('test_whileStatement_true_break', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_true_break);
//       });
//       _ut.test('test_whileStatement_true_continue', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_true_continue);
//       });
//       _ut.test('test_whileStatement_true_if_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_true_if_return);
//       });
//       _ut.test('test_whileStatement_true_noBreak', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_true_noBreak);
//       });
//       _ut.test('test_whileStatement_true_return', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_true_return);
//       });
//       _ut.test('test_whileStatement_true_throw', () {
//         final __test = new ExitDetectorTest();
//         runJUnitTest(__test, __test.test_whileStatement_true_throw);
//       });
//     });
//   }
// }
// /**
//  * An explicit package: resolver. This UriResolver shells out to pub, calling it's list-package-dirs
//  * command. It parses the resulting json map, which maps symbolic package references to their
//  * concrete locations on disk.
//  *
//  * <pre>
//  *{
//  *"packages": {
//  *"foo": "path/to/foo",
//  *"bar": "path/to/bar"
//  *},
//  *"input_files": [
//  *...
//  *]
//  *},
//  *</pre>
//  */
// class ExplicitPackageUriResolver extends UriResolver {
//   /**
//    * The name of the `package` scheme.
//    */
//   static String PACKAGE_SCHEME = "package";
//   static String PUB_LIST_COMMAND = "list-package-dirs";
//   /**
//    * Return `true` if the given URI is a `package` URI.
//    *
//    * @param uri the URI being tested
//    * @return `true` if the given URI is a `package` URI
//    */
//   static bool isPackageUri(Uri uri) => PACKAGE_SCHEME == uri.scheme;
//   final JavaFile rootDir;
//   final DirectoryBasedDartSdk _sdk;
//   Map<String, List<JavaFile>> packageMap;
//   /**
//    * Create a new ExplicitPackageUriResolver.
//    *
//    * @param sdk the sdk; this is used to locate the pub command to run
//    * @param rootDir the directory for which we'll be resolving package information
//    */
//   ExplicitPackageUriResolver(this._sdk, this.rootDir) {
//     if (rootDir == null) {
//       throw new IllegalArgumentException("the root dir must not be null");
//     }
//   }
//   List<String> get command => <String> [_sdk.pubExecutable.getAbsolutePath(), PUB_LIST_COMMAND];
//   @override
//   Source resolveAbsolute(Uri uri) {
//     if (!isPackageUri(uri)) {
//       return null;
//     }
//     String path = uri.path;
//     if (path == null) {
//       path = uri.path;
//       if (path == null) {
//         return null;
//       }
//     }
//     String pkgName;
//     String relPath;
//     int index = path.indexOf('/');
//     if (index == -1) {
//       // No slash
//       pkgName = path;
//       relPath = "";
//     } else if (index == 0) {
//       // Leading slash is invalid
//       return null;
//     } else {
//       // <pkgName>/<relPath>
//       pkgName = path.substring(0, index);
//       relPath = path.substring(index + 1);
//     }
//     if (packageMap == null) {
//       packageMap = calculatePackageMap();
//     }
//     List<JavaFile> dirs = packageMap[pkgName];
//     if (dirs != null) {
//       for (JavaFile packageDir in dirs) {
//         if (packageDir.exists()) {
//           JavaFile resolvedFile = new JavaFile.relative(packageDir, relPath.replaceAll('/', new String.fromCharCode(JavaFile.separatorChar)));
//           if (resolvedFile.exists()) {
//             return new FileBasedSource.con2(uri, resolvedFile);
//           }
//         }
//       }
//     }
//     //
//     // Return a FileBasedSource that doesn't exist. This helps provide more meaningful error
//     // messages to users (a missing file error, as opposed to an invalid uri error).
//     //
//     String fullPackagePath = "${pkgName}/${relPath}";
//     return new FileBasedSource.con2(uri, new JavaFile.relative(rootDir, fullPackagePath.replaceAll('/', new String.fromCharCode(JavaFile.separatorChar))));
//   }
//   String resolvePathToPackage(String path) {
//     if (packageMap == null) {
//       return null;
//     }
//     for (String key in packageMap.keys.toSet()) {
//       List<JavaFile> files = packageMap[key];
//       for (JavaFile file in files) {
//         try {
//           if (file.getCanonicalPath().endsWith(path)) {
//             return key;
//           }
//         } on JavaIOException catch (e) {
//         }
//       }
//     }
//     return null;
//   }
//   @override
//   Uri restoreAbsolute(Source source) {
//     if (packageMap == null) {
//       return null;
//     }
//     if (source is FileBasedSource) {
//       String sourcePath = (source as FileBasedSource).file.getPath();
//       for (MapEntry<String, List<JavaFile>> entry in getMapEntrySet(packageMap)) {
//         for (JavaFile pkgFolder in entry.getValue()) {
//           String pkgCanonicalPath = pkgFolder.getAbsolutePath();
//           if (sourcePath.startsWith(pkgCanonicalPath)) {
//             String packageName = entry.getKey();
//             String relPath = sourcePath.substring(pkgCanonicalPath.length);
//             return parseUriWithException("${PACKAGE_SCHEME}:${packageName}${relPath}");
//           }
//         }
//       }
//     }
//     return null;
//   }
//   Map<String, List<JavaFile>> calculatePackageMap() {
//     ProcessBuilder builder = new ProcessBuilder(command);
//     builder.directory(rootDir);
//     ProcessRunner runner = new ProcessRunner(builder);
//     try {
//       if (runProcess(runner) == 0) {
//         return parsePackageMap(runner.getStdOut());
//       } else {
//         AnalysisEngine.instance.logger.logInformation("pub ${PUB_LIST_COMMAND} failed: exit code ${runner.getExitCode()}");
//       }
//     } on JavaIOException catch (ioe) {
//       AnalysisEngine.instance.logger.logInformation2("error running pub ${PUB_LIST_COMMAND}", ioe);
//     } on JSONException catch (e) {
//       AnalysisEngine.instance.logger.logError2("malformed json from pub ${PUB_LIST_COMMAND}", e);
//     }
//     return new HashMap<String, List<JavaFile>>();
//   }
//   Map<String, List<JavaFile>> parsePackageMap(String jsonText) {
//     Map<String, List<JavaFile>> map = new HashMap<String, List<JavaFile>>();
//     JSONObject obj = new JSONObject(jsonText);
//     JSONObject packages = obj.optJSONObject("packages");
//     if (packages != null) {
//       JavaIterator keys = packages.keys();
//       while (keys.hasNext) {
//         Object key = keys.next();
//         if (key is String) {
//           String strKey = key as String;
//           List<JavaFile> files = new List<JavaFile>();
//           map[strKey] = files;
//           Object val = packages.get(strKey);
//           if (val is String) {
//             String path = val as String;
//             files.add(new JavaFile(path));
//           } else if (val is JSONArray) {
//             JSONArray arr = val as JSONArray;
//             for (int i = 0; i < arr.length(); i++) {
//               files.add(new JavaFile(arr.getString(i)));
//             }
//           }
//         }
//       }
//     }
//     return map;
//   }
//   /**
//    * Run the external process and return the exit value once the external process has completed.
//    *
//    * @param runner the external process runner
//    * @return the external process exit code
//    */
//   int runProcess(ProcessRunner runner) => runner.runSync(0);
// }
// class ExplicitPackageUriResolverTest extends JUnitTestCase {
//   void test_creation() {
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/foo_project");
//     JUnitTestCase.assertNotNull(new ExplicitPackageUriResolver(null, directory));
//   }
//   void test_resolve_invalid() {
//     JavaFile projectDir = new JavaFile("foo_project");
//     UriResolver resolver = new ExplicitPackageUriResolverTest_MockExplicitPackageUriResolver.con1(projectDir);
//     // Invalid: URI
//     try {
//       parseUriWithException("package:");
//       JUnitTestCase.fail("Expected exception");
//     } on URISyntaxException catch (e) {
//     }
//     // Invalid: just slash
//     Source result = resolver.resolveAbsolute(parseUriWithException("package:/"));
//     JUnitTestCase.assertNull(result);
//     // Invalid: leading slash... or should we gracefully degrade and ignore the leading slash?
//     result = resolver.resolveAbsolute(parseUriWithException("package:/foo"));
//     JUnitTestCase.assertNull(result);
//   }
//   void test_resolve_nonPackage() {
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/foo_project");
//     UriResolver resolver = new ExplicitPackageUriResolverTest_MockExplicitPackageUriResolver.con1(directory);
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:core"));
//     JUnitTestCase.assertNull(result);
//   }
//   void test_resolve_resolvePathToPackage() {
//     JavaFile directory = FileUtilities2.createFile("/src/foo/bar/baz/lib");
//     String packages = "{\"packages\":{\"unittest\": [\"/dart/unittest/lib\"],\"foo.bar.baz\": [\"/src/foo/bar/baz/lib\",\"/gen/foo/bar/baz\"]}}";
//     ExplicitPackageUriResolver resolver = new ExplicitPackageUriResolverTest_MockExplicitPackageUriResolver.con2(directory, packages);
//     String resolvedPath = resolver.resolvePathToPackage("${JavaFile.separator}baz${JavaFile.separator}lib");
//     JUnitTestCase.assertNotNull(resolvedPath);
//     JUnitTestCase.assertEquals("foo.bar.baz", resolvedPath);
//     resolvedPath = resolver.resolvePathToPackage("${JavaFile.separator}dart${JavaFile.separator}mypackage");
//     JUnitTestCase.assertNull(resolvedPath);
//   }
//   @override
//   void tearDown() {
//     FileUtilities2.deleteTempDir();
//   }
//   static dartSuite() {
//     _ut.group('ExplicitPackageUriResolverTest', () {
//       _ut.test('test_creation', () {
//         final __test = new ExplicitPackageUriResolverTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_resolve_invalid', () {
//         final __test = new ExplicitPackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_invalid);
//       });
//       _ut.test('test_resolve_nonPackage', () {
//         final __test = new ExplicitPackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_nonPackage);
//       });
//       _ut.test('test_resolve_resolvePathToPackage', () {
//         final __test = new ExplicitPackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_resolvePathToPackage);
//       });
//     });
//   }
// }
// class ExplicitPackageUriResolverTest_MockExplicitPackageUriResolver extends ExplicitPackageUriResolver {
//   String _jsonText = "{\"foo\":\"bar\"}";
//   ExplicitPackageUriResolverTest_MockExplicitPackageUriResolver.con1(JavaFile rootDir) : super(null, rootDir);
//   ExplicitPackageUriResolverTest_MockExplicitPackageUriResolver.con2(JavaFile rootDir, String jsonPackageList) : super(null, rootDir) {
//     if (!jsonPackageList.isEmpty) {
//       _jsonText = jsonPackageList;
//       packageMap = calculatePackageMap();
//     }
//   }
//   @override
//   Map<String, List<JavaFile>> calculatePackageMap() {
//     try {
//       return parsePackageMap(_jsonText);
//     } on JSONException catch (e) {
//       return new HashMap<String, List<JavaFile>>();
//     }
//   }
// }
// class ExpressionVisitor_AngularTest_verify extends ExpressionVisitor {
//   ResolutionVerifier verifier;
//   ExpressionVisitor_AngularTest_verify(this.verifier) : super();
//   @override
//   void visitExpression(Expression expression) {
//     expression.accept(verifier);
//   }
// }
// class FileBasedSourceTest extends JUnitTestCase {
//   void test_equals_false_differentFiles() {
//     JavaFile file1 = FileUtilities2.createFile("/does/not/exist1.dart");
//     JavaFile file2 = FileUtilities2.createFile("/does/not/exist2.dart");
//     FileBasedSource source1 = new FileBasedSource.con1(file1);
//     FileBasedSource source2 = new FileBasedSource.con1(file2);
//     JUnitTestCase.assertFalse(source1 == source2);
//   }
//   void test_equals_false_null() {
//     JavaFile file = FileUtilities2.createFile("/does/not/exist1.dart");
//     FileBasedSource source1 = new FileBasedSource.con1(file);
//     JUnitTestCase.assertFalse(source1 == null);
//   }
//   void test_equals_true() {
//     JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
//     JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
//     FileBasedSource source1 = new FileBasedSource.con1(file1);
//     FileBasedSource source2 = new FileBasedSource.con1(file2);
//     JUnitTestCase.assertTrue(source1 == source2);
//   }
//   void test_getEncoding() {
//     SourceFactory factory = new SourceFactory([new FileUriResolver()]);
//     String fullPath = "/does/not/exist.dart";
//     JavaFile file = FileUtilities2.createFile(fullPath);
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertEquals(source, factory.fromEncoding(source.encoding));
//   }
//   void test_getFullName() {
//     String fullPath = "/does/not/exist.dart";
//     JavaFile file = FileUtilities2.createFile(fullPath);
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertEquals(file.getAbsolutePath(), source.fullName);
//   }
//   void test_getShortName() {
//     JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertEquals("exist.dart", source.shortName);
//   }
//   void test_hashCode() {
//     JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
//     JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
//     FileBasedSource source1 = new FileBasedSource.con1(file1);
//     FileBasedSource source2 = new FileBasedSource.con1(file2);
//     JUnitTestCase.assertEquals(source1.hashCode, source2.hashCode);
//   }
//   void test_isInSystemLibrary_contagious() {
//     JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
//     JUnitTestCase.assertNotNull(sdkDirectory);
//     DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
//     UriResolver resolver = new DartUriResolver(sdk);
//     SourceFactory factory = new SourceFactory([resolver]);
//     // resolve dart:core
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:core"));
//     JUnitTestCase.assertNotNull(result);
//     JUnitTestCase.assertTrue(result.isInSystemLibrary);
//     // system libraries reference only other system libraries
//     Source partSource = factory.resolveUri(result, "num.dart");
//     JUnitTestCase.assertNotNull(partSource);
//     JUnitTestCase.assertTrue(partSource.isInSystemLibrary);
//   }
//   void test_isInSystemLibrary_false() {
//     JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertNotNull(source);
//     JUnitTestCase.assertEquals(file.getAbsolutePath(), source.fullName);
//     JUnitTestCase.assertFalse(source.isInSystemLibrary);
//   }
//   void test_issue14500() {
//     // see https://code.google.com/p/dart/issues/detail?id=14500
//     FileBasedSource source = new FileBasedSource.con1(FileUtilities2.createFile("/some/packages/foo:bar.dart"));
//     JUnitTestCase.assertNotNull(source);
//     JUnitTestCase.assertFalse(source.exists());
//   }
//   void test_resolveRelative_dart_fileName() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("dart:test"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("dart:test/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_dart_filePath() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("dart:test"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("dart:test/c/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_dart_filePathWithParent() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("dart:test/b/test.dart"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("dart:test/c/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_file_fileName() {
//     if (OSUtilities.isWindows()) {
//       // On Windows, the URI that is produced includes a drive letter, which I believe is not
//       // consistent across all machines that might run this test.
//       return;
//     }
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("file:/a/b/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_file_filePath() {
//     if (OSUtilities.isWindows()) {
//       // On Windows, the URI that is produced includes a drive letter, which I believe is not
//       // consistent across all machines that might run this test.
//       return;
//     }
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("file:/a/b/c/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_file_filePathWithParent() {
//     if (OSUtilities.isWindows()) {
//       // On Windows, the URI that is produced includes a drive letter, which I believe is not
//       // consistent across all machines that might run this test.
//       return;
//     }
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con1(file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("file:/a/c/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_package_fileName() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("package:b/test.dart"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("package:b/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_package_fileNameWithoutPackageName() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("package:test.dart"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("package:lib.dart", relative.toString());
//   }
//   void test_resolveRelative_package_filePath() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("package:b/test.dart"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("package:b/c/lib.dart", relative.toString());
//   }
//   void test_resolveRelative_package_filePathWithParent() {
//     JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("package:a/b/test.dart"), file);
//     JUnitTestCase.assertNotNull(source);
//     Uri relative = source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
//     JUnitTestCase.assertNotNull(relative);
//     JUnitTestCase.assertEquals("package:a/c/lib.dart", relative.toString());
//   }
//   void test_system() {
//     JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
//     FileBasedSource source = new FileBasedSource.con2(parseUriWithException("dart:core"), file);
//     JUnitTestCase.assertNotNull(source);
//     JUnitTestCase.assertEquals(file.getAbsolutePath(), source.fullName);
//     JUnitTestCase.assertTrue(source.isInSystemLibrary);
//   }
//   static dartSuite() {
//     _ut.group('FileBasedSourceTest', () {
//       _ut.test('test_equals_false_differentFiles', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_equals_false_differentFiles);
//       });
//       _ut.test('test_equals_false_null', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_equals_false_null);
//       });
//       _ut.test('test_equals_true', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_equals_true);
//       });
//       _ut.test('test_getEncoding', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_getEncoding);
//       });
//       _ut.test('test_getFullName', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_getFullName);
//       });
//       _ut.test('test_getShortName', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_getShortName);
//       });
//       _ut.test('test_hashCode', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_hashCode);
//       });
//       _ut.test('test_isInSystemLibrary_contagious', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_isInSystemLibrary_contagious);
//       });
//       _ut.test('test_isInSystemLibrary_false', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_isInSystemLibrary_false);
//       });
//       _ut.test('test_issue14500', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_issue14500);
//       });
//       _ut.test('test_resolveRelative_dart_fileName', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_dart_fileName);
//       });
//       _ut.test('test_resolveRelative_dart_filePath', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_dart_filePath);
//       });
//       _ut.test('test_resolveRelative_dart_filePathWithParent', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_dart_filePathWithParent);
//       });
//       _ut.test('test_resolveRelative_file_fileName', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_file_fileName);
//       });
//       _ut.test('test_resolveRelative_file_filePath', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_file_filePath);
//       });
//       _ut.test('test_resolveRelative_file_filePathWithParent', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_file_filePathWithParent);
//       });
//       _ut.test('test_resolveRelative_package_fileName', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_package_fileName);
//       });
//       _ut.test('test_resolveRelative_package_fileNameWithoutPackageName', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_package_fileNameWithoutPackageName);
//       });
//       _ut.test('test_resolveRelative_package_filePath', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_package_filePath);
//       });
//       _ut.test('test_resolveRelative_package_filePathWithParent', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative_package_filePathWithParent);
//       });
//       _ut.test('test_system', () {
//         final __test = new FileBasedSourceTest();
//         runJUnitTest(__test, __test.test_system);
//       });
//     });
//   }
// }
// class FileUriResolverTest extends JUnitTestCase {
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new FileUriResolver());
//   }
//   void test_resolve_file() {
//     UriResolver resolver = new FileUriResolver();
//     Source result = resolver.resolveAbsolute(parseUriWithException("file:/does/not/exist.dart"));
//     JUnitTestCase.assertNotNull(result);
//     JUnitTestCase.assertEquals(FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath(), result.fullName);
//   }
//   void test_resolve_nonFile() {
//     UriResolver resolver = new FileUriResolver();
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:core"));
//     JUnitTestCase.assertNull(result);
//   }
//   static dartSuite() {
//     _ut.group('FileUriResolverTest', () {
//       _ut.test('test_creation', () {
//         final __test = new FileUriResolverTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_resolve_file', () {
//         final __test = new FileUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_file);
//       });
//       _ut.test('test_resolve_nonFile', () {
//         final __test = new FileUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_nonFile);
//       });
//     });
//   }
// }
// /**
//  * The class `FileUtilities2` implements utility methods used to create and manipulate files.
//  */
// class FileUtilities2 {
//   /**
//    * A temporary directory used during testing and cleared via [deleteTempDir].
//    */
//   static JavaFile _TEMP_DIR = new JavaFile(JavaSystemIO.getProperty("java.io.tmpdir"), "AnalysisEngineTestTmp");
//   /**
//    * Create a file with the given path after replacing any forward slashes ('/') in the path with
//    * the current file separator.
//    *
//    * @param path the path of the file to be created
//    * @return the file representing the path
//    */
//   static JavaFile createFile(String path) => new JavaFile(_convertPath(path)).getAbsoluteFile();
//   /**
//    * Create a new symlink or throw an exception if creation of symlinks is not supported. Use
//    * [isSymLinkSupported] to determine if this method will work on the current platform.
//    *
//    * @param existingFile the existing file to which the new symlink should point (not `null`,
//    *          and must exist)
//    * @param linkFile the symlink to be created (not `null`, but must not exist)
//    */
//   static void createSymLink(JavaFile existingFile, JavaFile linkFile) {
//     JUnitTestCase.assertTrueMsg("Creation of symlinks is not supported", isSymLinkSupported);
//     JUnitTestCase.assertTrueMsg("Target file does not exist", existingFile.exists());
//     JUnitTestCase.assertFalseMsg("Link already exists", linkFile.exists());
//     ProcessRunner runner = new ProcessRunner(<String> ["ln", "-s", existingFile.getPath(), linkFile.getPath()]);
//     int exitCode = runner.runSync(10000);
//     if (exitCode != 0) {
//       JUnitTestCase.fail("Symlink creation failed [${exitCode}] ${linkFile}");
//     }
//   }
//   /**
//    * Create a temporary directory. Call [deleteTempDir] in the [TestCase] tearDown
//    * method to delete all temporary files and directories.
//    *
//    * @param name the name of the temporary directory (not `null`, not empty)
//    * @return the directory created (not `null`)
//    */
//   static JavaFile createTempDir(String name) {
//     JavaFile dir = new JavaFile.relative(_TEMP_DIR, name);
//     if (dir.mkdirs()) {
//       return dir;
//     }
//     throw new JavaIOException("Failed to create directory ${dir}");
//   }
//   /**
//    * Create a temporary file. Call [deleteTempDir] in the [TestCase] tearDown method
//    * to delete all temporary files and directories.
//    *
//    * @param name the name of the temporary file (not `null`, not empty)
//    * @return the file (not `null`)
//    */
//   static JavaFile createTempFile(String name, String content) {
//     JavaFile file = new JavaFile.relative(_TEMP_DIR, name);
//     if (file.createNewFile()) {
//       return file;
//     }
//     throw new JavaIOException("Failed to create file ${file}");
//   }
//   /**
//    * Delete the contents of the given directory, given that we know it is a directory.
//    *
//    * @param dir the directory whose contents are to be deleted
//    */
//   static void deleteDirectory(JavaFile dir) {
//     for (JavaFile file in dir.listFiles()) {
//       if (file.isDirectory()) {
//         deleteDirectory(file);
//       } else {
//         if (!file.delete()) {
//           throw new JavaIOException("Failed to delete ${file}");
//         }
//       }
//     }
//     if (!dir.delete()) {
//       throw new JavaIOException("Failed to delete ${dir}");
//     }
//   }
//   /**
//    * Delete symlink or throw an exception if creation of symlinks is not supported. Use
//    * [isSymLinkSupported] to determine if this method will work on the current platform.
//    *
//    * @param linkFile the symlink to be deleted (not `null`, and must exist)
//    */
//   static void deleteSymLink(JavaFile linkFile) {
//     JUnitTestCase.assertTrueMsg("Creation of symlinks is not supported", isSymLinkSupported);
//     JUnitTestCase.assertTrueMsg("Link does not exist", linkFile.exists());
//     ProcessRunner runner = new ProcessRunner(<String> ["rm", linkFile.getPath()]);
//     int exitCode = runner.runSync(10000);
//     if (exitCode != 0) {
//       JUnitTestCase.fail("Symlink deletion failed [${exitCode}] ${linkFile}");
//     }
//   }
//   /**
//    * Delete the temporary directory. This should called from the [TestCase] tearDown method of
//    * any test case which calls [createTempDir] or [createTempFile].
//    */
//   static void deleteTempDir() {
//     if (_TEMP_DIR.exists()) {
//       deleteDirectory(_TEMP_DIR);
//     }
//   }
//   /**
//    * Determine if creation of symlinks via [createSymLink] is supported.
//    *
//    * @return `true` if symlinks can be created, else false
//    */
//   static bool get isSymLinkSupported => !OSUtilities.isWindows();
//   /**
//    * Convert all forward slashes in the given path to the current file separator.
//    *
//    * @param path the path to be converted
//    * @return the converted path
//    */
//   static String _convertPath(String path) {
//     if (JavaFile.separator == "/") {
//       // We're on a unix-ish OS.
//       return path;
//     } else {
//       // On windows, the path separator is '\'.
//       return path.replaceAll("/", "\\\\");
//     }
//   }
// }
// class GeneralizingElementVisitor_AngularTest_findElement extends GeneralizingElementVisitor<Object> {
//   ElementKind kind;
//   String name;
//   List<Element> result;
//   GeneralizingElementVisitor_AngularTest_findElement(this.kind, this.name, this.result) : super();
//   @override
//   Object visitElement(Element element) {
//     if ((kind == null || element.kind == kind) && name == element.name) {
//       result[0] = element;
//     }
//     return super.visitElement(element);
//   }
// }
// /**
//  * Utility methods to create HTML nodes.
//  */
// class HtmlFactory {
//   static XmlAttributeNode attribute(String name, String value) {
//     Token nameToken = _stringToken(name);
//     Token equalsToken = new Token.con1(TokenType.EQ, 0);
//     Token valueToken = _stringToken(value);
//     return new XmlAttributeNode(nameToken, equalsToken, valueToken);
//   }
//   static List list(List<Object> elements) {
//     List elementList = new List();
//     for (Object element in elements) {
//       elementList.add(element);
//     }
//     return elementList;
//   }
//   static HtmlScriptTagNode scriptTag(List<XmlAttributeNode> attributes) => new HtmlScriptTagNode(_ltToken(), _stringToken("script"), list(attributes), _sgtToken(), null, null, null, null);
//   static HtmlScriptTagNode scriptTagWithContent(String contents, List<XmlAttributeNode> attributes) {
//     Token attributeEnd = _gtToken();
//     Token contentToken = _stringToken(contents);
//     attributeEnd.setNext(contentToken);
//     Token contentEnd = _ltsToken();
//     contentToken.setNext(contentEnd);
//     return new HtmlScriptTagNode(_ltToken(), _stringToken("script"), list(attributes), attributeEnd, null, contentEnd, _stringToken("script"), _gtToken());
//   }
//   static XmlTagNode tagNode(String name, List<XmlAttributeNode> attributes) => new XmlTagNode(_ltToken(), _stringToken(name), [], _sgtToken(), null, null, null, null);
//   static Token _gtToken() => new Token.con1(TokenType.GT, 0);
//   static Token _ltsToken() => new Token.con1(TokenType.LT_SLASH, 0);
//   static Token _ltToken() => new Token.con1(TokenType.LT, 0);
//   static Token _sgtToken() => new Token.con1(TokenType.SLASH_GT, 0);
//   static Token _stringToken(String value) => new Token.con2(TokenType.STRING, 0, value);
// }
// class HtmlParserTest extends EngineTestCase {
//   /**
//    * The name of the 'script' tag in an HTML file.
//    */
//   static String _TAG_SCRIPT = "script";
//   void fail_parse_scriptWithComment() {
//     String scriptBody = EngineTestCase.createSource([
//         "      /**",
//         "       *     <editable-label bind-value=\"dartAsignableValue\">",
//         "       *     </editable-label>",
//         "       */",
//         "      class Foo {}"]);
//     HtmlUnit htmlUnit = parse(EngineTestCase.createSource([
//         "  <html>",
//         "    <body>",
//         "      <script type=\"application/dart\">",
//         scriptBody,
//         "      </script>",
//         "    </body>",
//         "  </html>"]));
//     _validate(htmlUnit, [_t4("html", [_t4("body", [_t("script", _a(["type", "\"application/dart\""]), scriptBody, [])])])]);
//   }
//   void test_parse_attribute() {
//     HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
//     _validate(htmlUnit, [_t4("html", [_t("body", _a(["foo", "\"sdfsdf\""]), "", [])])]);
//     XmlTagNode htmlNode = htmlUnit.tagNodes[0];
//     XmlTagNode bodyNode = htmlNode.tagNodes[0];
//     JUnitTestCase.assertEquals("sdfsdf", bodyNode.attributes[0].text);
//   }
//   void test_parse_attribute_EOF() {
//     HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"");
//     _validate(htmlUnit, [_t4("html", [_t("body", _a(["foo", "\"sdfsdf\""]), "", [])])]);
//   }
//   void test_parse_attribute_EOF_missing_quote() {
//     HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsd");
//     _validate(htmlUnit, [_t4("html", [_t("body", _a(["foo", "\"sdfsd"]), "", [])])]);
//     XmlTagNode htmlNode = htmlUnit.tagNodes[0];
//     XmlTagNode bodyNode = htmlNode.tagNodes[0];
//     JUnitTestCase.assertEquals("sdfsd", bodyNode.attributes[0].text);
//   }
//   void test_parse_attribute_extra_quote() {
//     HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"\"></body></html>");
//     _validate(htmlUnit, [_t4("html", [_t("body", _a(["foo", "\"sdfsdf\""]), "", [])])]);
//   }
//   void test_parse_attribute_single_quote() {
//     HtmlUnit htmlUnit = parse("<html><body foo='sdfsdf'></body></html>");
//     _validate(htmlUnit, [_t4("html", [_t("body", _a(["foo", "'sdfsdf'"]), "", [])])]);
//     XmlTagNode htmlNode = htmlUnit.tagNodes[0];
//     XmlTagNode bodyNode = htmlNode.tagNodes[0];
//     JUnitTestCase.assertEquals("sdfsdf", bodyNode.attributes[0].text);
//   }
//   void test_parse_comment_embedded() {
//     HtmlUnit htmlUnit = parse("<html <!-- comment -->></html>");
//     _validate(htmlUnit, [_t3("html", "", [])]);
//   }
//   void test_parse_comment_first() {
//     HtmlUnit htmlUnit = parse("<!-- comment --><html></html>");
//     _validate(htmlUnit, [_t3("html", "", [])]);
//   }
//   void test_parse_comment_in_content() {
//     HtmlUnit htmlUnit = parse("<html><!-- comment --></html>");
//     _validate(htmlUnit, [_t3("html", "<!-- comment -->", [])]);
//   }
//   void test_parse_content() {
//     HtmlUnit htmlUnit = parse("<html>\n<p a=\"b\">blat \n </p>\n</html>");
//     // XmlTagNode.getContent() does not include whitespace between '<' and '>' at this time
//     _validate(htmlUnit, [_t3("html", "\n<pa=\"b\">blat \n </p>\n", [_t("p", _a(["a", "\"b\""]), "blat \n ", [])])]);
//   }
//   void test_parse_content_none() {
//     HtmlUnit htmlUnit = parse("<html><p/>blat<p/></html>");
//     _validate(htmlUnit, [_t3("html", "<p/>blat<p/>", [_t3("p", "", []), _t3("p", "", [])])]);
//   }
//   void test_parse_declaration() {
//     HtmlUnit htmlUnit = parse("<!DOCTYPE html>\n\n<html><p></p></html>");
//     _validate(htmlUnit, [_t4("html", [_t3("p", "", [])])]);
//   }
//   void test_parse_directive() {
//     HtmlUnit htmlUnit = parse("<?xml ?>\n\n<html><p></p></html>");
//     _validate(htmlUnit, [_t4("html", [_t3("p", "", [])])]);
//   }
//   void test_parse_getAttribute() {
//     HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
//     XmlTagNode htmlNode = htmlUnit.tagNodes[0];
//     XmlTagNode bodyNode = htmlNode.tagNodes[0];
//     JUnitTestCase.assertEquals("sdfsdf", bodyNode.getAttribute("foo").text);
//     JUnitTestCase.assertEquals(null, bodyNode.getAttribute("bar"));
//     JUnitTestCase.assertEquals(null, bodyNode.getAttribute(null));
//   }
//   void test_parse_getAttributeText() {
//     HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
//     XmlTagNode htmlNode = htmlUnit.tagNodes[0];
//     XmlTagNode bodyNode = htmlNode.tagNodes[0];
//     JUnitTestCase.assertEquals("sdfsdf", bodyNode.getAttributeText("foo"));
//     JUnitTestCase.assertEquals(null, bodyNode.getAttributeText("bar"));
//     JUnitTestCase.assertEquals(null, bodyNode.getAttributeText(null));
//   }
//   void test_parse_headers() {
//     String code = EngineTestCase.createSource([
//         "<html>",
//         "  <body>",
//         "    <h2>000</h2>",
//         "    <div>",
//         "      111",
//         "    </div>",
//         "  </body>",
//         "</html>"]);
//     HtmlUnit htmlUnit = parse(code);
//     _validate(htmlUnit, [_t4("html", [_t4("body", [_t3("h2", "000", []), _t4("div", [])])])]);
//   }
//   void test_parse_script() {
//     HtmlUnit htmlUnit = parse("<html><script >here is <p> some</script></html>");
//     _validate(htmlUnit, [_t4("html", [_t3("script", "here is <p> some", [])])]);
//   }
//   void test_parse_self_closing() {
//     HtmlUnit htmlUnit = parse("<html>foo<br>bar</html>");
//     _validate(htmlUnit, [_t3("html", "foo<br>bar", [_t3("br", "", [])])]);
//   }
//   void test_parse_self_closing_declaration() {
//     HtmlUnit htmlUnit = parse("<!DOCTYPE html><html>foo</html>");
//     _validate(htmlUnit, [_t3("html", "foo", [])]);
//   }
//   HtmlUnit parse(String contents) {
//     TestSource source = new TestSource.con1(FileUtilities2.createFile("/test.dart"), contents);
//     AbstractScanner scanner = new StringScanner(source, contents);
//     scanner.passThroughElements = <String> [_TAG_SCRIPT];
//     Token token = scanner.tokenize();
//     LineInfo lineInfo = new LineInfo(scanner.lineStarts);
//     GatheringErrorListener errorListener = new GatheringErrorListener();
//     HtmlUnit unit = new HtmlParser(source, errorListener).parse(token, lineInfo);
//     errorListener.assertNoErrors();
//     return unit;
//   }
//   XmlValidator_Attributes _a(List<String> keyValuePairs) => new XmlValidator_Attributes(keyValuePairs);
//   XmlValidator_Tag _t(String tag, XmlValidator_Attributes attributes, String content, List<XmlValidator_Tag> children) => new XmlValidator_Tag(tag, attributes, content, children);
//   XmlValidator_Tag _t2(String tag, XmlValidator_Attributes attributes, List<XmlValidator_Tag> children) => new XmlValidator_Tag(tag, attributes, null, children);
//   XmlValidator_Tag _t3(String tag, String content, List<XmlValidator_Tag> children) => new XmlValidator_Tag(tag, new XmlValidator_Attributes([]), content, children);
//   XmlValidator_Tag _t4(String tag, List<XmlValidator_Tag> children) => new XmlValidator_Tag(tag, new XmlValidator_Attributes([]), null, children);
//   void _validate(HtmlUnit htmlUnit, List<XmlValidator_Tag> expectedTags) {
//     XmlValidator validator = new XmlValidator();
//     validator.expectTags(expectedTags);
//     htmlUnit.accept(validator);
//     validator.assertValid();
//   }
//   static dartSuite() {
//     _ut.group('HtmlParserTest', () {
//       _ut.test('test_parse_attribute', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_attribute);
//       });
//       _ut.test('test_parse_attribute_EOF', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_attribute_EOF);
//       });
//       _ut.test('test_parse_attribute_EOF_missing_quote', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_attribute_EOF_missing_quote);
//       });
//       _ut.test('test_parse_attribute_extra_quote', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_attribute_extra_quote);
//       });
//       _ut.test('test_parse_attribute_single_quote', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_attribute_single_quote);
//       });
//       _ut.test('test_parse_comment_embedded', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_comment_embedded);
//       });
//       _ut.test('test_parse_comment_first', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_comment_first);
//       });
//       _ut.test('test_parse_comment_in_content', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_comment_in_content);
//       });
//       _ut.test('test_parse_content', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_content);
//       });
//       _ut.test('test_parse_content_none', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_content_none);
//       });
//       _ut.test('test_parse_declaration', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_declaration);
//       });
//       _ut.test('test_parse_directive', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_directive);
//       });
//       _ut.test('test_parse_getAttribute', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_getAttribute);
//       });
//       _ut.test('test_parse_getAttributeText', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_getAttributeText);
//       });
//       _ut.test('test_parse_headers', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_headers);
//       });
//       _ut.test('test_parse_script', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_script);
//       });
//       _ut.test('test_parse_self_closing', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_self_closing);
//       });
//       _ut.test('test_parse_self_closing_declaration', () {
//         final __test = new HtmlParserTest();
//         runJUnitTest(__test, __test.test_parse_self_closing_declaration);
//       });
//     });
//   }
// }
// class HtmlTagInfoBuilderTest extends HtmlParserTest {
//   void test_buider() {
//     HtmlTagInfoBuilder builder = new HtmlTagInfoBuilder();
//     HtmlUnit unit = parse(EngineTestCase.createSource([
//         "<html>",
//         "  <body>",
//         "    <div id=\"x\"></div>",
//         "    <p class='c'></p>",
//         "    <div class='c'></div>",
//         "  </body>",
//         "</html>"]));
//     unit.accept(builder);
//     HtmlTagInfo info = builder.getTagInfo();
//     JUnitTestCase.assertNotNull(info);
//     List<String> allTags = info.getAllTags();
//     EngineTestCase.assertLength(4, allTags);
//     JUnitTestCase.assertEquals("div", info.getTagWithId("x"));
//     List<String> tagsWithClass = info.getTagsWithClass("c");
//     EngineTestCase.assertLength(2, tagsWithClass);
//   }
//   static dartSuite() {
//     _ut.group('HtmlTagInfoBuilderTest', () {
//       _ut.test('test_buider', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_buider);
//       });
//       _ut.test('test_parse_attribute', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_attribute);
//       });
//       _ut.test('test_parse_attribute_EOF', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_attribute_EOF);
//       });
//       _ut.test('test_parse_attribute_EOF_missing_quote', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_attribute_EOF_missing_quote);
//       });
//       _ut.test('test_parse_attribute_extra_quote', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_attribute_extra_quote);
//       });
//       _ut.test('test_parse_attribute_single_quote', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_attribute_single_quote);
//       });
//       _ut.test('test_parse_comment_embedded', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_comment_embedded);
//       });
//       _ut.test('test_parse_comment_first', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_comment_first);
//       });
//       _ut.test('test_parse_comment_in_content', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_comment_in_content);
//       });
//       _ut.test('test_parse_content', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_content);
//       });
//       _ut.test('test_parse_content_none', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_content_none);
//       });
//       _ut.test('test_parse_declaration', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_declaration);
//       });
//       _ut.test('test_parse_directive', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_directive);
//       });
//       _ut.test('test_parse_getAttribute', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_getAttribute);
//       });
//       _ut.test('test_parse_getAttributeText', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_getAttributeText);
//       });
//       _ut.test('test_parse_headers', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_headers);
//       });
//       _ut.test('test_parse_script', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_script);
//       });
//       _ut.test('test_parse_self_closing', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_self_closing);
//       });
//       _ut.test('test_parse_self_closing_declaration', () {
//         final __test = new HtmlTagInfoBuilderTest();
//         runJUnitTest(__test, __test.test_parse_self_closing_declaration);
//       });
//     });
//   }
// }
// class HtmlUnitBuilderTest extends EngineTestCase {
//   AnalysisContextImpl _context;
//   void test_embedded_script() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource([
//         "<html>",
//         "<script type=\"application/dart\">foo=2;</script>",
//         "</html>"]));
//     _validate(element, [_s(_l([_v("foo")]))]);
//   }
//   void test_embedded_script_no_content() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource([
//         "<html>",
//         "<script type=\"application/dart\"></script>",
//         "</html>"]));
//     _validate(element, [_s(_l([]))]);
//   }
//   void test_external_script() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource([
//         "<html>",
//         "<script type=\"application/dart\" src=\"other.dart\"/>",
//         "</html>"]));
//     _validate(element, [_s2("other.dart")]);
//   }
//   void test_external_script_no_source() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource([
//         "<html>",
//         "<script type=\"application/dart\"/>",
//         "</html>"]));
//     _validate(element, [_s2(null as String)]);
//   }
//   void test_external_script_with_content() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource([
//         "<html>",
//         "<script type=\"application/dart\" src=\"other.dart\">blat=2;</script>",
//         "</html>"]));
//     _validate(element, [_s2("other.dart")]);
//   }
//   void test_no_scripts() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource(["<!DOCTYPE html>", "<html><p></p></html>"]));
//     _validate(element, []);
//   }
//   void test_two_dart_scripts() {
//     HtmlElementImpl element = _build(EngineTestCase.createSource([
//         "<html>",
//         "<script type=\"application/dart\">bar=2;</script>",
//         "<script type=\"application/dart\" src=\"other.dart\"/>",
//         "<script src=\"dart.js\"/>",
//         "</html>"]));
//     _validate(element, [_s(_l([_v("bar")])), _s2("other.dart")]);
//   }
//   @override
//   void setUp() {
//     _context = AnalysisContextFactory.contextWithCore();
//   }
//   HtmlUnitBuilderTest_ExpectedLibrary _l(List<HtmlUnitBuilderTest_ExpectedVariable> expectedVariables) => new HtmlUnitBuilderTest_ExpectedLibrary(this, expectedVariables);
//   HtmlElementImpl _build(String contents) {
//     TestSource source = new TestSource.con1(FileUtilities2.createFile("/test.html"), contents);
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.addedSource(source);
//     _context.applyChanges(changeSet);
//     HtmlUnitBuilder builder = new HtmlUnitBuilder(_context);
//     return builder.buildHtmlElement(source, _context.getModificationStamp(source), _context.parseHtmlUnit(source));
//   }
//   HtmlUnitBuilderTest_ExpectedScript _s(HtmlUnitBuilderTest_ExpectedLibrary expectedLibrary) => new HtmlUnitBuilderTest_ExpectedScript.con1(expectedLibrary);
//   HtmlUnitBuilderTest_ExpectedScript _s2(String scriptSourcePath) => new HtmlUnitBuilderTest_ExpectedScript.con2(scriptSourcePath);
//   HtmlUnitBuilderTest_ExpectedVariable _v(String varName) => new HtmlUnitBuilderTest_ExpectedVariable(varName);
//   void _validate(HtmlElementImpl element, List<HtmlUnitBuilderTest_ExpectedScript> expectedScripts) {
//     JUnitTestCase.assertSame(_context, element.context);
//     List<HtmlScriptElement> scripts = element.scripts;
//     JUnitTestCase.assertNotNull(scripts);
//     EngineTestCase.assertLength(expectedScripts.length, scripts);
//     for (int scriptIndex = 0; scriptIndex < scripts.length; scriptIndex++) {
//       expectedScripts[scriptIndex]._validate(scriptIndex, scripts[scriptIndex]);
//     }
//   }
//   static dartSuite() {
//     _ut.group('HtmlUnitBuilderTest', () {
//       _ut.test('test_embedded_script', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_embedded_script);
//       });
//       _ut.test('test_embedded_script_no_content', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_embedded_script_no_content);
//       });
//       _ut.test('test_external_script', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_external_script);
//       });
//       _ut.test('test_external_script_no_source', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_external_script_no_source);
//       });
//       _ut.test('test_external_script_with_content', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_external_script_with_content);
//       });
//       _ut.test('test_no_scripts', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_no_scripts);
//       });
//       _ut.test('test_two_dart_scripts', () {
//         final __test = new HtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_two_dart_scripts);
//       });
//     });
//   }
// }
// class HtmlUnitBuilderTest_ExpectedLibrary {
//   final HtmlUnitBuilderTest HtmlUnitBuilderTest_this;
//   final List<HtmlUnitBuilderTest_ExpectedVariable> _expectedVariables;
//   HtmlUnitBuilderTest_ExpectedLibrary(this.HtmlUnitBuilderTest_this, this._expectedVariables);
//   void _validate(int scriptIndex, EmbeddedHtmlScriptElementImpl script) {
//     LibraryElement library = script.scriptLibrary;
//     JUnitTestCase.assertNotNullMsg("script ${scriptIndex}", library);
//     JUnitTestCase.assertSameMsg("script ${scriptIndex}", HtmlUnitBuilderTest_this._context, script.context);
//     CompilationUnitElement unit = library.definingCompilationUnit;
//     JUnitTestCase.assertNotNullMsg("script ${scriptIndex}", unit);
//     List<TopLevelVariableElement> variables = unit.topLevelVariables;
//     EngineTestCase.assertLength(_expectedVariables.length, variables);
//     for (int index = 0; index < variables.length; index++) {
//       _expectedVariables[index].validate(scriptIndex, variables[index]);
//     }
//     JUnitTestCase.assertSameMsg("script ${scriptIndex}", script, library.enclosingElement);
//   }
// }
// class HtmlUnitBuilderTest_ExpectedScript {
//   String _expectedExternalScriptName;
//   HtmlUnitBuilderTest_ExpectedLibrary _expectedLibrary;
//   HtmlUnitBuilderTest_ExpectedScript.con1(HtmlUnitBuilderTest_ExpectedLibrary expectedLibrary) {
//     this._expectedExternalScriptName = null;
//     this._expectedLibrary = expectedLibrary;
//   }
//   HtmlUnitBuilderTest_ExpectedScript.con2(String expectedExternalScriptPath) {
//     this._expectedExternalScriptName = expectedExternalScriptPath;
//     this._expectedLibrary = null;
//   }
//   void _validate(int scriptIndex, HtmlScriptElement script) {
//     if (_expectedLibrary != null) {
//       _validateEmbedded(scriptIndex, script);
//     } else {
//       _validateExternal(scriptIndex, script);
//     }
//   }
//   void _validateEmbedded(int scriptIndex, HtmlScriptElement script) {
//     if (script is! EmbeddedHtmlScriptElementImpl) {
//       JUnitTestCase.fail("Expected script ${scriptIndex} to be embedded, but found ${(script != null ? script.runtimeType : "null")}");
//     }
//     EmbeddedHtmlScriptElementImpl embeddedScript = script as EmbeddedHtmlScriptElementImpl;
//     _expectedLibrary._validate(scriptIndex, embeddedScript);
//   }
//   void _validateExternal(int scriptIndex, HtmlScriptElement script) {
//     if (script is! ExternalHtmlScriptElementImpl) {
//       JUnitTestCase.fail("Expected script ${scriptIndex} to be external with src=${_expectedExternalScriptName} but found ${(script != null ? script.runtimeType : "null")}");
//     }
//     ExternalHtmlScriptElementImpl externalScript = script as ExternalHtmlScriptElementImpl;
//     Source scriptSource = externalScript.scriptSource;
//     if (_expectedExternalScriptName == null) {
//       JUnitTestCase.assertNullMsg("script ${scriptIndex}", scriptSource);
//     } else {
//       JUnitTestCase.assertNotNullMsg("script ${scriptIndex}", scriptSource);
//       String actualExternalScriptName = scriptSource.shortName;
//       JUnitTestCase.assertEqualsMsg("script ${scriptIndex}", _expectedExternalScriptName, actualExternalScriptName);
//     }
//   }
// }
// class HtmlUnitBuilderTest_ExpectedVariable {
//   final String _expectedName;
//   HtmlUnitBuilderTest_ExpectedVariable(this._expectedName);
//   void validate(int scriptIndex, TopLevelVariableElement variable) {
//     JUnitTestCase.assertNotNullMsg("script ${scriptIndex}", variable);
//     JUnitTestCase.assertEqualsMsg("script ${scriptIndex}", _expectedName, variable.name);
//   }
// }
// /**
//  * Instances of the class `HtmlWarningCodeTest` test the generation of HTML warning codes.
//  */
// class HtmlWarningCodeTest extends EngineTestCase {
//   /**
//    * The source factory used to create the sources to be resolved.
//    */
//   SourceFactory _sourceFactory;
//   /**
//    * The analysis context used to resolve the HTML files.
//    */
//   AnalysisContextImpl _context;
//   /**
//    * The contents of the 'test.html' file.
//    */
//   String _contents;
//   /**
//    * The list of reported errors.
//    */
//   List<AnalysisError> _errors;
//   void test_invalidUri() {
//     _verify(EngineTestCase.createSource([
//         "<html>",
//         "<script type='application/dart' src='ht:'/>",
//         "</html>"]), [HtmlWarningCode.INVALID_URI]);
//     _assertErrorLocation2(_errors[0], "ht:");
//   }
//   void test_uriDoesNotExist() {
//     _verify(EngineTestCase.createSource([
//         "<html>",
//         "<script type='application/dart' src='other.dart'/>",
//         "</html>"]), [HtmlWarningCode.URI_DOES_NOT_EXIST]);
//     _assertErrorLocation2(_errors[0], "other.dart");
//   }
//   @override
//   void setUp() {
//     _sourceFactory = new SourceFactory([new FileUriResolver()]);
//     _context = new AnalysisContextImpl();
//     _context.sourceFactory = _sourceFactory;
//   }
//   void _assertErrorLocation(AnalysisError error, int expectedOffset, int expectedLength) {
//     JUnitTestCase.assertEqualsMsg(error.toString(), expectedOffset, error.offset);
//     JUnitTestCase.assertEqualsMsg(error.toString(), expectedLength, error.length);
//   }
//   void _assertErrorLocation2(AnalysisError error, String expectedString) {
//     _assertErrorLocation(error, _contents.indexOf(expectedString), expectedString.length);
//   }
//   void _verify(String contents, List<ErrorCode> expectedErrorCodes) {
//     this._contents = contents;
//     TestSource source = new TestSource.con1(FileUtilities2.createFile("/test.html"), contents);
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.addedSource(source);
//     _context.applyChanges(changeSet);
//     HtmlUnitBuilder builder = new HtmlUnitBuilder(_context);
//     builder.buildHtmlElement(source, _context.getModificationStamp(source), _context.parseHtmlUnit(source));
//     GatheringErrorListener errorListener = new GatheringErrorListener();
//     errorListener.addAll2(builder.errorListener);
//     errorListener.assertErrorsWithCodes(expectedErrorCodes);
//     _errors = errorListener.errors;
//   }
//   static dartSuite() {
//     _ut.group('HtmlWarningCodeTest', () {
//       _ut.test('test_invalidUri', () {
//         final __test = new HtmlWarningCodeTest();
//         runJUnitTest(__test, __test.test_invalidUri);
//       });
//       _ut.test('test_uriDoesNotExist', () {
//         final __test = new HtmlWarningCodeTest();
//         runJUnitTest(__test, __test.test_uriDoesNotExist);
//       });
//     });
//   }
// }
// /**
//  * Instances of the class `MockDartSdk` implement a [DartSdk].
//  */
// class MockDartSdk implements DartSdk {
//   @override
//   Source fromFileUri(Uri uri) => null;
//   @override
//   AnalysisContext get context => null;
//   @override
//   List<SdkLibrary> get sdkLibraries => null;
//   @override
//   SdkLibrary getSdkLibrary(String dartUri) => null;
//   @override
//   String get sdkVersion => null;
//   @override
//   List<String> get uris => null;
//   @override
//   Source mapDartUri(String dartUri) => null;
// }
// class NonExistingSourceTest extends JUnitTestCase {
//   Source _source = new NonExistingSource("/foo/bar/baz.dart", UriKind.PACKAGE_URI);
//   void test_access() {
//     JUnitTestCase.assertFalse(_source.exists());
//     JUnitTestCase.assertSame(UriKind.PACKAGE_URI, _source.uriKind);
//     JUnitTestCase.assertEquals("/foo/bar/baz.dart", _source.fullName);
//     JUnitTestCase.assertEquals("/foo/bar/baz.dart", _source.shortName);
//     JUnitTestCase.assertEquals(0, _source.modificationStamp);
//     JUnitTestCase.assertFalse(_source.isInSystemLibrary);
//   }
//   void test_getContents() {
//     try {
//       _source.contents;
//       JUnitTestCase.fail();
//     } on UnsupportedOperationException catch (e) {
//     }
//   }
//   void test_getContentsToReceiver() {
//     try {
//       _source.getContentsToReceiver(null);
//       JUnitTestCase.fail();
//     } on UnsupportedOperationException catch (e) {
//     }
//   }
//   void test_getEncoding() {
//     try {
//       _source.encoding;
//       JUnitTestCase.fail();
//     } on UnsupportedOperationException catch (e) {
//     }
//   }
//   void test_resolveRelative() {
//     try {
//       _source.resolveRelativeUri(parseUriWithException("qux.dart"));
//       JUnitTestCase.fail();
//     } on UnsupportedOperationException catch (e) {
//     }
//   }
//   static dartSuite() {
//     _ut.group('NonExistingSourceTest', () {
//       _ut.test('test_access', () {
//         final __test = new NonExistingSourceTest();
//         runJUnitTest(__test, __test.test_access);
//       });
//       _ut.test('test_getContents', () {
//         final __test = new NonExistingSourceTest();
//         runJUnitTest(__test, __test.test_getContents);
//       });
//       _ut.test('test_getContentsToReceiver', () {
//         final __test = new NonExistingSourceTest();
//         runJUnitTest(__test, __test.test_getContentsToReceiver);
//       });
//       _ut.test('test_getEncoding', () {
//         final __test = new NonExistingSourceTest();
//         runJUnitTest(__test, __test.test_getEncoding);
//       });
//       _ut.test('test_resolveRelative', () {
//         final __test = new NonExistingSourceTest();
//         runJUnitTest(__test, __test.test_resolveRelative);
//       });
//     });
//   }
// }
// class PackageUriResolverTest extends JUnitTestCase {
//   void test_absolute_vs_canonical() {
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/packages");
//     // Cannot compare paths on Windows because this
//     //    assertEquals(directory.getAbsolutePath(), directory.getCanonicalPath());
//     // results in
//     //    expected:<[e]:\does\not\exist\pac...> but was:<[E]:\does\not\exist\pac...>
//     JUnitTestCase.assertEquals(directory.getAbsoluteFile(), directory.getCanonicalFile());
//   }
//   void test_creation() {
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/packages");
//     JUnitTestCase.assertNotNull(new PackageUriResolver([directory]));
//   }
//   void test_isPackageUri_null_scheme() {
//     Uri uri = parseUriWithException("foo.dart");
//     JUnitTestCase.assertNull(uri.scheme);
//     JUnitTestCase.assertFalse(PackageUriResolver.isPackageUri(uri));
//   }
//   void test_resolve_canonical() {
//     if (!FileUtilities2.isSymLinkSupported) {
//       print("Skipping ${runtimeType.toString()} test_resolve_canonical");
//       return;
//     }
//     JavaFile lib1Dir = FileUtilities2.createTempDir("pkg1/lib").getCanonicalFile();
//     JavaFile otherDir = FileUtilities2.createTempDir("pkg1/other").getCanonicalFile();
//     JavaFile packagesDir = FileUtilities2.createTempDir("pkg1/packages").getCanonicalFile();
//     JavaFile lib2Dir = FileUtilities2.createTempDir("pkg2/lib").getCanonicalFile();
//     // Create symlink packages/pkg1 --> lib1
//     JavaFile pkg1Dir = new JavaFile.relative(packagesDir, "pkg1");
//     FileUtilities2.createSymLink(lib1Dir, pkg1Dir);
//     // Create symlink packages/pkg1/other --> other
//     FileUtilities2.createSymLink(otherDir, new JavaFile.relative(lib1Dir, "other"));
//     // Create symlink packages/pkg2 --> lib2
//     JavaFile pkg2Dir = new JavaFile.relative(packagesDir, "pkg2");
//     FileUtilities2.createSymLink(lib2Dir, pkg2Dir);
//     UriResolver resolver = new PackageUriResolver([packagesDir]);
//     // Assert that package:pkg1 resolves to lib1
//     Source result = resolver.resolveAbsolute(parseUriWithException("package:pkg1"));
//     JUnitTestCase.assertEquals(lib1Dir, new JavaFile(result.fullName));
//     JUnitTestCase.assertSame(UriKind.FILE_URI, result.uriKind);
//     // Assert that package:pkg1/ resolves to lib1
//     result = resolver.resolveAbsolute(parseUriWithException("package:pkg1/"));
//     JUnitTestCase.assertEquals(lib1Dir, new JavaFile(result.fullName));
//     JUnitTestCase.assertSame(UriKind.FILE_URI, result.uriKind);
//     // Assert that package:pkg1/other resolves to lib1/other not other
//     result = resolver.resolveAbsolute(parseUriWithException("package:pkg1/other"));
//     JUnitTestCase.assertEquals(new JavaFile.relative(lib1Dir, "other"), new JavaFile(result.fullName));
//     JUnitTestCase.assertSame(UriKind.FILE_URI, result.uriKind);
//     // Assert that package:pkg1/other/some.dart resolves to lib1/other/some.dart not other.dart
//     // when some.dart does NOT exist
//     JavaFile someDart = new JavaFile.relative(new JavaFile.relative(lib1Dir, "other"), "some.dart");
//     result = resolver.resolveAbsolute(parseUriWithException("package:pkg1/other/some.dart"));
//     JUnitTestCase.assertEquals(someDart, new JavaFile(result.fullName));
//     // Assert that package:pkg1/other/some.dart resolves to lib1/other/some.dart not other.dart
//     // when some.dart exists
//     JUnitTestCase.assertTrue(new JavaFile.relative(otherDir, someDart.getName()).createNewFile());
//     JUnitTestCase.assertTrue(someDart.exists());
//     result = resolver.resolveAbsolute(parseUriWithException("package:pkg1/other/some.dart"));
//     JUnitTestCase.assertEquals(someDart, new JavaFile(result.fullName));
//     // Assert that package:pkg2/ resolves to lib2
//     result = resolver.resolveAbsolute(parseUriWithException("package:pkg2/"));
//     JUnitTestCase.assertEquals(lib2Dir, new JavaFile(result.fullName));
//     JUnitTestCase.assertSame(UriKind.PACKAGE_URI, result.uriKind);
//   }
//   void test_resolve_invalid() {
//     JavaFile packagesDir = new JavaFile("packages");
//     UriResolver resolver = new PackageUriResolver([packagesDir]);
//     // Invalid: URI
//     try {
//       parseUriWithException("package:");
//       JUnitTestCase.fail("Expected exception");
//     } on URISyntaxException catch (e) {
//     }
//     // Invalid: just slash
//     Source result = resolver.resolveAbsolute(parseUriWithException("package:/"));
//     JUnitTestCase.assertNull(result);
//     // Invalid: leading slash... or should we gracefully degrade and ignore the leading slash?
//     result = resolver.resolveAbsolute(parseUriWithException("package:/foo"));
//     JUnitTestCase.assertNull(result);
//   }
//   void test_resolve_nonPackage() {
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/packages");
//     UriResolver resolver = new PackageUriResolver([directory]);
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:core"));
//     JUnitTestCase.assertNull(result);
//   }
//   void test_resolve_package() {
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/packages");
//     UriResolver resolver = new PackageUriResolver([directory]);
//     Source result = resolver.resolveAbsolute(parseUriWithException("package:third/party/library.dart"));
//     JUnitTestCase.assertNotNull(result);
//     JUnitTestCase.assertEquals(FileUtilities2.createFile("/does/not/exist/packages/third/party/library.dart").getAbsoluteFile(), new JavaFile(result.fullName));
//   }
//   void test_restore() {
//     if (!FileUtilities2.isSymLinkSupported) {
//       print("Skipping ${runtimeType.toString()} test_restore");
//       return;
//     }
//     JavaFile argsCanonicalDir = FileUtilities2.createTempDir("args").getCanonicalFile();
//     JavaFile packagesDir = FileUtilities2.createTempDir("packages");
//     // Create symlink packages/args --> args-canonical
//     FileUtilities2.createSymLink(argsCanonicalDir, new JavaFile.relative(packagesDir, "args"));
//     UriResolver resolver = new PackageUriResolver([packagesDir]);
//     // args-canonical/args.dart --> packages:args/args.dart
//     JavaFile someDart = new JavaFile.relative(argsCanonicalDir, "args.dart");
//     FileBasedSource source = new FileBasedSource.con1(someDart);
//     JUnitTestCase.assertEquals(parseUriWithException("package:args/args.dart"), resolver.restoreAbsolute(source));
//   }
//   @override
//   void tearDown() {
//     FileUtilities2.deleteTempDir();
//   }
//   static dartSuite() {
//     _ut.group('PackageUriResolverTest', () {
//       _ut.test('test_absolute_vs_canonical', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_absolute_vs_canonical);
//       });
//       _ut.test('test_creation', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_isPackageUri_null_scheme', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_isPackageUri_null_scheme);
//       });
//       _ut.test('test_resolve_canonical', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_canonical);
//       });
//       _ut.test('test_resolve_invalid', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_invalid);
//       });
//       _ut.test('test_resolve_nonPackage', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_nonPackage);
//       });
//       _ut.test('test_resolve_package', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_resolve_package);
//       });
//       _ut.test('test_restore', () {
//         final __test = new PackageUriResolverTest();
//         runJUnitTest(__test, __test.test_restore);
//       });
//     });
//   }
// }
// class PolymerCompilationUnitBuilderTest extends PolymerTest {
//   void test_badAnnotation_noArguments() {
//     addTagDartSource(EngineTestCase.createSource([
//         "class MyAnnotation {}",
//         "@MyAnnotation",
//         "class MyElement {",
//         "}",
//         ""]));
//     resolveTagDart();
//     JUnitTestCase.assertNull(tagDartElement);
//   }
//   void test_badAnnotation_notConstructor() {
//     addTagDartSource(EngineTestCase.createSource(["@NoSuchAnnotation()", "class MyElement {", "}", ""]));
//     resolveTagDart();
//     JUnitTestCase.assertNull(tagDartElement);
//   }
//   void test_customTag() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "}",
//         ""]));
//     resolveTagDart();
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertEquals("my-element", tagDartElement.name);
//     JUnitTestCase.assertEquals(findTagDartOffset("my-element') // marker"), tagDartElement.nameOffset);
//   }
//   static dartSuite() {
//     _ut.group('PolymerCompilationUnitBuilderTest', () {
//       _ut.test('test_badAnnotation_noArguments', () {
//         final __test = new PolymerCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_badAnnotation_noArguments);
//       });
//       _ut.test('test_badAnnotation_notConstructor', () {
//         final __test = new PolymerCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_badAnnotation_notConstructor);
//       });
//       _ut.test('test_customTag', () {
//         final __test = new PolymerCompilationUnitBuilderTest();
//         runJUnitTest(__test, __test.test_customTag);
//       });
//     });
//   }
// }
// /**
//  * Test for [PolymerHtmlUnitBuilder].
//  */
// class PolymerHtmlUnitBuilderTest extends PolymerTest {
//   void test_buildTagHtmlElement_bad_script_noSuchCustomTag() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('other-name')",
//         "class MyElement {",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     // HTML part is resolved
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     // ...but no Dart part found
//     JUnitTestCase.assertNull(tagHtmlElement.dartElement);
//   }
//   void test_buildTagHtmlElement_bad_script_notResolved() {
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='no-such-file.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagHtml();
//     // HTML part is resolved
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     JUnitTestCase.assertNull(tagHtmlElement.dartElement);
//   }
//   void test_buildTagHtmlElement_error_AttributeFieldNotPublished() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "const otherAnnotation = null;",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "  @otherAnnotation",
//         "  String attr;",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element' attributes='attr'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     assertNoErrorsTagDart();
//     assertErrors(tagHtmlSource, [PolymerCode.ATTRIBUTE_FIELD_NOT_PUBLISHED]);
//     // Dart and HTML parts are resolved
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     // attribute is still created
//     List<PolymerAttributeElement> attributes = tagHtmlElement.attributes;
//     EngineTestCase.assertLength(1, attributes);
//     {
//       PolymerAttributeElement attribute = attributes[0];
//       JUnitTestCase.assertEquals("attr", attribute.name);
//       JUnitTestCase.assertNotNull(attribute.field);
//     }
//   }
//   void test_buildTagHtmlElement_error_DuplicateAttributeDefinition() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "  @published String attr;",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element' attributes='attr attr'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     assertNoErrorsTagDart();
//     assertErrors(tagHtmlSource, [PolymerCode.DUPLICATE_ATTRIBUTE_DEFINITION]);
//     // Dart and HTML parts are resolved
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     // attribute is still created
//     List<PolymerAttributeElement> attributes = tagHtmlElement.attributes;
//     EngineTestCase.assertLength(1, attributes);
//     {
//       PolymerAttributeElement attribute = attributes[0];
//       JUnitTestCase.assertEquals("attr", attribute.name);
//       JUnitTestCase.assertNotNull(attribute.field);
//     }
//   }
//   void test_buildTagHtmlElement_error_EmptyAttributes() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element' attributes=''>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     assertNoErrorsTagDart();
//     assertErrors(tagHtmlSource, [PolymerCode.EMPTY_ATTRIBUTES]);
//     // Dart and HTML parts are resolved
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     // no attributes
//     List<PolymerAttributeElement> attributes = tagHtmlElement.attributes;
//     EngineTestCase.assertLength(0, attributes);
//   }
//   void test_buildTagHtmlElement_error_InvalidAttributeName() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "  @published String goodAttr;",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element' attributes='1badAttr goodAttr'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     assertNoErrorsTagDart();
//     assertErrors(tagHtmlSource, [PolymerCode.INVALID_ATTRIBUTE_NAME]);
//     // Dart and HTML parts are resolved
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     // one attribute is still created
//     List<PolymerAttributeElement> attributes = tagHtmlElement.attributes;
//     EngineTestCase.assertLength(1, attributes);
//     {
//       PolymerAttributeElement attribute = attributes[0];
//       JUnitTestCase.assertEquals("goodAttr", attribute.name);
//     }
//   }
//   void test_buildTagHtmlElement_error_InvalidTagName() {
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='invalid name'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "</polymer-element>",
//         ""]));
//     resolveTagHtml();
//     assertErrors(tagHtmlSource, [PolymerCode.INVALID_TAG_NAME]);
//     JUnitTestCase.assertNull(tagHtmlElement);
//   }
//   void test_buildTagHtmlElement_error_InvalidTagName_noValue() {
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "</polymer-element>",
//         ""]));
//     resolveTagHtml();
//     assertErrors(tagHtmlSource, [PolymerCode.INVALID_TAG_NAME]);
//     JUnitTestCase.assertNull(tagHtmlElement);
//   }
//   void test_buildTagHtmlElement_error_MissingTagName() {
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "</polymer-element>",
//         ""]));
//     resolveTagHtml();
//     assertErrors(tagHtmlSource, [PolymerCode.MISSING_TAG_NAME]);
//     JUnitTestCase.assertNull(tagHtmlElement);
//   }
//   void test_buildTagHtmlElement_error_UndefinedAttributeField() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element' attributes='attr'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     assertNoErrorsTagDart();
//     assertErrors(tagHtmlSource, [PolymerCode.UNDEFINED_ATTRIBUTE_FIELD]);
//     // Dart and HTML parts are resolved
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     // attribute is still created
//     List<PolymerAttributeElement> attributes = tagHtmlElement.attributes;
//     EngineTestCase.assertLength(1, attributes);
//     {
//       PolymerAttributeElement attribute = attributes[0];
//       JUnitTestCase.assertEquals("attr", attribute.name);
//       JUnitTestCase.assertNull(attribute.field);
//     }
//   }
//   void test_buildTagHtmlElement_OK() {
//     addTagDartSource(EngineTestCase.createSource([
//         "import 'polymer.dart';",
//         "",
//         "@CustomTag('my-element') // marker",
//         "class MyElement {",
//         "  @published String attrA;",
//         "  @published String attrB;",
//         "}",
//         ""]));
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element' attributes='attrA attrB'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "  <script type='application/dart' src='my-element.dart'></script>",
//         "</polymer-element>",
//         ""]));
//     resolveTagDart();
//     resolveTagHtml();
//     assertNoErrorsTag();
//     // Dart and HTML parts are resolved
//     JUnitTestCase.assertNotNull(tagDartElement);
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     JUnitTestCase.assertEquals("my-element", tagDartElement.name);
//     JUnitTestCase.assertEquals("my-element", tagHtmlElement.name);
//     JUnitTestCase.assertEquals(findTagHtmlOffset("my-element' attributes="), tagHtmlElement.nameOffset);
//     // Dart and HTML parts should point at each other
//     JUnitTestCase.assertSame(tagDartElement, tagHtmlElement.dartElement);
//     JUnitTestCase.assertSame(tagHtmlElement, tagDartElement.htmlElement);
//     // check attributes
//     List<PolymerAttributeElement> attributes = tagHtmlElement.attributes;
//     EngineTestCase.assertLength(2, attributes);
//     {
//       PolymerAttributeElement attribute = attributes[0];
//       JUnitTestCase.assertEquals("attrA", attribute.name);
//       JUnitTestCase.assertEquals(findTagHtmlOffset("attrA "), attribute.nameOffset);
//       FieldElement field = attribute.field;
//       JUnitTestCase.assertNotNull(field);
//       JUnitTestCase.assertEquals("attrA", field.name);
//     }
//     {
//       PolymerAttributeElement attribute = attributes[1];
//       JUnitTestCase.assertEquals("attrB", attribute.name);
//       JUnitTestCase.assertEquals(findTagHtmlOffset("attrB'>"), attribute.nameOffset);
//       FieldElement field = attribute.field;
//       JUnitTestCase.assertNotNull(field);
//       JUnitTestCase.assertEquals("attrB", field.name);
//     }
//   }
//   void test_buildTagHtmlElement_OK_noScript() {
//     addTagHtmlSource(EngineTestCase.createSource([
//         "<!DOCTYPE html>",
//         "",
//         "<polymer-element name='my-element'>",
//         "  <template>",
//         "    <div>Hello!</div>",
//         "  </template>",
//         "</polymer-element>",
//         ""]));
//     resolveTagHtml();
//     assertNoErrorsTagHtml();
//     // HTML part is resolved
//     JUnitTestCase.assertNotNull(tagHtmlElement);
//     JUnitTestCase.assertNull(tagHtmlElement.dartElement);
//   }
//   void test_isValidAttributeName() {
//     // empty
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidAttributeName(""));
//     // invalid first character
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidAttributeName(" "));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidAttributeName("-"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidAttributeName("0"));
//     // invalid character in the middle
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidAttributeName("a&"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidAttributeName("a-b"));
//     // OK
//     JUnitTestCase.assertTrue(PolymerHtmlUnitBuilder.isValidAttributeName("a"));
//     JUnitTestCase.assertTrue(PolymerHtmlUnitBuilder.isValidAttributeName("bb"));
//   }
//   void test_isValidTagName() {
//     // empty
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName(""));
//     // invalid first character
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName(" "));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("-"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("0"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("&"));
//     // invalid character in the middle
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("a&"));
//     // no '-'
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("a"));
//     // forbidden names
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("annotation-xml"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("color-profile"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("font-face"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("font-face-src"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("font-face-uri"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("font-face-format"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("font-face-name"));
//     JUnitTestCase.assertFalse(PolymerHtmlUnitBuilder.isValidTagName("missing-glyph"));
//     // OK
//     JUnitTestCase.assertTrue(PolymerHtmlUnitBuilder.isValidTagName("a-b"));
//     JUnitTestCase.assertTrue(PolymerHtmlUnitBuilder.isValidTagName("a-b-c"));
//     JUnitTestCase.assertTrue(PolymerHtmlUnitBuilder.isValidTagName("aaa-bbb"));
//   }
//   static dartSuite() {
//     _ut.group('PolymerHtmlUnitBuilderTest', () {
//       _ut.test('test_buildTagHtmlElement_OK', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_OK);
//       });
//       _ut.test('test_buildTagHtmlElement_OK_noScript', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_OK_noScript);
//       });
//       _ut.test('test_buildTagHtmlElement_bad_script_noSuchCustomTag', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_bad_script_noSuchCustomTag);
//       });
//       _ut.test('test_buildTagHtmlElement_bad_script_notResolved', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_bad_script_notResolved);
//       });
//       _ut.test('test_buildTagHtmlElement_error_AttributeFieldNotPublished', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_AttributeFieldNotPublished);
//       });
//       _ut.test('test_buildTagHtmlElement_error_DuplicateAttributeDefinition', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_DuplicateAttributeDefinition);
//       });
//       _ut.test('test_buildTagHtmlElement_error_EmptyAttributes', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_EmptyAttributes);
//       });
//       _ut.test('test_buildTagHtmlElement_error_InvalidAttributeName', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_InvalidAttributeName);
//       });
//       _ut.test('test_buildTagHtmlElement_error_InvalidTagName', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_InvalidTagName);
//       });
//       _ut.test('test_buildTagHtmlElement_error_InvalidTagName_noValue', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_InvalidTagName_noValue);
//       });
//       _ut.test('test_buildTagHtmlElement_error_MissingTagName', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_MissingTagName);
//       });
//       _ut.test('test_buildTagHtmlElement_error_UndefinedAttributeField', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_buildTagHtmlElement_error_UndefinedAttributeField);
//       });
//       _ut.test('test_isValidAttributeName', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_isValidAttributeName);
//       });
//       _ut.test('test_isValidTagName', () {
//         final __test = new PolymerHtmlUnitBuilderTest();
//         runJUnitTest(__test, __test.test_isValidTagName);
//       });
//     });
//   }
// }
// abstract class PolymerTest extends EngineTestCase {
//   /**
//    * @return the offset of given <code>search</code> string in <code>contents</code>. Fails test if
//    *         not found.
//    */
//   static int findOffset(String contents, String search) {
//     int offset = contents.indexOf(search);
//     assertThat(offset).describedAs(contents).isNotEqualTo(-1);
//     return offset;
//   }
//   AnalysisContextHelper contextHelper = new AnalysisContextHelper();
//   AnalysisContext context;
//   Source tagDartSource;
//   String tagDartContents;
//   Source tagHtmlSource;
//   String tagHtmlContents;
//   CompilationUnitElement tagDartUnitElement;
//   HtmlElement tagHtmlUnitElement;
//   PolymerTagDartElement tagDartElement;
//   PolymerTagHtmlElement tagHtmlElement;
//   void addTagDartSource(String contents) {
//     tagDartContents = contents;
//     tagDartSource = contextHelper.addSource("/my-element.dart", contents);
//   }
//   void addTagHtmlSource(String contents) {
//     tagHtmlContents = contents;
//     tagHtmlSource = contextHelper.addSource("/my-element.html", contents);
//   }
//   /**
//    * Assert that the number of errors reported against the given source matches the number of errors
//    * that are given and that they have the expected error codes. The order in which the errors were
//    * gathered is ignored.
//    *
//    * @param source the source against which the errors should have been reported
//    * @param expectedErrorCodes the error codes of the errors that should have been reported
//    * @throws AnalysisException if the reported errors could not be computed
//    * @throws AssertionFailedError if a different number of errors have been reported than were
//    *           expected
//    */
//   void assertErrors(Source source, List<ErrorCode> expectedErrorCodes) {
//     GatheringErrorListener errorListener = new GatheringErrorListener();
//     AnalysisErrorInfo errorsInfo = context.getErrors(source);
//     for (AnalysisError error in errorsInfo.errors) {
//       errorListener.onError(error);
//     }
//     errorListener.assertErrorsWithCodes(expectedErrorCodes);
//   }
//   void assertNoErrorsTag() {
//     assertNoErrorsTagDart();
//     assertNoErrorsTagHtml();
//   }
//   void assertNoErrorsTagDart() {
//     assertErrors(tagDartSource, []);
//   }
//   void assertNoErrorsTagHtml() {
//     assertErrors(tagHtmlSource, []);
//   }
//   /**
//    * @return the offset of given <code>search</code> string in [tagDartContents]. Fails test
//    *         if not found.
//    */
//   int findTagDartOffset(String search) => findOffset(tagDartContents, search);
//   /**
//    * @return the offset of given <code>search</code> string in [tagHtmlContents]. Fails test
//    *         if not found.
//    */
//   int findTagHtmlOffset(String search) => findOffset(tagHtmlContents, search);
//   void resolveTagDart() {
//     contextHelper.runTasks();
//     tagDartUnitElement = contextHelper.getDefiningUnitElement(tagDartSource);
//     // try to find a PolymerTagDartElement
//     for (ClassElement classElement in tagDartUnitElement.types) {
//       for (ToolkitObjectElement toolkitObject in classElement.toolkitObjects) {
//         if (toolkitObject is PolymerTagDartElement) {
//           tagDartElement = toolkitObject as PolymerTagDartElement;
//         }
//       }
//     }
//   }
//   void resolveTagHtml() {
//     contextHelper.runTasks();
//     tagHtmlUnitElement = context.getHtmlElement(tagHtmlSource);
//     // try to find a PolymerTagHtmlElement
//     List<PolymerTagHtmlElement> polymerTags = tagHtmlUnitElement.polymerTags;
//     if (polymerTags.length != 0) {
//       tagHtmlElement = polymerTags[0];
//     }
//   }
//   @override
//   void setUp() {
//     super.setUp();
//     _configureForPolymer(contextHelper);
//     context = contextHelper.context;
//   }
//   @override
//   void tearDown() {
//     contextHelper = null;
//     context = null;
//     tagDartSource = null;
//     tagDartContents = null;
//     tagHtmlSource = null;
//     tagHtmlContents = null;
//     tagDartUnitElement = null;
//     tagHtmlUnitElement = null;
//     tagDartElement = null;
//     tagHtmlElement = null;
//     super.tearDown();
//   }
//   void _configureForPolymer(AnalysisContextHelper contextHelper) {
//     contextHelper.addSource("/polymer.dart", EngineTestCase.createSource([
//         "library polymer;",
//         "",
//         "class CustomTag {",
//         "  final String tagName;",
//         "  const CustomTag(this.tagName);",
//         "}",
//         "",
//         "class ObservableProperty {",
//         "  const ObservableProperty();",
//         "}",
//         "const ObservableProperty observable = const ObservableProperty();",
//         "",
//         "class PublishedProperty extends ObservableProperty {",
//         "  const PublishedProperty();",
//         "}",
//         "const published = const PublishedProperty();",
//         ""]));
//   }
// }
// class ReferenceFinderTest extends EngineTestCase {
//   DirectedGraph<AstNode> _referenceGraph;
//   HashMap<VariableElement, VariableDeclaration> _variableDeclarationMap;
//   HashMap<ConstructorElement, ConstructorDeclaration> _constructorDeclarationMap;
//   VariableDeclaration _head;
//   AstNode _tail;
//   void test_visitInstanceCreationExpression_const() {
//     _visitNode(_makeTailConstructor("A", true, true, true));
//     _assertOneArc(_tail);
//   }
//   void test_visitInstanceCreationExpression_nonConstDeclaration() {
//     // In the source:
//     //   const x = const A();
//     // x depends on "const A()" even if the A constructor isn't declared as const.
//     _visitNode(_makeTailConstructor("A", false, true, true));
//     _assertOneArc(_tail);
//   }
//   void test_visitInstanceCreationExpression_nonConstUsage() {
//     _visitNode(_makeTailConstructor("A", true, false, true));
//     _assertNoArcs();
//   }
//   void test_visitInstanceCreationExpression_notInMap() {
//     // In the source:
//     //   const x = const A();
//     // x depends on "const A()" even if the AST for the A constructor isn't available.
//     _visitNode(_makeTailConstructor("A", true, true, false));
//     _assertOneArc(_tail);
//   }
//   void test_visitSimpleIdentifier_const() {
//     _visitNode(_makeTailVariable("v2", true, true));
//     _assertOneArc(_tail);
//   }
//   void test_visitSimpleIdentifier_nonConst() {
//     _visitNode(_makeTailVariable("v2", false, true));
//     _assertNoArcs();
//   }
//   void test_visitSimpleIdentifier_notInMap() {
//     _visitNode(_makeTailVariable("v2", true, false));
//     _assertNoArcs();
//   }
//   void test_visitSuperConstructorInvocation_const() {
//     _visitNode(_makeTailSuperConstructorInvocation("A", true, true));
//     _assertOneArc(_tail);
//   }
//   void test_visitSuperConstructorInvocation_nonConst() {
//     _visitNode(_makeTailSuperConstructorInvocation("A", false, true));
//     _assertNoArcs();
//   }
//   void test_visitSuperConstructorInvocation_notInMap() {
//     _visitNode(_makeTailSuperConstructorInvocation("A", true, false));
//     _assertNoArcs();
//   }
//   void test_visitSuperConstructorInvocation_unresolved() {
//     SuperConstructorInvocation superConstructorInvocation = AstFactory.superConstructorInvocation([]);
//     _tail = superConstructorInvocation;
//     _visitNode(superConstructorInvocation);
//     _assertNoArcs();
//   }
//   @override
//   void setUp() {
//     _referenceGraph = new DirectedGraph<AstNode>();
//     _variableDeclarationMap = new HashMap<VariableElement, VariableDeclaration>();
//     _constructorDeclarationMap = new HashMap<ConstructorElement, ConstructorDeclaration>();
//     _head = AstFactory.variableDeclaration("v1");
//   }
//   void _assertNoArcs() {
//     Set<AstNode> tails = _referenceGraph.getTails(_head);
//     EngineTestCase.assertSizeOfSet(0, tails);
//   }
//   void _assertOneArc(AstNode tail) {
//     Set<AstNode> tails = _referenceGraph.getTails(_head);
//     EngineTestCase.assertSizeOfSet(1, tails);
//     JUnitTestCase.assertSame(tail, new JavaIterator(tails).next());
//   }
//   ReferenceFinder _createReferenceFinder(AstNode source) => new ReferenceFinder(source, _referenceGraph, _variableDeclarationMap, _constructorDeclarationMap);
//   InstanceCreationExpression _makeTailConstructor(String name, bool isConstDeclaration, bool isConstUsage, bool inMap) {
//     List<ConstructorInitializer> initializers = new List<ConstructorInitializer>();
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration(AstFactory.identifier3(name), null, AstFactory.formalParameterList([]), initializers);
//     if (isConstDeclaration) {
//       constructorDeclaration.constKeyword = new KeywordToken(Keyword.CONST, 0);
//     }
//     ClassElementImpl classElement = ElementFactory.classElement2(name, []);
//     SimpleIdentifier identifier = AstFactory.identifier3(name);
//     TypeName type = AstFactory.typeName3(identifier, []);
//     InstanceCreationExpression instanceCreationExpression = AstFactory.instanceCreationExpression2(isConstUsage ? Keyword.CONST : Keyword.NEW, type, []);
//     _tail = instanceCreationExpression;
//     ConstructorElementImpl constructorElement = ElementFactory.constructorElement(classElement, name, isConstDeclaration, []);
//     if (inMap) {
//       _constructorDeclarationMap[constructorElement] = constructorDeclaration;
//     }
//     instanceCreationExpression.staticElement = constructorElement;
//     return instanceCreationExpression;
//   }
//   SuperConstructorInvocation _makeTailSuperConstructorInvocation(String name, bool isConst, bool inMap) {
//     List<ConstructorInitializer> initializers = new List<ConstructorInitializer>();
//     ConstructorDeclaration constructorDeclaration = AstFactory.constructorDeclaration(AstFactory.identifier3(name), null, AstFactory.formalParameterList([]), initializers);
//     _tail = constructorDeclaration;
//     if (isConst) {
//       constructorDeclaration.constKeyword = new KeywordToken(Keyword.CONST, 0);
//     }
//     ClassElementImpl classElement = ElementFactory.classElement2(name, []);
//     SuperConstructorInvocation superConstructorInvocation = AstFactory.superConstructorInvocation([]);
//     ConstructorElementImpl constructorElement = ElementFactory.constructorElement(classElement, name, isConst, []);
//     if (inMap) {
//       _constructorDeclarationMap[constructorElement] = constructorDeclaration;
//     }
//     superConstructorInvocation.staticElement = constructorElement;
//     return superConstructorInvocation;
//   }
//   SimpleIdentifier _makeTailVariable(String name, bool isConst, bool inMap) {
//     VariableDeclaration variableDeclaration = AstFactory.variableDeclaration(name);
//     _tail = variableDeclaration;
//     VariableElementImpl variableElement = ElementFactory.localVariableElement2(name);
//     variableElement.const3 = isConst;
//     AstFactory.variableDeclarationList2(isConst ? Keyword.CONST : Keyword.VAR, [variableDeclaration]);
//     if (inMap) {
//       _variableDeclarationMap[variableElement] = variableDeclaration;
//     }
//     SimpleIdentifier identifier = AstFactory.identifier3(name);
//     identifier.staticElement = variableElement;
//     return identifier;
//   }
//   void _visitNode(AstNode node) {
//     node.accept(_createReferenceFinder(_head));
//   }
//   static dartSuite() {
//     _ut.group('ReferenceFinderTest', () {
//       _ut.test('test_visitInstanceCreationExpression_const', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitInstanceCreationExpression_const);
//       });
//       _ut.test('test_visitInstanceCreationExpression_nonConstDeclaration', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitInstanceCreationExpression_nonConstDeclaration);
//       });
//       _ut.test('test_visitInstanceCreationExpression_nonConstUsage', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitInstanceCreationExpression_nonConstUsage);
//       });
//       _ut.test('test_visitInstanceCreationExpression_notInMap', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitInstanceCreationExpression_notInMap);
//       });
//       _ut.test('test_visitSimpleIdentifier_const', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSimpleIdentifier_const);
//       });
//       _ut.test('test_visitSimpleIdentifier_nonConst', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSimpleIdentifier_nonConst);
//       });
//       _ut.test('test_visitSimpleIdentifier_notInMap', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSimpleIdentifier_notInMap);
//       });
//       _ut.test('test_visitSuperConstructorInvocation_const', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSuperConstructorInvocation_const);
//       });
//       _ut.test('test_visitSuperConstructorInvocation_nonConst', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSuperConstructorInvocation_nonConst);
//       });
//       _ut.test('test_visitSuperConstructorInvocation_notInMap', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSuperConstructorInvocation_notInMap);
//       });
//       _ut.test('test_visitSuperConstructorInvocation_unresolved', () {
//         final __test = new ReferenceFinderTest();
//         runJUnitTest(__test, __test.test_visitSuperConstructorInvocation_unresolved);
//       });
//     });
//   }
// }
// class RelativeFileResolverTest extends JUnitTestCase {
//   void test_creation() {
//     JavaFile root = FileUtilities2.createFile("/does/not/exist");
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/relative");
//     JUnitTestCase.assertNotNull(new RelativeFileUriResolver(root, [directory]));
//   }
//   void test_resolve_file() {
//     JavaFile root = FileUtilities2.createTempDir("/does/not/exist");
//     JavaFile directory = FileUtilities2.createTempDir("/does/not/exist/relative");
//     JavaFile testFile = new JavaFile.relative(directory, "exist.dart");
//     testFile.createNewFile();
//     Uri uri = new Uri("file", null, "${root.toURI().path}${JavaFile.separator}exist.dart", null, null);
//     UriResolver resolver = new RelativeFileUriResolver(root, [directory]);
//     Source result = resolver.resolveAbsolute(uri);
//     JUnitTestCase.assertNotNull(result);
//     JUnitTestCase.assertEquals(testFile.getAbsolutePath(), result.fullName);
//   }
//   void test_resolve_nonFile() {
//     JavaFile root = FileUtilities2.createFile("/does/not/exist");
//     JavaFile directory = FileUtilities2.createFile("/does/not/exist/relative");
//     UriResolver resolver = new RelativeFileUriResolver(root, [directory]);
//     Source result = resolver.resolveAbsolute(parseUriWithException("dart:core"));
//     JUnitTestCase.assertNull(result);
//   }
//   @override
//   void tearDown() {
//     FileUtilities2.deleteTempDir();
//   }
//   static dartSuite() {
//     _ut.group('RelativeFileResolverTest', () {
//       _ut.test('test_creation', () {
//         final __test = new RelativeFileResolverTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_resolve_file', () {
//         final __test = new RelativeFileResolverTest();
//         runJUnitTest(__test, __test.test_resolve_file);
//       });
//       _ut.test('test_resolve_nonFile', () {
//         final __test = new RelativeFileResolverTest();
//         runJUnitTest(__test, __test.test_resolve_nonFile);
//       });
//     });
//   }
// }
// class SDKLibrariesReaderTest extends EngineTestCase {
//   void test_readFrom_dart2js() {
//     LibraryMap libraryMap = new SdkLibrariesReader(true).readFromFile(FileUtilities2.createFile("/libs.dart"), EngineTestCase.createSource([
//         "final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {",
//         "  'first' : const LibraryInfo(",
//         "    'first/first.dart',",
//         "    category: 'First',",
//         "    documented: true,",
//         "    platforms: VM_PLATFORM,",
//         "    dart2jsPath: 'first/first_dart2js.dart'),",
//         "};"]));
//     JUnitTestCase.assertNotNull(libraryMap);
//     JUnitTestCase.assertEquals(1, libraryMap.size());
//     SdkLibrary first = libraryMap.getLibrary("dart:first");
//     JUnitTestCase.assertNotNull(first);
//     JUnitTestCase.assertEquals("First", first.category);
//     JUnitTestCase.assertEquals("first/first_dart2js.dart", first.path);
//     JUnitTestCase.assertEquals("dart:first", first.shortName);
//     JUnitTestCase.assertEquals(false, first.isDart2JsLibrary);
//     JUnitTestCase.assertEquals(true, first.isDocumented);
//     JUnitTestCase.assertEquals(false, first.isImplementation);
//     JUnitTestCase.assertEquals(true, first.isVmLibrary);
//   }
//   void test_readFrom_empty() {
//     LibraryMap libraryMap = new SdkLibrariesReader(false).readFromFile(FileUtilities2.createFile("/libs.dart"), "");
//     JUnitTestCase.assertNotNull(libraryMap);
//     JUnitTestCase.assertEquals(0, libraryMap.size());
//   }
//   void test_readFrom_normal() {
//     LibraryMap libraryMap = new SdkLibrariesReader(false).readFromFile(FileUtilities2.createFile("/libs.dart"), EngineTestCase.createSource([
//         "final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {",
//         "  'first' : const LibraryInfo(",
//         "    'first/first.dart',",
//         "    category: 'First',",
//         "    documented: true,",
//         "    platforms: VM_PLATFORM),",
//         "",
//         "  'second' : const LibraryInfo(",
//         "    'second/second.dart',",
//         "    category: 'Second',",
//         "    documented: false,",
//         "    implementation: true,",
//         "    platforms: 0),",
//         "};"]));
//     JUnitTestCase.assertNotNull(libraryMap);
//     JUnitTestCase.assertEquals(2, libraryMap.size());
//     SdkLibrary first = libraryMap.getLibrary("dart:first");
//     JUnitTestCase.assertNotNull(first);
//     JUnitTestCase.assertEquals("First", first.category);
//     JUnitTestCase.assertEquals("first/first.dart", first.path);
//     JUnitTestCase.assertEquals("dart:first", first.shortName);
//     JUnitTestCase.assertEquals(false, first.isDart2JsLibrary);
//     JUnitTestCase.assertEquals(true, first.isDocumented);
//     JUnitTestCase.assertEquals(false, first.isImplementation);
//     JUnitTestCase.assertEquals(true, first.isVmLibrary);
//     SdkLibrary second = libraryMap.getLibrary("dart:second");
//     JUnitTestCase.assertNotNull(second);
//     JUnitTestCase.assertEquals("Second", second.category);
//     JUnitTestCase.assertEquals("second/second.dart", second.path);
//     JUnitTestCase.assertEquals("dart:second", second.shortName);
//     JUnitTestCase.assertEquals(false, second.isDart2JsLibrary);
//     JUnitTestCase.assertEquals(false, second.isDocumented);
//     JUnitTestCase.assertEquals(true, second.isImplementation);
//     JUnitTestCase.assertEquals(false, second.isVmLibrary);
//   }
//   static dartSuite() {
//     _ut.group('SDKLibrariesReaderTest', () {
//       _ut.test('test_readFrom_dart2js', () {
//         final __test = new SDKLibrariesReaderTest();
//         runJUnitTest(__test, __test.test_readFrom_dart2js);
//       });
//       _ut.test('test_readFrom_empty', () {
//         final __test = new SDKLibrariesReaderTest();
//         runJUnitTest(__test, __test.test_readFrom_empty);
//       });
//       _ut.test('test_readFrom_normal', () {
//         final __test = new SDKLibrariesReaderTest();
//         runJUnitTest(__test, __test.test_readFrom_normal);
//       });
//     });
//   }
// }
// class SourceFactoryTest extends JUnitTestCase {
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new SourceFactory([]));
//   }
//   void test_fromEncoding_invalidUri() {
//     SourceFactory factory = new SourceFactory([]);
//     try {
//       factory.fromEncoding("<:&%>");
//       JUnitTestCase.fail("Expected IllegalArgumentException");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_fromEncoding_noResolver() {
//     SourceFactory factory = new SourceFactory([]);
//     try {
//       factory.fromEncoding("foo:/does/not/exist.dart");
//       JUnitTestCase.fail("Expected IllegalArgumentException");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_fromEncoding_valid() {
//     String encoding = "file:/does/not/exist.dart";
//     SourceFactory factory = new SourceFactory([new UriResolver_SourceFactoryTest_test_fromEncoding_valid(encoding)]);
//     JUnitTestCase.assertNotNull(factory.fromEncoding(encoding));
//   }
//   void test_resolveUri_absolute() {
//     List<bool> invoked = [false];
//     SourceFactory factory = new SourceFactory([new UriResolver_SourceFactoryTest_test_resolveUri_absolute(invoked)]);
//     factory.resolveUri(null, "dart:core");
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_resolveUri_nonAbsolute_absolute() {
//     SourceFactory factory = new SourceFactory([new UriResolver_SourceFactoryTest_test_resolveUri_nonAbsolute_absolute()]);
//     String absolutePath = "/does/not/matter.dart";
//     Source containingSource = new FileBasedSource.con1(FileUtilities2.createFile("/does/not/exist.dart"));
//     Source result = factory.resolveUri(containingSource, absolutePath);
//     JUnitTestCase.assertEquals(FileUtilities2.createFile(absolutePath).getAbsolutePath(), result.fullName);
//   }
//   void test_resolveUri_nonAbsolute_relative() {
//     SourceFactory factory = new SourceFactory([new UriResolver_SourceFactoryTest_test_resolveUri_nonAbsolute_relative()]);
//     Source containingSource = new FileBasedSource.con1(FileUtilities2.createFile("/does/not/have.dart"));
//     Source result = factory.resolveUri(containingSource, "exist.dart");
//     JUnitTestCase.assertEquals(FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath(), result.fullName);
//   }
//   void test_restoreUri() {
//     JavaFile file1 = FileUtilities2.createFile("/some/file1.dart");
//     JavaFile file2 = FileUtilities2.createFile("/some/file2.dart");
//     Source source1 = new FileBasedSource.con1(file1);
//     Source source2 = new FileBasedSource.con1(file2);
//     Uri expected1 = parseUriWithException("http://www.google.com");
//     SourceFactory factory = new SourceFactory([new UriResolver_SourceFactoryTest_test_restoreUri(source1, expected1)]);
//     JUnitTestCase.assertSame(expected1, factory.restoreUri(source1));
//     JUnitTestCase.assertSame(null, factory.restoreUri(source2));
//   }
//   static dartSuite() {
//     _ut.group('SourceFactoryTest', () {
//       _ut.test('test_creation', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_fromEncoding_invalidUri', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_fromEncoding_invalidUri);
//       });
//       _ut.test('test_fromEncoding_noResolver', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_fromEncoding_noResolver);
//       });
//       _ut.test('test_fromEncoding_valid', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_fromEncoding_valid);
//       });
//       _ut.test('test_resolveUri_absolute', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_resolveUri_absolute);
//       });
//       _ut.test('test_resolveUri_nonAbsolute_absolute', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_resolveUri_nonAbsolute_absolute);
//       });
//       _ut.test('test_resolveUri_nonAbsolute_relative', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_resolveUri_nonAbsolute_relative);
//       });
//       _ut.test('test_restoreUri', () {
//         final __test = new SourceFactoryTest();
//         runJUnitTest(__test, __test.test_restoreUri);
//       });
//     });
//   }
// }
// class StringScannerTest extends AbstractScannerTest {
//   @override
//   AbstractScanner newScanner(String input) => new StringScanner(null, input);
//   static dartSuite() {
//     _ut.group('StringScannerTest', () {
//       _ut.test('test_tokenize_attribute', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_attribute);
//       });
//       _ut.test('test_tokenize_comment', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_comment);
//       });
//       _ut.test('test_tokenize_comment_incomplete', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_comment_incomplete);
//       });
//       _ut.test('test_tokenize_comment_with_gt', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_comment_with_gt);
//       });
//       _ut.test('test_tokenize_declaration', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_declaration);
//       });
//       _ut.test('test_tokenize_declaration_malformed', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_declaration_malformed);
//       });
//       _ut.test('test_tokenize_directive_incomplete', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_directive_incomplete);
//       });
//       _ut.test('test_tokenize_directive_xml', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_directive_xml);
//       });
//       _ut.test('test_tokenize_directives_incomplete_with_newline', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_directives_incomplete_with_newline);
//       });
//       _ut.test('test_tokenize_empty', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_empty);
//       });
//       _ut.test('test_tokenize_lt', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_lt);
//       });
//       _ut.test('test_tokenize_script_embedded_tags', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_embedded_tags);
//       });
//       _ut.test('test_tokenize_script_embedded_tags2', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_embedded_tags2);
//       });
//       _ut.test('test_tokenize_script_embedded_tags3', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_embedded_tags3);
//       });
//       _ut.test('test_tokenize_script_partial', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_partial);
//       });
//       _ut.test('test_tokenize_script_partial2', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_partial2);
//       });
//       _ut.test('test_tokenize_script_partial3', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_partial3);
//       });
//       _ut.test('test_tokenize_script_ref', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_ref);
//       });
//       _ut.test('test_tokenize_script_with_newline', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_script_with_newline);
//       });
//       _ut.test('test_tokenize_spaces_and_newlines', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_spaces_and_newlines);
//       });
//       _ut.test('test_tokenize_string', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_string);
//       });
//       _ut.test('test_tokenize_string_partial', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_string_partial);
//       });
//       _ut.test('test_tokenize_string_single_quote', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_string_single_quote);
//       });
//       _ut.test('test_tokenize_string_single_quote_partial', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_string_single_quote_partial);
//       });
//       _ut.test('test_tokenize_tag_begin_end', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_tag_begin_end);
//       });
//       _ut.test('test_tokenize_tag_begin_only', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_tag_begin_only);
//       });
//       _ut.test('test_tokenize_tag_incomplete_with_special_characters', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_tag_incomplete_with_special_characters);
//       });
//       _ut.test('test_tokenize_tag_self_contained', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_tag_self_contained);
//       });
//       _ut.test('test_tokenize_tags_wellformed', () {
//         final __test = new StringScannerTest();
//         runJUnitTest(__test, __test.test_tokenize_tags_wellformed);
//       });
//     });
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ClassDeclarationTest);
//     suite.addTestSuite(ClassTypeAliasTest);
//     suite.addTestSuite(IndexExpressionTest);
//     suite.addTestSuite(NodeListTest);
//     suite.addTestSuite(SimpleIdentifierTest);
//     suite.addTestSuite(SimpleStringLiteralTest);
//     suite.addTestSuite(VariableDeclarationTest);
//     suite.addTest(com.google.dart.engine.ast.visitor.TestAll.suite());
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ConstantEvaluatorTest);
//     suite.addTestSuite(ElementLocatorTest);
//     suite.addTestSuite(NodeLocatorTest);
//     suite.addTestSuite(ToSourceVisitorTest);
//     suite.addTestSuite(BreadthFirstVisitorTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ConstantEvaluatorTest);
//     suite.addTestSuite(DeclaredVariablesTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AnalysisDeltaTest);
//     suite.addTestSuite(ChangeSetTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ElementKindTest);
//     suite.addTest(com.google.dart.engine.element.angular.TestAll.suite());
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AngularPropertyKindTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ErrorSeverityTest);
//     suite.addTestSuite(TodoCodeTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTest(com.google.dart.engine.html.ast.TestAll.suite());
//     suite.addTest(com.google.dart.engine.html.parser.TestAll.suite());
//     suite.addTest(com.google.dart.engine.html.scanner.TestAll.suite());
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTest(com.google.dart.engine.html.ast.visitor.TestAll.suite());
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ToSourceVisitorTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(HtmlParserTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(StringScannerTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTest(com.google.dart.engine.internal.builder.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.cache.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.constant.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.context.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.element.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.error.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.hint.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.html.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.index.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.object.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.resolver.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.scope.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.sdk.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.search.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.task.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.type.TestAll.suite());
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AngularCompilationUnitBuilderTest);
//     suite.addTestSuite(ElementBuilderTest);
//     suite.addTestSuite(EnumMemberBuilderTest);
//     suite.addTestSuite(HtmlUnitBuilderTest);
//     suite.addTestSuite(HtmlWarningCodeTest);
//     suite.addTestSuite(PolymerCompilationUnitBuilderTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AnalysisCacheTest);
//     suite.addTestSuite(DartEntryImplTest);
//     suite.addTestSuite(HtmlEntryImplTest);
//     suite.addTestSuite(PartitionManagerTest);
//     suite.addTestSuite(SdkCachePartitionTest);
//     suite.addTestSuite(UniversalCachePartitionTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ConstantFinderTest);
//     suite.addTestSuite(ConstantValueComputerTest);
//     suite.addTestSuite(ConstantVisitorTest);
//     suite.addTestSuite(ReferenceFinderTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AnalysisContextImplTest);
//     suite.addTestSuite(AnalysisOptionsImplTest);
//     suite.addTestSuite(IncrementalAnalysisCacheTest);
//     suite.addTestSuite(InstrumentedAnalysisContextImplTest);
//     suite.addTestSuite(WorkManagerTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ClassElementImplTest);
//     suite.addTestSuite(CompilationUnitElementImplTest);
//     suite.addTestSuite(ElementLocationImplTest);
//     suite.addTestSuite(ElementImplTest);
//     suite.addTestSuite(HtmlElementImplTest);
//     suite.addTestSuite(LibraryElementImplTest);
//     suite.addTestSuite(MultiplyDefinedElementImplTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ErrorReporterTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ExitDetectorTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTest(com.google.dart.engine.internal.html.angular.TestAll.suite());
//     suite.addTest(com.google.dart.engine.internal.html.polymer.TestAll.suite());
//     suite.addTestSuite(HtmlTagInfoBuilderTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AngularDartIndexContributorTest);
//     suite.addTestSuite(AngularHtmlIndexContributorTest);
//     suite.addTestSuite(AngularHtmlUnitResolverTest);
//     suite.addTestSuite(AngularHtmlUnitUtilsTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(PolymerHtmlUnitBuilderTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(DartObjectImplTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(DeclarationMatcherTest);
//     suite.addTestSuite(ElementResolverTest);
//     suite.addTestSuite(IncrementalResolverTest);
//     suite.addTestSuite(InheritanceManagerTest);
//     suite.addTestSuite(LibraryElementBuilderTest);
//     suite.addTestSuite(LibraryTest);
//     suite.addTestSuite(StaticTypeAnalyzerTest);
//     suite.addTestSuite(SubtypeManagerTest);
//     suite.addTestSuite(TypeOverrideManagerTest);
//     suite.addTestSuite(TypeProviderImplTest);
//     suite.addTestSuite(TypeResolverVisitorTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(EnclosedScopeTest);
//     suite.addTestSuite(LibraryImportScopeTest);
//     suite.addTestSuite(LibraryScopeTest);
//     suite.addTestSuite(ScopeBuilderTest);
//     suite.addTestSuite(ScopeTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(SDKLibrariesReaderTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(AnalysisTaskTest);
//     suite.addTestSuite(GenerateDartErrorsTaskTest);
//     suite.addTestSuite(GenerateDartHintsTaskTest);
//     suite.addTestSuite(GetContentTaskTest);
//     suite.addTestSuite(IncrementalAnalysisTaskTest);
//     suite.addTestSuite(ParseDartTaskTest);
//     suite.addTestSuite(ParseHtmlTaskTest);
//     suite.addTestSuite(ResolveDartLibraryTaskTest);
//     suite.addTestSuite(ResolveDartUnitTaskTest);
//     suite.addTestSuite(ResolveHtmlTaskTest);
//     suite.addTestSuite(ScanDartTaskTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(FunctionTypeImplTest);
//     suite.addTestSuite(InterfaceTypeImplTest);
//     suite.addTestSuite(TypeParameterTypeImplTest);
//     suite.addTestSuite(UnionTypeImplTest);
//     suite.addTestSuite(VoidTypeImplTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ComplexParserTest);
//     suite.addTestSuite(ErrorParserTest);
//     suite.addTestSuite(IncrementalParserTest);
//     suite.addTestSuite(NonErrorParserTest);
//     suite.addTestSuite(RecoveryParserTest);
//     suite.addTestSuite(ResolutionCopierTest);
//     suite.addTestSuite(SimpleParserTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(CompileTimeErrorCodeTest);
//     suite.addTestSuite(ErrorResolverTest);
//     suite.addTestSuite(HintCodeTest);
//     suite.addTestSuite(MemberMapTest);
//     suite.addTestSuite(NonErrorResolverTest);
//     suite.addTestSuite(NonHintCodeTest);
//     //suite.addTestSuite(PubSuggestionCodeTest.class);
//     suite.addTestSuite(SimpleResolverTest);
//     suite.addTestSuite(StaticTypeWarningCodeTest);
//     suite.addTestSuite(StaticWarningCodeTest);
//     suite.addTestSuite(StrictModeTest);
//     suite.addTestSuite(TypePropagationTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(CharSequenceReaderTest);
//     suite.addTestSuite(IncrementalScannerTest);
//     suite.addTestSuite(KeywordStateTest);
//     suite.addTestSuite(ScannerTest);
//     suite.addTestSuite(TokenTypeTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(DirectoryBasedDartSdkTest);
//     return suite;
//   }
// }
// class TestAll {
//   static Test suite() {
//     TestSuite suite = new ExtendedTestSuite("Tests in ${TestAll.getPackage().getName()}");
//     suite.addTestSuite(ContentCacheTest);
//     suite.addTestSuite(DartUriResolverTest);
//     suite.addTestSuite(ExplicitPackageUriResolverTest);
//     suite.addTestSuite(FileUriResolverTest);
//     suite.addTestSuite(NonExistingSourceTest);
//     suite.addTestSuite(PackageUriResolverTest);
//     suite.addTestSuite(RelativeFileResolverTest);
//     suite.addTestSuite(DirectoryBasedSourceContainerTest);
//     suite.addTestSuite(SourceFactoryTest);
//     suite.addTestSuite(FileBasedSourceTest);
//     suite.addTestSuite(UriKindTest);
//     return suite;
//   }
// }
// /**
//  * Instances of the class `TestSource` implement a source object that can be used for testing
//  * purposes.
//  */
// class TestSource extends FileBasedSource {
//   /**
//    * The contents of the file represented by this source.
//    */
//   String _contents;
//   /**
//    * The modification stamp associated with this source.
//    */
//   int _modificationStamp = 0;
//   /**
//    * A flag indicating whether an exception should be generated when an attempt is made to access
//    * the contents of this source.
//    */
//   bool _generateExceptionOnRead = false;
//   /**
//    * The number of times that the contents of this source have been requested.
//    */
//   int _readCount = 0;
//   /**
//    * Initialize a newly created source object.
//    */
//   TestSource() : this.con1(FileUtilities2.createFile("/test.dart"), "");
//   /**
//    * Initialize a newly created source object. The source object is assumed to not be in a system
//    * library.
//    *
//    * @param file the file represented by this source
//    * @param contents the contents of the file represented by this source
//    */
//   TestSource.con1(JavaFile file, String contents) : super.con1(file) {
//     this._contents = contents;
//     _modificationStamp = JavaSystem.currentTimeMillis();
//   }
//   /**
//    * Initialize a newly created source object with the specified contents.
//    *
//    * @param contents the contents of the file represented by this source
//    */
//   TestSource.con2(String contents) : this.con1(FileUtilities2.createFile("/test.dart"), contents);
//   @override
//   int get modificationStamp => _modificationStamp;
//   /**
//    * The number of times that the contents of this source have been requested.
//    */
//   int get readCount => _readCount;
//   /**
//    * Set the contents of this source to the given contents. This has the side-effect of updating the
//    * modification stamp of the source.
//    *
//    * @param contents the new contents of this source
//    */
//   void set contents(String contents) {
//     this._contents = contents;
//     _modificationStamp = JavaSystem.currentTimeMillis();
//   }
//   /**
//    * A flag indicating whether an exception should be generated when an attempt is made to access
//    * the contents of this source.
//    */
//   void set generateExceptionOnRead(bool generate) {
//     _generateExceptionOnRead = generate;
//   }
//   @override
//   TimestampedData<String> get contentsFromFile {
//     _readCount++;
//     if (_generateExceptionOnRead) {
//       throw new JavaIOException("I/O Exception while getting the contents of ${fullName}");
//     }
//     return new TimestampedData<String>(_modificationStamp, _contents);
//   }
//   @override
//   void getContentsFromFileToReceiver(Source_ContentReceiver receiver) {
//     _readCount++;
//     if (_generateExceptionOnRead) {
//       throw new JavaIOException("I/O Exception while getting the contents of ${fullName}");
//     }
//     receiver.accept(_contents, _modificationStamp);
//   }
// }
// /**
//  * Instances of the class `ToSourceVisitorTest`
//  */
// class ToSourceVisitorTest extends EngineTestCase {
//   void fail_visitHtmlScriptTagNode_attributes_content() {
//     _assertSource("<script type='application/dart'>f() {}</script>", HtmlFactory.scriptTagWithContent("f() {}", [HtmlFactory.attribute("type", "'application/dart'")]));
//   }
//   void fail_visitHtmlScriptTagNode_noAttributes_content() {
//     _assertSource("<script>f() {}</script>", HtmlFactory.scriptTagWithContent("f() {}", []));
//   }
//   void test_visitHtmlScriptTagNode_attributes_noContent() {
//     _assertSource("<script type='application/dart'/>", HtmlFactory.scriptTag([HtmlFactory.attribute("type", "'application/dart'")]));
//   }
//   void test_visitHtmlScriptTagNode_noAttributes_noContent() {
//     _assertSource("<script/>", HtmlFactory.scriptTag([]));
//   }
//   void test_visitHtmlUnit_empty() {
//     _assertSource("", new HtmlUnit(null, new List<XmlTagNode>(), null));
//   }
//   void test_visitHtmlUnit_nonEmpty() {
//     _assertSource("<html/>", new HtmlUnit(null, HtmlFactory.list([HtmlFactory.tagNode("html", [])]), null));
//   }
//   void test_visitXmlAttributeNode() {
//     _assertSource("x=y", HtmlFactory.attribute("x", "y"));
//   }
//   /**
//    * Assert that a `ToSourceVisitor` will produce the expected source when visiting the given
//    * node.
//    *
//    * @param expectedSource the source string that the visitor is expected to produce
//    * @param node the AST node being visited to produce the actual source
//    */
//   void _assertSource(String expectedSource, XmlNode node) {
//     PrintStringWriter writer = new PrintStringWriter();
//     node.accept(new ToSourceVisitor(writer));
//     JUnitTestCase.assertEquals(expectedSource, writer.toString());
//   }
//   static dartSuite() {
//     _ut.group('ToSourceVisitorTest', () {
//       _ut.test('test_visitHtmlScriptTagNode_attributes_noContent', () {
//         final __test = new ToSourceVisitorTest();
//         runJUnitTest(__test, __test.test_visitHtmlScriptTagNode_attributes_noContent);
//       });
//       _ut.test('test_visitHtmlScriptTagNode_noAttributes_noContent', () {
//         final __test = new ToSourceVisitorTest();
//         runJUnitTest(__test, __test.test_visitHtmlScriptTagNode_noAttributes_noContent);
//       });
//       _ut.test('test_visitHtmlUnit_empty', () {
//         final __test = new ToSourceVisitorTest();
//         runJUnitTest(__test, __test.test_visitHtmlUnit_empty);
//       });
//       _ut.test('test_visitHtmlUnit_nonEmpty', () {
//         final __test = new ToSourceVisitorTest();
//         runJUnitTest(__test, __test.test_visitHtmlUnit_nonEmpty);
//       });
//       _ut.test('test_visitXmlAttributeNode', () {
//         final __test = new ToSourceVisitorTest();
//         runJUnitTest(__test, __test.test_visitXmlAttributeNode);
//       });
//     });
//   }
// }
// class TodoCodeTest extends EngineTestCase {
//   void test_locateLineCommentTodo() {
//     _locate("//TODO", 2, 4);
//     _locate("//TODO:", 2, 5);
//     _locate("// TODO(sdsdf): ", 3, 13);
//     _locate("// TODO (sdsdf): ", 3, 14);
//     _locate("//TODO(sdsdf)", 2, 11);
//     _locate("//  TODO(sdsdf): ", 4, 13);
//   }
//   void test_locateMultiLineCommentTodo() {
//     _locate("* TODO \n * foo", 2, 5);
//     _locate("*TODO:\n * foo", 1, 5);
//     _locate("*TODO(sdsdf): \n * foo", 1, 13);
//     _locate("* TODO(sdsdf)\n * foo", 2, 11);
//     _locate(" * TODO(sdsdf): \n * foo", 3, 13);
//     _locate(" * sdfsdf \n * TODO(sdsdf): \n * foo", 14, 13);
//   }
//   void test_locateMultipleComments() {
//     JavaPatternMatcher m = new JavaPatternMatcher(TodoCode.TODO_REGEX, "/**\n * TODO: foo bar\n * TODO bar baz\n*/");
//     JUnitTestCase.assertTrue(m.find());
//     JUnitTestCase.assertEquals(7, m.start(2));
//     JUnitTestCase.assertEquals(13, m.end(2) - m.start(2));
//     JUnitTestCase.assertTrue(m.find());
//     JUnitTestCase.assertEquals(24, m.start(2));
//     JUnitTestCase.assertEquals(12, m.end(2) - m.start(2));
//     JUnitTestCase.assertFalse(m.find());
//   }
//   void test_negativeLineCommentTodo() {
//     _negative("// TODOS");
//     _negative("// todo");
//   }
//   void test_negativeMultiLineCommentTodo() {
//     _negative(" * TODOS    \n * foo");
//     _negative(" * todo\n * foo");
//   }
//   void _locate(String comment, int start, int length) {
//     JavaPatternMatcher m = new JavaPatternMatcher(TodoCode.TODO_REGEX, comment);
//     JUnitTestCase.assertTrue(m.find());
//     JUnitTestCase.assertEquals(start, m.start(2));
//     JUnitTestCase.assertEquals(length, m.end(2) - m.start(2));
//   }
//   void _negative(String comment) {
//     JavaPatternMatcher m = new JavaPatternMatcher(TodoCode.TODO_REGEX, comment);
//     JUnitTestCase.assertFalse(m.find());
//   }
//   static dartSuite() {
//     _ut.group('TodoCodeTest', () {
//       _ut.test('test_locateLineCommentTodo', () {
//         final __test = new TodoCodeTest();
//         runJUnitTest(__test, __test.test_locateLineCommentTodo);
//       });
//       _ut.test('test_locateMultiLineCommentTodo', () {
//         final __test = new TodoCodeTest();
//         runJUnitTest(__test, __test.test_locateMultiLineCommentTodo);
//       });
//       _ut.test('test_locateMultipleComments', () {
//         final __test = new TodoCodeTest();
//         runJUnitTest(__test, __test.test_locateMultipleComments);
//       });
//       _ut.test('test_negativeLineCommentTodo', () {
//         final __test = new TodoCodeTest();
//         runJUnitTest(__test, __test.test_negativeLineCommentTodo);
//       });
//       _ut.test('test_negativeMultiLineCommentTodo', () {
//         final __test = new TodoCodeTest();
//         runJUnitTest(__test, __test.test_negativeMultiLineCommentTodo);
//       });
//     });
//   }
// }
// class UriKindTest extends JUnitTestCase {
//   void test_fromEncoding() {
//     JUnitTestCase.assertSame(UriKind.DART_URI, UriKind.fromEncoding(0x64));
//     JUnitTestCase.assertSame(UriKind.FILE_URI, UriKind.fromEncoding(0x66));
//     JUnitTestCase.assertSame(UriKind.PACKAGE_URI, UriKind.fromEncoding(0x70));
//     JUnitTestCase.assertSame(null, UriKind.fromEncoding(0x58));
//   }
//   void test_getEncoding() {
//     JUnitTestCase.assertEquals(0x64, UriKind.DART_URI.encoding);
//     JUnitTestCase.assertEquals(0x66, UriKind.FILE_URI.encoding);
//     JUnitTestCase.assertEquals(0x70, UriKind.PACKAGE_URI.encoding);
//   }
//   static dartSuite() {
//     _ut.group('UriKindTest', () {
//       _ut.test('test_fromEncoding', () {
//         final __test = new UriKindTest();
//         runJUnitTest(__test, __test.test_fromEncoding);
//       });
//       _ut.test('test_getEncoding', () {
//         final __test = new UriKindTest();
//         runJUnitTest(__test, __test.test_getEncoding);
//       });
//     });
//   }
// }
// class UriResolver_SourceFactoryTest_test_fromEncoding_valid extends UriResolver {
//   String encoding;
//   UriResolver_SourceFactoryTest_test_fromEncoding_valid(this.encoding) : super();
//   @override
//   Source resolveAbsolute(Uri uri) {
//     if (uri.toString() == encoding) {
//       return new TestSource();
//     }
//     return null;
//   }
// }
// class UriResolver_SourceFactoryTest_test_resolveUri_absolute extends UriResolver {
//   List<bool> invoked;
//   UriResolver_SourceFactoryTest_test_resolveUri_absolute(this.invoked) : super();
//   @override
//   Source resolveAbsolute(Uri uri) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class UriResolver_SourceFactoryTest_test_resolveUri_nonAbsolute_absolute extends UriResolver {
//   @override
//   Source resolveAbsolute(Uri uri) => new FileBasedSource.con2(uri, new JavaFile.fromUri(uri));
// }
// class UriResolver_SourceFactoryTest_test_resolveUri_nonAbsolute_relative extends UriResolver {
//   @override
//   Source resolveAbsolute(Uri uri) => new FileBasedSource.con2(uri, new JavaFile.fromUri(uri));
// }
// class UriResolver_SourceFactoryTest_test_restoreUri extends UriResolver {
//   Source source1;
//   Uri expected1;
//   UriResolver_SourceFactoryTest_test_restoreUri(this.source1, this.expected1) : super();
//   @override
//   Source resolveAbsolute(Uri uri) => null;
//   @override
//   Uri restoreAbsolute(Source source) {
//     if (identical(source, source1)) {
//       return expected1;
//     }
//     return null;
//   }
// }
// /**
//  * Instances of `XmlValidator` traverse an [XmlNode] structure and validate the node
//  * hierarchy.
//  */
// class XmlValidator extends RecursiveXmlVisitor<Object> {
//   /**
//    * A list containing the errors found while traversing the AST structure.
//    */
//   List<String> _errors = new List<String>();
//   /**
//    * The tags to expect when visiting or `null` if tags should not be checked.
//    */
//   List<XmlValidator_Tag> _expectedTagsInOrderVisited;
//   /**
//    * The current index into the [expectedTagsInOrderVisited] array.
//    */
//   int _expectedTagsIndex = 0;
//   /**
//    * The key/value pairs to expect when visiting or `null` if attributes should not be
//    * checked.
//    */
//   List<String> _expectedAttributeKeyValuePairs;
//   /**
//    * The current index into the [expectedAttributeKeyValuePairs].
//    */
//   int _expectedAttributeIndex = 0;
//   /**
//    * Assert that no errors were found while traversing any of the AST structures that have been
//    * visited.
//    */
//   void assertValid() {
//     while (_expectedTagsIndex < _expectedTagsInOrderVisited.length) {
//       String expectedTag = _expectedTagsInOrderVisited[_expectedTagsIndex++]._tag;
//       _errors.add("Expected to visit node with tag: ${expectedTag}");
//     }
//     if (!_errors.isEmpty) {
//       PrintStringWriter writer = new PrintStringWriter();
//       writer.print("Invalid XML structure:");
//       for (String message in _errors) {
//         writer.newLine();
//         writer.print("   ");
//         writer.print(message);
//       }
//       JUnitTestCase.fail(writer.toString());
//     }
//   }
//   /**
//    * Set the tags to be expected when visiting
//    *
//    * @param expectedTags the expected tags
//    */
//   void expectTags(List<XmlValidator_Tag> expectedTags) {
//     // Flatten the hierarchy into expected order in which the tags are visited
//     List<XmlValidator_Tag> expected = new List<XmlValidator_Tag>();
//     _expectTags(expected, expectedTags);
//     this._expectedTagsInOrderVisited = new List.from(expected);
//   }
//   @override
//   Object visitHtmlUnit(HtmlUnit node) {
//     if (node.parent != null) {
//       _errors.add("HtmlUnit should not have a parent");
//     }
//     if (node.endToken.type != TokenType.EOF) {
//       _errors.add("HtmlUnit end token should be of type EOF");
//     }
//     _validateNode(node);
//     return super.visitHtmlUnit(node);
//   }
//   @override
//   Object visitXmlAttributeNode(XmlAttributeNode actual) {
//     if (actual.parent is! XmlTagNode) {
//       _errors.add("Expected ${actual.runtimeType.toString()} to have parent of type ${XmlTagNode.toString()}");
//     }
//     String actualName = actual.name;
//     String actualValue = actual.valueToken.lexeme;
//     if (_expectedAttributeIndex < _expectedAttributeKeyValuePairs.length) {
//       String expectedName = _expectedAttributeKeyValuePairs[_expectedAttributeIndex];
//       if (expectedName != actualName) {
//         _errors.add("Expected ${(_expectedTagsIndex - 1)} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${(_expectedAttributeIndex ~/ 2)} to have name: ${expectedName} but found: ${actualName}");
//       }
//       String expectedValue = _expectedAttributeKeyValuePairs[_expectedAttributeIndex + 1];
//       if (expectedValue != actualValue) {
//         _errors.add("Expected ${(_expectedTagsIndex - 1)} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${(_expectedAttributeIndex ~/ 2)} to have value: ${expectedValue} but found: ${actualValue}");
//       }
//     } else {
//       _errors.add("Unexpected ${(_expectedTagsIndex - 1)} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${(_expectedAttributeIndex ~/ 2)} name: ${actualName} value: ${actualValue}");
//     }
//     _expectedAttributeIndex += 2;
//     _validateNode(actual);
//     return super.visitXmlAttributeNode(actual);
//   }
//   @override
//   Object visitXmlTagNode(XmlTagNode actual) {
//     if (!(actual.parent is HtmlUnit || actual.parent is XmlTagNode)) {
//       _errors.add("Expected ${actual.runtimeType.toString()} to have parent of type ${HtmlUnit.toString()} or ${XmlTagNode.toString()}");
//     }
//     if (_expectedTagsInOrderVisited != null) {
//       String actualTag = actual.tag;
//       if (_expectedTagsIndex < _expectedTagsInOrderVisited.length) {
//         XmlValidator_Tag expected = _expectedTagsInOrderVisited[_expectedTagsIndex];
//         if (expected._tag != actualTag) {
//           _errors.add("Expected ${_expectedTagsIndex} tag: ${expected._tag} but found: ${actualTag}");
//         }
//         _expectedAttributeKeyValuePairs = expected._attributes._keyValuePairs;
//         int expectedAttributeCount = _expectedAttributeKeyValuePairs.length ~/ 2;
//         int actualAttributeCount = actual.attributes.length;
//         if (expectedAttributeCount != actualAttributeCount) {
//           _errors.add("Expected ${_expectedTagsIndex} tag: ${expected._tag} to have ${expectedAttributeCount} attributes but found ${actualAttributeCount}");
//         }
//         _expectedAttributeIndex = 0;
//         _expectedTagsIndex++;
//         Assert.assertNotNull(actual.attributeEnd);
//         Assert.assertNotNull(actual.contentEnd);
//         int count = 0;
//         Token token = actual.attributeEnd.next;
//         Token lastToken = actual.contentEnd;
//         while (!identical(token, lastToken)) {
//           token = token.next;
//           if (++count > 1000) {
//             JUnitTestCase.fail("Expected ${_expectedTagsIndex} tag: ${expected._tag} to have a sequence of tokens from getAttributeEnd() to getContentEnd()");
//             break;
//           }
//         }
//         if (actual.attributeEnd.type == TokenType.GT) {
//           if (HtmlParser.SELF_CLOSING.contains(actual.tag)) {
//             Assert.assertNull(actual.closingTag);
//           } else {
//             Assert.assertNotNull(actual.closingTag);
//           }
//         } else if (actual.attributeEnd.type == TokenType.SLASH_GT) {
//           Assert.assertNull(actual.closingTag);
//         } else {
//           JUnitTestCase.fail("Unexpected attribute end token: ${actual.attributeEnd.lexeme}");
//         }
//         if (expected._content != null && expected._content != actual.content) {
//           _errors.add("Expected ${_expectedTagsIndex} tag: ${expected._tag} to have content '${expected._content}' but found '${actual.content}'");
//         }
//         if (expected._children.length != actual.tagNodes.length) {
//           _errors.add("Expected ${_expectedTagsIndex} tag: ${expected._tag} to have ${expected._children.length} children but found ${actual.tagNodes.length}");
//         } else {
//           for (int index = 0; index < expected._children.length; index++) {
//             String expectedChildTag = expected._children[index]._tag;
//             String actualChildTag = actual.tagNodes[index].tag;
//             if (expectedChildTag != actualChildTag) {
//               _errors.add("Expected ${_expectedTagsIndex} tag: ${expected._tag} child ${index} to have tag: ${expectedChildTag} but found: ${actualChildTag}");
//             }
//           }
//         }
//       } else {
//         _errors.add("Visited unexpected tag: ${actualTag}");
//       }
//     }
//     _validateNode(actual);
//     return super.visitXmlTagNode(actual);
//   }
//   /**
//    * Append the specified tags to the array in depth first order
//    *
//    * @param expected the array to which the tags are added (not `null`)
//    * @param expectedTags the expected tags to be added (not `null`, contains no `null`s)
//    */
//   void _expectTags(List<XmlValidator_Tag> expected, List<XmlValidator_Tag> expectedTags) {
//     for (XmlValidator_Tag tag in expectedTags) {
//       expected.add(tag);
//       _expectTags(expected, tag._children);
//     }
//   }
//   void _validateNode(XmlNode node) {
//     if (node.beginToken == null) {
//       _errors.add("No begin token for ${node.runtimeType.toString()}");
//     }
//     if (node.endToken == null) {
//       _errors.add("No end token for ${node.runtimeType.toString()}");
//     }
//     int nodeStart = node.offset;
//     int nodeLength = node.length;
//     if (nodeStart < 0 || nodeLength < 0) {
//       _errors.add("No source info for ${node.runtimeType.toString()}");
//     }
//     XmlNode parent = node.parent;
//     if (parent != null) {
//       int nodeEnd = nodeStart + nodeLength;
//       int parentStart = parent.offset;
//       int parentEnd = parentStart + parent.length;
//       if (nodeStart < parentStart) {
//         _errors.add("Invalid source start (${nodeStart}) for ${node.runtimeType.toString()} inside ${parent.runtimeType.toString()} (${parentStart})");
//       }
//       if (nodeEnd > parentEnd) {
//         _errors.add("Invalid source end (${nodeEnd}) for ${node.runtimeType.toString()} inside ${parent.runtimeType.toString()} (${parentStart})");
//       }
//     }
//   }
// }
// class XmlValidator_Attributes {
//   final List<String> _keyValuePairs;
//   XmlValidator_Attributes(this._keyValuePairs);
// }
// class XmlValidator_Tag {
//   final String _tag;
//   final XmlValidator_Attributes _attributes;
//   final String _content;
//   final List<XmlValidator_Tag> _children;
//   XmlValidator_Tag(this._tag, this._attributes, this._content, this._children);
// }