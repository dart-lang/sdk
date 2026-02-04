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
    if (member is Field) {
      if (member.setterReference == this) return true;
      if (member.isInstanceMember) {
        return _isUncheckedEntrySetterReference ||
            _isCheckedEntrySetterReference;
      }
    }
    return false;
  }

  bool get isFieldInitializer {
    Member member = asMember;
    if (member is Field) {
      if (member.fieldReference == this) return true;
    }
    return false;
  }

  bool get isGetter {
    Member member = asMember;
    return (member is Procedure && member.isGetter) || isImplicitGetter;
  }

  bool get isSetter {
    Member member = asMember;
    return (member is Procedure && member.isSetter) || isImplicitSetter;
  }
}

// Extend procedures with a tearOffReference that refers to the tear-off
// implementation for that procedure. This enables a Reference to refer to any
// implementation relating to a member, including its tear-off, which it can't
// do in plain kernel.

// Use Expandos to avoid keeping the procedure alive.
final Expando<Reference> _tearOffReference = Expando();
final Expando<Reference> _typeCheckerReference = Expando();
final Expando<Reference> _checkedEntryReferences = Expando();
final Expando<Reference> _uncheckedEntryReferences = Expando();
final Expando<Reference> _bodyReferences = Expando();
final Expando<Reference> _initializerReference = Expando();
final Expando<Reference> _constructorBodyReference = Expando();

extension CustomReference on Member {
  Reference get tearOffReference =>
      _tearOffReference[this] ??= Reference()..node = this;

  Reference get typeCheckerReference =>
      _typeCheckerReference[this] ??= Reference()..node = this;

  Reference get checkedEntryReference {
    assert(_memberCanHaveMultipleEntryPoints(this));
    return _checkedEntryReferences[this] ??= Reference()..node = this;
  }

  Reference get uncheckedEntryReference {
    assert(_memberCanHaveMultipleEntryPoints(this));
    return _uncheckedEntryReferences[this] ??= Reference()..node = this;
  }

  Reference get bodyReference {
    assert(_memberCanHaveMultipleEntryPoints(this));
    return _bodyReferences[this] ??= Reference()..node = this;
  }

  Reference get initializerReference =>
      _initializerReference[this] ??= Reference()..node = this;

  Reference get constructorBodyReference =>
      _constructorBodyReference[this] ??= Reference()..node = this;
}

extension IsCustomReference on Reference {
  bool get isTearOffReference => _tearOffReference[asMember] == this;

  bool get isTypeCheckerReference => _typeCheckerReference[asMember] == this;

  bool get isCheckedEntryReference => _checkedEntryReferences[asMember] == this;

  bool get _isCheckedEntrySetterReference =>
      (asMember is Field) && isCheckedEntryReference;

  bool get isUncheckedEntryReference =>
      _uncheckedEntryReferences[asMember] == this;

  bool get _isUncheckedEntrySetterReference =>
      (asMember is Field) && isUncheckedEntryReference;

  bool get isBodyReference => _bodyReferences[asMember] == this;

  bool get isInitializerReference => _initializerReference[asMember] == this;

  bool get isConstructorBodyReference =>
      _constructorBodyReference[asMember] == this;

  EntryPoint get entryKind {
    if (isUncheckedEntryReference) {
      return EntryPoint.unchecked;
    }
    if (isCheckedEntryReference) {
      return EntryPoint.checked;
    }
    if (isBodyReference) {
      return EntryPoint.body;
    }
    return EntryPoint.normal;
  }
}

extension ReferenceAs on Member {
  Reference referenceAs({required bool getter, required bool setter}) {
    assert(!getter || !setter); // members cannot be both setter and getter
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

// Sanity check that [member] may have multiple entry points.
bool _memberCanHaveMultipleEntryPoints(Member member) {
  if (member is Field && member.hasSetter ||
      member is Procedure && member.isSetter) {
    // The unchecked entry will bypass type checks on the setter values.
    return true;
  }
  if (member is Procedure &&
      const [ProcedureKind.Method, ProcedureKind.Operator]
          .contains(member.kind) &&
      (member.function.positionalParameters.isNotEmpty ||
          member.function.namedParameters.isNotEmpty ||
          member.function.typeParameters.isNotEmpty)) {
    // The unchecked entry will bypass type checks on the method.
    return true;
  }
  return false;
}

enum EntryPoint {
  // A single procedure doing type argument checks, optional argument handling
  // and the body.
  normal,
  // A entry function doing type argument checks, optional argument handling but
  // delegates to the actual [body] function.
  checked,
  // A entry function doing optional argument handling but
  // delegates to the actual [body] function.
  unchecked,
  // The body of a function excluding type checks and optional argument
  // handling.
  body,
}
