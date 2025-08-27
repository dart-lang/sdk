// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_THREAD_SANITIZER_H_
#define RUNTIME_PLATFORM_THREAD_SANITIZER_H_

#include "platform/globals.h"

#if __SANITIZE_THREAD__
#define USING_THREAD_SANITIZER
#elif defined(__has_feature)
#if __has_feature(thread_sanitizer)
#define USING_THREAD_SANITIZER
#endif
#endif

#if defined(USING_THREAD_SANITIZER)
#define NO_SANITIZE_THREAD __attribute__((no_sanitize("thread")))
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
extern "C" void __tsan_func_entry(void* pc);
extern "C" void __tsan_func_exit();
#else
#define NO_SANITIZE_THREAD
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

#endif  // RUNTIME_PLATFORM_THREAD_SANITIZER_H_
