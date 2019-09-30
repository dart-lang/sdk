// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../support/abstract_context.dart';
import 'dart/dart_change_builder_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartChangeBuilderImplTest);
    defineReflectiveTests(DartEditBuilderImplTest);
    defineReflectiveTests(DartFileEditBuilderImplTest);
    defineReflectiveTests(DartLinkedEditBuilderImplTest);
    defineReflectiveTests(ImportLibraryTest);
    defineReflectiveTests(WriteOverrideTest);
  });
}

@reflectiveTest
class DartChangeBuilderImplTest extends AbstractContextTest
    with DartChangeBuilderMixin {
  test_createFileEditBuilder() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'library test;');
    DartChangeBuilderImpl builder = newBuilder();
    DartFileEditBuilderImpl fileEditBuilder =
        await builder.createFileEditBuilder(path);
    expect(fileEditBuilder, const TypeMatcher<DartFileEditBuilder>());
    SourceFileEdit fileEdit = fileEditBuilder.fileEdit;
    expect(fileEdit.file, path);
  }
}

@reflectiveTest
class DartEditBuilderImplTest extends AbstractContextTest
    with DartChangeBuilderMixin {
  test_writeClassDeclaration_interfaces() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class A {}');
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class A {}');
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class A {} class B {}');
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class B {}');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class C {}');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, r'''
class C {
  final int a;
  final bool bb;
}
''');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(42, (DartEditBuilder builder) {
        builder.writeConstructorDeclaration('A', fieldNames: ['a', 'bb']);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A(this.a, this.bb);'));
  }

  test_writeConstructorDeclaration_initializerWriter() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class C {}');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class C {}');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isConst: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const f;'));
  }

  test_writeFieldDeclaration_isConst_isFinal() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isFinal: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('final f;'));
  }

  test_writeFieldDeclaration_isFinal_type() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isStatic: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('static var f;'));
  }

  test_writeFieldDeclaration_nameGroupName() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}''';
    addSource(path, content);
    await driver.getResult(path);

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}
class MyClass {}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    ClassDeclaration A = unit.declarations[1] as ClassDeclaration;

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration(
          'foo',
          initializerWriter: () {
            builder.write('null');
          },
          type: A.declaredElement.instantiate(
            typeArguments: [],
            nullabilitySuffix: NullabilitySuffix.star,
          ),
        );
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('MyClass foo = null;'));
  }

  test_writeLocalVariableDeclaration_type_noInitializer() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}
class MyClass {}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    ClassDeclaration A = unit.declarations[1] as ClassDeclaration;

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration(
          'foo',
          type: A.declaredElement.instantiate(
            typeArguments: [],
            nullabilitySuffix: NullabilitySuffix.star,
          ),
          typeGroupName: 'type',
        );
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
void f() {

}
class MyClass {}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    ClassDeclaration A = unit.declarations[1] as ClassDeclaration;

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(11, (EditBuilder builder) {
        (builder as DartEditBuilder).writeLocalVariableDeclaration(
          'foo',
          isFinal: true,
          type: A.declaredElement.instantiate(
            typeArguments: [],
            nullabilitySuffix: NullabilitySuffix.star,
          ),
          typeGroupName: 'type',
        );
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

  test_writeMixinDeclaration_interfaces() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class A {}');
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeMixinDeclaration('M', interfaces: [typeA]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(
        edit.replacement, equalsIgnoringWhitespace('mixin M implements A { }'));
  }

  test_writeMixinDeclaration_interfacesAndSuperclassConstraints() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class A {} class B {}');
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeMixinDeclaration('M',
            interfaces: [typeA], superclassConstraints: [typeB]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('mixin M on B implements A { }'));
  }

  test_writeMixinDeclaration_memberWriter() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeMixinDeclaration('M',
            membersWriter: () {
          builder.write('/**/');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('mixin M { /**/}'));
  }

  test_writeMixinDeclaration_nameGroupName() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeMixinDeclaration('M', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('mixin M { }'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
  }

  test_writeMixinDeclaration_superclassConstraints() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'class A {}');
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeMixinDeclaration('M', superclassConstraints: [typeA]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('mixin M on A { }'));
  }

  test_writeParameter() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameter('a');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('a'));
  }

  test_writeParameter_type() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameter('a', type: typeA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A a'));
  }

  test_writeParameterMatchingArgument() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = r'''
f() {}
g() {
  f(new A());
}
class A {}
''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration g = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = g.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement =
        body.block.statements[0] as ExpressionStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    Expression argument = invocation.argumentList.arguments[0];

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'f(int a, {bool b = false, String c}) {}';
    addSource(path, content);

    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0] as FunctionDeclaration;
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements =
        parameters.parameters.map((p) => p.declaredElement);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('(int a, {bool b = false, String c})'));
  }

  test_writeParameters_positional() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'f(int a, [bool b = false, String c]) {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0] as FunctionDeclaration;
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements =
        parameters.parameters.map((p) => p.declaredElement);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('(int a, [bool b = false, String c])'));
  }

  test_writeParameters_required() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'f(int i, String s) {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0] as FunctionDeclaration;
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements =
        parameters.parameters.map((p) => p.declaredElement);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, String s)'));
  }

  test_writeParametersMatchingArguments_named() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
f(int i, String s) {
  g(s, index: i);
}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = f.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement =
        body.block.statements[0] as ExpressionStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = '''
f(int i, String s) {
  g(s, i);
}''';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    FunctionDeclaration f = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = f.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement =
        body.block.statements[0] as ExpressionStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;

    DartChangeBuilderImpl builder = newBuilder();
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
    String aPath = convertPath('/a.dart');
    addSource(aPath, r'''
class A {
  void foo() {}
}
''');

    String path = convertPath('/home/test/lib/test.dart');
    String content = r'''
import 'a.dart';
''';
    addSource(path, content);

    var aElement = await _getClassElement(aPath, 'A');
    var fooElement = aElement.methods[0];

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(fooElement);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('foo'));
  }

  test_writeReference_topLevel_hasImport_noPrefix() async {
    String aPath = convertPath('/home/test/lib/a.dart');
    addSource(aPath, 'const a = 42;');

    String path = convertPath('/home/test/lib/test.dart');
    String content = r'''
import 'a.dart';
''';
    addSource(path, content);

    var aElement = await _getTopLevelAccessorElement(aPath, 'a');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(aElement);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('a'));
  }

  test_writeReference_topLevel_hasImport_prefix() async {
    String aPath = convertPath('/home/test/lib/a.dart');
    addSource(aPath, 'const a = 42;');

    String path = convertPath('/home/test/lib/test.dart');
    String content = r'''
import 'a.dart' as p;
''';
    addSource(path, content);

    var aElement = await _getTopLevelAccessorElement(aPath, 'a');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeReference(aElement);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('p.a'));
  }

  test_writeReference_topLevel_noImport() async {
    String aPath = convertPath('/home/test/bin/a.dart');
    addSource(aPath, 'const a = 42;');

    String path = convertPath('/home/test/bin/test.dart');
    String content = '';
    addSource(path, content);

    var aElement = await _getTopLevelAccessorElement(aPath, 'a');

    DartChangeBuilderImpl builder = newBuilder();
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

  test_writeSetterDeclaration_bodyWriter() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeSetterDeclaration('s',
            bodyWriter: () {
          builder.write('{/* TODO */}');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('set s(s) {/* TODO */}'));
  }

  test_writeSetterDeclaration_isStatic() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeSetterDeclaration('s', isStatic: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('static set s(s) {}'));
  }

  test_writeSetterDeclaration_nameGroupName() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeSetterDeclaration('s', nameGroupName: 'name');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('set s(s) {}'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
    Position position = group.positions[0];
    expect(position.offset, equals(13));
  }

  test_writeSetterDeclaration_parameterType() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeSetterDeclaration('s',
            parameterType: typeA, parameterTypeGroupName: 'returnType');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('set s(A s) {}'));

    List<LinkedEditGroup> linkedEditGroups =
        builder.sourceChange.linkedEditGroups;
    expect(linkedEditGroups, hasLength(1));
    LinkedEditGroup group = linkedEditGroups[0];
    expect(group.length, 1);
    expect(group.positions, hasLength(1));
    Position position = group.positions[0];
    expect(position.offset, equals(26));
  }

  test_writeType_dynamic() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        var typeProvider = unit.declaredElement.context.typeProvider;
        (builder as DartEditBuilder).writeType(typeProvider.dynamicType);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  test_writeType_function() async {
    await _assertWriteType('int Function(double a, String b)');
  }

  test_writeType_function_generic() async {
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B<E> {}';
    addSource(path, content);
    InterfaceType typeA = await _getType(path, 'A');
    InterfaceType typeBofA = await _getType(path, 'B', typeArguments: [typeA]);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(typeBofA);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('B<A>'));
  }

  test_writeType_groupName() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B extends A {} class C extends B {}';
    addSource(path, content);
    DartType typeC = await _getType(path, 'C');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B extends A {} class C extends B {}';
    addSource(path, content);
    DartType typeC = await _getType(path, 'C');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A<T> {}';
    addSource(path, content);

    var classA = await _getClassElement(path, 'A');
    DartType typeT = classA.typeParameters.single.instantiate(
      nullabilitySuffix: NullabilitySuffix.star,
    );

    var builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  test_writeType_prefixGenerator() async {
    String aPath = convertPath('/home/test/lib/a.dart');
    String bPath = convertPath('/home/test/lib/b.dart');

    addSource(aPath, r'''
class A1 {}
class A2 {}
''');
    addSource(bPath, r'''
class B {}
''');

    String path = convertPath('/home/test/lib/test.dart');
    String content = '';
    addSource(path, content);

    ClassElement a1 = await _getClassElement(aPath, 'A1');
    ClassElement a2 = await _getClassElement(aPath, 'A2');
    ClassElement b = await _getClassElement(bPath, 'B');

    int nextPrefixIndex = 0;
    String prefixGenerator(_) {
      return '_prefix${nextPrefixIndex++}';
    }

    var builder = newBuilder();
    await builder.addFileEdit(path, (builder) {
      builder.addInsertion(content.length - 1, (builder) {
        builder.writeType(a1.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.star,
        ));
        builder.write(' a1; ');

        builder.writeType(a2.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.star,
        ));
        builder.write(' a2; ');

        builder.writeType(b.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.star,
        ));
        builder.write(' b;');
      });
    }, importPrefixGenerator: prefixGenerator);
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(2));
    expect(
        edits[0].replacement,
        equalsIgnoringWhitespace("import 'package:test/a.dart' as _prefix0; "
            "import 'package:test/b.dart' as _prefix1;"));
    expect(
        edits[1].replacement,
        equalsIgnoringWhitespace(
            '_prefix0.A1 a1; _prefix0.A2 a2; _prefix1.B b;'));
  }

  test_writeType_required_dynamic() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    CompilationUnit unit = (await driver.getResult(path))?.unit;

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        var typeProvider = unit.declaredElement.context.typeProvider;
        (builder as DartEditBuilder)
            .writeType(typeProvider.dynamicType, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  test_writeType_required_notNull() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(typeA, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }

  test_writeType_required_null() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(null, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  test_writeType_simpleType() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');

    DartChangeBuilderImpl builder = newBuilder();
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
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, isEmpty);
  }

  test_writeTypes_noPrefix() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([typeA, typeB]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A, B'));
  }

  test_writeTypes_null() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {}';
    addSource(path, content);

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, isEmpty);
  }

  test_writeTypes_prefix() async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = 'class A {} class B {}';
    addSource(path, content);
    DartType typeA = await _getType(path, 'A');
    DartType typeB = await _getType(path, 'B');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl)
            .writeTypes([typeA, typeB], prefix: 'implements ');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('implements A, B'));
  }

  Future<void> _assertWriteType(String typeCode, {String declarations}) async {
    String path = convertPath('/home/test/lib/test.dart');
    String content = (declarations ?? '') + '$typeCode v;';
    addSource(path, content);

    var f = await _getTopLevelAccessorElement(path, 'v');

    var builder = newBuilder();
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

  Future<InterfaceType> _getType(
    String path,
    String name, {
    List<DartType> typeArguments = const [],
  }) async {
    ClassElement classElement = await _getClassElement(path, name);
    return classElement.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }
}

@reflectiveTest
class DartFileEditBuilderImplTest extends AbstractContextTest
    with DartChangeBuilderMixin {
  test_convertFunctionFromSyncToAsync_closure() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '''var f = () {}''');

    var resolvedUnit = await driver.getResult(path);
    var findNode = FindNode(resolvedUnit.content, resolvedUnit.unit);
    var body = findNode.functionBody('{}');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      (builder as DartFileEditBuilder)
          .convertFunctionFromSyncToAsync(body, resolvedUnit.typeProvider);
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(1));
    expect(edits[0].replacement, equalsIgnoringWhitespace('async'));
  }

  test_convertFunctionFromSyncToAsync_topLevelFunction() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'String f() {}');

    var resolvedUnit = await driver.getResult(path);
    var findNode = FindNode(resolvedUnit.content, resolvedUnit.unit);
    var body = findNode.functionBody('{}');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      (builder as DartFileEditBuilder)
          .convertFunctionFromSyncToAsync(body, resolvedUnit.typeProvider);
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(2));
    expect(edits[0].replacement, equalsIgnoringWhitespace('async'));
    expect(edits[1].replacement, equalsIgnoringWhitespace('Future<String>'));
  }

  test_createEditBuilder() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'library test;');
    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      int offset = 4;
      int length = 5;
      DartEditBuilderImpl editBuilder = (builder as DartFileEditBuilderImpl)
          .createEditBuilder(offset, length);
      expect(editBuilder, const TypeMatcher<DartEditBuilder>());
      SourceEdit sourceEdit = editBuilder.sourceEdit;
      expect(sourceEdit.length, length);
      expect(sourceEdit.offset, offset);
      expect(sourceEdit.replacement, isEmpty);
    });
  }

  test_format_hasEdits() async {
    var initialCode = r'''
void functionBefore() {
  1 +  2;
}

void foo() {
  1 +  2;
  42;
  3 +  4;
}

void functionAfter() {
  1 +  2;
}
''';
    var path = convertPath('/home/test/lib/test.dart');
    newFile(path, content: initialCode);

    var builder = newBuilder();
    await builder.addFileEdit(path, (builder) {
      builder.addInsertion(34, (builder) {
        builder.writeln('  3 +  4;');
      });
      builder.addSimpleReplacement(SourceRange(62, 2), '1 +  2 +  3');
      builder.addInsertion(112, (builder) {
        builder.writeln('  3 +  4;');
      });
      builder.format(SourceRange(48, 29));
    });

    var edits = getEdits(builder);
    var resultCode = SourceEdit.applySequence(initialCode, edits);
    expect(resultCode, r'''
void functionBefore() {
  1 +  2;
  3 +  4;
}

void foo() {
  1 + 2;
  1 + 2 + 3;
  3 + 4;
}

void functionAfter() {
  1 +  2;
  3 +  4;
}
''');
  }

  test_format_noEdits() async {
    var initialCode = r'''
void functionBefore() {
  1 +  2;
}

void foo() {
  1 +  2;
  3;
  4 +  5;
}

void functionAfter() {
  1 +  2;
}
''';
    var path = convertPath('/home/test/lib/test.dart');
    newFile(path, content: initialCode);

    var builder = newBuilder();
    await builder.addFileEdit(path, (builder) {
      builder.format(SourceRange(37, 39));
    });

    var edits = getEdits(builder);
    var resultCode = SourceEdit.applySequence(initialCode, edits);
    expect(resultCode, r'''
void functionBefore() {
  1 +  2;
}

void foo() {
  1 + 2;
  3;
  4 + 5;
}

void functionAfter() {
  1 +  2;
}
''');
  }

  test_replaceTypeWithFuture() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, 'String f() {}');

    var resolvedUnit = await driver.getResult(path);
    var findNode = FindNode(resolvedUnit.content, resolvedUnit.unit);
    var type = findNode.typeAnnotation('String');

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      (builder as DartFileEditBuilder)
          .replaceTypeWithFuture(type, resolvedUnit.typeProvider);
    });
    List<SourceEdit> edits = getEdits(builder);
    expect(edits, hasLength(1));
    expect(edits[0].replacement, equalsIgnoringWhitespace('Future<String>'));
  }
}

@reflectiveTest
class DartLinkedEditBuilderImplTest extends AbstractContextTest {
  test_addSuperTypesAsSuggestions() async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, '''
class A {}
class B extends A {}
class C extends B {}
''');
    CompilationUnit unit = (await driver.getResult(path))?.unit;
    ClassDeclaration classC = unit.declarations[2] as ClassDeclaration;
    DartLinkedEditBuilderImpl builder = new DartLinkedEditBuilderImpl(null);
    builder.addSuperTypesAsSuggestions(
      classC.declaredElement.instantiate(
        typeArguments: [],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    List<LinkedEditSuggestion> suggestions = builder.suggestions;
    expect(suggestions, hasLength(4));
    expect(suggestions.map((s) => s.value),
        unorderedEquals(['Object', 'A', 'B', 'C']));
  }
}

@reflectiveTest
class ImportLibraryTest extends AbstractContextTest
    with DartChangeBuilderMixin {
  test_dart_beforeDart() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:aaa';
import 'dart:ccc';
''',
      uriList: ['dart:bbb'],
      expectedCode: '''
import 'dart:aaa';
import 'dart:bbb';
import 'dart:ccc';
''',
    );
  }

  test_dart_beforeDart_first() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:bbb';
''',
      uriList: ['dart:aaa'],
      expectedCode: '''
import 'dart:aaa';
import 'dart:bbb';
''',
    );
  }

  test_dart_beforePackage() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:foo/foo.dart';
''',
      uriList: ['dart:async'],
      expectedCode: '''
import 'dart:async';

import 'package:foo/foo.dart';
''',
    );
  }

  test_multiple_dart_then_package() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:aaa';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:ccc/ccc.dart';
''',
      uriList: ['dart:bbb', 'package:bbb/bbb.dart'],
      expectedCode: '''
import 'dart:aaa';
import 'dart:bbb';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
''',
    );
  }

  test_multiple_package_then_dart() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:aaa';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:ccc/ccc.dart';
''',
      uriList: ['package:bbb/bbb.dart', 'dart:bbb'],
      expectedCode: '''
import 'dart:aaa';
import 'dart:bbb';
import 'dart:ccc';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
''',
    );
  }

  test_noDirectives_docComment() async {
    await _assertImportLibrary(
      initialCode: '''
/// Documentation comment.
/// Continues.
void main() {}
''',
      uriList: ['dart:async'],
      expectedCode: '''
import 'dart:async';

/// Documentation comment.
/// Continues.
void main() {}
''',
    );
  }

  test_noDirectives_hashBang() async {
    await _assertImportLibrary(
      initialCode: '''
#!/bin/dart

void main() {}
''',
      uriList: ['dart:async'],
      expectedCode: '''
#!/bin/dart

import 'dart:async';

void main() {}
''',
    );
  }

  test_noDirectives_lineComment() async {
    await _assertImportLibrary(
      initialCode: '''
// Not documentation comment.
// Continues.

void main() {}
''',
      uriList: ['dart:async'],
      expectedCode: '''
// Not documentation comment.
// Continues.

import 'dart:async';

void main() {}
''',
    );
  }

  test_noImports_afterLibrary_hasDeclaration() async {
    await _assertImportLibrary(
      initialCode: '''
library test;

class A {}
''',
      uriList: ['dart:async'],
      expectedCode: '''
library test;

import 'dart:async';

class A {}
''',
    );
  }

  test_noImports_afterLibrary_hasPart() async {
    await _assertImportLibrary(
      initialCode: '''
library test;

part 'a.dart';
''',
      uriList: ['dart:aaa', 'dart:bbb'],
      expectedCode: '''
library test;

import 'dart:aaa';
import 'dart:bbb';

part 'a.dart';
''',
    );
  }

  test_noImports_beforePart() async {
    await _assertImportLibrary(
      initialCode: '''
part 'a.dart';
''',
      uriList: ['dart:aaa', 'dart:bbb'],
      expectedCode: '''
import 'dart:aaa';
import 'dart:bbb';

part 'a.dart';
''',
    );
  }

  test_package_afterDart() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:async';
''',
      uriList: ['package:aaa/aaa.dart'],
      expectedCode: '''
import 'dart:async';

import 'package:aaa/aaa.dart';
''',
    );
  }

  test_package_afterPackage() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:aaa/a1.dart';

import 'foo.dart';
''',
      uriList: ['package:aaa/a2.dart'],
      expectedCode: '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
    );
  }

  test_package_afterPackage_leadingComment() async {
    await _assertImportLibrary(
      initialCode: '''
// comment
import 'package:aaa/a1.dart';

import 'foo.dart';
''',
      uriList: ['package:aaa/a2.dart'],
      expectedCode: '''
// comment
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
    );
  }

  test_package_afterPackage_trailingComment() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:aaa/a1.dart'; // comment

import 'foo.dart';
''',
      uriList: ['package:aaa/a2.dart'],
      expectedCode: '''
import 'package:aaa/a1.dart'; // comment
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
    );
  }

  test_package_beforePackage() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:aaa/a1.dart';
import 'package:aaa/a3.dart';

import 'foo.dart';
''',
      uriList: ['package:aaa/a2.dart'],
      expectedCode: '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';
import 'package:aaa/a3.dart';

import 'foo.dart';
''',
    );
  }

  test_package_beforePackage_first() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
      uriList: ['package:aaa/a1.dart'],
      expectedCode: '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
    );
  }

  test_package_beforePackage_leadingComments() async {
    await _assertImportLibrary(
      initialCode: '''
// comment a2
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
      uriList: ['package:aaa/a1.dart'],
      expectedCode: '''
// comment a2
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart';

import 'foo.dart';
''',
    );
  }

  test_package_beforePackage_trailingComments() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:aaa/a2.dart'; // comment a2

import 'foo.dart';
''',
      uriList: ['package:aaa/a1.dart'],
      expectedCode: '''
import 'package:aaa/a1.dart';
import 'package:aaa/a2.dart'; // comment a2

import 'foo.dart';
''',
    );
  }

  test_package_beforeRelative() async {
    await _assertImportLibrary(
      initialCode: '''
import 'foo.dart';
''',
      uriList: ['package:aaa/aaa.dart'],
      expectedCode: '''
import 'package:aaa/aaa.dart';

import 'foo.dart';
''',
    );
  }

  test_relative_afterDart() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:async';
''',
      uriList: ['aaa.dart'],
      expectedCode: '''
import 'dart:async';

import 'aaa.dart';
''',
    );
  }

  test_relative_afterPackage() async {
    await _assertImportLibrary(
      initialCode: '''
import 'package:foo/foo.dart';
''',
      uriList: ['aaa.dart'],
      expectedCode: '''
import 'package:foo/foo.dart';

import 'aaa.dart';
''',
    );
  }

  test_relative_beforeRelative() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
import 'ccc.dart';
''',
      uriList: ['bbb.dart'],
      expectedCode: '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
import 'bbb.dart';
import 'ccc.dart';
''',
    );
  }

  test_relative_beforeRelative_first() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'bbb.dart';
''',
      uriList: ['aaa.dart'],
      expectedCode: '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
import 'bbb.dart';
''',
    );
  }

  test_relative_last() async {
    await _assertImportLibrary(
      initialCode: '''
import 'dart:async';

import 'package:foo/foo.dart';
''',
      uriList: ['aaa.dart'],
      expectedCode: '''
import 'dart:async';

import 'package:foo/foo.dart';

import 'aaa.dart';
''',
    );
  }

  Future<void> _assertImportLibrary({
    String initialCode,
    List<String> uriList,
    String expectedCode,
  }) async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, initialCode);
    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (DartFileEditBuilder builder) {
      for (var i = 0; i < uriList.length; ++i) {
        var uri = Uri.parse(uriList[i]);
        builder.importLibrary(uri);
      }
    });

    String resultCode = initialCode;
    List<SourceEdit> edits = getEdits(builder);
    for (SourceEdit edit in edits) {
      resultCode = edit.apply(resultCode);
    }
    expect(resultCode, expectedCode);
  }
}

@reflectiveTest
class WriteOverrideTest extends AbstractContextTest
    with DartChangeBuilderMixin {
  test_getter_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  int get zero;
}
class B extends A {
}
''',
      nameToOverride: 'zero',
      expected: '''
  @override
  // TODO: implement zero
  int get zero => null;
''',
      displayText: 'zero => …',
      selection: new SourceRange(111, 4),
    );
  }

  test_getter_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  int get zero => 0;
}
class B extends A {
}
''',
      nameToOverride: 'zero',
      invokeSuper: true,
      expected: '''
  @override
  // TODO: implement zero
  int get zero => super.zero;
''',
      displayText: 'zero => …',
      selection: new SourceRange(107, 10),
    );
  }

  test_method_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  A add(A a);
}
class B extends A {
}
''',
      nameToOverride: 'add',
      expected: '''
  @override
  A add(A a) {
    // TODO: implement add
    return null;
  }
''',
      displayText: 'add(A a) { … }',
      selection: new SourceRange(111, 12),
    );
  }

  test_method_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  A add(A a) => null;
}
class B extends A {
}
''',
      nameToOverride: 'add',
      invokeSuper: true,
      expected: '''
  @override
  A add(A a) {
    // TODO: implement add
    return super.add(a);
  }
''',
      displayText: 'add(A a) { … }',
      selection: new SourceRange(110, 20),
    );
  }

  test_method_functionTypeAlias_abstract() async {
    await _assertWriteOverride(
      content: '''
typedef int F(int left, int right);
abstract class A {
  void perform(F f);
}
class B extends A {
}
''',
      nameToOverride: 'perform',
      expected: '''
  @override
  void perform(F f) {
    // TODO: implement perform
  }
''',
      displayText: 'perform(F f) { … }',
    );
  }

  test_method_functionTypeAlias_concrete() async {
    await _assertWriteOverride(
      content: '''
typedef int F(int left, int right);
class A {
  void perform(F f) {}
}
class B extends A {
}
''',
      nameToOverride: 'perform',
      invokeSuper: true,
      expected: '''
  @override
  void perform(F f) {
    // TODO: implement perform
    super.perform(f);
  }
''',
      displayText: 'perform(F f) { … }',
      selection: new SourceRange(158, 17),
    );
  }

  test_method_functionTypedParameter_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  forEach(int f(double p1, String p2));
}
class B extends A {
}
''',
      nameToOverride: 'forEach',
      expected: '''
  @override
  forEach(int Function(double p1, String p2) f) {
    // TODO: implement forEach
    return null;
  }
''',
      displayText: 'forEach(int Function(double p1, String p2) f) { … }',
      selection: new SourceRange(176, 12),
    );
  }

  test_method_functionTypedParameter_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  forEach(int f(double p1, String p2)) {}
}
class B extends A {
}
''',
      nameToOverride: 'forEach',
      invokeSuper: true,
      expected: '''
  @override
  forEach(int Function(double p1, String p2) f) {
    // TODO: implement forEach
    return super.forEach(f);
  }
''',
      displayText: 'forEach(int Function(double p1, String p2) f) { … }',
      selection: new SourceRange(169, 24),
    );
  }

  test_method_generic_noBounds_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  List<T> get<T>(T key);
}
class B implements A {
}
''',
      nameToOverride: 'get',
      expected: '''
  @override
  List<T> get<T>(T key) {
    // TODO: implement get
    return null;
  }
''',
      displayText: 'get<T>(T key) { … }',
      selection: new SourceRange(136, 12),
    );
  }

  test_method_generic_noBounds_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  List<T> get<T>(T key) {}
}
class B implements A {
}
''',
      nameToOverride: 'get',
      invokeSuper: true,
      expected: '''
  @override
  List<T> get<T>(T key) {
    // TODO: implement get
    return super.get(key);
  }
''',
      displayText: 'get<T>(T key) { … }',
      selection: new SourceRange(129, 22),
    );
  }

  test_method_generic_withBounds_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A<K1, V1> {
  List<T> get<T extends V1>(K1 key);
}
class B<K2, V2> implements A<K2, V2> {
}
''',
      nameToOverride: 'get',
      expected: '''
  @override
  List<T> get<T extends V2>(K2 key) {
    // TODO: implement get
    return null;
  }
''',
      displayText: 'get<T extends V2>(K2 key) { … }',
      selection: new SourceRange(184, 12),
    );
  }

  test_method_generic_withBounds_concrete() async {
    await _assertWriteOverride(
      content: '''
class A<K1, V1> {
  List<T> get<T extends V1>(K1 key) {
    return null;
  }
}
class B<K2, V2> implements A<K2, V2> {
}
''',
      nameToOverride: 'get',
      invokeSuper: true,
      expected: '''
  @override
  List<T> get<T extends V2>(K2 key) {
    // TODO: implement get
    return super.get(key);
  }
''',
      displayText: 'get<T extends V2>(K2 key) { … }',
      selection: new SourceRange(197, 22),
    );
  }

  test_method_genericFunctionTypedParameter_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  int foo(T Function<T>() fn);
}
class B extends A {
}
''',
      nameToOverride: 'foo',
      expected: '''
  @override
  int foo(T Function<T>() fn) {
    // TODO: implement foo
    return null;
 }
''',
      displayText: 'foo(T Function<T>() fn) { … }',
      selection: new SourceRange(145, 12),
    );
  }

  test_method_genericFunctionTypedParameter_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  int foo(T Function<T>() fn) => 0;
}
class B extends A {
}
''',
      nameToOverride: 'foo',
      invokeSuper: true,
      expected: '''
  @override
  int foo(T Function<T>() fn) {
    // TODO: implement foo
    return super.foo(fn);
 }
''',
      displayText: 'foo(T Function<T>() fn) { … }',
      selection: new SourceRange(141, 21),
    );
  }

  test_method_nullAsTypeArgument_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  List<Null> foo();
}
class B extends A {
}
''',
      nameToOverride: 'foo',
      expected: '''
  @override
  List<Null> foo() {
    // TODO: implement foo
    return null;
 }
''',
      displayText: 'foo() { … }',
      selection: new SourceRange(123, 12),
    );
  }

  test_method_nullAsTypeArgument_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  List<Null> foo() => null
}
class B extends A {
}
''',
      nameToOverride: 'foo',
      invokeSuper: true,
      expected: '''
  @override
  List<Null> foo() {
    // TODO: implement foo
    return super.foo();
 }
''',
      displayText: 'foo() { … }',
      selection: new SourceRange(121, 19),
    );
  }

  test_method_returnVoid_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  void test();
}
class B extends A {
}
''',
      nameToOverride: 'test',
      expected: '''
  @override
  void test() {
    // TODO: implement test
  }
''',
      displayText: 'test() { … }',
      selection: new SourceRange(109, 0),
    );
  }

  test_method_voidAsTypeArgument_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  List<void> foo();
}
class B extends A {
}
''',
      nameToOverride: 'foo',
      expected: '''
  @override
  List<void> foo() {
    // TODO: implement foo
    return null;
  }
''',
      displayText: 'foo() { … }',
      selection: new SourceRange(123, 12),
    );
  }

  test_method_voidAsTypeArgument_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  List<void> foo() => null;
}
class B extends A {
}
''',
      nameToOverride: 'foo',
      invokeSuper: true,
      expected: '''
  @override
  List<void> foo() {
    // TODO: implement foo
    return super.foo();
  }
''',
      displayText: 'foo() { … }',
      selection: new SourceRange(122, 19),
    );
  }

  test_mixin_method_of_interface() async {
    await _assertWriteOverride(
      content: '''
class A {
  void foo(int a) {}
}

mixin M implements A {
}
''',
      nameToOverride: 'foo',
      targetMixinName: 'M',
      expected: '''
  @override
  void foo(int a) {
    // TODO: implement foo
  }
''',
      displayText: 'foo(int a) { … }',
      selection: new SourceRange(113, 0),
    );
  }

  test_mixin_method_of_superclassConstraint() async {
    await _assertWriteOverride(
      content: '''
class A {
  void foo(int a) {}
}

mixin M on A {
}
''',
      nameToOverride: 'foo',
      targetMixinName: 'M',
      invokeSuper: true,
      expected: '''
  @override
  void foo(int a) {
    // TODO: implement foo
    super.foo(a);
  }
''',
      displayText: 'foo(int a) { … }',
      selection: new SourceRange(110, 13),
    );
  }

  test_setter_abstract() async {
    await _assertWriteOverride(
      content: '''
abstract class A {
  set value(int value);
}
class B extends A {
}
''',
      nameToOverride: 'value=',
      expected: '''
  @override
  void set value(int value) {
    // TODO: implement value
  }
''',
      displayText: 'value(int value) { … }',
      selection: new SourceRange(133, 0),
    );
  }

  test_setter_concrete() async {
    await _assertWriteOverride(
      content: '''
class A {
  set value(int value) {}
}
class B extends A {
}
''',
      nameToOverride: 'value=',
      invokeSuper: true,
      expected: '''
  @override
  void set value(int value) {
    // TODO: implement value
    super.value = value;
  }
''',
      displayText: 'value(int value) { … }',
      selection: new SourceRange(131, 20),
    );
  }

  /**
   * Assuming that the [content] being edited defines a class named `A` whose
   * member with the given [nameToOverride] to be overridden and has
   * `class B extends A {...}` to which an inherited method is to be added,
   * assert that the text of the overridden member matches the [expected] text
   * (modulo white space). Assert that the generated display text matches the
   * given [displayText]. If a [selection] is provided, assert that the
   * generated selection range matches it.
   */
  _assertWriteOverride({
    String content,
    String nameToOverride,
    String expected,
    String displayText,
    SourceRange selection,
    String targetClassName = 'B',
    String targetMixinName,
    bool invokeSuper = false,
  }) async {
    String path = convertPath('/home/test/lib/test.dart');
    addSource(path, content);

    ClassElement targetElement;
    {
      var unitResult = await driver.getUnitElement(path);
      if (targetMixinName != null) {
        targetElement = unitResult.element.mixins
            .firstWhere((e) => e.name == targetMixinName);
      } else {
        targetElement = unitResult.element.types
            .firstWhere((e) => e.name == targetClassName);
      }
    }

    var targetType = targetElement.instantiate(
      typeArguments: targetElement.typeParameters
          .map((e) => e.instantiate(nullabilitySuffix: NullabilitySuffix.star))
          .toList(),
      nullabilitySuffix: NullabilitySuffix.star,
    );

    TypeSystem typeSystem = await session.typeSystem;
    var inherited = new InheritanceManager3(typeSystem).getInherited(
      targetType,
      new Name(null, nameToOverride),
    );

    StringBuffer displayBuffer =
        displayText != null ? new StringBuffer() : null;

    DartChangeBuilderImpl builder = newBuilder();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 2, (EditBuilder builder) {
        (builder as DartEditBuilder).writeOverride(
          inherited,
          displayTextBuffer: displayBuffer,
          invokeSuper: invokeSuper,
        );
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(expected));
    expect(displayBuffer?.toString(), displayText);
    if (selection != null) {
      expect(builder.selectionRange, selection);
    }
  }
}
