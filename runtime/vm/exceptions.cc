// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/exceptions.h"

#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, print_stacktrace_at_throw, false,
    "Prints a stack trace everytime a throw occurs.");


const char* Exceptions::kCastErrorDstName = "type cast";


// Iterate through the stack frames and try to find a frame with an
// exception handler. Once found, set the pc, sp and fp so that execution
// can continue in that frame.
static bool FindExceptionHandler(uword* handler_pc,
                                 uword* handler_sp,
                                 uword* handler_fp,
                                 const GrowableObjectArray& func_list,
                                 const GrowableObjectArray& code_list,
                                 const GrowableObjectArray& pc_offset_list) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  if (frame == NULL) {
    // We have no dart invocation frames and hence cannot find a handler
    // to return to.
    return false;
  }
  Function& func = Function::Handle();
  Code& code = Code::Handle();
  Smi& offset = Smi::Handle();
  while (!frame->IsEntryFrame()) {
    if (frame->IsDartFrame()) {
      func = frame->LookupDartFunction();
      code = frame->LookupDartCode();
      offset = Smi::New(frame->pc() - code.EntryPoint());
      func_list.Add(func);
      code_list.Add(code);
      pc_offset_list.Add(offset);
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


void JumpToExceptionHandler(uword program_counter,
                            uword stack_pointer,
                            uword frame_pointer,
                            const Instance& exception_object,
                            const Instance& stacktrace_object) {
  // The no_gc StackResource is unwound through the tear down of
  // stack resources below.
  NoGCScope no_gc;
  RawInstance* exception = exception_object.raw();
  RawInstance* stacktrace = stacktrace_object.raw();

  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }

  // Set up the appropriate register state and jump to the handler.
  typedef void (*ExcpHandler)(uword, uword, uword, RawInstance*, RawInstance*);
  ExcpHandler func = reinterpret_cast<ExcpHandler>(
      StubCode::JumpToExceptionHandlerEntryPoint());
  func(program_counter, stack_pointer, frame_pointer, exception, stacktrace);
  UNREACHABLE();
}


void JumpToErrorHandler(uword program_counter,
                        uword stack_pointer,
                        uword frame_pointer,
                        const Error& error) {
  // The no_gc StackResource is unwound through the tear down of
  // stack resources below.
  NoGCScope no_gc;
  ASSERT(!error.IsNull());
  RawError* raw_error = error.raw();

  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }

  // Set up the error object as the return value in EAX and continue
  // from the invocation stub.
  typedef void (*ErrorHandler)(uword, uword, uword, RawError*);
  ErrorHandler func = reinterpret_cast<ErrorHandler>(
      StubCode::JumpToErrorHandlerEntryPoint());
  func(program_counter, stack_pointer, frame_pointer, raw_error);
  UNREACHABLE();
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
  const GrowableObjectArray& func_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const GrowableObjectArray& code_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const GrowableObjectArray& pc_offset_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  bool handler_exists = FindExceptionHandler(&handler_pc,
                                             &handler_sp,
                                             &handler_fp,
                                             func_list,
                                             code_list,
                                             pc_offset_list);
  if (handler_pc == 0) {
    // There are no dart invocation frames on the stack so we do not
    // have a caller to return to. This is a case where we would have
    // to call the Isolate error handler and let it deal with the shutdown.
    // We report an error and shutdown the process as a temporary solution
    // until the isolate error handler stuff is implemented.
    ASSERT(!handler_exists);
    OS::PrintErr("Exception '%s' thrown:\n", exception.ToCString());
    OS::PrintErr("Exiting the process\n");
    OS::Exit(255);
  }
  // TODO(5411263): At some point we can optimize by figuring out if a
  // stack trace is needed based on whether the catch code specifies a
  // stack trace object or there is a rethrow in the catch clause.
  Stacktrace& stacktrace = Stacktrace::Handle();
  if (pc_offset_list.Length() != 0) {
    if (existing_stacktrace.IsNull()) {
      stacktrace = Stacktrace::New(func_list, code_list, pc_offset_list);
    } else {
      stacktrace ^= existing_stacktrace.raw();
      stacktrace.Append(func_list, code_list, pc_offset_list);
    }
  } else {
    stacktrace ^= existing_stacktrace.raw();
  }
  if (FLAG_print_stacktrace_at_throw) {
    OS::Print("Exception '%s' thrown:\n", exception.ToCString());
    OS::Print("%s\n", stacktrace.ToCString());
  }
  if (handler_exists) {
    // Found a dart handler for the exception, jump to it.
    JumpToExceptionHandler(handler_pc,
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
    JumpToErrorHandler(handler_pc, handler_sp, handler_fp, unhandled_exception);
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
  return caller.script();
}


// Allocate a new instance of the given class name.
// TODO(hausner): Rename this NewCoreInstance to call out the fact that
// the class name is resolved in the core library implicitly?
RawInstance* Exceptions::NewInstance(const char* class_name) {
  const String& cls_name = String::Handle(Symbols::New(class_name));
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
      String::Handle(Symbols::New(field_name))));
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
  // Allocate a new instance of TypeError or CastError.
  Instance& type_error = Instance::Handle();
  Class& cls = Class::Handle();
  if (dst_name.Equals(kCastErrorDstName)) {
    type_error = NewInstance("CastErrorImplementation");
    cls = type_error.clazz();
    cls = cls.SuperClass();
  } else {
    type_error = NewInstance("TypeErrorImplementation");
    cls = type_error.clazz();
  }

  // Initialize 'url', 'line', and 'column' fields.
  DartFrameIterator iterator;
  const Script& script = Script::Handle(GetCallerScript(&iterator));
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
  if (FLAG_print_stacktrace_at_throw) {
    if (!malformed_error.IsNull()) {
      OS::Print("%s\n", malformed_error.ToCString());
    }
    intptr_t line, column;
    script.GetTokenLocation(location, &line, &column);
    OS::Print("'%s': Failed type check: line %"Pd" pos %"Pd": ",
              String::Handle(script.url()).ToCString(), line, column);
    if (!dst_name.IsNull() && (dst_name.Length() > 0)) {
      OS::Print("type '%s' is not a subtype of type '%s' of '%s'.\n",
                src_type_name.ToCString(),
                dst_type_name.ToCString(),
                dst_name.ToCString());
    } else {
      OS::Print("malformed type used.\n");
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


void Exceptions::PropagateError(const Error& error) {
  ASSERT(Isolate::Current()->top_exit_frame_info() != 0);
  if (error.IsUnhandledException()) {
    // If the error object represents an unhandled exception, then
    // rethrow the exception in the normal fashion.
    const UnhandledException& uhe = UnhandledException::Cast(error);
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
    JumpToErrorHandler(handler_pc, handler_sp, handler_fp, error);
  }
  UNREACHABLE();
}


void Exceptions::ThrowByType(
    ExceptionType type, const GrowableArray<const Object*>& arguments) {
  const Object& result = Object::Handle(Create(type, arguments));
  if (result.IsError()) {
    // We got an error while constructing the exception object.
    // Propagate the error instead of throwing the exception.
    PropagateError(Error::Cast(result));
  } else {
    ASSERT(result.IsInstance());
    Throw(Instance::Cast(result));
  }
}


RawObject* Exceptions::Create(
    ExceptionType type, const GrowableArray<const Object*>& arguments) {
  Library& library = Library::Handle();
  String& class_name = String::Handle();
  switch (type) {
    case kIndexOutOfRange:
      library = Library::CoreLibrary();
      class_name = Symbols::New("IndexOutOfRangeException");
      break;
    case kArgument:
      library = Library::CoreLibrary();
      class_name = Symbols::New("ArgumentError");
      break;
    case kNoSuchMethod:
      library = Library::CoreLibrary();
      class_name = Symbols::New("NoSuchMethodError");
      break;
    case kClosureArgumentMismatch:
      library = Library::CoreLibrary();
      class_name = Symbols::New("ClosureArgumentMismatchException");
      break;
    case kObjectNotClosure:
      library = Library::CoreLibrary();
      class_name = Symbols::New("ObjectNotClosureException");
      break;
    case kFormat:
      library = Library::CoreLibrary();
      class_name = Symbols::New("FormatException");
      break;
    case kStackOverflow:
      library = Library::CoreLibrary();
      class_name = Symbols::New("StackOverflowException");
      break;
    case kOutOfMemory:
      library = Library::CoreLibrary();
      class_name = Symbols::New("OutOfMemoryError");
      break;
    case kWrongArgumentCount:
      library = Library::CoreLibrary();
      class_name = Symbols::New("WrongArgumentCountException");
      break;
    case kInternalError:
      library = Library::CoreLibrary();
      class_name = Symbols::New("InternalError");
      break;
    case kNullPointer:
      library = Library::CoreLibrary();
      class_name = Symbols::New("NullPointerException");
      break;
    case kIllegalJSRegExp:
      library = Library::CoreLibrary();
      class_name = Symbols::New("IllegalJSRegExpException");
      break;
    case kIsolateSpawn:
      library = Library::IsolateLibrary();
      class_name = Symbols::New("IsolateSpawnException");
      break;
  }

  return DartLibraryCalls::ExceptionCreate(library, class_name, arguments);
}

}  // namespace dart
