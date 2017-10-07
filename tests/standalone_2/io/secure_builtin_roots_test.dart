// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:async";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

Future testGoogleUrl(SecurityContext context, String outcome) async {
  var client = new HttpClient(context: context);
  // We need to use an external server that is backed by a
  // built-in root certificate authority.
  try {
    // First, check if the lookup works.
    await InternetAddress.lookup('www.google.com');
    var request = await client.getUrl(Uri.parse('https://www.google.com'));
    request.followRedirects = false;
    var response = await request.close();
    Expect.equals('pass', outcome, 'Unexpected successful connection');
    try {
      await response.drain();
    } catch (e) {}
  } on HandshakeException {
    Expect.equals('fail', outcome, 'Unexpected failed connection');
  } on SocketException {
    // Lookup failed or connection failed.  Don't report a failure.
  } finally {
    client.close();
  }
}

main() async {
  asyncStart();
  await testGoogleUrl(null, "pass");
  await testGoogleUrl(SecurityContext.defaultContext, "pass");
  await testGoogleUrl(new SecurityContext(), "fail");
  asyncEnd();
}
