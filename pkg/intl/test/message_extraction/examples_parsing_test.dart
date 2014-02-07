// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test for parsing the examples argument from an Intl.message call. Very
 * minimal so far.
 */
import 'package:unittest/unittest.dart';
import 'package:intl/extract_messages.dart';
import '../data_directory.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

main() {
  test("Message examples are correctly extracted", () {
    var file = path.join(
        intlDirectory,
        'test',
        'message_extraction',
        'sample_with_messages.dart');
    var messages = parseFile(new File(file));
    expect(messages['message2'].examples, {"x" : 3});
  });
}
