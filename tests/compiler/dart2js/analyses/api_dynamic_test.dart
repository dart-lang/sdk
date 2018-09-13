// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'analysis_helper.dart';

// TODO(johnniwinther): Remove unneeded dynamic accesses.
const Map<String, List<String>> allowedList = {
  'sdk/lib/_http/crypto.dart': null,
  'sdk/lib/_http/http_date.dart': null,
  'sdk/lib/_http/http_headers.dart': null,
  'sdk/lib/_http/http_impl.dart': null,
  'sdk/lib/_http/http_parser.dart': null,
  'sdk/lib/_http/websocket_impl.dart': null,
  'sdk/lib/_internal/js_runtime/lib/async_patch.dart': null,
  'sdk/lib/_internal/js_runtime/lib/collection_patch.dart': null,
  'sdk/lib/_internal/js_runtime/lib/constant_map.dart': null,
  'sdk/lib/_internal/js_runtime/lib/convert_patch.dart': null,
  'sdk/lib/_internal/js_runtime/lib/core_patch.dart': null,
  'sdk/lib/_internal/js_runtime/lib/interceptors.dart': null,
  'sdk/lib/_internal/js_runtime/lib/js_helper.dart': null,
  'sdk/lib/_internal/js_runtime/lib/js_number.dart': null,
  'sdk/lib/_internal/js_runtime/lib/js_rti.dart': null,
  'sdk/lib/_internal/js_runtime/lib/linked_hash_map.dart': null,
  'sdk/lib/_internal/js_runtime/lib/native_helper.dart': null,
  'sdk/lib/_internal/js_runtime/lib/native_typed_data.dart': null,
  'sdk/lib/_internal/js_runtime/lib/regexp_helper.dart': null,
  'sdk/lib/_internal/js_runtime/lib/string_helper.dart': null,
  'sdk/lib/async/async_error.dart': null,
  'sdk/lib/async/future.dart': null,
  'sdk/lib/async/stream.dart': null,
  'sdk/lib/collection/hash_map.dart': null,
  'sdk/lib/collection/iterable.dart': null,
  'sdk/lib/collection/splay_tree.dart': null,
  'sdk/lib/convert/encoding.dart': null,
  'sdk/lib/convert/json.dart': null,
  'sdk/lib/convert/string_conversion.dart': null,
  'sdk/lib/core/date_time.dart': null,
  'sdk/lib/core/duration.dart': null,
  'sdk/lib/core/errors.dart': null,
  'sdk/lib/core/exceptions.dart': null,
  'sdk/lib/core/uri.dart': null,
  'sdk/lib/html/dart2js/html_dart2js.dart': null,
  'sdk/lib/html/html_common/conversions.dart': null,
  'sdk/lib/html/html_common/filtered_element_list.dart': null,
  'sdk/lib/html/html_common/lists.dart': null,
  'sdk/lib/indexed_db/dart2js/indexed_db_dart2js.dart': null,
  'sdk/lib/io/common.dart': null,
  'sdk/lib/io/directory_impl.dart': null,
  'sdk/lib/io/file_impl.dart': null,
  'sdk/lib/io/file_system_entity.dart': null,
  'sdk/lib/io/io_resource_info.dart': null,
  'sdk/lib/io/link.dart': null,
  'sdk/lib/io/platform_impl.dart': null,
  'sdk/lib/io/secure_server_socket.dart': null,
  'sdk/lib/io/secure_socket.dart': null,
  'sdk/lib/io/stdio.dart': null,
  'sdk/lib/isolate/isolate.dart': null,
  'sdk/lib/js/dart2js/js_dart2js.dart': null,
  'sdk/lib/math/point.dart': null,
  'sdk/lib/math/rectangle.dart': null,
  'sdk/lib/svg/dart2js/svg_dart2js.dart': null,
};

main(List<String> args) {
  asyncTest(() async {
    await run(Uri.parse('memory:main.dart'),
        memorySourceFiles: {'main.dart': 'main() {}'},
        allowedList: allowedList,
        verbose: args.contains('-v'));
  });
}
