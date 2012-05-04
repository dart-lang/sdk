// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "bin/fdutils.h"
#include "bin/socket.h"


void DebuggerConnectionImpl::StartHandler(int port_number) {
  FATAL("Debugger wire protocol not yet implemented on Linux\n");
}
