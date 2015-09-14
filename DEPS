# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

vars = {
  # The dart_root is the root of our sdk checkout. This is normally
  # simply sdk, but if using special gclient specs it can be different.
  "dart_root": "sdk",

  # The svn location to pull out dependencies from
  "third_party": "http://dart.googlecode.com/svn/third_party",

  # The svn location for pulling pinned revisions of bleeding edge dependencies.
  "bleeding_edge": "http://dart.googlecode.com/svn/branches/bleeding_edge",

  # Use this googlecode_url variable only if there is an internal mirror for it.
  # If you do not know, use the full path while defining your new deps entry.
  "googlecode_url": "http://%s.googlecode.com/svn",

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

  "gyp_rev": "@6ee91ad8659871916f9aa840d42e1513befdf638",
  "co19_rev": "@f95f109fea67127a220958794ef5200a63cb454c",
  "chromium_url": "http://src.chromium.org/svn",
  "chromium_git": "https://chromium.googlesource.com",

  # Revisions of /third_party/* dependencies.
  "7zip_rev" : "@19997",
  "analyzer_cli_rev" : "@0b89a16c0566f36676fa8f2016eb2c332178f616",
  "args_tag": "@0.13.0",
  "async_tag": "@1.2.0",
  "barback_tag" : "@0.15.2+6",
  "boringssl_rev" : "@daeafc22c66ad48f6b32fc8d3362eb9ba31b774e",
  "charcode_tag": "@1.1.0",
  "chrome_rev" : "@19997",
  "clang_rev" : "@28450",
  "cli_util_tag" : "@0.0.1+2",
  "collection_rev": "@1da9a07f32efa2ba0c391b289e2037391e31da0e",
  "crypto_rev" : "@2df57a1e26dd88e8d0614207d4b062c73209917d",
  "csslib_tag" : "@0.12.0",
  "dart2js_info_rev" : "@bad01369f1f605ab688d505c135db54de927318f",
  "dartdoc_rev" : "@ae12ca7aa2ea15535fac9e262cab65e3c2b66a04",
  "dart_services_rev" : "@7aea2574e6f3924bf409a80afb8ad52aa2be4f97",
  "dart_style_tag": "@0.2.0",
  "dev_compiler_rev": "@0.1.7",
  "fake_async_rev" : "@38614",
  "firefox_jsshell_rev" : "@45554",
  "glob_rev": "@704cf75e4f26b417505c5c611bdaacd8808467dd",
  "gsutil_rev" : "@33376",
  "html_tag" : "@0.12.1+1",
  "http_rev" : "@9b93e1542c753090c50b46ef1592d44bc858bfe7",
  "http_multi_server_tag" : "@1.3.2",
  "http_parser_rev" : "@8b179e36aba985208e4c5fb15cfddd386b6370a4",
  "http_throttle_rev" : "@a81f08be942cdd608883c7b67795c12226abc235",
  "idl_parser_rev": "@6316d5982dc24b34d09dd8b10fbeaaff28d83a48",
  "intl_rev": "@32047558bd220a53c1f4d93a26d54b83533b1475",
  "jinja2_rev": "@2222b31554f03e62600cd7e383376a7c187967a1",
  "json_rpc_2_tag": "@1.1.1",
  "linter_rev": "@140ee2d1d7a255cf1265e990e528c6575ab2d5bb",
  "logging_rev": "@85d83e002670545e9039ad3985f0018ab640e597",
  "markdown_rev": "@9a1071a859df9c9edd4f556e948f898f70bf1e5e",
  "matcher_tag": "@0.12.0",
  "metatest_rev": "@e5aa8e4e19fc4188ac2f6d38368a47d8f07c3df1",
  "mime_rev": "@75890811d4af5af080351ba8a2853ad4c8df98dd",
  "mustache4dart_rev" : "@5724cfd85151e5b6b53ddcd3380daf188fe47f92",
  "oauth2_rev": "@1bff41f4d54505c36f2d1a001b83b8b745c452f5",
  "observe_rev": "@eee2b8ec34236fa46982575fbccff84f61202ac6",
  "observatory_pub_packages_rev": "@cdc4b3d4c15b9c0c8e7702dff127b440afbb7485",
  "package_config_rev": "@0.1.3",
  "path_tag": "@1.3.6",
  "petitparser_rev" : "@37878",
  "ply_rev": "@604b32590ffad5cbb82e4afef1d305512d06ae93",
  "plugin_tag": "@0.1.0",
  "pool_rev": "@e454b4b54d2987e8d2f0fbd3ac519641ada9bd0f",
  "pub_rev": "@1c08b841158e33b8090bb07e5c39df830db58d44",
  "pub_cache_tag": "@v0.1.0",
  "pub_semver_tag": "@1.2.1",
  "quiver_tag": "@0.21.4",
  "root_certificates_rev": "@c3a41df63afacec62fcb8135196177e35fe72f71",
  "scheduled_test_tag": "@0.12.1+2",
  "shelf_tag": "@0.6.2+1",
  "smoke_rev" : "@f3361191cc2a85ebc1e4d4c33aec672d7915aba9",
  "source_maps_tag": "@0.10.1",
  "shelf_static_tag": "@0.2.3+1",
  "shelf_web_socket_tag": "@0.0.1+4",
  "source_map_stack_trace_tag": "@1.0.4",
  "source_span_tag": "@1.2.0",
  "stack_trace_tag": "@1.3.4",
  "string_scanner_tag": "@0.1.4",
  "sunflower_rev": "@879b704933413414679396b129f5dfa96f7a0b1e",
  "test_tag": "@0.12.3+8",
  "test_reflective_loader_tag": "@0.0.3",
  "utf_rev": "@1f55027068759e2d52f2c12de6a57cce5f3c5ee6",
  "unittest_tag": "@0.11.6",
  "usage_rev": "@b5080dac0d26a5609b266f8fdb0d053bc4c1c638",
  "watcher_tag": "@0.9.7",
  "when_tag": "@0.2.0+2",
  "which_tag": "@0.1.3+1",
  "web_components_rev": "@0e636b534d9b12c9e96f841e6679398e91a986ec",
  "WebCore_rev" : "@44061",
  "yaml_tag": "@2.1.5",
  "zlib_rev": "@c3d0a6190f2f8c924a05ab6cc97b8f975bddd33f",
  "font_awesome_rev": "@31824",
  "barback-0.13.0_rev": "@34853",
  "barback-0.14.0_rev": "@36398",
  "barback-0.14.1_rev": "@38525",
  "source_maps-0.9.4_rev": "@38524",
}

deps = {
  # Stuff needed for GYP to run.
  Var("dart_root") + "/third_party/gyp":
      Var('chromium_git') + '/external/gyp.git' + Var("gyp_rev"),

  Var("dart_root") + "/tests/co19/src":
      (Var("github_mirror") % "co19") + Var("co19_rev"),

  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      Var("zlib_rev"),

  Var("dart_root") + "/third_party/boringssl/src":
      "https://boringssl.googlesource.com/boringssl.git" +
      Var("boringssl_rev"),

  Var("dart_root") + "/third_party/root_certificates":
      "https://github.com/dart-lang/root_certificates.git" +
      Var("root_certificates_rev"),

  Var("dart_root") + "/third_party/jinja2":
      Var("chromium_git") + "/chromium/src/third_party/jinja2.git" +
      Var("jinja2_rev"),

  Var("dart_root") + "/third_party/ply":
      Var("chromium_git") + "/chromium/src/third_party/ply.git" +
      Var("ply_rev"),

  Var("dart_root") + "/third_party/idl_parser":
      Var("chromium_git") + "/chromium/src/tools/idl_parser.git" +
      Var("idl_parser_rev"),

  Var("dart_root") + "/third_party/7zip":
     Var("third_party") + "/7zip" + Var("7zip_rev"),
  Var("dart_root") + "/third_party/chrome":
      Var("third_party") + "/chrome" + Var("chrome_rev"),
  Var("dart_root") + "/third_party/pkg/fake_async":
      Var("third_party") + "/fake_async" + Var("fake_async_rev"),
  Var("dart_root") + "/third_party/firefox_jsshell":
      Var("third_party") + "/firefox_jsshell" + Var("firefox_jsshell_rev"),
  Var("dart_root") + "/third_party/font-awesome":
      Var("third_party") + "/font-awesome" + Var("font_awesome_rev"),
  Var("dart_root") + "/third_party/gsutil":
      Var("third_party") + "/gsutil" + Var("gsutil_rev"),
  Var("dart_root") + "/third_party/pkg/petitparser":
      Var("third_party") + "/petitparser" + Var("petitparser_rev"),
  Var("dart_root") + "/third_party/WebCore":
      Var("third_party") + "/WebCore" + Var("WebCore_rev"),

  Var("dart_root") + "/third_party/dart-services":
      (Var("github_mirror") % "dart-services") +
      Var("dart_services_rev"),

  Var("dart_root") + "/third_party/pkg/analyzer_cli":
      (Var("github_mirror") % "analyzer_cli") + Var("analyzer_cli_rev"),
  Var("dart_root") + "/third_party/pkg/args":
      (Var("github_mirror") % "args") + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async":
      (Var("github_mirror") % "async") + Var("async_tag"),
  Var("dart_root") + "/third_party/pkg/barback":
      (Var("github_mirror") % "barback") + Var("barback_tag"),
  Var("dart_root") + "/third_party/pkg/charcode":
      (Var("github_mirror") % "charcode") + Var("charcode_tag"),
  Var("dart_root") + "/third_party/pkg/cli_util":
      (Var("github_mirror") % "cli_util") + Var("cli_util_tag"),
  Var("dart_root") + "/third_party/pkg/collection":
      (Var("github_mirror") % "collection") + Var("collection_rev"),
  Var("dart_root") + "/third_party/pkg/crypto":
      (Var("github_mirror") % "crypto") + Var("crypto_rev"),
  Var("dart_root") + "/third_party/pkg/csslib":
      (Var("github_mirror") % "csslib") + Var("csslib_tag"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      (Var("github_mirror") % "dart_style") + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/dart2js_info":
      (Var("github_mirror") % "dart2js_info") + Var("dart2js_info_rev"),
  Var("dart_root") + "/third_party/pkg/dartdoc":
      (Var("github_mirror") % "dartdoc") + Var("dartdoc_rev"),
  Var("dart_root") + "/third_party/pkg/dev_compiler":
      (Var("github_mirror") % "dev_compiler") + Var("dev_compiler_rev"),
  Var("dart_root") + "/third_party/pkg/glob":
      (Var("github_mirror") % "glob") + Var("glob_rev"),
  Var("dart_root") + "/third_party/pkg/html":
      (Var("github_mirror") % "html") + Var("html_tag"),
  Var("dart_root") + "/third_party/pkg/http":
      (Var("github_mirror") % "http") + Var("http_rev"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      (Var("github_mirror") % "http_multi_server") +
      Var("http_multi_server_tag"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      (Var("github_mirror") % "http_parser") + Var("http_parser_rev"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      (Var("github_mirror") % "http_throttle") +
      Var("http_throttle_rev"),
  Var("dart_root") + "/third_party/pkg/intl":
      (Var("github_mirror") % "intl") + Var("intl_rev"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      (Var("github_mirror") % "json_rpc_2") + Var("json_rpc_2_tag"),
  Var("dart_root") + "/third_party/pkg/linter":
      (Var("github_mirror") % "linter") + Var("linter_rev"),
  Var("dart_root") + "/third_party/pkg/logging":
      (Var("github_mirror") % "logging") + Var("logging_rev"),
  Var("dart_root") + "/third_party/pkg/markdown":
      (Var("github_mirror") % "markdown") + Var("markdown_rev"),
  Var("dart_root") + "/third_party/pkg/matcher":
      (Var("github_mirror") % "matcher") + Var("matcher_tag"),
  Var("dart_root") + "/third_party/pkg/metatest":
      (Var("github_mirror") % "metatest") + Var("metatest_rev"),
  Var("dart_root") + "/third_party/pkg/mime":
      (Var("github_mirror") % "mime") + Var("mime_rev"),
  Var("dart_root") + "/third_party/pkg/mustache4dart":
      Var("chromium_git")
      + "/external/github.com/valotas/mustache4dart.git"
      + Var("mustache4dart_rev"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      (Var("github_mirror") % "oauth2") + Var("oauth2_rev"),
  Var("dart_root") + "/third_party/pkg/observe":
      (Var("github_mirror") % "observe") + Var("observe_rev"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
     (Var("github_mirror") % "observatory_pub_packages")
      + Var("observatory_pub_packages_rev"),
  Var("dart_root") + "/third_party/pkg_tested/package_config":
      (Var("github_mirror") % "package_config") +
      Var("package_config_rev"),
  Var("dart_root") + "/third_party/pkg/path":
      (Var("github_mirror") % "path") + Var("path_tag"),
  Var("dart_root") + "/third_party/pkg/plugin":
      (Var("github_mirror") % "plugin") + Var("plugin_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      (Var("github_mirror") % "pool") + Var("pool_rev"),
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
  Var("dart_root") + "/third_party/pkg/scheduled_test":
      (Var("github_mirror") % "scheduled_test") + Var("scheduled_test_tag"),
  Var("dart_root") + "/third_party/pkg/shelf":
      (Var("github_mirror") % "shelf") + Var("shelf_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_static":
      (Var("github_mirror") % "shelf_static") + Var("shelf_static_tag"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      (Var("github_mirror") % "shelf_web_socket") +
      Var("shelf_web_socket_tag"),
  Var("dart_root") + "/third_party/pkg/smoke":
      (Var("github_mirror") % "smoke") + Var("smoke_rev"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      (Var("github_mirror") % "source_maps") + Var("source_maps_tag"),
  Var("dart_root") + "/third_party/pkg/source_span":
      (Var("github_mirror") % "source_span") + Var("source_span_tag"),
  Var("dart_root") + "/third_party/pkg/source_map_stack_trace":
      (Var("github_mirror") % "source_map_stack_trace") +
      Var("source_map_stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      (Var("github_mirror") % "stack_trace") + Var("stack_trace_tag"),
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
  Var("dart_root") + "/third_party/pkg/unittest":
      (Var("github_mirror") % "test") + Var("unittest_tag"),
  Var("dart_root") + "/third_party/pkg/usage":
      (Var("github_mirror") % "usage") + Var("usage_rev"),
  Var("dart_root") + "/third_party/pkg/utf":
      (Var("github_mirror") % "utf") + Var("utf_rev"),
  Var("dart_root") + "/third_party/pkg/watcher":
      (Var("github_mirror") % "watcher") + Var("watcher_tag"),
  Var("dart_root") + "/third_party/pkg/web_components":
      (Var("github_mirror") % "web-components") +
      Var("web_components_rev"),
  Var("dart_root") + "/third_party/pkg/when":
      (Var("github_mirror") % "when") + Var("when_tag"),
  Var("dart_root") + "/third_party/pkg/which":
      (Var("github_mirror") % "which") + Var("which_tag"),
  Var("dart_root") + "/third_party/pkg/yaml":
      (Var("github_mirror") % "yaml") + Var("yaml_tag"),

  # These specific versions of barback and source_maps are used for testing and
  # should be pulled from bleeding_edge even on channels.
  Var("dart_root") + "/third_party/pkg/barback-0.13.0":
      Var("bleeding_edge") + "/dart/pkg/barback" + Var("barback-0.13.0_rev"),
  Var("dart_root") + "/third_party/pkg/barback-0.14.0+3":
      Var("bleeding_edge") + "/dart/pkg/barback" + Var("barback-0.14.0_rev"),
  Var("dart_root") + "/third_party/pkg/barback-0.14.1+4":
      Var("bleeding_edge") + "/dart/pkg/barback" + Var("barback-0.14.1_rev"),
  Var("dart_root") + "/third_party/pkg/source_maps-0.9.4":
      Var("bleeding_edge") + "/dart/pkg/source_maps" +
      Var("source_maps-0.9.4_rev"),
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
    Var("dart_root") + "/third_party/drt_resources":
      Var("chromium_url") +
      "/trunk/src/webkit/tools/test_shell/resources@157099",
  },
  "unix": {
    Var("dart_root") + "/third_party/clang":
      Var("third_party") + "/clang" + Var("clang_rev"),
  },
}

# TODO(iposva): Move the necessary tools so that hooks can be run
# without the runtime being available.
hooks = [
  {
    "pattern": ".",
    "action": ["python", Var("dart_root") + "/tools/gyp_dart.py"],
  },
  {
    'name': 'checked_in_dart_binaries',
    'pattern': '.',
    'action': [
      'download_from_google_storage',
      '--no_auth',
      '--no_resume',
      '--bucket',
      'dart-dependencies',
      '--recursive',
      '--directory',
      Var('dart_root') + '/tools/testing/bin',
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
]
