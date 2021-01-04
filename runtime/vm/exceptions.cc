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

  virtual void AddFrame(const Object& code, const Smi& offset) = 0;
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

  virtual void AddFrame(const Object& code, const Smi& offset) {
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
    ASSERT(
        stacktrace_.raw() ==
        Isolate::Current()->isolate_object_store()->preallocated_stack_trace());
  }
  ~PreallocatedStackTraceBuilder() {}

  virtual void AddFrame(const Object& code, const Smi& offset);

 private:
  static const int kNumTopframes = StackTrace::kPreallocatedStackdepth / 2;

  const StackTrace& stacktrace_;
  intptr_t cur_index_;
  intptr_t dropped_frames_;

  DISALLOW_COPY_AND_ASSIGN(PreallocatedStackTraceBuilder);
};

void PreallocatedStackTraceBuilder::AddFrame(const Object& code,
                                             const Smi& offset) {
  if (cur_index_ >= StackTrace::kPreallocatedStackdepth) {
    // The number of frames is overflowing the preallocated stack trace object.
    Object& frame_code = Object::Handle();
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
    frame_offset = Smi::New(dropped_frames_);
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
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle();
  Smi& offset = Smi::Handle();
  for (; frame != NULL; frame = frames.NextFrame()) {
    if (!frame->IsDartFrame()) {
      continue;
    }
    code = frame->LookupDartCode();
    ASSERT(code.ContainsInstructionAt(frame->pc()));
    offset = Smi::New(frame->pc() - code.PayloadStart());
    builder->AddFrame(code, offset);
  }
}

class ExceptionHandlerFinder : public StackResource {
 public:
  explicit ExceptionHandlerFinder(Thread* thread)
      : StackResource(thread), thread_(thread) {}

  // Iterate through the stack frames and try to find a frame with an
  // exception handler. Once found, set the pc, sp and fp so that execution
  // can continue in that frame. Sets 'needs_stacktrace' if there is no
  // catch-all handler or if a stack-trace is specified in the catch.
  bool Find() {
    StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
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
    catch_entry_moves_cache_ = thread_->isolate()->catch_entry_moves_cache();

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
              CatchEntryMovesRefPtr* cached_catch_entry_moves =
                  catch_entry_moves_cache_->Lookup(pc_);
              if (cached_catch_entry_moves != NULL) {
                cached_catch_entry_moves_ = *cached_catch_entry_moves;
              }
              if (cached_catch_entry_moves_.IsEmpty()) {
#if defined(DART_PRECOMPILED_RUNTIME)
                // Only AOT mode is supported.
                ReadCompressedCatchEntryMoves();
#elif defined(DART_PRECOMPILER)
                // Both AOT and JIT modes are supported.
                if (FLAG_precompiled_mode) {
                  ReadCompressedCatchEntryMoves();
                } else {
                  GetCatchEntryMovesFromDeopt(code_->num_variables(), frame);
                }
#else
                // Only JIT mode is supported.
                ASSERT(!FLAG_precompiled_mode);
                GetCatchEntryMovesFromDeopt(code_->num_variables(), frame);
#endif
              }
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

  // When entering catch block in the optimized code we need to execute
  // catch entry moves that would morph the state of the frame into
  // what catch entry expects.
  void PrepareFrameForCatchEntry() {
    if (code_ == nullptr || !code_->is_optimized()) {
      return;
    }

    if (cached_catch_entry_moves_.IsEmpty()) {
      catch_entry_moves_cache_->Insert(
          pc_, CatchEntryMovesRefPtr(catch_entry_moves_));
    } else {
      catch_entry_moves_ = &cached_catch_entry_moves_.moves();
    }

    ExecuteCatchEntryMoves(*catch_entry_moves_);
  }

  void ExecuteCatchEntryMoves(const CatchEntryMoves& moves) {
    Zone* zone = Thread::Current()->zone();
    auto& value = Object::Handle(zone);
    GrowableArray<Object*> dst_values;

    uword fp = handler_fp;
    ObjectPool* pool = nullptr;
    for (int j = 0; j < moves.count(); j++) {
      const CatchEntryMove& move = moves.At(j);

      switch (move.source_kind()) {
        case CatchEntryMove::SourceKind::kConstant:
          if (pool == nullptr) {
            pool = &ObjectPool::Handle(code_->GetObjectPool());
          }
          value = pool->ObjectAt(move.src_slot());
          break;

        case CatchEntryMove::SourceKind::kTaggedSlot:
          value = *TaggedSlotAt(fp, move.src_slot());
          break;

        case CatchEntryMove::SourceKind::kDoubleSlot:
          value = Double::New(*SlotAt<double>(fp, move.src_slot()));
          break;

        case CatchEntryMove::SourceKind::kFloat32x4Slot:
          value = Float32x4::New(*SlotAt<simd128_value_t>(fp, move.src_slot()));
          break;

        case CatchEntryMove::SourceKind::kFloat64x2Slot:
          value = Float64x2::New(*SlotAt<simd128_value_t>(fp, move.src_slot()));
          break;

        case CatchEntryMove::SourceKind::kInt32x4Slot:
          value = Int32x4::New(*SlotAt<simd128_value_t>(fp, move.src_slot()));
          break;

        case CatchEntryMove::SourceKind::kInt64PairSlot:
          value = Integer::New(
              Utils::LowHighTo64Bits(*SlotAt<uint32_t>(fp, move.src_lo_slot()),
                                     *SlotAt<int32_t>(fp, move.src_hi_slot())));
          break;

        case CatchEntryMove::SourceKind::kInt64Slot:
          value = Integer::New(*SlotAt<int64_t>(fp, move.src_slot()));
          break;

        case CatchEntryMove::SourceKind::kInt32Slot:
          value = Integer::New(*SlotAt<int32_t>(fp, move.src_slot()));
          break;

        case CatchEntryMove::SourceKind::kUint32Slot:
          value = Integer::New(*SlotAt<uint32_t>(fp, move.src_slot()));
          break;

        default:
          UNREACHABLE();
      }

      dst_values.Add(&Object::Handle(zone, value.raw()));
    }

    {
      NoSafepointScope no_safepoint_scope;

      for (int j = 0; j < moves.count(); j++) {
        const CatchEntryMove& move = moves.At(j);
        *TaggedSlotAt(fp, move.dest_slot()) = dst_values[j]->raw();
      }
    }
  }

#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  void ReadCompressedCatchEntryMoves() {
    const intptr_t pc_offset = pc_ - code_->PayloadStart();
    const auto& td = TypedData::Handle(code_->catch_entry_moves_maps());

    CatchEntryMovesMapReader reader(td);
    catch_entry_moves_ = reader.ReadMovesForPcOffset(pc_offset);
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)

#if !defined(DART_PRECOMPILED_RUNTIME)
  void GetCatchEntryMovesFromDeopt(intptr_t num_vars, StackFrame* frame) {
    Isolate* isolate = thread_->isolate();
    DeoptContext* deopt_context =
        new DeoptContext(frame, *code_, DeoptContext::kDestIsAllocated, NULL,
                         NULL, true, false /* deoptimizing_code */);
    isolate->set_deopt_context(deopt_context);

    catch_entry_moves_ = deopt_context->ToCatchEntryMoves(num_vars);

    isolate->set_deopt_context(NULL);
    delete deopt_context;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  bool needs_stacktrace;
  uword handler_pc;
  uword handler_sp;
  uword handler_fp;

 private:
  template <typename T>
  static T* SlotAt(uword fp, int stack_slot) {
    const intptr_t frame_slot =
        runtime_frame_layout.FrameSlotForVariableIndex(-stack_slot);
    return reinterpret_cast<T*>(fp + frame_slot * kWordSize);
  }

  static ObjectPtr* TaggedSlotAt(uword fp, int stack_slot) {
    return SlotAt<ObjectPtr>(fp, stack_slot);
  }

  typedef ReadStream::Raw<sizeof(intptr_t), intptr_t> Reader;
  Thread* thread_;
  Code* code_;
  bool handler_pc_set_;
  intptr_t pc_;             // Current pc in the handler frame.

  const CatchEntryMoves* catch_entry_moves_ = nullptr;
  CatchEntryMovesCache* catch_entry_moves_cache_ = nullptr;
  CatchEntryMovesRefPtr cached_catch_entry_moves_;
};

CatchEntryMove CatchEntryMove::ReadFrom(ReadStream* stream) {
  using Reader = ReadStream::Raw<sizeof(int32_t), int32_t>;
  const int32_t src = Reader::Read(stream);
  const int32_t dest_and_kind = Reader::Read(stream);
  return CatchEntryMove(src, dest_and_kind);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void CatchEntryMove::WriteTo(BaseWriteStream* stream) {
  using Writer = BaseWriteStream::Raw<sizeof(int32_t), int32_t>;
  Writer::Write(stream, src_);
  Writer::Write(stream, dest_and_kind_);
}
#endif

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
const char* CatchEntryMove::ToCString() const {
  char from[256];

  switch (source_kind()) {
    case SourceKind::kConstant:
      Utils::SNPrint(from, ARRAY_SIZE(from), "pp[%" Pd "]", src_slot());
      break;

    case SourceKind::kTaggedSlot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "fp[%" Pd "]", src_slot());
      break;

    case SourceKind::kDoubleSlot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "f64 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kFloat32x4Slot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "f32x4 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kFloat64x2Slot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "f64x2 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kInt32x4Slot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "i32x4 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kInt64PairSlot:
      Utils::SNPrint(from, ARRAY_SIZE(from),
                     "i64 ([fp + %" Pd "], [fp + %" Pd "])",
                     src_lo_slot() * compiler::target::kWordSize,
                     src_hi_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kInt64Slot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "i64 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kInt32Slot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "i32 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    case SourceKind::kUint32Slot:
      Utils::SNPrint(from, ARRAY_SIZE(from), "u32 [fp + %" Pd "]",
                     src_slot() * compiler::target::kWordSize);
      break;

    default:
      UNREACHABLE();
  }

  return Thread::Current()->zone()->PrintToString("fp[%" Pd "] <- %s",
                                                  dest_slot(), from);
}

void CatchEntryMovesMapReader::PrintEntries() {
  NoSafepointScope no_safepoint;

  using Reader = ReadStream::Raw<sizeof(intptr_t), intptr_t>;

  ReadStream stream(static_cast<uint8_t*>(bytes_.DataAddr(0)), bytes_.Length());

  while (stream.PendingBytes() > 0) {
    const intptr_t stream_position = stream.Position();
    const intptr_t target_pc_offset = Reader::Read(&stream);
    const intptr_t prefix_length = Reader::Read(&stream);
    const intptr_t suffix_length = Reader::Read(&stream);
    const intptr_t length = prefix_length + suffix_length;
    Reader::Read(&stream);  // Skip suffix_offset
    for (intptr_t j = 0; j < prefix_length; j++) {
      CatchEntryMove::ReadFrom(&stream);
    }

    ReadStream inner_stream(static_cast<uint8_t*>(bytes_.DataAddr(0)),
                            bytes_.Length());
    CatchEntryMoves* moves = ReadCompressedCatchEntryMovesSuffix(
        &inner_stream, stream_position, length);
    THR_Print("  [code+0x%08" Px "]: (% " Pd " moves)\n", target_pc_offset,
              moves->count());
    for (intptr_t i = 0; i < moves->count(); i++) {
      THR_Print("    %s\n", moves->At(i).ToCString());
    }
    CatchEntryMoves::Free(moves);
  }
}
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

CatchEntryMoves* CatchEntryMovesMapReader::ReadMovesForPcOffset(
    intptr_t pc_offset) {
  NoSafepointScope no_safepoint;

  ReadStream stream(static_cast<uint8_t*>(bytes_.DataAddr(0)), bytes_.Length());

  intptr_t position = 0;
  intptr_t length = 0;
  FindEntryForPc(&stream, pc_offset, &position, &length);

  return ReadCompressedCatchEntryMovesSuffix(&stream, position, length);
}

void CatchEntryMovesMapReader::FindEntryForPc(ReadStream* stream,
                                              intptr_t pc_offset,
                                              intptr_t* position,
                                              intptr_t* length) {
  using Reader = ReadStream::Raw<sizeof(intptr_t), intptr_t>;

  while (stream->PendingBytes() > 0) {
    const intptr_t stream_position = stream->Position();
    const intptr_t target_pc_offset = Reader::Read(stream);
    const intptr_t prefix_length = Reader::Read(stream);
    const intptr_t suffix_length = Reader::Read(stream);
    Reader::Read(stream);  // Skip suffix_offset
    if (pc_offset == target_pc_offset) {
      *position = stream_position;
      *length = prefix_length + suffix_length;
      return;
    }

    // Skip the prefix moves.
    for (intptr_t j = 0; j < prefix_length; j++) {
      CatchEntryMove::ReadFrom(stream);
    }
  }

  UNREACHABLE();
}

CatchEntryMoves* CatchEntryMovesMapReader::ReadCompressedCatchEntryMovesSuffix(
    ReadStream* stream,
    intptr_t offset,
    intptr_t length) {
  using Reader = ReadStream::Raw<sizeof(intptr_t), intptr_t>;

  CatchEntryMoves* moves = CatchEntryMoves::Allocate(length);

  intptr_t remaining_length = length;

  intptr_t moves_offset = 0;
  while (remaining_length > 0) {
    stream->SetPosition(offset);
    Reader::Read(stream);  // skip pc_offset
    Reader::Read(stream);  // skip prefix length
    const intptr_t suffix_length = Reader::Read(stream);
    const intptr_t suffix_offset = Reader::Read(stream);
    const intptr_t to_read = remaining_length - suffix_length;
    if (to_read > 0) {
      for (int j = 0; j < to_read; j++) {
        // The prefix is written from the back.
        moves->At(moves_offset + to_read - j - 1) =
            CatchEntryMove::ReadFrom(stream);
      }
      remaining_length -= to_read;
      moves_offset += to_read;
    }
    offset = suffix_offset;
  }

  return moves;
}

static void FindErrorHandler(uword* handler_pc,
                             uword* handler_sp,
                             uword* handler_fp) {
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
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
        program_counter = StubCode::DeoptimizeLazyFromThrow().EntryPoint();
        if (FLAG_trace_deoptimization) {
          THR_Print("Throwing to frame scheduled for lazy deopt fp=%" Pp "\n",
                    frame_pointer);

#if defined(DEBUG)
          // Ensure the frame references optimized code.
          ObjectPtr pc_marker = *(reinterpret_cast<ObjectPtr*>(
              frame_pointer + runtime_frame_layout.code_from_fp * kWordSize));
          Code& code = Code::Handle(Code::RawCast(pc_marker));
          ASSERT(code.is_optimized() && !code.is_force_optimized());
#endif
        }
        break;
      }
    }
  }
  return program_counter;
}

static void ClearLazyDeopts(Thread* thread, uword frame_pointer) {
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts =
      thread->isolate()->pending_deopts();
  if (pending_deopts->length() > 0) {
    // We may be jumping over frames scheduled for lazy deopt. Remove these
    // frames from the pending deopt table, but only after unmarking them so
    // any stack walk that happens before the stack is unwound will still work.
    {
      DartFrameIterator frames(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
      for (StackFrame* frame = frames.NextFrame(); frame != nullptr;
           frame = frames.NextFrame()) {
        if (frame->fp() >= frame_pointer) {
          break;
        }
        if (frame->IsMarkedForLazyDeopt()) {
          frame->UnmarkForLazyDeopt();
        }
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
        pending_deopts->RemoveAt(i--);
      }
    }

#if defined(DEBUG)
    ValidateFrames();
#endif
  }
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
  uword run_exception_pc = StubCode::RunExceptionHandler().EntryPoint();
  Exceptions::JumpToFrame(thread, run_exception_pc, stack_pointer,
                          frame_pointer, false /* do not clear deopt */);
}

NO_SANITIZE_SAFE_STACK  // This function manipulates the safestack pointer.
void Exceptions::JumpToFrame(Thread* thread,
                             uword program_counter,
                             uword stack_pointer,
                             uword frame_pointer,
                             bool clear_deopt_at_target) {
  const uword fp_for_clearing =
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
  ExcpHandler func =
      reinterpret_cast<ExcpHandler>(StubCode::JumpToFrame().EntryPoint());

  // Unpoison the stack before we tear it down in the generated stub code.
  uword current_sp = OSThread::GetCurrentStackPointer() - 1024;
  ASAN_UNPOISON(reinterpret_cast<void*>(current_sp),
                stack_pointer - current_sp);

  // We are jumping over C++ frames, so we have to set the safestack pointer
  // back to what it was when we entered the runtime from Dart code.
#if defined(USING_SAFE_STACK)
  const uword saved_ssp = thread->saved_safestack_limit();
  OSThread::SetCurrentSafestackPointer(saved_ssp);
#endif

#if defined(USING_SHADOW_CALL_STACK)
  // The shadow call stack register will be restored by the JumpToFrame stub.
#endif

  func(program_counter, stack_pointer, frame_pointer, thread);
#endif
  UNREACHABLE();
}

static FieldPtr LookupStackTraceField(const Instance& instance) {
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

StackTracePtr Exceptions::CurrentStackTrace() {
  return GetStackTraceForException();
}

DART_NORETURN
static void ThrowExceptionHelper(Thread* thread,
                                 const Instance& incoming_exception,
                                 const Instance& existing_stacktrace,
                                 const bool is_rethrow) {
  // SuspendLongJumpScope during Dart entry ensures that if a longjmp base is
  // available, it is the innermost error handler. If one is available, so
  // should jump there instead.
  RELEASE_ASSERT(thread->long_jump_base() == nullptr);
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
#if !defined(PRODUCT)
  // Do not notify debugger on stack overflow and out of memory exceptions.
  // The VM would crash when the debugger calls back into the VM to
  // get values of variables.
  if (incoming_exception.raw() != isolate->object_store()->out_of_memory() &&
      incoming_exception.raw() != isolate->object_store()->stack_overflow()) {
    isolate->debugger()->PauseException(incoming_exception);
  }
#endif
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
          zone,
          isolate->isolate_object_store()->preallocated_unhandled_exception());
      thread->long_jump_base()->Jump(1, error);
      UNREACHABLE();
    }
    stacktrace = isolate->isolate_object_store()->preallocated_stack_trace();
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
    finder.PrepareFrameForCatchEntry();
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
    // the isolate etc.). This can happen in the compiler, which is not
    // allowed to allocate in new space, so we pass the kOld argument.
    const UnhandledException& unhandled_exception = UnhandledException::Handle(
        zone, exception.raw() == isolate->object_store()->out_of_memory()
                  ? isolate->isolate_object_store()
                        ->preallocated_unhandled_exception()
                  : UnhandledException::New(exception, stacktrace, Heap::kOld));
    stacktrace = StackTrace::null();
    JumpToExceptionHandler(thread, handler_pc, handler_sp, handler_fp,
                           unhandled_exception, stacktrace);
  }
  UNREACHABLE();
}

// Static helpers for allocating, initializing, and throwing an error instance.

// Return the script of the Dart function that called the native entry or the
// runtime entry. The frame iterator points to the callee.
ScriptPtr Exceptions::GetCallerScript(DartFrameIterator* iterator) {
  StackFrame* caller_frame = iterator->NextFrame();
  ASSERT(caller_frame != NULL && caller_frame->IsDartFrame());
  const Function& caller = Function::Handle(caller_frame->LookupDartFunction());
#if defined(DART_PRECOMPILED_RUNTIME)
  if (caller.IsNull()) return Script::null();
#else
  ASSERT(!caller.IsNull());
#endif
  return caller.script();
}

// Allocate a new instance of the given class name.
// TODO(hausner): Rename this NewCoreInstance to call out the fact that
// the class name is resolved in the core library implicitly?
InstancePtr Exceptions::NewInstance(const char* class_name) {
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
                                         const String& dst_name) {
  ASSERT(!dst_name.IsNull());  // Pass Symbols::Empty() instead.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Array& args = Array::Handle(zone, Array::New(4));

  ExceptionType exception_type =
      (dst_name.raw() == Symbols::InTypeCast().raw()) ? kCast : kType;

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  const Script& script = Script::Handle(zone, GetCallerScript(&iterator));
  const String& url = String::Handle(
      zone, script.IsNull() ? Symbols::OptimizedOut().raw() : script.url());
  intptr_t line = -1;
  intptr_t column = -1;
  if (!script.IsNull()) {
    script.GetTokenLocation(location, &line, &column);
  }
  // Initialize '_url', '_line', and '_column' arguments.
  args.SetAt(0, url);
  args.SetAt(1, Smi::Handle(zone, Smi::New(line)));
  args.SetAt(2, Smi::Handle(zone, Smi::New(column)));

  // Construct '_errorMsg'.
  const GrowableObjectArray& pieces =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New(20));

  if (!dst_type.IsNull()) {
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
    // Print ambiguous URIs of src and dst types.
    URIs uris(zone, 12);
    if (!src_type.IsNull()) {
      src_type.EnumerateURIs(&uris);
    }
    if (!dst_type.IsDynamicType() && !dst_type.IsVoidType() &&
        !dst_type.IsNeverType()) {
      dst_type.EnumerateURIs(&uris);
    }
    const String& formatted_uris =
        String::Handle(zone, AbstractType::PrintURIs(&uris));
    if (formatted_uris.Length() > 0) {
      pieces.Add(Symbols::SpaceWhereNewLine());
      pieces.Add(formatted_uris);
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
  ASSERT(!error.IsNull());
  Thread* thread = Thread::Current();
  // SuspendLongJumpScope during Dart entry ensures that if a longjmp base is
  // available, it is the innermost error handler. If one is available, so
  // should jump there instead.
  RELEASE_ASSERT(thread->long_jump_base() == nullptr);
  Zone* zone = thread->zone();
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

void Exceptions::PropagateToEntry(const Error& error) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->top_exit_frame_info() != 0);
  Instance& stacktrace = Instance::Handle(zone);
  if (error.IsUnhandledException()) {
    const UnhandledException& uhe = UnhandledException::Cast(error);
    stacktrace = uhe.stacktrace();
  } else {
    stacktrace = Exceptions::CurrentStackTrace();
  }
  uword handler_pc = 0;
  uword handler_sp = 0;
  uword handler_fp = 0;
  FindErrorHandler(&handler_pc, &handler_sp, &handler_fp);
  JumpToExceptionHandler(thread, handler_pc, handler_sp, handler_fp, error,
                         stacktrace);
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

void Exceptions::ThrowUnsupportedError(const char* msg) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, String::Handle(String::New(msg)));
  Exceptions::ThrowByType(Exceptions::kUnsupported, args);
}

void Exceptions::ThrowCompileTimeError(const LanguageError& error) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, String::Handle(error.FormatMessage()));
  Exceptions::ThrowByType(Exceptions::kCompileTimeError, args);
}

void Exceptions::ThrowLateFieldNotInitialized(const String& name) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, name);
  Exceptions::ThrowByType(Exceptions::kLateFieldNotInitialized, args);
}

void Exceptions::ThrowLateFieldAssignedDuringInitialization(
    const String& name) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, name);
  Exceptions::ThrowByType(Exceptions::kLateFieldAssignedDuringInitialization,
                          args);
}

ObjectPtr Exceptions::Create(ExceptionType type, const Array& arguments) {
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
    case kIntegerDivisionByZeroException:
      library = Library::CoreLibrary();
      class_name = &Symbols::IntegerDivisionByZeroException();
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
    case kLateFieldAssignedDuringInitialization:
      library = Library::InternalLibrary();
      class_name = &Symbols::LateError();
      constructor_name = &Symbols::DotFieldADI();
      break;
    case kLateFieldNotInitialized:
      library = Library::InternalLibrary();
      class_name = &Symbols::LateError();
      constructor_name = &Symbols::DotFieldNI();
      break;
  }

  Thread* thread = Thread::Current();
  NoReloadScope no_reload_scope(thread->isolate(), thread);
  return DartLibraryCalls::InstanceCreate(library, *class_name,
                                          *constructor_name, arguments);
}

UnhandledExceptionPtr Exceptions::CreateUnhandledException(Zone* zone,
                                                           ExceptionType type,
                                                           const char* msg) {
  const String& error_str = String::Handle(zone, String::New(msg));
  const Array& args = Array::Handle(zone, Array::New(1));
  args.SetAt(0, error_str);

  Object& result = Object::Handle(zone, Exceptions::Create(type, args));
  const StackTrace& stacktrace = StackTrace::Handle(zone);
  return UnhandledException::New(Instance::Cast(result), stacktrace);
}

}  // namespace dart
