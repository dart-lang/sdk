// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for serving HTTP requests and resources.
 *
 * ## Installing ##
 *
 * Use [pub][] to install this package. Add the following to your
 * `pubspec.yaml` file.
 *
 *     dependencies:
 *       http_server: any
 *
 * Then run `pub install`.
 *
 * For more information, see the
 * [http_server package on pub.dartlang.org][pub].
 *
 * ## Basic usage
 *
 * Here is a short example of how to serve all files from the current
 * directory.
 *
 * 	import 'dart:io';
 * 	import 'dart:async';
 * 	import 'package:http_server/http_server.dart';
 * 
 * 	void main() {
 * 	  var staticFiles = new VirtualDirectory('.')
 * 	    ..allowDirectoryListing = true;
 * 
 * 	  runZoned(() {
 * 	    HttpServer.bind('0.0.0.0', 7777).then((server) {
 * 	      print('Server running');
 * 	      server.listen(staticFiles.serveRequest);
 * 	    });
 * 	  },
 * 	  onError: (e, stackTrace) => print('Oh noes! $e $stackTrace'));
 *     }
 *
 * ## Virtual directory
 * 
 * The [VirtualDirectory] class makes it easy to serve static content
 * from the file system. It supports:
 * 
 *  *  Range-based requests.
 *  *  If-Modified-Since based caching.
 *  *  Automatic GZip-compression of content.
 *  *  Following symlinks, either throughout the system or inside
 *     a jailed root.
 *  *  Directory listing.
 * 
 * See [VirtualDirectory] for more information.
 * 
 * ## Virtual host
 * 
 * The [VirtualHost] class helps to serve multiple hosts on the same
 * address, by using the `Host` field of the incoming requests. It also
 * works with wildcards for sub-domains.
 * 
 *     var virtualHost = new VirtualHost(server);
 *     // Filter out on a specific host
 *     var stream1 = virtualServer.addHost('static.myserver.com');
 *     // Wildcard for any other sub-domains.
 *     var stream2 = virtualServer.addHost('*.myserver.com');
 *     // Requets not matching any hosts.
 *     var stream3 = virtualServer.unhandled;
 * 
 * See [VirtualHost] for more information.
 *
 * [pub]: http://pub.dartlang.org/packages/http_server
 */
library http_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import "package:path/path.dart";

part 'src/http_body.dart';
part 'src/http_body_impl.dart';
part 'src/http_multipart_form_data.dart';
part 'src/http_multipart_form_data_impl.dart';
part 'src/virtual_directory.dart';
part 'src/virtual_host.dart';

