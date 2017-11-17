// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Script that updates kernel status lines automatically for tests under the
/// '$strong' configuration.
///
/// This script is hardcoded to only support this configuration and relies on
/// a convention for how the status files are structured, In particular,
/// every status file is expected to have these sections:
///
///     [ $compiler == dartk && $runtime == vm && $strong ]
///     [ $compiler == dartk && $runtime == vm && $strong && $mode == debug ]
///     [ $compiler == dartkp && $runtime == dart_precompiled && $strong ]
///     [ $compiler == dartkp && $runtime == dart_precompiled && $strong && $mode == debug]
///
/// we allow other sections specifying $checked mode, but the script currently
/// has not been configured to update them.
///
///     [ $compiler == dartk && $runtime == vm && $strong && $checked ]
///     [ $compiler == dartk && $runtime == vm && $strong && !$checked ]
///     [ $compiler == dartkp && $runtime == dart_precompiled && $strong && $checked]
///     [ $compiler == dartkp && $runtime == dart_precompiled && $strong && !$checked]
///
/// Note that this script is brittle and will not work properly if there are
/// other overlapping sections. If you see the script adding entries like "Pass"
/// it is a sign that a test was broadly marked as failing in a more general
/// section (e.g. $runtime == vm, but no compiler was specified).

library front_end.status_files.update_from_log;

import '../../../compiler/tool/status_files/update_from_log.dart'
    show mainInternal;

final kernelStrongConfigurations = {
  'dartk': r'[ $compiler == dartk && $runtime == vm && $strong ]',
  'dartk-debug':
      r'[ $compiler == dartk && $runtime == vm && $strong && $mode == debug]',
  'dartkp':
      r'[ $compiler == dartkp && $runtime == dart_precompiled && $strong ]',
  'dartkp-debug':
      r'[ $compiler == dartkp && $runtime == dart_precompiled && $strong && $mode == debug]',
};

final kernelStrongStatusFiles = {
  'corelib_2': 'tests/corelib_2/corelib_2.status',
  'language_2': 'tests/language_2/language_2_kernel.status',
  'lib_2': 'tests/lib_2/lib_2_kernel.status',
  'standalone_2': 'tests/standalone_2/standalone_2_kernel.status',
};

main(args) {
  mainInternal(args, kernelStrongConfigurations, kernelStrongStatusFiles);
}
