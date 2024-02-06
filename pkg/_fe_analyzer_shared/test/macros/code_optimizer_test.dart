// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/code_optimizer.dart';
import 'package:test/test.dart';

void main() {
  group('Class |', () {
    group('Method |', () {
      group('Return type |', () {
        group('Not shadowed', () {
          test('Simple', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}
''');
          });

          test('Other class type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

class B<String> {}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}

class B<String> {}
''');
          });

          test('Other class method type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

class B {
  void bar<String>() {}
}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}

class B {
  void bar<String>() {}
}
''');
          });

          test('Other method formal parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  void bar(String) {}
}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
  void bar(String) {}
}
''');
          });

          test('Other method type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  void bar<String>() {}
}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
  void bar<String>() {}
}
''');
          });

          test('Sibling constructor', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  A.String();
  prefix0.String foo() {}
}
''', expected: r'''
58 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  A.String();
  String foo() {}
}
''');
          });

          test('Enum, type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

enum X<String> { v }
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}

enum X<String> { v }
''');
          });

          test('Extension, type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

extension X<String> on A {}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}

extension X<String> on A {}
''');
          });

          test('Extension type, type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

extension type X<String>(A it) {}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}

extension type X<String>(A it) {}
''');
          });

          test('Typedef, type parameter', () {
            assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

typedef F<String> = void Function();
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String foo() {}
}

typedef F<String> = void Function();
''');
          });
        });

        group('Shadowed | ', () {
          test('By local class, before', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class String {}

class A {
  prefix0.String foo() {}
}
''');
          });

          test('By local class, after', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

class String {}
''');
          });

          test('By local enum', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

enum String { v }
''');
          });

          test('By local extension', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

extension String on A {}
''');
          });

          test('By local extension type', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

extension type String(A it) {}
''');
          });

          test('By local function', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

void String() {}
''');
          });

          test('By local mixin', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

mixin String {}
''');
          });

          test('By local top-level variable, no initializer', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

int? String;
''');
          });

          test('By local top-level variable, with initializer', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

int String = 0;
''');
          });

          test('By local typedef', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

typedef String = void Function();
''');
          });

          test('By class type parameter', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A<String> {
  prefix0.String foo() {}
}
''');
          });

          test('By method formal parameter', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo<String>(String) {}
}
''');
          });

          test('By method type parameter', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo<String>() {}
}
''');
          });

          test('By sibling getter', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  int get String {}
}
''');
          });

          test('By sibling setter', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  set String(_) {}
}
''');
          });

          test('By sibling method', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  void String() {}
}
''');
          });

          test('Other class method', () {
            // This rarely causes actual shadowing, but still might, if
            // we invoke `String()` from a subclass `C` of `B`. If we import
            // `dart:core` without an import prefix, inside `C` the meaning
            // of `String()` will change to invoking the `dart:core@String`
            // constructor.
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

class B {
  void String() {}
}
''');
          });

          test('By sibling field, no initializer', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  int String;
}
''');
          });

          test('By sibling field, with initializer', () {
            assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
  int String = 0;
}
''');
          });
        });
      });
    });
  });
}

const _dartImports = {
  'dart:core': {'bool', 'double', 'int', 'String'},
};

void assertEdits({
  Map<String, Set<String>> importedNames = const {},
  required String code,
  required String expected,
  bool throwIfHasErrors = true,
}) {
  var optimizer = _CodeOptimizer(
    importedNames: {
      ..._dartImports,
      ...importedNames,
    },
  );

  var edits = optimizer.optimize(
    code,
    throwIfHasErrors: throwIfHasErrors,
  );

  var buffer = StringBuffer();
  for (var edit in edits) {
    buffer.write('${edit.offset} +${edit.length}');

    var toReplace = code.substring(edit.offset, edit.offset + edit.length);
    buffer.write(' |${escape(toReplace)}|');

    buffer.writeln(' -> |${escape(edit.replacement)}|');
  }

  var optimized = Edit.applyList(edits, code);
  buffer.writeln('-' * 16);
  buffer.write(optimized);

  var actual = buffer.toString();
  if (actual != expected) {
    print('-------- Actual --------');
    print('$actual------------------------');
    fail('Not as expected');
  }
}

void assertEditsNoChanges({
  Map<String, Set<String>> importedNames = const {},
  required String code,
  bool throwIfHasErrors = true,
}) {
  assertEdits(
    importedNames: importedNames,
    code: code,
    throwIfHasErrors: throwIfHasErrors,
    expected: '${'-' * 16}\n$code',
  );
}

class _CodeOptimizer extends CodeOptimizer {
  final Map<String, Set<String>> importedNames;

  _CodeOptimizer({
    required this.importedNames,
  });

  @override
  Set<String> getImportedNames(String uriStr) {
    return importedNames[uriStr] ?? (throw StateError('Unexpected: $uriStr'));
  }
}
