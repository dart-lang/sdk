# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libevent',
      'type': 'none',
      'toolsets': ['host', 'target'],
      'variables': {
        'headers_root_path': '.',
        'header_filenames': [
          'event.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'link_settings': {
        'libraries': [
          '-levent',
        ],
      },
    }
  ],
}
