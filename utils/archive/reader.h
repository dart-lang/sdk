// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file declares request-handling functions for reading archives. Each
 * function is called when a message is received with the corresponding request
 * type, and posts a success or error response to the reply port.
 *
 * There is a close correspondence between functions here and the libarchive
 * API. It's left up to the Dart code to present a more Darty API. As such,
 * documentation of these functions is omitted, since it's available in the
 * libarchive documentation.
 */
#ifndef DART_ARCHIVE_READER_H_
#define DART_ARCHIVE_READER_H_

#include "dart_archive.h"

void archiveReadNew(Dart_Port p);

void archiveReadSupportFilterAll(Dart_Port p, struct archive* a);

void archiveReadSupportFilterBzip2(Dart_Port p, struct archive* a);

void archiveReadSupportFilterCompress(Dart_Port p, struct archive* a);

void archiveReadSupportFilterGzip(Dart_Port p, struct archive* a);

void archiveReadSupportFilterLzma(Dart_Port p, struct archive* a);

void archiveReadSupportFilterXz(Dart_Port p, struct archive* a);

void archiveReadSupportFilterProgram(Dart_Port p, struct archive* a,
                                     Dart_CObject* request);

void archiveReadSupportFilterProgramSignature(
    Dart_Port p, struct archive* a, Dart_CObject* request);

void archiveReadSupportFormatAll(Dart_Port p, struct archive* a);

void archiveReadSupportFormatAr(Dart_Port p, struct archive* a);

void archiveReadSupportFormatCpio(Dart_Port p, struct archive* a);

void archiveReadSupportFormatEmpty(Dart_Port p, struct archive* a);

void archiveReadSupportFormatIso9660(Dart_Port p, struct archive* a);

void archiveReadSupportFormatMtree(Dart_Port p, struct archive* a);

void archiveReadSupportFormatRaw(Dart_Port p, struct archive* a);

void archiveReadSupportFormatTar(Dart_Port p, struct archive* a);

void archiveReadSupportFormatZip(Dart_Port p, struct archive* a);

void archiveReadSetFilterOption(Dart_Port p, struct archive* a,
                                Dart_CObject* request);

void archiveReadSetFormatOption(Dart_Port p, struct archive* a,
                                Dart_CObject* request);

void archiveReadSetOption(Dart_Port p, struct archive* a,
                          Dart_CObject* request);

void archiveReadOpenFilename(Dart_Port p, struct archive* a,
                             Dart_CObject* request);

void archiveReadOpenMemory(Dart_Port p, struct archive* a,
                           Dart_CObject* request);

void archiveReadNextHeader(Dart_Port p, struct archive* a);

void archiveReadDataBlock(Dart_Port p, struct archive* a);

void archiveReadDataSkip(Dart_Port p, struct archive* a);

void archiveReadClose(Dart_Port p, struct archive* a);

void archiveReadFree(Dart_Port p, struct archive* a);

#endif  // DART_ARCHIVE_READER_H_
