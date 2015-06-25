// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import 'dart:convert';
import 'dart:collection' show HashMap;

import '../common.dart';

import '../constants/values.dart';

import '../closure.dart' show
    ClosureClassElement,
    ClosureClassMap,
    ClosureFieldElement,
    CapturedVariable;

import '../dart_types.dart' show
    TypedefType;

import '../io/code_output.dart';

import '../elements/elements.dart' show
    ConstructorBodyElement,
    ElementKind,
    FieldElement,
    ParameterElement,
    TypeVariableElement,
    MethodElement,
    MemberElement;

import '../hash/sha1.dart' show Hasher;

import '../js/js.dart' as jsAst;
import '../js/js.dart' show
    js;

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
import 'program_builder.dart';

import 'new_emitter/emitter.dart' as new_js_emitter;

import '../io/line_column_provider.dart' show
    LineColumnCollector,
    LineColumnProvider;

import '../io/source_map_builder.dart' show
    SourceMapBuilder;

import '../universe/universe.dart' show
    TypeMaskSet,
    TypedSelector;

import '../util/characters.dart' show
    $$,
    $A,
    $HASH,
    $PERIOD,
    $Z,
    $a,
    $z;

import '../util/util.dart' show
    NO_LOCATION_SPANNABLE,
    Setlet;

import '../util/uri_extras.dart' show
    relativize;

import '../util/util.dart' show
    equalElements;

import '../deferred_load.dart' show
    OutputUnit;

import 'package:_internal/compiler/js_lib/shared/embedded_names.dart'
    as embeddedNames;
import 'package:_internal/compiler/js_lib/shared/embedded_names.dart' show
    JsBuiltin;

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

part 'old_emitter/class_builder.dart';
part 'old_emitter/class_emitter.dart';
part 'old_emitter/code_emitter_helper.dart';
part 'old_emitter/container_builder.dart';
part 'old_emitter/declarations.dart';
part 'old_emitter/emitter.dart';
part 'old_emitter/interceptor_emitter.dart';
part 'old_emitter/nsm_emitter.dart';
part 'old_emitter/setup_program_builder.dart';
