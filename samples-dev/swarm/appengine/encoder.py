# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
'''
This Encoder shares a lot in common with protobufs.  It uses variable length
ints and size-encoded strings and binary values.  Other than being hugely
stripped down, the major conceptual difference is that this encoding
is UTF8 "safe".  This means that it generates a form that should be passed
on the wire as UTF8 and then can be very efficiently decoded by JS in the
browser which natively handles these kinds of strings.  To stay efficient in
this range, all numeric data is encoded in only 7 bits.
'''

import base64


class Encoder:

    def __init__(self):
        self.data = []

    def writeInt(self, value):
        '''Uses a 7-bit per byte encoding to stay UTF-8 "safe".'''
        bits = value & 0x3f
        value >>= 6
        while value:
            self.data.append(chr(0x40 | bits))
            bits = value & 0x3f
            value >>= 6
        self.data.append(chr(bits))

    def writeBool(self, b):
        self.data.append(('F', 'T')[b])

    def writeString(self, s):
        if not s: s = ''
        self.writeInt(len(s))
        self.data.append(s)

    def writeBinary(self, s):
        '''Encode binary data using base64.  This is less efficient than a 7-bit
    encoding would be; however, it can be decoded much faster on most
    browsers due to native support for the format.'''
        v = base64.b64encode(s)
        self.writeInt(len(v))
        self.data.append(v)

    def writeList(self, l):
        self.writeInt(len(l))
        for i in l:
            i.encode(self)

    def writeRaw(self, s):
        self.data.append(s)

    def finish(self):
        d = ''.join(self.data)
        return _encVarInt(len(d)) + d

    def getRaw(self):
        return ''.join(self.data)
