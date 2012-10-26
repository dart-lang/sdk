#library('KeyNameLocationTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

// Test for existence of some KeyName and KeyLocation constants.

main() {

  useHtmlConfiguration();

  test('keyNames', () {
      expect(KeyName.DOWN_LEFT, "DownLeft");
      expect(KeyName.FN, "Fn");
      expect(KeyName.F1, "F1");
      expect(KeyName.META, "Meta");
      expect(KeyName.MEDIA_NEXT_TRACK, "MediaNextTrack");
      expect(KeyName.NUM_LOCK, "NumLock");
      expect(KeyName.PAGE_DOWN, "PageDown");
      expect(KeyName.DEAD_IOTA, "DeadIota");
  });

  test('keyLocations', () {
      expect(KeyLocation.STANDARD, 0);
      expect(KeyLocation.LEFT, 1);
      expect(KeyLocation.RIGHT, 2);
      expect(KeyLocation.NUMPAD, 3);
      expect(KeyLocation.MOBILE, 4);
      expect(KeyLocation.JOYSTICK, 5);
  });
}
