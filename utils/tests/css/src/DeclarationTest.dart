// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../css/css.dart");

class DeclarationTest {

  static testMain() {
    initCssWorld();

    testSimpleTerms();
    testMoreDecls();
    testIdentifiers();
    testComposites();
    testNewerCss();
    testCssFile();
  }

  static void testSimpleTerms() {
    final String input =
      ".foo {\n" +
      "  background-color: #191919;\n" +
      "  width: 10PX;\n" +
      "  height: 22mM !important;\n" +
      "  border-width: 20cm;\n" +
      "  margin-width: 33%;\n" +
      "  border-height: 30EM;\n" +
      "  width: .6in;\n" +
      "  length: 1.2in;\n" +
      "  -web-stuff: -10Px;\n" +
      "}\n";
    final String generated =
      "\n" +
      ".foo {\n" +
      "  background-color: #191919;\n" +
      "  width: 10px;\n" +
      "  height: 22mm !important;\n" +
      "  border-width: 20cm;\n" +
      "  margin-width: 33%;\n" +
      "  border-height: 30em;\n" +
      "  width: .6in;\n" +          // Check double values.
      "  length: 1.2in;\n" +
      "  -web-stuff: -10px;\n" +
      "}\n";

    Parser parser =
        new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE, input));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(generated, stylesheet.toString());
  }

  static void testMoreDecls() {
    final String input =
      ".more {\n" +
        "  color: red;\n" +
        "  color: #aabbcc;  /* test -- 3 */\n" +
        "  color: blue;\n" +
        "  background-image: url(http://test.jpeg);\n" +
        "  background-image: url(\"http://double_quote.html\");\n" +
        "  background-image: url('http://single_quote.html');\n" +
        "  color: rgba(10,20,255);  <!-- test CDO/CDC  -->\n" +
        "  color: #123aef;   /* hex # part integer and part identifier */\n" +
        "}\n";
    final String generated =
      "\n" +
      ".more {\n" +
        "  color: #ff0000;\n" +
        "  color: #aabbcc;\n" +
        "  color: #0ff;\n" +
        "  background-image: url(http://test.jpeg);\n" +
        "  background-image: url(http://double_quote.html);\n" +
        "  background-image: url(http://single_quote.html);\n" +
        "  color: rgba(10, 20, 255);\n" +
        "  color: #123aef;\n" +
        "}\n";

    Parser parser =
      new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE, input));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(generated, stylesheet.toString());
  }

  static void testIdentifiers() {
    final String input =
      // Make sure identifiers that could look like hex are handled.
      "#da {\n" +
      "  height: 100px;\n" +
      "}\n" +
      // Make sure elements that contain a leading dash (negative) are valid.
      "#-foo {\n" +
      "  width: 10px;\n" +
      "  color: #ff00cc;\n" +
      "}\n";
    final String generated =
      "\n" +
      "#da {\n" +
      "  height: 100px;\n" +
      "}\n" +
      "\n" +
      "#-foo {\n" +
      "  width: 10px;\n" +
      "  color: #ff00cc;\n" +
      "}\n";

    Parser parser =
      new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE, input));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(generated, stylesheet.toString());
  }

  static void testComposites() {
    final String input =
      // Composites
      ".xyzzy {\n" +
      "  border: 10px 80px 90px 100px;\n" +
      "  width: 99%;\n" +
      "}\n" +
      "@-webkit-keyframes pulsate {\n" +
      "  0% {\n" +
      "    -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n" +
      "  }\n" +
      "}\n";
    final String generated =
      "\n" +
      ".xyzzy {\n" +
      "  border: 10px 80px 90px 100px;\n" +
      "  width: 99%;\n" +
      "}\n" +
      "@-webkit-keyframes pulsate {\n" +
      "  0% {\n" +
      "  -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n" +
      "  }\n" +
      "}\n";
    Parser parser =
      new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE, input));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(generated, stylesheet.toString());
  }

  static void testNewerCss() {
    final String input =
      // Newer things in CSS
      "@media screen,print {\n" +
      "  .foobar_screen {\n" +
      "    width: 10px;\n" +
      "  }\n" +
      "}\n" +
      "@page : test {\n" +
      "  width: 10px;\n" +
      "}\n" +
      "@page {\n" +
      "  height: 22px;\n" +
      "}\n";
    final String generated =
      "@media screen,print {\n" +
      "\n" +
      ".foobar_screen {\n" +
      "  width: 10px;\n" +
      "}\n" +
      "\n" +
      "}\n" +
      "@page : test {\n" +
      "  width: 10px;\n" +
      "\n" +
      "}\n" +
      "@page {\n" +
      "  height: 22px;\n" +
      "\n" +
      "}\n";

    Parser parser =
      new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE, input));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(generated, stylesheet.toString());
  }

  static void testCssFile() {
    final String scss =
      "@import 'simple.css'\n" +
      "@import \"test.css\" print\n" +
      "@import url(test.css) screen, print\n" +

      "div[href^='test'] {\n" +
      "  height: 10px;\n" +
      "}\n" +

      "@-webkit-keyframes pulsate {\n" +
      "  from {\n" +
      "    -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n" +
      "  }\n" +
      "  10% {\n" +
      "    -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n" +
      "  }\n" +
      "  30% {\n" +
      "    -webkit-transform: translate3d(0, 2, 0) scale(1.0);\n" +
      "  }\n" +
      "}\n" +

      ".foobar {\n" +
      "    grid-columns: 10px (\"content\" 1fr 10px)[4];\n" +
      "}\n";

    final String generated =
      "@import url(simple.css)\n" +
      "@import url(test.css) print\n" +
      "@import url(test.css) screen,print\n" +
      "\n" +
      "div[href ^= \"test\"] {\n" +
      "  height: 10px;\n" +
      "}\n" +
      "@-webkit-keyframes pulsate {\n" +
      "  from {\n" +
      "  -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n" +
      "  }\n" +
      "  10% {\n" +
      "  -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n" +
      "  }\n" +
      "  30% {\n" +
      "  -webkit-transform: translate3d(0, 2, 0) scale(1.0);\n" +
      "  }\n" +
      "}\n" +
      "\n" +
      ".foobar {\n" +
      "  grid-columns: 10px (\"content\" 1fr 10px) [4];\n" +
      "}\n";

    Parser parser =
      new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE, scss));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(generated, stylesheet.toString());
  }
}

main() {
  DeclarationTest.testMain();
}
