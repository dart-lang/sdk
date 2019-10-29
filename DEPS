# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# IMPORTANT:
# Before adding or updating dependencies, please review the documentation here:
# https://github.com/dart-lang/sdk/wiki/Adding-and-Updating-Dependencies

allowed_hosts = [
  'boringssl.googlesource.com',
  'chrome-infra-packages.appspot.com',
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

  # co19 is a cipd package. Use tests/co19_2/update.sh to update this hash.
  # It requires access to the dart-build-access group, which EngProd has.
  "co19_2_rev": "a8f7aa15ab860a309667168243bda01fda0794df",

  # As Flutter does, we use Fuchsia's GN and Clang toolchain. These revision
  # should be kept up to date with the revisions pulled by the Flutter engine.
  # The list of revisions for these tools comes from Fuchsia, here:
  # https://fuchsia.googlesource.com/buildtools/+/master/fuchsia.ensure
  # If there are problems with the toolchain, contact fuchsia-toolchain@.
  "clang_revision": "de39621f0f03f20633bdfa50bde97a3908bf6e98",
  "gn_revision": "bdb0fd02324b120cacde634a9235405061c8ea06",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "c09c8deeac31f05bd801995c475e7c8070f9ecda",

  "gperftools_revision": "e9ab4c53041ac62feefbbb076d326e9a77dd1567",

  # Revisions of /third_party/* dependencies.
  "args_tag": "1.5.0",
  "async_tag": "2.0.8",
  "bazel_worker_tag": "v0.1.22",
  "benchmark_harness_tag": "81641290dea44c34138a109a37e215482f405f81",
  "boolean_selector_tag" : "1.0.4",
  "boringssl_gen_rev": "b9e27cff1ff0803e97ab1f88764a83be4aa94a6d",
  "boringssl_rev" : "4dfd5af70191b068aebe567b8e29ce108cee85ce",
  "charcode_tag": "v1.1.2",
  "chrome_rev" : "19997",
  "cli_util_rev" : "4ad7ccbe3195fd2583b30f86a86697ef61e80f41",
  "collection_tag": "1.14.11",
  "convert_tag": "2.0.2",
  "crypto_tag" : "2.0.6",
  "csslib_tag" : "0.15.0",
  "dart2js_info_tag" : "0.6.0",

  # Note: Updates to dart_style have to be coordinated with the infrastructure
  # team so that the internal formatter in `tools/sdks/dart-sdk/bin/dartfmt`
  # matches the version here.
  #
  # Please follow this process to make updates:
  #
  # *   Create a commit that updates the version here to the desired version and
  #     adds any appropriate CHANGELOG text.
  # *   Send that to eng-prod to review. They will update the checked-in SDK
  #     and land the review.
  #
  # For more details, see https://github.com/dart-lang/sdk/issues/30164
  "dart_style_tag": "1.3.2",  # Please see the note above before updating.

  "args_tag" : "1.5.2",
  "dartdoc_tag" : "v0.28.8",
  "ffi_tag": "ea88d71b043ee14b268c3aedff14e9eb32e20959",
  "fixnum_tag": "0.10.9",
  "glob_tag": "1.1.7",
  "html_tag" : "0.14.0+1",
  "http_io_rev": "2fa188caf7937e313026557713f7feffedd4978b",
  "http_multi_server_tag" : "2.0.5",
  "http_parser_tag" : "3.1.3",
  "http_retry_tag": "0.1.1",
  "http_tag" : "0.12.0+2",
  "http_throttle_tag" : "1.0.2",
  "icu_rev" : "c56c671998902fcc4fc9ace88c83daa99f980793",
  "idl_parser_rev": "5fb1ebf49d235b5a70c9f49047e83b0654031eb7",
  "intl_tag": "0.15.7",
  "jinja2_rev": "2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_tag": "2.0.9",
  "linter_tag": "0.1.101",
  "logging_tag": "0.11.3+2",
  "markupsafe_rev": "8f45f5cfa0009d2a70589bcda0349b8cb2b72783",
  "markdown_tag": "2.1.1",
  "matcher_tag": "0.12.3",
  "mime_tag": "0.9.6+2",
  "mockito_tag": "d39ac507483b9891165e422ec98d9fb480037c8b",
  "mustache_tag" : "5e81b12215566dbe2473b2afd01a8a8aedd56ad9",
  "oauth2_tag": "1.2.1",
  "observatory_pub_packages_rev": "0894122173b0f98eb08863a7712e78407d4477bc",
  "package_config_tag": "2453cd2e78c2db56ee2669ced17ce70dd00bf576", # should be 1.1.0
  "package_resolver_tag": "1.0.10",
  "path_tag": "1.6.2",
  "pedantic_tag": "v1.8.0",
  "ply_rev": "604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_tag": "1.3.6",
  "protobuf_rev": "3746c8fd3f2b0147623a8e3db89c3ff4330de760",
  "pub_rev": "80ac76400ff58fde3c5a335d860d196c3febe837",
  "pub_semver_tag": "1.4.2",
  "quiver-dart_tag": "2.0.0+1",
  "resource_rev": "f8e37558a1c4f54550aa463b88a6a831e3e33cd6",
  "root_certificates_rev": "16ef64be64c7dfdff2b9f4b910726e635ccc519e",
  "rust_revision": "60960a260f7b5c695fd0717311d72ce62dd4eb43",
  "shelf_static_rev": "v0.2.8",
  "shelf_packages_handler_tag": "1.0.4",
  "shelf_tag": "0.7.3+3",
  "shelf_web_socket_tag": "0.2.2+3",
  "source_map_stack_trace_tag": "1.1.5",
  "source_maps-0.9.4_rev": "38524",
  "source_maps_tag": "8af7cc1a1c3a193c1fba5993ce22a546a319c40e",
  "source_span_tag": "1.5.5",
  "stack_trace_tag": "1.9.3",
  "stream_channel_tag": "2.0.0",
  "string_scanner_tag": "1.0.3",
  "test_descriptor_tag": "1.1.1",
  "test_process_tag": "1.0.3",
  "term_glyph_tag": "1.0.1",
  "test_reflective_loader_tag": "0.1.9",
  "test_tag": "test-v1.6.4",
  "tflite_native_rev": "3c777c40608a2a9f1427bfe0028ab48e7116b4c1",
  "typed_data_tag": "1.1.6",
  "unittest_rev": "2b8375bc98bb9dc81c539c91aaea6adce12e1072",
  "usage_tag": "3.4.0",
  "watcher_rev": "0.9.7+12-pub",
  "web_components_rev": "8f57dac273412a7172c8ade6f361b407e2e4ed02",
  "web_socket_channel_tag": "1.0.9",
  "WebCore_rev": "fb11e887f77919450e497344da570d780e078bc8",
  "yaml_tag": "2.2.0",
  "zlib_rev": "c44fb7248079cc3d5563b14b3f758aee60d6b415",
  "crashpad_rev": "bf327d8ceb6a669607b0dbab5a83a275d03f99ed",
  "minichromium_rev": "8d641e30a8b12088649606b912c2bc4947419ccc",
  "googletest_rev": "f854f1d27488996dc8a6db3c9453f80b02585e12",

  # An LLVM backend needs LLVM binaries and headers. To avoid build time
  # increases we can use prebuilts. We don't want to download this on every
  # CQ/CI bot nor do we want the average Dart developer to incur that cost.
  # So by default we will not download prebuilts.
  "checkout_llvm": False,
  "llvm_revision": "fe8bd96ebd6c490ea0b5c1fb342db2d7c393a109"
}

gclient_gn_args_file = Var("dart_root") + '/build/config/gclient_args.gni'
gclient_gn_args = [
  'checkout_llvm'
]

deps = {
  # Stuff needed for GN build.
  Var("dart_root") + "/buildtools/clang_format/script":
    Var("chromium_git") + "/chromium/llvm-project/cfe/tools/clang-format.git" +
    "@" + Var("clang_format_scripts_rev"),

  Var("dart_root") + "/tools/sdks": {
      "packages": [{
          "package": "dart/dart-sdk/${{platform}}",
          "version": "version:2.6.0-dev.4.0",
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/d8": {
      "packages": [{
          "package": "dart/d8",
          "version": "version:7.5.149",
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/tests/co19_2/src": {
      "packages": [{
          "package": "dart/third_party/co19",
          "version": "git_revision:" + Var("co19_2_rev"),
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/markupsafe":
      Var("chromium_git") + "/chromium/src/third_party/markupsafe.git" +
      "@" + Var("markupsafe_rev"),
  Var("dart_root") + "/third_party/babel": {
      "packages": [{
          "package": "dart/third_party/babel",
          "version": "version:7.4.5",
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      "@" + Var("zlib_rev"),

  Var("dart_root") + "/third_party/boringssl":
      Var("dart_git") + "boringssl_gen.git" + "@" + Var("boringssl_gen_rev"),
  Var("dart_root") + "/third_party/boringssl/src":
      "https://boringssl.googlesource.com/boringssl.git" +
      "@" + Var("boringssl_rev"),

  Var("dart_root") + "/third_party/gsutil": {
      "packages": [{
          "package": "infra/gsutil",
          "version": "version:4.34",
      }],
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/root_certificates":
      Var("dart_git") + "root_certificates.git" +
      "@" + Var("root_certificates_rev"),

  Var("dart_root") + "/third_party/jinja2":
      Var("chromium_git") + "/chromium/src/third_party/jinja2.git" +
      "@" + Var("jinja2_rev"),

  Var("dart_root") + "/third_party/ply":
      Var("chromium_git") + "/chromium/src/third_party/ply.git" +
      "@" + Var("ply_rev"),

  Var("dart_root") + "/third_party/icu":
      Var("chromium_git") + "/chromium/deps/icu.git" +
      "@" + Var("icu_rev"),

  Var("dart_root") + "/tools/idl_parser":
      Var("chromium_git") + "/chromium/src/tools/idl_parser.git" +
      "@" + Var("idl_parser_rev"),

  Var("dart_root") + "/third_party/WebCore":
      Var("dart_git") + "webcore.git" + "@" + Var("WebCore_rev"),

  Var("dart_root") + "/third_party/tcmalloc/gperftools":
      Var('chromium_git') + '/external/github.com/gperftools/gperftools.git' +
      "@" + Var("gperftools_revision"),

  Var("dart_root") + "/third_party/pkg/args":
      Var("dart_git") + "args.git" + "@" + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async":
      Var("dart_git") + "async.git" + "@" + Var("async_tag"),
  Var("dart_root") + "/third_party/pkg/bazel_worker":
      Var("dart_git") + "bazel_worker.git" + "@" + Var("bazel_worker_tag"),
  Var("dart_root") + "/third_party/pkg/benchmark_harness":
      Var("dart_git") + "benchmark_harness.git" + "@" +
      Var("benchmark_harness_tag"),
  Var("dart_root") + "/third_party/pkg/boolean_selector":
      Var("dart_git") + "boolean_selector.git" +
      "@" + Var("boolean_selector_tag"),
  Var("dart_root") + "/third_party/pkg/charcode":
      Var("dart_git") + "charcode.git" + "@" + Var("charcode_tag"),
  Var("dart_root") + "/third_party/pkg/cli_util":
      Var("dart_git") + "cli_util.git" + "@" + Var("cli_util_rev"),
  Var("dart_root") + "/third_party/pkg/collection":
      Var("dart_git") + "collection.git" + "@" + Var("collection_tag"),
  Var("dart_root") + "/third_party/pkg/convert":
      Var("dart_git") + "convert.git" + "@" + Var("convert_tag"),
  Var("dart_root") + "/third_party/pkg/crypto":
      Var("dart_git") + "crypto.git" + "@" + Var("crypto_tag"),
  Var("dart_root") + "/third_party/pkg/csslib":
      Var("dart_git") + "csslib.git" + "@" + Var("csslib_tag"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      Var("dart_git") + "dart_style.git" + "@" + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      Var("dart_git") + "dart2js_info.git" + "@" + Var("dart2js_info_tag"),
  Var("dart_root") + "/third_party/pkg/args":
      Var("dart_git") + "args.git" + "@" + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      Var("dart_git") + "dartdoc.git" + "@" + Var("dartdoc_tag"),
  Var("dart_root") + "/third_party/pkg/ffi":
      Var("dart_git") + "ffi.git" + "@" + Var("ffi_tag"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      Var("dart_git") + "fixnum.git" + "@" + Var("fixnum_tag"),
  Var("dart_root") + "/third_party/pkg/glob":
      Var("dart_git") + "glob.git" + "@" + Var("glob_tag"),
  Var("dart_root") + "/third_party/pkg/html":
      Var("dart_git") + "html.git" + "@" + Var("html_tag"),
  Var("dart_root") + "/third_party/pkg/http":
      Var("dart_git") + "http.git" + "@" + Var("http_tag"),
  Var("dart_root") + "/third_party/pkg_tested/http_io":
    Var("dart_git") + "http_io.git" + "@" + Var("http_io_rev"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      Var("dart_git") + "http_multi_server.git" +
      "@" + Var("http_multi_server_tag"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      Var("dart_git") + "http_parser.git" + "@" + Var("http_parser_tag"),
  Var("dart_root") + "/third_party/pkg/http_retry":
      Var("dart_git") + "http_retry.git" +
      "@" + Var("http_retry_tag"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      Var("dart_git") + "http_throttle.git" +
      "@" + Var("http_throttle_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      Var("dart_git") + "intl.git" + "@" + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      Var("dart_git") + "json_rpc_2.git" + "@" + Var("json_rpc_2_tag"),
  Var("dart_root") + "/third_party/pkg/linter":
      Var("dart_git") + "linter.git" + "@" + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      Var("dart_git") + "logging.git" + "@" + Var("logging_tag"),
  Var("dart_root") + "/third_party/pkg/markdown":
      Var("dart_git") + "markdown.git" + "@" + Var("markdown_tag"),
  Var("dart_root") + "/third_party/pkg/matcher":
      Var("dart_git") + "matcher.git" + "@" + Var("matcher_tag"),
  Var("dart_root") + "/third_party/pkg/mime":
      Var("dart_git") + "mime.git" + "@" + Var("mime_tag"),
  Var("dart_root") + "/third_party/pkg/mockito":
      Var("dart_git") + "mockito.git" + "@" + Var("mockito_tag"),
  Var("dart_root") + "/third_party/pkg/mustache":
      Var("dart_git")
      + "external/github.com/xxgreg/mustache"
      + "@" + Var("mustache_tag"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      Var("dart_git") + "oauth2.git" + "@" + Var("oauth2_tag"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
      Var("dart_git") + "observatory_pub_packages.git"
      + "@" + Var("observatory_pub_packages_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      Var("dart_git") + "package_config.git" +
      "@" + Var("package_config_tag"),
  Var("dart_root") + "/third_party/pkg_tested/package_resolver":
      Var("dart_git") + "package_resolver.git"
      + "@" + Var("package_resolver_tag"),
  Var("dart_root") + "/third_party/pkg/path":
      Var("dart_git") + "path.git" + "@" + Var("path_tag"),
  Var("dart_root") + "/third_party/pkg/pedantic":
      Var("dart_git") + "pedantic.git" + "@" + Var("pedantic_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      Var("dart_git") + "pool.git" + "@" + Var("pool_tag"),
  Var("dart_root") + "/third_party/pkg/protobuf":
       Var("dart_git") + "protobuf.git" + "@" + Var("protobuf_rev"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      Var("dart_git") + "pub_semver.git" + "@" + Var("pub_semver_tag"),
  Var("dart_root") + "/third_party/pkg/pub":
      Var("dart_git") + "pub.git" + "@" + Var("pub_rev"),
  Var("dart_root") + "/third_party/pkg/quiver":
      Var("chromium_git")
      + "/external/github.com/google/quiver-dart.git"
      + "@" + Var("quiver-dart_tag"),
  Var("dart_root") + "/third_party/pkg/resource":
      Var("dart_git") + "resource.git" + "@" + Var("resource_rev"),
  Var("dart_root") + "/third_party/pkg/shelf":
      Var("dart_git") + "shelf.git" + "@" + Var("shelf_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_packages_handler":
      Var("dart_git") + "shelf_packages_handler.git"
      + "@" + Var("shelf_packages_handler_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      Var("dart_git") + "shelf_static.git" + "@" + Var("shelf_static_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      Var("dart_git") + "shelf_web_socket.git" +
      "@" + Var("shelf_web_socket_tag"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      Var("dart_git") + "source_maps.git" + "@" + Var("source_maps_tag"),
  Var("dart_root") + "/third_party/pkg/source_span":
      Var("dart_git") + "source_span.git" + "@" + Var("source_span_tag"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      Var("dart_git") + "source_map_stack_trace.git" +
      "@" + Var("source_map_stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      Var("dart_git") + "stack_trace.git" + "@" + Var("stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stream_channel":
      Var("dart_git") + "stream_channel.git" +
      "@" + Var("stream_channel_tag"),
  Var("dart_root") + "/third_party/pkg/string_scanner":
      Var("dart_git") + "string_scanner.git" +
      "@" + Var("string_scanner_tag"),
  Var("dart_root") + "/third_party/pkg/term_glyph":
      Var("dart_git") + "term_glyph.git" + "@" + Var("term_glyph_tag"),
  Var("dart_root") + "/third_party/pkg/test":
      Var("dart_git") + "test.git" + "@" + Var("test_tag"),
  Var("dart_root") + "/third_party/pkg/tflite_native":
      Var("dart_git") + "tflite_native.git" + "@" + Var("tflite_native_rev"),
  Var("dart_root") + "/third_party/pkg/test_descriptor":
      Var("dart_git") + "test_descriptor.git" + "@" + Var("test_descriptor_tag"),
  Var("dart_root") + "/third_party/pkg/test_process":
      Var("dart_git") + "test_process.git" + "@" + Var("test_process_tag"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      Var("dart_git") + "test_reflective_loader.git" +
      "@" + Var("test_reflective_loader_tag"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      Var("dart_git") + "typed_data.git" + "@" + Var("typed_data_tag"),
  # Unittest is an early version, 0.11.x, of the package "test"
  # Do not use it in any new tests. Fetched from chromium_git to avoid
  # race condition in cache with pkg/test.
  Var("dart_root") + "/third_party/pkg/unittest":
      Var("chromium_git") + "/external/github.com/dart-lang/test.git" +
      "@" + Var("unittest_rev"),
  Var("dart_root") + "/third_party/pkg/usage":
      Var("dart_git") + "usage.git" + "@" + Var("usage_tag"),
  Var("dart_root") + "/third_party/pkg/watcher":
      Var("dart_git") + "watcher.git" + "@" + Var("watcher_rev"),
  Var("dart_root") + "/third_party/pkg/web_components":
      Var("dart_git") + "web-components.git" +
      "@" + Var("web_components_rev"),
  Var("dart_root") + "/third_party/pkg/web_socket_channel":
      Var("dart_git") + "web_socket_channel.git" +
      "@" + Var("web_socket_channel_tag"),
  Var("dart_root") + "/third_party/pkg/yaml":
      Var("dart_git") + "yaml.git" + "@" + Var("yaml_tag"),

  Var("dart_root") + "/buildtools/" + Var("host_os") + "-" + Var("host_cpu") + "/clang": {
      "packages": [
          {
              "package": "fuchsia/clang/${{platform}}",
              "version": "git_revision:" + Var("clang_revision"),
          },
      ],
      "condition": "(host_os == 'linux' or host_os == 'mac') and (host_cpu == 'x64' or host_cpu == 'arm64')",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/pkg/analysis_server/language_model": {
    "packages": [
      {
        "package": "dart/language_model",
        "version": "9fJQZ0TrnAGQKrEtuL3-AXbUfPzYxqpN_OBHr9P4hE4C",
      }
    ],
    "dep_type": "cipd",
  },

  Var("dart_root") + "/buildtools": {
      "packages": [
          {
              "package": "gn/gn/${{platform}}",
              "version": "git_revision:" + Var("gn_revision"),
          },
      ],
      "dep_type": "cipd",
  },

  Var("dart_root") + "/buildtools/" + Var("host_os") + "-" + Var("host_cpu") + "/rust": {
      "packages": [
          {
              "package": "fuchsia/rust/${{platform}}",
              "version": "git_revision:" + Var("rust_revision"),
          },
      ],
      "condition": "(host_os == 'linux' or host_os == 'mac') and host_cpu == 'x64'",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/pkg/front_end/test/fasta/types/benchmark_data": {
    "packages": [
      {
        "package": "dart/cfe/benchmark_data",
        "version": "sha1sum:4640fa0bff40726392748d1ad3147e5dd0324ea2",
      }
    ],
    "dep_type": "cipd",
  },

  Var("dart_root") + "/pkg/front_end/testcases/old_dills/dills": {
    "packages": [
      {
        "package": "dart/cfe/dart2js_dills",
        "version": "binary_version:36",
      }
    ],
    "dep_type": "cipd",
  },

  # TODO(37531): Remove these cipd packages and build with sdk instead when
  # benchmark runner gets support for that.
  Var("dart_root") + "/benchmarks/FfiBoringssl/dart/native/out/": {
      "packages": [
          {
              "package": "dart/benchmarks/ffiboringssl",
              "version": "commit:a86c69888b9a416f5249aacb4690a765be064969",
          },
      ],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/benchmarks/FfiCall/dart/native/out/": {
      "packages": [
          {
              "package": "dart/benchmarks/fficall",
              "version": "version:1",
          },
      ],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/llvm": {
      "packages": [
          {
              "package": "fuchsia/lib/llvm/${{platform}}",
              "version": "git_revision:" + Var("llvm_revision"),
          },
      ],
      "condition": "checkout_llvm",
      "dep_type": "cipd",
  }
}

deps_os = {
  "win": {
    Var("dart_root") + "/third_party/cygwin":
        Var("chromium_git") + "/chromium/deps/cygwin.git" + "@" +
        "c89e446b273697fadf3a10ff1007a97c0b7de6df",
    Var("dart_root") + "/third_party/crashpad/crashpad":
        Var("chromium_git") + "/crashpad/crashpad.git" + "@" +
        Var("crashpad_rev"),
    Var("dart_root") + "/third_party/mini_chromium/mini_chromium":
        Var("chromium_git") + "/chromium/mini_chromium" + "@" +
        Var("minichromium_rev"),
    Var("dart_root") + "/third_party/googletest":
        Var("fuchsia_git") + "/third_party/googletest" + "@" +
        Var("googletest_rev"),
  }
}

# TODO(iposva): Move the necessary tools so that hooks can be run
# without the runtime being available.
hooks = [
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
    # Download dill files for all supported ABI versions, if necessary.
    'name': 'abiversions',
    'pattern': '.',
    'action': ['python', 'sdk/tools/download_abi_dills.py'],
  },
]

hooks_os = {
  "win": [
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
  ]
}
