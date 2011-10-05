// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import junit.framework.TestCase;

import java.net.URI;

public class SystemLibraryManagerTest extends TestCase {
  SystemLibraryManager systemLibraryManager = new SystemLibraryManager();

  public void testExpand1() throws Exception {
    URI shortUri = new URI("dart:core.lib");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("dart", fullUri.getScheme());
    assertEquals("core", fullUri.getHost());
    assertTrue(fullUri.getPath().endsWith("/corelib.lib"));
  }

  public void testExpand2() throws Exception {
    URI shortUri = new URI("dart:coreimpl.lib");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    assertNotNull(fullUri);
    assertEquals("dart", fullUri.getScheme());
    assertEquals("core", fullUri.getHost());
    assertTrue(fullUri.getPath().endsWith("/corelib_impl.lib"));
  }

  public void testExpand3() throws Exception {
    URI shortUri = new URI("dart:coreimpl.lib");
    URI fullUri1 = systemLibraryManager.expandRelativeDartUri(shortUri);
    URI fullUri2 = systemLibraryManager.expandRelativeDartUri(fullUri1);
    assertNotNull(fullUri2);
    assertEquals("dart", fullUri2.getScheme());
    assertEquals("core", fullUri2.getHost());
    assertTrue(fullUri2.getPath().endsWith("/corelib_impl.lib"));
  }

  public void testExpand4() throws Exception {
    URI shortUri = new URI("dart:doesnotexist.lib");
    try {
      URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
      fail("Expected expansion of " + shortUri + " to fail, but returned " + fullUri);
    } catch (RuntimeException e) {
      String message = e.getMessage();
      assertTrue(message.startsWith("No system library"));
      assertTrue(message.contains(shortUri.toString()));
    }
  }

  public void testTranslate1() throws Exception {
    URI shortUri = new URI("dart:core.lib");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = systemLibraryManager.translateDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file") || scheme.equals("jar"));
    assertTrue(translatedURI.getPath().endsWith("/corelib.lib"));
  }

  public void testTranslate2() throws Exception {
    URI shortUri = new URI("dart:coreimpl.lib");
    URI fullUri = systemLibraryManager.expandRelativeDartUri(shortUri);
    URI translatedURI = systemLibraryManager.translateDartUri(fullUri);
    assertNotNull(translatedURI);
    String scheme = translatedURI.getScheme();
    assertTrue(scheme.equals("file") || scheme.equals("jar"));
    assertTrue(translatedURI.getPath().endsWith("/corelib_impl.lib"));
  }

  public void testTranslate3() throws Exception {
    URI fullUri = new URI("dart://doesnotexist/some/file.dart");
    try {
      URI translatedURI = systemLibraryManager.translateDartUri(fullUri);
      fail("Expected translate " + fullUri + " to fail, but returned " + translatedURI);
    } catch (RuntimeException e) {
      String message = e.getMessage();
      assertTrue(message.startsWith("No system library"));
      assertTrue(message.contains(fullUri.toString()));
    }
  }
}
