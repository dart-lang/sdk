// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js;

import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:profiler' show
    UserTag;

import '../compiler.dart' as api;
import 'cache_strategy.dart';
import 'closure.dart' as closureMapping;
import 'compile_time_constants.dart';
import 'constant_system_dart.dart';
import 'constants/constant_system.dart';
import 'constants/expressions.dart';
import 'constants/values.dart';
import 'core_types.dart';
import 'cps_ir/cps_ir_builder_task.dart' show IrBuilderTask;
import 'dart_backend/dart_backend.dart' as dart_backend;
import 'dart_types.dart';
import 'deferred_load.dart' show DeferredLoadTask, OutputUnit;
import 'dump_info.dart';
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
import 'js/js.dart' as js;
import 'js_backend/js_backend.dart' as js_backend;
import 'library_loader.dart'
    show LibraryLoader,
         LibraryLoaderTask,
         LoadedLibraries;
import 'mirrors_used.dart' show MirrorUsageAnalyzerTask;
import 'native/native.dart' as native;
import 'ordered_typeset.dart';
import 'patch_parser.dart';
import 'resolution/class_members.dart' show MembersCreator;
import 'resolution/resolution.dart';
import 'resolution/semantic_visitor.dart';
import 'resolution/send_structure.dart';
import 'resolution/operators.dart' as op;
import 'scanner/scannerlib.dart';
import 'ssa/ssa.dart';
import 'io/source_file.dart' show SourceFile;
import 'tracer.dart' show Tracer;
import 'tree/tree.dart';
import 'types/types.dart' as ti;
import 'universe/universe.dart';
import 'util/characters.dart' show $_;
import 'util/uri_extras.dart' as uri_extras show relativize;
import 'util/util.dart';
import 'dart_backend/dart_backend.dart';

export 'helpers/helpers.dart';
export 'resolution/resolution.dart' show TreeElements, TreeElementMapping;
export 'scanner/scannerlib.dart' show isUserDefinableOperator,
                                      isUnaryOperator,
                                      isBinaryOperator,
                                      isTernaryOperator,
                                      isMinusOperator;
export 'universe/universe.dart' show CallStructure, Selector, TypedSelector;
export 'util/util.dart'
    show Spannable,
         CURRENT_ELEMENT_SPANNABLE,
         NO_LOCATION_SPANNABLE;

part 'compiler.dart';
part 'diagnostic_listener.dart';
part 'enqueue.dart';
part 'resolved_visitor.dart';
part 'script.dart';
part 'typechecker.dart';
part 'warnings.dart';
part 'world.dart';
