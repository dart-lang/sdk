// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/util.dart';
import 'package:args/args.dart';

/// AST Spelunker
void main([List<String> args]) {
  var parser = new ArgParser(allowTrailingOptions: true);

  var options = parser.parse(args);
  options.rest.forEach((path) => new Spelunker(path).spelunk());
}
