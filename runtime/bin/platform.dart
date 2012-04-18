// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Platform] class exposes details of the machine and operating
 * system.
 */
class Platform {
  /**
   * Get the number of processors of the machine.
   */
  static int numberOfProcessors() => _Platform.numberOfProcessors();

  /**
   * Get the path separator used by the operating system to separate
   * components in file paths.
   */
  static String pathSeparator() => _Platform.pathSeparator();

  /**
   * Get a string ('macos', 'windows', 'linux') representing the
   * operating system.
   */
  static String operatingSystem() => _Platform.operatingSystem();

  /**
   * Get the local hostname for the system.
   */
  static String localHostname() => _Platform.localHostname();

  /**
   * Get the environment for this process.
   */
  static Map<String, String> environment() => _Platform.environment();
}
