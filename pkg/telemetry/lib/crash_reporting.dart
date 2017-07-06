// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stack_trace/stack_trace.dart';
import 'package:usage/usage.dart';

/// Crash backend host.
const String _crashServerHost = 'clients2.google.com';

/// Path to the crash servlet.
const String _crashEndpointPath = '/cr/report'; // or, staging_report

/// The field corresponding to the multipart/form-data file attachment where
/// crash backend expects to find the Dart stack trace.
const String _stackTraceFileField = 'DartError';

/// The name of the file attached as [stackTraceFileField].
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

  final String crashProductId;
  final Analytics analytics;
  final http.Client _httpClient;

  /// Create a new [CrashReportSender], using the data from the given
  /// [Analytics] instance.
  CrashReportSender(this.crashProductId, this.analytics,
      {http.Client httpClient})
      : _httpClient = httpClient ?? new http.Client();

  /// Sends one crash report.
  ///
  /// The report is populated from data in [error] and [stackTrace].
  Future sendReport(dynamic error, {StackTrace stackTrace}) async {
    if (!analytics.enabled) {
      return;
    }

    try {
      final Uri uri = _baseUri.replace(
        queryParameters: <String, String>{
          'product': analytics.trackingId,
          'version': analytics.applicationVersion,
        },
      );

      final http.MultipartRequest req = new http.MultipartRequest('POST', uri);
      req.fields['uuid'] = analytics.clientId;
      req.fields['product'] = crashProductId;
      req.fields['version'] = analytics.applicationVersion;
      req.fields['osName'] = Platform.operatingSystem;
      // TODO(devoncarew): Report the operating system version when we're able.
      //req.fields['osVersion'] = Platform.operatingSystemVersion;
      req.fields['type'] = 'DartError';
      req.fields['error_runtime_type'] = '${error.runtimeType}';

      final Chain chain = new Chain.parse(stackTrace.toString());
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
