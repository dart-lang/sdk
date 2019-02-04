// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
@pragma("vm:entry-point")
class _Platform {
  @patch
  static int _numberOfProcessors() native "Platform_NumberOfProcessors";
  @patch
  static String _pathSeparator() native "Platform_PathSeparator";
  @patch
  static String _operatingSystem() native "Platform_OperatingSystem";
  @patch
  static _operatingSystemVersion() native "Platform_OperatingSystemVersion";
  @patch
  static _localHostname() native "Platform_LocalHostname";
  @patch
  static _executable() native "Platform_ExecutableName";
  @patch
  static _resolvedExecutable() native "Platform_ResolvedExecutableName";
  @patch
  static _environment() native "Platform_Environment";
  @patch
  static List<String> _executableArguments()
      native "Platform_ExecutableArguments";
  @patch
  static String _version() native "Platform_GetVersion";

  @patch
  static String _localeName() native "Platform_LocaleName";

  @patch
  static String _packageRoot() => VMLibraryHooks.packageRootString;
  @patch
  static String _packageConfig() => VMLibraryHooks.packageConfigString;

  @patch
  static Uri _script() => VMLibraryHooks.platformScript;

  // This script singleton is written to by the embedder if applicable.
  @pragma("vm:entry-point")
  static void set _nativeScript(String path) {
    VMLibraryHooks.platformScript = (() {
      if (path.startsWith('http:') ||
          path.startsWith('https:') ||
          path.startsWith('package:') ||
          path.startsWith('dart:') ||
          path.startsWith('data:') ||
          path.startsWith('file:')) {
        return Uri.parse(path);
      } else {
        return Uri.base.resolveUri(new Uri.file(path));
      }
    });
  }
}
