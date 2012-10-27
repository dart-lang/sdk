// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end.inc;

import static com.google.dart.compiler.DartCompiler.EXTENSION_DEPS;
import static com.google.dart.compiler.DartCompiler.EXTENSION_TIMESTAMP;

import com.google.common.collect.Lists;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.MockBundleLibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.util.apache.StringUtils;

import junit.framework.AssertionFailedError;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

// TODO(zundel): update this test not to rely on code generation
public class IncrementalCompilationTest extends CompilerTestCase {

  private static final String TEST_BASE_PATH = "com/google/dart/compiler/end2end/inc/";
  private static final String TEST_APP = "my.app.dart";

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
      writes.add(source.getName() + "/" + extension);
      return super.getArtifactWriter(source, part, extension);
    }

    void resetReadsAndWrites() {
      reads.clear();
      writes.clear();
    }
  }

  private DefaultCompilerConfiguration config;
  private IncMockArtifactProvider provider;

  private MockBundleLibrarySource myAppSource;
  private MockBundleLibrarySource someLibSource;
  private MockBundleLibrarySource someImplLibSource;

  private final List<DartCompilationError> errors = Lists.newArrayList();

  @Override
  protected void setUp() throws Exception {
    config = new DefaultCompilerConfiguration() {
      @Override
      public boolean incremental() {
        return true;
      }
    };
    provider = new IncMockArtifactProvider();

    myAppSource = new MockBundleLibrarySource(IncrementalCompilationTest.class.getClassLoader(),
      TEST_BASE_PATH, TEST_APP);
    someLibSource = myAppSource.getImportFor("some.lib.dart");
    someImplLibSource = someLibSource.getImportFor("someimpl.lib.dart");
  }

  @Override
  protected void tearDown() {
    config = null;
    provider = null;
    myAppSource = null;
    someLibSource = null;
    someImplLibSource = null;
  }

  public void testRemoveDeps() throws Exception {
    compile();

    MockBundleLibrarySource myNuke5AppSource = new MockBundleLibrarySource(
      IncrementalCompilationTest.class.getClassLoader(),
      TEST_BASE_PATH, "my.nuke5.app.dart", "my.app.dart");
    myNuke5AppSource.remapSource("mybase.dart", "mybase.no5ref.dart");
    myNuke5AppSource.remapSource("my.dart", "my.no5ref.dart");
    myNuke5AppSource.removeSource("myother5.dart");

    compile(myNuke5AppSource);
  }

  public void testFullCompile() {
    compile();
    System.out.println(StringUtils.join(errors, "\n"));

    // Assert that all artifacts are written.
    didWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didWrite("some.dart", EXTENSION_TIMESTAMP);
    didWrite("some.lib.dart", EXTENSION_DEPS);

    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didWrite("myother2.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);
    didWrite("my.app.dart", EXTENSION_TIMESTAMP);
  }

  public void testNoOpRecompile() {
    compile();

    provider.resetReadsAndWrites();
    compile();

    // Assert we didn't write anything.
    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("my.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
    didNotWrite("my.app.dart", EXTENSION_DEPS);
    didNotWrite("my.app.dart", EXTENSION_TIMESTAMP);
  }

  public void testTouchOneSource() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("my.dart");
    compile();

    // We just bumped the timestamp on my.dart, so only my.dart.js and my.app.js should be changed.
    // At present, the app's deps and api will be rewritten. This might be optimized later.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    // Nothing else should have changed.
    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testNormalizationTracking() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother7.dart");
    compile();

    // Test against normalization having an effect on hashcodes
    // SomeInterface2 is an empty interface that can have an extra default constructor added by
    // the dartc backend normalization process.  By depending on a class that implements the interface,
    // my.app.dart.deps will transitively depend on the empty interface.  If something changes
    // with how hashcodes are generated, this test should be updated.

    // We just bumped the timestamp on myother7.dart, so only myother7.dart.js and my.app.js should
    // be changed. At present, the app's deps and api will be rewritten.

    didWrite("myother7.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    // Nothing else should have changed.
    didNotWrite("my.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testKnockout_timestamp() {
    compile();

    provider.resetReadsAndWrites();
    provider.removeArtifact("my.dart", "", EXTENSION_TIMESTAMP);
    compile();

    // At present, knocking out a js artifact will force an update of the library's api and
    // deps. This could be optimized.
    didWrite("my.dart", EXTENSION_TIMESTAMP);

    // Assert that everything else was left alone.
    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeImplementation_methodBody() {
    compile();

    provider.resetReadsAndWrites();
    someImplLibSource.remapSource("someimpl.dart", "someimpl.bodychange.dart");
    compile();

    // Changed someimpl.dart, so it, its library, and the compiled app should be written.
    didWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS);

    // We've switched to (unit -> unit) dependency, so should be recompiled too.
    didWrite("some.dart", EXTENSION_TIMESTAMP);
    didWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("my.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
    didNotWrite("my.app.dart", EXTENSION_DEPS);
  }

  public void testChangeApi_newStaticMethod() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother0.dart", "myother0.newstaticmethod.dart");
    compile();

    // Added a new static method to Other0, which should force a recompile of my.dart,
    // because the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_staticFieldRef() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother3.dart", "myother3.newstaticfield.dart");
    compile();

    // Added a new static field to Other0, which should force a recompile of my.dart,
    // because the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother3.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_viaTypeParamBound() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother4.dart", "myother4.newstaticfield.dart");
    compile();

    // Added a new static field to Other0, which should force a recompile of my.dart,
    // because the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother4.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_returnTypeChange() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother0.dart", "myother0.returntypechange.dart");
    compile();

    // Changed a return type in Other0, which should force a recompile of my.dart,
    // because the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_globalVarChange() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother0.dart", "myother0.globalvarchange.dart");
    compile();

    // Changed a top-level variable type in Other0, which should force a recompile of my.dart,
    // because the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);
  }

  public void testChangeApi_globalFunctionChange() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother0.dart", "myother0.globalfunctionchange.dart");
    compile();

    // Changed a return type in Other0, which should force a recompile of my.dart,
    // because the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);
  }

  public void testChangeApi_viaNew() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother1.dart", "myother1.change.dart");
    compile();

    // Changed the api of Other1, which should force a recompile of my.dart,
    // because the latter instantiates one of its classes.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_viaSubclassing() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother2.dart", "myother2.change.dart");
    compile();

    // Changed the api of Other2, which should force a recompile of my.dart,
    // because the latter subclasses one of its classes.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother2.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_inLibrary() {
    compile();

    provider.resetReadsAndWrites();
    someLibSource.remapSource("some.dart", "some.newmethod.dart");
    someImplLibSource.remapSource("someimpl.dart", "someimpl.change.dart");
    compile();

    // We changed both the interface and implementation libraries, so almost everything should have
    // been recompiled.
    didWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didWrite("some.dart", EXTENSION_TIMESTAMP);
    didWrite("some.lib.dart", EXTENSION_DEPS);

    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    // Except the "others", which have no dependency on the library.
    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testChangeApi_inImplLibrary() {
    compile();

    provider.resetReadsAndWrites();
    someImplLibSource.remapSource("someimpl.dart", "someimpl.change.dart");
    compile();

    // Assert that only the interface and implementation library were recompiled.
    didWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didWrite("some.dart", EXTENSION_TIMESTAMP);
    didWrite("some.lib.dart", EXTENSION_DEPS);

    // The app should remain untouched.
    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
    didNotWrite("my.dart", EXTENSION_TIMESTAMP);
    didNotWrite("my.app.dart", EXTENSION_DEPS);
  }

  public void testChangeApi_inInterface() {
    compile();

    provider.resetReadsAndWrites();
    someLibSource.remapSource("some.dart", "some.intfchange.dart");
    compile();

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);

    // Assert we recompiled both some.dart and someimpl.dart, as well as my.dart.
    // (someimpl.dart is recompiled because its interface in some.dart changed)
    didWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didWrite("some.dart", EXTENSION_TIMESTAMP);
    didWrite("some.lib.dart", EXTENSION_DEPS);

    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);
  }

  // TODO(jgw): Bug 5319907.
  public void disabled_testFieldHole() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother0.dart", "myother0.fillthehole.dart");
    compile();

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);

    // Both myother0.dart and my.dart should be recompiled.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);
  }

  public void testMethodHole() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother0.dart", "myother0.fillthemethodhole.dart");
    compile();
  }

  public void testQualifiedFieldRef() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother5.dart", "myother5.change.dart");
    compile();

    // Changed the api of Other5, which should force a recompile of my.dart,
    // because the latter includes a qualified reference to one of its instance fields.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother5.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testQualifiedMethodRef() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother6.dart", "myother6.change.dart");
    compile();

    // Changed the api of Other6, which should force a recompile of my.dart,
    // because the latter includes a qualified reference to one of its instance methods.
    didWrite("my.dart", EXTENSION_TIMESTAMP);
    didWrite("myother6.dart", EXTENSION_TIMESTAMP);
    didWrite("my.app.dart", EXTENSION_DEPS);

    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testRemoveDepClass() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.remapSource("myother5.dart", "myother5.change.dart");
    myAppSource.remapSource("myother6.dart", "myother6.removeclass.dart");
    compile();

    // Changed myother6.dart, which should force a recompile of myother5.dart,
    // because the latter had a qualified reference to one of its classes.
    didWrite("myother5.dart", EXTENSION_TIMESTAMP);
    didWrite("myother6.dart", EXTENSION_TIMESTAMP);

    didWrite("my.dart", EXTENSION_TIMESTAMP);
    // Because of the previous changes my.app.dart is also recompile.
    didWrite("my.app.dart", EXTENSION_DEPS);

    // No changes in not related units.
    didNotWrite("someimpl.dart", EXTENSION_TIMESTAMP);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS);

    didNotWrite("some.dart", EXTENSION_TIMESTAMP);
    didNotWrite("some.lib.dart", EXTENSION_DEPS);

    didNotWrite("myother0.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother1.dart", EXTENSION_TIMESTAMP);
    didNotWrite("myother2.dart", EXTENSION_TIMESTAMP);
  }

  public void testMergeFiles() throws Exception {
    compile();

    MockBundleLibrarySource myMergedAppSource = new MockBundleLibrarySource(
      IncrementalCompilationTest.class.getClassLoader(),
      TEST_BASE_PATH, "my.merged.app.dart", "my.app.dart");

    compile(myMergedAppSource);
  }

  private void compile() {
    compile(myAppSource);
  }

  private void compile(LibrarySource lib) {
    try {
      errors.clear();
      DartCompilerListener listener = new DartCompilerListener.Empty() {
        @Override
        public void onError(DartCompilationError event) {
          errors.add(event);
        }
      };
      DartCompiler.compileLib(lib, config, provider, listener);
    } catch (IOException e) {
      throw new AssertionFailedError("Unexpected IOException: " + e.getMessage());
    }
  }

  private void didWrite(String sourceName, String extension) {
    String spec = sourceName + "/" + extension;
    assertTrue("Expected write: " + spec, provider.writes.contains(spec));
  }

  private void didNotWrite(String sourceName, String extension) {
    String spec = sourceName + "/" + extension;
    assertFalse("Didn't expect write: " + spec, provider.writes.contains(spec));
  }
}
