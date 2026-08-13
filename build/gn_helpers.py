# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Helper functions useful when writing scripts that are run from GN's
exec_script function."""


import sys


class GNException(Exception):
    pass


# Computes ASCII code of an element of encoded Python 2 str / Python 3 bytes.
_Ord = ord if sys.version_info.major < 3 else lambda c: c


def _TranslateToGnChars(s):
    for decoded_ch in s.encode('utf-8'):  # str in Python 2, bytes in Python 3.
        code = _Ord(decoded_ch)  # int
        if code in (34, 36, 92):  # For '"', '$', or '\\'.
            yield '\\' + chr(code)
        elif 32 <= code < 127:
            yield chr(code)
        else:
            yield '$0x%02X' % code


def ToGNString(value, allow_dicts=True):
    """Returns a stringified GN equivalent of a Python value.

  allow_dicts indicates if this function will allow converting dictionaries
  to GN scopes. This is only possible at the top level, you can't nest a
  GN scope in a list, so this should be set to False for recursive calls."""
    if isinstance(value, str) or isinstance(value, unicode):
        if value.find('\n') >= 0:
            raise GNException("Trying to print a string with a newline in it.")
        return '"' + ''.join(_TranslateToGnChars(value)) + '"'

    if isinstance(value, list):
        return '[ %s ]' % ', '.join(ToGNString(v, False) for v in value)

    if isinstance(value, dict):
        if not allow_dicts:
            raise GNException("Attempting to recursively print a dictionary.")
        result = ""
        for key in value:
            if not isinstance(key, str):
                raise GNException("Dictionary key is not a string.")
            result += "%s = %s\n" % (key, ToGNString(value[key], False))
        return result

    if isinstance(value, int):
        return str(value)

    raise GNException("Unsupported type %s (value %s) when printing to GN." %
                      (type(value), value))
