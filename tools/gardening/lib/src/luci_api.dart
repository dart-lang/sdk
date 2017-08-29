// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'try.dart';
import 'cache_new.dart';

const String LUCI_HOST = "luci-milo.appspot.com";

typedef void ModifyRequestFunction(HttpClientRequest request);

/// Base class for communicating with [Luci]
/// Some information is found through the api
/// <https://docs.google.com/document/d/1HbPp7Sy7ofC
/// U7C9USqcE91VubGg_IIET2GUj9iknev4/edit#>
/// and some information is found via screen-scraping.
class LuciApi {
  final HttpClient _client = new HttpClient();

  LuciApi();

  /// [getBuildBots] fetches all build bots from luci (we cannot
  /// get this from the api). The format is:
  /// <li>
  ///     <a href="/buildbot/client.crashpad/crashpad_win_x86_wow64_rel">
  ///        crashpad_win_x86_wow64_rel</a>
  /// </li>
  /// <h3> client.dart </h3>
  /// <li>
  ///     <a href="/buildbot/client.dart/analyze-linux-be">analyze-linux-be</a>
  /// </li>
  /// <li>
  ///     <a href="/buildbot/client.dart/analyze-linux-stable">
  ///        analyze-linux-stable</a>
  /// </li>
  /// <li>
  ///     <a href="/buildbot/client.dart/analyzer-linux-release-be">
  ///        analyzer-linux-release-be</a>
  /// </li>
  ///
  /// We look for the section header matching clients, then
  /// if we are in the right section, we take the <li> element
  /// and transform to a build bot
  ///
  Future<Try<List<LuciBuildBot>>> getAllBuildBots(
      String client, WithCacheFunction withCache) async {
    return await tryStartAsync(() => withCache(
            () => _makeGetRequest(
                new Uri(scheme: 'https', host: LUCI_HOST, path: "/")),
            "all_buildbots"))
        .then((Try<String> tryRes) => tryRes.bind(parse).bind((htmlDoc) {
              // This is really dirty, but the structure of
              // the document is not really suited for anything else.
              var takeSection = false;
              return htmlDoc.body.children.where((node) {
                if (node.localName == "li") return takeSection;
                if (node.localName != "h3") {
                  takeSection = false;
                  return false;
                }
                // Current node is <h3>.
                takeSection = client == node.text.trim();
                return false;
              });
            }).bind((elements) {
              // Here we hold an iterable of buildbot elements
              // <li>
              //     <a href="/buildbot/client.dart/analyzer-linux-release-be">
              //        analyzer-linux-release-be</a>
              // </li>
              return elements.map((element) {
                var name = element.children[0].text;
                var url = element.children[0].attributes['href'];
                return new LuciBuildBot(client, name, url);
              }).toList();
            }));
  }

  /// [getPrimaryBuilders] fetches all primary builders
  /// (the ones usually used by gardeners) by not including buildbots with
  /// the name -dev, -stable or -integration.
  Future<Try<List<LuciBuildBot>>> getPrimaryBuilders(
      String client, WithCacheFunction withCache) async {
    return await getAllBuildBots(client, withCache)
        .then((Try<List<LuciBuildBot>> tryRes) {
      return tryRes
          .bind((buildBots) => buildBots.where((LuciBuildBot buildBot) {
                return !(buildBot.name.contains("-dev") ||
                    buildBot.name.contains("-stable") ||
                    buildBot.name.contains("-integration"));
              }));
    });
  }

  /// Calling the Milo Api to get latest builds for this bot,
  /// where the field [amount] is the number of recent builds to fetch.
  Future<Try<List<BuildDetail>>> getBuildBotDetails(
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
    var result = await tryStartAsync(() => withCache(
        () => _makePostRequest(uri, JSON.encode(body), {
              HttpHeaders.CONTENT_TYPE: "application/json",
              HttpHeaders.ACCEPT: "application/json"
            }),
        '${uri.path}_${botName}_$amount'));
    return result.bind(JSON.decode).bind((json) {
      return json["builds"].map((b) {
        var build = JSON.decode(UTF8.decode(BASE64.decode(b["data"])));
        return getBuildDetailFromJson(client, botName, build);
      }).toList();
    });
  }

  /// Calling the Milo Api to get information about a specific build
  /// where the field [buildNumber] is the build number to fetch.
  Future<Try<BuildDetail>> getBuildBotBuildDetails(String client,
      String botName, int buildNumber, WithCacheFunction withCache) async {
    var uri = new Uri(
        scheme: "https",
        host: LUCI_HOST,
        path: "prpc/milo.Buildbot/GetBuildbotBuildJSON");
    var body = {"master": client, "builder": botName, "buildNum": buildNumber};
    print(body);
    var result = await tryStartAsync(() => withCache(
        () => _makePostRequest(uri, JSON.encode(body), {
              HttpHeaders.CONTENT_TYPE: "application/json",
              HttpHeaders.ACCEPT: "application/json"
            }),
        '${uri.path}_${botName}_$buildNumber'));
    return result.bind(JSON.decode).bind((json) {
      var build = JSON.decode(UTF8.decode(BASE64.decode(json["data"])));
      return getBuildDetailFromJson(client, botName, build);
    });
  }

  /// [_makeGetRequest] performs a get request to [uri].
  Future<String> _makeGetRequest(Uri uri) async {
    var request = await _client.getUrl(uri);
    var response = await request.close();
    if (response.statusCode != 200) {
      response.drain();
      throw new HttpException(response.reasonPhrase, uri: uri);
    }
    return response.transform(UTF8.decoder).join();
  }

  /// [_makeGetRequest] performs a post request to [uri], where the posted
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
    return new GitCommit(change["revision"], change["revLink"], change["who"],
        change["comments"], change["files"].map((file) => file["name"]));
  }).toList();

  List<BuildProperty> properties = build["properties"].map((prop) {
    return new BuildProperty(prop[0], prop[1].toString(), prop[2]);
  }).toList();

  List<BuildStep> steps = build["steps"].map((step) {
    var start =
        new DateTime.fromMillisecondsSinceEpoch(step["times"][0] * 1000);
    DateTime end = null;
    if (step["times"][1] != null) {
      end = new DateTime.fromMillisecondsSinceEpoch(step["times"][1] * 1000);
    }
    return new BuildStep(
        step["name"],
        step["text"],
        step["results"].toString(),
        start,
        end,
        step["step_number"],
        step["isStarted"],
        step["isFinished"],
        step["logs"].map((log) => new BuildLog(log[0], log[1])));
  }).toList();

  DateTime end = null;
  if (build["times"][1] != null) {
    end = new DateTime.fromMillisecondsSinceEpoch(build["times"][1] * 1000);
  }

  Timing timing = new Timing(
      new DateTime.fromMillisecondsSinceEpoch(build["times"][0] * 1000), end);

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

// Structured classes to relay information from api and web pages

/// [LuciBuildBot] holds information about a build bot
class LuciBuildBot {
  final String client;
  final String name;
  final String url;

  LuciBuildBot(this.client, this.name, this.url);

  @override
  String toString() {
    return "LuciBuildBot { client: $client, name: $name, url: $url }";
  }
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
