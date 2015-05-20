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

  "gyp_rev": "@1752",
  "co19_rev": "@801",
  "chromium_url": "http://src.chromium.org/svn",
  "chromium_git": "https://chromium.googlesource.com",

  # Revisions of /third_party/* dependencies.
  "7zip_rev" : "@19997",
  "analyzer_cli_tag" : "@1.0.1",
  "args_tag": "@0.13.0",
  "barback_rev" : "@29ee90dbcf77cfd64632fa2797a4c8a4f29a4b51",
  "chrome_rev" : "@19997",
  "clang_rev" : "@28450",
  "collection_rev": "@1da9a07f32efa2ba0c391b289e2037391e31da0e",
  "crypto_rev" : "@2df57a1e26dd88e8d0614207d4b062c73209917d",
  "csslib_tag" : "@0.12.0",
  "async_await_rev" : "@8b401a9f2e5e81dca5f70dbe7564112a0823dee6",
  "dart_services_rev" : "@7aea2574e6f3924bf409a80afb8ad52aa2be4f97",
  "dart_style_tag": "@0.1.8",
  "d8_rev" : "@39739",
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
  "json_rpc_2_rev": "@a38eefd116d910199de205f962af92fed87c164c",
  "linter_tag": "@0.0.2+3",
  "logging_rev": "@85d83e002670545e9039ad3985f0018ab640e597",
  "markdown_rev": "@56b0fd6c018d6103862d07e8e27407b9ea3b963d",
  "matcher_tag": "@0.12.0",
  "metatest_rev": "@e5aa8e4e19fc4188ac2f6d38368a47d8f07c3df1",
  "mime_rev": "@75890811d4af5af080351ba8a2853ad4c8df98dd",
  "net_nss_rev": "@f81948e9a402db94287a43bb34a07ee0daf56cb5",
  "nss_rev": "@87b96db4268293187d7cf741907a6d5d1d8080e0",
  "oauth2_rev": "@1bff41f4d54505c36f2d1a001b83b8b745c452f5",
  "observe_rev": "@eee2b8ec34236fa46982575fbccff84f61202ac6",
  "observatory_pub_packages_rev": "@45565",
  "package_config_rev": "@286f9cf48448c4563e735a142c6f9442ab57674e",
  "path_rev": "@93b3e2aa1db0ac0c8bab9d341588d77acda60320",
  "petitparser_rev" : "@37878",
  "ply_rev": "@604b32590ffad5cbb82e4afef1d305512d06ae93",
  "plugin_tag": "@0.1.0",
  "pool_rev": "@22e12aeb16ad0b626900dbe79e4a25391ddfb28c",
  "pub_semver_tag": "@1.2.0",
  "scheduled_test_tag": "@0.11.8+1",
  "shelf_rev": "@1e87b79b21ac5e6fa2f93576d6c06eaa65285ef4",
  "smoke_rev" : "@f3361191cc2a85ebc1e4d4c33aec672d7915aba9",
  "source_maps_rev": "@379b4f31c4e2987eb15934d1ad8b419c6cc897b3",
  "sqlite_rev": "@38811b79f42801662adc0458a25270ab690a6b81",
  "shelf_web_socket_rev": "@ff170cec2c0e4e5722cdf47c557be63b5035a602",
  "source_span_rev": "@42501132e43599a151ba6727d340e44442f86c05",
  "stack_trace_tag": "@1.2.1",
  "string_scanner_rev": "@3e7617d6f74ba382e9b6130b1cc12091d89a9bc5",
  "sunflower_rev": "@879b704933413414679396b129f5dfa96f7a0b1e",
  "test_tag": "@0.12.1",
  "test_reflective_loader_tag": "@0.0.3",
  "utf_rev": "@1f55027068759e2d52f2c12de6a57cce5f3c5ee6",
  "unittest_tag": "@0.11.6",
  "usage_rev": "@b5080dac0d26a5609b266f8fdb0d053bc4c1c638",
  "watcher_tag": "@0.9.5",
  "web_components_rev": "@0e636b534d9b12c9e96f841e6679398e91a986ec",
  "WebCore_rev" : "@44061",
  "yaml_rev": "@563a5ffd4a800a2897b8f4dd6b19f2a370df2f2b",
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
      (Var("googlecode_url") % "gyp") + "/trunk" + Var("gyp_rev"),

  Var("dart_root") + "/tests/co19/src": ((Var("googlecode_url") % "co19") +
      "/trunk/co19/tests/co19/src" + Var("co19_rev")),

  Var("dart_root") + "/third_party/nss":
      Var("chromium_git") + "/chromium/deps/nss.git" + Var("nss_rev"),

  Var("dart_root") + "/third_party/sqlite":
      Var("chromium_git") + "/chromium/src/third_party/sqlite.git" +
      Var("sqlite_rev"),

  Var("dart_root") + "/third_party/zlib":
      Var("chromium_git") + "/chromium/src/third_party/zlib.git" +
      Var("zlib_rev"),

  Var("dart_root") + "/third_party/net_nss":
      Var("chromium_git") + "/chromium/src/net/third_party/nss.git" +
      Var("net_nss_rev"),

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
  Var("dart_root") + "/third_party/d8":
      Var("third_party") + "/d8" + Var("d8_rev"),
  Var("dart_root") + "/third_party/WebCore":
      Var("third_party") + "/WebCore" + Var("WebCore_rev"),
  Var("dart_root") + "/third_party/observatory_pub_packages":
      Var("third_party") + "/observatory_pub_packages" +
      Var("observatory_pub_packages_rev"),

  Var("dart_root") + "/third_party/dart-services":
      "https://github.com/dart-lang/dart-services.git" +
      Var("dart_services_rev"),

  Var("dart_root") + "/third_party/pkg_tested/analyzer_cli":
      "https://github.com/dart-lang/analyzer_cli.git" + Var("analyzer_cli_tag"),
  Var("dart_root") + "/third_party/pkg/args":
      "https://github.com/dart-lang/args.git" + Var("args_tag"),
  Var("dart_root") + "/third_party/pkg/async_await":
      "https://github.com/dart-lang/async_await.git" + Var("async_await_rev"),
  Var("dart_root") + "/third_party/pkg/barback":
      "https://github.com/dart-lang/barback.git" + Var("barback_rev"),
  Var("dart_root") + "/third_party/pkg/collection":
      "https://github.com/dart-lang/collection.git" + Var("collection_rev"),
  Var("dart_root") + "/third_party/pkg/crypto":
      "https://github.com/dart-lang/crypto.git" + Var("crypto_rev"),
  Var("dart_root") + "/third_party/pkg/csslib":
      "https://github.com/dart-lang/csslib.git" + Var("csslib_tag"),
  Var("dart_root") + "/third_party/pkg_tested/dart_style":
      "https://github.com/dart-lang/dart_style.git" + Var("dart_style_tag"),
  Var("dart_root") + "/third_party/pkg/glob":
      "https://github.com/dart-lang/glob.git" + Var("glob_rev"),
  Var("dart_root") + "/third_party/pkg/html":
      "https://github.com/dart-lang/html.git" + Var("html_tag"),
  Var("dart_root") + "/third_party/pkg/http":
      "https://github.com/dart-lang/http.git" + Var("http_rev"),
  Var("dart_root") + "/third_party/pkg/http_multi_server":
      "https://github.com/dart-lang/http_multi_server.git" +
      Var("http_multi_server_tag"),
  Var("dart_root") + "/third_party/pkg/http_parser":
      "https://github.com/dart-lang/http_parser.git" + Var("http_parser_rev"),
  Var("dart_root") + "/third_party/pkg/http_throttle":
      "https://github.com/dart-lang/http_throttle.git" +
      Var("http_throttle_rev"),
  Var("dart_root") + "/third_party/pkg/intl":
      "https://github.com/dart-lang/intl.git" + Var("intl_rev"),
  Var("dart_root") + "/third_party/pkg/json_rpc_2":
      "https://github.com/dart-lang/json_rpc_2.git" + Var("json_rpc_2_rev"),
  Var("dart_root") + "/third_party/pkg/linter":
      "https://github.com/dart-lang/linter.git" + Var("linter_tag"),
  Var("dart_root") + "/third_party/pkg/logging":
      "https://github.com/dart-lang/logging.git" + Var("logging_rev"),
  Var("dart_root") + "/third_party/pkg/markdown":
      "https://github.com/dpeek/dart-markdown.git" + Var("markdown_rev"),
  Var("dart_root") + "/third_party/pkg/matcher":
      "https://github.com/dart-lang/matcher.git" + Var("matcher_tag"),
  Var("dart_root") + "/third_party/pkg/metatest":
      "https://github.com/dart-lang/metatest.git" + Var("metatest_rev"),
  Var("dart_root") + "/third_party/pkg/mime":
      "https://github.com/dart-lang/mime.git" + Var("mime_rev"),
  Var("dart_root") + "/third_party/pkg/oauth2":
      "https://github.com/dart-lang/oauth2.git" + Var("oauth2_rev"),
  Var("dart_root") + "/third_party/pkg/observe":
      "https://github.com/dart-lang/observe.git" + Var("observe_rev"),
  Var("dart_root") + "/third_party/pkg/package_config":
      "https://github.com/dart-lang/package_config.git" +
      Var("package_config_rev"),
  Var("dart_root") + "/third_party/pkg/path":
      "https://github.com/dart-lang/path.git" + Var("path_rev"),
  Var("dart_root") + "/third_party/pkg/plugin":
      "https://github.com/dart-lang/plugin.git" + Var("plugin_tag"),
  Var("dart_root") + "/third_party/pkg/pool":
      "https://github.com/dart-lang/pool.git" + Var("pool_rev"),
  Var("dart_root") + "/third_party/pkg/pub_semver":
      "https://github.com/dart-lang/pub_semver.git" + Var("pub_semver_tag"),
  Var("dart_root") + "/third_party/pkg/scheduled_test":
      "https://github.com/dart-lang/scheduled_test.git" +
      Var("scheduled_test_tag"),
  Var("dart_root") + "/third_party/pkg/shelf":
      "https://github.com/dart-lang/shelf.git" + Var("shelf_rev"),
  Var("dart_root") + "/third_party/pkg/shelf_web_socket":
      "https://github.com/dart-lang/shelf_web_socket.git" +
      Var("shelf_web_socket_rev"),
  Var("dart_root") + "/third_party/pkg/smoke":
      "https://github.com/dart-lang/smoke.git" + Var("smoke_rev"),
  Var("dart_root") + "/third_party/pkg/source_maps":
      "https://github.com/dart-lang/source_maps.git" + Var("source_maps_rev"),
  Var("dart_root") + "/third_party/pkg/source_span":
      "https://github.com/dart-lang/source_span.git" + Var("source_span_rev"),
  Var("dart_root") + "/third_party/pkg/stack_trace":
      "https://github.com/dart-lang/stack_trace.git" + Var("stack_trace_tag"),
  Var("dart_root") + "/third_party/pkg/string_scanner":
      "https://github.com/dart-lang/string_scanner.git" +
      Var("string_scanner_rev"),
  Var("dart_root") + "/third_party/sunflower":
      "https://github.com/dart-lang/sample-sunflower.git" +
      Var("sunflower_rev"),
  Var("dart_root") + "/third_party/pkg/test":
      "https://github.com/dart-lang/test.git" + Var("test_tag"),
  Var("dart_root") + "/third_party/pkg/test_reflective_loader":
      "https://github.com/dart-lang/test_reflective_loader.git" + Var("test_reflective_loader_tag"),
  Var("dart_root") + "/third_party/pkg/unittest":
      "https://github.com/dart-lang/test.git" + Var("unittest_tag"),
  Var("dart_root") + "/third_party/pkg/usage":
      "https://github.com/dart-lang/usage.git" + Var("usage_rev"),
  Var("dart_root") + "/third_party/pkg/utf":
      "https://github.com/dart-lang/utf.git" + Var("utf_rev"),
  Var("dart_root") + "/third_party/pkg/watcher":
      "https://github.com/dart-lang/watcher.git" + Var("watcher_tag"),
  Var("dart_root") + "/third_party/pkg/web_components":
      "https://github.com/dart-lang/web-components.git" +
      Var("web_components_rev"),
  Var("dart_root") + "/third_party/pkg/yaml":
      "https://github.com/dart-lang/yaml.git" + Var("yaml_rev"),

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
      '-d',
      '-r',
      Var('dart_root') + '/tools/testing/bin',
    ],
  },
]
