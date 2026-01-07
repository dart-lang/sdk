// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_THREAD_SANITIZER_H_
#define RUNTIME_PLATFORM_THREAD_SANITIZER_H_

#include "platform/allocation.h"
#include "platform/globals.h"

#if __SANITIZE_THREAD__
#define USING_THREAD_SANITIZER
#elif defined(__has_feature)
#if __has_feature(thread_sanitizer)
#define USING_THREAD_SANITIZER
#endif
#endif

#if defined(USING_THREAD_SANITIZER)
#define NO_SANITIZE_THREAD __attribute__((no_sanitize_thread))
#if defined(__clang__)
#define DISABLE_SANITIZER_INSTRUMENTATION                                      \
  __attribute__((disable_sanitizer_instrumentation))
#else
#define DISABLE_SANITIZER_INSTRUMENTATION
#endif

extern "C" uint32_t __tsan_atomic32_load(uint32_t* addr, int order);
extern "C" void __tsan_atomic32_store(uint32_t* addr,
                                      uint32_t value,
                                      int order);
extern "C" uint64_t __tsan_atomic64_load(uint64_t* addr, int order);
extern "C" void __tsan_atomic64_store(uint64_t* addr,
                                      uint64_t value,
                                      int order);
extern "C" void __tsan_read1(void* addr);
extern "C" void __tsan_read2(void* addr);
extern "C" void __tsan_read4(void* addr);
extern "C" void __tsan_read8(void* addr);
extern "C" void __tsan_read16(void* addr);
extern "C" void __tsan_write1(void* addr);
extern "C" void __tsan_write2(void* addr);
extern "C" void __tsan_write4(void* addr);
extern "C" void __tsan_write8(void* addr);
extern "C" void __tsan_write16(void* addr);
extern "C" void __tsan_read1_pc(void* addr, void* pc);
extern "C" void __tsan_read2_pc(void* addr, void* pc);
extern "C" void __tsan_read4_pc(void* addr, void* pc);
extern "C" void __tsan_read8_pc(void* addr, void* pc);
extern "C" void __tsan_read16_pc(void* addr, void* pc);
extern "C" void __tsan_write1_pc(void* addr, void* pc);
extern "C" void __tsan_write2_pc(void* addr, void* pc);
extern "C" void __tsan_write4_pc(void* addr, void* pc);
extern "C" void __tsan_write8_pc(void* addr, void* pc);
extern "C" void __tsan_write16_pc(void* addr, void* pc);
extern "C" void __tsan_func_entry(void* pc);
extern "C" void __tsan_func_exit();
extern "C" void __tsan_ignore_thread_begin();
extern "C" void __tsan_ignore_thread_end();
constexpr uintptr_t kExternalPCBit = 1ULL << 60;
#else
#define NO_SANITIZE_THREAD
#define DISABLE_SANITIZER_INSTRUMENTATION
#endif

#if defined(USING_THREAD_SANITIZER)
#define DO_IF_TSAN(CODE) CODE
#else
#define DO_IF_TSAN(CODE)
#endif

#if defined(USING_THREAD_SANITIZER)
#define DO_IF_NOT_TSAN(CODE)
#else
#define DO_IF_NOT_TSAN(CODE) CODE
#endif

namespace dart {

class TsanIgnoreScope : public ValueObject {
 public:
  TsanIgnoreScope() {
#if defined(USING_THREAD_SANITIZER)
    __tsan_ignore_thread_begin();
#endif
  }
  ~TsanIgnoreScope() {
#if defined(USING_THREAD_SANITIZER)
    __tsan_ignore_thread_end();
#endif
  }
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_THREAD_SANITIZER_H_
