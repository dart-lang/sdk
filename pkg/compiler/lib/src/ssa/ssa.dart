// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import 'dart:collection';

import 'package:js_runtime/shared/embedded_names.dart';

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show
    CodegenRegistry,
    CodegenWorkItem;
import '../common/names.dart' show
    Identifiers,
    Selectors;
import '../common/tasks.dart' show
    CompilerTask;
import '../compiler.dart' show
    Compiler;
import '../constant_system_dart.dart';
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../core_types.dart' show
    CoreClasses;
import '../dart_types.dart';
import '../diagnostics/messages.dart' show
    Message,
    MessageTemplate;
import '../elements/elements.dart';
import '../elements/modelx.dart' show
    ConstructorBodyElementX,
    ElementX,
    VariableElementX;
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend_helpers.dart' show
    BackendHelpers;
import '../js_backend/js_backend.dart';
import '../js_emitter/js_emitter.dart' show
    CodeEmitterTask,
    NativeEmitter;
import '../native/native.dart' as native;
import '../resolution/operators.dart';
import '../resolution/semantic_visitor.dart';
import '../resolution/tree_elements.dart' show
    TreeElements;
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../types/constants.dart' show
    computeTypeMask;
import '../universe/call_structure.dart' show
    CallStructure;
import '../universe/selector.dart' show
    Selector;
import '../universe/side_effects.dart' show
    SideEffects;
import '../universe/use.dart' show
    DynamicUse,
    StaticUse,
    TypeUse;
import '../util/util.dart';
import '../world.dart' show
    ClassWorld,
    World;
import '../dump_info.dart' show InfoReporter;

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
