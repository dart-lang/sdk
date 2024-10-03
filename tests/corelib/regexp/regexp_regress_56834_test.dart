// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://dartbug.com/56834

void main() {
  final RegExp _codeDelimiter = RegExp(r'[_-]');

  'msgs-en'.lastIndexOf(_codeDelimiter);

  'EN'.split(_codeDelimiter); // Should not throw.
}
