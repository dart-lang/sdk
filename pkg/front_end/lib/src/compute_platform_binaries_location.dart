// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File, Platform;

import 'package:kernel/ast.dart' show Source;
import 'package:kernel/target/targets.dart';

import 'base/nnbd_mode.dart' show NnbdMode;
import 'base/processed_options.dart' show ProcessedOptions;

import 'fasta/compiler_context.dart' show CompilerContext;

/// Returns the name of the default platform dill file name for the [target]
/// with the given [nnbdMode].
///
/// If the target doesn't have a default platform dill file for the nnbd mode,
/// [onError] is called.
String? computePlatformDillName(
    Target target, NnbdMode nnbdMode, void Function() onError) {
  switch (target.name) {
    case 'dartdevc':
      switch (nnbdMode) {
        case NnbdMode.Strong:
          // DDC is always compiled against the outline so we use it here by
          // default.
          return 'ddc_outline.dill';
        //TODO(johnniwinther): Support using the full dill.
        //return 'ddc_platform.dill';
        case NnbdMode.Weak:
          // DDC is always compiled against the outline so we use it here by
          // default.
          return 'ddc_outline_unsound.dill';
        //TODO(johnniwinther): Support using the full dill.
        //return 'ddc_platform_unsound.dill';
        case NnbdMode.Agnostic:
          break;
      }
      break;
    case 'dart2js':
      switch (nnbdMode) {
        case NnbdMode.Strong:
          return 'dart2js_platform.dill';
        case NnbdMode.Weak:
          return 'dart2js_platform_unsound.dill';
        case NnbdMode.Agnostic:
          break;
      }
      break;
    case 'dart2js_server':
      switch (nnbdMode) {
        case NnbdMode.Strong:
          return 'dart2js_server_platform.dill';
        case NnbdMode.Weak:
          return 'dart2js_server_platform_unsound.dill';
        case NnbdMode.Agnostic:
          break;
      }
      break;
    case 'vm':
      // TODO(johnniwinther): Stop generating 'vm_platform.dill' and rename
      // 'vm_platform_strong.dill' to 'vm_platform.dill'.
      return "vm_platform_strong.dill";
    case 'none':
      return "vm_platform_strong.dill";
    case 'wasm':
      switch (nnbdMode) {
        case NnbdMode.Strong:
          return 'dart2wasm_outline.dill';
        //TODO(johnniwinther): Support using the full dill.
        //return 'dart2wasm_platform.dill';
        case NnbdMode.Weak:
        case NnbdMode.Agnostic:
          break;
      }
      break;
    case 'wasm_stringref':
      switch (nnbdMode) {
        case NnbdMode.Strong:
          return 'dart2wasm_stringref_outline.dill';
        //TODO(johnniwinther): Support using the full dill.
        //return 'dart2wasm_stringref_platform.dill';
        case NnbdMode.Weak:
        case NnbdMode.Agnostic:
          break;
      }
      break;
    case 'wasm_js_compatibility':
      switch (nnbdMode) {
        case NnbdMode.Strong:
          return 'dart2wasm_js_compatibility_outline.dill';
        //TODO(johnniwinther): Support using the full dill.
        //return 'dart2wasm_js_compatibility_platform.dill';
        case NnbdMode.Weak:
        case NnbdMode.Agnostic:
          break;
      }
      break;
    default:
      break;
  }
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
    if (uri.isScheme("org-dartlang-sdk")) {
      String path = uri.path;
      if (path.startsWith("/sdk/")) {
        CompilerContext context = CompilerContext.current;
        Uri? sdkRoot = context.cachedSdkRoot;
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
            if (!isExistingFile(sdkRoot.resolve("lib/libraries.json"))) {
              if (isExistingFile(sdkRoot.resolve("sdk/lib/libraries.json"))) {
                sdkRoot = sdkRoot.resolve("sdk/");
              } else {
                sdkRoot = null;
              }
            }
          }
          sdkRoot ??= Uri.parse("org-dartlang-sdk:///sdk/");
          context.cachedSdkRoot = sdkRoot;
        }
        Uri candidate = sdkRoot.resolve(path.substring(5));
        if (isExistingFile(candidate)) {
          Map<Uri, Source> uriToSource = CompilerContext.current.uriToSource;
          Source source = uriToSource[uri]!;
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
  if (uri.isScheme("file")) {
    return new File.fromUri(uri).existsSync();
  } else {
    return false;
  }
}
