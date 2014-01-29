// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"

namespace dart {

// Allocate and throw a new AssertionError.
// Arg0: index of the first token of the failed assertion.
// Arg1: index of the first token after the failed assertion.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(AssertionError_throwNew, 2) {
  // No need to type check the arguments. This function can only be called
  // internally from the VM.
  intptr_t assertion_start =
      Smi::CheckedHandle(arguments->NativeArgAt(0)).Value();
  intptr_t assertion_end =
      Smi::CheckedHandle(arguments->NativeArgAt(1)).Value();

  const Array& args = Array::Handle(Array::New(4));

  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(Exceptions::GetCallerScript(&iterator));

  // Initialize argument 'failed_assertion' with source snippet.
  intptr_t from_line, from_column;
  script.GetTokenLocation(assertion_start, &from_line, &from_column);
  intptr_t to_line, to_column;
  script.GetTokenLocation(assertion_end, &to_line, &to_column);
  // The snippet will extract the correct assertion code even if the source
  // is generated.
  args.SetAt(0, String::Handle(
      script.GetSnippet(from_line, from_column, to_line, to_column)));

  // Initialize location arguments starting at position 1.
  // Do not set a column if the source has been generated as it will be wrong.
  args.SetAt(1, String::Handle(script.url()));
  args.SetAt(2, Smi::Handle(Smi::New(from_line)));
  args.SetAt(3, Smi::Handle(Smi::New(script.HasSource() ? from_column : -1)));

  Exceptions::ThrowByType(Exceptions::kAssertion, args);
  UNREACHABLE();
  return Object::null();
}


// Allocate and throw a new TypeError or CastError.
// Arg0: index of the token of the failed type check.
// Arg1: src value.
// Arg2: dst type name.
// Arg3: dst name.
// Arg4: type error message.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(TypeError_throwNew, 5) {
  // No need to type check the arguments. This function can only be called
  // internally from the VM.
  intptr_t location = Smi::CheckedHandle(arguments->NativeArgAt(0)).Value();
  const Instance& src_value =
      Instance::CheckedHandle(arguments->NativeArgAt(1));
  const String& dst_type_name =
      String::CheckedHandle(arguments->NativeArgAt(2));
  const String& dst_name = String::CheckedHandle(arguments->NativeArgAt(3));
  const String& error_msg = String::CheckedHandle(arguments->NativeArgAt(4));
  const String& src_type_name =
      String::Handle(Type::Handle(src_value.GetType()).UserVisibleName());
  Exceptions::CreateAndThrowTypeError(location, src_type_name,
                                      dst_type_name, dst_name, error_msg);
  UNREACHABLE();
  return Object::null();
}


// Allocate and throw a new FallThroughError.
// Arg0: index of the case clause token into which we fall through.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(FallThroughError_throwNew, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_pos, arguments->NativeArgAt(0));
  intptr_t fallthrough_pos = smi_pos.Value();

  const Array& args = Array::Handle(Array::New(2));

  // Initialize 'url' and 'line' arguments.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(Exceptions::GetCallerScript(&iterator));
  args.SetAt(0, String::Handle(script.url()));
  intptr_t line;
  script.GetTokenLocation(fallthrough_pos, &line, NULL);
  args.SetAt(1, Smi::Handle(Smi::New(line)));

  Exceptions::ThrowByType(Exceptions::kFallThrough, args);
  UNREACHABLE();
  return Object::null();
}


// Allocate and throw a new AbstractClassInstantiationError.
// Arg0: Token position of allocation statement.
// Arg1: class name of the abstract class that cannot be instantiated.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(AbstractClassInstantiationError_throwNew, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_pos, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, class_name, arguments->NativeArgAt(1));
  intptr_t error_pos = smi_pos.Value();

  const Array& args = Array::Handle(Array::New(3));

  // Initialize 'className', 'url' and 'line' arguments.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(Exceptions::GetCallerScript(&iterator));
  args.SetAt(0, class_name);
  args.SetAt(1, String::Handle(script.url()));
  intptr_t line;
  script.GetTokenLocation(error_pos, &line, NULL);
  args.SetAt(2, Smi::Handle(Smi::New(line)));

  Exceptions::ThrowByType(Exceptions::kAbstractClassInstantiation, args);
  UNREACHABLE();
  return Object::null();
}

}  // namespace dart
