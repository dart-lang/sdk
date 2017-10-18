// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'cache_new.dart';

const String LUCI_HOST = "luci-milo.appspot.com";
const String CBE_HOST = "chrome-build-extract.appspot.com";

typedef void ModifyRequestFunction(HttpClientRequest request);

/// Base class for communicating with [Luci]
/// Some information is found through the api
/// <https://luci-milo.appspot.com/rpcexplorer/services/milo.Buildbot/>,
/// some information is found via Cbe
/// <https://chrome-build-extract.appspot.com/get_master/<client>> and
/// and some raw log files is found via [Luci]/log/raw.
class LuciApi {
  final HttpClient _client = new HttpClient();

  LuciApi();

  /// [getJsonFromChromeBuildExtract] gets json from Cbe, with information
  /// about all bots and current builds.
  Future<dynamic> getJsonFromChromeBuildExtract(
      String client, WithCacheFunction withCache) async {
    return withCache(
            () => _makeGetRequest(new Uri(
                scheme: 'https',
                host: CBE_HOST,
                path: "/get_master/${client}")),
            "cbe")
        .then(JSON.decode);
  }

  /// [getMaster] fetches master information for all bots.
  Future<dynamic> getMaster(String client, WithCacheFunction withCache) async {
    var uri = new Uri(
        scheme: "https",
        host: LUCI_HOST,
        path: "prpc/milo.Buildbot/GetCompressedMasterJSON");
    var body = {"name": client};
    return withCache(
            () => _makePostRequest(uri, JSON.encode(body), {
                  HttpHeaders.CONTENT_TYPE: "application/json",
                  HttpHeaders.ACCEPT: "application/json"
                }),
            '${uri.path}')
        .then(JSON.decode)
        .then((json) {
      var data = JSON.decode(UTF8
          .decode(new GZipDecoder().decodeBytes(BASE64.decode(json["data"]))));
      return data;
    });
  }

  /// Calling the Milo Api to get latest builds for this bot,
  /// where the field [amount] is the number of recent builds to fetch.
  Future<List<BuildDetail>> getBuildBotDetails(
      String client, String botName, WithCacheFunction withCache,
      [int amount = 20]) async {
    var uri = new Uri(
        scheme: "https",
        host: LUCI_HOST,
        path: "prpc/milo.Buildbot/GetBuildbotBuildsJSON");
    var body = {
      "master": client,
      "builder": botName,
      "limit": amount,
      "includeCurrent": true
    };
    return withCache(
            () => _makePostRequest(uri, JSON.encode(body), {
                  HttpHeaders.CONTENT_TYPE: "application/json",
                  HttpHeaders.ACCEPT: "application/json"
                }),
            '${uri.path}_${botName}_$amount')
        .then(JSON.decode)
        .then((json) {
      return json["builds"].map((b) {
        var build = JSON.decode(UTF8.decode(BASE64.decode(b["data"])));
        return getBuildDetailFromJson(client, botName, build);
      }).toList();
    });
  }

  /// Calling the Milo Api to get information about a specific build
  /// where the field [buildNumber] is the build number to fetch.
  Future<BuildDetail> getBuildBotBuildDetails(String client, String botName,
      int buildNumber, WithCacheFunction withCache) async {
    var uri = new Uri(
        scheme: "https",
        host: LUCI_HOST,
        path: "prpc/milo.Buildbot/GetBuildbotBuildJSON");
    var body = {"master": client, "builder": botName, "buildNum": buildNumber};
    return withCache(
            () => _makePostRequest(uri, JSON.encode(body), {
                  HttpHeaders.CONTENT_TYPE: "application/json",
                  HttpHeaders.ACCEPT: "application/json"
                }),
            '${uri.path}_${botName}_$buildNumber')
        .then(JSON.decode)
        .then((json) {
      var build = JSON.decode(UTF8.decode(BASE64.decode(json["data"])));
      return getBuildDetailFromJson(client, botName, build);
    });
  }

  /// [_makeGetRequest] performs a get request to [uri].
  Future<String> _makeGetRequest(Uri uri) async {
    String uriString = uri.toString();
    var request = await _client.getUrl(uri);
    var response = await request.close();
    if (response.statusCode != 200) {
      response.drain();
      throw new HttpException(response.reasonPhrase, uri: uri);
    }
    return response.transform(UTF8.decoder).join();
  }

  /// [_makePostRequest] performs a post request to [uri], where the posted
  /// body is the string representation of [body]. For adding custom headers
  /// use the map [headers].
  Future<String> _makePostRequest(
      Uri uri, Object body, Map<String, String> headers) async {
    var response = await http.post(uri, body: body, headers: headers);
    if (response.statusCode != 200) {
      throw new HttpException(response.reasonPhrase, uri: uri);
    }
    // Prpc outputs a prefix to combat vulnerability.
    if (response.body.startsWith(")]}'")) {
      return response.body.substring(4);
    }
    return response.body;
  }

  /// Closes the Http client connection
  void close() {
    _client.close();
  }
}

/// [getBuildDetailFromJson] parses json [build] to a class [BuildDetail]
BuildDetail getBuildDetailFromJson(
    String client, String botName, dynamic build) {
  List<GitCommit> changes = build["sourceStamp"]["changes"].map((change) {
    return new GitCommit(
        change["revision"],
        change["revLink"],
        change["who"],
        change["comments"],
        change["files"].map((file) => file["name"]).toList());
  }).toList();

  List<BuildProperty> properties = build["properties"].map((prop) {
    return new BuildProperty(prop[0], prop[1].toString(), prop[2]);
  }).toList();

  DateTime parseDateTime(num value) {
    if (value == null) return null;
    return new DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
  }

  List<BuildStep> steps = build["steps"].map((Map step) {
    DateTime start = parseDateTime(step["times"][0]);
    DateTime end = parseDateTime(step["times"][1]);
    return new BuildStep(
        step["name"],
        step["text"].join(', '),
        step["results"].toString(),
        start,
        end,
        step["step_number"],
        step["isStarted"],
        step["isFinished"],
        step["logs"].map((log) => new BuildLog(log[0], log[1])).toList());
  }).toList();

  Timing timing = new Timing(
      parseDateTime(build["times"][0]), parseDateTime(build["times"][1]));

  return new BuildDetail(
      client,
      botName,
      build["number"],
      build["text"].join(' '),
      build["finished"],
      steps,
      properties,
      build["blame"],
      timing,
      changes);
}

/// [BuildDetail] holds data detailing a specific build
class BuildDetail {
  final String client;
  final String botName;
  final int buildNumber;
  final String results;
  final bool finished;
  final List<BuildStep> steps;
  final List<BuildProperty> buildProperties;
  final List<String> blameList;
  final Timing timing;
  final List<GitCommit> allChanges;

  BuildDetail(
      this.client,
      this.botName,
      this.buildNumber,
      this.results,
      this.finished,
      this.steps,
      this.buildProperties,
      this.blameList,
      this.timing,
      this.allChanges);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln("--------------------------------------");
    buffer.writeln(results);
    buffer.writeln(timing);
    buffer.writeln("----------------STEPS-----------------");
    if (steps != null) steps.forEach(buffer.writeln);
    buffer.writeln("----------BUILD PROPERTIES------------");
    if (buildProperties != null) buildProperties.forEach(buffer.writeln);
    buffer.writeln("-------------BLAME LIST---------------");
    if (blameList != null) blameList.forEach(buffer.writeln);
    buffer.writeln("------------ALL CHANGES---------------");
    if (allChanges != null) allChanges.forEach(buffer.writeln);
    return buffer.toString();
  }
}

/// [BuildStep] holds data detailing a specific build
class BuildStep {
  final String name;
  final String description;
  final String result;
  final DateTime start;
  final DateTime end;
  final int number;
  final bool isStarted;
  final bool isFinished;
  final List<BuildLog> logs;

  BuildStep(this.name, this.description, this.result, this.start, this.end,
      this.number, this.isStarted, this.isFinished, this.logs);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln("${result == '[0, []]' ? 'SUCCESS' : result}: "
        "$name - $description ($start, $end)");
    logs.forEach((subLink) {
      buffer.writeln("\t${subLink}");
    });
    return buffer.toString();
  }
}

/// [BuildLog] holds log-information for a specific build.
class BuildLog {
  final String name;
  final String url;

  BuildLog(this.name, this.url);

  @override
  String toString() {
    return "$name | $url";
  }
}

/// [BuildProperty] descibes build properties of a specific build.
class BuildProperty {
  final String name;
  final String value;
  final String source;

  BuildProperty(this.name, this.value, this.source);

  @override
  String toString() {
    return "$name\t$value\t$source";
  }
}

/// [Timing] is a class to hold timing information for builds and steps.
class Timing {
  final DateTime start;
  final DateTime end;

  Timing(this.start, this.end);

  @override
  String toString() {
    return "start: $start\tend: $end";
  }
}

/// [GitCommit] holds data about a specific commit.
class GitCommit {
  final String revision;
  final String commitUrl;
  final String changedBy;
  final String comments;
  final List<String> changedFiles;

  GitCommit(this.revision, this.commitUrl, this.changedBy, this.comments,
      this.changedFiles);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln("revision: $revision");
    buffer.writeln("commitUrl: $commitUrl");
    buffer.writeln("changedBy: $changedBy");
    buffer.write("\n");
    buffer.writeln(comments);
    buffer.write("\nfiles:\n");
    changedFiles.forEach(buffer.writeln);
    return buffer.toString();
  }
}
