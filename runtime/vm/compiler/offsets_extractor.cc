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

#if defined(PRODUCT)
#define PRODUCT_DEF "true"
#else
#define PRODUCT_DEF "false"
#endif

#if defined(TARGET_ARCH_ARM)
#define ARCH_DEF_CPU "arm"
#elif defined(TARGET_ARCH_X64)
#define ARCH_DEF_CPU "x64"
#elif defined(TARGET_ARCH_IA32)
#define ARCH_DEF_CPU "ia32"
#elif defined(TARGET_ARCH_ARM64)
#define ARCH_DEF_CPU "arm64"
#elif defined(TARGET_ARCH_RISCV32)
#define ARCH_DEF_CPU "riscv32"
#elif defined(TARGET_ARCH_RISCV64)
#define ARCH_DEF_CPU "riscv64"
#else
#error Unknown architecture
#endif

#if defined(DART_COMPRESSED_POINTERS)
#define COMPRESSED_DEF "true"
#else
#define COMPRESSED_DEF "false"
#endif

#if defined(DART_PRECOMPILED_RUNTIME)
#define AOT_DEF "true"
#else
#define AOT_DEF "false"
#endif

namespace dart {

void Assert::Fail(const char* format, ...) const {
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

// These macros don't use any special constants, just method calls, so no
// output.
#define PRINT_ARRAY_SIZEOF(Class, Name, ElementOffset)
#define PRINT_PAYLOAD_SIZEOF(Class, Name, HeaderSize)

#define PRINT_FIELD_OFFSET(Class, Name)                                        \
  std::cout << "{\"kind\": \"value\","                                         \
               " \"class\": \"" #Class "\", \"name\": \"" #Name                \
               "\", \"value\": \""                                             \
            << Class::Name() << "\"},\n";

#define PRINT_ARRAY_LAYOUT(Class, Name)                                        \
  std::cout << "{\"kind\": \"array\","                                         \
               " \"class\": \"" #Class "\", \"startOffset\": \""               \
            << Class::ArrayTraits::elements_start_offset()                     \
            << "\", \"elemSize\": \"" << Class::ArrayTraits::kElementSize      \
            << "\"},\n";

#define PRINT_SIZEOF(Class, Name, What)                                        \
  std::cout << "{\"kind\": \"value\","                                         \
               " \"class\": \"" #Class "\", \"name\": \"" #Name                \
               "\", \"value\": \""                                             \
            << sizeof(What) << "\"},\n";

#define PRINT_RANGE(Class, Name, Type, First, Last, Filter)                    \
  {                                                                            \
    auto filter = Filter;                                                      \
    bool comma = false;                                                        \
    std::cout << "{\"kind\": \"range\","                                       \
                 " \"class\": \"" #Class "\", \"name\": \"" #Name              \
                 "\", \"values\": [";                                          \
    for (intptr_t i = static_cast<intptr_t>(First);                            \
         i <= static_cast<intptr_t>(Last); i++) {                              \
      auto v = static_cast<Type>(i);                                           \
      std::cout << (comma ? ", " : "");                                        \
      if (filter(v)) {                                                         \
        std::cout << "\"" << Class::Name(v) << "\"";                           \
      } else {                                                                 \
        std::cout << "\"-1\"";                                                 \
      }                                                                        \
      comma = true;                                                            \
    }                                                                          \
    std::cout << "]},\n";                                                      \
  }

#define PRINT_CONSTANT(Class, Name)                                            \
  std::cout << "{\"kind\": \"value\","                                         \
               " \"class\": \"" #Class "\", \"name\": \"" #Name                \
               "\", \"value\": \""                                             \
            << Class::Name << "\"},\n";

#define PRINT_ENUM(Name, Elements)                                             \
  {                                                                            \
    std::cout << "{\"kind\": \"enum\","                                        \
                 " \"name\": \"" #Name "\", \"elements\": [";                  \
    bool comma = false;                                                        \
    for (auto elem : Elements) {                                               \
      std::cout << (comma ? ", " : "");                                        \
      std::cout << "\"" << elem << "\"";                                       \
      comma = true;                                                            \
    }                                                                          \
    std::cout << "]},\n";                                                      \
  }

#if defined(DART_PRECOMPILED_RUNTIME)
    AOT_OFFSETS_LIST(PRINT_FIELD_OFFSET, PRINT_ARRAY_LAYOUT, PRINT_SIZEOF,
                     PRINT_ARRAY_SIZEOF, PRINT_PAYLOAD_SIZEOF, PRINT_RANGE,
                     PRINT_CONSTANT, PRINT_ENUM)
#else  // defined(DART_PRECOMPILED_RUNTIME)
    JIT_OFFSETS_LIST(PRINT_FIELD_OFFSET, PRINT_ARRAY_LAYOUT, PRINT_SIZEOF,
                     PRINT_ARRAY_SIZEOF, PRINT_PAYLOAD_SIZEOF, PRINT_RANGE,
                     PRINT_CONSTANT, PRINT_ENUM)

#endif  // defined(DART_PRECOMPILED_RUNTIME)

    COMMON_OFFSETS_LIST(PRINT_FIELD_OFFSET, PRINT_ARRAY_LAYOUT, PRINT_SIZEOF,
                        PRINT_ARRAY_SIZEOF, PRINT_PAYLOAD_SIZEOF, PRINT_RANGE,
                        PRINT_CONSTANT, PRINT_ENUM)

#undef PRINT_FIELD_OFFSET
#undef PRINT_ARRAY_LAYOUT
#undef PRINT_SIZEOF
#undef PRINT_RANGE
#undef PRINT_CONSTANT
#undef PRINT_ARRAY_SIZEOF
#undef PRINT_PAYLOAD_SIZEOF
#undef PRINT_ENUM
  }
};

}  // namespace dart

int main(int argc, char* argv[]) {
  std::cout << "{\n";
  std::cout << "\"product\": " PRODUCT_DEF ",\n";
  std::cout << "\"arch\": \"" ARCH_DEF_CPU "\",\n";
  std::cout << "\"compressed\": " COMPRESSED_DEF ",\n";
  std::cout << "\"aot\": " AOT_DEF ",\n";
  std::cout << "\"offsets\": [\n";
#if !defined(TARGET_ARCH_IA32) || !defined(DART_PRECOMPILED_RUNTIME)
  dart::OffsetsExtractor::DumpOffsets();
#endif
  std::cout << "{\"kind\": \"\"}\n";  // Terminate the list after comma.
  std::cout << "]\n";
  std::cout << "}\n";
  return 0;
}
