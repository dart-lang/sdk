// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'elements/entities.dart';

/// A type variable as a local variable.
class TypeVariableLocal implements Local {
  final TypeVariableEntity typeVariable;

  TypeVariableLocal(this.typeVariable);

  @override
  String? get name => typeVariable.name;

  @override
  int get hashCode => typeVariable.hashCode;

  @override
  bool operator ==(other) {
    if (other is! TypeVariableLocal) return false;
    return typeVariable == other.typeVariable;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('type_variable_local(');
    sb.write(typeVariable);
    sb.write(')');
    return sb.toString();
  }
}

/// A local variable used encode the direct (uncaptured) references to [this].
class ThisLocal extends Local {
  final ClassEntity enclosingClass;

  ThisLocal(this.enclosingClass);

  @override
  String get name => 'this';

  @override
  bool operator ==(other) {
    return other is ThisLocal && other.enclosingClass == enclosingClass;
  }

  @override
  int get hashCode => enclosingClass.hashCode;
}

/// A local variable that contains the box object holding the [BoxFieldElement]
/// fields.
class BoxLocal extends Local {
  final ClassEntity container;

  BoxLocal(this.container);

  @override
  String get name => container.name;

  @override
  bool operator ==(other) {
    return other is BoxLocal && other.container == container;
  }

  @override
  int get hashCode => container.hashCode;

  @override
  String toString() => 'BoxLocal($name)';
}

///
/// Move the below classes to a JS model eventually.
///
abstract class JSEntity implements MemberEntity {
  String get declaredName;
}

abstract class PrivatelyNamedJSEntity implements JSEntity {
  Entity get rootOfScope;
}
