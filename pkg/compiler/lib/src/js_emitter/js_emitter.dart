// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import '../common.dart';

import '../constants/expressions.dart';
import '../constants/values.dart';

import '../closure.dart' show
    ClosureClassElement,
    ClosureClassMap,
    ClosureFieldElement,
    CapturedVariable;

import '../dart_types.dart' show
    TypedefType;

import '../dart2jslib.dart' show
    CodeBuffer;

import '../elements/elements.dart' show
    ConstructorBodyElement,
    ElementKind,
    ParameterElement,
    TypeVariableElement;

import '../hash/sha1.dart' show hashOfString;

// import '../helpers/helpers.dart';  // Included for debug helpers.

import '../js/js.dart' as jsAst;
import '../js/js.dart' show
    js;

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

import 'model.dart';
import 'program_builder.dart';

import 'new_emitter/emitter.dart' as new_js_emitter;

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

import 'package:_internal/compiler/js_lib/shared/runtime_data.dart' as encoding;
import 'package:_internal/compiler/js_lib/shared/embedded_names.dart'
    as embeddedNames;

import '../hash/sha1.dart';

part 'class_stub_generator.dart';
part 'code_emitter_task.dart';
part 'helpers.dart';
part 'interceptor_stub_generator.dart';
part 'type_test_registry.dart';

part 'old_emitter/class_builder.dart';
part 'old_emitter/class_emitter.dart';
part 'old_emitter/code_emitter_helper.dart';
part 'old_emitter/container_builder.dart';
part 'old_emitter/declarations.dart';
part 'old_emitter/emitter.dart';
part 'old_emitter/interceptor_emitter.dart';
part 'old_emitter/metadata_emitter.dart';
part 'old_emitter/nsm_emitter.dart';
part 'old_emitter/reflection_data_parser.dart';
part 'old_emitter/type_test_emitter.dart';
