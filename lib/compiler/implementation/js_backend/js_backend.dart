// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('js_backend');

#import('../closure.dart');
#import('../../compiler.dart', prefix: 'api');
#import('../elements/elements.dart');
#import('../leg.dart');
#import('../native_handler.dart', prefix: 'native');
#import('../scanner/scannerlib.dart');
#import('../source_file.dart');
#import('../source_map_builder.dart');
#import('../ssa/ssa.dart');
#import('../tree/tree.dart');
#import('../universe/universe.dart');
#import('../util/characters.dart');
#import('../util/util.dart');

#source('backend.dart');
#source('constant_emitter.dart');
#source('constant_system_javascript.dart');
#source('emitter.dart');
#source('namer.dart');
#source('native_emitter.dart');
