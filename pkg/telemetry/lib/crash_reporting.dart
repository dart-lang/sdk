// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stack_trace/stack_trace.dart';

import 'src/utils.dart';

/// Tells crash backend that this is a Dart error (as opposed to, say, Java).
const String _dartTypeId = 'DartError';

/// Crash backend host.
const String _crashServerHost = 'clients2.google.com';

/// Path to the crash servlet.
const String _crashEndpointPath = '/cr/report'; // or, 'staging_report'

/// The field corresponding to the multipart/form-data file attachment where
/// crash backend expects to find the Dart stack trace.
const String _stackTraceFileField = 'DartError';

/// The name of the file attached as [_stackTraceFileField].
///
/// The precise value is not important. It is ignored by the crash back end, but
/// it must be supplied in the request.
const String _stackTraceFilename = 'stacktrace_file';

/// Sends crash reports to Google.
///
/// Clients shouldn't extend, mixin or implement this class.
class CrashReportSender {
  static final Uri _baseUri = new Uri(
      scheme: 'https', host: _crashServerHost, path: _crashEndpointPath);

  static const int _maxReportsToSend = 1000;

  final String crashProductId;
  final EnablementCallback shouldSend;
  final http.Client _httpClient;

  final ThrottlingBucket _throttle = ThrottlingBucket(10, Duration(minutes: 1));
  int _reportsSend = 0;

  /// Create a new [CrashReportSender].
  CrashReportSender(
    this.crashProductId,
    this.shouldSend, {
    http.Client httpClient,
  }) : _httpClient = httpClient ?? new http.Client();

  /// Sends one crash report.
  ///
  /// The report is populated from data in [error] and [stackTrace].
  Future sendReport(dynamic error, {StackTrace stackTrace}) async {
    if (!shouldSend()) {
      return;
    }

    // Check if we've sent too many reports recently.
    if (!_throttle.removeDrop()) {
      return;
    }

    // Don't send too many total reports to crash reporting.
    if (_reportsSend >= _maxReportsToSend) {
      return;
    }

    try {
      final String dartVersion = Platform.version.split(' ').first;

      final Uri uri = _baseUri.replace(
        queryParameters: <String, String>{
          'product': crashProductId,
          'version': dartVersion,
        },
      );

      final http.MultipartRequest req = new http.MultipartRequest('POST', uri);
      req.fields['product'] = crashProductId;
      req.fields['version'] = dartVersion;
      req.fields['osName'] = Platform.operatingSystem;
      req.fields['osVersion'] = Platform.operatingSystemVersion;
      req.fields['type'] = _dartTypeId;
      req.fields['error_runtime_type'] = '${error.runtimeType}';
      req.fields['error_message'] = '$error';

      final Chain chain = new Chain.forTrace(stackTrace);
      req.files.add(new http.MultipartFile.fromString(
          _stackTraceFileField, chain.terse.toString(),
          filename: _stackTraceFilename));

      final http.StreamedResponse resp = await _httpClient.send(req);

      if (resp.statusCode != 200) {
        throw 'server responded with HTTP status code ${resp.statusCode}';
      }
    } on SocketException catch (error) {
      throw 'network error while sending crash report: $error';
    } catch (error, stackTrace) {
      // If the sender itself crashes, just print.
      throw 'exception while sending crash report: $error\n$stackTrace';
    }
  }

  /// Closes the client and cleans up any resources associated with it. This
  /// will close the associated [http.Client].
  void dispose() {
    _httpClient.close();
  }
}

/// A typedef to allow crash reporting to query as to whether it should send a
/// crash report.
typedef bool EnablementCallback();
