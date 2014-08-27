// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js;

import 'dart:async';
import 'dart:collection' show Queue;

import 'dart:profiler' show
    UserTag;

import 'closure.dart' as closureMapping;
import 'dart_backend/dart_backend.dart' as dart_backend;
import 'dart_types.dart';
import 'elements/elements.dart';
import 'elements/modelx.dart'
    show ErroneousElementX,
         ClassElementX,
         CompilationUnitElementX,
         LibraryElementX,
         PrefixElementX,
         VoidElementX,
         AnalyzableElement,
         DeferredLoaderGetterElementX;
import 'helpers/helpers.dart';  // Included for debug helpers.
import 'js_backend/js_backend.dart' as js_backend;
import 'library_loader.dart'
    show LibraryLoader,
         LibraryLoaderTask;
import 'native_handler.dart' as native;
import 'scanner/scannerlib.dart';
import 'ssa/ssa.dart';
import 'tree/tree.dart';
import 'cps_ir/cps_ir_builder.dart' show IrBuilderTask;
import 'universe/universe.dart';
import 'util/util.dart';
import 'util/characters.dart' show $_;
import 'ordered_typeset.dart';
import '../compiler.dart' as api;
import 'patch_parser.dart';
import 'types/types.dart' as ti;
import 'resolution/resolution.dart';
import 'resolution/class_members.dart' show MembersCreator;
import 'source_file.dart' show SourceFile;
import 'js/js.dart' as js;
import 'deferred_load.dart' show DeferredLoadTask, OutputUnit;
import 'mirrors_used.dart' show MirrorUsageAnalyzerTask;
import 'dump_info.dart';
import 'tracer.dart' show Tracer;
import 'cache_strategy.dart';

export 'resolution/resolution.dart' show TreeElements, TreeElementMapping;
export 'scanner/scannerlib.dart' show isUserDefinableOperator,
                                      isUnaryOperator,
                                      isBinaryOperator,
                                      isTernaryOperator,
                                      isMinusOperator;
export 'universe/universe.dart' show Selector, TypedSelector;
export 'util/util.dart'
    show Spannable,
         CURRENT_ELEMENT_SPANNABLE,
         NO_LOCATION_SPANNABLE;
export 'helpers/helpers.dart';

part 'code_buffer.dart';
part 'compile_time_constants.dart';
part 'compiler.dart';
part 'constants.dart';
part 'constant_system.dart';
part 'constant_system_dart.dart';
part 'diagnostic_listener.dart';
part 'enqueue.dart';
part 'resolved_visitor.dart';
part 'script.dart';
part 'tree_validator.dart';
part 'typechecker.dart';
part 'warnings.dart';
part 'world.dart';
