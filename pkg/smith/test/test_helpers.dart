// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/minitest.dart';

import 'package:smith/smith.dart';

void expectParseError(String name, Map<String, dynamic> options, String error) {
  try {
    var configuration = Configuration.parse(name, options);
    fail("Expected FormatException but got $configuration.");
  } on FormatException catch (ex) {
    expect(ex.message, equals(error));
  }
}

void expectFormatError(String error, test()) {
  try {
    test();
  } on FormatException catch (e) {
    expect(e.message, equals(error));
    // This is the exception we expected, do nothing.
    return;
  } catch (e) {
    fail("Expected FormatException '$error' but got ${e.runtimeType}: $e");
  }
  fail("Expected exception '$error' did not occur");
}

void expectExpandError(
    String template, Map<String, dynamic> options, String error) {
  try {
    var configurations = Configuration.expandTemplate(template, options);
    fail("Expected FormatException but got $configurations.");
  } on FormatException catch (ex) {
    expect(ex.message, equals(error));
  }
}
