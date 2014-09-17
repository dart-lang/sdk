// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import 'dart:collection';

import '../closure.dart';
import '../cps_ir/const_expression.dart';
import '../js/js.dart' as js;
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../dart_types.dart';
import '../source_file.dart';
import '../source_map_builder.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
import '../native_handler.dart' as native;
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../universe/universe.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../util/util.dart';

import '../scanner/scannerlib.dart'
    show PartialFunctionElement, Token, PLUS_TOKEN;

import '../elements/modelx.dart'
    show ElementX,
         VariableElementX,
         ConstructorBodyElementX;

import '../js_emitter/js_emitter.dart' show CodeEmitterTask;

part 'builder.dart';
part 'codegen.dart';
part 'codegen_helpers.dart';
part 'interceptor_simplifier.dart';
part 'invoke_dynamic_specializers.dart';
part 'nodes.dart';
part 'optimize.dart';
part 'types.dart';
part 'types_propagation.dart';
part 'validate.dart';
part 'variable_allocator.dart';
part 'value_range_analyzer.dart';
part 'value_set.dart';
