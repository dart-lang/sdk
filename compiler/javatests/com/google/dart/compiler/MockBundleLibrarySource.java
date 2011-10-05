// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.Reader;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * A mock application source that uses resources bundled in the classpath, along with methods for
 * remapping sources and modifying their timestamps.
 */
public class MockBundleLibrarySource extends UrlLibrarySource implements LibrarySource {

  private class NonexistentDartSource implements DartSource {
    private final String relPath;

    public NonexistentDartSource(String relPath) {
      this.relPath = relPath;
    }

    @Override
    public boolean exists() {
      return false;
    }

    @Override
    public long getLastModified() {
      return 0;
    }

    @Override
    public String getName() {
      return relPath;
    }

    @Override
    public Reader getSourceReader() throws IOException {
      throw new FileNotFoundException();
    }

    @Override
    public URI getUri() {
      try {
        return new URI(relPath);
      } catch (URISyntaxException e) {
        throw new AssertionError(e.getMessage());
      }
    }

    @Override
    public LibrarySource getLibrary() {
      return MockBundleLibrarySource.this;
    }

    @Override
    public String getRelativePath() {
      return relPath;
    }
  }

  private final String basePath;
  private final ClassLoader loader;
  private final String libName;

  private final Map<String, MockBundleLibrarySource> imports =
      new HashMap<String, MockBundleLibrarySource>();

  /**
   * Source remappings. Each key identifies the name of a source file that will be remapped to an
   * alternate source file in {@link #getSourceFor(String)}.
   */
  private final Map<String, String> sourceRemapping = new HashMap<String, String>();
  private final Set<String> sourceTimestamps = new HashSet<String>();

  public MockBundleLibrarySource(ClassLoader loader, String basePath, String libName)
      throws URISyntaxException {
    this(loader, basePath, libName, libName);
  }

  public MockBundleLibrarySource(ClassLoader loader, String basePath, String libName,
      String altName) throws URISyntaxException {
    super(loader.getResource(basePath + libName).toURI());
    this.loader = loader;
    this.basePath = basePath;
    this.libName = altName;
  }

  @Override
  public MockBundleLibrarySource getImportFor(String relPath) {
    MockBundleLibrarySource libSrc = imports.get(relPath);
    if (libSrc == null) {
      try {
        libSrc = new MockBundleLibrarySource(loader, basePath, relPath);
      } catch (URISyntaxException e) {
        throw new AssertionError();
      }
      imports.put(relPath, libSrc);
    }
    return libSrc;
  }

  @Override
  public DartSource getSourceFor(final String relPath) {
    String remap = sourceRemapping.get(relPath);
    final boolean touched = sourceTimestamps.contains(relPath);

    String fullPath = basePath + ((remap != null) ? remap : relPath);
    URI uri;
    try {
      URL url = loader.getResource(fullPath);
      if (url == null) {
        return new NonexistentDartSource(relPath);
      }

      uri = url.toURI();
    } catch (URISyntaxException e) {
      throw new AssertionError();
    }

    return new UrlDartSource(uri, relPath, this) {
      @Override
      public long getLastModified() {
        if (touched) {
          return new Date().getTime();
        }
        return super.getLastModified();
      }

      @Override
      public String getName() {
        return relPath;
      }
    };
  }

  @Override
  public String getName() {
    return libName;
  }

  /**
   * Remaps the given source to an alternate. This allows testing of changes to source contents.
   * Note that you'll still need to call {@link #touchSource(String)} to cause it to be recompiled.
   */
  public void remapSource(String relPath, String remappedRelPath) {
    sourceRemapping.put(relPath, remappedRelPath);
  }

  /**
   * Removes the given source. Any attempt to read it will result in an NPE.
   */
  public void removeSource(String relPath) {
    sourceRemapping.put(relPath, "does/not/exist");
  }

  /**
   * Touches the given source file, forcing a recompile.
   */
  public void touchSource(String relPath) {
    sourceTimestamps.add(relPath);
  }

  /**
   * Clears all remappings and source timestamps.
   */
  public void resetRemappings() {
    sourceRemapping.clear();
    sourceTimestamps.clear();
  }
}
