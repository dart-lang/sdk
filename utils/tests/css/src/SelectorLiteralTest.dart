// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("SelectorLiteralTest");
#import("../../../css/css.dart");

class SelectorLiteralTest {
  static final String ERROR = 'CompilerException: <buffer>:';

  static testMain() {
    initCssWorld();
    options.useColors = false;

    testSimpleClassSelectorSuccesses();
    testSimpleClassSelectorFailures();
    testPrivateNameFailures();
  }

  static void testSimpleClassSelectorSuccesses() {
    List<String> knownClasses = ['foobar', 'xyzzy', 'a-story', 'b-story'];
    List<String> knownIds = ['id1', 'id2', 'id-number-3'];

    CssWorld cssWorld = new CssWorld(knownClasses, knownIds);

    try {
      // Valid selectors for class names.
      cssParseAndValidate('@{.foobar}', cssWorld);
      cssParseAndValidate('@{.foobar .xyzzy}', cssWorld);
      cssParseAndValidate('@{.foobar .a-story .xyzzy}', cssWorld);
      cssParseAndValidate('@{.foobar .xyzzy .a-story .b-story}', cssWorld);

      // Valid selectors for element IDs.
      cssParseAndValidate('@{#id1}', cssWorld);
      cssParseAndValidate('@{#id-number-3}', cssWorld);
      cssParseAndValidate('@{#_privateId}', cssWorld);

      // Valid selectors for private class names (leading underscore).
      cssParseAndValidate('@{.foobar ._privateClass}', cssWorld);
      cssParseAndValidate('@{.foobar ._privateClass .xyzzy}', cssWorld);
      cssParseAndValidate('@{.foobar ._private1 .xyzzy ._private2}', cssWorld);

      // Valid selectors for private element IDs (leading underscore).
      cssParseAndValidate('@{._privateClass}', cssWorld);
    } catch (final e) {
      // CSS Expressions failed
      Expect.fail(e.toString());
    }
  }

  static void testSimpleClassSelectorFailures() {
    List<String> knownClasses = ['foobar', 'xyzzy', 'a-story', 'b-story'];
    List<String> knownIds = ['id1', 'id2', 'id-number-3'];

    CssWorld cssWorld = new CssWorld(knownClasses, knownIds);

    // Invalid class name.
    String css = '@{.-foobar}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Unknown selector name .-foobar",
          e.toString());
    }

    // Error this class name is not known.
    css = '@{.foobar1}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Unknown selector name .foobar1",
          e.toString());
    }

    // Error if any class name is not known.
    css = '@{.foobar .xyzzy1}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Unknown selector name .xyzzy1",
          e.toString());
    }

    // Test for invalid class name (can't start with number).
    css = '@{.foobar .1a-story .xyzzy}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("${ERROR}1:11: fatal: parsing error expected }\n" +
          "${css}\n          ^^", e.toString());
    }

    // element id must be single selector.
    css = '@{#id1 #id2}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Use of Id selector must be " +
          "singleton starting at #id2", e.toString());
    }

    // element id must be single selector.
    css = '@{#id-number-3 .foobar}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("@{#id-number-3 .foobar} should not succeed.");
    } catch (final e) {
      // CSS Expressions failed
      Expect.equals("CssSelectorException: Can not mix Id selector with "+
          "class selector(s). Id selector must be singleton too many " +
          "starting at .foobar", e.toString(), '');
    }

    // element id must be alone and only one element id.
    css = '@{.foobar #id-number-3 #id1}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      // CSS Expressions failed
      Expect.equals("CssSelectorException: Use of Id selector must be " +
          "singleton starting at #id-number-3", e.toString());
    }

    // Namespace selector not valid in @{css_expression}
    css = '@{foo|div}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Invalid template selector foo|div",
          e.toString());
    }

    // class and element id not allowed together. 
    css = '@{.foobar foo|div}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("$css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Invalid template selector foo|div",
          e.toString());
    }

    // Element id and namespace not allowed together. 
    css = '@{#id1 foo|div}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Invalid template selector foo|div",
          e.toString());
    }

    // namespace and element id not allowed together. 
    css = '@{foo|div #id1}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Invalid template selector foo|div",
          e.toString());
    }

    // namespace / element not allowed.
    css = '@{foo|div .foobar}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Invalid template selector foo|div",
          e.toString());
    }

    // Combinators not allowed.
    css = '@{.foobar > .xyzzy}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Selectors can not have " +
          "combinators (>, +, or ~) before >.xyzzy", e.toString());
    }
  }

  static void testPrivateNameFailures() {
    List<String> knownClasses = ['foobar', 'xyzzy', 'a-story', 'b-story'];
    List<String> knownIds = ['id1', 'id2', 'id-number-3'];

    CssWorld cssWorld = new CssWorld(knownClasses, knownIds);

    // Too many.
    String css = '@{._private #id2}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Use of Id selector must be " +
          "singleton starting at #id2", e.toString());
    }

    // Unknown class foobar2.
    css = '@{._private .foobar2}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Unknown selector name .foobar2",
          e.toString());
    }

    // Too many element IDs.
    css = '@{#_privateId #id2}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Use of Id selector must be " +
          "singleton starting at #id2", e.toString());
    }

    // Too many element IDs.
    css = '@{#_privateId1 #_privateId2}';
    try {
      cssParseAndValidate('${css}', cssWorld);
      Expect.fail("${css} should not succeed.");
    } catch (final e) {
      Expect.equals("CssSelectorException: Use of Id selector must be " +
          "singleton starting at #_privateId2", e.toString());
    }
  }

}

main() {
  SelectorLiteralTest.testMain();
}
