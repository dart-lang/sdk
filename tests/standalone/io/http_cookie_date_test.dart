// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.io;

import "package:expect/expect.dart";
import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:developer";
import "dart:math";
import "dart:typed_data";
import "dart:isolate";

part "../../../sdk/lib/io/bytes_builder.dart";
part "../../../sdk/lib/io/common.dart";
part "../../../sdk/lib/io/crypto.dart";
part "../../../sdk/lib/io/data_transformer.dart";
part "../../../sdk/lib/io/directory.dart";
part "../../../sdk/lib/io/directory_impl.dart";
part "../../../sdk/lib/io/file.dart";
part "../../../sdk/lib/io/file_impl.dart";
part "../../../sdk/lib/io/file_system_entity.dart";
part "../../../sdk/lib/io/link.dart";
part "../../../sdk/lib/io/http.dart";
part "../../../sdk/lib/io/http_impl.dart";
part "../../../sdk/lib/io/http_date.dart";
part "../../../sdk/lib/io/http_parser.dart";
part "../../../sdk/lib/io/http_headers.dart";
part "../../../sdk/lib/io/http_session.dart";
part "../../../sdk/lib/io/io_resource_info.dart";
part "../../../sdk/lib/io/io_service.dart";
part "../../../sdk/lib/io/io_sink.dart";
part "../../../sdk/lib/io/platform.dart";
part "../../../sdk/lib/io/platform_impl.dart";
part "../../../sdk/lib/io/service_object.dart";
part "../../../sdk/lib/io/secure_socket.dart";
part "../../../sdk/lib/io/secure_server_socket.dart";
part "../../../sdk/lib/io/security_context.dart";
part "../../../sdk/lib/io/socket.dart";

void testParseHttpCookieDate() {
  Expect.throws(() => HttpDate._parseCookieDate(""));

  test(int year, int month, int day, int hours, int minutes, int seconds,
      String formatted) {
    DateTime date =
        new DateTime.utc(year, month, day, hours, minutes, seconds, 0);
    Expect.equals(date, HttpDate._parseCookieDate(formatted));
  }

  test(2012, DateTime.JUNE, 19, 14, 15, 01, "tue, 19-jun-12 14:15:01 gmt");
  test(2021, DateTime.JUNE, 09, 10, 18, 14, "Wed, 09-Jun-2021 10:18:14 GMT");
  test(2021, DateTime.JANUARY, 13, 22, 23, 01, "Wed, 13-Jan-2021 22:23:01 GMT");
  test(2013, DateTime.JANUARY, 15, 21, 47, 38, "Tue, 15-Jan-2013 21:47:38 GMT");
  test(1970, DateTime.JANUARY, 01, 00, 00, 01, "Thu, 01-Jan-1970 00:00:01 GMT");
}

void main() {
  testParseHttpCookieDate();
}
