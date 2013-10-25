// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Runtime information about the current platform.
 */
library dart.platform;

/**
 * The number of processors of the platform.
 *
 * Returns null if no information is available.
 *
 * Supported on the standalone Dart executable.
 */
external int get numberOfProcessors;

/**
 * The path separator used on the platform to separate
 * components in file paths.
 */
external String get pathSeparator;

/**
 * A string (`linux`, `macos`, `windows` or `android`)
 * representing the operating system.
 *
 * Returns null if the operating system could not be determined.
 */
external String get operatingSystem;

/**
 * The local hostname for the system.
 *
 * Returns null if the local hostname is not available.
 *
 * Supported on the standalone Dart executable.
 */
external String get localHostname;

/**
 * The version of the current Dart runtime.
 *
 * Returns null if not running a Dart runtime.
 *
 * Supported on the standalone Dart executable.
 */
external String get version;

/**
 * True if the operating system is Linux.
 */
// TODO(6997): Replace with bool get isLinux => operatingSystem == 'linux'
// when issue with patched top-level functions is fixed.
external bool get isLinux;

/**
 * True if the operating system is Mac OS.
 */
external bool get isMacOS;

/**
 * True if the operating system is Windows.
 */
external bool get isWindows;

/**
 * True if the operating system is Android.
 */
external bool get isAndroid;

/**
 * The environment for this instance of the platform.
 *
 * If environment variables are not supported on this platform, or not
 * available, null is returned.
 *
 * Environment variables on Windows are case-insensitive. The map
 * returned on Windows is therefore case-insensitive and converts
 * all keys and key arguments to its methods to upper case.
 * On other platforms the returned map is
 * a standard case-sensitive map.
 *
 * Supported on the standalone Dart executable.
 */
external Map<String, String> get environment;

/**
 * The path of the executable this Dart isolate is running on.
 *
 * Returns null if the execution environment does not make the information
 * available.
 *
 * Supported on the standalone Dart executable.
 */
external String get executable;

/**
 * The URI of the script being run in this isolate.
 *
 * If the URI is relative it is relative to the file URI of
 * the working directory of the VM when it was started.
 *
 * Returns null if the executable environment does not make the information
 * available.
 *
 * Supported on the standalone Dart executable.
 */
external Uri get script;

/**
 * The flags passed to the executable used to run the script in this
 * isolate. These are the command-line flags between the executable name
 * and the script name.
 *
 * Returns the empty list if [executableArguments] is not supported.
 *
 * Supported on the standalone Dart executable.
 */
external List<String> get executableArguments;

/**
 * The value of the --package-root flag passed to the executable
 * used to run the script in this isolate.  This is the directory in which
 * Dart packages are looked up.
 *
 * If there is no --package-root flag, then the empty string is returned.
 *
 * Returns null if the information is not available on this platform.
 *
 * Supported on the standalone Dart executable.
 */
external String get packageRoot;
