// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('leg');

#import('dart:uri');

#import('dart_backend/dart_backend.dart', prefix: 'dart_backend');
#import('elements/elements.dart');
#import('native_handler.dart', prefix: 'native');
#import('scanner/scanner_implementation.dart');
#import('scanner/scannerlib.dart');
#import('ssa/ssa.dart');
#import('string_validator.dart');
#import('source_file.dart');
#import('tree/tree.dart');
#import('util/characters.dart');
#import('util/util.dart');
#import('../compiler.dart', prefix: 'api');

#source('compile_time_constants.dart');
#source('compiler.dart');
#source('diagnostic_listener.dart');
#source('emitter.dart');
#source('enqueue.dart');
#source('namer.dart');
#source('native_emitter.dart');
#source('operations.dart');
#source('resolved_visitor.dart');
#source('resolver.dart');
#source('script.dart');
#source('tree_validator.dart');
#source('typechecker.dart');
#source('universe.dart');
#source('unparse_validator.dart');
#source('warnings.dart');
#source('world.dart');
