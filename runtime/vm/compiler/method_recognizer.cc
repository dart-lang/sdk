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
                          Symbols::vm_exact_result_type(),
                          /*multiple=*/false, &option)) {
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

intptr_t MethodRecognizer::MethodKindToReceiverCid(Kind kind) {
  switch (kind) {
    case kObjectArrayGetIndexed:
    case kObjectArraySetIndexed:
    case kObjectArraySetIndexedUnchecked:
      return kArrayCid;

    case kGrowableArrayGetIndexed:
    case kGrowableArraySetIndexed:
    case kGrowableArraySetIndexedUnchecked:
      return kGrowableObjectArrayCid;

#define TYPED_DATA_GET_SET_INDEXED_CASES(clazz)                                \
  case k##clazz##ArrayGetIndexed:                                              \
  case k##clazz##ArraySetIndexed:                                              \
    return kTypedData##clazz##ArrayCid;                                        \
  case kExternal##clazz##ArrayGetIndexed:                                      \
    return kExternalTypedData##clazz##ArrayCid;                                \
  case k##clazz##ArrayViewGetIndexed:                                          \
    return kTypedData##clazz##ArrayViewCid;

      DART_CLASS_LIST_TYPED_DATA(TYPED_DATA_GET_SET_INDEXED_CASES);
#undef TYPED_DATA_GET_SET_INDEXED_CASES

    case kExternalUint8ArraySetIndexed:
      return kExternalTypedDataUint8ArrayCid;

    case kExternalUint8ClampedArraySetIndexed:
      return kExternalTypedDataUint8ClampedArrayCid;

    default:
      break;
  }
  UNREACHABLE();
  return kIllegalCid;
}

static const struct {
  const char* const function_name;
  const char* const enum_name;
} recognized_methods[MethodRecognizer::kNumRecognizedMethods] = {
    {"", "Unknown"},
#define RECOGNIZE_METHOD(library, class_name, function_name, enum_name, fp)    \
  {"" #function_name, #enum_name},
    RECOGNIZED_LIST(RECOGNIZE_METHOD)
#undef RECOGNIZE_METHOD
};

const char* MethodRecognizer::KindToCString(Kind kind) {
  if (kind >= kUnknown && kind < kNumRecognizedMethods)
    return recognized_methods[kind].enum_name;
  return "?";
}

const char* MethodRecognizer::KindToFunctionNameCString(Kind kind) {
  if (kind >= kUnknown && kind < kNumRecognizedMethods)
    return recognized_methods[kind].function_name;
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
  bool is_recognized = Library::FindPragma(
      Thread::Current(), /*only_core=*/true, *functionp,
      Symbols::vm_recognized(), /*multiple=*/false, &options);
  if (!is_recognized) return false;
  if (kind == nullptr) return true;

  ASSERT(options.IsString());
  ASSERT(String::Cast(options).Equals("asm-intrinsic") ||
         String::Cast(options).Equals("graph-intrinsic") ||
         String::Cast(options).Equals("other"));
  return String::Cast(options).Equals(kind);
}

static bool IsAssemblerIntrinsic(MethodRecognizer::Kind kind) {
  switch (kind) {
#define RECOGNIZE_METHOD(library, class_name, function_name, enum_name, fp)    \
  case MethodRecognizer::k##enum_name:
    ASM_INTRINSICS_LIST(RECOGNIZE_METHOD)
#undef RECOGNIZE_METHOD
    return true;
    default:
      return false;
  }
}

static bool IsGraphIntrinsic(MethodRecognizer::Kind kind) {
  switch (kind) {
#define RECOGNIZE_METHOD(library, class_name, function_name, enum_name, fp)    \
  case MethodRecognizer::k##enum_name:
    GRAPH_INTRINSICS_LIST(RECOGNIZE_METHOD)
#undef RECOGNIZE_METHOD
    return true;
    default:
      return false;
  }
}

void MethodRecognizer::InitializeState() {
  Library& lib = Library::Handle();
  Function& func = Function::Handle();
  bool fingerprints_match = true;

#define RECOGNIZE_METHOD(library, class_name, function_name, enum_name, fp)    \
  lib = Library::library();                                                    \
  func = Library::GetFunction(lib, #class_name, #function_name);               \
  if (!func.IsNull()) {                                                        \
    fingerprints_match =                                                       \
        func.CheckSourceFingerprint(fp) && fingerprints_match;                 \
    func.set_recognized_kind(k##enum_name);                                    \
    if (IsAssemblerIntrinsic(k##enum_name)) {                                  \
      func.reset_unboxed_parameters_and_return();                              \
      func.set_is_intrinsic(true);                                             \
    } else if (IsGraphIntrinsic(k##enum_name)) {                               \
      func.set_is_intrinsic(true);                                             \
    }                                                                          \
  } else if (!FLAG_precompiled_mode) {                                         \
    fingerprints_match = false;                                                \
    OS::PrintErr("Missing %s %s::%s\n", #library, #class_name,                 \
                 #function_name);                                              \
  }
  RECOGNIZED_LIST(RECOGNIZE_METHOD)
#undef RECOGNIZE_METHOD

#define SET_FUNCTION_BIT(library, class_name, function_name, dest, fp, setter, \
                         value)                                                \
  lib = Library::library();                                                    \
  func = Library::GetFunction(lib, #class_name, #function_name);               \
  if (!func.IsNull()) {                                                        \
    fingerprints_match =                                                       \
        func.CheckSourceFingerprint(fp) && fingerprints_match;                 \
    func.setter(value);                                                        \
  } else if (!FLAG_precompiled_mode) {                                         \
    OS::PrintErr("Missing %s::%s\n", #class_name, #function_name);             \
    fingerprints_match = false;                                                \
  }

#define SET_IS_POLYMORPHIC_TARGET(library, class_name, function_name, dest,    \
                                  fp)                                          \
  SET_FUNCTION_BIT(library, class_name, function_name, dest, fp,               \
                   set_is_polymorphic_target, true)

  POLYMORPHIC_TARGET_LIST(SET_IS_POLYMORPHIC_TARGET);

#undef SET_RECOGNIZED_KIND
#undef SET_IS_POLYMORPHIC_TARGET
#undef SET_FUNCTION_BIT

  if (!fingerprints_match) {
    // Private names are mangled. Mangling depends on Library::private_key_.
    // If registering a new bootstrap library, add at the end.
    FATAL(
        "FP mismatch while recognizing methods. If the behavior of "
        "these functions has changed, then changes are also needed in "
        "the VM's compiler. Otherwise the fingerprint can simply be "
        "updated in recognized_methods_list.h\n");
  }
}

static Token::Kind RecognizeTokenKindHelper(const String& name) {
  if (name.ptr() == Symbols::Plus().ptr()) {
    return Token::kADD;
  } else if (name.ptr() == Symbols::Minus().ptr()) {
    return Token::kSUB;
  } else if (name.ptr() == Symbols::Star().ptr()) {
    return Token::kMUL;
  } else if (name.ptr() == Symbols::Slash().ptr()) {
    return Token::kDIV;
  } else if (name.ptr() == Symbols::TruncDivOperator().ptr()) {
    return Token::kTRUNCDIV;
  } else if (name.ptr() == Symbols::Percent().ptr()) {
    return Token::kMOD;
  } else if (name.ptr() == Symbols::BitOr().ptr()) {
    return Token::kBIT_OR;
  } else if (name.ptr() == Symbols::Ampersand().ptr()) {
    return Token::kBIT_AND;
  } else if (name.ptr() == Symbols::Caret().ptr()) {
    return Token::kBIT_XOR;
  } else if (name.ptr() == Symbols::LeftShiftOperator().ptr()) {
    return Token::kSHL;
  } else if (name.ptr() == Symbols::RightShiftOperator().ptr()) {
    return Token::kSHR;
  } else if (name.ptr() == Symbols::UnsignedRightShiftOperator().ptr()) {
    return Token::kUSHR;
  } else if (name.ptr() == Symbols::Tilde().ptr()) {
    return Token::kBIT_NOT;
  } else if (name.ptr() == Symbols::UnaryMinus().ptr()) {
    return Token::kNEGATE;
  } else if (name.ptr() == Symbols::EqualOperator().ptr()) {
    return Token::kEQ;
  } else if (name.ptr() == Symbols::Token(Token::kNE).ptr()) {
    return Token::kNE;
  } else if (name.ptr() == Symbols::LAngleBracket().ptr()) {
    return Token::kLT;
  } else if (name.ptr() == Symbols::RAngleBracket().ptr()) {
    return Token::kGT;
  } else if (name.ptr() == Symbols::LessEqualOperator().ptr()) {
    return Token::kLTE;
  } else if (name.ptr() == Symbols::GreaterEqualOperator().ptr()) {
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

#define RECOGNIZE_FACTORY(symbol, library, class_name, constructor_name, cid,  \
                          fp)                                                  \
  {Symbols::k##symbol##Id, cid, fp, #symbol ", " #cid},  // NOLINT

static const struct {
  const intptr_t symbol_id;
  const intptr_t cid;
  const uint32_t finger_print;
  const char* const name;
} factory_recognizer_list[] = {RECOGNIZED_LIST_FACTORY_LIST(RECOGNIZE_FACTORY){
    Symbols::kIllegal, -1, 0, nullptr}};

#undef RECOGNIZE_FACTORY

intptr_t FactoryRecognizer::ResultCid(const Function& factory) {
  ASSERT(factory.IsFactory());
  const Class& function_class = Class::Handle(factory.Owner());
  const Library& lib = Library::Handle(function_class.library());
  ASSERT((lib.ptr() == Library::CoreLibrary()) ||
         (lib.ptr() == Library::TypedDataLibrary()));
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

  if (owner.Name() == Symbols::List().ptr()) {
    if (function.name() == Symbols::ListFactory().ptr()) {
      ASSERT(argument_count == 1 || argument_count == 2);
      return (argument_count == 1) ? kGrowableObjectArrayCid : kArrayCid;
    } else if (function.name() == Symbols::ListFilledFactory().ptr()) {
      ASSERT(argument_count == 3 || argument_count == 4);
      return (argument_count == 3) ? kArrayCid : kDynamicCid;
    }
  }

  return ResultCid(function);
}

}  // namespace dart
