/*
 * Copyright (c) 2015, the Dart-ApiX project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef INCLUDE_DART_APIX_H_
#define INCLUDE_DART_APIX_H_

#include "dart_api.h"

DART_EXPORT bool DartX_Initialize();

DART_EXPORT bool DartX_Finalize();

DART_EXPORT bool DartX_LoadScript(const char* script);

DART_EXPORT bool DartX_Invoke(const char* func);

/**
 * Returns the port that script load requests should be sent on.
 *
 * \return Returns the port for load requests or ILLEGAL_PORT if the service
 * isolate failed to startup or does not support load requests.
 */
DART_EXPORT bool DartX_RegisterNativeFunction();

#endif  /* INCLUDE_DART_APIX_H_ */  /* NOLINT */
