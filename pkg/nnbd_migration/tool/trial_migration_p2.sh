#!/usr/bin/env bash
#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

TRIAL_MIGRATION=`dirname "$0"`/trial_migration.dart

# Priority Two, Group One, as defined at go/dart-null-safety-migration-order.
p2g1 () {
  echo "-g https://github.com/google/ansicolor-dart.git"
  echo "-g https://dart.googlesource.com/args.git"
  echo "-p dart_internal"
  echo "-g https://dart.googlesource.com/fixnum.git"
  echo "-g https://github.com/google/inject.dart.git"
  echo "-p js"
  echo "-g https://github.com/a14n/dart-js-wrapping.git"
  echo "-g https://dart.googlesource.com/mime.git"
  echo "-g https://github.com/xxgreg/mustache.git"
  echo "-g https://github.com/leonsenft/path_to_regexp.git"
  echo "-g https://github.com/petitparser/dart-petitparser.git"
  echo "-g https://github.com/google/platform.dart.git"
  echo "-g https://github.com/dart-lang/stream_transform.git"
  echo "-g https://github.com/dart-lang/sync_http.git"
  echo "-g https://github.com/srawlins/timezone.git"
}

# Priority Two, Group Two, as defined at go/dart-null-safety-migration-order.
p2g2 () {
  echo "-g https://github.com/google/ansicolor-dart.git"
  echo "-g https://dart.googlesource.com/cli_util.git"
  echo "-g https://github.com/dart-lang/clock.git"
  echo "-g https://github.com/kevmoo/completion.dart.git"
  echo "-g https://dart.googlesource.com/convert.git"
  echo "-g https://github.com/a14n/dart-google-maps.git"
  echo "-g https://github.com/dart-lang/http_server.git"
  echo "-g https://dart.googlesource.com/intl.git"
  echo "-p kernel"
  echo "-g https://dart.googlesource.com/package_config.git"
  # TODO(srawlins): Add protobuf, from monorepo
  #  https://github.com/dart-lang/protobuf.
  echo "-g https://dart.googlesource.com/pub_semver.git"
  echo "-g https://github.com/google/quiver-dart.git"
}

# Priority Two, Group Three, as defined at go/dart-null-safety-migration-order.
p2g3 () {
  # TODO(srawlins): Add android_intent, from monorepo
  #  https://github.com/flutter/plugins/tree/master/packages/android_intent.
  # SDK-only packages.
  echo "-g https://dart.googlesource.com/bazel_worker.git"
  echo "-g https://github.com/google/built_collection.dart.git"
  # TODO(srawlins): Add charts_common, from monorepo
  #  https://github.com/google/charts/tree/master/charts_common.
  echo "-g https://github.com/jathak/cli_repl.git"
  echo "-g https://dart.googlesource.com/crypto.git"
  echo "-g https://dart.googlesource.com/csslib.git"
  echo "-g https://github.com/google/file.dart.git"
  # TODO(srawlins): Add front_end, which currently crashes.
  echo "-g https://github.com/reyerstudio/google-maps-markerclusterer.git"
  # TODO(srawlins): Add google_sign_in, from monorepo
  #  https://github.com/flutter/plugins/tree/master/packages/google_sign_in.
  echo "-g https://dart.googlesource.com/http_multi_server.git"
  echo "-g https://github.com/dart-lang/observable.git"
  # TODO(srawlins): Add package_info, from monorepo
  #  https://github.com/flutter/plugins/tree/master/packages/package_info.
  echo "-g https://dart.googlesource.com/pool.git"
  # TODO(srawlins): Add protoc_plugin, from monorepo
  #  https://github.com/dart-lang/protobuf.
  echo "-g https://github.com/google/quiver-log.git"
  # TODO(srawlins): Add shared_preferences, from monorepo
  #  https://github.com/flutter/plugins/tree/master/packages/shared_preferences.
  echo "-g https://dart.googlesource.com/source_maps.git"
  echo "-g https://dart.googlesource.com/string_scanner.git"
  echo "-g https://github.com/renggli/dart-xml.git"
}

# Priority Two, Group Four, as defined at go/dart-null-safety-migration-order.
p2g4 () {
  echo "-g https://github.com/brendan-duncan/archive.git"
  # TODO(srawlins): Add built_value, from monorepo
  #  https://github.com/google/built_value.dart
  # Not including charted; concern is internal copy; not old published copy.
  echo "-g https://dart.googlesource.com/glob.git"
  echo "-g https://dart.googlesource.com/html.git"
  echo "-g https://dart.googlesource.com/http_parser.git"
  echo "-g https://dart.googlesource.com/json_rpc_2.git"
  # Not including observe; concern is internal copy; not old published copy.
  echo "-g https://github.com/google/process.dart.git"
  # Not including scissors; concern is internal copy; not old published copy.
}

# Priority Two, Group Five, as defined at go/dart-null-safety-migration-order.
p2g5 () {
  echo "-p analyzer"
  # Not including angular_forms; concern is internal copy; not old published copy.
  # Not including angular_router; concern is internal copy; not old published copy.
  # Not including angular_test; concern is internal copy; not old published copy.
  echo "-g https://github.com/dart-lang/code_builder.git"
  echo "-g https://dart.googlesource.com/http.git"
  echo "-g https://github.com/brendan-duncan/image.git"
  echo "-g https://dart.googlesource.com/shelf.git"
}

# Priority Two, Group Six, as defined at go/dart-null-safety-migration-order.
p2g6 () {
  echo "-p analyzer_plugin"
  # TODO(srawlins): Add build, from monorepo
  #  https://github.com/dart-lang/build/tree/master/build.
  echo "-g https://github.com/dart-lang/coverage.git"
  echo "-g https://dart.googlesource.com/dart_style.git"
  # TODO(srawlins): Add flutter_test.
  echo "-g https://github.com/dart-lang/googleapis_auth.git"
  echo "-g https://github.com/dart-lang/intl_translation.git"
  echo "-g https://dart.googlesource.com/mockito.git"
  echo "-g https://dart.googlesource.com/package_resolver.git"
  # Not including pageloader ("2"); concern is internal copy; not old published copy.
  echo "-g https://dart.googlesource.com/shelf_static.git"
  echo "-g https://dart.googlesource.com/shelf_web_socket.git"
}

# Priority Two, Group Seven, as defined at go/dart-null-safety-migration-order.
p2g7 () {
  echo "-g https://github.com/dart-lang/grpc-dart.git"
  echo "-g https://github.com/google/pageloader.git" # This is pageloader3.
  echo "-g https://github.com/sass/dart-sass.git"
  echo "-g https://dart.googlesource.com/shelf_packages_handler.git"
  # TODO(srawlins): Add source_gen.
  echo "-g https://dart.googlesource.com/source_map_stack_trace.git"
}

# Priority Two, Group Eight, as defined at go/dart-null-safety-migration-order.
p2g8 () {
  # Not including angular_compiler; concern is internal copy; not old published copy.
  # TODO(srawlins): Add built_value_generator, from monorepo
  #  https://github.com/google/built_value.dart.
  # TODO(srawlins): Add flutter_tools, from monorepo
  #  https://github.com/flutter/flutter.
  # TODO(srawlins): Locate and add rpc_client.
  echo ""
}

# The current "official" set of parameters for the trial_migration script.
set -x
dart --enable-asserts ${TRIAL_MIGRATION} \
  $(p2g1) $(p2g2) $(p2g3) $(p2g4) $(p2g5) $(p2g6) $(p2g7) $(p2g8) \
  "$@"
