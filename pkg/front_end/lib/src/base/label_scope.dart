// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../kernel/body_builder.dart' show JumpTarget;

abstract class LabelScope {
  Map<String, JumpTarget>? get unclaimedForwardDeclarations;
  void declareLabel(String name, JumpTarget target);
  JumpTarget? lookupLabel(String name);
  bool hasLocalLabel(String name);
  bool claimLabel(String name);
  void forwardDeclareLabel(String name, JumpTarget target);
}

class LabelScopeImpl implements LabelScope {
  Map<String, JumpTarget>? _labels;
  LabelScope? _parent;

  Map<String, JumpTarget>? forwardDeclaredLabels;

  LabelScopeImpl([this._parent]);

  @override
  void declareLabel(String name, JumpTarget target) {
    (_labels ??= {})[name] = target;
  }

  @override
  JumpTarget? lookupLabel(String name) {
    return _labels?[name] ?? _parent?.lookupLabel(name);
  }

  @override
  bool hasLocalLabel(String name) =>
      _labels != null && _labels!.containsKey(name);

  @override
  bool claimLabel(String name) {
    if (forwardDeclaredLabels == null ||
        forwardDeclaredLabels!.remove(name) == null) {
      return false;
    }
    if (forwardDeclaredLabels!.length == 0) {
      forwardDeclaredLabels = null;
    }
    return true;
  }

  @override
  void forwardDeclareLabel(String name, JumpTarget target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, JumpTarget>{};
    forwardDeclaredLabels![name] = target;
  }

  @override
  Map<String, JumpTarget>? get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
  }
}
