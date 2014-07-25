// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:template_binding/template_binding.dart' show templateBind;

// We use mirrors for illustration purposes, but ideally we would generate a
// static configuration with smoke/static.dart.
import 'package:smoke/mirrors.dart';

// Since we use smoke/mirrors, we need to preserve symbols used in the template.
// This includes String.startsWith, List.take, and Person.
@MirrorsUsed(targets: const [String, List, Person])
import 'dart:mirrors';

import 'person.dart';

main() {
  useMirrors();
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
