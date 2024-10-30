// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ConstructorName {
  /// The name of the constructor itself.
  ///
  /// For an unnamed constructor, this is ''.
  final String name;

  /// The offset of the name of the constructor, if the constructor is not
  /// unnamed.
  final int? nameOffset;

  /// The name of the constructor including the enclosing declaration name.
  final String fullName;

  /// The offset at which [fullName] occurs.
  ///
  /// This is used in messages to put the `^` at the start of the [fullName].
  final int fullNameOffset;

  /// The number of characters of [fullName] that occurs at [fullNameOffset].
  ///
  /// This is used in messages to put the right amount of `^` under the name.
  final int fullNameLength;

  ConstructorName(
      {required this.name,
      required this.nameOffset,
      required this.fullName,
      required this.fullNameOffset,
      required this.fullNameLength});
}
