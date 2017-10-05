// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing access to private fields.

part of PrivateLib;

class PrivateLib {
  final _myPrecious;

  const PrivateLib() : this._myPrecious = "The Ring";
}
