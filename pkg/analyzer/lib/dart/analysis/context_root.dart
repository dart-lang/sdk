// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/**
 * Information about the root directory associated with an analysis context.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ContextRoot {
  /**
   * A list of the files and directories within the root directory that should
   * not be analyzed.
   */
  List<Resource> get excluded;

  /**
   * A collection of the absolute, normalized paths of files and directories
   * within the root directory that should not be analyzed.
   */
  Iterable<String> get excludedPaths;

  /**
   * A list of the files and directories within the root directory that should
   * be analyzed. If all of the files in the root directory (other than those
   * that are explicitly excluded) should be analyzed, then this list will
   * contain the root directory.
   */
  List<Resource> get included;

  /**
   * A collection of the absolute, normalized paths of files within the root
   * directory that should be analyzed. If all of the files in the root
   * directory (other than those that are explicitly excluded) should be
   * analyzed, then this collection will contain the path of the root directory.
   */
  Iterable<String> get includedPaths;

  /**
   * The analysis options file that should be used when analyzing the files
   * within this context root, or `null` if there is no options file.
   */
  File get optionsFile;

  /**
   * The packages file that should be used when analyzing the files within this
   * context root, or `null` if there is no options file.
   */
  File get packagesFile;

  /**
   * The root directory containing the files to be analyzed.
   */
  Folder get root;
}
