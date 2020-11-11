// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';

/// An exception that is thrown when a change builder is asked to include an
/// edit that conflicts with a previous edit.
class ConflictingEditException implements Exception {
  /// The new edit that was being added.
  final SourceEdit newEdit;

  /// The existing edit with which it conflicts.
  final SourceEdit existingEdit;

  /// Initialize a newly created exception indicating that the [newEdit].
  ConflictingEditException(
      {@required this.newEdit, @required this.existingEdit});

  @override
  String toString() =>
      'ConflictingEditException: $newEdit conflicts with $existingEdit';
}
