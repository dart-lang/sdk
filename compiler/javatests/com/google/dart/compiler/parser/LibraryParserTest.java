// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;

import junit.framework.TestCase;

import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * Tests for parsing library directives from a dart file.
 */
public class LibraryParserTest extends TestCase {

  static class TestLibrarySource implements LibrarySource {
    private final String source;

    public TestLibrarySource(String source) {
      this.source = source;
    }

    @Override
    public String getUniqueIdentifier() {
      return getName();
    }

    @Override
    public URI getUri() {
      try {
        return new URI(getName());
      } catch (URISyntaxException e) {
        throw new RuntimeException(e);
      }
    }

    @Override
    public Reader getSourceReader() {
      return new StringReader(source);
    }

    @Override
    public String getName() {
      return "test.dart";
    }

    @Override
    public boolean exists() {
      return true;
    }

    @Override
    public long getLastModified() {
      return 0;
    }

    @Override
    public DartSource getSourceFor(String relPath) {
      return null;
    }

    @Override
    public LibrarySource getImportFor(String relPath) {
      return null;
    }
  }

  public void testLibrary() {
    // "library { import = ['foo.lib', 'bar.lib'] source = ['this.dart', 'that.dart'] }";
    String text =
        "#library(\"testLibrary\");\n" 
      + "#import(\"foo.dart\");\n" 
      + "#import(\"bar.dart\");\n"
      + "#source(\"this.dart\");\n" 
      + "#source(\"that.dart\");\n";

    LibraryUnit unit = parse(text);

    assertHasImport(unit, "foo.dart");
    assertHasImport(unit, "bar.dart");
    assertHasSource(unit, "this.dart");
    assertHasSource(unit, "that.dart");
  }

  public void testNative() {
      // "library { import = ['foo.lib'] source = ['this.dart'] native = ['impl.js'] }";
    String text =
        "#library(\"testLibrary\");\n" 
      + "#import(\"foo.dart\");\n" 
      + "#source(\"this.dart\");\n" 
      + "#native(\"impl.js\");\n";
      
    LibraryUnit unit = parse(text);

    assertHasImport(unit, "foo.dart");
    assertHasSource(unit, "this.dart");
    assertHasNative(unit, "impl.js");
  }

  public void testImportPrefix() {
//      "library { import = [foo:'foo.lib', 'bar.lib'] source = ['this.dart', 'that.dart'] }";
    String text =
        "#library(\"testLibrary\");\n" 
      + "#import(\"foo.dart\", prefix:\"foo\");\n" 
      + "#import(\"bar.dart\");\n" 
      + "#source(\"this.dart\");\n" 
      + "#native(\"impl.js\");\n";
    LibraryUnit unit = parse(text);

    assertHasImport(unit, "foo.dart", "foo");
    assertHasImport(unit, "bar.dart");
    assertHasSource(unit, "this.dart");
    assertHasNative(unit, "impl.js");
  }

  private void assertHasImport(LibraryUnit unit, String name) {
    assertHas(unit.getImportPaths(), name);
  }

  private void assertHasImport(LibraryUnit unit, String name, String prefix) {
    assertHas(unit.getImportPaths(), name, prefix);
  }

  private void assertHasSource(LibraryUnit unit, String name) {
    assertHas(unit.getSourcePaths(), name);
  }

  private void assertHasNative(LibraryUnit unit, String name) {
    assertHas(unit.getNativePaths(), name);
  }

  private void assertHas(Iterable<LibraryNode> nodes, String name) {
    assertHas(nodes, name, null);
  }

  private void assertHas(Iterable<LibraryNode> nodes, String name, String prefix) {
    for (LibraryNode node : nodes) {
      if (node.getText().equals(name)) {
        if ((prefix != null) && !node.getPrefix().equals(prefix)) {
          break;
        }
        return;
      }
    }
    fail("Missing " + ((prefix != null) ? (prefix + " : ") : "") + name);
  }

  private LibraryUnit parse(String text, Object... errors) {
    TestLibrarySource source = new TestLibrarySource(text);
    DartCompilerListenerTest listener = new DartCompilerListenerTest(source.getName(), errors);
    LibraryUnit unit = new DartParser(
        source,
        text,
        false,
        Sets.<String>newHashSet(),
        listener,
        null).preProcessLibraryDirectives(source);
    listener.checkAllErrorsReported();
    return unit;
  }
}
