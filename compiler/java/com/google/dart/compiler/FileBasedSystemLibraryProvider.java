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

import java.io.File;
import java.io.IOException;
import java.net.URI;

/**
 * A file-based {@link SystemLibraryProvider} that reads dart-sdk/lib/_internal/libraries.dart for
 * system library information.
 */
public class FileBasedSystemLibraryProvider extends SystemLibraryProvider {

  private File sdkLibPath;

  /**
   * Create a {@link FileBasedSystemLibraryProvider} with the given path to the dart SDK.
   */
  public FileBasedSystemLibraryProvider(File sdkPath) {
    super(new File(sdkPath, "lib").getAbsoluteFile().toURI());
    //TODO(pquitslund): remove this duplicated file creation
    sdkLibPath = new File(sdkPath, "lib").getAbsoluteFile();
  }

  @Override
  protected SystemLibrariesReader createReader() throws IOException {
    return new SystemLibrariesReader(sdkLibPath);
  }

  @Override
  public SystemLibrary createSystemLibrary(String name, String host, String pathToLib,
      String category, boolean documented, boolean implementation) {
    
    
    File dir = new File(sdkLibPath, host);
    
    File libFile = new File(dir, pathToLib);
    if (!libFile.isFile()) {
      throw new InternalCompilerException("Error mapping dart:" + host + ", path "
          + libFile.getAbsolutePath() + " is not a file.");
    }
    
    return new SystemLibrary(
        name, host, pathToLib, dir, category, documented, implementation);
  }
  
  @Override
  public boolean exists(URI uri) {
    return new File(uri).exists();
  }
  
  @Override
  public URI resolveHost(String host, URI uri) {
    return new File(sdkLibPath, host).toURI().resolve("." + uri.getPath());
  }
  
}