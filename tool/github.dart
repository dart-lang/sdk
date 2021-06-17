// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:github/github.dart';

Future<List<Issue>> getLinterIssues({Authentication? auth}) async {
  var github = GitHub(auth: auth);
  var slug = RepositorySlug('dart-lang', 'linter');
  try {
    return github.issues.listByRepo(slug).toList();
  } on Exception catch (e) {
    print('exception caught fetching github issues');
    print(e);
    print('(defaulting to an empty list)');
    return Future.value(<Issue>[]);
  }
}

bool isBug(Issue issue) => issue.labels.map((l) => l.name).contains('bug');
