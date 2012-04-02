// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class ParserTests extends TestSetup {

  public ParserTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart parser test suite.");

    suite.addTestSuite(SyntaxTest.class);
    suite.addTestSuite(DietParserTest.class);
    suite.addTestSuite(CPParserTest.class);
    suite.addTestSuite(ParserRoundTripTest.class);
    suite.addTestSuite(LibraryParserTest.class);
    suite.addTestSuite(NegativeParserTest.class);
    suite.addTestSuite(ValidatingSyntaxTest.class);
    suite.addTestSuite(CommentTest.class);
    suite.addTestSuite(ErrorMessageLocationTest.class);
    suite.addTestSuite(ParserEventsTest.class);
    suite.addTestSuite(TruncatedSourceParserTest.class);
    suite.addTestSuite(ParserRecoveryTest.class);
    return new ParserTests(suite);
  }
}
