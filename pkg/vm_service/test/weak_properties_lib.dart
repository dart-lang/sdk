// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'common/test_helper.dart';

class Foo {}

class Bar {}

late Expando expando;
late final Foo key;
late final Bar value;
dynamic weakProperty;

void script() {
  expando = Expando('some debug name');
  key = Foo();
  value = Bar();
  expando[key] = value;

  final expandoMirror = reflect(expando);
  final libcore = expandoMirror.type.owner as LibraryMirror;

  final entries = expandoMirror
      .getField(MirrorSystem.getSymbol('_data', libcore))
      .reflectee;
  weakProperty = entries.singleWhere((e) => e != null);
  print(weakProperty);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
