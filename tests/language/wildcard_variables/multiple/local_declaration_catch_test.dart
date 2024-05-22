// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests multiple catch clause wildcard variable declarations.

// SharedOptions=--enable-experiment=wildcard-variables

void main() {
  try {
    throw '!';
  } on Exception catch (_, _) {
    rethrow; // Should not hit this catch.
  } catch (_, _) {
    print('catch');
  }
}
