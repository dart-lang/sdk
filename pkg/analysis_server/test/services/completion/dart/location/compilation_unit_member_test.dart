// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitMemberTest);
  });
}

@reflectiveTest
class CompilationUnitMemberTest extends AbstractCompletionDriverTest
    with CompilationUnitTestCases {}

mixin CompilationUnitTestCases on AbstractCompletionDriverTest {
  @FailingTest(reason: 'Unexpected AST structure with no suggestions.')
  Future<void> test_afterAbstract() async {
    await computeSuggestions('''
abstract ^
''');
    assertResponse(r'''
suggestions
  base
    kind: keyword
  class
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  mixin
    kind: keyword
''');
  }

  Future<void> test_afterAbstract_base_prefix() async {
    await computeSuggestions('''
abstract b^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  base
    kind: keyword
''');
  }

  Future<void> test_afterAbstract_beforeClass() async {
    await computeSuggestions('''
abstract ^ class A {}
''');
    assertResponse(r'''
suggestions
  base
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  mixin
    kind: keyword
''');
  }

  Future<void> test_afterAbstract_beforeMixinClass() async {
    await computeSuggestions('''
abstract ^ mixin class A {}
''');
    assertResponse('''
suggestions
  base
    kind: keyword
''');
  }

  @FailingTest(reason: 'Unexpected AST structure with no suggestions.')
  Future<void> test_afterBase() async {
    await computeSuggestions('''
abstract base ^
''');
    assertResponse(r'''
suggestions
  class
    kind: keyword
  mixin
    kind: keyword
''');
  }

  Future<void> test_afterBase_beforeClass() async {
    await computeSuggestions('''
base ^ class A {}
''');
    assertResponse(r'''
suggestions
  abstract
    kind: keyword
  mixin
    kind: keyword
''');
  }

  Future<void> test_afterBase_beforeClass_abstract() async {
    await computeSuggestions('''
abstract base ^ class A {}
''');
    assertResponse(r'''
suggestions
  mixin
    kind: keyword
''');
  }

  Future<void> test_afterBase_beforeMixin() async {
    await computeSuggestions('''
base ^ mixin A {}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_afterBase_beforeMixinClass() async {
    await computeSuggestions('''
base ^ mixin class A {}
''');
    assertResponse('''
suggestions
  abstract
    kind: keyword
''');
  }

  Future<void> test_afterBOF() async {
    await computeSuggestions('''
^
''');
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  library
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  part of '';
    kind: keyword
    selection: 9
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterBOF_beforeIdentifier() async {
    await computeSuggestions('''
^
imp
import "package:foo/foo.dart";
''');
    // TODO(danrubel): should not suggest declaration keywords
    // TODO(brianwilkerson): Should not suggest export or part directives.
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  library
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterBOF_beforeImport() async {
    await computeSuggestions('''
^
import foo;
''');
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  library
    kind: keyword
  part '';
    kind: keyword
    selection: 6
''');
  }

  Future<void> test_afterBOF_beforeImport_prefix() async {
    await computeSuggestions('''
imp^
import "package:foo/foo.dart";
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '';
    kind: keyword
    selection: 8
''');
  }

  Future<void> test_afterBOF_prefix() async {
    await computeSuggestions('''
cl^
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  class
    kind: keyword
''');
  }

  Future<void> test_afterBOF_suffix() async {
    await computeSuggestions('''
^imp
import "package:foo/foo.dart";
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  library
    kind: keyword
  part '';
    kind: keyword
    selection: 6
''');
  }

  Future<void> test_afterDeclaration_class() async {
    await computeSuggestions('''
class A {}
^
''');
    assertResponse(r'''
suggestions
  class
    kind: keyword
  const
    kind: keyword
  void
    kind: keyword
  final
    kind: keyword
  enum
    kind: keyword
  typedef
    kind: keyword
  abstract
    kind: keyword
  base
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  sealed
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterDeclaration_class_prefix() async {
    await computeSuggestions('''
class A {}
c^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
''');
  }

  Future<void> test_afterDirective_import() async {
    await computeSuggestions('''
import "foo";
^
''');
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterDirective_import_prefix() async {
    await computeSuggestions('''
import "foo";
c^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
''');
  }

  Future<void> test_afterFinal_beforeClass() async {
    await computeSuggestions('''
final ^ class A {}
''');
    assertResponse(r'''
suggestions
  abstract
    kind: keyword
''');
  }

  Future<void> test_afterFinal_beforeClass_abstract() async {
    await computeSuggestions('''
abstract final ^ class A {}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_afterInterface_beforeClass() async {
    await computeSuggestions('''
interface ^ class A {}
''');
    assertResponse('''
suggestions
  abstract
    kind: keyword
''');
  }

  Future<void> test_afterInterface_beforeClass_abstract() async {
    await computeSuggestions('''
abstract interface ^ class A {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLibraryDirective_beforeEnd() async {
    await computeSuggestions('''
library foo;^
''');
    assertResponse(r'''
suggestions
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  export '';
    kind: keyword
    selection: 8
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  import '';
    kind: keyword
    selection: 8
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLibraryDirective_prefix() async {
    await computeSuggestions('''
library a;
cl^
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  class
    kind: keyword
''');
  }

  Future<void> test_afterMixin_beforeClass() async {
    await computeSuggestions('''
mixin ^ class A {}
''');
    assertResponse(r'''
suggestions
  abstract
    kind: keyword
  base
    kind: keyword
''');
  }

  Future<void> test_afterPartOf() async {
    await computeSuggestions('''
part of foo;
^
''');
    // TODO(brianwilkerson): We should not be suggesting directives.
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterSealed_beforeClass() async {
    await computeSuggestions('''
sealed ^ class A {}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_afterWhitespaceAtBOF_suffix() async {
    await computeSuggestions('''
 ^imp
 import "package:foo/foo.dart";
 ''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  library
    kind: keyword
  part '';
    kind: keyword
    selection: 6
''');
  }

  Future<void> test_base_prefix() async {
    await computeSuggestions('''
b^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  base
    kind: keyword
''');
  }

  Future<void> test_beforeClass() async {
    await computeSuggestions('''
^ class A {}
''');
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  library
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  part of '';
    kind: keyword
    selection: 9
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_beforeMixin() async {
    await computeSuggestions('''
^ mixin M {}
''');
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  library
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  part of '';
    kind: keyword
    selection: 9
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_beforeMixin_afterClass() async {
    await computeSuggestions('''
class A {}
^ mixin M {}
''');
    assertResponse(r'''
suggestions
  class
    kind: keyword
  const
    kind: keyword
  void
    kind: keyword
  final
    kind: keyword
  enum
    kind: keyword
  typedef
    kind: keyword
  abstract
    kind: keyword
  base
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  sealed
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_beforeMixin_prefix_base() async {
    await computeSuggestions('''
b^ mixin M {}
''');
    assertResponse('''
replacement
  left: 1
suggestions
  base
    kind: keyword
''');
  }

  Future<void> test_beforeMixin_prefix_final() async {
    await computeSuggestions('''
f^ mixin M {}
''');
    assertResponse('''
replacement
  left: 1
suggestions
  final
    kind: keyword
''');
  }

  Future<void> test_beforeMixin_prefix_interface() async {
    await computeSuggestions('''
i^ mixin M {}
''');
    assertResponse('''
replacement
  left: 1
suggestions
  import '';
    kind: keyword
    selection: 8
  interface
    kind: keyword
''');
  }

  Future<void> test_beforeMixin_prefix_sealed() async {
    await computeSuggestions('''
s^ mixin M {}
''');
    assertResponse('''
replacement
  left: 1
suggestions
  sealed
    kind: keyword
''');
  }

  Future<void> test_betweenImports_prefix() async {
    await computeSuggestions('''
library bar;
import "zoo.dart";
imp^
import "package:foo/foo.dart";
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '';
    kind: keyword
    selection: 8
''');
  }

  Future<void> test_betweenLibraryAndImport_prefix() async {
    await computeSuggestions('''
library libA;
imp^
import "package:foo/foo.dart";
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '';
    kind: keyword
    selection: 8
''');
  }

  Future<void> test_empty() async {
    await computeSuggestions('''
^
''');
    assertResponse(r'''
suggestions
  import '';
    kind: keyword
    selection: 8
  export '';
    kind: keyword
    selection: 8
  abstract
    kind: keyword
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  enum
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  library
    kind: keyword
  mixin
    kind: keyword
  part '';
    kind: keyword
    selection: 6
  part of '';
    kind: keyword
    selection: 9
  sealed
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_enum_prefix() async {
    await computeSuggestions('''
enu^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  enum
    kind: keyword
''');
  }

  Future<void> test_final_prefix() async {
    await computeSuggestions('''
f^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  final
    kind: keyword
''');
  }

  Future<void> test_interface_prefix() async {
    await computeSuggestions('''
i^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  import '';
    kind: keyword
    selection: 8
  interface
    kind: keyword
''');
  }

  Future<void> test_mixin_prefix() async {
    await computeSuggestions('''
m^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  mixin
    kind: keyword
''');
  }

  Future<void> test_sealed_prefix() async {
    await computeSuggestions('''
s^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  sealed
    kind: keyword
''');
  }
}
