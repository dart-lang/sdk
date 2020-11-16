// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/method_recognizer.h"

#include "vm/log.h"
#include "vm/object.h"
#include "vm/reusable_handles.h"
#include "vm/symbols.h"

namespace dart {

intptr_t MethodRecognizer::NumArgsCheckedForStaticCall(
    const Function& function) {
  switch (function.recognized_kind()) {
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
    } else if (option.IsArray()) {
      const Array& array = Array::Cast(option);
      if (array.Length() > 0) {
        const Object& type = Object::Handle(Array::Cast(option).At(0));
        if (type.IsType()) {
          return Type::Cast(type).type_class_id();
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

static const struct {
  const char* const class_name;
  const char* const function_name;
  const char* const enum_name;
  const uint32_t fp;
} recognized_methods[MethodRecognizer::kNumRecognizedMethods] = {
    {"", "", "Unknown", 0},
#define RECOGNIZE_METHOD(class_name, function_name, enum_name, fp)             \
  {"" #class_name, "" #function_name, #enum_name, fp},
    RECOGNIZED_LIST(RECOGNIZE_METHOD)
#undef RECOGNIZE_METHOD
};

const char* MethodRecognizer::KindToCString(Kind kind) {
  if (kind >= kUnknown && kind < kNumRecognizedMethods)
    return recognized_methods[kind].enum_name;
  return "?";
}

// Is this method marked with the vm:recognized pragma?
bool MethodRecognizer::IsMarkedAsRecognized(const Function& function,
                                            const char* kind) {
  const Function* functionp =
      function.IsDynamicInvocationForwarder()
          ? &Function::Handle(function.ForwardingTarget())
          : &function;
  Object& options = Object::Handle();
  bool is_recognized =
      Library::FindPragma(Thread::Current(), /*only_core=*/true, *functionp,
                          Symbols::vm_recognized(), &options);
  if (!is_recognized) return false;
  if (kind == nullptr) return true;

  ASSERT(options.IsString());
  ASSERT(String::Cast(options).Equals("asm-intrinsic") ||
         String::Cast(options).Equals("graph-intrinsic") ||
         String::Cast(options).Equals("other"));
  return String::Cast(options).Equals(kind);
}

void MethodRecognizer::InitializeState() {
  GrowableArray<Library*> libs(3);
  Libraries(&libs);
  Function& func = Function::Handle();
  bool fingerprints_match = true;

  for (intptr_t i = 1; i < MethodRecognizer::kNumRecognizedMethods; i++) {
    const MethodRecognizer::Kind kind = static_cast<MethodRecognizer::Kind>(i);
    func = Library::GetFunction(libs, recognized_methods[i].class_name,
                                recognized_methods[i].function_name);
    if (!func.IsNull()) {
      fingerprints_match =
          func.CheckSourceFingerprint(recognized_methods[i].fp) &&
          fingerprints_match;
      func.set_recognized_kind(kind);
      switch (kind) {
#define RECOGNIZE_METHOD(class_name, function_name, enum_name, fp)             \
  case MethodRecognizer::k##enum_name:                                         \
    func.reset_unboxed_parameters_and_return();                                \
    break;
        ALL_INTRINSICS_LIST(RECOGNIZE_METHOD)
#undef RECOGNIZE_METHOD
        default:
          break;
      }
    } else if (!FLAG_precompiled_mode) {
      fingerprints_match = false;
      OS::PrintErr("Missing %s::%s\n", recognized_methods[i].class_name,
                   recognized_methods[i].function_name);
    }
  }

#define SET_FUNCTION_BIT(class_name, function_name, dest, fp, setter, value)   \
  func = Library::GetFunction(libs, #class_name, #function_name);              \
  if (!func.IsNull()) {                                                        \
    fingerprints_match =                                                       \
        func.CheckSourceFingerprint(fp) && fingerprints_match;                 \
    func.setter(value);                                                        \
  } else if (!FLAG_precompiled_mode) {                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    fingerprints_match = false;                                                \
  }

#define SET_IS_POLYMORPHIC_TARGET(class_name, function_name, dest, fp)         \
  SET_FUNCTION_BIT(class_name, function_name, dest, fp,                        \
                   set_is_polymorphic_target, true)

  POLYMORPHIC_TARGET_LIST(SET_IS_POLYMORPHIC_TARGET);

#undef SET_RECOGNIZED_KIND
#undef SET_IS_POLYMORPHIC_TARGET
#undef SET_FUNCTION_BIT

  if (!fingerprints_match) {
    FATAL(
        "FP mismatch while recognizing methods. If the behavior of "
        "these functions has changed, then changes are also needed in "
        "the VM's compiler. Otherwise the fingerprint can simply be "
        "updated in recognized_methods_list.h\n");
  }
}

void MethodRecognizer::Libraries(GrowableArray<Library*>* libs) {
  libs->Add(&Library::ZoneHandle(Library::CoreLibrary()));
  libs->Add(&Library::ZoneHandle(Library::CollectionLibrary()));
  libs->Add(&Library::ZoneHandle(Library::MathLibrary()));
  libs->Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  libs->Add(&Library::ZoneHandle(Library::ConvertLibrary()));
  libs->Add(&Library::ZoneHandle(Library::InternalLibrary()));
  libs->Add(&Library::ZoneHandle(Library::DeveloperLibrary()));
  libs->Add(&Library::ZoneHandle(Library::AsyncLibrary()));
  libs->Add(&Library::ZoneHandle(Library::FfiLibrary()));
}

static Token::Kind RecognizeTokenKindHelper(const String& name) {
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

Token::Kind MethodTokenRecognizer::RecognizeTokenKind(const String& name) {
  ASSERT(name.IsSymbol());
  if (Function::IsDynamicInvocationForwarderName(name)) {
    Thread* thread = Thread::Current();
    const auto& demangled_name = String::Handle(
        thread->zone(), Function::DemangleDynamicInvocationForwarderName(name));
    return RecognizeTokenKindHelper(demangled_name);
  } else {
    return RecognizeTokenKindHelper(name);
  }
}

#define RECOGNIZE_FACTORY(symbol, class_name, constructor_name, cid, fp)       \
  {Symbols::k##symbol##Id, cid, fp, #symbol ", " #cid},  // NOLINT

static struct {
  const intptr_t symbol_id;
  const intptr_t cid;
  const uint32_t finger_print;
  const char* const name;
} factory_recognizer_list[] = {RECOGNIZED_LIST_FACTORY_LIST(RECOGNIZE_FACTORY){
    Symbols::kIllegal, -1, 0, NULL}};

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

intptr_t FactoryRecognizer::GetResultCidOfListFactory(Zone* zone,
                                                      const Function& function,
                                                      intptr_t argument_count) {
  if (!function.IsFactory()) {
    return kDynamicCid;
  }

  const Class& owner = Class::Handle(zone, function.Owner());
  if ((owner.library() != Library::CoreLibrary()) &&
      (owner.library() != Library::TypedDataLibrary())) {
    return kDynamicCid;
  }

  if (owner.Name() == Symbols::List().raw()) {
    if (function.name() == Symbols::ListFactory().raw()) {
      ASSERT(argument_count == 1 || argument_count == 2);
      return (argument_count == 1) ? kGrowableObjectArrayCid : kArrayCid;
    } else if (function.name() == Symbols::ListFilledFactory().raw()) {
      ASSERT(argument_count == 3 || argument_count == 4);
      return (argument_count == 3) ? kArrayCid : kDynamicCid;
    }
  }

  return ResultCid(function);
}

}  // namespace dart
