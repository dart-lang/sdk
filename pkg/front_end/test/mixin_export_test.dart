// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:front_end/src/testing/compiler_common.dart';
import 'package:front_end/src/api_prototype/front_end.dart';

void main() {
  asyncTest(() async {
    var sources = <String, dynamic>{
      'a.dart': 'class A extends Object with M {}  mixin M {}',
      'b.dart': 'import "a.dart"; class B extends Object with M {}',
      'c.dart': 'export "a.dart"; export "b.dart";',
    };
    await compileUnit(sources.keys.toList(), sources,
        options: new CompilerOptions()
          ..onDiagnostic = (m) => throw m.plainTextFormatted.join("\n"));
  });
}
