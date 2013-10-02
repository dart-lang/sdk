// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import 'dart:collection' show LinkedHashMap, Queue;

import '../common.dart';

import '../js/js.dart' as jsAst;

import '../closure.dart' show
    ClosureClassElement,
    ClosureClassMap,
    ClosureFieldElement;

import '../dart2jslib.dart' show
    CodeBuffer;

import '../elements/modelx.dart' show
    FunctionElementX;

import '../js/js.dart' show
    js;

import '../js_backend/js_backend.dart' show
    CheckedModeHelper,
    CheckedModeHelper,
    ConstantEmitter,
    JavaScriptBackend,
    JavaScriptBackend,
    Namer,
    NativeEmitter,
    RuntimeTypes,
    Substitution,
    TypeCheck,
    TypeChecks;

import '../source_file.dart' show
    SourceFile;

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

import '../util/uri_extras.dart' show
    relativize;

part 'class_builder.dart';
part 'closure_invocation_element.dart';
part 'code_emitter_task.dart';
part 'declarations.dart';
part 'reflection_data_parser.dart';
