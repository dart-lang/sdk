// @dart=3.10
class C() {}
class C(a) {}
class C(a b) {}
class C(var a) {}
class C(final a) {}
class C(var a b) {}
class C(final a b) {}
class C(var f()) {}
class C(final f()) {}
class C(var void f()) {}
class C(final void f()) {}
class C(var f<T>()) {}
class C(final f<T>()) {}
class C(var void f<T>()) {}
class C(final void f<T>()) {}

enum E() {}
enum E(a) {}
enum E(a b) {}
enum E(var a) {}
enum E(final a) {}
enum E(var a b) {}
enum E(final a b) {}
enum E(var f()) {}
enum E(final f()) {}
enum E(var void f()) {}
enum E(final void f()) {}
enum E(var f<T>()) {}
enum E(final f<T>()) {}
enum E(var void f<T>()) {}
enum E(final void f<T>()) {}

extension type ET() {}
extension type ET(a) {}
extension type ET(a b) {}
extension type ET(var a) {}
extension type ET(final a) {}
extension type ET(var a b) {}
extension type ET(final a b) {}
extension type ET(var f()) {}
extension type ET(final f()) {}
extension type ET(var void f()) {}
extension type ET(final void f()) {}
extension type ET(var f<T>()) {}
extension type ET(final f<T>()) {}
extension type ET(var void f<T>()) {}
extension type ET(final void f<T>()) {}
