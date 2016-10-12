# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

vars = {
  # The dart_root is the root of our sdk checkout. This is normally
  # simply sdk, but if using special gclient specs it can be different.
  "dart_root": "sdk",

  # We use mirrors of all github repos to guarantee reproducibility and
  # consistency between what users see and what the bots see.
  # We need the mirrors to not have 100+ bots pulling github constantly.
  # We mirror our github repos on chromium git servers.
  # DO NOT use this var if you don't see a mirror here:
  #   https://chromium.googlesource.com/
  # named like:
  #   external/github.com/dart-lang/NAME
  # It is ok to add a dependency directly on dart-lang (dart-lang only)
  # github repo until the mirror has been created, but please do file a bug
  # against infra to make that happen.
  "github_mirror":
      "https://chromium.googlesource.com/external/github.com/dart-lang/%s.git",

  # Chromium git
  "chromium_git": "https://chromium.googlesource.com",

  # Only use this temporarily while waiting for a mirror for a new package.
  "github_dartlang": "https://github.com/dart-lang/%s.git",

  "gyp_rev": "@6ee91ad8659871916f9aa840d42e1513befdf638",
  "co19_rev": "@d4767b4caea3c5828ad8e053cd051d44a59061af",

  # Revisions of GN related dependencies.
  "buildtools_revision": "@39b1db2ab4aa4b2ccaa263c29bdf63e7c1ee28aa",

  "gperftools_revision": "@02eeed29df112728564a5dde6417fa4622b57a06",

  # Revisions of /third_party/* dependencies.
  "args_tag": "@0.13.5",
  "async_tag": "@1.11.2",
  "barback-0.13.0_rev": "@34853",
  "barback-0.14.0_rev": "@36398",
  "barback-0.14.1_rev": "@38525",
  "barback_tag" : "@0.15.2+9",
  "bazel_worker_tag": "@0.1.1",
  "boolean_selector_tag" : "@1.0.2",
  "boringssl_gen_rev": "@62c20247d582444cb2804f9ea4e3abaa6e47f6a5",
  "boringssl_rev" : "@8d343b44bbab829d1a28fdef650ca95f7db4412e",
  "charcode_tag": "@1.1.0",
  "chrome_rev" : "@19997",
  "cli_util_tag" : "@0.0.1+3",
  "code_transformers_tag": "@v0.4.2+3",
  "collection_tag": "@1.9.1",
  "convert_tag": "@2.0.1",
  "crypto_tag" : "@2.0.1",
  "csslib_tag" : "@0.13.2",
  "dart2js_info_tag" : "@0.5.0",
  "dart_services_rev" : "@7aea2574e6f3924bf409a80afb8ad52aa2be4f97",
  "dart_style_tag": "@0.2.10",
  "dartdoc_tag" : "@v0.9.7+6",
  "fixnum_tag": "@0.10.5",
  "func_tag": "@0.1.0",
  "glob_tag": "@1.1.3",
  "html_tag" : "@0.13.0",
  "http_multi_server_tag" : "@2.0.2",
  "http_parser_tag" : "@3.0.2",
  "http_tag" : "@0.11.3+9",
  "http_throttle_rev" : "@284344cd357e435c6c8ff9a4a21f02b9e384a541",
  "idl_parser_rev": "@7fbe68cab90c38147dee4f48c30ad0d496c17915",
  "initialize_tag": "@v0.6.2+2",
  "intl_tag": "@0.14.0",
  "isolate_tag": "@0.2.3",
  "jinja2_rev": "@2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_tag": "@2.0.2",
  "kernel_rev": "@1906e420431656d351a9f4ee9a36b8ca9a4da1db",
  "linter_tag": "@0.1.28",
  "logging_tag": "@0.11.3+1",
  "markdown_tag": "@0.11.0",
  "matcher_tag": "@0.12.0+2",
  "metatest_tag": "@0.2.2+2",
  "mime_rev": "@75890811d4af5af080351ba8a2853ad4c8df98dd",
  "mustache4dart_tag" : "@v1.0.10",
  "oauth2_tag": "@1.0.2",
  "observatory_pub_packages_rev": "@26aad88f1c1915d39bbcbff3cad589e2402fdcf1",
  "observe_tag": "@0.13.5",
  "package_config_tag": "@1.0.0",
  "package_resolver_tag": "@1.0.2",
  "path_tag": "@1.3.9",
  "plugin_tag": "@0.2.0",
  "ply_rev": "@604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_tag": "@1.2.4",
  "protobuf_tag": "@0.5.3",
  "pub_cache_tag": "@v0.1.0",
  "pub_rev": "@3dd04bd17ba269ccdd34502a253041dd96ded3be",
  "pub_semver_tag": "@1.3.0",
  "quiver_tag": "@0.22.0",
  "resource_rev":"@a49101ba2deb29c728acba6fb86000a8f730f4b1",
  "root_certificates_rev": "@aed07942ce98507d2be28cbd29e879525410c7fc",
  "scheduled_test_tag": "@0.12.6",
  "shelf_static_tag": "@0.2.4",
  "shelf_packages_handler_tag": "@1.0.0",
  "shelf_tag": "@0.6.5+3",
  "shelf_web_socket_tag": "@0.2.1",
  "smoke_tag" : "@v0.3.6+2",
  "source_map_stack_trace_tag": "@1.1.3",
  "source_maps-0.9.4_rev": "@38524",
  "source_maps_tag": "@0.10.1+1",
  "source_span_tag": "@1.2.3",
  "stack_trace_tag": "@1.6.6",
  "stream_channel_tag": "@1.5.0",
  "string_scanner_tag": "@1.0.0",
  "sunflower_rev": "@879b704933413414679396b129f5dfa96f7a0b1e",
  "test_reflective_loader_tag": "@0.1.0",
  "test_tag": "@0.12.15+6",
  "typed_data_tag": "@1.1.3",
  "usage_tag": "@v2.2.2",
  "utf_tag": "@0.9.0+3",
  "watcher_tag": "@0.9.7+3",
  "web_components_rev": "@6349e09f9118dce7ae1b309af5763745e25a9d61",
  "web_socket_channel_tag": "@1.0.4",
  "WebCore_rev": "@a86fe28efadcfc781f836037a80f27e22a5dad17",
  "when_tag": "@0.2.0+2",
  "which_tag": "@0.1.3+1",
  "yaml_tag": "@2.1.10",
  "zlib_rev": "@c3d0a6190f2f8c924a05ab6cc97b8f975bddd33f",
}

deps = {
  # Stuff needed for GYP to run.
  Var("dart_root") + "/third_party/gyp":
      Var('chromium_git') + '/external/gyp.git' + Var("gyp_rev"),

  # Stuff needed for GN build.
  Var("dart_root") + "/buildtools":
     Var('chromium_git') + '/chromium/buildtools.git' +
     Var('buildtools_revision'),

  Var("dart_root") + "/tests/co19/src":
      (Var("github_mirror") % "co19") + Var("co19_rev"),

  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      Var("zlib_rev"),

  Var("dart_root") + "/third_party/boringssl":
     (Var("github_dartlang") % "boringssl_gen") + Var("boringssl_gen_rev"),
  Var("dart_root") + "/third_party/boringssl/src":
      "https://boringssl.googlesource.com/boringssl.git" +
      Var("boringssl_rev"),

  Var("dart_root") + "/third_party/root_certificates":
      (Var("github_mirror") % "root_certificates") +
      Var("root_certificates_rev"),

  Var("dart_root") + "/third_party/jinja2":
      Var("chromium_git") + "/chromium/src/third_party/jinja2.git" +
      Var("jinja2_rev"),

  Var("dart_root") + "/third_party/ply":
      Var("chromium_git") + "/chromium/src/third_party/ply.git" +
      Var("ply_rev"),

  Var("dart_root") + "/tools/idl_parser":
      Var("chromium_git") + "/chromium/src/tools/idl_parser.git" +
      Var("idl_parser_rev"),

  Var("dart_root") + "/third_party/WebCore":
      "https://github.com/dart-lang/webcore.git" + Var("WebCore_rev"),

  Var("dart_root") + "/third_party/tcmalloc/gperftools":
      Var('chromium_git') + '/external/github.com/gperftools/gperftools.git' +
      Var("gperftools_revision"),

  Var("dart_root") + "/third_party/pkg/args":
      (Var("github_mirror") % "args") + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async":
      (Var("github_mirror") % "async") + Var("async_tag"),
  Var("dart_root") + "/third_party/pkg/barback":
      (Var("github_mirror") % "barback") + Var("barback_tag"),
  Var("dart_root") + "/third_party/pkg/bazel_worker":
      (Var("github_dartlang") % "bazel_worker") + Var("bazel_worker_tag"),
  Var("dart_root") + "/third_party/pkg/boolean_selector":
      (Var("github_dartlang") % "boolean_selector") +
      Var("boolean_selector_tag"),
  Var("dart_root") + "/third_party/pkg/charcode":
      (Var("github_mirror") % "charcode") + Var("charcode_tag"),
  Var("dart_root") + "/third_party/pkg/cli_util":
      (Var("github_mirror") % "cli_util") + Var("cli_util_tag"),
  Var("dart_root") + "/third_party/pkg/collection":
      (Var("github_mirror") % "collection") + Var("collection_tag"),
  Var("dart_root") + "/third_party/pkg/convert":
      (Var("github_mirror") % "convert") + Var("convert_tag"),
  Var("dart_root") + "/third_party/pkg/crypto":
      (Var("github_mirror") % "crypto") + Var("crypto_tag"),
  Var("dart_root") + "/third_party/pkg/csslib":
      (Var("github_mirror") % "csslib") + Var("csslib_tag"),
  Var("dart_root") + "/third_party/pkg/code_transformers":
      (Var("github_dartlang") % "code_transformers") +
      Var("code_transformers_tag"),
  Var("dart_root") + "/third_party/dart-services":
      (Var("github_mirror") % "dart-services") +
      Var("dart_services_rev"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      (Var("github_mirror") % "dart_style") + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      (Var("github_mirror") % "dart2js_info") + Var("dart2js_info_tag"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      (Var("github_mirror") % "dartdoc") + Var("dartdoc_tag"),
  Var("dart_root") + "/third_party/pkg/func":
      (Var("github_dartlang") % "func") + Var("func_tag"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      "https://github.com/dart-lang/fixnum.git" + Var("fixnum_tag"),
  Var("dart_root") + "/third_party/pkg/glob":
      (Var("github_mirror") % "glob") + Var("glob_tag"),
  Var("dart_root") + "/third_party/pkg/html":
      (Var("github_mirror") % "html") + Var("html_tag"),
  Var("dart_root") + "/third_party/pkg/http":
      (Var("github_mirror") % "http") + Var("http_tag"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      (Var("github_mirror") % "http_multi_server") +
      Var("http_multi_server_tag"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      (Var("github_mirror") % "http_parser") + Var("http_parser_tag"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      (Var("github_mirror") % "http_throttle") +
      Var("http_throttle_rev"),
  Var("dart_root") + "/third_party/pkg/initialize":
      (Var("github_dartlang") % "initialize") + Var("initialize_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      (Var("github_mirror") % "intl") + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/isolate":
      (Var("github_dartlang") % "isolate") + Var("isolate_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      (Var("github_mirror") % "json_rpc_2") + Var("json_rpc_2_tag"),
  Var("dart_root") + "/third_party/pkg/kernel":
      (Var("github_mirror") % "kernel") + Var("kernel_rev"),
  Var("dart_root") + "/third_party/pkg/linter":
      (Var("github_mirror") % "linter") + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      (Var("github_mirror") % "logging") + Var("logging_tag"),
  Var("dart_root") + "/third_party/pkg/markdown":
      (Var("github_mirror") % "markdown") + Var("markdown_tag"),
  Var("dart_root") + "/third_party/pkg/matcher":
      (Var("github_mirror") % "matcher") + Var("matcher_tag"),
  Var("dart_root") + "/third_party/pkg/metatest":
      (Var("github_mirror") % "metatest") + Var("metatest_tag"),
  Var("dart_root") + "/third_party/pkg/mime":
      (Var("github_mirror") % "mime") + Var("mime_rev"),
  Var("dart_root") + "/third_party/pkg/mustache4dart":
      Var("chromium_git")
      + "/external/github.com/valotas/mustache4dart.git"
      + Var("mustache4dart_tag"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      (Var("github_mirror") % "oauth2") + Var("oauth2_tag"),
  Var("dart_root") + "/third_party/pkg/observe":
      (Var("github_mirror") % "observe") + Var("observe_tag"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
     (Var("github_mirror") % "observatory_pub_packages")
      + Var("observatory_pub_packages_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      (Var("github_mirror") % "package_config") +
      Var("package_config_tag"),
  Var("dart_root") + "/third_party/pkg_tested/package_resolver":
      "https://github.com/dart-lang/package_resolver.git" +
      Var("package_resolver_tag"),
  Var("dart_root") + "/third_party/pkg/path":
      (Var("github_mirror") % "path") + Var("path_tag"),
  Var("dart_root") + "/third_party/pkg/plugin":
      (Var("github_mirror") % "plugin") + Var("plugin_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      (Var("github_mirror") % "pool") + Var("pool_tag"),
  Var("dart_root") + "/third_party/pkg/protobuf":
      (Var("github_dartlang") % "dart-protobuf") + Var("protobuf_tag"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      (Var("github_mirror") % "pub_semver") + Var("pub_semver_tag"),
  Var("dart_root") + "/third_party/pkg/pub":
      (Var("github_mirror") % "pub") + Var("pub_rev"),
  Var("dart_root") + "/third_party/pkg/pub_cache":
      (Var("github_mirror") % "pub_cache") + Var("pub_cache_tag"),
  Var("dart_root") + "/third_party/pkg/quiver":
      Var("chromium_git")
      + "/external/github.com/google/quiver-dart.git"
      + Var("quiver_tag"),
  Var("dart_root") + "/third_party/pkg/resource":
      (Var("github_mirror") % "resource") + Var("resource_rev"),
  Var("dart_root") + "/third_party/pkg/scheduled_test":
      (Var("github_mirror") % "scheduled_test") + Var("scheduled_test_tag"),
  Var("dart_root") + "/third_party/pkg/shelf":
      (Var("github_mirror") % "shelf") + Var("shelf_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_packages_handler":
      (Var("github_mirror") % "shelf_packages_handler")
      + Var("shelf_packages_handler_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      (Var("github_mirror") % "shelf_static") + Var("shelf_static_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      (Var("github_mirror") % "shelf_web_socket") +
      Var("shelf_web_socket_tag"),
  Var("dart_root") + "/third_party/pkg/smoke":
      (Var("github_mirror") % "smoke") + Var("smoke_tag"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      (Var("github_mirror") % "source_maps") + Var("source_maps_tag"),
  Var("dart_root") + "/third_party/pkg/source_span":
      (Var("github_mirror") % "source_span") + Var("source_span_tag"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      (Var("github_mirror") % "source_map_stack_trace") +
      Var("source_map_stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      (Var("github_mirror") % "stack_trace") + Var("stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stream_channel":
      (Var("github_dartlang") % "stream_channel") +
      Var("stream_channel_tag"),
  Var("dart_root") + "/third_party/pkg/string_scanner":
      (Var("github_mirror") % "string_scanner") +
      Var("string_scanner_tag"),
  Var("dart_root") + "/third_party/sunflower":
      (Var("github_mirror") % "sample-sunflower") +
      Var("sunflower_rev"),
  Var("dart_root") + "/third_party/pkg/test":
      (Var("github_mirror") % "test") + Var("test_tag"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      (Var("github_mirror") % "test_reflective_loader") +
      Var("test_reflective_loader_tag"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      (Var("github_dartlang") % "typed_data") + Var("typed_data_tag"),
  Var("dart_root") + "/third_party/pkg/usage":
      (Var("github_mirror") % "usage") + Var("usage_tag"),
  Var("dart_root") + "/third_party/pkg/utf":
      (Var("github_mirror") % "utf") + Var("utf_tag"),
  Var("dart_root") + "/third_party/pkg/watcher":
      (Var("github_mirror") % "watcher") + Var("watcher_tag"),
  Var("dart_root") + "/third_party/pkg/web_components":
      (Var("github_mirror") % "web-components") +
      Var("web_components_rev"),
  Var("dart_root") + "/third_party/pkg/web_socket_channel":
      (Var("github_dartlang") % "web_socket_channel") +
      Var("web_socket_channel_tag"),
  Var("dart_root") + "/third_party/pkg/when":
      (Var("github_mirror") % "when") + Var("when_tag"),
  Var("dart_root") + "/third_party/pkg/which":
      (Var("github_mirror") % "which") + Var("which_tag"),
  Var("dart_root") + "/third_party/pkg/yaml":
      (Var("github_mirror") % "yaml") + Var("yaml_tag"),
}

deps_os = {
  "android": {
    Var("dart_root") + "/third_party/android_tools":
      Var("chromium_git") + "/android_tools.git" +
      "@aaeda3d69df4b4352e3cac7c16bea7f16bd1ec12",
  },
  "win": {
    Var("dart_root") + "/third_party/cygwin":
      Var("chromium_git") + "/chromium/deps/cygwin.git" +
      "@c89e446b273697fadf3a10ff1007a97c0b7de6df",
  },
}

# TODO(iposva): Move the necessary tools so that hooks can be run
# without the runtime being available.
hooks = [
  # Pull GN binaries. This needs to be before running GYP below.
  {
    'name': 'gn_linux64',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--quiet',
      '--platform=linux*',
      '--bucket',
      'chromium-gn',
      '-s',
      Var('dart_root') + '/buildtools/linux64/gn.sha1',
    ],
  },
  {
    'name': 'gn_mac',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--quiet',
      '--platform=darwin',
      '--bucket',
      'chromium-gn',
      '-s',
      Var('dart_root') + '/buildtools/mac/gn.sha1',
    ],
  },
  {
    'name': 'gn_win',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--quiet',
      '--platform=win*',
      '--bucket',
      'chromium-gn',
      '-s',
      Var('dart_root') + '/buildtools/win/gn.exe.sha1',
    ],
  },
  # Pull clang-format binaries using checked-in hashes.
  {
    'name': 'clang_format_linux',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--quiet',
      '--platform=linux*',
      '--bucket',
      'chromium-clang-format',
      '-s',
      Var('dart_root') + '/buildtools/linux64/clang-format.sha1',
    ],
  },
  {
    'name': 'clang_format_mac',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--quiet',
      '--platform=darwin',
      '--bucket',
      'chromium-clang-format',
      '-s',
      Var('dart_root') + '/buildtools/mac/clang-format.sha1',
    ],
  },
  {
    'name': 'd8_testing_binaries',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--bucket',
      'dart-dependencies',
      '--recursive',
      '--directory',
      Var('dart_root') + '/third_party/d8',
    ],
  },
  {
    "name": "checked_in_dart_sdks",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--recursive",
      "--auto_platform",
      "--extract",
      "--directory",
      Var('dart_root') + "/tools/sdks",
    ],
  },
  {
    "name": "firefox_jsshell",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--recursive",
      "--auto_platform",
      "--extract",
      "--directory",
      Var('dart_root') + "/third_party/firefox_jsshell",
    ],
  },
  {
    "name": "drt_resources",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--platform=win32",
      "--directory",
      Var('dart_root') + "/third_party/drt_resources",
    ],
  },
  {
    "name": "unittest",
    # Unittest is an early version, 0.11.6, of the package "test"
    # Do not use it in any new tests.
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--extract",
      "-s",
      Var('dart_root') + "/third_party/pkg/unittest.tar.gz.sha1",
    ],
  },
  {
    "name": "7zip",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--platform=win32",
      "--extract",
      "-s",
      Var('dart_root') + "/third_party/7zip.tar.gz.sha1",
    ],
  },
  {
    "name": "gsutil",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--extract",
      "-s",
      Var('dart_root') + "/third_party/gsutil.tar.gz.sha1",
    ],
  },
  {
    "name": "clang",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--platform=linux*",
      "--extract",
      "-s",
      Var('dart_root') + "/third_party/clang.tar.gz.sha1",
    ],
  },
  {
    # Pull clang if needed or requested via GYP_DEFINES.
    'name': 'gn_clang',
    'pattern': '.',
    'action': ['python', 'sdk/tools/clang/scripts/update.py', '--if-needed'],
  },
  {
    # Update the Windows toolchain if necessary.
    'name': 'win_toolchain',
    'pattern': '.',
    'action': ['python', 'sdk/build/vs_toolchain.py', 'update'],
  },
  {
    "pattern": ".",
    "action": ["python", Var("dart_root") + "/tools/generate_buildfiles.py"],
  },
]
