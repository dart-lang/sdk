// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import '../common.dart';

import '../js/js.dart' as jsAst;

import '../closure.dart' show
    ClosureClassElement,
    ClosureClassMap,
    ClosureFieldElement;

import '../dart2jslib.dart' show
    CodeBuffer;

import '../elements/elements.dart' show
    TypeVariableElement,
    ConstructorBodyElement;

import '../js/js.dart' show
    js, templateManager;

import '../js_backend/js_backend.dart' show
    CheckedModeHelper,
    ConstantEmitter,
    CustomElementsAnalysis,
    JavaScriptBackend,
    JavaScriptConstantCompiler,
    Namer,
    NativeEmitter,
    RuntimeTypes,
    Substitution,
    TypeCheck,
    TypeChecks,
    TypeVariableHandler;

import '../source_file.dart' show
    SourceFile,
    StringSourceFile;

import '../source_map_builder.dart' show
    SourceMapBuilder;

import '../util/characters.dart' show
    $$,
    $A,
    $HASH,
    $PERIOD,
    $Z,
    $a,
    $z;

import '../util/util.dart' show
    NO_LOCATION_SPANNABLE;

import '../util/uri_extras.dart' show
    relativize;

import '../util/util.dart' show
    equalElements;

import '../deferred_load.dart' show
    OutputUnit;

part 'class_builder.dart';
part 'class_emitter.dart';
part 'code_emitter_helper.dart';
part 'code_emitter_task.dart';
part 'container_builder.dart';
part 'declarations.dart';
part 'helpers.dart';
part 'interceptor_emitter.dart';
part 'metadata_emitter.dart';
part 'nsm_emitter.dart';
part 'reflection_data_parser.dart';
part 'type_test_emitter.dart';
