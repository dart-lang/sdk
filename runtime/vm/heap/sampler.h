// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_SAMPLER_H_
#define RUNTIME_VM_HEAP_SAMPLER_H_

#if !defined(PRODUCT)

#include "include/dart_api.h"

#include "vm/globals.h"

namespace dart {

// Forward declarations.
class RwLock;
class Thread;

// Poisson sampler for memory allocations. We apply sampling individually to
// each byte. The whole allocation gets accounted as often as the number of
// sampled bytes it contains.
//
// Heavily inspired by Perfetto's Sampler class:
// https://source.chromium.org/chromium/chromium/src/+/531db6ec90bd7194d4d8064588966a0118d1495c:third_party/perfetto/src/profiling/memory/sampler.h;l=34
class HeapProfileSampler {
 public:
  explicit HeapProfileSampler(Thread* thread);

  static void Enable(bool enabled);

  static void SetSamplingInterval(intptr_t bytes_interval);

  static void SetSamplingCallback(Dart_HeapSamplingCallback callback);

  void Initialize();

  void HandleNewTLAB(intptr_t old_tlab_remaining_space);

  void InvokeCallbackForLastSample(Dart_PersistentHandle type_name,
                                   Dart_WeakPersistentHandle obj);

  bool HasOutstandingSample() const {
    return last_sample_size_ != kUninitialized;
  }

  // Returns number of bytes that should be be attributed to the sample.
  // If returned size is 0, the allocation should not be sampled.
  //
  // Due to how the poisson sampling works, some samples should be accounted
  // multiple times if they cover allocations larger than the average sampling
  // rate.
  void SampleSize(intptr_t allocation_size);

 private:
  void EnableLocked();
  void SetSamplingIntervalLocked();

  intptr_t SetNextSamplingIntervalLocked(intptr_t next_interval);

  intptr_t GetNextSamplingIntervalLocked();
  intptr_t NumberOfSamplesLocked(intptr_t allocation_size);

  // Protects sampling logic from modifications of callback_, sampling_interval,
  // and enabled_ while collecting a sample.
  static RwLock* lock_;
  static bool enabled_;
  static Dart_HeapSamplingCallback callback_;
  static intptr_t sampling_interval_;

  static const intptr_t kUninitialized = -1;
  static const intptr_t kDefaultSamplingInterval = 512 * KB;

  intptr_t interval_to_next_sample_;
  intptr_t next_tlab_offset_ = kUninitialized;
  intptr_t last_sample_size_ = kUninitialized;

  Thread* thread_;

  DISALLOW_COPY_AND_ASSIGN(HeapProfileSampler);
};

}  // namespace dart

#endif  // !defined(PRODUCT)
#endif  // RUNTIME_VM_HEAP_SAMPLER_H_
