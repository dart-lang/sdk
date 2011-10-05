// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end.inc;

import static com.google.dart.compiler.DartCompiler.EXTENSION_API;
import static com.google.dart.compiler.DartCompiler.EXTENSION_DEPS;
import static com.google.dart.compiler.backend.js.JavascriptBackend.EXTENSION_APP_JS;
import static com.google.dart.compiler.backend.js.JavascriptBackend.EXTENSION_JS;

import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.MockBundleLibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.backend.js.JavascriptBackend;

import junit.framework.AssertionFailedError;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URISyntaxException;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

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

  @Override
  protected void setUp() throws Exception {
    config = new DefaultCompilerConfiguration(new JavascriptBackend()) {
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

  public void testRemoveDeps() throws URISyntaxException {
    compile();

    MockBundleLibrarySource myNuke5AppSource = new MockBundleLibrarySource(
      IncrementalCompilationTest.class.getClassLoader(),
      TEST_BASE_PATH, "my.nuke5.app.dart", "my.app.dart");
    myNuke5AppSource.remapSource("mybase.dart", "mybase.no5ref.dart");
    myNuke5AppSource.remapSource("my.dart", "my.no5ref.dart");
    myNuke5AppSource.removeSource("myother5.dart");

    compile(myNuke5AppSource, null);
  }

  public void testFullCompile() {
    compile();

    // Assert that all artifacts are written.
    didWrite("someimpl.dart", EXTENSION_JS, provider);
    didWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didWrite("some.dart", EXTENSION_JS, provider);
    didWrite("some.lib.dart", EXTENSION_API, provider);
    didWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("myother1.dart", EXTENSION_JS, provider);
    didWrite("myother2.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_JS, provider);
  }

  public void testNoOpRecompile() {
    compile();

    provider.resetReadsAndWrites();
    compile();

    // Assert we didn't write anything.
    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("my.dart", EXTENSION_JS, provider);
    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
    didNotWrite("my.app.dart", EXTENSION_API, provider);
    didNotWrite("my.app.dart", EXTENSION_DEPS, provider);
    didNotWrite("my.app.dart", EXTENSION_JS, provider);
  }

  public void testTouchOneSource() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("my.dart");
    compile();

    // We just bumped the timestamp on my.dart, so only my.dart.js and my.app.js should be changed.
    // At present, the app's deps and api will be rewritten. This might be optimized later.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);

    // Nothing else should have changed.
    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testKnockout_jsArtifact() {
    compile();

    provider.resetReadsAndWrites();
    provider.removeArtifact("my.dart", "", EXTENSION_JS);
    compile();

    // At present, knocking out a js artifact will force an update of the library's api and
    // deps. This could be optimized.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);

    // Assert that everything else was left alone.
    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testKnockout_intfArtifact() {
    compile();

    provider.resetReadsAndWrites();
    provider.removeArtifact("my.app.dart", "", EXTENSION_API);
    compile();

    // At present, knocking out an api artifact will force an update of the library's units
    // and deps. This could be optimized.
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("myother1.dart", EXTENSION_JS, provider);
    didWrite("myother2.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);

    // Assert that everything else was left alone.
    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);
  }

  public void testChangeImplementation_methodBody() {
    compile();

    provider.resetReadsAndWrites();
    someImplLibSource.touchSource("someimpl.dart");
    someImplLibSource.remapSource("someimpl.dart", "someimpl.bodychange.dart");
    compile();

    // Changed someimpl.dart, so it, its library, and the compiled app should be written, but not
    // units that depend upon it.
    didWrite("someimpl.dart", EXTENSION_JS, provider);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("my.dart", EXTENSION_JS, provider);
    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
    didNotWrite("my.app.dart", EXTENSION_API, provider);
    didNotWrite("my.app.dart", EXTENSION_DEPS, provider);
  }

  public void testChangeApi_newStaticMethod() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.newstaticmethod.dart");
    compile();

    // Added a new static method to Other0, which should force a recompile of my.dart, because the
    // latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testChangeApi_staticFieldRef() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother3.dart");
    myAppSource.remapSource("myother3.dart", "myother3.newstaticfield.dart");
    compile();

    // Added a new static method to Other0, which should force a recompile of my.dart, because the
    // latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother3.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testChangeApi_viaTypeParamBound() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother4.dart");
    myAppSource.remapSource("myother4.dart", "myother4.newstaticfield.dart");
    compile();

    // Added a new static method to Other0, which should force a recompile of my.dart, because the
    // latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother4.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testChangeApi_returnTypeChange() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.returntypechange.dart");
    compile();

    // Changed a return type in Other0, which should force a recompile of my.dart, because
    // the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testChangeApi_globalVarChange() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.globalvarchange.dart");
    compile();

    // Changed a return type in Other0, which should force a recompile of my.dart, because
    // the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
  }

  public void testChangeApi_globalFunctionChange() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.globalfunctionchange.dart");
    compile();

    // Changed a return type in Other0, which should force a recompile of my.dart, because
    // the latter contains a reference to one of its static methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
  }

  public void testChangeApi_viaNew() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother1.dart");
    myAppSource.remapSource("myother1.dart", "myother1.change.dart");
    compile();

    // Changed the api of Other1, which should force a recompile of my.dart, because the
    // latter intantiates one of its classes.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother1.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testChangeApi_viaSubclassing() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother2.dart");
    myAppSource.remapSource("myother2.dart", "myother2.change.dart");
    compile();

    // Changed the api of Other2, which should force a recompile of my.dart, because the
    // latter subclasses one of its classes.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother2.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
  }

  public void testChangeApi_inLibrary() {
    compile();

    provider.resetReadsAndWrites();
    someLibSource.touchSource("some.dart");
    someLibSource.remapSource("some.dart", "some.newmethod.dart");
    someImplLibSource.touchSource("someimpl.dart");
    someImplLibSource.remapSource("someimpl.dart", "someimpl.change.dart");
    compile();

    // We changed both the interface and implementation libraries, so almost everything should have
    // been recompiled.
    didWrite("someimpl.dart", EXTENSION_JS, provider);
    didWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didWrite("some.dart", EXTENSION_JS, provider);
    didWrite("some.lib.dart", EXTENSION_API, provider);
    didWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    // Except the "others", which have no dependency on the library.
    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);

    // And the app's api, which also hasn't changed.
    didNotWrite("my.app.dart", EXTENSION_API, provider);
  }

  public void testChangeApi_inImplLibrary() {
    compile();

    provider.resetReadsAndWrites();
    someImplLibSource.touchSource("someimpl.dart");
    someImplLibSource.remapSource("someimpl.dart", "someimpl.change.dart");
    compile();

    // Assert that only the interface and implementation library were recompiled.
    didWrite("someimpl.dart", EXTENSION_JS, provider);
    didWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didWrite("some.dart", EXTENSION_JS, provider);
    didWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    // The app should remain untouched.
    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
    didNotWrite("my.dart", EXTENSION_JS, provider);
    didNotWrite("my.app.dart", EXTENSION_API, provider);
    didNotWrite("my.app.dart", EXTENSION_DEPS, provider);

    // As should the api of some.lib.
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
  }

  public void testChangeApi_inInterface() {
    compile();

    provider.resetReadsAndWrites();
    someLibSource.touchSource("some.dart");
    someLibSource.remapSource("some.dart", "some.intfchange.dart");
    compile();

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
    didNotWrite("my.app.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    // Assert we recompiled both some.dart and someimpl.dart, as well as my.dart.
    // (someimpl.dart is recompiled because its interface in some.dart changed)
    didWrite("someimpl.dart", EXTENSION_JS, provider);
    didWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didWrite("some.dart", EXTENSION_JS, provider);
    didWrite("some.lib.dart", EXTENSION_API, provider);
    didWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
  }

  // TODO(jgw): Bug 5319907.
  public void disabled_testFieldHole() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.fillthehole.dart");
    compile();

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);

    // Both myother0.dart and my.dart should be recompiled.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
  }

  public void testMethodHole() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.fillthemethodhole.dart");
    compile("my.dart", "methodHole is a class. Did you mean (new methodHole)?", 48, 5);
  }

  public void testTheNotHole() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother0.dart");
    myAppSource.remapSource("myother0.dart", "myother0.fillthenothole.dart");
    compile();

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("my.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);

    // Only myother0.dart should be recompiled.
    didWrite("myother0.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
  }

  public void testQualifiedFieldRef() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother5.dart");
    myAppSource.remapSource("myother5.dart", "myother5.change.dart");
    compile();

    // Changed the api of Other5, which should force a recompile of my.dart, because the
    // latter includes a qualified reference to one of its instance fields.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother5.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testQualifiedMethodRef() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother6.dart");
    myAppSource.remapSource("myother6.dart", "myother6.change.dart");
    compile();

    // Changed the api of Other6, which should force a recompile of my.dart, because the
    // latter includes a qualified reference to one of its instance methods.
    didWrite("my.dart", EXTENSION_JS, provider);
    didWrite("myother6.dart", EXTENSION_JS, provider);
    didWrite("my.app.dart", EXTENSION_API, provider);
    didWrite("my.app.dart", EXTENSION_DEPS, provider);
    didWrite("my.app.dart", EXTENSION_APP_JS, provider);

    didNotWrite("someimpl.dart", EXTENSION_JS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_DEPS, provider);
    didNotWrite("someimpl.lib.dart", EXTENSION_API, provider);

    didNotWrite("some.dart", EXTENSION_JS, provider);
    didNotWrite("some.lib.dart", EXTENSION_API, provider);
    didNotWrite("some.lib.dart", EXTENSION_DEPS, provider);

    didNotWrite("myother0.dart", EXTENSION_JS, provider);
    didNotWrite("myother1.dart", EXTENSION_JS, provider);
    didNotWrite("myother2.dart", EXTENSION_JS, provider);
  }

  public void testRemoveDepClass() {
    compile();

    provider.resetReadsAndWrites();
    myAppSource.touchSource("myother5.dart");
    myAppSource.remapSource("myother5.dart", "myother5.change.dart");
    myAppSource.touchSource("myother6.dart");
    myAppSource.remapSource("myother6.dart", "myother6.removeclass.dart");
    compile();

    // TODO
  }

  public void testMergeFiles() throws URISyntaxException {
    compile();

    MockBundleLibrarySource myMergedAppSource = new MockBundleLibrarySource(
      IncrementalCompilationTest.class.getClassLoader(),
      TEST_BASE_PATH, "my.merged.app.dart", "my.app.dart");

    compile(myMergedAppSource, null);
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

  private void didWrite(String sourceName, String extension, IncMockArtifactProvider provider) {
    String spec = sourceName + "/" + extension;
    assertTrue("Expected write: " + spec, provider.writes.contains(spec));
  }

  private void didNotWrite(String sourceName, String extension, IncMockArtifactProvider provider) {
    String spec = sourceName + "/" + extension;
    assertFalse("Didn't expect write: " + spec, provider.writes.contains(spec));
  }
}
