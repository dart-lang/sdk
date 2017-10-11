// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.

// Convenience values.
var c = new C();
var x = 42;
var y = 42;
var z = 42;

// Trailing comma in parameter litss.

// Typedefs.
typedef fx(x, ); //                                     //# none: ok
typedef fy([y,]); //                                    //# none: continued
typedef fxy(x, [y, ]); //                               //# none: continued
typedef fz({z,}); //                                    //# none: continued
typedef fxz(x, {z, }); //                               //# none: continued

// As arguments type.
argfx(void f(x, )) {} //                                //# none: continued
argfy(void f([y, ])) {} //                              //# none: continued
argfxy(void f(x, [y, ])) {} //                          //# none: continued
argfz(void f({z, })) {} //                              //# none: continued
argfxz(void f(x, {z, })) {} //                          //# none: continued

// Top level functions
void topx(x,) {} //                                     //# none: continued
void topy([y, ]) {} //                                  //# none: continued
void topxy(x, [y, ]) {} //                              //# none: continued
void topz({z, }) {} //                                  //# none: continued
void topxz(x, {z, }) {} //                              //# none: continued

void set topsetx(x, ) {} //                             //# none: continued

// After specific parameter formats.
void afterDefaultValueY([int y = 42, ]) {} //           //# none: continued
void afterDefaultValueZ({int z : 42, }) {} //           //# none: continued
void afterFunsigX(void f(),) {} //                      //# none: continued
void afterFunsigY([void f(),]) {} //                    //# none: continued
void afterFunsigZ({void f(),}) {} //                    //# none: continued
void afterFunsigDefaultValueY([void f() = topy,]) {} // //# none: continued
void afterFunsigDefaultValueZ({void f() : topz,}) {} // //# none: continued

class C {
  C();

  // Constructors.
  C.x(x, ); //                                          //# none: continued
  C.y([y, ]); //                                        //# none: continued
  C.xy(x, [y, ]); //                                    //# none: continued
  C.z({z, }); //                                        //# none: continued
  C.xz(x, {z, }); //                                    //# none: continued

  // Static members
  static void staticx(x,) {} //                         //# none: continued
  static void staticy([y, ]) {} //                      //# none: continued
  static void staticxy(x, [y, ]) {} //                  //# none: continued
  static void staticz({z, }) {} //                      //# none: continued
  static void staticxz(x, {z, }) {} //                  //# none: continued

  static void set staticsetx(x, ) {} //                 //# none: continued

  // Instance members
  void instancex(x,) {} //                              //# none: continued
  void instancey([y, ]) {} //                           //# none: continued
  void instancexy(x, [y, ]) {} //                       //# none: continued
  void instancez({z, }) {} //                           //# none: continued
  void instancexz(x, {z, }) {} //                       //# none: continued

  void set instancesetx(x, ) {} //                      //# none: continued

  operator +(x, ) => this; //                           //# none: continued
  operator []=(x, y, ) {} //                            //# none: continued
}

main() {
  testCalls(); //                                       //# none: continued
  // Make sure the cases are checked.
  testBadCalls();
}

void testCalls() {
  // Check that all functions can be called normally
  topx(x); //                                           //# none: continued
  topy(y); //                                           //# none: continued
  topxy(x, y); //                                       //# none: continued
  topz(); //                                            //# none: continued
  topz(z: z); //                                        //# none: continued
  topxz(x); //                                          //# none: continued
  topxz(x, z: z); //                                    //# none: continued
  topsetx = x; //                                       //# none: continued
  afterDefaultValueY(); //                              //# none: continued
  afterDefaultValueY(y); //                             //# none: continued
  afterDefaultValueZ(); //                              //# none: continued
  afterDefaultValueZ(z: z); //                          //# none: continued
  new C.x(x); //                                        //# none: continued
  new C.xy(x); //                                       //# none: continued
  new C.xy(x, y); //                                    //# none: continued
  new C.y(y); //                                        //# none: continued
  new C.xz(x); //                                       //# none: continued
  new C.xz(x, z: z); //                                 //# none: continued
  new C.z(z: z); //                                     //# none: continued
  C.staticx(x); //                                      //# none: continued
  C.staticy(y); //                                      //# none: continued
  C.staticxy(x); //                                     //# none: continued
  C.staticxy(x, y); //                                  //# none: continued
  C.staticz(); //                                       //# none: continued
  C.staticz(z: z); //                                   //# none: continued
  C.staticxz(x); //                                     //# none: continued
  C.staticxz(x, z: z); //                               //# none: continued
  C.staticsetx = x; //                                  //# none: continued
  c.instancex(x); //                                    //# none: continued
  c.instancey(); //                                     //# none: continued
  c.instancey(y); //                                    //# none: continued
  c.instancexy(x); //                                   //# none: continued
  c.instancexy(x, y); //                                //# none: continued
  c.instancez(); //                                     //# none: continued
  c.instancez(z: z); //                                 //# none: continued
  c.instancexz(x); //                                   //# none: continued
  c.instancexz(x, z: z); //                             //# none: continued
  c.instancesetx = x; //                                //# none: continued
  c + x; //                                             //# none: continued
  c[x] = y; //                                          //# none: continued

  // Call with extra comma (not possible for setters and operators).
  topx(x, ); //                                         //# none: continued
  topy(y, ); //                                         //# none: continued
  topxy(x, y, ); //                                     //# none: continued
  topxy(x, ); //                                        //# none: continued
  topz(z: z, ); //                                      //# none: continued
  topxz(x, ); //                                        //# none: continued
  topxz(x, z: z, ); //                                  //# none: continued
  new C.x(x, ); //                                      //# none: continued
  new C.xy(x, y, ); //                                  //# none: continued
  new C.xy(x, ); //                                     //# none: continued
  new C.y(y, ); //                                      //# none: continued
  new C.xz(x, ); //                                     //# none: continued
  new C.xz(x, z: z, ); //                               //# none: continued
  new C.z(z: z, ); //                                   //# none: continued
  C.staticx(x, ); //                                    //# none: continued
  C.staticy(y, ); //                                    //# none: continued
  C.staticxy(x, y, ); //                                //# none: continued
  C.staticxy(x, ); //                                   //# none: continued
  C.staticz(z: z, ); //                                 //# none: continued
  C.staticxz(x, ); //                                   //# none: continued
  C.staticxz(x, z: z, ); //                             //# none: continued
  c.instancex(x, ); //                                  //# none: continued
  c.instancey(y, ); //                                  //# none: continued
  c.instancexy(x, y, ); //                              //# none: continued
  c.instancexy(x, ); //                                 //# none: continued
  c.instancez(z: z, ); //                               //# none: continued
  c.instancexz(x, ); //                                 //# none: continued
  c.instancexz(x, z: z, ); //                           //# none: continued

  // Typedefs work as expected.
  if (topx is! fx) throw "Bad type: $fx"; //            //# none: continued
  if (topy is! fy) throw "Bad type: $fy"; //            //# none: continued
  if (topxy is! fxy) throw "Bad type: $fxy"; //         //# none: continued
  if (topz is! fz) throw "Bad type: $fz"; //            //# none: continued
  if (topxz is! fxz) throw "Bad type: $fxz"; //         //# none: continued

  // Parameter types work (checked mode only test).
  argfx(topx); //                                       //# none: continued
  argfy(topy); //                                       //# none: continued
  argfxy(topxy); //                                     //# none: continued
  argfz(topz); //                                       //# none: continued
  argfxz(topxz); //                                     //# none: continued
}

// Invalid syntax. This was invalid syntax before the addition of trailing
// commas too, and should stay that way.
void topBadEmpty(,) {} //                          //# 1: compile-time error
void topBadStart(, a) {} //                        //# 2: compile-time error
void topBadEnd(a,,) {} //                          //# 3: compile-time error
void topBadMiddle(a,, b) {} //                     //# 4: compile-time error
void topBadPosEmpty([]) {} //                      //# 5: compile-time error
void topBadPosEmpty(,[]) {} //                     //# 6: compile-time error
void topBadPosEmpty([,]) {} //                     //# 7: compile-time error
void topBadPosEmpty([],) {} //                     //# 8: compile-time error
void topBadPosStart(,[a]) {} //                    //# 9: compile-time error
void topBadPosStart([, a]) {} //                   //# 10: compile-time error
void topBadPosEnd([a,,]) {} //                     //# 11: compile-time error
void topBadPosStart([a],) {} //                    //# 12: compile-time error
void topBadPosMiddle([a,, b]) {} //                //# 13: compile-time error
void topBadNamEmpty({}) {} //                      //# 14: compile-time error
void topBadNamEmpty(,{}) {} //                     //# 15: compile-time error
void topBadNamEmpty({,}) {} //                     //# 16: compile-time error
void topBadNamEmpty({},) {} //                     //# 17: compile-time error
void topBadNamStart(,{a}) {} //                    //# 18: compile-time error
void topBadNamStart({, a}) {} //                   //# 19: compile-time error
void topBadNamEnd({a,,}) {} //                     //# 20: compile-time error
void topBadNamStart({a},) {} //                    //# 21: compile-time error
void topBadNamMiddle({a,, b}) {} //                //# 22: compile-time error
void set topSetBadEmpty(,) {} //                   //# 23: compile-time error
void set topSetBadStart(, a) {} //                 //# 24: compile-time error
void set topSetBadEnd(a,,) {} //                   //# 25: compile-time error
void set topSetBadMiddle(a,, b) {} //              //# 26: compile-time error
class Bad {
  Bad() {}
  Bad.empty(,) {} //                               //# 27: compile-time error
  Bad.start(, a) {} //                             //# 28: compile-time error
  Bad.end(a,,) {} //                               //# 29: compile-time error
  Bad.middle(a,, b) {} //                          //# 30: compile-time error
  Bad.posEmpty([]) {} //                           //# 31: compile-time error
  Bad.posEmpty(,[]) {} //                          //# 32: compile-time error
  Bad.posEmpty([,]) {} //                          //# 33: compile-time error
  Bad.posEmpty([],) {} //                          //# 34: compile-time error
  Bad.posStart(,[a]) {} //                         //# 35: compile-time error
  Bad.posStart([, a]) {} //                        //# 36: compile-time error
  Bad.posEnd([a,,]) {} //                          //# 37: compile-time error
  Bad.posStart([a],) {} //                         //# 38: compile-time error
  Bad.PosMiddle([a,, b]) {} //                     //# 39: compile-time error
  Bad.namEmpty({}) {} //                           //# 40: compile-time error
  Bad.namEmpty(,{}) {} //                          //# 41: compile-time error
  Bad.namEmpty({,}) {} //                          //# 42: compile-time error
  Bad.namEmpty({},) {} //                          //# 43: compile-time error
  Bad.namStart(,{a}) {} //                         //# 44: compile-time error
  Bad.namStart({, a}) {} //                        //# 45: compile-time error
  Bad.namEnd({a,,}) {} //                          //# 46: compile-time error
  Bad.namStart({a},) {} //                         //# 47: compile-time error
  Bad.namMiddle({a,, b}) {} //                     //# 48: compile-time error
  static void staticBadEmpty(,) {} //              //# 49: compile-time error
  static void staticBadStart(, a) {} //            //# 50: compile-time error
  static void staticBadEnd(a,,) {} //              //# 51: compile-time error
  static void staticBadMiddle(a,, b) {} //         //# 52: compile-time error
  static void staticBadPosEmpty([]) {} //          //# 53: compile-time error
  static void staticBadPosEmpty(,[]) {} //         //# 54: compile-time error
  static void staticBadPosEmpty([,]) {} //         //# 55: compile-time error
  static void staticBadPosEmpty([],) {} //         //# 56: compile-time error
  static void staticBadPosStart(,[a]) {} //        //# 57: compile-time error
  static void staticBadPosStart([, a]) {} //       //# 58: compile-time error
  static void staticBadPosEnd([a,,]) {} //         //# 59: compile-time error
  static void staticBadPosStart([a],) {} //        //# 60: compile-time error
  static void staticBadPosMiddle([a,, b]) {} //    //# 61: compile-time error
  static void staticBadNamEmpty({}) {} //          //# 62: compile-time error
  static void staticBadNamEmpty(,{}) {} //         //# 63: compile-time error
  static void staticBadNamEmpty({,}) {} //         //# 64: compile-time error
  static void staticBadNamEmpty({},) {} //         //# 65: compile-time error
  static void staticBadNamStart(,{a}) {} //        //# 66: compile-time error
  static void staticBadNamStart({, a}) {} //       //# 67: compile-time error
  static void staticBadNamEnd({a,,}) {} //         //# 68: compile-time error
  static void staticBadNamStart({a},) {} //        //# 69: compile-time error
  static void staticBadNamMiddle({a,, b}) {} //    //# 70: compile-time error
  static void set staticSetBadEmpty(,) {} //       //# 71: compile-time error
  static void set staticSetBadStart(, a) {} //     //# 72: compile-time error
  static void set staticSetBadEnd(a,,) {} //       //# 73: compile-time error
  static void set staticSetBadMiddle(a,, b) {} //  //# 74: compile-time error
  void instanceBadEmpty(,) {} //                   //# 75: compile-time error
  void instanceBadStart(, a) {} //                 //# 76: compile-time error
  void instanceBadEnd(a,,) {} //                   //# 77: compile-time error
  void instanceBadMiddle(a,, b) {} //              //# 78: compile-time error
  void instanceBadPosEmpty([]) {} //               //# 79: compile-time error
  void instanceBadPosEmpty(,[]) {} //              //# 80: compile-time error
  void instanceBadPosEmpty([,]) {} //              //# 81: compile-time error
  void instanceBadPosEmpty([],) {} //              //# 82: compile-time error
  void instanceBadPosStart(,[a]) {} //             //# 83: compile-time error
  void instanceBadPosStart([, a]) {} //            //# 84: compile-time error
  void instanceBadPosEnd([a,,]) {} //              //# 85: compile-time error
  void instanceBadPosStart([a],) {} //             //# 86: compile-time error
  void instanceBadPosMiddle([a,, b]) {} //         //# 87: compile-time error
  void instanceBadNamEmpty({}) {} //               //# 88: compile-time error
  void instanceBadNamEmpty(,{}) {} //              //# 89: compile-time error
  void instanceBadNamEmpty({,}) {} //              //# 90: compile-time error
  void instanceBadNamEmpty({},) {} //              //# 91: compile-time error
  void instanceBadNamStart(,{a}) {} //             //# 92: compile-time error
  void instanceBadNamStart({, a}) {} //            //# 93: compile-time error
  void instanceBadNamEnd({a,,}) {} //              //# 94: compile-time error
  void instanceBadNamStart({a},) {} //             //# 95: compile-time error
  void instanceBadNamMiddle({a,, b}) {} //         //# 96: compile-time error
  void set instanceSetBadEmpty(,) {} //            //# 97: compile-time error
  void set instanceSetBadStart(, a) {} //          //# 98: compile-time error
  void set instanceSetBadEnd(a,,) {} //            //# 99: compile-time error
  void set instanceSetBadMiddle(a,, b) {} //       //# 100: compile-time error
  void operator *(,); //                           //# 101: compile-time error
  void operator *(, a); //                         //# 102: compile-time error
  void operator *(a,,); //                         //# 103: compile-time error
  void operator []=(, a); //                       //# 104: compile-time error
  void operator []=(a,,); //                       //# 105: compile-time error
  void operator []=(a,, b); //                     //# 106: compile-time error
  void operator []=(a,); //                        //# 107: compile-time error

  method() {
    // Local methods.
    void localBadEmpty(,) {} //                    //# 108: compile-time error
    void localBadStart(, a) {} //                  //# 109: compile-time error
    void localBadEnd(a,,) {} //                    //# 110: compile-time error
    void localBadMiddle(a,, b) {} //               //# 111: compile-time error
    void localBadPosEmpty([]) {} //                //# 112: compile-time error
    void localBadPosEmpty(,[]) {} //               //# 113: compile-time error
    void localBadPosEmpty([,]) {} //               //# 114: compile-time error
    void localBadPosEmpty([],) {} //               //# 115: compile-time error
    void localBadPosStart(,[a]) {} //              //# 116: compile-time error
    void localBadPosStart([, a]) {} //             //# 117: compile-time error
    void localBadPosEnd([a,,]) {} //               //# 118: compile-time error
    void localBadPosStart([a],) {} //              //# 119: compile-time error
    void localBadPosMiddle([a,, b]) {} //          //# 120: compile-time error
    void localBadNamEmpty({}) {} //                //# 121: compile-time error
    void localBadNamEmpty(,{}) {} //               //# 122: compile-time error
    void localBadNamEmpty({,}) {} //               //# 123: compile-time error
    void localBadNamEmpty({},) {} //               //# 124: compile-time error
    void localBadNamStart(,{a}) {} //              //# 125: compile-time error
    void localBadNamStart({, a}) {} //             //# 126: compile-time error
    void localBadNamEnd({a,,}) {} //               //# 127: compile-time error
    void localBadNamStart({a},) {} //              //# 128: compile-time error
    void localBadNamMiddle({a,, b}) {} //          //# 129: compile-time error

    // invalid calls.

    topx(,); //                                    //# 130: compile-time error
    topy(,); //                                    //# 131: compile-time error
    topz(,); //                                    //# 132: compile-time error
    topx(, x); //                                  //# 133: compile-time error
    topz(, z:z); //                                //# 134: compile-time error
    topxy(x,, y); //                               //# 135: compile-time error
    topxz(x,, z:z); //                             //# 136: compile-time error
    topx(x,,); //                                  //# 137: compile-time error
    topz(z:z,,); //                                //# 138: compile-time error

    new C.x(,); //                                 //# 139: compile-time error
    new C.y(,); //                                 //# 140: compile-time error
    new C.z(,); //                                 //# 141: compile-time error
    new C.x(, x); //                               //# 142: compile-time error
    new C.z(, z:z); //                             //# 143: compile-time error
    new C.xy(x,, y); //                            //# 144: compile-time error
    new C.xz(x,, z:z); //                          //# 145: compile-time error
    new C.x(x,,); //                               //# 146: compile-time error
    new C.z(z:z,,); //                             //# 147: compile-time error

    C.staticx(,); //                               //# 148: compile-time error
    C.staticy(,); //                               //# 149: compile-time error
    C.staticz(,); //                               //# 150: compile-time error
    C.staticx(, x); //                             //# 151: compile-time error
    C.staticz(, z:z); //                           //# 152: compile-time error
    C.staticxy(x,, y); //                          //# 153: compile-time error
    C.staticxz(x,, z:z); //                        //# 154: compile-time error
    C.staticx(x,,); //                             //# 155: compile-time error
    C.staticz(z:z,,); //                           //# 156: compile-time error

    c.instancex(,); //                             //# 157: compile-time error
    c.instancey(,); //                             //# 158: compile-time error
    c.instancez(,); //                             //# 159: compile-time error
    c.instancex(, x); //                           //# 160: compile-time error
    c.instancez(, z:z); //                         //# 161: compile-time error
    c.instancexy(x,, y); //                        //# 162: compile-time error
    c.instancexz(x,, z:z); //                      //# 163: compile-time error
    c.instancex(x,,); //                           //# 164: compile-time error
    c.instancez(z:z,,); //                         //# 165: compile-time error

    c[x,] = y; //                                  //# 166: compile-time error
  }

  // As parameters:
  void f(void topBadEmpty(,)) {} //                //# 167: compile-time error
  void f(void topBadStart(, a)) {} //              //# 168: compile-time error
  void f(void topBadEnd(a,,)) {} //                //# 169: compile-time error
  void f(void topBadMiddle(a,, b)) {} //           //# 170: compile-time error
  void f(void topBadPosEmpty([])) {} //            //# 171: compile-time error
  void f(void topBadPosEmpty(,[])) {} //           //# 172: compile-time error
  void f(void topBadPosEmpty([,])) {} //           //# 173: compile-time error
  void f(void topBadPosEmpty([],)) {} //           //# 174: compile-time error
  void f(void topBadPosStart(,[a])) {} //          //# 175: compile-time error
  void f(void topBadPosStart([, a])) {} //         //# 176: compile-time error
  void f(void topBadPosEnd([a,,])) {} //           //# 177: compile-time error
  void f(void topBadPosStart([a],)) {} //          //# 178: compile-time error
  void f(void topBadPosMiddle([a,, b])) {} //      //# 179: compile-time error
  void f(void topBadNamEmpty({})) {} //            //# 180: compile-time error
  void f(void topBadNamEmpty(,{})) {} //           //# 181: compile-time error
  void f(void topBadNamEmpty({,})) {} //           //# 182: compile-time error
  void f(void topBadNamEmpty({},)) {} //           //# 183: compile-time error
  void f(void topBadNamStart(,{a})) {} //          //# 184: compile-time error
  void f(void topBadNamStart({, a})) {} //         //# 185: compile-time error
  void f(void topBadNamEnd({a,,})) {} //           //# 186: compile-time error
  void f(void topBadNamStart({a},)) {} //          //# 187: compile-time error
  void f(void topBadNamMiddle({a,, b})) {} //      //# 188: compile-time error
}

// As typedefs
typedef void BadEmpty(,); //                       //# 189: compile-time error
typedef void BadStart(, a); //                     //# 190: compile-time error
typedef void BadEnd(a,,); //                       //# 191: compile-time error
typedef void BadMiddle(a,, b); //                  //# 192: compile-time error
typedef void BadPosEmpty([]); //                   //# 193: compile-time error
typedef void BadPosEmpty(,[]); //                  //# 194: compile-time error
typedef void BadPosEmpty([,]); //                  //# 195: compile-time error
typedef void BadPosEmpty([],); //                  //# 196: compile-time error
typedef void BadPosStart(,[a]); //                 //# 197: compile-time error
typedef void BadPosStart([, a]); //                //# 198: compile-time error
typedef void BadPosEnd([a,,]); //                  //# 199: compile-time error
typedef void BadPosStart([a],); //                 //# 200: compile-time error
typedef void BadPosMiddle([a,, b]); //             //# 201: compile-time error
typedef void BadNamEmpty({}); //                   //# 202: compile-time error
typedef void BadNamEmpty(,{}); //                  //# 203: compile-time error
typedef void BadNamEmpty({,}); //                  //# 204: compile-time error
typedef void BadNamEmpty({},); //                  //# 205: compile-time error
typedef void BadNamStart(,{a}); //                 //# 206: compile-time error
typedef void BadNamStart({, a}); //                //# 207: compile-time error
typedef void BadNamEnd({a,,}); //                  //# 208: compile-time error
typedef void BadNamStart({a},); //                 //# 209: compile-time error
typedef void BadNamMiddle({a,, b}); //             //# 210: compile-time error

void testBadCalls() {
  topBadEmpty(); //                                //# 1: continued
  topBadStart(); //                                //# 2: continued
  topBadEnd(); //                                  //# 3: continued
  topBadMiddle(); //                               //# 4: continued
  topBadPosEmpty(); //                             //# 5: continued
  topBadPosEmpty(); //                             //# 6: continued
  topBadPosEmpty(); //                             //# 7: continued
  topBadPosEmpty(); //                             //# 8: continued
  topBadPosStart(); //                             //# 9: continued
  topBadPosStart(); //                             //# 10: continued
  topBadPosEnd(); //                               //# 11: continued
  topBadPosStart(); //                             //# 12: continued
  topBadPosMiddle(); //                            //# 13: continued
  topBadNamEmpty(); //                             //# 14: continued
  topBadNamEmpty(); //                             //# 15: continued
  topBadNamEmpty(); //                             //# 16: continued
  topBadNamEmpty(); //                             //# 17: continued
  topBadNamStart(); //                             //# 18: continued
  topBadNamStart(); //                             //# 19: continued
  topBadNamEnd(); //                               //# 20: continued
  topBadNamStart(); //                             //# 21: continued
  topBadNamMiddle(); //                            //# 22: continued
  topSetBadEmpty = 1; //                           //# 23: continued
  topSetBadStart = 1; //                           //# 24: continued
  topSetBadEnd = 1; //                             //# 25: continued
  topSetBadMiddle = 1; //                          //# 26: continued
  new Bad.empty(); //                              //# 27: continued
  new Bad.start(); //                              //# 28: continued
  new Bad.end(); //                                //# 29: continued
  new Bad.middle(); //                             //# 30: continued
  new Bad.posEmpty(); //                           //# 31: continued
  new Bad.posEmpty(); //                           //# 32: continued
  new Bad.posEmpty(); //                           //# 33: continued
  new Bad.posEmpty(); //                           //# 34: continued
  new Bad.posStart(); //                           //# 35: continued
  new Bad.posStart(); //                           //# 36: continued
  new Bad.posEnd(); //                             //# 37: continued
  new Bad.posStart(); //                           //# 38: continued
  new Bad.PosMiddle(); //                          //# 39: continued
  new Bad.namEmpty(); //                           //# 40: continued
  new Bad.namEmpty(); //                           //# 41: continued
  new Bad.namEmpty(); //                           //# 42: continued
  new Bad.namEmpty(); //                           //# 43: continued
  new Bad.namStart(); //                           //# 44: continued
  new Bad.namStart(); //                           //# 45: continued
  new Bad.namEnd(); //                             //# 46: continued
  new Bad.namStart(); //                           //# 47: continued
  new Bad.namMiddle(); //                          //# 48: continued
  Bad.staticBadEmpty(); //                         //# 49: continued
  Bad.staticBadStart(); //                         //# 50: continued
  Bad.staticBadEnd(); //                           //# 51: continued
  Bad.staticBadMiddle(); //                        //# 52: continued
  Bad.staticBadPosEmpty(); //                      //# 53: continued
  Bad.staticBadPosEmpty(); //                      //# 54: continued
  Bad.staticBadPosEmpty(); //                      //# 55: continued
  Bad.staticBadPosEmpty(); //                      //# 56: continued
  Bad.staticBadPosStart(); //                      //# 57: continued
  Bad.staticBadPosStart(); //                      //# 58: continued
  Bad.staticBadPosEnd(); //                        //# 59: continued
  Bad.staticBadPosStart(); //                      //# 60: continued
  Bad.staticBadPosMiddle(); //                     //# 61: continued
  Bad.staticBadNamEmpty(); //                      //# 62: continued
  Bad.staticBadNamEmpty(); //                      //# 63: continued
  Bad.staticBadNamEmpty(); //                      //# 64: continued
  Bad.staticBadNamEmpty(); //                      //# 65: continued
  Bad.staticBadNamStart(); //                      //# 66: continued
  Bad.staticBadNamStart(); //                      //# 67: continued
  Bad.staticBadNamEnd(); //                        //# 68: continued
  Bad.staticBadNamStart(); //                      //# 69: continued
  Bad.staticBadNamMiddle(); //                     //# 70: continued
  Bad.staticSetBadEmpty = 1; //                    //# 71: continued
  Bad.staticSetBadStart = 1; //                    //# 72: continued
  Bad.staticSetBadEnd = 1; //                      //# 73: continued
  Bad.staticSetBadMiddle = 1; //                   //# 74: continued

  var bad = new Bad();
  bad.instanceBadEmpty(); //                       //# 75: continued
  bad.instanceBadStart(); //                       //# 76: continued
  bad.instanceBadEnd(); //                         //# 77: continued
  bad.instanceBadMiddle(); //                      //# 78: continued
  bad.instanceBadPosEmpty(); //                    //# 79: continued
  bad.instanceBadPosEmpty(); //                    //# 80: continued
  bad.instanceBadPosEmpty(); //                    //# 81: continued
  bad.instanceBadPosEmpty(); //                    //# 82: continued
  bad.instanceBadPosStart(); //                    //# 83: continued
  bad.instanceBadPosStart(); //                    //# 84: continued
  bad.instanceBadPosEnd(); //                      //# 85: continued
  bad.instanceBadPosStart(); //                    //# 86: continued
  bad.instanceBadPosMiddle(); //                   //# 87: continued
  bad.instanceBadNamEmpty(); //                    //# 88: continued
  bad.instanceBadNamEmpty(); //                    //# 89: continued
  bad.instanceBadNamEmpty(); //                    //# 90: continued
  bad.instanceBadNamEmpty(); //                    //# 91: continued
  bad.instanceBadNamStart(); //                    //# 92: continued
  bad.instanceBadNamStart(); //                    //# 93: continued
  bad.instanceBadNamEnd(); //                      //# 94: continued
  bad.instanceBadNamStart(); //                    //# 95: continued
  bad.instanceBadNamMiddle(); //                   //# 96: continued
  bad.instanceSetBadEmpty = 1; //                  //# 97: continued
  bad.instanceSetBadStart = 1; //                  //# 98: continued
  bad.instanceSetBadEnd = 1; //                    //# 99: continued
  bad.instanceSetBadMiddle = 1; //                 //# 100: continued
  bad * bad; //                                    //# 101: continued
  bad * bad; //                                    //# 102: continued
  bad * bad; //                                    //# 103: continued
  bad[1] = 1; //                                   //# 104: continued
  bad[1] = 1; //                                   //# 105: continued
  bad[1] = 1; //                                   //# 106: continued
  bad[1] = 1; //                                   //# 107: continued

  // This covers tests 108-166
  bad.method();

  bad.f(() {}); //                                 //# 167: compile-time error
  bad.f(() {}); //                                 //# 168: compile-time error
  bad.f(() {}); //                                 //# 169: compile-time error
  bad.f(() {}); //                                 //# 170: compile-time error
  bad.f(() {}); //                                 //# 171: compile-time error
  bad.f(() {}); //                                 //# 172: compile-time error
  bad.f(() {}); //                                 //# 173: compile-time error
  bad.f(() {}); //                                 //# 174: compile-time error
  bad.f(() {}); //                                 //# 175: compile-time error
  bad.f(() {}); //                                 //# 176: compile-time error
  bad.f(() {}); //                                 //# 177: compile-time error
  bad.f(() {}); //                                 //# 178: compile-time error
  bad.f(() {}); //                                 //# 179: compile-time error
  bad.f(() {}); //                                 //# 180: compile-time error
  bad.f(() {}); //                                 //# 181: compile-time error
  bad.f(() {}); //                                 //# 182: compile-time error
  bad.f(() {}); //                                 //# 183: compile-time error
  bad.f(() {}); //                                 //# 184: compile-time error
  bad.f(() {}); //                                 //# 185: compile-time error
  bad.f(() {}); //                                 //# 186: compile-time error
  bad.f(() {}); //                                 //# 187: compile-time error
  bad.f(() {}); //                                 //# 188: compile-time error

  BadEmpty x; //                                   //# 189: compile-time error
  BadStart x; //                                   //# 190: compile-time error
  BadEnd x; //                                     //# 191: compile-time error
  BadMiddle x; //                                  //# 192: compile-time error
  BadPosEmpty x; //                                //# 193: compile-time error
  BadPosEmpty x; //                                //# 194: compile-time error
  BadPosEmpty x; //                                //# 195: compile-time error
  BadPosEmpty x; //                                //# 196: compile-time error
  BadPosStart x; //                                //# 197: compile-time error
  BadPosStart x; //                                //# 198: compile-time error
  BadPosEnd x; //                                  //# 199: compile-time error
  BadPosStart x; //                                //# 200: compile-time error
  BadPosMiddle x; //                               //# 201: compile-time error
  BadNamEmpty x; //                                //# 202: compile-time error
  BadNamEmpty x; //                                //# 203: compile-time error
  BadNamEmpty x; //                                //# 204: compile-time error
  BadNamEmpty x; //                                //# 205: compile-time error
  BadNamStart x; //                                //# 206: compile-time error
  BadNamStart x; //                                //# 207: compile-time error
  BadNamEnd x; //                                  //# 208: compile-time error
  BadNamStart x; //                                //# 209: compile-time error
  BadNamMiddle x; //                               //# 210: compile-time error
}
