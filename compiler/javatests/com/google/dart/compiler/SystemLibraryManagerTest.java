// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import junit.framework.TestCase;

import java.net.URI;

public class SystemLibraryManagerTest extends TestCase {
  SystemLibraryManager systemLibraryManager = new SystemLibraryManager();

  public void testExpand1() throws Exception {
    URI shortUri = new URI("dart:core");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("dart", fullUri.getScheme());
    assertEquals("core", fullUri.getHost());
    assertTrue(getPath(fullUri).endsWith("/core_runtime.dart"));
  }

  public void testExpand2() throws Exception {
    URI shortUri = new URI("dart:coreimpl");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("dart", fullUri.getScheme());
    assertEquals("coreimpl", fullUri.getHost());
    assertTrue(getPath(fullUri).endsWith("/coreimpl_runtime.dart"));
  }

  public void testExpand3() throws Exception {
    URI shortUri = new URI("dart:coreimpl");
    URI fullUri1 = systemLibraryManager.expandRelativeDartUri(shortUri);
    URI fullUri2 = systemLibraryManager.expandRelativeDartUri(fullUri1);
    assertNotNull(fullUri2);
    assertEquals("dart", fullUri2.getScheme());
    assertEquals("coreimpl", fullUri2.getHost());
    assertTrue(getPath(fullUri2).endsWith("/coreimpl_runtime.dart"));
  }

  public void testExpand4() throws Exception {
    URI shortUri = new URI("dart:doesnotexist");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    assertNull(fullUri);
  }

  public void testTranslate1() throws Exception {
    URI shortUri = new URI("dart:core");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = systemLibraryManager.resolveDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file"));
    assertTrue(getPath(translatedURI).endsWith("/core_runtime.dart"));
  }

  public void testTranslate2() throws Exception {
    URI shortUri = new URI("dart:coreimpl");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = systemLibraryManager.resolveDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file"));
    assertTrue(getPath(translatedURI).endsWith("/coreimpl_runtime.dart"));
  }

  public void testTranslate3() throws Exception {
    URI fullUri = new URI("dart://doesnotexist/some/file.dart");
    try {
      URI translatedURI = systemLibraryManager.resolveDartUri(fullUri);
      fail("Expected translate " + fullUri + " to fail, but returned " + translatedURI);
    } catch (RuntimeException e) {
      String message = e.getMessage();
      assertTrue(message.startsWith("No system library"));
      assertTrue(message.contains(fullUri.toString()));
    }
  }

  /**
   * For FS based {@link URI} the path is not <code>null</code>, for JAR {@link URI} the scheme
   * specific part is not <code>null</code>.
   * 
   * @return the scheme specific path.
   */
  private static String getPath(URI uri) {
    if (uri.getPath() != null) {
      return uri.getPath();
    }
    return uri.getSchemeSpecificPart();
  }
}
