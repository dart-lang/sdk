// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/method_recognizer.h"

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

intptr_t MethodRecognizer::ResultCid(const Function& function) {
  switch (function.recognized_kind()) {
#define DEFINE_CASE(cname, fname, ename, result_type, fingerprint)             \
  case k##ename:                                                               \
    return k##result_type##Cid;
    RECOGNIZED_LIST(DEFINE_CASE)
#undef DEFINE_CASE
    default:
      return kDynamicCid;
  }
}

intptr_t MethodRecognizer::MethodKindToReceiverCid(Kind kind) {
  switch (kind) {
    case kImmutableArrayGetIndexed:
      return kImmutableArrayCid;

    case kObjectArrayGetIndexed:
    case kObjectArraySetIndexed:
      return kArrayCid;

    case kGrowableArrayGetIndexed:
    case kGrowableArraySetIndexed:
      return kGrowableObjectArrayCid;

    case kFloat32ArrayGetIndexed:
    case kFloat32ArraySetIndexed:
      return kTypedDataFloat32ArrayCid;

    case kFloat64ArrayGetIndexed:
    case kFloat64ArraySetIndexed:
      return kTypedDataFloat64ArrayCid;

    case kInt8ArrayGetIndexed:
    case kInt8ArraySetIndexed:
      return kTypedDataInt8ArrayCid;

    case kUint8ArrayGetIndexed:
    case kUint8ArraySetIndexed:
      return kTypedDataUint8ArrayCid;

    case kUint8ClampedArrayGetIndexed:
    case kUint8ClampedArraySetIndexed:
      return kTypedDataUint8ClampedArrayCid;

    case kExternalUint8ArrayGetIndexed:
    case kExternalUint8ArraySetIndexed:
      return kExternalTypedDataUint8ArrayCid;

    case kExternalUint8ClampedArrayGetIndexed:
    case kExternalUint8ClampedArraySetIndexed:
      return kExternalTypedDataUint8ClampedArrayCid;

    case kInt16ArrayGetIndexed:
    case kInt16ArraySetIndexed:
      return kTypedDataInt16ArrayCid;

    case kUint16ArrayGetIndexed:
    case kUint16ArraySetIndexed:
      return kTypedDataUint16ArrayCid;

    case kInt32ArrayGetIndexed:
    case kInt32ArraySetIndexed:
      return kTypedDataInt32ArrayCid;

    case kUint32ArrayGetIndexed:
    case kUint32ArraySetIndexed:
      return kTypedDataUint32ArrayCid;

    case kInt64ArrayGetIndexed:
    case kInt64ArraySetIndexed:
      return kTypedDataInt64ArrayCid;

    case kFloat32x4ArrayGetIndexed:
    case kFloat32x4ArraySetIndexed:
      return kTypedDataFloat32x4ArrayCid;

    case kInt32x4ArrayGetIndexed:
    case kInt32x4ArraySetIndexed:
      return kTypedDataInt32x4ArrayCid;

    case kFloat64x2ArrayGetIndexed:
    case kFloat64x2ArraySetIndexed:
      return kTypedDataFloat64x2ArrayCid;

    default:
      break;
  }
  UNREACHABLE();
  return kIllegalCid;
}

#define KIND_TO_STRING(class_name, function_name, enum_name, type, fp)         \
  #enum_name,
static const char* recognized_list_method_name[] = {
    "Unknown", RECOGNIZED_LIST(KIND_TO_STRING)};
#undef KIND_TO_STRING

const char* MethodRecognizer::KindToCString(Kind kind) {
  if (kind > kUnknown && kind < kNumRecognizedMethods)
    return recognized_list_method_name[kind];
  return "?";
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void MethodRecognizer::InitializeState() {
  GrowableArray<Library*> libs(3);
  libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  libs.Add(&Library::ZoneHandle(Library::CollectionLibrary()));
  libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  libs.Add(&Library::ZoneHandle(Library::InternalLibrary()));
  libs.Add(&Library::ZoneHandle(Library::DeveloperLibrary()));
  libs.Add(&Library::ZoneHandle(Library::AsyncLibrary()));
  Function& func = Function::Handle();

#define SET_RECOGNIZED_KIND(class_name, function_name, enum_name, type, fp)    \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (func.IsNull()) {                                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    UNREACHABLE();                                                             \
  }                                                                            \
  CHECK_FINGERPRINT3(func, class_name, function_name, enum_name, fp);          \
  func.set_recognized_kind(k##enum_name);

  RECOGNIZED_LIST(SET_RECOGNIZED_KIND);

#define SET_FUNCTION_BIT(class_name, function_name, dest, fp, setter, value)   \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (func.IsNull()) {                                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    UNREACHABLE();                                                             \
  }                                                                            \
  CHECK_FINGERPRINT3(func, class_name, function_name, dest, fp);               \
  func.setter(value);

#define SET_IS_ALWAYS_INLINE(class_name, function_name, dest, fp)              \
  SET_FUNCTION_BIT(class_name, function_name, dest, fp, set_always_inline, true)

#define SET_IS_NEVER_INLINE(class_name, function_name, dest, fp)               \
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
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

Token::Kind MethodTokenRecognizer::RecognizeTokenKind(const String& name) {
  ASSERT(name.IsSymbol());
  if (name.raw() == Symbols::Plus().raw()) {
    return Token::kADD;
  } else if (name.raw() == Symbols::Minus().raw()) {
    return Token::kSUB;
  } else if (name.raw() == Symbols::Star().raw()) {
    return Token::kMUL;
  } else if (name.raw() == Symbols::Slash().raw()) {
    return Token::kDIV;
  } else if (name.raw() == Symbols::TruncDivOperator().raw()) {
    return Token::kTRUNCDIV;
  } else if (name.raw() == Symbols::Percent().raw()) {
    return Token::kMOD;
  } else if (name.raw() == Symbols::BitOr().raw()) {
    return Token::kBIT_OR;
  } else if (name.raw() == Symbols::Ampersand().raw()) {
    return Token::kBIT_AND;
  } else if (name.raw() == Symbols::Caret().raw()) {
    return Token::kBIT_XOR;
  } else if (name.raw() == Symbols::LeftShiftOperator().raw()) {
    return Token::kSHL;
  } else if (name.raw() == Symbols::RightShiftOperator().raw()) {
    return Token::kSHR;
  } else if (name.raw() == Symbols::Tilde().raw()) {
    return Token::kBIT_NOT;
  } else if (name.raw() == Symbols::UnaryMinus().raw()) {
    return Token::kNEGATE;
  } else if (name.raw() == Symbols::EqualOperator().raw()) {
    return Token::kEQ;
  } else if (name.raw() == Symbols::Token(Token::kNE).raw()) {
    return Token::kNE;
  } else if (name.raw() == Symbols::LAngleBracket().raw()) {
    return Token::kLT;
  } else if (name.raw() == Symbols::RAngleBracket().raw()) {
    return Token::kGT;
  } else if (name.raw() == Symbols::LessEqualOperator().raw()) {
    return Token::kLTE;
  } else if (name.raw() == Symbols::GreaterEqualOperator().raw()) {
    return Token::kGTE;
  } else if (Field::IsGetterName(name)) {
    return Token::kGET;
  } else if (Field::IsSetterName(name)) {
    return Token::kSET;
  }
  return Token::kILLEGAL;
}

}  // namespace dart
