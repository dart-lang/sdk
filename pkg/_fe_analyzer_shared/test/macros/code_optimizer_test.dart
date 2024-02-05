// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/code_optimizer.dart';
import 'package:test/test.dart';

void main() {
  group('Class |', () {
    group('Method |', () {
      group('Return type |', () {
        test('Not shadowed', () {
          assertEdits(importedNames: {}, code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String get foo {}
}
''', expected: r'''
44 +8 |prefix0.| -> ||
----------------
import 'dart:core' as prefix0;

class A {
  String get foo {}
}
''');
        });

        group('Shadowed | ', () {
          test('By local class, before', () {
            assertEdits(importedNames: {}, code: r'''
import 'dart:core' as prefix0;

class String {}

class A {
  prefix0.String get foo {}
}
''', expected: r'''
----------------
import 'dart:core' as prefix0;

class String {}

class A {
  prefix0.String get foo {}
}
''');
          });

          test('By local class, after', () {
            assertEdits(importedNames: {}, code: r'''
import 'dart:core' as prefix0;

class A {
  prefix0.String get foo {}
}

class String {}
''', expected: r'''
----------------
import 'dart:core' as prefix0;

class A {
  prefix0.String get foo {}
}

class String {}
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
  required Map<String, Set<String>> importedNames,
  required String code,
  required String expected,
}) {
  var optimizer = _CodeOptimizer(
    importedNames: {
      ..._dartImports,
      ...importedNames,
    },
  );

  var edits = optimizer.optimize(code);

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
  }
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
