// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

// Extend references with flags to more easily identify getters and setters.

extension GetterSetterReference on Reference {
  bool get isImplicitGetter {
    Member member = asMember;
    return member is Field && member.getterReference == this;
  }

  bool get isImplicitSetter {
    Member member = asMember;
    return member is Field && member.setterReference == this;
  }

  bool get isGetter {
    Member member = asMember;
    return member is Procedure && member.isGetter || isImplicitGetter;
  }

  bool get isSetter {
    Member member = asMember;
    return member is Procedure && member.isSetter || isImplicitSetter;
  }
}

// Extend procedures with a tearOffReference that refers to the tear-off
// implementation for that procedure. This enables a Reference to refer to any
// implementation relating to a member, including its tear-off, which it can't
// do in plain kernel.

extension TearOffReference on Procedure {
  // Use an Expando to avoid keeping the procedure alive.
  static final Expando<Reference> _tearOffReference = Expando();

  Reference get tearOffReference =>
      _tearOffReference[this] ??= Reference()..node = this;
}

extension IsTearOffReference on Reference {
  bool get isTearOffReference {
    Member member = asMember;
    return member is Procedure && member.tearOffReference == this;
  }
}

extension ReferenceAs on Member {
  Reference referenceAs({required bool getter, required bool setter}) {
    Member member = this;
    return member is Field
        ? setter
            ? member.setterReference!
            : member.getterReference
        : getter && member is Procedure && member.kind == ProcedureKind.Method
            ? member.tearOffReference
            : member.reference;
  }
}
