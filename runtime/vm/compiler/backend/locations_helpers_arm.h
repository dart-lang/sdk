// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains few helpful marker types that can be used with
// MakeLocationSummaryFromEmitter and InvokeEmitter to simplify writing
// of ARM code.

#ifndef RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_HELPERS_ARM_H_
#define RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_HELPERS_ARM_H_

namespace dart {

// QRegisterView is a wrapper around QRegister that provides helpers for
// accessing S and D components.
class QRegisterView {
 public:
  explicit QRegisterView(QRegister reg) : reg_(reg) {}

  operator QRegister() const { return reg_; }

  inline DRegister d(intptr_t i) const {
    ASSERT(0 <= i && i < 2);
    return static_cast<DRegister>(reg_ * 2 + i);
  }

  inline SRegister s(intptr_t i) const {
    ASSERT(0 <= i && i < 4);
    ASSERT(reg_ <= Q7);
    return static_cast<SRegister>(reg_ * 4 + i);
  }

 private:
  QRegister reg_;
};

// FixedQRegisterView<r> is a handy replacement for Fixed<QRegister, r> that
// provides helpers for accessing S and D components.
//
// Note: this class is provided because Fixed<QRegisterView, r> is not a valid
// type.
template <QRegister reg>
class FixedQRegisterView {
 public:
  inline DRegister d(intptr_t i) const {
    return static_cast<DRegister>(reg * 2 + i);
  }

  inline SRegister s(intptr_t i) const {
    return static_cast<SRegister>(reg * 4 + i);
  }

  operator QRegister() const { return reg; }
};

template <>
struct LocationTrait<QRegisterView> {
  static const bool kIsTemp = false;

  static QRegisterView Unwrap(const Location& loc) {
    return QRegisterView(loc.fpu_reg());
  }

  template <intptr_t arity, intptr_t index>
  static QRegisterView UnwrapInput(LocationSummary* locs) {
    return Unwrap(locs->in(index));
  }

  template <intptr_t arity, intptr_t index>
  static void SetInputConstraint(LocationSummary* locs) {
    locs->set_in(index, ToConstraint());
  }

  static Location ToConstraint() { return Location::RequiresFpuRegister(); }
};

template <QRegister reg>
struct LocationTrait<FixedQRegisterView<reg> > {
  static const bool kIsTemp = false;

  static FixedQRegisterView<reg> Unwrap(const Location& loc) {
    ASSERT(LocationTrait<QRegister>::Unwrap(loc) == reg);
    return FixedQRegisterView<reg>();
  }

  template <intptr_t arity, intptr_t index>
  static FixedQRegisterView<reg> UnwrapInput(LocationSummary* locs) {
    return Unwrap(locs->in(index));
  }

  template <intptr_t arity, intptr_t index>
  static void SetInputConstraint(LocationSummary* locs) {
    locs->set_in(index, ToConstraint());
  }

  static Location ToConstraint() { return Location::FpuRegisterLocation(reg); }
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_HELPERS_ARM_H_
