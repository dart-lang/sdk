// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js;

import 'dart:async';
import 'dart:profiler' show
    UserTag;

import '../compiler_new.dart' as api;
import 'cache_strategy.dart';
import 'closure.dart' as closureMapping;
import 'compile_time_constants.dart';
import 'constants/constant_system.dart';
import 'constants/values.dart';
import 'core_types.dart';
import 'cps_ir/cps_ir_builder_task.dart' show IrBuilderTask;
import 'dart_backend/dart_backend.dart' as dart_backend;
import 'dart_types.dart';
import 'deferred_load.dart' show DeferredLoadTask, OutputUnit;
import 'diagnostic_listener.dart';
import 'dump_info.dart';
import 'enqueue.dart';
import 'elements/elements.dart';
import 'elements/modelx.dart'
    show ErroneousElementX,
         ClassElementX,
         CompilationUnitElementX,
         MethodElementX,
         LibraryElementX,
         PrefixElementX,
         VoidElementX,
         AnalyzableElement,
         DeferredLoaderGetterElementX;
import 'helpers/helpers.dart';  // Included for debug helpers.
import 'io/code_output.dart' show CodeBuffer;
import 'io/source_information.dart';
import 'js_backend/js_backend.dart' as js_backend;
import 'library_loader.dart'
    show LibraryLoader,
         LibraryLoaderTask,
         LoadedLibraries;
import 'messages.dart';
import 'mirrors_used.dart' show MirrorUsageAnalyzerTask;
import 'null_compiler_output.dart';
import 'native/native.dart' as native;
import 'patch_parser.dart';
import 'resolution/resolution.dart';
import 'scanner/scannerlib.dart';
import 'serialization/task.dart';
import 'script.dart';
import 'ssa/ssa.dart';
import 'tracer.dart' show Tracer;
import 'tree/tree.dart';
import 'typechecker.dart';
import 'types/types.dart' as ti;
import 'universe/universe.dart';
import 'util/characters.dart' show $_;
import 'util/uri_extras.dart' as uri_extras show relativize;
import 'util/util.dart';
import 'world.dart';

export 'helpers/helpers.dart';

part 'compiler.dart';
