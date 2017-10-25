// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformation.reify.analysis.program_analysis;

import '../asts.dart';
import '../../../ast.dart';

// TODO(karlklose): keep all predicates and derived information here and move
// the actual data to a builder class.
class ProgramKnowledge {
  Map<Member, Set<TypeParameter>> _usedTypeVariables =
      <Member, Set<TypeParameter>>{};

  Map<Member, Set<DartType>> isTests = <Member, Set<DartType>>{};

  Set<Class> _classTests;

  /// Contains all classes that are used as the declaration of a type expression
  /// in a type test.
  Set<Class> get classTests {
    if (_classTests == null) {
      _classTests = isTests.values
          .expand((set) => set)
          .where((DartType type) => type is InterfaceType)
          .map((DartType type) => (type as InterfaceType).classNode)
          .toSet();
    }
    return _classTests;
  }

  recordTypeVariableUse(Expression expression, TypeParameter parameter) {
    // TODO(karlklose): also record expression.
    add(_usedTypeVariables, getEnclosingMember(expression), parameter);
  }

  Set<TypeParameter> usedParameters(Member member) {
    return _usedTypeVariables[member] ?? new Set<TypeParameter>();
  }

  void recordIsTest(IsExpression node, DartType type) {
    add(isTests, getEnclosingMember(node), type);
  }

  add(Map<dynamic, Set> map, key, value) {
    map.putIfAbsent(key, () => new Set()).add(value);
  }
}

typedef bool LibraryFilter(Library library);

class ProgramAnalysis extends Visitor {
  final ProgramKnowledge knowledge;
  final LibraryFilter analyzeLibrary;

  ProgramAnalysis(this.knowledge, this.analyzeLibrary);

  defaultTreeNode(TreeNode node) => node.visitChildren(this);

  visitLibrary(Library library) {
    if (!analyzeLibrary(library)) {
      return;
    }
    super.visitLibrary(library);
  }

  handleTypeReference(TreeNode node, DartType type) {
    typeVariables(type).forEach((TypeParameter parameter) {
      knowledge.recordTypeVariableUse(node, parameter);
    });
  }

  handleInstantiation(InvocationExpression node) {
    node.arguments.types.forEach((DartType type) {
      handleTypeReference(node, type);
    });
  }

  visitIsExpression(IsExpression node) {
    knowledge.recordIsTest(node, node.type);
    handleTypeReference(node, node.type);
    node.visitChildren(this);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    handleInstantiation(node);
    node.visitChildren(this);
  }

  visitStaticInvocation(StaticInvocation node) {
    if (node.target.kind == ProcedureKind.Factory) {
      handleInstantiation(node);
    }
    node.visitChildren(this);
  }
}

bool _analyzeAll(Library library) => true;

ProgramKnowledge analyze(Program program,
    {LibraryFilter analyzeLibrary: _analyzeAll}) {
  ProgramKnowledge knowledge = new ProgramKnowledge();
  program.accept(new ProgramAnalysis(knowledge, analyzeLibrary));
  return knowledge;
}
