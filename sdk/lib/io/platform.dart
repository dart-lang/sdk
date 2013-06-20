// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * The [Platform] class exposes details of the machine and operating
 * system.
 */
class Platform {
  static final _numberOfProcessors = _Platform.numberOfProcessors;
  static final _pathSeparator = _Platform.pathSeparator;
  static final _operatingSystem = _Platform.operatingSystem;
  static final _localHostname = _Platform.localHostname;

  /**
   * Get the number of processors of the machine.
   */
  static int get numberOfProcessors => _numberOfProcessors;

  /**
   * Get the path separator used by the operating system to separate
   * components in file paths.
   */
  static String get pathSeparator => _pathSeparator;

  /**
   * Get a string (`linux`, `macos`, `windows` or `android`)
   * representing the operating system.
   */
  static String get operatingSystem => _operatingSystem;

  /**
   * Get the local hostname for the system.
   */
  static String get localHostname => _localHostname;

  /**
   * Returns true if the operating system is Linux.
   */
  static bool get isLinux => _operatingSystem == "linux";

  /**
   * Returns true if the operating system is Mac OS.
   */
  static bool get isMacOS => _operatingSystem == "macos";

  /**
   * Returns true if the operating system is Windows.
   */
  static bool get isWindows => _operatingSystem == "windows";

  /**
   * Returns true if the operating system is Android.
   */
  static bool get isAndroid => _operatingSystem == "android";

  /**
   * Get the environment for this process.
   *
   * Environment variables on Windows are case-insensitive. The map
   * returned on Windows is therefore case-insensitive and will convert
   * all keys to upper case. On other platforms the returned map is
   * a standard case-sensitive map.
   */
  static Map<String, String> get environment => _Platform.environment;
}
