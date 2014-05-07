// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_backend;

import 'dart:async' show Future;
import '../elements/elements.dart';
import '../elements/modelx.dart' show SynthesizedConstructorElementX;
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../tree/tree.dart';
import '../ir/ir_nodes.dart' as ir;
import 'dart_tree.dart' as tree;
import '../util/util.dart';
import '../mirror_renamer/mirror_renamer.dart';
import 'dart_codegen.dart' as dart_codegen;

import '../scanner/scannerlib.dart' show StringToken,
                                         Keyword,
                                         OPEN_PAREN_INFO,
                                         CLOSE_PAREN_INFO,
                                         SEMICOLON_INFO,
                                         IDENTIFIER_INFO;

part 'backend.dart';
part 'emitter.dart';
part 'renamer.dart';
part 'placeholder_collector.dart';
