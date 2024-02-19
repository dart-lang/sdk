// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';

void main(List<String> args) {
  for (String arg in args) {
    File f = new File(arg);
    if (!f.existsSync()) {
      print("Skipping '$arg', not a file.");
      continue;
    }
    Component c;
    try {
      c = loadComponentFromBytes(f.readAsBytesSync());
    } catch (e) {
      print("Skipping '$arg', couldn't load as kernel: '$e'");
      continue;
    }
    try {
      List<Warning> warnings = UnreachableIfFinder.find(c);
      if (warnings.isEmpty) {
        print("No warnings found for '$arg'");
      } else {
        for (Warning warning in warnings) {
          print(warning);
          print("");
        }
      }
    } catch (e, st) {
      print("Failure '$e' on '$arg':");
      print(st);
    }
  }
}

class UnreachableIfFinder extends RecursiveVisitor {
  static List<Warning> find(Component c) {
    EffectivelyFinal effectivelyFinal = new EffectivelyFinal._();
    c.accept(effectivelyFinal);
    UnreachableIfFinder unreachableIfFinder =
        new UnreachableIfFinder._(effectivelyFinal.unwritten);
    c.accept(unreachableIfFinder);
    return unreachableIfFinder.warnings;
  }

  final Set<VariableDeclaration> unwritten;

  UnreachableIfFinder._(this.unwritten);

  List<Warning> warnings = [];

  Map<VariableDeclaration, bool> knownValues = {};

  @override
  void visitIfStatement(IfStatement node) {
    helperForIfLikeStructure(node.condition, node.then, node.otherwise, node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    helperForIfLikeStructure(node.condition, node.then, node.otherwise, node);
  }

  void helperForIfLikeStructure(
    Expression condition,
    TreeNode then,
    TreeNode? otherwise,
    TreeNode originNode,
  ) {
    // TODO(jensj): We could make the visit return a bool? instead and use that
    // from the condition instead of doing special casing on `Not` and
    // `VariableGet`.
    VariableDeclaration? newKnownValueHere;
    bool conditionNegated = false;

    if (condition is Not) {
      condition = condition.operand;
      conditionNegated = true;
    }

    if (condition is VariableGet) {
      bool? knownValue = knownValues[condition.variable];
      if (knownValue != null) {
        if (conditionNegated) knownValue = !knownValue;
        String? hint;

        if (knownValue && otherwise != null) {
          hint = "The else branch will never execute.";
        } else if (!knownValue) {
          hint = "The then branch will never execute.";
        }
        warnings.add(new Warning(
            originNode.location, "Condition is always $knownValue", hint));
      } else {
        if (condition.variable.isFinal ||
            unwritten.contains(condition.variable)) {
          newKnownValueHere = condition.variable;
        }
      }
    }
    if (newKnownValueHere != null) {
      knownValues[newKnownValueHere] = conditionNegated ? false : true;
    }
    then.accept(this);
    if (newKnownValueHere != null) {
      knownValues[newKnownValueHere] = conditionNegated ? true : false;
    }
    otherwise?.accept(this);
    if (newKnownValueHere != null) {
      knownValues.remove(newKnownValueHere);
    }
  }
}

class EffectivelyFinal extends RecursiveVisitor {
  final Set<VariableDeclaration> unwritten = {};

  EffectivelyFinal._();

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    unwritten.add(node);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    unwritten.remove(node.variable);
    super.visitVariableSet(node);
  }
}

class Warning {
  final Location? location;
  final String message;
  final String? hint;

  Warning(this.location, this.message, this.hint);

  @override
  String toString() {
    return "Warning: $message @ $location.${hint != null ? "\n$hint." : ""}";
  }
}
