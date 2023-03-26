// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustive(List<num> list) => switch (list) {
      [...] => 0,
    };

exhaustive1a(List<num> list) => switch (list) {
      [] => 0,
      [_, ...] => 1,
    };

exhaustive1b(List<num> list) => switch (list) {
      [] => 0,
      [..., _] => 1,
    };

exhaustive2a(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [_, _, ...] => 2,
    };

exhaustive2b(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [_, ..., _] => 2,
    };

exhaustive2c(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [..., _, _] => 2,
    };

nonExhaustive1aMissing(List<num> list) => switch (list) {
      [_, ...] => 1,
    };

nonExhaustive1bMissing(List<num> list) => switch (list) {
      [..., _] => 1,
    };

nonExhaustive2aMissing(List<num> list) => switch (list) {
      [] => 0,
      [_, _, ...] => 2,
    };

nonExhaustive2bMissing(List<num> list) => switch (list) {
      [] => 0,
      [_, ..., _] => 2,
    };

nonExhaustive2cMissing(List<num> list) => switch (list) {
      [] => 0,
      [..., _, _] => 2,
    };

nonExhaustiveRestrictedType(List<num> list) => switch (list) {
      [...List<int> _] => 0,
    };

nonExhaustive1aRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [1, ...] => 1,
    };

nonExhaustive1aRestrictedType(List<num> list) => switch (list) {
      <int>[] => 0,
      [_, ...] => 1,
    };

nonExhaustive1bRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [..., 1] => 1,
    };

nonExhaustive1bRestrictedType(List<num> list) => switch (list) {
      [] => 0,
      [...List<int> _, _] => 1,
    };

nonExhaustive2aRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [1] => 1,
      [_, _, ...] => 2,
    };

nonExhaustive2bRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [1, _, ...] => 2,
    };

nonExhaustive2cRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [_, 1, ...] => 2,
    };

nonExhaustive2dRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [_, ..., 1] => 2,
    };

nonExhaustive2eRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [..., 1, _] => 2,
    };

nonExhaustive2fRestrictedValue(List<num> list) => switch (list) {
      [] => 0,
      [_] => 1,
      [..., _, 1] => 2,
    };
