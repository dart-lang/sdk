// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Information about the environment in which the current program is running.
 *
 * Platform provides information such as the operating system,
 * the hostname of the computer, the value of environment variables,
 * the path to the running program,
 * and so on.
 *
 * ## Get the URI to the current Dart script
 *
 * Use the [script] getter to get the URI to the currently running
 * Dart script.
 *
 *     import 'dart:io' show Platform;
 *
 *     void main() {
 *       // Get the URI of the script being run.
 *       var uri = Platform.script;
 *       // Convert the URI to a path.
 *       var path = uri.toFilePath();
 *     }
 *
 * ## Get the value of an environment variable
 *
 * The [environment] getter returns a the names and values of environment
 * variables in a [Map] that contains key-value pairs of strings. The Map is
 * unmodifiable. This sample shows how to get the value of the `PATH`
 * environment variable.
 *
 *     import 'dart:io' show Platform;
 *
 *     void main() {
 *       Map<String, String> envVars = Platform.environment;
 *       print(envVars['PATH']);
 *     }
 *
 * ## Determine the OS
 *
 * You can get the name of the operating system as a string with the
 * [operatingSystem] getter. You can also use one of the static boolean
 * getters: [isMacOS], [isLinux], and [isWindows].
 *
 *     import 'dart:io' show Platform, stdout;
 *
 *     void main() {
 *       // Get the operating system as a string.
 *       String os = Platform.operatingSystem;
 *       // Or, use a predicate getter.
 *       if (Platform.isMacOS) {
 *         print('is a Mac');
 *       } else {
 *         print('is not a Mac');
 *       }
 *     }
 *
 * ## Other resources
 *
 * [Dart by Example](https://www.dartlang.org/dart-by-example/#dart-io-and-command-line-apps)
 * provides additional task-oriented code samples that show how to use
 * various API from the [dart:io] library.
 */
class Platform {
  static final _numberOfProcessors = _Platform.numberOfProcessors;
  static final _pathSeparator = _Platform.pathSeparator;
  static final _operatingSystem = _Platform.operatingSystem;
  static final _localHostname = _Platform.localHostname;
  static final _version = _Platform.version;

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
   * Get a string (`linux`, `macos`, `windows`, `android`, or `ios`)
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
  static final bool isLinux = (_operatingSystem == "linux");

  /**
   * Returns true if the operating system is OS X.
   */
  static final bool isMacOS = (_operatingSystem == "macos");

  /**
   * Returns true if the operating system is Windows.
   */
  static final bool isWindows = (_operatingSystem == "windows");

  /**
   * Returns true if the operating system is Android.
   */
  static final bool isAndroid = (_operatingSystem == "android");

  /**
   * Returns true if the operating system is iOS.
   */
  static final bool isIOS = (_operatingSystem == "ios");

  /**
   * Returns true if the operating system is Fuchsia
   */
  static final bool isFuchsia = (_operatingSystem == "fuchsia");

  /**
   * Get the environment for this process.
   *
   * The returned environment is an unmodifiable map which content is
   * retrieved from the operating system on its first use.
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
   * The path returned is the literal path used to run the script. This
   * path might be relative or just be a name from which the executable
   * was found by searching the `PATH`.
   *
   * To get the absolute path to the resolved executable use
   * [resolvedExecutable].
   */
  static String get executable => _Platform.executable;

  /**
   * Returns the path of the executable used to run the script in this
   * isolate after it has been resolved by the OS.
   *
   * This is the absolute path, with all symlinks resolved, to the
   * executable used to run the script.
   */
  static String get resolvedExecutable => _Platform.resolvedExecutable;

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
   * Returns the value of the `--package-root` flag passed to the executable
   * used to run the script in this isolate.  This is the directory in which
   * Dart packages are looked up.
   *
   * If there is no `--package-root` flag, `null` is returned.
   */
  static String get packageRoot => _Platform.packageRoot;

/**
 * Returns the value of the `--packages` flag passed to the executable
 * used to run the script in this isolate. This is the configuration which
 * specifies how Dart packages are looked up.
 *
 * If there is no `--packages` flag, `null` is returned.
 */
  static String get packageConfig => _Platform.packageConfig;

  /**
   * Returns the version of the current Dart runtime.
   *
   * The returned `String` is formatted as the
   * [semver](http://semver.org) version string of the current dart
   * runtime, possibly followed by whitespace and other version and
   * build details.
   */
  static String get version => _version;
}
