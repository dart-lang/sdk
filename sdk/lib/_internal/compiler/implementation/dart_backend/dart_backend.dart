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
import '../cps_ir/cps_ir_nodes.dart' as cps_ir;
import '../cps_ir/optimizers.dart';
import 'tree_ir_builder.dart' as tree_builder;
import 'tree_ir_nodes.dart' as tree_ir;
import '../util/util.dart';
import '../mirror_renamer/mirror_renamer.dart';
import 'logical_rewriter.dart' show LogicalRewriter;
import 'loop_rewriter.dart' show LoopRewriter;
import 'copy_propagator.dart' show CopyPropagator;
import 'statement_rewriter.dart' show StatementRewriter;
import 'backend_ast_emitter.dart' as backend_ast_emitter;
import 'backend_ast_nodes.dart' as backend_ast;
import 'backend_ast_to_frontend_ast.dart' as backend2frontend;

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
