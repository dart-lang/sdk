// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ffi_callback_metadata.h"

#include <memory>
#include <thread>  // NOLINT(build/c++11)
#include <unordered_set>
#include <vector>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

FunctionPtr CreateTestFunction() {
  const auto& ffi_lib = Library::Handle(Library::FfiLibrary());
  const auto& ffi_void = Class::Handle(ffi_lib.LookupClass(Symbols::FfiVoid()));
  const auto& ffi_void_type =
      Type::Handle(Type::NewNonParameterizedType(ffi_void));

  auto* thread = Thread::Current();
  const char* kScriptChars =
      R"(
      void testFunction() {
      }
      )";
  Dart_Handle library;
  {
    TransitionVMToNative transition(thread);
    library = TestCase::LoadTestScript(kScriptChars, nullptr);
    EXPECT_VALID(library);
  }

  const auto& lib =
      Library::Handle(Library::RawCast(Api::UnwrapHandle(library)));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const auto& cls = Class::Handle(lib.toplevel_class());
  EXPECT(!cls.IsNull());
  const auto& error = cls.EnsureIsFinalized(thread);
  EXPECT(error == Error::null());

  auto& function_name = String::Handle(String::New("testFunction"));
  const auto& func = Function::Handle(cls.LookupStaticFunction(function_name));
  EXPECT(!func.IsNull());

  FunctionType& signature = FunctionType::Handle(FunctionType::New());
  signature.set_result_type(ffi_void_type);
  signature.SetIsFinalized();
  signature ^= signature.Canonicalize(thread);

  const auto& callback = Function::Handle(compiler::ffi::NativeCallbackFunction(
      signature, func, Instance::Handle(Instance::null())));

  const auto& result = Object::Handle(
      thread->zone(), Compiler::CompileFunction(thread, callback));
  EXPECT(!result.IsError());

  return callback.ptr();
}

class FakeMessageHandler : public MessageHandler {
 public:
  MessageStatus HandleMessage(std::unique_ptr<Message> message) override {
    return MessageHandler::kOK;
  }
};

VM_UNIT_TEST_CASE(FfiCallbackMetadata_CreateSyncFfiCallback) {
  auto* fcm = FfiCallbackMetadata::Instance();
  FfiCallbackMetadata::Trampoline tramp1 = 0;
  FfiCallbackMetadata::Trampoline tramp2 = 0;

  {
    TestIsolateScope isolate_scope;
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    ASSERT(isolate == isolate_scope.isolate());
    TransitionNativeToVM transition(thread);
    StackZone stack_zone(thread);
    HandleScope handle_scope(thread);

    auto* zone = thread->zone();

    const auto& func = Function::Handle(CreateTestFunction());
    const auto& code = Code::Handle(func.EnsureHasCode());
    EXPECT(!code.IsNull());

    EXPECT_EQ(isolate->ffi_callback_sync_list_head(), nullptr);
    tramp1 = isolate->CreateSyncFfiCallback(zone, func);
    FfiCallbackMetadata::Metadata* m1 = isolate->ffi_callback_sync_list_head();

    EXPECT_NE(tramp1, 0u);
    EXPECT_NE(m1, nullptr);
    EXPECT_EQ(m1->sync_list_next(), nullptr);

    EXPECT(m1->IsLive());
    EXPECT_EQ(m1->target_isolate(), isolate);
    EXPECT_EQ(m1->target_entry_point(), code.EntryPoint());
    EXPECT(m1->trampoline_type() == FfiCallbackMetadata::TrampolineType::kSync);

    tramp2 = isolate->CreateSyncFfiCallback(zone, func);
    FfiCallbackMetadata::Metadata* m2 = isolate->ffi_callback_sync_list_head();

    EXPECT_NE(tramp2, 0u);
    EXPECT_NE(m2, nullptr);
    EXPECT_NE(m2, m1);
    EXPECT_EQ(m2->sync_list_next(), m1);
    EXPECT_EQ(m2->sync_list_next()->sync_list_next(), nullptr);

    EXPECT(m2->IsLive());
    EXPECT_EQ(m2->target_isolate(), isolate);
    EXPECT_EQ(m2->target_entry_point(), code.EntryPoint());
    EXPECT(m2->trampoline_type() == FfiCallbackMetadata::TrampolineType::kSync);
  }

  {
    // Isolate has shut down, so all sync callbacks should be deleted.
    FfiCallbackMetadata::Metadata m1 = fcm->LookupMetadataForTrampoline(tramp1);
    EXPECT(!m1.IsLive());

    FfiCallbackMetadata::Metadata m2 = fcm->LookupMetadataForTrampoline(tramp2);
    EXPECT(!m2.IsLive());
  }
}

VM_UNIT_TEST_CASE(FfiCallbackMetadata_DeleteSyncTrampolines) {
  static constexpr int kIterations = 1000;

  TestIsolateScope isolate_scope;
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate == isolate_scope.isolate());
  TransitionNativeToVM transition(thread);
  StackZone stack_zone(thread);
  HandleScope handle_scope(thread);

  auto* fcm = FfiCallbackMetadata::Instance();
  std::unordered_set<FfiCallbackMetadata::Trampoline> sync_tramps;
  FfiCallbackMetadata::Metadata* sync_list_head = nullptr;

  const auto& sync_func = Function::Handle(CreateTestFunction());
  const auto& sync_code = Code::Handle(sync_func.EnsureHasCode());
  EXPECT(!sync_code.IsNull());

  for (int itr = 0; itr < kIterations; ++itr) {
    sync_tramps.insert(fcm->CreateSyncFfiCallback(isolate, thread->zone(),
                                                  sync_func, &sync_list_head));
  }

  // Verify all the callbacks.
  for (FfiCallbackMetadata::Trampoline tramp : sync_tramps) {
    auto metadata = fcm->LookupMetadataForTrampoline(tramp);
    EXPECT(metadata.IsLive());
    EXPECT_EQ(metadata.target_isolate(), isolate);
    EXPECT_EQ(metadata.target_entry_point(), sync_code.EntryPoint());
    EXPECT_EQ(static_cast<uint8_t>(metadata.trampoline_type()),
              static_cast<uint8_t>(FfiCallbackMetadata::TrampolineType::kSync));
  }

  // Verify the list of callbacks.
  uword sync_list_length = 0;
  for (FfiCallbackMetadata::Metadata* metadata = sync_list_head;
       metadata != 0;) {
    ++sync_list_length;
    EXPECT(metadata->IsLive());
    EXPECT_EQ(metadata->target_isolate(), isolate);
    metadata = metadata->sync_list_next();
  }
  EXPECT_EQ(sync_list_length, sync_tramps.size());

  // Delete all callbacks and verify they're destroyed.
  fcm->DeleteSyncTrampolines(&sync_list_head);
  EXPECT_EQ(sync_list_head, nullptr);
  for (FfiCallbackMetadata::Trampoline tramp : sync_tramps) {
    EXPECT(!fcm->LookupMetadataForTrampoline(tramp).IsLive());
  }
}

static void RunBigRandomMultithreadedTest(uint64_t seed) {
  static constexpr int kIterations = 1000;

  TestIsolateScope isolate_scope;
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate == isolate_scope.isolate());
  TransitionNativeToVM transition(thread);
  StackZone stack_zone(thread);
  HandleScope handle_scope(thread);

  auto* fcm = FfiCallbackMetadata::Instance();
  Random random(seed);
  std::unordered_set<FfiCallbackMetadata::Trampoline> sync_tramps;
  FfiCallbackMetadata::Metadata* sync_list_head = nullptr;

  const auto& sync_func = Function::Handle(CreateTestFunction());
  const auto& sync_code = Code::Handle(sync_func.EnsureHasCode());
  EXPECT(!sync_code.IsNull());

  for (int itr = 0; itr < kIterations; ++itr) {
    // Do a random action:
    //  - Allocate a sync callback from one of the threads
    //  - Allocate an async callback from one of the threads
    //  - Delete an async callback
    //  - Delete all the sync callbacks for an isolate

    // Sync callbacks. Randomly create and destroy them, but make destruction
    // rare since all sync callbacks for the isolate are deleted at once.
    if ((random.NextUInt32() % 100) == 0) {
      // Delete.
      fcm->DeleteSyncTrampolines(&sync_list_head);
      // It would be nice to verify that all the sync_tramps have been deleted,
      // but this is flaky because other threads can recycle these trampolines
      // before we finish checking all of them.
      EXPECT_EQ(sync_list_head, nullptr);
      sync_tramps.clear();
    } else {
      // Create.
      sync_tramps.insert(fcm->CreateSyncFfiCallback(
          isolate, thread->zone(), sync_func, &sync_list_head));
    }

    // Verify all the sync callbacks.
    for (FfiCallbackMetadata::Trampoline tramp : sync_tramps) {
      auto metadata = fcm->LookupMetadataForTrampoline(tramp);
      EXPECT(metadata.IsLive());
      EXPECT_EQ(metadata.target_isolate(), isolate);
      EXPECT_EQ(metadata.target_entry_point(), sync_code.EntryPoint());
      EXPECT_EQ(
          static_cast<uint8_t>(metadata.trampoline_type()),
          static_cast<uint8_t>(FfiCallbackMetadata::TrampolineType::kSync));
    }

    // Verify the isolate's list of sync callbacks.
    uword sync_list_length = 0;
    for (FfiCallbackMetadata::Metadata* metadata = sync_list_head;
         metadata != 0;) {
      ++sync_list_length;
      EXPECT(metadata->IsLive());
      EXPECT_EQ(metadata->target_isolate(), isolate);
      metadata = metadata->sync_list_next();
    }
    EXPECT_EQ(sync_list_length, sync_tramps.size());
  }

  // Delete all remaining callbacks.
  fcm->DeleteSyncTrampolines(&sync_list_head);
  EXPECT_EQ(sync_list_head, nullptr);
}

ISOLATE_UNIT_TEST_CASE(FfiCallbackMetadata_BigRandomMultithreadedTest) {
  static constexpr int kThreads = 5;

  std::vector<std::thread> threads;

  Random random;
  for (int i = 0; i < kThreads; ++i) {
    threads.push_back(
        std::thread(RunBigRandomMultithreadedTest, random.NextUInt64()));
  }

  for (auto& thread : threads) {
    thread.join();
  }
}

}  // namespace dart
