// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library colors;

// See http://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes
const String RESET = '\u001b[0m';

// See http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
const String BLACK_COLOR = '\u001b[30m';
const String RED_COLOR = '\u001b[31m';
const String GREEN_COLOR = '\u001b[32m';
const String YELLOW_COLOR = '\u001b[33m';
const String BLUE_COLOR = '\u001b[34m';
const String MAGENTA_COLOR = '\u001b[35m';
const String CYAN_COLOR = '\u001b[36m';
const String WHITE_COLOR = '\u001b[37m';

String wrap(String string, String color) => "${color}$string${RESET}";

String black(String string) => wrap(string, BLACK_COLOR);
String red(String string) => wrap(string, RED_COLOR);
String green(String string) => wrap(string, GREEN_COLOR);
String yellow(String string) => wrap(string, YELLOW_COLOR);
String blue(String string) => wrap(string, BLUE_COLOR);
String magenta(String string) => wrap(string, MAGENTA_COLOR);
String cyan(String string) => wrap(string, CYAN_COLOR);
String white(String string) => wrap(string, WHITE_COLOR);
