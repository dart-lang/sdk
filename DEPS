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
  "fuchsia_git": "https://fuchsia.googlesource.com",

  # Only use this temporarily while waiting for a mirror for a new package.
  "github_dartlang": "https://github.com/dart-lang/%s.git",

  "gyp_rev": "@6ee91ad8659871916f9aa840d42e1513befdf638",
  "co19_rev": "@dec2b67aaab3bb7339b9764049707e71e601da3d",

  # Revisions of GN related dependencies. This should match the revision
  # pulled by Flutter.
  "buildtools_revision": "@057ef89874e3c622248cf99259434fdc683c4e30",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "@c09c8deeac31f05bd801995c475e7c8070f9ecda",

  "gperftools_revision": "@02eeed29df112728564a5dde6417fa4622b57a06",

  # Revisions of /third_party/* dependencies.
  "args_tag": "@0.13.7",
  "async_tag": "@daf66909019d2aaec1721fc39d94ea648a9fdc1d",
  "barback-0.13.0_rev": "@34853",
  "barback-0.14.0_rev": "@36398",
  "barback-0.14.1_rev": "@38525",
  "barback_tag" : "@0.15.2+11",
  "bazel_worker_tag": "@v0.1.4",
  "boolean_selector_tag" : "@1.0.2",
  "boringssl_gen_rev": "@753224969dbe43dad29343146529727b5066c0f3",
  "boringssl_rev" : "@d519bf6be0b447fb80fbc539d4bff4479b5482a2",
  "charcode_tag": "@v1.1.1",
  "chrome_rev" : "@19997",
  "cli_util_tag" : "@0.1.0",
  "code_transformers_tag": "@v0.5.1",
  "collection_tag": "@1.13.0",
  "convert_tag": "@2.0.1",
  "crypto_tag" : "@2.0.1",
  "csslib_tag" : "@0.13.3+1",
  "dart2js_info_tag" : "@0.5.4+2",
  "dart_services_rev" : "@7aea2574e6f3924bf409a80afb8ad52aa2be4f97",
  "dart_style_tag": "@1.0.6",
  "dartdoc_tag" : "@v0.12.0",
  "fixnum_tag": "@0.10.5",
  "func_tag": "@1.0.0",
  "glob_tag": "@1.1.3",
  "html_tag" : "@0.13.1",
  "http_multi_server_tag" : "@2.0.3",
  "http_parser_tag" : "@3.1.1",
  "http_tag" : "@0.11.3+9",
  "http_throttle_tag" : "@1.0.1",
  "idl_parser_rev": "@7fbe68cab90c38147dee4f48c30ad0d496c17915",
  "initialize_tag": "@v0.6.2+5",
  "intl_tag": "@0.14.0",
  "isolate_tag": "@1.0.0",
  "jinja2_rev": "@2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_tag": "@2.0.4",
  "linter_tag": "@0.1.31",
  "logging_tag": "@0.11.3+1",
  "markdown_tag": "@0.11.2",
  "matcher_tag": "@0.12.0+2",
  "metatest_tag": "@0.2.2+3",
  "mime_rev": "@75890811d4af5af080351ba8a2853ad4c8df98dd",
  "mustache4dart_tag" : "@v1.1.0",
  "oauth2_tag": "@1.0.2",
  "observable_tag": "@0.17.0",
  "observatory_pub_packages_rev": "@26aad88f1c1915d39bbcbff3cad589e2402fdcf1",
  "observe_tag": "@0.15.0",
  "package_config_tag": "@1.0.0",
  "package_resolver_tag": "@1.0.2+1",
  "path_tag": "@1.4.1",
  "plugin_tag": "@0.2.0",
  "ply_rev": "@604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_tag": "@1.3.0",
  "protobuf_tag": "@0.5.4",
  "pub_rev": "@0713718a83054fcc1c0a4b163e036f7c39ea4790",
  "pub_semver_tag": "@1.3.2",
  "quiver_tag": "@0.22.0",
  "resource_rev":"@a49101ba2deb29c728acba6fb86000a8f730f4b1",
  "root_certificates_rev": "@a4c7c6f23a664a37bc1b6f15a819e3f2a292791a",
  "scheduled_test_tag": "@0.12.11",
  "shelf_static_tag": "@0.2.4",
  "shelf_packages_handler_tag": "@1.0.0",
  "shelf_tag": "@0.6.7+2",
  "shelf_web_socket_tag": "@0.2.1",
  "smoke_tag" : "@v0.3.6+2",
  "source_map_stack_trace_tag": "@1.1.4",
  "source_maps-0.9.4_rev": "@38524",
  "source_maps_tag": "@0.10.4",
  "source_span_tag": "@1.4.0",
  "stack_trace_tag": "@1.7.2",
  "stream_channel_tag": "@1.6.1",
  "string_scanner_tag": "@1.0.1",
  "sunflower_rev": "@879b704933413414679396b129f5dfa96f7a0b1e",
  "test_reflective_loader_tag": "@0.1.0",
  "test_tag": "@0.12.18+1",
  "tuple_tag": "@v1.0.1",
  "typed_data_tag": "@1.1.3",
  "usage_tag": "@v3.0.0+1",
  "utf_tag": "@0.9.0+3",
  "watcher_tag": "@0.9.7+3",
  "web_components_rev": "@6349e09f9118dce7ae1b309af5763745e25a9d61",
  "web_socket_channel_tag": "@1.0.4",
  "WebCore_rev": "@3c45690813c112373757bbef53de1602a62af609",
  "yaml_tag": "@2.1.12",
  "zlib_rev": "@c3d0a6190f2f8c924a05ab6cc97b8f975bddd33f",
}

deps = {
  # Stuff needed for GYP to run.
  Var("dart_root") + "/third_party/gyp":
      Var('chromium_git') + '/external/gyp.git' + Var("gyp_rev"),

  # Stuff needed for GN build.
  Var("dart_root") + "/buildtools":
     Var("fuchsia_git") + "/buildtools" + Var("buildtools_revision"),
  Var("dart_root") + "/buildtools/clang_format/script":
    Var("chromium_git") + "/chromium/llvm-project/cfe/tools/clang-format.git" +
    Var("clang_format_scripts_rev"),

  Var("dart_root") + "/tests/co19/src":
      (Var("github_mirror") % "co19") + Var("co19_rev"),

  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      Var("zlib_rev"),

  Var("dart_root") + "/third_party/boringssl":
      (Var("github_mirror") % "boringssl_gen") + Var("boringssl_gen_rev"),
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
      (Var("github_mirror") % "bazel_worker") + Var("bazel_worker_tag"),
  Var("dart_root") + "/third_party/pkg/boolean_selector":
      (Var("github_mirror") % "boolean_selector") +
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
      (Var("github_mirror") % "code_transformers") +
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
  Var("dart_root") + "/third_party/pkg/fixnum":
      (Var("github_mirror") % "fixnum") + Var("fixnum_tag"),
  Var("dart_root") + "/third_party/pkg/func":
      (Var("github_mirror") % "func") + Var("func_tag"),
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
      Var("http_throttle_tag"),
  Var("dart_root") + "/third_party/pkg/initialize":
      (Var("github_mirror") % "initialize") + Var("initialize_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      (Var("github_mirror") % "intl") + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/isolate":
      (Var("github_mirror") % "isolate") + Var("isolate_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      (Var("github_mirror") % "json_rpc_2") + Var("json_rpc_2_tag"),
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
  Var("dart_root") + "/third_party/pkg/observable":
      (Var("github_mirror") % "observable") + Var("observable_tag"),
  Var("dart_root") + "/third_party/pkg/observe":
      (Var("github_mirror") % "observe") + Var("observe_tag"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
      (Var("github_mirror") % "observatory_pub_packages")
      + Var("observatory_pub_packages_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      (Var("github_mirror") % "package_config") +
      Var("package_config_tag"),
  Var("dart_root") + "/third_party/pkg_tested/package_resolver":
      (Var("github_mirror") % "package_resolver") + Var("package_resolver_tag"),
  Var("dart_root") + "/third_party/pkg/path":
      (Var("github_mirror") % "path") + Var("path_tag"),
  Var("dart_root") + "/third_party/pkg/plugin":
      (Var("github_mirror") % "plugin") + Var("plugin_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      (Var("github_mirror") % "pool") + Var("pool_tag"),
  Var("dart_root") + "/third_party/pkg/protobuf":
      # Restore the github mirror once it's corrected to point to protobuf
      # instead of dart-protobuf
      # (Var("github_mirror") % "dart-protobuf") + Var("protobuf_tag"),
      (Var("github_dartlang") % "protobuf") + Var("protobuf_tag"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      (Var("github_mirror") % "pub_semver") + Var("pub_semver_tag"),
  Var("dart_root") + "/third_party/pkg/pub":
      (Var("github_mirror") % "pub") + Var("pub_rev"),
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
      (Var("github_mirror") % "stream_channel") +
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
  Var("dart_root") + "/third_party/pkg/tuple":
      (Var("github_dartlang") % "tuple") + Var("tuple_tag"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      (Var("github_mirror") % "typed_data") + Var("typed_data_tag"),
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
      (Var("github_mirror") % "web_socket_channel") +
      Var("web_socket_channel_tag"),
  Var("dart_root") + "/third_party/pkg/yaml":
      (Var("github_mirror") % "yaml") + Var("yaml_tag"),
}

deps_os = {
  "win": {
    Var("dart_root") + "/third_party/cygwin":
      Var("chromium_git") + "/chromium/deps/cygwin.git" +
      "@c89e446b273697fadf3a10ff1007a97c0b7de6df",
  },
}

# TODO(iposva): Move the necessary tools so that hooks can be run
# without the runtime being available.
hooks = [
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
    # Pull Debian wheezy sysroot for i386 Linux
    'name': 'sysroot_i386',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--running-as-hook', '--arch', 'i386'],
  },
  {
    # Pull Debian wheezy sysroot for amd64 Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--running-as-hook', '--arch', 'amd64'],
  },
  {
    'name': 'download_android_tools',
    'pattern': '.',
    'action': ['python', 'sdk/tools/android/download_android_tools.py'],
  },
  {
    'name': 'buildtools',
    'pattern': '.',
    'action': ['python', 'sdk/tools/buildtools/update.py'],
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
