// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debuginfo.h"


namespace dart {

DebugInfo::DebugInfo() {
  handle_ = NULL;
}


DebugInfo::~DebugInfo() {
}


void DebugInfo::AddCode(uword pc, intptr_t size) {
  // Nothing to do as there is no support for this on Android.
}


void DebugInfo::AddCodeRegion(const char* name, uword pc, intptr_t size) {
  // Nothing to do as there is no support for this on Android.
}


bool DebugInfo::WriteToMemory(ByteBuffer* region) {
  // Nothing to do as there is no support for this on Android.
  return false;
}


DebugInfo* DebugInfo::NewGenerator() {
  return new DebugInfo();
}


void DebugInfo::RegisterSection(const char* name,
                                uword entry_point,
                                intptr_t size) {
  // Nothing to do as there is no support for this on Android.
}


void DebugInfo::UnregisterAllSections() {
  // Nothing to do as there is no support for this on Android.
}

}  // namespace dart
