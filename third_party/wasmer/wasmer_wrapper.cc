// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Wraps several functions from wasmer.hh, so that they take and return all
// structs by pointer, rather than by value. This is necessary because Dart FFI
// doesn't support passing structs by value yet (once it does, we can delete
// this wrapper).

#include "wasmer.hh"

extern "C" {
// Wraps wasmer_export_name.
void wasmer_export_name_ptr(wasmer_export_t* export_,
                            wasmer_byte_array* out_name) {
  *out_name = wasmer_export_name(export_);
}

// Wraps wasmer_export_descriptor_name.
void wasmer_export_descriptor_name_ptr(
    wasmer_export_descriptor_t* export_descriptor,
    wasmer_byte_array* out_name) {
  *out_name = wasmer_export_descriptor_name(export_descriptor);
}

// Wraps wasmer_import_descriptor_module_name.
void wasmer_import_descriptor_module_name_ptr(
    wasmer_import_descriptor_t* import_descriptor,
    wasmer_byte_array* out_name) {
  *out_name = wasmer_import_descriptor_module_name(import_descriptor);
}

// Wraps wasmer_import_descriptor_name.
void wasmer_import_descriptor_name_ptr(
    wasmer_import_descriptor_t* import_descriptor,
    wasmer_byte_array* out_name) {
  *out_name = wasmer_import_descriptor_name(import_descriptor);
}

// Wraps wasmer_memory_new.
wasmer_result_t wasmer_memory_new_ptr(wasmer_memory_t** memory,
                                      wasmer_limits_t* limits) {
  return wasmer_memory_new(memory, *limits);
}
}
