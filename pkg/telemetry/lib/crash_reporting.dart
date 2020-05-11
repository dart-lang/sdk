// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/utils.dart';

/// Tells crash backend that this is a Dart error (as opposed to, say, Java).
const String _dartTypeId = 'DartError';

/// Crash backend host.
const String _crashServerHost = 'clients2.google.com';

/// Path to the staging crash servlet.
const String _crashEndpointPathStaging = '/cr/staging_report';

/// Path to the prod crash servlet.
const String _crashEndpointPathProd = '/cr/report';

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
  final Uri _baseUri;

  static const int _maxReportsToSend = 1000;

  final String crashProductId;
  final EnablementCallback shouldSend;
  final http.Client _httpClient;
  final Stopwatch _processStopwatch = new Stopwatch()..start();

  final ThrottlingBucket _throttle = ThrottlingBucket(10, Duration(minutes: 1));
  int _reportsSent = 0;
  int _skippedReports = 0;

  CrashReportSender._(
    this.crashProductId,
    this.shouldSend, {
    http.Client httpClient,
    String endpointPath = _crashEndpointPathStaging,
  })  : _httpClient = httpClient ?? new http.Client(),
        _baseUri = new Uri(
            scheme: 'https', host: _crashServerHost, path: endpointPath);

  /// Create a new [CrashReportSender] connected to the staging endpoint.
  CrashReportSender.staging(
    String crashProductId,
    EnablementCallback shouldSend, {
    http.Client httpClient,
  }) : this._(crashProductId, shouldSend,
            httpClient: httpClient, endpointPath: _crashEndpointPathStaging);

  /// Create a new [CrashReportSender] connected to the prod endpoint.
  CrashReportSender.prod(
    String crashProductId,
    EnablementCallback shouldSend, {
    http.Client httpClient,
  }) : this._(crashProductId, shouldSend,
            httpClient: httpClient, endpointPath: _crashEndpointPathProd);

  /// Sends one crash report.
  ///
  /// The report is populated from data in [error] and [stackTrace].
  ///
  /// Additional context about the crash can optionally be passed in via
  /// [comment]. Note that this field should not include PII.
  Future sendReport(
    dynamic error,
    StackTrace stackTrace, {
    List<CrashReportAttachment> attachments = const [],
    String comment,
  }) async {
    if (!shouldSend()) {
      return;
    }

    // Check if we've sent too many reports recently.
    if (!_throttle.removeDrop()) {
      _skippedReports++;
      return;
    }

    // Don't send too many total reports to crash reporting.
    if (_reportsSent >= _maxReportsToSend) {
      return;
    }

    _reportsSent++;

    // Calculate the 'weight' of the this report; we increase the weight of a
    // report if we had throttled previous reports.
    int weight = math.min(_skippedReports + 1, 10000);
    _skippedReports = 0;

    try {
      final String dartVersion = Platform.version.split(' ').first;

      final Uri uri = _baseUri.replace(
        queryParameters: <String, String>{
          'product': crashProductId,
          'version': dartVersion,
        },
      );

      final http.MultipartRequest req = new http.MultipartRequest('POST', uri);

      Map<String, String> fields = req.fields;
      fields['product'] = crashProductId;
      fields['version'] = dartVersion;
      fields['osName'] = Platform.operatingSystem;
      fields['osVersion'] = Platform.operatingSystemVersion;
      fields['type'] = _dartTypeId;
      fields['error_runtime_type'] = '${error.runtimeType}';
      fields['error_message'] = '$error';

      // Optional comments.
      if (comment != null) {
        fields['comments'] = comment;
      }

      // The uptime of the process before it crashed (in milliseconds).
      fields['ptime'] = _processStopwatch.elapsedMilliseconds.toString();

      // Send the amount to weight this report.
      if (weight > 1) {
        fields['weight'] = weight.toString();
      }

      final Chain chain = new Chain.forTrace(stackTrace);
      req.files.add(
        new http.MultipartFile.fromString(
          _stackTraceFileField,
          chain.terse.toString(),
          filename: _stackTraceFilename,
        ),
      );

      for (var attachment in attachments) {
        req.files.add(
          new http.MultipartFile.fromString(
            attachment._field,
            attachment._value,
            filename: attachment._field,
          ),
        );
      }

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

  @visibleForTesting
  int get reportsSent => _reportsSent;

  /// Closes the client and cleans up any resources associated with it. This
  /// will close the associated [http.Client].
  void dispose() {
    _httpClient.close();
  }
}

/// The additional attachment to be added to a crash report.
class CrashReportAttachment {
  final String _field;
  final String _value;

  CrashReportAttachment.string({
    @required String field,
    @required String value,
  })  : _field = field,
        _value = value;
}

/// A typedef to allow crash reporting to query as to whether it should send a
/// crash report.
typedef bool EnablementCallback();
