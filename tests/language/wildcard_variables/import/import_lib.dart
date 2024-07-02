// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=wildcard-variables

int topLevel = 1;

class C {
  final bool bar;
  final bool fn;

  C(String str)
      : bar = str.bar,
        fn = str.fn;
}

extension StringExtension on String {
  bool get foo => true;
}

extension _PrivateStringExtension on String {
  bool get bar => true;
}

extension on String {
  bool get fn => true;
}
