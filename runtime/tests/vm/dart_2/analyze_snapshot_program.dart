import "package:expect/expect.dart";

class MethodChannel {
  final String name;
  const MethodChannel(this.name);

  void dump() {
    print('MethodChannel($name)');
  }
}

final channel1 = MethodChannel("channel1");
final channel2 = MethodChannel("channel2");
const constChannel = MethodChannel("constChannel1");
const constChannel2 = MethodChannel("constChannel2");

main() {
  final mcs = [channel1, channel2, constChannel, constChannel2];
  for (int i = 0; i < mcs.length; ++i) {
    mcs[i].dump();
  }
}
