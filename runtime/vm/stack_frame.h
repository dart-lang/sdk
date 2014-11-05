// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_H_
#define VM_STACK_FRAME_H_

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
#elif defined(TARGET_ARCH_MIPS)
#include "vm/stack_frame_mips.h"
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
  virtual ~StackFrame() { }

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

  void set_pc(uword value) {
    *reinterpret_cast<uword*>(sp_ + (kSavedPcSlotFromSp * kWordSize)) = value;
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
  bool FindExceptionHandler(Isolate* isolate,
                            uword* handler_pc,
                            bool* needs_stacktrace,
                            bool* is_catch_all) const;
  // Returns token_pos of the pc(), or -1 if none exists.
  intptr_t GetTokenPos() const;

 protected:
  explicit StackFrame(Isolate* isolate)
      : fp_(0), sp_(0), pc_(0), isolate_(isolate) { }

  // Name of the frame, used for generic frame printing functionality.
  virtual const char* GetName() const { return IsStubFrame()? "stub" : "dart"; }

  Isolate* isolate() const { return isolate_; }

 private:
  RawCode* GetCodeObject() const;

  uword GetCallerSp() const {
    return fp() + (kCallerSpSlotFromFp * kWordSize);
  }
  uword GetCallerFp() const {
    return *(reinterpret_cast<uword*>(
        fp() + (kSavedCallerFpSlotFromFp * kWordSize)));
  }
  uword GetCallerPc() const {
    return *(reinterpret_cast<uword*>(
        fp() + (kSavedCallerPcSlotFromFp * kWordSize)));
  }

  uword fp_;
  uword sp_;
  uword pc_;
  Isolate* isolate_;

  // The iterators FrameSetIterator and StackFrameIterator set the private
  // fields fp_ and sp_ when they return the respective frame objects.
  friend class FrameSetIterator;
  friend class StackFrameIterator;
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
  explicit ExitFrame(Isolate* isolate) : StackFrame(isolate) { }

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(ExitFrame);
};


// Entry Frame is used to mark the transition from dart VM runtime code into
// dart code.
class EntryFrame : public StackFrame {
 public:
  bool IsValid() const {
    return StubCode::InInvocationStubForIsolate(isolate(), pc());
  }
  bool IsDartFrame(bool validate = true) const { return false; }
  bool IsStubFrame() const { return false; }
  bool IsEntryFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

 protected:
  virtual const char* GetName() const { return "entry"; }

 private:
  explicit EntryFrame(Isolate* isolate) : StackFrame(isolate) { }

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(EntryFrame);
};


// A StackFrameIterator can be initialized with an isolate other than the
// current thread's isolate. Because this is generally a bad idea,
// it is only allowed on Windows- where it is needed for the profiler.
// It is the responsibility of users of StackFrameIterator to ensure that the
// isolate given is not running concurrently on another thread.
class StackFrameIterator : public ValueObject {
 public:
  static const bool kValidateFrames = true;
  static const bool kDontValidateFrames = false;

  // Iterators for iterating over all frames from the last ExitFrame to the
  // first EntryFrame.
  explicit StackFrameIterator(bool validate,
                              Isolate* isolate = Isolate::Current());
  StackFrameIterator(uword last_fp, bool validate,
                     Isolate* isolate = Isolate::Current());

  // Iterator for iterating over all frames from the current frame (given by its
  // fp, sp, and pc) to the first EntryFrame.
  StackFrameIterator(uword fp, uword sp, uword pc, bool validate,
                     Isolate* isolate = Isolate::Current());

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
      const uword pc = *(reinterpret_cast<uword*>(
          sp_ + (kSavedPcSlotFromSp * kWordSize)));
      return !StubCode::InInvocationStubForIsolate(isolate_, pc);
    }

    // Get next non entry/exit frame in the set (assumes a next frame exists).
    StackFrame* NextFrame(bool validate);

   private:
    explicit FrameSetIterator(Isolate* isolate)
        : fp_(0), sp_(0), pc_(0), stack_frame_(isolate), isolate_(isolate) { }
    uword fp_;
    uword sp_;
    uword pc_;
    StackFrame stack_frame_;  // Singleton frame returned by NextFrame().
    Isolate* isolate_;

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

  bool validate_;  // Validate each frame as we traverse the frames.
  EntryFrame entry_;  // Singleton entry frame returned by NextEntryFrame().
  ExitFrame exit_;  // Singleton exit frame returned by NextExitFrame().
  FrameSetIterator frames_;
  StackFrame* current_frame_;  // Points to the current frame in the iterator.
  Isolate* isolate_;

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
  explicit DartFrameIterator(Isolate* isolate = Isolate::Current())
      : frames_(StackFrameIterator::kDontValidateFrames, isolate) { }
  DartFrameIterator(uword last_fp,
                    Isolate* isolate = Isolate::Current())
      : frames_(last_fp, StackFrameIterator::kDontValidateFrames, isolate) { }
  DartFrameIterator(uword fp,
                    uword sp,
                    uword pc,
                    Isolate* isolate = Isolate::Current())
      : frames_(fp, sp, pc, StackFrameIterator::kDontValidateFrames, isolate) {
  }
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
  Code& code_;
  DeoptInfo& deopt_info_;
  Function& function_;
  uword pc_;
  GrowableArray<DeoptInstr*> deopt_instructions_;
  Array& object_table_;

  DISALLOW_COPY_AND_ASSIGN(InlinedFunctionsIterator);
};

}  // namespace dart

#endif  // VM_STACK_FRAME_H_
