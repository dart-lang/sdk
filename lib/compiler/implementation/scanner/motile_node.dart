// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('motile'); // aka parser'
#import('scannerlib.dart');
#import('scanner_implementation.dart');
#import('../elements/elements.dart');
#import('node_scanner_bench.dart', prefix: 'node');
#import('scanner_bench.dart');
#source('parser_bench.dart');

class BaseParserBench extends node.NodeScannerBench {
}
