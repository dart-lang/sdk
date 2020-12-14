// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_METHOD_RECOGNIZER_H_
#define RUNTIME_VM_COMPILER_METHOD_RECOGNIZER_H_

#include "vm/allocation.h"
#include "vm/compiler/recognized_methods_list.h"
#include "vm/growable_array.h"
#include "vm/token.h"

namespace dart {

// Forward declarations.
class Function;
class Library;
class Object;
class String;
class Zone;

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name, fp) k##enum_name,
    RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
        kNumRecognizedMethods
  };

  static intptr_t NumArgsCheckedForStaticCall(const Function& function);

  // Try to find an annotation of the form
  //   @pragma("vm:exact-result-type", int)
  //   @pragma("vm:exact-result-type", "dart:core#_Smi")
  // and return the exact cid if found or kDynamicCid otherwise.
  //
  // See [result_type_pragma.md].
  static intptr_t ResultCidFromPragma(const Object& function_or_field);

  // Try to find an annotation of the form
  //   @pragma("vm:non-nullable-result-type")
  // and returns true iff `false` was specified in the annotation.
  //
  // See [pragmas.md].
  static bool HasNonNullableResultTypeFromPragma(
      const Object& function_or_field);

  static intptr_t MethodKindToReceiverCid(Kind kind);
  static const char* KindToCString(Kind kind);

  static bool IsMarkedAsRecognized(const Function& function,
                                   const char* kind = nullptr);
  static void InitializeState();

 private:
  static void Libraries(GrowableArray<Library*>* libs);
};

// Recognizes token corresponding to a method name.
class MethodTokenRecognizer : public AllStatic {
 public:
  static Token::Kind RecognizeTokenKind(const String& name);
};

// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return result cid of 'factory' if it is recognized.
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);

  // Return result cid of 'function' called with 'argument_count' arguments,
  // if function is a recognized list factory constructor.
  // Return kDynamicCid if function is not recognized.
  static intptr_t GetResultCidOfListFactory(Zone* zone,
                                            const Function& function,
                                            intptr_t argument_count);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_METHOD_RECOGNIZER_H_
