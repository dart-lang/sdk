// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.end2end.inc;

import static com.google.dart.compiler.DartCompiler.EXTENSION_DEPS;
import static com.google.dart.compiler.DartCompiler.EXTENSION_TIMESTAMP;
import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;
import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import com.google.common.collect.Lists;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;

import junit.framework.AssertionFailedError;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.Writer;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

// TODO(zundel): update this test not to rely on code generation
public class IncrementalCompilation2Test extends CompilerTestCase {
  private static final String APP = "Application.dart";

  private static class IncMockArtifactProvider extends MockArtifactProvider {
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
  private MemoryLibrarySource appSource;
  private long appSourceLastModified = 0;
  private String appSourceContent = makeCode(
      "// filler filler filler filler filler filler filler filler filler filler filler",
      "#library('application');",
      "#source('A.dart');",
      "#source('B.dart');",
      "#source('C.dart');",
      "");
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
    appSource = new MemoryLibrarySource(APP, "<not-used>") {
      @Override
      public long getLastModified() {
        return appSourceLastModified;
      }

      @Override
      public Reader getSourceReader() throws IOException {
        return new StringReader(appSourceContent);
      }
    };
    appSource.setContent("A.dart", "");
    appSource.setContent("B.dart", "");
    appSource.setContent("C.dart", "");
  }

  @Override
  protected void tearDown() {
    config = null;
    provider = null;
    appSource = null;
  }

  /**
   * "not_hole" is referenced using "super" qualifier, so is not affected by declaring top-level
   * field with same name.
   */
  public void test_useQualifiedFieldReference_ignoreTopLevelDeclaration() {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  int not_hole;",
            "}",
            ""));
    appSource.setContent(
        "C.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class B extends A {",
            "  int bar() {",
            "    return super.not_hole;", // qualified reference
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors);
    // Update units and compile.
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "int not_hole;",
            ""));
    compile();
    // TODO(scheglov) Fix this after 1159
    //assertErrors(errors, errEx(ResolverErrorCode.DUPLICATE_LOCAL_VARIABLE_WARNING, -1, 7, 20));
    // B should be compiled because it now conflicts with A.
    // C should not be compiled, because it reference "not_hole" field, not top-level variable.
    didWrite("A.dart", EXTENSION_TIMESTAMP);
    didWrite("B.dart", EXTENSION_TIMESTAMP);
    didNotWrite("C.dart", EXTENSION_TIMESTAMP);
    assertAppBuilt();
  }

  /**
   * Referenced "hole" identifier can not be resolved, but when we declare it in A, then B should be
   * recompiled and error message disappear.
   */
  public void test_useUnresolvedField_recompileOnTopLevelDeclaration() {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  int foo() {",
            "    return hole;", // no such field
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors, errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 4, 12, 4));
    // Update units and compile.
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "int hole;",
            ""));
    compile();
    // A and B should be compiled.
    didWrite("A.dart", EXTENSION_TIMESTAMP);
    didWrite("B.dart", EXTENSION_TIMESTAMP);
    assertAppBuilt();
    // "hole" was filled with top-level field.
    assertErrors(errors);
  }

  /**
   * Test for "hole" feature. If we use unqualified invocation and add/remove top-level method, this
   * should cause compilation of invocation unit.
   */
  public void test_isMethodHole_useUnqualifiedInvocation() throws Exception {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  foo() {}",
            "}",
            ""));
    appSource.setContent(
        "C.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class B extends A {",
            "  int bar() {",
            "    foo();", // unqualified invocation
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors);
    // Declare top-level foo(), now invocation of foo() in B should be bound to this top-level.
    {
      appSource.setContent(
          "A.dart",
          makeCode(
              "// filler filler filler filler filler filler filler filler filler filler filler",
              "foo() {}",
              ""));
      compile();
      // B should be compiled because it also declares foo(), so produces "shadow" conflict.
      // C should be compiled because it has unqualified invocation which was declared in A.
      didWrite("A.dart", EXTENSION_TIMESTAMP);
      didWrite("B.dart", EXTENSION_TIMESTAMP);
      didWrite("C.dart", EXTENSION_TIMESTAMP);
      assertAppBuilt();
    }
    // Wait, because analysis is so fast that may be A will have same time as old artifact.
    Thread.sleep(5);
    // Remove top-level foo(), so invocation of foo() in B should be bound to the super class.
    {
      appSource.setContent("A.dart", "");
      compile();
      // B should be compiled because it also declares foo(), so produces "shadow" conflict.
      // C should be compiled because it has unqualified invocation which was declared in A.
      didWrite("A.dart", EXTENSION_TIMESTAMP);
      didWrite("B.dart", EXTENSION_TIMESTAMP);
      didWrite("C.dart", EXTENSION_TIMESTAMP);
    }
  }

  /**
   * Test for "hole" feature. If we use qualified invocation and add/remove top-level method, this
   * should not cause compilation of invocation unit.
   */
  public void test_notMethodHole_useQualifiedInvocation() {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  foo() {}",
            "}",
            ""));
    appSource.setContent(
        "C.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class B extends A {",
            "  int bar() {",
            "    super.foo();", // qualified invocation
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors);
    // Declare top-level foo(), but it is ignored.
    {
      appSource.setContent(
          "A.dart",
          makeCode(
              "// filler filler filler filler filler filler filler filler filler filler filler",
              "foo() {}",
              ""));
      compile();
      // B should be compiled because it also declares foo(), so produces "shadow" conflict.
      // C should not be compiled because.
      didWrite("A.dart", EXTENSION_TIMESTAMP);
      didWrite("B.dart", EXTENSION_TIMESTAMP);
      didNotWrite("C.dart", EXTENSION_TIMESTAMP);
      assertAppBuilt();
    }
  }

  /**
   * Test for "hole" feature. If we use unqualified access and add/remove top-level field, this
   * should cause compilation of invocation unit.
   */
  public void test_fieldHole_useUnqualifiedAccess() throws Exception {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  var foo;",
            "}",
            ""));
    appSource.setContent(
        "C.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class B extends A {",
            "  int bar() {",
            "    foo = 0;", // unqualified access
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors);
    // Declare top-level "foo", now access to "foo" in B should be bound to this top-level.
    {
      appSource.setContent(
          "A.dart",
          makeCode(
              "// filler filler filler filler filler filler filler filler filler filler filler",
              "var foo;",
              ""));
      compile();
      // B should be compiled because it also declares "foo", so produces "shadow" conflict.
      // C should be compiled because it has unqualified invocation which was declared in A.
      didWrite("A.dart", EXTENSION_TIMESTAMP);
      didWrite("B.dart", EXTENSION_TIMESTAMP);
      didWrite("C.dart", EXTENSION_TIMESTAMP);
      assertAppBuilt();
    }
    // Wait, because analysis is so fast that may be A will have same time as old artifact.
    Thread.sleep(5);
    // Remove top-level "foo", so access to "foo" in B should be bound to the super class.
    {
      appSource.setContent("A.dart", "");
      compile();
      // B should be compiled because it also declares "foo", so produces "shadow" conflict.
      // C should be compiled because it has unqualified access which was declared in A.
      didWrite("A.dart", EXTENSION_TIMESTAMP);
      didWrite("B.dart", EXTENSION_TIMESTAMP);
      didWrite("C.dart", EXTENSION_TIMESTAMP);
    }
  }

  /**
   * Test for "hole" feature. If we use qualified access and add/remove top-level field, this should
   * not cause compilation of invocation unit.
   */
  public void test_fieldHole_useQualifiedAccess() {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  var foo;",
            "}",
            ""));
    appSource.setContent(
        "C.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class B extends A {",
            "  int bar() {",
            "    super.foo = 0;", // qualified access
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors);
    // Declare top-level "foo", but it is ignored.
    {
      appSource.setContent(
          "A.dart",
          makeCode(
              "// filler filler filler filler filler filler filler filler filler filler filler",
              "var foo;",
              ""));
      compile();
      // B should be compiled because it also declares "foo", so produces "shadow" conflict.
      // C should not be compiled because it has qualified access to "foo".
      didWrite("A.dart", EXTENSION_TIMESTAMP);
      didWrite("B.dart", EXTENSION_TIMESTAMP);
      didNotWrite("C.dart", EXTENSION_TIMESTAMP);
      assertAppBuilt();
    }
  }

  public void test_declareTopLevel_conflictWithLocalVariable() {
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "methodB() {",
            "  var symbolDependency_foo;",
            "}"));
    compile();
    assertErrors(errors);
    // Update units and compile.
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "var symbolDependency_foo;"));
    compile();
    // Now there is top-level declarations conflict between A and B.
    // So, B should be compiled.
    didWrite("B.dart", EXTENSION_TIMESTAMP);
    // But application should be build.
    assertAppBuilt();
    // Because B was compiled, it has warning.
    assertErrors(errors, errEx(ResolverErrorCode.DUPLICATE_LOCAL_VARIABLE_WARNING, 3, 7, 20));
  }

  public void test_undeclareTopLevel_conflictWithLocalVariable() {
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "var duplicate;"));
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "bar() {",
            "  var duplicate;",
            "}"));
    compile();
    assertErrors(errors, errEx(ResolverErrorCode.DUPLICATE_LOCAL_VARIABLE_WARNING, 3, 7, 9));
    // Update units and compile.
    appSource.setContent("A.dart", "");
    compile();
    // Top-level declaration in A was removed, so no conflict.
    // So:
    // ... B should be recompiled.
    didWrite("B.dart", EXTENSION_TIMESTAMP);
    // ... but application should be rebuild.
    assertAppBuilt();
    // Because B was recompiled, it has no warning.
    assertErrors(errors);
  }

  /**
   * Removes A, so changes set of top level units and forces compilation.
   */
  public void test_removeOneSource() {
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "var duplicate;"));
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "bar() {",
            "  var duplicate;",
            "}"));
    compile();
    assertErrors(errors, errEx(ResolverErrorCode.DUPLICATE_LOCAL_VARIABLE_WARNING, 3, 7, 9));
    // Exclude A and compile.
    appSourceLastModified++;
    appSourceContent =
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "#library('app');",
            "#source('B.dart');",
            "");
    compile();
    // Now there is top-level declarations conflict between A and B.
    // So:
    // ... B should be recompiled.
    didWrite("B.dart", EXTENSION_TIMESTAMP);
    // ... but application should be rebuild.
    didWrite(APP, EXTENSION_DEPS);
    // Because B was recompiled, it has no warning.
    assertErrors(errors);
  }

  public void test_declareField_conflictWithLocalVariable() {
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "}",
            ""));
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class B extends A {",
            "  foo() {",
            "    var bar;",
            "  }",
            "}",
            ""));
    compile();
    assertErrors(errors);
    // Update units and compile.
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  var bar;",
            "}",
            ""));
    compile();
    // B depends on A class, so compiled.
    didWrite("B.dart", EXTENSION_TIMESTAMP);
    assertAppBuilt();
    // Because B was compiled, it has warning.
    assertErrors(errors, errEx(ResolverErrorCode.DUPLICATE_LOCAL_VARIABLE_WARNING, 4, 9, 3));
  }

  public void test_declareTopLevelVariable_conflictOtherTopLevelVariable() {
    appSource.setContent(
        "A.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "var conflict;",
            ""));
    compile();
    assertErrors(errors);
    // Update units and compile.
    appSource.setContent(
        "B.dart",
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "var conflict;",
            ""));
    compile();
    // A symbols intersect with new B symbols, so we compile A too.
    // Both A and B have errors.
    assertErrors(
        errors,
        errEx("A.dart", ResolverErrorCode.DUPLICATE_TOP_LEVEL_DECLARATION, 2, 5, 8),
        errEx("B.dart", ResolverErrorCode.DUPLICATE_TOP_LEVEL_DECLARATION, 2, 5, 8));
  }

  /**
   * Test that invalid "#import" is reported as any other error between "unitAboutToCompile" and
   * "unitCompiled".
   */
  public void test_reportMissingImportSourcce() throws Exception {
    appSourceContent =
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler filler",
            "#library('app');",
            "#import('dart:noSuchLib.dart');",
            "");
    // Remember errors only between unitAboutToCompile/unitCompiled.
    errors.clear();
    DartCompilerListener listener = new DartCompilerListener.Empty() {
      boolean isCompiling = false;

      @Override
      public void unitAboutToCompile(DartSource source, boolean diet) {
        isCompiling = true;
      }

      @Override
      public void onError(DartCompilationError event) {
        if (isCompiling) {
          errors.add(event);
        }
      }

      @Override
      public void unitCompiled(DartUnit unit) {
        isCompiling = false;
      }
    };
    DartCompiler.compileLib(appSource, config, provider, listener);
    // Check that errors where reported (and in correct time).
    assertErrors(errors, errEx(DartCompilerErrorCode.MISSING_SOURCE, 3, 1, 31));
  }

  private void assertAppBuilt() {
    didWrite(APP, EXTENSION_DEPS);
  }

  private void compile() {
    compile(appSource);
  }

  private void compile(LibrarySource lib) {
    try {
      provider.resetReadsAndWrites();
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
