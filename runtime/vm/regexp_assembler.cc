// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_assembler.h"

// SNIP

namespace dart {

RegExpMacroAssembler::RegExpMacroAssembler(Zone* zone)
  : slow_safe_compiler_(false),
    global_mode_(NOT_GLOBAL),
    zone_(zone) {
}


RegExpMacroAssembler::~RegExpMacroAssembler() {
}

// SNIP

}  // namespace dart
