// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
  public static final File DEFAULT_SDK_PATH = new File(System.getProperty(
      "com.google.dart.sdk", "../"));
  
  public static final File DEFAULT_PACKAGE_ROOT = new File("packages");

  private static final String DART_SCHEME = "dart";
  private static final String DART_SCHEME_SPEC = "dart:";
  private static final String IMPORT_CONFIG = "import_%s.config";

  private static final String PACKAGE_SCHEME = "package";
  private static final String PACKAGE_SCHEME_SPEC = "package:";

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

  /**
   * Answer <code>true</code> if the string is a package spec
   */
  public static boolean isPackageSpec(String spec) {
    return spec != null && spec.startsWith(PACKAGE_SCHEME_SPEC);
  }

  /**
   * Answer <code>true</code> if the specified URI has a "package" scheme
   */
  public static boolean isPackageUri(URI uri) {
    return uri != null && PACKAGE_SCHEME.equals(uri.getScheme());
  }

  private HashMap<String, String> expansionMap;
  private Map<String, SystemLibrary> hostMap;
  private final File sdkLibPath;
  private final URI sdkLibPathUri;
  private final String platformName;
  private File packageRoot = DEFAULT_PACKAGE_ROOT;
  private URI packageRootUri = packageRoot.toURI();

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
   * Expand a relative or short URI (e.g. "dart:html") which is implementation independent to its
   * full URI (e.g. "dart://html/com/google/dart/htmllib/html.dart").
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
    if (isPackageUri(uri)){
      String host = uri.getHost();
      if (host == null) {
        String spec = uri.getSchemeSpecificPart();
        if (!spec.startsWith("//")){
          try {
            if (spec.startsWith("/")){
              // TODO(keertip): fix to handle spaces
              uri = new URI(PACKAGE_SCHEME + ":/" + spec);
            } else {
              uri = new URI(PACKAGE_SCHEME + "://" + spec);
            } 
          } catch (URISyntaxException e) {
            throw new AssertionError();
          }
        }       
      }
    }
    return uri;
  }

  /**
   * Answer a collection of all bundled library URL specs (e.g. "dart:html").
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
   * @return the packagePath
   */
  public File getPackageRoot() {
    return packageRoot;
  }
  
  protected InputStream getImportConfigStream() {
    File file = new File(new File(sdkLibPath, "config"),
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
   * Given an absolute file URI (e.g. "file:/some/install/directory/dart-sdk/lib/core/bool.dart"),
   *  answer the corresponding dart: URI (e.g. "dart://core/bool.dart") for that file URI,
   *  or <code>null</code> if the file URI does not map to a dart: URI 
   * @param fileUri the file URI
   * @return the dart URI or <code>null</code>
   */
  public URI getRelativeUri(URI fileUri) {
    // TODO (danrubel): does not convert dart: libraries outside the dart-sdk/lib directory
    if (fileUri == null || !fileUri.getScheme().equals("file")) {
      return null;
    }
    URI relativeUri = sdkLibPathUri.relativize(fileUri);
    if (relativeUri.getScheme() == null) {
      try {
        return new URI(null, null, "dart://" + relativeUri.getPath(), null);
      } catch (URISyntaxException e) {
        //$FALL-THROUGH$
      }
    }
    
    relativeUri = packageRootUri.relativize(fileUri);
    if (relativeUri.getScheme() == null) {
      try {
        return new URI(null, null, "package://" + relativeUri.getPath(), null);
      } catch (URISyntaxException e) {
        //$FALL-THROUGH$
      }
    }
    return null;
  }

  /**
   * Answer the original "dart:<libname>" URI for the specified resolved URI or <code>null</code> if
   * it does not map to a short URI.
   */
  public URI getShortUri(URI uri) {
    URI shortUri = longToShortUriMap.get(uri);
    if (shortUri != null){
      return shortUri;
    }
    shortUri = getRelativeUri(uri);
    if (shortUri != null){
      try {
        return new URI(null, null, shortUri.getScheme() + ":" +  shortUri.getHost() + shortUri.getPath(),null);
      } catch (URISyntaxException e) {
      }
    }
    return null;
  }

  /**
   * Expand a relative or short URI (e.g. "dart:html") which is implementation independent to its
   * full URI (e.g. "dart://html/com/google/dart/htmllib/html.dart") and then translate that URI to
   * a "file:"  URI (e.g.
   * "file:/some/install/directory/com/google/dart/htmllib/html.dart").
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

   * @param packageRoot the packagePath to set
   */
  public void setPackageRoot(File packageRoot) {
    this.packageRoot = packageRoot;
    packageRootUri = packageRoot.toURI();
  }
  
  /**
   * Translate the URI from dart://[host]/[pathToLib] (e.g. dart://html/html.dart)
   * to a "file:" URI (e.g. "file:/some/install/directory/html.dart")
   *
   * @param uri the original URI
   * @return the translated URI, which may be <code>null</code> and may not exist
   * @exception RuntimeException if the URI is a "dart" scheme,
   *     but does not map to a defined system library
   */
  private URI translateDartUri(URI uri) {
    if (isDartUri(uri)) {
      String host = uri.getHost();
      SystemLibrary library = hostMap.get(host);
      if (library == null) {
        throw new RuntimeException("No system library defined for " + uri);
      }
      return library.translateUri(uri);
    } 
    if (isPackageUri(uri)){   
      URI fileUri;
      // TODO(keertip): Investigate further
      // if uri.getHost() returns null, then it is resolved right
      // so use uri.getAuthority to resolve
      // package://third_party/dart_lang/lib/unittest/unittest.dart
      if (uri.getHost() != null){
        fileUri =  packageRootUri.resolve(uri.getHost() + uri.getPath());
      } else {
        fileUri = packageRootUri.resolve(uri.getAuthority() + uri.getPath());
      }
      File file  = new File(fileUri);
        return file.toURI();
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
        String host = file.getParentFile().getName();
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
   * "dart:html") will automatically be expanded to dart://[host]/[pathToLib] (e.g.
   * dart://html/html.dart)
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
