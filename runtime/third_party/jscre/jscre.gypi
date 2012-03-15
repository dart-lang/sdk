# Copyright 2010 Google Inc. All Rights Reserved.

{
  'targets': [
    {
      'target_name': 'libjscre',
      'type': 'static_library',
      'dependencies': [
      ],
      'include_dirs': [
        '.',
      ],
      'defines': [
        'SUPPORT_UTF8',
        'SUPPORT_UCP',
        'NO_RECURSE',
      ],
      'sources': [
        'ASCIICType.h',
        'config.h',
        'pcre.h',
        'pcre_internal.h',
        'ucpinternal.h',
        'pcre_compile.cpp',
        'pcre_exec.cpp',
        'pcre_tables.cpp',
        'pcre_ucp_searchfuncs.cpp',
        'pcre_xclass.cpp',
      ],
    },
  ],
}
