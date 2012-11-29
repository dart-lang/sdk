// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

/**
 * The [Platform] class exposes details of the machine and operating
 * system.
 */
class Platform {
  /**
   * Get the number of processors of the machine.
   */
  static int get numberOfProcessors => _Platform.numberOfProcessors;

  /**
   * Get the path separator used by the operating system to separate
   * components in file paths.
   */
  static String get pathSeparator => _Platform.pathSeparator;

  /**
   * Get a string ('macos', 'windows', 'linux') representing the
   * operating system.
   */
  static String get operatingSystem => _Platform.operatingSystem;

  /**
   * Get the local hostname for the system.
   */
  static String get localHostname => _Platform.localHostname;

  /**
   * Get the environment for this process.
   */
  static Map<String, String> get environment => _Platform.environment;
}
