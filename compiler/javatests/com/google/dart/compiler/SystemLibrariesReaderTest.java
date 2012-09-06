// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import com.google.dart.compiler.SystemLibrariesReader.DartLibrary;

import junit.framework.TestCase;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Map;
import java.util.Map.Entry;

/**
 * Test the {@link SystemLibrariesReader}
 */
public class SystemLibrariesReaderTest extends TestCase {

  
  public void testLibrariesFileExists(){
    File sdkLibPath = new File(PackageLibraryManager.DEFAULT_SDK_PATH, "lib");
    File librariesFile = new File(new File(sdkLibPath, SystemLibrariesReader.INTERNAL_DIR), SystemLibrariesReader.LIBRARIES_FILE);
    assertTrue(librariesFile.exists());
  }
  
  public void testLibrariesFileContent() throws URISyntaxException{
    File sdkLibPath = new File(PackageLibraryManager.DEFAULT_SDK_PATH, "lib");
    URI base = sdkLibPath.toURI();
    SystemLibrariesReader reader = new SystemLibrariesReader(sdkLibPath);
    Map<String, DartLibrary> librariesMap = reader.getLibrariesMap();
    assertTrue(!librariesMap.isEmpty());
    for (Entry<String, DartLibrary> entry : librariesMap.entrySet()) {
      if (entry.getValue().getCategory().equals("Internal")){
        continue;
      }
      String path = entry.getValue().getPath();
      File file = new File(base.resolve(new URI(null, null, path, null, null)).normalize());
      if (!file.exists()) {
        fail("Expected " + entry.getKey() + " path in libraries.dart to exist in SDK"
            + "\n  could not find " + file);
      }
    }

    // check content
    //   "coreimpl": const LibraryInfo(
    //       "coreimpl/coreimpl_runtime.dart",
    //       implementation: true,
    //       dart2jsPath: "compiler/implementation/lib/coreimpl.dart",
    //       dart2jsPatchPath: "compiler/implementation/lib/coreimpl_patch.dart")
    DartLibrary library = librariesMap.get("dart:coreimpl");
    assertTrue(library != null);
    assertEquals("dart:coreimpl",library.getShortName());
    assertTrue(library.isImplementation());
    assertEquals("Shared", library.getCategory());   
    
  }
  
}
