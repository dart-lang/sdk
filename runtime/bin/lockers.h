// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_LOCKERS_H_
#define RUNTIME_BIN_LOCKERS_H_

#include "platform/assert.h"
#include "platform/lockers.h"

namespace dart {
namespace bin {

using MutexLocker = dart::platform::MutexLocker;
using MonitorLocker = dart::platform::MonitorLocker;

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_LOCKERS_H_
