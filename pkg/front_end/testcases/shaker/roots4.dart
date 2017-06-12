// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'lib/lib.dart';

/// Tree-shaker preserves APIs used anywhere in the library, there is no special
/// root, and `main` is no special.
@Meta(toplevel)
class X {}

class Meta {
  final f;
  const Meta(this.f);
}
