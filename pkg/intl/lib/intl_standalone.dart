// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This provides facilities for Internationalization that are only available
 * when running standalone. You should import only one of this or
 * intl_browser.dart. Right now the only thing provided here is finding
 * the operating system locale.
 */

library intl_standalone;

import "dart:async";
import "dart:io";
import "intl.dart";

// TODO(alanknight): The need to do this by forcing the user to specially
// import a particular library is a horrible hack, only done because there
// seems to be no graceful way to do this at all. Either mirror access on
// dart2js or the ability to do spawnUri in the browser would be promising
// as ways to get rid of this requirement.
/**
 * Find the system locale, accessed via the appropriate system APIs, and
 * set it as the default for internationalization operations in
 * the [Intl.systemLocale] variable. To find it, we
 * check the "LANG" environment variable on *nix, use the "systeminfo"
 * command on Windows, and on the Mac check the environment variable "LANG",
 * and if it's not found, use "defaults read -g AppleLocale". This
 * is not an ideal way of getting a single system locale, even if that
 * concept really made sense, but it's a reasonable first approximation that's
 * not too difficult to get. If it can't find the locale information, it will
 * not modify [Intl.systemLocale] and the Future will complete with null.
 */
Future<String> findSystemLocale() {
  // On *nix systems we expect this is an environment variable, which is the
  // easiest thing to check. On a Mac the environment variable may be present
  // so always check it first. We have no mechanism for this right now on
  // Windows, so it will just fail.
  String baseLocale = _checkEnvironmentVariable();
  if (baseLocale != null) return _setLocale(baseLocale);
  if (Platform.operatingSystem == 'macos') {
    return _getAppleDefaults();
  }
  // We can't find anything, don't set the system locale and return null.
  return new Future.value();
}

/**
 * Regular expression to match the expected output of reading the defaults
 * database for AppleLanguages on Mac systems.
 * e.g. {
 *     en,
 *     "pt-PT",
 *     ...
 */
RegExp _appleDefaultsRegex = new RegExp(r'((\w\w)_\w+)');

/**
 * Check to see if we have a "LANG" environment variable we can use and return
 * it if found. Otherwise return null;
 */
String _checkEnvironmentVariable() {
  try {
    return Platform.environment['LANG'];
  } catch (e) {};
  return null;
}

/**
 * Run the "defaults read -g AppleLocale" command and return the output in
 * a future.
 */
Future _getAppleDefaults() {
  var p = Process.run('defaults', ['read', '-g', 'AppleLocale']);
  var myResult = p.then((result) => _checkResult(result, _appleDefaultsRegex));
  return myResult;
}

/**
 * Given [result], find its text and extract the locale from it using
 * [regex], and set it as the system locale. If the process didn't run correctly
 * then don't set the variable and return a future that completes with null.
 */
Future<String> _checkResult(ProcessResult result, RegExp regex) {
  if (result.exitCode != 0) return new Future.value();
  var match = regex.firstMatch(result.stdout);
  if (match == null) return new Future.value();
  var locale = match.group(1);
  _setLocale(locale);
  return new Future.value(locale);
}

/**
 * Set [Intl.systemLocale] to be the canonicalizedLocale of [aLocale].
 */
Future<String> _setLocale(aLocale) {
  Intl.systemLocale = Intl.canonicalizedLocale(aLocale);
  return new Future.value(Intl.systemLocale);
}
