// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'buildbot_structures.dart';

/// Data describing the steps of the buildbots.
// TODO(johnniwinther): Add the remaining buildbot groups.
const List<BuildGroup> buildGroups = const <BuildGroup>[
  const BuildGroup(
    groupName: 'dart2js-linux',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-linux-chromeff-1-4-be',
        'dart2js-linux-chromeff-2-4-be',
        'dart2js-linux-chromeff-3-4-be',
        'dart2js-linux-chromeff-4-4-be'
      ], testSteps: const <String>[
        'dart2js chrome tests',
        'dart2js chrome observatory_ui tests',
        'dart2js chrome package tests',
        'dart2js chrome co19 tests',
        'dart2js chrome extra tests',
        'dart2js chrome fast-startup tests',
        'dart2js chrome observatory_ui fast-startup tests',
        'dart2js chrome package fast-startup tests',
        'dart2js chrome co19 fast-startup tests',
        'dart2js chrome extra fast-startup tests',
        'dart2js ff tests',
        'dart2js ff observatory_ui tests',
        'dart2js ff package tests',
        'dart2js ff co19 tests',
        'dart2js ff extra tests',
        'dart2js ff fast-startup tests',
        'dart2js ff observatory_ui fast-startup tests',
        'dart2js ff package fast-startup tests',
        'dart2js ff co19 fast-startup tests',
        'dart2js ff extra fast-startup tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'chrome',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-linux-drt-1-2-be',
        'dart2js-linux-drt-2-2-be',
        'dart2js-linux-drt-csp-minified-be'
      ], testSteps: const <String>[
        'dart2js drt tests',
        'dart2js drt observatory_ui tests',
        'dart2js drt package tests',
        'dart2js drt co19 tests',
        'dart2js drt extra tests',
        'dart2js drt fast-startup tests',
        'dart2js drt observatory_ui fast-startup tests',
        'dart2js drt package fast-startup tests',
        'dart2js drt co19 fast-startup tests',
        'dart2js drt extra fast-startup tests',
        'dart2js drt fast-startup checked tests',
        'dart2js drt observatory_ui fast-startup checked tests',
        'dart2js drt package fast-startup checked tests',
        'dart2js drt co19 fast-startup checked tests',
        'dart2js drt extra fast-startup checked tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-mac10.11-chrome-be'
      ], testSteps: const <String>[
        'dart2js chrome tests',
        'dart2js chrome observatory_ui tests',
        'dart2js chrome package tests',
        'dart2js chrome co19 tests',
        'dart2js chrome extra tests',
        'dart2js chrome fast-startup tests',
        'dart2js chrome observatory_ui fast-startup tests',
        'dart2js chrome package fast-startup tests',
        'dart2js chrome co19 fast-startup tests',
        'dart2js chrome extra fast-startup tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'safari',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-mac10.11-safari-1-3-be',
        'dart2js-mac10.11-safari-2-3-be',
        'dart2js-mac10.11-safari-3-3-be'
      ], testSteps: const <String>[
        'dart2js safari tests',
        'dart2js safari observatory_ui tests',
        'dart2js safari package tests',
        'dart2js safari co19 tests',
        'dart2js safari extra tests',
        'dart2js safari fast-startup tests',
        'dart2js safari observatory_ui fast-startup tests',
        'dart2js safari package fast-startup tests',
        'dart2js safari co19 fast-startup tests',
        'dart2js safari extra fast-startup tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'ie',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-win8-ie10-be'
      ], testSteps: const <String>[
        'dart2js ie10 tests',
        'dart2js ie10 co19 tests',
        'dart2js ie10 fast-startup tests',
        'dart2js ie10 co19 fast-startup tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-win8-ie11-be'
      ], testSteps: const <String>[
        'dart2js ie11 tests',
        'dart2js ie11 co19 tests',
        'dart2js ie11 fast-startup tests',
        'dart2js ie11 co19 fast-startup tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'dart2js-windows',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-win7-ie10chrome-1-4-be',
        'dart2js-win7-ie10chrome-2-4-be',
        'dart2js-win7-ie10chrome-3-4-be',
        'dart2js-win7-ie10chrome-4-4-be'
      ], testSteps: const <String>[
        'dart2js ie10 tests',
        'dart2js ie10 co19 tests',
        'dart2js ie10 fast-startup tests',
        'dart2js ie10 co19 fast-startup tests',
        'dart2js chrome tests',
        'dart2js chrome observatory_ui tests',
        'dart2js chrome package tests',
        'dart2js chrome co19 tests',
        'dart2js chrome extra tests',
        'dart2js chrome fast-startup tests',
        'dart2js chrome observatory_ui fast-startup tests',
        'dart2js chrome package fast-startup tests',
        'dart2js chrome co19 fast-startup tests',
        'dart2js chrome extra fast-startup tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-win7-ie11ff-1-4-be',
        'dart2js-win7-ie11ff-2-4-be',
        'dart2js-win7-ie11ff-3-4-be',
        'dart2js-win7-ie11ff-4-4-be'
      ], testSteps: const <String>[
        'dart2js ie11 tests',
        'dart2js ie11 co19 tests',
        'dart2js ie11 fast-startup tests',
        'dart2js ie11 co19 fast-startup tests',
        'dart2js ff tests',
        'dart2js ff observatory_ui tests',
        'dart2js ff package tests',
        'dart2js ff co19 tests',
        'dart2js ff extra tests',
        'dart2js ff fast-startup tests',
        'dart2js ff observatory_ui fast-startup tests',
        'dart2js ff package fast-startup tests',
        'dart2js ff co19 fast-startup tests',
        'dart2js ff extra fast-startup tests',
      ]),
    ],
  ),
];

/// Descriptor for a buildbot group, e.g. 'dart2js-linux', 'chrome' and
/// 'safari'.
class BuildGroup {
  /// The name of the group as display on the buildbot site.
  final String groupName;

  /// The subgroups, often shards, of the buildbot group.
  final List<BuildSubgroup> subgroups;

  const BuildGroup({this.groupName, this.subgroups});

  /// Returns the [BuildUri] corresponding to the build steps for shards in this
  /// group.
  List<BuildUri> createUris(int buildNumber) {
    List<BuildUri> uriList = <BuildUri>[];
    for (BuildSubgroup subgroup in subgroups) {
      uriList.addAll(subgroup.createUris(buildNumber));
    }
    return uriList;
  }
}

/// A group of buildbot subgroups, often shards, that share their test steps,
/// for instance all `dart2js-win7-ie10chrome-*-4-be` shards.
class BuildSubgroup {
  /// The names of the shards in this, for instance
  /// `dart2js-win7-ie10chrome-1-4-be`, `dart2js-win7-ie10chrome-2-4-be`, etc.
  final List<String> shardNames;

  /// The names of the test steps for the shards in this subgroup, for instance
  /// `dart2js ie10 tests`, `dart2js ie10 co19 tests`, etc.
  final List<String> testSteps;

  const BuildSubgroup({this.shardNames, this.testSteps});

  /// Returns the [BuildUri] corresponding to the build steps for all shards
  /// in this subgroup.
  List<BuildUri> createUris(int buildNumber) {
    List<BuildUri> uriList = <BuildUri>[];
    for (String shardName in shardNames) {
      for (String testStep in testSteps) {
        uriList.add(new BuildUri.fromData(shardName, buildNumber, testStep));
      }
    }
    return uriList;
  }
}
