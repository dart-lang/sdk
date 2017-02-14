// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.test.src.utilities.change_builder_dart_test;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/edit/utilities/change_builder_core.dart';
import 'package:analysis_server/src/provisional/edit/utilities/change_builder_dart.dart';
import 'package:analysis_server/src/utilities/change_builder_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartChangeBuilderImplTest);
    defineReflectiveTests(DartEditBuilderImplTest);
    defineReflectiveTests(DartFileEditBuilderImplTest);
  });
}

@reflectiveTest
class DartChangeBuilderImplTest extends AbstractContextTest {
  test_createFileEditBuilder() async {
    Source source = addSource('/test.dart', 'library test;');
    await resolveLibraryUnit(source);
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

  test_writeClassDeclaration_interfaces() async {
    Source source = addSource('/test.dart', 'class A {}');
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration declaration = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C', interfaces: [
          resolutionMap.elementDeclaredByClassDeclaration(declaration).type
        ]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(
        edit.replacement, equalsIgnoringWhitespace('class C implements A { }'));
  }

  test_writeClassDeclaration_isAbstract() async {
    Source source = addSource('/test.dart', '');
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeClassDeclaration('C', isAbstract: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('abstract class C { }'));
  }

  test_writeClassDeclaration_memberWriter() async {
    Source source = addSource('/test.dart', '');
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C',
            memberWriter: () {
          builder.write('/**/');
        });
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('class C { /**/ }'));
  }

  test_writeClassDeclaration_mixins_noSuperclass() async {
    Source source = addSource('/test.dart', 'class A {}');
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C', mixins: [
          resolutionMap.elementDeclaredByClassDeclaration(classA).type
        ]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('class C extends Object with A { }'));
  }

  test_writeClassDeclaration_mixins_superclass() async {
    Source source = addSource('/test.dart', 'class A {} class B {}');
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];
    ClassDeclaration classB = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C',
            mixins: [
              resolutionMap.elementDeclaredByClassDeclaration(classB).type
            ],
            superclass:
                resolutionMap.elementDeclaredByClassDeclaration(classA).type);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement,
        equalsIgnoringWhitespace('class C extends A with B { }'));
  }

  test_writeClassDeclaration_nameGroupName() async {
    Source source = addSource('/test.dart', '');
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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
    Source source = addSource('/test.dart', 'class B {}');
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration declaration = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(0, (EditBuilder builder) {
        (builder as DartEditBuilder).writeClassDeclaration('C',
            superclass: resolutionMap
                .elementDeclaredByClassDeclaration(declaration)
                .type);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('class C extends B { }'));
  }

  test_writeFieldDeclaration_initializerWriter() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isConst: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const f;'));
  }

  test_writeFieldDeclaration_isConst_isFinal() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeFieldDeclaration('f', isConst: true, isFinal: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('const f;'));
  }

  test_writeFieldDeclaration_isFinal() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isFinal: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('final f;'));
  }

  test_writeFieldDeclaration_isStatic() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f', isStatic: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('static var f;'));
  }

  test_writeFieldDeclaration_nameGroupName() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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
    String content = 'class A {} class B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration declaration = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeFieldDeclaration('f',
            type: resolutionMap
                .elementDeclaredByClassDeclaration(declaration)
                .type,
            typeGroupName: 'type');
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

  test_writeGetterDeclaration_bodyWriter() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeGetterDeclaration('g', isStatic: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('static get g => null;'));
  }

  test_writeGetterDeclaration_nameGroupName() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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
    String content = 'class A {} class B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeGetterDeclaration('g',
            returnType:
                resolutionMap.elementDeclaredByClassDeclaration(classA).type,
            returnTypeGroupName: 'returnType');
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

  test_writeOverrideOfInheritedMember() async {
    String content = '''
class A {
  A add(A a) => null;
}
class B extends A {
}''';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration declaration = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeOverrideOfInheritedMember(
            resolutionMap
                .elementDeclaredByClassDeclaration(declaration)
                .methods[0]);
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

  test_writeParameters_named() async {
    String content = 'f(int i, {String s}) {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements = parameters.parameters
        .map(resolutionMap.elementDeclaredByFormalParameter);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, {String s})'));
  }

  test_writeParameters_positional() async {
    String content = 'f(int i, [String s]) {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements = parameters.parameters
        .map(resolutionMap.elementDeclaredByFormalParameter);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, [String s])'));
  }

  test_writeParameters_required() async {
    String content = 'f(int i, String s) {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    FormalParameterList parameters = f.functionExpression.parameters;
    Iterable<ParameterElement> elements = parameters.parameters
        .map(resolutionMap.elementDeclaredByFormalParameter);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameters(elements);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(int i, String s)'));
  }

  test_writeParametersMatchingArguments_named() async {
    String content = '''
f(int i, String s) {
  g(s, index: i);
}''';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeParametersMatchingArguments(invocation.argumentList);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(
        edit.replacement, equalsIgnoringWhitespace('(String s, [int index])'));
  }

  test_writeParametersMatchingArguments_required() async {
    String content = '''
f(int i, String s) {
  g(s, i);
}''';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    FunctionDeclaration f = unit.declarations[0];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder)
            .writeParametersMatchingArguments(invocation.argumentList);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('(String s, int i)'));
  }

  test_writeParameterSource() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeParameterSource(
            resolutionMap.elementDeclaredByClassDeclaration(classA).type, 'a');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A a'));
  }

  test_writeType_dynamic() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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

  test_writeType_genericType() async {
    String content = 'class A {} class B<E> {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];
    ClassDeclaration classB = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(resolutionMap
            .elementDeclaredByClassDeclaration(classB)
            .type
            .instantiate([
          resolutionMap.elementDeclaredByClassDeclaration(classA).type
        ]));
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('B<A>'));
  }

  test_writeType_groupName() async {
    String content = 'class A {} class B extends A {} class C extends B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classC = unit.declarations[2];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(
            resolutionMap.elementDeclaredByClassDeclaration(classC).type,
            groupName: 'type');
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
    String content = 'class A {} class B extends A {} class C extends B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classC = unit.declarations[2];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(
            resolutionMap.elementDeclaredByClassDeclaration(classC).type,
            addSupertypeProposals: true,
            groupName: 'type');
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

  test_writeType_null() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace(''));
  }

  test_writeType_required_dynamic() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
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
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(
            resolutionMap.elementDeclaredByClassDeclaration(classA).type,
            required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }

  test_writeType_required_null() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(null, required: true);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('var'));
  }

  test_writeType_simpleType() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilder).writeType(
            resolutionMap.elementDeclaredByClassDeclaration(classA).type);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A'));
  }

  test_writeTypes_empty() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, isEmpty);
  }

  test_writeTypes_noPrefix() async {
    String content = 'class A {} class B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];
    ClassDeclaration classB = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([
          resolutionMap.elementDeclaredByClassDeclaration(classA).type,
          resolutionMap.elementDeclaredByClassDeclaration(classB).type
        ]);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('A, B'));
  }

  test_writeTypes_null() async {
    String content = 'class A {}';
    Source source = addSource('/test.dart', content);
    await resolveLibraryUnit(source);

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes(null);
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, isEmpty);
  }

  test_writeTypes_prefix() async {
    String content = 'class A {} class B {}';
    Source source = addSource('/test.dart', content);
    CompilationUnit unit = await resolveLibraryUnit(source);
    ClassDeclaration classA = unit.declarations[0];
    ClassDeclaration classB = unit.declarations[1];

    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, 1, (FileEditBuilder builder) {
      builder.addInsertion(content.length - 1, (EditBuilder builder) {
        (builder as DartEditBuilderImpl).writeTypes([
          resolutionMap.elementDeclaredByClassDeclaration(classA).type,
          resolutionMap.elementDeclaredByClassDeclaration(classB).type
        ], prefix: 'implements ');
      });
    });
    SourceEdit edit = getEdit(builder);
    expect(edit.replacement, equalsIgnoringWhitespace('implements A, B'));
  }
}

@reflectiveTest
class DartFileEditBuilderImplTest extends AbstractContextTest {
  test_createEditBuilder() async {
    Source source = addSource('/test.dart', 'library test;');
    await resolveLibraryUnit(source);
    int timeStamp = 65;
    DartChangeBuilderImpl builder = new DartChangeBuilderImpl(context);
    builder.addFileEdit(source, timeStamp, (FileEditBuilder builder) {
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
}
