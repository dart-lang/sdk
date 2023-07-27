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

FunctionPtr CreateTestFunction(FfiTrampolineKind kind) {
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
      signature, func, Instance::Handle(Instance::null()), kind));

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

    const auto& func =
        Function::Handle(CreateTestFunction(FfiTrampolineKind::kSyncCallback));
    const auto& code = Code::Handle(func.EnsureHasCode());
    EXPECT(!code.IsNull());

    tramp1 = isolate->CreateSyncFfiCallback(zone, func);
    EXPECT_NE(tramp1, 0u);

    {
      FfiCallbackMetadata::Metadata m1 =
          fcm->LookupMetadataForTrampoline(tramp1);
      EXPECT(m1.IsLive());
      EXPECT_EQ(m1.target_isolate(), isolate);
      EXPECT_EQ(m1.target_entry_point(), code.EntryPoint());
      EXPECT_EQ(m1.send_port(), ILLEGAL_PORT);
      EXPECT_EQ(static_cast<int>(m1.trampoline_type()),
                static_cast<int>(FfiCallbackMetadata::TrampolineType::kSync));

      // head -> tramp1
      auto* e1 = fcm->MetadataOfTrampoline(tramp1);
      EXPECT_EQ(isolate->ffi_callback_list_head(), e1);
      EXPECT_EQ(e1->list_prev(), nullptr);
      EXPECT_EQ(e1->list_next(), nullptr);
    }

    tramp2 = isolate->CreateSyncFfiCallback(zone, func);
    EXPECT_NE(tramp2, 0u);
    EXPECT_NE(tramp2, tramp1);

    {
      FfiCallbackMetadata::Metadata m2 =
          fcm->LookupMetadataForTrampoline(tramp2);
      EXPECT(m2.IsLive());
      EXPECT_EQ(m2.target_isolate(), isolate);
      EXPECT_EQ(m2.target_entry_point(), code.EntryPoint());
      EXPECT_EQ(m2.send_port(), ILLEGAL_PORT);
      EXPECT_EQ(static_cast<int>(m2.trampoline_type()),
                static_cast<int>(FfiCallbackMetadata::TrampolineType::kSync));
    }

    {
      // head -> tramp2 -> tramp1
      auto* e1 = fcm->MetadataOfTrampoline(tramp1);
      auto* e2 = fcm->MetadataOfTrampoline(tramp2);
      EXPECT_EQ(isolate->ffi_callback_list_head(), e2);
      EXPECT_EQ(e2->list_prev(), nullptr);
      EXPECT_EQ(e2->list_next(), e1);
      EXPECT_EQ(e1->list_prev(), e2);
      EXPECT_EQ(e1->list_next(), nullptr);
    }

    {
      isolate->DeleteFfiCallback(tramp1);
      FfiCallbackMetadata::Metadata m1 =
          fcm->LookupMetadataForTrampoline(tramp1);
      EXPECT(!m1.IsLive());

      // head -> tramp2
      auto* e2 = fcm->MetadataOfTrampoline(tramp2);
      EXPECT_EQ(isolate->ffi_callback_list_head(), e2);
      EXPECT_EQ(e2->list_prev(), nullptr);
      EXPECT_EQ(e2->list_next(), nullptr);
    }
  }

  {
    // Isolate has shut down, so all callbacks should be deleted.
    FfiCallbackMetadata::Metadata m1 = fcm->LookupMetadataForTrampoline(tramp1);
    EXPECT(!m1.IsLive());

    FfiCallbackMetadata::Metadata m2 = fcm->LookupMetadataForTrampoline(tramp2);
    EXPECT(!m2.IsLive());
  }
}

VM_UNIT_TEST_CASE(FfiCallbackMetadata_CreateAsyncFfiCallback) {
  auto* fcm = FfiCallbackMetadata::Instance();
  FfiCallbackMetadata::Trampoline tramp1 = 0;
  FfiCallbackMetadata::Trampoline tramp2 = 0;

  {
    TestIsolateScope isolate_scope;
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    ASSERT(thread->isolate() == isolate_scope.isolate());
    TransitionNativeToVM transition(thread);
    StackZone stack_zone(thread);
    HandleScope handle_scope(thread);

    auto* zone = thread->zone();

    const Function& func =
        Function::Handle(CreateTestFunction(FfiTrampolineKind::kAsyncCallback));
    const Code& code = Code::Handle(func.EnsureHasCode());
    EXPECT(!code.IsNull());

    EXPECT_EQ(isolate->ffi_callback_list_head(), nullptr);

    auto port1 = PortMap::CreatePort(new FakeMessageHandler());
    tramp1 = isolate->CreateAsyncFfiCallback(zone, func, port1);
    EXPECT_NE(tramp1, 0u);

    {
      FfiCallbackMetadata::Metadata m1 =
          fcm->LookupMetadataForTrampoline(tramp1);
      EXPECT(m1.IsLive());
      EXPECT_EQ(m1.target_isolate(), isolate);
      EXPECT_EQ(m1.target_entry_point(), code.EntryPoint());
      EXPECT_EQ(m1.send_port(), port1);
      EXPECT_EQ(static_cast<int>(m1.trampoline_type()),
                static_cast<int>(FfiCallbackMetadata::TrampolineType::kAsync));

      // head -> tramp1
      auto* e1 = fcm->MetadataOfTrampoline(tramp1);
      EXPECT_EQ(isolate->ffi_callback_list_head(), e1);
      EXPECT_EQ(e1->list_prev(), nullptr);
      EXPECT_EQ(e1->list_next(), nullptr);
    }

    auto port2 = PortMap::CreatePort(new FakeMessageHandler());
    tramp2 = isolate->CreateAsyncFfiCallback(zone, func, port2);
    EXPECT_NE(tramp2, 0u);
    EXPECT_NE(tramp2, tramp1);

    {
      FfiCallbackMetadata::Metadata m2 =
          fcm->LookupMetadataForTrampoline(tramp2);
      EXPECT(m2.IsLive());
      EXPECT_EQ(m2.target_isolate(), isolate);
      EXPECT_EQ(m2.target_entry_point(), code.EntryPoint());
      EXPECT_EQ(m2.send_port(), port2);
      EXPECT_EQ(static_cast<int>(m2.trampoline_type()),
                static_cast<int>(FfiCallbackMetadata::TrampolineType::kAsync));
    }

    {
      // head -> tramp2 -> tramp1
      auto* e1 = fcm->MetadataOfTrampoline(tramp1);
      auto* e2 = fcm->MetadataOfTrampoline(tramp2);
      EXPECT_EQ(isolate->ffi_callback_list_head(), e2);
      EXPECT_EQ(e2->list_prev(), nullptr);
      EXPECT_EQ(e2->list_next(), e1);
      EXPECT_EQ(e1->list_prev(), e2);
      EXPECT_EQ(e1->list_next(), nullptr);
    }

    {
      isolate->DeleteFfiCallback(tramp2);
      FfiCallbackMetadata::Metadata m2 =
          fcm->LookupMetadataForTrampoline(tramp2);
      EXPECT(!m2.IsLive());

      // head -> tramp1
      auto* e1 = fcm->MetadataOfTrampoline(tramp1);
      EXPECT_EQ(isolate->ffi_callback_list_head(), e1);
      EXPECT_EQ(e1->list_prev(), nullptr);
      EXPECT_EQ(e1->list_next(), nullptr);
    }
  }

  {
    // Isolate has shut down, so all callbacks should be deleted.
    FfiCallbackMetadata::Metadata m1 = fcm->LookupMetadataForTrampoline(tramp1);
    EXPECT(!m1.IsLive());

    FfiCallbackMetadata::Metadata m2 = fcm->LookupMetadataForTrampoline(tramp2);
    EXPECT(!m2.IsLive());
  }
}

ISOLATE_UNIT_TEST_CASE(FfiCallbackMetadata_TrampolineRecycling) {
  Isolate* isolate = thread->isolate();
  auto* zone = thread->zone();
  auto* fcm = FfiCallbackMetadata::Instance();

  const Function& func =
      Function::Handle(CreateTestFunction(FfiTrampolineKind::kAsyncCallback));
  const Code& code = Code::Handle(func.EnsureHasCode());
  EXPECT(!code.IsNull());

  auto port = PortMap::CreatePort(new FakeMessageHandler());
  FfiCallbackMetadata::Metadata* list_head = nullptr;

  // Allocate and free one callback at a time, and verify that we don't reuse
  // them. Allocate enough that the whole page fills up with dead trampolines.
  std::vector<FfiCallbackMetadata::Trampoline> allocation_order;
  std::unordered_set<FfiCallbackMetadata::Trampoline> allocated;
  const intptr_t trampolines_per_page =
      FfiCallbackMetadata::NumCallbackTrampolinesPerPage();
  for (intptr_t i = 0; i < trampolines_per_page; ++i) {
    auto tramp =
        fcm->CreateAsyncFfiCallback(isolate, zone, func, port, &list_head);
    EXPECT_EQ(allocated.count(tramp), 0u);
    allocation_order.push_back(tramp);
    allocated.insert(tramp);
    fcm->DeleteCallback(tramp, &list_head);
  }

  // Now  as we continue allocating and freeing, we start reusing them, in the
  // same allocation order as before.
  for (intptr_t i = 0; i < trampolines_per_page; ++i) {
    auto tramp =
        fcm->CreateAsyncFfiCallback(isolate, zone, func, port, &list_head);
    EXPECT_EQ(allocated.count(tramp), 1u);
    EXPECT_EQ(allocation_order[i], tramp);
    fcm->DeleteCallback(tramp, &list_head);
  }

  // Now allocate enough to fill the page without freeing them. Again they
  // should come out in the same order.
  for (intptr_t i = 0; i < trampolines_per_page; ++i) {
    auto tramp =
        fcm->CreateAsyncFfiCallback(isolate, zone, func, port, &list_head);
    EXPECT_EQ(allocated.count(tramp), 1u);
    EXPECT_EQ(allocation_order[i], tramp);
  }

  // Now that the page is full, we should allocate a new page and see new
  // trampolines we haven't seen before.
  for (intptr_t i = 0; i < 3 * trampolines_per_page; ++i) {
    auto tramp =
        fcm->CreateAsyncFfiCallback(isolate, zone, func, port, &list_head);
    EXPECT_EQ(allocated.count(tramp), 0u);
  }
}

VM_UNIT_TEST_CASE(FfiCallbackMetadata_DeleteTrampolines) {
  static constexpr int kCreations = 1000;
  static constexpr int kDeletions = 100;

  TestIsolateScope isolate_scope;
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate == isolate_scope.isolate());
  TransitionNativeToVM transition(thread);
  StackZone stack_zone(thread);
  HandleScope handle_scope(thread);

  auto* fcm = FfiCallbackMetadata::Instance();
  std::unordered_set<FfiCallbackMetadata::Trampoline> tramps;
  FfiCallbackMetadata::Metadata* list_head = nullptr;

  const auto& sync_func =
      Function::Handle(CreateTestFunction(FfiTrampolineKind::kSyncCallback));
  const auto& sync_code = Code::Handle(sync_func.EnsureHasCode());
  EXPECT(!sync_code.IsNull());

  // Create some callbacks.
  for (int itr = 0; itr < kCreations; ++itr) {
    tramps.insert(fcm->CreateSyncFfiCallback(isolate, thread->zone(), sync_func,
                                             &list_head));
  }

  // Delete some of the callbacks.
  for (int itr = 0; itr < kDeletions; ++itr) {
    auto tramp = *tramps.begin();
    fcm->DeleteCallback(tramp, &list_head);
    tramps.erase(tramp);
  }

  // Verify all the callbacks.
  for (FfiCallbackMetadata::Trampoline tramp : tramps) {
    auto metadata = fcm->LookupMetadataForTrampoline(tramp);
    EXPECT(metadata.IsLive());
    EXPECT_EQ(metadata.target_isolate(), isolate);
    EXPECT_EQ(static_cast<int>(metadata.trampoline_type()),
              static_cast<int>(FfiCallbackMetadata::TrampolineType::kSync));
    EXPECT_EQ(metadata.target_entry_point(), sync_code.EntryPoint());
  }

  // Verify the list of callbacks.
  uword list_length = 0;
  for (FfiCallbackMetadata::Metadata* m = list_head; m != nullptr;) {
    ++list_length;
    auto tramp = fcm->TrampolineOfMetadata(m);
    EXPECT(m->IsLive());
    EXPECT_EQ(m->target_isolate(), isolate);
    EXPECT_EQ(tramps.count(tramp), 1u);
    auto* next = m->list_next();
    auto* prev = m->list_prev();
    if (prev != nullptr) {
      EXPECT_EQ(prev->list_next(), m);
    } else {
      EXPECT_EQ(list_head, m);
    }
    if (next != nullptr) {
      EXPECT_EQ(next->list_prev(), m);
    }
    m = m->list_next();
  }
  EXPECT_EQ(list_length, tramps.size());

  // Delete all callbacks and verify they're destroyed.
  fcm->DeleteAllCallbacks(&list_head);
  EXPECT_EQ(list_head, nullptr);
  for (FfiCallbackMetadata::Trampoline tramp : tramps) {
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

  struct TrampolineWithPort {
    FfiCallbackMetadata::Trampoline tramp;
    Dart_Port port;
  };

  auto* fcm = FfiCallbackMetadata::Instance();
  Random random(seed);
  std::vector<TrampolineWithPort> tramps;
  std::unordered_set<FfiCallbackMetadata::Trampoline> tramp_set;
  FfiCallbackMetadata::Metadata* list_head = nullptr;

  const Function& async_func =
      Function::Handle(CreateTestFunction(FfiTrampolineKind::kAsyncCallback));
  const Code& async_code = Code::Handle(async_func.EnsureHasCode());
  EXPECT(!async_code.IsNull());
  const Function& sync_func =
      Function::Handle(CreateTestFunction(FfiTrampolineKind::kSyncCallback));
  const auto& sync_code = Code::Handle(sync_func.EnsureHasCode());
  EXPECT(!sync_code.IsNull());

  for (int itr = 0; itr < kIterations; ++itr) {
    // Do a random action:
    //  - Allocate a sync callback
    //  - Allocate an async callback
    //  - Delete a callback
    //  - Delete all the sync callbacks for an isolate

    if ((random.NextUInt32() % 100) == 0) {
      // 1% chance of deleting all the callbacks on the thread.
      fcm->DeleteAllCallbacks(&list_head);

      // It would be nice to verify that all the trampolines have been deleted,
      // but this is flaky because other threads can recycle these trampolines
      // before we finish checking all of them.
      tramps.clear();
      tramp_set.clear();
      EXPECT_EQ(list_head, nullptr);
    } else if (tramps.size() > 0 && (random.NextUInt32() % 4) == 0) {
      // 25% chance of deleting a callback.
      uint32_t r = random.NextUInt32() % tramps.size();
      auto tramp = tramps[r].tramp;
      fcm->DeleteCallback(tramp, &list_head);
      tramps[r] = tramps[tramps.size() - 1];
      tramps.pop_back();
      tramp_set.erase(tramp);
    } else {
      TrampolineWithPort tramp;
      if ((random.NextUInt32() % 2) == 0) {
        // 50% chance of creating a sync callback.
        tramp.port = ILLEGAL_PORT;
        tramp.tramp = fcm->CreateSyncFfiCallback(isolate, thread->zone(),
                                                 sync_func, &list_head);
      } else {
        // 50% chance of creating an async callback.
        tramp.port = PortMap::CreatePort(new FakeMessageHandler());
        tramp.tramp = fcm->CreateAsyncFfiCallback(
            isolate, thread->zone(), async_func, tramp.port, &list_head);
      }
      tramps.push_back(tramp);
      tramp_set.insert(tramp.tramp);
    }

    // Verify all the callbacks.
    for (const auto& tramp : tramps) {
      auto metadata = fcm->LookupMetadataForTrampoline(tramp.tramp);
      EXPECT(metadata.IsLive());
      EXPECT_EQ(metadata.target_isolate(), isolate);
      EXPECT_EQ(metadata.send_port(), tramp.port);
      if (metadata.trampoline_type() ==
          FfiCallbackMetadata::TrampolineType::kSync) {
        EXPECT_EQ(metadata.target_entry_point(), sync_code.EntryPoint());
      } else {
        EXPECT_EQ(metadata.target_entry_point(), async_code.EntryPoint());
      }
    }

    // Verify the isolate's list of callbacks.
    uword list_length = 0;
    for (FfiCallbackMetadata::Metadata* m = list_head; m != nullptr;) {
      ++list_length;
      auto tramp = fcm->TrampolineOfMetadata(m);
      EXPECT(m->IsLive());
      EXPECT_EQ(m->target_isolate(), isolate);
      EXPECT_EQ(tramp_set.count(tramp), 1u);
      m = m->list_next();
    }
    EXPECT_EQ(list_length, tramps.size());
    EXPECT_EQ(list_length, tramp_set.size());
  }

  // Delete all remaining callbacks.
  fcm->DeleteAllCallbacks(&list_head);
  EXPECT_EQ(list_head, nullptr);
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
