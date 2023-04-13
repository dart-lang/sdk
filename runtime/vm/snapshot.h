// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SNAPSHOT_H_
#define RUNTIME_VM_SNAPSHOT_H_

#include <memory>
#include <utility>

#include "platform/assert.h"
#include "platform/unaligned.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/message.h"
#include "vm/thread.h"

namespace dart {

// Structure capturing the raw snapshot.
//
class Snapshot {
 public:
  enum Kind {
    kFull,      // Full snapshot of an application.
    kFullCore,  // Full snapshot of core libraries. Agnostic to null safety.
    kFullJIT,   // Full + JIT code
    kFullAOT,   // Full + AOT code
    kNone,      // gen_snapshot
    kInvalid
  };
  static const char* KindToCString(Kind kind);

  static const Snapshot* SetupFromBuffer(const void* raw_memory);

  static constexpr int32_t kMagicValue = 0xdcdcf5f5;
  static constexpr intptr_t kMagicOffset = 0;
  static constexpr intptr_t kMagicSize = sizeof(int32_t);
  static constexpr intptr_t kLengthOffset = kMagicOffset + kMagicSize;
  static constexpr intptr_t kLengthSize = sizeof(int64_t);
  static constexpr intptr_t kKindOffset = kLengthOffset + kLengthSize;
  static constexpr intptr_t kKindSize = sizeof(int64_t);
  static constexpr intptr_t kHeaderSize = kKindOffset + kKindSize;

  // Accessors.
  bool check_magic() const {
    return Read<int32_t>(kMagicOffset) == kMagicValue;
  }
  void set_magic() { return Write<int32_t>(kMagicOffset, kMagicValue); }
  // Excluding the magic value from the size written in the buffer is needed
  // so we give a proper version mismatch error for snapshots create before
  // magic value was written by the VM instead of the embedder.
  int64_t large_length() const {
    return Read<int64_t>(kLengthOffset) + kMagicSize;
  }
  intptr_t length() const { return static_cast<intptr_t>(large_length()); }
  void set_length(intptr_t value) {
    return Write<int64_t>(kLengthOffset, value - kMagicSize);
  }
  Kind kind() const { return static_cast<Kind>(Read<int64_t>(kKindOffset)); }
  void set_kind(Kind value) { return Write<int64_t>(kKindOffset, value); }

  static bool IsFull(Kind kind) {
    return (kind == kFull) || (kind == kFullCore) || (kind == kFullJIT) ||
           (kind == kFullAOT);
  }
  static bool IsAgnosticToNullSafety(Kind kind) { return (kind == kFullCore); }
  static bool IncludesCode(Kind kind) {
    return (kind == kFullJIT) || (kind == kFullAOT);
  }

  static bool IncludesStringsInROData(Kind kind) {
#if !defined(DART_COMPRESSED_POINTERS)
    return IncludesCode(kind);
#else
    return false;
#endif
  }

  const uint8_t* Addr() const { return reinterpret_cast<const uint8_t*>(this); }

  const uint8_t* DataImage() const {
    if (!IncludesCode(kind())) {
      return nullptr;
    }
    uword offset = Utils::RoundUp(length(), kObjectStartAlignment);
    return Addr() + offset;
  }

 private:
  // Prevent Snapshot from ever being allocated directly.
  Snapshot();

  template <typename T>
  T Read(intptr_t offset) const {
    return LoadUnaligned(
        reinterpret_cast<const T*>(reinterpret_cast<uword>(this) + offset));
  }

  template <typename T>
  void Write(intptr_t offset, T value) {
    return StoreUnaligned(
        reinterpret_cast<T*>(reinterpret_cast<uword>(this) + offset), value);
  }

  DISALLOW_COPY_AND_ASSIGN(Snapshot);
};

inline static bool IsSnapshotCompatible(Snapshot::Kind vm_kind,
                                        Snapshot::Kind isolate_kind) {
  if (vm_kind == isolate_kind) return true;
  if (((vm_kind == Snapshot::kFull) || (vm_kind == Snapshot::kFullCore)) &&
      isolate_kind == Snapshot::kFullJIT)
    return true;
  return Snapshot::IsFull(isolate_kind);
}

class SerializedObjectBuffer : public StackResource {
 public:
  SerializedObjectBuffer()
      : StackResource(Thread::Current()), message_(nullptr) {}

  void set_message(std::unique_ptr<Message> message) {
    ASSERT(message_ == nullptr);
    message_ = std::move(message);
  }
  std::unique_ptr<Message> StealMessage() { return std::move(message_); }

 private:
  std::unique_ptr<Message> message_;
};

}  // namespace dart

#endif  // RUNTIME_VM_SNAPSHOT_H_
