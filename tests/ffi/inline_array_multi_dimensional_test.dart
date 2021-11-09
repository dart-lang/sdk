// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";
import 'package:ffi/ffi.dart';

// Reuse compound definitions.
import 'function_structs_by_value_generated_compounds.dart';

void main() {
  testSizeOf();
  testLoad();
  testLoadMultiAnnotation();
  testStore();
  testToString();
  testRange();
}

void testSizeOf() {
  Expect.equals(32, sizeOf<Struct32BytesInlineArrayMultiDimensionalInt>());
  Expect.equals(64, sizeOf<Struct64BytesInlineArrayMultiDimensionalInt>());
}

/// Tests the load of nested `Array`s.
///
/// Only stores into arrays which do not have nested arrays.
void testLoad() {
  final Pointer<Struct32BytesInlineArrayMultiDimensionalInt> pointer = calloc();
  final struct = pointer.ref;
  final array = struct.a0;
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        for (int l = 0; l < 2; l++) {
          for (int m = 0; m < 2; m++) {
            array[i][j][k][l][m] = i + j + k + l + m;
          }
        }
      }
    }
  }
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        for (int l = 0; l < 2; l++) {
          for (int m = 0; m < 2; m++) {
            Expect.equals(i + j + k + l + m, array[i][j][k][l][m]);
          }
        }
      }
    }
  }
  calloc.free(pointer);
}

/// Tests the load of nested `Array`s.
///
/// Only stores into arrays which do not have nested arrays.
void testLoadMultiAnnotation() {
  final Pointer<Struct64BytesInlineArrayMultiDimensionalInt> pointer = calloc();
  final struct = pointer.ref;
  final array = struct.a0;
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        for (int l = 0; l < 2; l++) {
          for (int m = 0; m < 2; m++) {
            for (int o = 0; o < 2; o++) {
              array[i][j][k][l][m][o] = i + j + k + l + m + o;
            }
          }
        }
      }
    }
  }
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        for (int l = 0; l < 2; l++) {
          for (int m = 0; m < 2; m++) {
            for (int o = 0; o < 2; o++) {
              Expect.equals(i + j + k + l + m + o, array[i][j][k][l][m][o]);
            }
          }
        }
      }
    }
  }
  calloc.free(pointer);
}

void testStore() {
  final Pointer<Struct32BytesInlineArrayMultiDimensionalInt> pointer = calloc();
  final struct = pointer.ref;
  final array = struct.a0;
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        for (int l = 0; l < 2; l++) {
          for (int m = 0; m < 2; m++) {
            array[i][j][k][l][m] = i + j + k + l + m;
          }
        }
      }
    }
  }
  array[0] = array[1]; // Copy many things.
  for (int j = 0; j < 2; j++) {
    for (int k = 0; k < 2; k++) {
      for (int l = 0; l < 2; l++) {
        for (int m = 0; m < 2; m++) {
          Expect.equals(array[1][j][k][l][m], array[0][j][k][l][m]);
        }
      }
    }
  }
  calloc.free(pointer);
}

// // Tests the toString of the test generator.
void testToString() {
  final Pointer<Struct32BytesInlineArrayMultiDimensionalInt> pointer = calloc();
  final struct = pointer.ref;
  final array = struct.a0;
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        for (int l = 0; l < 2; l++) {
          for (int m = 0; m < 2; m++) {
            array[i][j][k][l][m] = 16 * i + 8 * j + 4 * k + 2 * l + m;
          }
        }
      }
    }
  }
  Expect.equals(
      "([[[[[0, 1], [2, 3]], [[4, 5], [6, 7]]], [[[8, 9], [10, 11]], [[12, 13], [14, 15]]]], [[[[16, 17], [18, 19]], [[20, 21], [22, 23]]], [[[24, 25], [26, 27]], [[28, 29], [30, 31]]]]])",
      struct.toString());
  calloc.free(pointer);
}

void testRange() {
  final pointer = calloc<Struct32BytesInlineArrayMultiDimensionalInt>();
  final struct = pointer.ref;
  final array = struct.a0;
  array[0];
  array[1];
  Expect.throws(() => array[-1]);
  Expect.throws(() => array[-1] = array[1]);
  Expect.throws(() => array[2]);
  Expect.throws(() => array[2] = array[1]);
  array[0][0];
  array[0][1];
  Expect.throws(() => array[0][-1]);
  Expect.throws(() => array[0][-1] = array[0][1]);
  Expect.throws(() => array[0][2]);
  Expect.throws(() => array[0][2] = array[0][1]);
  calloc.free(pointer);
}
