// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _Platform {
  /* patch */ static int _numberOfProcessors()
      native "Platform_NumberOfProcessors";
  /* patch */ static String _pathSeparator() native "Platform_PathSeparator";
  /* patch */ static String _operatingSystem()
      native "Platform_OperatingSystem";
  /* patch */ static _localHostname() native "Platform_LocalHostname";
  /* patch */ static _executable() native "Platform_ExecutableName";
  /* patch */ static _resolvedExecutable()
      native "Platform_ResolvedExecutableName";
  /* patch */ static _environment() native "Platform_Environment";
  /* patch */ static List<String> _executableArguments()
       native "Platform_ExecutableArguments";
  /* patch */ static String _packageRoot() => VMLibraryHooks.packageRoot;
  /* patch */ static String _packageConfig() => VMLibraryHooks.packageConfig;
  /* patch */ static String _version() native "Platform_GetVersion";
}
