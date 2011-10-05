// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#library('dartcombat_tests');

#import('../../../../html/html.dart');
#import('../../../../testing/unittest/unittest.dart');
#import('../../../../samples/dartcombat/dartcombatlib.dart');

void main() {
  new DartCombatTests().run();
}

/** Tests for the dart combat app. */
class DartCombatTests extends UnitTestSuite {
  ReceivePort testPort;

  DartCombatTests() : super() {
    testPort = new ReceivePort();
    setupUI();
    // add relative URL to stylesheet to the correct location. Note: The CSS is
    // needed because the app uses a flexbox layout, which is then used to
    // interpret UI events (mousedown/up/click).
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.type = "text/css";
    link.href = "../../samples/dartcombat/dartcombat.css";
    document.head.nodes.add(link);
  }

  void setUpTestSuite() {
    addAsyncTest(waitUntilSetup, 1);
    addAsyncTest(testParallelShoot, 1);
    addAsyncTest(testSerialShoot, 1);
  }

  void waitUntilSetup() {
    int playersReady = 0;
    testPort.receive((message, SendPort reply) {
      if (message[0] == '_TEST:handleSetup') {
        playersReady++;
        if (playersReady == 2) {
          callbackDone();
        }
      }
    });
    createPlayersForTest(testPort.toSendPort());
  }

  void testParallelShoot() {
    // player 2 is configured to make parallel super shots towards player 1
    var p1OwnBoard = document.queryOne("#p1own");

    // add a boat of length 4 using mousedown/mousemove/mouseup
    var startCell = p1OwnBoard.nodes[0].nodes[4].nodes[2];
    var endCell = p1OwnBoard.nodes[0].nodes[4].nodes[5];
    doMouseEvent("mousedown", startCell);
    doMouseEvent("mousemove", endCell);
    doMouseEvent("mouseup", endCell);

    // check that the boat was added:
    var boat = p1OwnBoard.nodes[1];
    Expect.setEquals(["icons", "boat4", "boatdir-left"], boat.classes);

    // check that the boat shows as sunk in player 1's board:
    // Note that the shoot order is respected: center, left, right, up, down,
    // left, right again, as if they progress in parallel.
    List<int> expectedShots = const [
        Constants.HIT,  3, 4,  // initial shot (center)
        Constants.HIT,  2, 4,  // left
        Constants.HIT,  4, 4,  // right
        Constants.MISS, 3, 3,  // up
        Constants.MISS, 3, 5,  // down
        Constants.MISS, 1, 4,  // left
        Constants.SUNK, 5, 4]; // right
    _expectShotSequence(expectedShots, p1OwnBoard, 1);

    // hit the boat from the enemy side.
    var p2EnemyBoard = document.queryOne("#p2enemy");
    var hitCell = p2EnemyBoard.nodes[0].nodes[4].nodes[3];
    doMouseEvent("click", hitCell);
  }

  void testSerialShoot() {
    // player 1 is configured to make serial super shots towards player 2
    var p2OwnBoard = document.queryOne("#p2own");

    // add a boat of length 4 using mousedown/mousemove/mouseup
    var startCell = p2OwnBoard.nodes[0].nodes[3].nodes[8];
    var endCell = p2OwnBoard.nodes[0].nodes[7].nodes[8];
    doMouseEvent("mousedown", startCell);
    doMouseEvent("mousemove", endCell);
    doMouseEvent("mouseup", endCell);

    // check that the boat was added:
    var boat = p2OwnBoard.nodes[1];
    Expect.setEquals(["icons", "boat5", "boatdir-down"], boat.classes);

    // check that the boat shows as sunk in player 2's board:
    // Note that the shoot order is respected: center, left, right, up, down
    // sequentially.
    List<int> expectedShots = const [
      Constants.HIT,  8, 4,  // initial shot (center)
      Constants.MISS, 7, 4,  // left  (miss - stop this direction)
      Constants.MISS, 9, 4,  // right (miss - stop this direction)
      Constants.HIT,  8, 3,  // up
      Constants.MISS, 8, 2,  // up    (miss - stop this direction)
      Constants.HIT,  8, 5,  // down
      Constants.HIT,  8, 6,  // down
      Constants.SUNK, 8, 7]; // down  (sunk - done)
    _expectShotSequence(expectedShots, p2OwnBoard, 2);

    // hit the boat from the enemy side.
    var p1EnemyBoard = document.queryOne("#p1enemy");
    var hitCell = p1EnemyBoard.nodes[0].nodes[4].nodes[8];
    doMouseEvent("click", hitCell);
  }

  void _expectShotSequence(
      List<int> expectedShots, Element playerBoard, int id) {
    int shots = 0;
    testPort.receive((message, SendPort reply) {
      if (message[0] == '_TEST:handleShot') {
        Expect.equals(id, message[1]);
        Expect.equals(expectedShots[(shots * 3)], message[2]);
        Expect.equals(expectedShots[(shots * 3) + 1], message[3]);
        Expect.equals(expectedShots[(shots * 3) + 2], message[4]);
        _checkNodeInfo(playerBoard.nodes[shots + 2],
            "icons " + (expectedShots[shots * 3] == Constants.MISS
              ? "miss" : "hit-onboat"),
            expectedShots[(shots * 3) + 1] * 50,
            expectedShots[(shots * 3) + 2] * 50);
        shots++;
        if (shots * 3 == expectedShots.length) {
          callbackDone();
        }
      }
    });

  }

  void _checkNodeInfo(node, className, x, y) {
    Expect.setEquals(className.split(" "), node.classes);
    Expect.equals("${x}px", node.style.getPropertyValue("left"));
    Expect.equals("${y}px", node.style.getPropertyValue("top"));
  }

  void doMouseEvent(String type, var targetCell) {
    final point = window.webkitConvertPointFromNodeToPage(targetCell,
        new Point(5, 5));

    MouseEvent e = document.createEvent('MouseEvents');
    e.initMouseEvent(type, true, true, window, 0, 0, 0, point.x, point.y,
      false, false, false, false, 0, targetCell);
    targetCell.on[type].dispatch(e);
  }
}
