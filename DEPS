# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# IMPORTANT:
# Before adding or updating dependencies, please review the documentation here:
# https://github.com/dart-lang/sdk/wiki/Adding-and-Updating-Dependencies

allowed_hosts = [
  'boringssl.googlesource.com',
  'chromium.googlesource.com',
  'dart.googlesource.com',
  'fuchsia.googlesource.com',
]

vars = {
  # The dart_root is the root of our sdk checkout. This is normally
  # simply sdk, but if using special gclient specs it can be different.
  "dart_root": "sdk",

  # We use mirrors of all github repos to guarantee reproducibility and
  # consistency between what users see and what the bots see.
  # We need the mirrors to not have 100+ bots pulling github constantly.
  # We mirror our github repos on Dart's git servers.
  # DO NOT use this var if you don't see a mirror here:
  #   https://dart.googlesource.com/
  "dart_git":
      "https://dart.googlesource.com/",
  # If the repo you want to use is at github.com/dart-lang, but not at
  # dart.googlesource.com, please file an issue
  # on github and add the label 'area-infrastructure'.
  # When the repo is mirrored, you can add it to this DEPS file.

  # Chromium git
  "chromium_git": "https://chromium.googlesource.com",
  "fuchsia_git": "https://fuchsia.googlesource.com",

  "co19_rev": "@d4b3fc9af414c990b4d22f313e533b275d2f27c5",
  "co19_2_rev": "@74562e984a81673b581e148b5802684d6df840d2",

  # As Flutter does, we pull buildtools, including the clang toolchain, from
  # Fuchsia. This revision should be kept up to date with the revision pulled
  # by the Flutter engine. If there are problems with the toolchain, contact
  # fuchsia-toolchain@.
  "buildtools_revision": "@de2d6da936fa0be8bcb0bacd096fe124efff2854",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "@c09c8deeac31f05bd801995c475e7c8070f9ecda",

  "gperftools_revision": "@02eeed29df112728564a5dde6417fa4622b57a06",

  # Revisions of /third_party/* dependencies.
  "args_tag": "@0.13.7",
  "async_tag": "@2.0.4",
  "barback-0.13.0_rev": "@34853",
  "barback-0.14.0_rev": "@36398",
  "barback-0.14.1_rev": "@38525",
  "barback_tag" : "@0.15.2+14",
  "bazel_worker_tag": "@v0.1.9",
  "boolean_selector_tag" : "@1.0.2",
  "boringssl_gen_rev": "@39762c7f9ee4d828ff212838fae79528b94d5443",
  "boringssl_rev" : "@a62dbf88d8a3c04446db833a1eb80a620cb1514d",
  "charcode_tag": "@v1.1.1",
  "chrome_rev" : "@19997",
  "cli_util_tag" : "@0.1.2+1",
  "collection_tag": "@1.14.5",
  "convert_tag": "@2.0.1",
  "crypto_tag" : "@2.0.2+1",
  "csslib_tag" : "@0.14.1",
  "dart2js_info_tag" : "@0.5.5+1",

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
  "dart_style_tag": "@1.0.10",  # Please see the note above before updating.

  "dartdoc_tag" : "@v0.17.0",
  "fixnum_tag": "@0.10.5",
  "func_rev": "@25eec48146a58967d75330075ab376b3838b18a8",
  "glob_tag": "@1.1.5",
  "html_tag" : "@0.13.2+2",
  "http_io_tag": "@35dc43c9144cf7ed4236843dacd62ebaf89df21a",
  "http_multi_server_tag" : "@2.0.4",
  "http_parser_tag" : "@3.1.1",
  "http_retry_tag": "@0.1.0",
  "http_tag" : "@0.11.3+14",
  "http_throttle_tag" : "@1.0.1",
  "idl_parser_rev": "@7fbe68cab90c38147dee4f48c30ad0d496c17915",
  "intl_tag": "@0.15.2",
  "isolate_tag": "@1.1.0",
  "jinja2_rev": "@2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_tag": "@2.0.6",
  "linter_tag": "@0.1.43",
  "logging_tag": "@0.11.3+1",
  "markdown_tag": "@1.0.0",
  "matcher_tag": "@0.12.1+4",
  "mime_tag": "@0.9.6",
  "mockito_tag": "@a92db054fba18bc2d605be7670aee74b7cadc00a",
  "mustache4dart_tag" : "@v2.1.0",
  "oauth2_tag": "@1.1.0",
  "observatory_pub_packages_rev": "@4c282bb240b68f407c8c7779a65c68eeb0139dc6",
  "package_config_tag": "@1.0.3",
  "package_resolver_tag": "@1.0.2+1",
  "path_tag": "@1.5.1",
  "plugin_tag": "@0.2.0+2",
  "ply_rev": "@604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_tag": "@1.3.4",
  "protobuf_tag": "@0.7.0",
  "pub_rev": "@73ff0d3d9f80f60d41e3135ac44597d011abb4f3",
  "pub_semver_tag": "@1.3.2",
  "quiver_tag": "@0.28.0",
  "resource_rev":"@af5a5bf65511943398146cf146e466e5f0b95cb9",
  "root_certificates_rev": "@16ef64be64c7dfdff2b9f4b910726e635ccc519e",
  "shelf_static_rev": "@3558aa35a0d2f0f35868c3fd64b258e140db0122",
  "shelf_packages_handler_tag": "@1.0.3",
  "shelf_tag": "@0.7.1",
  "shelf_web_socket_tag": "@0.2.2",
  "source_map_stack_trace_tag": "@1.1.4",
  "source_maps-0.9.4_rev": "@38524",
  "source_maps_tag": "@0.10.4",
  "source_span_tag": "@1.4.0",
  "stack_trace_tag": "@1.9.0",
  "stream_channel_tag": "@1.6.2",
  "string_scanner_tag": "@1.0.2",
  "sunflower_rev": "@879b704933413414679396b129f5dfa96f7a0b1e",
  "test_descriptor_tag": "@1.0.3",
  "test_process_tag": "@1.0.1",
  "term_glyph_tag": "@1.0.0",
  "test_reflective_loader_tag": "@0.1.3",
  "test_tag": "@0.12.30+1",
  "tuple_tag": "@v1.0.1",
  "typed_data_tag": "@1.1.3",
  "usage_tag": "@3.3.0",
  "utf_tag": "@0.9.0+4",
  "watcher_tag": "@0.9.7+7",
  "web_socket_channel_tag": "@1.0.7",
  "WebCore_rev": "@3c45690813c112373757bbef53de1602a62af609",
  "yaml_tag": "@2.1.13",
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
      Var("dart_git") + "co19.git" + Var("co19_rev"),

Var("dart_root") + "/tests/co19_2/src":
      Var("chromium_git") + "/external/github.com/dart-lang/co19.git" +
      Var("co19_2_rev"),

  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      Var("zlib_rev"),

  Var("dart_root") + "/third_party/boringssl":
      Var("dart_git") + "boringssl_gen.git" + Var("boringssl_gen_rev"),
  Var("dart_root") + "/third_party/boringssl/src":
      "https://boringssl.googlesource.com/boringssl.git" +
      Var("boringssl_rev"),

  Var("dart_root") + "/third_party/root_certificates":
      Var("dart_git") + "root_certificates.git" +
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
      Var("dart_git") + "webcore.git" + Var("WebCore_rev"),

  Var("dart_root") + "/third_party/tcmalloc/gperftools":
      Var('chromium_git') + '/external/github.com/gperftools/gperftools.git' +
      Var("gperftools_revision"),

  Var("dart_root") + "/third_party/pkg/args":
      Var("dart_git") + "args.git" + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async":
      Var("dart_git") + "async.git" + Var("async_tag"),
  Var("dart_root") + "/third_party/pkg/barback":
      Var("dart_git") + "barback.git" + Var("barback_tag"),
  Var("dart_root") + "/third_party/pkg/bazel_worker":
      Var("dart_git") + "bazel_worker.git" + Var("bazel_worker_tag"),
  Var("dart_root") + "/third_party/pkg/boolean_selector":
      Var("dart_git") + "boolean_selector.git" +
      Var("boolean_selector_tag"),
  Var("dart_root") + "/third_party/pkg/charcode":
      Var("dart_git") + "charcode.git" + Var("charcode_tag"),
  Var("dart_root") + "/third_party/pkg/cli_util":
      Var("dart_git") + "cli_util.git" + Var("cli_util_tag"),
  Var("dart_root") + "/third_party/pkg/collection":
      Var("dart_git") + "collection.git" + Var("collection_tag"),
  Var("dart_root") + "/third_party/pkg/convert":
      Var("dart_git") + "convert.git" + Var("convert_tag"),
  Var("dart_root") + "/third_party/pkg/crypto":
      Var("dart_git") + "crypto.git" + Var("crypto_tag"),
  Var("dart_root") + "/third_party/pkg/csslib":
      Var("dart_git") + "csslib.git" + Var("csslib_tag"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      Var("dart_git") + "dart_style.git" + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      Var("dart_git") + "dart2js_info.git" + Var("dart2js_info_tag"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      Var("dart_git") + "dartdoc.git" + Var("dartdoc_tag"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      Var("dart_git") + "fixnum.git" + Var("fixnum_tag"),
  Var("dart_root") + "/third_party/pkg/func":
      Var("dart_git") + "func.git" + Var("func_rev"),
  Var("dart_root") + "/third_party/pkg/glob":
      Var("dart_git") + "glob.git" + Var("glob_tag"),
  Var("dart_root") + "/third_party/pkg/html":
      Var("dart_git") + "html.git" + Var("html_tag"),
  Var("dart_root") + "/third_party/pkg/http":
      Var("dart_git") + "http.git" + Var("http_tag"),
  Var("dart_root") + "/third_party/pkg_tested/http_io":
    Var("dart_git") + "http_io.git" + Var("http_io_tag"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      Var("dart_git") + "http_multi_server.git" +
      Var("http_multi_server_tag"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      Var("dart_git") + "http_parser.git" + Var("http_parser_tag"),
  Var("dart_root") + "/third_party/pkg/http_retry":
      Var("dart_git") + "http_retry.git" +
      Var("http_retry_tag"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      Var("dart_git") + "http_throttle.git" +
      Var("http_throttle_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      Var("dart_git") + "intl.git" + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/isolate":
      Var("dart_git") + "isolate.git" + Var("isolate_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      Var("dart_git") + "json_rpc_2.git" + Var("json_rpc_2_tag"),
  Var("dart_root") + "/third_party/pkg/linter":
      Var("dart_git") + "linter.git" + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      Var("dart_git") + "logging.git" + Var("logging_tag"),
  Var("dart_root") + "/third_party/pkg/markdown":
      Var("dart_git") + "markdown.git" + Var("markdown_tag"),
  Var("dart_root") + "/third_party/pkg/matcher":
      Var("dart_git") + "matcher.git" + Var("matcher_tag"),
  Var("dart_root") + "/third_party/pkg/mime":
      Var("dart_git") + "mime.git" + Var("mime_tag"),
  Var("dart_root") + "/third_party/pkg/mockito":
      Var("dart_git") + "mockito.git" + Var("mockito_tag"),
  Var("dart_root") + "/third_party/pkg/mustache4dart":
      Var("chromium_git")
      + "/external/github.com/valotas/mustache4dart.git"
      + Var("mustache4dart_tag"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      Var("dart_git") + "oauth2.git" + Var("oauth2_tag"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
      Var("dart_git") + "observatory_pub_packages.git"
      + Var("observatory_pub_packages_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      Var("dart_git") + "package_config.git" +
      Var("package_config_tag"),
  Var("dart_root") + "/third_party/pkg_tested/package_resolver":
      Var("dart_git") + "package_resolver.git"
      + Var("package_resolver_tag"),
  Var("dart_root") + "/third_party/pkg/path":
      Var("dart_git") + "path.git" + Var("path_tag"),
  Var("dart_root") + "/third_party/pkg/plugin":
      Var("dart_git") + "plugin.git" + Var("plugin_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      Var("dart_git") + "pool.git" + Var("pool_tag"),
  Var("dart_root") + "/third_party/pkg/protobuf":
      Var("dart_git") + "protobuf.git" + Var("protobuf_tag"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      Var("dart_git") + "pub_semver.git" + Var("pub_semver_tag"),
  Var("dart_root") + "/third_party/pkg/pub":
      Var("dart_git") + "pub.git" + Var("pub_rev"),
  Var("dart_root") + "/third_party/pkg/quiver":
      Var("chromium_git")
      + "/external/github.com/google/quiver-dart.git"
      + Var("quiver_tag"),
  Var("dart_root") + "/third_party/pkg/resource":
      Var("dart_git") + "resource.git" + Var("resource_rev"),
  Var("dart_root") + "/third_party/pkg/shelf":
      Var("dart_git") + "shelf.git" + Var("shelf_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_packages_handler":
      Var("dart_git") + "shelf_packages_handler.git"
      + Var("shelf_packages_handler_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      Var("dart_git") + "shelf_static.git" + Var("shelf_static_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      Var("dart_git") + "shelf_web_socket.git" +
      Var("shelf_web_socket_tag"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      Var("dart_git") + "source_maps.git" + Var("source_maps_tag"),
  Var("dart_root") + "/third_party/pkg/source_span":
      Var("dart_git") + "source_span.git" + Var("source_span_tag"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      Var("dart_git") + "source_map_stack_trace.git" +
      Var("source_map_stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      Var("dart_git") + "stack_trace.git" + Var("stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stream_channel":
      Var("dart_git") + "stream_channel.git" +
      Var("stream_channel_tag"),
  Var("dart_root") + "/third_party/pkg/string_scanner":
      Var("dart_git") + "string_scanner.git" +
      Var("string_scanner_tag"),
  Var("dart_root") + "/third_party/sunflower":
      Var("chromium_git") +
      "/external/github.com/dart-lang/sample-sunflower.git" +
      Var("sunflower_rev"),
  Var("dart_root") + "/third_party/pkg/term_glyph":
      Var("dart_git") + "term_glyph.git" + Var("term_glyph_tag"),
  Var("dart_root") + "/third_party/pkg/test":
      Var("dart_git") + "test.git" + Var("test_tag"),
  Var("dart_root") + "/third_party/pkg/test_descriptor":
      Var("dart_git") + "test_descriptor.git" + Var("test_descriptor_tag"),
  Var("dart_root") + "/third_party/pkg/test_process":
      Var("dart_git") + "test_process.git" + Var("test_process_tag"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      Var("dart_git") + "test_reflective_loader.git" +
      Var("test_reflective_loader_tag"),
  Var("dart_root") + "/third_party/pkg/tuple":
      Var("dart_git") + "tuple.git" + Var("tuple_tag"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      Var("dart_git") + "typed_data.git" + Var("typed_data_tag"),
  Var("dart_root") + "/third_party/pkg/usage":
      Var("dart_git") + "usage.git" + Var("usage_tag"),
  Var("dart_root") + "/third_party/pkg/utf":
      Var("dart_git") + "utf.git" + Var("utf_tag"),
  Var("dart_root") + "/third_party/pkg/watcher":
      Var("dart_git") + "watcher.git" + Var("watcher_tag"),
  Var("dart_root") + "/third_party/pkg/web_socket_channel":
      Var("dart_git") + "web_socket_channel.git" +
      Var("web_socket_channel_tag"),
  Var("dart_root") + "/third_party/pkg/yaml":
      Var("dart_git") + "yaml.git" + Var("yaml_tag"),
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
               '--arch', 'i386'],
  },
  {
    # Pull Debian wheezy sysroot for amd64 Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'amd64'],
  },
  {
    # Pull Debian wheezy sysroot for arm Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'arm'],
  },
  {
    # Pull Debian jessie sysroot for arm64 Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'arm64'],
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
