# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    '../../runtime/tools/gyp/runtime-configurations.gypi',
    'boringssl_configurations.gypi',
  ],
  'targets': [
    {
      'target_name': 'boringssl',
      'type': '<(component)',
      'toolsets': ['host', 'target'],
      'includes': [
        'boringssl.gypi',
      ],
      'sources': [
        '<@(boringssl_crypto_sources)',
        '<@(boringssl_ssl_sources)',
      ],
      'defines': [
        'BORINGSSL_IMPLEMENTATION',
        'BORINGSSL_NO_STATIC_INITIALIZER',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
      'conditions': [
        ['OS == "mac"', {
          'sources': [
            '<@(boringssl_mac_x86_sources)',
            '<@(boringssl_mac_x86_64_sources)'
          ],
        }],
        ['OS == "linux" or OS == "android"', {
          'sources': [
            '<@(boringssl_linux_x86_64_sources)',
            '<@(boringssl_linux_x86_sources)',
            '<@(boringssl_linux_arm_sources)',
            '<@(boringssl_linux_aarch64_sources)',
          ],
        }],
        ['OS == "win"', {
          'defines': [ 'OPENSSL_NO_ASM', 'WIN32_LEAN_AND_MEAN' ],
        }],
      ],
      'include_dirs': [
        'src/include',
        # This is for arm_arch.h, which is needed by some asm files. Since the
        # asm files are generated and kept in a different directory, they
        # cannot use relative paths to find this file.
        'src/crypto',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'src/include',
        ],
      },
    },
  ],
}
