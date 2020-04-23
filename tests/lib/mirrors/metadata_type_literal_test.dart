// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Foo {}

class Annotation {
  final Object bindings;
  const Annotation(this.bindings);
}

@Annotation(Foo)
class Annotated {}

main(List<String> args) {
  ClassMirror mirror = reflectType(Annotated) as ClassMirror;
  Expect.equals("ClassMirror on 'Annotated'", mirror.toString());

  var bindings = mirror.metadata[0].reflectee.bindings;
  Expect.equals('Foo', bindings.toString());
}
