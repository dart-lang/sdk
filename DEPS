# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# IMPORTANT:
# Before adding or updating dependencies, please review the documentation here:
# https://github.com/dart-lang/sdk/wiki/Adding-and-Updating-Dependencies

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
  "github_mirror":
      "https://chromium.googlesource.com/external/github.com/dart-lang/",

  # Chromium git
  "chromium_git": "https://chromium.googlesource.com",
  "fuchsia_git": "https://fuchsia.googlesource.com",

  # IMPORTANT:
  # This should only be used for local testing. Before adding a new package,
  # request a mirror of the package you need. To request a mirror, file an issue
  # on github and add the label 'area-infrastructure'.
  # "github_dartlang": "https://github.com/dart-lang/%s.git",

  "co19_rev": "@dec2b67aaab3bb7339b9764049707e71e601da3d",

  # Revisions of GN related dependencies. This should match the revision
  # pulled by Flutter.
  "buildtools_revision": "@5b8eb38aaf523f0124756454276cd0a5b720c17e",

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
  "collection_tag": "@1.14.3",
  "convert_tag": "@2.0.1",
  "crypto_tag" : "@2.0.2",
  "csslib_tag" : "@0.13.3+1",
  "dart2js_info_tag" : "@0.5.4+2",

  # Note: updates to dart_style have to be coordinated carefully with
  # the infrastructure-team so that the internal formatter in
  # `sdk/tools/sdks/*/dart-sdk/bin/dartfmt` matches the version here.
  #
  # Please follow this process to make updates:
  #   * file an issue with area-infrastructure requesting a roll for this
  #     package (please also indicate what version to roll).
  #   * let the infrastructure team submit the change on your behalf,
  #     so they can build a new dev release and roll the submitted sdks a few
  #     minutes later.
  #
  # For more details, see https://github.com/dart-lang/sdk/issues/30164
  "dart_style_tag": "@1.0.7",  # Please see the note above before updating.

  "dartdoc_tag" : "@v0.13.0+2",
  "fixnum_tag": "@0.10.5",
  "func_tag": "@1.0.0",
  "glob_tag": "@1.1.3",
  "html_tag" : "@0.13.1",
  "http_multi_server_tag" : "@2.0.3",
  "http_parser_tag" : "@3.1.1",
  "http_tag" : "@0.11.3+14",
  "http_throttle_tag" : "@1.0.1",
  "idl_parser_rev": "@7fbe68cab90c38147dee4f48c30ad0d496c17915",
  "intl_tag": "@0.14.0",
  "isolate_tag": "@1.0.0",
  "jinja2_rev": "@2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_tag": "@2.0.4",
  "linter_tag": "@0.1.35",
  "logging_tag": "@0.11.3+1",
  "markdown_tag": "@0.11.3",
  "matcher_tag": "@0.12.0+2",
  "mime_rev": "@75890811d4af5af080351ba8a2853ad4c8df98dd",
  "mockito_tag": "@2.0.2",
  "mustache4dart_tag" : "@v1.1.0",
  "oauth2_tag": "@1.0.2",
  "observatory_pub_packages_rev": "@a4e392521c720d244cd63e067387195d78584b35",
  "package_config_tag": "@1.0.1",
  "package_resolver_tag": "@1.0.2+1",
  "path_tag": "@1.4.1",
  "plugin_tag": "@0.2.0",
  "ply_rev": "@604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_tag": "@1.3.0",
  "protobuf_tag": "@0.5.4",
  "pub_rev": "@0f122625f8e607842afe156b9b23a9709e4ce39a",
  "pub_semver_tag": "@1.3.2",
  "quiver_tag": "@0.22.0",
  "resource_rev":"@a49101ba2deb29c728acba6fb86000a8f730f4b1",
  "root_certificates_rev": "@a4c7c6f23a664a37bc1b6f15a819e3f2a292791a",
  "scheduled_test_tag": "@0.12.11",
  "shelf_static_tag": "@0.2.4",
  "shelf_packages_handler_tag": "@1.0.0",
  "shelf_tag": "@0.6.7+2",
  "shelf_web_socket_tag": "@0.2.1",
  "source_map_stack_trace_tag": "@1.1.4",
  "source_maps-0.9.4_rev": "@38524",
  "source_maps_tag": "@0.10.4",
  "source_span_tag": "@1.4.0",
  "stack_trace_tag": "@1.7.2",
  "stream_channel_tag": "@1.6.1",
  "string_scanner_tag": "@1.0.1",
  "sunflower_rev": "@879b704933413414679396b129f5dfa96f7a0b1e",
  "term_glyph_tag": "@1.0.0",
  "test_reflective_loader_tag": "@0.1.0",
  "test_tag": "@0.12.18+1",
  "tuple_tag": "@v1.0.1",
  "typed_data_tag": "@1.1.3",
  "usage_tag": "@3.3.0",
  "utf_tag": "@0.9.0+3",
  "watcher_tag": "@0.9.7+3",
  "web_socket_channel_tag": "@1.0.4",
  "WebCore_rev": "@3c45690813c112373757bbef53de1602a62af609",
  "yaml_tag": "@2.1.12",
  "zlib_rev": "@c3d0a6190f2f8c924a05ab6cc97b8f975bddd33f",
}

deps = {
  # Stuff needed for GN build.
  Var("dart_root") + "/buildtools":
     Var("fuchsia_git") + "/buildtools" + Var("buildtools_revision"),
  Var("dart_root") + "/buildtools/clang_format/script":
    Var("chromium_git") + "/chromium/llvm-project/cfe/tools/clang-format.git" +
    Var("clang_format_scripts_rev"),

  Var("dart_root") + "/tests/co19/src":
      Var("github_mirror") + "co19.git" + Var("co19_rev"),

  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      Var("zlib_rev"),

  Var("dart_root") + "/third_party/boringssl":
      Var("github_mirror") + "boringssl_gen.git" + Var("boringssl_gen_rev"),
  Var("dart_root") + "/third_party/boringssl/src":
      "https://boringssl.googlesource.com/boringssl.git" +
      Var("boringssl_rev"),

  Var("dart_root") + "/third_party/root_certificates":
      Var("github_mirror") + "root_certificates.git" +
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
      Var("github_mirror") + "webcore.git" + Var("WebCore_rev"),

  Var("dart_root") + "/third_party/tcmalloc/gperftools":
      Var('chromium_git') + '/external/github.com/gperftools/gperftools.git' +
      Var("gperftools_revision"),

  Var("dart_root") + "/third_party/pkg/args":
      Var("github_mirror") + "args.git" + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async":
      Var("github_mirror") + "async.git" + Var("async_tag"),
  Var("dart_root") + "/third_party/pkg/barback":
      Var("github_mirror") + "barback.git" + Var("barback_tag"),
  Var("dart_root") + "/third_party/pkg/bazel_worker":
      Var("github_mirror") + "bazel_worker.git" + Var("bazel_worker_tag"),
  Var("dart_root") + "/third_party/pkg/boolean_selector":
      Var("github_mirror") + "boolean_selector.git" +
      Var("boolean_selector_tag"),
  Var("dart_root") + "/third_party/pkg/charcode":
      Var("github_mirror") + "charcode.git" + Var("charcode_tag"),
  Var("dart_root") + "/third_party/pkg/cli_util":
      Var("github_mirror") + "cli_util.git" + Var("cli_util_tag"),
  Var("dart_root") + "/third_party/pkg/collection":
      Var("github_mirror") + "collection.git" + Var("collection_tag"),
  Var("dart_root") + "/third_party/pkg/convert":
      Var("github_mirror") + "convert.git" + Var("convert_tag"),
  Var("dart_root") + "/third_party/pkg/crypto":
      Var("github_mirror") + "crypto.git" + Var("crypto_tag"),
  Var("dart_root") + "/third_party/pkg/csslib":
      Var("github_mirror") + "csslib.git" + Var("csslib_tag"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      Var("github_mirror") + "dart_style.git" + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      Var("github_mirror") + "dart2js_info.git" + Var("dart2js_info_tag"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      Var("github_mirror") + "dartdoc.git" + Var("dartdoc_tag"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      Var("github_mirror") + "fixnum.git" + Var("fixnum_tag"),
  Var("dart_root") + "/third_party/pkg/func":
      Var("github_mirror") + "func.git" + Var("func_tag"),
  Var("dart_root") + "/third_party/pkg/glob":
      Var("github_mirror") + "glob.git" + Var("glob_tag"),
  Var("dart_root") + "/third_party/pkg/html":
      Var("github_mirror") + "html.git" + Var("html_tag"),
  Var("dart_root") + "/third_party/pkg/http":
      Var("github_mirror") + "http.git" + Var("http_tag"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      Var("github_mirror") + "http_multi_server.git" +
      Var("http_multi_server_tag"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      Var("github_mirror") + "http_parser.git" + Var("http_parser_tag"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      Var("github_mirror") + "http_throttle.git" +
      Var("http_throttle_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      Var("github_mirror") + "intl.git" + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/isolate":
      Var("github_mirror") + "isolate.git" + Var("isolate_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      Var("github_mirror") + "json_rpc_2.git" + Var("json_rpc_2_tag"),
  Var("dart_root") + "/third_party/pkg/linter":
      Var("github_mirror") + "linter.git" + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      Var("github_mirror") + "logging.git" + Var("logging_tag"),
  Var("dart_root") + "/third_party/pkg/markdown":
      Var("github_mirror") + "markdown.git" + Var("markdown_tag"),
  Var("dart_root") + "/third_party/pkg/matcher":
      Var("github_mirror") + "matcher.git" + Var("matcher_tag"),
  Var("dart_root") + "/third_party/pkg/mime":
      Var("github_mirror") + "mime.git" + Var("mime_rev"),
  Var("dart_root") + "/third_party/pkg/mockito":
      Var("github_mirror") + "mockito.git" + Var("mockito_tag"),
  Var("dart_root") + "/third_party/pkg/mustache4dart":
      Var("chromium_git")
      + "/external/github.com/valotas/mustache4dart.git"
      + Var("mustache4dart_tag"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      Var("github_mirror") + "oauth2.git" + Var("oauth2_tag"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
      Var("github_mirror") + "observatory_pub_packages.git"
      + Var("observatory_pub_packages_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      Var("github_mirror") + "package_config.git" +
      Var("package_config_tag"),
  Var("dart_root") + "/third_party/pkg_tested/package_resolver":
      Var("github_mirror") + "package_resolver.git"
      + Var("package_resolver_tag"),
  Var("dart_root") + "/third_party/pkg/path":
      Var("github_mirror") + "path.git" + Var("path_tag"),
  Var("dart_root") + "/third_party/pkg/plugin":
      Var("github_mirror") + "plugin.git" + Var("plugin_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      Var("github_mirror") + "pool.git" + Var("pool_tag"),
  Var("dart_root") + "/third_party/pkg/protobuf":
      Var("github_mirror") + "protobuf.git" + Var("protobuf_tag"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      Var("github_mirror") + "pub_semver.git" + Var("pub_semver_tag"),
  Var("dart_root") + "/third_party/pkg/pub":
      Var("github_mirror") + "pub.git" + Var("pub_rev"),
  Var("dart_root") + "/third_party/pkg/quiver":
      Var("chromium_git")
      + "/external/github.com/google/quiver-dart.git"
      + Var("quiver_tag"),
  Var("dart_root") + "/third_party/pkg/resource":
      Var("github_mirror") + "resource.git" + Var("resource_rev"),
  Var("dart_root") + "/third_party/pkg/scheduled_test":
      Var("github_mirror") + "scheduled_test.git" + Var("scheduled_test_tag"),
  Var("dart_root") + "/third_party/pkg/shelf":
      Var("github_mirror") + "shelf.git" + Var("shelf_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_packages_handler":
      Var("github_mirror") + "shelf_packages_handler.git"
      + Var("shelf_packages_handler_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      Var("github_mirror") + "shelf_static.git" + Var("shelf_static_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      Var("github_mirror") + "shelf_web_socket.git" +
      Var("shelf_web_socket_tag"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      Var("github_mirror") + "source_maps.git" + Var("source_maps_tag"),
  Var("dart_root") + "/third_party/pkg/source_span":
      Var("github_mirror") + "source_span.git" + Var("source_span_tag"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      Var("github_mirror") + "source_map_stack_trace.git" +
      Var("source_map_stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      Var("github_mirror") + "stack_trace.git" + Var("stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stream_channel":
      Var("github_mirror") + "stream_channel.git" +
      Var("stream_channel_tag"),
  Var("dart_root") + "/third_party/pkg/string_scanner":
      Var("github_mirror") + "string_scanner.git" +
      Var("string_scanner_tag"),
  Var("dart_root") + "/third_party/sunflower":
      Var("github_mirror") + "sample-sunflower.git" +
      Var("sunflower_rev"),
  Var("dart_root") + "/third_party/pkg/term_glyph":
      Var("github_mirror") + "term_glyph.git" + Var("term_glyph_tag"),
  Var("dart_root") + "/third_party/pkg/test":
      Var("github_mirror") + "test.git" + Var("test_tag"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      Var("github_mirror") + "test_reflective_loader.git" +
      Var("test_reflective_loader_tag"),
  Var("dart_root") + "/third_party/pkg/tuple":
      Var("github_mirror") + "tuple.git" + Var("tuple_tag"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      Var("github_mirror") + "typed_data.git" + Var("typed_data_tag"),
  Var("dart_root") + "/third_party/pkg/usage":
      Var("github_mirror") + "usage.git" + Var("usage_tag"),
  Var("dart_root") + "/third_party/pkg/utf":
      Var("github_mirror") + "utf.git" + Var("utf_tag"),
  Var("dart_root") + "/third_party/pkg/watcher":
      Var("github_mirror") + "watcher.git" + Var("watcher_tag"),
  Var("dart_root") + "/third_party/pkg/web_socket_channel":
      Var("github_mirror") + "web_socket_channel.git" +
      Var("web_socket_channel_tag"),
  Var("dart_root") + "/third_party/pkg/yaml":
      Var("github_mirror") + "yaml.git" + Var("yaml_tag"),
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
