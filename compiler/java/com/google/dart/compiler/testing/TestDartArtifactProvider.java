// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.testing;

import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.Source;

import java.io.Reader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;

/**
 * A mock artifact provider for use in tests.
 */
public class TestDartArtifactProvider extends DartArtifactProvider {
  @Override
  public boolean isOutOfDate(Source source, Source base, String extension) {
    return true;
  }

  @Override
  public Writer getArtifactWriter(Source source, String part, String extension) {
    return new StringWriter();
  }

  @Override
  public URI getArtifactUri(Source source, String part, String extension) {
    throw new AssertionError();
  }

  @Override
  public Reader getArtifactReader(Source source, String part, String extension) {
    return null;
  }
}
