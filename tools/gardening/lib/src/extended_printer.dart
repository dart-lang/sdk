// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// [ExtendedPrinter] provides helper and utility methods around print
/// functions.
class ExtendedPrinter {
  final String preceeding;
  final int width;

  ExtendedPrinter({this.preceeding = "", this.width = 80});

  /// Prints to stdout. All preeceding characters will be placed before.
  void print(Object obj) {
    stdout.write(preceeding);
    stdout.write(obj);
  }

  /// Prints to stdout followed by a line break. All preeceding characters will
  /// be placed before.
  void println(Object obj) {
    stdout.write(preceeding);
    stdout.writeln(obj);
  }

  /// Prints the [pattern] to stdout by writing the pattern as many times it can
  /// before width is reached.
  void printLinePattern(String pattern) {
    if (pattern.length == 0) {
      stdout.writeln();
    }
    stdout.writeln(pattern * (width ~/ pattern.length));
  }
}
