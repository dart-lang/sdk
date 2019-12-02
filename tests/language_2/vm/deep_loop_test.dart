// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Stress tests on loop nesting depth. Make sure loop and induction
// analysis do not break down (excessive compile-time or otherwise)
// when analyzing a deeply nested loop with dependent bounds.

@pragma("vm:never-inline")
foo(List<int> a) {
  for (int i0 = 100; i0 <= a.length - 101; i0++)
    for (int i1 = i0 - 1; i1 <= i0 + 1; i1++)
      for (int i2 = i1 - 1; i2 <= i1 + 1; i2++)
        for (int i3 = i2 - 1; i3 <= i2 + 1; i3++)
          for (int i4 = i3 - 1; i4 <= i3 + 1; i4++)
            for (int i5 = i4 - 1; i5 <= i4 + 1; i5++)
              for (int i6 = i5 - 1; i6 <= i5 + 1; i6++)
                for (int i7 = i6 - 1; i7 <= i6 + 1; i7++)
                  for (int i8 = i7 - 1; i8 <= i7 + 1; i8++)
                    for (int i9 = i8 - 1; i9 <= i8 + 1; i9++)
                      for (int i10 = i9 - 1; i10 <= i9 + 1; i10++)
                        for (int i11 = i10 - 1; i11 <= i10 + 1; i11++)
                          for (int i12 = i11 - 1; i12 <= i11 + 1; i12++)
                            for (int i13 = i12 - 1; i13 <= i12 + 1; i13++)
                              for (int i14 = i13 - 1; i14 <= i13 + 1; i14++)
                                for (int i15 = i14 - 1; i15 <= i14 + 1; i15++)
                                  for (int i16 = i15 - 1; i16 <= i15 + 1; i16++)
                                    for (int i17 = i16 - 1;
                                        i17 <= i16 + 1;
                                        i17++)
                                      for (int i18 = i17 - 1;
                                          i18 <= i17 + 1;
                                          i18++)
                                        for (int i19 = i18 - 1;
                                            i19 <= i18 + 1;
                                            i19++)
                                          for (int i20 = i19 - 1;
                                              i20 <= i19 + 1;
                                              i20++)
                                            for (int i21 = i20 - 1;
                                                i21 <= i20 + 1;
                                                i21++)
                                              for (int i22 = i21 - 1;
                                                  i22 <= i21 + 1;
                                                  i22++)
                                                for (int i23 = i22 - 1;
                                                    i23 <= i22 + 1;
                                                    i23++)
                                                  for (int i24 = i23 - 1;
                                                      i24 <= i23 + 1;
                                                      i24++)
                                                    for (int i25 = i24 - 1;
                                                        i25 <= i24 + 1;
                                                        i25++)
                                                      for (int i26 = i25 - 1;
                                                          i26 <= i25 + 1;
                                                          i26++)
                                                        for (int i27 = i26 - 1;
                                                            i27 <= i26 + 1;
                                                            i27++)
                                                          for (int i28 =
                                                                  i27 - 1;
                                                              i28 <= i27 + 1;
                                                              i28++)
                                                            for (int i29 =
                                                                    i28 - 1;
                                                                i29 <= i28 + 1;
                                                                i29++)
                                                              for (int i30 =
                                                                      i29 - 1;
                                                                  i30 <=
                                                                      i29 + 1;
                                                                  i30++)
                                                                for (int i31 =
                                                                        i30 - 1;
                                                                    i31 <=
                                                                        i30 + 1;
                                                                    i31++)
                                                                  for (int i32 =
                                                                          i31 -
                                                                              1;
                                                                      i32 <=
                                                                          i31 +
                                                                              1;
                                                                      i32++)
                                                                    for (int i33 =
                                                                            i32 -
                                                                                1;
                                                                        i33 <=
                                                                            i32 +
                                                                                1;
                                                                        i33++)
                                                                      for (int i34 = i33 -
                                                                              1;
                                                                          i34 <=
                                                                              i33 + 1;
                                                                          i34++)
                                                                        for (int i35 = i34 -
                                                                                1;
                                                                            i35 <=
                                                                                i34 + 1;
                                                                            i35++)
                                                                          for (int i36 = i35 - 1;
                                                                              i36 <= i35 + 1;
                                                                              i36++)
                                                                            for (int i37 = i36 - 1;
                                                                                i37 <= i36 + 1;
                                                                                i37++)
                                                                              for (int i38 = i37 - 1; i38 <= i37 + 1; i38++)
                                                                                for (int i39 = i38 - 1; i39 <= i38 + 1; i39++)
                                                                                  for (int i40 = i39 - 1; i40 <= i39 + 1; i40++)
                                                                                    for (int i41 = i40 - 1; i41 <= i40 + 1; i41++)
                                                                                      for (int i42 = i41 - 1; i42 <= i41 + 1; i42++)
                                                                                        for (int i43 = i42 - 1; i43 <= i42 + 1; i43++)
                                                                                          for (int i44 = i43 - 1; i44 <= i43 + 1; i44++)
                                                                                            for (int i45 = i44 - 1; i45 <= i44 + 1; i45++)
                                                                                              for (int i46 = i45 - 1; i46 <= i45 + 1; i46++)
                                                                                                for (int i47 = i46 - 1; i47 <= i46 + 1; i47++)
                                                                                                  for (int i48 = i47 - 1; i48 <= i47 + 1; i48++)
                                                                                                    for (int i49 = i48 - 1; i49 <= i48 + 1; i49++)
                                                                                                      for (int i50 = i49 - 1; i50 <= i49 + 1; i50++)
                                                                                                        for (int i51 = i50 - 1; i51 <= i50 + 1; i51++)
                                                                                                          for (int i52 = i51 - 1; i52 <= i51 + 1; i52++)
                                                                                                            for (int i53 = i52 - 1; i53 <= i52 + 1; i53++)
                                                                                                              for (int i54 = i53 - 1; i54 <= i53 + 1; i54++)
                                                                                                                for (int i55 = i54 - 1; i55 <= i54 + 1; i55++)
                                                                                                                  for (int i56 = i55 - 1; i56 <= i55 + 1; i56++)
                                                                                                                    for (int i57 = i56 - 1; i57 <= i56 + 1; i57++)
                                                                                                                      for (int i58 = i57 - 1; i58 <= i57 + 1; i58++)
                                                                                                                        for (int i59 = i58 - 1; i59 <= i58 + 1; i59++)
                                                                                                                          for (int i60 = i59 - 1; i60 <= i59 + 1; i60++)
                                                                                                                            for (int i61 = i60 - 1; i61 <= i60 + 1; i61++)
                                                                                                                              for (int i62 = i61 - 1; i62 <= i61 + 1; i62++)
                                                                                                                                for (int i63 = i62 - 1; i63 <= i62 + 1; i63++)
                                                                                                                                  for (int i64 = i63 - 1; i64 <= i63 + 1; i64++)
                                                                                                                                    for (int i65 = i64 - 1; i65 <= i64 + 1; i65++)
                                                                                                                                      for (int i66 = i65 - 1; i66 <= i65 + 1; i66++)
                                                                                                                                        for (int i67 = i66 - 1; i67 <= i66 + 1; i67++)
                                                                                                                                          for (int i68 = i67 - 1; i68 <= i67 + 1; i68++)
                                                                                                                                            for (int i69 = i68 - 1; i69 <= i68 + 1; i69++)
                                                                                                                                              for (int i70 = i69 - 1; i70 <= i69 + 1; i70++)
                                                                                                                                                for (int i71 = i70 - 1; i71 <= i70 + 1; i71++)
                                                                                                                                                  for (int i72 = i71 - 1; i72 <= i71 + 1; i72++)
                                                                                                                                                    for (int i73 = i72 - 1; i73 <= i72 + 1; i73++)
                                                                                                                                                      for (int i74 = i73 - 1; i74 <= i73 + 1; i74++)
                                                                                                                                                        for (int i75 = i74 - 1; i75 <= i74 + 1; i75++)
                                                                                                                                                          for (int i76 = i75 - 1; i76 <= i75 + 1; i76++)
                                                                                                                                                            for (int i77 = i76 - 1; i77 <= i76 + 1; i77++)
                                                                                                                                                              for (int i78 = i77 - 1; i78 <= i77 + 1; i78++)
                                                                                                                                                                for (int i79 = i78 - 1; i79 <= i78 + 1; i79++)
                                                                                                                                                                  for (int i80 = i79 - 1; i80 <= i79 + 1; i80++)
                                                                                                                                                                    for (int i81 = i80 - 1; i81 <= i80 + 1; i81++)
                                                                                                                                                                      for (int i82 = i81 - 1; i82 <= i81 + 1; i82++)
                                                                                                                                                                        for (int i83 = i82 - 1; i83 <= i82 + 1; i83++)
                                                                                                                                                                          for (int i84 = i83 - 1; i84 <= i83 + 1; i84++)
                                                                                                                                                                            for (int i85 = i84 - 1; i85 <= i84 + 1; i85++)
                                                                                                                                                                              for (int i86 = i85 - 1; i86 <= i85 + 1; i86++)
                                                                                                                                                                                for (int i87 = i86 - 1; i87 <= i86 + 1; i87++)
                                                                                                                                                                                  for (int i88 = i87 - 1; i88 <= i87 + 1; i88++)
                                                                                                                                                                                    for (int i89 = i88 - 1; i89 <= i88 + 1; i89++)
                                                                                                                                                                                      for (int i90 = i89 - 1; i90 <= i89 + 1; i90++)
                                                                                                                                                                                        for (int i91 = i90 - 1; i91 <= i90 + 1; i91++)
                                                                                                                                                                                          for (int i92 = i91 - 1; i92 <= i91 + 1; i92++)
                                                                                                                                                                                            for (int i93 = i92 - 1; i93 <= i92 + 1; i93++)
                                                                                                                                                                                              for (int i94 = i93 - 1; i94 <= i93 + 1; i94++)
                                                                                                                                                                                                for (int i95 = i94 - 1; i95 <= i94 + 1; i95++)
                                                                                                                                                                                                  for (int i96 = i95 - 1; i96 <= i95 + 1; i96++)
                                                                                                                                                                                                    for (int i97 = i96 - 1; i97 <= i96 + 1; i97++)
                                                                                                                                                                                                      for (int i98 = i97 - 1; i98 <= i97 + 1; i98++)
                                                                                                                                                                                                        for (int i99 = i98 - 1; i99 <= i98 + 1; i99++)
                                                                                                                                                                                                          for (int i100 = i99 - 1; i100 <= i99 + 1; i100++) {
                                                                                                                                                                                                            // Range [0,a.length).
                                                                                                                                                                                                            a[i100] += 1;
                                                                                                                                                                                                          }
}

@pragma("vm:never-inline")
bar(List<int> a) {
  for (int i0 = a.length - 101; i0 >= 100; i0--)
    for (int i1 = i0 + 1; i1 >= i0 - 1; i1--)
      for (int i2 = i1 + 1; i2 >= i1 - 1; i2--)
        for (int i3 = i2 + 1; i3 >= i2 - 1; i3--)
          for (int i4 = i3 + 1; i4 >= i3 - 1; i4--)
            for (int i5 = i4 + 1; i5 >= i4 - 1; i5--)
              for (int i6 = i5 + 1; i6 >= i5 - 1; i6--)
                for (int i7 = i6 + 1; i7 >= i6 - 1; i7--)
                  for (int i8 = i7 + 1; i8 >= i7 - 1; i8--)
                    for (int i9 = i8 + 1; i9 >= i8 - 1; i9--)
                      for (int i10 = i9 + 1; i10 >= i9 - 1; i10--)
                        for (int i11 = i10 + 1; i11 >= i10 - 1; i11--)
                          for (int i12 = i11 + 1; i12 >= i11 - 1; i12--)
                            for (int i13 = i12 + 1; i13 >= i12 - 1; i13--)
                              for (int i14 = i13 + 1; i14 >= i13 - 1; i14--)
                                for (int i15 = i14 + 1; i15 >= i14 - 1; i15--)
                                  for (int i16 = i15 + 1; i16 >= i15 - 1; i16--)
                                    for (int i17 = i16 + 1;
                                        i17 >= i16 - 1;
                                        i17--)
                                      for (int i18 = i17 + 1;
                                          i18 >= i17 - 1;
                                          i18--)
                                        for (int i19 = i18 + 1;
                                            i19 >= i18 - 1;
                                            i19--)
                                          for (int i20 = i19 + 1;
                                              i20 >= i19 - 1;
                                              i20--)
                                            for (int i21 = i20 + 1;
                                                i21 >= i20 - 1;
                                                i21--)
                                              for (int i22 = i21 + 1;
                                                  i22 >= i21 - 1;
                                                  i22--)
                                                for (int i23 = i22 + 1;
                                                    i23 >= i22 - 1;
                                                    i23--)
                                                  for (int i24 = i23 + 1;
                                                      i24 >= i23 - 1;
                                                      i24--)
                                                    for (int i25 = i24 + 1;
                                                        i25 >= i24 - 1;
                                                        i25--)
                                                      for (int i26 = i25 + 1;
                                                          i26 >= i25 - 1;
                                                          i26--)
                                                        for (int i27 = i26 + 1;
                                                            i27 >= i26 - 1;
                                                            i27--)
                                                          for (int i28 =
                                                                  i27 + 1;
                                                              i28 >= i27 - 1;
                                                              i28--)
                                                            for (int i29 =
                                                                    i28 + 1;
                                                                i29 >= i28 - 1;
                                                                i29--)
                                                              for (int i30 =
                                                                      i29 + 1;
                                                                  i30 >=
                                                                      i29 - 1;
                                                                  i30--)
                                                                for (int i31 =
                                                                        i30 + 1;
                                                                    i31 >=
                                                                        i30 - 1;
                                                                    i31--)
                                                                  for (int i32 =
                                                                          i31 +
                                                                              1;
                                                                      i32 >=
                                                                          i31 -
                                                                              1;
                                                                      i32--)
                                                                    for (int i33 =
                                                                            i32 +
                                                                                1;
                                                                        i33 >=
                                                                            i32 -
                                                                                1;
                                                                        i33--)
                                                                      for (int i34 = i33 +
                                                                              1;
                                                                          i34 >=
                                                                              i33 - 1;
                                                                          i34--)
                                                                        for (int i35 = i34 +
                                                                                1;
                                                                            i35 >=
                                                                                i34 - 1;
                                                                            i35--)
                                                                          for (int i36 = i35 + 1;
                                                                              i36 >= i35 - 1;
                                                                              i36--)
                                                                            for (int i37 = i36 + 1;
                                                                                i37 >= i36 - 1;
                                                                                i37--)
                                                                              for (int i38 = i37 + 1; i38 >= i37 - 1; i38--)
                                                                                for (int i39 = i38 + 1; i39 >= i38 - 1; i39--)
                                                                                  for (int i40 = i39 + 1; i40 >= i39 - 1; i40--)
                                                                                    for (int i41 = i40 + 1; i41 >= i40 - 1; i41--)
                                                                                      for (int i42 = i41 + 1; i42 >= i41 - 1; i42--)
                                                                                        for (int i43 = i42 + 1; i43 >= i42 - 1; i43--)
                                                                                          for (int i44 = i43 + 1; i44 >= i43 - 1; i44--)
                                                                                            for (int i45 = i44 + 1; i45 >= i44 - 1; i45--)
                                                                                              for (int i46 = i45 + 1; i46 >= i45 - 1; i46--)
                                                                                                for (int i47 = i46 + 1; i47 >= i46 - 1; i47--)
                                                                                                  for (int i48 = i47 + 1; i48 >= i47 - 1; i48--)
                                                                                                    for (int i49 = i48 + 1; i49 >= i48 - 1; i49--)
                                                                                                      for (int i50 = i49 + 1; i50 >= i49 - 1; i50--)
                                                                                                        for (int i51 = i50 + 1; i51 >= i50 - 1; i51--)
                                                                                                          for (int i52 = i51 + 1; i52 >= i51 - 1; i52--)
                                                                                                            for (int i53 = i52 + 1; i53 >= i52 - 1; i53--)
                                                                                                              for (int i54 = i53 + 1; i54 >= i53 - 1; i54--)
                                                                                                                for (int i55 = i54 + 1; i55 >= i54 - 1; i55--)
                                                                                                                  for (int i56 = i55 + 1; i56 >= i55 - 1; i56--)
                                                                                                                    for (int i57 = i56 + 1; i57 >= i56 - 1; i57--)
                                                                                                                      for (int i58 = i57 + 1; i58 >= i57 - 1; i58--)
                                                                                                                        for (int i59 = i58 + 1; i59 >= i58 - 1; i59--)
                                                                                                                          for (int i60 = i59 + 1; i60 >= i59 - 1; i60--)
                                                                                                                            for (int i61 = i60 + 1; i61 >= i60 - 1; i61--)
                                                                                                                              for (int i62 = i61 + 1; i62 >= i61 - 1; i62--)
                                                                                                                                for (int i63 = i62 + 1; i63 >= i62 - 1; i63--)
                                                                                                                                  for (int i64 = i63 + 1; i64 >= i63 - 1; i64--)
                                                                                                                                    for (int i65 = i64 + 1; i65 >= i64 - 1; i65--)
                                                                                                                                      for (int i66 = i65 + 1; i66 >= i65 - 1; i66--)
                                                                                                                                        for (int i67 = i66 + 1; i67 >= i66 - 1; i67--)
                                                                                                                                          for (int i68 = i67 + 1; i68 >= i67 - 1; i68--)
                                                                                                                                            for (int i69 = i68 + 1; i69 >= i68 - 1; i69--)
                                                                                                                                              for (int i70 = i69 + 1; i70 >= i69 - 1; i70--)
                                                                                                                                                for (int i71 = i70 + 1; i71 >= i70 - 1; i71--)
                                                                                                                                                  for (int i72 = i71 + 1; i72 >= i71 - 1; i72--)
                                                                                                                                                    for (int i73 = i72 + 1; i73 >= i72 - 1; i73--)
                                                                                                                                                      for (int i74 = i73 + 1; i74 >= i73 - 1; i74--)
                                                                                                                                                        for (int i75 = i74 + 1; i75 >= i74 - 1; i75--)
                                                                                                                                                          for (int i76 = i75 + 1; i76 >= i75 - 1; i76--)
                                                                                                                                                            for (int i77 = i76 + 1; i77 >= i76 - 1; i77--)
                                                                                                                                                              for (int i78 = i77 + 1; i78 >= i77 - 1; i78--)
                                                                                                                                                                for (int i79 = i78 + 1; i79 >= i78 - 1; i79--)
                                                                                                                                                                  for (int i80 = i79 + 1; i80 >= i79 - 1; i80--)
                                                                                                                                                                    for (int i81 = i80 + 1; i81 >= i80 - 1; i81--)
                                                                                                                                                                      for (int i82 = i81 + 1; i82 >= i81 - 1; i82--)
                                                                                                                                                                        for (int i83 = i82 + 1; i83 >= i82 - 1; i83--)
                                                                                                                                                                          for (int i84 = i83 + 1; i84 >= i83 - 1; i84--)
                                                                                                                                                                            for (int i85 = i84 + 1; i85 >= i84 - 1; i85--)
                                                                                                                                                                              for (int i86 = i85 + 1; i86 >= i85 - 1; i86--)
                                                                                                                                                                                for (int i87 = i86 + 1; i87 >= i86 - 1; i87--)
                                                                                                                                                                                  for (int i88 = i87 + 1; i88 >= i87 - 1; i88--)
                                                                                                                                                                                    for (int i89 = i88 + 1; i89 >= i88 - 1; i89--)
                                                                                                                                                                                      for (int i90 = i89 + 1; i90 >= i89 - 1; i90--)
                                                                                                                                                                                        for (int i91 = i90 + 1; i91 >= i90 - 1; i91--)
                                                                                                                                                                                          for (int i92 = i91 + 1; i92 >= i91 - 1; i92--)
                                                                                                                                                                                            for (int i93 = i92 + 1; i93 >= i92 - 1; i93--)
                                                                                                                                                                                              for (int i94 = i93 + 1; i94 >= i93 - 1; i94--)
                                                                                                                                                                                                for (int i95 = i94 + 1; i95 >= i94 - 1; i95--)
                                                                                                                                                                                                  for (int i96 = i95 + 1; i96 >= i95 - 1; i96--)
                                                                                                                                                                                                    for (int i97 = i96 + 1; i97 >= i96 - 1; i97--)
                                                                                                                                                                                                      for (int i98 = i97 + 1; i98 >= i97 - 1; i98--)
                                                                                                                                                                                                        for (int i99 = i98 + 1; i99 >= i98 - 1; i99--)
                                                                                                                                                                                                          for (int i100 = i99 + 1; i100 >= i99 - 1; i100--) {
                                                                                                                                                                                                            // Range [0,a.length).
                                                                                                                                                                                                            a[i100] += 1;
                                                                                                                                                                                                          }
}

main() {
  // To avoid executing the deep loops completely, we pass in a list
  // with null values, so that each first iteration throws an exception.
  List<int> a = new List<int>(300);
  int tryCallingPlusOnNull = 0;
  try {
    foo(a);
  } on NoSuchMethodError catch (e) {
    ++tryCallingPlusOnNull;
  }
  try {
    bar(a);
  } on NoSuchMethodError catch (e) {
    ++tryCallingPlusOnNull;
  }
  Expect.equals(2, tryCallingPlusOnNull);
}
