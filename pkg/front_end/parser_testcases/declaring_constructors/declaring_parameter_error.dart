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

enum E(covariant a) {}
enum E(covariant a b) {}
enum E(covariant var a) {}
enum E(covariant final a) {}
enum E(covariant var a b) {}
enum E(covariant final a b) {}

extension type ET(int i) {
  ET(var a b) {}
}

extension type ET(covariant a) {}
extension type ET(covariant a b) {}
extension type ET(covariant var a) {}
extension type ET(covariant final a) {}
extension type ET(covariant var a b) {}
extension type ET(covariant final a b) {}
