// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustiveWildcard((int, String, {bool named}) r) => switch (r) {
      (_, _, named: _) => 0,
    };

exhaustiveTyped((int, String, {bool named}) r) => switch (r) {
      (int(), String(), named: bool()) => 0,
    };

exhaustiveValue((int, String, {bool named}) r) => switch (r) {
      (_, _, named: true) => 0,
      (_, _, named: false) => 1,
    };

nonExhaustiveRestrictedValue1((int, String, {bool named}) r) => switch (r) {
      (5, _, named: _) => 1,
    };

nonExhaustiveRestrictedValue2((int, String, {bool named}) r) => switch (r) {
      (_, 'foo', named: _) => 1,
    };

nonExhaustiveRestrictedValue3((int, String, {bool named}) r) => switch (r) {
      (_, _, named: true) => 1,
    };
