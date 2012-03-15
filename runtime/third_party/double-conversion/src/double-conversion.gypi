# Copyright 2010 Google Inc. All Rights Reserved.

{
  'targets': [
    {
      'target_name': 'libdouble_conversion',
      'type': 'static_library',
      'dependencies': [
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'bignum.cc',
        'bignum.h',
        'bignum-dtoa.cc',
        'bignum-dtoa.h',
        'cached-powers.cc',
        'cached-powers.h',
        'diy-fp.cc',
        'diy-fp.h',
        'double.h',
        'double-conversion.cc',
        'double-conversion.h',
        'fast-dtoa.cc',
        'fast-dtoa.h',
        'fixed-dtoa.cc',
        'fixed-dtoa.h',
        'strtod.cc',
        'strtod.h',
        'utils.h',
      ],
    },
  ],
}
