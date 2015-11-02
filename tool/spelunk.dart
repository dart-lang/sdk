// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:linter/src/util.dart';

/// AST Spelunker
void main([args]) {
  var parser = new ArgParser(allowTrailingOptions: true);

  var options = parser.parse(args);
  options.rest.forEach((path) => new Spelunker(path).spelunk());
}
