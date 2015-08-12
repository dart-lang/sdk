// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import '../common.dart';

import '../constants/values.dart';

import '../closure.dart' show
    ClosureClassElement,
    ClosureClassMap,
    ClosureFieldElement,
    CapturedVariable;

import '../dart_types.dart' show
    TypedefType;

import '../diagnostics/spannable.dart' show
    NO_LOCATION_SPANNABLE;

import '../elements/elements.dart' show
    ConstructorBodyElement,
    ElementKind,
    FieldElement,
    ParameterElement,
    TypeVariableElement,
    MethodElement,
    MemberElement;

import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;

import 'package:js_ast/src/precedence.dart' as js_precedence;

import '../js_backend/js_backend.dart' show
    CheckedModeHelper,
    CompoundName,
    ConstantEmitter,
    CustomElementsAnalysis,
    GetterName,
    JavaScriptBackend,
    JavaScriptConstantCompiler,
    Namer,
    RuntimeTypes,
    SetterName,
    Substitution,
    TypeCheck,
    TypeChecks,
    TypeVariableHandler;

import 'model.dart';
import 'program_builder/program_builder.dart';

import 'full_emitter/emitter.dart' as full_js_emitter;
import 'lazy_emitter/emitter.dart' as lazy_js_emitter;
import 'startup_emitter/emitter.dart' as startup_js_emitter;

import '../universe/universe.dart' show
    TypeMaskSet,
    TypedSelector;

import '../util/util.dart' show
    Setlet;

import '../deferred_load.dart' show
    OutputUnit;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import 'package:js_runtime/shared/embedded_names.dart' show JsBuiltin;

import '../native/native.dart' as native;

part 'class_stub_generator.dart';
part 'code_emitter_task.dart';
part 'helpers.dart';
part 'interceptor_stub_generator.dart';
part 'main_call_stub_generator.dart';
part 'metadata_collector.dart';
part 'native_emitter.dart';
part 'native_generator.dart';
part 'parameter_stub_generator.dart';
part 'runtime_type_generator.dart';
part 'type_test_registry.dart';
