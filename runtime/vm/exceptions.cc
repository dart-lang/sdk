// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/exceptions.h"

#include "platform/address_sanitizer.h"

#include "lib/stacktrace.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/datastream.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/flags.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"


namespace dart {

DECLARE_FLAG(bool, trace_deoptimization);
DEFINE_FLAG(bool,
            print_stacktrace_at_throw,
            false,
            "Prints a stack trace everytime a throw occurs.");


class StackTraceBuilder : public ValueObject {
 public:
  StackTraceBuilder() {}
  virtual ~StackTraceBuilder() {}

  virtual void AddFrame(const Code& code, const Smi& offset) = 0;
};


class RegularStackTraceBuilder : public StackTraceBuilder {
 public:
  explicit RegularStackTraceBuilder(Zone* zone)
      : code_list_(
            GrowableObjectArray::Handle(zone, GrowableObjectArray::New())),
        pc_offset_list_(
            GrowableObjectArray::Handle(zone, GrowableObjectArray::New())) {}
  ~RegularStackTraceBuilder() {}

  const GrowableObjectArray& code_list() const { return code_list_; }
  const GrowableObjectArray& pc_offset_list() const { return pc_offset_list_; }

  virtual void AddFrame(const Code& code, const Smi& offset) {
    code_list_.Add(code);
    pc_offset_list_.Add(offset);
  }

 private:
  const GrowableObjectArray& code_list_;
  const GrowableObjectArray& pc_offset_list_;

  DISALLOW_COPY_AND_ASSIGN(RegularStackTraceBuilder);
};


class PreallocatedStackTraceBuilder : public StackTraceBuilder {
 public:
  explicit PreallocatedStackTraceBuilder(const Instance& stacktrace)
      : stacktrace_(StackTrace::Cast(stacktrace)),
        cur_index_(0),
        dropped_frames_(0) {
    ASSERT(stacktrace_.raw() ==
           Isolate::Current()->object_store()->preallocated_stack_trace());
  }
  ~PreallocatedStackTraceBuilder() {}

  virtual void AddFrame(const Code& code, const Smi& offset);

 private:
  static const int kNumTopframes = StackTrace::kPreallocatedStackdepth / 2;

  const StackTrace& stacktrace_;
  intptr_t cur_index_;
  intptr_t dropped_frames_;

  DISALLOW_COPY_AND_ASSIGN(PreallocatedStackTraceBuilder);
};


void PreallocatedStackTraceBuilder::AddFrame(const Code& code,
                                             const Smi& offset) {
  if (cur_index_ >= StackTrace::kPreallocatedStackdepth) {
    // The number of frames is overflowing the preallocated stack trace object.
    Code& frame_code = Code::Handle();
    Smi& frame_offset = Smi::Handle();
    intptr_t start = StackTrace::kPreallocatedStackdepth - (kNumTopframes - 1);
    intptr_t null_slot = start - 2;
    // We are going to drop one frame.
    dropped_frames_++;
    // Add an empty slot to indicate the overflow so that the toString
    // method can account for the overflow.
    if (stacktrace_.CodeAtFrame(null_slot) != Code::null()) {
      stacktrace_.SetCodeAtFrame(null_slot, frame_code);
      // We drop an extra frame here too.
      dropped_frames_++;
    }
    // Encode the number of dropped frames into the pc offset.
    frame_offset ^= Smi::New(dropped_frames_);
    stacktrace_.SetPcOffsetAtFrame(null_slot, frame_offset);
    // Move frames one slot down so that we can accommodate the new frame.
    for (intptr_t i = start; i < StackTrace::kPreallocatedStackdepth; i++) {
      intptr_t prev = (i - 1);
      frame_code = stacktrace_.CodeAtFrame(i);
      frame_offset = stacktrace_.PcOffsetAtFrame(i);
      stacktrace_.SetCodeAtFrame(prev, frame_code);
      stacktrace_.SetPcOffsetAtFrame(prev, frame_offset);
    }
    cur_index_ = (StackTrace::kPreallocatedStackdepth - 1);
  }
  stacktrace_.SetCodeAtFrame(cur_index_, code);
  stacktrace_.SetPcOffsetAtFrame(cur_index_, offset);
  cur_index_ += 1;
}


static void BuildStackTrace(StackTraceBuilder* builder) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle();
  Smi& offset = Smi::Handle();
  while (frame != NULL) {
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      ASSERT(code.ContainsInstructionAt(frame->pc()));
      offset = Smi::New(frame->pc() - code.PayloadStart());
      builder->AddFrame(code, offset);
    }
    frame = frames.NextFrame();
  }
}


static RawObject** VariableAt(uword fp, int stack_slot) {
#if defined(TARGET_ARCH_DBC)
  return reinterpret_cast<RawObject**>(fp + stack_slot * kWordSize);
#else
  if (stack_slot < 0) {
    return reinterpret_cast<RawObject**>(ParamAddress(fp, -stack_slot));
  } else {
    return reinterpret_cast<RawObject**>(
        LocalVarAddress(fp, kFirstLocalSlotFromFp - stack_slot));
  }
#endif
}


class ExceptionHandlerFinder : public StackResource {
 public:
  explicit ExceptionHandlerFinder(Thread* thread)
      : StackResource(thread), thread_(thread), cache_(NULL), metadata_(NULL) {}

  // Iterate through the stack frames and try to find a frame with an
  // exception handler. Once found, set the pc, sp and fp so that execution
  // can continue in that frame. Sets 'needs_stacktrace' if there is no
  // cath-all handler or if a stack-trace is specified in the catch.
  bool Find() {
    StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = frames.NextFrame();
    if (frame == NULL) return false;  // No Dart frame.
    handler_pc_set_ = false;
    needs_stacktrace = false;
    bool is_catch_all = false;
    uword temp_handler_pc = kUwordMax;
    bool is_optimized = false;
    code_ = NULL;
    cache_ = thread_->isolate()->catch_entry_state_cache();

    while (!frame->IsEntryFrame()) {
      if (frame->IsDartFrame()) {
        if (frame->FindExceptionHandler(thread_, &temp_handler_pc,
                                        &needs_stacktrace, &is_catch_all,
                                        &is_optimized)) {
          if (!handler_pc_set_) {
            handler_pc_set_ = true;
            handler_pc = temp_handler_pc;
            handler_sp = frame->sp();
            handler_fp = frame->fp();
            if (is_optimized) {
              pc_ = frame->pc();
              code_ = &Code::Handle(frame->LookupDartCode());
              CatchEntryState* state = cache_->Lookup(pc_);
              if (state != NULL) cached_ = *state;
#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_PRECOMPILER)
              intptr_t num_vars = Smi::Value(code_->variables());
              if (cached_.Empty()) GetMetaDataFromDeopt(num_vars, frame);
#else
              if (cached_.Empty()) ReadCompressedMetaData();
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_PRECOMPILER)
            }
          }
          if (needs_stacktrace || is_catch_all) {
            return true;
          }
        }
      }  // if frame->IsDartFrame
      frame = frames.NextFrame();
      ASSERT(frame != NULL);
    }  // while !frame->IsEntryFrame
    ASSERT(frame->IsEntryFrame());
    if (!handler_pc_set_) {
      handler_pc = frame->pc();
      handler_sp = frame->sp();
      handler_fp = frame->fp();
    }
    // No catch-all encountered, needs stacktrace.
    needs_stacktrace = true;
    return handler_pc_set_;
  }

  void TrySync() {
    if (code_ == NULL || !code_->is_optimized()) {
      return;
    }
    if (!cached_.Empty()) {
      // Cache hit.
      TrySyncCached(&cached_);
    } else {
      // New cache entry.
      CatchEntryState m(metadata_);
      TrySyncCached(&m);
      cache_->Insert(pc_, m);
    }
  }

  void TrySyncCached(CatchEntryState* md) {
    uword fp = handler_fp;
    ObjectPool* pool = NULL;
    intptr_t pairs = md->Pairs();
    for (int j = 0; j < pairs; j++) {
      intptr_t src = md->Src(j);
      intptr_t dest = md->Dest(j);
      if (md->isMove(j)) {
        *VariableAt(fp, dest) = *VariableAt(fp, src);
      } else {
        if (pool == NULL) {
          pool = &ObjectPool::Handle(code_->object_pool());
        }
        RawObject* obj = pool->ObjectAt(src);
        *VariableAt(fp, dest) = obj;
      }
    }
  }

#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  void ReadCompressedMetaData() {
    intptr_t pc_offset = pc_ - code_->PayloadStart();
    const TypedData& td = TypedData::Handle(code_->catch_entry_state_maps());
    NoSafepointScope no_safepoint;
    ReadStream stream(static_cast<uint8_t*>(td.DataAddr(0)), td.Length());

    bool found_metadata = false;
    while (stream.PendingBytes() > 0) {
      intptr_t target_pc_offset = Reader::Read(&stream);
      intptr_t variables = Reader::Read(&stream);
      intptr_t suffix_length = Reader::Read(&stream);
      intptr_t suffix_offset = Reader::Read(&stream);
      if (pc_offset == target_pc_offset) {
        metadata_ = new intptr_t[2 * (variables + suffix_length) + 1];
        metadata_[0] = variables + suffix_length;
        for (int j = 0; j < variables; j++) {
          intptr_t src = Reader::Read(&stream);
          intptr_t dest = Reader::Read(&stream);
          metadata_[1 + 2 * j] = src;
          metadata_[2 + 2 * j] = dest;
        }
        ReadCompressedSuffix(&stream, suffix_offset, suffix_length, metadata_,
                             2 * variables + 1);
        found_metadata = true;
        break;
      } else {
        for (intptr_t j = 0; j < 2 * variables; j++) {
          Reader::Read(&stream);
        }
      }
    }
    ASSERT(found_metadata);
  }

  void ReadCompressedSuffix(ReadStream* stream,
                            intptr_t offset,
                            intptr_t length,
                            intptr_t* target,
                            intptr_t target_offset) {
    stream->SetPosition(offset);
    Reader::Read(stream);  // skip pc_offset
    Reader::Read(stream);  // skip variables
    intptr_t suffix_length = Reader::Read(stream);
    intptr_t suffix_offset = Reader::Read(stream);
    intptr_t to_read = length - suffix_length;
    for (int j = 0; j < to_read; j++) {
      target[target_offset + 2 * j] = Reader::Read(stream);
      target[target_offset + 2 * j + 1] = Reader::Read(stream);
    }
    if (suffix_length > 0) {
      ReadCompressedSuffix(stream, suffix_offset, suffix_length, target,
                           target_offset + to_read * 2);
    }
  }

#else
  void GetMetaDataFromDeopt(intptr_t num_vars, StackFrame* frame) {
    Isolate* isolate = thread_->isolate();
    DeoptContext* deopt_context =
        new DeoptContext(frame, *code_, DeoptContext::kDestIsAllocated, NULL,
                         NULL, true, false /* deoptimizing_code */);
    isolate->set_deopt_context(deopt_context);

    metadata_ = deopt_context->CatchEntryState(num_vars);

    isolate->set_deopt_context(NULL);
    delete deopt_context;
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)

  bool needs_stacktrace;
  uword handler_pc;
  uword handler_sp;
  uword handler_fp;

 private:
  typedef ReadStream::Raw<sizeof(intptr_t), intptr_t> Reader;
  Thread* thread_;
  CatchEntryStateCache* cache_;
  Code* code_;
  bool handler_pc_set_;
  intptr_t* metadata_;      // MetaData generated from deopt.
  CatchEntryState cached_;  // Value of per PC MetaData cache.
  intptr_t pc_;             // Current pc in the handler frame.
};


static void FindErrorHandler(uword* handler_pc,
                             uword* handler_sp,
                             uword* handler_fp) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
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


static uword RemapExceptionPCForDeopt(Thread* thread,
                                      uword program_counter,
                                      uword frame_pointer) {
#if !defined(TARGET_ARCH_DBC)
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts =
      thread->isolate()->pending_deopts();
  if (pending_deopts->length() > 0) {
    // Check if the target frame is scheduled for lazy deopt.
    for (intptr_t i = 0; i < pending_deopts->length(); i++) {
      if ((*pending_deopts)[i].fp() == frame_pointer) {
        // Deopt should now resume in the catch handler instead of after the
        // call.
        (*pending_deopts)[i].set_pc(program_counter);

        // Jump to the deopt stub instead of the catch handler.
        program_counter =
            StubCode::DeoptimizeLazyFromThrow_entry()->EntryPoint();
        if (FLAG_trace_deoptimization) {
          THR_Print("Throwing to frame scheduled for lazy deopt fp=%" Pp "\n",
                    frame_pointer);
        }
        break;
      }
    }
  }
#endif  // !DBC
  return program_counter;
}


static void ClearLazyDeopts(Thread* thread, uword frame_pointer) {
#if !defined(TARGET_ARCH_DBC)
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts =
      thread->isolate()->pending_deopts();
  if (pending_deopts->length() > 0) {
    // We may be jumping over frames scheduled for lazy deopt. Remove these
    // frames from the pending deopt table, but only after unmarking them so
    // any stack walk that happens before the stack is unwound will still work.
    {
      DartFrameIterator frames(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* frame = frames.NextFrame();
      while ((frame != NULL) && (frame->fp() < frame_pointer)) {
        if (frame->IsMarkedForLazyDeopt()) {
          frame->UnmarkForLazyDeopt();
        }
        frame = frames.NextFrame();
      }
    }

#if defined(DEBUG)
    ValidateFrames();
#endif

    for (intptr_t i = 0; i < pending_deopts->length(); i++) {
      if ((*pending_deopts)[i].fp() < frame_pointer) {
        if (FLAG_trace_deoptimization) {
          THR_Print(
              "Lazy deopt skipped due to throw for "
              "fp=%" Pp ", pc=%" Pp "\n",
              (*pending_deopts)[i].fp(), (*pending_deopts)[i].pc());
        }
        pending_deopts->RemoveAt(i);
      }
    }

#if defined(DEBUG)
    ValidateFrames();
#endif
  }
#endif  // !DBC
}


static void JumpToExceptionHandler(Thread* thread,
                                   uword program_counter,
                                   uword stack_pointer,
                                   uword frame_pointer,
                                   const Object& exception_object,
                                   const Object& stacktrace_object) {
  uword remapped_pc =
      RemapExceptionPCForDeopt(thread, program_counter, frame_pointer);
  thread->set_active_exception(exception_object);
  thread->set_active_stacktrace(stacktrace_object);
  thread->set_resume_pc(remapped_pc);
  uword run_exception_pc = StubCode::RunExceptionHandler_entry()->EntryPoint();
  Exceptions::JumpToFrame(thread, run_exception_pc, stack_pointer,
                          frame_pointer, false /* do not clear deopt */);
}


void Exceptions::JumpToFrame(Thread* thread,
                             uword program_counter,
                             uword stack_pointer,
                             uword frame_pointer,
                             bool clear_deopt_at_target) {
  uword fp_for_clearing =
      (clear_deopt_at_target ? frame_pointer + 1 : frame_pointer);
  ClearLazyDeopts(thread, fp_for_clearing);
#if defined(USING_SIMULATOR)
  // Unwinding of the C++ frames and destroying of their stack resources is done
  // by the simulator, because the target stack_pointer is a simulated stack
  // pointer and not the C++ stack pointer.

  // Continue simulating at the given pc in the given frame after setting up the
  // exception object in the kExceptionObjectReg register and the stacktrace
  // object (may be raw null) in the kStackTraceObjectReg register.

  Simulator::Current()->JumpToFrame(program_counter, stack_pointer,
                                    frame_pointer, thread);
#else
  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  StackResource::Unwind(thread);

  // Call a stub to set up the exception object in kExceptionObjectReg,
  // to set up the stacktrace object in kStackTraceObjectReg, and to
  // continue execution at the given pc in the given frame.
  typedef void (*ExcpHandler)(uword, uword, uword, Thread*);
  ExcpHandler func = reinterpret_cast<ExcpHandler>(
      StubCode::JumpToFrame_entry()->EntryPoint());

  // Unpoison the stack before we tear it down in the generated stub code.
  uword current_sp = Thread::GetCurrentStackPointer() - 1024;
  ASAN_UNPOISON(reinterpret_cast<void*>(current_sp),
                stack_pointer - current_sp);

  func(program_counter, stack_pointer, frame_pointer, thread);
#endif
  UNREACHABLE();
}


static RawField* LookupStackTraceField(const Instance& instance) {
  if (instance.GetClassId() < kNumPredefinedCids) {
    // 'class Error' is not a predefined class.
    return Field::null();
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Class& error_class =
      Class::Handle(zone, isolate->object_store()->error_class());
  if (error_class.IsNull()) {
    const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
    error_class = core_lib.LookupClass(Symbols::Error());
    ASSERT(!error_class.IsNull());
    isolate->object_store()->set_error_class(error_class);
  }
  // If instance class extends 'class Error' return '_stackTrace' field.
  Class& test_class = Class::Handle(zone, instance.clazz());
  AbstractType& type = AbstractType::Handle(zone, AbstractType::null());
  while (true) {
    if (test_class.raw() == error_class.raw()) {
      return error_class.LookupInstanceFieldAllowPrivate(
          Symbols::_stackTrace());
    }
    type = test_class.super_type();
    if (type.IsNull()) return Field::null();
    test_class = type.type_class();
  }
  UNREACHABLE();
  return Field::null();
}


RawStackTrace* Exceptions::CurrentStackTrace() {
  return GetStackTraceForException();
}


static void ThrowExceptionHelper(Thread* thread,
                                 const Instance& incoming_exception,
                                 const Instance& existing_stacktrace,
                                 const bool is_rethrow) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  bool use_preallocated_stacktrace = false;
  Instance& exception = Instance::Handle(zone, incoming_exception.raw());
  if (exception.IsNull()) {
    exception ^=
        Exceptions::Create(Exceptions::kNullThrown, Object::empty_array());
  } else if (exception.raw() == isolate->object_store()->out_of_memory() ||
             exception.raw() == isolate->object_store()->stack_overflow()) {
    use_preallocated_stacktrace = true;
  }
  // Find the exception handler and determine if the handler needs a
  // stacktrace.
  ExceptionHandlerFinder finder(thread);
  bool handler_exists = finder.Find();
  uword handler_pc = finder.handler_pc;
  uword handler_sp = finder.handler_sp;
  uword handler_fp = finder.handler_fp;
  bool handler_needs_stacktrace = finder.needs_stacktrace;
  Instance& stacktrace = Instance::Handle(zone);
  if (use_preallocated_stacktrace) {
    if (handler_pc == 0) {
      // No Dart frame.
      ASSERT(incoming_exception.raw() ==
             isolate->object_store()->out_of_memory());
      const UnhandledException& error = UnhandledException::Handle(
          zone, isolate->object_store()->preallocated_unhandled_exception());
      thread->long_jump_base()->Jump(1, error);
      UNREACHABLE();
    }
    stacktrace ^= isolate->object_store()->preallocated_stack_trace();
    PreallocatedStackTraceBuilder frame_builder(stacktrace);
    ASSERT(existing_stacktrace.IsNull() ||
           (existing_stacktrace.raw() == stacktrace.raw()));
    ASSERT(existing_stacktrace.IsNull() || is_rethrow);
    if (handler_needs_stacktrace && existing_stacktrace.IsNull()) {
      BuildStackTrace(&frame_builder);
    }
  } else {
    if (!existing_stacktrace.IsNull()) {
      // If we have an existing stack trace then this better be a rethrow. The
      // reverse is not necessarily true (e.g. Dart_PropagateError can cause
      // a rethrow being called without an existing stacktrace.)
      ASSERT(is_rethrow);
      stacktrace = existing_stacktrace.raw();
    } else {
      // Get stacktrace field of class Error to determine whether we have a
      // subclass of Error which carries around its stack trace.
      const Field& stacktrace_field =
          Field::Handle(zone, LookupStackTraceField(exception));
      if (!stacktrace_field.IsNull() || handler_needs_stacktrace) {
        // Collect the stacktrace if needed.
        ASSERT(existing_stacktrace.IsNull());
        stacktrace = Exceptions::CurrentStackTrace();
        // If we have an Error object, then set its stackTrace field only if it
        // not yet initialized.
        if (!stacktrace_field.IsNull() &&
            (exception.GetField(stacktrace_field) == Object::null())) {
          exception.SetField(stacktrace_field, stacktrace);
        }
      }
    }
  }
  // We expect to find a handler_pc, if the exception is unhandled
  // then we expect to at least have the dart entry frame on the
  // stack as Exceptions::Throw should happen only after a dart
  // invocation has been done.
  ASSERT(handler_pc != 0);

  if (FLAG_print_stacktrace_at_throw) {
    THR_Print("Exception '%s' thrown:\n", exception.ToCString());
    THR_Print("%s\n", stacktrace.ToCString());
  }
  if (handler_exists) {
    finder.TrySync();
    // Found a dart handler for the exception, jump to it.
    JumpToExceptionHandler(thread, handler_pc, handler_sp, handler_fp,
                           exception, stacktrace);
  } else {
    // No dart exception handler found in this invocation sequence,
    // so we create an unhandled exception object and return to the
    // invocation stub so that it returns this unhandled exception
    // object. The C++ code which invoked this dart sequence can check
    // and do the appropriate thing (rethrow the exception to the
    // dart invocation sequence above it, print diagnostics and terminate
    // the isolate etc.).
    const UnhandledException& unhandled_exception = UnhandledException::Handle(
        zone, UnhandledException::New(exception, stacktrace));
    stacktrace = StackTrace::null();
    JumpToExceptionHandler(thread, handler_pc, handler_sp, handler_fp,
                           unhandled_exception, stacktrace);
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
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const String& cls_name =
      String::Handle(zone, Symbols::New(thread, class_name));
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  // No ambiguity error expected: passing NULL.
  Class& cls = Class::Handle(core_lib.LookupClass(cls_name));
  ASSERT(!cls.IsNull());
  // There are no parameterized error types, so no need to set type arguments.
  return Instance::New(cls);
}


// Allocate, initialize, and throw a TypeError or CastError.
// If error_msg is not null, throw a TypeError, even for a type cast.
void Exceptions::CreateAndThrowTypeError(TokenPosition location,
                                         const AbstractType& src_type,
                                         const AbstractType& dst_type,
                                         const String& dst_name,
                                         const String& bound_error_msg) {
  ASSERT(!dst_name.IsNull());  // Pass Symbols::Empty() instead.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Array& args = Array::Handle(zone, Array::New(4));

  ExceptionType exception_type =
      (bound_error_msg.IsNull() &&
       (dst_name.raw() == Symbols::InTypeCast().raw()))
          ? kCast
          : kType;

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  const Script& script = Script::Handle(zone, GetCallerScript(&iterator));
  intptr_t line = -1;
  intptr_t column = -1;
  ASSERT(!script.IsNull());
  if (location.IsReal()) {
    if (script.HasSource() || script.kind() == RawScript::kKernelTag) {
      script.GetTokenLocation(location, &line, &column);
    } else {
      script.GetTokenLocation(location, &line, NULL);
    }
  }
  // Initialize '_url', '_line', and '_column' arguments.
  args.SetAt(0, String::Handle(zone, script.url()));
  args.SetAt(1, Smi::Handle(zone, Smi::New(line)));
  args.SetAt(2, Smi::Handle(zone, Smi::New(column)));

  // Construct '_errorMsg'.
  const GrowableObjectArray& pieces =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New(20));

  // Print bound error first, if any.
  if (!bound_error_msg.IsNull() && (bound_error_msg.Length() > 0)) {
    pieces.Add(bound_error_msg);
    pieces.Add(Symbols::NewLine());
  }

  // If dst_type is malformed or malbounded, only print the embedded error.
  if (!dst_type.IsNull()) {
    const LanguageError& error = LanguageError::Handle(zone, dst_type.error());
    if (!error.IsNull()) {
      // Print the embedded error only.
      pieces.Add(String::Handle(zone, String::New(error.ToErrorCString())));
      pieces.Add(Symbols::NewLine());
    } else {
      // Describe the type error.
      if (!src_type.IsNull()) {
        pieces.Add(Symbols::TypeQuote());
        pieces.Add(String::Handle(zone, src_type.UserVisibleName()));
        pieces.Add(Symbols::QuoteIsNotASubtypeOf());
      }
      pieces.Add(Symbols::TypeQuote());
      pieces.Add(String::Handle(zone, dst_type.UserVisibleName()));
      pieces.Add(Symbols::SingleQuote());
      if (exception_type == kCast) {
        pieces.Add(dst_name);
      } else if (dst_name.Length() > 0) {
        pieces.Add(Symbols::SpaceOfSpace());
        pieces.Add(Symbols::SingleQuote());
        pieces.Add(dst_name);
        pieces.Add(Symbols::SingleQuote());
      }
      // Print URIs of src and dst types.
      // Do not print "where" when no URIs get printed.
      bool printed_where = false;
      if (!src_type.IsNull()) {
        const String& uris = String::Handle(zone, src_type.EnumerateURIs());
        if (uris.Length() > Symbols::SpaceIsFromSpace().Length()) {
          printed_where = true;
          pieces.Add(Symbols::SpaceWhereNewLine());
          pieces.Add(uris);
        }
      }
      if (!dst_type.IsDynamicType() && !dst_type.IsVoidType()) {
        const String& uris = String::Handle(zone, dst_type.EnumerateURIs());
        if (uris.Length() > Symbols::SpaceIsFromSpace().Length()) {
          if (!printed_where) {
            pieces.Add(Symbols::SpaceWhereNewLine());
          }
          pieces.Add(uris);
        }
      }
    }
  }
  const Array& arr = Array::Handle(zone, Array::MakeFixedLength(pieces));
  const String& error_msg = String::Handle(zone, String::ConcatAll(arr));
  args.SetAt(3, error_msg);

  // Type errors in the core library may be difficult to diagnose.
  // Print type error information before throwing the error when debugging.
  if (FLAG_print_stacktrace_at_throw) {
    THR_Print("'%s': Failed type check: line %" Pd " pos %" Pd ": ",
              String::Handle(zone, script.url()).ToCString(), line, column);
    THR_Print("%s\n", error_msg.ToCString());
  }

  // Throw TypeError or CastError instance.
  Exceptions::ThrowByType(exception_type, args);
  UNREACHABLE();
}


void Exceptions::Throw(Thread* thread, const Instance& exception) {
  // Do not notify debugger on stack overflow and out of memory exceptions.
  // The VM would crash when the debugger calls back into the VM to
  // get values of variables.
  if (FLAG_support_debugger) {
    Isolate* isolate = thread->isolate();
    if (exception.raw() != isolate->object_store()->out_of_memory() &&
        exception.raw() != isolate->object_store()->stack_overflow()) {
      isolate->debugger()->PauseException(exception);
    }
  }
  // Null object is a valid exception object.
  ThrowExceptionHelper(thread, exception, StackTrace::Handle(thread->zone()),
                       false);
}


void Exceptions::ReThrow(Thread* thread,
                         const Instance& exception,
                         const Instance& stacktrace) {
  // Null object is a valid exception object.
  ThrowExceptionHelper(thread, exception, stacktrace, true);
}


void Exceptions::PropagateError(const Error& error) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->top_exit_frame_info() != 0);
  if (error.IsUnhandledException()) {
    // If the error object represents an unhandled exception, then
    // rethrow the exception in the normal fashion.
    const UnhandledException& uhe = UnhandledException::Cast(error);
    const Instance& exc = Instance::Handle(zone, uhe.exception());
    const Instance& stk = Instance::Handle(zone, uhe.stacktrace());
    Exceptions::ReThrow(thread, exc, stk);
  } else {
    // Return to the invocation stub and return this error object.  The
    // C++ code which invoked this dart sequence can check and do the
    // appropriate thing.
    uword handler_pc = 0;
    uword handler_sp = 0;
    uword handler_fp = 0;
    FindErrorHandler(&handler_pc, &handler_sp, &handler_fp);
    JumpToExceptionHandler(thread, handler_pc, handler_sp, handler_fp, error,
                           StackTrace::Handle(zone));  // Null stacktrace.
  }
  UNREACHABLE();
}


void Exceptions::ThrowByType(ExceptionType type, const Array& arguments) {
  Thread* thread = Thread::Current();
  const Object& result =
      Object::Handle(thread->zone(), Create(type, arguments));
  if (result.IsError()) {
    // We got an error while constructing the exception object.
    // Propagate the error instead of throwing the exception.
    PropagateError(Error::Cast(result));
  } else {
    ASSERT(result.IsInstance());
    Throw(thread, Instance::Cast(result));
  }
}


void Exceptions::ThrowOOM() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const Instance& oom = Instance::Handle(
      thread->zone(), isolate->object_store()->out_of_memory());
  Throw(thread, oom);
}


void Exceptions::ThrowStackOverflow() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const Instance& stack_overflow = Instance::Handle(
      thread->zone(), isolate->object_store()->stack_overflow());
  Throw(thread, stack_overflow);
}


void Exceptions::ThrowArgumentError(const Instance& arg) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, arg);
  Exceptions::ThrowByType(Exceptions::kArgument, args);
}


void Exceptions::ThrowRangeError(const char* argument_name,
                                 const Integer& argument_value,
                                 intptr_t expected_from,
                                 intptr_t expected_to) {
  const Array& args = Array::Handle(Array::New(4));
  args.SetAt(0, argument_value);
  args.SetAt(1, Integer::Handle(Integer::New(expected_from)));
  args.SetAt(2, Integer::Handle(Integer::New(expected_to)));
  args.SetAt(3, String::Handle(String::New(argument_name)));
  Exceptions::ThrowByType(Exceptions::kRange, args);
}


void Exceptions::ThrowRangeErrorMsg(const char* msg) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, String::Handle(String::New(msg)));
  Exceptions::ThrowByType(Exceptions::kRangeMsg, args);
}


void Exceptions::ThrowCompileTimeError(const LanguageError& error) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, String::Handle(error.FormatMessage()));
  Exceptions::ThrowByType(Exceptions::kCompileTimeError, args);
}


RawObject* Exceptions::Create(ExceptionType type, const Array& arguments) {
  Library& library = Library::Handle();
  const String* class_name = NULL;
  const String* constructor_name = &Symbols::Dot();
  switch (type) {
    case kNone:
    case kStackOverflow:
    case kOutOfMemory:
      UNREACHABLE();
      break;
    case kRange:
      library = Library::CoreLibrary();
      class_name = &Symbols::RangeError();
      constructor_name = &Symbols::DotRange();
      break;
    case kRangeMsg:
      library = Library::CoreLibrary();
      class_name = &Symbols::RangeError();
      constructor_name = &Symbols::Dot();
      break;
    case kArgument:
      library = Library::CoreLibrary();
      class_name = &Symbols::ArgumentError();
      break;
    case kArgumentValue:
      library = Library::CoreLibrary();
      class_name = &Symbols::ArgumentError();
      constructor_name = &Symbols::DotValue();
      break;
    case kNoSuchMethod:
      library = Library::CoreLibrary();
      class_name = &Symbols::NoSuchMethodError();
      constructor_name = &Symbols::DotWithType();
      break;
    case kFormat:
      library = Library::CoreLibrary();
      class_name = &Symbols::FormatException();
      break;
    case kUnsupported:
      library = Library::CoreLibrary();
      class_name = &Symbols::UnsupportedError();
      break;
    case kNullThrown:
      library = Library::CoreLibrary();
      class_name = &Symbols::NullThrownError();
      break;
    case kIsolateSpawn:
      library = Library::IsolateLibrary();
      class_name = &Symbols::IsolateSpawnException();
      break;
    case kAssertion:
      library = Library::CoreLibrary();
      class_name = &Symbols::AssertionError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kCast:
      library = Library::CoreLibrary();
      class_name = &Symbols::CastError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kType:
      library = Library::CoreLibrary();
      class_name = &Symbols::TypeError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kFallThrough:
      library = Library::CoreLibrary();
      class_name = &Symbols::FallThroughError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kAbstractClassInstantiation:
      library = Library::CoreLibrary();
      class_name = &Symbols::AbstractClassInstantiationError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kCyclicInitializationError:
      library = Library::CoreLibrary();
      class_name = &Symbols::CyclicInitializationError();
      break;
    case kCompileTimeError:
      library = Library::CoreLibrary();
      class_name = &Symbols::_CompileTimeError();
      break;
  }

  Thread* thread = Thread::Current();
  NoReloadScope no_reload_scope(thread->isolate(), thread);
  return DartLibraryCalls::InstanceCreate(library, *class_name,
                                          *constructor_name, arguments);
}


}  // namespace dart
