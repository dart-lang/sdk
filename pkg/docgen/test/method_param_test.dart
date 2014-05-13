// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.method_param;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import 'util.dart';
import '../lib/docgen.dart' as gen;

void main() {
  test('method function parameters', () {
    var lib_file = path.toUri(path.join(getMultiLibraryCodePath(), 'lib',
        'test_lib2.dart'));
    return gen.getMirrorSystem([lib_file], false)
      .then((mirrorSystem) {
        var library = new gen.Library(mirrorSystem.libraries[lib_file]);

        // Test that libraries do recursive exports correctly.
        var funcParams = library.functions['fooFunc'].parameters;
        expect('Symbol("dart.core.int")', library.functions['fooFunc']
            .parameters['fooFuncParam'].functionDeclaration.parameters['x']
            .type.mirror.qualifiedName.toString());
      });
  });
}