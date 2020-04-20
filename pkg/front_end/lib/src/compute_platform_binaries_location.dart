// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File, Platform;

import 'package:kernel/ast.dart' show Source;

import 'base/processed_options.dart' show ProcessedOptions;

import 'fasta/compiler_context.dart' show CompilerContext;

/// Computes the location of platform binaries, that is, compiled `.dill` files
/// of the platform libraries that are used to avoid recompiling those
/// libraries.
Uri computePlatformBinariesLocation({bool forceBuildDir: false}) {
  String resolvedExecutable = Platform.environment['resolvedExecutable'];
  // The directory of the Dart VM executable.
  Uri vmDirectory = Uri.base
      .resolveUri(
          new Uri.file(resolvedExecutable ?? Platform.resolvedExecutable))
      .resolve(".");
  if (vmDirectory.path.endsWith("/bin/")) {
    // Looks like the VM is in a `/bin/` directory, so this is running from a
    // built SDK.
    return vmDirectory.resolve(forceBuildDir ? "../../" : "../lib/_internal/");
  } else {
    // We assume this is running from a build directory (for example,
    // `out/ReleaseX64` or `xcodebuild/ReleaseX64`).
    return vmDirectory;
  }
}

/// Translates an SDK URI ("org-dartlang-sdk:///...") to a file URI.
Uri translateSdk(Uri uri) {
  if (CompilerContext.isActive) {
    if (uri.scheme == "org-dartlang-sdk") {
      String path = uri.path;
      if (path.startsWith("/sdk/")) {
        CompilerContext context = CompilerContext.current;
        Uri sdkRoot = context.cachedSdkRoot;
        if (sdkRoot == null) {
          ProcessedOptions options = context.options;
          sdkRoot = options.sdkRoot;
          if (sdkRoot == null) {
            sdkRoot = options.librariesSpecificationUri?.resolve("../");
            if (sdkRoot != null) {
              if (!isExistingFile(sdkRoot.resolve("lib/libraries.json"))) {
                sdkRoot = null;
              }
            }
          }
          if (sdkRoot == null) {
            sdkRoot = (options.sdkSummary ?? computePlatformBinariesLocation())
                .resolve("../../");
            if (sdkRoot != null) {
              if (!isExistingFile(sdkRoot.resolve("lib/libraries.json"))) {
                if (isExistingFile(sdkRoot.resolve("sdk/lib/libraries.json"))) {
                  sdkRoot = sdkRoot.resolve("sdk/");
                } else {
                  sdkRoot = null;
                }
              }
            }
          }
          sdkRoot ??= Uri.parse("org-dartlang-sdk:///sdk/");
          context.cachedSdkRoot = sdkRoot;
        }
        Uri candidate = sdkRoot.resolve(path.substring(5));
        if (isExistingFile(candidate)) {
          Map<Uri, Source> uriToSource = CompilerContext.current.uriToSource;
          Source source = uriToSource[uri];
          if (source.source.isEmpty) {
            uriToSource[uri] = new Source(
                source.lineStarts,
                new File.fromUri(candidate).readAsBytesSync(),
                source.importUri,
                source.fileUri);
          }
        }
        return candidate;
      }
    }
  }
  return uri;
}

bool isExistingFile(Uri uri) {
  if (uri.scheme == "file") {
    return new File.fromUri(uri).existsSync();
  } else {
    return false;
  }
}
