// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'factory.dart' show Factory;

/// Implementation of [Factory] for use during top level type inference, when
/// no representation of the code semantics needs to be created (only the type
/// needs to be inferred).
///
/// TODO(paulberry): fill this with methods that do nothing.
class ToplevelInferenceFactory implements Factory<void, void, void> {
  const ToplevelInferenceFactory();
}

const toplevelInferenceFactory = const ToplevelInferenceFactory();
