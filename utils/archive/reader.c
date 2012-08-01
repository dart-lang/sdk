// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "messaging.h"
#include "reader.h"

void archiveReadNew(Dart_Port p) {
  struct archive* a = archive_read_new();
  DART_INT64(result, (intptr_t) a)
  postSuccess(p, &result);
  return;
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

#define RAW_ARCHIVE_SIZE 32

void archiveReadNextHeader(Dart_Port p, struct archive* a) {
  // TODO(nweiz): At some point, we'll want to attach the actual archive pointer
  // to the struct we send to Dart so that it can later be modified, passed in
  // to other functions, etc. When we do so, we'll need to use archive_entry_new
  // to create it and we'll have to attach a finalizer to the Dart object to
  // ensure that it gets freed.
  struct archive_entry* entry;
  int result = archive_read_next_header(a, &entry);
  if (result == ARCHIVE_EOF) {
    postSuccess(p, NULL);
    return;
  }
  if (checkError(p, a, result)) return;

  Dart_CObject* archive_entry_array[RAW_ARCHIVE_SIZE];

  // archive_entry_paths(3)
  DART_STRING(hardlink, (char*) archive_entry_hardlink(entry))
  archive_entry_array[0] = &hardlink;
  DART_STRING(pathname, (char*) archive_entry_pathname(entry))
  archive_entry_array[1] = &pathname;
  DART_STRING(sourcepath, (char*) archive_entry_sourcepath(entry))
  archive_entry_array[2] = &sourcepath;
  DART_STRING(symlink, (char*) archive_entry_symlink(entry))
  archive_entry_array[3] = &symlink;

  // archive_entry_perms(3)
  DART_INT32(gid, archive_entry_gid(entry))
  archive_entry_array[4] = &gid;
  DART_INT32(uid, archive_entry_uid(entry))
  archive_entry_array[5] = &uid;
  DART_INT32(perm, archive_entry_perm(entry))
  archive_entry_array[6] = &perm;
  DART_STRING(strmode, (char*) archive_entry_strmode(entry))
  archive_entry_array[7] = &strmode;
  DART_STRING(gname, (char*) archive_entry_gname(entry))
  archive_entry_array[8] = &gname;
  DART_STRING(uname, (char*) archive_entry_uname(entry))
  archive_entry_array[9] = &uname;

  unsigned long fflags_set;
  unsigned long fflags_clear;
  archive_entry_fflags(entry, &fflags_set, &fflags_clear);
  DART_INT64(wrapped_fflags_set, fflags_set)
  archive_entry_array[10] = &wrapped_fflags_set;
  DART_INT64(wrapped_fflags_clear, fflags_clear)
  archive_entry_array[11] = &wrapped_fflags_clear;

  DART_STRING(fflags_text, (char*) archive_entry_fflags_text(entry))
  archive_entry_array[12] = &fflags_text;

  // archive_entry_stat(3)
  DART_INT32(filetype, archive_entry_filetype(entry))
  archive_entry_array[13] = &filetype;
  DART_INT32(mode, archive_entry_mode(entry))
  archive_entry_array[14] = &mode;

  Dart_CObject size;
  if (archive_entry_size_is_set(entry)) {
    size.type = kInt64;
    size.value.as_int64 = archive_entry_size(entry);
  } else {
    size.type = kNull;
  }
  archive_entry_array[15] = &size;

  Dart_CObject dev;
  if (archive_entry_dev_is_set(entry)) {
    dev.type = kInt64;
    dev.value.as_int64 = archive_entry_dev(entry);
  } else {
    dev.type = kNull;
  }
  archive_entry_array[16] = &dev;

  DART_INT64(devmajor, archive_entry_devmajor(entry))
  archive_entry_array[17] = &devmajor;
  DART_INT64(devminor, archive_entry_devminor(entry))
  archive_entry_array[18] = &devminor;

  Dart_CObject ino;
  if (archive_entry_ino_is_set(entry)) {
    ino.type = kInt64;
    ino.value.as_int64 = archive_entry_ino64(entry);
  } else {
    ino.type = kNull;
  }
  archive_entry_array[19] = &ino;

  DART_INT64(nlink, archive_entry_nlink(entry))
  archive_entry_array[20] = &nlink;
  DART_INT64(rdev, archive_entry_rdev(entry))
  archive_entry_array[21] = &rdev;
  DART_INT64(rdevmajor, archive_entry_rdevmajor(entry))
  archive_entry_array[22] = &rdevmajor;
  DART_INT64(rdevminor, archive_entry_rdevminor(entry))
  archive_entry_array[23] = &rdevminor;

  // archive_entry_time(3)
  Dart_CObject atime;
  Dart_CObject atime_nsec;
  if (archive_entry_atime_is_set(entry)) {
    atime.type = kInt64;
    atime.value.as_int64 = archive_entry_atime(entry);
    atime_nsec.type = kInt64;
    atime_nsec.value.as_int64 = archive_entry_atime_nsec(entry);
  } else {
    atime.type = kNull;
    atime_nsec.type = kNull;
  }
  archive_entry_array[24] = &atime;
  archive_entry_array[25] = &atime_nsec;

  Dart_CObject birthtime;
  Dart_CObject birthtime_nsec;
  if (archive_entry_birthtime_is_set(entry)) {
    birthtime.type = kInt64;
    birthtime.value.as_int64 = archive_entry_birthtime(entry);
    birthtime_nsec.type = kInt64;
    birthtime_nsec.value.as_int64 = archive_entry_birthtime_nsec(entry);
  } else {
    birthtime.type = kNull;
    birthtime_nsec.type = kNull;
  }
  archive_entry_array[26] = &birthtime;
  archive_entry_array[27] = &birthtime_nsec;

  Dart_CObject ctime;
  Dart_CObject ctime_nsec;
  if (archive_entry_ctime_is_set(entry)) {
    ctime.type = kInt64;
    ctime.value.as_int64 = archive_entry_ctime(entry);
    ctime_nsec.type = kInt64;
    ctime_nsec.value.as_int64 = archive_entry_ctime_nsec(entry);
  } else {
    ctime.type = kNull;
    ctime_nsec.type = kNull;
  }
  archive_entry_array[28] = &ctime;
  archive_entry_array[29] = &ctime_nsec;

  Dart_CObject mtime;
  Dart_CObject mtime_nsec;
  if (archive_entry_mtime_is_set(entry)) {
    mtime.type = kInt64;
    mtime.value.as_int64 = archive_entry_mtime(entry);
    mtime_nsec.type = kInt64;
    mtime_nsec.value.as_int64 = archive_entry_mtime_nsec(entry);
  } else {
    mtime.type = kNull;
    mtime_nsec.type = kNull;
  }
  archive_entry_array[30] = &mtime;
  archive_entry_array[31] = &mtime_nsec;
  // If you add entries, don't forget to increase RAW_ARCHIVE_SIZE.

  Dart_CObject wrapped_archive_entry;
  wrapped_archive_entry.type = kArray;
  wrapped_archive_entry.value.as_array.values = archive_entry_array;
  wrapped_archive_entry.value.as_array.length = RAW_ARCHIVE_SIZE;

  postSuccess(p, &wrapped_archive_entry);
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
