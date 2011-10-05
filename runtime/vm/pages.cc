// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/pages.h"

#include "vm/assert.h"
#include "vm/object.h"
#include "vm/virtual_memory.h"

namespace dart {

HeapPage* HeapPage::Initialize(VirtualMemory* memory, bool is_executable) {
  ASSERT(memory->size() > VirtualMemory::PageSize());
  memory->Commit(is_executable);

  HeapPage* result = reinterpret_cast<HeapPage*>(memory->address());
  result->memory_ = memory;
  result->next_ = NULL;
  result->used_ = 0;
  result->top_ = result->first_object_start();
  return result;
}


HeapPage* HeapPage::Allocate(intptr_t size, bool is_executable) {
  VirtualMemory* memory =
      VirtualMemory::ReserveAligned(size, PageSpace::kPageAlignment);
  return Initialize(memory, is_executable);
}


void HeapPage::Deallocate() {
  // The memory for this object will become unavailable after the delete below.
  delete memory_;
}


void HeapPage::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  uword obj_addr = first_object_start();
  uword end_addr = top();
  while (obj_addr < end_addr) {
    RawObject* raw_obj = RawObject::FromAddr(obj_addr);
    obj_addr += raw_obj->VisitPointers(visitor);
  }
  ASSERT(obj_addr == end_addr);
}


PageSpace::PageSpace(Heap* heap, intptr_t max_capacity, bool is_executable)
    : heap_(heap),
      pages_(NULL),
      pages_tail_(NULL),
      large_pages_(NULL),
      max_capacity_(max_capacity),
      capacity_(0),
      in_use_(0),
      is_executable_(is_executable) { }


PageSpace::~PageSpace() {
  FreePages(pages_);
  FreePages(large_pages_);
}


void PageSpace::AllocatePage() {
  HeapPage* page = HeapPage::Allocate(kPageSize, is_executable_);
  if (pages_ == NULL) {
    pages_ = page;
  } else {
    pages_tail_->set_next(page);
  }
  pages_tail_ = page;
  capacity_ += kPageSize;
}


HeapPage* PageSpace::AllocateLargePage(intptr_t size) {
  intptr_t page_size = Utils::RoundUp(size + sizeof(HeapPage),
                                      VirtualMemory::PageSize());
  HeapPage* page = HeapPage::Allocate(page_size, is_executable_);
  page->set_next(large_pages_);
  large_pages_ = page;
  capacity_ += page_size;
  return page;
}


void PageSpace::FreePages(HeapPage* pages) {
  HeapPage* page = pages;
  while (page != NULL) {
    HeapPage* next = page->next();
    page->Deallocate();
    page = next;
  }
}


uword PageSpace::TryBumpAllocate(intptr_t size) {
  HeapPage* page = pages_tail_;
  if (page == NULL) {
    return 0;
  }
  uword result = page->top();
  intptr_t remaining_space = page->end() - result;
  if (remaining_space < size) {
    return 0;
  }
  page->set_top(result + size);
  return result;
}


uword PageSpace::TryAllocate(intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword result = 0;
  if (size < kAllocatablePageSize) {
    result = TryBumpAllocate(size);
    if (result == 0) {
      if (capacity_ < max_capacity_) {
        AllocatePage();
        result = TryBumpAllocate(size);
        ASSERT(result != 0);
      }
    }
  } else {
    // Large page allocation.
    HeapPage* page = AllocateLargePage(size);
    if (page != NULL) {
      result = page->top();
      page->set_top(result + size);
    }
  }
  if (result != 0) {
    in_use_ += size;
  }
  return result;
}


bool PageSpace::Contains(uword addr) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    if (page->Contains(addr)) {
      return true;
    }
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    if (page->Contains(addr)) {
      return true;
    }
    page = page->next();
  }
  return false;
}


void PageSpace::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    page->VisitObjectPointers(visitor);
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    page->VisitObjectPointers(visitor);
    page = page->next();
  }
}

}  // namespace dart
