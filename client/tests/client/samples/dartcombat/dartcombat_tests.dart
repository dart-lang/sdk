// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#library('dartcombat_tests');

#import('dart:html');
#import('../../../../testing/unittest/unittest.dart');
#import('../../../../samples/dartcombat/dartcombatlib.dart');

ReceivePort testPort;

main() {
  testPort = new ReceivePort();

  setupUI();
  // add relative URL to stylesheet to the correct location. Note: The CSS is
  // needed because the app uses a flexbox layout, which is then used to
  // interpret UI events (mousedown/up/click).
  var link = new Element.tag('link');
  link.rel = 'stylesheet';
  link.type = 'text/css';
  link.href = '../../samples/dartcombat/dartcombat.css';
  document.head.nodes.add(link);

  asyncTest('wait until setup', 1, () {
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
  });


  asyncTest('parallel shoot', 1, () {
    // player 2 is configured to make parallel super shots towards player 1
    var p1OwnBoard = document.query('#p1own');

    // add a boat of length 4 using mousedown/mousemove/mouseup
    var startCell = p1OwnBoard.nodes[0].nodes[4].nodes[2];
    var endCell = p1OwnBoard.nodes[0].nodes[4].nodes[5];
    serialInvokeAsync([
      () => doMouseEvent("mousedown", startCell),
      () => doMouseEvent("mousemove", endCell),
      () => doMouseEvent("mouseup", endCell),
      () {
      // check that the boat was added:
      var boat = p1OwnBoard.nodes[1];
      expect(boat.classes).equalsSet(['icons', 'boat4', 'boatdir-left']);

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
      var p2EnemyBoard = document.query("#p2enemy");
      var hitCell = p2EnemyBoard.nodes[0].nodes[4].nodes[3];
      doMouseEvent("click", hitCell);
    }]);
  });

  asyncTest('serial shoot', 1, () {
    // player 1 is configured to make serial super shots towards player 2
    var p2OwnBoard = document.query('#p2own');

    // add a boat of length 4 using mousedown/mousemove/mouseup
    var startCell = p2OwnBoard.nodes[0].nodes[3].nodes[8];
    var endCell = p2OwnBoard.nodes[0].nodes[7].nodes[8];
    serialInvokeAsync([
      () => doMouseEvent("mousedown", startCell),
      () => doMouseEvent("mousemove", endCell),
      () => doMouseEvent("mouseup", endCell),
      () {
      // check that the boat was added:
      var boat = p2OwnBoard.nodes[1];
      expect(boat.classes).equalsSet(['icons', 'boat5', 'boatdir-down']);

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
      var p1EnemyBoard = document.query("#p1enemy");
      var hitCell = p1EnemyBoard.nodes[0].nodes[4].nodes[8];
      doMouseEvent("click", hitCell);
    }]);
  });
}

_expectShotSequence(List<int> expectedShots, Element playerBoard, int id) {
  int shots = 0;
  testPort.receive((message, SendPort reply) {
    if (message[0] == '_TEST:handleShot') {
      expect(message[1]).equals(id);
      expect(message[2]).equals(expectedShots[(shots * 3)]);
      expect(message[3]).equals(expectedShots[(shots * 3) + 1]);
      expect(message[4]).equals(expectedShots[(shots * 3) + 2]);
      _checkNodeInfo(playerBoard.nodes[shots + 2],
          'icons ' + (expectedShots[shots * 3] == Constants.MISS
            ? 'miss' : 'hit-onboat'),
          expectedShots[(shots * 3) + 1] * 50,
          expectedShots[(shots * 3) + 2] * 50);
      shots++;
      if (shots * 3 == expectedShots.length) {
        callbackDone();
      }
    }
  });
}

_checkNodeInfo(node, className, x, y) {
  expect(node.classes).equalsSet(className.split(' '));
  expect(node.style.getPropertyValue('left')).equals('${x}px');
  expect(node.style.getPropertyValue('top')).equals('${y}px');
}

doMouseEvent(String type, var targetCell) {
  final point = window.webkitConvertPointFromNodeToPage(targetCell,
      new Point(5, 5));

  MouseEvent e = new MouseEvent(type, window, 0, 0, 0, point.x, point.y, 0,
      relatedTarget: targetCell);
  targetCell.on[type].dispatch(e);
}
