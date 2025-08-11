// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/checks/check_all_yaml.dart';
import '../tool/checks/check_messages_yaml.dart';

void main() {
  test('examples/all.yaml is correct', () {
    var errors = checkAllYaml();
    if (errors != null) {
      fail(errors);
    }
  });

  test('messages.yaml is correct', checkMessagesYaml);
}
