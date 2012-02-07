// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.backend.js;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

// TODO(zundel): Remove this suite when code generation is removed.
public class JsBackendTests extends TestSetup {
  public JsBackendTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart Javascript backend test suite.");
    return new JsBackendTests(suite);
  }
}
