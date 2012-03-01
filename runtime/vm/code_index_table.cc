// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_index_table.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

CodeIndexTable::CodeIndexTable() : code_pages_(NULL),
                                   code_lists_(Array::null()),
                                   largecode_pc_ranges_(NULL),
                                   largecode_list_(Array::null()) {
  code_pages_ = new IndexArray<CodePageInfo>(kInitialSize);
  ASSERT(code_pages_ != NULL);
  code_lists_ = Array::New(kInitialSize);
}


CodeIndexTable::~CodeIndexTable() {
  for (intptr_t i = 0; i < code_pages_->length(); i++) {
    IndexArray<PcRange>* pc_ranges = code_pages_->At(i).pc_ranges;
    delete pc_ranges;
  }
  delete code_pages_;
  code_lists_ = Array::null();
  delete largecode_pc_ranges_;
  largecode_list_ = Array::null();
}


void CodeIndexTable::AddFunction(const Function& func) {
  const Code& code = Code::Handle(func.code());
  ASSERT(!code.IsNull());
  uword entrypoint = code.EntryPoint();  // Entry point for a function.
  intptr_t instr_size = code.Size();  // Instructions size for the function.
  if (PageSpace::IsPageAllocatableSize(instr_size)) {
    uword page_start = (entrypoint & ~(PageSpace::kPageSize - 1));
    int page_index = FindPageIndex(page_start);
    if (page_index == -1) {
      // We do not have an entry for this code page, add one.
      page_index = AddPageIndex(page_start);
    }
    ASSERT(page_index != -1);
    // Add the entrypoint, size and function object at the specified index.
    AddFunctionToList(page_index, entrypoint, instr_size, func);
  } else {
    AddLargeFunction(entrypoint, instr_size, func);
  }
}


RawFunction* CodeIndexTable::LookupFunction(uword pc) const {
  const Code& code = Code::Handle(LookupCode(pc));
  if (code.IsNull()) {
    return Function::null();
  }
  return code.function();
}


RawCode* CodeIndexTable::LookupCode(uword pc) const {
  uword page_start = (pc & ~(PageSpace::kPageSize - 1));
  int page_index = FindPageIndex(page_start);
  if (page_index == -1) {
    // Check if the pc exists in the large pc ranges as this might be
    // the pc of a large code object. This would return the large code
    // or a null object if it doesn't exist in that list too.
    return LookupLargeCode(pc);
  }
  IndexArray<PcRange>* pc_ranges = code_pages_->At(page_index).pc_ranges;
  const Array& codes_list = Array::Handle(code_lists_);
  ASSERT(!codes_list.IsNull());
  ASSERT(page_index < (codes_list.Length() - 1));
  Array& codes = Array::Handle();
  codes ^= codes_list.At(page_index);
  return LookupCodeFromList(pc_ranges, codes, pc, kIsSorted);
}


void CodeIndexTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&code_lists_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&largecode_list_));
}


void CodeIndexTable::Init(Isolate* isolate) {
  ASSERT(isolate->code_index_table() == NULL);
  CodeIndexTable* code_index_table = new CodeIndexTable();
  isolate->set_code_index_table(code_index_table);
}


int CodeIndexTable::AddPageIndex(uword page_start) {
  ASSERT(FindPageIndex(page_start) == -1);
  int page_index = code_pages_->length();
  CodePageInfo code;
  code.page_start = page_start;
  code.pc_ranges = new IndexArray<PcRange>(kInitialSize);
  ASSERT(code.pc_ranges != NULL);
  code_pages_->Add(code);  // code gets added at 'index'.
  const Array& codes_list = Array::Handle(code_lists_);
  ASSERT(!codes_list.IsNull());
  const Array& codes = Array::Handle(Array::New(kInitialSize));
  codes_list.SetAt(page_index, codes);
  if (code_pages_->IsFull()) {
    // Grow the index table.
    int new_size = code_pages_->length() + kInitialSize;
    GrowCodeIndexTable(new_size);
  }
  return page_index;
}


int CodeIndexTable::FindPageIndex(uword page_start) const {
  // We don't expect too many code pages (maybe max of 16) so it is
  // ok to scan linearly in order to find the page_start in this index
  // table.
  for (int i = 0; i < code_pages_->length(); i++) {
    if (code_pages_->At(i).page_start == page_start) {
      return i;
    }
  }
  return -1;
}


void CodeIndexTable::AddFunctionToList(int page_index,
                                       uword entrypoint,
                                       intptr_t size,
                                       const Function& func) {
  // Get PC ranges index array at specified index.
  IndexArray<PcRange>* pc_ranges = code_pages_->At(page_index).pc_ranges;
  ASSERT(pc_ranges != NULL);
  const Array& codes_list = Array::Handle(code_lists_);
  ASSERT(!codes_list.IsNull());
  // Get functions array present at specified index.
  Array& codes = Array::Handle();
  codes ^= codes_list.At(page_index);
  ASSERT(!codes.IsNull());
  // Asserting with an unsorted search, to ensure addition of pc was done right.
  ASSERT(FindPcIndex(*pc_ranges, entrypoint, kIsNotSorted) == -1);
  AddFuncHelper(pc_ranges, codes, entrypoint, size, func);
  if (pc_ranges->IsFull()) {
    // Grow the pc ranges table and the associated functions table.
    int new_size = pc_ranges->length() + kInitialSize;
    pc_ranges->Resize(new_size);
    codes = Array::Grow(codes, new_size);
    codes_list.SetAt(page_index, codes);
  }
}


void CodeIndexTable::AddLargeFunction(uword entrypoint,
                                      intptr_t size,
                                      const Function& func) {
  if (largecode_pc_ranges_ == NULL) {
    // No large functions seen so far.
    largecode_pc_ranges_ = new IndexArray<PcRange>(kInitialSize);
    ASSERT(largecode_pc_ranges_ != NULL);
    largecode_list_ = Array::New(kInitialSize);
  }
  ASSERT(FindPcIndex(*largecode_pc_ranges_, entrypoint, kIsNotSorted) == -1);
  const Array& largecode_list = Array::Handle(largecode_list_);
  ASSERT(!largecode_list.IsNull());
  AddFuncHelper(largecode_pc_ranges_, largecode_list, entrypoint, size, func);
  if (largecode_pc_ranges_->IsFull()) {
    // Grow largecode_pc_ranges_ and largecode_list_.
    int new_size = largecode_pc_ranges_->length() + kInitialSize;
    largecode_pc_ranges_->Resize(new_size);
    largecode_list_ = Array::Grow(largecode_list, new_size);
  }
}


void CodeIndexTable::AddFuncHelper(IndexArray<PcRange>* pc_ranges,
                                   const Array& codes,
                                   uword entrypoint,
                                   intptr_t size,
                                   const Function& func) {
  PcRange pc_range;
  pc_range.entrypoint = entrypoint;
  pc_range.size = size;
  intptr_t next_slot = pc_ranges->length();
  pc_ranges->Add(pc_range);  // pc_range gets added at 'next_slot'.
  codes.SetAt(next_slot, Code::Handle(func.code()));
}


RawCode* CodeIndexTable::LookupLargeCode(uword pc) const {
  const Array& large_codes = Array::Handle(largecode_list_);
  return LookupCodeFromList(largecode_pc_ranges_,
                            large_codes,
                            pc,
                            kIsNotSorted);
}


RawCode* CodeIndexTable::LookupCodeFromList(
    IndexArray<PcRange>* pc_ranges,
    const Array& codes,
    uword pc,
    bool sorted) {
  if (pc_ranges == NULL) {
    return Code::null();  // no entries in array so return null object.
  }
  intptr_t i = FindPcIndex(*pc_ranges, pc, sorted);
  if (i == -1) {
    return Code::null();  // no entry for pc, return null object.
  }
  // 'i' is in the index which holds the entry for the function,
  // access the functions array at 'i' and return the function object.
  ASSERT(!codes.IsNull());
  ASSERT(i < (codes.Length() - 1));
  Code& code = Code::Handle();
  code ^= codes.At(i);
  return code.raw();
}


intptr_t CodeIndexTable::FindPcIndex(const IndexArray<PcRange>& pc_ranges,
                                     uword pc,
                                     bool sorted) {
  if (sorted) {
    // The pc range entries are sorted, do a binary search to see if pc exists.
    intptr_t low = 0;
    intptr_t high = pc_ranges.length();
    while (low < high) {
      intptr_t mid = low + (high - low) / 2;
      uword entrypoint =  pc_ranges.At(mid).entrypoint;
      intptr_t size = pc_ranges.At(mid).size;
      if (entrypoint <= pc) {
        if (pc < (entrypoint + size)) {
          return mid;  // Found entry, return index.
        } else {
          low = mid + 1;
        }
      } else {
        high = mid;
      }
    }
  } else {
    // The pc range entries are not sorted, do a linear search.
    for (intptr_t i = (pc_ranges.length() - 1); i >= 0; i--) {
      uword entrypoint =  pc_ranges.At(i).entrypoint;
      intptr_t size = pc_ranges.At(i).size;
      if (entrypoint <= pc &&  pc < (entrypoint + size)) {
        return i;  // Found entry, return index.
      }
    }
  }
  return -1;  // Entry not found.
}


void CodeIndexTable::GrowCodeIndexTable(int new_size) {
  code_pages_->Resize(new_size);
  code_lists_ = Array::Grow(Array::Handle(code_lists_), new_size);
}

}  // namespace dart
