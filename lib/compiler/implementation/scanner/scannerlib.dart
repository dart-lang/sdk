// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('scanner');

#import('scanner_implementation.dart');
#import('../../../uri/uri.dart');
#import('../elements/elements.dart');
#import('../leg.dart');
#import('../native_handler.dart', prefix: 'native');
#import('../string_validator.dart');
#import('../tree/tree.dart');
#import('../util/characters.dart');
#import('../util/util.dart');

#source('class_element_parser.dart');
#source('keyword.dart');
#source('listener.dart');
#source('parser.dart');
#source('parser_task.dart');
#source('partial_parser.dart');
#source('scanner.dart');
#source('scanner_task.dart');
#source('string_scanner.dart');
#source('token.dart');
