// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

enum Color { red, green, blue }

enum Taste { sweet, sour, salty, bitter, umami }

void main() {
  Expect.equals(getValue(Taste.sweet, Color.blue), 1);
  Expect.equals(getValue(Taste.bitter, Color.blue), 1);
  Expect.equals(getValue(Taste.salty, Color.red), 2);
  Expect.equals(getValue(Taste.salty, Color.blue), 4);
  Expect.equals(getValue(Taste.salty, Color.green), 3);
  Expect.equals(getValue(Taste.umami, Color.red), 4);
}

int getValue(Taste taste, Color color) {
  switch (taste) {
    case Taste.sweet:
    case Taste.sour:
    case Taste.bitter:
      return 1;
    case Taste.salty:
      switch (color) {
        case Color.red:
          return 2;
        case Color.blue:
          continue LABEL;
        case Color.green:
          return 3;
      }
      throw Exception('Invalid state.');
    LABEL:
    case Taste.umami:
      return 4;
  }
}
