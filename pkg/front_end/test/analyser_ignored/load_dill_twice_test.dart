// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform, exit;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/text/ast_to_text.dart' show componentToString;

import 'package:kernel/kernel.dart' show Component;

import '../incremental_load_from_dill_suite.dart' show normalCompileToBytes;

main() async {
  List<int> bytes = await normalCompileToBytes(
      Platform.script.resolve("load_dill_twice_lib_1.dart"));

  Component c = new Component();
  new BinaryBuilder(bytes).readComponent(c);
  // Print once to lazy-load whatever it needs to lazy-load to print.
  // This *might* change the textual representation because references can be
  // created.
  componentToString(c);
  String loadedOnceString = componentToString(c);
  new BinaryBuilder(bytes).readComponent(c);
  String loadedTwiceString = componentToString(c);

  if (loadedOnceString != loadedTwiceString) {
    print("Loading the dill twice produces a different textual representation");
    List<String> linesOnce = loadedOnceString.split("\n");
    List<String> linesTwice = loadedTwiceString.split("\n");

    if (linesOnce.length != linesTwice.length) {
      print("Number of lines differ! "
          "(${linesOnce.length} vs ${linesTwice.length})");
    }

    // Do some simple and stupid diff.
    int i = 0;
    int j = 0;
    while (i < linesOnce.length || j < linesTwice.length) {
      if (i < linesOnce.length && j < linesTwice.length) {
        if (linesOnce[i] == linesTwice[j]) {
          i++;
          j++;
        } else {
          // Search for line from linesOnce in linesTwice
          bool good = false;
          for (int k = j + 1; k < linesTwice.length && k < j + 100; k++) {
            if (linesOnce[i] == linesTwice[k]) {
              // Inserted lines between j and k.
              for (int k2 = j; k2 < k; k2++) {
                print("+ ${linesTwice[k2]}");
              }
              i++;
              j = k + 1;
              good = true;
              break;
            }
          }
          if (!good) {
            // Assume lines deleted.
            print("- ${linesOnce[i]}");
            i++;
          }
        }
      } else if (i < linesOnce.length) {
        // Rest from linesOnce was deleted.
        for (; i < linesOnce.length; i++) {
          print("- ${linesOnce[i]}");
        }
      } else if (j < linesTwice.length) {
        // Rest from linesTwice was added.
        for (; j < linesTwice.length; j++) {
          print("+ ${linesTwice[j]}");
        }
      }
    }

    exit(1);
  }
  print("OK");
}
