import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isWindowBase = predicate((x) => x is WindowBase, 'is a WindowBase');
  var isWindow = predicate((x) => x is Window, 'is a Window');
  var isLocationBase = predicate((x) => x is LocationBase, 'is a LocationBase');
  var isLocation = predicate((x) => x is Location, 'is a Location');
  var isHistoryBase = predicate((x) => x is HistoryBase, 'is a HistoryBase');
  var isHistory = predicate((x) => x is History, 'is a History');

  final dynamic iframe = new IFrameElement();
  document.body.append(iframe);

  test('window', () {
    expect(window, isWindow);
    expect(window.document, document);
  });

  test('iframe', () {
    final frameWindow = iframe.contentWindow;
    expect(frameWindow, isWindowBase);
    //TODO(gram) The next test should be written as:
    //    expect(frameWindow, isNot(isWindow));
    // but that will cause problems now until is/is! work
    // properly in dart2js instead of always returning true.
    expect(frameWindow is! Window, isTrue);
    expect(frameWindow.parent, isWindow);

    // Ensure that the frame's document is inaccessible via window.
    expect(() => frameWindow.document, throws);
  });

  test('contentDocument', () {
    // Ensure that the frame's document is inaccessible.
    expect(() => iframe.contentDocument, throws);
  });

  test('location', () {
    expect(window.location, isLocation);
    final frameLocation = iframe.contentWindow.location;
    expect(frameLocation, isLocationBase);
    // TODO(gram) Similar to the above, the next test should be:
    //     expect(frameLocation, isNot(isLocation));
    expect(frameLocation is! Location, isTrue);

    expect(() => frameLocation.href, throws);
    expect(() => frameLocation.hash, throws);

    final frameParentLocation = iframe.contentWindow.parent.location;
    expect(frameParentLocation, isLocation);
  });

  test('history', () {
    expect(window.history, isHistory);
    final frameHistory = iframe.contentWindow.history;
    expect(frameHistory, isHistoryBase);
    // See earlier comments.
    //expect(frameHistory, isNot(isHistory));
    expect(frameHistory is! History, isTrue);

    // Valid methods.
    frameHistory.forward();

    expect(() => frameHistory.length, throws);

    final frameParentHistory = iframe.contentWindow.parent.history;
    expect(frameParentHistory, isHistory);
  });
}
