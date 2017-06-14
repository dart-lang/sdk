// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.label_scope;

import '../elements/jumps.dart';
import '../util/util.dart' show Link;

abstract class LabelScope {
  LabelScope get outer;
  LabelDefinition lookup(String label);
}

class LabeledStatementLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelDefinition> labels;
  LabeledStatementLabelScope(this.outer, this.labels);
  LabelDefinition lookup(String labelName) {
    LabelDefinition label = labels[labelName];
    if (label != null) return label;
    return outer.lookup(labelName);
  }
}

class SwitchLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelDefinition> caseLabels;

  SwitchLabelScope(this.outer, this.caseLabels);

  LabelDefinition lookup(String labelName) {
    LabelDefinition result = caseLabels[labelName];
    if (result != null) return result;
    return outer.lookup(labelName);
  }
}

class EmptyLabelScope implements LabelScope {
  const EmptyLabelScope();
  LabelDefinition lookup(String label) => null;
  LabelScope get outer {
    throw 'internal error: empty label scope has no outer';
  }
}

class StatementScope {
  LabelScope labels;
  Link<JumpTarget> breakTargetStack;
  Link<JumpTarget> continueTargetStack;
  // Used to provide different numbers to statements if one is inside the other.
  // Can be used to make otherwise duplicate labels unique.
  int nestingLevel = 0;

  StatementScope()
      : labels = const EmptyLabelScope(),
        breakTargetStack = const Link<JumpTarget>(),
        continueTargetStack = const Link<JumpTarget>();

  LabelDefinition lookupLabel(String label) {
    return labels.lookup(label);
  }

  JumpTarget currentBreakTarget() =>
      breakTargetStack.isEmpty ? null : breakTargetStack.head;

  JumpTarget currentContinueTarget() =>
      continueTargetStack.isEmpty ? null : continueTargetStack.head;

  void enterLabelScope(Map<String, LabelDefinition> elements) {
    labels = new LabeledStatementLabelScope(labels, elements);
    nestingLevel++;
  }

  void exitLabelScope() {
    nestingLevel--;
    labels = labels.outer;
  }

  void enterLoop(JumpTarget element) {
    breakTargetStack = breakTargetStack.prepend(element);
    continueTargetStack = continueTargetStack.prepend(element);
    nestingLevel++;
  }

  void exitLoop() {
    nestingLevel--;
    breakTargetStack = breakTargetStack.tail;
    continueTargetStack = continueTargetStack.tail;
  }

  void enterSwitch(
      JumpTarget breakElement, Map<String, LabelDefinition> continueElements) {
    breakTargetStack = breakTargetStack.prepend(breakElement);
    labels = new SwitchLabelScope(labels, continueElements);
    nestingLevel++;
  }

  void exitSwitch() {
    nestingLevel--;
    breakTargetStack = breakTargetStack.tail;
    labels = labels.outer;
  }
}
