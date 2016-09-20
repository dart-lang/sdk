# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'dynamic_annotations',
      'type': 'static_library',
      'toolsets': ['host', 'target'],
      'include_dirs': [
        'include',
        'gperftools/src/base',
        'gperftools/src',
      ],
      'cflags!': [
        '-Werror',
        '-Wnon-virtual-dtor',
        '-Woverloaded-virtual',
        '-fno-rtti',
      ],
      'sources': [
        'gperftools/src/base/dynamic_annotations.c',
        'gperftools/src/base/dynamic_annotations.h',
      ],
    },
    {
      'target_name': 'tcmalloc',
      'type': 'static_library',
      'toolsets': ['host', 'target'],
      'dependencies': [
        'dynamic_annotations',
      ],
      'include_dirs': [
        'include',
        'gperftools/src/base',
        'gperftools/src',
      ],
      'includes': [
        'tcmalloc_sources.gypi',
      ],
      # Disable the heap checker in tcmalloc.
      'defines': [
        'ENABLE_EMERGENCY_MALLOC',
        'NO_HEAP_CHECK',
        # Disable debug even in a Dart Debug build. It is too slow.
        'NDEBUG',
      ],
      'defines!': [
        # Disable debug even in a Dart Debug build. It is too slow.
        'DEBUG',
      ],
      'cflags': [
        '-Wno-missing-field-initializers',
        '-Wno-sign-compare',
        '-Wno-type-limits',
        '-Wno-unused-result',
        '-Wno-vla',
        '-fno-builtin-malloc',
        '-fno-builtin-free',
        '-fno-builtin-realloc',
        '-fno-builtin-calloc',
        '-fno-builtin-cfree',
        '-fno-builtin-memalign',
        '-fno-builtin-posix_memalign',
        '-fno-builtin-valloc',
        '-fno-builtin-pvalloc',
        '-fpermissive',
      ],
      'cflags!': [
        '-Werror',
        '-Wvla',
      ],
      'link_settings': {
        'configurations': {
          'Dart_Linux_Base': {
            'ldflags': [
              # Don't let linker rip this symbol out, otherwise the heap&cpu
              # profilers will not initialize properly on startup.
              '-Wl,-uIsHeapProfilerRunning,-uProfilerStart',
            ],
          },
        },
      },
      'sources!': [
        # No debug allocator.
        'gperftools/src/debugallocation.cc',
        # Not needed when using emergency malloc.
        'gperftools/src/fake_stacktrace_scope.cc',
        # Not using the cpuprofiler
        'gperftools/src/base/thread_lister.c',
        'gperftools/src/base/thread_lister.h',
        'gperftools/src/profile-handler.cc',
        'gperftools/src/profile-handler.h',
        'gperftools/src/profiledata.cc',
        'gperftools/src/profiledata.h',
        'gperftools/src/profiler.cc',
      ],
      # Disable sample collection in Release and Product builds.
      'configurations': {
        'Dart_Product': {
          'defines': [
            'NO_TCMALLOC_SAMPLES',
          ],
        },
      },
    },
  ],
}
