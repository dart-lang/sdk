// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Properties;

/**
 * Manages the collection of {@link SystemLibrary}s.
 */
public class SystemLibraryManager {

  public static class NotADartShortUriException extends RuntimeException {

    public NotADartShortUriException(String uriString) {
      super("Expected dart:<short name>, got: " + uriString);
    }

    public NotADartShortUriException(URI uri) {
      super("Expected dart:<short name>, got: " + uri.toString());
    }
  }

  /**
   * The "any" platform is meant to have definitions for all known dart system libraries.
   * Other implementations may only contain a subset.
   */
  public static final String DEFAULT_PLATFORM = "any";
  public static final File DEFAULT_SDK_PATH =
      new File(System.getProperty("com.google.dart.sdk", "../"));

  private static final String DART_SCHEME = "dart";
  private static final String DART_SCHEME_SPEC = "dart:";
  private static final String IMPORT_CONFIG = "import_%s.config";

  /**
   * Answer <code>true</code> if the string is a dart spec
   */
  public static boolean isDartSpec(String spec) {
    return spec != null && spec.startsWith(DART_SCHEME_SPEC);
  }
  /**
   * Answer <code>true</code> if the specified URI has a "dart" scheme
   */
  public static boolean isDartUri(URI uri) {
    return uri != null && DART_SCHEME.equals(uri.getScheme());
  }

  private HashMap<String, String> expansionMap;
  private Map<String, SystemLibrary> hostMap;
  private final File sdkLibPath;
  private final URI sdkLibPathUri;
  private final String platformName;

  private Map<URI, URI> longToShortUriMap;

  private List<SystemLibrary> libraries;

  public SystemLibraryManager() {
    this(DEFAULT_SDK_PATH, DEFAULT_PLATFORM);
  }

  public SystemLibraryManager(File sdkPath, String platformName) {
    this.sdkLibPath = new File(sdkPath, "lib").getAbsoluteFile();
    this.sdkLibPathUri = sdkLibPath.toURI();
    this.platformName = platformName;
    setLibraries(getDefaultLibraries());
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
   * Answer a collection of all bundled library URL specs (e.g. "dart:dom").
   *
   * @return a collection of specs (not <code>null</code>, contains no <code>null</code>s)
   */
  public Collection<String> getAllLibrarySpecs() {
    Collection<String> result = new ArrayList<String>(libraries.size());
    for (SystemLibrary lib : libraries) {
      result.add("dart:" + lib.getShortName());
    }
    return result;
  }

  /**
   * The import config files have the path: dart-sdk/_internal/config/import_<platform>.config
   */
  protected InputStream getImportConfigStream() {
    File file = new File(new File(new File(sdkLibPath, "_internal"), "config"),
                         String.format(IMPORT_CONFIG, platformName));
    if (!file.exists()) {
      throw new InternalCompilerException("Failed to find " + file.toString()
                                          + ".  Is dart-sdk path correct?");
    }
    try {
      return new BufferedInputStream(new FileInputStream(file));
    } catch (FileNotFoundException e) {
      throw new InternalCompilerException("Failed to open " + file);
    }
  }

  /**
   * Answer the original "dart:<libname>" URI for the specified resolved URI or <code>null</code> if
   * it does not map to a short URI.
   */
  public URI getShortUri(URI uri) {
    return longToShortUriMap.get(uri);
  }

  /**
   * Expand a relative or short URI (e.g. "dart:dom") which is implementation independent to its
   * full URI (e.g. "dart://dom/com/google/dart/domlib/dom.dart") and then translate that URI to
   * a "file:"  URI (e.g.
   * "file:/some/install/directory/com/google/dart/domlib/dom.dart").
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
   * to a "file:" URI (e.g. "file:/some/install/directory/dom.dart")
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

  public File getSdkLibPath() {
    return sdkLibPath;
  }

  /**
   * Scan the directory returned by {@link #getLibrariesDir()} looking for libraries of the form
   * libraries/<name>/<name>_<platform>.dart and libraries/<name>/<name>.dart where <platform> is
   * the value initialized in the {@link SystemLibraryManager}.
   */
  protected SystemLibrary[] getDefaultLibraries() {
    libraries = new ArrayList<SystemLibrary>();
    longToShortUriMap = new HashMap<URI, URI>();

    // Cycle through the import.config, extracting explicit mappings and searching directories
    URI base = this.sdkLibPathUri;
    Properties importConfig = getImportConfig();
    HashSet<String> explicitShortNames = new HashSet<String>();
    for (Entry<Object, Object> entry : importConfig.entrySet()) {
      String shortName = ((String) entry.getKey()).trim();
      String path = ((String) entry.getValue()).trim();

      File file;
      try {
        file = new File(base.resolve(new URI(null, null, path, null)).normalize());
      } catch (URISyntaxException e) {
        continue;
      }
      if (!file.exists()) {
        throw new InternalCompilerException("Can't find system library dart:" + shortName
                                            + " at " + file);
      }

      // If the shortName ends with ":" then search the associated directory for libraries

      if (shortName.endsWith(":")) {
        if (!file.isDirectory()) {
          continue;
        }
        for (File child : file.listFiles()) {
          String host = child.getName();
          // Do not overwrite explicit shortName to dart file mappings
          if (explicitShortNames.contains(shortName + host)) {
            continue;
          }
          if (!child.isDirectory()) {
            continue;
          }
          File dartFile = new File(child, child.getName() + ".dart");
          if (!dartFile.isFile()) {
            // addLib() will throw an exception. In this case, we are just scanning
            // for libraries and don't want the error to be fatal.
            continue;
          }
          addLib(shortName, host, host, child, dartFile.getName());
        }
      } else {
        // Otherwise treat the entry as an explicit shortName to dart file mapping
        int index = shortName.indexOf(':');
        if (index == -1) {
          continue;
        }
        explicitShortNames.add(shortName);
        String scheme = shortName.substring(0, index + 1);
        String name = shortName.substring(index + 1);
        index = name.indexOf('/');
        String host = index > 0 ? name.substring(0, index) : name;
        addLib(scheme, host, name, file.getParentFile(), file.getName());
      }
    }
    return libraries.toArray(new SystemLibrary[libraries.size()]);
  }

  /**
   * Read the import.config content and return it as a collection of key/value pairs
   */
  protected Properties getImportConfig() {
    Properties importConfig = new Properties();
    InputStream stream = getImportConfigStream();
    try {
      importConfig.load(stream);
    } catch (IOException ignored) {
    } finally {
      try {
        stream.close();
      } catch (IOException ignored) {
      }
    }
    return importConfig;
  }

  private boolean addLib(String scheme, String host, String name, File dir, String libFileName)
      throws AssertionError {
    File libFile = new File(dir, libFileName);
    if (!libFile.isFile()) {
      throw new InternalCompilerException("Error mapping dart:" + host + ", path "
          + libFile.getAbsolutePath() + " is not a file.");
    }
    SystemLibrary lib = new SystemLibrary(name, host, libFileName, dir);
    libraries.add(lib);
    String libSpec = scheme + name;
    URI libUri;
    URI expandedUri;
    try {
      libUri = new URI(libSpec);
      expandedUri = new URI("dart:" + "//" + host + "/" + libFileName);
    } catch (URISyntaxException e) {
      throw new AssertionError(e);
    }
    URI resolvedUri = lib.translateUri(expandedUri);
    longToShortUriMap.put(resolvedUri, libUri);
    longToShortUriMap.put(expandedUri, libUri);
    return true;
  }

  /**
   * Register system libraries for the "dart:" protocol such that dart:[shortLibName] (e.g.
   * "dart:dom") will automatically be expanded to dart://[host]/[pathToLib] (e.g.
   * dart://dom/dom.dart)
   */
  private void setLibraries(SystemLibrary[] newLibraries) {
    libraries = new ArrayList<SystemLibrary>();
    hostMap = new HashMap<String, SystemLibrary>();
    expansionMap = new HashMap<String, String>();
    for (SystemLibrary library : newLibraries) {
      String host = library.getHost();
      SystemLibrary existingLib = hostMap.get(host);
      if (existingLib != null) {
        libraries.remove(existingLib);
      }
      libraries.add(library);
      hostMap.put(host, library);
      expansionMap.put(library.getShortName(),
          "//" + host + "/" + library.getPathToLib());
    }
  }
}
