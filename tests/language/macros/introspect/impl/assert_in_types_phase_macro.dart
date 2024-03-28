// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:macros/macros.dart';
import 'package:expect/expect.dart';

import 'impl.dart';

macro class AssertInTypesPhase implements ClassTypesMacro {
  final String targetLibrary;
  final String targetName;
  final String? resolveIdentifier;

  const AssertInTypesPhase(
      {required this.targetLibrary,
      required this.targetName,
      this.resolveIdentifier});

  @override
  Future<void> buildTypesForClass(
          ClassDeclaration clazz, ClassTypeBuilder builder) =>
      _assert(clazz, builder);

  // TODO(davidmorgan): support asserting in more places.

  Future<void> _assert(
      TypeDeclaration typeDeclaration, TypePhaseIntrospector builder) async {
    if (resolveIdentifier != null) {
      Expect.deepEquals(
          resolveIdentifier,
          stringify(await builder.resolveIdentifier(
              Uri.parse(targetLibrary), targetName)));
    }
  }
}
