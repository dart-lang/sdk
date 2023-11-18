// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

/// The target of a `call` instruction in the IR.
sealed class CallDescriptor {
  String get name;
}

/// Call descriptor for an instance (non-static) getter.
class InstanceGetDescriptor extends CallDescriptor {
  final PropertyAccessorElement getter;

  InstanceGetDescriptor(this.getter) : assert(getter.isGetter);

  @override
  int get hashCode => getter.hashCode;

  @override
  String get name => getter.name;

  @override
  bool operator ==(Object other) =>
      other is InstanceGetDescriptor && getter == other.getter;

  @override
  String toString() => '${getter.enclosingElement.name}.$name';
}

/// Call descriptor for an instance (non-static) setter.
class InstanceSetDescriptor extends CallDescriptor {
  final PropertyAccessorElement setter;

  InstanceSetDescriptor(this.setter) : assert(setter.isSetter);

  @override
  int get hashCode => setter.hashCode;

  @override
  String get name => setter.name;

  @override
  bool operator ==(Object other) =>
      other is InstanceSetDescriptor && setter == other.setter;

  @override
  String toString() => '${setter.enclosingElement.name}.$name';
}
