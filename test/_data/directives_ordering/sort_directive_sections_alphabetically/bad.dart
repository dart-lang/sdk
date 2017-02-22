// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async'; // OK
import 'dart:html'; // OK
import 'dart:convert'; // LINT
import 'dart:math'; // OK

import 'package:async/async.dart'; // OK
import 'package:yaml/yaml.dart'; // OK
import 'package:charcode/ascii.dart'; // LINT
import 'package:ansicolor/ansicolor.dart'; // LINT

import 'package:linter/src/analyzer.dart'; // OK
import 'package:linter/src/ast.dart'; // OK
import 'package:linter/src/rules.dart'; // OK
import 'package:linter/src/formatter.dart'; // LINT

import 'dummy4.dart'; // OK
import 'dummy4.dart'; // OK
import 'dummy3.dart'; // LINT
import 'dummy3.dart'; // OK
import 'dummy2.dart'; // LINT
import 'dummy2.dart'; // OK
import 'dummy1.dart'; // LINT
import 'dummy1.dart'; // OK

export 'dummy4.dart'; // OK
export 'dummy1.dart'; // LINT
export 'dummy2.dart'; // OK
export 'dummy3.dart'; // OK
