// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../lib/docgen.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';

/**
 * Analyzes Dart files and generates a representation of included libraries, 
 * classes, and members. 
 */
void main() {
  var results = initArgParser().parse(new Options().arguments);
  new Docgen(results).analyze(listLibraries(results.rest));
}