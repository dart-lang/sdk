// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int? _;
  int? __extraPrivate;
  int? _123;
  int? _for;

  C.onlyUnderscore({this._}); // Error
  C.stillPrivate({this.__extraPrivate}); // Error
  C.notIdentifier({this._123}); // Error
  C.reservedWord({this._for}); // Error
}

main() {}
