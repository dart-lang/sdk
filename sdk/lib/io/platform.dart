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
  static final _version = _Platform.version;

  // This script singleton is written to by the embedder if applicable.
  static String _nativeScript = '';

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

  /**
   * Returns the path of the executable used to run the script in this
   * isolate.
   *
   * If the execution environment does not support [executable] an empty
   * string is returned.
   */
  static String get executable => _Platform.executable;

  /**
   * Returns the absolute URI of the script being run in this
   * isolate.
   *
   * If the script argument on the command line is relative,
   * it is resolved to an absolute URI before fetching the script, and
   * this absolute URI is returned.
   *
   * URI resolution only does string manipulation on the script path, and this
   * may be different from the file system's path resolution behavior. For
   * example, a symbolic link immediately followed by '..' will not be
   * looked up.
   *
   * If the executable environment does not support [script] an empty
   * [Uri] is returned.
   */
  static Uri get script => _Platform.script;

  /**
   * Returns the flags passed to the executable used to run the script in this
   * isolate. These are the command-line flags between the executable name
   * and the script name. Each fetch of executableArguments returns a new
   * List, containing the flags passed to the executable.
   */
  static List<String> get executableArguments => _Platform.executableArguments;

  /**
   * Returns the value of the --package-root flag passed to the executable
   * used to run the script in this isolate.  This is the directory in which
   * Dart packages are looked up.
   *
   * If there is no --package-root flag, then the empty string is returned.
   */
  static String get packageRoot => _Platform.packageRoot;

  /**
   * Returns the version of the current Dart runtime.
   */
  static String get version => _version;
}
