// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.base.Joiner;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.end2end.inc.MemoryLibrarySource;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.testing.TestCompilerConfiguration;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.testing.TestDartArtifactProvider;
import com.google.dart.compiler.util.DartSourceString;

import junit.framework.TestCase;

import java.io.IOException;

public class DeltaAnalyzerTest extends TestCase {
  private final TestCompilerConfiguration config = new TestCompilerConfiguration();
  private final DartCompilerListener listener = new TestCompilerContext();
  private final DartArtifactProvider provider = new TestDartArtifactProvider();

  public void testNoChangeSingleFile() throws IOException {
    MemoryLibrarySource librarySource = new MemoryLibrarySource("App.dart");
    librarySource.setContent("App.dart", "library App; part 'before.dart';");
    librarySource.setContent("before.dart",
        Joiner.on("\n").join(new String[] {
                            "part of App;",
                            "class Foo {}",
                            "m() {}"}));
    DartUnit change = analyzeNoChange(librarySource);
    assertEquals(2, change.getTopLevelNodes().size());
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getElement();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
    Element element = change.getLibrary().getElement().lookupLocalElement("Foo");
    assertEquals(cls, element);
    MethodElement method = (MethodElement) change.getTopLevelNodes().get(1).getElement();
    assertNotNull(method);
    assertEquals("m", method.getName());
    element = change.getLibrary().getElement().lookupLocalElement("m");
    assertSame(method, element);
  }

  public void testNoChangeTwoFiles() throws IOException {
    MemoryLibrarySource librarySource = new MemoryLibrarySource("App.dart");
    librarySource.setContent("App.dart", "library App; part 'before.dart'; part 'common.dart';");
    librarySource.setContent("before.dart",
        Joiner.on("\n").join(new String[] {
                            "part of App;",
                            "class Foo extends Bar {}",
                            "m() {}"}));
    librarySource.setContent("common.dart",
        Joiner.on("\n").join(new String[] {
                            "part of App;",
                            "class Bar {}"}));
    DartUnit change = analyzeNoChange(librarySource);
    assertEquals(2, change.getTopLevelNodes().size());
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getElement();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
    assertNotNull(change.getLibrary().getElement().lookupLocalElement("Foo"));
    assertEquals("Bar", cls.getSupertype().toString());
    assertNotNull(change.getLibrary().getElement().lookupLocalElement("Bar"));
    MethodElement method = (MethodElement) change.getTopLevelNodes().get(1).getElement();
    assertNotNull(method);
    assertEquals("m", method.getName());
    Element element = change.getLibrary().getElement().lookupLocalElement("m");
    assertSame(method, element);
  }

  public void testChangeSingleFile() throws IOException {
    MemoryLibrarySource librarySource = new MemoryLibrarySource("App.dart");
    librarySource.setContent("App.dart", "library App;");
    librarySource.setContent(
        "before.dart",
        Joiner.on("\n").join(new String[] {"part of App;", "class Foo {}", "m() {}"}));
    DartSource sourceBefore = librarySource.getSourceFor("before.dart");
    DartSource sourceAfter = new DartSourceString("after.dart", Joiner.on("\n").join(
        new String[] {"part of App;", "class Foo {}", ""}));
    DartUnit change = analyze(librarySource, sourceBefore, sourceAfter);
    assertEquals(1, change.getTopLevelNodes().size());
    Element element = change.getLibrary().getElement().lookupLocalElement("m");
    assertNull(element);
    element = change.getLibrary().getElement().lookupLocalElement("Foo");
    assertNotNull(element);
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getElement();
    assertEquals("Foo", cls.getName());
    assertSame(cls, element);
  }

  public void testChangeTwoFiles() throws IOException {
    MemoryLibrarySource librarySource = new MemoryLibrarySource("App.dart");
    librarySource.setContent("App.dart", "library App; part 'before.dart'; part 'common.dart';");
    librarySource.setContent("before.dart",
        Joiner.on("\n").join(new String[] {
                            "part of App;",
                            "class Foo extends Bar {}",
                            "m() {}"}));
    librarySource.setContent("common.dart",
        Joiner.on("\n").join(new String[] {
                            "part of App;",
                            "class Bar {}"}));
    DartSource sourceBefore = librarySource.getSourceFor("before.dart");
    DartSource sourceAfter = new DartSourceString("after.dart", "part of App; class Foo extends Bar {}");
    DartUnit change = analyze(librarySource, sourceBefore, sourceAfter);
    assertEquals(1, change.getTopLevelNodes().size());
    assertNull(change.getLibrary().getElement().lookupLocalElement("m"));
    ClassElement cls = (ClassElement) change.getTopLevelNodes().get(0).getElement();
    assertNotNull(cls);
    assertEquals("Foo", cls.getName());
    assertEquals("Bar", cls.getSupertype().toString());
    Element element = change.getLibrary().getElement().lookupLocalElement("Foo");
    assertSame(cls, element);
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
    LibraryElement coreLibrary = libraryUnit.getImportedLibraries().iterator().next().getElement();
    return (DartUnit) DartCompiler.analyzeDelta(SourceDelta.before(sourceBefore).after(sourceAfter),
                                                enclosingLibrary, coreLibrary,
                                                null, -1, -1, config, listener);
  }
}
