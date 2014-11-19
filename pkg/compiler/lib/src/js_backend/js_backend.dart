// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend;

import 'dart:async' show EventSink, Future;
import 'dart:collection' show Queue, LinkedHashMap, LinkedHashSet;

import 'package:_internal/compiler/js_lib/shared/embedded_names.dart' as embeddedNames;

import '../closure.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_emitter/js_emitter.dart'
    show Emitter, CodeEmitterTask, ClassBuilder, MetadataEmitter;
import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native;
import '../ssa/ssa.dart';
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/universe.dart';
import '../util/characters.dart';
import '../util/util.dart';

import '../elements/visitor.dart' show
    ElementVisitor;
import '../js_backend/codegen/task.dart';

part 'backend.dart';
part 'checked_mode_helpers.dart';
part 'constant_emitter.dart';
part 'constant_handler_javascript.dart';
part 'constant_system_javascript.dart';
part 'custom_elements_analysis.dart';
part 'minify_namer.dart';
part 'namer.dart';
part 'native_emitter.dart';
part 'runtime_types.dart';
part 'type_variable_handler.dart';
