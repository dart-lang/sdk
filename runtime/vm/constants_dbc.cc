// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#define RUNTIME_VM_CONSTANTS_H_  // To work around include guard.
#include "vm/constants_dbc.h"

namespace dart {

const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "R0",  "R1",  "R2",  "R3",  "R4",  "R5",  "R6",  "R7",  "R8",  "R9",  "R10",
    "R11", "R12", "R13", "R14", "R15", "R16", "R17", "R18", "R19", "R20", "R21",
    "R22", "R23", "R24", "R25", "R26", "R27", "R28", "R29", "R30", "R31",
#if defined(ARCH_IS_64_BIT)
    "R32", "R33", "R34", "R35", "R36", "R37", "R38", "R39", "R40", "R41", "R42",
    "R43", "R44", "R45", "R46", "R47", "R48", "R49", "R50", "R51", "R52", "R53",
    "R54", "R55", "R56", "R57", "R58", "R59", "R60", "R61", "R62", "R63",
#endif
};

const char* fpu_reg_names[kNumberOfFpuRegisters] = {
    "F0",
};

}  // namespace dart
