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
  "sdk_tag": "version:2.15.1",

  # co19 is a cipd package. Use update.sh in tests/co19[_2] to update these
  # hashes. It requires access to the dart-build-access group, which EngProd
  # has.
  "co19_rev": "a38d7c5685e64499cfbdbfe6548fbd5b63b57f15",
  # This line prevents conflicts when both packages are rolled simultaneously.
  "co19_2_rev": "995745937abffe9fc3a6441f9f0db27b2d706e4c",

  # The internal benchmarks to use. See go/dart-benchmarks-internal
  "benchmarks_internal_rev": "076df10d9b77af337f2d8029725787155eb1cd52",
  "checkout_benchmarks_internal": False,

  # Checkout Android dependencies only on Mac and Linux.
  "download_android_deps":
    "(host_os == mac or host_os == linux) and host_cpu == x64",

  # Checkout extra javascript engines for testing or benchmarking.
  # d8, the V8 shell, is always checked out.
  "checkout_javascript_engines": False,
  "d8_tag": "version:10.0.40",
  "jsshell_tag": "version:95.0",

  # As Flutter does, we use Fuchsia's GN and Clang toolchain. These revision
  # should be kept up to date with the revisions pulled by the Flutter engine.
  # The list of revisions for these tools comes from Fuchsia, here:
  # https://fuchsia.googlesource.com/integration/+/HEAD/prebuilts
  # If there are problems with the toolchain, contact fuchsia-toolchain@.
  "clang_revision": "e3a7f0e2f9ab566bd9b71fb54fe77e947b061a12",
  "gn_revision": "b79031308cc878488202beb99883ec1f2efd9a6d",

  # Scripts that make 'git cl format' work.
  "clang_format_scripts_rev": "c09c8deeac31f05bd801995c475e7c8070f9ecda",

  "gperftools_revision": "180bfa10d7cb38e8b3784d60943d50e8fcef0dcb",

  # Revisions of /third_party/* dependencies.
  "args_rev": "3b3f55766af13d895d2020ec001a28e8dc147f91",
  "async_rev": "80886150a5e6c58006c8ae5a6c2aa7108638e2a9",
  "bazel_worker_rev": "ceeba0982d4ff40d32371c9d35f3d2dc1868de20",
  "benchmark_harness_rev": "c546dbd9f639f75cd2f75de8df2eb9f8ea15e8e7",
  "boolean_selector_rev": "665e6921ab246569420376f827bff4585dff0b14",
  "boringssl_gen_rev": "ced85ef0a00bbca77ce5a91261a5f2ae61b1e62f",
  "boringssl_rev" : "87f316d7748268eb56f2dc147bd593254ae93198",
  "browser-compat-data_tag": "v1.0.22",
  "browser_launcher_rev": "c6cc1025d6901926cf022e144ba109677e3548f1",
  "characters_rev": "6ec389c4dfa8fce14820dc5cbf6e693202e7e052",
  "charcode_rev": "84ea427711e24abf3b832923959caa7dd9a8514b",
  "chrome_rev" : "19997",
  "cli_util_rev" : "b0adbba89442b2ea6fef39c7a82fe79cb31e1168",
  "clock_rev" : "a494269254ba978e7ef8f192c5f7fec3fc05b9d3",
  "collection_rev": "a4c941ab94044d118b2086a3f261c30377604127",
  "convert_rev": "e063fdca4bebffecbb5e6aa5525995120982d9ce",
  "crypto_rev": "b5024e4de2b1c474dd558bef593ddbf0bfade152",
  "csslib_rev": "f746368a0a53cf8f68fd71b218239034e88841d5",

  # Note: Updates to dart_style have to be coordinated with the infrastructure
  # team so that the internal formatter `tools/sdks/dart-sdk/bin/dart format`
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
  "dart_style_rev": "6f894c0ca33686122be9085f06e5b9bf6ad55262",

  "dartdoc_rev" : "b3927dd89d6ff9c78dc88ab2901e63b6a3bf29b7",
  "devtools_rev" : "3b054edf3a14a4a51bc8019f456efcf0073cd626",
  "ffi_rev": "4dd32429880a57b64edaf54c9d5af8a9fa9a4ffb",
  "fixnum_rev": "848341f061359ef7ddc0cad472c2ecbb036b28ac",
  "file_rev": "0e09370f581ab6388d46fda4cdab66638c0171a1",
  "glob_rev": "da1f4595ee2f87982cbcc663d4cac244822d9227",
  "html_rev": "3c2448108b431dd00d3a7033d9f43f19fa5d93d3",
  "http_io_rev": "2fa188caf7937e313026557713f7feffedd4978b",
  "http_multi_server_rev": "34bf7f04b61cce561f47f7f275c2cc811534a05a",
  "http_parser_rev": "202391286ddc13c4c3c284ac5b511f04697250ed",
  "http_rev": "1e42ffa181b263f7790f276a5465832bff7ce615",
  "icu_rev" : "81d656878ec611cb0b42d52c82e9dae93920d9ba",
  "intl_tag": "0.17.0-nullsafety",
  "jinja2_rev": "2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_rev": "7e00f893440a72de0637970325e4ea44bd1e8c8e",
  "linter_tag": "1.18.0",
  "lints_tag": "f9670df2a66e0ec12eb51554e70c1cbf56c8f5d0",
  "logging_rev": "575781ef196e4fed4fb737e38fb4b73d62727187",
  "markupsafe_rev": "8f45f5cfa0009d2a70589bcda0349b8cb2b72783",
  "markdown_rev": "7479783f0493f6717e1d7ae31cb37d39a91026b2",
  "matcher_rev": "07595a7739d47a8315caba5a8e58fb9ae3d81261",
  "mime_rev": "7f4252d469de032aa4df9f90e827dbac4b8efa48",
  "mockito_rev": "d39ac507483b9891165e422ec98d9fb480037c8b",
  "oauth2_rev": "7cd3284049fe5badbec9f2bea2afc41d14c01057",
  "package_config_rev": "8731bf10b5375542792a32a0f7c8a6f370583d96",
  "path_rev": "baedce9d2ca11ea2cdf54395a74eb038087777a4",
  "pedantic_rev": "66f2f6c27581c7936482e83be80b27be2719901c",
  "platform_rev": "1ffad63428bbd1b3ecaa15926bacfb724023648c",
  "ply_rev": "604b32590ffad5cbb82e4afef1d305512d06ae93",
  "pool_rev": "7abe634002a1ba8a0928eded086062f1307ccfae",
  "process_rev": "56ece43b53b64c63ae51ec184b76bd5360c28d0b",
  "protobuf_rev": "c1eb6cb51af39ccbaa1a8e19349546586a5c8e31",
  "pub_rev": "8f5ab7b1aba3b9f66b56246d77e167990339d317",
  "pub_semver_rev": "a43ad72fb6b7869607581b5fedcb186d1e74276a",
  "root_certificates_rev": "692f6d6488af68e0121317a9c2c9eb393eb0ee50",
  "rust_revision": "b7856f695d65a8ebc846754f97d15814bcb1c244",
  "shelf_static_rev": "202ec1a53c9a830c17cf3b718d089cf7eba568ad",
  "shelf_packages_handler_rev": "78302e67c035047e6348e692b0c1182131f0fe35",
  "shelf_proxy_tag": "v1.0.0",
  "shelf_rev": "46483f896cc4308ee3d8e997030ae799b72aa16a",
  "shelf_web_socket_rev": "24fb8a04befa75a94ac63a27047b231d1a22aab4",
  "source_map_stack_trace_rev": "1c3026f69d9771acf2f8c176a1ab750463309cce",
  "source_maps-0.9.4_rev": "38524",
  "source_maps_rev": "6499ee3adac8d469e2953e2e8ba4bdb4c2fbef90",
  "source_span_rev": "dc189b455d823e2919667f6c5dcb41ab7483bce0",
  "sse_rev": "9084339389eb441d0c0518cddac211a097e78657",
  "stack_trace_rev": "5220580872625ddee41e9ca9a5f3364789b2f0f6",
  "stream_channel_rev": "3fa3e40c75c210d617b8b943b9b8f580e9866a89",
  "string_scanner_rev": "1b63e6e5db5933d7be0a45da6e1129fe00262734",
  "sync_http_rev": "b59c134f2e34d12acac110d4f17f83e5a7db4330",
  "test_descriptor_rev": "ead23c1e7df079ac0f6457a35f7a71432892e527",
  "test_process_rev": "7c73ec8a8a6e0e63d0ec27d70c21ca4323fb5e8f",
  "term_glyph_rev": "6a0f9b6fb645ba75e7a00a4e20072678327a0347",
  "test_reflective_loader_rev": "fcfce37666672edac849d2af6dffc0f8df236a94",
  "test_rev": "099dcc4d052a30c6921489cfbefa1c8531d12975",
  "typed_data_rev": "29ce5a92b03326d0b8035916ac04f528874994bd",
  "usage_rev": "f0cb8f7cce8b675255c81488dbab8cf9f2f56404",
  "vector_math_rev": "0c9f5d68c047813a6dcdeb88ba7a42daddf25025",
  "watcher_rev": "f76997ab0c857dc5537ac0975a9ada92b54ef949",
  "webdriver_rev": "ff5ccb1522edf4bed578ead4d65e0cbc1f2c4f02",
  "web_components_rev": "8f57dac273412a7172c8ade6f361b407e2e4ed02",
  "web_socket_channel_rev": "6448ce532445a8a458fa191d9346df071ae0acad",
  "WebCore_rev": "bcb10901266c884e7b3740abc597ab95373ab55c",
  "webdev_rev": "832b096c0c24798d3df46faa7b7661fe930573c2",
  "webkit_inspection_protocol_rev": "dd6fb5d8b536e19cedb384d0bbf1f5631923f1e8",
  "yaml_edit_rev": "df1452bfe1653286277a1a8f34dddf3e4fbedd9e",
  "yaml_rev": "ad0779d1baa25c6b10a192d080efc45de02b6a32",
  "zlib_rev": "bf44340d1b6be1af8950bbdf664fec0cf5a831cc",
  "crashpad_rev": "bf327d8ceb6a669607b0dbab5a83a275d03f99ed",
  "minichromium_rev": "8d641e30a8b12088649606b912c2bc4947419ccc",
  "googletest_rev": "f854f1d27488996dc8a6db3c9453f80b02585e12",

  # Pinned browser versions used by the testing infrastructure. These are not
  # meant to be downloaded by users for local testing.
  "download_chrome": False,
  "chrome_tag": "91",
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

  # Update from https://chrome-infra-packages.appspot.com/p/fuchsia/sdk/gn
  Var("dart_root") + "/third_party/fuchsia/sdk/mac": {
    "packages": [
      {
      "package": "fuchsia/sdk/gn/mac-amd64",
      "version": "git_revision:190502a955c482431c2edd0525e128423728b662"
      }
    ],
    "condition": 'host_os == "mac" and host_cpu == "x64"',
    "dep_type": "cipd",
  },
  Var("dart_root") + "/third_party/fuchsia/sdk/linux": {
    "packages": [
      {
      "package": "fuchsia/sdk/gn/linux-amd64",
      "version": "git_revision:190502a955c482431c2edd0525e128423728b662"
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
