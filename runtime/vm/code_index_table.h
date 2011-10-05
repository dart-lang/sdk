// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_INDEX_TABLE_H_
#define VM_CODE_INDEX_TABLE_H_

#include "vm/assert.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class Array;
class Code;
class Function;
class Isolate;
class ObjectPointerVisitor;
class RawArray;
class RawCode;
class RawFunction;

// This class is used to lookup a Function object given a pc.
// This functionality is used while stack walking in order to find the Dart
// function corresponding to a frame (enables the pc descriptors for
// a stack frame to be located).
// Most functions fit within a normal page (PageSpace::KPageSize) but some
// functions may have code which is larger than the size of a normal page.
// These functions are referred to as large functions in this code and are
// handled by maintaining separate index lists.
class CodeIndexTable {
 public:
  ~CodeIndexTable();

  // Add specified compiled function to the code index table.
  void AddFunction(const Function& func);

  // Lookup code index table to find the function corresponding to the
  // specified 'pc'. If there is no corresponding function a null object
  // is returned.
  RawFunction* LookupFunction(uword pc) const;

  // Lookup code index table to find corresponding code object.
  RawCode* LookupCode(uword pc) const;

  // Visit all object pointers (support for GC).
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Initialize the code index table for specified isolate.
  static void Init(Isolate* isolate);

 private:
  static const int kInitialSize = 16;
  static const bool kIsSorted = true;
  static const bool kIsNotSorted = false;

  template<typename T>
  class IndexArray {
   public:
    explicit IndexArray(int initial_capacity)
        : length_(0),
          capacity_(initial_capacity),
          data_(NULL) {
      data_ = reinterpret_cast<T*>(malloc(capacity_ * sizeof(T)));
      ASSERT(data_ != NULL);
    }
    ~IndexArray() {
      free(data_);
      data_ = NULL;
      capacity_ = 0;
      length_ = 0;
    }
    intptr_t length() const { return length_; }
    T* data() const { return data_; }
    bool IsFull() const { return length_ >= capacity_; }
    T& At(intptr_t index) const {
      ASSERT(0 <= index);
      ASSERT(index < length_);
      ASSERT(length_ <= capacity_);
      return data_[index];
    }
    void Add(const T& value) {
      ASSERT(length_ < capacity_);
      data_[length_] = value;
      length_ += 1;
    }
    void Resize(int new_capacity) {
      ASSERT(new_capacity > capacity_);
      T* new_data = reinterpret_cast<T*>(realloc(reinterpret_cast<void*>(data_),
                                                 new_capacity * sizeof(T)));
      ASSERT(new_data != NULL);
      data_ = new_data;
      capacity_ = new_capacity;
    }
   private:
    intptr_t length_;
    intptr_t capacity_;
    T* data_;
    DISALLOW_COPY_AND_ASSIGN(IndexArray);
  };

  // PC range for a function.
  typedef struct {
    uword entrypoint;  // Entry point for the function.
    intptr_t size;  // Code size for the function.
  } PcRange;

  // Information about function pc ranges for a code page.
  typedef struct {
    uword page_start;  // Start address of code page.
    IndexArray<PcRange>* pc_ranges;  // Array of entry points in a code page.
  } CodePageInfo;

  // Constructor.
  CodeIndexTable();

  // Add code page information to the index table.
  int AddPageIndex(uword page_start);

  // Find the index corresponding to the code page in the index table.
  int FindPageIndex(uword page_start) const;

  // Add information about a function (entrypoint, size, function object)
  // at the specified index of the index table.
  void AddFunctionToList(int page_index,
                         uword entrypoint,
                         intptr_t size,
                         const Function& func);

  // Add information about a large function (entrypoint, size, function object)
  // to the large function list.
  void AddLargeFunction(uword entrypoint, intptr_t size, const Function& func);

  // Helper function to add a function to the list.
  void AddFuncHelper(IndexArray<PcRange>* pc_ranges,
                     const Array& functions,
                     uword entrypoint,
                     intptr_t size,
                     const Function& func);

  // Lookup code corresponding to the pc in the large functions list
  RawCode* LookupLargeCode(uword pc) const;

  // Lookup code corresponding to the pc in the functions list
  // present at the specified page index.
  static RawCode* LookupCodeFromList(IndexArray<PcRange>* pc_ranges,
                                     const Array& functions,
                                     uword pc,
                                     bool sorted);

  // Find index of pc in the pc ranges array, returns -1 if the pc
  // is not found in the array.
  static intptr_t FindPcIndex(const IndexArray<PcRange>& pc_ranges,
                              uword pc,
                              bool sorted);

  // Grow the index table to the specified new size.
  void GrowCodeIndexTable(int new_size);

  IndexArray<CodePageInfo>* code_pages_;  // Array of code pages information.
  RawArray* code_lists_;  // Array of pointers to code lists (arrays).
  IndexArray<PcRange>* largecode_pc_ranges_;  // pc ranges of large codes.
  RawArray* largecode_list_;  // Array of pointer to large code objects.

  DISALLOW_COPY_AND_ASSIGN(CodeIndexTable);
};

}  // namespace dart

#endif  // VM_CODE_INDEX_TABLE_H_
