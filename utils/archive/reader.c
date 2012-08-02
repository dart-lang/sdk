// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "entry.h"
#include "messaging.h"
#include "reader.h"

void archiveReadNew(Dart_Port p) {
  checkPointerResult(p, archive_read_new(), "archive input stream");
}

void archiveReadSupportFilterAll(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_filter_all(a));
}

void archiveReadSupportFilterBzip2(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_filter_bzip2(a));
}

void archiveReadSupportFilterCompress(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_filter_compress(a));
}

void archiveReadSupportFilterGzip(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_filter_gzip(a));
}

void archiveReadSupportFilterLzma(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_filter_lzma(a));
}

void archiveReadSupportFilterXz(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_filter_xz(a));
}

void archiveReadSupportFilterProgram(Dart_Port p, struct archive* a,
                                     Dart_CObject* request) {
  Dart_CObject* cmd = getTypedArgument(p, request, 0, kString);
  if (cmd == NULL) return;
  int result = archive_read_support_filter_program(
      a, cmd->value.as_string);
  checkResult(p, a, result);
}

void archiveReadSupportFilterProgramSignature(
    Dart_Port p, struct archive* a, Dart_CObject* request) {
  Dart_CObject* cmd = getTypedArgument(p, request, 0, kString);
  if (cmd == NULL) return;

  Dart_CObject* signature = getTypedArgument(p, request, 1, kUint8Array);
  if (cmd == NULL) return;

  int result = archive_read_support_filter_program_signature(
      a, cmd->value.as_string, signature->value.as_byte_array.values,
      signature->value.as_byte_array.length);
  checkResult(p, a, result);
}

void archiveReadSupportFormatAll(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_all(a));
}

void archiveReadSupportFormatAr(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_ar(a));
}

void archiveReadSupportFormatCpio(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_cpio(a));
}

void archiveReadSupportFormatEmpty(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_empty(a));
}

void archiveReadSupportFormatIso9660(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_iso9660(a));
}

void archiveReadSupportFormatMtree(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_mtree(a));
}

void archiveReadSupportFormatRaw(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_raw(a));
}

void archiveReadSupportFormatTar(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_tar(a));
}

void archiveReadSupportFormatZip(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_support_format_zip(a));
}

void archiveReadSetFilterOptions(Dart_Port p, struct archive* a,
                                 Dart_CObject* request) {
  Dart_CObject* options = getTypedArgument(p, request, 0, kString);
  if (options == NULL) return;
  int result = archive_read_set_filter_options(a, options->value.as_string);
  checkResult(p, a, result);
}

void archiveReadSetFormatOptions(Dart_Port p, struct archive* a,
                                 Dart_CObject* request) {
  Dart_CObject* options = getTypedArgument(p, request, 0, kString);
  if (options == NULL) return;
  int result = archive_read_set_format_options(a, options->value.as_string);
  checkResult(p, a, result);
}

void archiveReadSetOptions(Dart_Port p, struct archive* a,
                           Dart_CObject* request) {
  Dart_CObject* options = getTypedArgument(p, request, 0, kString);
  if (options == NULL) return;
  int result = archive_read_set_options(a, options->value.as_string);
  checkResult(p, a, result);
}

// TODO(nweiz): wrap archive_read_open2
// TODO(nweiz): wrap archive_read_FILE when issue 4160 is fixed

void archiveReadOpenFilename(Dart_Port p, struct archive* a,
                             Dart_CObject* request) {
  Dart_CObject* filename = getTypedArgument(p, request, 0, kString);
  if (filename == NULL) return;

  Dart_CObject* block_size = getIntArgument(p, request, 1);
  if (block_size == NULL) return;

  int result = archive_read_open_filename(a, filename->value.as_string,
                                          getInteger(block_size));
  checkResult(p, a, result);
}

void archiveReadOpenMemory(Dart_Port p, struct archive* a,
                           Dart_CObject* request) {
  Dart_CObject* filename = getTypedArgument(p, request, 0, kUint8Array);
  if (filename == NULL) return;

  int result = archive_read_open_memory(a, filename->value.as_byte_array.values,
                                        filename->value.as_byte_array.length);
  checkResult(p, a, result);
}

void archiveReadNextHeader(Dart_Port p, struct archive* a) {
  // TODO(nweiz): At some point, we'll want to attach the actual archive pointer
  // to the struct we send to Dart so that it can later be modified, passed in
  // to other functions, etc. When we do so, we'll need to use archive_entry_new
  // to create it and we'll have to attach a finalizer to the Dart object to
  // ensure that it gets freed.
  struct archive_entry* entry = archive_entry_new();
  if (checkPointerError(p, entry, "archive entry")) return;

  int result = archive_read_next_header2(a, entry);
  if (result == ARCHIVE_EOF) {
    postSuccess(p, NULL);
    archive_entry_free(entry);
  } else if (checkError(p, a, result)) {
    archive_entry_free(entry);
  } else {
    postArchiveEntryArray(p, entry);
  }
}

void archiveReadDataBlock(Dart_Port p, struct archive* a) {
  const void* buffer;
  size_t len;
  int64_t offset;
  int result = archive_read_data_block(a, &buffer, &len, &offset);
  if (result == ARCHIVE_EOF) {
    postSuccess(p, NULL);
    return;
  }
  if (checkError(p, a, result)) return;

  Dart_CObject wrapped_data_block;
  wrapped_data_block.type = kUint8Array;
  wrapped_data_block.value.as_byte_array.length = len;
  wrapped_data_block.value.as_byte_array.values = (void*) buffer + offset;
  postSuccess(p, &wrapped_data_block);
}

void archiveReadDataSkip(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_data_skip(a));
}

// TODO(nweiz): wrap archive_read_into_fd when issue 4160 is fixed
// TODO(nweiz): wrap archive_read_extract and friends

void archiveReadClose(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_close(a));
}

void archiveReadFree(Dart_Port p, struct archive* a) {
  checkResult(p, a, archive_read_free(a));
}
