// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements.jumps;

import 'entities.dart';

/// The label entity defined by a labeled statement.
abstract class LabelDefinition<T> extends Entity {
  T get label;
  String get labelName;
  JumpTarget<T> get target;

  bool get isTarget;
  bool get isBreakTarget;
  bool get isContinueTarget;

  void setBreakTarget();
  void setContinueTarget();
}

/// A jump target is the reference point of a statement or switch-case,
/// either by label or as the default target of a break or continue.
abstract class JumpTarget<T> extends Local {
  T get statement;
  int get nestingLevel;
  List<LabelDefinition<T>> get labels;

  bool get isTarget;
  bool get isBreakTarget;
  bool get isContinueTarget;
  bool get isSwitch;

  // TODO(kasperl): Try to get rid of these.
  void set isBreakTarget(bool value);
  void set isContinueTarget(bool value);

  LabelDefinition<T> addLabel(T label, String labelName);
}
