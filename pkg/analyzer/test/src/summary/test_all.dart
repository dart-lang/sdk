// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'api_signature_test.dart' as api_signature;
import 'elements/test_all.dart' as elements;
import 'flat_buffers_test.dart' as flat_buffers;
import 'macro_test.dart' as macro;
import 'reference_test.dart' as reference;
import 'top_level_inference_test.dart' as top_level_inference;

main() {
  defineReflectiveSuite(() {
    api_signature.main();
    elements.main();
    flat_buffers.main();
    macro.main();
    reference.main();
    top_level_inference.main();
  }, name: 'summary');
}
