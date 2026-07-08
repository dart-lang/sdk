// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: overridden_fields

import 'common/test_helper.dart';
import 'evaluate_activation_in_method_class_other.dart';

var topLevel = 'TestLibrary';

class Subclass extends Superclass1 {
  final _instVar = 'Subclass';
  @override
  var instVar = 'Subclass';
  @override
  String method() => 'Subclass';
  static String staticMethod() => 'Subclass';
  @override
  String suppressWarning() => _instVar;
}

void testeeDo() {
  final obj = Subclass();
  obj.test();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeDo);
}
