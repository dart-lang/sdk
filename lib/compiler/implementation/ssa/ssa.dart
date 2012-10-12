// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('ssa');

#import('../closure.dart');
#import('../js/js.dart', prefix: 'js');
#import('../leg.dart');
#import('../source_file.dart');
#import('../source_map_builder.dart');
#import('../elements/elements.dart');
#import('../js_backend/js_backend.dart');
#import('../native_handler.dart', prefix: 'native');
#import('../runtime_types.dart');
#import('../scanner/scannerlib.dart');
#import('../tree/tree.dart');
#import('../types/types.dart');
#import('../universe/universe.dart');
#import('../util/util.dart');
#import('../util/characters.dart');

#source('bailout.dart');
#source('builder.dart');
#source('codegen.dart');
#source('codegen_helpers.dart');
#source('js_names.dart');
#source('nodes.dart');
#source('optimize.dart');
#source('types.dart');
#source('types_propagation.dart');
#source('validate.dart');
#source('variable_allocator.dart');
#source('value_range_analyzer.dart');
#source('value_set.dart');
