// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'lib5.dart';

extension type E3(int _info) {
  int get info => _info;
}

extension type _E4(int _info) {
  int get info => _info;
}

extension E5 on String {
  String addSuffix1(String suffix) => this + suffix;
}

extension _E6 on String {
  String addSuffix2(String suffix) => this + suffix;
}

extension on String {
  String addSuffix3(String suffix) => this + suffix;
}
