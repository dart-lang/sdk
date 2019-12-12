#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Find the success/failure status for a builder that is written to
// Firestore by the cloud functions that process results.json.
// These cloud functions write a success/failure result to the
// builder table based on the approvals in Firestore.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

const firebaseUrl =
    'https://firestore.googleapis.com/v1/projects/dart-ci/databases/(default)/documents';

void main(List<String> args) async {
  final builder = args[0];
  final buildNumber = args[1];
  final client = Client();
  return; // Temporarily make script return immediately, while we
  // land recipe change that calls it.
  for (int count = 0; count < 30; ++count) {
    // TODO(whesse): Add code to fetch from "try_builds" for builders that
    // end with "-try".
    final response =
        await client.get('$firebaseUrl/build_status/$builder:$buildNumber');
    if (response.statusCode == HttpStatus.ok) {
      final document = jsonDecode(response.body);
      final status = (document['fields']['status'] ?? const {})['stringValue'];
      if (status == 'success') exit(0);
      if (status == 'failed') exit(1);
    }
    await Future.delayed(Duration(seconds: 10));
  }
  print(
      'No status received for $builder:$buildNumber after 30 attempts, with 10 second waits.');
  exit(2);
}
