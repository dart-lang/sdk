#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';

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
  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var source = resourceProvider.getFile(file.path).createSource();
  var reader = new CharSequenceReader(src);
  var listener = new BooleanErrorListener();
  var scanner = new Scanner(source, reader, listener);
  var token = scanner.tokenize();
  while (token.type != TokenType.EOF) {
    print(token);
    token = token.next;
  }
  if (listener.errorReported) {
    print('Errors found.');
    exit(1);
  }
}
