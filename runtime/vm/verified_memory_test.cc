// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/verified_memory.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

void Init() {
#if defined(DEBUG)
  FLAG_verified_mem = true;
#endif
}

void Shutdown() {
#if defined(DEBUG)
  // We must reset this to false to avoid checking some assumptions in
  // VM shutdown that are left violated by these tests.
  FLAG_verified_mem = false;
#endif
}

VM_UNIT_TEST_CASE(VerifiedMemoryReserve) {
  Init();
  const intptr_t kReservationSize = 64 * KB;
  VirtualMemory* vm = VerifiedMemory::Reserve(kReservationSize);
  EXPECT_EQ(kReservationSize, vm->size());
  delete vm;
  Shutdown();
}

VM_UNIT_TEST_CASE(VerifiedMemoryCommit) {
  Init();
  const intptr_t kReservationSize = 64 * KB;
  VirtualMemory* vm = VerifiedMemory::Reserve(kReservationSize);
  EXPECT_EQ(kReservationSize, vm->size());
  vm->Commit(false);
  delete vm;
  Shutdown();
}

VM_UNIT_TEST_CASE(VerifiedMemoryBasic) {
  Init();
  const intptr_t kReservationSize = 64 * KB;
  VirtualMemory* vm = VerifiedMemory::Reserve(kReservationSize);
  EXPECT_EQ(kReservationSize, vm->size());
  vm->Commit(false);
  double* addr = reinterpret_cast<double*>(vm->address());
  VerifiedMemory::Write(&addr[0], 0.5);
  EXPECT_EQ(0.5, addr[0]);
  VerifiedMemory::Write(&addr[1], 1.5);
  VerifiedMemory::Write(&addr[2], 2.5);
  VerifiedMemory::Write(&addr[0], 0.25);
  static const double kNaN = NAN;
  VerifiedMemory::Write(&addr[0], kNaN);  // Bitwise comparison should be used.
  VerifiedMemory::Write(&addr[0], 0.5);
  int64_t* unverified = reinterpret_cast<int64_t*>(&addr[3]);
  *unverified = 123;
  VerifiedMemory::Verify(reinterpret_cast<uword>(addr), 3 * sizeof(double));
  delete vm;
  Shutdown();
}

VM_UNIT_TEST_CASE(VerifiedMemoryAccept) {
  Init();
  const intptr_t kReservationSize = 64 * KB;
  VirtualMemory* vm = VerifiedMemory::Reserve(kReservationSize);
  EXPECT_EQ(kReservationSize, vm->size());
  vm->Commit(false);
  double* addr = reinterpret_cast<double*>(vm->address());
  VerifiedMemory::Write(&addr[0], 0.5);
  VerifiedMemory::Write(&addr[1], 1.5);
  VerifiedMemory::Write(&addr[2], 2.5);
  VerifiedMemory::Write(&addr[0], 0.25);
  // Unverified write followed by Accept ("I know what I'm doing").
  memset(addr, 0xf3, 2 * sizeof(double));
  VerifiedMemory::Accept(reinterpret_cast<uword>(addr), 2 * sizeof(double));
  VerifiedMemory::Verify(reinterpret_cast<uword>(addr), 3 * sizeof(double));
  delete vm;
  Shutdown();
}

// Negative tests below.

VM_UNIT_TEST_CASE(VerifyImplicit_Crash) {
  Init();
  const intptr_t kReservationSize = 64 * KB;
  VirtualMemory* vm = VerifiedMemory::Reserve(kReservationSize);
  EXPECT_EQ(kReservationSize, vm->size());
  vm->Commit(false);
  double* addr = reinterpret_cast<double*>(vm->address());
  addr[0] = 0.5;  // Forget to use Write.
  VerifiedMemory::Write(&addr[0], 1.5);
  Shutdown();
}

VM_UNIT_TEST_CASE(VerifyExplicit_Crash) {
  Init();
  const intptr_t kReservationSize = 64 * KB;
  VirtualMemory* vm = VerifiedMemory::Reserve(kReservationSize);
  EXPECT_EQ(kReservationSize, vm->size());
  vm->Commit(false);
  double* addr = reinterpret_cast<double*>(vm->address());
  VerifiedMemory::Write(&addr[0], 0.5);
  VerifiedMemory::Write(&addr[1], 1.5);
  addr[1] = 3.5;  // Forget to use Write.
  VerifiedMemory::Write(&addr[2], 2.5);
  VerifiedMemory::Verify(reinterpret_cast<uword>(addr), 3 * sizeof(double));
  Shutdown();
}

}  // namespace dart
