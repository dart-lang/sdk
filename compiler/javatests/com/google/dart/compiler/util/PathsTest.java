// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.util;

import junit.framework.TestCase;

import java.io.File;
import java.net.URI;

public class PathsTest extends TestCase {

  public void testRelativePathToFile_inChildDir_1() {
    testPathToFile("mylib.lib", "childDir/other.lib", "childDir/other.lib");
  }

  public void testRelativePathToFile_inChildDir_2() {
    testPathToFile("dir/mylib.lib", "childDir/other.lib", "dir/childDir/other.lib");
  }

  public void testRelativePathToFile_inParentDir_1() {
    testPathToFile("mylib.lib", "../other.lib", "../other.lib");
  }

  public void testRelativePathToFile_inParentDir_2() {
    testPathToFile("dir/mylib.lib", "../other.lib", "other.lib");
  }

  public void testRelativePathToFile_inSameDir_1() {
    testPathToFile("mylib.lib", "other.lib", "other.lib");
  }

  public void testRelativePathToFile_inSameDir_2() {
    testPathToFile("dir/mylib.lib", "other.lib", "dir/other.lib");
  }

  public void testRelativePathToFile_inSiblingDir_1() {
    testPathToFile("mylib.lib", "../alt/other.lib", "../alt/other.lib");
  }

  public void testRelativePathToFile_inSiblingDir_2() {
    testPathToFile("dir/mylib.lib", "../alt/other.lib", "alt/other.lib");
  }

  private void testPathToFile(String baseFilePath, String relPath,
      String expectedPath) {
    
    File baseFile1 = new File(baseFilePath);
    File actual1 = Paths.relativePathToFile(baseFile1, relPath);
    String expectedPath1 = expectedPath;
    assertEquals(expectedPath1, actual1.getPath());
    
    File baseFile2 = baseFile1.getAbsoluteFile();
    File actual2 = Paths.relativePathToFile(baseFile2, relPath);
    String expectedPath2 = URI.create(actual1.getAbsolutePath()).normalize().getPath();
    assertEquals(expectedPath2, actual2.getPath());
  }

  //==========================================================================

  public void testRelativePathFor_inChildDir_1() {
    testPathFor("mylib.lib", "childDir/other.lib", "childDir/other.lib");
  }

  public void testRelativePathFor_inChildDir_2() {
    testPathFor("dir/mylib.lib", "dir/childDir/other.lib", "childDir/other.lib");
  }

  public void testRelativePathFor_inParentDir_1() {
    testPathFor("mylib.lib", "../other.lib", "../other.lib");
  }

  public void testRelativePathFor_inParentDir_2() {
    testPathFor("dir/mylib.lib", "other.lib", "../other.lib");
  }

  public void testRelativePathFor_inParentDir_3() {
    testPathFor("grandDir/dir/mylib.lib", "grandDir/other.lib", "../other.lib");
  }

  public void testRelativePathFor_inSameDir_1() {
    testPathFor("mylib.lib", "other.lib", "other.lib");
  }

  public void testRelativePathFor_inSameDir_2() {
    testPathFor("dir/mylib.lib", "dir/other.lib", "other.lib");
  }

  public void testRelativePathFor_inSameDir_3() {
    testPathFor("grandDir/dir/mylib.lib", "grandDir/dir/other.lib", "other.lib");
  }

  public void testRelativePathFor_inSameDir_4() {
    testPathFor("grandDir/dir/amylib.lib", "grandDir/dir/aother.lib", "aother.lib");
  }

  public void testRelativePathFor_inSameDir_5() {
    testPathFor("grandDir/dir/abmylib.lib", "grandDir/dir/abother.lib", "abother.lib");
  }

  public void testRelativePathFor_inSiblingDir_1() {
    testPathFor("mylib.lib", "../otherdir/other.lib", "../otherdir/other.lib");
  }

  public void testRelativePathFor_inSiblingDir_2() {
    testPathFor("dir/mylib.lib", "otherdir/other.lib", "../otherdir/other.lib");
  }

  public void testRelativePathFor_inSiblingDir_3() {
    testPathFor("grandDir/dir/mylib.lib", "grandDir/otherdir/other.lib", "../otherdir/other.lib");
  }

  public void testRelativePathFor_inSiblingDir_4() {
    testPathFor("src/mylib.lib", "src-dir/other.lib", "../src-dir/other.lib");
  }

  private void testPathFor(String baseFilePath, String relFilePath,
      String expected) {
    
    File baseFile1 = new File(baseFilePath);
    File relativeFile1 = new File(relFilePath);
    String actual1 = Paths.relativePathFor(baseFile1, relativeFile1);
    assertEquals(expected, actual1);
    
    File baseFile2 = baseFile1.getAbsoluteFile();
    File relativeFile2 = relativeFile1.getAbsoluteFile();
    String actual2 = Paths.relativePathFor(baseFile2, relativeFile2);
    assertEquals(expected, actual2);
  }

}
