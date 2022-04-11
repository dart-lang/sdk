// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../support/abstract_context.dart';
import 'dart_change_builder_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryElementTest);
    defineReflectiveTests(ImportLibraryElement_existingImport_Test);
    defineReflectiveTests(ImportLibraryElement_newImport_withoutPrefix_Test);
  });
}

@reflectiveTest
class ImportLibraryElement_existingImport_Test extends _Base {
  Future<void> test_dartCore_implicit() async {
    await _assertImportLibraryElement(
      initialCode: r'''
import 'dart:math';
''',
      uriStr: 'dart:core',
      name: 'String',
    );
  }

  Future<void> test_dartCore_withPrefix() async {
    await _assertImportLibraryElement(
      initialCode: r'''
import 'dart:core' as my_core;
import 'dart:math';
''',
      uriStr: 'dart:core',
      name: 'String',
      expectedPrefix: 'my_core',
    );
  }

  Future<void> test_withoutPrefix() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
    );
  }

  Future<void> test_withoutPrefix_exported() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');
    newFile2('/home/test/lib/b.dart', r'''
export 'a.dart';
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/b.dart';
''',
      uriStr: 'package:test/b.dart',
      name: 'A',
    );
  }

  Future<void> test_withoutPrefix_hasInvalidImport() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');

    await _assertImportLibraryElement(
      initialCode: r'''
import ':[invalidUri]';
import 'package:test/a.dart';
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
    );
  }

  Future<void> test_withoutPrefix_referencedNames_sameElements() async {
    newFile2('/home/test/lib/a.dart', r'''
class A {}
''');
    newFile2('/home/test/lib/b.dart', r'''
export 'a.dart';

class B {}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/b.dart';

A a;
B b;
''',
      uriStr: 'package:test/b.dart',
      name: 'B',
    );
  }

  Future<void> test_withoutPrefix_twoImports_sameElement() async {
    newFile2('/home/test/lib/a.dart', 'class C {}');
    newFile2('/home/test/lib/b.dart', r'''
export 'package:test/a.dart';
''');

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';
''',
      uriStr: 'package:test/a.dart',
      name: 'C',
    );

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';
''',
      uriStr: 'package:test/b.dart',
      name: 'C',
    );
  }

  Future<void> test_withPrefix() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' as p;
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedPrefix: 'p',
    );
  }

  Future<void> test_withPrefix_twoImports_sameElement() async {
    newFile2('/home/test/lib/a.dart', 'class C {}');
    newFile2('/home/test/lib/b.dart', r'''
export 'package:test/a.dart';
''');

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' as p;
import 'package:test/b.dart' as p;
''',
      uriStr: 'package:test/a.dart',
      name: 'C',
      expectedPrefix: 'p',
    );

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' as p;
import 'package:test/b.dart' as p;
''',
      uriStr: 'package:test/b.dart',
      name: 'C',
      expectedPrefix: 'p',
    );
  }
}

@reflectiveTest
class ImportLibraryElement_newImport_withoutPrefix_Test extends _Base {
  Future<void> test_constructorName_name() async {
    newFile2('/home/test/lib/a.dart', r'''
int foo;
''');
    newFile2('/home/test/lib/b.dart', r'''
class B {
  B.foo();
}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/b.dart';

main() {
  B.foo();
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  B.foo();
}
''',
    );
  }

  Future<void> test_exported() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');
    newFile2('/home/test/lib/b.dart', r'''
export 'a.dart';
''');
    await _assertImportLibraryElement(
      initialCode: '',
      uriStr: 'package:test/b.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/b.dart';
''',
    );
  }

  Future<void> test_exported_differentUri() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');
    newFile2('/home/test/lib/b.dart', r'''
export 'a.dart';
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
''',
      uriStr: 'package:test/b.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';
''',
    );
  }

  Future<void> test_methodInvocation_name() async {
    newFile2('/home/test/lib/a.dart', r'''
int foo;
''');
    newFile2('/home/test/lib/b.dart', r'''
class B {
  static void foo() {}
}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/b.dart';

main() {
  B.foo();
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  B.foo();
}
''',
    );
  }

  Future<void> test_noConflict_otherImport_hide() async {
    newFile2('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    newFile2('/home/test/lib/b.dart', 'class B {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' hide B;
''',
      uriStr: 'package:test/b.dart',
      name: 'B',
      expectedCode: r'''
import 'package:test/a.dart' hide B;
import 'package:test/b.dart';
''',
    );
  }

  Future<void> test_noConflict_otherImport_show() async {
    newFile2('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    newFile2('/home/test/lib/b.dart', 'class B {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' show A;
''',
      uriStr: 'package:test/b.dart',
      name: 'B',
      expectedCode: r'''
import 'package:test/a.dart' show A;
import 'package:test/b.dart';
''',
    );
  }

  Future<void> test_noShadow_syntacticScope_localVariable() async {
    newFile2('/home/test/lib/a.dart', r'''
var foo = 0;
''');
    await _assertImportLibraryElement(
      initialCode: r'''
void f() {
^
}

void g() {
  var foo = 1;
  foo;
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedCode: r'''
import 'package:test/a.dart';

void f() {

}

void g() {
  var foo = 1;
  foo;
}
''',
    );
  }

  Future<void> test_noShadow_syntacticScope_typeParameter() async {
    newFile2('/home/test/lib/a.dart', r'''
class A {}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
class C<A> {
  A f;
}
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/a.dart';

class C<A> {
  A f;
}
''',
    );
  }

  Future<void> test_prefixedIdentifier_identifier() async {
    newFile2('/home/test/lib/a.dart', r'''
int foo;
''');
    newFile2('/home/test/lib/b.dart', r'''
class B {
  static int foo;
}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/b.dart';

main() {
  B.foo;
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  B.foo;
}
''',
    );
  }

  Future<void> test_thisName_notShadowed_localVariable_otherFunction() async {
    newFile2('/home/test/lib/a.dart', 'int foo = 0;');
    await _assertImportLibraryElement(
      initialCode: r'''
void f() {
^
}

void g() {
  var foo = '';
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedCode: r'''
import 'package:test/a.dart';

void f() {

}

void g() {
  var foo = '';
}
''',
    );
  }

  Future<void> test_unrelated() async {
    newFile2('/home/test/lib/a.dart', 'class A {}');
    newFile2('/home/test/lib/b.dart', 'class B {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
''',
      uriStr: 'package:test/b.dart',
      name: 'B',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';
''',
    );
  }
}

@reflectiveTest
class ImportLibraryElementTest extends _Base {
  Future<void> test_thisLibrary() async {
    await _assertImportLibraryElement(
      initialCode: r'''
class A {}
''',
      uriStr: 'package:test/test.dart',
      name: 'A',
    );
  }
}

class _Base extends AbstractContextTest with DartChangeBuilderMixin {
  void _assertEmptyChange(ChangeBuilder builder) {
    var change = builder.sourceChange;
    expect(change, isNotNull);
    expect(change.edits, isEmpty);
  }

  Future<void> _assertImportLibraryElement(
      {required String initialCode,
      required String uriStr,
      required String name,
      String? expectedPrefix,
      String? expectedCode}) async {
    var offset = initialCode.indexOf('^');
    if (offset > 0) {
      initialCode =
          initialCode.substring(0, offset) + initialCode.substring(offset + 1);
    } else {
      offset = initialCode.length;
    }

    var path = convertPath('/home/test/lib/test.dart');
    newFile2(path, initialCode);

    var requestedResult =
        await (await session).getLibraryByUri(uriStr) as LibraryElementResult;
    var requestedLibrary = requestedResult.element;
    var requestedElement = requestedLibrary.exportNamespace.get(name);
    expect(requestedElement, isNotNull, reason: '`$name` in $uriStr');

    var builder = await newBuilder();
    await builder.addDartFileEdit(path, (builder) {
      var uri = Uri.parse(uriStr);
      var result = builder.importLibraryElement(uri);
      expect(result.prefix, expectedPrefix);
    });

    if (expectedCode != null) {
      var edits = getEdits(builder);
      var resultCode = SourceEdit.applySequence(initialCode, edits);
      expect(resultCode, expectedCode);
    } else {
      _assertEmptyChange(builder);
    }
  }
}
