// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Whether the [processOutput] is a `String` or a `List` and not empty.
///
/// Can be used to check if the output of a process is empty or not.
bool processOutputIsNotEmpty(Object? processOutput) => switch (processOutput) {
      String() => processOutput.isNotEmpty,
      List() => processOutput.isNotEmpty,
      _ => false,
    };
