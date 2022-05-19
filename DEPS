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
  "sdk_tag": "version:2.17.0",

  # co19 is a cipd package. Use update.sh in tests/co19[_2] to update these
  # hashes.
  "co19_rev": "9849573cd1b8317e58247b8c1672e89b1cd842e2",
  # This line prevents conflicts when both packages are rolled simultaneously.
  "co19_2_rev": "b2034a17609472e374623f3dbe0efd9f5cb258af",

  # The internal benchmarks to use. See go/dart-benchmarks-internal
  "benchmarks_internal_rev": "599aa474a03c37be146f82dfbad85f34f25ffa47",
  "checkout_benchmarks_internal": False,

  # Checkout Android dependencies only on Mac and Linux.
  "download_android_deps":
    "host_os == mac or (host_os == linux and host_cpu == x64)",

  # Checkout extra javascript engines for testing or benchmarking.
  # d8, the V8 shell, is always checked out.
  "checkout_javascript_engines": False,
  "d8_tag": "version:10.2.78",
  "jsshell_tag": "version:95.0",

  # As Flutter does, we use Fuchsia's GN and Clang toolchain. These revision
  # should be kept up to date with the revisions pulled by the Flutter engine.
  # The list of revisions for these tools comes from Fuchsia, here:
  # https://fuchsia.googlesource.com/integration/+/HEAD/toolchain
  # If there are problems with the toolchain, contact fuchsia-toolchain@.
  "clang_revision": "c2592c374e469f343ecea82d6728609650924259",
  "gn_revision": "d7c2209cebcfe37f46dba7be4e1a7000ffc342fb",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "bb994c6f067340c1135eb43eed84f4b33cfa7397",

  "gperftools_revision": "180bfa10d7cb38e8b3784d60943d50e8fcef0dcb",

  # Revisions of /third_party/* dependencies.
  "args_rev": "862d929b980b993334974d38485a39d891d83918",
  "async_rev": "f3ed5f690e2ec9dbe1bfc5184705575b4f6480e5",
  "bazel_worker_rev": "ceeba0982d4ff40d32371c9d35f3d2dc1868de20",
  "benchmark_harness_rev": "0530da692a5d689f4b5450a7c8d1a8abe3e2d555",
  "boolean_selector_rev": "1d3565e2651d16566bb556955b96ea75018cbd0c",
  "boringssl_gen_rev": "ced85ef0a00bbca77ce5a91261a5f2ae61b1e62f",
  "boringssl_rev": "87f316d7748268eb56f2dc147bd593254ae93198",
  "browser-compat-data_tag": "ac8cae697014da1ff7124fba33b0b4245cc6cd1b", # v1.0.22
  "browser_launcher_rev": "c6cc1025d6901926cf022e144ba109677e3548f1",
  "characters_rev": "4b1d4b7737ad47cd2b8105c47e2159174010f29f",
  "charcode_rev": "84ea427711e24abf3b832923959caa7dd9a8514b",
  "chrome_rev": "19997",
  "cli_util_rev": "b0adbba89442b2ea6fef39c7a82fe79cb31e1168",
  "clock_rev": "f594d86da123015186d5680b0d0e8255c52fc162",
  "collection_rev": "e1407da23b9f17400b3a905aafe2b8fa10db3d86",
  "convert_rev": "e063fdca4bebffecbb5e6aa5525995120982d9ce",
  "crypto_rev": "4297d240b0e1e780ec0a9eab23eaf1ad491f3e68",
  "csslib_rev": "518761b166974537f334dbf264e7f56cb157a96a",

  # Note: Updates to dart_style have to be coordinated with the infrastructure
  # team so that the internal formatter `tools/sdks/dart-sdk/bin/dart format`
  # matches the version here. Please follow this process to make updates:
  #
  # * Create a commit that updates the version here to the desired version and
  #   adds any appropriate CHANGELOG text.
  # * Send that to eng-prod to review. They will update the checked-in SDK
  #   and land the review.
  #
  # For more details, see https://github.com/dart-lang/sdk/issues/30164.
  "dart_style_rev": "d7b73536a8079331c888b7da539b80e6825270ea",

  "dartdoc_rev": "334072b0cad436c05f6bcecf8a1a59f2f0809b84",
  "devtools_rev": "3c16b8d73120e46958982d94215d499793b972eb",
  "ffi_rev": "0c8364a728cfe4e4ba859c53b99d56b3dbe3add4",
  "file_rev": "0132eeedea2933513bf230513a766a8baeab0c4f",
  "fixnum_rev": "3bfc2ed1eea7e7acb79ad4f17392f92c816fc5ce",
  "glob_rev": "e10eb2407c58427144004458ef85c9bbf7286e56",
  "html_rev": "f108bce59d136c584969fd24a5006914796cf213",
  "http_io_rev": "405fc79233b4a3d4bb079ebf438bb2caf2f49355",
  "http_multi_server_rev": "34bf7f04b61cce561f47f7f275c2cc811534a05a",
  "http_parser_rev": "9126ee04e77fd8e4e2e6435b503ee4dd708d7ddc",
  "http_rev": "2c9b418f5086f999c150d18172d2eec1f963de7b",
  "icu_rev": "81d656878ec611cb0b42d52c82e9dae93920d9ba",
  "intl_rev": "9145f308f1458f37630a1ffce3b7d3b471ebbc56",
  "jinja2_rev": "2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_rev": "7e00f893440a72de0637970325e4ea44bd1e8c8e",
  "linter_rev": "a8529c6692922b45bc287543b355c90d7b1286d3", # 1.24.0
  "lints_rev": "8294e5648ab49474541527e2911e72e4c5aefe55",
  "logging_rev": "dfbe88b890c3b4f7bc06da5a7b3b43e9e263b688",
  "markdown_rev": "7479783f0493f6717e1d7ae31cb37d39a91026b2",
  "markupsafe_rev": "8f45f5cfa0009d2a70589bcda0349b8cb2b72783",
  "matcher_rev": "07595a7739d47a8315caba5a8e58fb9ae3d81261",
  "mime_rev": "c2c5ffd594674f32dc277521369da1557a1622d3",
  "mockito_rev": "1e977a727e82a2e1bdb49b79ef1dce0f23aa1faa",
  "oauth2_rev": "7cd3284049fe5badbec9f2bea2afc41d14c01057",
  "package_config_rev": "8731bf10b5375542792a32a0f7c8a6f370583d96",
  "path_rev": "3d41ea582f5b0b18de3d90008809b877ff3f69bc",
  "platform_rev": "1ffad63428bbd1b3ecaa15926bacfb724023648c",
  "ply_rev": "604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_rev": "c40cc32eabecb9d60f1045d1403108d968805f9a",
  "process_rev": "2546dfef7ba839b1514e0c9045344692eb47b771",
  "protobuf_rev": "c1eb6cb51af39ccbaa1a8e19349546586a5c8e31",
  "pub_rev": "51435efcd574b7bc18d47a5dd620cb9759dea8f8",
  "pub_semver_rev": "ea6c54019948dc03042c595ce9413e17aaf7aa38",
  "root_certificates_rev": "692f6d6488af68e0121317a9c2c9eb393eb0ee50",
  "rust_revision": "b7856f695d65a8ebc846754f97d15814bcb1c244",
  "shelf_rev": "fadca320b04689be9ec960013843a0d9ee6c4fc4",
  "source_map_stack_trace_rev": "8eabd96b1811e30a11d3c54c9b4afae4fb72e98f",
  "source_maps_rev": "c07a01b8d5547ce3a47ee7a7a2b938a2bc09afe3",
  "source_span_rev": "8ae724c3e67f5afaacead44e93ff145bfb8775c7",
  "sse_rev": "9a54f1cdd91c8d79a6bf5ef8e849a12756607453",
  "stack_trace_rev": "5220580872625ddee41e9ca9a5f3364789b2f0f6",
  "stream_channel_rev": "3fa3e40c75c210d617b8b943b9b8f580e9866a89",
  "string_scanner_rev": "6579871b528036767b3200b390a3ecef28e4900d",
  "sync_http_rev": "b6bd47965694dddffb6e62fb8a6c12d17c4ae4cd",
  "term_glyph_rev": "d0f205c67ea70eea47b9f41c8440129a72a9c86e",
  "test_descriptor_rev": "ead23c1e7df079ac0f6457a35f7a71432892e527",
  "test_process_rev": "7c73ec8a8a6e0e63d0ec27d70c21ca4323fb5e8f",
  "test_reflective_loader_rev": "fcfce37666672edac849d2af6dffc0f8df236a94",
  "test_rev": "d54846bc2b5cfa4e1445fda85c5e48a00940aa68",
  "typed_data_rev": "8b19e29bcf4077147de4d67adeabeb48270c65eb",
  "usage_rev": "e85d575d6decb921c57a43b9844bba3607479f56",
  "vector_math_rev": "0cbed0914d49a6a44555e6d5444c438a4a4c3fc1",
  "watcher_rev": "f76997ab0c857dc5537ac0975a9ada92b54ef949",
  "web_components_rev": "8f57dac273412a7172c8ade6f361b407e2e4ed02",
  "web_socket_channel_rev": "99dbdc5769e19b9eeaf69449a59079153c6a8b1f",
  "WebCore_rev": "bcb10901266c884e7b3740abc597ab95373ab55c",
  "webdev_rev": "8c814f9d89915418d8abe354ff9befec8f2906b2",
  "webdriver_rev": "ff5ccb1522edf4bed578ead4d65e0cbc1f2c4f02",
  "webkit_inspection_protocol_rev": "e4965778e2837adc62354eec3a19123402997897",
  "yaml_edit_rev": "0b74d85fac10b4fbf7d1a347debcf16c8f7b0e9c",
  "yaml_rev": "0971c06490b9670add644ed62182acd6a5536946",
  "zlib_rev": "27c2f474b71d0d20764f86f60ef8b00da1a16cda",

  # Windows deps
  "crashpad_rev": "bf327d8ceb6a669607b0dbab5a83a275d03f99ed",
  "minichromium_rev": "8d641e30a8b12088649606b912c2bc4947419ccc",
  "googletest_rev": "f854f1d27488996dc8a6db3c9453f80b02585e12",

  # Pinned browser versions used by the testing infrastructure. These are not
  # meant to be downloaded by users for local testing.
  "download_chrome": False,
  "chrome_tag": "101.0.4951.41",
  "download_firefox": False,
  "firefox_tag": "98.0.2",
}

gclient_gn_args_file = Var("dart_root") + '/build/config/gclient_args.gni'
gclient_gn_args = [
]

deps = {
  # Stuff needed for GN build.
  Var("dart_root") + "/buildtools/clang_format/script":
    Var("chromium_git") + "/chromium/llvm-project/cfe/tools/clang-format.git" +
    "@" + Var("clang_format_scripts_rev"),

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
          "version": Var("d8_tag"),
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
          "version": "version:2@5.5",
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

  Var("dart_root") + "/third_party/WebCore":
      Var("dart_git") + "webcore.git" + "@" + Var("WebCore_rev"),

  Var("dart_root") + "/third_party/mdn/browser-compat-data/src":
      Var('chromium_git') + '/external/github.com/mdn/browser-compat-data' +
      "@" + Var("browser-compat-data_tag"),

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
  Var("dart_root") + "/third_party/pkg/browser_launcher":
      Var("dart_git") + "browser_launcher.git" + "@" + Var("browser_launcher_rev"),
  Var("dart_root") + "/third_party/pkg/characters":
      Var("dart_git") + "characters.git" + "@" + Var("characters_rev"),
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
  Var("dart_root") + "/third_party/pkg/dartdoc":
      Var("dart_git") + "dartdoc.git" + "@" + Var("dartdoc_rev"),
  Var("dart_root") + "/third_party/pkg/ffi":
      Var("dart_git") + "ffi.git" + "@" + Var("ffi_rev"),
  Var("dart_root") + "/third_party/pkg/fixnum":
      Var("dart_git") + "fixnum.git" + "@" + Var("fixnum_rev"),
  Var("dart_root") + "/third_party/pkg/file":
      Var("dart_git") + "external/github.com/google/file.dart"
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
  Var("dart_root") + "/third_party/pkg/intl":
      Var("dart_git") + "intl.git" + "@" + Var("intl_rev"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      Var("dart_git") + "json_rpc_2.git" + "@" + Var("json_rpc_2_rev"),
  Var("dart_root") + "/third_party/pkg/linter":
      Var("dart_git") + "linter.git" + "@" + Var("linter_rev"),
  Var("dart_root") + "/third_party/pkg/lints":
      Var("dart_git") + "lints.git" + "@" + Var("lints_rev"),
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
  Var("dart_root") + "/third_party/pkg/shelf":
      Var("dart_git") + "shelf.git" + "@" + Var("shelf_rev"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      Var("dart_git") + "source_maps.git" + "@" + Var("source_maps_rev"),
  Var("dart_root") + "/third_party/pkg/source_span":
      Var("dart_git") + "source_span.git" + "@" + Var("source_span_rev"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      Var("dart_git") + "source_map_stack_trace.git" +
      "@" + Var("source_map_stack_trace_rev"),
  Var("dart_root") + "/third_party/pkg/sse":
      Var("dart_git") + "sse.git" + "@" + Var("sse_rev"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      Var("dart_git") + "stack_trace.git" + "@" + Var("stack_trace_rev"),
  Var("dart_root") + "/third_party/pkg/stream_channel":
      Var("dart_git") + "stream_channel.git" +
      "@" + Var("stream_channel_rev"),
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
      Var("dart_git") + "test_descriptor.git" + "@" + Var("test_descriptor_rev"),
  Var("dart_root") + "/third_party/pkg/test_process":
      Var("dart_git") + "test_process.git" + "@" + Var("test_process_rev"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      Var("dart_git") + "test_reflective_loader.git" +
      "@" + Var("test_reflective_loader_rev"),
  Var("dart_root") + "/third_party/pkg/typed_data":
      Var("dart_git") + "typed_data.git" + "@" + Var("typed_data_rev"),
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
  Var("dart_root") + "/third_party/pkg/yaml_edit":
      Var("dart_git") + "yaml_edit.git" + "@" + Var("yaml_edit_rev"),
  Var("dart_root") + "/third_party/pkg/yaml":
      Var("dart_git") + "yaml.git" + "@" + Var("yaml_rev"),

  Var("dart_root") + "/buildtools/linux-x64/clang": {
      "packages": [
          {
              "package": "fuchsia/third_party/clang/linux-amd64",
              "version": "git_revision:" + Var("clang_revision"),
          },
      ],
      "condition": "host_cpu == x64 and host_os == linux",
      "dep_type": "cipd",
  },
  Var("dart_root") + "/buildtools/mac-x64/clang": {
      "packages": [
          {
              "package": "fuchsia/third_party/clang/mac-amd64",
              "version": "git_revision:" + Var("clang_revision"),
          },
      ],
      # TODO(https://fxbug.dev/73385): Use arm64 toolchain on arm64 when it exists.
      "condition": "host_cpu == x64 and host_os == mac or host_cpu == arm64 and host_os == mac",
      "dep_type": "cipd",
  },
  Var("dart_root") + "/buildtools/win-x64/clang": {
      "packages": [
          {
              "package": "fuchsia/third_party/clang/windows-amd64",
              "version": "git_revision:" + Var("clang_revision"),
          },
      ],
      "condition": "host_cpu == x64 and host_os == win",
      "dep_type": "cipd",
  },
  Var("dart_root") + "/buildtools/linux-arm64/clang": {
      "packages": [
          {
              "package": "fuchsia/third_party/clang/linux-arm64",
              "version": "git_revision:" + Var("clang_revision"),
          },
      ],
      "condition": "host_os == 'linux' and host_cpu == 'arm64'",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/webdriver/chrome": {
    "packages": [
      {
        "package": "dart/third_party/chromedriver/${{platform}}",
        "version": "version:" + Var("chrome_tag"),
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
            "package": "flutter/android/ndk/${{os}}-amd64",
            "version": "version:r21.0.6113669"
          }
      ],
      "condition": "download_android_deps",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/android_tools/sdk/build-tools": {
      "packages": [
          {
            "package": "flutter/android/sdk/build-tools/${{os}}-amd64",
            "version": "version:30.0.1"
          }
      ],
      "condition": "download_android_deps",
      "dep_type": "cipd",
  },

  Var("dart_root") + "/third_party/android_tools/sdk/platform-tools": {
     "packages": [
          {
            "package": "flutter/android/sdk/platform-tools/${{os}}-amd64",
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
            "package": "flutter/android/sdk/tools/${{os}}-amd64",
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

  # Update from https://chrome-infra-packages.appspot.com/p/fuchsia/sdk/gn
  Var("dart_root") + "/third_party/fuchsia/sdk/mac": {
    "packages": [
      {
      "package": "fuchsia/sdk/gn/mac-amd64",
      "version": "git_revision:c9bdf5da65647923cb79c391824434125cb00bbe"
      }
    ],
    "condition": 'host_os == "mac" and host_cpu == "x64"',
    "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/fuchsia/sdk/linux": {
    "packages": [
      {
      "package": "fuchsia/sdk/gn/linux-amd64",
      "version": "git_revision:c9bdf5da65647923cb79c391824434125cb00bbe"
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
  Var("dart_root") + "/benchmarks/NativeCall/native/out/": {
      "packages": [
          {
              "package": "dart/benchmarks/nativecall",
              "version": "w1JKzCIHSfDNIjqnioMUPq0moCXKwX67aUfhyrvw4E0C",
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
    # Generate the .dart_tool/package_confg.json file.
    'name': 'Generate .dart_tool/package_confg.json',
    'pattern': '.',
    'action': ['python3', 'sdk/tools/generate_package_config.py'],
  },
  {
    # Generate the sdk/version file.
    'name': 'Generate sdk/version',
    'pattern': '.',
    'action': ['python3', 'sdk/tools/generate_sdk_version_file.py'],
  },
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
