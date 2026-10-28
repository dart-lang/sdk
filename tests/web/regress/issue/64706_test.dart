// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for https://dartbug.com/64706
//
// Hoisting a common constant phi input into an HTry block caused the variable
// initialization and declaration to be omitted during code generation.

import 'dart:async';

import 'package:expect/expect.dart';

class ServerError implements Exception {
  final String code;
  ServerError(this.code);
}

class Example {
  String? note;
  void update(void Function() callback) => callback();

  Future<String?> extract() async {
    if (DateTime.now().toString() == 'server') throw ServerError('unavailable');
    return 'draft';
  }

  Future<String> send() async {
    String? problem;
    String? code;
    String? result;
    try {
      result = await extract();
      if (result == null) problem = 'no draft';
    } on ServerError catch (error) {
      code = error.code;
      problem = switch (error.code) {
        'a' => 'one',
        _ => 'two',
      };
    }
    if (result == null && problem != null && code == null) code = 'unavailable';
    final status = problem != null ? 'FAILED ($code)' : 'ok ($result)';
    if (problem != null) {
      update(() {
        note = code == null ? problem : '$problem ($code)';
      });
    }
    return status;
  }
}

Future<void> main() async {
  Expect.equals('ok (draft)', await Example().send());
}
