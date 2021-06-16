// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:meta/meta.dart';

void main(List<String> args) {}

class Subcommand {
  final String name;
  final String suffix;
  final String help;
  final ArgParser argParser;

  Subcommand(
      {@required this.name,
      this.suffix,
      @required this.help,
      @required this.argParser});
}
