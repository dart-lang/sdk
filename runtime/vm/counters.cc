// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/counters.h"

#include <string.h>
#include <map>  // TODO(koda): Remove STL dependencies.

#include "platform/globals.h"
#include "vm/os.h"

namespace dart {

struct CStrLess {
  bool operator()(const char* a, const char* b) const {
    return strcmp(a, b) < 0;
  }
};


Counters::~Counters() {
  if (collision_) {
    OS::PrintErr("Counters table collision; increase Counters::kSize.");
    return;
  }
  typedef std::map<const char*, int64_t, CStrLess> TotalsMap;
  TotalsMap totals;
  for (int i = 0; i < kSize; ++i) {
    const Counter& counter = counters_[i];
    if (counter.name != NULL) {
      totals[counter.name] += counter.value;
    }
  }
  for (TotalsMap::iterator it = totals.begin(); it != totals.end(); ++it) {
    OS::PrintErr("%s: %" Pd64 "\n", it->first, it->second);
  }
}

}  // namespace dart
