// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

const String BUILD_BUCKET_HOST = "cr-buildbucket.appspot.com";
const String BUILD_BUCKET_API = r"/_ah/api/buildbucket/v1";

/// Class to communicate with the build bucket (swarming) by calling the api.
class BuildBucketApi {
  /// Searches the build bucket for a build with [tag].
  Future<String> search(String tag) {
    String path = BUILD_BUCKET_API + "/search";
    String query =
        "tag=${Uri.encodeFull(tag)}&max_builds=50&&fields=builds(id,tags)";
    var uri = new Uri(
        scheme: 'https', host: BUILD_BUCKET_HOST, path: path, query: query);
    return _makeGetRequest(uri);
  }

  /// [_makeGetRequest] performs a get request to [uri].
  Future<String> _makeGetRequest(Uri uri) async {
    var response = await http.get(uri);
    if (response.statusCode != 200) {
      throw new HttpException(response.reasonPhrase, uri: uri);
    }
    return response.body;
  }
}
