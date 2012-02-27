// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_H_
#define VM_STACK_FRAME_H_

#include "vm/allocation.h"
#include "vm/object.h"
#include "vm/stub_code.h"

namespace dart {

// Forward declarations.
class ObjectPointerVisitor;


// Generic stack frame.
class StackFrame : public ValueObject {
 public:
  enum FrameType {
    kDartFrame,
    kStubFrame,
    kEntryFrame,
    kExitFrame,
    kInvalidFrame,
  };

  virtual ~StackFrame() { }

  // Accessors to get the pc, sp and fp of a frame.
  uword sp() const { return sp_; }
  uword fp() const { return fp_; }
  uword pc() const {
    return *reinterpret_cast<uword*>(sp_ + PcAddressOffsetFromSp());
  }

  void set_pc(uword value) {
    *reinterpret_cast<uword*>(sp_ + PcAddressOffsetFromSp()) = value;
  }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor) = 0;

  // Print a frame.
  virtual void Print() const;

  // Check validity of a frame, used for assertion purposes.
  virtual bool IsValid() const { return false; }

  // Frame type.
  virtual bool IsDartFrame() const { return false; }
  virtual bool IsStubFrame() const { return false; }
  virtual bool IsEntryFrame() const { return false; }
  virtual bool IsExitFrame() const { return false; }

 protected:
  StackFrame() : fp_(0), sp_(0) { }

  // Name of the frame, used for generic frame printing functionality.
  virtual const char* GetName() const = 0;

 private:
  // Target specific implementations for locating pc and caller fp/sp values.
  static intptr_t PcAddressOffsetFromSp();
  uword GetCallerSp() const;
  uword GetCallerFp() const;

  uword fp_;
  uword sp_;

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
  bool IsExitFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

 protected:
  virtual const char* GetName() const { return "exit"; }

 private:
  ExitFrame() { }

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(ExitFrame);
};


// Entry Frame is used to mark the transition from dart VM runtime code into
// dart code.
class EntryFrame : public StackFrame {
 public:
  bool IsValid() const { return StubCode::InInvocationStub(pc()); }
  bool IsEntryFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

 protected:
  virtual const char* GetName() const { return "entry"; }

 private:
  EntryFrame() { }
  intptr_t ExitLinkOffset();

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(EntryFrame);
};


// Regular dart frames, these exist between an EntryFrame and an ExitFrame.
class DartFrame : public StackFrame {
 public:
  bool IsValid() const { return (LookupDartFunction() != Function::null()); }
  bool IsDartFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Get function object corresponding to pc for the frame.
  RawFunction* LookupDartFunction() const;

  // Get code object corresponding to pc for the frame.
  RawCode* LookupDartCode() const;

  // Find exception handler pc in frame if one exists.
  bool FindExceptionHandler(uword* handler_pc) const;

 protected:
  virtual const char* GetName() const { return "dart"; }

 private:
  DartFrame() { }

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(DartFrame);
};


// Stub frames.
class StubFrame : public StackFrame {
 public:
  bool IsValid() const;
  bool IsStubFrame() const { return true; }

  // Visit objects in the frame.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor);

 protected:
  virtual const char* GetName() const { return "stub"; }

 private:
  StubFrame() { }

  friend class StackFrameIterator;
  DISALLOW_COPY_AND_ASSIGN(StubFrame);
};


// Iterator for iterating over all frames from the last ExitFrame to the
// first EntryFrame.
class StackFrameIterator : public ValueObject {
 public:
  static const bool kValidateFrames = true;
  static const bool kDontValidateFrames = false;

  explicit StackFrameIterator(bool validate);

  // Checks if a next frame exists.
  bool HasNextFrame() const { return frames_.fp_ != 0; }

  // Get next frame.
  StackFrame* NextFrame();

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
      intptr_t offset = StackFrame::PcAddressOffsetFromSp();
      uword pc = *(reinterpret_cast<uword*>(sp_ + offset));
      return !StubCode::InInvocationStub(pc);
    }

    // Get next non entry/exit frame in the set (assumes a next frame exists).
    StackFrame* NextFrame(bool validate);

   private:
    FrameSetIterator() : fp_(0), sp_(0), from_stub_exitframe_(false),
                         dart_frame_(), stub_frame_() { }

    uword fp_;
    uword sp_;
    bool from_stub_exitframe_;  // Indicates if runtime called from stub frame.
    DartFrame dart_frame_;  // Singleton dart frame returned by NextFrame().
    StubFrame stub_frame_;  // Singleton stub frame returned by NextFrame().

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

  DISALLOW_COPY_AND_ASSIGN(StackFrameIterator);
};


// Iterator for iterating over all dart frames (skips over exit frames,
// entry frames and stub frames).
class DartFrameIterator : public ValueObject {
 public:
  DartFrameIterator() : frames_(StackFrameIterator::kDontValidateFrames) { }

  // Get next dart frame.
  DartFrame* NextFrame() {
    StackFrame* frame = frames_.NextFrame();
    while (frame != NULL && !frame->IsDartFrame()) {
      frame = frames_.NextFrame();
    }
    return reinterpret_cast<DartFrame*>(frame);
  }

 private:
  StackFrameIterator frames_;

  DISALLOW_COPY_AND_ASSIGN(DartFrameIterator);
};

}  // namespace dart

#endif  // VM_STACK_FRAME_H_
