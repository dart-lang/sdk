// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:collection/iterable_zip.dart";
import "package:unittest/unittest.dart";

/// Iterable like [base] except that it throws when value equals [errorValue].
Iterable iterError(Iterable base, int errorValue) {
  return base.map((x) => x == errorValue ? throw "BAD" : x);
}

main() {
  test("Basic", () {
    expect(new IterableZip([[1, 2, 3], [4, 5, 6], [7, 8, 9]]),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });

  test("Uneven length 1", () {
    expect(new IterableZip([[1, 2, 3, 99, 100], [4, 5, 6], [7, 8, 9]]),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });

  test("Uneven length 2", () {
    expect(new IterableZip([[1, 2, 3], [4, 5, 6, 99, 100], [7, 8, 9]]),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });

  test("Uneven length 3", () {
    expect(new IterableZip([[1, 2, 3], [4, 5, 6], [7, 8, 9, 99, 100]]),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });

  test("Uneven length 3", () {
    expect(new IterableZip([[1, 2, 3, 98], [4, 5, 6], [7, 8, 9, 99, 100]]),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });

  test("Empty 1", () {
    expect(new IterableZip([[], [4, 5, 6], [7, 8, 9]]), equals([]));
  });

  test("Empty 2", () {
    expect(new IterableZip([[1, 2, 3], [], [7, 8, 9]]), equals([]));
  });

  test("Empty 3", () {
    expect(new IterableZip([[1, 2, 3], [4, 5, 6], []]), equals([]));
  });

  test("Empty source", () {
    expect(new IterableZip([]), equals([]));
  });

  test("Single Source", () {
    expect(new IterableZip([[1, 2, 3]]), equals([[1], [2], [3]]));
  });

  test("Not-lists", () {
    // Use other iterables than list literals.
    Iterable it1 = [1, 2, 3, 4, 5, 6].where((x) => x < 4);
    Set it2 = new LinkedHashSet()..add(4)..add(5)..add(6);
    Iterable it3 = (new LinkedHashMap()..[7] = 0 ..[8] = 0 ..[9] = 0).keys;
    Iterable<Iterable> allIts =
        new Iterable.generate(3, (i) => [it1, it2, it3][i]);
    expect(new IterableZip(allIts),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });

  test("Error 1", () {
    expect(() => new IterableZip([iterError([1, 2, 3], 2),
                                  [4, 5, 6],
                                  [7, 8, 9]]).toList(),
           throwsA(equals("BAD")));
  });

  test("Error 2", () {
    expect(() => new IterableZip([[1, 2, 3],
                                  iterError([4, 5, 6], 5),
                                  [7, 8, 9]]).toList(),
           throwsA(equals("BAD")));
  });

  test("Error 3", () {
    expect(() => new IterableZip([[1, 2, 3],
                                  [4, 5, 6],
                                  iterError([7, 8, 9], 8)]).toList(),
           throwsA(equals("BAD")));
  });

  test("Error at end", () {
    expect(() => new IterableZip([[1, 2, 3],
                                  iterError([4, 5, 6], 6),
                                  [7, 8, 9]]).toList(),
           throwsA(equals("BAD")));
  });

  test("Error before first end", () {
    expect(() => new IterableZip([iterError([1, 2, 3, 4], 4),
                                  [4, 5, 6],
                                  [7, 8, 9]]).toList(),
           throwsA(equals("BAD")));
  });

  test("Error after first end", () {
    expect(new IterableZip([[1, 2, 3],
                            [4, 5, 6],
                            iterError([7, 8, 9, 10], 10)]),
           equals([[1, 4, 7], [2, 5, 8], [3, 6, 9]]));
  });
}
