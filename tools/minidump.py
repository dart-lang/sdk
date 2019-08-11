# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains a set of utilities for parsing minidumps.

import ctypes
import mmap
import os
import sys


class Enum(object):

    def __init__(self, type, name2value):
        self.name2value = name2value
        self.value2name = {v: k for k, v in name2value.iteritems()}
        self.type = type

    def from_raw(self, v):
        if v not in self.value2name:
            return 'Unknown(' + str(v) + ')'
        return self.value2name[v]

    def to_raw(self, v):
        return self.name2value[v]


class Descriptor(object):
    """A handy wrapper over ctypes.Structure"""

    def __init__(self, fields):
        self.fields = fields
        self.ctype = Descriptor._GetCtype(fields)
        self.size = ctypes.sizeof(self.ctype)

    def Read(self, address):
        return self.ctype.from_address(address)

    @staticmethod
    def _GetCtype(fields):
        raw_fields = []
        wrappers = {}
        for field in fields:
            (name, type) = field
            if isinstance(type, Enum):
                raw_fields.append(('_raw_' + name, type.type))
                wrappers[name] = type
            else:
                raw_fields.append(field)

        class Raw(ctypes.Structure):
            _fields_ = raw_fields
            _pack_ = 1

            def __getattribute__(self, name):
                if name in wrappers:
                    return wrappers[name].from_raw(
                        getattr(self, '_raw_' + name))
                else:
                    return ctypes.Structure.__getattribute__(self, name)

            def __repr__(self):
                return '{' + ', '.join(
                    '%s: %s' % (field, self.__getattribute__(field))
                    for field, _ in fields) + '}'

        return Raw


# Structures below are based on the information in the MSDN pages and
# Breakpad/Crashpad sources.

MINIDUMP_HEADER = Descriptor([('signature', ctypes.c_uint32),
                              ('version', ctypes.c_uint32),
                              ('stream_count', ctypes.c_uint32),
                              ('stream_directories_rva', ctypes.c_uint32),
                              ('checksum', ctypes.c_uint32),
                              ('time_date_stampt', ctypes.c_uint32),
                              ('flags', ctypes.c_uint64)])

MINIDUMP_LOCATION_DESCRIPTOR = Descriptor([('data_size', ctypes.c_uint32),
                                           ('rva', ctypes.c_uint32)])

MINIDUMP_STREAM_TYPE = {
    'MD_UNUSED_STREAM': 0,
    'MD_RESERVED_STREAM_0': 1,
    'MD_RESERVED_STREAM_1': 2,
    'MD_THREAD_LIST_STREAM': 3,
    'MD_MODULE_LIST_STREAM': 4,
    'MD_MEMORY_LIST_STREAM': 5,
    'MD_EXCEPTION_STREAM': 6,
    'MD_SYSTEM_INFO_STREAM': 7,
    'MD_THREAD_EX_LIST_STREAM': 8,
    'MD_MEMORY_64_LIST_STREAM': 9,
    'MD_COMMENT_STREAM_A': 10,
    'MD_COMMENT_STREAM_W': 11,
    'MD_HANDLE_DATA_STREAM': 12,
    'MD_FUNCTION_TABLE_STREAM': 13,
    'MD_UNLOADED_MODULE_LIST_STREAM': 14,
    'MD_MISC_INFO_STREAM': 15,
    'MD_MEMORY_INFO_LIST_STREAM': 16,
    'MD_THREAD_INFO_LIST_STREAM': 17,
    'MD_HANDLE_OPERATION_LIST_STREAM': 18,
}

MINIDUMP_DIRECTORY = Descriptor([('stream_type',
                                  Enum(ctypes.c_uint32, MINIDUMP_STREAM_TYPE)),
                                 ('location',
                                  MINIDUMP_LOCATION_DESCRIPTOR.ctype)])

MINIDUMP_MISC_INFO_2 = Descriptor([
    ('SizeOfInfo', ctypes.c_uint32),
    ('Flags1', ctypes.c_uint32),
    ('ProcessId', ctypes.c_uint32),
    ('ProcessCreateTime', ctypes.c_uint32),
    ('ProcessUserTime', ctypes.c_uint32),
    ('ProcessKernelTime', ctypes.c_uint32),
    ('ProcessorMaxMhz', ctypes.c_uint32),
    ('ProcessorCurrentMhz', ctypes.c_uint32),
    ('ProcessorMhzLimit', ctypes.c_uint32),
    ('ProcessorMaxIdleState', ctypes.c_uint32),
    ('ProcessorCurrentIdleState', ctypes.c_uint32),
])

MINIDUMP_MISC1_PROCESS_ID = 0x00000001


# A helper to get a raw address of the memory mapped buffer returned by
# mmap.
def BufferToAddress(buf):
    obj = ctypes.py_object(buf)
    address = ctypes.c_void_p()
    length = ctypes.c_ssize_t()
    ctypes.pythonapi.PyObject_AsReadBuffer(obj, ctypes.byref(address),
                                           ctypes.byref(length))
    return address.value


class MinidumpFile(object):
    """Class for reading minidump files."""
    _HEADER_MAGIC = 0x504d444d

    def __init__(self, minidump_name):
        self.minidump_name = minidump_name
        self.minidump_file = open(minidump_name, 'r')
        self.minidump = mmap.mmap(
            self.minidump_file.fileno(), 0, access=mmap.ACCESS_READ)
        self.minidump_address = BufferToAddress(self.minidump)
        self.header = self.Read(MINIDUMP_HEADER, 0)
        if self.header.signature != MinidumpFile._HEADER_MAGIC:
            raise Exception('Unsupported minidump header magic')
        self.directories = []
        offset = self.header.stream_directories_rva
        for _ in range(self.header.stream_count):
            self.directories.append(self.Read(MINIDUMP_DIRECTORY, offset))
            offset += MINIDUMP_DIRECTORY.size

    def GetProcessId(self):
        for dir in self.directories:
            if dir.stream_type == 'MD_MISC_INFO_STREAM':
                info = self.Read(MINIDUMP_MISC_INFO_2, dir.location.rva)
                if info.Flags1 & MINIDUMP_MISC1_PROCESS_ID != 0:
                    return info.ProcessId
        return -1

    def Read(self, what, offset):
        return what.Read(self.minidump_address + offset)

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.minidump.close()
        self.minidump_file.close()


# Returns process id of the crashed process recorded in the given minidump.
def GetProcessIdFromDump(path):
    try:
        with MinidumpFile(path) as f:
            return int(f.GetProcessId())
    except:
        return -1
