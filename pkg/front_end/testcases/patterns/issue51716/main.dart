// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart';
import 'main_lib2.dart';

method1(Main1 main1, Main2 main2, Lib1a lib1a, Lib1b lib1b, Lib2 lib2) {
  switch (main1) {
    case Main1.a:
    case Main1.b:
  }
  switch (main2) {
    case Main2.a:
    case Main2.b:
  }
  switch (lib1a) {
    case Lib1a.a:
    case Lib1a.b:
  }
  switch (lib1b) {
    case Lib1b.a:
    case Lib1b.b:
  }
  switch (lib2) {
    case Lib2.a:
    case Lib2.b:
  }
}

enum Main1 {
  a,
  b,
}

method2(Main1 main1, Main2 main2, Lib1a lib1a, Lib1b lib1b, Lib2 lib2) {
  switch (main1) {
    case Main1.a:
    case Main1.b:
  }
  switch (main2) {
    case Main2.a:
    case Main2.b:
  }
  switch (lib1a) {
    case Lib1a.a:
    case Lib1a.b:
  }
  switch (lib1b) {
    case Lib1b.a:
    case Lib1b.b:
  }
  switch (lib2) {
    case Lib2.a:
    case Lib2.b:
  }
}

enum Main2 {
  a,
  b,
}

method3(Main1 main1, Main2 main2, Lib1a lib1a, Lib1b lib1b, Lib2 lib2) {
  switch (main1) {
    case Main1.a:
    case Main1.b:
  }
  switch (main2) {
    case Main2.a:
    case Main2.b:
  }
  switch (lib1a) {
    case Lib1a.a:
    case Lib1a.b:
  }
  switch (lib1b) {
    case Lib1b.a:
    case Lib1b.b:
  }
  switch (lib2) {
    case Lib2.a:
    case Lib2.b:
  }
}
