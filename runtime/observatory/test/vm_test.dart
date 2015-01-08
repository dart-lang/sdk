import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [

(Isolate isolate) {
  VM vm = isolate.owner;
  expect(vm.targetCPU, isNotNull);
  expect(vm.architectureBits == 32 ||
         vm.architectureBits == 64, isTrue);
},

];

main(args) => runIsolateTests(args, tests);
