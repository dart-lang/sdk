// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Operators1 {
  operator ==() => true;
  operator <() => true;
  operator >() => true;
  operator <=() => true;
  operator >=() => true;
  operator +() => true;
  operator /() => true;
  operator ~/() => true;
  operator *() => true;
  operator %() => true;
  operator |() => true;
  operator ^() => true;
  operator &() => true;
  operator <<() => true;
  operator >>() => true;
  operator []=(a, b, c) => true;
  operator []() => true;
  operator ~(a) => true;
}

class Operators2 {
  operator ==(a, b) => true;
  operator <(a, b) => true;
  operator >(a, b) => true;
  operator <=(a, b) => true;
  operator >=(a, b) => true;
  operator -(a, b) => true;
  operator +(a, b) => true;
  operator /(a, b) => true;
  operator ~/(a, b) => true;
  operator *(a, b) => true;
  operator %(a, b) => true;
  operator |(a, b) => true;
  operator ^(a, b) => true;
  operator &(a, b) => true;
  operator <<(a, b) => true;
  operator >>(a, b) => true;
  operator []=(a, b, c) => true;
  operator [](a, b) => true;
  operator ~(a, b) => true;
}

class Operators3 {
  operator ==([a]) => true;
  operator <([a]) => true;
  operator >([a]) => true;
  operator <=([a]) => true;
  operator >=([a]) => true;
  operator -([a]) => true;
  operator +([a]) => true;
  operator /([a]) => true;
  operator ~/([a]) => true;
  operator *([a]) => true;
  operator %([a]) => true;
  operator |([a]) => true;
  operator ^([a]) => true;
  operator &([a]) => true;
  operator <<([a]) => true;
  operator >>([a]) => true;
  operator []=([a, b]) => true;
  operator []([a]) => true;
  operator ~([a]) => true;
}

class Operators4 {
  operator ==({a}) => true;
  operator <({a}) => true;
  operator >({a}) => true;
  operator <=({a}) => true;
  operator >=({a}) => true;
  operator -({a}) => true;
  operator +({a}) => true;
  operator /({a}) => true;
  operator ~/({a}) => true;
  operator *({a}) => true;
  operator %({a}) => true;
  operator |({a}) => true;
  operator ^({a}) => true;
  operator &({a}) => true;
  operator <<({a}) => true;
  operator >>({a}) => true;
  operator []=({a, b}) => true;
  operator []({a}) => true;
  operator ~({a}) => true;
}

class Operators5 {
  operator ==(a, [b]) => true;
  operator <(a, [b]) => true;
  operator >(a, [b]) => true;
  operator <=(a, [b]) => true;
  operator >=(a, [b]) => true;
  operator -(a, [b]) => true;
  operator +(a, [b]) => true;
  operator /(a, [b]) => true;
  operator ~/(a, [b]) => true;
  operator *(a, [b]) => true;
  operator %(a, [b]) => true;
  operator |(a, [b]) => true;
  operator ^(a, [b]) => true;
  operator &(a, [b]) => true;
  operator <<(a, [b]) => true;
  operator >>(a, [b]) => true;
  operator []=(a, b, [c]) => true;
  operator [](a, [b]) => true;
  operator ~(a, [b]) => true;
}

class Operators6 {
  operator ==(a, {b}) => true;
  operator <(a, {b}) => true;
  operator >(a, {b}) => true;
  operator <=(a, {b}) => true;
  operator >=(a, {b}) => true;
  operator -(a, {b}) => true;
  operator +(a, {b}) => true;
  operator /(a, {b}) => true;
  operator ~/(a, {b}) => true;
  operator *(a, {b}) => true;
  operator %(a, {b}) => true;
  operator |(a, {b}) => true;
  operator ^(a, {b}) => true;
  operator &(a, {b}) => true;
  operator <<(a, {b}) => true;
  operator >>(a, {b}) => true;
  operator []=(a, b, {c}) => true;
  operator [](a, {b}) => true;
  operator ~(a, {b}) => true;
}

class Operators7 {
  operator ==<T>(a) => true;
  operator ><T>(a) => true;
  operator <=<T>(a) => true;
  operator >=<T>(a) => true;
  operator -<T>() => true;
  operator -<T>(a) => true;
  operator +<T>(a) => true;
  operator /<T>(a) => true;
  operator ~/<T>(a) => true;
  operator *<T>(a) => true;
  operator %<T>(a) => true;
  operator |<T>(a) => true;
  operator ^<T>(a) => true;
  operator &<T>(a) => true;
  operator <<<T>(a) => true;
  operator >><T>(a) => true;
  operator []=<T>(a, b) => true;
  operator []<T>(a) => true;
  operator ~<T>() => true;
}

main() {}
