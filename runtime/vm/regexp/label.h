// Copyright 2017 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_CODEGEN_LABEL_H_
#define V8_CODEGEN_LABEL_H_

#include "vm/object.h"
#include "vm/regexp/base.h"

namespace dart {

class V8Label {
 public:
  enum Distance {
    kNear,  // near jump: 8 bit displacement (signed)
    kFar    // far jump: 32 bit displacement (signed)
  };

  V8Label() = default;

  // Disallow copy construction and assignment, but allow move construction and
  // move assignment on selected platforms (see below).
  V8Label(const V8Label&) = delete;
  V8Label& operator=(const V8Label&) = delete;

// On ARM64, the Assembler keeps track of pointers to V8Labels to resolve
// branches to distant targets. Copying labels would confuse the Assembler.
// On other platforms, allow move construction.
#if !V8_TARGET_ARCH_ARM64
// In debug builds, the old V8Label has to be cleared in order to avoid a DCHECK
// failure in it's destructor.
#ifdef DEBUG
  V8Label(V8Label&& other) V8_NOEXCEPT { *this = std::move(other); }
  V8Label& operator=(V8Label&& other) V8_NOEXCEPT {
    pos_ = other.pos_;
    near_link_pos_ = other.near_link_pos_;
    other.Unuse();
    other.UnuseNear();
    return *this;
  }
#else
  V8Label(V8Label&&) V8_NOEXCEPT = default;
  V8Label& operator=(V8Label&&) V8_NOEXCEPT = default;
#endif
#endif

#ifdef DEBUG
  V8_INLINE ~V8Label() {
    DCHECK(!is_linked());
    DCHECK(!is_near_linked());
  }
#endif

  V8_INLINE void Unuse() { pos_ = 0; }
  V8_INLINE void UnuseNear() { near_link_pos_ = 0; }

  V8_INLINE bool is_bound() const { return pos_ < 0; }
  V8_INLINE bool is_unused() const { return pos_ == 0 && near_link_pos_ == 0; }
  V8_INLINE bool is_linked() const { return pos_ > 0; }
  V8_INLINE bool is_near_linked() const { return near_link_pos_ > 0; }

  // Returns the position of bound or linked labels. Cannot be used
  // for unused labels.
  int pos() const {
    if (pos_ < 0) return -pos_ - 1;
    if (pos_ > 0) return pos_ - 1;
    UNREACHABLE();
  }

  int near_link_pos() const { return near_link_pos_ - 1; }

 private:
  // pos_ encodes both the binding state (via its sign)
  // and the binding position (via its value) of a label.
  //
  // pos_ <  0  bound label, pos() returns the jump target position
  // pos_ == 0  unused label
  // pos_ >  0  linked label, pos() returns the last reference position
  int pos_ = 0;

  // Behaves like |pos_| in the "> 0" case, but for near jumps to this label.
  int near_link_pos_ = 0;

  void bind_to(int pos) {
    pos_ = -pos - 1;
    DCHECK(is_bound());
  }
  void link_to(int pos, Distance distance = kFar) {
    if (distance == kNear) {
      near_link_pos_ = pos + 1;
      DCHECK(is_near_linked());
    } else {
      pos_ = pos + 1;
      DCHECK(is_linked());
    }
  }

  friend class Assembler;
  friend class Displacement;
  friend class RegExpBytecodeGenerator;
  friend class RegExpBytecodeWriter;
};

}  // namespace dart

#endif  // V8_CODEGEN_LABEL_H_
