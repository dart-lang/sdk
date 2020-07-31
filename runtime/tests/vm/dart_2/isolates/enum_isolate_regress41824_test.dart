// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

enum Command {
  kValue0,
  kValue1,
  kValue2,
  kValue3,
  kValue4,
  kValue5,
  kValue6,
  kValue7,
  kValue8,
  kValue9,
  kValue10,
  kValue11,
  kValue12,
  kValue13,
  kValue14,
  kValue15,
  kValue16,
  kValue17,
  kValue18,
  kValue19,
  kValue20,
  kValue21,
  kValue22,
  kValue23,
  kValue24,
  kValue25,
  kValue26,
  kValue27,
  kValue28,
  kValue29,
  kValue30,
  kValue31,
  kValue32,
  kValue33,
  kValue34,
  kValue35,
  kValue36,
  kValue37,
  kValue38,
  kValue39,
  kValue40,
  kValue41,
  kValue42,
  kValue43,
  kValue44,
  kValue45,
  kValue46,
  kValue47,
  kValue48,
  kValue49,
  kValue50,
  kValue51,
  kValue52,
  kValue53,
  kValue54,
  kValue55,
  kValue56,
  kValue57,
  kValue58,
  kValue59,
  kValue60,
  kValue61,
  kValue62,
  kValue63,
  kValue64,
  kValue65,
  kValue66,
  kValue67,
  kValue68,
  kValue69,
  kValue70,
  kValue71,
  kValue72,
  kValue73,
  kValue74,
  kValue75,
  kValue76,
  kValue77,
  kValue78,
  kValue79,
  kValue80,
  kValue81,
  kValue82,
  kValue83,
  kValue84,
  kValue85,
  kValue86,
  kValue87,
  kValue88,
  kValue89,
  kValue90,
  kValue91,
  kValue92,
  kValue93,
  kValue94,
  kValue95,
  kValue96,
  kValue97,
  kValue98,
  kValue99,
  kValue100,
  kValue101,
  kValue102,
  kValue103,
  kValue104,
  kValue105,
  kValue106,
  kValue107,
  kValue108,
  kValue109,
  kValue110,
  kValue111,
  kValue112,
  kValue113,
  kValue114,
  kValue115,
  kValue116,
  kValue117,
  kValue118,
  kValue119,
  kValue120,
  kValue121,
  kValue122,
  kValue123,
  kValue124,
  kValue125,
  kValue126,
  kValue127,
  kValue128,
  kValue129,
  kValue130,
  kValue131,
  kValue132,
  kValue133,
  kValue134,
  kValue135,
  kValue136,
  kValue137,
  kValue138,
  kValue139,
  kValue140,
  kValue141,
  kValue142,
  kValue143,
  kValue144,
  kValue145,
  kValue146,
  kValue147,
  kValue148,
  kValue149,
  kValue150,
  kValue151,
  kValue152,
  kValue153,
  kValue154,
  kValue155,
  kValue156,
  kValue157,
  kValue158,
  kValue159,
  kValue160,
  kValue161,
  kValue162,
  kValue163,
  kValue164,
  kValue165,
  kValue166,
  kValue167,
  kValue168,
  kValue169,
  kValue170,
  kValue171,
  kValue172,
  kValue173,
  kValue174,
  kValue175,
  kValue176,
  kValue177,
  kValue178,
  kValue179,
  kValue180,
  kValue181,
  kValue182,
  kValue183,
  kValue184,
  kValue185,
  kValue186,
  kValue187,
  kValue188,
  kValue189,
  kValue190,
  kValue191,
  kValue192,
  kValue193,
  kValue194,
  kValue195,
  kValue196,
  kValue197,
  kValue198,
  kValue199,
  kValue200
}

void tryClose(List list) {
  final List commands = list[0];
  final SendPort sendPort = list[1];
  sendPort.send(identical(commands[0], Command.kValue0) &&
      identical(commands[1], Command.kValue1) &&
      identical(commands[2], Command.kValue2) &&
      identical(commands[3], Command.kValue3) &&
      identical(commands[4], Command.kValue4) &&
      identical(commands[5], Command.kValue5) &&
      identical(commands[6], Command.kValue6) &&
      identical(commands[7], Command.kValue7) &&
      identical(commands[8], Command.kValue8) &&
      identical(commands[9], Command.kValue9) &&
      identical(commands[10], Command.kValue10) &&
      identical(commands[11], Command.kValue11) &&
      identical(commands[12], Command.kValue12) &&
      identical(commands[13], Command.kValue13) &&
      identical(commands[14], Command.kValue14) &&
      identical(commands[15], Command.kValue15) &&
      identical(commands[16], Command.kValue16) &&
      identical(commands[17], Command.kValue17) &&
      identical(commands[18], Command.kValue18) &&
      identical(commands[19], Command.kValue19) &&
      identical(commands[20], Command.kValue20) &&
      identical(commands[21], Command.kValue21) &&
      identical(commands[22], Command.kValue22) &&
      identical(commands[23], Command.kValue23) &&
      identical(commands[24], Command.kValue24) &&
      identical(commands[25], Command.kValue25) &&
      identical(commands[26], Command.kValue26) &&
      identical(commands[27], Command.kValue27) &&
      identical(commands[28], Command.kValue28) &&
      identical(commands[29], Command.kValue29) &&
      identical(commands[30], Command.kValue30) &&
      identical(commands[31], Command.kValue31) &&
      identical(commands[32], Command.kValue32) &&
      identical(commands[33], Command.kValue33) &&
      identical(commands[34], Command.kValue34) &&
      identical(commands[35], Command.kValue35) &&
      identical(commands[36], Command.kValue36) &&
      identical(commands[37], Command.kValue37) &&
      identical(commands[38], Command.kValue38) &&
      identical(commands[39], Command.kValue39) &&
      identical(commands[40], Command.kValue40) &&
      identical(commands[41], Command.kValue41) &&
      identical(commands[42], Command.kValue42) &&
      identical(commands[43], Command.kValue43) &&
      identical(commands[44], Command.kValue44) &&
      identical(commands[45], Command.kValue45) &&
      identical(commands[46], Command.kValue46) &&
      identical(commands[47], Command.kValue47) &&
      identical(commands[48], Command.kValue48) &&
      identical(commands[49], Command.kValue49) &&
      identical(commands[50], Command.kValue50) &&
      identical(commands[51], Command.kValue51) &&
      identical(commands[52], Command.kValue52) &&
      identical(commands[53], Command.kValue53) &&
      identical(commands[54], Command.kValue54) &&
      identical(commands[55], Command.kValue55) &&
      identical(commands[56], Command.kValue56) &&
      identical(commands[57], Command.kValue57) &&
      identical(commands[58], Command.kValue58) &&
      identical(commands[59], Command.kValue59) &&
      identical(commands[60], Command.kValue60) &&
      identical(commands[61], Command.kValue61) &&
      identical(commands[62], Command.kValue62) &&
      identical(commands[63], Command.kValue63) &&
      identical(commands[64], Command.kValue64) &&
      identical(commands[65], Command.kValue65) &&
      identical(commands[66], Command.kValue66) &&
      identical(commands[67], Command.kValue67) &&
      identical(commands[68], Command.kValue68) &&
      identical(commands[69], Command.kValue69) &&
      identical(commands[70], Command.kValue70) &&
      identical(commands[71], Command.kValue71) &&
      identical(commands[72], Command.kValue72) &&
      identical(commands[73], Command.kValue73) &&
      identical(commands[74], Command.kValue74) &&
      identical(commands[75], Command.kValue75) &&
      identical(commands[76], Command.kValue76) &&
      identical(commands[77], Command.kValue77) &&
      identical(commands[78], Command.kValue78) &&
      identical(commands[79], Command.kValue79) &&
      identical(commands[80], Command.kValue80) &&
      identical(commands[81], Command.kValue81) &&
      identical(commands[82], Command.kValue82) &&
      identical(commands[83], Command.kValue83) &&
      identical(commands[84], Command.kValue84) &&
      identical(commands[85], Command.kValue85) &&
      identical(commands[86], Command.kValue86) &&
      identical(commands[87], Command.kValue87) &&
      identical(commands[88], Command.kValue88) &&
      identical(commands[89], Command.kValue89) &&
      identical(commands[90], Command.kValue90) &&
      identical(commands[91], Command.kValue91) &&
      identical(commands[92], Command.kValue92) &&
      identical(commands[93], Command.kValue93) &&
      identical(commands[94], Command.kValue94) &&
      identical(commands[95], Command.kValue95) &&
      identical(commands[96], Command.kValue96) &&
      identical(commands[97], Command.kValue97) &&
      identical(commands[98], Command.kValue98) &&
      identical(commands[99], Command.kValue99) &&
      identical(commands[100], Command.kValue100) &&
      identical(commands[101], Command.kValue101) &&
      identical(commands[102], Command.kValue102) &&
      identical(commands[103], Command.kValue103) &&
      identical(commands[104], Command.kValue104) &&
      identical(commands[105], Command.kValue105) &&
      identical(commands[106], Command.kValue106) &&
      identical(commands[107], Command.kValue107) &&
      identical(commands[108], Command.kValue108) &&
      identical(commands[109], Command.kValue109) &&
      identical(commands[110], Command.kValue110) &&
      identical(commands[111], Command.kValue111) &&
      identical(commands[112], Command.kValue112) &&
      identical(commands[113], Command.kValue113) &&
      identical(commands[114], Command.kValue114) &&
      identical(commands[115], Command.kValue115) &&
      identical(commands[116], Command.kValue116) &&
      identical(commands[117], Command.kValue117) &&
      identical(commands[118], Command.kValue118) &&
      identical(commands[119], Command.kValue119) &&
      identical(commands[120], Command.kValue120) &&
      identical(commands[121], Command.kValue121) &&
      identical(commands[122], Command.kValue122) &&
      identical(commands[123], Command.kValue123) &&
      identical(commands[124], Command.kValue124) &&
      identical(commands[125], Command.kValue125) &&
      identical(commands[126], Command.kValue126) &&
      identical(commands[127], Command.kValue127) &&
      identical(commands[128], Command.kValue128) &&
      identical(commands[129], Command.kValue129) &&
      identical(commands[130], Command.kValue130) &&
      identical(commands[131], Command.kValue131) &&
      identical(commands[132], Command.kValue132) &&
      identical(commands[133], Command.kValue133) &&
      identical(commands[134], Command.kValue134) &&
      identical(commands[135], Command.kValue135) &&
      identical(commands[136], Command.kValue136) &&
      identical(commands[137], Command.kValue137) &&
      identical(commands[138], Command.kValue138) &&
      identical(commands[139], Command.kValue139) &&
      identical(commands[140], Command.kValue140) &&
      identical(commands[141], Command.kValue141) &&
      identical(commands[142], Command.kValue142) &&
      identical(commands[143], Command.kValue143) &&
      identical(commands[144], Command.kValue144) &&
      identical(commands[145], Command.kValue145) &&
      identical(commands[146], Command.kValue146) &&
      identical(commands[147], Command.kValue147) &&
      identical(commands[148], Command.kValue148) &&
      identical(commands[149], Command.kValue149) &&
      identical(commands[150], Command.kValue150) &&
      identical(commands[151], Command.kValue151) &&
      identical(commands[152], Command.kValue152) &&
      identical(commands[153], Command.kValue153) &&
      identical(commands[154], Command.kValue154) &&
      identical(commands[155], Command.kValue155) &&
      identical(commands[156], Command.kValue156) &&
      identical(commands[157], Command.kValue157) &&
      identical(commands[158], Command.kValue158) &&
      identical(commands[159], Command.kValue159) &&
      identical(commands[160], Command.kValue160) &&
      identical(commands[161], Command.kValue161) &&
      identical(commands[162], Command.kValue162) &&
      identical(commands[163], Command.kValue163) &&
      identical(commands[164], Command.kValue164) &&
      identical(commands[165], Command.kValue165) &&
      identical(commands[166], Command.kValue166) &&
      identical(commands[167], Command.kValue167) &&
      identical(commands[168], Command.kValue168) &&
      identical(commands[169], Command.kValue169) &&
      identical(commands[170], Command.kValue170) &&
      identical(commands[171], Command.kValue171) &&
      identical(commands[172], Command.kValue172) &&
      identical(commands[173], Command.kValue173) &&
      identical(commands[174], Command.kValue174) &&
      identical(commands[175], Command.kValue175) &&
      identical(commands[176], Command.kValue176) &&
      identical(commands[177], Command.kValue177) &&
      identical(commands[178], Command.kValue178) &&
      identical(commands[179], Command.kValue179) &&
      identical(commands[180], Command.kValue180) &&
      identical(commands[181], Command.kValue181) &&
      identical(commands[182], Command.kValue182) &&
      identical(commands[183], Command.kValue183) &&
      identical(commands[184], Command.kValue184) &&
      identical(commands[185], Command.kValue185) &&
      identical(commands[186], Command.kValue186) &&
      identical(commands[187], Command.kValue187) &&
      identical(commands[188], Command.kValue188) &&
      identical(commands[189], Command.kValue189) &&
      identical(commands[190], Command.kValue190) &&
      identical(commands[191], Command.kValue191) &&
      identical(commands[192], Command.kValue192) &&
      identical(commands[193], Command.kValue193) &&
      identical(commands[194], Command.kValue194) &&
      identical(commands[195], Command.kValue195) &&
      identical(commands[196], Command.kValue196) &&
      identical(commands[197], Command.kValue197) &&
      identical(commands[198], Command.kValue198) &&
      identical(commands[199], Command.kValue199) &&
      identical(commands[200], Command.kValue200));
}

main(args) async {
  final rp = ReceivePort();
  final si = StreamIterator(rp);
  print('spawning child isolate');
  await Isolate.spawn(tryClose, [
    [
      Command.kValue0,
      Command.kValue1,
      Command.kValue2,
      Command.kValue3,
      Command.kValue4,
      Command.kValue5,
      Command.kValue6,
      Command.kValue7,
      Command.kValue8,
      Command.kValue9,
      Command.kValue10,
      Command.kValue11,
      Command.kValue12,
      Command.kValue13,
      Command.kValue14,
      Command.kValue15,
      Command.kValue16,
      Command.kValue17,
      Command.kValue18,
      Command.kValue19,
      Command.kValue20,
      Command.kValue21,
      Command.kValue22,
      Command.kValue23,
      Command.kValue24,
      Command.kValue25,
      Command.kValue26,
      Command.kValue27,
      Command.kValue28,
      Command.kValue29,
      Command.kValue30,
      Command.kValue31,
      Command.kValue32,
      Command.kValue33,
      Command.kValue34,
      Command.kValue35,
      Command.kValue36,
      Command.kValue37,
      Command.kValue38,
      Command.kValue39,
      Command.kValue40,
      Command.kValue41,
      Command.kValue42,
      Command.kValue43,
      Command.kValue44,
      Command.kValue45,
      Command.kValue46,
      Command.kValue47,
      Command.kValue48,
      Command.kValue49,
      Command.kValue50,
      Command.kValue51,
      Command.kValue52,
      Command.kValue53,
      Command.kValue54,
      Command.kValue55,
      Command.kValue56,
      Command.kValue57,
      Command.kValue58,
      Command.kValue59,
      Command.kValue60,
      Command.kValue61,
      Command.kValue62,
      Command.kValue63,
      Command.kValue64,
      Command.kValue65,
      Command.kValue66,
      Command.kValue67,
      Command.kValue68,
      Command.kValue69,
      Command.kValue70,
      Command.kValue71,
      Command.kValue72,
      Command.kValue73,
      Command.kValue74,
      Command.kValue75,
      Command.kValue76,
      Command.kValue77,
      Command.kValue78,
      Command.kValue79,
      Command.kValue80,
      Command.kValue81,
      Command.kValue82,
      Command.kValue83,
      Command.kValue84,
      Command.kValue85,
      Command.kValue86,
      Command.kValue87,
      Command.kValue88,
      Command.kValue89,
      Command.kValue90,
      Command.kValue91,
      Command.kValue92,
      Command.kValue93,
      Command.kValue94,
      Command.kValue95,
      Command.kValue96,
      Command.kValue97,
      Command.kValue98,
      Command.kValue99,
      Command.kValue100,
      Command.kValue101,
      Command.kValue102,
      Command.kValue103,
      Command.kValue104,
      Command.kValue105,
      Command.kValue106,
      Command.kValue107,
      Command.kValue108,
      Command.kValue109,
      Command.kValue110,
      Command.kValue111,
      Command.kValue112,
      Command.kValue113,
      Command.kValue114,
      Command.kValue115,
      Command.kValue116,
      Command.kValue117,
      Command.kValue118,
      Command.kValue119,
      Command.kValue120,
      Command.kValue121,
      Command.kValue122,
      Command.kValue123,
      Command.kValue124,
      Command.kValue125,
      Command.kValue126,
      Command.kValue127,
      Command.kValue128,
      Command.kValue129,
      Command.kValue130,
      Command.kValue131,
      Command.kValue132,
      Command.kValue133,
      Command.kValue134,
      Command.kValue135,
      Command.kValue136,
      Command.kValue137,
      Command.kValue138,
      Command.kValue139,
      Command.kValue140,
      Command.kValue141,
      Command.kValue142,
      Command.kValue143,
      Command.kValue144,
      Command.kValue145,
      Command.kValue146,
      Command.kValue147,
      Command.kValue148,
      Command.kValue149,
      Command.kValue150,
      Command.kValue151,
      Command.kValue152,
      Command.kValue153,
      Command.kValue154,
      Command.kValue155,
      Command.kValue156,
      Command.kValue157,
      Command.kValue158,
      Command.kValue159,
      Command.kValue160,
      Command.kValue161,
      Command.kValue162,
      Command.kValue163,
      Command.kValue164,
      Command.kValue165,
      Command.kValue166,
      Command.kValue167,
      Command.kValue168,
      Command.kValue169,
      Command.kValue170,
      Command.kValue171,
      Command.kValue172,
      Command.kValue173,
      Command.kValue174,
      Command.kValue175,
      Command.kValue176,
      Command.kValue177,
      Command.kValue178,
      Command.kValue179,
      Command.kValue180,
      Command.kValue181,
      Command.kValue182,
      Command.kValue183,
      Command.kValue184,
      Command.kValue185,
      Command.kValue186,
      Command.kValue187,
      Command.kValue188,
      Command.kValue189,
      Command.kValue190,
      Command.kValue191,
      Command.kValue192,
      Command.kValue193,
      Command.kValue194,
      Command.kValue195,
      Command.kValue196,
      Command.kValue197,
      Command.kValue198,
      Command.kValue199,
      Command.kValue200
    ],
    rp.sendPort
  ]);
  await si.moveNext();
  Expect.equals(true, si.current);
  rp.close();
}
