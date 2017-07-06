// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "io.dart";

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
  static final _localeName = _Platform.localeName;

  /**
   * The number of individual execution units of the machine.
   */
  static int get numberOfProcessors => _numberOfProcessors;

  /**
   * The path separator used by the operating system to separate
   * components in file paths.
   */
  static String get pathSeparator => _pathSeparator;

  /**
   * Get the name of the current locale.
   */
  static String get localeName => _localeName;

  /**
   * A string representing the operating system or platform.
   */
  static String get operatingSystem => _operatingSystem;

  /**
   * The local hostname for the system.
   */
  static String get localHostname => _localHostname;

  /**
   * Whether the operating system is a version of
   * [Linux](https://en.wikipedia.org/wiki/Linux).
   *
   * This value is `false` if the operating system is a specialized
   * version of Linux that identifies itself by a different name,
   * for example Android (see [isAndroid]).
   */
  static final bool isLinux = (_operatingSystem == "linux");

  /**
   * Whether the operating system is a version of
   * [macOS](https://en.wikipedia.org/wiki/MacOS).
   */
  static final bool isMacOS = (_operatingSystem == "macos");

  /**
   * Whether the operating system is a version of
   * [Microsoft Windows](https://en.wikipedia.org/wiki/Microsoft_Windows).
   */
  static final bool isWindows = (_operatingSystem == "windows");

  /**
   * Whether the operating system is a version of
   * [Android](https://en.wikipedia.org/wiki/Android_%28operating_system%29).
   */
  static final bool isAndroid = (_operatingSystem == "android");

  /**
   * Whether the operating system is a version of
   * [iOS](https://en.wikipedia.org/wiki/IOS).
   */
  static final bool isIOS = (_operatingSystem == "ios");

  /**
   * Whether the operating system is a version of
   * [Fuchsia](https://en.wikipedia.org/wiki/Google_Fuchsia).
   */
  static final bool isFuchsia = (_operatingSystem == "fuchsia");

  /**
   * The environment for this process as a map from string key to string value.
   *
   * The map is unmodifiable,
   * and its content is retrieved from the operating system on its first use.
   *
   * Environment variables on Windows are case-insensitive,
   * so on Windows the map is case-insensitive and will convert
   * all keys to upper case.
   * On other platforms, keys can be distinguished by case.
   */
  static Map<String, String> get environment => _Platform.environment;

  /**
   * The path of the executable used to run the script in this isolate.
   *
   * The literal path used to identify the script.
   * This path might be relative or just be a name from which the executable
   * was found by searching the system path.
   *
   * Use [resolvedExecutable] to get an absolute path to the executable.
   */
  static String get executable => _Platform.executable;

  /**
   * The path of the executable used to run the script in this
   * isolate after it has been resolved by the OS.
   *
   * This is the absolute path, with all symlinks resolved, to the
   * executable used to run the script.
   */
  static String get resolvedExecutable => _Platform.resolvedExecutable;

  /**
   * The absolute URI of the script being run in this isolate.
   *
   * If the script argument on the command line is relative,
   * it is resolved to an absolute URI before fetching the script, and
   * that absolute URI is returned.
   *
   * URI resolution only does string manipulation on the script path, and this
   * may be different from the file system's path resolution behavior. For
   * example, a symbolic link immediately followed by '..' will not be
   * looked up.
   *
   * If the executable environment does not support [script],
   * the URI is empty.
   */
  static Uri get script => _Platform.script;

  /**
   * The flags passed to the executable used to run the script in this isolate.
   *
   * These are the command-line flags to the executable that precedes
   * the script name.
   * Provides a new list every time the value is read.
   */
  static List<String> get executableArguments => _Platform.executableArguments;

  /**
   * The `--package-root` flag passed to the executable used to run the script
   * in this isolate.
   *
   * If present, it specifies the directory where Dart packages are looked up.
   *
   * Is `null` if there is no `--package-root` flag.
   */
  static String get packageRoot => _Platform.packageRoot;

  /**
   * The `--packages` flag passed to the executable used to run the script
   * in this isolate.
   *
   * If present, it specifies a file describing how Dart packages are looked up.
   *
   * Is `null` if there is no `--packages` flag.
   */
  static String get packageConfig => _Platform.packageConfig;

  /**
   * The version of the current Dart runtime.
   *
   * The value is a [semantic versioning](http://semver.org)
   * string representing the version of the current Dart runtime,
   * possibly followed by whitespace and other version and
   * build details.
   */
  static String get version => _version;
}
