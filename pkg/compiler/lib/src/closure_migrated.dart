// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'elements/entities.dart';

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
