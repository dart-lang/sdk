#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/generated/scanner.dart';

main(List<String> args) {

  print('working dir ${new File('.').resolveSymbolicLinksSync()}');

  if (args.length == 0) {
    print('Usage: scanner_driver [files_to_scan]');
    exit(0);
  }

  for (var arg in args) {
    _scan(new File(arg));
  }

}

_scan(File file) {
  var src = file.readAsStringSync();
  var reader = new CharSequenceReader(src);
  var scanner = new Scanner(null, reader, null);
  var token = scanner.tokenize();
  while (token.type != TokenType.EOF) {
    print(token);
    token = token.next;
  }
}
