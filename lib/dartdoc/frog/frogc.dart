// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('lang.dart', prefix: 'lang');
#import('frog_leg.dart', prefix: 'leg');
#import('minfrogc.dart', prefix: 'minfrogc');

void main() {
  lang.legCompile = leg.compile;
  try {
    minfrogc.main();
  } catch (var exception, var trace) {
    try {
      print('Internal error: $exception');
    } catch (var ignored) {
      print('Internal error: error while printing exception');
    }
    try {
      print(trace);
    } finally {
      exit(253);
    }
  }
}
