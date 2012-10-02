// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// or details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test date formatting and parsing using locale data read via an http request
 * to a server.
 */

// TODO(alanknight): It would be nice if there were a more general facility
// than this and it could be replaced, possibly the things Graham is working on.
// The following magical comments will cause the test code run via test.py
// to add an extra command starting up a web server that will serve the
// files we are looking for. "dart" will be replaced by the current dart
// VM, and in arguments, $dartDir will be replaced by the current Dart
// root directory.
// ExtraCommand=dart
// ExtraCommandArgs=$dartDir/pkg/intl/test/start_web_server.dart
#library('date_time_format_http_request_test');

#import('../lib/date_format.dart');
#import('../lib/date_symbol_data_http_request.dart');
#import('date_time_format_test_core.dart');
#import('dart:html');
#import('../../../pkg/unittest/unittest.dart');

var url = "http://localhost:8000/dates/";

main() {
  // Initialize one locale just so we know what the list is.
  test('Run everything', () {
    initializeDateFormatting("en_US", url).then(expectAsync1(runEverything));});
}

void runEverything(_) {
  // Initialize all locales and wait for them to finish before running tests.
  var futures = DateFormat.allLocalesWithSymbols().map(
      (locale) => initializeDateFormatting(locale, url));
  Futures.wait(futures).then(expectAsync1((_) {
      runDateTests();
      shutDown();}));
}

void shutDown() {
  // The tiny web server knows to use this request as a cue to terminate.
  var source = '${url}terminate';
  var request = new HttpRequest.get(source, (_) {});
}