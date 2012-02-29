// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end.inc;

import static com.google.dart.compiler.DartCompiler.EXTENSION_DEPS;
import static com.google.dart.compiler.DartCompiler.EXTENSION_TIMESTAMP;

import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.MockBundleLibrarySource;
import com.google.dart.compiler.Source;

import junit.framework.AssertionFailedError;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URISyntaxException;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

public class IncrementalCompilationWithPrefixTest extends CompilerTestCase {

  private static final String TEST_BASE_PATH = "com/google/dart/compiler/end2end/inc/";

  static class IncMockArtifactProvider extends MockArtifactProvider {
    Set<String> reads = new ConcurrentSkipListSet<String>();
    Set<String> writes = new ConcurrentSkipListSet<String>();

    @Override
    public Reader getArtifactReader(Source source, String part, String extension) {
      reads.add(source.getName() + "/" + extension);
      return super.getArtifactReader(source, part, extension);
    }

    @Override
    public Writer getArtifactWriter(Source source, String part, String extension) {
      // System.out.println("Writing " + source.getName() + "/" + extension);
      writes.add(source.getName() + "/" + extension);
      return super.getArtifactWriter(source, part, extension);
    }

    void resetReadsAndWrites() {
      // System.out.println("Clearing reads/writes");
      reads.clear();
      writes.clear();
    }
  }

  private DefaultCompilerConfiguration config;
  private IncMockArtifactProvider provider;

  private MockBundleLibrarySource myAppSource;
  private MockBundleLibrarySource someLibSource;

  @Override
  protected void setUp() throws Exception {
    config = new DefaultCompilerConfiguration() {
      @Override
      public boolean incremental() {
        return true;
      }
    };
    provider = new IncMockArtifactProvider();
  }

  @Override
  protected void tearDown() {
    config = null;
    provider = null;
    myAppSource = null;
    someLibSource = null;
  }

  public void testModifyUnPrefixedLib() {
    try {
      myAppSource = new MockBundleLibrarySource(IncrementalCompilationWithPrefixTest.class.getClassLoader(),
      TEST_BASE_PATH, "my.unprefixed.app.dart");
      someLibSource = myAppSource.getImportFor("some.prefixable.lib.dart");
    } catch (URISyntaxException e) {
      throw new AssertionError(e);
    }

    compile();

    provider.resetReadsAndWrites();
    someLibSource.touchSource("some.prefixable.lib.dart");
    someLibSource.remapSource("some.prefixable.lib.dart", "some.prefixable.modified.lib.dart");
    compile();

    didWrite("my.unprefixed.app.dart", EXTENSION_TIMESTAMP);
    didWrite("my.unprefixed.app.dart", EXTENSION_DEPS);
    didWrite("some.prefixable.lib.dart", EXTENSION_TIMESTAMP);
    didWrite("some.prefixable.lib.dart", EXTENSION_DEPS);
  }

  public void testModifyPrefixedLib() {
    try {
      myAppSource = new MockBundleLibrarySource(IncrementalCompilationWithPrefixTest.class.getClassLoader(),
      TEST_BASE_PATH, "my.prefixed.app.dart");
      someLibSource = myAppSource.getImportFor("some.prefixable.lib.dart");
    } catch (URISyntaxException e) {
      throw new AssertionError(e);
    }

    compile();

    provider.resetReadsAndWrites();
    someLibSource.touchSource("some.prefixable.lib.dart");
    someLibSource.remapSource("some.prefixable.lib.dart", "some.prefixable.modified.lib.dart");
    compile();

    didWrite("my.prefixed.app.dart", EXTENSION_TIMESTAMP);
    didWrite("my.prefixed.app.dart", EXTENSION_DEPS);
    didWrite("some.prefixable.lib.dart", EXTENSION_TIMESTAMP);
    didWrite("some.prefixable.lib.dart", EXTENSION_DEPS);
  }

  private void compile() {
    compile(null);
  }

  private void compile(String srcName, Object... errors) {
    compile(myAppSource, srcName, errors);
  }

  private void compile(LibrarySource lib, String srcName, Object... errors) {
    try {
      DartCompilerListener listener = new DartCompilerListenerTest(srcName, errors);
      DartCompiler.compileLib(lib, config, provider, listener);
    } catch (IOException e) {
      throw new AssertionFailedError("Unexpected IOException: " + e.getMessage());
    }
  }

  private void didWrite(String sourceName, String extension) {
    String spec = sourceName + "/" + extension;
    assertTrue("Expected write: " + spec, provider.writes.contains(spec));
  }
}
