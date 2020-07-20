// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:meta/meta.dart';

/// The data related to an element that has been renamed.
class RenameChange extends Change {
  /// The new name of the element.
  final String newName;

  /// Initialize a newly created transform to describe a renaming of an element
  /// to the [newName].
  RenameChange({@required this.newName});
}
