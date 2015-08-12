// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend;

import 'dart:async' show EventSink, Future;
import 'dart:collection' show HashMap;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import 'package:js_runtime/shared/embedded_names.dart' show JsGetName;

import '../closure.dart';
import '../common/backend_api.dart' show
    Backend;
import '../common/codegen.dart' show
    CodegenRegistry,
    CodegenWorkItem;
import '../common/registry.dart' show
    Registry;
import '../common/tasks.dart' show
    CompilerTask;
import '../common/resolution.dart' show
    ResolutionCallbacks;
import '../common/work.dart' show
    ItemCompilationContext;
import '../compiler.dart' show
    Compiler,
    isPrivateName;
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../dart_types.dart';
import '../diagnostics/invariant.dart' show
    invariant;
import '../diagnostics/messages.dart' show MessageKind;
import '../diagnostics/spannable.dart' show
    NO_LOCATION_SPANNABLE,
    Spannable,
    SpannableAssertionFailure;
import '../elements/elements.dart';
import '../elements/visitor.dart' show
    BaseElementVisitor;
import '../enqueue.dart' show
    Enqueuer,
    ResolutionEnqueuer,
    WorldImpact;
import '../io/code_output.dart';
import '../io/source_information.dart' show
    SourceInformationStrategy,
    useNewSourceInfo;
import '../io/position_information.dart' show
    PositionSourceInformationStrategy;
import '../io/start_end_information.dart' show
    StartEndSourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js/js_source_mapping.dart' show
    JavaScriptSourceInformationStrategy;
import '../js/rewrite_async.dart';
import '../js_emitter/js_emitter.dart' show
    ClassBuilder,
    CodeEmitterTask,
    Emitter,
    MetadataCollector,
    Placeholder,
    TokenFinalizer,
    USE_LAZY_EMITTER;
import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native;
import '../resolution/resolution.dart' show
    ResolutionRegistry,
    TreeElements;
import '../ssa/ssa.dart';
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/universe.dart';
import '../util/characters.dart';
import '../util/util.dart';
import '../world.dart' show
    ClassWorld;

import 'codegen/task.dart';
import 'constant_system_javascript.dart';
import 'patch_resolver.dart';

part 'backend.dart';
part 'checked_mode_helpers.dart';
part 'constant_emitter.dart';
part 'constant_handler_javascript.dart';
part 'custom_elements_analysis.dart';
part 'frequency_namer.dart';
part 'field_naming_mixin.dart';
part 'minify_namer.dart';
part 'namer.dart';
part 'namer_names.dart';
part 'no_such_method_registry.dart';
part 'runtime_types.dart';
part 'type_variable_handler.dart';
