// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'buildbot_structures.dart';

/// Data describing the steps of the buildbots.
const List<BuildGroup> buildGroups = const <BuildGroup>[
  const BuildGroup(
    groupName: 'vm',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-debug-simdbc64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-release-simdbc64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-debug-x64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-x64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-debug-ia32-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-ia32-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-debug-x64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-release-x64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-debug-ia32-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-release-ia32-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-win-debug-x64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-win-release-x64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-win-debug-ia32-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-win-release-ia32-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-debug-simmips-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-simmips-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-debug-simarm-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-simarm-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-simarm64-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-app',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'app-linux-debug-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'app-linux-release-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'app-linux-product-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-kernel',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'vm-kernel-linux-release-x64-be',
      ], testSteps: const <String>[
        'front-end tests',
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-kernel-linux-debug-x64-be',
      ], testSteps: const <String>[
        'front-end tests',
        'vm tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-misc',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'vm-win-debug-ia32-russian-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'cross-arm-vm-linux-release-be',
      ], testSteps: const <String>[
        '', // This subgroup triggers other tests.
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-ia32-asan-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-x64-asan-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-ia32-optcounter-threshold-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-x64-optcounter-threshold-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      // TODO(dmitryas): add data for this subgroup
      // const BuildSubgroup(shardNames: const <String>[
      //   '',
      // ], testSteps: const <String>[
      //   '',
      // ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-precomp',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'vm-noopt-simarm64-mac-be',
      ], testSteps: const <String>[
        'test vm',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-precomp-android-release-1-3-be',
        'vm-precomp-android-release-2-3-be',
        'vm-precomp-android-release-3-3-be',
      ], testSteps: const <String>[
        'test vm',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'precomp-linux-debug-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'precomp-linux-product-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-precomp-win-simarm64-1-4-be',
        'vm-precomp-win-simarm64-2-4-be',
        'vm-precomp-win-simarm64-3-4-be',
        'vm-precomp-win-simarm64-4-4-be',
      ], testSteps: const <String>[
        'test vm',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-product',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-product-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-win-product-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-product-x64-be',
      ], testSteps: const <String>[
        'vm tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-reload',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-debug-x64-reload-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-debug-x64-reload-rollback-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-debug-simdbc64-reload-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-x64-reload-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-linux-release-x64-reload-rollback-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'vm-mac-release-simdbc64-reload-be',
      ], testSteps: const <String>[
        'vm tests',
        'checked vm tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'dart2js-d8-hostchecked',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-linux-d8-hostchecked-1-5-be',
        'dart2js-linux-d8-hostchecked-2-5-be',
        'dart2js-linux-d8-hostchecked-3-5-be',
        'dart2js-linux-d8-hostchecked-4-5-be',
        'dart2js-linux-d8-hostchecked-5-5-be',
      ], testSteps: const <String>[
        'dart2js d8 tests',
        'dart2js d8 package tests',
        'dart2js d8 observatory_ui tests',
        'dart2js d8 co19 tests',
        'dart2js d8 extra tests',
        'dart2js d8 try tests',
        'dart2js d8 checked tests',
        'dart2js d8 package checked tests',
        'dart2js d8 observatory_ui checked tests',
        'dart2js d8 co19 checked tests',
        'dart2js d8 extra checked tests',
        'dart2js d8 try checked tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'dart2js-d8-minified',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-linux-d8-minified-1-5-be',
        'dart2js-linux-d8-minified-2-5-be',
        'dart2js-linux-d8-minified-3-5-be',
        'dart2js-linux-d8-minified-4-5-be',
        'dart2js-linux-d8-minified-5-5-be',
      ], testSteps: const <String>[
        'dart2js d8 tests',
        'dart2js d8 observatory_ui tests',
        'dart2js d8 package tests',
        'dart2js d8 co19 tests',
        'dart2js d8 extra tests',
        'dart2js d8 fast-startup tests',
        'dart2js d8 observatory_ui fast-startup tests',
        'dart2js d8 package fast-startup tests',
        'dart2js d8 co19 fast-startup tests',
        'dart2js d8 extra fast-startup tests',
        'dart2js d8 fast-startup checked tests',
        'dart2js d8 observatory_ui fast-startup checked tests',
        'dart2js d8 package fast-startup checked tests',
        'dart2js d8 co19 fast-startup checked tests',
        'dart2js d8 extra fast-startup checked tests',
      ])
    ],
  ),
  const BuildGroup(
    groupName: 'dart2js-jsshell',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-linux-jsshell-1-4-be',
        'dart2js-linux-jsshell-2-4-be',
        'dart2js-linux-jsshell-3-4-be',
        'dart2js-linux-jsshell-4-4-be',
      ], testSteps: const <String>[
        'dart2js unit tests',
        'dart2js jsshell tests',
        'dart2js jsshell observatory_ui tests',
        'dart2js jsshell package tests',
        'dart2js jsshell co19 tests',
        'dart2js jsshell extra tests',
        'dart2js jsshell fast-startup tests',
        'dart2js jsshell observatory_ui fast-startup tests',
        'dart2js jsshell package fast-startup tests',
        'dart2js jsshell co19 fast-startup tests',
        'dart2js jsshell extra fast-startup tests',
      ])
    ],
  ),
  const BuildGroup(
    groupName: 'dart2js',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-dump-info-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ])
    ],
  ),
  const BuildGroup(
    groupName: 'analyzer',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'analyzer-mac10.11-release-be',
      ], testSteps: const <String>[
        'analyze tests',
        'analyze pkg tests',
        'analyze tests checked',
        'analyze pkg tests checked',
        'analyzer unit tests',
        'analysis server unit tests',
        'analyzer_cli unit tests',
        'front end unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'analyzer-linux-release-be',
      ], testSteps: const <String>[
        'analyze tests',
        'analyze pkg tests',
        'analyze tests checked',
        'analyze pkg tests checked',
        'analyzer unit tests',
        'analysis server unit tests',
        'analyzer_cli unit tests',
        'front end unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'analyzer-win7-release-be',
      ], testSteps: const <String>[
        'analyze tests',
        'analyze pkg tests',
        'analyze tests checked',
        'analyze pkg tests checked',
        'analyzer unit tests',
        'analysis server unit tests',
        'analyzer_cli unit tests',
        'front end unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'analyzer-mac10.11-release-strong-be',
      ], testSteps: const <String>[
        'analyze tests',
        'analyze pkg tests',
        'analyze tests checked',
        'analyze pkg tests checked',
        'analyze strong tests',
        'analyze strong tests checked',
        'analyzer unit tests',
        'analysis server unit tests',
        'analyzer_cli unit tests',
        'front end unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'analyzer-linux-release-strong-be',
      ], testSteps: const <String>[
        'analyze tests',
        'analyze pkg tests',
        'analyze tests checked',
        'analyze pkg tests checked',
        'analyze strong tests',
        'analyze strong tests checked',
        'analyzer unit tests',
        'analysis server unit tests',
        'analyzer_cli unit tests',
        'front end unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'analyzer-win7-release-strong-be',
      ], testSteps: const <String>[
        'analyze tests',
        'analyze pkg tests',
        'analyze tests checked',
        'analyze pkg tests checked',
        'analyze strong tests',
        'analyze strong tests checked',
        'analyzer unit tests',
        'analysis server unit tests',
        'analyzer_cli unit tests',
        'front end unit tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'dart-sdk',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dart-sdk-linux-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dart-sdk-windows-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dart-sdk-mac-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'sdk-trigger-be',
      ], testSteps: const <String>[
        '', // This subgroup triggers other tests.
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'dartium-inc',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dartium-linux-x64-inc-be',
      ], testSteps: const <String>[
        'annotated steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dartium-mac-x64-inc-be',
      ], testSteps: const <String>[
        'annotated steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dartium-win-ia32-inc-be',
      ], testSteps: const <String>[
        'annotated steps',
      ]),
    ],
  ),
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
      ], isActive: false), // Replaced by 'win8-ie11' and 'win7-chrome'.
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-win8-ie11-1-4-be',
        'dart2js-win8-ie11-2-4-be',
        'dart2js-win8-ie11-3-4-be',
        'dart2js-win8-ie11-4-4-be'
      ], testSteps: const <String>[
        'dart2js ie11 tests',
        'dart2js ie11 co19 tests',
        'dart2js ie11 fast-startup tests',
        'dart2js ie11 co19 fast-startup tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dart2js-win7-chrome-1-4-be',
        'dart2js-win7-chrome-2-4-be',
        'dart2js-win7-chrome-3-4-be',
        'dart2js-win7-chrome-4-4-be'
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
  const BuildGroup(
    groupName: 'pub-pkg',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'pub-mac-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'pub-linux-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'pkg-mac10.11-release-be',
      ], testSteps: const <String>[
        'package unit tests',
        'third_party/pkg_tested unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'pkg-linux-release-be',
      ], testSteps: const <String>[
        'package unit tests',
        'third_party/pkg_tested unit tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'pkg-win7-release-be',
      ], testSteps: const <String>[
        'package unit tests',
        'third_party/pkg_tested unit tests',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'dartium-full',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'dartium-linux-x64-be',
      ], testSteps: const <String>[
        'annotated steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dartium-mac-x64-be',
      ], testSteps: const <String>[
        'annotated steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'dartium-win-ia32-be',
      ], testSteps: const <String>[
        'annotated steps',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'misc',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'version-checker-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'linux-distribution-support-debian_wheezy-be',
      ], testSteps: const <String>[
        'annotated_steps',
      ]),
    ],
  ),
  const BuildGroup(
    groupName: 'vm-app-dev',
    subgroups: const <BuildSubgroup>[
      const BuildSubgroup(shardNames: const <String>[
        'app-linux-debug-x64-dev',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'app-linux-release-x64-dev',
      ], testSteps: const <String>[
        'vm tests',
      ]),
      const BuildSubgroup(shardNames: const <String>[
        'app-linux-product-x64-dev',
      ], testSteps: const <String>[
        'vm tests',
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
  List<BuildUri> createUris(int buildNumber, {bool includeInactive: false}) {
    List<BuildUri> uriList = <BuildUri>[];
    for (BuildSubgroup subgroup in subgroups) {
      if (!subgroup.isActive && !includeInactive) continue;
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

  /// Whether this subgroup is currently on the buildbot.
  ///
  /// Set this to `false` to preserve data for older build structures. The data
  /// will continuously be available through logdog.
  final bool isActive;

  const BuildSubgroup({this.shardNames, this.testSteps, this.isActive: true});

  Map<String, String> get logDogPaths {
    Map<String, String> paths = <String, String>{};
    for (String shardName in shardNames) {
      paths[shardName] = 'chromium/bb/client.dart/$shardName';
    }
    return paths;
  }

  /// Returns the [BuildUri] corresponding to the build steps for all shards
  /// in this subgroup.
  List<BuildUri> createUris(int buildNumber) {
    List<BuildUri> uriList = <BuildUri>[];
    for (String shardName in shardNames) {
      uriList.addAll(createShardUris(shardName, buildNumber));
    }
    return uriList;
  }

  List<BuildUri> createShardUris(String shardName, int buildNumber) {
    List<BuildUri> uriList = <BuildUri>[];
    for (String testStep in testSteps) {
      uriList.add(new BuildUri.fromData(shardName, buildNumber, testStep));
    }
    return uriList;
  }
}
