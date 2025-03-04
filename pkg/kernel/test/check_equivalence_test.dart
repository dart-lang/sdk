// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/equivalence.dart' show EquivalenceResult;
import 'package:kernel/src/tool/check_equivalence.dart';

Uri fileUri1 = Uri.parse('file://uri1');
Uri fileUri2 = Uri.parse('file://uri2');
Uri fileUri3 = Uri.parse('file://uri3');
Uri importUri1 = Uri.parse('import://uri1');
Uri importUri2 = Uri.parse('import://uri2');
Uri importUri3 = Uri.parse('import://uri3');

List<Test> tests = [
  new Test((_) => new Component()),
  new Test((_) => new Component()
    ..libraries.add(new Library(importUri1, fileUri: fileUri1))),
  new Test((bool first) {
    return new Component()
      ..libraries.add(new Library(first ? importUri1 : importUri2,
          fileUri: first ? fileUri1 : fileUri2))
      ..libraries.add(new Library(first ? importUri2 : importUri1,
          fileUri: first ? fileUri2 : fileUri1));
  }, inequivalence: '''
Inequivalent nodes
1: library import://uri1
2: library import://uri2
.root
 Component.libraries[0]
''', unorderedLibraries: true),
  new Test((bool first) {
    Component c = new Component();
    Library library1 = new Library(importUri1, fileUri: fileUri1);
    Library library2 = new Library(importUri2, fileUri: fileUri2);
    c.libraries.add(library1);
    c.libraries.add(library2);
    library1.dependencies
      ..add(new LibraryDependency.import(first ? library2 : library1))
      ..add(new LibraryDependency.import(first ? library1 : library2));
    return c;
  }, inequivalence: '''
Inequivalent references:
1: Reference to library import://uri2
2: Reference to library import://uri1
.root
 Component.libraries[0]
  Library(library import://uri1).dependencies[0]
   LibraryDependency.importedLibraryReference
Inequivalent references:
1: Reference to library import://uri1
2: Reference to library import://uri2
.root
 Component.libraries[0]
  Library(library import://uri1).dependencies[1]
   LibraryDependency.importedLibraryReference
''', unorderedLibraryDependencies: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    Field f1 = new Field.immutable(new Name('field1'), fileUri: fileUri1);
    l.addField(f1);
    Field f2 = new Field.immutable(new Name('field2'), fileUri: fileUri1);
    l.addField(f2);
    l.additionalExports.add(first ? f1.getterReference : f2.getterReference);
    l.additionalExports.add(first ? f2.getterReference : f1.getterReference);
    return c;
  }, inequivalence: '''
Inequivalent references:
1: Reference to field1
2: Reference to field2
.root
 Component.libraries[0]
  Library(library import://uri1).additionalExports[0]
''', unorderedAdditionalExports: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    l.parts
      ..add(new LibraryPart([], first ? '${fileUri2}' : '${fileUri3}')
        ..parent = l)
      ..add(new LibraryPart([], first ? '${fileUri3}' : '${fileUri2}')
        ..parent = l);
    return c;
  }, inequivalence: '''
Values file://uri2/ and file://uri3/ are not equivalent
.root
 Component.libraries[0]
  Library(library import://uri1).parts[0]
   LibraryPart.partUri
Values file://uri3/ and file://uri2/ are not equivalent
.root
 Component.libraries[0]
  Library(library import://uri1).parts[1]
   LibraryPart.partUri
''', unorderedParts: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    l
      ..addTypedef(new Typedef(
          first ? 'Typedef1' : 'Typedef2', const DynamicType(),
          fileUri: fileUri1))
      ..addTypedef(new Typedef(
          first ? 'Typedef2' : 'Typedef1', const DynamicType(),
          fileUri: fileUri1));
    return c;
  }, inequivalence: '''
Inequivalent nodes
1: Typedef(Typedef1)
2: Typedef(Typedef2)
.root
 Component.libraries[0]
  Library(library import://uri1).typedefs[0]
''', unorderedTypedefs: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    l
      ..addClass(
          new Class(name: first ? 'Class1' : 'Class2', fileUri: fileUri1))
      ..addClass(
          new Class(name: first ? 'Class2' : 'Class1', fileUri: fileUri1));
    return c;
  }, inequivalence: '''
Inequivalent nodes
1: Class(Class1)
2: Class(Class2)
.root
 Component.libraries[0]
  Library(library import://uri1).classes[0]
''', unorderedClasses: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    Field f1 = new Field.immutable(new Name('field1'), fileUri: fileUri1);
    Field f2 = new Field.immutable(new Name('field2'), fileUri: fileUri1);
    l.addField(first ? f1 : f2);
    l.addField(first ? f2 : f1);
    Class cls = new Class(name: first ? 'Class' : 'Class', fileUri: fileUri1);
    l.addClass(cls);
    Field f3 = new Field.immutable(new Name('field3'), fileUri: fileUri1);
    Field f4 = new Field.immutable(new Name('field4'), fileUri: fileUri1);
    cls.addField(first ? f3 : f4);
    cls.addField(first ? f4 : f3);
    return c;
  }, inequivalence: '''
Inequivalent nodes
1: Class.field3
2: Class.field4
.root
 Component.libraries[0]
  Library(library import://uri1).classes[0]
   Class(Class).fields[0]
Inequivalent nodes
1: field1
2: field2
.root
 Component.libraries[0]
  Library(library import://uri1).fields[0]
''', unorderedFields: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    Procedure p1 = new Procedure(
        new Name('procedure1'), ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri1);
    Procedure p2 = new Procedure(
        new Name('procedure2'), ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri1);
    l.addProcedure(first ? p1 : p2);
    l.addProcedure(first ? p2 : p1);
    Class cls = new Class(name: first ? 'Class' : 'Class', fileUri: fileUri1);
    l.addClass(cls);
    Procedure p3 = new Procedure(
        new Name('procedure3'), ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri1);
    Procedure p4 = new Procedure(
        new Name('procedure4'), ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri1);
    cls.addProcedure(first ? p3 : p4);
    cls.addProcedure(first ? p4 : p3);
    return c;
  }, inequivalence: '''
Inequivalent nodes
1: Class.procedure3
2: Class.procedure4
.root
 Component.libraries[0]
  Library(library import://uri1).classes[0]
   Class(Class).procedures[0]
Inequivalent nodes
1: procedure1
2: procedure2
.root
 Component.libraries[0]
  Library(library import://uri1).procedures[0]
''', unorderedProcedures: true),
  new Test((bool first) {
    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    Class cls = new Class(name: first ? 'Class' : 'Class', fileUri: fileUri1);
    l.addClass(cls);
    Constructor c1 = new Constructor(new FunctionNode(null),
        name: new Name('constructor1'), fileUri: fileUri1);
    Constructor c2 = new Constructor(new FunctionNode(null),
        name: new Name('constructor2'), fileUri: fileUri1);
    cls.addConstructor(first ? c1 : c2);
    cls.addConstructor(first ? c2 : c1);
    return c;
  }, inequivalence: '''
Inequivalent nodes
1: Class.constructor1
2: Class.constructor2
.root
 Component.libraries[0]
  Library(library import://uri1).classes[0]
   Class(Class).constructors[0]
''', unorderedConstructors: true),
  new Test((bool first) {
    Expression createAnnotation1() =>
        first ? new IntLiteral(0) : new StringLiteral("foo");
    Expression createAnnotation2() =>
        first ? new StringLiteral("foo") : new IntLiteral(0);

    Component c = new Component();
    Library l = new Library(importUri1, fileUri: fileUri1);
    c.libraries.add(l);
    l
      ..addAnnotation(createAnnotation1())
      ..addAnnotation(createAnnotation2());
    Class cls = new Class(name: first ? 'Class' : 'Class', fileUri: fileUri1);
    l.addClass(cls);
    cls
      ..addAnnotation(createAnnotation1())
      ..addAnnotation(createAnnotation2());
    Procedure p = new Procedure(
        new Name('procedure'), ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri1);
    l.addProcedure(p);
    p
      ..addAnnotation(createAnnotation1())
      ..addAnnotation(createAnnotation2());
    return c;
  }, inequivalence: '''
Inequivalent nodes
1: IntLiteral(0)
2: StringLiteral("foo")
.root
 Component.libraries[0]
  Library(library import://uri1).annotations[0]
Inequivalent nodes
1: IntLiteral(0)
2: StringLiteral("foo")
.root
 Component.libraries[0]
  Library(library import://uri1).classes[0]
   Class(Class).annotations[0]
Inequivalent nodes
1: IntLiteral(0)
2: StringLiteral("foo")
.root
 Component.libraries[0]
  Library(library import://uri1).procedures[0]
   Procedure(procedure).annotations[0]
''', unorderedAnnotations: true),
];

class Test {
  final Node a;
  final Node b;
  final String? inequivalence;
  final bool? unorderedLibraries;
  final bool? unorderedLibraryDependencies;
  final bool? unorderedAdditionalExports;
  final bool? unorderedParts;
  final bool? unorderedTypedefs;
  final bool? unorderedClasses;
  final bool? unorderedFields;
  final bool? unorderedProcedures;
  final bool? unorderedConstructors;
  final bool? unorderedAnnotations;

  Test(
    Node Function(bool) create, {
    this.inequivalence,
    this.unorderedLibraries,
    this.unorderedLibraryDependencies,
    this.unorderedAdditionalExports,
    this.unorderedParts,
    this.unorderedTypedefs,
    this.unorderedClasses,
    this.unorderedFields,
    this.unorderedProcedures,
    this.unorderedConstructors,
    this.unorderedAnnotations,
  })  : a = create(true),
        b = create(false);

  bool get isEquivalent => inequivalence == null;

  String get options {
    List<String> list = [];
    if (unorderedLibraries != null) {
      list.add('unorderedLibraries=$unorderedLibraries');
    }
    if (unorderedLibraryDependencies != null) {
      list.add('unorderedLibraryDependencies=$unorderedLibraryDependencies');
    }
    if (unorderedAdditionalExports != null) {
      list.add('unorderedAdditionalExports=$unorderedAdditionalExports');
    }
    if (unorderedParts != null) {
      list.add('unorderedParts=$unorderedParts');
    }
    if (unorderedTypedefs != null) {
      list.add('unorderedTypedefs=$unorderedTypedefs');
    }
    if (unorderedClasses != null) {
      list.add('unorderedClasses=$unorderedClasses');
    }
    if (unorderedFields != null) {
      list.add('unorderedFields=$unorderedFields');
    }
    if (unorderedProcedures != null) {
      list.add('unorderedProcedures=$unorderedProcedures');
    }
    if (unorderedConstructors != null) {
      list.add('unorderedConstructors=$unorderedConstructors');
    }
    if (unorderedAnnotations != null) {
      list.add('unorderedAnnotations=$unorderedAnnotations');
    }
    return list.join(',');
  }
}

void main() {
  for (Test test in tests) {
    EquivalenceResult result = checkNodeEquivalence(test.a, test.b);
    if (test.isEquivalent) {
      Expect.equals(result.isEquivalent, test.isEquivalent,
          'Unexpected result for\n${test.a}\n${test.b}:\n$result');
      Expect.equals(
          '', test.options, 'Unexpected options for\n${test.a}\n${test.b}.');
    } else if (result.isEquivalent) {
      Expect.equals(
          result.isEquivalent,
          test.isEquivalent,
          'Unexpected equivalence for\n${test.a}\n${test.b}:\n'
          'Expected ${test.inequivalence}');
    } else {
      Expect.stringEquals(
          result.toString(),
          test.inequivalence!,
          'Unexpected inequivalence result for\n${test.a}\n${test.b}:\n'
          'Expected:\n---\n${test.inequivalence}\n---\n'
          'Actual:\n---\n${result}\n---');

      EquivalenceResult optionResult = checkNodeEquivalence(
        test.a,
        test.b,
        unorderedLibraries: test.unorderedLibraries ?? false,
        unorderedLibraryDependencies:
            test.unorderedLibraryDependencies ?? false,
        unorderedAdditionalExports: test.unorderedAdditionalExports ?? false,
        unorderedParts: test.unorderedParts ?? false,
        unorderedTypedefs: test.unorderedTypedefs ?? false,
        unorderedClasses: test.unorderedClasses ?? false,
        unorderedFields: test.unorderedFields ?? false,
        unorderedProcedures: test.unorderedProcedures ?? false,
        unorderedConstructors: test.unorderedConstructors ?? false,
        unorderedAnnotations: test.unorderedAnnotations ?? false,
      );
      Expect.isTrue(
          optionResult.isEquivalent,
          'Unexpected result for\n${test.a}\n${test.b} with ${test.options}:\n'
          '$optionResult');
    }
  }
}
