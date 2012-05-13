#library('TypedArrays1Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {

  useDomConfiguration();

  test('createByLengthTest', () {
      var a = new Float32Array(10);
      Expect.equals(10, a.length);
      Expect.equals(0, a[4]);
  });

  test('aliasTest', () {
      var a1 = new Uint8Array.fromList([0,0,1,0x45]);
      var a2 = new Float32Array.fromBuffer(a1.buffer);

      Expect.equals(1, a2.length);

      // 0x45010000 = 2048+16
      Expect.equals(2048 + 16, a2[0]);

      a1[2] = 0;
      // 0x45000000 = 2048
      Expect.equals(2048, a2[0]);

      a1[3]--;
      a1[2] += 128;
      // 0x44800000 = 1024
      Expect.equals(1024, a2[0]);

  });

  test('aliasClampedTest', () {
      var a1 = new Uint8ClampedArray.fromList([0,0,1,0x45]);
      var a2 = new Float32Array.fromBuffer(a1.buffer);

      Expect.equals(1, a2.length);

      // 0x45010000 = 2048+16
      Expect.equals(2048 + 16, a2[0]);

      a1[2] = 0;
      // 0x45000000 = 2048
      Expect.equals(2048, a2[0]);

      a1[3]--;
      a1[2] += 128;
      // 0x44800000 = 1024
      Expect.equals(1024, a2[0]);

  });

  test('typeTests', () {
      var a = new Float32Array(10);
      Expect.isTrue(a is List);
      Expect.isTrue(a is List<num>);
      Expect.isTrue(a is! List<String>);
    });
}
