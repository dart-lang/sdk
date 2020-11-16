// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "platform/syslog.h"
#include "vm/compiler/ffi/native_calling_convention.h"

namespace dart {
namespace compiler {
namespace ffi {

#if defined(TARGET_ARCH_ARM)
const char* kArch = "arm";
#elif defined(TARGET_ARCH_ARM64)
const char* kArch = "arm64";
#elif defined(TARGET_ARCH_IA32)
const char* kArch = "ia32";
#elif defined(TARGET_ARCH_X64)
const char* kArch = "x64";
#endif

#if defined(TARGET_OS_ANDROID)
const char* kOs = "android";
#elif defined(TARGET_OS_IOS)
const char* kOs = "ios";
#elif defined(TARGET_OS_LINUX)
const char* kOs = "linux";
#elif defined(TARGET_OS_MACOS)
const char* kOs = "macos";
#elif defined(TARGET_OS_WINDOWS)
const char* kOs = "win";
#endif

void WriteToFile(char* path, const char* contents) {
  FILE* file;
  file = fopen(path, "w");
  if (file != nullptr) {
    fprintf(file, "%s", contents);
  } else {
    Syslog::Print("Error %d \n", errno);
  }
  fclose(file);
}

void ReadFromFile(char* path, char** buffer_pointer) {
  FILE* file = fopen(path, "rb");
  if (file == nullptr) {
    Syslog::Print("Error %d \n", errno);
    return;
  }

  fseek(file, 0, SEEK_END);
  size_t size = ftell(file);
  rewind(file);

  char* buffer = reinterpret_cast<char*>(malloc(sizeof(char) * (size + 1)));

  fread(buffer, 1, size, file);
  buffer[size] = 0;

  fclose(file);
  *buffer_pointer = buffer;
}

void RunSignatureTest(dart::Zone* zone,
                      const char* name,
                      const NativeTypes& argument_types,
                      const NativeType& return_type) {
  const auto& native_signature =
      *new (zone) NativeFunctionType(argument_types, return_type);

  const auto& native_calling_convention =
      NativeCallingConvention::FromSignature(zone, native_signature);

  const char* test_result =
      native_calling_convention.ToCString(zone, /*multi_line=*/true);

  const int kFilePathLength = 100;
  char expectation_file_path[kFilePathLength];
  Utils::SNPrint(expectation_file_path, kFilePathLength,
                 "runtime/vm/compiler/ffi/unit_tests/%s/%s_%s.expect", name,
                 kArch, kOs);

  if (TestCaseBase::update_expectations) {
    Syslog::Print("Updating %s\n", expectation_file_path);
    WriteToFile(expectation_file_path, test_result);
  }

  char* expectation_file_contents = nullptr;
  ReadFromFile(expectation_file_path, &expectation_file_contents);
  EXPECT_NOTNULL(expectation_file_contents);
  if (expectation_file_contents != nullptr) {
    EXPECT_STREQ(expectation_file_contents, test_result);
    free(expectation_file_contents);
  }
}

UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_int8x10) {
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  auto& arguments = *new (Z) NativeTypes(Z, 10);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);

  RunSignatureTest(Z, "int8x10", arguments, int8type);
}

UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_floatx10) {
  const auto& floatType = *new (Z) NativePrimitiveType(kFloat);

  auto& arguments = *new (Z) NativeTypes(Z, 10);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);

  RunSignatureTest(Z, "floatx10", arguments, floatType);
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
