// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is linked into the dart executable when it does not have
// Observatory baked in.

#if defined(_WIN32)
typedef unsigned __int8 uint8_t;
#else
#include <inttypes.h>
#include <stdint.h>
#endif
#include <stddef.h>

namespace dart {
namespace bin {

static const uint8_t observatory_assets_archive_[] = {'\0'};
unsigned int observatory_assets_archive_len = 0;
const uint8_t* observatory_assets_archive = observatory_assets_archive_;

}  // namespace bin
}  // namespace dart
