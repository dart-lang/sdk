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
  "sdk_tag": "version:2.13.0-211.14.beta",

  # co19 is a cipd package. Use update.sh in tests/co19[_2] to update these
  # hashes. It requires access to the dart-build-access group, which EngProd
  # has.
  "co19_rev": "26019f5b2efb294eacddfef6ce443083979feff5",
  "co19_2_rev": "1c2e425f461bfae7de6db7014fc44a58fc72b4a8",

  # The internal benchmarks to use. See go/dart-benchmarks-internal
  "benchmarks_internal_rev": "076df10d9b77af337f2d8029725787155eb1cd52",
  "checkout_benchmarks_internal": False,

  # Checkout Android dependencies only on Mac and Linux.
  "download_android_deps": 'host_os == "mac" or host_os == "linux"',

  # Checkout extra javascript engines for testing or benchmarking.
  # d8, the V8 shell, is always checked out.
  "checkout_javascript_engines": False,

  # As Flutter does, we use Fuchsia's GN and Clang toolchain. These revision
  # should be kept up to date with the revisions pulled by the Flutter engine.
  # The list of revisions for these tools comes from Fuchsia, here:
  # https://fuchsia.googlesource.com/integration/+/HEAD/prebuilts
  # If there are problems with the toolchain, contact fuchsia-toolchain@.
  "clang_revision": "3dc24bc31edbc01dea085b24a6a6b024d7ae531c",
  "gn_revision": "39a87c0b36310bdf06b692c098f199a0d97fc810",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "c09c8deeac31f05bd801995c475e7c8070f9ecda",

  "gperftools_revision": "180bfa10d7cb38e8b3784d60943d50e8fcef0dcb",

  # Revisions of /third_party/* dependencies.
  "args_rev": "d8fea36c10ef96797be02e3d132d572445cd86f4",
  "async_rev": "92e7119aa068bfb86a6a9519d44037ffff5eece8",
  "bazel_worker_rev": "0885637b037979afbf5bcd05fd748b309fd669c0",
  "benchmark_harness_rev": "c546dbd9f639f75cd2f75de8df2eb9f8ea15e8e7",
  "boolean_selector_rev": "665e6921ab246569420376f827bff4585dff0b14",
  "boringssl_gen_rev": "7322fc15cc065d8d2957fccce6b62a509dc4d641",
  "boringssl_rev" : "1607f54fed72c6589d560254626909a64124f091",
  "browser-compat-data_tag": "v1.0.22",
  "browser_launcher_rev": "12ab9f351a44ac803de9bc17bb2180bb312a9dd7",
  "charcode_rev": "bcd8a12c315b7a83390e4865ad847ecd9344cba2",
  "chrome_rev" : "19997",
  "cli_util_rev" : "8c504de5deb08fe32ecf51f9662bb37d8c708e57",
  "clock_rev" : "a494269254ba978e7ef8f192c5f7fec3fc05b9d3",
  "collection_rev": "9967dcd3d7645db6de48d5abfab3018bb0c84236",
  "convert_rev": "a60156c6efd653657c8926b5788219ed609917d7",
  "crypto_rev": "1c8ccc07b83b100216dc6dede767371043385648",
  "csslib_rev": "e411d862fd8cc50415c1badf2632e017373b3f47",
  "dart2js_info_rev" : "e0acfeb5affdf94c53067e68bd836adf589628fd",

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
  "dart_style_rev": "f17c23e0eea9a870601c19d904e2a9c1a7c81470",

  "chromedriver_tag": "83.0.4103.39",
  "dartdoc_rev" : "305713608c25106d95f9114418d895e08d1a9e9c",
  "devtools_rev" : "e138d55437a59838607415ef21f20bd6c4955dbc",
  "jsshell_tag": "version:88.0",
  "ffi_rev": "f3346299c55669cc0db48afae85b8110088bf8da",
  "fixnum_rev": "16d3890c6dc82ca629659da1934e412292508bba",
  "file_rev": "0e09370f581ab6388d46fda4cdab66638c0171a1",
  "glob_rev": "a62acf590598f458d3198d9f2930c1c9dd4b1379",
  "html_rev": "00cd3c22dac0e68e6ed9e7e4945101aedb1b3109",
  "http_io_rev": "2fa188caf7937e313026557713f7feffedd4978b",
  "http_multi_server_rev": "de1b312164c24a1690b46c6e97bd47eff40c4649",
  "http_parser_rev": "7720bfd42a0c096734c5213478fdce92c62f0293",
  "http_retry_rev": "845771af7bb5ab38ab740ce4a31f3b0c7680302b",
  "http_rev": "abb2bb182fbd7f03aafd1f889b902d7b3bdb8769",
  "http_throttle_tag" : "1.0.2",
  "icu_rev" : "81d656878ec611cb0b42d52c82e9dae93920d9ba",
  "idl_parser_rev": "5fb1ebf49d235b5a70c9f49047e83b0654031eb7",
  "intl_tag": "0.17.0-nullsafety",
  "jinja2_rev": "2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_rev": "7e00f893440a72de0637970325e4ea44bd1e8c8e",
  "linter_tag": "1.4.0",
  "lints_tag": "f9670df2a66e0ec12eb51554e70c1cbf56c8f5d0",
  "logging_rev": "e2f633b543ef89c54688554b15ca3d7e425b86a2",
  "markupsafe_rev": "8f45f5cfa0009d2a70589bcda0349b8cb2b72783",
  "markdown_rev": "9c4beaac96d8f008078e00b027915f81b665d2de",
  "matcher_rev": "1f7b6f0cb15eb6659a1de0513571575a5c8a51d0",
  "mime_rev": "c931f4bed87221beaece356494b43731445ce7b8",
  "mockito_rev": "d39ac507483b9891165e422ec98d9fb480037c8b",
  "oauth2_rev": "7cd3284049fe5badbec9f2bea2afc41d14c01057",
  "package_config_rev": "a84c0d45401f215fbe9384df923a38f4022a3c45",
  "path_rev": "407ab76187fade41c31e39c745b39661b710106c",
  "pedantic_rev": "66f2f6c27581c7936482e83be80b27be2719901c",
  "platform_rev": "c20e6fa315e9f8820e51c0ae721f63aff33b8e17",
  "ply_rev": "604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_rev": "7abe634002a1ba8a0928eded086062f1307ccfae",
  "process_rev": "56ece43b53b64c63ae51ec184b76bd5360c28d0b",
  "protobuf_rev": "0d03fd588df69e9863e2a2efc0059dee8f18d5b2",
  "pub_rev": "00c00e8adf9706bebe8f94483b7663c5f36f59d2",
  "pub_semver_rev": "f50d80ef10c4b2fa5f4c8878036a4d9342c0cc82",
  "resource_rev": "6b79867d0becf5395e5819a75720963b8298e9a7",
  "root_certificates_rev": "7e5ec82c99677a2e5b95ce296c4d68b0d3378ed8",
  "rust_revision": "b7856f695d65a8ebc846754f97d15814bcb1c244",
  "shelf_static_rev": "fa30419055279a00c9e428439b1abe362d18f25d",
  "shelf_packages_handler_rev": "78302e67c035047e6348e692b0c1182131f0fe35",
  "shelf_proxy_tag": "v1.0.0",
  "shelf_rev": "4b9294e29eb308709444a5c0b890fa8ccd69fae4",
  "shelf_web_socket_rev": "24fb8a04befa75a94ac63a27047b231d1a22aab4",
  "source_map_stack_trace_rev": "1c3026f69d9771acf2f8c176a1ab750463309cce",
  "source_maps-0.9.4_rev": "38524",
  "source_maps_rev": "53eb92ccfe6e64924054f83038a534b959b12b3e",
  "source_span_rev": "1be3c44045a06dff840d2ed3a13e6082d7a03a23",
  "sse_tag": "adc3ac8027784ed9783d066dccadad44458788e4",
  "stack_trace_tag": "6788afc61875079b71b3d1c3e65aeaa6a25cbc2f",
  "stream_channel_tag": "d7251e61253ec389ee6e045ee1042311bced8f1d",
  "string_scanner_rev": "1b63e6e5db5933d7be0a45da6e1129fe00262734",
  "sync_http_rev": "b59c134f2e34d12acac110d4f17f83e5a7db4330",
  "test_descriptor_tag": "2.0.0",
  "test_process_tag": "2.0.0",
  "term_glyph_rev": "6a0f9b6fb645ba75e7a00a4e20072678327a0347",
  "test_reflective_loader_rev": "54e930a11c372683792e22bddad79197728c91ce",
  "test_rev": "cd91c38f184fe7162ecbab8bfa2f15d2a335015d",
  "typed_data_tag": "f94fc57b8e8c0e4fe4ff6cfd8290b94af52d3719",
  "usage_rev": "e0780cd8b2f8af69a28dc52678ffe8492da27d06",
  "vector_math_rev": "0c9f5d68c047813a6dcdeb88ba7a42daddf25025",
  "watcher_rev": "3924194385fb215cef483193ed2879a618a3d69c",
  "webdriver_rev": "ff5ccb1522edf4bed578ead4d65e0cbc1f2c4f02",
  "web_components_rev": "8f57dac273412a7172c8ade6f361b407e2e4ed02",
  "web_socket_channel_rev": "6448ce532445a8a458fa191d9346df071ae0acad",
  "WebCore_rev": "fb11e887f77919450e497344da570d780e078bc8",
  "webdev_rev": "b0aae7b6944d484722e6af164abedd864a2a0afa",
  "webkit_inspection_protocol_rev": "6b15729292d030f2e5c5861022da4c5a4c11961c",
  "yaml_rev": "b4c4411631bda556ce9a45af1ab0eecaf9f3ac53",
  "zlib_rev": "bf44340d1b6be1af8950bbdf664fec0cf5a831cc",
  "crashpad_rev": "bf327d8ceb6a669607b0dbab5a83a275d03f99ed",
  "minichromium_rev": "8d641e30a8b12088649606b912c2bc4947419ccc",
  "googletest_rev": "f854f1d27488996dc8a6db3c9453f80b02585e12",

  # Pinned browser versions used by the testing infrastructure. These are not
  # meant to be downloaded by users for local testing.
  "download_chrome": False,
  "chrome_tag": "84",
  "download_firefox": False,
  "firefox_tag": "67",
}

gclient_gn_args_file = Var("dart_root") + '/build/config/gclient_args.gni'
gclient_gn_args = [
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
  Var("dart_root") + "/third_party/firefox_jsshell": {
      "packages": [{
          "package": "dart/third_party/jsshell/${{platform}}",
          "version": Var("jsshell_tag"),
      }],
      "condition": "checkout_javascript_engines",
      "dep_type": "cipd",
  },
  # TODO(b/186078239): remove this copy to the old location
  Var("dart_root") + "/third_party/firefox_jsshell/linux/jsshell": {
      "packages": [{
          "package": "dart/third_party/jsshell/linux-amd64",
          "version": Var("jsshell_tag"),
      }],
      "condition": "checkout_javascript_engines",
      "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/devtools": {
      "packages": [{
          "package": "dart/third_party/flutter/devtools",
          "version": "git_revision:" + Var("devtools_rev"),
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
          "package": "infra/3pp/tools/gsutil",
          "version": "version:4.58",
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

  Var("dart_root") + "/third_party/pkg/browser_launcher":
      Var("dart_git") + "browser_launcher.git" + "@" + Var("browser_launcher_rev"),

  Var("dart_root") + "/third_party/tcmalloc/gperftools":
      Var('chromium_git') + '/external/github.com/gperftools/gperftools.git' +
      "@" + Var("gperftools_revision"),

  Var("dart_root") + "/third_party/pkg/args":
      Var("dart_git") + "args.git" + "@" + Var("args_rev"),
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
      Var("dart_git") + "cli_util.git" + "@" + Var("cli_util_rev"),
  Var("dart_root") + "/third_party/pkg/clock":
      Var("dart_git") + "clock.git" + "@" + Var("clock_rev"),
  Var("dart_root") + "/third_party/pkg/collection":
      Var("dart_git") + "collection.git" + "@" + Var("collection_rev"),
  Var("dart_root") + "/third_party/pkg/convert":
      Var("dart_git") + "convert.git" + "@" + Var("convert_rev"),
  Var("dart_root") + "/third_party/pkg/crypto":
      Var("dart_git") + "crypto.git" + "@" + Var("crypto_rev"),
  Var("dart_root") + "/third_party/pkg/csslib":
      Var("dart_git") + "csslib.git" + "@" + Var("csslib_rev"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      Var("dart_git") + "dart_style.git" + "@" + Var("dart_style_rev"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      Var("dart_git") + "dart2js_info.git" + "@" + Var("dart2js_info_rev"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      Var("dart_git") + "dartdoc.git" + "@" + Var("dartdoc_rev"),
  Var("dart_root") + "/third_party/pkg/ffi":
      Var("dart_git") + "ffi.git" + "@" + Var("ffi_rev"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      Var("dart_git") + "fixnum.git" + "@" + Var("fixnum_rev"),
  Var("dart_root") + "/third_party/pkg/file":
      Var("dart_git") + "external/github.com/google/file.dart/"
      + "@" + Var("file_rev"),
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
      "@" + Var("http_retry_rev"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      Var("dart_git") + "http_throttle.git" +
      "@" + Var("http_throttle_tag"),
  Var("dart_root") + "/third_party/pkg/intl":
      Var("dart_git") + "intl.git" + "@" + Var("intl_tag"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      Var("dart_git") + "json_rpc_2.git" + "@" + Var("json_rpc_2_rev"),
  Var("dart_root") + "/third_party/pkg/linter":
      Var("dart_git") + "linter.git" + "@" + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/lints":
      Var("dart_git") + "lints.git" + "@" + Var("lints_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      Var("dart_git") + "logging.git" + "@" + Var("logging_rev"),
  Var("dart_root") + "/third_party/pkg/markdown":
      Var("dart_git") + "markdown.git" + "@" + Var("markdown_rev"),
  Var("dart_root") + "/third_party/pkg/matcher":
      Var("dart_git") + "matcher.git" + "@" + Var("matcher_rev"),
  Var("dart_root") + "/third_party/pkg/mime":
      Var("dart_git") + "mime.git" + "@" + Var("mime_rev"),
  Var("dart_root") + "/third_party/pkg/mockito":
      Var("dart_git") + "mockito.git" + "@" + Var("mockito_rev"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      Var("dart_git") + "oauth2.git" + "@" + Var("oauth2_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      Var("dart_git") + "package_config.git" +
      "@" + Var("package_config_rev"),
  Var("dart_root") + "/third_party/pkg/path":
      Var("dart_git") + "path.git" + "@" + Var("path_rev"),
  Var("dart_root") + "/third_party/pkg/pedantic":
      Var("dart_git") + "pedantic.git" + "@" + Var("pedantic_rev"),
  Var("dart_root") + "/third_party/pkg/platform":
       Var("dart_git") + "platform.dart.git" + "@" + Var("platform_rev"),
  Var("dart_root") + "/third_party/pkg/pool":
      Var("dart_git") + "pool.git" + "@" + Var("pool_rev"),
  Var("dart_root") + "/third_party/pkg/protobuf":
       Var("dart_git") + "protobuf.git" + "@" + Var("protobuf_rev"),
  Var("dart_root") + "/third_party/pkg/process":
       Var("dart_git") + "process.dart.git" + "@" + Var("process_rev"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      Var("dart_git") + "pub_semver.git" + "@" + Var("pub_semver_rev"),
  Var("dart_root") + "/third_party/pkg/pub":
      Var("dart_git") + "pub.git" + "@" + Var("pub_rev"),
  Var("dart_root") + "/third_party/pkg/resource":
      Var("dart_git") + "resource.git" + "@" + Var("resource_rev"),
  Var("dart_root") + "/third_party/pkg/shelf":
      Var("dart_git") + "shelf.git" + "@" + Var("shelf_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_packages_handler":
      Var("dart_git") + "shelf_packages_handler.git"
      + "@" + Var("shelf_packages_handler_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_proxy":
      Var("dart_git") + "shelf_proxy.git" + "@" + Var("shelf_proxy_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      Var("dart_git") + "shelf_static.git" + "@" + Var("shelf_static_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      Var("dart_git") + "shelf_web_socket.git" +
      "@" + Var("shelf_web_socket_rev"),
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
  Var("dart_root") + "/third_party/pkg/test_descriptor":
      Var("dart_git") + "test_descriptor.git" + "@" + Var("test_descriptor_tag"),
  Var("dart_root") + "/third_party/pkg/test_process":
      Var("dart_git") + "test_process.git" + "@" + Var("test_process_tag"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      Var("dart_git") + "test_reflective_loader.git" +
      "@" + Var("test_reflective_loader_rev"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      Var("dart_git") + "typed_data.git" + "@" + Var("typed_data_tag"),
  Var("dart_root") + "/third_party/pkg/usage":
      Var("dart_git") + "usage.git" + "@" + Var("usage_rev"),
  Var("dart_root") + "/third_party/pkg/vector_math":
      Var("dart_git") + "external/github.com/google/vector_math.dart.git" +
      "@" + Var("vector_math_rev"),
  Var("dart_root") + "/third_party/pkg/watcher":
      Var("dart_git") + "watcher.git" + "@" + Var("watcher_rev"),
  Var("dart_root") + "/third_party/pkg/web_components":
      Var("dart_git") + "web-components.git" +
      "@" + Var("web_components_rev"),
  Var("dart_root") + "/third_party/pkg/webdev":
      Var("dart_git") + "webdev.git" + "@" + Var("webdev_rev"),
  Var("dart_root") + "/third_party/pkg/webdriver":
      Var("dart_git") + "external/github.com/google/webdriver.dart.git" +
      "@" + Var("webdriver_rev"),
  Var("dart_root") + "/third_party/pkg/webkit_inspection_protocol":
      Var("dart_git") + "external/github.com/google/webkit_inspection_protocol.dart.git" +
      "@" + Var("webkit_inspection_protocol_rev"),

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

  Var("dart_root") + "/third_party/android_tools/ndk": {
      "packages": [
          {
            "package": "flutter/android/ndk/${{platform}}",
            "version": "version:r21.0.6113669"
          }
      ],
      "condition": "download_android_deps",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/android_tools/sdk/build-tools": {
      "packages": [
          {
            "package": "flutter/android/sdk/build-tools/${{platform}}",
            "version": "version:30.0.1"
          }
      ],
      "condition": "download_android_deps",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/android_tools/sdk/platform-tools": {
     "packages": [
          {
            "package": "flutter/android/sdk/platform-tools/${{platform}}",
            "version": "version:29.0.2"
          }
      ],
      "condition": "download_android_deps",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/android_tools/sdk/platforms": {
      "packages": [
          {
            "package": "flutter/android/sdk/platforms",
            "version": "version:30r3"
          }
      ],
      "condition": "download_android_deps",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/android_tools/sdk/tools": {
      "packages": [
          {
            "package": "flutter/android/sdk/tools/${{platform}}",
            "version": "version:26.1.1"
          }
      ],
      "condition": "download_android_deps",
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
      "version": "git_revision:e0a61431eb6e28d31d293cbb0c12f6b3a089bba4"
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

hooks = [
  {
    # Pull Debian sysroot for i386 Linux
    'name': 'sysroot_i386',
    'pattern': '.',
    'action': ['python3', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'i386'],
  },
  {
    # Pull Debian sysroot for amd64 Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python3', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'amd64'],
  },
  {
    # Pull Debian sysroot for arm Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python3', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'arm'],
  },
  {
    # Pull Debian jessie sysroot for arm64 Linux
    'name': 'sysroot_amd64',
    'pattern': '.',
    'action': ['python3', 'sdk/build/linux/sysroot_scripts/install-sysroot.py',
               '--arch', 'arm64'],
  },
  {
    'name': 'buildtools',
    'pattern': '.',
    'action': ['python3', 'sdk/tools/buildtools/update.py'],
  },
  {
    # Update the Windows toolchain if necessary.
    'name': 'win_toolchain',
    'pattern': '.',
    'action': ['python3', 'sdk/build/vs_toolchain.py', 'update'],
    'condition': 'checkout_win'
  },
]
