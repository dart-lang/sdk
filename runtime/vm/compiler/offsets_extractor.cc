// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <iostream>

#include "vm/compiler/runtime_api.h"
#include "vm/compiler/runtime_offsets_list.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/timeline.h"

#if defined(TARGET_ARCH_ARM)
#define ARCH_DEF "defined(TARGET_ARCH_ARM)"
#elif defined(TARGET_ARCH_X64)
#define ARCH_DEF "defined(TARGET_ARCH_X64)"
#elif defined(TARGET_ARCH_IA32)
#define ARCH_DEF "defined(TARGET_ARCH_IA32)"
#elif defined(TARGET_ARCH_ARM64)
#define ARCH_DEF "defined(TARGET_ARCH_ARM64)"
#else
#error Unknown architecture
#endif

namespace dart {

void Assert::Fail(const char* format, ...) {
  abort();
}

class OffsetsExtractor : public AllStatic {
 public:
  static void DumpOffsets() {
// Currently we have two different axes for offset generation:
//
//  * Target architecture
//  * DART_PRECOMPILED_RUNTIME (i.e, AOT vs. JIT)
//
// TODO(dartbug.com/43646): Add DART_PRECOMPILER as another axis.

// This doesn't use any special constants, just method calls, so no output.
#define PRINT_PAYLOAD_SIZEOF(Class, Name, HeaderSize)

#if defined(DART_PRECOMPILED_RUNTIME)

#define PRINT_FIELD_OFFSET(Class, Name)                                        \
  std::cout << "static constexpr dart::compiler::target::word AOT_" #Class     \
               "_" #Name " = "                                                 \
            << Class::Name() << ";\n";

#define PRINT_ARRAY_LAYOUT(Class, Name)                                        \
  std::cout << "static constexpr dart::compiler::target::word AOT_" #Class     \
               "_elements_start_offset = "                                     \
            << Class::ArrayTraits::elements_start_offset() << ";\n";           \
  std::cout << "static constexpr dart::compiler::target::word AOT_" #Class     \
               "_element_size = "                                              \
            << Class::ArrayTraits::kElementSize << ";\n";

#define PRINT_SIZEOF(Class, Name, What)                                        \
  std::cout << "static constexpr dart::compiler::target::word AOT_" #Class     \
               "_" #Name " = "                                                 \
            << sizeof(What) << ";\n";

#define PRINT_RANGE(Class, Name, Type, First, Last, Filter)                    \
  {                                                                            \
    auto filter = Filter;                                                      \
    bool comma = false;                                                        \
    std::cout << "static constexpr dart::compiler::target::word AOT_" #Class   \
                 "_" #Name "[] = {";                                           \
    for (intptr_t i = static_cast<intptr_t>(First);                            \
         i <= static_cast<intptr_t>(Last); i++) {                              \
      auto v = static_cast<Type>(i);                                           \
      std::cout << (comma ? ", " : "") << (filter(v) ? Class::Name(v) : -1);   \
      comma = true;                                                            \
    }                                                                          \
    std::cout << "};\n";                                                       \
  }

#define PRINT_CONSTANT(Class, Name)                                            \
  std::cout << "static constexpr dart::compiler::target::word AOT_" #Class     \
               "_" #Name " = "                                                 \
            << Class::Name << ";\n";

#else  // defined(DART_PRECOMPILED_RUNTIME)

#define PRINT_FIELD_OFFSET(Class, Name)                                        \
  std::cout << "static constexpr dart::compiler::target::word " #Class         \
               "_" #Name " = "                                                 \
            << Class::Name() << ";\n";

#define PRINT_ARRAY_LAYOUT(Class, Name)                                        \
  std::cout << "static constexpr dart::compiler::target::word " #Class         \
               "_elements_start_offset = "                                     \
            << Class::ArrayTraits::elements_start_offset() << ";\n";           \
  std::cout << "static constexpr dart::compiler::target::word " #Class         \
               "_element_size = "                                              \
            << Class::ArrayTraits::kElementSize << ";\n";

#define PRINT_SIZEOF(Class, Name, What)                                        \
  std::cout << "static constexpr dart::compiler::target::word " #Class         \
               "_" #Name " = "                                                 \
            << sizeof(What) << ";\n";

#define PRINT_RANGE(Class, Name, Type, First, Last, Filter)                    \
  {                                                                            \
    auto filter = Filter;                                                      \
    bool comma = false;                                                        \
    std::cout << "static constexpr dart::compiler::target::word " #Class       \
                 "_" #Name "[] = {";                                           \
    for (intptr_t i = static_cast<intptr_t>(First);                            \
         i <= static_cast<intptr_t>(Last); i++) {                              \
      auto v = static_cast<Type>(i);                                           \
      std::cout << (comma ? ", " : "") << (filter(v) ? Class::Name(v) : -1);   \
      comma = true;                                                            \
    }                                                                          \
    std::cout << "};\n";                                                       \
  }

#define PRINT_CONSTANT(Class, Name)                                            \
  std::cout << "static constexpr dart::compiler::target::word " #Class         \
               "_" #Name " = "                                                 \
            << Class::Name << ";\n";

    JIT_OFFSETS_LIST(PRINT_FIELD_OFFSET, PRINT_ARRAY_LAYOUT, PRINT_SIZEOF,
                     PRINT_PAYLOAD_SIZEOF, PRINT_RANGE, PRINT_CONSTANT)

#endif  // defined(DART_PRECOMPILED_RUNTIME)

    COMMON_OFFSETS_LIST(PRINT_FIELD_OFFSET, PRINT_ARRAY_LAYOUT, PRINT_SIZEOF,
                        PRINT_PAYLOAD_SIZEOF, PRINT_RANGE, PRINT_CONSTANT)

#undef PRINT_FIELD_OFFSET
#undef PRINT_ARRAY_LAYOUT
#undef PRINT_SIZEOF
#undef PRINT_RANGE
#undef PRINT_CONSTANT
#undef PRINT_PAYLOAD_SIZEOF
  }
};

}  // namespace dart

int main(int argc, char* argv[]) {
  std::cout << "#if " << ARCH_DEF << std::endl;
#if !defined(TARGET_ARCH_IA32) || !defined(DART_PRECOMPILED_RUNTIME)
  dart::OffsetsExtractor::DumpOffsets();
#endif
  std::cout << "#endif  // " << ARCH_DEF << std::endl;
  return 0;
}
