// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('leg');

#import('dart:uri');

#import('closure.dart', prefix: 'closureMapping');
#import('dart_backend/dart_backend.dart', prefix: 'dart_backend');
#import('elements/elements.dart');
#import('js_backend/js_backend.dart', prefix: 'js_backend');
#import('native_handler.dart', prefix: 'native');
#import('scanner/scanner_implementation.dart');
#import('scanner/scannerlib.dart');
#import('ssa/ssa.dart');
#import('string_validator.dart');
#import('source_file.dart');
#import('tree/tree.dart');
#import('universe/universe.dart');
#import('util/characters.dart');
#import('util/util.dart');
#import('../compiler.dart', prefix: 'api');
#import('patch_parser.dart');
#import('types/types.dart', prefix: 'ti');

#source('code_buffer.dart');
#source('compile_time_constants.dart');
#source('compiler.dart');
#source('constants.dart');
#source('constant_system.dart');
#source('constant_system_dart.dart');
#source('diagnostic_listener.dart');
#source('enqueue.dart');
#source('library_loader.dart');
#source('resolved_visitor.dart');
#source('resolver.dart');
#source('script.dart');
#source('tree_validator.dart');
#source('typechecker.dart');
#source('warnings.dart');
#source('world.dart');
