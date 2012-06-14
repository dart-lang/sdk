// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/exceptions.h"

#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/stack_frame.h"

namespace dart {

DEFINE_FLAG(bool, print_stack_trace_at_throw, false,
    "Prints a stack trace everytime a throw occurs.");

// Iterate through the stack frames and try to find a frame with an
// exception handler. Once found, set the pc, sp and fp so that execution
// can continue in that frame.
static bool FindExceptionHandler(uword* handler_pc,
                                 uword* handler_sp,
                                 uword* handler_fp,
                                 GrowableArray<uword>* stack_frame_pcs) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);
  while (!frame->IsEntryFrame()) {
    if (frame->IsDartFrame()) {
      stack_frame_pcs->Add(frame->pc());
      if (frame->FindExceptionHandler(handler_pc)) {
        *handler_sp = frame->sp();
        *handler_fp = frame->fp();
        return true;
      }
    }
    frame = frames.NextFrame();
    ASSERT(frame != NULL);
  }
  ASSERT(frame->IsEntryFrame());
  *handler_pc = frame->pc();
  *handler_sp = frame->sp();
  *handler_fp = frame->fp();
  return false;
}


static void FindErrorHandler(uword* handler_pc,
                             uword* handler_sp,
                             uword* handler_fp) {
  // TODO(turnidge): Is there a faster way to get the next entry frame?
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);
  while (!frame->IsEntryFrame()) {
    frame = frames.NextFrame();
    ASSERT(frame != NULL);
  }
  ASSERT(frame->IsEntryFrame());
  *handler_pc = frame->pc();
  *handler_sp = frame->sp();
  *handler_fp = frame->fp();
}


static void ThrowExceptionHelper(const Instance& incoming_exception,
                                 const Instance& existing_stacktrace) {
  Instance& exception = Instance::Handle(incoming_exception.raw());
  if (exception.IsNull()) {
    GrowableArray<const Object*> arguments;
    exception ^= Exceptions::Create(Exceptions::kNullPointer, arguments);
  }
  uword handler_pc = 0;
  uword handler_sp = 0;
  uword handler_fp = 0;
  GrowableArray<uword> stack_frame_pcs;
  bool handler_exists = FindExceptionHandler(&handler_pc,
                                             &handler_sp,
                                             &handler_fp,
                                             &stack_frame_pcs);
  // TODO(5411263): At some point we can optimize by figuring out if a
  // stack trace is needed based on whether the catch code specifies a
  // stack trace object or there is a rethrow in the catch clause.
  Stacktrace& stacktrace = Stacktrace::Handle();
  if (stack_frame_pcs.length() > 0) {
    if (existing_stacktrace.IsNull()) {
      stacktrace = Stacktrace::New(stack_frame_pcs);
    } else {
      stacktrace ^= existing_stacktrace.raw();
      stacktrace.Append(stack_frame_pcs);
    }
  } else {
    stacktrace ^= existing_stacktrace.raw();
  }
  if (FLAG_print_stack_trace_at_throw) {
    OS::Print("Exception '%s' thrown:\n", exception.ToCString());
    OS::Print("%s\n", stacktrace.ToCString());
  }
  if (handler_exists) {
    // Found a dart handler for the exception, jump to it.
    CPU::JumpToExceptionHandler(handler_pc,
                                handler_sp,
                                handler_fp,
                                exception,
                                stacktrace);
  } else {
    // No dart exception handler found in this invocation sequence,
    // so we create an unhandled exception object and return to the
    // invocation stub so that it returns this unhandled exception
    // object. The C++ code which invoked this dart sequence can check
    // and do the appropriate thing (rethrow the exception to the
    // dart invocation sequence above it, print diagnostics and terminate
    // the isolate etc.).
    const UnhandledException& unhandled_exception = UnhandledException::Handle(
        UnhandledException::New(exception, stacktrace));
    CPU::JumpToErrorHandler(handler_pc,
                            handler_sp,
                            handler_fp,
                            unhandled_exception);
  }
  UNREACHABLE();
}


// Static helpers for allocating, initializing, and throwing an error instance.

// Return the script of the Dart function that called the native entry or the
// runtime entry. The frame iterator points to the callee.
RawScript* Exceptions::GetCallerScript(DartFrameIterator* iterator) {
  StackFrame* caller_frame = iterator->NextFrame();
  ASSERT(caller_frame != NULL && caller_frame->IsDartFrame());
  const Function& caller = Function::Handle(caller_frame->LookupDartFunction());
  ASSERT(!caller.IsNull());
  const Class& caller_class = Class::Handle(caller.owner());
  return caller_class.script();
}


// Allocate a new instance of the given class name.
// TODO(hausner): Rename this NewCoreInstance to call out the fact that
// the class name is resolved in the core library implicitly?
RawInstance* Exceptions::NewInstance(const char* class_name) {
  const String& cls_name = String::Handle(String::NewSymbol(class_name));
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  Class& cls = Class::Handle(core_lib.LookupClass(cls_name));
  ASSERT(!cls.IsNull());
  // There are no parameterized error types, so no need to set type arguments.
  return Instance::New(cls);
}


// Assign the value to the field given by its name in the given instance.
void Exceptions::SetField(const Instance& instance,
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
void Exceptions::SetLocationFields(const Instance& instance,
                                   const Class& cls,
                                   const Script& script,
                                   intptr_t location) {
  SetField(instance, cls, "url", String::Handle(script.url()));
  intptr_t line, column;
  script.GetTokenLocation(location, &line, &column);
  SetField(instance, cls, "line", Smi::Handle(Smi::New(line)));
  SetField(instance, cls, "column", Smi::Handle(Smi::New(column)));
}


// Allocate, initialize, and throw a TypeError.
void Exceptions::CreateAndThrowTypeError(intptr_t location,
                                         const String& src_type_name,
                                         const String& dst_type_name,
                                         const String& dst_name,
                                         const String& malformed_error) {
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

  // Initialize field 'malformedError'.
  SetField(type_error, cls, "malformedError", malformed_error);

  // Type errors in the core library may be difficult to diagnose.
  // Print type error information before throwing the error when debugging.
  if (FLAG_print_stack_trace_at_throw) {
    if (!malformed_error.IsNull()) {
      OS::Print("%s\n", malformed_error.ToCString());
    }
    intptr_t line, column;
    script.GetTokenLocation(location, &line, &column);
    OS::Print("'%s': Failed type check: line %d pos %d: ",
              String::Handle(script.url()).ToCString(), line, column);
    if (!dst_name.IsNull() && (dst_name.Length() > 0)) {
      OS::Print("type '%s' is not a subtype of type '%s' of '%s'.\n",
                src_type_name.ToCString(),
                dst_type_name.ToCString(),
                dst_name.ToCString());
    } else {
      OS::Print("malformed type used.\n",
                String::Handle(script.url()).ToCString(),
                line, column);
    }
  }
  // Throw TypeError instance.
  Exceptions::Throw(type_error);
  UNREACHABLE();
}


void Exceptions::Throw(const Instance& exception) {
  Isolate* isolate = Isolate::Current();
  isolate->debugger()->SignalExceptionThrown(exception);
  // Null object is a valid exception object.
  ThrowExceptionHelper(exception, Instance::Handle(isolate));
}


void Exceptions::ReThrow(const Instance& exception,
                         const Instance& stacktrace) {
  // Null object is a valid exception object.
  ThrowExceptionHelper(exception, stacktrace);
}


void Exceptions::PropagateError(const Object& obj) {
  ASSERT(Isolate::Current()->top_exit_frame_info() != 0);
  Error& error = Error::Handle();
  error ^= obj.raw();
  if (error.IsUnhandledException()) {
    // If the error object represents an unhandled exception, then
    // rethrow the exception in the normal fashion.
    UnhandledException& uhe = UnhandledException::Handle();
    uhe ^= error.raw();
    const Instance& exc = Instance::Handle(uhe.exception());
    const Instance& stk = Instance::Handle(uhe.stacktrace());
    Exceptions::ReThrow(exc, stk);
  } else {
    // Return to the invocation stub and return this error object.  The
    // C++ code which invoked this dart sequence can check and do the
    // appropriate thing.
    uword handler_pc = 0;
    uword handler_sp = 0;
    uword handler_fp = 0;
    FindErrorHandler(&handler_pc, &handler_sp, &handler_fp);
    CPU::JumpToErrorHandler(handler_pc, handler_sp, handler_fp, error);
  }
  UNREACHABLE();
}


void Exceptions::ThrowByType(
    ExceptionType type, const GrowableArray<const Object*>& arguments) {
  const Object& result = Object::Handle(Create(type, arguments));
  if (result.IsError()) {
    // We got an error while constructing the exception object.
    // Propagate the error instead of throwing the exception.
    Error& error = Error::Handle();
    error ^= result.raw();
    PropagateError(error);
  } else {
    ASSERT(result.IsInstance());
    Instance& exception = Instance::Handle();
    exception ^= result.raw();
    Throw(exception);
  }
}


RawObject* Exceptions::Create(
    ExceptionType type, const GrowableArray<const Object*>& arguments) {
  Library& library = Library::Handle();
  String& class_name = String::Handle();
  switch (type) {
    case kIndexOutOfRange:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("IndexOutOfRangeException");
      break;
    case kIllegalArgument:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("IllegalArgumentException");
      break;
    case kNoSuchMethod:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("NoSuchMethodException");
      break;
    case kClosureArgumentMismatch:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("ClosureArgumentMismatchException");
      break;
    case kObjectNotClosure:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("ObjectNotClosureException");
      break;
    case kBadNumberFormat:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("BadNumberFormatException");
      break;
    case kStackOverflow:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("StackOverflowException");
      break;
    case kOutOfMemory:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("OutOfMemoryException");
      break;
    case kWrongArgumentCount:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("WrongArgumentCountException");
      break;
    case kInternalError:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("InternalError");
      break;
    case kNullPointer:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("NullPointerException");
      break;
    case kIllegalJSRegExp:
      library = Library::CoreLibrary();
      class_name = String::NewSymbol("IllegalJSRegExpException");
      break;
    case kIsolateSpawn:
      library = Library::IsolateLibrary();
      class_name = String::NewSymbol("IsolateSpawnException");
      break;
  }

  return DartLibraryCalls::ExceptionCreate(library, class_name, arguments);
}

}  // namespace dart
