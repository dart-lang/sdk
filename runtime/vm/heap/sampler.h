// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_SAMPLER_H_
#define RUNTIME_VM_HEAP_SAMPLER_H_

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

#include <atomic>

#include "include/dart_api.h"
#include "vm/allocation.h"
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

  // Enables or disables heap profiling for all threads.
  //
  // NOTE: the enabled state will update on a thread-by-thread basis once
  // the thread performs an interrupt check. There is no guarantee that the
  // enabled state will be updated for each thread by the time this method
  // returns.
  static void Enable(bool enabled);
  static bool enabled() { return enabled_; }

  // Updates the heap profiling sampling interval for all threads.
  //
  // NOTE: the sampling interval will update on a thread-by-thread basis once
  // the thread performs an interrupt check. There is no guarantee that the
  // sampling interval will be updated for each thread by the time this method
  // returns.
  static void SetSamplingInterval(intptr_t bytes_interval);

  // Updates the callback that's invoked when a sample is collected.
  static void SetSamplingCallback(
      Dart_HeapSamplingCreateCallback create_callback,
      Dart_HeapSamplingDeleteCallback delete_callback);

  static Dart_HeapSamplingDeleteCallback delete_callback() {
    return delete_callback_;
  }

  void Initialize();
  void Cleanup() {
    ResetState();
    last_sample_size_ = kUninitialized;
  }

  // Notifies the thread that it needs to update the enabled state of the heap
  // sampling profiler.
  //
  // This method is safe to call from any thread.
  void ScheduleUpdateThreadEnable();

  // Returns true if [ScheduleUpdateThreadEnable()] has been invoked.
  //
  // Calling this method will clear the state set by
  // [ScheduleUpdateThreadEnable()].
  //
  // This method is safe to call from any thread.
  bool ShouldUpdateThreadEnable() {
    return schedule_thread_enable_.exchange(false);
  }

  // Updates the enabled state of the thread's heap sampling profiler.
  //
  // WARNING: This method can only be called by the thread associated with this
  // profiler instance to avoid concurrent modification of the thread's TLAB.
  void UpdateThreadEnable();

  // Notifies the thread that it needs to update the sampling interval of its
  // heap sampling profiler.
  //
  // This method is safe to call from any thread.
  void ScheduleSetThreadSamplingInterval();

  // Returns true if [ScheduleSetThreadSamplingInterval()] has been invoked.
  //
  // Calling this method will clear the state set by
  // [ScheduleSetThreadEnable()].
  //
  // This method is safe to call from any thread.
  bool ShouldSetThreadSamplingInterval() {
    return schedule_thread_set_sampling_interval_.exchange(false);
  }

  // Updates the sampling interval of the thread's heap sampling profiler.
  //
  // WARNING: This method can only be called by the thread associated with this
  // profiler instance to avoid concurrent modification of the thread's TLAB.
  void SetThreadSamplingInterval();

  // Updates internal book keeping tracking the remaining size of the sampling
  // interval. This method must be called when a TLAB is torn down to ensure
  // that a future TLAB is initialized with the correct sampling interval.
  void HandleReleasedTLAB(Thread* thread);

  // Handles the creation of a new TLAB by updating its boundaries based on the
  // remaining sampling interval.
  //
  // is_first_tlab should be set to true if this is the first TLAB associated
  // with thread_ in order to correctly set the TLAB boundaries to match the
  // remaining sampling interval that's been used to keep track of old space
  // allocations.
  void HandleNewTLAB(intptr_t old_tlab_remaining_space, bool is_first_tlab);

  void* InvokeCallbackForLastSample(intptr_t cid);

  bool HasOutstandingSample() const {
    return last_sample_size_ != kUninitialized;
  }

  void SampleNewSpaceAllocation(intptr_t allocation_size);
  void SampleOldSpaceAllocation(intptr_t allocation_size);

 private:
  void ResetState();
  void ResetIntervalState() { interval_to_next_sample_ = kUninitialized; }

  void UpdateThreadEnableLocked();

  void SetThreadSamplingIntervalLocked();
  void SetNextSamplingIntervalLocked(intptr_t next_interval);

  intptr_t GetNextSamplingIntervalLocked();
  intptr_t NumberOfSamplesLocked(intptr_t allocation_size);

  // Helper to calculate the remaining sampling interval based on TLAB
  // boundaries. Returns kUninitialized if there's no active TLAB.
  intptr_t remaining_TLAB_interval() const;

  std::atomic<bool> schedule_thread_enable_ = false;
  std::atomic<bool> schedule_thread_set_sampling_interval_ = false;

  // Protects sampling logic from modifications of callback_, sampling_interval,
  // and enabled_ while collecting a sample.
  //
  // This lock should be acquired using WriteRwLocker when modifying static
  // state, and should be acquired using ReadRwLocker when accessing static
  // state from instances of HeapProfileSampler.
  static RwLock* lock_;
  static bool enabled_;
  static Dart_HeapSamplingCreateCallback create_callback_;
  static Dart_HeapSamplingDeleteCallback delete_callback_;
  static intptr_t sampling_interval_;

  static constexpr intptr_t kUninitialized = -1;
  static constexpr intptr_t kDefaultSamplingInterval = 512 * KB;

  bool thread_enabled_ = false;
  intptr_t interval_to_next_sample_ = kUninitialized;
  intptr_t next_tlab_offset_ = kUninitialized;
  intptr_t last_sample_size_ = kUninitialized;

  Thread* thread_;

  DISALLOW_COPY_AND_ASSIGN(HeapProfileSampler);
};

}  // namespace dart

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
#endif  // RUNTIME_VM_HEAP_SAMPLER_H_
