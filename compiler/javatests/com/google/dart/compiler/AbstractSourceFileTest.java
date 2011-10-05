// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.common.LibrarySourceFileTest;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * Shared behavior for creating a temporary file from a java resource
 * to support testing {@link File} based classes
 */
public abstract class AbstractSourceFileTest extends CompilerTestCase {

  private File tempFile;

  /**
   * Create a temporary file to be cleaned up when the test is complete
   *
   * @param filePath the path to the file relative to the test class
   * @return the temporary file
   */
  protected File createTempFile(String filePath) throws IOException {
    String source = readUrl(inputUrlFor(LibrarySourceFileTest.class, filePath));
    return createTempFile(filePath, source);
  }

  protected File createTempFile(String filePath, String source) throws IOException {
    String fileExt = filePath.substring(filePath.lastIndexOf('.'));
    String fileName = filePath.substring(filePath.lastIndexOf('/') + 1,
        filePath.length() - fileExt.length());
    tempFile = File.createTempFile(fileName, fileExt);
    FileWriter writer = new FileWriter(tempFile);
    writer.write(source);
    writer.close();
    return tempFile;
  }

  /**
   * Delete the temporary file if it was created.
   *
   * @see junit.framework.TestCase#tearDown()
   */
  @Override
  protected void tearDown() throws Exception {
    if (tempFile != null) {
      tempFile.delete();
    }
    super.tearDown();
  }

}
