// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String upcase(String? s) {
  if (s == null) return '';
  return s.toUpperCase();
}

String format(dynamic thing) {
  if (thing is String?) return upcase(thing);
  if (thing is num) return '$thing';
  return '?';
}

main() {
  log(format(null));
  log(format('hello'));
  log(format([]));

  if (trace != '[][HELLO][?]') throw 'Unexpected: "$trace"';
}

String trace = '';

void log(String s) {
  trace += '[$s]';
}
