// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declares classes which describe a call: selectors and arguments.
library vm.transformations.type_flow.calls;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';

import 'types.dart';
import 'utils.dart';

enum CallKind {
  Method, // x.foo(..) or foo()
  PropertyGet, // ... x.foo ...
  PropertySet, // x.foo = ...
  FieldInitializer, // run initializer of a field
  SetFieldInConstructor, // foo = ... in initializer list in a constructor
}

/// [Selector] encapsulates the way of calling (at the call site).
abstract class Selector {
  /// Call kind: how call is performed?
  final CallKind callKind;

  Selector(this.callKind);

  /// Interface or concrete target, may be null.
  Member get member;

  /// Selector name.
  Name get name => member.name;

  bool get isSetter => (callKind == CallKind.PropertySet);

  @override
  int get hashCode => callKind.hashCode;

  @override
  bool operator ==(other) =>
      identical(this, other) || other is Selector && other.callKind == callKind;

  /// Static approximation of Dart return type.
  DartType get staticReturnType {
    if (member == null) {
      return const DynamicType();
    }
    switch (callKind) {
      case CallKind.Method:
        return (member is Procedure)
            ? member.function.returnType
            : const BottomType();
      case CallKind.PropertyGet:
        return member.getterType;
      case CallKind.PropertySet:
      case CallKind.FieldInitializer:
      case CallKind.SetFieldInConstructor:
        return const BottomType();
    }
    return null;
  }

  bool memberAgreesToCallKind(Member member) {
    switch (callKind) {
      case CallKind.Method:
        return ((member is Procedure) &&
                !member.isGetter &&
                !member.isSetter) ||
            (member is Constructor);
      case CallKind.PropertyGet:
        return (member is Field) || ((member is Procedure) && member.isGetter);
      case CallKind.PropertySet:
        return (member is Field) || ((member is Procedure) && member.isSetter);
      case CallKind.FieldInitializer:
      case CallKind.SetFieldInConstructor:
        return member is Field;
    }
    return false;
  }

  String get _callKindPrefix {
    switch (callKind) {
      case CallKind.Method:
        return '';
      case CallKind.PropertyGet:
        return 'get ';
      case CallKind.PropertySet:
      case CallKind.SetFieldInConstructor:
        return 'set ';
      case CallKind.FieldInitializer:
        return 'init ';
    }
    return '';
  }
}

/// Direct call to [member].
class DirectSelector extends Selector {
  final Member member;

  DirectSelector(this.member, {CallKind callKind = CallKind.Method})
      : super(callKind) {
    assert((callKind == CallKind.Method) ||
        (callKind == CallKind.PropertyGet) ||
        memberAgreesToCallKind(member));
  }

  @override
  int get hashCode => (super.hashCode ^ member.hashCode) & kHashMask;

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      other is DirectSelector && super == (other) && other.member == member;

  @override
  String toString() => 'direct ${_callKindPrefix}'
      '[${nodeToText(member)}]';
}

/// Interface call via known interface target [member].
class InterfaceSelector extends Selector {
  final Member member;

  InterfaceSelector(this.member, {CallKind callKind = CallKind.Method})
      : super(callKind);

  @override
  int get hashCode => (super.hashCode ^ member.hashCode + 31) & kHashMask;

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      other is InterfaceSelector && super == (other) && other.member == member;

  @override
  String toString() => '${_callKindPrefix}'
      '[${nodeToText(member)}]';
}

/// Virtual call (using 'this' as a receiver).
class VirtualSelector extends InterfaceSelector {
  VirtualSelector(Member member, {CallKind callKind = CallKind.Method})
      : super(member, callKind: callKind);

  @override
  int get hashCode => (super.hashCode + 37) & kHashMask;

  @override
  bool operator ==(other) =>
      identical(this, other) || other is VirtualSelector && super == (other);

  @override
  String toString() => 'virtual ${_callKindPrefix}'
      '[${nodeToText(member)}]';
}

/// Dynamic call.
class DynamicSelector extends Selector {
  @override
  final Name name;

  static final kCall = new DynamicSelector(CallKind.Method, new Name('call'));

  DynamicSelector(CallKind callKind, this.name) : super(callKind);

  @override
  Member get member => null;

  @override
  int get hashCode => (super.hashCode ^ name.hashCode + 37) & kHashMask;

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      other is DynamicSelector && super == (other) && other.name == name;

  @override
  String toString() => 'dynamic ${_callKindPrefix}[${nodeToText(name)}]';
}

/// Arguments passed to a call, including implicit receiver argument.
// TODO(alexmarkov): take type arguments into account
class Args<T extends TypeExpr> {
  final List<T> values;
  final List<String> names;

  int _hashCode;

  Args(this.values, {this.names = const <String>[]}) {
    assert(isSorted(names));
  }

  Args.withReceiver(Args<T> args, T receiver)
      : values = new List.from(args.values),
        names = args.names {
    values[0] = receiver;
  }

  int get positionalCount => values.length - names.length;
  int get namedCount => names.length;

  T get receiver => values[0];

  @override
  int get hashCode => _hashCode ??= _computeHashCode();

  int _computeHashCode() {
    int hash = 1231;
    for (var v in values) {
      hash = (((hash * 31) & kHashMask) + v.hashCode) & kHashMask;
    }
    for (var n in names) {
      hash = (((hash * 31) & kHashMask) + n.hashCode) & kHashMask;
    }
    return hash;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is Args<T> &&
        (this.values.length == other.values.length) &&
        (this.names.length == other.names.length)) {
      for (int i = 0; i < values.length; i++) {
        if (values[i] != other.values[i]) {
          return false;
        }
      }
      for (int i = 0; i < names.length; i++) {
        if (names[i] != other.names[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buf = new StringBuffer();
    buf.write("(");
    for (int i = 0; i < positionalCount; i++) {
      if (i != 0) {
        buf.write(", ");
      }
      buf.write(values[i]);
    }
    for (int i = 0; i < names.length; i++) {
      if (positionalCount + i != 0) {
        buf.write(", ");
      }
      buf.write(names[i]);
      buf.write(': ');
      buf.write(values[positionalCount + i]);
    }
    buf.write(")");
    return buf.toString();
  }
}
