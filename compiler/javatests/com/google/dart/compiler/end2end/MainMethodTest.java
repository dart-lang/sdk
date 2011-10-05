// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DefaultLibrarySource;
import com.google.dart.compiler.LibrarySource;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.List;

/**
 * Augment the {@link BasicTests} and {@link End2EndTestCase} by driving the
 * {@link DartCompiler#main(String[])} method.
 */
public class MainMethodTest extends End2EndTestCase {
  private File tempDir;

  /**
   * Sanity check that the {@link DartCompiler#main(String[])} method will
   * compile a single dart file with no lib or app file.
   */
  public void testDartCompiler_main_dartFileOnly() throws Exception {
    runTest("BasicTest.dart");
  }

  @Override
  protected LibrarySource createApplication(List<String> srcs) {
    assert srcs.size() == 1;
    String path = srcs.get(0);
    try {
      File dartFile = writeTempFile("BasicTest.dart", readResource(path));
      return new DefaultLibrarySource(dartFile, null);
    } catch (IOException e) {
      String message = "Failed to compile " + path;
      System.err.println(message);
      e.printStackTrace();
      fail(message + "\n" + e.getMessage());
      return null;
    }
  }

  /**
   * Read the content of a resource stored relative to this class
   *
   * @param fileName the path to the resource relative to this class
   * @return the content
   */
  private String readResource(String fileName) throws IOException {
    return readStream(getClass().getResourceAsStream(fileName));
  }

  /**
   * Read the content of the specified string and close the stream.
   *
   * @param stream the stream to read (not <code>null</code>)
   * @return the content (not <code>null</code>)
   */
  private String readStream(InputStream stream) throws IOException {
    try {
      InputStreamReader reader = new InputStreamReader(stream);
      StringBuilder result = new StringBuilder(2000);
      char[] buf = new char[100];
      while (true) {
        int count = reader.read(buf);
        if (count == -1)
          break;
        result.append(buf, 0, count);
      }
      return result.toString();
    } finally {
      stream.close();
    }
  }

  /**
   * Write the specified source into a temporary file with the specified name in
   * a temporary directory that will be cleaned up at the end of the test.
   *
   * @param fileName the name of the file to be written (not <code>null</code>)
   * @param content the content to be written (not <code>null</code>)
   * @return the file that was written (not <code>null</code>)
   */
  private File writeTempFile(String fileName, String content)
      throws IOException {
    File file = new File(getTempDir(), fileName);
    FileWriter writer = new FileWriter(file);
    try {
      writer.write(content);
    } finally {
      writer.close();
    }
    return file;
  }

  /**
   * Answer a temporary directory for this test that is later cleaned up in
   * {@link #tearDown()}.
   */
  private File getTempDir() throws IOException {
    if (tempDir == null) {
      tempDir = File.createTempFile(getClass().getSimpleName(), null);
      tempDir.delete();
      tempDir.mkdirs();
    }
    return tempDir;
  }

  /**
   * Delete the temporary directory if it exists
   */
  @Override
  protected void tearDown() throws Exception {
    if (tempDir != null) {
      File[] allFiles = tempDir.listFiles();
      for (File file : allFiles) {
        file.delete();
      }
      tempDir.delete();
      tempDir = null;
    }
    super.tearDown();
  }
}
