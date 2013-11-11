// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';
import 'package:watcher/src/path_set.dart';

import 'utils.dart';

Matcher containsPath(String path) => predicate((set) =>
    set is PathSet && set.contains(path),
    'set contains "$path"');

Matcher containsDir(String path) => predicate((set) =>
    set is PathSet && set.containsDir(path),
    'set contains directory "$path"');

void main() {
  initConfig();

  var set;
  setUp(() => set = new PathSet("root"));

  group("adding a path", () {
    test("stores the path in the set", () {
      set.add("root/path/to/file");
      expect(set, containsPath("root/path/to/file"));
    });

    test("that's a subdir of another path keeps both in the set", () {
      set.add("root/path");
      set.add("root/path/to/file");
      expect(set, containsPath("root/path"));
      expect(set, containsPath("root/path/to/file"));
    });

    test("that's not normalized normalizes the path before storing it", () {
      set.add("root/../root/path/to/../to/././file");
      expect(set, containsPath("root/path/to/file"));
    });

    test("that's absolute normalizes the path before storing it", () {
      set.add(p.absolute("root/path/to/file"));
      expect(set, containsPath("root/path/to/file"));
    });

    test("that's not beneath the root throws an error", () {
      expect(() => set.add("path/to/file"), throwsArgumentError);
    });
  });

  group("removing a path", () {
    test("that's in the set removes and returns that path", () {
      set.add("root/path/to/file");
      expect(set.remove("root/path/to/file"),
          unorderedEquals([p.normalize("root/path/to/file")]));
      expect(set, isNot(containsPath("root/path/to/file")));
    });

    test("that's not in the set returns an empty set", () {
      set.add("root/path/to/file");
      expect(set.remove("root/path/to/nothing"), isEmpty);
    });

    test("that's a directory removes and returns all files beneath it", () {
      set.add("root/outside");
      set.add("root/path/to/one");
      set.add("root/path/to/two");
      set.add("root/path/to/sub/three");

      expect(set.remove("root/path"), unorderedEquals([
        "root/path/to/one",
        "root/path/to/two",
        "root/path/to/sub/three"
      ].map(p.normalize)));

      expect(set, containsPath("root/outside"));
      expect(set, isNot(containsPath("root/path/to/one")));
      expect(set, isNot(containsPath("root/path/to/two")));
      expect(set, isNot(containsPath("root/path/to/sub/three")));
    });
  
    test("that's a directory in the set removes and returns it and all files "
        "beneath it", () {
      set.add("root/path");
      set.add("root/path/to/one");
      set.add("root/path/to/two");
      set.add("root/path/to/sub/three");

      expect(set.remove("root/path"), unorderedEquals([
        "root/path",
        "root/path/to/one",
        "root/path/to/two",
        "root/path/to/sub/three"
      ].map(p.normalize)));

      expect(set, isNot(containsPath("root/path")));
      expect(set, isNot(containsPath("root/path/to/one")));
      expect(set, isNot(containsPath("root/path/to/two")));
      expect(set, isNot(containsPath("root/path/to/sub/three")));
    });

    test("that's not normalized removes and returns the normalized path", () {
      set.add("root/path/to/file");
      expect(set.remove("root/../root/path/to/../to/./file"),
          unorderedEquals([p.normalize("root/path/to/file")]));
    });

    test("that's absolute removes and returns the normalized path", () {
      set.add("root/path/to/file");
      expect(set.remove(p.absolute("root/path/to/file")),
          unorderedEquals([p.normalize("root/path/to/file")]));
    });

    test("that's not beneath the root throws an error", () {
      expect(() => set.remove("path/to/file"), throwsArgumentError);
    });
  });

  group("containsPath()", () {
    test("returns false for a non-existent path", () {
      set.add("root/path/to/file");
      expect(set, isNot(containsPath("root/path/to/nothing")));
    });

    test("returns false for a directory that wasn't added explicitly", () {
      set.add("root/path/to/file");
      expect(set, isNot(containsPath("root/path")));
    });

    test("returns true for a directory that was added explicitly", () {
      set.add("root/path");
      set.add("root/path/to/file");
      expect(set, containsPath("root/path"));
    });

    test("with a non-normalized path normalizes the path before looking it up",
        () {
      set.add("root/path/to/file");
      expect(set, containsPath("root/../root/path/to/../to/././file"));
    });

    test("with an absolute path normalizes the path before looking it up", () {
      set.add("root/path/to/file");
      expect(set, containsPath(p.absolute("root/path/to/file")));
    });

    test("with a path that's not beneath the root throws an error", () {
      expect(() => set.contains("path/to/file"), throwsArgumentError);
    });
  });

  group("containsDir()", () {
    test("returns true for a directory that was added implicitly", () {
      set.add("root/path/to/file");
      expect(set, containsDir("root/path"));
      expect(set, containsDir("root/path/to"));
    });

    test("returns true for a directory that was added explicitly", () {
      set.add("root/path");
      set.add("root/path/to/file");
      expect(set, containsDir("root/path"));
    });

    test("returns false for a directory that wasn't added", () {
      expect(set, isNot(containsDir("root/nothing")));
    });

    test("returns false for a non-directory path that was added", () {
      set.add("root/path/to/file");
      expect(set, isNot(containsDir("root/path/to/file")));
    });

    test("returns false for a directory that was added implicitly and then "
        "removed implicitly", () {
      set.add("root/path/to/file");
      set.remove("root/path/to/file");
      expect(set, isNot(containsDir("root/path")));
    });

    test("returns false for a directory that was added explicitly whose "
        "children were then removed", () {
      set.add("root/path");
      set.add("root/path/to/file");
      set.remove("root/path/to/file");
      expect(set, isNot(containsDir("root/path")));
    });

    test("with a non-normalized path normalizes the path before looking it up",
        () {
      set.add("root/path/to/file");
      expect(set, containsDir("root/../root/path/to/../to/."));
    });

    test("with an absolute path normalizes the path before looking it up", () {
      set.add("root/path/to/file");
      expect(set, containsDir(p.absolute("root/path")));
    });
  });

  group("toSet", () {
    test("returns paths added to the set", () {
      set.add("root/path");
      set.add("root/path/to/one");
      set.add("root/path/to/two");

      expect(set.toSet(), unorderedEquals([
        "root/path",
        "root/path/to/one",
        "root/path/to/two",
      ].map(p.normalize)));
    });

    test("doesn't return paths removed from the set", () {
      set.add("root/path/to/one");
      set.add("root/path/to/two");
      set.remove("root/path/to/two");

      expect(set.toSet(), unorderedEquals([p.normalize("root/path/to/one")]));
    });
  });

  group("clear", () {
    test("removes all paths from the set", () {
      set.add("root/path");
      set.add("root/path/to/one");
      set.add("root/path/to/two");

      set.clear();
      expect(set.toSet(), isEmpty);
    });
  });
}
