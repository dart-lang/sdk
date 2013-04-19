// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

void testZLibInflate_regress10026() {
  test(data, expect) {
    var port = new ReceivePort();
    var controller = new StreamController();
    controller.stream
        .transform(new ZLibInflater())
        .transform(new StringDecoder())
        .fold(new StringBuffer(), (buffer, s) {
          buffer.write(s);
          return buffer;
        })
        .then((out) {
          Expect.equals(out.toString(), expect);
          port.close();
        });
    controller.add(data);
    controller.close();
  }
  test([
      31, 139, 8, 0, 140, 39, 113, 81, 2, 255, 125, 84, 205, 142, 211, 48, 16,
      62, 55, 79, 49, 132, 11, 72, 77, 211, 101, 1, 85, 217, 52, 2, 1, 18, 23,
      224, 0, 23, 142, 211, 120, 210, 142, 54, 177, 131, 237, 164, 173, 16, 239,
      206, 216, 105, 187, 133, 21, 168, 145, 26, 207, 196, 223, 159, 39, 41,
      159, 40, 83, 251, 99, 79, 176, 243, 93, 91, 37, 229, 249, 143, 80, 85,
      201, 172, 244, 236, 91, 170, 62, 28, 176, 235, 91, 130, 247, 166, 67, 214,
      101, 62, 85, 19, 233, 119, 228, 17, 234, 29, 90, 71, 126, 157, 14, 190,
      201, 86, 41, 228, 213, 185, 179, 243, 190, 207, 232, 199, 192, 227, 58,
      125, 103, 180, 39, 237, 179, 192, 150, 66, 61, 173, 214, 169, 167, 131,
      207, 3, 235, 221, 5, 231, 17, 140, 198, 142, 214, 233, 200, 180, 239, 141,
      245, 87, 155, 247, 172, 252, 110, 173, 104, 228, 154, 178, 184, 152, 3,
      107, 246, 140, 109, 230, 106, 108, 105, 125, 115, 194, 113, 254, 40, 6, 2,
      247, 137, 178, 118, 46, 149, 198, 198, 168, 35, 252, 76, 102, 179, 13,
      214, 247, 91, 107, 6, 173, 178, 218, 180, 198, 22, 240, 180, 89, 202, 239,
      197, 157, 52, 59, 180, 91, 214, 5, 44, 195, 162, 71, 165, 88, 111, 79,
      171, 70, 180, 100, 13, 118, 220, 30, 11, 72, 191, 244, 164, 225, 43, 106,
      151, 206, 33, 253, 72, 237, 72, 158, 107, 132, 207, 52, 144, 84, 46, 133,
      57, 188, 181, 162, 113, 14, 78, 30, 205, 28, 89, 110, 2, 86, 50, 251, 149,
      204, 20, 143, 81, 80, 180, 83, 192, 235, 229, 178, 63, 92, 107, 120, 69,
      29, 224, 224, 205, 31, 82, 110, 169, 187, 251, 135, 137, 38, 66, 111, 140,
      85, 100, 51, 139, 138, 7, 87, 192, 77, 124, 94, 216, 176, 104, 89, 223,
      207, 1, 139, 145, 29, 123, 82, 145, 251, 188, 249, 118, 245, 114, 181,
      138, 251, 67, 102, 153, 162, 218, 88, 244, 108, 68, 134, 54, 154, 38, 136,
      55, 29, 41, 70, 120, 214, 225, 33, 187, 22, 253, 124, 202, 245, 28, 240,
      127, 196, 9, 200, 197, 246, 217, 247, 217, 226, 67, 246, 15, 165, 191,
      204, 196, 115, 120, 200, 98, 242, 22, 64, 229, 42, 243, 120, 242, 213, 44,
      41, 243, 105, 168, 147, 50, 72, 146, 25, 23, 198, 48, 25, 187, 155, 71,
      243, 45, 37, 105, 244, 213, 183, 29, 59, 80, 177, 8, 114, 71, 206, 227,
      166, 101, 183, 147, 148, 188, 129, 13, 193, 224, 228, 182, 49, 22, 184,
      109, 7, 231, 67, 54, 35, 1, 77, 112, 78, 70, 81, 118, 215, 67, 39, 179,
      234, 22, 240, 221, 12, 178, 148, 224, 60, 104, 138, 16, 49, 105, 241, 194,
      26, 61, 129, 192, 160, 187, 143, 112, 61, 217, 142, 157, 147, 160, 3, 145,
      176, 128, 191, 150, 162, 47, 20, 114, 112, 90, 1, 251, 32, 47, 0, 227,
      136, 220, 138, 72, 10, 48, 2, 111, 105, 203, 147, 46, 163, 23, 101, 222,
      79, 190, 74, 121, 51, 45, 53, 235, 52, 188, 159, 69, 158, 239, 247, 251,
      5, 163, 198, 133, 177, 219, 124, 34, 113, 185, 235, 169, 150, 25, 77, 171,
      79, 198, 146, 112, 10, 96, 55, 225, 44, 4, 9, 171, 136, 86, 230, 49, 197,
      50, 63, 101, 154, 79, 223, 143, 223, 163, 237, 129, 168, 87, 4, 0, 0],
      '''<!doctype html>
<html>
<head>
	<title>Example Domain</title>

	<meta charset="utf-8" />
	<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<style type="text/css">
	body {
		background-color: #f0f0f2;
		margin: 0;
		padding: 0;
		font-family: "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
		
	}
	div {
		width: 600px;
		margin: 5em auto;
		padding: 3em;
		background-color: #fff;
		border-radius: 1em;
	}
	a:link, a:visited {
		color: #38488f;
		text-decoration: none;
	}
	@media (max-width: 600px) {
		body {
			background-color: #fff;
		}
		div {
			width: auto;
			margin: 0 auto;
			border-radius: 0;
			padding: 1em;
		}
	}
	</style>	
</head>

<body>
<div>
	<h1>Example Domain</h1>
	<p>This domain is established to be used for illustrative examples in documents. You do not need to
		coordinate or ask for permission to use this domain in examples, and it is not available for
		registration.</p>
	<p><a href="http://www.iana.org/domains/special">More information...</a></p>
</div>
</body>
</html>
''');
}

void main() {
  testZLibInflate_regress10026();
}

