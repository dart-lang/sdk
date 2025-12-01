m(var a b) {}

class C {
  C(var a b) {}
}

class C(covariant a) {}
class C(covariant a b) {}
class C(covariant var a) {}
class C(covariant final a) {}
class C(covariant var a b) {}
class C(covariant final a b) {}
class C(const f()) {}
class C(const f<T>()) {}
class C(const void f()) {}
class C(const void f<T>()) {}

enum E(covariant a) {}
enum E(covariant a b) {}
enum E(covariant var a) {}
enum E(covariant final a) {}
enum E(covariant var a b) {}
enum E(covariant final a b) {}
enum E(const f()) {}
enum E(const f<T>()) {}
enum E(const void f()) {}
enum E(const void f<T>()) {}

extension type ET(int i) {
  ET(var a b) {}
}

extension type ET(covariant a) {}
extension type ET(covariant a b) {}
extension type ET(covariant var a) {}
extension type ET(covariant final a) {}
extension type ET(covariant var a b) {}
extension type ET(covariant final a b) {}
extension type ET(const f()) {}
extension type ET(const f<T>()) {}
extension type ET(const void f()) {}
extension type ET(const void f<T>()) {}
