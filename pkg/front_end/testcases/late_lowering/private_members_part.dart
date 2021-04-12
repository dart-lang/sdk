// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'private_members.dart';

class _Class {
  late int _privateField1 = 1;

  late int? _privateField2 = 1;

  late int _privateFinalField1 = 1;

  late int? _privateFinalField2 = 1;
}

extension _Extension on int {
  static late int _privateField1 = 1;

  static late int? _privateField2 = 1;

  static late int _privateFinalField1 = 1;

  static late int? _privateFinalField2 = 1;
}
