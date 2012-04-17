// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Platform] class exposes details of the machine and operating
 * system.
 */
interface Platform default _Platform {
  /**
   * Create a Platform object.
   */
  Platform();

  /**
   * Get the number of processors of the machine.
   */
  int numberOfProcessors();

  /**
   * Get the path separator used by the operating system to separate
   * components in file paths.
   */
  String pathSeparator();

  /**
   * Get a string ('macos', 'windows', 'linux') representing the
   * operating system.
   */
  String operatingSystem();

  /**
   * Get the local hostname for the system.
   */
  String localHostname();

  /**
   * Get the environment for this process.
   */
  Map<String, String> environment();
}
