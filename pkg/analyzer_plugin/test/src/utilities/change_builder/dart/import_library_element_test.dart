// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../support/abstract_context.dart';
import 'dart_change_builder_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryElementTest);
    defineReflectiveTests(ImportLibraryElement_existingImport_Test);
    defineReflectiveTests(ImportLibraryElement_incompleteCode_Test);
    defineReflectiveTests(ImportLibraryElement_newImport_withoutPrefix_Test);
    defineReflectiveTests(ImportLibraryElement_newImport_withPrefix_Test);
  });
}

@reflectiveTest
class ImportLibraryElement_existingImport_Test extends _Base {
  test_dartCore_implicit() async {
    await _assertImportLibraryElement(
      initialCode: r'''
import 'dart:math';
''',
      uriStr: 'dart:core',
      name: 'String',
    );
  }

  test_dartCore_withPrefix() async {
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

  test_withoutPrefix() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
    );
  }

  test_withoutPrefix_exported() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    newFile('/home/test/lib/b.dart', content: r'''
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

  test_withoutPrefix_referencedNames_sameElements() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/test/lib/b.dart', content: r'''
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

  test_withoutPrefix_twoImports_sameElement() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    newFile('/home/test/lib/b.dart', content: r'''
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

  test_withPrefix() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');

    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' as p;
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedPrefix: 'p',
    );
  }

  test_withPrefix_twoImports_sameElement() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    newFile('/home/test/lib/b.dart', content: r'''
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
class ImportLibraryElement_incompleteCode_Test extends _Base {
  test_fieldDeclaration_atEnd() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    await _assertImportLibraryElement(
      initialCode: r'''
class C {
  A^
}
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/a.dart';

class C {
  A
}
''',
    );
  }

  test_fieldDeclaration_beforeReturnType() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    await _assertImportLibraryElement(
      initialCode: r'''
class C {
  A^
  
  A foo() => null;
}
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/a.dart';

class C {
  A
  
  A foo() => null;
}
''',
    );
  }

  test_formalParameter_end() async {
    newFile('/home/test/lib/a.dart', content: 'class AAA {}');
    await _assertImportLibraryElement(
      initialCode: r'''
f(AAA^) {}
''',
      uriStr: 'package:test/a.dart',
      name: 'AAA',
      expectedCode: r'''
import 'package:test/a.dart';

f(AAA) {}
''',
    );
  }

  test_formalParameter_start() async {
    newFile('/home/test/lib/a.dart', content: 'class AAA {}');
    await _assertImportLibraryElement(
      initialCode: r'''
f(^AAA) {}
''',
      uriStr: 'package:test/a.dart',
      name: 'AAA',
      expectedCode: r'''
import 'package:test/a.dart';

f(AAA) {}
''',
    );
  }

  test_topLevelVariable_atEnd() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    newFile('/home/test/lib/b.dart', content: r'''
export 'a.dart';
''');
    await _assertImportLibraryElement(
      initialCode: r'''
A^
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/a.dart';

A
''',
    );
  }

  test_topLevelVariable_beforeReturnType() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    await _assertImportLibraryElement(
      initialCode: r'''
A^

A foo() => null;
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedCode: r'''
import 'package:test/a.dart';

A

A foo() => null;
''',
    );
  }
}

@reflectiveTest
class ImportLibraryElement_newImport_withoutPrefix_Test extends _Base {
  test_exported() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    newFile('/home/test/lib/b.dart', content: r'''
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

  test_exported_differentUri() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    newFile('/home/test/lib/b.dart', content: r'''
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

  test_noConflict_otherImport_hide() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
class B {}
''');
    newFile('/home/test/lib/b.dart', content: 'class B {}');
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

  test_noConflict_otherImport_show() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
class B {}
''');
    newFile('/home/test/lib/b.dart', content: 'class B {}');
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

  test_noShadow_syntacticScope_localVariable() async {
    newFile('/home/test/lib/a.dart', content: r'''
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

  test_noShadow_syntacticScope_typeParameter() async {
    newFile('/home/test/lib/a.dart', content: r'''
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

  test_thisName_notShadowed_localVariable_otherFunction() async {
    newFile('/home/test/lib/a.dart', content: 'int foo = 0;');
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

  test_unrelated() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');
    newFile('/home/test/lib/b.dart', content: 'class B {}');
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
class ImportLibraryElement_newImport_withPrefix_Test extends _Base {
  test_existingImport_nameIsAmbiguous() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    newFile('/home/test/lib/b.dart', content: 'class C {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';
''',
      uriStr: 'package:test/b.dart',
      name: 'C',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart';
import 'package:test/b.dart' as prefix0;
''',
    );
  }

  test_existingImport_nameIsAmbiguous_prefixed() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    newFile('/home/test/lib/b.dart', content: 'class C {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart' as p;
import 'package:test/b.dart' as p;
''',
      uriStr: 'package:test/b.dart',
      name: 'C',
      expectedCode: r'''
import 'package:test/a.dart' as p;
import 'package:test/b.dart' as p;
import 'package:test/b.dart';
''',
    );
  }

  test_nameIsAmbiguous() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    newFile('/home/test/lib/b.dart', content: 'class C {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';
''',
      uriStr: 'package:test/b.dart',
      name: 'C',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart' as prefix0;
''',
    );
  }

  test_shadow_otherName_imported() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/test/lib/b.dart', content: r'''
class A {}
class B {}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';

A a;
''',
      uriStr: 'package:test/b.dart',
      name: 'B',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/b.dart' as prefix0;

A a;
''',
    );
  }

  test_shadow_otherName_inherited() async {
    newFile('/home/test/lib/b.dart', content: '''
int foo = 0;
int bar = 0;
''');
    await _assertImportLibraryElement(
      initialCode: r'''
class A {
  void bar() {}
}

class X extends A {
  voif f() {
    bar();
  }
}
''',
      uriStr: 'package:test/b.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/b.dart' as prefix0;

class A {
  void bar() {}
}

class X extends A {
  voif f() {
    bar();
  }
}
''',
    );
  }

  test_shadowed_class() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'package:test/a.dart';

class C {}
''',
      uriStr: 'package:test/a.dart',
      name: 'C',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart';
import 'package:test/a.dart' as prefix0;

class C {}
''',
    );
  }

  test_shadowed_class_inPart() async {
    newFile('/home/test/lib/a.dart', content: 'class C {}');
    newFile('/home/test/lib/p.dart', content: 'class C {}');
    await _assertImportLibraryElement(
      initialCode: r'''
part 'p.dart';
''',
      uriStr: 'package:test/a.dart',
      name: 'C',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

part 'p.dart';
''',
    );
  }

  test_shadowed_formalParameter() async {
    newFile('/home/test/lib/a.dart', content: r'''
var foo = 0;
''');
    await _assertImportLibraryElement(
      initialCode: r'''
void f(int foo) {^}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

void f(int foo) {}
''',
    );
  }

  test_shadowed_function() async {
    newFile('/home/test/lib/a.dart', content: r'''
var foo = 0;
''');
    await _assertImportLibraryElement(
      initialCode: r'''
void foo() {^}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

void foo() {}
''',
    );
  }

  test_shadowed_function_local_after() async {
    newFile('/home/test/lib/a.dart', content: r'''
var foo = 0;
''');
    await _assertImportLibraryElement(
      initialCode: r'''
void f() {
  void foo() {}
^}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

void f() {
  void foo() {}
}
''',
    );
  }

  test_shadowed_function_local_before() async {
    newFile('/home/test/lib/a.dart', content: r'''
var foo = 0;
''');
    await _assertImportLibraryElement(
      initialCode: r'''
void f() {^
  void foo() {}
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

void f() {
  void foo() {}
}
''',
    );
  }

  test_shadowed_importPrefix() async {
    newFile('/home/test/lib/a.dart', content: 'int foo = 0;');
    await _assertImportLibraryElement(
      initialCode: r'''
import 'dart:math' as foo;
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'dart:math' as foo;

import 'package:test/a.dart' as prefix0;
''',
    );
  }

  test_shadowed_localVariable_after() async {
    newFile('/home/test/lib/a.dart', content: 'int foo = 0;');
    await _assertImportLibraryElement(
      initialCode: r'''
main() {
  var foo = '';
^}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

main() {
  var foo = '';
}
''',
    );
  }

  test_shadowed_localVariable_before() async {
    newFile('/home/test/lib/a.dart', content: 'int foo = 0;');
    await _assertImportLibraryElement(
      initialCode: r'''
main() {^
  var foo = '';
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

main() {
  var foo = '';
}
''',
    );
  }

  test_shadowed_method() async {
    newFile('/home/test/lib/a.dart', content: 'int foo = 0;');
    await _assertImportLibraryElement(
      initialCode: r'''
class A {
  void foo() {}
  
  void bar() {^}
}
''',
      uriStr: 'package:test/a.dart',
      name: 'foo',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

class A {
  void foo() {}
  
  void bar() {}
}
''',
    );
  }

  test_shadowed_typeParameter_class() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
class C<A> {^}
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

class C<A> {}
''',
    );
  }

  test_shadowed_typeParameter_function() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
''');
    await _assertImportLibraryElement(
      initialCode: r'''
void f<A>() {^}
''',
      uriStr: 'package:test/a.dart',
      name: 'A',
      expectedPrefix: 'prefix0',
      expectedCode: r'''
import 'package:test/a.dart' as prefix0;

void f<A>() {}
''',
    );
  }
}

@reflectiveTest
class ImportLibraryElementTest extends _Base {
  test_thisLibrary() async {
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
  void _assertEmptyChange(DartChangeBuilderImpl builder) {
    var change = builder.sourceChange;
    expect(change, isNotNull);
    expect(change.edits, isEmpty);
  }

  Future<void> _assertImportLibraryElement(
      {String initialCode,
      String uriStr,
      String name,
      String expectedPrefix,
      String expectedCode}) async {
    var offset = initialCode.indexOf('^');
    if (offset > 0) {
      initialCode =
          initialCode.substring(0, offset) + initialCode.substring(offset + 1);
    } else {
      offset = initialCode.length;
    }

    var path = convertPath('/home/test/lib/test.dart');
    newFile(path, content: initialCode);

    var resolvedLibrary = await session.getResolvedLibrary(path);
    var requestedLibrary = await session.getLibraryByUri(uriStr);

    var requestedElement = requestedLibrary.exportNamespace.get(name);
    expect(requestedElement, isNotNull, reason: '`$name` in $uriStr');

    var builder = newBuilder();
    await builder.addFileEdit(path, (builder) {
      var result = builder.importLibraryElement(
        targetLibrary: resolvedLibrary,
        targetPath: path,
        targetOffset: offset,
        requestedLibrary: requestedLibrary,
        requestedElement: requestedElement,
      );
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
