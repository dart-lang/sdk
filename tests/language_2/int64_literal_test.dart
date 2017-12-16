import 'package:expect/expect.dart';

const String realMaxInt64Value = '9223372036854775807';
const String realMinInt64Value = '-9223372036854775808';

main() {
  int minInt64Value = (-9223372036854775807) - 1;
  minInt64Value = -(1 << 63);               /// 01: ok
  minInt64Value = -9223372036854775808;     /// 02: ok
  minInt64Value = -(9223372036854775808);   /// 03: compile-time error
  minInt64Value = -(0x8000000000000000);    /// 04: ok
  minInt64Value = 0x8000000000000000;       /// 05: ok

  Expect.equals('$minInt64Value', realMinInt64Value);
  Expect.equals('${minInt64Value - 1}', realMaxInt64Value);

  int maxInt64Value = 9223372036854775807;
  maxInt64Value = (1 << 63) - 1;            /// 10: ok
  maxInt64Value = 9223372036854775807;      /// 20: ok
  maxInt64Value = 9223372036854775808 - 1;  /// 30: compile-time error
  maxInt64Value = 0x8000000000000000 - 1;   /// 40: ok

  Expect.equals('$maxInt64Value', realMaxInt64Value);
  Expect.equals('${maxInt64Value + 1}', realMinInt64Value);
}
