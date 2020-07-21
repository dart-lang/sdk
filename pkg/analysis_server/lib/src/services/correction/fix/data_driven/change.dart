// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// The behavior common to all of the changes used to construct a transform.
abstract class Change<D> {
  /// Use the [builder] to create a change that is part or all of the fix being
  /// made by the data-driven [fix]. The [data] is the data returned by the
  /// [validate] method.
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, D data);

  /// Validate that this change can be applied. Return the data to be passed to
  /// [apply] if the change can be applied, or `null` if it can't be applied.
  D validate(DataDrivenFix fix);
}
