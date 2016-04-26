// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend;

import 'dart:async' show Future;
import 'dart:collection' show HashMap;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import 'package:js_runtime/shared/embedded_names.dart' show JsGetName;

import '../closure.dart';
import '../common.dart';
import '../common/backend_api.dart'
    show Backend, ImpactTransformer, ForeignResolver;
import '../common/codegen.dart' show CodegenImpact, CodegenWorkItem;
import '../common/names.dart' show Identifiers, Names, Selectors, Uris;
import '../common/registry.dart' show EagerRegistry, Registry;
import '../common/resolution.dart'
    show
        Feature,
        Frontend,
        ListLiteralUse,
        MapLiteralUse,
        Resolution,
        ResolutionImpact;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart' show ItemCompilationContext;
import '../compile_time_constants.dart';
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../core_types.dart' show CoreClasses, CoreTypes;
import '../dart_types.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../diagnostics/invariant.dart' show DEBUG_MODE;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/elements.dart';
import '../elements/modelx.dart' show ConstructorBodyElementX;
import '../elements/visitor.dart' show BaseElementVisitor;
import '../enqueue.dart' show Enqueuer, ResolutionEnqueuer;
import '../io/code_output.dart';
import '../io/position_information.dart' show PositionSourceInformationStrategy;
import '../io/source_information.dart' show SourceInformationStrategy;
import '../io/start_end_information.dart'
    show StartEndSourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js/js_source_mapping.dart' show JavaScriptSourceInformationStrategy;
import '../js/rewrite_async.dart';
import '../js_emitter/js_emitter.dart'
    show CodeEmitterTask, MetadataCollector, Placeholder;
import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native;
import '../resolution/tree_elements.dart' show TreeElements;
import '../ssa/builder.dart' show SsaFunctionCompiler;
import '../ssa/codegen.dart' show SsaCodeGenerator;
import '../ssa/nodes.dart' show HTypeConversion, HInstruction;
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector, SelectorKind;
import '../universe/universe.dart';
import '../universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import '../universe/world_impact.dart'
    show
        ImpactStrategy,
        ImpactUseCase,
        TransformedWorldImpact,
        WorldImpact,
        WorldImpactVisitor;
import '../util/characters.dart';
import '../util/util.dart';
import '../world.dart' show ClassWorld;
import 'backend_helpers.dart';
import 'backend_impact.dart';
import 'backend_serialization.dart' show JavaScriptBackendSerialization;
import 'codegen/task.dart';
import 'constant_system_javascript.dart';
import 'js_interop_analysis.dart' show JsInteropAnalysis;
import 'lookup_map_analysis.dart' show LookupMapAnalysis;
import 'native_data.dart' show NativeData;
import 'patch_resolver.dart';

part 'backend.dart';
part 'checked_mode_helpers.dart';
part 'constant_emitter.dart';
part 'constant_handler_javascript.dart';
part 'custom_elements_analysis.dart';
part 'field_naming_mixin.dart';
part 'frequency_namer.dart';
part 'minify_namer.dart';
part 'namer.dart';
part 'namer_names.dart';
part 'no_such_method_registry.dart';
part 'runtime_types.dart';
part 'type_variable_handler.dart';
