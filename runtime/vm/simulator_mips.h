// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declares a Simulator for MIPS instructions if we are not generating a native
// MIPS binary. This Simulator allows us to run and debug MIPS code generation
// on regular desktop machines.
// Dart calls into generated code by "calling" the InvokeDartCode stub,
// which will start execution in the Simulator or forwards to the real entry
// on a MIPS HW platform.

#ifndef VM_SIMULATOR_MIPS_H_
#define VM_SIMULATOR_MIPS_H_

#ifndef VM_SIMULATOR_H_
#error Do not include simulator_mips.h directly; use simulator.h.
#endif

namespace dart {

class Simulator {
 public:
  static const uword kSimulatorStackUnderflowSize = 64;

  Simulator();
  ~Simulator();

  // The currently executing Simulator instance, which is associated to the
  // current isolate
  static Simulator* Current();

  // Accessor to the internal simulator stack top.
  uword StackTop() const;

  // Call on program start.
  static void InitOnce();

  // Dart generally calls into generated code with 5 parameters. This is a
  // convenience function, which sets up the simulator state and grabs the
  // result on return.
  int64_t Call(int32_t entry,
               int32_t parameter0,
               int32_t parameter1,
               int32_t parameter2,
               int32_t parameter3,
               int32_t parameter4);

 private:
  char* stack_;
};

}  // namespace dart

#endif  // VM_SIMULATOR_MIPS_H_
