// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

main() {
  String spades = "These are three black spades: ♠♠♠";
  String german = "German characters: aäbcdefghijklmnoöpqrsßtuüvwxyz";

  stdout.writeln(spades);
  stdout.writeln(german);
  print(spades);
  print(german);

  stdout.add(spades.runes.toList());
  stdout.writeln();
  stdout.add(german.runes.toList());
  stdout.writeln();

  stdout.add(spades.codeUnits);
  stdout.writeln();
  stdout.add(german.codeUnits);
  stdout.writeln();

  stdout.writeln(spades);
  stdout.writeln(german);
  print(spades);
  print(german);
}