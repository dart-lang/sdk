# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is a modified copy of Chromium's src/net/third_party/nss/ssl.gyp.
# Revision 165464 (this should agree with "nss_rev" in DEPS).
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
  'conditions': [[ 'in_dartium==0', {
  'targets': [
    {
      'target_name': 'libssl_dart',
      'type': 'static_library',
      # Changed by Dart: '<(ssl_directory)/' added to all paths.
      'sources': [
        '<(ssl_directory)/ssl/authcert.c',
        '<(ssl_directory)/ssl/cmpcert.c',
        '<(ssl_directory)/ssl/derive.c',
        '<(ssl_directory)/ssl/dtls1con.c',
        '<(ssl_directory)/ssl/nsskea.c',
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
      ],
      'sources!': [
        '<(ssl_directory)/ssl/os2_err.c',
        '<(ssl_directory)/ssl/os2_err.h',
      ],
      'defines': [
        'NSS_ENABLE_ECC',
        'NSS_ENABLE_ZLIB',
        'USE_UTIL_DIRECTLY',
      ],
      'defines!': [
        # Regrettably, NSS can't be compiled with NO_NSPR_10_SUPPORT yet.
        'NO_NSPR_10_SUPPORT',
      ],
      'dependencies': [
        'zlib.gyp:zlib_dart',
        # Dart: Start of copy of code from 'bodge' conditions section below.
        'nss.gyp:nspr_dart',
        'nss.gyp:nss_dart',
      ],
      'export_dependent_settings': [
        'nss.gyp:nspr_dart',
        'nss.gyp:nss_dart',
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
      'msvs_disabled_warnings': [4018, 4244],
      'conditions': [
        [ 'clang == 1', {
          'cflags': [
            # See http://crbug.com/138571#c8. In short, sslsecur.c picks up the
            # system's cert.h because cert.h isn't in chromium's repo.
            '-Wno-incompatible-pointer-types',
          ],
        }],
        # Added by Dart.
        [ 'OS == "linux"', {
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
          'defines': [
            'DEBUG',
          ],
        },
      },
    },
  ],
  }]],
}
