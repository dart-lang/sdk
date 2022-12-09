// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(PRODUCT)

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

namespace dart {

bool HeapProfileSampler::enabled_ = false;
Dart_HeapSamplingCallback HeapProfileSampler::callback_ = nullptr;
RwLock* HeapProfileSampler::lock_ = new RwLock();
intptr_t HeapProfileSampler::sampling_interval_ =
    HeapProfileSampler::kDefaultSamplingInterval;

HeapProfileSampler::HeapProfileSampler(Thread* thread)
    : interval_to_next_sample_(kUninitialized), thread_(thread) {}

void HeapProfileSampler::Enable(bool enabled) {
  WriteRwLocker locker(Thread::Current(), lock_);
  enabled_ = enabled;
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->thread_registry()->ForEachThread(
        [&](Thread* thread) { thread->heap_sampler().EnableLocked(); });
  });
}

void HeapProfileSampler::SetSamplingInterval(intptr_t bytes_interval) {
  WriteRwLocker locker(Thread::Current(), lock_);
  ASSERT(bytes_interval >= 0);
  sampling_interval_ = bytes_interval;
  if (!enabled_) {
    return;
  }
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->thread_registry()->ForEachThread([&](Thread* thread) {
      thread->heap_sampler().SetSamplingIntervalLocked();
    });
  });
}

void HeapProfileSampler::SetSamplingCallback(
    Dart_HeapSamplingCallback callback) {
  // Protect against the callback being changed in the middle of a sample.
  WriteRwLocker locker(Thread::Current(), lock_);
  callback_ = callback;
}

void HeapProfileSampler::Initialize() {
  ReadRwLocker locker(Thread::Current(), lock_);
  EnableLocked();
}

void HeapProfileSampler::EnableLocked() {
  if (enabled_) {
    SetNextSamplingIntervalLocked(GetNextSamplingIntervalLocked());
  } else {
    // Reset the TLAB boundaries to the true end to avoid unnecessary slow
    // path invocations when sampling is disabled.
    thread_->set_end(thread_->true_end());
    next_tlab_offset_ = kUninitialized;
  }
}

void HeapProfileSampler::SetSamplingIntervalLocked() {
  // Force reset the next sampling point.
  thread_->set_end(thread_->true_end());
  SetNextSamplingIntervalLocked(GetNextSamplingIntervalLocked());
}

void HeapProfileSampler::HandleNewTLAB(intptr_t old_tlab_remaining_space) {
  ReadRwLocker locker(thread_, lock_);
  if (!enabled_ || next_tlab_offset_ == kUninitialized) {
    return;
  }
  intptr_t updated_offset = next_tlab_offset_ + old_tlab_remaining_space;
  if (updated_offset + thread_->top() > thread_->true_end()) {
    // The next sampling point isn't in this TLAB.
    next_tlab_offset_ = updated_offset - (thread_->true_end() - thread_->top());
    thread_->set_end(thread_->true_end());
  } else {
    ASSERT(updated_offset <= static_cast<intptr_t>(thread_->true_end()) -
                                 static_cast<intptr_t>(thread_->top()));
    thread_->set_end(updated_offset + thread_->top());
    next_tlab_offset_ = kUninitialized;
  }
}

void HeapProfileSampler::InvokeCallbackForLastSample(
    Dart_PersistentHandle type_name,
    Dart_WeakPersistentHandle obj) {
  ReadRwLocker locker(thread_, lock_);
  if (!enabled_) {
    return;
  }
  if (callback_ != nullptr) {
    callback_(
        reinterpret_cast<void*>(thread_->isolate_group()->embedder_data()),
        type_name, obj, last_sample_size_);
  }
  last_sample_size_ = kUninitialized;
}

void HeapProfileSampler::SampleSize(intptr_t allocation_size) {
  ReadRwLocker locker(thread_, lock_);
  if (!enabled_) {
    return;
  }
  // We should never be sampling an allocation that won't fit in the
  // current TLAB.
  ASSERT(allocation_size <=
         static_cast<intptr_t>(thread_->true_end() - thread_->top()));

  ASSERT(sampling_interval_ >= 0);
  if (UNLIKELY(allocation_size >= sampling_interval_)) {
    last_sample_size_ = allocation_size;
    // Reset the sampling interval, but only count the sample once.
    NumberOfSamplesLocked(allocation_size);
    return;
  }
  last_sample_size_ =
      sampling_interval_ * NumberOfSamplesLocked(allocation_size);
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

intptr_t HeapProfileSampler::SetNextSamplingIntervalLocked(
    intptr_t next_interval) {
  intptr_t new_end = thread_->end();
  const intptr_t top = static_cast<intptr_t>(thread_->top());
  const intptr_t true_end = static_cast<intptr_t>(thread_->true_end());
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
  return next_interval;
}

}  // namespace dart

#endif  // !defined(PRODUCT)
