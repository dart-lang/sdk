// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_NATIVE_SERVICE_H_
#define BIN_NATIVE_SERVICE_H_

#include "include/dart_api.h"
#include "platform/globals.h"
#include "platform/thread.h"

// Utility class to set up a native service and allocate Dart native
// ports to interact with it from Dart code. The number of native ports
// allocated for each service is limited.
class NativeService {
 public:
  // Create a native service with the given name and handler. Allow
  // the creation of [number_of_ports] native ports for the service.
  // If GetServicePort is called more than [number_of_ports] times
  // one of the already allocated native ports will be reused.
  NativeService(const char* name,
                Dart_NativeMessageHandler handler,
                int number_of_ports);

  ~NativeService();

  // Get a Dart native port for this native service.
  Dart_Port GetServicePort();

 private:
  // Name and handler for the native service.
  const char* name_;
  Dart_NativeMessageHandler handler_;

  // Allocated native ports for the service. Mutex protected since
  // the service can be used from multiple isolates.
  dart::Mutex mutex_;
  int service_ports_size_;
  Dart_Port* service_ports_;
  int service_ports_index_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(NativeService);
};

#endif  // BIN_NATIVE_SERVICE_H_
