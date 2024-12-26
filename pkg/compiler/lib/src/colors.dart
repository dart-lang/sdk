// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

// See http://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes
const String reset = '\u001b[0m';

// See http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
const String blackColor = '\u001b[30m';
const String redColor = '\u001b[31m';
const String greenColor = '\u001b[32m';
const String yellowColor = '\u001b[33m';
const String blueColor = '\u001b[34m';
const String magentaColor = '\u001b[35m';
const String cyanColor = '\u001b[36m';
const String whiteColor = '\u001b[37m';

String wrap(String string, String color) => "$color$string$reset";

String black(String string) => wrap(string, blackColor);
String red(String string) => wrap(string, redColor);
String green(String string) => wrap(string, greenColor);
String yellow(String string) => wrap(string, yellowColor);
String blue(String string) => wrap(string, blueColor);
String magenta(String string) => wrap(string, magentaColor);
String cyan(String string) => wrap(string, cyanColor);
String white(String string) => wrap(string, whiteColor);
