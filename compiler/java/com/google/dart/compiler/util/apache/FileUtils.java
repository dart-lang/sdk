// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.dart.compiler.util.apache;

import java.io.File;
import java.net.URL;

/**
 * General file manipulation utilities.
 * * <p>
 * NOTICE: This file is modified copy of its original Apache library.
 * It was moved to the different package, and changed to reduce number of dependencies.
 */
public class FileUtils {
  /**
   * Convert from a <code>URL</code> to a <code>File</code>.
   * <p>
   * From version 1.1 this method will decode the URL.
   * Syntax such as <code>file:///my%20docs/file.txt</code> will be
   * correctly decoded to <code>/my docs/file.txt</code>. Starting with version
   * 1.5, this method uses UTF-8 to decode percent-encoded octets to characters.
   * Additionally, malformed percent-encoded octets are handled leniently by
   * passing them through literally.
   *
   * @param url  the file URL to convert, <code>null</code> returns <code>null</code>
   * @return the equivalent <code>File</code> object, or <code>null</code>
   *  if the URL's protocol is not <code>file</code>
   */
  public static File toFile(URL url) {
    if (url == null || !url.getProtocol().equals("file")) {
      return null;
    } else {
      String filename = url.getFile().replace('/', File.separatorChar);
      int pos = 0;
      while ((pos = filename.indexOf('%', pos)) >= 0) {
        if (pos + 2 < filename.length()) {
          String hexStr = filename.substring(pos + 1, pos + 3);
          char ch = (char) Integer.parseInt(hexStr, 16);
          filename = filename.substring(0, pos) + ch + filename.substring(pos + 3);
        }
      }
      return new File(filename);
    }
  }

}
