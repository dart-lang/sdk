// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is linked into the dart executable when it does not have a
// snapshot linked into it.

#include <stdint.h>

extern "C" {
const uint8_t* kDartCoreSnapshotData = nullptr;
const uint8_t* kDartCoreSnapshotText = nullptr;
}
