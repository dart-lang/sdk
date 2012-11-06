// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library colors;

const String GREEN_COLOR = '\u001b[32m';
const String RED_COLOR = '\u001b[31m';
const String MAGENTA_COLOR = '\u001b[35m';
const String NO_COLOR = '\u001b[0m';

String wrap(String string, String color) => "${color}$string${NO_COLOR}";
String green(String string) => wrap(string, GREEN_COLOR);
String red(String string) => wrap(string, RED_COLOR);
String magenta(String string) => wrap(string, MAGENTA_COLOR);
