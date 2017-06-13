// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_assembler.h"

#include "vm/flags.h"
#include "vm/regexp.h"

namespace dart {

BlockLabel::BlockLabel()
    : block_(NULL), is_bound_(false), is_linked_(false), pos_(-1) {
  if (!FLAG_interpret_irregexp) {
    // Only needed by the compiled IR backend.
    block_ = new JoinEntryInstr(-1, -1, Thread::Current()->GetNextDeoptId());
  }
}


RegExpMacroAssembler::RegExpMacroAssembler(Zone* zone)
    : slow_safe_compiler_(false), global_mode_(NOT_GLOBAL), zone_(zone) {}


RegExpMacroAssembler::~RegExpMacroAssembler() {}

}  // namespace dart
