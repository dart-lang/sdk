// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements.jumps;

import 'entities.dart';

/// The label entity defined by a labeled statement.
abstract class LabelDefinition extends Entity {
  String get labelName;
  JumpTarget get target;

  bool get isTarget => isBreakTarget || isContinueTarget;

  bool get isBreakTarget;
  bool get isContinueTarget;
}

/// A jump target is the reference point of a statement or switch-case,
/// either by label or as the default target of a break or continue.
abstract class JumpTarget extends Local {
  @override
  String get name => 'target';

  bool get isTarget => isBreakTarget || isContinueTarget;

  int get nestingLevel;
  List<LabelDefinition> get labels;

  bool get isBreakTarget;
  bool get isContinueTarget;
  bool get isSwitch;
  bool get isSwitchCase;

  LabelDefinition addLabel(String labelName,
      {bool isBreakTarget: false, bool isContinueTarget: false});
}
