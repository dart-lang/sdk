// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// Access hidden identity hash code field
external int _getHash(Object obj);
external void _setHash(Object obj, int hash);

external _Type _getInterfaceTypeRuntimeType(
    Object object, List<Type> typeArguments);

@patch
class Object {
  @patch
  external bool operator ==(Object other);

  // Random number generator used to generate identity hash codes.
  static final _hashCodeRnd = new Random();

  static int _objectHashCode(Object obj) {
    var result = _getHash(obj);
    if (result == 0) {
      // We want the hash to be a Smi value greater than 0.
      do {
        result = _hashCodeRnd.nextInt(0x40000000);
      } while (result == 0);

      _setHash(obj, result);
      return result;
    }
    return result;
  }

  @patch
  int get hashCode => _objectHashCode(this);
  int get _identityHashCode => _objectHashCode(this);

  /// Concrete subclasses of [Object] will have overrides of [_typeArguments]
  /// which return their type arguments.
  List<Type> get _typeArguments => const [];

  /// We use [_runtimeType] for internal type testing, because objects can
  /// override [runtimeType].
  @patch
  external Type get runtimeType;
  _Type get _runtimeType => _getInterfaceTypeRuntimeType(this, _typeArguments);

  @patch
  String toString() => _toString(this);
  // A statically dispatched version of Object.toString.
  static String _toString(obj) => "Instance of '${obj.runtimeType}'";

  @patch
  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError.withInvocation(this, invocation);
  }
}
