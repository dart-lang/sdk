library tree_ir.integrity;

import 'tree_ir_nodes.dart';

/// Performs integrity checks on the tree_ir.
///
/// Should only be run for debugging purposes, not in production.
///
/// - Reference counts on must match the actual number of references.
/// - Labels must be in scope when referenced.
/// - Breaks must target a [LabeledStatement].
/// - Continues must target a [Loop].
/// - Variables must only be used after their first assignment
///   (checked on a best-effort basis).
/// - Variables with a declaration must only be referenced in scope.
/// - Variables must not have more than one declaration.
///
class CheckTreeIntegrity extends RecursiveVisitor {
  FunctionDefinition topLevelNode;

  Map<Variable, int> varReads = <Variable, int>{};
  Map<Variable, int> varWrites = <Variable, int>{};
  Map<Label, int> labelUses = <Label, int>{};
  Map<Label, JumpTarget> label2declaration = <Label, JumpTarget>{};

  /// Variables that are currently in scope.
  Set<Variable> scope = new Set<Variable>();

  /// Variables for which we have seen a declaration.
  Set<Variable> seenDeclaration = new Set<Variable>();

  void write(Variable variable) {
    if (!seenDeclaration.contains(variable)) {
      // Implicitly-declared variables are in scope after the first assignment.
      scope.add(variable);
    } else if (!scope.contains(variable)) {
      // There is a declaration for variable but it is no longer in scope.
      error('$variable assigned out of scope');
    }
    varWrites.putIfAbsent(variable, () => 0);
    varWrites[variable]++;
  }

  void read(Variable variable) {
    if (!scope.contains(variable)) {
      error('$variable used out of scope');
    }
    varReads.putIfAbsent(variable, () => 0);
    varReads[variable]++;
  }

  void declare(Variable variable) {
    if (!scope.add(variable) || !seenDeclaration.add(variable)) {
      error('Redeclared $variable');
    }
    varWrites.putIfAbsent(variable, () => 0);
    varWrites[variable]++;
  }

  void undeclare(Variable variable) {
    scope.remove(variable);
  }

  visitVariableUse(VariableUse node) {
    read(node.variable);
  }

  visitAssign(Assign node) {
    visitExpression(node.value);
    write(node.variable);
  }

  visitTry(Try node) {
    visitStatement(node.tryBody);
    node.catchParameters.forEach(declare);
    visitStatement(node.catchBody);
    node.catchParameters.forEach(undeclare);
  }

  visitJumpTargetBody(JumpTarget target) {
    Label label = target.label;
    if (label2declaration.containsKey(label)) {
      error('Duplicate declaration of label $label');
    }
    label2declaration[label] = target;
    labelUses[label] = 0;
    visitStatement(target.body);
    label2declaration.remove(label);

    if (labelUses[label] != label.useCount) {
      error('Label $label has ${labelUses[label]} uses '
            'but its reference count is ${label.useCount}');
    }
  }

  visitLabeledStatement(LabeledStatement node) {
    visitJumpTargetBody(node);
    visitStatement(node.next);
  }

  visitWhileTrue(WhileTrue node) {
    visitJumpTargetBody(node);
  }

  visitFor(For node) {
    visitExpression(node.condition);
    visitJumpTargetBody(node);
    node.updates.forEach(visitExpression);
    visitStatement(node.next);
  }

  visitBreak(Break node) {
    if (!label2declaration.containsKey(node.target)) {
      error('Break to label that is not in scope');
    }
    if (label2declaration[node.target] is! LabeledStatement) {
      error('Break to non-labeled statement ${label2declaration[node.target]}');
    }
    labelUses[node.target]++;
  }

  visitContinue(Continue node) {
    if (!label2declaration.containsKey(node.target)) {
      error('Continue to label that is not in scope');
    }
    if (label2declaration[node.target] is! Loop) {
      error('Continue to non-loop statement ${label2declaration[node.target]}');
    }
    labelUses[node.target]++;
  }

  visitInnerFunction(FunctionDefinition node) {
    checkBody(node);
  }

  void checkBody(FunctionDefinition node) {
    node.parameters.forEach(declare);
    visitStatement(node.body);
    node.parameters.forEach(undeclare);
  }

  dynamic error(String message) {
    throw 'Tree IR integrity violation in ${topLevelNode.element}:\n$message';
  }

  void check(FunctionDefinition node) {
    topLevelNode = node;
    checkBody(node);

    // Verify reference counters for all variables.
    List<Variable> seenVariables = new List<Variable>();
    seenVariables.addAll(varReads.keys);
    seenVariables.addAll(varWrites.keys);
    for (Variable variable in seenVariables) {
      int reads = varReads.putIfAbsent(variable, () => 0);
      int writes = varWrites.putIfAbsent(variable, () => 0);
      if (reads != variable.readCount || writes != variable.writeCount) {
        error('Invalid reference count for $variable:\n'
              '- Variable has $reads reads and $writes writes\n'
              '- Reference count is ${variable.readCount} reads and '
              '${variable.writeCount} writes');
      }
    }
  }

}
