// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'doc_comment_test.dart' as doc_comment;
import 'extension_type_test.dart' as extension_type;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    doc_comment.main();
    extension_type.main();
  }, name: 'parser');
}
