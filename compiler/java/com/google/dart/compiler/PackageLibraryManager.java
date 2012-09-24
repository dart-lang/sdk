// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;


/**
 * Manages the collection of {@link SystemLibrary}s.
 */
public class PackageLibraryManager {

  public static class NotADartShortUriException extends RuntimeException {
    private static final long serialVersionUID = 1L;

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
  public static final List<File> DEFAULT_PACKAGE_ROOTS = Arrays.asList(new File[] {DEFAULT_PACKAGE_ROOT});

  public static final String PACKAGE_SCHEME = "package";
  public static final String PACKAGE_SCHEME_SPEC = "package:";

  public static final String DART_SCHEME = "dart";
  public static final String DART_SCHEME_SPEC = "dart:";
  

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

  private static SystemLibraryManager SDK_LIBRARY_MANAGER;
  
  private List<File> packageRoots = new ArrayList<File>();
  private List<URI> packageRootsUri = new ArrayList<URI>(); 

  public PackageLibraryManager() {
    this(DEFAULT_SDK_PATH, DEFAULT_PLATFORM);
  }

  public PackageLibraryManager(File sdkPath, String platformName) {
    initLibraryManager(sdkPath);
    setPackageRoots(DEFAULT_PACKAGE_ROOTS);
  }

  /**
   * Initialize the SDK system library manager.
   * 
   * @param sdkPath the path to the SDK
   */
  protected void initLibraryManager(File sdkPath) {
    if (SDK_LIBRARY_MANAGER == null){
      SDK_LIBRARY_MANAGER = new SystemLibraryManager(sdkPath);
    }
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
      return SDK_LIBRARY_MANAGER.expandRelativeDartUri(uri);
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
   
    URI relativeUri = SDK_LIBRARY_MANAGER.getRelativeUri(fileUri);
    if (relativeUri != null){
      return relativeUri;
    }
    
    for (URI rootUri : packageRootsUri){
      relativeUri = rootUri.relativize(fileUri);
        if (relativeUri.getScheme() == null) {
          try {
            return new URI(null, null, "package://" + relativeUri.getPath(), null, null);
          } catch (URISyntaxException e) {
        //$FALL-THROUGH$
        }
      }
    }
    return null;
  }

  /**
   * Given a package URI (package:foo/foo.dart), convert it into a file system URI.
   */
  public URI resolvePackageUri(String packageUriRef) {
    if (packageUriRef.startsWith(PACKAGE_SCHEME_SPEC)) {
      String relPath = packageUriRef.substring(PACKAGE_SCHEME_SPEC.length());
      if (relPath.startsWith("/")){
        relPath = relPath.replaceAll("^\\/+", "");
      }
      for (URI rootUri : packageRootsUri){
        URI fileUri = rootUri.resolve(relPath);
        File file = new File(fileUri);
        if (file.exists()){
          try {
            return file.getCanonicalFile().toURI();
          } catch (IOException e) {
            file.toURI();
          }
        }
      }
      // don't return null for package scheme
      return packageRootsUri.get(0).resolve(relPath);
    }
   return null; 
  }

  /**
   * Answer the original "dart:<libname>" URI for the specified resolved URI or <code>null</code> if
   * it does not map to a short URI.
   */
  public URI getShortUri(URI uri) {
    URI shortUri = SDK_LIBRARY_MANAGER.getShortUri(uri);
    if (shortUri != null){
      return shortUri;
    }
    shortUri = getRelativeUri(uri);
    if (shortUri != null){
      try {
        return new URI(null, null, shortUri.getScheme() + ":" +  shortUri.getHost() + shortUri.getPath(),null, null);
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
  
  
  public List<File> getPackageRoots(){
    return packageRoots;
  }
  
  
  public void setPackageRoots(List<File> roots){
    if (roots == null || roots.isEmpty()){
      roots = DEFAULT_PACKAGE_ROOTS;
    }
    packageRoots.clear();
    for (File file : roots){   
      packageRoots.add(file.getAbsoluteFile());
    }   
    packageRootsUri.clear();
    for (File file : roots){
      packageRootsUri.add(file.toURI());
    }
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
  public URI translateDartUri(URI uri) {
    if (isDartUri(uri)) {
     return SDK_LIBRARY_MANAGER.translateDartUri(uri);
    } 
    if (isPackageUri(uri)){   
      URI fileUri;
      for (URI rootUri : packageRootsUri){
        fileUri = getResolvedPackageUri(uri, rootUri);
        File file  = new File(fileUri);
        if (file.exists()){
          try {
            return file.getCanonicalFile().toURI();
          } catch (IOException e) {
            return file.toURI();
          }
        }
      }
      // resolve against first package root
      fileUri = getResolvedPackageUri(uri, packageRootsUri.get(0));
      return fileUri;
    }
    return uri;
  }

  
  /**
   * Given a uri, resolve against the list of package roots, used to find generated files
   * @return uri - resolved uri if file exists, else return given uri 
   */
  public URI findExistingFileInPackages(URI fileUri){
    
    URI resolvedUri = getRelativeUri(fileUri);
    if (isPackageUri(resolvedUri)){
      resolvedUri = resolvePackageUri(resolvedUri.toString());
      return resolvedUri;
    }
    return fileUri;
  }

  /**
   * Resolves the given uri against the package root uri
   */
  private URI getResolvedPackageUri(URI uri, URI packageRootUri) {
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
    return fileUri;
  }

  /**
   * Answer a collection of all bundled library URL specs (e.g. "dart:html").
   *
   * @return a collection of specs (not <code>null</code>, contains no <code>null</code>s)
   */
  public Collection<String> getAllLibrarySpecs() {
    return SDK_LIBRARY_MANAGER.getAllLibrarySpecs();
  }
  
  protected SystemLibrary[] getDefaultLibraries() {
    return SDK_LIBRARY_MANAGER.getDefaultLibraries(); 
  }
  
  public Collection<SystemLibrary> getSystemLibraries(){
    return SDK_LIBRARY_MANAGER.getAllSystemLibraries();
  }
  
  public File getSdkLibPath() {
    return SDK_LIBRARY_MANAGER.getSdkLibPath();
  }
  
  
  
}
