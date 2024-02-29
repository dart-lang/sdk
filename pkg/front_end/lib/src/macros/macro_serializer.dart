// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Interface for supporting serialization of [Component]s for macro
/// precompilation.
abstract class MacroSerializer {
  /// Returns a [Uri] that can be accessed by the macro executor.
  Future<Uri> createUriForComponent(Component component);

  /// Releases all resources of this serializer.
  ///
  /// This must be called when the [Uri]s created by [createUriForComponent]
  /// are no longer needed.
  Future<void> close();
}
