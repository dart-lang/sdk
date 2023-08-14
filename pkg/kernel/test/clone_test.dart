// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/src/coverage.dart';
import 'package:kernel/src/equivalence.dart';
import 'package:kernel/src/node_creator.dart';

void main() {
  testBodyCloning();
  testBodyCloningInContext();
  testMemberCloning();
}

void testBodyCloning() {
  // TODO(johnniwinther): Add a test for cloning in context.
  NodeCreator creator =
      new NodeCreator(initializers: [], members: [], nodes: inBodyNodeKinds);
  List<TreeNode> nodes = creator.generateBodies();

  CoverageVisitor coverageVisitor = new CoverageVisitor();
  for (TreeNode node in nodes) {
    node.accept(coverageVisitor);
    CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
    TreeNode clone = cloner.clone(node);
    EquivalenceResult result = checkEquivalence(node, clone,
        strategy: const NoFileOffsetEquivalenceStrategy());
    if (!result.isEquivalent) {
      print(result);
    }
    Expect.isTrue(result.isEquivalent, "$node");
  }
  Expect.isEmpty(
      creator.createdKinds.toSet()..removeAll(coverageVisitor.visited),
      'Nodes not covered in testing.');
}

void testBodyCloningInContext() {
  NodeCreator creator =
      new NodeCreator(initializers: [], members: [], nodes: inBodyNodeKinds);
  List<Statement> nodes = creator.generateBodies();

  CoverageVisitor coverageVisitor = new CoverageVisitor();
  for (Statement node in nodes) {
    node.accept(coverageVisitor);
    CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
    // Set up context for [statement].
    new Procedure(Name('foo'), ProcedureKind.Method, FunctionNode(node),
        fileUri: dummyUri);
    TreeNode clone = cloner.cloneInContext(node);
    EquivalenceResult result = checkEquivalence(node, clone);
    if (!result.isEquivalent) {
      print(result);
    }
    Expect.isTrue(result.isEquivalent, "$node");
  }
  Expect.isEmpty(
      creator.createdKinds.toSet()..removeAll(coverageVisitor.visited),
      'Nodes not covered in testing.');
}

void testMemberCloning() {
  NodeCreator creator = new NodeCreator(nodes: inBodyNodeKinds);
  Component component = creator.generateComponent();

  CoverageVisitor coverageVisitor = new CoverageVisitor();

  void testMembers<M extends Member>(
      Iterable<M> members,
      M Function(CloneVisitorWithMembers, M) cloneFunction,
      String Function(M) toStringFunction) {
    for (M member in members) {
      member.accept(coverageVisitor);
      CloneVisitorWithMembers cloner = new CloneVisitorWithMembers();
      M clone = cloneFunction(cloner, member);
      EquivalenceResult result = checkEquivalence(member, clone,
          strategy: const MemberEquivalenceStrategy());
      if (!result.isEquivalent) {
        print(result);
      }
      Expect.isTrue(result.isEquivalent, toStringFunction(member));
    }
  }

  void testProcedures(Iterable<Procedure> procedures) {
    testMembers<Procedure>(
        procedures,
        (cloner, procedure) => cloner.cloneProcedure(procedure, null),
        (procedure) => "${procedure.runtimeType}(${procedure.name}):"
            "${procedure.function.body}");
  }

  void testFields(Iterable<Field> fields) {
    testMembers<Field>(
        fields,
        (cloner, field) => cloner.cloneField(field, null, null, null),
        (field) => "${field.runtimeType}(${field.name}):"
            "${field.initializer}");
  }

  void testConstructors(Iterable<Constructor> constructors) {
    testMembers<Constructor>(
        constructors,
        (cloner, constructor) => cloner.cloneConstructor(constructor, null),
        (constructor) => "${constructor.runtimeType}(${constructor.name}):"
            "${constructor.initializers}:"
            "${constructor.function.body}");
  }

  for (Library library in component.libraries) {
    testProcedures(library.procedures);
    testFields(library.fields);
    for (Class cls in library.classes) {
      testProcedures(cls.procedures);
      testFields(cls.fields);
      testConstructors(cls.constructors);
    }
  }
  Expect.isEmpty(
      creator.createdKinds.toSet()..removeAll(coverageVisitor.visited),
      'Nodes not covered in testing.');
}

class NoFileOffsetEquivalenceStrategy extends EquivalenceStrategy {
  const NoFileOffsetEquivalenceStrategy();

  @override
  bool checkTreeNode_fileOffset(
      EquivalenceVisitor visitor, TreeNode node, TreeNode other) {
    if (other.fileOffset == TreeNode.noOffset) return true;
    return super.checkTreeNode_fileOffset(visitor, node, other);
  }
}

class MemberEquivalenceStrategy extends EquivalenceStrategy {
  const MemberEquivalenceStrategy();

  void assumeClonedReferences(EquivalenceVisitor visitor, Member member1,
      Reference? reference1, Member member2, Reference? reference2) {
    if (reference1 != null && reference2 != null) {
      ReferenceName referenceName1 = ReferenceName.fromNamedNode(member1);
      ReferenceName referenceName2 = ReferenceName.fromNamedNode(member2);
      if (referenceName1.kind == referenceName2.kind &&
              referenceName1.memberName == referenceName2.memberName &&
              referenceName1.memberUri == referenceName2.memberUri &&
              referenceName2.declarationName == null ||
          referenceName2.libraryUri == null) {
        visitor.assumeReferences(reference1, reference2);
      }
    }
  }

  @override
  bool checkProcedure(
      EquivalenceVisitor visitor, Procedure? node, Object? other) {
    if (node is Procedure && other is Procedure) {
      assumeClonedReferences(
          visitor, node, node.reference, other, other.reference);
    }
    return super.checkProcedure(visitor, node, other);
  }

  @override
  bool checkConstructor(
      EquivalenceVisitor visitor, Constructor? node, Object? other) {
    if (node is Constructor && other is Constructor) {
      assumeClonedReferences(
          visitor, node, node.reference, other, other.reference);
    }
    return super.checkConstructor(visitor, node, other);
  }

  @override
  bool checkField(EquivalenceVisitor visitor, Field? node, Object? other) {
    if (node is Field && other is Field) {
      assumeClonedReferences(
          visitor, node, node.fieldReference, other, other.fieldReference);
      assumeClonedReferences(
          visitor, node, node.getterReference, other, other.getterReference);
      assumeClonedReferences(
          visitor, node, node.setterReference, other, other.setterReference);
    }
    return super.checkField(visitor, node, other);
  }
}
