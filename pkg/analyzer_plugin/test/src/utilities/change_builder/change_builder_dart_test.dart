// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../support/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartChangeBuilderImplTest);
    defineReflectiveTests(DartEditBuilderImplTest);
    defineReflectiveTests(DartFileEditBuilderImplTest);
    defineReflectiveTests(DartLinkedEditBuilderImplTest);
  });
}

abstract class BuilderTestMixin {
  SourceEdit getEdit(DartChangeBuilderImpl builder) {
    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    List<SourceEdit> edits = fileEdit.edits;
    expect(edits, hasLength(1));
    return edits[0];
  }

  List<SourceEdit> getEdits(DartChangeBuilderImpl builder) {
    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    return fileEdit.edits;
  }
}

@reflectiveTest
class DartChangeBuilderImplTest extends AbstractContextTest {
  test_createFileEditBuilder() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'library test;');
    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    DartFileEditBuilderImpl fileEditBuilder =
        await builder.createFileEditBuilder(path);
    expect(fileEditBuilder, new isInstanceOf<DartFileEditBuilder>());
    SourceFileEdit fileEdit = fileEditBuilder.fileEdit;
    expect(fileEdit.file, path);
  }
}

@reflectiveTest
class DartEditBuilderImplTest extends AbstractContextTest
    with BuilderTestMixin {
  test_importLibraries_DP() async {
    await _assertImportLibrary('''
import 'dart:aaa';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:ccc/ccc.dart';
''', ['dart:bbb', 'package:bbb/bbb.dart'], '''
import 'dart:aaa';
import 'dart:bbb';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
''');
  }

  test_importLibraries_PD() async {
    await _assertImportLibrary('''
import 'dart:aaa';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:ccc/ccc.dart';
''', ['package:bbb/bbb.dart', 'dart:bbb'], '''
import 'dart:aaa';
import 'dart:bbb';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
''');
  }

  test_importLibrary_afterLibraryDirective_dart() async {
    await _assertImportLibrary('''
library test;

class A {}
''', ['dart:async'], '''
library test;

import 'dart:async';


class A {}
''');
  }

  test_importLibrary_dart_beforeDart() async {
    await _assertImportLibrary('''
import 'dart:aaa';
import 'dart:ccc';
''', ['dart:bbb'], '''
import 'dart:aaa';
import 'dart:bbb';
import 'dart:ccc';
''');
  }

  test_importLibrary_dart_beforeDart_first() async {
    await _assertImportLibrary('''
import 'dart:bbb';
''', ['dart:aaa'], '''
import 'dart:aaa';
import 'dart:bbb';
''');
  }

  test_importLibrary_dart_beforePackage() async {
    await _assertImportLibrary('''
import 'package:foo/foo.dart';
''', ['dart:async'], '''
import 'dart:async';

import 'package:foo/foo.dart';
''');
  }

  test_importLibrary_noDirectives_docComment() async {
    await _assertImportLibrary('''
/// Documentation comment.
/// Continues.
void main() {}
''', ['dart:async'], '''
import 'dart:async';

/// Documentation comment.
/// Continues.
void main() {}
''');
  }

  test_importLibrary_noDirectives_hashBang() async {
    await _assertImportLibrary('''
#!/bin/dart

void main() {}
''', ['dart:async'], '''
#!/bin/dart

import 'dart:async';

void main() {}
''');
  }

  test_importLibrary_noDirectives_lineComment() async {
    await _assertImportLibrary('''
// Not documentation comment.
// Continues.

void main() {}
''', ['dart:async'], '''
// Not documentation comment.
// Continues.

import 'dart:async';

void main() {}
''');
  }

  test_importLibrary_package_afterDart() async {
    await _assertImportLibrary('''
import 'dart:async';
''', ['package:aaa/aaa.dart'], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
''');
  }

  test_importLibrary_package_afterPackage() async {
    await _assertImportLibrary('''
import 'package:aaa/a1.dart';

import 'foo.dart';
''', ['package:aaa/a2.dart'], '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_package_afterPackage_leadingComment() async {
    await _assertImportLibrary('''
// comment
import 'package:aaa/a1.dart';

import 'foo.dart';
''', ['package:aaa/a2.dart'], '''
// comment
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_package_afterPackage_trailingComment() async {
    await _assertImportLibrary('''
import 'package:aaa/a1.dart'; // comment

import 'foo.dart';
''', ['package:aaa/a2.dart'], '''
import 'package:aaa/a1.dart'; // comment
import 'package:aaa/a2.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_package_beforePackage() async {
    await _assertImportLibrary('''
import 'package:aaa/a1.dart';
import 'package:aaa/a3.dart';

import 'foo.dart';
''', ['package:aaa/a2.dart'], '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';
import 'package:aaa/a3.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_package_beforePackage_first() async {
    await _assertImportLibrary('''
import 'package:aaa/a2.dart';

import 'foo.dart';
''', ['package:aaa/a1.dart'], '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_package_beforePackage_leadingComments() async {
    await _assertImportLibrary('''
// comment a2
import 'package:aaa/a2.dart';

import 'foo.dart';
''', ['package:aaa/a1.dart'], '''
// comment a2
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_package_beforePackage_trailingComments() async {
    await _assertImportLibrary('''
import 'package:aaa/a2.dart'; // comment a2

import 'foo.dart';
''', ['package:aaa/a1.dart'], '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart'; // comment a2

import 'foo.dart';
''');
  }

  test_importLibrary_package_beforeRelative() async {
    await _assertImportLibrary('''
import 'foo.dart';
''', ['package:aaa/aaa.dart'], '''
import 'package:aaa/aaa.dart';

import 'foo.dart';
''');
  }

  test_importLibrary_relative_afterDart() async {
    await _assertImportLibrary('''
import 'dart:async';
''', ['aaa.dart'], '''
import 'dart:async';

import 'aaa.dart';
''');
  }

  test_importLibrary_relative_afterPackage() async {
    await _assertImportLibrary('''
import 'package:foo/foo.dart';
''', ['aaa.dart'], '''
import 'package:foo/foo.dart';

import 'aaa.dart';
''');
  }

  test_importLibrary_relative_beforeRelative() async {
    await _assertImportLibrary('''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
import 'ccc.dart';
''', ['bbb.dart'], '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
import 'bbb.dart';
import 'ccc.dart';
''');
  }

  test_importLibrary_relative_beforeRelative_first() async {
    await _assertImportLibrary('''
import 'dart:async';

import 'package:foo/foo.dart';

import 'bbb.dart';
''', ['aaa.dart'], '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
import 'bbb.dart';
''');
  }

  test_importLibrary_relative_last() async {
    await _assertImportLibrary('''
import 'dart:async';

import 'package:foo/foo.dart';
''', ['aaa.dart'], '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
''');
  }

  test_writeClassDeclaration_interfaces() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class A {}');
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeClassDeclaration('C', interfaces: [typeA]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(
        edit.replacement, equalsIgnoringWhitespace('class C implements A { }'));
  }

  test_writeClassDeclaration_isAbstract() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeClassDeclaration('C', isAbstract: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('abstract class C { }'));
  }

  test_writeClassDeclaration_memberWriter() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C',
            membersWriter: () {
          builder.write('/**/');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('class C { /**/}'));
  }

  test_writeClassDeclaration_mixins_noSuperclass() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class A {}');
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeClassDeclaration('C', mixins: [typeA]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('class C extends Object with A { }'));
  }

  test_writeClassDeclaration_mixins_superclass() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class A {} class B {}');
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeClassDeclaration('C', mixins: [typeB], superclass: typeA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('class C extends A with B { }'));
  }

  test_writeClassDeclaration_nameGroupName() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeClassDeclaration('C', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('class C { }'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
  }

  test_writeClassDeclaration_superclass() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class B {}');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C',
            superclass: typeB, superclassGroupName: 'superclass');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('class C extends B { }'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
  }

  test_writeConstructorDeclaration_bodyWriter() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class C {}');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(9, (DartEditBuilder builder) {
        builder.writeConstructorDeclaration('A', bodyWriter: () {
          builder.write(' { print(42); }');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A() { print(42); }'));
  }

  test_writeConstructorDeclaration_fieldNames() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, r'''
class C {
  final int a;
  final bool bb;
}
''');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(42, (DartEditBuilder builder) {
        builder.writeConstructorDeclaration('A', fieldNames: ['a', 'bb']);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A(this.a, this.bb);'));
  }

  test_writeConstructorDeclaration_initializerWriter() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class C {}');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(9, (DartEditBuilder builder) {
        builder.writeConstructorDeclaration('A', initializerWriter: () {
          builder.write('super()');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A() : super();'));
  }

  test_writeConstructorDeclaration_parameterWriter() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'class C {}');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(9, (DartEditBuilder builder) {
        builder.writeConstructorDeclaration('A', parameterWriter: () {
          builder.write('int a, {this.b}');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A(int a, {this.b});'));
  }

  test_writeFieldDeclaration_initializerWriter() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f',
            initializerWriter: () {
          builder.write('e');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var f = e;'));
  }

  test_writeFieldDeclaration_isConst() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isConst: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const f;'));
  }

  test_writeFieldDeclaration_isConst_isFinal() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFieldDeclaration('f', isConst: true, isFinal: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const f;'));
  }

  test_writeFieldDeclaration_isConst_type() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFieldDeclaration('f', isConst: true, type: typeA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const A f;'));
  }

  test_writeFieldDeclaration_isFinal() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isFinal: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('final f;'));
  }

  test_writeFieldDeclaration_isFinal_type() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFieldDeclaration('f', isFinal: true, type: typeA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('final A f;'));
  }

  test_writeFieldDeclaration_isStatic() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isStatic: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('static var f;'));
  }

  test_writeFieldDeclaration_nameGroupName() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFieldDeclaration('f', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var f;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
    Position position = group.positions[0];
    expect(position.offset, equals(13));
  }

  test_writeFieldDeclaration_type_typeGroupName() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFieldDeclaration('f', type: typeA, typeGroupName: 'type');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A f;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
    Position position = group.positions[0];
    expect(position.offset, equals(20));
  }

  test_writeFunctionDeclaration_noReturnType_noParams_body() async {
    String path = provider.convertPath('/test.dart');
    String content = '';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFunctionDeclaration('fib',
            bodyWriter: () {
          builder.write('{ ... }');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('fib() { ... }'));
  }

  test_writeFunctionDeclaration_noReturnType_noParams_noBody() async {
    String path = provider.convertPath('/test.dart');
    String content = '';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFunctionDeclaration('fib', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('fib() {}'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 3);
    expect(group.positions, hasLength(1));
  }

  test_writeFunctionDeclaration_noReturnType_params_noBody() async {
    String path = provider.convertPath('/test.dart');
    String content = '';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFunctionDeclaration('fib',
            parameterWriter: () {
          builder.write('p, q, r');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('fib(p, q, r) {}'));
  }

  test_writeFunctionDeclaration_returnType_noParams_noBody() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFunctionDeclaration('fib',
            returnType: typeA, returnTypeGroupName: 'type');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A fib() => null;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
  }

  test_writeGetterDeclaration_bodyWriter() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeGetterDeclaration('g',
            bodyWriter: () {
          builder.write('{}');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('get g {}'));
  }

  test_writeGetterDeclaration_isStatic() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeGetterDeclaration('g', isStatic: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('static get g => null;'));
  }

  test_writeGetterDeclaration_nameGroupName() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeGetterDeclaration('g', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('get g => null;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
    Position position = group.positions[0];
    expect(position.offset, equals(13));
  }

  test_writeGetterDeclaration_returnType() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeGetterDeclaration('g',
            returnType: typeA, returnTypeGroupName: 'returnType');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A get g => null;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
    Position position = group.positions[0];
    expect(position.offset, equals(20));
  }

  test_writeLocalVariableDeclaration_noType_initializer() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration('foo',
            initializerWriter: () {
          builder.write('null');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var foo = null;'));
  }

  test_writeLocalVariableDeclaration_noType_noInitializer() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeLocalVariableDeclaration('foo', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var foo;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 3);
    expect(group.positions, hasLength(1));
  }

  test_writeLocalVariableDeclaration_noType_noInitializer_const() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeLocalVariableDeclaration('foo', isConst: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const foo;'));
  }

  test_writeLocalVariableDeclaration_noType_noInitializer_final() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeLocalVariableDeclaration('foo', isFinal: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('final foo;'));
  }

  test_writeLocalVariableDeclaration_type_initializer() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}
class MyClass {}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    ClassDeclaration A = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration('foo',
            initializerWriter: () {
          builder.write('null');
        }, type: A.element.type);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('MyClass foo = null;'));
  }

  test_writeLocalVariableDeclaration_type_noInitializer() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}
class MyClass {}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    ClassDeclaration A = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration('foo',
            type: A.element.type, typeGroupName: 'type');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('MyClass foo;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 7);
    expect(group.positions, hasLength(1));
  }

  test_writeLocalVariableDeclaration_type_noInitializer_final() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
void f() {

}
class MyClass {}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    ClassDeclaration A = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration('foo',
            isFinal: true, type: A.element.type, typeGroupName: 'type');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('final MyClass foo;'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 7);
    expect(group.positions, hasLength(1));
  }

  test_writeOverrideOfInheritedMember_getter_abstract() async {
    await _assertWriteOverrideOfInheritedAccessor('''
abstract class A {
  int get zero;
}
class B extends A {
}
''', '''
  @override
  // TODO: implement zero
  int get zero => null;
''', displayText: 'zero => …', selection: new SourceRange(113, 4));
  }

  test_writeOverrideOfInheritedMember_getter_concrete() async {
    await _assertWriteOverrideOfInheritedAccessor('''
class A {
  int get zero => 0;
}
class B extends A {
}
''', '''
  @override
  // TODO: implement zero
  int get zero => super.zero;
''', displayText: 'zero => …', selection: new SourceRange(109, 10));
  }

  test_writeOverrideOfInheritedMember_method_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A {
  A add(A a);
}
class B extends A {
}
''', '''
  @override
  A add(A a) {
    // TODO: implement add
    return null;
  }
''', displayText: 'add(A a) { … }', selection: new SourceRange(113, 12));
  }

  test_writeOverrideOfInheritedMember_method_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A {
  A add(A a) => null;
}
class B extends A {
}
''', '''
  @override
  A add(A a) {
    // TODO: implement add
    return super.add(a);
  }
''', displayText: 'add(A a) { … }', selection: new SourceRange(112, 20));
  }

  test_writeOverrideOfInheritedMember_method_functionTypeAlias_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
typedef int F(int left, int right);
abstract class A {
  void perform(F f);
}
class B extends A {
}
''', '''
  @override
  void perform(F f) {
    // TODO: implement perform
  }
''', displayText: 'perform(F f) { … }', selection: null);
  }

  test_writeOverrideOfInheritedMember_method_functionTypeAlias_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
typedef int F(int left, int right);
class A {
  void perform(F f) {}
}
class B extends A {
}
''', '''
  @override
  void perform(F f) {
    // TODO: implement perform
    super.perform(f);
  }
''', displayText: 'perform(F f) { … }', selection: new SourceRange(160, 17));
  }

  test_writeOverrideOfInheritedMember_method_functionTypedParameter_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A {
  forEach(int f(double p1, String p2));
}
class B extends A {
}
''', '''
  @override
  forEach(int Function(double p1, String p2) f) {
    // TODO: implement forEach
    return null;
  }
''',
        displayText: 'forEach(int Function(double p1, String p2) f) { … }',
        selection: new SourceRange(178, 12));
  }

  test_writeOverrideOfInheritedMember_method_functionTypedParameter_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A {
  forEach(int f(double p1, String p2)) {}
}
class B extends A {
}
''', '''
  @override
  forEach(int Function(double p1, String p2) f) {
    // TODO: implement forEach
    return super.forEach(f);
  }
''',
        displayText: 'forEach(int Function(double p1, String p2) f) { … }',
        selection: new SourceRange(171, 24));
  }

  test_writeOverrideOfInheritedMember_method_generic_noBounds_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A {
  List<T> get<T>(T key);
}
class B implements A {
}
''', '''
  @override
  List<T> get<T>(T key) {
    // TODO: implement get
    return null;
  }
''', displayText: 'get<T>(T key) { … }', selection: new SourceRange(138, 12));
  }

  test_writeOverrideOfInheritedMember_method_generic_noBounds_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A {
  List<T> get<T>(T key) {}
}
class B implements A {
}
''', '''
  @override
  List<T> get<T>(T key) {
    // TODO: implement get
    return super.get(key);
  }
''', displayText: 'get<T>(T key) { … }', selection: new SourceRange(131, 22));
  }

  test_writeOverrideOfInheritedMember_method_generic_withBounds_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A<K1, V1> {
  List<T> get<T extends V1>(K1 key);
}
class B<K2, V2> implements A<K2, V2> {
}
''', '''
  @override
  List<T> get<T extends V2>(K2 key) {
    // TODO: implement get
    return null;
  }
''',
        displayText: 'get<T extends V2>(K2 key) { … }',
        selection: new SourceRange(186, 12));
  }

  test_writeOverrideOfInheritedMember_method_generic_withBounds_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A<K1, V1> {
  List<T> get<T extends V1>(K1 key) {
    return null;
  }
}
class B<K2, V2> implements A<K2, V2> {
}
''', '''
  @override
  List<T> get<T extends V2>(K2 key) {
    // TODO: implement get
    return super.get(key);
  }
''',
        displayText: 'get<T extends V2>(K2 key) { … }',
        selection: new SourceRange(199, 22));
  }

  test_writeOverrideOfInheritedMember_method_genericFunctionTypedParameter_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A {
  int foo(T Function<T>() fn);
}
class B extends A {
}
''', '''
  @override
  int foo(T Function<T>() fn) {
    // TODO: implement foo
    return null;
 }
''',
        displayText: 'foo(T Function<T>() fn) { … }',
        selection: new SourceRange(147, 12));
  }

  test_writeOverrideOfInheritedMember_method_genericFunctionTypedParameter_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A {
  int foo(T Function<T>() fn) => 0;
}
class B extends A {
}
''', '''
  @override
  int foo(T Function<T>() fn) {
    // TODO: implement foo
    return super.foo(fn);
 }
''',
        displayText: 'foo(T Function<T>() fn) { … }',
        selection: new SourceRange(143, 21));
  }

  test_writeOverrideOfInheritedMember_method_nullAsTypeArgument_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A {
  List<Null> foo();
}
class B extends A {
}
''', '''
  @override
  List<Null> foo() {
    // TODO: implement foo
    return null;
 }
''', displayText: 'foo() { … }', selection: new SourceRange(125, 12));
  }

  test_writeOverrideOfInheritedMember_method_nullAsTypeArgument_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A {
  List<Null> foo() => null
}
class B extends A {
}
''', '''
  @override
  List<Null> foo() {
    // TODO: implement foo
    return super.foo();
 }
''', displayText: 'foo() { … }', selection: new SourceRange(123, 19));
  }

  test_writeOverrideOfInheritedMember_method_voidAsTypeArgument_abstract() async {
    await _assertWriteOverrideOfInheritedMethod('''
abstract class A {
  List<void> foo();
}
class B extends A {
}
''', '''
  @override
  List<void> foo() {
    // TODO: implement foo
    return null;
  }
''', displayText: 'foo() { … }', selection: new SourceRange(125, 12));
  }

  test_writeOverrideOfInheritedMember_method_voidAsTypeArgument_concrete() async {
    await _assertWriteOverrideOfInheritedMethod('''
class A {
  List<void> foo() => null;
}
class B extends A {
}
''', '''
  @override
  List<void> foo() {
    // TODO: implement foo
    return super.foo();
  }
''', displayText: 'foo() { … }', selection: new SourceRange(124, 19));
  }

  test_writeOverrideOfInheritedMember_setter_abstract() async {
    if (previewDart2) {
      await _assertWriteOverrideOfInheritedAccessor('''
abstract class A {
  set value(int value);
}
class B extends A {
}
''', '''
  @override
  void set value(int value) {
    // TODO: implement value
  }
''', displayText: 'value(int value) { … }', selection: null);
    } else {
      await _assertWriteOverrideOfInheritedAccessor('''
abstract class A {
  set value(int value);
}
class B extends A {
}
''', '''
  @override
  set value(int value) {
    // TODO: implement value
  }
''', displayText: 'value(int value) { … }', selection: null);
    }
  }

  test_writeOverrideOfInheritedMember_setter_concrete() async {
    if (previewDart2) {
      await _assertWriteOverrideOfInheritedAccessor('''
class A {
  set value(int value) {}
}
class B extends A {
}
''', '''
  @override
  void set value(int value) {
    // TODO: implement value
    super.value = value;
  }
''',
          displayText: 'value(int value) { … }',
          selection: new SourceRange(133, 20));
    } else {
      await _assertWriteOverrideOfInheritedAccessor('''
class A {
  set value(int value) {}
}
class B extends A {
}
''', '''
  @override
  set value(int value) {
    // TODO: implement value
    super.value = value;
  }
''',
          displayText: 'value(int value) { … }',
          selection: new SourceRange(128, 20));
    }
  }

  test_writeParameter() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameter('a');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('a'));
  }

  test_writeParameter_type() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameter('a', type: typeA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A a'));
  }

  test_writeParameterMatchingArgument() async {
    String path = provider.convertPath('/test.dart');
    String content = r'''
f() {}
g() {
  f(new A());
}
class A {}
''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration g = unit.declarations[1];
    BlockFunctionBody body = g.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;
    Expression argument = invocation.argumentList.arguments[0];

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(2, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeParameterMatchingArgument(argument, 0, new Set<String>());
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A a'));
  }

  test_writeParameters_named() async {
    String path = provider.convertPath('/test.dart');
    String content = 'f(int i, {String s}) {}';
    addSource(path, content);

    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements = parameters.parameters
        .map(resolutionMap.elementDeclaredByFormalParameter);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, {String s})'));
  }

  test_writeParameters_positional() async {
    String path = provider.convertPath('/test.dart');
    String content = 'f(int i, [String s]) {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements = parameters.parameters
        .map(resolutionMap.elementDeclaredByFormalParameter);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, [String s])'));
  }

  test_writeParameters_required() async {
    String path = provider.convertPath('/test.dart');
    String content = 'f(int i, String s) {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements = parameters.parameters
        .map(resolutionMap.elementDeclaredByFormalParameter);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, String s)'));
  }

  test_writeParametersMatchingArguments_named() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
f(int i, String s) {
  g(s, index: i);
}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeParametersMatchingArguments(invocation.argumentList);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('String s, {int index}'));
  }

  test_writeParametersMatchingArguments_required() async {
    String path = provider.convertPath('/test.dart');
    String content = '''
f(int i, String s) {
  g(s, i);
}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeParametersMatchingArguments(invocation.argumentList);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('String s, int i'));
  }

  test_writeReference_method() async {
    String aPath = provider.convertPath('/a.dart');
    addSource(aPath, r'''
class A {
  void foo() {}
}
''');

    String path = provider.convertPath('/test.dart');
    String content = r'''
import 'a.dart';
''';
    addSource(path, content);

    var aElement = await _getClassElement(aPath, 'A');
    var fooElement = aElement.methods[0];

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(fooElement);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('foo'));
  }

  test_writeReference_topLevel_hasImport_noPrefix() async {
    String aPath = provider.convertPath('/a.dart');
    addSource(aPath, 'const a = 42;');

    String path = provider.convertPath('/test.dart');
    String content = r'''
import 'a.dart';
''';
    addSource(path, content);

    var aElement = await _getTopLevelAccessorElement(aPath, 'a');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(aElement);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('a'));
  }

  test_writeReference_topLevel_hasImport_prefix() async {
    String aPath = provider.convertPath('/a.dart');
    addSource(aPath, 'const a = 42;');

    String path = provider.convertPath('/test.dart');
    String content = r'''
import 'a.dart' as p;
''';
    addSource(path, content);

    var aElement = await _getTopLevelAccessorElement(aPath, 'a');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(aElement);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('p.a'));
  }

  test_writeReference_topLevel_noImport() async {
    String aPath = provider.convertPath('/a.dart');
    addSource(aPath, 'const a = 42;');

    String path = provider.convertPath('/test.dart');
    String content = '';
    addSource(path, content);

    var aElement = await _getTopLevelAccessorElement(aPath, 'a');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(aElement);
      });
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(2));
    expect(edits[0].replacement, equalsIgnoringWhitespace("import 'a.dart';"));
    expect(edits[1].replacement, equalsIgnoringWhitespace('a'));
  }

  test_writeType_dynamic() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(resolutionMap
            .elementDeclaredByCompilationUnit(unit)
            .context
            .typeProvider
            .dynamicType);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  test_writeType_function() async {
    await _assertWriteType('int Function(double a, String b)');
  }

  @failingTest
  test_writeType_function_generic() async {
    // TODO(scheglov) Fails because T/U are considered invisible.
    await _assertWriteType('T Function<T, U>(T a, U b)');
  }

  test_writeType_function_noReturnType() async {
    await _assertWriteType('Function()');
  }

  test_writeType_function_parameters_named() async {
    await _assertWriteType('int Function(int a, {int b, int c})');
  }

  test_writeType_function_parameters_noName() async {
    await _assertWriteType('int Function(double, String)');
  }

  test_writeType_function_parameters_positional() async {
    await _assertWriteType('int Function(int a, [int b, int c])');
  }

  test_writeType_genericType() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B<E> {}';
    addSource(path, content);
    InterfaceType typeA = await _getType(path, 'A');
    InterfaceType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(typeB.instantiate([typeA]));
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('B<A>'));
  }

  test_writeType_groupName() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B extends A {} class C extends B {}';
    addSource(path, content);
    DartType typeC = await _getType(path, 'C');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(typeC, groupName: 'type');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('C'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group, isNotNull);
  }

  test_writeType_groupName_addSupertypeProposals() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B extends A {} class C extends B {}';
    addSource(path, content);
    DartType typeC = await _getType(path, 'C');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeType(typeC, addSupertypeProposals: true, groupName: 'type');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('C'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    List<LinkedEditSuggestion> suggestions = group.suggestions;
    expect(suggestions, hasLength(4));
    Iterable<String> values =
        suggestions.map((LinkedEditSuggestion suggestion) {
      expect(suggestion.kind, LinkedEditSuggestionKind.TYPE);
      return suggestion.value;
    });
    expect(values, contains('Object'));
    expect(values, contains('A'));
    expect(values, contains('B'));
    expect(values, contains('C'));
  }

  test_writeType_groupName_invalidType() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A<T> {}';
    addSource(path, content);

    InterfaceType typeA = await _getType(path, 'A');
    DartType typeT = typeA.typeParameters.single.type;

    var builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (builder) {
      builder.addInsertion(content.length, (builder) {
        // "T" cannot be written, because we are outside of "A".
        // So, we also should not create linked groups.
        builder.writeType(typeT, groupName: 'type');
      });
    });
    expect(builder.sourceChange.linkedEditGroups, isEmpty);
  }

  test_writeType_interface_typeArguments() async {
    await _assertWriteType('Map<int, List<String>>');
  }

  test_writeType_interface_typeArguments_allDynamic() async {
    await _assertWriteType('Map');
  }

  test_writeType_null() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  test_writeType_prefixGenerator() async {
    String aPath = provider.convertPath('/a.dart');
    String bPath = provider.convertPath('/b.dart');

    addSource(aPath, r'''
class A1 {}
class A2 {}
''');
    addSource(bPath, r'''
class B {}
''');

    String path = provider.convertPath('/test.dart');
    String content = '';
    addSource(path, content);

    ClassElement a1 = await _getClassElement(aPath, 'A1');
    ClassElement a2 = await _getClassElement(aPath, 'A2');
    ClassElement b = await _getClassElement(bPath, 'B');

    int nextPrefixIndex = 0;
    String prefixGenerator(_) {
      return '_prefix${nextPrefixIndex++}';
    }

    var builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (builder) {
      builder.addInsertion(content.length - 1, (builder) {
        builder.writeType(a1.type);
        builder.write(' a1; ');

        builder.writeType(a2.type);
        builder.write(' a2; ');

        builder.writeType(b.type);
        builder.write(' b;');
      });
    }, importPrefixGenerator: prefixGenerator);
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(2));
    expect(
        edits[0].replacement,
        equalsIgnoringWhitespace(
            "import 'a.dart' as _prefix0; import 'b.dart' as _prefix1;"));
    expect(
        edits[1].replacement,
        equalsIgnoringWhitespace(
            '_prefix0.A1 a1; _prefix0.A2 a2; _prefix1.B b;'));
  }

  test_writeType_required_dynamic() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(
            resolutionMap
                .elementDeclaredByCompilationUnit(unit)
                .context
                .typeProvider
                .dynamicType,
            required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  test_writeType_required_notNull() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(typeA, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }

  test_writeType_required_null() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(null, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  test_writeType_simpleType() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(typeA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }

  test_writeType_typedef_typeArguments() async {
    await _assertWriteType('F<int, String>',
        declarations: 'typedef void F<T, U>(T t, U u);');
  }

  test_writeType_void() async {
    await _assertWriteType('void Function()');
  }

  test_writeTypes_empty() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, isEmpty);
  }

  test_writeTypes_noPrefix() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([typeA, typeB]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A, B'));
  }

  test_writeTypes_null() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, isEmpty);
  }

  test_writeTypes_prefix() async {
    String path = provider.convertPath('/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl)
            .writeTypes([typeA, typeB], prefix: 'implements ');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('implements A, B'));
  }

  Future<Null> _assertImportLibrary(
      String initialCode, List<String> newUris, String expectedCode) async {
    String path = provider.convertPath('/test.dart');
    addSource(path, initialCode);
    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      for (String newUri in newUris) {
        builder.importLibrary(Uri.parse(newUri));
      }
    });

    String resultCode = initialCode;
    List<SourceEdit> edits = getEdits(builder);
    for (SourceEdit edit in edits) {
      resultCode = edit.apply(resultCode);
    }
    expect(resultCode, expectedCode);
  }

  /**
   * Assuming that the [content] being edited defines a class named 'A' whose
   * first accessor is the member to be overridden and ends with a class to
   * which an inherited method is to be added, assert that the text of the
   * overridden member matches the [expected] text (modulo white space). Assert
   * that the generated display text matches the given [displayText]. If a
   * [selection] is provided, assert that the generated selection range matches
   * it.
   */
  _assertWriteOverrideOfInheritedAccessor(String content, String expected,
      {String displayText, SourceRange selection}) async {
    String path = provider.convertPath('/test.dart');
    addSource(path, content);
    ClassElement classA = await _getClassElement(path, 'A');

    StringBuffer displayBuffer =
        displayText != null ? new StringBuffer() : null;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 2, (EditBuilder builder) {
        (builder as DartEditBuilder).writeOverrideOfInheritedMember(
            classA.accessors[0],
            displayTextBuffer: displayBuffer);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(expected));
    expect(displayBuffer?.toString(), displayText);
    if (selection != null) {
      expect(builder.selectionRange, selection);
    }
  }

  /**
   * Assuming that the [content] being edited defines a class named 'A' whose
   * first method is the member to be overridden and ends with a class to which
   * an inherited method is to be added, assert that the text of the overridden
   * member matches the [expected] text (modulo white space). Assert that the
   * generated display text matches the given [displayText]. If a [selection] is
   * provided, assert that the generated selection range matches it.
   */
  _assertWriteOverrideOfInheritedMethod(String content, String expected,
      {String displayText, SourceRange selection}) async {
    String path = provider.convertPath('/test.dart');
    addSource(path, content);
    ClassElement classA = await _getClassElement(path, 'A');

    StringBuffer displayBuffer =
        displayText != null ? new StringBuffer() : null;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 2, (EditBuilder builder) {
        (builder as DartEditBuilder).writeOverrideOfInheritedMember(
            classA.methods[0],
            displayTextBuffer: displayBuffer);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(expected));
    expect(displayBuffer?.toString(), displayText);
    if (selection != null) {
      expect(builder.selectionRange, selection);
    }
  }

  Future<void> _assertWriteType(String typeCode, {String declarations}) async {
    String path = provider.convertPath('/test.dart');
    String content = (declarations ?? '') + '$typeCode v;';
    addSource(path, content);

    var f = await _getTopLevelAccessorElement(path, 'v');

    var builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (builder) {
      builder.addInsertion(content.length - 1, (builder) {
        builder.writeType(f.returnType);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, typeCode);
  }

  Future<ClassElement> _getClassElement(String path, String name) async {
    UnitElementResult result = await driver.getUnitElement(path);
    return result.element.getType(name);
  }

  Future<PropertyAccessorElement> _getTopLevelAccessorElement(
      String path, String name) async {
    UnitElementResult result = await driver.getUnitElement(path);
    return result.element.accessors.firstWhere((v) => v.name == name);
  }

  Future<InterfaceType> _getType(String path, String name) async {
    ClassElement classElement = await _getClassElement(path, name);
    return classElement.type;
  }
}

@reflectiveTest
class DartFileEditBuilderImplTest extends AbstractContextTest
    with BuilderTestMixin {
  TypeProvider get typeProvider {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactoryImpl([new DartUriResolver(sdk)]);
    return new TestTypeProvider(context);
  }

  test_convertFunctionFromSyncToAsync_closure() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, '''var f = () {}''');

    CompilationUnit unit = (await driver.getResult(path))?.unit;
    TopLevelVariableDeclaration variable = unit.declarations[0];
    FunctionBody body =
        (variable.variables.variables[0].initializer as FunctionExpression)
            .body;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      (builder as DartFileEditBuilder)
          .convertFunctionFromSyncToAsync(body, typeProvider);
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(1));
    expect(edits[0].replacement, equalsIgnoringWhitespace('async'));
  }

  test_convertFunctionFromSyncToAsync_topLevelFunction() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'String f() {}');

    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration function = unit.declarations[0];
    FunctionBody body = function.functionExpression.body;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      (builder as DartFileEditBuilder)
          .convertFunctionFromSyncToAsync(body, typeProvider);
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(3));
    expect(edits[0].replacement, equalsIgnoringWhitespace('async'));
    expect(
        edits[1].replacement, equalsIgnoringWhitespace("import 'dart:async';"));
    expect(edits[2].replacement, equalsIgnoringWhitespace('Future<String>'));
  }

  test_createEditBuilder() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'library test;');
    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      int offset = 4;
      int length = 5;
      DartEditBuilderImpl editBuilder = (builder as DartFileEditBuilderImpl)
          .createEditBuilder(offset, length);
      expect(editBuilder, new isInstanceOf<DartEditBuilder>());
      SourceEdit sourceEdit = editBuilder.sourceEdit;
      expect(sourceEdit.length, length);
      expect(sourceEdit.offset, offset);
      expect(sourceEdit.replacement, isEmpty);
    });
  }

  test_replaceTypeWithFuture() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, 'String f() {}');

    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration function = unit.declarations[0];
    TypeAnnotation type = function.returnType;

    DartChangeBuilderImpl builder = new DartChangeBuilder(session);
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      (builder as DartFileEditBuilder)
          .replaceTypeWithFuture(type, typeProvider);
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(2));
    expect(
        edits[0].replacement, equalsIgnoringWhitespace("import 'dart:async';"));
    expect(edits[1].replacement, equalsIgnoringWhitespace('Future<String>'));
  }
}

@reflectiveTest
class DartLinkedEditBuilderImplTest extends AbstractContextTest {
  test_addSuperTypesAsSuggestions() async {
    String path = provider.convertPath('/test.dart');
    addSource(path, '''
class A {}
class B extends A {}
class C extends B {}
''');
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    ClassDeclaration classC = unit.declarations[2];
    DartLinkedEditBuilderImpl builder = new DartLinkedEditBuilderImpl(null);
    builder.addSuperTypesAsSuggestions(classC.element.type);
    List<LinkedEditSuggestion> suggestions = builder.suggestions;
    expect(suggestions, hasLength(4));
    expect(suggestions.map((s) => s.value),
        unorderedEquals(['Object', 'A', 'B', 'C']));
  }
}
