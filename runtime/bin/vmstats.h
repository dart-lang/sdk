// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_VMSTATS_H_
#define BIN_VMSTATS_H_

#include "include/dart_api.h"

/**
 * A VM status callback. Status plug-ins implement and register this
 * function using Dart_RegisterStatusPlugin. When Dart_GetVMStatus is
 * called, each callback is invoked to provide the requested information,
 * and the first one to do so "wins".
 *
 * Note: status requests execute outside of an isolate (which is why
 * handles aren't used).
 *
 * \param request an optional string that defines REST-like parameters
 *     to define what information is requested.
 *
 * \return Returns a valid JSON string, allocated from C heap. The caller
 *     is responsible for releasing this string. NULL is returned if the
 *     callback didn't handle that request.
 */
typedef char* (*Dart_VmStatusCallback)(const char* request);


/**
 * Register a VM status plug-in. The specified status type must not already
 * have a registered plug-in.
 *
 * \return 0 if the plug-in was registered, or -1 if there is an error.
 */
DART_EXPORT int Dart_RegisterVmStatusPlugin(Dart_VmStatusCallback callback);

#endif  // BIN_VMSTATS_H_
