// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/dart_api_impl.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/heap/safepoint.h"
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

DEFINE_FFI_NATIVE_ENTRY(Mutex_RunLocked,
                        Dart_Handle,
                        (Dart_Handle mutex_handle,
                         Dart_Handle closure_handle)) {
  Mutex* mutex;
  Dart_Handle result = Dart_GetNativeInstanceField(
      mutex_handle, kMutexNativeField, reinterpret_cast<intptr_t*>(&mutex));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  mutex->Lock();
  result = Dart_InvokeClosure(closure_handle, 0, nullptr);
  mutex->Unlock();
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return result;
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
                         Dart_Handle mutex_handle,
                         intptr_t timeout)) {
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
  condvar->Wait(mutex, timeout);
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

DEFINE_FFI_NATIVE_ENTRY(ConditionVariable_NotifyAll,
                        void,
                        (Dart_Handle condvar_handle)) {
  ConditionVariable* condvar;
  Dart_Handle result_condvar =
      Dart_GetNativeInstanceField(condvar_handle, kCondVarNativeField,
                                  reinterpret_cast<intptr_t*>(&condvar));
  if (Dart_IsError(result_condvar)) {
    Dart_PropagateError(result_condvar);
  }
  condvar->NotifyAll();
}

DEFINE_FFI_NATIVE_ENTRY(IsolateGroup_runSync,
                        Dart_Handle,
                        (Dart_Handle closure)) {
  if (!FLAG_experimental_shared_data) {
    FATAL(
        "Encountered shared data api when functionality is disabled. "
        "Pass --experimental-shared-data");
  }
  Thread* current_thread = Thread::Current();
  ASSERT(current_thread->execution_state() == Thread::kThreadInNative);

  {
    DARTSCOPE(current_thread);
    auto& object =
        Object::Handle(current_thread->zone(), Api::UnwrapHandle(closure));
    object.EnsureDeeplyImmutable(current_thread->zone());
  }

  Isolate* saved_isolate = current_thread->isolate();
  current_thread->ExitSafepointFromNative();
  current_thread->set_execution_state(Thread::kThreadInVM);
  Thread::ExitIsolate(/*isolate_shutdown=*/false);

  Thread::EnterIsolateGroupAsMutator(current_thread->isolate_group(),
                                     /*bypass_safepoint=*/false);

  auto mutator_thread = Thread::Current();

  ApiState* state = mutator_thread->isolate_group()->api_state();
  ASSERT(state != nullptr);
  mutator_thread->EnterApiScope();
  ASSERT(mutator_thread->execution_state() == Thread::kThreadInVM);

  Dart_PersistentHandle persistent_result;
  {
    TransitionVMToNative transition(mutator_thread);
    Dart_Handle result = Dart_InvokeClosure(closure, 0, nullptr);
    persistent_result = Dart_NewPersistentHandle(result);
  }

  mutator_thread->ExitApiScope();

  Thread::ExitIsolateGroupAsMutator(/*bypass_safepoint=*/false);
  Thread::EnterIsolate(saved_isolate);

  Thread* T = Thread::Current();
  T->set_execution_state(Thread::kThreadInNative);
  T->EnterSafepoint();

  Dart_Handle local_handle = Dart_HandleFromPersistent(persistent_result);
  Dart_DeletePersistentHandle(persistent_result);
  return local_handle;
}

}  // namespace dart
