// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'buildbucket_api.dart';

/// Get builds from Gerrit with a [changeNumber] and [patchSet].
Future<List<BuildBucketBuild>> buildsFromGerrit(
    int changeNumber, int patchset) {
  var api = new BuildBucketApi();
  var result = api.search("buildset:patch/gerrit/dart-review.googlesource.com/"
      "${changeNumber}/${patchset}");
  return result.then(JSON.decode).then(_buildsFromJson);
}

/// Get builds from a swarming task with [swarmingTaskId].
Future<List<BuildBucketBuild>> buildsFromSwarmingTaskId(String swarmingTaskId) {
  var api = new BuildBucketApi();
  var result = api.search("swarming_task_id:$swarmingTaskId");
  return result.then(JSON.decode).then(_buildsFromJson);
}

List<BuildBucketBuild> _buildsFromJson(Map json) {
  if (json == null || !json.containsKey("builds")) {
    return null;
  }
  return json["builds"].map((build) {
    var tags = build["tags"];
    return new BuildBucketBuild(
        build["id"],
        _valueFromTag("builder", tags),
        _valueFromTag("master", tags),
        _valueFromTag("swarming_tag:pool", tags),
        _valueFromTag("swarming_task_id", tags));
  }).toList();
}

String _valueFromTag(String tag, List tags) {
  String key = "${tag}:";
  for (var taggedValue in tags) {
    if (taggedValue.startsWith(key)) {
      return taggedValue.substring(key.length);
    }
  }
  return null;
}

/// [BuildBucketBuild] holds information about a specific swarming build.
class BuildBucketBuild {
  final String id;
  final String builder;
  final String master;
  final String pool;
  final String swarmingTaskId;
  BuildBucketBuild(
      this.id, this.builder, this.master, this.pool, this.swarmingTaskId);
}
