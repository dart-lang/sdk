// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

#include <math.h>
#include <algorithm>

#include "vm/heap/safepoint.h"
#include "vm/heap/sampler.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/os.h"
#include "vm/random.h"
#include "vm/thread.h"
#include "vm/thread_registry.h"

#define ASSERT_TLAB_BOUNDARIES_VALID(__thread)                                 \
  do {                                                                         \
    ASSERT(__thread->top() <= __thread->end());                                \
    ASSERT(__thread->end() <= __thread->true_end());                           \
    if (next_tlab_offset_ != kUninitialized) {                                 \
      ASSERT(__thread->end() == __thread->true_end());                         \
      ASSERT(next_tlab_offset_ > 0);                                           \
    }                                                                          \
  } while (0)

#define ASSERT_THREAD_STATE(__thread)                                          \
  do {                                                                         \
    Thread* __cur = Thread::Current();                                         \
    ASSERT(__cur == nullptr || __cur == __thread);                             \
  } while (0)

namespace dart {

bool HeapProfileSampler::enabled_ = false;
Dart_HeapSamplingCreateCallback HeapProfileSampler::create_callback_ = nullptr;
Dart_HeapSamplingDeleteCallback HeapProfileSampler::delete_callback_ = nullptr;
RwLock* HeapProfileSampler::lock_ = new RwLock();
intptr_t HeapProfileSampler::sampling_interval_ =
    HeapProfileSampler::kDefaultSamplingInterval;

HeapProfileSampler::HeapProfileSampler(Thread* thread)
    : interval_to_next_sample_(kUninitialized), thread_(thread) {}

void HeapProfileSampler::Enable(bool enabled) {
  // Don't try and change enabled state if sampler instances are currently
  // doing work.
  WriteRwLocker locker(Thread::Current(), lock_);
  enabled_ = enabled;

  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->thread_registry()->ForEachThread([&](Thread* thread) {
      thread->heap_sampler().ScheduleUpdateThreadEnable();
    });
  });
}

void HeapProfileSampler::SetSamplingInterval(intptr_t bytes_interval) {
  // Don't try and change sampling interval state if sampler instances are
  // currently doing work.
  WriteRwLocker locker(Thread::Current(), lock_);
  ASSERT(bytes_interval >= 0);
  sampling_interval_ = bytes_interval;

  // The sampling interval will be set in each thread once sampling is enabled.
  if (!enabled_) {
    return;
  }

  // If sampling is enabled, notify each thread that it should update its
  // sampling interval.
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->thread_registry()->ForEachThread([&](Thread* thread) {
      thread->heap_sampler().ScheduleSetThreadSamplingInterval();
    });
  });
}

void HeapProfileSampler::SetSamplingCallback(
    Dart_HeapSamplingCreateCallback create_callback,
    Dart_HeapSamplingDeleteCallback delete_callback) {
  // Protect against the callback being changed in the middle of a sample.
  WriteRwLocker locker(Thread::Current(), lock_);
  if ((create_callback_ != nullptr && create_callback == nullptr) ||
      (delete_callback_ != nullptr && delete_callback == nullptr)) {
    FATAL("Clearing sampling callbacks is prohibited.");
  }
  create_callback_ = create_callback;
  delete_callback_ = delete_callback;
}

void HeapProfileSampler::ResetState() {
  thread_->set_end(thread_->true_end());
  next_tlab_offset_ = kUninitialized;
  ResetIntervalState();
  ASSERT_TLAB_BOUNDARIES_VALID(thread_);
}

void HeapProfileSampler::Initialize() {
  // Don't grab lock_ here as it can cause a deadlock if thread initialization
  // occurs when the profiler state is being changed. Instead, let the thread
  // perform initialization when it's no longer holding the thread registry's
  // thread_lock().
  ScheduleUpdateThreadEnable();
}

void HeapProfileSampler::ScheduleUpdateThreadEnable() {
  schedule_thread_enable_ = true;
  thread_->ScheduleInterrupts(Thread::kVMInterrupt);
}

void HeapProfileSampler::UpdateThreadEnable() {
  ASSERT_THREAD_STATE(thread_);
  ReadRwLocker locker(Thread::Current(), lock_);
  UpdateThreadEnableLocked();
}

void HeapProfileSampler::UpdateThreadEnableLocked() {
  thread_enabled_ = enabled_;
  if (thread_enabled_) {
    SetNextSamplingIntervalLocked(GetNextSamplingIntervalLocked());
  } else {
    // Reset the TLAB boundaries to the true end to avoid unnecessary slow
    // path invocations when sampling is disabled.
    ResetState();
  }
}

void HeapProfileSampler::ScheduleSetThreadSamplingInterval() {
  schedule_thread_set_sampling_interval_ = true;
  thread_->ScheduleInterrupts(Thread::kVMInterrupt);
}

void HeapProfileSampler::SetThreadSamplingInterval() {
  ASSERT_THREAD_STATE(thread_);
  ReadRwLocker locker(thread_, lock_);
  SetThreadSamplingIntervalLocked();
}

void HeapProfileSampler::SetThreadSamplingIntervalLocked() {
  // Don't try and update the sampling interval if the sampler isn't enabled for
  // this thread. Otherwise, we'll get into an inconsistent state.
  if (!thread_enabled_) {
    return;
  }
  // Force reset the next sampling point.
  ResetState();
  SetNextSamplingIntervalLocked(GetNextSamplingIntervalLocked());
}

void HeapProfileSampler::HandleReleasedTLAB(Thread* thread) {
  ReadRwLocker locker(thread, lock_);
  if (!enabled_) {
    return;
  }
  interval_to_next_sample_ = remaining_TLAB_interval();
  next_tlab_offset_ = kUninitialized;
}

void HeapProfileSampler::HandleNewTLAB(intptr_t old_tlab_remaining_space,
                                       bool is_first_tlab) {
  ASSERT_THREAD_STATE(thread_);
  ReadRwLocker locker(thread_, lock_);
  if (!enabled_ || (next_tlab_offset_ == kUninitialized && !is_first_tlab)) {
    return;
  } else if (is_first_tlab) {
    ASSERT(next_tlab_offset_ == kUninitialized);
    if (interval_to_next_sample_ != kUninitialized) {
      intptr_t top = thread_->top();
      intptr_t tlab_size = thread_->true_end() - top;
      if (tlab_size >= interval_to_next_sample_) {
        thread_->set_end(top + interval_to_next_sample_);
        ASSERT_TLAB_BOUNDARIES_VALID(thread_);
      } else {
        next_tlab_offset_ = interval_to_next_sample_ - tlab_size;
        ASSERT_TLAB_BOUNDARIES_VALID(thread_);
      }
    } else {
      SetThreadSamplingIntervalLocked();
    }
    return;
  }
  intptr_t updated_offset = next_tlab_offset_ + old_tlab_remaining_space;
  if (updated_offset + thread_->top() > thread_->true_end()) {
    // The next sampling point isn't in this TLAB.
    next_tlab_offset_ = updated_offset - (thread_->true_end() - thread_->top());
    thread_->set_end(thread_->true_end());
    ASSERT_TLAB_BOUNDARIES_VALID(thread_);
  } else {
    ASSERT(updated_offset <= static_cast<intptr_t>(thread_->true_end()) -
                                 static_cast<intptr_t>(thread_->top()));
    thread_->set_end(updated_offset + thread_->top());
    next_tlab_offset_ = kUninitialized;
    ASSERT_TLAB_BOUNDARIES_VALID(thread_);
  }
}

void* HeapProfileSampler::InvokeCallbackForLastSample(intptr_t cid) {
  ASSERT(enabled_);
  ASSERT(create_callback_ != nullptr);
  ReadRwLocker locker(thread_, lock_);
  ClassTable* table = IsolateGroup::Current()->class_table();
  void* result = create_callback_(
      reinterpret_cast<Dart_Isolate>(thread_->isolate()),
      reinterpret_cast<Dart_IsolateGroup>(thread_->isolate_group()),
      table->UserVisibleNameFor(cid), last_sample_size_);
  last_sample_size_ = kUninitialized;
  return result;
}

void HeapProfileSampler::SampleNewSpaceAllocation(intptr_t allocation_size) {
  ReadRwLocker locker(thread_, lock_);
  if (!enabled_) {
    return;
  }
  // We should never be sampling an allocation that won't fit in the
  // current TLAB.
  ASSERT(allocation_size <=
         static_cast<intptr_t>(thread_->true_end() - thread_->top()));
  ASSERT(sampling_interval_ >= 0);

  // Clean up interval state in preparation for a new interval.
  ResetIntervalState();

  if (UNLIKELY(allocation_size >= sampling_interval_)) {
    last_sample_size_ = allocation_size;
    // Reset the sampling interval, but only count the sample once.
    NumberOfSamplesLocked(allocation_size);
    return;
  }
  last_sample_size_ =
      sampling_interval_ * NumberOfSamplesLocked(allocation_size);
}

void HeapProfileSampler::SampleOldSpaceAllocation(intptr_t allocation_size) {
  ASSERT_THREAD_STATE(thread_);
  ReadRwLocker locker(thread_, lock_);
  if (!enabled_) {
    return;
  }
  ASSERT(sampling_interval_ >= 0);
  // Account for any new space allocations that have happened since we last
  // updated the sampling interval statistic.
  intptr_t tlab_interval = remaining_TLAB_interval();
  if (tlab_interval != kUninitialized) {
    interval_to_next_sample_ = tlab_interval;
  }

  // Check the allocation is large enough to trigger a sample. If not, tighten
  // the interval.
  if (allocation_size < interval_to_next_sample_) {
    intptr_t end = static_cast<intptr_t>(thread_->end());
    const intptr_t orig_end = end;
    const intptr_t true_end = static_cast<intptr_t>(thread_->true_end());
    const intptr_t orig_tlab_offset = next_tlab_offset_;
    USE(orig_tlab_offset);
    USE(orig_end);
    // We may not have a TLAB, don't pull one out of thin air.
    if (end != 0) {
      if (next_tlab_offset_ != kUninitialized) {
        end += next_tlab_offset_;
        next_tlab_offset_ = kUninitialized;
      }

      end += allocation_size;
      if (end > true_end) {
        thread_->set_end(true_end);
        next_tlab_offset_ = end - true_end;
        ASSERT_TLAB_BOUNDARIES_VALID(thread_);
      } else {
        thread_->set_end(end);
        ASSERT_TLAB_BOUNDARIES_VALID(thread_);
      }
    }
    interval_to_next_sample_ -= allocation_size;
    ASSERT(interval_to_next_sample_ > 0);
    return;
  }
  // Clean up interval state in preparation for a new interval.
  ResetIntervalState();

  // Find a new sampling point and reset TLAB boundaries.
  SetThreadSamplingIntervalLocked();
  last_sample_size_ = allocation_size;
}

// Determines the next sampling interval by sampling from a poisson
intptr_t HeapProfileSampler::GetNextSamplingIntervalLocked() {
  ASSERT(thread_->isolate_group() != nullptr);
  double u = thread_->isolate_group()->random()->NextDouble();
  ASSERT(u >= 0.0 && u <= 1.0);
  // Approximate sampling from a poisson distribution using an exponential
  // distribution. We take the sample by feeding in a random uniform value in
  // the range [0,1] to the inverse of the exponential CDF.
  double next = -log(1 - u) * sampling_interval_;
  ASSERT(next > 0);
  // + 1 since the sample implies the number of "failures" before the next
  // success, which should be included in our interval.
  return std::max(kObjectAlignment, static_cast<intptr_t>(next) + 1);
}

intptr_t HeapProfileSampler::NumberOfSamplesLocked(intptr_t allocation_size) {
  // There's always at least a single sample if we've reached this point.
  intptr_t sample_count = 1;

  intptr_t next_interval = GetNextSamplingIntervalLocked();
  intptr_t total_next_interval = next_interval;

  // The remaining portion of the allocation that hasn't been accounted for yet.
  intptr_t remaining_size =
      allocation_size - static_cast<intptr_t>(thread_->end() - thread_->top());
  while (remaining_size > 0) {
    if (remaining_size > next_interval) {
      // The allocation is large enough to be counted again.
      sample_count++;
    }
    remaining_size =
        std::max(remaining_size - next_interval, static_cast<intptr_t>(0));
    next_interval = GetNextSamplingIntervalLocked();
    total_next_interval += next_interval;
  }

  // Update the TLAB boundary to account for the potential multiple samples
  // the last allocation generated.
  SetNextSamplingIntervalLocked(total_next_interval);

  return sample_count;
}

intptr_t HeapProfileSampler::remaining_TLAB_interval() const {
  if (thread_->end() == 0) {
    return kUninitialized;
  }
  intptr_t remaining = thread_->end() - thread_->top();
  if (next_tlab_offset_ != kUninitialized) {
    remaining += next_tlab_offset_;
  }
  return remaining;
}

void HeapProfileSampler::SetNextSamplingIntervalLocked(intptr_t next_interval) {
  ASSERT_THREAD_STATE(thread_);
  intptr_t new_end = thread_->end();
  const intptr_t top = static_cast<intptr_t>(thread_->top());
  const intptr_t true_end = static_cast<intptr_t>(thread_->true_end());
  // Don't create a TLAB out of thin air if one doesn't exist.
  if (true_end != 0) {
    if (new_end == true_end) {
      // Sampling was likely just enabled.
      new_end = top;
    }
    new_end += next_interval;

    if (new_end > true_end) {
      // The next sampling point is in the next TLAB.
      ASSERT(next_tlab_offset_ == kUninitialized);
      next_tlab_offset_ = new_end - true_end;
      new_end = true_end;
    }
    ASSERT(top <= new_end);
    thread_->set_end(new_end);
    ASSERT_TLAB_BOUNDARIES_VALID(thread_);
  }
  interval_to_next_sample_ = next_interval;
}

}  // namespace dart

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
