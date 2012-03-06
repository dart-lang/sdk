// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.jar.JarFile;

/**
 * Manages the collection of {@link SystemLibrary}s.
 */
public class SystemLibraryManager {
  private enum SystemLibraryPath {
    CORE("core", "core", "com/google/dart/corelib/", "corelib.dart", "corelib.jar", true), 
    COREIMPL("core", "coreimpl", "com/google/dart/corelib/", "corelib_impl.dart", "corelib.jar",
        CORE, true), 
    DOM("dom", "dom", "dom/", "dom.dart", "domlib.jar"),
    HTML("html", "html", "html/", "html.dart", "htmllib.jar"),
    JSON("json", "json", "json/", "json.dart", "jsonlib.jar"),
    ISOLATE("isolate", "isolate", "isolate/", "isolate_compiler.dart", "isolatelib.jar");

    final String hostName;
    final SystemLibraryPath base;
    final String shortName;
    final String jar;
    final String lib;
    final boolean failIfMissing;

    SystemLibraryPath(String hostName, String shortName, String path, String file, String jar,
        boolean failIfMissing) {
      this(hostName, shortName, path, file, jar, null, failIfMissing);
    }

    SystemLibraryPath(String hostName, String shortName, String path, String file, String jar) {
      this(hostName, shortName, path, file, jar, null, false);
    }

    SystemLibraryPath(String hostName, String shortName, String path, String file, String jar,
        SystemLibraryPath base, boolean failIfMissing) {
      this.hostName = hostName;
      this.shortName = shortName;
      this.jar = jar;
      this.lib = path + file;
      this.base = base;
      this.failIfMissing = failIfMissing;
    }
  }

  private static final String DART_SCHEME = "dart";
  private static final String DART_SCHEME_SPEC = "dart:";

  // executionFile is used to search for loose files on disk when the system libraries
  // are not on the classpath (e.g. Eclipse)
  private static final File executionFile = new File(SystemLibraryManager.class
      .getProtectionDomain().getCodeSource().getLocation().getPath());

  private HashMap<String, String> expansionMap;
  private Map<String, SystemLibrary> hostMap;

  private SystemLibrary[] libraries;

  public SystemLibraryManager() {
    setLibraries(getDefaultLibraries());
  }

  /**
   * Expand a relative or short URI (e.g. "dart:dom") which is implementation independent to its
   * full URI (e.g. "dart://dom/com/google/dart/domlib/dom.dart") and then translate that URI to
   * either a "file:" or "jar:" URI (e.g.
   * "jar:file:/some/install/director/dom.jar!/com/google/dart/domlib/dom.dart").
   *
   * @param uri the original URI
   * @return the expanded and translated URI, which may be <code>null</code> and may not exist
   * @exception RuntimeException if the URI is a "dart" scheme, but does not map to a defined system
   *     library
   */
  public URI resolveDartUri(URI uri) {
    return translateDartUri(expandRelativeDartUri(uri));
  }

  /**
   * Translate the URI from dart://[host]/[pathToLib] (e.g. dart://dom/dom.dart)
   * to either a "file:" or "jar:" URI (e.g. "jar:file:/some/install/director/dom.jar!/dom.dart")
   *
   * @param uri the original URI
   * @return the translated URI, which may be <code>null</code> and may not exist
   * @exception RuntimeException if the URI is a "dart" scheme,
   *     but does not map to a defined system library
   */
  public URI translateDartUri(URI uri) {
    if (isDartUri(uri)) {
      String host = uri.getHost();
      SystemLibrary library = hostMap.get(host);
      if (library == null) {
        throw new RuntimeException("No system library defined for " + uri);
      }
      return library.translateUri(uri);
    }

    return uri;
  }

  /**
   * Expand a relative or short URI (e.g. "dart:dom") which is implementation independent to its
   * full URI (e.g. "dart://dom/com/google/dart/domlib/dom.dart").
   * 
   * @param uri the relative URI
   * @return the expanded URI 
   *  or the original URI if it could not be expanded 
   *  or null if the uri is of the form "dart:<libname>" but does not correspond to a system library
   */
  public URI expandRelativeDartUri(URI uri) throws AssertionError {
    if (isDartUri(uri)) {
      String host = uri.getHost();
      if (host == null) {
        String spec = uri.getSchemeSpecificPart();
        String replacement = expansionMap.get(spec);
        if (replacement != null) {
          try {
            uri = new URI(DART_SCHEME + ":" + replacement);
          } catch (URISyntaxException e) {
            throw new AssertionError();
          }
        } else {
          return null;
        }
      }
    }
    return uri;
  }

  /**
   * Answer <code>true</code> if the specified URI has a "dart" scheme
   */
  public static boolean isDartUri(URI uri) {
    return uri != null && DART_SCHEME.equals(uri.getScheme());
  }

  /**
   * Answer <code>true</code> if the string is a dart spec
   */
  public static boolean isDartSpec(String spec) {
    return spec != null && spec.startsWith(DART_SCHEME_SPEC);
  }

  /**
   * Register system libraries for the "dart:" protocol such that dart:[shortLibName] (e.g.
   * "dart:dom") will automatically be expanded to dart://[host]/[pathToLib] (e.g.
   * dart://dom/dom.dart)
   */
  private void setLibraries(SystemLibrary[] newLibraries) {
    libraries = newLibraries;
    hostMap = new HashMap<String, SystemLibrary>();
    expansionMap = new HashMap<String, String>();
    for (SystemLibrary library : libraries) {
      hostMap.put(library.getHost(), library);
      expansionMap.put(library.getShortName(),
          "//" + library.getHost() + "/" + library.getPathToLib());
    }
  }

  private File getResource(String name, boolean failOnMissing) {
    URL baseUrl = SystemLibraryManager.class.getClassLoader().getResource(name);
    if (baseUrl == null) {
      if (!failOnMissing) {
        return null;
      }
      throw new RuntimeException("Failed to find the system library: " + name);
    }
    return resolveResource(baseUrl, name);
  }

  static private File resolveResource(URL baseUrl, String name) {
    if (baseUrl == null) {
      return null;
    }
    File coreDirOrZip = null;
    String protocol = baseUrl.getProtocol();
    String path = baseUrl.getPath();
    if ("file".equals(protocol)) {
      coreDirOrZip = new File(path.substring(0, path.lastIndexOf(name)));
    } else if ("jar".equals(protocol)) {
      // jar:file://www.foo.com/bar/baz.jar!/com/google/some.class
      if (path.startsWith("file:")) {
        int index = path.indexOf('!');
        coreDirOrZip = new File(path.substring(5, index > 0 ? index : path.length()));
      }
    }
    if (coreDirOrZip == null) {
      throw new RuntimeException("Failed to find system library in " + baseUrl);
    }
    if (!coreDirOrZip.exists()) {
      throw new RuntimeException("System library container does not exist " + coreDirOrZip
          + "\n  from " + baseUrl);
    }
    return coreDirOrZip;
  }

  private File searchForResource(String searchPath, String libraryName, boolean failOnMissing) {
    URL urlPath = null;
    File sourcePath = new File(searchPath);

    /* The source can be a directory or a jar file. Search both for our library. */
    if (sourcePath.isDirectory()) {
      File foundLibrary = new File(sourcePath.getPath() + File.separator + libraryName);
      if (!foundLibrary.exists()) {
        if (failOnMissing) {
          throw new RuntimeException("Failed to find system library " + libraryName + " with "
              + sourcePath.toString());
        }
        return null;
      }
      try {
        urlPath = foundLibrary.toURI().toURL();
      } catch (MalformedURLException e) {
        throw new RuntimeException(e);
      }
    } else if (sourcePath.isFile() && sourcePath.toString().endsWith(".jar")) {
      // Support for jar only right now...
      JarFile jarFile = null;
      try {
        jarFile = new JarFile(sourcePath);
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
      if (null != jarFile.getJarEntry(libraryName)) {
        String path = "jar:file:" + sourcePath.getPath() + "!/" + libraryName;
        try {
          urlPath = new URL(path);
        } catch (MalformedURLException e) {
          throw new RuntimeException(e);
        }
      } else {
        if (failOnMissing) {
          throw new RuntimeException("Failed to find system library " + libraryName + " with "
              + sourcePath.getPath());
        }
        return null;
      }
    }

    File foundLibrary = resolveResource(urlPath, libraryName);
    if (foundLibrary == null && failOnMissing) {
      throw new RuntimeException("Failed to find system library " + libraryName + " with "
          + sourcePath.getPath());
    }
    return foundLibrary;
  }

  protected SystemLibrary locateSystemLibrary(SystemLibraryPath path) {
    // First, check for jars on the class path
    File libraryDirOrZip = getResource(path.lib, path.failIfMissing);

    // TODO(codefu): This is a hack. To keep Eclipse happy and to find the
    // sources, we hard code this path. In the future, when the libraries are
    // all gathered into a common "lib/" path, we can search from there.
    if (libraryDirOrZip == null) {
      // Eclipse's executionPath should be a directory, unless a jar file was included.
      String executionPath;
      if (executionFile.isDirectory()) {
        // Universal location of eclipse workspace to the dart source tree is
        // 'dart/compiler/eclipse.workspace/dartc/output'
        // and we need 'dart/client'
        executionPath =
            executionFile.getParent() + File.separator + ".." + File.separator + ".."
                + File.separator + ".." + File.separator + "client";
      } else {
        executionPath = executionFile.getParent() + File.separator + path.jar;
      }
      libraryDirOrZip = searchForResource(executionPath, path.lib, false);
      if (libraryDirOrZip == null && executionFile.isFile()) {
        // Last ditch; are the artifacts just in a flat file...
        libraryDirOrZip = searchForResource(executionFile.getParent(), path.lib, false);
      }
    }
    if (libraryDirOrZip != null) {
      return new SystemLibrary(path.shortName, path.hostName, path.lib,
          libraryDirOrZip);
    }
    return null;
  }
  
  /**
   * Answer the libraries that are built into the compiler jar
   */
  protected SystemLibrary[] getDefaultLibraries() {
    ArrayList<SystemLibrary> defaultLibraries = new ArrayList<SystemLibrary>();
    File[] baseFiles = new File[SystemLibraryPath.values().length];

    for (SystemLibraryPath path : SystemLibraryPath.values()) {
      if (path.base != null) {
        defaultLibraries.add(new SystemLibrary(path.shortName, path.hostName, path.lib,
            baseFiles[path.base.ordinal()]));
        baseFiles[path.ordinal()] = baseFiles[path.base.ordinal()];
      } else {
        SystemLibrary library = locateSystemLibrary(path);
        if (library != null) {
          defaultLibraries.add(library);
          baseFiles[path.ordinal()] = library.getFile();
        }
      }
    }

    return defaultLibraries.toArray(new SystemLibrary[defaultLibraries.size()]);
  }
}
