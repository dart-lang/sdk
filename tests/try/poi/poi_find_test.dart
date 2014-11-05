// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that poi.dart finds the right element.

library trydart.poi_find_test;

import 'dart:io' show
    Platform;

import 'dart:async' show
    Future;

import 'package:try/poi/poi.dart' as poi;

import 'package:async_helper/async_helper.dart';

import 'package:expect/expect.dart';

import 'package:compiler/src/elements/elements.dart' show
    Element;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

Future testPoi() {
  Uri script = Platform.script.resolve('data/empty_main.dart');
  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();
  handler.verbose = false;

  Future future = poi.runPoi(script, 225, handler.provider, handler);
  return future.then((Element element) {
    Uri foundScript = element.compilationUnit.script.resourceUri;
    Expect.stringEquals('$script', '$foundScript');
    Expect.stringEquals('main', element.name);

    String source = handler.provider.sourceFiles['$script'].slowText();
    final int position = source.indexOf('main()');
    Expect.isTrue(position > 0, '$position > 0');

    var token;

    // When the cursor is at the same character offset as "main()", it
    // corresponds to having the cursor just before "main()". So we find the
    // "void" token.
    token = poi.findToken(element, position);
    Expect.isNotNull(token, 'token');
    Expect.stringEquals('void', token.value);

    // Cursor at position + 1 corresponds to having the cursor just after "m"
    // in "main()". So we find the "main" token.
    token = poi.findToken(element, position + 1);
    Expect.isNotNull(token, 'token');
    Expect.equals(position, token.charOffset);
    Expect.stringEquals('main', token.value);

    // This corresponds to the cursor after "main", but before "()" in
    // "main()". So we find the "main" token.
    token = poi.findToken(element, position + 4);
    Expect.isNotNull(token, 'token');
    Expect.equals(position, token.charOffset);
    Expect.stringEquals('main', token.value);

    // This corresponds to the cursor after "(" in "main()". So we find the "("
    // token.
    token = poi.findToken(element, position + 5);
    Expect.isNotNull(token, 'token');
    Expect.equals(position + 4, token.charOffset, '$token');
    Expect.stringEquals('(', token.value);
  });
}

void main() {
  asyncTest(testPoi);
}
