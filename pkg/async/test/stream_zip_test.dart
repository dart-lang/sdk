// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:async/stream_zip.dart";
import "package:unittest/unittest.dart";

/// Create an error with the same values as [base], except that it throwsA
/// when seeing the value [errorValue].
Stream streamError(Stream base, int errorValue, error) {
  return base.map((x) => (x == errorValue) ? throw error : x);
}

/// Make a [Stream] from an [Iterable] by adding events to a stream controller
/// at periodic intervals.
Stream mks(Iterable iterable) {
  Iterator iterator = iterable.iterator;
  StreamController controller = new StreamController();
  // Some varying time between 3 and 10 ms.
  int ms = ((++ctr) * 5) % 7 + 3;
  new Timer.periodic(new Duration(milliseconds: ms), (Timer timer) {
    if (iterator.moveNext()) {
      controller.add(iterator.current);
    } else {
      controller.close();
      timer.cancel();
    }
  });
  return controller.stream;
}

/// Counter used to give varying delays for streams.
int ctr = 0;

main() {
  // Test that zipping [streams] gives the results iterated by [expectedData].
  testZip(Iterable streams, Iterable expectedData) {
    List data = [];
    Stream zip = new StreamZip(streams);
    zip.listen(data.add, onDone: expectAsync0(() {
      expect(data, equals(expectedData));
    }));
  }

  test("Basic", () {
    testZip([mks([1, 2, 3]), mks([4, 5, 6]), mks([7, 8, 9])],
            [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
  });

  test("Uneven length 1", () {
    testZip([mks([1, 2, 3, 99, 100]), mks([4, 5, 6]), mks([7, 8, 9])],
            [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
  });

  test("Uneven length 2", () {
    testZip([mks([1, 2, 3]), mks([4, 5, 6, 99, 100]), mks([7, 8, 9])],
            [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
  });

  test("Uneven length 3", () {
    testZip([mks([1, 2, 3]), mks([4, 5, 6]), mks([7, 8, 9, 99, 100])],
            [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
  });

  test("Uneven length 4", () {
    testZip([mks([1, 2, 3, 98]), mks([4, 5, 6]), mks([7, 8, 9, 99, 100])],
            [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
  });

  test("Empty 1", () {
    testZip([mks([]), mks([4, 5, 6]), mks([7, 8, 9])], []);
  });

  test("Empty 2", () {
    testZip([mks([1, 2, 3]), mks([]), mks([7, 8, 9])], []);
  });

  test("Empty 3", () {
    testZip([mks([1, 2, 3]), mks([4, 5, 6]), mks([])], []);
  });

  test("Empty source", () {
    testZip([], []);
  });

  test("Single Source", () {
    testZip([mks([1, 2, 3])], [[1], [2], [3]]);
  });

  test("Other-streams", () {
    Stream st1 = mks([1, 2, 3, 4, 5, 6]).where((x) => x < 4);
    Stream st2 = new Stream.periodic(const Duration(milliseconds: 5),
                                     (x) => x + 4).take(3);
    StreamController c = new StreamController.broadcast();
    Stream st3 = c.stream;
    testZip([st1, st2, st3],
            [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
    c..add(7)..add(8)..add(9)..close();
  });

  test("Error 1", () {
    expect(new StreamZip([streamError(mks([1, 2, 3]), 2, "BAD-1"),
                          mks([4, 5, 6]),
                          mks([7, 8, 9])]).toList(),
           throwsA(equals("BAD-1")));
  });

  test("Error 2", () {
    expect(new StreamZip([mks([1, 2, 3]),
                          streamError(mks([4, 5, 6]), 5, "BAD-2"),
                          mks([7, 8, 9])]).toList(),
           throwsA(equals("BAD-2")));
  });

  test("Error 3", () {
    expect(new StreamZip([mks([1, 2, 3]),
                          mks([4, 5, 6]),
                          streamError(mks([7, 8, 9]), 8, "BAD-3")]).toList(),
           throwsA(equals("BAD-3")));
  });

  test("Error at end", () {
    expect(new StreamZip([mks([1, 2, 3]),
                          streamError(mks([4, 5, 6]), 6, "BAD-4"),
                          mks([7, 8, 9])]).toList(),
           throwsA(equals("BAD-4")));
  });

  test("Error before first end", () {
    // StreamControllers' streams with no "close" called will never be done,
    // so the fourth event of the first stream is guaranteed to come first.
    expect(new StreamZip(
                [streamError(mks([1, 2, 3, 4]), 4, "BAD-5"),
                 (new StreamController()..add(4)..add(5)..add(6)).stream,
                 (new StreamController()..add(7)..add(8)..add(9)).stream]
               ).toList(),
           throwsA(equals("BAD-5")));
  });

  test("Error after first end", () {
    StreamController controller = new StreamController();
    controller..add(7)..add(8)..add(9);
    // Transformer that puts error into controller when one of the first two
    // streams have sent a done event.
    StreamTransformer trans = new StreamTransformer.fromHandlers(
        handleDone: (EventSink s) {
      Timer.run(() { controller.addError("BAD-6"); });
      s.close();
    });
    testZip([mks([1, 2, 3]).transform(trans),
             mks([4, 5, 6]).transform(trans),
             controller.stream],
           [[1, 4, 7], [2, 5, 8], [3, 6, 9]]);
  });

  test("Pause/Resume", () {
    var done = expectAsync0((){});  // Call to complete test.

    int sc1p = 0;
    StreamController c1 = new StreamController(
      onPause: () {
        sc1p++;
      },
      onResume: () {
        sc1p--;
      });

    int sc2p = 0;
    StreamController c2 = new StreamController(
      onPause: () {
        sc2p++;
      },
      onResume: () {
        sc2p--;
      });
    Stream zip = new StreamZip([c1.stream, c2.stream]);

    const ms25 = const Duration(milliseconds: 25);

    // StreamIterator uses pause and resume to control flow.
    StreamIterator it = new StreamIterator(zip);

    it.moveNext().then((hasMore) {
      expect(hasMore, isTrue);
      expect(it.current, equals([1, 2]));
      return it.moveNext();
    }).then((hasMore) {
      expect(hasMore, isTrue);
      expect(it.current, equals([3, 4]));
      c2.add(6);
      return it.moveNext();
    }).then((hasMore) {
      expect(hasMore, isTrue);
      expect(it.current, equals([5, 6]));
      new Future.delayed(ms25).then((_) { c2.add(8); });
      return it.moveNext();
    }).then((hasMore) {
      expect(hasMore, isTrue);
      expect(it.current, equals([7, 8]));
      c2.add(9);
      return it.moveNext();
    }).then((hasMore) {
      expect(hasMore, isFalse);
      done();
    });

    c1..add(1)..add(3)..add(5)..add(7)..close();
    c2..add(2)..add(4);
  });

  test("pause-resume2", () {
    var s1 = new Stream.fromIterable([0, 2, 4, 6, 8]);
    var s2 = new Stream.fromIterable([1, 3, 5, 7]);
    var sz = new StreamZip([s1, s2]);
    int ctr = 0;
    var sub;
    sub = sz.listen(expectAsync1((v) {
      expect(v, equals([ctr * 2, ctr * 2 + 1]));
      if (ctr == 1) {
        sub.pause(new Future.delayed(const Duration(milliseconds: 25)));
      } else if (ctr == 2) {
        sub.pause();
        new Future.delayed(const Duration(milliseconds: 25)).then((_) {
          sub.resume();
        });
      }
      ctr++;
    }, count: 4));
  });
}
