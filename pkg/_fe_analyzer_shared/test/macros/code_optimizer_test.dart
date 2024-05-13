// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/code_optimizer.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:test/test.dart';

void main() {
  group('Function |', () {
    test('From dart:core', () {
      assertEdits(code: r'''
import 'dart:core' as prefix0;

void foo() {
  prefix0.print(42);
}
''', expected: r'''
RemoveImportPrefixDeclarationEdit
  18 +11 | as prefix0|
RemoveImportPrefixReferenceEdit
  47 +8 |prefix0.|
----------------
import 'dart:core';

void foo() {
  print(42);
}
''');
    });

    test('Shadowed by local variable', () {
      assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

void foo() {
  prefix0.print(42);
  int print;
}
''');
    });

    test('Shadowed by unqualified identifier', () {
      assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  void foo() {
    prefix0.print(42);
    print(); // could be from super
  }
}
''');
    });
  });

  group('Variable |', () {
    test('From dart:math', () {
      assertEdits(code: r'''
import 'dart:math' as prefix0;

void foo() {
  prefix0.pi;
}
''', expected: r'''
RemoveImportPrefixDeclarationEdit
  18 +11 | as prefix0|
RemoveImportPrefixReferenceEdit
  47 +8 |prefix0.|
----------------
import 'dart:math';

void foo() {
  pi;
}
''');
    });

    test('Shadowed by local variable', () {
      assertEditsNoChanges(code: r'''
import 'dart:math' as prefix0;

void foo() {
  prefix0.pi;
  int pi;
}
''');
    });

    test('Shadowed by unqualified identifier', () {
      assertEditsNoChanges(code: r'''
import 'dart:math' as prefix0;

class A {
  void foo() {
    prefix0.pi;
    pi; // could be from super
  }
}
''');
    });
  });

  group('NamedType |', () {
    group('Not shadowed |', () {
      test('Last import, dart:core', () {
        assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}
''', expected: r'''
RemoveImportPrefixDeclarationEdit
  18 +11 | as prefix0|
RemoveImportPrefixReferenceEdit
  44 +8 |prefix0.|
----------------
import 'dart:core';

class A {
  String foo() {}
}
''');
      });

      test('Last import, dart:math', () {
        assertEdits(code: r'''
import 'dart:math' as prefix0;

class A {
  prefix0.Random foo() {}
}
''', expected: r'''
RemoveImportPrefixDeclarationEdit
  18 +11 | as prefix0|
RemoveImportPrefixReferenceEdit
  44 +8 |prefix0.|
----------------
import 'dart:math';

class A {
  Random foo() {}
}
''');
      });

      test('First import, dart:math', () {
        assertEdits(code: r'''
import 'dart:core' as prefix0;
import 'dart:math' as prefix1;

class A {
  prefix0.int foo(prefix1.Random a) {}
}
''', expected: r'''
RemoveImportPrefixDeclarationEdit
  18 +11 | as prefix0|
RemoveImportPrefixDeclarationEdit
  49 +11 | as prefix1|
RemoveImportPrefixReferenceEdit
  75 +8 |prefix0.|
RemoveImportPrefixReferenceEdit
  91 +8 |prefix1.|
----------------
import 'dart:core';
import 'dart:math';

class A {
  int foo(Random a) {}
}
''');
      });
    });

    group('Shadowed | ', () {
      test('By library declaration name', () {
        assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}
''', libraryDeclarationNames: {'String'});
      });

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

      test('Partial 1/3', () {
        assertEdits(code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.bool foo1() {}
  prefix0.int foo2() {}
  prefix0.String foo3() {}
}

class String {}
''', expected: r'''
ImportWithoutPrefixEdit
  30 |\nimport 'dart:core' hide String;|
RemoveImportPrefixReferenceEdit
  44 +8 |prefix0.|
RemoveImportPrefixReferenceEdit
  69 +8 |prefix0.|
----------------
import 'dart:core' as prefix0;
import 'dart:core' hide String;

class A {
  bool foo1() {}
  int foo2() {}
  prefix0.String foo3() {}
}

class String {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  A.String();
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
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
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String foo() {}
}

typedef F<String> = void Function();
''');
      });

      test('By class field', () {
        assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

class A {
  int String;
  prefix0.String foo() {}
}
''');
      });

      test('By local variable', () {
        assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

prefix0.String foo() {
  int String;
}
''');
      });

      test('By formal parameter', () {
        assertEditsNoChanges(code: r'''
import 'dart:core' as prefix0;

prefix0.String foo(int String) {
}
''');
      });
    });
  });

  test('JsonSerializable', () {
    assertEdits(
        importedNames: {
          'package:json_serializable/json_serializable.dart': {
            'FromJson',
            'ToJson'
          },
        },
        withEdits: false,
        code: r'''
augment library 'test.dart';

import 'package:json_serializable/json_serializable.dart' as prefix0;
import 'dart:core' as prefix1;

augment class User {
  @prefix0.FromJson()
  external User.fromJson(prefix1.Map<prefix1.String, prefix1.Object?> json);
  @prefix0.ToJson()
  external prefix1.Map<prefix1.String, prefix1.Object?> toJson();
  augment User.fromJson(prefix1.Map<prefix1.String, prefix1.Object?> json, )  :
    this.age = json["age"] as prefix1.int,
    this.name = json["name"] as prefix1.String{}
  augment prefix1.Map<prefix1.String, prefix1.Object?> toJson()  => {
    'age': this.age,
    'name': this.name,
  };
}
''',
        expected: r'''
augment library 'test.dart';

import 'package:json_serializable/json_serializable.dart';
import 'dart:core';

augment class User {
  @FromJson()
  external User.fromJson(Map<String, Object?> json);
  @ToJson()
  external Map<String, Object?> toJson();
  augment User.fromJson(Map<String, Object?> json, )  :
    this.age = json["age"] as int,
    this.name = json["name"] as String{}
  augment Map<String, Object?> toJson()  => {
    'age': this.age,
    'name': this.name,
  };
}
''');
  });

  test('Update expectations', () {
    // import '../../../analyzer/test/src/dart/resolution/node_text_expectations.dart';
    // NodeTextExpectationsCollector.apply();
  });
}

const _dartImports = {
  'dart:core': {'bool', 'double', 'int', 'Map', 'Object', 'String', 'print'},
  'dart:math': {'Random', 'pi'},
};

void assertEdits({
  Map<String, Set<String>> importedNames = const {},
  Set<String> libraryDeclarationNames = const {},
  required String code,
  required String expected,
  bool withEdits = true,
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
    libraryDeclarationNames: libraryDeclarationNames,
    scannerConfiguration: ScannerConfiguration(
      enableExtensionMethods: true,
      enableNonNullable: true,
      forAugmentationLibrary: true,
    ),
    throwIfHasErrors: throwIfHasErrors,
  );

  var buffer = StringBuffer();

  if (withEdits) {
    void writeRemoveEdit(RemoveEdit edit) {
      buffer.write('  ${edit.offset} +${edit.length}');
      var removed = code.substring(edit.offset, edit.offset + edit.length);
      buffer.writeln(' |${escape(removed)}|');
    }

    for (var edit in edits) {
      switch (edit) {
        case RemoveDartCoreImportEdit():
          buffer.writeln('RemoveDartCoreImportEdit');
          writeRemoveEdit(edit);
        case RemoveImportPrefixDeclarationEdit():
          buffer.writeln('RemoveImportPrefixDeclarationEdit');
          writeRemoveEdit(edit);
        case RemoveImportPrefixReferenceEdit():
          buffer.writeln('RemoveImportPrefixReferenceEdit');
          writeRemoveEdit(edit);
        case ImportWithoutPrefixEdit():
          buffer.writeln('ImportWithoutPrefixEdit');
          buffer.write('  ${edit.offset}');
          buffer.writeln(' |${escape(edit.replacement)}|');
      }
    }
    buffer.writeln('-' * 16);
  }

  // Apply in reverse order.
  var optimized = Edit.applyList(edits, code);
  buffer.write(optimized);

  var actual = buffer.toString();
  if (actual != expected) {
    print('-------- Actual --------');
    print('$actual------------------------');
    // NodeTextExpectationsCollector.add(actual);
    fail('Not as expected');
  }
}

void assertEditsNoChanges({
  Map<String, Set<String>> importedNames = const {},
  Set<String> libraryDeclarationNames = const {},
  required String code,
  bool throwIfHasErrors = true,
}) {
  assertEdits(
    importedNames: importedNames,
    libraryDeclarationNames: libraryDeclarationNames,
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
