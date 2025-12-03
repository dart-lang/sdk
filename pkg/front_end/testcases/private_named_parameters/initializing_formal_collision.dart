// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Colliding initializing formals.
class C1 {
  final String? _foo;
  C1({required this._foo, required this._foo}) {}
}

/// Collide with previous public initializing formal.
class C2 {
  final String? _foo;
  C2({required this._foo, String? _foo}) {}
}

/// Collide with later private named.
class C3 {
  final String? _foo;
  C3({required this._foo, String? foo}) {}
}

/// Collide with later public named.
class C4 {
  final String? _foo;
  C4({String? _foo, required this._foo}) {}
}

/// Collide with previous private named.
class C5 {
  final String? _foo;
  C5(String _foo, {required this._foo}) {}
}

/// Collide with previous public named.
class C6 {
  final String? foo;
  final String? _foo;
  C6({required this.foo, required this._foo}) {}
}

/// Collide with previous private positional.
class C7 {
  final String? _foo;
  C7({String? foo, required this._foo}) {}
}

/// Collide with previous public positional.
class C8 {
  final String? _foo;
  C8(String? foo, {required this._foo}) {}
}

/// More than two parameters.
class C9 {
  final String? _foo;
  C9(String? foo, {required this._foo, int? _foo, int? foo}) {}
}
