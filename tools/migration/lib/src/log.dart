// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

final _cyan = _getSpecial('\u001b[36m');
final _green = _getSpecial('\u001b[32m');
final _magenta = _getSpecial('\u001b[35m');
final _red = _getSpecial('\u001b[31m');
final _yellow = _getSpecial('\u001b[33m');
final _blue = _getSpecial('\u001b[34m');
final _gray = _getSpecial('\u001b[1;30m');
final _none = _getSpecial('\u001b[0m');
final _noColor = _getSpecial('\u001b[39m');
final _bold = _getSpecial('\u001b[1m');

void done(Object message) {
  print("  ${green('(DONE)')} $message");
}

void note(Object message) {
  print("  ${cyan('(NOTE)')} $message");
}

void todo(Object message) {
  print("${red('(TODO)')} $message");
}

String bold(text) => "$_bold$text$_none";

String cyan(text) => "$_cyan$text$_noColor";

String green(text) => "$_green$text$_noColor";

String red(text) => "$_red$text$_noColor";

/// Gets a "special" string (ANSI escape or Unicode).
///
/// On Windows or when not printing to a terminal, returns something else since
/// those aren't supported.
String _getSpecial(String special, [String onWindows = '']) {
  if (Platform.operatingSystem == 'windows' ||
      stdioType(stdout) != StdioType.TERMINAL) {
    return onWindows;
  }

  return special;
}
