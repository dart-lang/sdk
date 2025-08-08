// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_testing/src/spelunker.dart';
import 'package:args/args.dart';

/// AST Spelunker
void main(List<String> args) {
  var parser = ArgParser();

  var options = parser.parse(args);
  for (var path in options.rest) {
    var source = File(path).readAsStringSync();
    Spelunker(source).spelunk();
  }
}
