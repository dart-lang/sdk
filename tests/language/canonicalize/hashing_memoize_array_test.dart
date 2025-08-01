// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// If canonicalization uses deep structural hashing without memoizing, this
// will exhibit superlinear time.

const list1_0 = <Object?>[null, null];
const list1_1 = <Object?>[list1_0, list1_0];
const list1_2 = <Object?>[list1_1, list1_1];
const list1_3 = <Object?>[list1_2, list1_2];
const list1_4 = <Object?>[list1_3, list1_3];
const list1_5 = <Object?>[list1_4, list1_4];
const list1_6 = <Object?>[list1_5, list1_5];
const list1_7 = <Object?>[list1_6, list1_6];
const list1_8 = <Object?>[list1_7, list1_7];
const list1_9 = <Object?>[list1_8, list1_8];
const list1_10 = <Object?>[list1_9, list1_9];
const list1_11 = <Object?>[list1_10, list1_10];
const list1_12 = <Object?>[list1_11, list1_11];
const list1_13 = <Object?>[list1_12, list1_12];
const list1_14 = <Object?>[list1_13, list1_13];
const list1_15 = <Object?>[list1_14, list1_14];
const list1_16 = <Object?>[list1_15, list1_15];
const list1_17 = <Object?>[list1_16, list1_16];
const list1_18 = <Object?>[list1_17, list1_17];
const list1_19 = <Object?>[list1_18, list1_18];
const list1_20 = <Object?>[list1_19, list1_19];
const list1_21 = <Object?>[list1_20, list1_20];
const list1_22 = <Object?>[list1_21, list1_21];
const list1_23 = <Object?>[list1_22, list1_22];
const list1_24 = <Object?>[list1_23, list1_23];
const list1_25 = <Object?>[list1_24, list1_24];
const list1_26 = <Object?>[list1_25, list1_25];
const list1_27 = <Object?>[list1_26, list1_26];
const list1_28 = <Object?>[list1_27, list1_27];
const list1_29 = <Object?>[list1_28, list1_28];
const list1_30 = <Object?>[list1_29, list1_29];
const list1_31 = <Object?>[list1_30, list1_30];
const list1_32 = <Object?>[list1_31, list1_31];
const list1_33 = <Object?>[list1_32, list1_32];
const list1_34 = <Object?>[list1_33, list1_33];
const list1_35 = <Object?>[list1_34, list1_34];
const list1_36 = <Object?>[list1_35, list1_35];
const list1_37 = <Object?>[list1_36, list1_36];
const list1_38 = <Object?>[list1_37, list1_37];
const list1_39 = <Object?>[list1_38, list1_38];
const list1_40 = <Object?>[list1_39, list1_39];
const list1_41 = <Object?>[list1_40, list1_40];
const list1_42 = <Object?>[list1_41, list1_41];
const list1_43 = <Object?>[list1_42, list1_42];
const list1_44 = <Object?>[list1_43, list1_43];
const list1_45 = <Object?>[list1_44, list1_44];
const list1_46 = <Object?>[list1_45, list1_45];
const list1_47 = <Object?>[list1_46, list1_46];
const list1_48 = <Object?>[list1_47, list1_47];
const list1_49 = <Object?>[list1_48, list1_48];
const list1_50 = <Object?>[list1_49, list1_49];
const list1_51 = <Object?>[list1_50, list1_50];
const list1_52 = <Object?>[list1_51, list1_51];
const list1_53 = <Object?>[list1_52, list1_52];
const list1_54 = <Object?>[list1_53, list1_53];
const list1_55 = <Object?>[list1_54, list1_54];
const list1_56 = <Object?>[list1_55, list1_55];
const list1_57 = <Object?>[list1_56, list1_56];
const list1_58 = <Object?>[list1_57, list1_57];
const list1_59 = <Object?>[list1_58, list1_58];
const list1_60 = <Object?>[list1_59, list1_59];
const list1_61 = <Object?>[list1_60, list1_60];
const list1_62 = <Object?>[list1_61, list1_61];
const list1_63 = <Object?>[list1_62, list1_62];
const list1_64 = <Object?>[list1_63, list1_63];
const list1_65 = <Object?>[list1_64, list1_64];
const list1_66 = <Object?>[list1_65, list1_65];
const list1_67 = <Object?>[list1_66, list1_66];
const list1_68 = <Object?>[list1_67, list1_67];
const list1_69 = <Object?>[list1_68, list1_68];
const list1_70 = <Object?>[list1_69, list1_69];
const list1_71 = <Object?>[list1_70, list1_70];
const list1_72 = <Object?>[list1_71, list1_71];
const list1_73 = <Object?>[list1_72, list1_72];
const list1_74 = <Object?>[list1_73, list1_73];
const list1_75 = <Object?>[list1_74, list1_74];
const list1_76 = <Object?>[list1_75, list1_75];
const list1_77 = <Object?>[list1_76, list1_76];
const list1_78 = <Object?>[list1_77, list1_77];
const list1_79 = <Object?>[list1_78, list1_78];
const list1_80 = <Object?>[list1_79, list1_79];
const list1_81 = <Object?>[list1_80, list1_80];
const list1_82 = <Object?>[list1_81, list1_81];
const list1_83 = <Object?>[list1_82, list1_82];
const list1_84 = <Object?>[list1_83, list1_83];
const list1_85 = <Object?>[list1_84, list1_84];
const list1_86 = <Object?>[list1_85, list1_85];
const list1_87 = <Object?>[list1_86, list1_86];
const list1_88 = <Object?>[list1_87, list1_87];
const list1_89 = <Object?>[list1_88, list1_88];
const list1_90 = <Object?>[list1_89, list1_89];
const list1_91 = <Object?>[list1_90, list1_90];
const list1_92 = <Object?>[list1_91, list1_91];
const list1_93 = <Object?>[list1_92, list1_92];
const list1_94 = <Object?>[list1_93, list1_93];
const list1_95 = <Object?>[list1_94, list1_94];
const list1_96 = <Object?>[list1_95, list1_95];
const list1_97 = <Object?>[list1_96, list1_96];
const list1_98 = <Object?>[list1_97, list1_97];
const list1_99 = <Object?>[list1_98, list1_98];

const list2_0 = <Object?>[null, null];
const list2_1 = <Object?>[list2_0, list2_0];
const list2_2 = <Object?>[list2_1, list2_1];
const list2_3 = <Object?>[list2_2, list2_2];
const list2_4 = <Object?>[list2_3, list2_3];
const list2_5 = <Object?>[list2_4, list2_4];
const list2_6 = <Object?>[list2_5, list2_5];
const list2_7 = <Object?>[list2_6, list2_6];
const list2_8 = <Object?>[list2_7, list2_7];
const list2_9 = <Object?>[list2_8, list2_8];
const list2_10 = <Object?>[list2_9, list2_9];
const list2_11 = <Object?>[list2_10, list2_10];
const list2_12 = <Object?>[list2_11, list2_11];
const list2_13 = <Object?>[list2_12, list2_12];
const list2_14 = <Object?>[list2_13, list2_13];
const list2_15 = <Object?>[list2_14, list2_14];
const list2_16 = <Object?>[list2_15, list2_15];
const list2_17 = <Object?>[list2_16, list2_16];
const list2_18 = <Object?>[list2_17, list2_17];
const list2_19 = <Object?>[list2_18, list2_18];
const list2_20 = <Object?>[list2_19, list2_19];
const list2_21 = <Object?>[list2_20, list2_20];
const list2_22 = <Object?>[list2_21, list2_21];
const list2_23 = <Object?>[list2_22, list2_22];
const list2_24 = <Object?>[list2_23, list2_23];
const list2_25 = <Object?>[list2_24, list2_24];
const list2_26 = <Object?>[list2_25, list2_25];
const list2_27 = <Object?>[list2_26, list2_26];
const list2_28 = <Object?>[list2_27, list2_27];
const list2_29 = <Object?>[list2_28, list2_28];
const list2_30 = <Object?>[list2_29, list2_29];
const list2_31 = <Object?>[list2_30, list2_30];
const list2_32 = <Object?>[list2_31, list2_31];
const list2_33 = <Object?>[list2_32, list2_32];
const list2_34 = <Object?>[list2_33, list2_33];
const list2_35 = <Object?>[list2_34, list2_34];
const list2_36 = <Object?>[list2_35, list2_35];
const list2_37 = <Object?>[list2_36, list2_36];
const list2_38 = <Object?>[list2_37, list2_37];
const list2_39 = <Object?>[list2_38, list2_38];
const list2_40 = <Object?>[list2_39, list2_39];
const list2_41 = <Object?>[list2_40, list2_40];
const list2_42 = <Object?>[list2_41, list2_41];
const list2_43 = <Object?>[list2_42, list2_42];
const list2_44 = <Object?>[list2_43, list2_43];
const list2_45 = <Object?>[list2_44, list2_44];
const list2_46 = <Object?>[list2_45, list2_45];
const list2_47 = <Object?>[list2_46, list2_46];
const list2_48 = <Object?>[list2_47, list2_47];
const list2_49 = <Object?>[list2_48, list2_48];
const list2_50 = <Object?>[list2_49, list2_49];
const list2_51 = <Object?>[list2_50, list2_50];
const list2_52 = <Object?>[list2_51, list2_51];
const list2_53 = <Object?>[list2_52, list2_52];
const list2_54 = <Object?>[list2_53, list2_53];
const list2_55 = <Object?>[list2_54, list2_54];
const list2_56 = <Object?>[list2_55, list2_55];
const list2_57 = <Object?>[list2_56, list2_56];
const list2_58 = <Object?>[list2_57, list2_57];
const list2_59 = <Object?>[list2_58, list2_58];
const list2_60 = <Object?>[list2_59, list2_59];
const list2_61 = <Object?>[list2_60, list2_60];
const list2_62 = <Object?>[list2_61, list2_61];
const list2_63 = <Object?>[list2_62, list2_62];
const list2_64 = <Object?>[list2_63, list2_63];
const list2_65 = <Object?>[list2_64, list2_64];
const list2_66 = <Object?>[list2_65, list2_65];
const list2_67 = <Object?>[list2_66, list2_66];
const list2_68 = <Object?>[list2_67, list2_67];
const list2_69 = <Object?>[list2_68, list2_68];
const list2_70 = <Object?>[list2_69, list2_69];
const list2_71 = <Object?>[list2_70, list2_70];
const list2_72 = <Object?>[list2_71, list2_71];
const list2_73 = <Object?>[list2_72, list2_72];
const list2_74 = <Object?>[list2_73, list2_73];
const list2_75 = <Object?>[list2_74, list2_74];
const list2_76 = <Object?>[list2_75, list2_75];
const list2_77 = <Object?>[list2_76, list2_76];
const list2_78 = <Object?>[list2_77, list2_77];
const list2_79 = <Object?>[list2_78, list2_78];
const list2_80 = <Object?>[list2_79, list2_79];
const list2_81 = <Object?>[list2_80, list2_80];
const list2_82 = <Object?>[list2_81, list2_81];
const list2_83 = <Object?>[list2_82, list2_82];
const list2_84 = <Object?>[list2_83, list2_83];
const list2_85 = <Object?>[list2_84, list2_84];
const list2_86 = <Object?>[list2_85, list2_85];
const list2_87 = <Object?>[list2_86, list2_86];
const list2_88 = <Object?>[list2_87, list2_87];
const list2_89 = <Object?>[list2_88, list2_88];
const list2_90 = <Object?>[list2_89, list2_89];
const list2_91 = <Object?>[list2_90, list2_90];
const list2_92 = <Object?>[list2_91, list2_91];
const list2_93 = <Object?>[list2_92, list2_92];
const list2_94 = <Object?>[list2_93, list2_93];
const list2_95 = <Object?>[list2_94, list2_94];
const list2_96 = <Object?>[list2_95, list2_95];
const list2_97 = <Object?>[list2_96, list2_96];
const list2_98 = <Object?>[list2_97, list2_97];
const list2_99 = <Object?>[list2_98, list2_98];

@pragma("vm:never-inline")
@pragma("vm:entry-point")
@pragma("dart2js:noInline")
confuse(x) {
  try {
    throw x;
  } catch (e) {
    return e;
  }
}

main() {
  if (!identical(confuse(list1_99), confuse(list2_99))) {
    throw new Exception("list1_99 !== list2_99");
  }
}
