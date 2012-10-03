/*
 * Copyright (c) 2012, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.compiler;

import com.google.dart.compiler.SystemLibrariesReader.DartLibrary;

import java.io.IOException;
import java.net.URI;
import java.util.Map;

/**
 * A provider for System libraries.
 */
public abstract class SystemLibraryProvider {

  private final URI sdkLibPathUri;
  private SystemLibrariesReader reader;

  /**
   * Create a {@link SystemLibraryProvider} with the given path to the dart SDK.
   */
  public SystemLibraryProvider(URI sdkLibPathUri) {
    this.sdkLibPathUri = sdkLibPathUri;
  }

  /**
   * Define a new system library.
   * 
   * @param name the short name of the library
   * @param host the host
   * @param pathToLib the path to the library
   * @param category the library category
   * @param documented <code>true</code> if documented, <code>false</code> otherwise
   * @param implementation <code>true</code> if an implementation library, <code>false</code>
   *          otherwise
   * @return the resulting {@link SystemLibrary}
   */
  public abstract SystemLibrary createSystemLibrary(String name, String host, String pathToLib,
      String category, boolean documented, boolean implementation);

  /**
   * Tests whether the resource denoted by this abstract URI exists.
   * 
   * @param uri the URI to test
   * @return <code>true</code> if and only if the resource denoted by this URI exists;
   *         <code>false</code> otherwise
   */
  public abstract boolean exists(URI uri);

  /**
   * Get a URI describing the root of the SDK.
   */
  public URI getSdkLibPathUri() {
    return sdkLibPathUri;
  }

  /**
   * Get a mapping of symbolic names (e.g., "dart:html") to {@link DartLibrary}s.
   */
  public Map<String, DartLibrary> getLibraryMap() {
    return getReader().getLibrariesMap();
  }

  /**
   * Check if this URI denotes a patch file.
   */
  public boolean isPatchFile(URI uri) {
    return getReader().getPatchPaths().contains(uri);
  }

  /**
   * Constructs a new URI by parsing the given host string and then resolving it against this URI.
   * 
   * @param host the host string
   * @param uri the uri to resolve against
   * @return the resulting URI
   */
  public abstract URI resolveHost(String host, URI uri);

  /**
   * Create the system libraries reader.
   * 
   * @return a reader for parsing system libraries
   */
  protected abstract SystemLibrariesReader createReader() throws IOException;

  private SystemLibrariesReader getReader() {
    if (reader == null) {
      try {
        reader = createReader();
      } catch (IOException e) {
        throw new InternalCompilerException("Unable to create system library reader", e);
      }
    }
    return reader;
  }

}
