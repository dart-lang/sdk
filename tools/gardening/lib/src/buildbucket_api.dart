// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

const String BUILD_BUCKET_HOST = "cr-buildbucket.appspot.com";
const String BUILD_BUCKET_API = r"/_ah/api/buildbucket/v1";
const String BUILD_BUCKET_SWARM = r"/_ah/api/swarmbucket/v1";

/// Class to communicate with the build bucket (swarming) by calling the api.
class BuildBucketApi {
  /// Searches the build bucket for a build with [tag].
  Future<String> search(String tag) {
    return searchExtended(tag);
  }

  /// Searches the build bucket for a build with [tag].
  Future<String> searchExtended(String tag,
      {int maxBuilds = 50,
      String bucket = "luci.dart.try",
      String fields = "builds(id,tags)",
      String status = "",
      String result = ""}) {
    String path = BUILD_BUCKET_API + "/search";
    String query =
        "tag=${Uri.encodeFull(tag)}&max_builds=$maxBuilds&fields=$fields";
    if (status.isNotEmpty) {
      query += "&status=$status";
    }
    if (result.isNotEmpty) {
      query += "&result=$result";
    }
    var uri = new Uri(
        scheme: 'https', host: BUILD_BUCKET_HOST, path: path, query: query);
    return _makeGetRequest(uri);
  }

  /// Request all builders for with masters in build-bucket (swarming), by
  /// calling the build-bucket api.
  Future<String> builders() {
    String path = BUILD_BUCKET_SWARM + "/builders";
    var uri = new Uri(scheme: 'https', host: BUILD_BUCKET_HOST, path: path);
    return _makeGetRequest(uri);
  }

  /// [_makeGetRequest] performs a get request to [uri].
  Future<String> _makeGetRequest(Uri uri) async {
    print(uri);
    var response = await http.get(uri);
    if (response.statusCode != 200) {
      throw new HttpException(response.reasonPhrase, uri: uri);
    }
    return response.body;
  }
}
