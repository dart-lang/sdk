#!/usr/bin/env python
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
from ctypes import create_string_buffer
from struct import *

# FILE HEADER FLAGS
FILE_HEADER_RELFLG = 0x1  # No relocation information
FILE_HEADER_EXEC = 0x2  # Executable
FILE_HEADER_LNNO = 0x4  # No line number information
FILE_HEADER_LSYMS = 0x8  # Local symbols removed / not present
FILE_HEADER_AR32WR = 0x100  # File is 32-bit little endian

# SECTION HEADER FLAGS
SECTION_HEADER_TEXT = 0x20  # Contains executable code
SECTION_HEADER_DATA = 0x40  # Contains only initialized data
SECTION_HEADER_BSS = 0x80  # Contains uninitialized data

# FILE HEADER FORMAT
# typedef struct {
#   unsigned short f_magic;         /* magic number             */
#   unsigned short f_nscns;         /* number of sections       */
#   unsigned long  f_timdat;        /* time & date stamp        */
#   unsigned long  f_symptr;        /* file pointer to symtab   */
#   unsigned long  f_nsyms;         /* number of symtab entries */
#   unsigned short f_opthdr;        /* sizeof(optional hdr)     */
#   unsigned short f_flags;         /* flags                    */
# } FILHDR;
FILE_HEADER_FORMAT = 'HHIIIHH'
FILE_HEADER_SIZE = calcsize(FILE_HEADER_FORMAT)
FILE_HEADER_MAGIC_X64 = 0x8664
FILE_HEADER_MAGIC_IA32 = 0x014c
FILE_HEADER_NUM_SECTIONS = 1
FILE_HEADER_TIMESTAMP = 0
FILE_HEADER_SIZE_OF_OPTIONAL = 0
FILE_HEADER_FLAGS = FILE_HEADER_LNNO

# SECTION HEADER FORMAT
# typedef struct {
#   char           s_name[8];  /* section name                     */
#   unsigned long  s_paddr;    /* physical address, aliased s_nlib */
#   unsigned long  s_vaddr;    /* virtual address                  */
#   unsigned long  s_size;     /* section size                     */
#   unsigned long  s_scnptr;   /* file ptr to raw data for section */
#   unsigned long  s_relptr;   /* file ptr to relocation           */
#   unsigned long  s_lnnoptr;  /* file ptr to line numbers         */
#   unsigned short s_nreloc;   /* number of relocation entries     */
#   unsigned short s_nlnno;    /* number of line number entries    */
#   unsigned long  s_flags;    /* flags                            */
# } SCNHDR;
SECTION_HEADER_FORMAT = '8sIIIIIIHHI'
SECTION_HEADER_SIZE = calcsize(SECTION_HEADER_FORMAT)
SECTION_NAME_RODATA = '.rodata'
SECTION_NAME_TEXT = '.text'
SECTION_PADDR = 0x0
SECTION_VADDR = 0x0
SECTION_RAW_DATA_PTR = (
    FILE_HEADER_SIZE + FILE_HEADER_NUM_SECTIONS * SECTION_HEADER_SIZE)
SECTION_RELOCATION_PTR = 0x0
SECTION_LINE_NUMS_PTR = 0x0
SECTION_NUM_RELOCATION = 0
SECTION_NUM_LINE_NUMS = 0

# SYMBOL TABLE FORMAT
# typedef struct {
#   union {
#     char e_name[8];
#     struct {
#       unsigned long e_zeroes;
#       unsigned long e_offset;
#     } e;
#   } e;
#   unsigned long e_value;
#   short e_scnum;
#   unsigned short e_type;
#   unsigned char e_sclass;
#   unsigned char e_numaux;
# } SYMENT;
SYMBOL_TABLE_ENTRY_SHORT_LEN = 8
SYMBOL_TABLE_ENTRY_FORMAT_SHORT = '8sIhHBB'
SYMBOL_TABLE_ENTRY_FORMAT_LONG = 'IIIhHBB'
SYMBOL_TABLE_ENTRY_SIZE = calcsize(SYMBOL_TABLE_ENTRY_FORMAT_SHORT)
SYMBOL_TABLE_ENTRY_ZEROS = 0x0
SYMBOL_TABLE_ENTRY_SECTION = 1
SYMBOL_TABLE_ENTRY_TYPE = 0
SYMBOL_TABLE_ENTRY_CLASS = 2  # External (public) symbol.
SYMBOL_TABLE_ENTRY_NUM_AUX = 0  # Number of auxiliary entries.

STRING_TABLE_OFFSET = 0x4  # Starting offset for the string table.
SIZE_FORMAT = 'I'
SIZE_LENGTH = calcsize(SIZE_FORMAT)

SIZE_SYMBOL_FORMAT_X64 = 'Q'
SIZE_SYMBOL_LENGTH_X64 = calcsize(SIZE_SYMBOL_FORMAT_X64)


def main():
    parser = argparse.ArgumentParser(
        description='Generate a COFF file for binary data.')
    parser.add_argument('--input', dest='input', help='Path of the input file.')
    parser.add_argument(
        '--output', dest='output', help='Name of the output file.')
    parser.add_argument(
        '--symbol_name',
        dest='symbol_name',
        help='Name of the symbol for the binary data')
    parser.add_argument(
        '--size_symbol_name',
        dest='size_name',
        help='Name of the symbol for the size of the binary data')
    parser.add_argument(
        '--64-bit', dest='use_64_bit', action='store_true', default=False)
    parser.add_argument(
        '--executable', dest='executable', action='store_true', default=False)

    args = parser.parse_args()

    with open(args.input, 'rb') as f:
        section_data = f.read()

    # We need to calculate the following to determine the size of our buffer:
    #   1) Size of the data
    #   2) Total length of the symbol strings which are over 8 characters

    section_size = len(section_data)
    includes_size_name = (args.size_name != None)

    # Symbols on x86 are prefixed with '_'
    symbol_prefix = '' if args.use_64_bit else '_'
    num_symbols = 2 if includes_size_name else 1
    symbol_name = symbol_prefix + args.symbol_name
    size_symbol_name = None
    if (includes_size_name):
        size_symbol = args.size_name if args.size_name else args.symbol_name + "Size"
        size_symbol_name = symbol_prefix + size_symbol

    size_symbol_format = SIZE_SYMBOL_FORMAT_X64 if args.use_64_bit else SIZE_FORMAT
    size_symbol_size = SIZE_SYMBOL_LENGTH_X64 if args.use_64_bit else SIZE_LENGTH

    # The symbol table is directly after the data section
    symbol_table_ptr = (FILE_HEADER_SIZE + SECTION_HEADER_SIZE + section_size +
                        size_symbol_size)
    string_table_len = 0

    # Symbols longer than 8 characters have their string representations stored
    # in the string table.
    long_symbol_name = False
    long_size_symbol_name = False
    if (len(symbol_name) > SYMBOL_TABLE_ENTRY_SHORT_LEN):
        string_table_len += len(symbol_name) + 1
        long_symbol_name = True

    if (includes_size_name and
        (len(size_symbol_name) > SYMBOL_TABLE_ENTRY_SHORT_LEN)):
        string_table_len += len(size_symbol_name) + 1
        long_size_symbol_name = True

    # Create the buffer and start building.
    offset = 0
    buff = create_string_buffer(
        FILE_HEADER_SIZE + SECTION_HEADER_SIZE + section_size +
        num_symbols * SYMBOL_TABLE_ENTRY_SIZE + SIZE_LENGTH + size_symbol_size +
        string_table_len)

    FILE_HEADER_MAGIC = FILE_HEADER_MAGIC_X64 if args.use_64_bit else FILE_HEADER_MAGIC_IA32

    # Populate the file header. Basically constant except for the pointer to the
    # beginning of the symbol table.
    pack_into(FILE_HEADER_FORMAT, buff, offset, FILE_HEADER_MAGIC,
              FILE_HEADER_NUM_SECTIONS, FILE_HEADER_TIMESTAMP, symbol_table_ptr,
              num_symbols, FILE_HEADER_SIZE_OF_OPTIONAL, FILE_HEADER_FLAGS)
    offset += FILE_HEADER_SIZE

    section_name = SECTION_NAME_RODATA
    section_type = SECTION_HEADER_DATA
    if args.executable:
        section_name = SECTION_NAME_TEXT
        section_type = SECTION_HEADER_TEXT

    # Populate the section header for a single section.
    pack_into(SECTION_HEADER_FORMAT, buff, offset, section_name, SECTION_PADDR,
              SECTION_VADDR, section_size + size_symbol_size,
              SECTION_RAW_DATA_PTR, SECTION_RELOCATION_PTR,
              SECTION_LINE_NUMS_PTR, SECTION_NUM_RELOCATION,
              SECTION_NUM_LINE_NUMS, section_type)
    offset += SECTION_HEADER_SIZE

    # Copy the binary data.
    buff[offset:offset + section_size] = section_data
    offset += section_size

    # Append the size of the section.
    pack_into(size_symbol_format, buff, offset, section_size)
    offset += size_symbol_size

    # Build the symbol table. If a symbol name is 8 characters or less, it's
    # placed directly in the symbol table. If not, it's entered in the string
    # table immediately after the symbol table.

    string_table_offset = STRING_TABLE_OFFSET
    if long_symbol_name:
        pack_into(SYMBOL_TABLE_ENTRY_FORMAT_LONG, buff, offset,
                  SYMBOL_TABLE_ENTRY_ZEROS, string_table_offset, 0x0,
                  SYMBOL_TABLE_ENTRY_SECTION, SYMBOL_TABLE_ENTRY_TYPE,
                  SYMBOL_TABLE_ENTRY_CLASS, SYMBOL_TABLE_ENTRY_NUM_AUX)
        string_table_offset += len(symbol_name) + 1
    else:
        pack_into(SYMBOL_TABLE_ENTRY_FORMAT_SHORT, buff, offset, symbol_name,
                  0x0, SYMBOL_TABLE_ENTRY_SECTION, SYMBOL_TABLE_ENTRY_TYPE,
                  SYMBOL_TABLE_ENTRY_CLASS, SYMBOL_TABLE_ENTRY_NUM_AUX)
    offset += SYMBOL_TABLE_ENTRY_SIZE

    if includes_size_name:
        # The size symbol table entry actually contains the value for the size.
        if long_size_symbol_name:
            pack_into(SYMBOL_TABLE_ENTRY_FORMAT_LONG, buff, offset,
                      SYMBOL_TABLE_ENTRY_ZEROS, string_table_offset,
                      section_size, SYMBOL_TABLE_ENTRY_SECTION,
                      SYMBOL_TABLE_ENTRY_TYPE, SYMBOL_TABLE_ENTRY_CLASS,
                      SYMBOL_TABLE_ENTRY_NUM_AUX)
        else:
            pack_into(SYMBOL_TABLE_ENTRY_FORMAT_SHORT, buff, offset,
                      symbol_name, section_size, SYMBOL_TABLE_ENTRY_SECTION,
                      SYMBOL_TABLE_ENTRY_TYPE, SYMBOL_TABLE_ENTRY_CLASS,
                      SYMBOL_TABLE_ENTRY_NUM_AUX)
        offset += SYMBOL_TABLE_ENTRY_SIZE

    pack_into(SIZE_FORMAT, buff, offset, string_table_len + SIZE_LENGTH)
    offset += SIZE_LENGTH

    # Populate the string table for any symbols longer than 8 characters.
    if long_symbol_name:
        symbol_len = len(symbol_name)
        buff[offset:offset + symbol_len] = symbol_name
        offset += symbol_len
        buff[offset] = '\0'
        offset += 1

    if includes_size_name and long_size_symbol_name:
        symbol_len = len(size_symbol_name)
        buff[offset:offset + symbol_len] = size_symbol_name
        offset += symbol_len
        buff[offset] = '\0'
        offset += 1

    with open(args.output, 'wb') as f:
        f.write(buff.raw)


if __name__ == '__main__':
    main()
