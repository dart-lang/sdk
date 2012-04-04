// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.JarURLConnection;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;
import java.nio.charset.Charset;
import java.util.jar.JarEntry;

/**
 * A {@link Source} backed by a URL (or optionally by a file).
 */
public abstract class UrlSource implements Source {

  private final static String FILE_PROTOCOL = "file";
  private final static String JAR_PROTOCOL = "jar";
  private final static URI CURRENT_DIR = new File(".").toURI().normalize();
  private final static Charset UTF8 = Charset.forName("UTF8");
  private final static URI BASE_URI = CURRENT_DIR;

  private final URI uri;
  private final URI absoluteUri;
  private final URI translatedUri;
  private final boolean shouldCareAboutLastModified;
  private volatile boolean exists = false;
  private volatile long lastModified = -1;
  private volatile boolean propertiesInitialized = false;

  // generally, one or the other of these will be non-null after properties are initialized
  private volatile File sourceFile = null;
  private volatile JarURLConnection jarConn = null;

  protected final SystemLibraryManager systemLibraryManager;

  protected UrlSource(URI uri) {
    this(uri,null);
  }

  protected UrlSource(URI uri, SystemLibraryManager slm) {
    URI expanded = slm != null ? slm.expandRelativeDartUri(uri) : uri;
    if (expanded == null) {
      // import("dart:typo") case
      expanded = uri;
    }
    this.uri = BASE_URI.relativize(expanded.normalize());
    this.absoluteUri = BASE_URI.resolve(expanded);
    this.systemLibraryManager = slm;
    if (SystemLibraryManager.isDartUri(this.uri)) {
      assert slm != null;
      this.shouldCareAboutLastModified = false;
      this.translatedUri = slm.resolveDartUri(this.absoluteUri);
    } else {
      this.shouldCareAboutLastModified = true;
      this.translatedUri = this.absoluteUri;
    }
  }

  protected UrlSource(File file) {
    URI uri = file.toURI().normalize();
    if (!file.exists()) {
      // TODO(jgw): This is a bit ugly, but some of the test infrastructure depends upon
      // non-existant relative files being looked up as classpath resources. This was
      // previously embedded in DartSourceFile.getSourceReader().
      URL url = getClass().getClassLoader().getResource(file.getPath());
      if (url != null) {
        uri = URI.create(url.toString());
      }
    }

    this.uri = BASE_URI.relativize(uri);
    this.translatedUri = this.absoluteUri = BASE_URI.resolve(uri);
    this.systemLibraryManager = null;
    this.shouldCareAboutLastModified = true;
  }

  @Override
  public boolean exists() {
    initProperties();
    return exists;
  }

  @Override
  public long getLastModified() {
    initProperties();
    return lastModified;
  }

  @Override
  public Reader getSourceReader() throws IOException {
    initProperties();
    if (sourceFile != null) {
      return new InputStreamReader(new FileInputStream(sourceFile), UTF8);
    } else if (jarConn != null) {
      return new InputStreamReader(jarConn.getInputStream(), UTF8);
    }
    // fall back case
    if (translatedUri != null) {
      InputStream stream = translatedUri.toURL().openStream();
      if (stream != null) {
        return new InputStreamReader(stream, UTF8);
      }
    }
    throw new FileNotFoundException(getName());
  }

  @Override
  public String getUniqueIdentifier() {
    return absoluteUri.toString();
  }

  @Override
  public URI getUri() {
    return absoluteUri;
  }

  private void initProperties() {
    if (!propertiesInitialized) {
      synchronized(this) {
        if (!propertiesInitialized) {
          try {
            URI resolvedUri = BASE_URI.resolve(translatedUri);
            String scheme = resolvedUri.getScheme();
            if (scheme == null || FILE_PROTOCOL.equals(scheme)) {
              // Faster than using URLConnection
              File file = new File(resolvedUri);
              lastModified = file.lastModified();
              exists = file.exists();
              sourceFile = file;
            } else {
              try {
                URL url = translatedUri.toURL();
                if (JAR_PROTOCOL.equals(url.getProtocol())) {
                  getJarEntryProperties(url);
                } else {
                  /*
                   * TODO(jbrosenberg): Flesh out the support for other
                   * protocols, like http, etc. Note, calling
                   * URLConnection.getLastModified() can be dangerous, some
                   * URLConnection sub-classes don't have a way to close a
                   * connection opened by this call. Return 0 for now.
                   */
                  lastModified = 0;
                  // Default this to true for now.
                  exists = true;
                }
              } catch (MalformedURLException e) {
                return;
              }
            }
          } finally {
            propertiesInitialized = true;
          }
        }
      }
    }
  }

  private void getJarEntryProperties(URL url) {
    try {
      jarConn = (JarURLConnection) url.openConnection();
      // useCaches is usually set to true by default, but make sure here
      jarConn.setUseCaches(true);
      // See if our entry exists
      JarEntry jarEntry = jarConn.getJarEntry();
      if (jarEntry != null) {
        exists = true;
        if (!shouldCareAboutLastModified) {
          lastModified = 0;
          return;
        }
        // TODO(jbrosenberg): Note the time field for a jarEntry can be
        // unreliable, and is not always required in a jar file. Consider using
        // the timestamp on the jar file itself.
        lastModified = jarEntry.getTime();
      }
      if (!exists) {
        lastModified = -1;
        return;
      }
    } catch (IOException e) {
      exists = false;
      lastModified = -1;
    }
  }
}