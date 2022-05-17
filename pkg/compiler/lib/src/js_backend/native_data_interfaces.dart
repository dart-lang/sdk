// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/entities.dart';

/// This is a facade interface for the members of NativeBasicData that are
/// required by other migrated classes.
// TODO(48820): When NativeBasicData is migrated, remove this facade.
abstract class NativeBasicData {
  bool isJsInteropClass(ClassEntity element);

  bool isNativeClass(ClassEntity element);
}
