// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

enum Enum<T> {
  a<num>(),
  b<String>(),
  c<bool>(),
}

method1(Enum<dynamic> e) {
  switch (e) {
    case Enum.a:
    case Enum.b:
    case Enum.c:
  }
}

method2(Enum<num> e) {
  switch (e) {
    case Enum.a:
    case Enum.b:
    case Enum.c:
  }
}

method3(Enum<int> e) {
  switch (e) {
    case Enum.a:
    case Enum.b:
    case Enum.c:
  }
}

method4<T>(Enum<T> e) {
  switch (e) {
    case Enum.a:
    case Enum.b:
    case Enum.c:
  }
}

method5<T extends num>(Enum<T> e) {
  switch (e) {
    case Enum.a:
    case Enum.b:
    case Enum.c:
  }
}
