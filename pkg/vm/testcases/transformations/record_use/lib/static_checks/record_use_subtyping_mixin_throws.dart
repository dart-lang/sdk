// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

@RecordUse()
mixin MyMixin {}

final class MixedIn with MyMixin {}

void main() {
  print(MixedIn());
}
