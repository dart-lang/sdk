// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/os_thread.h"

namespace dart {

static void DeleteMutex(void* isolate_data, void* mutex_pointer) {
  delete reinterpret_cast<Mutex*>(mutex_pointer);
}

static constexpr int kMutexNativeField = 0;

DEFINE_FFI_NATIVE_ENTRY(Mutex_Initialize, void, (Dart_Handle mutex_handle)) {
  Mutex* mutex = new Mutex();
  Dart_Handle err = Dart_SetNativeInstanceField(
      mutex_handle, kMutexNativeField, reinterpret_cast<intptr_t>(mutex));
  if (Dart_IsError(err)) {
    delete mutex;
    Dart_PropagateError(err);
  }
  Dart_NewFinalizableHandle(mutex_handle, mutex, sizeof(Mutex), DeleteMutex);
};

DEFINE_FFI_NATIVE_ENTRY(Mutex_Lock, void, (Dart_Handle mutex_handle)) {
  Mutex* mutex;
  Dart_Handle result = Dart_GetNativeInstanceField(
      mutex_handle, kMutexNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  mutex->Lock();
}

DEFINE_FFI_NATIVE_ENTRY(Mutex_Unlock, void, (Dart_Handle mutex_handle)) {
  Mutex* mutex;
  Dart_Handle result = Dart_GetNativeInstanceField(
      mutex_handle, kMutexNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  mutex->Unlock();
}

static void DeleteConditionVariable(void* isolate_data, void* condvar_pointer) {
  delete reinterpret_cast<ConditionVariable*>(condvar_pointer);
}

static constexpr int kCondVarNativeField = 0;

DEFINE_FFI_NATIVE_ENTRY(ConditionVariable_Initialize,
                        void,
                        (Dart_Handle condvar_handle)) {
  ConditionVariable* condvar = new ConditionVariable();
  Dart_Handle err = Dart_SetNativeInstanceField(
      condvar_handle, kCondVarNativeField, reinterpret_cast<intptr_t>(condvar));
  if (Dart_IsError(err)) {
    delete condvar;
    Dart_PropagateError(err);
  }
  Dart_NewFinalizableHandle(condvar_handle, condvar, sizeof(ConditionVariable),
                            DeleteConditionVariable);
}

DEFINE_FFI_NATIVE_ENTRY(ConditionVariable_Wait,
                        void,
                        (Dart_Handle condvar_handle,
                         Dart_Handle mutex_handle)) {
  Mutex* mutex;
  Dart_Handle result_mutex = Dart_GetNativeInstanceField(
      mutex_handle, kCondVarNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result_mutex)) {
    Dart_PropagateError(result_mutex);
  }
  ConditionVariable* condvar;
  Dart_Handle result_condvar =
      Dart_GetNativeInstanceField(condvar_handle, kCondVarNativeField,
                                  reinterpret_cast<intptr_t*>(&condvar));
  if (Dart_IsError(result_condvar)) {
    Dart_PropagateError(result_condvar);
  }
  condvar->Wait(mutex);
}

DEFINE_FFI_NATIVE_ENTRY(ConditionVariable_Notify,
                        void,
                        (Dart_Handle condvar_handle)) {
  ConditionVariable* condvar;
  Dart_Handle result_condvar =
      Dart_GetNativeInstanceField(condvar_handle, kCondVarNativeField,
                                  reinterpret_cast<intptr_t*>(&condvar));
  if (Dart_IsError(result_condvar)) {
    Dart_PropagateError(result_condvar);
  }
  condvar->Notify();
}

}  // namespace dart
