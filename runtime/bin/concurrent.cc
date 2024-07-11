// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/thread.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

static constexpr int kMutexNativeField = 0;
static constexpr int kCondVarNativeField = 0;

static void DeleteMutex(void* isolate_data, void* mutex_pointer) {
  delete reinterpret_cast<Mutex*>(mutex_pointer);
}

void FUNCTION_NAME(Mutex_Initialize)(Dart_NativeArguments args) {
  Dart_Handle mutex_obj = Dart_GetNativeArgument(args, 0);
  Mutex* mutex = new Mutex();
  Dart_Handle err = Dart_SetNativeInstanceField(
      mutex_obj, kMutexNativeField, reinterpret_cast<intptr_t>(mutex));
  if (Dart_IsError(err)) {
    delete mutex;
    Dart_PropagateError(err);
  }
  Dart_NewFinalizableHandle(mutex_obj, mutex, sizeof(Mutex), DeleteMutex);
}

void FUNCTION_NAME(Mutex_Lock)(Dart_NativeArguments args) {
  Dart_Handle mutex_obj = Dart_GetNativeArgument(args, 0);
  Mutex* mutex;
  Dart_Handle result = Dart_GetNativeInstanceField(
      mutex_obj, kMutexNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  mutex->Lock();
  Dart_SetReturnValue(args, Dart_Null());
}

void FUNCTION_NAME(Mutex_Unlock)(Dart_NativeArguments args) {
  Dart_Handle mutex_obj = Dart_GetNativeArgument(args, 0);
  Mutex* mutex;
  Dart_Handle result = Dart_GetNativeInstanceField(
      mutex_obj, kMutexNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  mutex->Unlock();
  Dart_SetReturnValue(args, Dart_Null());
}

static void DeleteConditionVariable(void* isolate_data, void* condvar_pointer) {
  delete reinterpret_cast<ConditionVariable*>(condvar_pointer);
}

void FUNCTION_NAME(ConditionVariable_Initialize)(Dart_NativeArguments args) {
  Dart_Handle condvar_obj = Dart_GetNativeArgument(args, 0);
  ConditionVariable* condvar = new ConditionVariable();
  Dart_Handle err = Dart_SetNativeInstanceField(
      condvar_obj, kCondVarNativeField, reinterpret_cast<intptr_t>(condvar));
  if (Dart_IsError(err)) {
    delete condvar;
    Dart_PropagateError(err);
  }
  Dart_NewFinalizableHandle(condvar_obj, condvar, sizeof(ConditionVariable),
                            DeleteConditionVariable);
}

void FUNCTION_NAME(ConditionVariable_Wait)(Dart_NativeArguments args) {
  Dart_Handle condvar_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle mutex_obj = Dart_GetNativeArgument(args, 1);
  Mutex* mutex;
  Dart_Handle result_mutex = Dart_GetNativeInstanceField(
      mutex_obj, kCondVarNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result_mutex)) {
    Dart_PropagateError(result_mutex);
  }
  ConditionVariable* condvar;
  Dart_Handle result_condvar = Dart_GetNativeInstanceField(
      condvar_obj, kCondVarNativeField, reinterpret_cast<intptr_t*>(&condvar));
  if (Dart_IsError(result_condvar)) {
    Dart_PropagateError(result_condvar);
  }
  condvar->Wait(mutex);
  Dart_SetReturnValue(args, Dart_Null());
}

void FUNCTION_NAME(ConditionVariable_Notify)(Dart_NativeArguments args) {
  Dart_Handle condvar_obj = Dart_GetNativeArgument(args, 0);
  ConditionVariable* condvar;
  Dart_Handle result_condvar = Dart_GetNativeInstanceField(
      condvar_obj, kCondVarNativeField, reinterpret_cast<intptr_t*>(&condvar));
  if (Dart_IsError(result_condvar)) {
    Dart_PropagateError(result_condvar);
  }
  condvar->Notify();
  Dart_SetReturnValue(args, Dart_Null());
}

}  // namespace bin
}  // namespace dart
