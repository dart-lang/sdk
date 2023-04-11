// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Nullable = Object?;

exhaustiveByValue(Null n) => switch (n) {
      null => 0,
    };

exhaustiveByType(Null n) => switch (n) {
      Null() => 0,
    };

exhaustiveWithField(Null n) => switch (n) {
      Null(:var hashCode) => hashCode,
    };

nonExhaustiveRestrictedField(Null n) => switch (n) {
      Null(hashCode: 5) => 0,
    };

exhaustiveNullable(Object? o) => switch (o) {
      Object() => 0,
      Null() => 1,
    };

nonExhaustiveNullable(Object? o) => switch (o) {
      Object() => 1,
    };

nonExhaustiveNullableRestricted(Object? o) => switch (o) {
      Nullable(hashCode: 5) => 1,
    };
