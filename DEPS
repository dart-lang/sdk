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
  'dart-internal.googlesource.com',
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
  "dart_git": "https://dart.googlesource.com/",
  "dart_internal_git": "https://dart-internal.googlesource.com",
  # If the repo you want to use is at github.com/dart-lang, but not at
  # dart.googlesource.com, please file an issue
  # on github and add the label 'area-infrastructure'.
  # When the repo is mirrored, you can add it to this DEPS file.

  # Chromium git
  "chromium_git": "https://chromium.googlesource.com",
  "fuchsia_git": "https://fuchsia.googlesource.com",

  # Checked-in SDK version. The checked-in SDK is a Dart SDK distribution in a
  # cipd package used to run Dart scripts in the build and test infrastructure.
  "sdk_tag": "version:2.10.0-110.3.beta",

  # co19 is a cipd package. Use update.sh in tests/co19[_2] to update these
  # hashes. It requires access to the dart-build-access group, which EngProd
  # has.
  "co19_rev": "827f96b4cddf68cd12049ad5612c53e215b58fcf",
  "co19_2_rev": "e48b3090826cf40b8037648f19d211e8eab1b4b6",

  # The internal benchmarks to use. See go/dart-benchmarks-internal
  "benchmarks_internal_rev": "7030a669aa70e2558cdebb3a89b6d11a34d09051",
  "checkout_benchmarks_internal": False,

  # As Flutter does, we use Fuchsia's GN and Clang toolchain. These revision
  # should be kept up to date with the revisions pulled by the Flutter engine.
  # The list of revisions for these tools comes from Fuchsia, here:
  # https://fuchsia.googlesource.com/integration/+/HEAD/prebuilts
  # If there are problems with the toolchain, contact fuchsia-toolchain@.
  "clang_revision": "7e9747b50bcb1be28d4a3236571e8050835497a6",
  "gn_revision": "1e3fd10c5df6b704fc764ee388149e4f32862823",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "c09c8deeac31f05bd801995c475e7c8070f9ecda",

  "gperftools_revision": "e9ab4c53041ac62feefbbb076d326e9a77dd1567",

  # Revisions of /third_party/* dependencies.
  "args_tag": "1.6.0",
  "async_rev": "128c461a97dbdbd9336ba000ba5a5c02e79b8651",
  "bazel_worker_rev": "26680d5e249b249c7216ab2fed0ac8ed4ee285c5",
  "benchmark_harness_rev": "ec6b646f5443faa871e126ac1ba248c94ca06257",
  "boolean_selector_rev": "665e6921ab246569420376f827bff4585dff0b14",
  "boringssl_gen_rev": "429ccb1877f7987a6f3988228bc2440e61293499",
  "boringssl_rev" : "4dfd5af70191b068aebe567b8e29ce108cee85ce",
  "browser-compat-data_tag": "v1.0.22",
  "charcode_rev": "4a685faba42d86ebd9d661eadd1e79d0a1c34c43",
  "chrome_rev" : "19997",
  "cli_util_tag" : "0.2.0",
  "collection_rev": "583693680fc067e34ca5b72503df25e8b80579f9",
  "convert_rev": "c1b01f832835d3d8a06b0b246a361c0eaab35d3c",
  "crypto_rev": "f7c48b334b1386bc5ab0f706fbcd6df8496a87fc",
  "csslib_rev": "681a6603f86bbbe64e8af42d722aef63b028d241",
  "dart2js_info_rev" : "0632a623b08e1f601c7eba99e0186a581ae799e9",

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
  "dart_style_tag": "1.3.7",  # Please see the note above before updating.

  "chromedriver_tag": "83.0.4103.39",
  "dartdoc_rev" : "2bef0f260594b822f55c8c8f777d9c4c1ea8f76c",
  "ffi_rev": "454ab0f9ea6bd06942a983238d8a6818b1357edb",
  "fixnum_rev": "16d3890c6dc82ca629659da1934e412292508bba",
  "glob_rev": "e9f4e6b7ae8abe5071461cf8f47191bb19cf7ef6",
  "html_rev": "083a36cd801a4b787ba156b7c6e4c8b2e2daed4a",
  "http_io_rev": "2fa188caf7937e313026557713f7feffedd4978b",
  "http_multi_server_rev" : "ea269f79321d659208402088f3297e8920a88ee6",
  "http_parser_rev": "6e63a97b5aaa2b4d1215fe01683e51fb73258e54",
  "http_retry_tag": "0.1.1",
  "http_rev": "7b55a2c62a5f6fb680ad7a4607bab7281a235563",
  "http_throttle_tag" : "1.0.2",
  "icu_rev" : "79326efe26e5440f530963704c3c0ff965b3a4ac",
  "idl_parser_rev": "5fb1ebf49d235b5a70c9f49047e83b0654031eb7",
  "intl_tag": "0.16.1",
  "jinja2_rev": "2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_rev": "8f189db8f0c299187a0e8fa959dba7e9b0254be5",
  "linter_tag": "0.1.119",
  "logging_rev": "1590ba0b648a51e7eb3895c612e4b72f72623b6f",
  "markupsafe_rev": "8f45f5cfa0009d2a70589bcda0349b8cb2b72783",
  "markdown_rev": "dbeafd47759e7dd0a167602153bb9c49fb5e5fe7",
  "matcher_rev": "9cae8faa7868bf3a88a7ba45eb0bd128e66ac515",
  "mime_tag": "0.9.7",
  "mockito_rev": "d39ac507483b9891165e422ec98d9fb480037c8b",
  "mustache_rev": "664737ecad027e6b96d0d1e627257efa0e46fcb1",
  "oauth2_tag": "1.6.0",
  "package_config_rev": "9c586d04bd26fef01215fd10e7ab96a3050cfa64",
  "path_rev": "62ecd5a78ffe5734d14ed0df76d20309084cd04a",
  "pedantic_rev": "24b38df72430d7e21cb4257828580becb9a39c72",
  "ply_rev": "604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_rev": "eedbd5fde84f9a1a8da643b475305a81841da599",
  "protobuf_rev": "3746c8fd3f2b0147623a8e3db89c3ff4330de760",
  "pub_rev": "04e237f78b2302d7f20d0b362554425e8deb8add",
  "pub_semver_tag": "v1.4.4",
  "quiver-dart_tag": "246e754fe45cecb6aa5f3f13b4ed61037ff0d784",
  "resource_rev": "f8e37558a1c4f54550aa463b88a6a831e3e33cd6",
  "root_certificates_rev": "7e5ec82c99677a2e5b95ce296c4d68b0d3378ed8",
  "rust_revision": "cbe7c5ce705896d4e22bf6096590bc1f17993b78",
  "shelf_static_rev": "v0.2.8",
  "shelf_packages_handler_tag": "2.0.0",
  "shelf_proxy_tag": "0.1.0+7",
  "shelf_rev": "289309adc6c39aab0a63db676d550c517fc1cc2d",
  "shelf_web_socket_tag": "0.2.2+3",
  "source_map_stack_trace_rev": "1c3026f69d9771acf2f8c176a1ab750463309cce",
  "source_maps-0.9.4_rev": "38524",
  "source_maps_rev": "53eb92ccfe6e64924054f83038a534b959b12b3e",
  "source_span_rev": "cc7c4288a83f71ecef3414199947b52a8c112c65",
  "sse_tag": "e5cf68975e8e87171a3dc297577aa073454a91dc",
  "stack_trace_tag": "d3813ca0a77348e0faf0d6af0cc17913e36afa39",
  "stagehand_tag": "v3.3.9",
  "stream_channel_tag": "c446774fd077c9bdbd6235a7aadc661ef60a9727",
  "string_scanner_rev": "1b63e6e5db5933d7be0a45da6e1129fe00262734",
  "sync_http_rev": "a85d7ec764ea485cbbc49f3f3e7f1b43f87a1c74",
  "test_descriptor_tag": "1.1.1",
  "test_process_tag": "1.0.3",
  "term_glyph_rev": "6a0f9b6fb645ba75e7a00a4e20072678327a0347",
  "test_reflective_loader_tag": "0.1.9",
  "test_rev": "e37a93bbeae23b215972d1659ac865d71287ff6a",
  "tflite_native_rev": "3c777c40608a2a9f1427bfe0028ab48e7116b4c1",
  "typed_data_tag": "f94fc57b8e8c0e4fe4ff6cfd8290b94af52d3719",
  "usage_tag": "3.4.0",
  "vector_math_rev": "0c9f5d68c047813a6dcdeb88ba7a42daddf25025",
  "watcher_rev": "fc3c9aae5d31d707b3013b42634dde8d8a1161b4",
  "webdriver_rev": "5a8d6805d9cf8a3cbb4fcd64849b538b7491e50e",
  "web_components_rev": "8f57dac273412a7172c8ade6f361b407e2e4ed02",
  "web_socket_channel_rev": "490061ef0e22d3c8460ad2802f9948219365ad6b",
  "WebCore_rev": "fb11e887f77919450e497344da570d780e078bc8",
  "yaml_rev": "e5de429147a6b0fcb7e8ddb3c8e4674dc5dd0ecc",
  "zlib_rev": "c44fb7248079cc3d5563b14b3f758aee60d6b415",
  "crashpad_rev": "bf327d8ceb6a669607b0dbab5a83a275d03f99ed",
  "minichromium_rev": "8d641e30a8b12088649606b912c2bc4947419ccc",
  "googletest_rev": "f854f1d27488996dc8a6db3c9453f80b02585e12",

  # Pinned browser versions used by the testing infrastructure. These are not
  # meant to be downloaded by users for local testing.
  "download_chrome": False,
  "chrome_tag": "84",
  "download_firefox": False,
  "firefox_tag": "67",

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

  Var("dart_root") + "/third_party/llvm-build/Release+Asserts": {
    "packages": [
      {
        "package": "flutter/clang/win-amd64",
        "version": "git_revision:5ec206df8534d2dd8cb9217c3180e5ddba587393"
      }
    ],
    "condition": "download_windows_deps",
    "dep_type": "cipd",
  },
  Var("dart_root") + "/benchmarks-internal": {
    "url": Var("dart_internal_git") + "/benchmarks-internal.git" +
           "@" + Var("benchmarks_internal_rev"),
    "condition": "checkout_benchmarks_internal",
  },
  Var("dart_root") + "/tools/sdks": {
      "packages": [{
          "package": "dart/dart-sdk/${{platform}}",
          "version": Var("sdk_tag"),
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/d8": {
      "packages": [{
          "package": "dart/d8",
          "version": "version:8.5.210",
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/tests/co19/src": {
      "packages": [{
          "package": "dart/third_party/co19",
          "version": "git_revision:" + Var("co19_rev"),
      }],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/tests/co19_2/src": {
      "packages": [{
          "package": "dart/third_party/co19/legacy",
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

  Var("dart_root") + "/third_party/mdn/browser-compat-data/src":
      Var('chromium_git') + '/external/github.com/mdn/browser-compat-data' +
      "@" + Var("browser-compat-data_tag"),

  Var("dart_root") + "/third_party/tcmalloc/gperftools":
      Var('chromium_git') + '/external/github.com/gperftools/gperftools.git' +
      "@" + Var("gperftools_revision"),

  Var("dart_root") + "/third_party/pkg/args":
      Var("dart_git") + "args.git" + "@" + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async":
      Var("dart_git") + "async.git" + "@" + Var("async_rev"),
  Var("dart_root") + "/third_party/pkg/bazel_worker":
      Var("dart_git") + "bazel_worker.git" + "@" + Var("bazel_worker_rev"),
  Var("dart_root") + "/third_party/pkg/benchmark_harness":
      Var("dart_git") + "benchmark_harness.git" + "@" +
      Var("benchmark_harness_rev"),
  Var("dart_root") + "/third_party/pkg/boolean_selector":
      Var("dart_git") + "boolean_selector.git" +
      "@" + Var("boolean_selector_rev"),
  Var("dart_root") + "/third_party/pkg/charcode":
      Var("dart_git") + "charcode.git" + "@" + Var("charcode_rev"),
  Var("dart_root") + "/third_party/pkg/cli_util":
      Var("dart_git") + "cli_util.git" + "@" + Var("cli_util_tag"),
  Var("dart_root") + "/third_party/pkg/collection":
      Var("dart_git") + "collection.git" + "@" + Var("collection_rev"),
  Var("dart_root") + "/third_party/pkg/convert":
      Var("dart_git") + "convert.git" + "@" + Var("convert_rev"),
  Var("dart_root") + "/third_party/pkg/crypto":
      Var("dart_git") + "crypto.git" + "@" + Var("crypto_rev"),
  Var("dart_root") + "/third_party/pkg/csslib":
      Var("dart_git") + "csslib.git" + "@" + Var("csslib_rev"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      Var("dart_git") + "dart_style.git" + "@" + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      Var("dart_git") + "dart2js_info.git" + "@" + Var("dart2js_info_rev"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      Var("dart_git") + "dartdoc.git" + "@" + Var("dartdoc_rev"),
  Var("dart_root") + "/third_party/pkg/ffi":
      Var("dart_git") + "ffi.git" + "@" + Var("ffi_rev"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      Var("dart_git") + "fixnum.git" + "@" + Var("fixnum_rev"),
  Var("dart_root") + "/third_party/pkg/glob":
      Var("dart_git") + "glob.git" + "@" + Var("glob_rev"),
  Var("dart_root") + "/third_party/pkg/html":
      Var("dart_git") + "html.git" + "@" + Var("html_rev"),
  Var("dart_root") + "/third_party/pkg/http":
      Var("dart_git") + "http.git" + "@" + Var("http_rev"),
  Var("dart_root") + "/third_party/pkg_tested/http_io":
    Var("dart_git") + "http_io.git" + "@" + Var("http_io_rev"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      Var("dart_git") + "http_multi_server.git" +
      "@" + Var("http_multi_server_rev"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      Var("dart_git") + "http_parser.git" + "@" + Var("http_parser_rev"),
  Var("dart_root") + "/third_party/pkg/http_retry":
      Var("dart_git") + "http_retry.git" +
      "@" + Var("http_retry_tag"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      Var("dart_git") + "http_throttle.git" +
      "@" + Var("http_throttle_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      Var("dart_git") + "intl.git" + "@" + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      Var("dart_git") + "json_rpc_2.git" + "@" + Var("json_rpc_2_rev"),
  Var("dart_root") + "/third_party/pkg/linter":
      Var("dart_git") + "linter.git" + "@" + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      Var("dart_git") + "logging.git" + "@" + Var("logging_rev"),
  Var("dart_root") + "/third_party/pkg/markdown":
      Var("dart_git") + "markdown.git" + "@" + Var("markdown_rev"),
  Var("dart_root") + "/third_party/pkg/matcher":
      Var("dart_git") + "matcher.git" + "@" + Var("matcher_rev"),
  Var("dart_root") + "/third_party/pkg/mime":
      Var("dart_git") + "mime.git" + "@" + Var("mime_tag"),
  Var("dart_root") + "/third_party/pkg/mockito":
      Var("dart_git") + "mockito.git" + "@" + Var("mockito_rev"),
  Var("dart_root") + "/third_party/pkg/mustache":
      Var("dart_git")
      + "external/github.com/xxgreg/mustache"
      + "@" + Var("mustache_rev"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      Var("dart_git") + "oauth2.git" + "@" + Var("oauth2_tag"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      Var("dart_git") + "package_config.git" +
      "@" + Var("package_config_rev"),
  Var("dart_root") + "/third_party/pkg/path":
      Var("dart_git") + "path.git" + "@" + Var("path_rev"),
  Var("dart_root") + "/third_party/pkg/pedantic":
      Var("dart_git") + "pedantic.git" + "@" + Var("pedantic_rev"),
  Var("dart_root") + "/third_party/pkg/pool":
      Var("dart_git") + "pool.git" + "@" + Var("pool_rev"),
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
      Var("dart_git") + "shelf.git" + "@" + Var("shelf_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_packages_handler":
      Var("dart_git") + "shelf_packages_handler.git"
      + "@" + Var("shelf_packages_handler_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_proxy":
      Var("dart_git") + "shelf_proxy.git" + "@" + Var("shelf_proxy_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      Var("dart_git") + "shelf_static.git" + "@" + Var("shelf_static_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      Var("dart_git") + "shelf_web_socket.git" +
      "@" + Var("shelf_web_socket_tag"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      Var("dart_git") + "source_maps.git" + "@" + Var("source_maps_rev"),
  Var("dart_root") + "/third_party/pkg/source_span":
      Var("dart_git") + "source_span.git" + "@" + Var("source_span_rev"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      Var("dart_git") + "source_map_stack_trace.git" +
      "@" + Var("source_map_stack_trace_rev"),
  Var("dart_root") + "/third_party/pkg/sse":
      Var("dart_git") + "sse.git" + "@" + Var("sse_tag"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      Var("dart_git") + "stack_trace.git" + "@" + Var("stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stagehand":
      Var("dart_git") + "stagehand.git" + "@" + Var("stagehand_tag"),
  Var("dart_root") + "/third_party/pkg/stream_channel":
      Var("dart_git") + "stream_channel.git" +
      "@" + Var("stream_channel_tag"),
  Var("dart_root") + "/third_party/pkg/string_scanner":
      Var("dart_git") + "string_scanner.git" +
      "@" + Var("string_scanner_rev"),
  Var("dart_root") + "/third_party/pkg/sync_http":
      Var("dart_git") + "sync_http.git" + "@" + Var("sync_http_rev"),
  Var("dart_root") + "/third_party/pkg/term_glyph":
      Var("dart_git") + "term_glyph.git" + "@" + Var("term_glyph_rev"),
  Var("dart_root") + "/third_party/pkg/test":
      Var("dart_git") + "test.git" + "@" + Var("test_rev"),
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
  Var("dart_root") + "/third_party/pkg/usage":
      Var("dart_git") + "usage.git" + "@" + Var("usage_tag"),
  Var("dart_root") + "/third_party/pkg/vector_math":
      Var("dart_git") + "external/github.com/google/vector_math.dart.git" +
      "@" + Var("vector_math_rev"),
  Var("dart_root") + "/third_party/pkg/watcher":
      Var("dart_git") + "watcher.git" + "@" + Var("watcher_rev"),
  Var("dart_root") + "/third_party/pkg/web_components":
      Var("dart_git") + "web-components.git" +
      "@" + Var("web_components_rev"),
  Var("dart_root") + "/third_party/pkg/webdriver":
      Var("dart_git") + "external/github.com/google/webdriver.dart.git" +
      "@" + Var("webdriver_rev"),

  Var("dart_root") + "/third_party/pkg/web_socket_channel":
      Var("dart_git") + "web_socket_channel.git" +
      "@" + Var("web_socket_channel_rev"),
  Var("dart_root") + "/third_party/pkg/yaml":
      Var("dart_git") + "yaml.git" + "@" + Var("yaml_rev"),

  Var("dart_root") + "/buildtools/" + Var("host_os") + "-" + Var("host_cpu") + "/clang": {
      "packages": [
          {
              "package": "fuchsia/third_party/clang/${{platform}}",
              "version": "git_revision:" + Var("clang_revision"),
          },
      ],
      "condition": "(host_os == 'linux' or host_os == 'mac') and (host_cpu == 'x64' or host_cpu == 'arm64')",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/webdriver/chrome": {
    "packages": [
      {
        "package": "dart/third_party/chromedriver/${{platform}}",
        "version": "version:" + Var("chromedriver_tag"),
      }
    ],
    "condition": "host_cpu == 'x64'",
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

  Var("dart_root") + "/third_party/fuchsia/sdk/linux": {
    "packages": [
      {
      "package": "fuchsia/sdk/gn/linux-amd64",
      "version": "git_revision:8d5242d4f6ff8b7634b492700e60b0fd09abefa3"
      }
    ],
    "condition": 'host_os == "linux" and host_cpu == "x64"',
    "dep_type": "cipd",
  },

  Var("dart_root") + "/pkg/front_end/test/fasta/types/benchmark_data": {
    "packages": [
      {
        "package": "dart/cfe/benchmark_data",
        "version": "sha1sum:5b6e6dfa33b85c733cab4e042bf46378984d1544",
      }
    ],
    "dep_type": "cipd",
  },

  Var("dart_root") + "/pkg/front_end/testcases/old_dills/dills": {
    "packages": [
      {
        "package": "dart/cfe/dart2js_dills",
        "version": "binary_version:45",
      }
    ],
    "dep_type": "cipd",
  },

  # TODO(37531): Remove these cipd packages and build with sdk instead when
  # benchmark runner gets support for that.
  Var("dart_root") + "/benchmarks/FfiBoringssl/native/out/": {
      "packages": [
          {
              "package": "dart/benchmarks/ffiboringssl",
              "version": "commit:a86c69888b9a416f5249aacb4690a765be064969",
          },
      ],
      "dep_type": "cipd",
  },
  Var("dart_root") + "/benchmarks/FfiCall/native/out/": {
      "packages": [
          {
              "package": "dart/benchmarks/fficall",
              "version": "ebF5aRXKDananlaN4Y8b0bbCNHT1MnkGbWqfpCpiND4C",
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
  },
  Var("dart_root") + "/third_party/browsers/chrome": {
      "packages": [
          {
              "package": "dart/browsers/chrome/${{platform}}",
              "version": "version:" + Var("chrome_tag"),
          },
      ],
      "condition": "download_chrome",
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/browsers/firefox": {
      "packages": [
          {
              "package": "dart/browsers/firefox/${{platform}}",
              "version": "version:" + Var("firefox_tag"),
          },
      ],
      "condition": "download_firefox",
      "dep_type": "cipd",
  },
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
    # Pull Debian sysroot for i386 Linux
    'name': 'sysroot_i386',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'i386'],
  },
  {
    # Pull Debian sysroot for amd64 Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'amd64'],
  },
  {
    # Pull Debian sysroot for arm Linux
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
