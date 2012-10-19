// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scanner;

import 'dart:uri';

import 'scanner_implementation.dart';
import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../native_handler.dart' as native;
import '../string_validator.dart';
import '../tree/tree.dart';
import '../util/characters.dart';
import '../util/util.dart';
// TODO(ahe): Rename prefix to 'api' when VM bug is fixed.
import '../../compiler.dart' as api_s;

part 'class_element_parser.dart';
part 'keyword.dart';
part 'listener.dart';
part 'parser.dart';
part 'parser_task.dart';
part 'partial_parser.dart';
part 'scanner.dart';
part 'scanner_task.dart';
part 'string_scanner.dart';
part 'token.dart';
