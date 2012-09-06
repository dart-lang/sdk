// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.SystemLibrariesReader.DartLibrary;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

/**
 * A Library manager that manages system libraries 
 */
public class SystemLibraryManager  {
  
  private HashMap<String, String> expansionMap;
  private Map<String, SystemLibrary> hostMap;
  private final File sdkLibPath;
  private final URI sdkLibPathUri;
  
  private Map<URI, URI> longToShortUriMap;

  private List<SystemLibrary> libraries;

  public SystemLibraryManager(File sdkPath) {
    this.sdkLibPath = new File(sdkPath, "lib").getAbsoluteFile();
    this.sdkLibPathUri = sdkLibPath.toURI();
    setLibraries(getDefaultLibraries());  
  }
  
  public URI expandRelativeDartUri(URI uri) throws AssertionError {
      String host = uri.getHost();
      if (host == null) {
        String spec = uri.getSchemeSpecificPart();
        String replacement = expansionMap.get(spec);
        if (replacement != null) {
          try {
            uri = new URI(PackageLibraryManager.DART_SCHEME + ":" + replacement);
          } catch (URISyntaxException e) {
            throw new AssertionError();
          }
        } else {
          return null;
        }
      }
      return uri;
  }
  
  public URI getRelativeUri(URI fileUri) {
    
    if (fileUri == null || !fileUri.getScheme().equals("file")){
      return null;
    }
  
    URI relativeUri = sdkLibPathUri.relativize(fileUri);
    if (relativeUri.getScheme() == null) {
      try {
        return new URI(null, null, "dart://" + relativeUri.getPath(), null, null);
      } catch (URISyntaxException e) {
        //$FALL-THROUGH$
      }
    } 
    return null;
  }
  
  public URI getShortUri(URI uri) {
    URI shortUri = longToShortUriMap.get(uri);
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
  
  public URI translateDartUri(URI uri) {
   
      String host = uri.getHost();
      SystemLibrary library = hostMap.get(host);
      if (library != null) {
        return library.translateUri(uri);
      }
      if (host != null) {
        return new File(getSdkLibPath(), host).toURI().resolve("." + uri.getPath());
      }
      throw new RuntimeException("No system library defined for " + uri);
   
  }
  
  
  public Collection<String> getAllLibrarySpecs() {
    Collection<String> result = new ArrayList<String>(libraries.size());
    for (SystemLibrary lib : libraries) {
      result.add("dart:" + lib.getShortName());
    }
    return result;
  }
  
  
  /**
   * Load the libraries listed out in the libraries.dart files as read by the {@link SystemLibrariesReader}
   */
  protected SystemLibrary[] getDefaultLibraries() {
    libraries = new ArrayList<SystemLibrary>();
    longToShortUriMap = new HashMap<URI, URI>();

    // Cycle through the import.config, extracting explicit mappings and searching directories
    URI base = this.sdkLibPathUri;
    
    SystemLibrariesReader reader = new SystemLibrariesReader(sdkLibPath);
    Map<String, DartLibrary> declaredLibraries = reader.getLibrariesMap();
    
    HashSet<String> explicitShortNames = new HashSet<String>();
    
    for (Entry<String, DartLibrary> entry : declaredLibraries.entrySet()) {
      if (entry.getValue().getCategory().equals("Internal")){
        continue;
      }
      String shortName = entry.getKey().trim();
      String path = entry.getValue().getPath();
      File file;
      try {
        file = new File(base.resolve(new URI(null, null, path, null, null)).normalize());
      } catch (URISyntaxException e) {
        continue;
      }
      if (!file.exists()) {
        throw new InternalCompilerException("Can't find system library dart:" + shortName
                                            + " at " + file);
      }
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
    return libraries.toArray(new SystemLibrary[libraries.size()]);
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
  
  public File getSdkLibPath() {
    return sdkLibPath;
  }

}
