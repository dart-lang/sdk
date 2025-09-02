// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File, Platform;

import 'package:kernel/ast.dart' show Source;
import 'package:kernel/target/targets.dart';

import 'base/compiler_context.dart' show CompilerContext;
import 'base/processed_options.dart' show ProcessedOptions;

/// Returns the name of the default platform dill file name for the [target]
/// with the given [nnbdMode].
///
/// If the target doesn't have a default platform dill file for the nnbd mode,
/// [onError] is called.
String? computePlatformDillName(Target target, void Function() onError) {
  switch (target.name) {
    case 'dartdevc':
      // DDC is always compiled against the outline so we use it here by
      // default.
      return 'ddc_outline.dill';
    //TODO(johnniwinther): Support using the full dill.
    //return 'ddc_platform.dill';
    case 'dart2js':
      return 'dart2js_platform.dill';
    case 'dart2js_server':
      return 'dart2js_server_platform.dill';
    case 'vm':
      return 'vm_platform.dill';
    case 'none':
      return 'vm_platform.dill';
    case 'wasm':
      return 'dart2wasm_outline.dill';
    // Coverage-ignore(suite): Not run.
    case 'wasm_js_compatibility':
      return 'dart2wasm_js_compatibility_outline.dill';
    default:
      break;
  }
  // Coverage-ignore-block(suite): Not run.
  onError();
  return null;
}

/// Computes the location of platform binaries, that is, compiled `.dill` files
/// of the platform libraries that are used to avoid recompiling those
/// libraries.
Uri computePlatformBinariesLocation({bool forceBuildDir = false}) {
  String? resolvedExecutable = Platform.environment['resolvedExecutable'];
  // The directory of the Dart VM executable.
  Uri vmDirectory = Uri.base
      .resolveUri(
        new Uri.file(resolvedExecutable ?? Platform.resolvedExecutable),
      )
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
Uri translateSdk(CompilerContext context, Uri uri) {
  if (uri.isScheme("org-dartlang-sdk")) {
    String path = uri.path;
    if (path.startsWith("/sdk/")) {
      Uri? sdkRoot = context.cachedSdkRoot;
      if (sdkRoot == null) {
        ProcessedOptions options = context.options;
        sdkRoot = options.sdkRoot;
        if (sdkRoot == null) {
          sdkRoot = options.librariesSpecificationUri
              // Coverage-ignore(suite): Not run.
              ?.resolve("../");
          if (sdkRoot != null) {
            // Coverage-ignore-block(suite): Not run.
            if (!isExistingFile(sdkRoot.resolve("lib/libraries.json"))) {
              sdkRoot = null;
            }
          }
        }
        if (sdkRoot == null) {
          sdkRoot =
              (options.sdkSummary ?? // Coverage-ignore(suite): Not run.
                      computePlatformBinariesLocation())
                  .resolve("../../");
          if (!isExistingFile(sdkRoot.resolve("lib/libraries.json"))) {
            if (isExistingFile(sdkRoot.resolve("sdk/lib/libraries.json"))) {
              sdkRoot = sdkRoot.resolve("sdk/");
            } else {
              sdkRoot = null;
            }
          }
        }
        // Coverage-ignore(suite): Not run.
        sdkRoot ??= Uri.parse("org-dartlang-sdk:///sdk/");
        context.cachedSdkRoot = sdkRoot;
      }
      Uri candidate = sdkRoot.resolve(path.substring(5));
      if (isExistingFile(candidate)) {
        Map<Uri, Source> uriToSource = context.uriToSource;
        Source source = uriToSource[uri]!;
        if (source.source.isEmpty) {
          // Coverage-ignore-block(suite): Not run.
          uriToSource[uri] = new Source(
            source.lineStarts,
            new File.fromUri(candidate).readAsBytesSync(),
            source.importUri,
            source.fileUri,
          );
        }
      }
      return candidate;
    }
  }
  return uri;
}

bool isExistingFile(Uri uri) {
  if (uri.isScheme("file")) {
    return new File.fromUri(uri).existsSync();
  } else {
    return false;
  }
}
