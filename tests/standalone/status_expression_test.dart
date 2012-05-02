// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("StatusExpressionTest");

#import("../../tools/testing/dart/status_expression.dart");


class StatusExpressionTest {
  static void testMain() {
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
  }

  static void test1() {
    Tokenizer tokenizer = new Tokenizer(
        @" $mode == debug && ($arch == chromium || $arch == dartc) ");
    tokenizer.tokenize();
    Expect.listEquals(tokenizer.tokens,
        ["\$", "mode", "==", "debug", "&&", "(", "\$", "arch", "==",
         "chromium", "||", "\$", "arch", "==", "dartc", ")"]);
    ExpressionParser parser =
        new ExpressionParser(new Scanner(tokenizer.tokens));
    BooleanExpression ast = parser.parseBooleanExpression();
    Expect.equals(
        @"(($mode == debug) && (($arch == chromium) || ($arch == dartc)))",
        ast.toString());
    // Test BooleanExpression.evaluate().
    Map environment = new Map();
    environment["arch"] = "dartc";
    environment["mode"] = "debug";
    Expect.isTrue(ast.evaluate(environment));
    environment["mode"] = "release";
    Expect.isFalse(ast.evaluate(environment));
    environment["arch"] = "ia32";
    Expect.isFalse(ast.evaluate(environment));
    environment["mode"] = "debug";
    Expect.isFalse(ast.evaluate(environment));
    environment["arch"] = "chromium";
    Expect.isTrue(ast.evaluate(environment));    
  }

  static void test2() {
    Tokenizer tokenizer = new Tokenizer(
        @"($arch == dartc || $arch == chromium) && $mode == release");
    tokenizer.tokenize();
    Expect.listEquals(
        tokenizer.tokens,
        ["(", "\$", "arch", "==", "dartc", "||", "\$", "arch", "==",
        "chromium", ")", "&&", "\$", "mode", "==", "release"]);
  }
      
  static void test3() {
    var thrown;
    String input = @" $mode == debug && ($arch==chromium || *$arch == dartc)";
    Tokenizer tokenizer = new Tokenizer(input);
    try {
      tokenizer.tokenize();
    } catch (Exception e) {
      thrown = e;
    }
    Expect.equals("Syntax error in '$input'", thrown.toString());
  }

  static void test4() {
    var thrown;
    String input =
        @"($arch == (-dartc || $arch == chromium) && $mode == release";
    Tokenizer tokenizer = new Tokenizer(input);
    try {
      tokenizer.tokenize();
    } catch (Exception e) {
      thrown = e;
    }
    Expect.equals("Syntax error in '$input'", thrown.toString());
  }

  static void test5() {
    Tokenizer tokenizer = new Tokenizer(
        @"Skip , Pass if $arch == dartc, Fail || Timeout if " +
        @"$arch == chromium && $mode == release");
    tokenizer.tokenize();
    ExpressionParser parser =
        new ExpressionParser(new Scanner(tokenizer.tokens));
    SetExpression ast = parser.parseSetExpression();
    Expect.equals(
        @"((skip || (pass if ($arch == dartc))) || ((fail || timeout) " +
        @"if (($arch == chromium) && ($mode == release))))",
        ast.toString());

    // Test SetExpression.evaluate().
    Map environment = new Map();
    environment["arch"] = "ia32";
    environment["checked"] = true;
    environment["mode"] = "debug";
    Set<String> result = ast.evaluate(environment);
    Expect.setEquals(["skip"], result);

    environment["arch"] = "dartc";
    result = ast.evaluate(environment);
    Expect.setEquals(["skip", "pass"], result);

    environment["arch"] = "chromium";
    result = ast.evaluate(environment);
    Expect.setEquals(["skip"], result);

    environment["mode"] = "release";
    result = ast.evaluate(environment);
    Expect.setEquals(["skip", "fail", "timeout"], result);
  }

  static void test6() {
    Tokenizer tokenizer = new Tokenizer(
      @"  $arch == ia32 && $checked || $mode == release    ");
    tokenizer.tokenize();
    ExpressionParser parser =
        new ExpressionParser(new Scanner(tokenizer.tokens));
    BooleanExpression ast = parser.parseBooleanExpression();
    Expect.equals(
        @"((($arch == ia32) && (bool $checked)) || ($mode == release))",
        ast.toString());

    // Test BooleanExpression.evaluate().
    Map environment = new Map();
    environment["arch"] = "ia32";
    environment["checked"] = true;
    environment["mode"] = "debug";
    Expect.isTrue(ast.evaluate(environment));
    environment["mode"] = "release";
    Expect.isTrue(ast.evaluate(environment));
    environment["checked"] = false;
    Expect.isTrue(ast.evaluate(environment));
    environment["mode"] = "debug";
    Expect.isFalse(ast.evaluate(environment));
    environment["arch"] = "arm";
    Expect.isFalse(ast.evaluate(environment));
    environment["checked"] = true;
    Expect.isFalse(ast.evaluate(environment));    
  }
}  

main() {
  StatusExpressionTest.testMain();
}
