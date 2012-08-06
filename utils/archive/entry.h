// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file declares request-handling functions for handling archive entries.
 * Each function is called when a message is received with the corresponding
 * request type, and posts a success or error response to the reply port.
 *
 * There is a close correspondence between most functions here and the
 * libarchive API. It's left up to the Dart code to present a more Darty API. As
 * such, documentation of these functions is omitted, since it's available in
 * the libarchive documentation.
 */
#ifndef DART_ARCHIVE_ENTRY_H_
#define DART_ARCHIVE_ENTRY_H_

#include "dart_archive.h"

/**
 * Posts a response containing all the data in archive entry [e]. If [e] is
 * `NULL`, posts an error response instead.
 */
void postArchiveEntryArray(Dart_Port p, struct archive_entry* e);

void archiveEntryClone(Dart_Port p, struct archive_entry* e);

void archiveEntryFree(Dart_Port p, struct archive_entry* e);

void archiveEntryNew(Dart_Port p);

void archiveEntrySetHardlink(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetPathname(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetSourcepath(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetSymlink(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetGid(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetUid(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetPerm(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetGname(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetUname(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetFflagsSet(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetFflagsClear(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetFflagsText(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetFiletype(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetMode(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetSize(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetDev(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetDevmajor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetDevminor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetIno(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetNlink(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetRdev(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetRdevmajor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetRdevminor(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetAtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetBirthtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetCtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

void archiveEntrySetMtime(Dart_Port p, struct archive_entry* e,
    Dart_CObject* request);

#endif  // DART_ARCHIVE_MESSAGING_H_

