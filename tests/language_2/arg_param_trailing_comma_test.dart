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
void topBadEmpty(,) {} //                          //# 1: syntax error
void topBadStart(, a) {} //                        //# 2: syntax error
void topBadEnd(a,,) {} //                          //# 3: syntax error
void topBadMiddle(a,, b) {} //                     //# 4: syntax error
void topBadPosEmpty([]) {} //                      //# 5: syntax error
void topBadPosEmpty(,[]) {} //                     //# 6: syntax error
void topBadPosEmpty([,]) {} //                     //# 7: syntax error
void topBadPosEmpty([],) {} //                     //# 8: syntax error
void topBadPosStart(,[a]) {} //                    //# 9: syntax error
void topBadPosStart([, a]) {} //                   //# 10: syntax error
void topBadPosEnd([a,,]) {} //                     //# 11: syntax error
void topBadPosStart([a],) {} //                    //# 12: syntax error
void topBadPosMiddle([a,, b]) {} //                //# 13: syntax error
void topBadNamEmpty({}) {} //                      //# 14: syntax error
void topBadNamEmpty(,{}) {} //                     //# 15: syntax error
void topBadNamEmpty({,}) {} //                     //# 16: syntax error
void topBadNamEmpty({},) {} //                     //# 17: syntax error
void topBadNamStart(,{a}) {} //                    //# 18: syntax error
void topBadNamStart({, a}) {} //                   //# 19: syntax error
void topBadNamEnd({a,,}) {} //                     //# 20: syntax error
void topBadNamStart({a},) {} //                    //# 21: syntax error
void topBadNamMiddle({a,, b}) {} //                //# 22: syntax error
void set topSetBadEmpty(,) {} //                   //# 23: syntax error
void set topSetBadStart(, a) {} //                 //# 24: syntax error
void set topSetBadEnd(a,,) {} //                   //# 25: syntax error
void set topSetBadMiddle(a,, b) {} //              //# 26: syntax error
class Bad {
  Bad() {}
  Bad.empty(,) {} //                               //# 27: syntax error
  Bad.start(, a) {} //                             //# 28: syntax error
  Bad.end(a,,) {} //                               //# 29: syntax error
  Bad.middle(a,, b) {} //                          //# 30: syntax error
  Bad.posEmpty([]) {} //                           //# 31: syntax error
  Bad.posEmpty(,[]) {} //                          //# 32: syntax error
  Bad.posEmpty([,]) {} //                          //# 33: syntax error
  Bad.posEmpty([],) {} //                          //# 34: syntax error
  Bad.posStart(,[a]) {} //                         //# 35: syntax error
  Bad.posStart([, a]) {} //                        //# 36: syntax error
  Bad.posEnd([a,,]) {} //                          //# 37: syntax error
  Bad.posStart([a],) {} //                         //# 38: syntax error
  Bad.PosMiddle([a,, b]) {} //                     //# 39: syntax error
  Bad.namEmpty({}) {} //                           //# 40: syntax error
  Bad.namEmpty(,{}) {} //                          //# 41: syntax error
  Bad.namEmpty({,}) {} //                          //# 42: syntax error
  Bad.namEmpty({},) {} //                          //# 43: syntax error
  Bad.namStart(,{a}) {} //                         //# 44: syntax error
  Bad.namStart({, a}) {} //                        //# 45: syntax error
  Bad.namEnd({a,,}) {} //                          //# 46: syntax error
  Bad.namStart({a},) {} //                         //# 47: syntax error
  Bad.namMiddle({a,, b}) {} //                     //# 48: syntax error
  static void staticBadEmpty(,) {} //              //# 49: syntax error
  static void staticBadStart(, a) {} //            //# 50: syntax error
  static void staticBadEnd(a,,) {} //              //# 51: syntax error
  static void staticBadMiddle(a,, b) {} //         //# 52: syntax error
  static void staticBadPosEmpty([]) {} //          //# 53: syntax error
  static void staticBadPosEmpty(,[]) {} //         //# 54: syntax error
  static void staticBadPosEmpty([,]) {} //         //# 55: syntax error
  static void staticBadPosEmpty([],) {} //         //# 56: syntax error
  static void staticBadPosStart(,[a]) {} //        //# 57: syntax error
  static void staticBadPosStart([, a]) {} //       //# 58: syntax error
  static void staticBadPosEnd([a,,]) {} //         //# 59: syntax error
  static void staticBadPosStart([a],) {} //        //# 60: syntax error
  static void staticBadPosMiddle([a,, b]) {} //    //# 61: syntax error
  static void staticBadNamEmpty({}) {} //          //# 62: syntax error
  static void staticBadNamEmpty(,{}) {} //         //# 63: syntax error
  static void staticBadNamEmpty({,}) {} //         //# 64: syntax error
  static void staticBadNamEmpty({},) {} //         //# 65: syntax error
  static void staticBadNamStart(,{a}) {} //        //# 66: syntax error
  static void staticBadNamStart({, a}) {} //       //# 67: syntax error
  static void staticBadNamEnd({a,,}) {} //         //# 68: syntax error
  static void staticBadNamStart({a},) {} //        //# 69: syntax error
  static void staticBadNamMiddle({a,, b}) {} //    //# 70: syntax error
  static void set staticSetBadEmpty(,) {} //       //# 71: syntax error
  static void set staticSetBadStart(, a) {} //     //# 72: syntax error
  static void set staticSetBadEnd(a,,) {} //       //# 73: syntax error
  static void set staticSetBadMiddle(a,, b) {} //  //# 74: syntax error
  void instanceBadEmpty(,) {} //                   //# 75: syntax error
  void instanceBadStart(, a) {} //                 //# 76: syntax error
  void instanceBadEnd(a,,) {} //                   //# 77: syntax error
  void instanceBadMiddle(a,, b) {} //              //# 78: syntax error
  void instanceBadPosEmpty([]) {} //               //# 79: syntax error
  void instanceBadPosEmpty(,[]) {} //              //# 80: syntax error
  void instanceBadPosEmpty([,]) {} //              //# 81: syntax error
  void instanceBadPosEmpty([],) {} //              //# 82: syntax error
  void instanceBadPosStart(,[a]) {} //             //# 83: syntax error
  void instanceBadPosStart([, a]) {} //            //# 84: syntax error
  void instanceBadPosEnd([a,,]) {} //              //# 85: syntax error
  void instanceBadPosStart([a],) {} //             //# 86: syntax error
  void instanceBadPosMiddle([a,, b]) {} //         //# 87: syntax error
  void instanceBadNamEmpty({}) {} //               //# 88: syntax error
  void instanceBadNamEmpty(,{}) {} //              //# 89: syntax error
  void instanceBadNamEmpty({,}) {} //              //# 90: syntax error
  void instanceBadNamEmpty({},) {} //              //# 91: syntax error
  void instanceBadNamStart(,{a}) {} //             //# 92: syntax error
  void instanceBadNamStart({, a}) {} //            //# 93: syntax error
  void instanceBadNamEnd({a,,}) {} //              //# 94: syntax error
  void instanceBadNamStart({a},) {} //             //# 95: syntax error
  void instanceBadNamMiddle({a,, b}) {} //         //# 96: syntax error
  void set instanceSetBadEmpty(,) {} //            //# 97: syntax error
  void set instanceSetBadStart(, a) {} //          //# 98: syntax error
  void set instanceSetBadEnd(a,,) {} //            //# 99: syntax error
  void set instanceSetBadMiddle(a,, b) {} //       //# 100: syntax error
  void operator *(,); //                           //# 101: syntax error
  void operator *(, a); //                         //# 102: syntax error
  void operator *(a,,); //                         //# 103: syntax error
  void operator []=(, a); //                       //# 104: syntax error
  void operator []=(a,,); //                       //# 105: syntax error
  void operator []=(a,, b); //                     //# 106: syntax error
  void operator []=(a,); //                        //# 107: compile-time error

  method() {
    // Local methods.
    void localBadEmpty(,) {} //                    //# 108: syntax error
    void localBadStart(, a) {} //                  //# 109: syntax error
    void localBadEnd(a,,) {} //                    //# 110: syntax error
    void localBadMiddle(a,, b) {} //               //# 111: syntax error
    void localBadPosEmpty([]) {} //                //# 112: syntax error
    void localBadPosEmpty(,[]) {} //               //# 113: syntax error
    void localBadPosEmpty([,]) {} //               //# 114: syntax error
    void localBadPosEmpty([],) {} //               //# 115: syntax error
    void localBadPosStart(,[a]) {} //              //# 116: syntax error
    void localBadPosStart([, a]) {} //             //# 117: syntax error
    void localBadPosEnd([a,,]) {} //               //# 118: syntax error
    void localBadPosStart([a],) {} //              //# 119: syntax error
    void localBadPosMiddle([a,, b]) {} //          //# 120: syntax error
    void localBadNamEmpty({}) {} //                //# 121: syntax error
    void localBadNamEmpty(,{}) {} //               //# 122: syntax error
    void localBadNamEmpty({,}) {} //               //# 123: syntax error
    void localBadNamEmpty({},) {} //               //# 124: syntax error
    void localBadNamStart(,{a}) {} //              //# 125: syntax error
    void localBadNamStart({, a}) {} //             //# 126: syntax error
    void localBadNamEnd({a,,}) {} //               //# 127: syntax error
    void localBadNamStart({a},) {} //              //# 128: syntax error
    void localBadNamMiddle({a,, b}) {} //          //# 129: syntax error

    // invalid calls.

    topx(,); //                                    //# 130: syntax error
    topy(,); //                                    //# 131: syntax error
    topz(,); //                                    //# 132: syntax error
    topx(, x); //                                  //# 133: syntax error
    topz(, z:z); //                                //# 134: syntax error
    topxy(x,, y); //                               //# 135: syntax error
    topxz(x,, z:z); //                             //# 136: syntax error
    topx(x,,); //                                  //# 137: syntax error
    topz(z:z,,); //                                //# 138: syntax error

    new C.x(,); //                                 //# 139: syntax error
    new C.y(,); //                                 //# 140: syntax error
    new C.z(,); //                                 //# 141: syntax error
    new C.x(, x); //                               //# 142: syntax error
    new C.z(, z:z); //                             //# 143: syntax error
    new C.xy(x,, y); //                            //# 144: syntax error
    new C.xz(x,, z:z); //                          //# 145: syntax error
    new C.x(x,,); //                               //# 146: syntax error
    new C.z(z:z,,); //                             //# 147: syntax error

    C.staticx(,); //                               //# 148: syntax error
    C.staticy(,); //                               //# 149: syntax error
    C.staticz(,); //                               //# 150: syntax error
    C.staticx(, x); //                             //# 151: syntax error
    C.staticz(, z:z); //                           //# 152: syntax error
    C.staticxy(x,, y); //                          //# 153: syntax error
    C.staticxz(x,, z:z); //                        //# 154: syntax error
    C.staticx(x,,); //                             //# 155: syntax error
    C.staticz(z:z,,); //                           //# 156: syntax error

    c.instancex(,); //                             //# 157: syntax error
    c.instancey(,); //                             //# 158: syntax error
    c.instancez(,); //                             //# 159: syntax error
    c.instancex(, x); //                           //# 160: syntax error
    c.instancez(, z:z); //                         //# 161: syntax error
    c.instancexy(x,, y); //                        //# 162: syntax error
    c.instancexz(x,, z:z); //                      //# 163: syntax error
    c.instancex(x,,); //                           //# 164: syntax error
    c.instancez(z:z,,); //                         //# 165: syntax error

    c[x,] = y; //                                  //# 166: syntax error
  }

  // As parameters:
  void f(void topBadEmpty(,)) {} //                //# 167: syntax error
  void f(void topBadStart(, a)) {} //              //# 168: syntax error
  void f(void topBadEnd(a,,)) {} //                //# 169: syntax error
  void f(void topBadMiddle(a,, b)) {} //           //# 170: syntax error
  void f(void topBadPosEmpty([])) {} //            //# 171: syntax error
  void f(void topBadPosEmpty(,[])) {} //           //# 172: syntax error
  void f(void topBadPosEmpty([,])) {} //           //# 173: syntax error
  void f(void topBadPosEmpty([],)) {} //           //# 174: syntax error
  void f(void topBadPosStart(,[a])) {} //          //# 175: syntax error
  void f(void topBadPosStart([, a])) {} //         //# 176: syntax error
  void f(void topBadPosEnd([a,,])) {} //           //# 177: syntax error
  void f(void topBadPosStart([a],)) {} //          //# 178: syntax error
  void f(void topBadPosMiddle([a,, b])) {} //      //# 179: syntax error
  void f(void topBadNamEmpty({})) {} //            //# 180: syntax error
  void f(void topBadNamEmpty(,{})) {} //           //# 181: syntax error
  void f(void topBadNamEmpty({,})) {} //           //# 182: syntax error
  void f(void topBadNamEmpty({},)) {} //           //# 183: syntax error
  void f(void topBadNamStart(,{a})) {} //          //# 184: syntax error
  void f(void topBadNamStart({, a})) {} //         //# 185: syntax error
  void f(void topBadNamEnd({a,,})) {} //           //# 186: syntax error
  void f(void topBadNamStart({a},)) {} //          //# 187: syntax error
  void f(void topBadNamMiddle({a,, b})) {} //      //# 188: syntax error
}

// As typedefs
typedef void BadEmpty(,); //                       //# 189: syntax error
typedef void BadStart(, a); //                     //# 190: syntax error
typedef void BadEnd(a,,); //                       //# 191: syntax error
typedef void BadMiddle(a,, b); //                  //# 192: syntax error
typedef void BadPosEmpty([]); //                   //# 193: syntax error
typedef void BadPosEmpty(,[]); //                  //# 194: syntax error
typedef void BadPosEmpty([,]); //                  //# 195: syntax error
typedef void BadPosEmpty([],); //                  //# 196: syntax error
typedef void BadPosStart(,[a]); //                 //# 197: syntax error
typedef void BadPosStart([, a]); //                //# 198: syntax error
typedef void BadPosEnd([a,,]); //                  //# 199: syntax error
typedef void BadPosStart([a],); //                 //# 200: syntax error
typedef void BadPosMiddle([a,, b]); //             //# 201: syntax error
typedef void BadNamEmpty({}); //                   //# 202: syntax error
typedef void BadNamEmpty(,{}); //                  //# 203: syntax error
typedef void BadNamEmpty({,}); //                  //# 204: syntax error
typedef void BadNamEmpty({},); //                  //# 205: syntax error
typedef void BadNamStart(,{a}); //                 //# 206: syntax error
typedef void BadNamStart({, a}); //                //# 207: syntax error
typedef void BadNamEnd({a,,}); //                  //# 208: syntax error
typedef void BadNamStart({a},); //                 //# 209: syntax error
typedef void BadNamMiddle({a,, b}); //             //# 210: syntax error

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

  bad.f(() {}); //                                 //# 167: continued
  bad.f(() {}); //                                 //# 168: continued
  bad.f(() {}); //                                 //# 169: continued
  bad.f(() {}); //                                 //# 170: continued
  bad.f(() {}); //                                 //# 171: continued
  bad.f(() {}); //                                 //# 172: continued
  bad.f(() {}); //                                 //# 173: continued
  bad.f(() {}); //                                 //# 174: continued
  bad.f(() {}); //                                 //# 175: continued
  bad.f(() {}); //                                 //# 176: continued
  bad.f(() {}); //                                 //# 177: continued
  bad.f(() {}); //                                 //# 178: continued
  bad.f(() {}); //                                 //# 179: continued
  bad.f(() {}); //                                 //# 180: continued
  bad.f(() {}); //                                 //# 181: continued
  bad.f(() {}); //                                 //# 182: continued
  bad.f(() {}); //                                 //# 183: continued
  bad.f(() {}); //                                 //# 184: continued
  bad.f(() {}); //                                 //# 185: continued
  bad.f(() {}); //                                 //# 186: continued
  bad.f(() {}); //                                 //# 187: continued
  bad.f(() {}); //                                 //# 188: continued

  BadEmpty x; //                                   //# 189: continued
  BadStart x; //                                   //# 190: continued
  BadEnd x; //                                     //# 191: continued
  BadMiddle x; //                                  //# 192: continued
  BadPosEmpty x; //                                //# 193: continued
  BadPosEmpty x; //                                //# 194: continued
  BadPosEmpty x; //                                //# 195: continued
  BadPosEmpty x; //                                //# 196: continued
  BadPosStart x; //                                //# 197: continued
  BadPosStart x; //                                //# 198: continued
  BadPosEnd x; //                                  //# 199: continued
  BadPosStart x; //                                //# 200: continued
  BadPosMiddle x; //                               //# 201: continued
  BadNamEmpty x; //                                //# 202: continued
  BadNamEmpty x; //                                //# 203: continued
  BadNamEmpty x; //                                //# 204: continued
  BadNamEmpty x; //                                //# 205: continued
  BadNamStart x; //                                //# 206: continued
  BadNamStart x; //                                //# 207: continued
  BadNamEnd x; //                                  //# 208: continued
  BadNamStart x; //                                //# 209: continued
  BadNamMiddle x; //                               //# 210: continued
}
