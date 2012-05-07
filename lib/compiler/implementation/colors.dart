// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('colors');

final String GREEN_COLOR = '\u001b[32m';
final String RED_COLOR = '\u001b[31m';
final String MAGENTA_COLOR = '\u001b[35m';
final String NO_COLOR = '\u001b[0m';

// BUG(2654): This is a fairly hacky way of turning of coloring used
// in messages. It would be better if the coloring could be dealt with
// entirely by the user of the compiler API, but that is not the case
// today.
bool enabled = true;

String wrap(String string, String color)
    => enabled ? "${color}$string${NO_COLOR}" : string;
String green(String string)
    => wrap(string, GREEN_COLOR);
String red(String string)
    => wrap(string, RED_COLOR);
String magenta(String string)
    => wrap(string, MAGENTA_COLOR);
