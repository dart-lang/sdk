// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SharedDeferredPrefixTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SharedDeferredPrefixTest extends PubPackageResolutionTest {
  test_hasSharedDeferredPrefix() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
f1() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
f2() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as lib;
//                 ^^^^^^^^
// [diag.sharedDeferredPrefix] The prefix of a deferred import can't be used in other import directives.
import 'lib2.dart' as lib;
main() { lib.f1(); lib.f2(); }
''');
  }
}
