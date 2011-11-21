// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
DECLARE_FLAG(bool, print_stack_trace_at_throw);


// Static helpers for allocating, initializing, and throwing an error instance.

// Return the script of the Dart function that called the native entry or the
// runtime entry. The frame iterator points to the callee.
static RawScript* GetCallerScript(DartFrameIterator* iterator) {
  DartFrame* caller_frame = iterator->NextFrame();
  ASSERT(caller_frame != NULL);
  const Function& caller = Function::Handle(caller_frame->LookupDartFunction());
  ASSERT(!caller.IsNull());
  const Class& caller_class = Class::Handle(caller.owner());
  return caller_class.script();
}


// Allocate a new instance of the given class name.
// TODO(hausner): Rename this NewCoreInstance to call out the fact that
// the class name is resolved in the core library implicitly?
static RawInstance* NewInstance(const char* class_name) {
  const String& cls_name = String::Handle(String::NewSymbol(class_name));
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  Class& cls = Class::Handle(core_lib.LookupClass(cls_name));
  ASSERT(!cls.IsNull());
  // There are no parameterized error types, so no need to set type arguments.
  return Instance::New(cls);
}


// Assign the value to the field given by its name in the given instance.
static void SetField(const Instance& instance,
                     const Class& cls,
                     const char* field_name,
                     const Object& value) {
  const Field& field = Field::Handle(cls.LookupInstanceField(
      String::Handle(String::NewSymbol(field_name))));
  ASSERT(!field.IsNull());
  instance.SetField(field, value);
}


// Initialize the fields 'url', 'line', and 'column' in the given instance
// according to the given token location in the given script.
static void SetLocationFields(const Instance& instance,
                              const Class& cls,
                              const Script& script,
                              intptr_t location) {
  SetField(instance, cls, "url", String::Handle(script.url()));
  intptr_t line, column;
  script.GetTokenLocation(location, &line, &column);
  SetField(instance, cls, "line", Smi::Handle(Smi::New(line)));
  SetField(instance, cls, "column", Smi::Handle(Smi::New(column)));
}


// Allocate and throw a new AssertionError.
// Arg0: index of the first token of the failed assertion.
// Arg1: index of the first token after the failed assertion.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(AssertionError_throwNew, 2) {
  intptr_t assertion_start = Smi::CheckedHandle(arguments->At(0)).Value();
  intptr_t assertion_end = Smi::CheckedHandle(arguments->At(1)).Value();

  // Allocate a new instance of type AssertionError.
  const Instance& assertion_error = Instance::Handle(
      NewInstance("AssertionError"));

  // Initialize 'url', 'line', and 'column' fields.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(GetCallerScript(&iterator));
  const Class& cls = Class::Handle(assertion_error.clazz());
  SetLocationFields(assertion_error, cls, script, assertion_start);

  // Initialize field 'failed_assertion' with source snippet.
  intptr_t from_line, from_column;
  script.GetTokenLocation(assertion_start, &from_line, &from_column);
  intptr_t to_line, to_column;
  script.GetTokenLocation(assertion_end, &to_line, &to_column);
  SetField(assertion_error, cls, "failedAssertion", String::Handle(
      script.GetSnippet(from_line, from_column, to_line, to_column)));

  // Throw AssertionError instance.
  Exceptions::Throw(assertion_error);
  UNREACHABLE();
}


// Allocate, initialize, and throw a TypeError.
static void ThrowTypeError(intptr_t location,
                           const String& src_type_name,
                           const String& dst_type_name,
                           const String& dst_name) {
  // Allocate a new instance of TypeError.
  const Instance& type_error = Instance::Handle(NewInstance("TypeError"));

  // Initialize 'url', 'line', and 'column' fields.
  DartFrameIterator iterator;
  const Script& script = Script::Handle(GetCallerScript(&iterator));
  const Class& cls = Class::Handle(type_error.clazz());
  // Location fields are defined in AssertionError, the superclass of TypeError.
  const Class& assertion_error_class = Class::Handle(cls.SuperClass());
  SetLocationFields(type_error, assertion_error_class, script, location);

  // Initialize field 'failedAssertion' in AssertionError superclass.
  // Printing the src_obj value would be possible, but ToString() is expensive
  // and not meaningful for all classes, so we just print '$expr instanceof...'.
  // Users should look at TypeError.ToString(), which contains more useful
  // information than AssertionError.failedAssertion.
  String& failed_assertion = String::Handle(String::New("$expr instanceof "));
  failed_assertion = String::Concat(failed_assertion, dst_type_name);
  SetField(type_error,
           assertion_error_class,
           "failedAssertion",
           failed_assertion);

  // Initialize field 'srcType'.
  SetField(type_error, cls, "srcType", src_type_name);

  // Initialize field 'dstType'.
  SetField(type_error, cls, "dstType", dst_type_name);

  // Initialize field 'dstName'.
  SetField(type_error, cls, "dstName", dst_name);

  // Type errors in the core library may be difficult to diagnose.
  // Print type error information before throwing the error when debugging.
  if (FLAG_print_stack_trace_at_throw) {
    intptr_t line, column;
    script.GetTokenLocation(location, &line, &column);
    OS::Print("'%s': Failed type check: line %d pos %d: "
              "type '%s' is not assignable to type '%s' of '%s'.\n",
              String::Handle(script.url()).ToCString(),
              line, column,
              src_type_name.ToCString(),
              dst_type_name.ToCString(),
              dst_name.ToCString());
  }
  // Throw TypeError instance.
  Exceptions::Throw(type_error);
  UNREACHABLE();
}


// Allocate and throw a new FallThroughError.
// Arg0: index of the case clause token into which we fall through.
// Return value: none, throws an exception.
DEFINE_NATIVE_ENTRY(FallThroughError_throwNew, 1) {
  GET_NATIVE_ARGUMENT(Smi, smi_pos, arguments->At(0));
  intptr_t fallthrough_pos = smi_pos.Value();

  // Allocate a new instance of type FallThroughError.
  const Instance& fallthrough_error =
      Instance::Handle(NewInstance("FallThroughError"));
  ASSERT(!fallthrough_error.IsNull());

  // Initialize 'url' and 'line' fields.
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  const Script& script = Script::Handle(GetCallerScript(&iterator));
  const Class& cls = Class::Handle(fallthrough_error.clazz());
  SetField(fallthrough_error, cls, "url", String::Handle(script.url()));
  intptr_t line, column;
  script.GetTokenLocation(fallthrough_pos, &line, &column);
  SetField(fallthrough_error, cls, "line", Smi::Handle(Smi::New(line)));

  // Throw FallThroughError instance.
  Exceptions::Throw(fallthrough_error);
  UNREACHABLE();
}


// Check that the type of the given instance is assignable to the given type.
// Arg0: index of the token of the assignment (source location).
// Arg1: instance being assigned.
// Arg2: type being assigned to.
// Arg3: type arguments of the instantiator of the type being assigned to.
// Arg4: name of instance being assigned to.
// Return value: instance if assignable, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 5) {
  ASSERT(arguments.Count() == kTypeCheckRuntimeEntry.argument_count());
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  const Instance& src_instance = Instance::CheckedHandle(arguments.At(1));
  const Type& dst_type = Type::CheckedHandle(arguments.At(2));
  const TypeArguments& dst_type_instantiator =
      TypeArguments::CheckedHandle(arguments.At(3));
  const String& dst_name = String::CheckedHandle(arguments.At(4));
  ASSERT(!dst_type.IsDynamicType());  // No need to check assignment.
  ASSERT(!src_instance.IsNull());  // Already checked in inlined code.

  const bool is_assignable =
      src_instance.IsAssignableTo(dst_type, dst_type_instantiator);

  if (FLAG_trace_type_checks) {
    const Type& src_type = Type::Handle(src_instance.GetType());
    Type& instantiated_dst_type = Type::Handle(dst_type.raw());
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before printing.
      instantiated_dst_type =
          dst_type.InstantiateFrom(dst_type_instantiator, 0);
    }
    OS::Print("TypeCheck: '%s' %s assignable to '%s'.\n",
              String::Handle(src_type.Name()).ToCString(),
              is_assignable ? "is" : "is not",
              String::Handle(dst_type.Name()).ToCString());
  }
  if (!is_assignable) {
    const Type& src_type = Type::Handle(src_instance.GetType());
    const String& src_type_name = String::Handle(src_type.Name());
    String& dst_type_name = String::Handle();
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      const Type& instantiated_dst_type = Type::Handle(
          dst_type.InstantiateFrom(dst_type_instantiator, 0));
      dst_type_name = instantiated_dst_type.Name();
    } else {
      dst_type_name = dst_type.Name();
    }
    ThrowTypeError(location, src_type_name, dst_type_name, dst_name);
    UNREACHABLE();
  }
  arguments.SetReturn(src_instance);
}


// Report that the type of the given object is not bool in conditional context.
// Arg0: index of the token of the assignment (source location).
// Arg1: bad object.
// Return value: none, throws a TypeError.
DEFINE_RUNTIME_ENTRY(ConditionTypeError, 2) {
  ASSERT(arguments.Count() ==
      kConditionTypeErrorRuntimeEntry.argument_count());
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  const Instance& src_instance = Instance::CheckedHandle(arguments.At(1));
  ASSERT(src_instance.IsNull() || !src_instance.IsBool());
  const char* msg = "boolean expression";
  const Type& bool_interface = Type::Handle(Type::BoolInterface());
  const Type& src_type = Type::Handle(src_instance.GetType());
  const String& src_type_name = String::Handle(src_type.Name());
  const String& bool_type_name = String::Handle(bool_interface.Name());
  ThrowTypeError(location, src_type_name, bool_type_name,
                 String::Handle(String::NewSymbol(msg)));
  UNREACHABLE();
}


// Check that the type of each element of the given array is assignable to the
// given type.
// Arg0: index of the token of the rest argument declaration (source location).
// Arg1: rest argument array.
// Arg2: element declaration type.
// Arg3: type arguments of the instantiator of the element declaration type.
// Arg4: name of object being assigned to, i.e. name of rest argument.
// Return value: null if assignable, otherwise allocate and throw a TypeError.
DEFINE_RUNTIME_ENTRY(RestArgumentTypeCheck, 5) {
  ASSERT(arguments.Count() ==
      kRestArgumentTypeCheckRuntimeEntry.argument_count());
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  const Array& rest_array = Array::CheckedHandle(arguments.At(1));
  const Type& element_type = Type::CheckedHandle(arguments.At(2));
  const TypeArguments& element_type_instantiator =
      TypeArguments::CheckedHandle(arguments.At(3));
  const String& rest_name = String::CheckedHandle(arguments.At(4));
  ASSERT(!element_type.IsDynamicType());  // No need to check assignment.
  ASSERT(!rest_array.IsNull());

  Instance& elem = Instance::Handle();
  for (intptr_t i = 0; i < rest_array.Length(); i++) {
    elem ^= rest_array.At(i);
    if (!elem.IsNull() &&
        !elem.IsAssignableTo(element_type, element_type_instantiator)) {
      // Allocate and throw a new instance of TypeError.
      char buf[256];
      OS::SNPrint(buf, sizeof(buf), "%s[%d]",
                  rest_name.ToCString(), static_cast<int>(i));
      const String& src_type_name =
          String::Handle(Type::Handle(elem.GetType()).Name());
      String& dst_type_name = String::Handle();
      if (!element_type.IsInstantiated()) {
        // Instantiate element_type before reporting the error.
        const Type& instantiated_element_type = Type::Handle(
            element_type.InstantiateFrom(element_type_instantiator, 0));
        dst_type_name = instantiated_element_type.Name();
      } else {
        dst_type_name = element_type.Name();
      }
      const String& dst_name = String::Handle(String::New(buf));
      ThrowTypeError(location, src_type_name, dst_type_name, dst_name);
      UNREACHABLE();
    }
  }
}

}  // namespace dart
