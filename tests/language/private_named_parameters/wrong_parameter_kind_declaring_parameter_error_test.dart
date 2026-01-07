// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// You can only use private named parameters on parameters that refer to
/// instance fields.

// SharedOptions=--enable-experiment=private-named-parameters,primary-constructors

// In a primary constructor, but not a declaring parameter or initializing
// formal.
class Primary({required String _notDeclaring});
//                             ^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified

// In a primary constructor, but not a declaring parameter or initializing
// formal.
class SuperParameter({required super._superParam}) extends SuperBase;
//                                   ^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified

class SuperBase {
  final String _superParam;
  SuperBase({required this._superParam});
}

void main() {}
