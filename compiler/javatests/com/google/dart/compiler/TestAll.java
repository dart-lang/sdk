/*
 * Copyright (c) 2013, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */

package com.google.dart.compiler;

import com.google.dart.compiler.ast.AstTests;
import com.google.dart.compiler.common.CommonTests;
import com.google.dart.compiler.end2end.End2EndTests;
import com.google.dart.compiler.parser.ParserTests;
import com.google.dart.compiler.resolver.ResolverTests;
import com.google.dart.compiler.util.UtilTests;

import junit.framework.Test;
import junit.framework.TestSuite;

public class TestAll {

  public static Test suite() {
    TestSuite suite = new TestSuite("Tests in " + TestAll.class.getPackage().getName());

    suite.addTest(CompilerTests.suite());
    suite.addTest(AstTests.suite());
    suite.addTest(CommonTests.suite());
    suite.addTest(End2EndTests.suite());
    suite.addTest(ParserTests.suite());
    suite.addTest(ResolverTests.suite());
    //suite.addTest(TypeTests.suite());
    suite.addTest(UtilTests.suite());

    return suite;
  }

}
