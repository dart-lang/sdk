// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/method_recognizer.h"

#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

MethodRecognizer::Kind MethodRecognizer::RecognizeKind(
    const Function& function) {
  return function.recognized_kind();
}


bool MethodRecognizer::AlwaysInline(const Function& function) {
  return function.always_inline();
}


bool MethodRecognizer::PolymorphicTarget(const Function& function) {
  return function.is_polymorphic_target();
}


const char* MethodRecognizer::KindToCString(Kind kind) {
#define KIND_TO_STRING(class_name, function_name, enum_name, fp)               \
  if (kind == k##enum_name) return #enum_name;
RECOGNIZED_LIST(KIND_TO_STRING)
#undef KIND_TO_STRING
  return "?";
}


void MethodRecognizer::InitializeState() {
  GrowableArray<Library*> libs(3);
  libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  libs.Add(&Library::ZoneHandle(Library::InternalLibrary()));
  libs.Add(&Library::ZoneHandle(Library::ProfilerLibrary()));
  Function& func = Function::Handle();

#define SET_RECOGNIZED_KIND(class_name, function_name, enum_name, fp)          \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (func.IsNull()) {                                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    UNREACHABLE();                                                             \
  }                                                                            \
  ASSERT(func.CheckSourceFingerprint(fp));                                     \
  func.set_recognized_kind(k##enum_name);

  RECOGNIZED_LIST(SET_RECOGNIZED_KIND);

#define SET_FUNCTION_BIT(class_name, function_name, dest, fp, setter, value)   \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (func.IsNull()) {                                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    UNREACHABLE();                                                             \
  }                                                                            \
  ASSERT(func.CheckSourceFingerprint(fp));                                     \
  func.setter(value);

#define SET_IS_ALWAYS_INLINE(class_name, function_name, dest, fp)              \
  SET_FUNCTION_BIT(class_name, function_name, dest, fp, set_always_inline, true)

#define SET_IS_NEVER_INLINE(class_name, function_name, dest, fp)              \
  SET_FUNCTION_BIT(class_name, function_name, dest, fp, set_is_inlinable, false)

#define SET_IS_POLYMORPHIC_TARGET(class_name, function_name, dest, fp)         \
  SET_FUNCTION_BIT(class_name, function_name, dest, fp,                        \
                   set_is_polymorphic_target, true)

  INLINE_WHITE_LIST(SET_IS_ALWAYS_INLINE);
  INLINE_BLACK_LIST(SET_IS_NEVER_INLINE);
  POLYMORPHIC_TARGET_LIST(SET_IS_POLYMORPHIC_TARGET);

#undef SET_RECOGNIZED_KIND
#undef SET_IS_ALWAYS_INLINE
#undef SET_IS_POLYMORPHIC_TARGET
#undef SET_FUNCTION_BIT
}

}  // namespace dart
