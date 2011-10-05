// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.testing.TestCompilerConfiguration;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.testing.TestDartArtifactProvider;
import com.google.dart.compiler.testing.TestLibrarySource;
import com.google.dart.compiler.util.DartSourceString;

import junit.framework.TestCase;

import java.io.IOException;

public class DeltaAnalyzerTest extends TestCase {
  private final TestCompilerConfiguration config = new TestCompilerConfiguration();
  private final DartCompilerListener listener = new TestCompilerContext();
  private final DartArtifactProvider provider = new TestDartArtifactProvider();

  public void testNoChangeSingleFile() throws IOException {
    TestLibrarySource librarySource = new TestLibrarySource(getName());
    librarySource.addSource("before.dart",
                            "class Foo {}",
                            "m() {}");
    DartUnit change = analyzeNoChange(librarySource);
    assertEquals(2, change.getTopLevelNodes().size());
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getSymbol();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
    MethodElement method = (MethodElement) change.getTopLevelNodes().get(1).getSymbol();
    assertNotNull(method);
    assertEquals("m", method.getName());
  }

  public void testNoChangeTwoFiles() throws IOException {
    TestLibrarySource librarySource = new TestLibrarySource(getName());
    librarySource.addSource("before.dart",
                            "class Foo extends Bar {}",
                            "m() {}");
    librarySource.addSource("common.dart",
                            "class Bar {}");
    DartUnit change = analyzeNoChange(librarySource);
    assertEquals(2, change.getTopLevelNodes().size());
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getSymbol();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
    assertEquals("Bar", cls.getSupertype().toString());
    MethodElement method = (MethodElement) change.getTopLevelNodes().get(1).getSymbol();
    assertNotNull(method);
    assertEquals("m", method.getName());
  }

  public void testChangeSingleFile() throws IOException {
    TestLibrarySource librarySource = new TestLibrarySource(getName());
    librarySource.addSource("before.dart",
                            "class Foo {}",
                            "m() {}");
    DartSource sourceBefore = librarySource.getSourceFor("before.dart");
    DartSource sourceAfter = new DartSourceString("after.dart", "class Foo {}");
    DartUnit change = analyze(librarySource, sourceBefore, sourceAfter);
    assertEquals(1, change.getTopLevelNodes().size());
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getSymbol();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
  }

  public void testChangeTwoFiles() throws IOException {
    TestLibrarySource librarySource = new TestLibrarySource(getName());
    librarySource.addSource("before.dart",
                            "class Foo extends Bar {}",
                            "m() {}");
    librarySource.addSource("common.dart",
                            "class Bar {}");
    DartSource sourceBefore = librarySource.getSourceFor("before.dart");
    DartSource sourceAfter = new DartSourceString("after.dart", "class Foo extends Bar {}");
    DartUnit change = analyze(librarySource, sourceBefore, sourceAfter);
    assertEquals(1, change.getTopLevelNodes().size());
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getSymbol();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
    assertEquals("Bar", cls.getSupertype().toString());
  }

  private DartUnit analyzeNoChange(LibrarySource librarySource) throws IOException {
    DartSource sourceBefore = librarySource.getSourceFor("before.dart");
    DartSource sourceAfter = sourceBefore;
    return analyze(librarySource, sourceBefore, sourceAfter);
  }

  private DartUnit analyze(LibrarySource librarySource, DartSource sourceBefore,
                           DartSource sourceAfter) throws IOException {
    LibraryUnit libraryUnit = DartCompiler.analyzeLibrary(librarySource, null,
                                                          config, provider, listener);
    LibraryElement enclosingLibrary = libraryUnit.getElement();
    LibraryElement coreLibrary = libraryUnit.getImports().iterator().next().getElement();
    return (DartUnit) DartCompiler.analyzeDelta(SourceDelta.before(sourceBefore).after(sourceAfter),
                                                enclosingLibrary, coreLibrary,
                                                null, -1, -1, config, listener);
  }
}
