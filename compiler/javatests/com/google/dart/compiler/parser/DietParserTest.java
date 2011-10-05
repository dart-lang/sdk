// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

/**
 * Tests for the parser, which simply assert that valid source units parse
 * correctly. All tests invoking {@code parseUnit} are designed such that
 * they will throw an exception if anything goes wrong in the parser.
 */
public class DietParserTest extends AbstractParserTest {

  public void testStringsErrors() {
    parseUnit("StringsErrorsNegativeTest.dart");
  }

  @Override
  protected DartParser makeParser(ParserContext context) {
    return new DartParser(context, /* isDietParse */true);
  }
}
