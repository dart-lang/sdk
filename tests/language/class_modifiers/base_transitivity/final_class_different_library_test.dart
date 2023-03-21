// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of a final class defined in a different library

import "shared_library_definitions.dart" show FinalClass;

base mixin BaseMixinOn on FinalClass {}

main() {}
