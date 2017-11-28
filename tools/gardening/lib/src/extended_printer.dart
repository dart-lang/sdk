// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

typedef String ItemCallBack<T>(T item);

/// [ExtendedPrinter] provides helper and utility methods around print
/// functions.
class ExtendedPrinter {
  String preceding;
  final int width;

  ExtendedPrinter({this.preceding = "", this.width = 80});

  /// Prints to stdout. All preeceding characters will be placed before.
  void print(Object obj) {
    stdout.write(preceding);
    stdout.write(obj);
  }

  /// Prints to stdout followed by a line break. All preeceding characters will
  /// be placed before.
  void println(Object obj) {
    stdout.write(preceding);
    stdout.writeln(obj);
  }

  /// Prints a block by cutting at new lines and calls [println] for each line.
  void printBlock(String block) {
    block.split("\n").forEach(println);
  }

  /// Prints the [pattern] to stdout by writing the pattern as many times it can
  /// before width is reached.
  void printLinePattern(String pattern) {
    if (pattern.length == 0) {
      stdout.writeln();
    }
    stdout.writeln(pattern * (width ~/ pattern.length));
  }

  /// Prints an iterable while maintaining state for index and preceding.
  void printIterable<T>(Iterable<T> items, ItemCallBack cb,
      {ItemCallBack header,
      String separatorPattern: "",
      String itemPreceding: ""}) {
    bool isFirst = true;
    String previousPreceding = this.preceding;
    items.forEach((item) {
      if (isFirst && separatorPattern != null && separatorPattern.isNotEmpty) {
        printLinePattern(separatorPattern);
      }
      if (header != null) {
        println(header(item));
      }
      this.preceding = itemPreceding;
      printBlock(cb(item));
      println("");
      this.preceding = previousPreceding;
      isFirst = false;
    });
  }
}
