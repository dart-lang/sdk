// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "entry.h"
#include "messaging.h"

#define DART_TIMESTAMP(name)                                      \
  Dart_CObject name;                                              \
  if (archive_entry_ ## name ## _is_set(e)) {                     \
    int64_t seconds = archive_entry_ ## name(e);                  \
    int64_t nanoseconds = archive_entry_ ## name ## _nsec(e);     \
    name.type = kInt64;                                           \
    name.value.as_int64 = seconds * 1000 + nanoseconds / 1000000; \
  } else {                                                        \
    name.type = kNull;                                            \
  }

#define RAW_ARCHIVE_SIZE 29

void postArchiveEntryArray(Dart_Port p, struct archive_entry* e) {
  if (checkPointerError(p, e, "archive entry")) return;

  Dart_CObject* archive_entry_array[RAW_ARCHIVE_SIZE];

  DART_INT64(id, (intptr_t) e);
  archive_entry_array[0] = &id;

  // archive_entry_paths(3)
  DART_STRING(hardlink, (char*) archive_entry_hardlink(e));
  archive_entry_array[1] = &hardlink;
  DART_STRING(pathname, (char*) archive_entry_pathname(e));
  archive_entry_array[2] = &pathname;
  DART_STRING(sourcepath, (char*) archive_entry_sourcepath(e));
  archive_entry_array[3] = &sourcepath;
  DART_STRING(symlink, (char*) archive_entry_symlink(e));
  archive_entry_array[4] = &symlink;

  // archive_entry_perms(3)
  DART_INT32(gid, archive_entry_gid(e));
  archive_entry_array[5] = &gid;
  DART_INT32(uid, archive_entry_uid(e));
  archive_entry_array[6] = &uid;
  DART_INT32(perm, archive_entry_perm(e));
  archive_entry_array[7] = &perm;
  DART_STRING(strmode, (char*) archive_entry_strmode(e));
  archive_entry_array[8] = &strmode;
  DART_STRING(gname, (char*) archive_entry_gname(e));
  archive_entry_array[9] = &gname;
  DART_STRING(uname, (char*) archive_entry_uname(e));
  archive_entry_array[10] = &uname;

  unsigned long fflags_set;
  unsigned long fflags_clear;
  archive_entry_fflags(e, &fflags_set, &fflags_clear);
  DART_INT64(wrapped_fflags_set, fflags_set);
  archive_entry_array[11] = &wrapped_fflags_set;
  DART_INT64(wrapped_fflags_clear, fflags_clear);
  archive_entry_array[12] = &wrapped_fflags_clear;

  DART_STRING(fflags_text, (char*) archive_entry_fflags_text(e));
  archive_entry_array[13] = &fflags_text;

  // archive_entry_stat(3)
  DART_INT32(filetype, archive_entry_filetype(e));
  archive_entry_array[14] = &filetype;
  DART_INT32(mode, archive_entry_mode(e));
  archive_entry_array[15] = &mode;

  Dart_CObject size;
  if (archive_entry_size_is_set(e)) {
    size.type = kInt64;
    size.value.as_int64 = archive_entry_size(e);
  } else {
    size.type = kNull;
  }
  archive_entry_array[16] = &size;

  Dart_CObject dev;
  if (archive_entry_dev_is_set(e)) {
    dev.type = kInt64;
    dev.value.as_int64 = archive_entry_dev(e);
  } else {
    dev.type = kNull;
  }
  archive_entry_array[17] = &dev;

  DART_INT64(devmajor, archive_entry_devmajor(e));
  archive_entry_array[18] = &devmajor;
  DART_INT64(devminor, archive_entry_devminor(e));
  archive_entry_array[19] = &devminor;

  Dart_CObject ino;
  if (archive_entry_ino_is_set(e)) {
    ino.type = kInt64;
    ino.value.as_int64 = archive_entry_ino64(e);
  } else {
    ino.type = kNull;
  }
  archive_entry_array[20] = &ino;

  DART_INT64(nlink, archive_entry_nlink(e));
  archive_entry_array[21] = &nlink;
  DART_INT64(rdev, archive_entry_rdev(e));
  archive_entry_array[22] = &rdev;
  DART_INT64(rdevmajor, archive_entry_rdevmajor(e));
  archive_entry_array[23] = &rdevmajor;
  DART_INT64(rdevminor, archive_entry_rdevminor(e));
  archive_entry_array[24] = &rdevminor;

  // archive_entry_time(3)
  DART_TIMESTAMP(atime);
  archive_entry_array[25] = &atime;
  DART_TIMESTAMP(birthtime);
  archive_entry_array[26] = &birthtime;
  DART_TIMESTAMP(ctime);
  archive_entry_array[27] = &ctime;
  DART_TIMESTAMP(mtime);
  archive_entry_array[28] = &mtime;
  // If you add entries, don't forget to increase RAW_ARCHIVE_SIZE.

  Dart_CObject wrapped_archive_entry;
  wrapped_archive_entry.type = kArray;
  wrapped_archive_entry.value.as_array.values = archive_entry_array;
  wrapped_archive_entry.value.as_array.length = RAW_ARCHIVE_SIZE;

  postSuccess(p, &wrapped_archive_entry);
}

void archiveEntryClone(Dart_Port p, struct archive_entry* e) {
  postArchiveEntryArray(p, archive_entry_clone(e));
}

void archiveEntryFree(Dart_Port p, struct archive_entry* e) {
  archive_entry_free(e);
  postSuccess(p, NULL);
}

void archiveEntryNew(Dart_Port p) {
  postArchiveEntryArray(p, archive_entry_new());
}

void archiveEntrySetHardlink(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_hardlink(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetPathname(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_pathname(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetSourcepath(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_sourcepath(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetSymlink(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_symlink(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetGid(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_gid(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetUid(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_uid(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetPerm(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_perm_mask(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetGname(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_update_gname_utf8(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetUname(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_update_uname_utf8(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetFflagsSet(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_fflags(e, getInteger(value), 0);
  postSuccess(p, NULL);
}

void archiveEntrySetFflagsClear(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_fflags(e, 0, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetFflagsText(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getNullableStringArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_fflags_text(e, getNullableString(value));
  postSuccess(p, NULL);
}

void archiveEntrySetFiletype(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_filetype(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetMode(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_mode(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetSize(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  if (request->type == kNull) {
    archive_entry_unset_size(e);
    postSuccess(p, NULL);
    return;
  }

  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_size(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetDev(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_dev(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetDevmajor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_devmajor(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetDevminor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_devminor(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetIno(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_ino64(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetNlink(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_nlink(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetRdev(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_rdev(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetRdevmajor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_rdevmajor(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetRdevminor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  archive_entry_set_rdevminor(e, getInteger(value));
  postSuccess(p, NULL);
}

void archiveEntrySetAtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  if (request->type == kNull) {
    archive_entry_unset_atime(e);
    postSuccess(p, NULL);
    return;
  }

  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  int64_t atime = getInteger(value);
  archive_entry_set_atime(e, atime / 1000, (atime % 1000) * 1000000);
  postSuccess(p, NULL);
}

void archiveEntrySetBirthtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  if (request->type == kNull) {
    archive_entry_unset_birthtime(e);
    postSuccess(p, NULL);
    return;
  }

  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  int64_t birthtime = getInteger(value);
  archive_entry_set_birthtime(
      e, birthtime / 1000, (birthtime % 1000) * 1000000);
  postSuccess(p, NULL);
}

void archiveEntrySetCtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  if (request->type == kNull) {
    archive_entry_unset_ctime(e);
    postSuccess(p, NULL);
    return;
  }

  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  int64_t ctime = getInteger(value);
  archive_entry_set_ctime(e, ctime / 1000, (ctime % 1000) * 1000000);
  postSuccess(p, NULL);
}

void archiveEntrySetMtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request) {
  if (request->type == kNull) {
    archive_entry_unset_mtime(e);
    postSuccess(p, NULL);
    return;
  }

  Dart_CObject* value = getIntArgument(p, request, 0);
  if (value == NULL) return;
  int64_t mtime = getInteger(value);
  archive_entry_set_mtime(e, mtime / 1000, (mtime % 1000) * 1000000);
  postSuccess(p, NULL);
}
