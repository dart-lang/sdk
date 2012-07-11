// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/locations.h"

#include "vm/intermediate_language.h"
#include "vm/flow_graph_compiler.h"

namespace dart {

LocationSummary* LocationSummary::Make(intptr_t input_count,
                                       Location out,
                                       ContainsCall contains_call) {
  LocationSummary* summary = new LocationSummary(input_count,
                                                 0,
                                                 contains_call);
  for (intptr_t i = 0; i < input_count; i++) {
    summary->set_in(i, Location::RequiresRegister());
  }
  summary->set_out(out);
  return summary;
}

}  // namespace dart

