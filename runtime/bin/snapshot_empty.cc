// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is linked into the dart executable when it does not have a
// snapshot linked into it.

#if defined(_WIN32)
typedef unsigned __int8 uint8_t;
#else
#include <inttypes.h>
#include <stdint.h>
#endif
#include <stddef.h>

extern "C" {
const uint8_t* kDartVmSnapshotData = NULL;
const uint8_t* kDartVmSnapshotInstructions = NULL;
const uint8_t* kDartCoreIsolateSnapshotData = NULL;
const uint8_t* kDartCoreIsolateSnapshotInstructions = NULL;
}
