// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('colors');

final String GREEN_COLOR = '\u001b[32m';
final String RED_COLOR = '\u001b[31m';
final String MAGENTA_COLOR = '\u001b[35m';
final String NO_COLOR = '\u001b[0m';

String green(String string) => "${GREEN_COLOR}$string${NO_COLOR}";
String red(String string) => "${RED_COLOR}$string${NO_COLOR}";
String magenta(String string) => "${MAGENTA_COLOR}$string${NO_COLOR}";
