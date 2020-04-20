// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

// This test ensures that the VM will support string literals that have non
// ascii characters. An unhandeld exception will be thrown if the VM fails
// to support non ascii characters.

main() {
  String canary = "Canary";
  String spades = "These are three black spades: ♠♠♠";
  String german = "German characters: aäbcdefghijklmnoöpqrsßtuüvwxyz";

  stdout.writeln(canary);
  stdout.writeln(spades);
  stdout.writeln(german);
  print(spades);
  print(german);

  stdout.add(canary.runes.toList());
  stdout.writeln();

  stdout.writeln(canary);
  stdout.writeln(spades);
  stdout.writeln(german);
  print(spades);
  print(german);

  stdout.add(canary.codeUnits);
  stdout.writeln();
}
