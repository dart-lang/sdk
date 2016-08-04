// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

final List<int> _UTF8_PLS_CERTIFICATE = UTF8.encode('''
-----BEGIN CERTIFICATE-----
MIIDZDCCAkygAwIBAgIBATANBgkqhkiG9w0BAQsFADAgMR4wHAYDVQQDDBVpbnRl
cm1lZGlhdGVhdXRob3JpdHkwHhcNMTUxMDI3MTAyNjM1WhcNMjUxMDI0MTAyNjM1
WjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
ggEKAoIBAQCkg/Qr8RQeLTOSgCkyiEX2ztgkgscX8hKGHEHdvlkmVK3JVEIIwkvu
/Y9LtHZUia3nPAgqEEbexzTENZjSCcC0V6I2XW/e5tIE3rO0KLZyhtZhN/2SfJ6p
KbOh0HLr1VtkKJGp1tzUmHW/aZI32pK60ZJ/N917NLPCJpCaL8+wHo3+w3oNqln6
oJsfgxy9SUM8Bsc9WMYKMUdqLO1QKs1A5YwqZuO7Mwj+4LY2QDixC7Ua7V9YAPo2
1SBeLvMCHbYxSPCuxcZ/kDkgax/DF9u7aZnGhMImkwBka0OQFvpfjKtTIuoobTpe
PAG7MQYXk4RjnjdyEX/9XAQzvNo1CDObAgMBAAGjgbQwgbEwPAYDVR0RBDUwM4IJ
bG9jYWxob3N0ggkxMjcuMC4wLjGCAzo6MYcEfwAAAYcQAAAAAAAAAAAAAAAAAAAA
ATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBSvhJo6taTggJQBukEvMo/PDk8tKTAf
BgNVHSMEGDAWgBS98L4T5RaIToE3DkBRsoeWPil0eDAOBgNVHQ8BAf8EBAMCA6gw
EwYDVR0lBAwwCgYIKwYBBQUHAwEwDQYJKoZIhvcNAQELBQADggEBAHLOt0mL2S4A
B7vN7KsfQeGlVgZUVlEjem6kqBh4fIzl4CsQuOO8oJ0FlO1z5JAIo98hZinymJx1
phBVpyGIKakT/etMH0op5evLe9dD36VA3IM/FEv5ibk35iGnPokiJXIAcdHd1zam
YaTHRAnZET5S03+7BgRTKoRuszhbvuFz/vKXaIAnVNOF4Gf2NUJ/Ax7ssJtRkN+5
UVxe8TZVxzgiRv1uF6NTr+J8PDepkHCbJ6zEQNudcFKAuC56DN1vUe06gRDrNbVq
2JHEh4pRfMpdsPCrS5YHBjVq/XHtFHgwDR6g0WTwSUJvDeM4OPQY5f61FB0JbFza
PkLkXmoIod8=
-----END CERTIFICATE-----''');

main() {
  // create context for establishing socket later
  final _context = SecurityContext.defaultContext;
  _context.useCertificateChainBytes(_UTF8_PLS_CERTIFICATE);
}
