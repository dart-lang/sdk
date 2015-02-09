// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PROFILER_SERVICE_H_
#define VM_PROFILER_SERVICE_H_

#include "vm/allocation.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/tags.h"
#include "vm/thread_interrupter.h"

// Profile VM Service.
// NOTE: For sampling and stack walking related code, see profiler.h.

namespace dart {

// Forward declarations.
class JSONArray;
class JSONStream;
class ProfilerCodeRegionTable;

class ProfilerService : public AllStatic {
 public:
  enum TagOrder {
    kNoTags,
    kUser,
    kUserVM,
    kVM,
    kVMUser
  };

  static void PrintJSON(JSONStream* stream,
                        TagOrder tag_order);
};

}  // namespace dart

#endif  // VM_PROFILER_SERVICE_H_
