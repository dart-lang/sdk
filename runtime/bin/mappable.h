// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_MAPPABLE_H_
#define RUNTIME_BIN_MAPPABLE_H_

#include "platform/globals.h"

#include "bin/file.h"
#include "bin/virtual_memory.h"

namespace dart {
namespace bin {

class Mappable {
 public:
  static Mappable* FromPath(const char* path);
#if defined(DART_HOST_OS_FUCHSIA) || defined(DART_HOST_OS_LINUX)
  static Mappable* FromFD(int fd);
#endif
  static Mappable* FromMemory(const uint8_t* memory, size_t size);

  virtual MappedMemory* Map(File::MapType type,
                            uint64_t position,
                            uint64_t length,
                            void* start = nullptr) = 0;

  virtual bool SetPosition(uint64_t position) = 0;
  virtual bool ReadFully(void* dest, int64_t length) = 0;

  virtual ~Mappable() {}

 protected:
  Mappable() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(Mappable);
};

class FileMappable : public Mappable {
 public:
  explicit FileMappable(File* file) : Mappable(), file_(file) {}

  ~FileMappable() override { file_->Release(); }

  MappedMemory* Map(File::MapType type,
                    uint64_t position,
                    uint64_t length,
                    void* start = nullptr) override {
    return file_->Map(type, position, length, start);
  }

  bool SetPosition(uint64_t position) override {
    return file_->SetPosition(position);
  }

  bool ReadFully(void* dest, int64_t length) override {
    return file_->ReadFully(dest, length);
  }

 private:
  File* const file_;
  DISALLOW_COPY_AND_ASSIGN(FileMappable);
};

class MemoryMappable : public Mappable {
 public:
  MemoryMappable(const uint8_t* memory, size_t size)
      : Mappable(), memory_(memory), size_(size), position_(memory) {}

  ~MemoryMappable() override {}

  MappedMemory* Map(File::MapType type,
                    uint64_t position,
                    uint64_t length,
                    void* start = nullptr) override {
    if (position > size_) return nullptr;
    MappedMemory* result = nullptr;
    const uword map_size = Utils::RoundUp(length, VirtualMemory::PageSize());
    if (start == nullptr) {
      auto* memory = VirtualMemory::Allocate(
          map_size, type == File::kReadExecute, "dart-compiled-image");
      if (memory == nullptr) return nullptr;
      result = new MappedMemory(memory->address(), memory->size());
      memory->release();
      delete memory;
    } else {
      result = new MappedMemory(start, map_size,
                                /*should_unmap=*/false);
    }

    size_t remainder = 0;
    if ((position + length) > size_) {
      remainder = position + length - size_;
      length = size_ - position;
    }
    memcpy(result->address(), memory_ + position, length);  // NOLINT
    memset(reinterpret_cast<uint8_t*>(result->address()) + length, 0,
           remainder);

    auto mode = VirtualMemory::kReadOnly;
    switch (type) {
      case File::kReadExecute:
        mode = VirtualMemory::kReadExecute;
        break;
      case File::kReadWrite:
        mode = VirtualMemory::kReadWrite;
        break;
      case File::kReadOnly:
        mode = VirtualMemory::kReadOnly;
        break;
      default:
        UNREACHABLE();
    }

    VirtualMemory::Protect(result->address(), result->size(), mode);

    return result;
  }

  bool SetPosition(uint64_t position) override {
    if (position > size_) return false;
    position_ = memory_ + position;
    return true;
  }

  bool ReadFully(void* dest, int64_t length) override {
    if ((position_ + length) > (memory_ + size_)) return false;
    memcpy(dest, position_, length);
    return true;
  }

 private:
  const uint8_t* const memory_;
  const size_t size_;
  const uint8_t* position_;
  DISALLOW_COPY_AND_ASSIGN(MemoryMappable);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_MAPPABLE_H_
