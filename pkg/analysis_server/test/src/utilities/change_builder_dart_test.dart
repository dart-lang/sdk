// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.test.src.utilities.change_builder_dart_test;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/utilities/change_builder_core.dart';
import 'package:analysis_server/src/utilities/change_builder_dart.dart';
import 'package:analysis_server/utilities/change_builder_core.dart';
import 'package:analysis_server/utilities/change_builder_dart.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';
import '../../domain_execution_test.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(DartChangeBuilderImplTest);
  defineReflectiveTests(DartEditBuilderImplTest);
  defineReflectiveTests(DartFileEditBuilderImplTest);
}

@reflectiveTest
class DartChangeBuilderImplTest extends AbstractContextTest {
  void test_createFileEditBuilder() {
    Source source = addSource('/test.dart', 'library test;');
    resolveLibraryUnit(source);
    int timeStamp = 54;
    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    DartFileEditBuilderImpl fileEditBuilder =
        builder.createFileEditBuilder(source, timeStamp);
    expect(fileEditBuilder, new isInstanceOf<DartFileEditBuilder>());
    SourceFileEdit fileEdit = fileEditBuilder.fileEdit;
    expect(fileEdit.file, source.fullName);
    expect(fileEdit.fileStamp, timeStamp);
  }
}

@reflectiveTest
class DartEditBuilderImplTest extends AbstractContextTest {
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

  void test_writeClassDeclaration_isAbstract() {
    Source source = addSource('/test.dart', '');
    resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(0, (DartEditBuilder builder) {
        builder.writeClassDeclaration('C', isAbstract: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('abstract class C { }'));
  }

  void test_writeClassDeclaration_nameOnly() {
    Source source = addSource('/test.dart', '');
    resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(0, (DartEditBuilder builder) {
        builder.writeClassDeclaration('C');
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

  void test_writeClassDeclaration_superclass() {
    Source source = addSource('/test.dart', 'class B {}');
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration declaration = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(0, (DartEditBuilder builder) {
        builder.writeClassDeclaration('C',
            superclass: declaration.element.type);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('class C extends B { }'));
  }

  void test_writeOverrideOfInheritedMember() {
    String content = '''
class A {
  A add(A a) => null;
}
class B extends A {
}''';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration declaration = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeOverrideOfInheritedMember(declaration.element.methods[0]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('''
@override
A add(A a) {
  // TODO: implement add
  return null;
}'''));
  }

  void test_writeParameters_named() {
    String content = 'f(int i, {String s}) {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable elements = parameters.parameters
        .map((FormalParameter parameter) => parameter.element);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, {String s})'));
  }

  void test_writeParameters_positional() {
    String content = 'f(int i, [String s]) {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable elements = parameters.parameters
        .map((FormalParameter parameter) => parameter.element);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, [String s])'));
  }

  void test_writeParameters_required() {
    String content = 'f(int i, String s) {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable elements = parameters.parameters
        .map((FormalParameter parameter) => parameter.element);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, String s)'));
  }

  void test_writeParametersMatchingArguments_named() {
    String content = '''
f(int i, String s) {
  g(s, index: i);
}''';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeParametersMatchingArguments(invocation.argumentList);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(
        edit.replacement, equalsIgnoringWhitespace('(String s, [int index])'));
  }

  void test_writeParametersMatchingArguments_required() {
    String content = '''
f(int i, String s) {
  g(s, i);
}''';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeParametersMatchingArguments(invocation.argumentList);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(String s, int i)'));
  }

  void test_writeParameterSource() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeParameterSource(classA.element.type, 'a');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A a'));
  }

  void test_writeType_dymanic() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(unit.element.context.typeProvider.dynamicType);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  void test_writeType_genericType() {
    String content = 'class A {} class B<E> {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];
    ClassDeclaration classB = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder
            .writeType(classB.element.type.substitute4([classA.element.type]));
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('B<A>'));
  }

  void test_writeType_groupName() {
    String content = 'class A {} class B extends A {} class C extends B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration classC = unit.declarations[2];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(classC.element.type, groupName: 'type');
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

  void test_writeType_groupName_addSupertypeProposals() {
    String content = 'class A {} class B extends A {} class C extends B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration classC = unit.declarations[2];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(classC.element.type,
            addSupertypeProposals: true, groupName: 'type');
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
    Iterable<String> values = suggestions
        .map((LinkedEditSuggestion suggestion) {
      expect(suggestion.kind, LinkedEditSuggestionKind.TYPE);
      return suggestion.value;
    });
    expect(values, contains('Object'));
    expect(values, contains('A'));
    expect(values, contains('B'));
    expect(values, contains('C'));
  }

  void test_writeType_null() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  void test_writeType_required_dymanic() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(unit.element.context.typeProvider.dynamicType,
            required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  void test_writeType_required_notNull() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(classA.element.type, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }

  void test_writeType_required_null() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(null, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  void test_writeType_simpleType() {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (DartFileEditBuilderImpl builder) {
      builder.addInsertion(content.length - 1, (DartEditBuilder builder) {
        builder.writeType(classA.element.type);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }
}

@reflectiveTest
class DartFileEditBuilderImplTest extends AbstractContextTest {
  void test_createEditBuilder() {
    Source source = addSource('/test.dart', 'library test;');
    resolveLibraryUnit(source);
    int timeStamp = 65;
    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, timeStamp, (DartFileEditBuilderImpl builder) {
      int offset = 4;
      int length = 5;
      DartEditBuilderImpl editBuilder =
          builder.createEditBuilder(offset, length);
      expect(editBuilder, new isInstanceOf<DartEditBuilder>());
      SourceEdit sourceEdit = editBuilder.sourceEdit;
      expect(sourceEdit.length, length);
      expect(sourceEdit.offset, offset);
      expect(sourceEdit.replacement, isEmpty);
    });
  }
}
