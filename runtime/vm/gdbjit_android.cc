// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "vm/gdbjit_android.h"

extern "C" {
  typedef enum {
    JIT_NOACTION = 0,
    JIT_REGISTER_FN,
    JIT_UNREGISTER_FN
  } jit_actions_t;

  struct jit_code_entry {
    struct jit_code_entry *next_entry;
    struct jit_code_entry *prev_entry;
    const char *symfile_addr;
    uint64_t symfile_size;
  };

  struct jit_descriptor {
    uint32_t version;
    /* This type should be jit_actions_t, but we use uint32_t
       to be explicit about the bitwidth.  */
    uint32_t action_flag;
    struct jit_code_entry *relevant_entry;
    struct jit_code_entry *first_entry;
  };

  /* GDB puts a breakpoint in this function.  */
  void __attribute__((noinline)) __jit_debug_register_code() { }

  /* Make sure to specify the version statically, because the
     debugger may check the version before we can set it.  */
  struct jit_descriptor __jit_debug_descriptor = { 1, 0, 0, 0 };

  static struct jit_code_entry* first_dynamic_region = NULL;
  static struct jit_code_entry* last_dynamic_region = NULL;

  void addDynamicSection(const char* symfile_addr, uint64_t symfile_size) {
    jit_code_entry* new_entry = reinterpret_cast<jit_code_entry*>(
        malloc(sizeof(jit_code_entry)));
    if (new_entry != NULL) {
      new_entry->symfile_addr = symfile_addr;
      new_entry->symfile_size = symfile_size;
      new_entry->next_entry = NULL;
      new_entry->prev_entry = last_dynamic_region;
      if (first_dynamic_region == NULL) {
        first_dynamic_region = new_entry;
      } else {
        last_dynamic_region->next_entry = new_entry;
      }
      last_dynamic_region = new_entry;
    }
    __jit_debug_descriptor.action_flag = JIT_REGISTER_FN;
    __jit_debug_descriptor.relevant_entry = new_entry;
    __jit_debug_descriptor.first_entry = first_dynamic_region;
    __jit_debug_register_code();
  }

  void deleteDynamicSections() {
    struct jit_code_entry* iterator = last_dynamic_region;
    while (iterator != NULL) {
      __jit_debug_descriptor.action_flag = JIT_UNREGISTER_FN;
      __jit_debug_descriptor.relevant_entry = iterator;
      __jit_debug_descriptor.first_entry = first_dynamic_region;
      __jit_debug_register_code();
      iterator = iterator->prev_entry;
    }
    first_dynamic_region = NULL;
    last_dynamic_region = NULL;
  }
};
