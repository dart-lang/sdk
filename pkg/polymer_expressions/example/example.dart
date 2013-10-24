// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:template_binding/template_binding.dart' show templateBind;

import 'person.dart';

main() {
  new Logger('polymer_expressions').onRecord.listen((LogRecord r) {
    print("${r.loggerName} ${r.level} ${r.message}");
  });

  var john = new Person('John', 'Messerly', ['A', 'B', 'C']);
  var justin = new Person('Justin', 'Fagnani', ['D', 'E', 'F']);
  var globals = {
    'uppercase': (String v) => v.toUpperCase(),
    'people': [john, justin],
  };

  templateBind(querySelector('#test'))
      ..bindingDelegate = new PolymerExpressions(globals: globals)
      ..model = john;

  templateBind(querySelector('#test2')).model = john;
}
