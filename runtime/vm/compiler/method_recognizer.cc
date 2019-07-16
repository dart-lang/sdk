// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/method_recognizer.h"

#include "vm/object.h"
#include "vm/reusable_handles.h"
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

intptr_t MethodRecognizer::NumArgsCheckedForStaticCall(
    const Function& function) {
  switch (RecognizeKind(function)) {
    case MethodRecognizer::kDoubleFromInteger:
    case MethodRecognizer::kMathMin:
    case MethodRecognizer::kMathMax:
      return 2;
    default:
      return 0;
  }
}

intptr_t MethodRecognizer::ResultCidFromPragma(
    const Object& function_or_field) {
  auto T = Thread::Current();
  auto Z = T->zone();
  auto& option = Object::Handle(Z);
  if (Library::FindPragma(T, /*only_core=*/true, function_or_field,
                          Symbols::vm_exact_result_type(), &option)) {
    if (option.IsType()) {
      return Type::Cast(option).type_class_id();
    } else if (option.IsString()) {
      auto& str = String::Cast(option);
      // 'str' should match the pattern '([^#]+)#([^#\?]+)' where group 1
      // is the library URI and group 2 is the class name.
      bool parse_failure = false;
      intptr_t library_end = -1;
      for (intptr_t i = 0; i < str.Length(); ++i) {
        if (str.CharAt(i) == '#') {
          if (library_end != -1) {
            parse_failure = true;
            break;
          } else {
            library_end = i;
          }
        }
      }
      if (!parse_failure && library_end > 0) {
        auto& tmp =
            String::Handle(String::SubString(str, 0, library_end, Heap::kOld));
        const auto& library = Library::Handle(Library::LookupLibrary(T, tmp));
        if (!library.IsNull()) {
          tmp = String::SubString(str, library_end + 1,
                                  str.Length() - library_end - 1, Heap::kOld);
          const auto& klass =
              Class::Handle(library.LookupClassAllowPrivate(tmp));
          if (!klass.IsNull()) {
            return klass.id();
          }
        }
      }
    }
  }

  return kDynamicCid;
}

bool MethodRecognizer::HasNonNullableResultTypeFromPragma(
    const Object& function_or_field) {
  auto T = Thread::Current();
  auto Z = T->zone();
  auto& option = Object::Handle(Z);
  if (Library::FindPragma(T, /*only_core=*/true, function_or_field,
                          Symbols::vm_non_nullable_result_type(), &option)) {
    return true;
  }

  // If nothing said otherwise, the return type is nullable.
  return false;
}

intptr_t MethodRecognizer::MethodKindToReceiverCid(Kind kind) {
  switch (kind) {
    case kImmutableArrayGetIndexed:
      return kImmutableArrayCid;

    case kObjectArrayGetIndexed:
    case kObjectArraySetIndexed:
    case kObjectArraySetIndexedUnchecked:
      return kArrayCid;

    case kGrowableArrayGetIndexed:
    case kGrowableArraySetIndexed:
    case kGrowableArraySetIndexedUnchecked:
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

    case kUint64ArrayGetIndexed:
    case kUint64ArraySetIndexed:
      return kTypedDataUint64ArrayCid;

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

#define KIND_TO_STRING(class_name, function_name, enum_name, fp) #enum_name,
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
  Libraries(&libs);
  Function& func = Function::Handle();

#define SET_RECOGNIZED_KIND(class_name, function_name, enum_name, fp)          \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (!func.IsNull()) {                                                        \
    CHECK_FINGERPRINT3(func, class_name, function_name, enum_name, fp);        \
    func.set_recognized_kind(k##enum_name);                                    \
  } else if (!FLAG_precompiled_mode) {                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    UNREACHABLE();                                                             \
  }

  RECOGNIZED_LIST(SET_RECOGNIZED_KIND);

#define SET_FUNCTION_BIT(class_name, function_name, dest, fp, setter, value)   \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (!func.IsNull()) {                                                        \
    CHECK_FINGERPRINT3(func, class_name, function_name, dest, fp);             \
    func.setter(value);                                                        \
  } else if (!FLAG_precompiled_mode) {                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    UNREACHABLE();                                                             \
  }

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

void MethodRecognizer::Libraries(GrowableArray<Library*>* libs) {
  libs->Add(&Library::ZoneHandle(Library::CoreLibrary()));
  libs->Add(&Library::ZoneHandle(Library::CollectionLibrary()));
  libs->Add(&Library::ZoneHandle(Library::MathLibrary()));
  libs->Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  libs->Add(&Library::ZoneHandle(Library::InternalLibrary()));
  libs->Add(&Library::ZoneHandle(Library::DeveloperLibrary()));
  libs->Add(&Library::ZoneHandle(Library::AsyncLibrary()));
  libs->Add(&Library::ZoneHandle(Library::FfiLibrary()));
}

RawGrowableObjectArray* MethodRecognizer::QueryRecognizedMethods(Zone* zone) {
  const GrowableObjectArray& methods =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  Function& func = Function::Handle(zone);

  GrowableArray<Library*> libs(3);
  Libraries(&libs);

#define ADD_RECOGNIZED_METHOD(class_name, function_name, enum_name, fp)        \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  methods.Add(func);

  RECOGNIZED_LIST(ADD_RECOGNIZED_METHOD);
#undef ADD_RECOGNIZED_METHOD

  return methods.raw();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

Token::Kind MethodTokenRecognizer::RecognizeTokenKind(const String& name_) {
  Thread* thread = Thread::Current();
  REUSABLE_STRING_HANDLESCOPE(thread);
  String& name = thread->StringHandle();
  name = name_.raw();
  ASSERT(name.IsSymbol());
  if (Function::IsDynamicInvocationForwarderName(name)) {
    name = Function::DemangleDynamicInvocationForwarderName(name);
  }
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

#define RECOGNIZE_FACTORY(symbol, class_name, constructor_name, cid, fp)       \
  {Symbols::k##symbol##Id, cid, fp, #symbol ", " #cid},  // NOLINT

static struct {
  intptr_t symbol_id;
  intptr_t cid;
  intptr_t finger_print;
  const char* name;
} factory_recognizer_list[] = {RECOGNIZED_LIST_FACTORY_LIST(RECOGNIZE_FACTORY){
    Symbols::kIllegal, -1, -1, NULL}};

#undef RECOGNIZE_FACTORY

intptr_t FactoryRecognizer::ResultCid(const Function& factory) {
  ASSERT(factory.IsFactory());
  const Class& function_class = Class::Handle(factory.Owner());
  const Library& lib = Library::Handle(function_class.library());
  ASSERT((lib.raw() == Library::CoreLibrary()) ||
         (lib.raw() == Library::TypedDataLibrary()));
  const String& factory_name = String::Handle(factory.name());
  for (intptr_t i = 0;
       factory_recognizer_list[i].symbol_id != Symbols::kIllegal; i++) {
    if (String::EqualsIgnoringPrivateKey(
            factory_name,
            Symbols::Symbol(factory_recognizer_list[i].symbol_id))) {
      return factory_recognizer_list[i].cid;
    }
  }
  return kDynamicCid;
}

}  // namespace dart
