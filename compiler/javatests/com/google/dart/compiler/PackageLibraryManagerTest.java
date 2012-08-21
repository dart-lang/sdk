// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import junit.framework.TestCase;

import java.net.URI;

public class PackageLibraryManagerTest extends TestCase {
  /**
   * For FS based {@link URI} the path is not <code>null</code>, for JAR {@link URI} the scheme
   * specific part is not <code>null</code>.
   * 
   * @return the scheme specific path.
   */
  private static String getPath(URI uri) {
    if (uri.getPath() != null && uri.getPath().length() != 0){
      return uri.getPath();
    }
    return uri.getSchemeSpecificPart();
  }

  PackageLibraryManager packageLibraryManager = new PackageLibraryManager();
 

  public void testExpand1() throws Exception {
    URI shortUri = new URI("dart:core");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("dart", fullUri.getScheme());
    assertEquals("core", fullUri.getHost());
    assertTrue(getPath(fullUri).endsWith("/core_runtime.dart"));
  }

  public void testExpand2() throws Exception {
    URI shortUri = new URI("dart:coreimpl");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("dart", fullUri.getScheme());
    assertEquals("coreimpl", fullUri.getHost());
    assertTrue(getPath(fullUri).endsWith("/coreimpl_runtime.dart"));
  }

  public void testExpand3() throws Exception {
    URI shortUri = new URI("dart:coreimpl");
    URI fullUri1 = packageLibraryManager.expandRelativeDartUri(shortUri);
    URI fullUri2 = packageLibraryManager.expandRelativeDartUri(fullUri1);
    assertNotNull(fullUri2);
    assertEquals("dart", fullUri2.getScheme());
    assertEquals("coreimpl", fullUri2.getHost());
    assertTrue(getPath(fullUri2).endsWith("/coreimpl_runtime.dart"));
  }

  public void testExpand4() throws Exception {
    URI shortUri = new URI("dart:doesnotexist");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    assertNull(fullUri);
  }

  public void testTranslate1() throws Exception {
    URI shortUri = new URI("dart:core");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = packageLibraryManager.resolveDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file"));
    assertTrue(getPath(translatedURI).endsWith("/core_runtime.dart"));
  }

  public void testTranslate2() throws Exception {
    URI shortUri = new URI("dart:coreimpl");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = packageLibraryManager.resolveDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file"));
    assertTrue(getPath(translatedURI).endsWith("/coreimpl_runtime.dart"));
  }

  public void testTranslate3() throws Exception {
    URI fullUri = new URI("dart://doesnotexist/some/file.dart");
    URI translatedURI = packageLibraryManager.resolveDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file"));
    assertTrue(getPath(translatedURI).endsWith("some/file.dart"));
  }
  
  public void testPackageExpand1() throws Exception {
    URI shortUri = new URI("package:test.dart");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("package", fullUri.getScheme());
    assertEquals("test.dart", fullUri.getHost());
    assertTrue(getPath(fullUri).endsWith("/test.dart"));
  }

  public void testPackageExpand2() throws Exception {
    URI shortUri = new URI("package:test.dart");
    URI fullUri1 = packageLibraryManager.expandRelativeDartUri(shortUri);
    URI fullUri2 = packageLibraryManager.expandRelativeDartUri(fullUri1);
    assertNotNull(fullUri2);
    assertEquals("package", fullUri2.getScheme());
    assertEquals("test.dart", fullUri2.getHost());
    assertTrue(getPath(fullUri2).endsWith("/test.dart"));
  }

  public void testPackageTranslate1() throws Exception {
    URI shortUri = new URI("package:test.dart");
    URI fullUri = packageLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = packageLibraryManager.resolveDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file"));
    assertTrue(getPath(translatedURI).endsWith("/test.dart"));
  }
}
