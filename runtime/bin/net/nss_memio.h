// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Written in NSPR style to also be suitable for adding to the NSS demo suite

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is a modified copy of Chromium's src/net/base/nss_memio.h.
// char* has been changed to uint8_t* everywhere, and C++ casts are used.
// Revision 291806 (this should agree with "nss_rev" in DEPS).

#ifndef BIN_NET_NSS_MEMIO_H_
#define BIN_NET_NSS_MEMIO_H_

#include <stddef.h>
#include "vm/globals.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "prio.h"

/* Opaque structure.  Really just a more typesafe alias for PRFilePrivate. */
struct memio_Private;
typedef struct memio_Private memio_Private;

/*----------------------------------------------------------------------
 NSPR I/O layer that terminates in a pair of circular buffers
 rather than talking to the real network.
 To use this with NSS:
 1) call memio_CreateIOLayer to create a fake NSPR socket
 2) call SSL_ImportFD to ssl-ify the socket
 3) Do your own networking calls to set up a TCP connection
 4) call memio_SetPeerName to tell NSS about the other end of the connection
 5) While at the same time doing plaintext nonblocking NSPR I/O as
    usual to the nspr file descriptor returned by SSL_ImportFD,
    your app must shuttle encrypted data between
    the real network and memio's network buffers.
    memio_GetReadParams/memio_PutReadResult
    are the hooks you need to pump data into memio's input buffer,
    and memio_GetWriteParams/memio_PutWriteResult
    are the hooks you need to pump data out of memio's output buffer.
----------------------------------------------------------------------*/

/* Create the I/O layer and its two circular buffers. */
PRFileDesc *memio_CreateIOLayer(int readbufsize, int writebufsize);

/* Must call before trying to make an ssl connection */
void memio_SetPeerName(PRFileDesc *fd, const PRNetAddr *peername);

/* Return a private pointer needed by the following
 * four functions.  (We could have passed a PRFileDesc to
 * them, but that would be slower.  Better for the caller
 * to grab the pointer once and cache it.
 * This may be a premature optimization.)
 */
memio_Private *memio_GetSecret(PRFileDesc *fd);

/* Ask memio how many bytes were requested by a higher layer if the
 * last attempt to read data resulted in PR_WOULD_BLOCK_ERROR, due to the
 * transport buffer being empty. If the last attempt to read data from the
 * memio did not result in PR_WOULD_BLOCK_ERROR, returns 0.
 */
int memio_GetReadRequest(memio_Private *secret);

/* Ask memio where to put bytes from the network, and how many it can handle.
 * Returns bytes available to write, or 0 if none available.
 * Puts current buffer position into *buf.
 */
int memio_GetReadParams(memio_Private *secret, uint8_t **buf);

/* Ask memio how many bytes are contained in the internal buffer.
 * Returns bytes available to read, or 0 if none available.
 */
int memio_GetReadableBufferSize(memio_Private *secret);

/* Tell memio how many bytes were read from the network.
 * If bytes_read is 0, causes EOF to be reported to
 * NSS after it reads the last byte from the circular buffer.
 * If bytes_read is < 0, it is treated as an NSPR error code.
 * See nspr/pr/src/md/unix/unix_errors.c for how to
 * map from Unix errors to NSPR error codes.
 * On EWOULDBLOCK or the equivalent, don't call this function.
 */
void memio_PutReadResult(memio_Private *secret, int bytes_read);

/* Ask memio what data it has to send to the network.
 * If there was previous a write error, the NSPR error code is returned.
 * Otherwise, it returns 0 and provides up to two buffers of data by
 * writing the positions and lengths into |buf1|, |len1| and |buf2|, |len2|.
 */
int memio_GetWriteParams(memio_Private *secret,
                         const uint8_t **buf1, unsigned int *len1,
                         const uint8_t **buf2, unsigned int *len2);

/* Tell memio how many bytes were sent to the network.
 * If bytes_written is < 0, it is treated as an NSPR error code.
 * See nspr/pr/src/md/unix/unix_errors.c for how to
 * map from Unix errors to NSPR error codes.
 * On EWOULDBLOCK or the equivalent, don't call this function.
 */
void memio_PutWriteResult(memio_Private *secret, int bytes_written);

#ifdef __cplusplus
}
#endif

#endif  // BIN_NET_NSS_MEMIO_H_
