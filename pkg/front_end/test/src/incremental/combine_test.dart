// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/incremental/combine.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CombineTest);
  });
}

@reflectiveTest
class CombineTest {
  Program sdk;
  CoreTypes coreTypes;

  Supertype get objectSuper => coreTypes.objectClass.asThisSupertype;

  void setUp() {
    sdk = createMockSdkProgram();
    coreTypes = new CoreTypes(sdk);
  }

  void test_class_mergeLibrary_appendClass() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addClass(new Class(name: 'A', supertype: objectSuper));

    var libraryA2 = _newLibrary('a');
    libraryA2.addClass(new Class(name: 'B', supertype: objectSuper));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');

      var classA = _getClass(libraryA, 'A');
      expect(classA.members, isEmpty);

      var classB = _getClass(libraryA, 'B');
      expect(classB.members, isEmpty);
    });
  }

  void test_field() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addField(_newField('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addField(_newField('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getField(libraryA, 'A');
      _getField(libraryA, 'B');
    });
  }

  void test_field_skipDuplicate() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addField(_newField('A'));
    libraryA1.addField(_newField('B'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addField(_newField('A'));
    libraryA2.addField(_newField('C'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getField(libraryA, 'A');
      _getField(libraryA, 'B');
      _getField(libraryA, 'C');
    });
  }

  void test_field_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var fieldA1A = _newField('A');
    libraryA1.addField(fieldA1A);

    var libraryA2 = _newLibrary('a');
    var fieldA2A = _newField('A');
    libraryA2.addField(fieldA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newMainProcedure([
      new StaticGet(fieldA2A),
      new StaticSet(fieldA2A, new IntLiteral(0)),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getField(libraryA, 'A');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect((_getMainExpression(main, 0) as StaticGet).targetReference,
          same(fieldA1A.reference));
      expect((_getMainExpression(main, 1) as StaticSet).targetReference,
          same(fieldA1A.reference));
    });
  }

  void test_library_replaceReference() {
    var libraryA1 = _newLibrary('a');

    var libraryA2 = _newLibrary('a');

    var libraryB = _newLibrary('b');
    libraryB.dependencies.add(new LibraryDependency.import(libraryA2));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');

      var libraryB = _getLibrary(result.program, 'b');
      expect(libraryB.dependencies, hasLength(1));
      expect(libraryB.dependencies[0].targetLibrary, libraryA);
    });
  }

  void test_procedure_getter() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newGetter('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newGetter('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@getters');
      _getProcedure(libraryA, 'B', '@getters');
    });
  }

  void test_procedure_method() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newMethod('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newMethod('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@methods');
      _getProcedure(libraryA, 'B', '@methods');
    });
  }

  void test_procedure_method_skipDuplicate() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newMethod('A'));
    libraryA1.addProcedure(_newMethod('B'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newMethod('A'));
    libraryA2.addProcedure(_newMethod('C'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@methods');
      _getProcedure(libraryA, 'B', '@methods');
      _getProcedure(libraryA, 'C', '@methods');
    });
  }

  void test_procedure_method_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var procedureA1A = _newMethod('A');
    libraryA1.addProcedure(procedureA1A);

    var libraryA2 = _newLibrary('a');
    var procedureA2A = _newMethod('A');
    libraryA2.addProcedure(procedureA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newMainProcedure([
      new StaticInvocation(procedureA2A, new Arguments.empty()),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@methods');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect((_getMainExpression(main, 0) as StaticInvocation).targetReference,
          same(procedureA1A.reference));
    });
  }

  void test_procedure_setter() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newSetter('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newSetter('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@setters');
      _getProcedure(libraryA, 'B', '@setters');
    });
  }

  void test_undo_twice() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addField(_newField('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addField(_newField('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    var result = combine([outline1, outline2]);
    result.undo();
    expect(() => result.undo(), throwsStateError);
  }

  /// Get a single [Class] with the given [name].
  /// Throw if there is not exactly one.
  Class _getClass(Library library, String name) {
    var results = library.classes.where((class_) => class_.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Class result = results.first;
    expect(result.parent, library);
    expect(result.canonicalName.parent, library.canonicalName);
    return result;
  }

  /// Get a single [Field] with the given [name].
  /// Throw if there is not exactly one.
  Field _getField(Library library, String name) {
    var results = library.fields.where((field) => field.name.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Field result = results.first;
    expect(result.parent, library);
    var parentName = library.canonicalName.getChild('@fields');
    expect(result.canonicalName.parent, parentName);
    return result;
  }

  /// Get a single [Library] with the given [name].
  /// Throw if there is not exactly one.
  Library _getLibrary(Program program, String name) {
    var results = program.libraries.where((library) => library.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    var result = results.first;
    expect(result.parent, program);
    expect(result.canonicalName.parent, program.root);
    return result;
  }

  /// Return the [Expression] in the [index]th statement of the [procedure]'s
  /// block body.
  Expression _getMainExpression(Procedure procedure, int index) {
    Block mainBlock = procedure.function.body;
    ExpressionStatement statement = mainBlock.statements[index];
    return statement.expression;
  }

  /// Get a single [Procedure] with the given [name].
  /// Throw if there is not exactly one.
  Procedure _getProcedure(Library library, String name, String prefixName) {
    var results =
        library.procedures.where((procedure) => procedure.name.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Procedure result = results.first;
    expect(result.parent, library);

    var parentName = library.canonicalName.getChild(prefixName);
    expect(result.canonicalName.parent, parentName);

    return result;
  }

  Field _newField(String name) {
    return new Field(new Name(name));
  }

  Procedure _newGetter(String name) {
    return new Procedure(new Name(name), ProcedureKind.Getter,
        new FunctionNode(new ExpressionStatement(new IntLiteral((0)))));
  }

  Library _newLibrary(String name) {
    var uri = Uri.parse('org-dartlang:///$name.dart');
    return new Library(uri, name: name);
  }

  Procedure _newMainProcedure(List<Expression> expressions) {
    var statements =
        expressions.map((e) => new ExpressionStatement(e)).toList();
    return new Procedure(new Name('main'), ProcedureKind.Method,
        new FunctionNode(new Block(statements)));
  }

  Procedure _newMethod(String name) {
    return new Procedure(new Name(name), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()));
  }

  Program _newOutline(List<Library> libraries) {
    var outline = new Program(libraries: libraries);
    outline.computeCanonicalNames();
    return outline;
  }

  Procedure _newSetter(String name) {
    return new Procedure(
        new Name(name),
        ProcedureKind.Setter,
        new FunctionNode(new EmptyStatement(),
            positionalParameters: [new VariableDeclaration('_')]));
  }

  void _runCombineTest(
      List<Program> outlines, void checkResult(CombineResult result)) {
    // Store the original state.
    var states = <Program, _OutlineState>{};
    for (var outline in outlines) {
      states[outline] = new _OutlineState(outline);
    }

    // Combine the outlines and check the result.
    var result = combine(outlines);
    checkResult(result);

    // Undo and verify that the state is the same as the original.
    result.undo();
    states.forEach((outline, state) {
      state.verifySame();
    });
  }
}

/// The original state of an outline, and code that validates that after some
/// manipulations (e.g. combine and undo) the state stays the same.
class _OutlineState {
  final Program outline;
  final initialCollector = new _StateCollector();

  _OutlineState(this.outline) {
    outline.accept(initialCollector);
  }

  void verifySame() {
    var collector = new _StateCollector();
    outline.accept(collector);
    expect(collector.nodes, initialCollector.nodes);
    expect(collector.references, initialCollector.references);
    initialCollector.libraryParents.forEach((library, outline) {
      expect(library.canonicalName.parent, outline.root);
      expect(library.parent, outline);
    });
    initialCollector.nodeParents.forEach((child, parent) {
      expect(child.parent, parent);
      if (child is Member) {
        var qualifier = CanonicalName.getMemberQualifier(child);
        var parentName = parent.canonicalName.getChild(qualifier);
        expect(child.canonicalName.parent, parentName);
      } else {
        expect(child.canonicalName.parent, parent.canonicalName);
      }
    });
  }
}

class _StateCollector extends RecursiveVisitor {
  final List<Node> nodes = [];
  final Map<NamedNode, NamedNode> nodeParents = {};
  final Map<Library, Program> libraryParents = {};
  final List<Reference> references = [];

  @override
  void defaultMemberReference(Member node) {
    references.add(node.reference);
  }

  @override
  void defaultNode(Node node) {
    nodes.add(node);
    if (node is Library) {
      libraryParents[node] = node.parent as Program;
    } else if (node is NamedNode) {
      nodeParents[node] = node.parent as NamedNode;
    }
    super.defaultNode(node);
  }

  @override
  void visitClassReference(Class node) {
    references.add(node.reference);
  }

  @override
  visitLibraryDependency(LibraryDependency node) {
    references.add(node.importedLibraryReference);
    super.visitLibraryDependency(node);
  }

  @override
  void visitTypedefReference(Typedef node) {
    references.add(node.reference);
  }
}
