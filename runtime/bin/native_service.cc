// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/native_service.h"

#include "platform/globals.h"
#include "bin/thread.h"


NativeService::NativeService(const char* name,
                             Dart_NativeMessageHandler handler,
                             int number_of_ports)
    : name_(name),
      handler_(handler),
      service_ports_size_(number_of_ports),
      service_ports_index_(0) {
  service_ports_ = new Dart_Port[service_ports_size_];
  for (int i = 0; i < service_ports_size_; i++) {
    service_ports_[i] = ILLEGAL_PORT;
  }
}


NativeService::~NativeService() {
  delete[] service_ports_;
}


Dart_Port NativeService::GetServicePort() {
  MutexLocker lock(&mutex_);
  Dart_Port result = service_ports_[service_ports_index_];
  if (result == ILLEGAL_PORT) {
    result = Dart_NewNativePort(name_, handler_, true);
    ASSERT(result != ILLEGAL_PORT);
    service_ports_[service_ports_index_] = result;
  }
  service_ports_index_ = (service_ports_index_ + 1) % service_ports_size_;
  return result;
}
