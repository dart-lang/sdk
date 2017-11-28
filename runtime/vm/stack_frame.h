// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_FRAME_H_
#define RUNTIME_VM_STACK_FRAME_H_

#include "vm/allocation.h"
#include "vm/object.h"
#include "vm/stub_code.h"

#if defined(TARGET_ARCH_IA32)
#include "vm/stack_frame_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/stack_frame_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/stack_frame_arm.h"
#elif defined(TARGET_ARCH_ARM64)
#include "vm/stack_frame_arm64.h"
#elif defined(TARGET_ARCH_DBC)
#include "vm/stack_frame_dbc.h"
#else
#error Unknown architecture.
#endif

namespace dart {

// Forward declarations.
class ObjectPointerVisitor;
class RawContext;

// Generic stack frame.
class StackFrame : public ValueObject {
 public:
  virtual ~StackFrame() {}

  // Accessors to get the pc, sp and fp of a frame.
  uword sp() const { return sp_; }
  uword fp() const { return fp_; }
  uword pc() const { return pc_; }

  // The pool pointer is not implemented on all architectures.
  static int SavedCallerPpSlotFromFp() {
    if (kSavedCallerPpSlotFromFp != kSavedCallerFpSlotFromFp) {
      return kSavedCallerPpSlotFromFp;
    }
    UNREACHABLE();
    return 0;
  }

  uword IsMarkedForLazyDeopt() const {
    uword raw_pc =
        *reinterpret_cast<uword*>(sp() + (kSavedPcSlotFromSp * kWordSize));
    return raw_pc == StubCode::DeoptimizeLazyFromReturn_entry()->EntryPoint();
  }
  void MarkForLazyDeopt() {
    set_pc(StubCode::DeoptimizeLazyFromReturn_entry()->EntryPoint());
  }
  void UnmarkForLazyDeopt() {
    // If this frame was marked for lazy deopt, pc_ was computed to be the
    // original return address using the pending deopts table in GetCallerPc.
    // Write this value back into the frame.
    uword original_pc = pc();
    ASSERT(original_pc !=
           StubCode::DeoptimizeLazyFromReturn_entry()->EntryPoint());
    set_pc(original_pc);
  }

  void set_pc(uword value) {
    *reinterpret_cast<uword*>(sp() + (kSavedPcSlotFromSp * kWordSize)) = value;
    pc_ = value;
  }

  void set_pc_marker(RawCode* code) {
    *reinterpret_cast<RawCode**>(fp() + (kPcMarkerSlotFromFp * kWordSize)) =
        code;
  }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

  const char* ToCString() const;

  // Check validity of a frame, used for assertion purposes.
  virtual bool IsValid() const;

  // Frame type.
  virtual bool IsDartFrame(bool validate = true) const {
    ASSERT(!validate || IsValid());
    return !(IsEntryFrame() || IsExitFrame() || IsStubFrame());
  }
  virtual bool IsStubFrame() const;
  virtual bool IsEntryFrame() const { return false; }
  virtual bool IsExitFrame() const { return false; }

  RawFunction* LookupDartFunction() const;
  RawCode* LookupDartCode() const;
  bool FindExceptionHandler(Thread* thread,
                            uword* handler_pc,
                            bool* needs_stacktrace,
                            bool* is_catch_all,
                            bool* is_optimized) const;
  // Returns token_pos of the pc(), or -1 if none exists.
  TokenPosition GetTokenPos() const;

 protected:
  explicit StackFrame(Thread* thread)
      : fp_(0), sp_(0), pc_(0), thread_(thread) {}

  // Name of the frame, used for generic frame printing functionality.
  virtual const char* GetName() const {
    return IsStubFrame() ? "stub" : "dart";
  }

  Isolate* isolate() const { return thread_->isolate(); }

  Thread* thread() const { return thread_; }

 private:
  RawCode* GetCodeObject() const;
  RawCode* UncheckedGetCodeObject() const;

  uword GetCallerSp() const { return fp() + (kCallerSpSlotFromFp * kWordSize); }

  uword GetCallerFp() const {
    return *(reinterpret_cast<uword*>(fp() +
                                      (kSavedCallerFpSlotFromFp * kWordSize)));
  }

  uword GetCallerPc() const {
    uword raw_pc = *(reinterpret_cast<uword*>(
        fp() + (kSavedCallerPcSlotFromFp * kWordSize)));
    ASSERT(raw_pc != StubCode::DeoptimizeLazyFromThrow_entry()->EntryPoint());
    if (raw_pc == StubCode::DeoptimizeLazyFromReturn_entry()->EntryPoint()) {
      return isolate()->FindPendingDeopt(GetCallerFp());
    }
    return raw_pc;
  }

  uword fp_;
  uword sp_;
  uword pc_;
  Thread* thread_;

  // The iterators FrameSetIterator and StackFrameIterator set the private
  // fields fp_ and sp_ when they return the respective frame objects.
  friend class FrameSetIterator;
  friend class StackFrameIterator;
  friend class ProfilerDartStackWalker;
  DISALLOW_COPY_AND_ASSIGN(StackFrame);
};

// Exit frame is used to mark the transition from dart code into dart VM
// runtime code.
class ExitFrame : public StackFrame {
 public:
  bool IsValid() const { return sp() == 0; }
  bool IsDartFrame(bool validate = true) const { return false; }
  bool IsStubFrame() const { return false; }
  bool IsExitFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

 protected:
  virtual const char* GetName() const { return "exit"; }

 private:
  explicit ExitFrame(Thread* thread) : StackFrame(thread) {}

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(ExitFrame);
};

// Entry Frame is used to mark the transition from dart VM runtime code into
// dart code.
class EntryFrame : public StackFrame {
 public:
  bool IsValid() const { return StubCode::InInvocationStub(pc()); }
  bool IsDartFrame(bool validate = true) const { return false; }
  bool IsStubFrame() const { return false; }
  bool IsEntryFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

 protected:
  virtual const char* GetName() const { return "entry"; }

 private:
  explicit EntryFrame(Thread* thread) : StackFrame(thread) {}

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(EntryFrame);
};

// A StackFrameIterator can be initialized with a thread other than the
// current thread. Because this is generally a bad idea, it is only allowed on
// Windows- where it is needed for the profiler. It is the responsibility of
// users of StackFrameIterator to ensure that the thread given is not running
// concurrently.
class StackFrameIterator : public ValueObject {
 public:
  enum ValidationPolicy {
    kValidateFrames = 0,
    kDontValidateFrames = 1,
  };
  enum CrossThreadPolicy {
    kNoCrossThreadIteration = 0,
    kAllowCrossThreadIteration = 1,
  };

  // Iterators for iterating over all frames from the last ExitFrame to the
  // first EntryFrame.
  explicit StackFrameIterator(ValidationPolicy validation_policy,
                              Thread* thread,
                              CrossThreadPolicy cross_thread_policy);
  StackFrameIterator(uword last_fp,
                     ValidationPolicy validation_policy,
                     Thread* thread,
                     CrossThreadPolicy cross_thread_policy);

#if !defined(TARGET_ARCH_DBC)
  // Iterator for iterating over all frames from the current frame (given by its
  // fp, sp, and pc) to the first EntryFrame.
  StackFrameIterator(uword fp,
                     uword sp,
                     uword pc,
                     ValidationPolicy validation_policy,
                     Thread* thread,
                     CrossThreadPolicy cross_thread_policy);
#endif

  // Checks if a next frame exists.
  bool HasNextFrame() const { return frames_.fp_ != 0; }

  // Get next frame.
  StackFrame* NextFrame();

  bool validate() const { return validate_; }

 private:
  // Iterator for iterating over the set of frames (dart or stub) which exist
  // in one EntryFrame and ExitFrame block.
  class FrameSetIterator : public ValueObject {
   public:
    // Checks if a next non entry/exit frame exists in the set.
    bool HasNext() const {
      if (fp_ == 0) {
        return false;
      }
      const uword pc =
          *(reinterpret_cast<uword*>(sp_ + (kSavedPcSlotFromSp * kWordSize)));
      return !StubCode::InInvocationStub(pc);
    }

    // Get next non entry/exit frame in the set (assumes a next frame exists).
    StackFrame* NextFrame(bool validate);

   private:
    explicit FrameSetIterator(Thread* thread)
        : fp_(0), sp_(0), pc_(0), stack_frame_(thread), thread_(thread) {}
    uword fp_;
    uword sp_;
    uword pc_;
    StackFrame stack_frame_;  // Singleton frame returned by NextFrame().
    Thread* thread_;

    friend class StackFrameIterator;
    DISALLOW_COPY_AND_ASSIGN(FrameSetIterator);
  };

  // Get next exit frame.
  ExitFrame* NextExitFrame();

  // Get next entry frame.
  EntryFrame* NextEntryFrame();

  // Get an iterator to the next set of frames between an entry and exit
  // frame.
  FrameSetIterator* NextFrameSet() { return &frames_; }

  // Setup last or next exit frames so that we are ready to iterate over
  // stack frames.
  void SetupLastExitFrameData();
  void SetupNextExitFrameData();

  bool validate_;     // Validate each frame as we traverse the frames.
  EntryFrame entry_;  // Singleton entry frame returned by NextEntryFrame().
  ExitFrame exit_;    // Singleton exit frame returned by NextExitFrame().
  FrameSetIterator frames_;
  StackFrame* current_frame_;  // Points to the current frame in the iterator.
  Thread* thread_;

  friend class ProfilerDartStackWalker;
  DISALLOW_COPY_AND_ASSIGN(StackFrameIterator);
};

// Iterator for iterating over all dart frames (skips over exit frames,
// entry frames and stub frames).
// A DartFrameIterator can be initialized with an isolate other than the
// current thread's isolate. Because this is generally a bad idea,
// it is only allowed on Windows- where it is needed for the profiler.
// It is the responsibility of users of DartFrameIterator to ensure that the
// isolate given is not running concurrently on another thread.
class DartFrameIterator : public ValueObject {
 public:
  explicit DartFrameIterator(
      Thread* thread,
      StackFrameIterator::CrossThreadPolicy cross_thread_policy)
      : frames_(StackFrameIterator::kDontValidateFrames,
                thread,
                cross_thread_policy) {}
  explicit DartFrameIterator(
      uword last_fp,
      Thread* thread,
      StackFrameIterator::CrossThreadPolicy cross_thread_policy)
      : frames_(last_fp,
                StackFrameIterator::kDontValidateFrames,
                thread,
                cross_thread_policy) {}

#if !defined(TARGET_ARCH_DBC)
  DartFrameIterator(uword fp,
                    uword sp,
                    uword pc,
                    Thread* thread,
                    StackFrameIterator::CrossThreadPolicy cross_thread_policy)
      : frames_(fp,
                sp,
                pc,
                StackFrameIterator::kDontValidateFrames,
                thread,
                cross_thread_policy) {}
#endif

  // Get next dart frame.
  StackFrame* NextFrame() {
    StackFrame* frame = frames_.NextFrame();
    while (frame != NULL && !frame->IsDartFrame(frames_.validate())) {
      frame = frames_.NextFrame();
    }
    return frame;
  }

 private:
  StackFrameIterator frames_;

  DISALLOW_COPY_AND_ASSIGN(DartFrameIterator);
};

// Iterator for iterating over all inlined dart functions in an optimized
// dart frame (the iteration includes the function that is inlining the
// other functions).
class InlinedFunctionsIterator : public ValueObject {
 public:
  InlinedFunctionsIterator(const Code& code, uword pc);
  bool Done() const { return index_ == -1; }
  void Advance();

  RawFunction* function() const {
    ASSERT(!Done());
    return function_.raw();
  }

  uword pc() const {
    ASSERT(!Done());
    return pc_;
  }

  RawCode* code() const {
    ASSERT(!Done());
    return code_.raw();
  }

  intptr_t GetDeoptFpOffset() const;

 private:
  void SetDone() { index_ = -1; }

  intptr_t index_;
  intptr_t num_materializations_;
  intptr_t dest_frame_size_;
  Code& code_;
  TypedData& deopt_info_;
  Function& function_;
  uword pc_;
  GrowableArray<DeoptInstr*> deopt_instructions_;
  ObjectPool& object_table_;

  DISALLOW_COPY_AND_ASSIGN(InlinedFunctionsIterator);
};

#if defined(DEBUG)
void ValidateFrames();
#endif

#if !defined(TARGET_ARCH_DBC)
DART_FORCE_INLINE static intptr_t LocalVarIndex(intptr_t fp_offset,
                                                intptr_t var_index) {
  return fp_offset + var_index;
}

DART_FORCE_INLINE static uword ParamAddress(uword fp, intptr_t reverse_index) {
  return fp + (kParamEndSlotFromFp * kWordSize) + (reverse_index * kWordSize);
}

DART_FORCE_INLINE static bool IsCalleeFrameOf(uword fp, uword other_fp) {
  return other_fp < fp;
}

// Value for stack limit that is used to cause an interrupt.
// Note that on DBC stack is growing upwards so interrupt limit is 0 unlike
// on all other architectures.
static const uword kInterruptStackLimit = ~static_cast<uword>(0);
#endif

DART_FORCE_INLINE static uword LocalVarAddress(uword fp, intptr_t index) {
  return fp + LocalVarIndex(0, index) * kWordSize;
}

}  // namespace dart

#endif  // RUNTIME_VM_STACK_FRAME_H_
