// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import 'dart:collection';

import '../closure.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show ElementX,
         VariableElementX,
         ConstructorBodyElementX;
import '../helpers/helpers.dart';
import '../js/js.dart' as js;
import '../js_backend/js_backend.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../native/native.dart' as native;
import '../scanner/scannerlib.dart'
    show PartialFunctionElement, Token, PLUS_TOKEN;
import '../source_file.dart';
import '../source_map_builder.dart';
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../types/constants.dart' show computeTypeMask;
import '../universe/universe.dart';
import '../util/util.dart';
import '../js_backend/codegen/task.dart';

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
