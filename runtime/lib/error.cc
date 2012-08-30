// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/error.h"

#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"

namespace dart {

DEFINE_FLAG(bool, trace_type_checks, false, "Trace runtime type checks.");

// Allocate and throw a new AssertionError.
// Arg0: index of the first token of the failed assertion.
// Arg1: index of the first token after the failed assertion.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(AssertionError_throwNew, 2) {
  // No need to type check the arguments. This function can only be called
  // internally from the VM.
  intptr_t assertion_start = Smi::CheckedHandle(arguments->At(0)).Value();
  intptr_t assertion_end = Smi::CheckedHandle(arguments->At(1)).Value();

  // Allocate a new instance of type AssertionError.
  const Instance& assertion_error = Instance::Handle(
      Exceptions::NewInstance("AssertionErrorImplementation"));

  // Initialize 'url', 'line', and 'column' fields.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(Exceptions::GetCallerScript(&iterator));
  const Class& cls = Class::Handle(assertion_error.clazz());
  Exceptions::SetLocationFields(assertion_error, cls, script, assertion_start);

  // Initialize field 'failed_assertion' with source snippet.
  intptr_t from_line, from_column;
  script.GetTokenLocation(assertion_start, &from_line, &from_column);
  intptr_t to_line, to_column;
  script.GetTokenLocation(assertion_end, &to_line, &to_column);
  Exceptions::SetField(assertion_error, cls, "failedAssertion", String::Handle(
      script.GetSnippet(from_line, from_column, to_line, to_column)));

  // Throw AssertionError instance.
  Exceptions::Throw(assertion_error);
  UNREACHABLE();
  return Object::null();
}


// Allocate and throw a new TypeError.
// Arg0: index of the token of the failed type check.
// Arg1: src value.
// Arg2: dst type name.
// Arg3: dst name.
// Arg4: malformed type error message.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(TypeError_throwNew, 5) {
  // No need to type check the arguments. This function can only be called
  // internally from the VM.
  intptr_t location = Smi::CheckedHandle(arguments->At(0)).Value();
  const Instance& src_value = Instance::CheckedHandle(arguments->At(1));
  const String& dst_type_name = String::CheckedHandle(arguments->At(2));
  const String& dst_name = String::CheckedHandle(arguments->At(3));
  const String& malformed_error = String::CheckedHandle(arguments->At(4));
  const String& src_type_name =
      String::Handle(Type::Handle(src_value.GetType()).UserVisibleName());
  Exceptions::CreateAndThrowTypeError(location, src_type_name,
                                      dst_type_name, dst_name, malformed_error);
  UNREACHABLE();
  return Object::null();
}


// Allocate and throw a new FallThroughError.
// Arg0: index of the case clause token into which we fall through.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(FallThroughError_throwNew, 1) {
  GET_NATIVE_ARGUMENT(Smi, smi_pos, arguments->At(0));
  intptr_t fallthrough_pos = smi_pos.Value();

  // Allocate a new instance of type FallThroughError.
  const Instance& fallthrough_error = Instance::Handle(Exceptions::NewInstance(
      "FallThroughErrorImplementation"));
  ASSERT(!fallthrough_error.IsNull());

  // Initialize 'url' and 'line' fields.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(Exceptions::GetCallerScript(&iterator));
  const Class& cls = Class::Handle(fallthrough_error.clazz());
  Exceptions::SetField(fallthrough_error, cls, "url",
                       String::Handle(script.url()));
  intptr_t line, column;
  script.GetTokenLocation(fallthrough_pos, &line, &column);
  Exceptions::SetField(fallthrough_error, cls, "line",
                       Smi::Handle(Smi::New(line)));

  // Throw FallThroughError instance.
  Exceptions::Throw(fallthrough_error);
  UNREACHABLE();
  return Object::null();
}


// Allocate and throw StaticResolutionException.
// Arg0: index of the static call that was not resolved at compile time.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(StaticResolutionException_throwNew, 1) {
  GET_NATIVE_ARGUMENT(Smi, smi_pos, arguments->At(0));
  intptr_t call_pos = smi_pos.Value();
  // Allocate a new instance of type StaticResolutionException.
  const Instance& resolution_exception =
      Instance::Handle(Exceptions::NewInstance("StaticResolutionException"));
  ASSERT(!resolution_exception.IsNull());

  // Initialize 'url', 'line', and 'column' fields.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(Exceptions::GetCallerScript(&iterator));
  const Class& cls = Class::Handle(resolution_exception.clazz());
  Exceptions::SetLocationFields(resolution_exception, cls, script, call_pos);

  intptr_t line, column;
  script.GetTokenLocation(call_pos, &line, &column);
  Exceptions::SetField(resolution_exception, cls, "failedResolutionLine",
                       String::Handle(script.GetLine(line)));

  Exceptions::Throw(resolution_exception);
  UNREACHABLE();
  return Object::null();
}

}  // namespace dart
