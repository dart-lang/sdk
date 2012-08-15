// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.common.collect.Sets;
import com.google.dart.compiler.AbstractSourceFileTest;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.parser.DartParser;

import java.io.File;
import java.io.IOException;
import java.util.Iterator;

/**
 * Tests {@link LibrarySource}
 */
public class LibrarySourceFileTest extends AbstractSourceFileTest {
  private LibraryUnit libUnit;

  public void testGetImports() throws IOException {
    LibraryUnit libUnit = getLibraryUnit("LibrarySourceFileTest.dart");
    Iterable<LibraryNode> imports = libUnit.getImportPaths();
    assertFalse(imports.iterator().hasNext());
  }

  public void testGetAppImports() throws IOException {
    LibraryUnit appUnit = getLibraryUnit("ApplicationSourceFileTest.dart");
    Iterable<LibraryNode> imports = appUnit.getImportPaths();
    Iterator<LibraryNode> iter = imports.iterator();
    assertEquals("somedir/somelib.dart", iter.next().getText());
    assertFalse(iter.hasNext());
  }

  public void testGetSources() throws IOException {
    LibraryUnit libUnit = getLibraryUnit("LibrarySourceFileTest.dart");
    Iterable<LibraryNode> sources = libUnit.getSourcePaths();
    Iterator<LibraryNode> iter = sources.iterator();
    assertEquals("OneSourceFile.dart", iter.next().getText());
    assertEquals("Source2.dart", iter.next().getText());
    assertEquals("subdir/Source3.dart", iter.next().getText());
    assertEquals(libUnit.getSelfSourcePath(), iter.next());
    assertFalse(iter.hasNext());
  }

  public void testGetAppSources() throws IOException {
    LibraryUnit appUnit = getLibraryUnit("ApplicationSourceFileTest.dart");
    Iterable<LibraryNode> paths = appUnit.getSourcePaths();
    Iterator<LibraryNode> iter = paths.iterator();
    assertEquals("MyFirstApp.dart", iter.next().getText());
    assertEquals("AnotherSource2.dart", iter.next().getText());
    assertEquals("subdir2/Source3x.dart", iter.next().getText());
    assertEquals(libUnit.getSelfSourcePath(), iter.next());
    assertFalse(iter.hasNext());
  }

  /**
   * Answer the {@link LibraryUnit} on which tests are performed
   *
   * @param filePath the path to the file relative to the test class
   * @return the library unit (not <code>null</code>)
   */
  protected LibraryUnit getLibraryUnit(String filePath) throws IOException {
    File tempFile = createTempFile(filePath);
    return getLibraryUnit(tempFile);
  }

  protected LibraryUnit getLibraryUnit(String filePath, String source) throws IOException {
    File tempFile = createTempFile(filePath, source);
    return getLibraryUnit(tempFile);
  }

  protected LibraryUnit getLibraryUnit(File file) {
    if (libUnit == null) {
      UrlLibrarySource lib = new UrlLibrarySource(file);

      DartCompilerListener listener = new DartCompilerListener.Empty() {
        @Override
        public void onError(DartCompilationError event) {
          // Ignore warnings when testing.
          if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING) {
            return;
          }
          // Rethrow error.
          throw new RuntimeException(event.getMessage());
        }
      };

      try {
        libUnit = new DartParser(
            lib,
            DartParser.read(lib),
            false,
            Sets.<String>newHashSet(),
            listener,
            null).preProcessLibraryDirectives(lib);
      } catch (IOException ioEx) {
        libUnit = null;
      }
    }
    return libUnit;
  }
}
