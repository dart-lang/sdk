// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <netdb.h>

#include "bin/utils.h"
#include "platform/assert.h"

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_sub_system(kSystem);
  set_code(errno);
  SetMessage(strerror(errno));
}


void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);
  if (sub_system == kSystem) {
    SetMessage(strerror(code));
  } else if (sub_system == kGetAddressInfo) {
    SetMessage(gai_strerror(code));
  } else {
    UNREACHABLE();
  }
}
