// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend;

import 'dart:async' show EventSink, Future;
import 'dart:collection' show HashMap;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import 'package:js_runtime/shared/embedded_names.dart' show JsGetName;

import '../closure.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
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
import '../js_emitter/js_emitter.dart'
    show ClassBuilder, CodeEmitterTask, Emitter, MetadataCollector, Placeholder,
        TokenFinalizer, USE_LAZY_EMITTER;

import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native;
import '../ssa/ssa.dart';
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/universe.dart';
import '../util/characters.dart';
import '../util/util.dart';

import '../elements/visitor.dart' show
    BaseElementVisitor;

import '../js_backend/codegen/task.dart';
import '../resolution/resolution.dart' show ResolutionRegistry;

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
