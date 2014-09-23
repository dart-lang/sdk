# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is a modified copy of Chromium's src/net/third_party/nss/ssl.gyp.
# Revision 291806 (this should agree with "nss_rev" in DEPS).

# The following modification was made to make sure we have the same
# xcode_settings on all configurations (otherwise we can't build with ninja):
#   'configurations': {
#     'Debug_Base': {
# +     'inherit_from': ['Dart_Base'],
#       'defines': [
#         'DEBUG',
#       ],
#    },
#  },

{
  # Conditions section for ssl-bodge (Compiling SSL on linux using system
  # NSS and NSPR libraries) removed:
  # 'conditions': [
  #   [ 'os_posix == 1 and OS != "mac" and OS != "ios"', {
  #   ...
  #   }]],

  # Added by Dart. All Dart comments refer to the following block or line.
  'includes': [
    '../../tools/gyp/runtime-configurations.gypi',
    '../../tools/gyp/nss_configurations.gypi',
  ],
  # Added by Dart.
  'variables': {
    'ssl_directory': '../../../third_party/net_nss',
    'os_posix': 0,
  },
  # Added by Dart.  We do not indent, so diffs with the original are clearer.
  'conditions': [[ 'dart_io_support==1', {
  'targets': [
    {
      'target_name': 'libssl_dart',  # Added by Dart (the _dart postfix)
      'type': 'static_library',
      'toolsets':['host','target'],
      # Changed by Dart: '<(ssl_directory)/' added to all paths.
      'sources': [
        '<(ssl_directory)/ssl/authcert.c',
        '<(ssl_directory)/ssl/cmpcert.c',
        '<(ssl_directory)/ssl/derive.c',
        '<(ssl_directory)/ssl/dtlscon.c',
        '<(ssl_directory)/ssl/os2_err.c',
        '<(ssl_directory)/ssl/os2_err.h',
        '<(ssl_directory)/ssl/preenc.h',
        '<(ssl_directory)/ssl/prelib.c',
        '<(ssl_directory)/ssl/ssl.h',
        '<(ssl_directory)/ssl/ssl3con.c',
        '<(ssl_directory)/ssl/ssl3ecc.c',
        '<(ssl_directory)/ssl/ssl3ext.c',
        '<(ssl_directory)/ssl/ssl3gthr.c',
        '<(ssl_directory)/ssl/ssl3prot.h',
        '<(ssl_directory)/ssl/sslauth.c',
        '<(ssl_directory)/ssl/sslcon.c',
        '<(ssl_directory)/ssl/ssldef.c',
        '<(ssl_directory)/ssl/sslenum.c',
        '<(ssl_directory)/ssl/sslerr.c',
        '<(ssl_directory)/ssl/sslerr.h',
        '<(ssl_directory)/ssl/SSLerrs.h',
        '<(ssl_directory)/ssl/sslerrstrs.c',
        '<(ssl_directory)/ssl/sslgathr.c',
        '<(ssl_directory)/ssl/sslimpl.h',
        '<(ssl_directory)/ssl/sslinfo.c',
        '<(ssl_directory)/ssl/sslinit.c',
        '<(ssl_directory)/ssl/sslmutex.c',
        '<(ssl_directory)/ssl/sslmutex.h',
        '<(ssl_directory)/ssl/sslnonce.c',
        '<(ssl_directory)/ssl/sslplatf.c',
        '<(ssl_directory)/ssl/sslproto.h',
        '<(ssl_directory)/ssl/sslreveal.c',
        '<(ssl_directory)/ssl/sslsecur.c',
        '<(ssl_directory)/ssl/sslsnce.c',
        '<(ssl_directory)/ssl/sslsock.c',
        '<(ssl_directory)/ssl/sslt.h',
        '<(ssl_directory)/ssl/ssltrace.c',
        '<(ssl_directory)/ssl/sslver.c',
        '<(ssl_directory)/ssl/unix_err.c',
        '<(ssl_directory)/ssl/unix_err.h',
        '<(ssl_directory)/ssl/win32err.c',
        '<(ssl_directory)/ssl/win32err.h',
        # Changed by Dart: All files under '<(ssl_directory)/ssl/bodge' removed.
      ],
      # Changed by Dart: '<(ssl_directory)/' added to all paths.
      'sources!': [
        '<(ssl_directory)/ssl/os2_err.c',
        '<(ssl_directory)/ssl/os2_err.h',
      ],
      'defines': [
        'NO_PKCS11_BYPASS',
        'NSS_ENABLE_ECC',
        'USE_UTIL_DIRECTLY',
      ],
      'defines!': [
        'DEBUG',
      ],
      'dependencies': [
        # Changed by Dart.
        'zlib.gyp:zlib_dart',  # Added by Dart (the _dart postfix)
        # Dart: Start of copy of code from 'bodge' conditions section below.
        'nss.gyp:nspr_dart',  # Added by Dart (the _dart postfix)
        'nss.gyp:nss_dart',  # Added by Dart (the _dart postfix)
      ],
      'export_dependent_settings': [
        'nss.gyp:nspr_dart',  # Added by Dart (the _dart postfix)
        'nss.gyp:nss_dart',  # Added by Dart (the _dart postfix)
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '<(ssl_directory)/ssl',
        ],
        'defines': [
          'NSS_PLATFORM_CLIENT_AUTH',
        ],
        # Dart: End of copy of code from bodge conditions section.
      },
      'msvs_disabled_warnings': [4018, 4244, 4267],
      'conditions': [
        ['component == "shared_library"', {
          'conditions': [
            ['OS == "mac" or OS == "ios"', {
              'xcode_settings': {
                'GCC_SYMBOLS_PRIVATE_EXTERN': 'NO',
              },
            }],
            ['OS == "win"', {
              'sources': [
                'ssl/exports_win.def',
              ],
            }],
            ['os_posix == 1 and OS != "mac" and OS != "ios"', {
              'cflags!': ['-fvisibility=hidden'],
            }],
          ],
        }],
        [ 'clang == 1', {
          'cflags': [
            # See http://crbug.com/138571#c8. In short, sslsecur.c picks up the
            # system's cert.h because cert.h isn't in chromium's repo.
            '-Wno-incompatible-pointer-types',

            # There is a broken header guard in /usr/include/nss/secmod.h:
            # https://bugzilla.mozilla.org/show_bug.cgi?id=884072
            '-Wno-header-guard',
          ],
        }],
        [ 'OS == "linux"', {
          'link_settings': {
            'libraries': [
              '-ldl',
            ],
          },
          # Added by Dart.
          'defines': [
            'XP_UNIX',
            'NSS_PLATFORM_CLIENT_AUTH',
            'NSS_USE_STATIC_LIBS',
          ],
        }],
        [ 'OS == "mac" or OS == "ios"', {
          'defines': [
            'XP_UNIX',
            'DARWIN',
            'XP_MACOSX',
          ],
        }],
        [ 'OS == "mac"', {
          'link_settings': {
            'libraries': [
              '$(SDKROOT)/System/Library/Frameworks/Security.framework',
            ],
          },
        }],
        [ 'OS == "win"', {
            'sources!': [
              '<(ssl_directory)/ssl/unix_err.c',
              '<(ssl_directory)/ssl/unix_err.h',
            ],
          },
          {  # else: OS != "win"
            'sources!': [
              '<(ssl_directory)/ssl/win32err.c',
              '<(ssl_directory)/ssl/win32err.h',
            ],
          },
        ],
        # Dart: Conditions sections for ssl/bodge removed.
        #       [ 'os_posix == 1 and OS != "mac" and OS != "ios", {
        #         ...
        #       ],
        #       [ 'OS == "mac" or OS == "ios" or OS == "win"', {
        #         ...
        #       ],
      ],
      'configurations': {
        'Debug_Base': {
          'inherit_from': ['Dart_Base'],
          'defines': [
            'DEBUG',
          ],
        },
      },
    },
  ],
  }]],
}
