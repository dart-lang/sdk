// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This benchmark suite measures the overhead of instantiating type arguments,
// with a particular aim of measuring the overhead of the caching mechanism.

// @dart=2.9"

import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
  // Instantiates a series of types, each type instantiated with a single type.
  const InstantiateOnce().report();
  // Repeats the instantiations in InstantiateOnce, this time depending
  // on the now-filled caches.
  const RepeatInstantiateOnce().report();
  // Instantiates a single type many times, each type being a new instantiation.
  const InstantiateMany().report();
  // Repeats the instantiations in InstantiateMany, this time depending on the
  // now-filled cache.
  const RepeatInstantiateMany().report();
}

class InstantiateOnce extends BenchmarkBase {
  const InstantiateOnce() : super('InstantiateTypeArgs.InstantiateOnce');

  // Only call run once, else the remaining runs will have the cached types.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateOnce<B>();
  }
}

class RepeatInstantiateOnce extends BenchmarkBase {
  const RepeatInstantiateOnce()
      : super('InstantiateTypeArgs.RepeatInstantiateOnce');

  @override
  void setup() {
    // Run once to make sure the instantiations are cached, in case this
    // benchmark is run on its own.
    instantiateOnce<B>();
  }

  // Only call run once, so this is directly comparable to InstantiateOnce.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateOnce<B>();
  }
}

class InstantiateMany extends BenchmarkBase {
  const InstantiateMany() : super('InstantiateTypeArgs.InstantiateMany');

  // Only call run once, else the remaining runs will have the cached types.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateMany();
  }
}

class RepeatInstantiateMany extends BenchmarkBase {
  const RepeatInstantiateMany()
      : super('InstantiateTypeArgs.RepeatInstantiateMany');

  @override
  void setup() {
    // Run once to make sure the instantiations are cached, in case this
    // benchmark is run on its own.
    instantiateMany();
  }

  // Only call run once, so this is directly comparable to InstantiateMany.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateMany();
  }
}

@pragma('vm:never-inline')
void blackhole<T>() => null;

class B {}

class D<T> {
  @pragma('vm:never-inline')
  static void instantiate<T>() => blackhole<D<T>>();
}

class A0<T> {}

class A1<T> {}

class A2<T> {}

class A3<T> {}

class A4<T> {}

class A5<T> {}

class A6<T> {}

class A7<T> {}

class A8<T> {}

class A9<T> {}

class A10<T> {}

class A11<T> {}

class A12<T> {}

class A13<T> {}

class A14<T> {}

class A15<T> {}

class A16<T> {}

class A17<T> {}

class A18<T> {}

class A19<T> {}

class A20<T> {}

class A21<T> {}

class A22<T> {}

class A23<T> {}

class A24<T> {}

class A25<T> {}

class A26<T> {}

class A27<T> {}

class A28<T> {}

class A29<T> {}

class A30<T> {}

class A31<T> {}

class A32<T> {}

class A33<T> {}

class A34<T> {}

class A35<T> {}

class A36<T> {}

class A37<T> {}

class A38<T> {}

class A39<T> {}

class A40<T> {}

class A41<T> {}

class A42<T> {}

class A43<T> {}

class A44<T> {}

class A45<T> {}

class A46<T> {}

class A47<T> {}

class A48<T> {}

class A49<T> {}

class A50<T> {}

class A51<T> {}

class A52<T> {}

class A53<T> {}

class A54<T> {}

class A55<T> {}

class A56<T> {}

class A57<T> {}

class A58<T> {}

class A59<T> {}

class A60<T> {}

class A61<T> {}

class A62<T> {}

class A63<T> {}

class A64<T> {}

class A65<T> {}

class A66<T> {}

class A67<T> {}

class A68<T> {}

class A69<T> {}

class A70<T> {}

class A71<T> {}

class A72<T> {}

class A73<T> {}

class A74<T> {}

class A75<T> {}

class A76<T> {}

class A77<T> {}

class A78<T> {}

class A79<T> {}

class A80<T> {}

class A81<T> {}

class A82<T> {}

class A83<T> {}

class A84<T> {}

class A85<T> {}

class A86<T> {}

class A87<T> {}

class A88<T> {}

class A89<T> {}

class A90<T> {}

class A91<T> {}

class A92<T> {}

class A93<T> {}

class A94<T> {}

class A95<T> {}

class A96<T> {}

class A97<T> {}

class A98<T> {}

class A99<T> {}

class A100<T> {}

class A101<T> {}

class A102<T> {}

class A103<T> {}

class A104<T> {}

class A105<T> {}

class A106<T> {}

class A107<T> {}

class A108<T> {}

class A109<T> {}

class A110<T> {}

class A111<T> {}

class A112<T> {}

class A113<T> {}

class A114<T> {}

class A115<T> {}

class A116<T> {}

class A117<T> {}

class A118<T> {}

class A119<T> {}

class A120<T> {}

class A121<T> {}

class A122<T> {}

class A123<T> {}

class A124<T> {}

class A125<T> {}

class A126<T> {}

class A127<T> {}

class A128<T> {}

class A129<T> {}

class A130<T> {}

class A131<T> {}

class A132<T> {}

class A133<T> {}

class A134<T> {}

class A135<T> {}

class A136<T> {}

class A137<T> {}

class A138<T> {}

class A139<T> {}

class A140<T> {}

class A141<T> {}

class A142<T> {}

class A143<T> {}

class A144<T> {}

class A145<T> {}

class A146<T> {}

class A147<T> {}

class A148<T> {}

class A149<T> {}

class A150<T> {}

class A151<T> {}

class A152<T> {}

class A153<T> {}

class A154<T> {}

class A155<T> {}

class A156<T> {}

class A157<T> {}

class A158<T> {}

class A159<T> {}

class A160<T> {}

class A161<T> {}

class A162<T> {}

class A163<T> {}

class A164<T> {}

class A165<T> {}

class A166<T> {}

class A167<T> {}

class A168<T> {}

class A169<T> {}

class A170<T> {}

class A171<T> {}

class A172<T> {}

class A173<T> {}

class A174<T> {}

class A175<T> {}

class A176<T> {}

class A177<T> {}

class A178<T> {}

class A179<T> {}

class A180<T> {}

class A181<T> {}

class A182<T> {}

class A183<T> {}

class A184<T> {}

class A185<T> {}

class A186<T> {}

class A187<T> {}

class A188<T> {}

class A189<T> {}

class A190<T> {}

class A191<T> {}

class A192<T> {}

class A193<T> {}

class A194<T> {}

class A195<T> {}

class A196<T> {}

class A197<T> {}

class A198<T> {}

class A199<T> {}

class A200<T> {}

class A201<T> {}

class A202<T> {}

class A203<T> {}

class A204<T> {}

class A205<T> {}

class A206<T> {}

class A207<T> {}

class A208<T> {}

class A209<T> {}

class A210<T> {}

class A211<T> {}

class A212<T> {}

class A213<T> {}

class A214<T> {}

class A215<T> {}

class A216<T> {}

class A217<T> {}

class A218<T> {}

class A219<T> {}

class A220<T> {}

class A221<T> {}

class A222<T> {}

class A223<T> {}

class A224<T> {}

class A225<T> {}

class A226<T> {}

class A227<T> {}

class A228<T> {}

class A229<T> {}

class A230<T> {}

class A231<T> {}

class A232<T> {}

class A233<T> {}

class A234<T> {}

class A235<T> {}

class A236<T> {}

class A237<T> {}

class A238<T> {}

class A239<T> {}

class A240<T> {}

class A241<T> {}

class A242<T> {}

class A243<T> {}

class A244<T> {}

class A245<T> {}

class A246<T> {}

class A247<T> {}

class A248<T> {}

class A249<T> {}

class A250<T> {}

class A251<T> {}

class A252<T> {}

class A253<T> {}

class A254<T> {}

class A255<T> {}

class A256<T> {}

class A257<T> {}

class A258<T> {}

class A259<T> {}

class A260<T> {}

class A261<T> {}

class A262<T> {}

class A263<T> {}

class A264<T> {}

class A265<T> {}

class A266<T> {}

class A267<T> {}

class A268<T> {}

class A269<T> {}

class A270<T> {}

class A271<T> {}

class A272<T> {}

class A273<T> {}

class A274<T> {}

class A275<T> {}

class A276<T> {}

class A277<T> {}

class A278<T> {}

class A279<T> {}

class A280<T> {}

class A281<T> {}

class A282<T> {}

class A283<T> {}

class A284<T> {}

class A285<T> {}

class A286<T> {}

class A287<T> {}

class A288<T> {}

class A289<T> {}

class A290<T> {}

class A291<T> {}

class A292<T> {}

class A293<T> {}

class A294<T> {}

class A295<T> {}

class A296<T> {}

class A297<T> {}

class A298<T> {}

class A299<T> {}

class A300<T> {}

class A301<T> {}

class A302<T> {}

class A303<T> {}

class A304<T> {}

class A305<T> {}

class A306<T> {}

class A307<T> {}

class A308<T> {}

class A309<T> {}

class A310<T> {}

class A311<T> {}

class A312<T> {}

class A313<T> {}

class A314<T> {}

class A315<T> {}

class A316<T> {}

class A317<T> {}

class A318<T> {}

class A319<T> {}

class A320<T> {}

class A321<T> {}

class A322<T> {}

class A323<T> {}

class A324<T> {}

class A325<T> {}

class A326<T> {}

class A327<T> {}

class A328<T> {}

class A329<T> {}

class A330<T> {}

class A331<T> {}

class A332<T> {}

class A333<T> {}

class A334<T> {}

class A335<T> {}

class A336<T> {}

class A337<T> {}

class A338<T> {}

class A339<T> {}

class A340<T> {}

class A341<T> {}

class A342<T> {}

class A343<T> {}

class A344<T> {}

class A345<T> {}

class A346<T> {}

class A347<T> {}

class A348<T> {}

class A349<T> {}

class A350<T> {}

class A351<T> {}

class A352<T> {}

class A353<T> {}

class A354<T> {}

class A355<T> {}

class A356<T> {}

class A357<T> {}

class A358<T> {}

class A359<T> {}

class A360<T> {}

class A361<T> {}

class A362<T> {}

class A363<T> {}

class A364<T> {}

class A365<T> {}

class A366<T> {}

class A367<T> {}

class A368<T> {}

class A369<T> {}

class A370<T> {}

class A371<T> {}

class A372<T> {}

class A373<T> {}

class A374<T> {}

class A375<T> {}

class A376<T> {}

class A377<T> {}

class A378<T> {}

class A379<T> {}

class A380<T> {}

class A381<T> {}

class A382<T> {}

class A383<T> {}

class A384<T> {}

class A385<T> {}

class A386<T> {}

class A387<T> {}

class A388<T> {}

class A389<T> {}

class A390<T> {}

class A391<T> {}

class A392<T> {}

class A393<T> {}

class A394<T> {}

class A395<T> {}

class A396<T> {}

class A397<T> {}

class A398<T> {}

class A399<T> {}

class A400<T> {}

class A401<T> {}

class A402<T> {}

class A403<T> {}

class A404<T> {}

class A405<T> {}

class A406<T> {}

class A407<T> {}

class A408<T> {}

class A409<T> {}

class A410<T> {}

class A411<T> {}

class A412<T> {}

class A413<T> {}

class A414<T> {}

class A415<T> {}

class A416<T> {}

class A417<T> {}

class A418<T> {}

class A419<T> {}

class A420<T> {}

class A421<T> {}

class A422<T> {}

class A423<T> {}

class A424<T> {}

class A425<T> {}

class A426<T> {}

class A427<T> {}

class A428<T> {}

class A429<T> {}

class A430<T> {}

class A431<T> {}

class A432<T> {}

class A433<T> {}

class A434<T> {}

class A435<T> {}

class A436<T> {}

class A437<T> {}

class A438<T> {}

class A439<T> {}

class A440<T> {}

class A441<T> {}

class A442<T> {}

class A443<T> {}

class A444<T> {}

class A445<T> {}

class A446<T> {}

class A447<T> {}

class A448<T> {}

class A449<T> {}

class A450<T> {}

class A451<T> {}

class A452<T> {}

class A453<T> {}

class A454<T> {}

class A455<T> {}

class A456<T> {}

class A457<T> {}

class A458<T> {}

class A459<T> {}

class A460<T> {}

class A461<T> {}

class A462<T> {}

class A463<T> {}

class A464<T> {}

class A465<T> {}

class A466<T> {}

class A467<T> {}

class A468<T> {}

class A469<T> {}

class A470<T> {}

class A471<T> {}

class A472<T> {}

class A473<T> {}

class A474<T> {}

class A475<T> {}

class A476<T> {}

class A477<T> {}

class A478<T> {}

class A479<T> {}

class A480<T> {}

class A481<T> {}

class A482<T> {}

class A483<T> {}

class A484<T> {}

class A485<T> {}

class A486<T> {}

class A487<T> {}

class A488<T> {}

class A489<T> {}

class A490<T> {}

class A491<T> {}

class A492<T> {}

class A493<T> {}

class A494<T> {}

class A495<T> {}

class A496<T> {}

class A497<T> {}

class A498<T> {}

class A499<T> {}

class A500<T> {}

class A501<T> {}

class A502<T> {}

class A503<T> {}

class A504<T> {}

class A505<T> {}

class A506<T> {}

class A507<T> {}

class A508<T> {}

class A509<T> {}

class A510<T> {}

class A511<T> {}

class A512<T> {}

class A513<T> {}

class A514<T> {}

class A515<T> {}

class A516<T> {}

class A517<T> {}

class A518<T> {}

class A519<T> {}

class A520<T> {}

class A521<T> {}

class A522<T> {}

class A523<T> {}

class A524<T> {}

class A525<T> {}

class A526<T> {}

class A527<T> {}

class A528<T> {}

class A529<T> {}

class A530<T> {}

class A531<T> {}

class A532<T> {}

class A533<T> {}

class A534<T> {}

class A535<T> {}

class A536<T> {}

class A537<T> {}

class A538<T> {}

class A539<T> {}

class A540<T> {}

class A541<T> {}

class A542<T> {}

class A543<T> {}

class A544<T> {}

class A545<T> {}

class A546<T> {}

class A547<T> {}

class A548<T> {}

class A549<T> {}

class A550<T> {}

class A551<T> {}

class A552<T> {}

class A553<T> {}

class A554<T> {}

class A555<T> {}

class A556<T> {}

class A557<T> {}

class A558<T> {}

class A559<T> {}

class A560<T> {}

class A561<T> {}

class A562<T> {}

class A563<T> {}

class A564<T> {}

class A565<T> {}

class A566<T> {}

class A567<T> {}

class A568<T> {}

class A569<T> {}

class A570<T> {}

class A571<T> {}

class A572<T> {}

class A573<T> {}

class A574<T> {}

class A575<T> {}

class A576<T> {}

class A577<T> {}

class A578<T> {}

class A579<T> {}

class A580<T> {}

class A581<T> {}

class A582<T> {}

class A583<T> {}

class A584<T> {}

class A585<T> {}

class A586<T> {}

class A587<T> {}

class A588<T> {}

class A589<T> {}

class A590<T> {}

class A591<T> {}

class A592<T> {}

class A593<T> {}

class A594<T> {}

class A595<T> {}

class A596<T> {}

class A597<T> {}

class A598<T> {}

class A599<T> {}

class A600<T> {}

class A601<T> {}

class A602<T> {}

class A603<T> {}

class A604<T> {}

class A605<T> {}

class A606<T> {}

class A607<T> {}

class A608<T> {}

class A609<T> {}

class A610<T> {}

class A611<T> {}

class A612<T> {}

class A613<T> {}

class A614<T> {}

class A615<T> {}

class A616<T> {}

class A617<T> {}

class A618<T> {}

class A619<T> {}

class A620<T> {}

class A621<T> {}

class A622<T> {}

class A623<T> {}

class A624<T> {}

class A625<T> {}

class A626<T> {}

class A627<T> {}

class A628<T> {}

class A629<T> {}

class A630<T> {}

class A631<T> {}

class A632<T> {}

class A633<T> {}

class A634<T> {}

class A635<T> {}

class A636<T> {}

class A637<T> {}

class A638<T> {}

class A639<T> {}

class A640<T> {}

class A641<T> {}

class A642<T> {}

class A643<T> {}

class A644<T> {}

class A645<T> {}

class A646<T> {}

class A647<T> {}

class A648<T> {}

class A649<T> {}

class A650<T> {}

class A651<T> {}

class A652<T> {}

class A653<T> {}

class A654<T> {}

class A655<T> {}

class A656<T> {}

class A657<T> {}

class A658<T> {}

class A659<T> {}

class A660<T> {}

class A661<T> {}

class A662<T> {}

class A663<T> {}

class A664<T> {}

class A665<T> {}

class A666<T> {}

class A667<T> {}

class A668<T> {}

class A669<T> {}

class A670<T> {}

class A671<T> {}

class A672<T> {}

class A673<T> {}

class A674<T> {}

class A675<T> {}

class A676<T> {}

class A677<T> {}

class A678<T> {}

class A679<T> {}

class A680<T> {}

class A681<T> {}

class A682<T> {}

class A683<T> {}

class A684<T> {}

class A685<T> {}

class A686<T> {}

class A687<T> {}

class A688<T> {}

class A689<T> {}

class A690<T> {}

class A691<T> {}

class A692<T> {}

class A693<T> {}

class A694<T> {}

class A695<T> {}

class A696<T> {}

class A697<T> {}

class A698<T> {}

class A699<T> {}

class A700<T> {}

class A701<T> {}

class A702<T> {}

class A703<T> {}

class A704<T> {}

class A705<T> {}

class A706<T> {}

class A707<T> {}

class A708<T> {}

class A709<T> {}

class A710<T> {}

class A711<T> {}

class A712<T> {}

class A713<T> {}

class A714<T> {}

class A715<T> {}

class A716<T> {}

class A717<T> {}

class A718<T> {}

class A719<T> {}

class A720<T> {}

class A721<T> {}

class A722<T> {}

class A723<T> {}

class A724<T> {}

class A725<T> {}

class A726<T> {}

class A727<T> {}

class A728<T> {}

class A729<T> {}

class A730<T> {}

class A731<T> {}

class A732<T> {}

class A733<T> {}

class A734<T> {}

class A735<T> {}

class A736<T> {}

class A737<T> {}

class A738<T> {}

class A739<T> {}

class A740<T> {}

class A741<T> {}

class A742<T> {}

class A743<T> {}

class A744<T> {}

class A745<T> {}

class A746<T> {}

class A747<T> {}

class A748<T> {}

class A749<T> {}

class A750<T> {}

class A751<T> {}

class A752<T> {}

class A753<T> {}

class A754<T> {}

class A755<T> {}

class A756<T> {}

class A757<T> {}

class A758<T> {}

class A759<T> {}

class A760<T> {}

class A761<T> {}

class A762<T> {}

class A763<T> {}

class A764<T> {}

class A765<T> {}

class A766<T> {}

class A767<T> {}

class A768<T> {}

class A769<T> {}

class A770<T> {}

class A771<T> {}

class A772<T> {}

class A773<T> {}

class A774<T> {}

class A775<T> {}

class A776<T> {}

class A777<T> {}

class A778<T> {}

class A779<T> {}

class A780<T> {}

class A781<T> {}

class A782<T> {}

class A783<T> {}

class A784<T> {}

class A785<T> {}

class A786<T> {}

class A787<T> {}

class A788<T> {}

class A789<T> {}

class A790<T> {}

class A791<T> {}

class A792<T> {}

class A793<T> {}

class A794<T> {}

class A795<T> {}

class A796<T> {}

class A797<T> {}

class A798<T> {}

class A799<T> {}

class A800<T> {}

class A801<T> {}

class A802<T> {}

class A803<T> {}

class A804<T> {}

class A805<T> {}

class A806<T> {}

class A807<T> {}

class A808<T> {}

class A809<T> {}

class A810<T> {}

class A811<T> {}

class A812<T> {}

class A813<T> {}

class A814<T> {}

class A815<T> {}

class A816<T> {}

class A817<T> {}

class A818<T> {}

class A819<T> {}

class A820<T> {}

class A821<T> {}

class A822<T> {}

class A823<T> {}

class A824<T> {}

class A825<T> {}

class A826<T> {}

class A827<T> {}

class A828<T> {}

class A829<T> {}

class A830<T> {}

class A831<T> {}

class A832<T> {}

class A833<T> {}

class A834<T> {}

class A835<T> {}

class A836<T> {}

class A837<T> {}

class A838<T> {}

class A839<T> {}

class A840<T> {}

class A841<T> {}

class A842<T> {}

class A843<T> {}

class A844<T> {}

class A845<T> {}

class A846<T> {}

class A847<T> {}

class A848<T> {}

class A849<T> {}

class A850<T> {}

class A851<T> {}

class A852<T> {}

class A853<T> {}

class A854<T> {}

class A855<T> {}

class A856<T> {}

class A857<T> {}

class A858<T> {}

class A859<T> {}

class A860<T> {}

class A861<T> {}

class A862<T> {}

class A863<T> {}

class A864<T> {}

class A865<T> {}

class A866<T> {}

class A867<T> {}

class A868<T> {}

class A869<T> {}

class A870<T> {}

class A871<T> {}

class A872<T> {}

class A873<T> {}

class A874<T> {}

class A875<T> {}

class A876<T> {}

class A877<T> {}

class A878<T> {}

class A879<T> {}

class A880<T> {}

class A881<T> {}

class A882<T> {}

class A883<T> {}

class A884<T> {}

class A885<T> {}

class A886<T> {}

class A887<T> {}

class A888<T> {}

class A889<T> {}

class A890<T> {}

class A891<T> {}

class A892<T> {}

class A893<T> {}

class A894<T> {}

class A895<T> {}

class A896<T> {}

class A897<T> {}

class A898<T> {}

class A899<T> {}

class A900<T> {}

class A901<T> {}

class A902<T> {}

class A903<T> {}

class A904<T> {}

class A905<T> {}

class A906<T> {}

class A907<T> {}

class A908<T> {}

class A909<T> {}

class A910<T> {}

class A911<T> {}

class A912<T> {}

class A913<T> {}

class A914<T> {}

class A915<T> {}

class A916<T> {}

class A917<T> {}

class A918<T> {}

class A919<T> {}

class A920<T> {}

class A921<T> {}

class A922<T> {}

class A923<T> {}

class A924<T> {}

class A925<T> {}

class A926<T> {}

class A927<T> {}

class A928<T> {}

class A929<T> {}

class A930<T> {}

class A931<T> {}

class A932<T> {}

class A933<T> {}

class A934<T> {}

class A935<T> {}

class A936<T> {}

class A937<T> {}

class A938<T> {}

class A939<T> {}

class A940<T> {}

class A941<T> {}

class A942<T> {}

class A943<T> {}

class A944<T> {}

class A945<T> {}

class A946<T> {}

class A947<T> {}

class A948<T> {}

class A949<T> {}

class A950<T> {}

class A951<T> {}

class A952<T> {}

class A953<T> {}

class A954<T> {}

class A955<T> {}

class A956<T> {}

class A957<T> {}

class A958<T> {}

class A959<T> {}

class A960<T> {}

class A961<T> {}

class A962<T> {}

class A963<T> {}

class A964<T> {}

class A965<T> {}

class A966<T> {}

class A967<T> {}

class A968<T> {}

class A969<T> {}

class A970<T> {}

class A971<T> {}

class A972<T> {}

class A973<T> {}

class A974<T> {}

class A975<T> {}

class A976<T> {}

class A977<T> {}

class A978<T> {}

class A979<T> {}

class A980<T> {}

class A981<T> {}

class A982<T> {}

class A983<T> {}

class A984<T> {}

class A985<T> {}

class A986<T> {}

class A987<T> {}

class A988<T> {}

class A989<T> {}

class A990<T> {}

class A991<T> {}

class A992<T> {}

class A993<T> {}

class A994<T> {}

class A995<T> {}

class A996<T> {}

class A997<T> {}

class A998<T> {}

class A999<T> {}

void instantiateOnce<T>() {
  blackhole<A0<T>>();
  blackhole<A1<T>>();
  blackhole<A2<T>>();
  blackhole<A3<T>>();
  blackhole<A4<T>>();
  blackhole<A5<T>>();
  blackhole<A6<T>>();
  blackhole<A7<T>>();
  blackhole<A8<T>>();
  blackhole<A9<T>>();
  blackhole<A10<T>>();
  blackhole<A11<T>>();
  blackhole<A12<T>>();
  blackhole<A13<T>>();
  blackhole<A14<T>>();
  blackhole<A15<T>>();
  blackhole<A16<T>>();
  blackhole<A17<T>>();
  blackhole<A18<T>>();
  blackhole<A19<T>>();
  blackhole<A20<T>>();
  blackhole<A21<T>>();
  blackhole<A22<T>>();
  blackhole<A23<T>>();
  blackhole<A24<T>>();
  blackhole<A25<T>>();
  blackhole<A26<T>>();
  blackhole<A27<T>>();
  blackhole<A28<T>>();
  blackhole<A29<T>>();
  blackhole<A30<T>>();
  blackhole<A31<T>>();
  blackhole<A32<T>>();
  blackhole<A33<T>>();
  blackhole<A34<T>>();
  blackhole<A35<T>>();
  blackhole<A36<T>>();
  blackhole<A37<T>>();
  blackhole<A38<T>>();
  blackhole<A39<T>>();
  blackhole<A40<T>>();
  blackhole<A41<T>>();
  blackhole<A42<T>>();
  blackhole<A43<T>>();
  blackhole<A44<T>>();
  blackhole<A45<T>>();
  blackhole<A46<T>>();
  blackhole<A47<T>>();
  blackhole<A48<T>>();
  blackhole<A49<T>>();
  blackhole<A50<T>>();
  blackhole<A51<T>>();
  blackhole<A52<T>>();
  blackhole<A53<T>>();
  blackhole<A54<T>>();
  blackhole<A55<T>>();
  blackhole<A56<T>>();
  blackhole<A57<T>>();
  blackhole<A58<T>>();
  blackhole<A59<T>>();
  blackhole<A60<T>>();
  blackhole<A61<T>>();
  blackhole<A62<T>>();
  blackhole<A63<T>>();
  blackhole<A64<T>>();
  blackhole<A65<T>>();
  blackhole<A66<T>>();
  blackhole<A67<T>>();
  blackhole<A68<T>>();
  blackhole<A69<T>>();
  blackhole<A70<T>>();
  blackhole<A71<T>>();
  blackhole<A72<T>>();
  blackhole<A73<T>>();
  blackhole<A74<T>>();
  blackhole<A75<T>>();
  blackhole<A76<T>>();
  blackhole<A77<T>>();
  blackhole<A78<T>>();
  blackhole<A79<T>>();
  blackhole<A80<T>>();
  blackhole<A81<T>>();
  blackhole<A82<T>>();
  blackhole<A83<T>>();
  blackhole<A84<T>>();
  blackhole<A85<T>>();
  blackhole<A86<T>>();
  blackhole<A87<T>>();
  blackhole<A88<T>>();
  blackhole<A89<T>>();
  blackhole<A90<T>>();
  blackhole<A91<T>>();
  blackhole<A92<T>>();
  blackhole<A93<T>>();
  blackhole<A94<T>>();
  blackhole<A95<T>>();
  blackhole<A96<T>>();
  blackhole<A97<T>>();
  blackhole<A98<T>>();
  blackhole<A99<T>>();
  blackhole<A100<T>>();
  blackhole<A101<T>>();
  blackhole<A102<T>>();
  blackhole<A103<T>>();
  blackhole<A104<T>>();
  blackhole<A105<T>>();
  blackhole<A106<T>>();
  blackhole<A107<T>>();
  blackhole<A108<T>>();
  blackhole<A109<T>>();
  blackhole<A110<T>>();
  blackhole<A111<T>>();
  blackhole<A112<T>>();
  blackhole<A113<T>>();
  blackhole<A114<T>>();
  blackhole<A115<T>>();
  blackhole<A116<T>>();
  blackhole<A117<T>>();
  blackhole<A118<T>>();
  blackhole<A119<T>>();
  blackhole<A120<T>>();
  blackhole<A121<T>>();
  blackhole<A122<T>>();
  blackhole<A123<T>>();
  blackhole<A124<T>>();
  blackhole<A125<T>>();
  blackhole<A126<T>>();
  blackhole<A127<T>>();
  blackhole<A128<T>>();
  blackhole<A129<T>>();
  blackhole<A130<T>>();
  blackhole<A131<T>>();
  blackhole<A132<T>>();
  blackhole<A133<T>>();
  blackhole<A134<T>>();
  blackhole<A135<T>>();
  blackhole<A136<T>>();
  blackhole<A137<T>>();
  blackhole<A138<T>>();
  blackhole<A139<T>>();
  blackhole<A140<T>>();
  blackhole<A141<T>>();
  blackhole<A142<T>>();
  blackhole<A143<T>>();
  blackhole<A144<T>>();
  blackhole<A145<T>>();
  blackhole<A146<T>>();
  blackhole<A147<T>>();
  blackhole<A148<T>>();
  blackhole<A149<T>>();
  blackhole<A150<T>>();
  blackhole<A151<T>>();
  blackhole<A152<T>>();
  blackhole<A153<T>>();
  blackhole<A154<T>>();
  blackhole<A155<T>>();
  blackhole<A156<T>>();
  blackhole<A157<T>>();
  blackhole<A158<T>>();
  blackhole<A159<T>>();
  blackhole<A160<T>>();
  blackhole<A161<T>>();
  blackhole<A162<T>>();
  blackhole<A163<T>>();
  blackhole<A164<T>>();
  blackhole<A165<T>>();
  blackhole<A166<T>>();
  blackhole<A167<T>>();
  blackhole<A168<T>>();
  blackhole<A169<T>>();
  blackhole<A170<T>>();
  blackhole<A171<T>>();
  blackhole<A172<T>>();
  blackhole<A173<T>>();
  blackhole<A174<T>>();
  blackhole<A175<T>>();
  blackhole<A176<T>>();
  blackhole<A177<T>>();
  blackhole<A178<T>>();
  blackhole<A179<T>>();
  blackhole<A180<T>>();
  blackhole<A181<T>>();
  blackhole<A182<T>>();
  blackhole<A183<T>>();
  blackhole<A184<T>>();
  blackhole<A185<T>>();
  blackhole<A186<T>>();
  blackhole<A187<T>>();
  blackhole<A188<T>>();
  blackhole<A189<T>>();
  blackhole<A190<T>>();
  blackhole<A191<T>>();
  blackhole<A192<T>>();
  blackhole<A193<T>>();
  blackhole<A194<T>>();
  blackhole<A195<T>>();
  blackhole<A196<T>>();
  blackhole<A197<T>>();
  blackhole<A198<T>>();
  blackhole<A199<T>>();
  blackhole<A200<T>>();
  blackhole<A201<T>>();
  blackhole<A202<T>>();
  blackhole<A203<T>>();
  blackhole<A204<T>>();
  blackhole<A205<T>>();
  blackhole<A206<T>>();
  blackhole<A207<T>>();
  blackhole<A208<T>>();
  blackhole<A209<T>>();
  blackhole<A210<T>>();
  blackhole<A211<T>>();
  blackhole<A212<T>>();
  blackhole<A213<T>>();
  blackhole<A214<T>>();
  blackhole<A215<T>>();
  blackhole<A216<T>>();
  blackhole<A217<T>>();
  blackhole<A218<T>>();
  blackhole<A219<T>>();
  blackhole<A220<T>>();
  blackhole<A221<T>>();
  blackhole<A222<T>>();
  blackhole<A223<T>>();
  blackhole<A224<T>>();
  blackhole<A225<T>>();
  blackhole<A226<T>>();
  blackhole<A227<T>>();
  blackhole<A228<T>>();
  blackhole<A229<T>>();
  blackhole<A230<T>>();
  blackhole<A231<T>>();
  blackhole<A232<T>>();
  blackhole<A233<T>>();
  blackhole<A234<T>>();
  blackhole<A235<T>>();
  blackhole<A236<T>>();
  blackhole<A237<T>>();
  blackhole<A238<T>>();
  blackhole<A239<T>>();
  blackhole<A240<T>>();
  blackhole<A241<T>>();
  blackhole<A242<T>>();
  blackhole<A243<T>>();
  blackhole<A244<T>>();
  blackhole<A245<T>>();
  blackhole<A246<T>>();
  blackhole<A247<T>>();
  blackhole<A248<T>>();
  blackhole<A249<T>>();
  blackhole<A250<T>>();
  blackhole<A251<T>>();
  blackhole<A252<T>>();
  blackhole<A253<T>>();
  blackhole<A254<T>>();
  blackhole<A255<T>>();
  blackhole<A256<T>>();
  blackhole<A257<T>>();
  blackhole<A258<T>>();
  blackhole<A259<T>>();
  blackhole<A260<T>>();
  blackhole<A261<T>>();
  blackhole<A262<T>>();
  blackhole<A263<T>>();
  blackhole<A264<T>>();
  blackhole<A265<T>>();
  blackhole<A266<T>>();
  blackhole<A267<T>>();
  blackhole<A268<T>>();
  blackhole<A269<T>>();
  blackhole<A270<T>>();
  blackhole<A271<T>>();
  blackhole<A272<T>>();
  blackhole<A273<T>>();
  blackhole<A274<T>>();
  blackhole<A275<T>>();
  blackhole<A276<T>>();
  blackhole<A277<T>>();
  blackhole<A278<T>>();
  blackhole<A279<T>>();
  blackhole<A280<T>>();
  blackhole<A281<T>>();
  blackhole<A282<T>>();
  blackhole<A283<T>>();
  blackhole<A284<T>>();
  blackhole<A285<T>>();
  blackhole<A286<T>>();
  blackhole<A287<T>>();
  blackhole<A288<T>>();
  blackhole<A289<T>>();
  blackhole<A290<T>>();
  blackhole<A291<T>>();
  blackhole<A292<T>>();
  blackhole<A293<T>>();
  blackhole<A294<T>>();
  blackhole<A295<T>>();
  blackhole<A296<T>>();
  blackhole<A297<T>>();
  blackhole<A298<T>>();
  blackhole<A299<T>>();
  blackhole<A300<T>>();
  blackhole<A301<T>>();
  blackhole<A302<T>>();
  blackhole<A303<T>>();
  blackhole<A304<T>>();
  blackhole<A305<T>>();
  blackhole<A306<T>>();
  blackhole<A307<T>>();
  blackhole<A308<T>>();
  blackhole<A309<T>>();
  blackhole<A310<T>>();
  blackhole<A311<T>>();
  blackhole<A312<T>>();
  blackhole<A313<T>>();
  blackhole<A314<T>>();
  blackhole<A315<T>>();
  blackhole<A316<T>>();
  blackhole<A317<T>>();
  blackhole<A318<T>>();
  blackhole<A319<T>>();
  blackhole<A320<T>>();
  blackhole<A321<T>>();
  blackhole<A322<T>>();
  blackhole<A323<T>>();
  blackhole<A324<T>>();
  blackhole<A325<T>>();
  blackhole<A326<T>>();
  blackhole<A327<T>>();
  blackhole<A328<T>>();
  blackhole<A329<T>>();
  blackhole<A330<T>>();
  blackhole<A331<T>>();
  blackhole<A332<T>>();
  blackhole<A333<T>>();
  blackhole<A334<T>>();
  blackhole<A335<T>>();
  blackhole<A336<T>>();
  blackhole<A337<T>>();
  blackhole<A338<T>>();
  blackhole<A339<T>>();
  blackhole<A340<T>>();
  blackhole<A341<T>>();
  blackhole<A342<T>>();
  blackhole<A343<T>>();
  blackhole<A344<T>>();
  blackhole<A345<T>>();
  blackhole<A346<T>>();
  blackhole<A347<T>>();
  blackhole<A348<T>>();
  blackhole<A349<T>>();
  blackhole<A350<T>>();
  blackhole<A351<T>>();
  blackhole<A352<T>>();
  blackhole<A353<T>>();
  blackhole<A354<T>>();
  blackhole<A355<T>>();
  blackhole<A356<T>>();
  blackhole<A357<T>>();
  blackhole<A358<T>>();
  blackhole<A359<T>>();
  blackhole<A360<T>>();
  blackhole<A361<T>>();
  blackhole<A362<T>>();
  blackhole<A363<T>>();
  blackhole<A364<T>>();
  blackhole<A365<T>>();
  blackhole<A366<T>>();
  blackhole<A367<T>>();
  blackhole<A368<T>>();
  blackhole<A369<T>>();
  blackhole<A370<T>>();
  blackhole<A371<T>>();
  blackhole<A372<T>>();
  blackhole<A373<T>>();
  blackhole<A374<T>>();
  blackhole<A375<T>>();
  blackhole<A376<T>>();
  blackhole<A377<T>>();
  blackhole<A378<T>>();
  blackhole<A379<T>>();
  blackhole<A380<T>>();
  blackhole<A381<T>>();
  blackhole<A382<T>>();
  blackhole<A383<T>>();
  blackhole<A384<T>>();
  blackhole<A385<T>>();
  blackhole<A386<T>>();
  blackhole<A387<T>>();
  blackhole<A388<T>>();
  blackhole<A389<T>>();
  blackhole<A390<T>>();
  blackhole<A391<T>>();
  blackhole<A392<T>>();
  blackhole<A393<T>>();
  blackhole<A394<T>>();
  blackhole<A395<T>>();
  blackhole<A396<T>>();
  blackhole<A397<T>>();
  blackhole<A398<T>>();
  blackhole<A399<T>>();
  blackhole<A400<T>>();
  blackhole<A401<T>>();
  blackhole<A402<T>>();
  blackhole<A403<T>>();
  blackhole<A404<T>>();
  blackhole<A405<T>>();
  blackhole<A406<T>>();
  blackhole<A407<T>>();
  blackhole<A408<T>>();
  blackhole<A409<T>>();
  blackhole<A410<T>>();
  blackhole<A411<T>>();
  blackhole<A412<T>>();
  blackhole<A413<T>>();
  blackhole<A414<T>>();
  blackhole<A415<T>>();
  blackhole<A416<T>>();
  blackhole<A417<T>>();
  blackhole<A418<T>>();
  blackhole<A419<T>>();
  blackhole<A420<T>>();
  blackhole<A421<T>>();
  blackhole<A422<T>>();
  blackhole<A423<T>>();
  blackhole<A424<T>>();
  blackhole<A425<T>>();
  blackhole<A426<T>>();
  blackhole<A427<T>>();
  blackhole<A428<T>>();
  blackhole<A429<T>>();
  blackhole<A430<T>>();
  blackhole<A431<T>>();
  blackhole<A432<T>>();
  blackhole<A433<T>>();
  blackhole<A434<T>>();
  blackhole<A435<T>>();
  blackhole<A436<T>>();
  blackhole<A437<T>>();
  blackhole<A438<T>>();
  blackhole<A439<T>>();
  blackhole<A440<T>>();
  blackhole<A441<T>>();
  blackhole<A442<T>>();
  blackhole<A443<T>>();
  blackhole<A444<T>>();
  blackhole<A445<T>>();
  blackhole<A446<T>>();
  blackhole<A447<T>>();
  blackhole<A448<T>>();
  blackhole<A449<T>>();
  blackhole<A450<T>>();
  blackhole<A451<T>>();
  blackhole<A452<T>>();
  blackhole<A453<T>>();
  blackhole<A454<T>>();
  blackhole<A455<T>>();
  blackhole<A456<T>>();
  blackhole<A457<T>>();
  blackhole<A458<T>>();
  blackhole<A459<T>>();
  blackhole<A460<T>>();
  blackhole<A461<T>>();
  blackhole<A462<T>>();
  blackhole<A463<T>>();
  blackhole<A464<T>>();
  blackhole<A465<T>>();
  blackhole<A466<T>>();
  blackhole<A467<T>>();
  blackhole<A468<T>>();
  blackhole<A469<T>>();
  blackhole<A470<T>>();
  blackhole<A471<T>>();
  blackhole<A472<T>>();
  blackhole<A473<T>>();
  blackhole<A474<T>>();
  blackhole<A475<T>>();
  blackhole<A476<T>>();
  blackhole<A477<T>>();
  blackhole<A478<T>>();
  blackhole<A479<T>>();
  blackhole<A480<T>>();
  blackhole<A481<T>>();
  blackhole<A482<T>>();
  blackhole<A483<T>>();
  blackhole<A484<T>>();
  blackhole<A485<T>>();
  blackhole<A486<T>>();
  blackhole<A487<T>>();
  blackhole<A488<T>>();
  blackhole<A489<T>>();
  blackhole<A490<T>>();
  blackhole<A491<T>>();
  blackhole<A492<T>>();
  blackhole<A493<T>>();
  blackhole<A494<T>>();
  blackhole<A495<T>>();
  blackhole<A496<T>>();
  blackhole<A497<T>>();
  blackhole<A498<T>>();
  blackhole<A499<T>>();
  blackhole<A500<T>>();
  blackhole<A501<T>>();
  blackhole<A502<T>>();
  blackhole<A503<T>>();
  blackhole<A504<T>>();
  blackhole<A505<T>>();
  blackhole<A506<T>>();
  blackhole<A507<T>>();
  blackhole<A508<T>>();
  blackhole<A509<T>>();
  blackhole<A510<T>>();
  blackhole<A511<T>>();
  blackhole<A512<T>>();
  blackhole<A513<T>>();
  blackhole<A514<T>>();
  blackhole<A515<T>>();
  blackhole<A516<T>>();
  blackhole<A517<T>>();
  blackhole<A518<T>>();
  blackhole<A519<T>>();
  blackhole<A520<T>>();
  blackhole<A521<T>>();
  blackhole<A522<T>>();
  blackhole<A523<T>>();
  blackhole<A524<T>>();
  blackhole<A525<T>>();
  blackhole<A526<T>>();
  blackhole<A527<T>>();
  blackhole<A528<T>>();
  blackhole<A529<T>>();
  blackhole<A530<T>>();
  blackhole<A531<T>>();
  blackhole<A532<T>>();
  blackhole<A533<T>>();
  blackhole<A534<T>>();
  blackhole<A535<T>>();
  blackhole<A536<T>>();
  blackhole<A537<T>>();
  blackhole<A538<T>>();
  blackhole<A539<T>>();
  blackhole<A540<T>>();
  blackhole<A541<T>>();
  blackhole<A542<T>>();
  blackhole<A543<T>>();
  blackhole<A544<T>>();
  blackhole<A545<T>>();
  blackhole<A546<T>>();
  blackhole<A547<T>>();
  blackhole<A548<T>>();
  blackhole<A549<T>>();
  blackhole<A550<T>>();
  blackhole<A551<T>>();
  blackhole<A552<T>>();
  blackhole<A553<T>>();
  blackhole<A554<T>>();
  blackhole<A555<T>>();
  blackhole<A556<T>>();
  blackhole<A557<T>>();
  blackhole<A558<T>>();
  blackhole<A559<T>>();
  blackhole<A560<T>>();
  blackhole<A561<T>>();
  blackhole<A562<T>>();
  blackhole<A563<T>>();
  blackhole<A564<T>>();
  blackhole<A565<T>>();
  blackhole<A566<T>>();
  blackhole<A567<T>>();
  blackhole<A568<T>>();
  blackhole<A569<T>>();
  blackhole<A570<T>>();
  blackhole<A571<T>>();
  blackhole<A572<T>>();
  blackhole<A573<T>>();
  blackhole<A574<T>>();
  blackhole<A575<T>>();
  blackhole<A576<T>>();
  blackhole<A577<T>>();
  blackhole<A578<T>>();
  blackhole<A579<T>>();
  blackhole<A580<T>>();
  blackhole<A581<T>>();
  blackhole<A582<T>>();
  blackhole<A583<T>>();
  blackhole<A584<T>>();
  blackhole<A585<T>>();
  blackhole<A586<T>>();
  blackhole<A587<T>>();
  blackhole<A588<T>>();
  blackhole<A589<T>>();
  blackhole<A590<T>>();
  blackhole<A591<T>>();
  blackhole<A592<T>>();
  blackhole<A593<T>>();
  blackhole<A594<T>>();
  blackhole<A595<T>>();
  blackhole<A596<T>>();
  blackhole<A597<T>>();
  blackhole<A598<T>>();
  blackhole<A599<T>>();
  blackhole<A600<T>>();
  blackhole<A601<T>>();
  blackhole<A602<T>>();
  blackhole<A603<T>>();
  blackhole<A604<T>>();
  blackhole<A605<T>>();
  blackhole<A606<T>>();
  blackhole<A607<T>>();
  blackhole<A608<T>>();
  blackhole<A609<T>>();
  blackhole<A610<T>>();
  blackhole<A611<T>>();
  blackhole<A612<T>>();
  blackhole<A613<T>>();
  blackhole<A614<T>>();
  blackhole<A615<T>>();
  blackhole<A616<T>>();
  blackhole<A617<T>>();
  blackhole<A618<T>>();
  blackhole<A619<T>>();
  blackhole<A620<T>>();
  blackhole<A621<T>>();
  blackhole<A622<T>>();
  blackhole<A623<T>>();
  blackhole<A624<T>>();
  blackhole<A625<T>>();
  blackhole<A626<T>>();
  blackhole<A627<T>>();
  blackhole<A628<T>>();
  blackhole<A629<T>>();
  blackhole<A630<T>>();
  blackhole<A631<T>>();
  blackhole<A632<T>>();
  blackhole<A633<T>>();
  blackhole<A634<T>>();
  blackhole<A635<T>>();
  blackhole<A636<T>>();
  blackhole<A637<T>>();
  blackhole<A638<T>>();
  blackhole<A639<T>>();
  blackhole<A640<T>>();
  blackhole<A641<T>>();
  blackhole<A642<T>>();
  blackhole<A643<T>>();
  blackhole<A644<T>>();
  blackhole<A645<T>>();
  blackhole<A646<T>>();
  blackhole<A647<T>>();
  blackhole<A648<T>>();
  blackhole<A649<T>>();
  blackhole<A650<T>>();
  blackhole<A651<T>>();
  blackhole<A652<T>>();
  blackhole<A653<T>>();
  blackhole<A654<T>>();
  blackhole<A655<T>>();
  blackhole<A656<T>>();
  blackhole<A657<T>>();
  blackhole<A658<T>>();
  blackhole<A659<T>>();
  blackhole<A660<T>>();
  blackhole<A661<T>>();
  blackhole<A662<T>>();
  blackhole<A663<T>>();
  blackhole<A664<T>>();
  blackhole<A665<T>>();
  blackhole<A666<T>>();
  blackhole<A667<T>>();
  blackhole<A668<T>>();
  blackhole<A669<T>>();
  blackhole<A670<T>>();
  blackhole<A671<T>>();
  blackhole<A672<T>>();
  blackhole<A673<T>>();
  blackhole<A674<T>>();
  blackhole<A675<T>>();
  blackhole<A676<T>>();
  blackhole<A677<T>>();
  blackhole<A678<T>>();
  blackhole<A679<T>>();
  blackhole<A680<T>>();
  blackhole<A681<T>>();
  blackhole<A682<T>>();
  blackhole<A683<T>>();
  blackhole<A684<T>>();
  blackhole<A685<T>>();
  blackhole<A686<T>>();
  blackhole<A687<T>>();
  blackhole<A688<T>>();
  blackhole<A689<T>>();
  blackhole<A690<T>>();
  blackhole<A691<T>>();
  blackhole<A692<T>>();
  blackhole<A693<T>>();
  blackhole<A694<T>>();
  blackhole<A695<T>>();
  blackhole<A696<T>>();
  blackhole<A697<T>>();
  blackhole<A698<T>>();
  blackhole<A699<T>>();
  blackhole<A700<T>>();
  blackhole<A701<T>>();
  blackhole<A702<T>>();
  blackhole<A703<T>>();
  blackhole<A704<T>>();
  blackhole<A705<T>>();
  blackhole<A706<T>>();
  blackhole<A707<T>>();
  blackhole<A708<T>>();
  blackhole<A709<T>>();
  blackhole<A710<T>>();
  blackhole<A711<T>>();
  blackhole<A712<T>>();
  blackhole<A713<T>>();
  blackhole<A714<T>>();
  blackhole<A715<T>>();
  blackhole<A716<T>>();
  blackhole<A717<T>>();
  blackhole<A718<T>>();
  blackhole<A719<T>>();
  blackhole<A720<T>>();
  blackhole<A721<T>>();
  blackhole<A722<T>>();
  blackhole<A723<T>>();
  blackhole<A724<T>>();
  blackhole<A725<T>>();
  blackhole<A726<T>>();
  blackhole<A727<T>>();
  blackhole<A728<T>>();
  blackhole<A729<T>>();
  blackhole<A730<T>>();
  blackhole<A731<T>>();
  blackhole<A732<T>>();
  blackhole<A733<T>>();
  blackhole<A734<T>>();
  blackhole<A735<T>>();
  blackhole<A736<T>>();
  blackhole<A737<T>>();
  blackhole<A738<T>>();
  blackhole<A739<T>>();
  blackhole<A740<T>>();
  blackhole<A741<T>>();
  blackhole<A742<T>>();
  blackhole<A743<T>>();
  blackhole<A744<T>>();
  blackhole<A745<T>>();
  blackhole<A746<T>>();
  blackhole<A747<T>>();
  blackhole<A748<T>>();
  blackhole<A749<T>>();
  blackhole<A750<T>>();
  blackhole<A751<T>>();
  blackhole<A752<T>>();
  blackhole<A753<T>>();
  blackhole<A754<T>>();
  blackhole<A755<T>>();
  blackhole<A756<T>>();
  blackhole<A757<T>>();
  blackhole<A758<T>>();
  blackhole<A759<T>>();
  blackhole<A760<T>>();
  blackhole<A761<T>>();
  blackhole<A762<T>>();
  blackhole<A763<T>>();
  blackhole<A764<T>>();
  blackhole<A765<T>>();
  blackhole<A766<T>>();
  blackhole<A767<T>>();
  blackhole<A768<T>>();
  blackhole<A769<T>>();
  blackhole<A770<T>>();
  blackhole<A771<T>>();
  blackhole<A772<T>>();
  blackhole<A773<T>>();
  blackhole<A774<T>>();
  blackhole<A775<T>>();
  blackhole<A776<T>>();
  blackhole<A777<T>>();
  blackhole<A778<T>>();
  blackhole<A779<T>>();
  blackhole<A780<T>>();
  blackhole<A781<T>>();
  blackhole<A782<T>>();
  blackhole<A783<T>>();
  blackhole<A784<T>>();
  blackhole<A785<T>>();
  blackhole<A786<T>>();
  blackhole<A787<T>>();
  blackhole<A788<T>>();
  blackhole<A789<T>>();
  blackhole<A790<T>>();
  blackhole<A791<T>>();
  blackhole<A792<T>>();
  blackhole<A793<T>>();
  blackhole<A794<T>>();
  blackhole<A795<T>>();
  blackhole<A796<T>>();
  blackhole<A797<T>>();
  blackhole<A798<T>>();
  blackhole<A799<T>>();
  blackhole<A800<T>>();
  blackhole<A801<T>>();
  blackhole<A802<T>>();
  blackhole<A803<T>>();
  blackhole<A804<T>>();
  blackhole<A805<T>>();
  blackhole<A806<T>>();
  blackhole<A807<T>>();
  blackhole<A808<T>>();
  blackhole<A809<T>>();
  blackhole<A810<T>>();
  blackhole<A811<T>>();
  blackhole<A812<T>>();
  blackhole<A813<T>>();
  blackhole<A814<T>>();
  blackhole<A815<T>>();
  blackhole<A816<T>>();
  blackhole<A817<T>>();
  blackhole<A818<T>>();
  blackhole<A819<T>>();
  blackhole<A820<T>>();
  blackhole<A821<T>>();
  blackhole<A822<T>>();
  blackhole<A823<T>>();
  blackhole<A824<T>>();
  blackhole<A825<T>>();
  blackhole<A826<T>>();
  blackhole<A827<T>>();
  blackhole<A828<T>>();
  blackhole<A829<T>>();
  blackhole<A830<T>>();
  blackhole<A831<T>>();
  blackhole<A832<T>>();
  blackhole<A833<T>>();
  blackhole<A834<T>>();
  blackhole<A835<T>>();
  blackhole<A836<T>>();
  blackhole<A837<T>>();
  blackhole<A838<T>>();
  blackhole<A839<T>>();
  blackhole<A840<T>>();
  blackhole<A841<T>>();
  blackhole<A842<T>>();
  blackhole<A843<T>>();
  blackhole<A844<T>>();
  blackhole<A845<T>>();
  blackhole<A846<T>>();
  blackhole<A847<T>>();
  blackhole<A848<T>>();
  blackhole<A849<T>>();
  blackhole<A850<T>>();
  blackhole<A851<T>>();
  blackhole<A852<T>>();
  blackhole<A853<T>>();
  blackhole<A854<T>>();
  blackhole<A855<T>>();
  blackhole<A856<T>>();
  blackhole<A857<T>>();
  blackhole<A858<T>>();
  blackhole<A859<T>>();
  blackhole<A860<T>>();
  blackhole<A861<T>>();
  blackhole<A862<T>>();
  blackhole<A863<T>>();
  blackhole<A864<T>>();
  blackhole<A865<T>>();
  blackhole<A866<T>>();
  blackhole<A867<T>>();
  blackhole<A868<T>>();
  blackhole<A869<T>>();
  blackhole<A870<T>>();
  blackhole<A871<T>>();
  blackhole<A872<T>>();
  blackhole<A873<T>>();
  blackhole<A874<T>>();
  blackhole<A875<T>>();
  blackhole<A876<T>>();
  blackhole<A877<T>>();
  blackhole<A878<T>>();
  blackhole<A879<T>>();
  blackhole<A880<T>>();
  blackhole<A881<T>>();
  blackhole<A882<T>>();
  blackhole<A883<T>>();
  blackhole<A884<T>>();
  blackhole<A885<T>>();
  blackhole<A886<T>>();
  blackhole<A887<T>>();
  blackhole<A888<T>>();
  blackhole<A889<T>>();
  blackhole<A890<T>>();
  blackhole<A891<T>>();
  blackhole<A892<T>>();
  blackhole<A893<T>>();
  blackhole<A894<T>>();
  blackhole<A895<T>>();
  blackhole<A896<T>>();
  blackhole<A897<T>>();
  blackhole<A898<T>>();
  blackhole<A899<T>>();
  blackhole<A900<T>>();
  blackhole<A901<T>>();
  blackhole<A902<T>>();
  blackhole<A903<T>>();
  blackhole<A904<T>>();
  blackhole<A905<T>>();
  blackhole<A906<T>>();
  blackhole<A907<T>>();
  blackhole<A908<T>>();
  blackhole<A909<T>>();
  blackhole<A910<T>>();
  blackhole<A911<T>>();
  blackhole<A912<T>>();
  blackhole<A913<T>>();
  blackhole<A914<T>>();
  blackhole<A915<T>>();
  blackhole<A916<T>>();
  blackhole<A917<T>>();
  blackhole<A918<T>>();
  blackhole<A919<T>>();
  blackhole<A920<T>>();
  blackhole<A921<T>>();
  blackhole<A922<T>>();
  blackhole<A923<T>>();
  blackhole<A924<T>>();
  blackhole<A925<T>>();
  blackhole<A926<T>>();
  blackhole<A927<T>>();
  blackhole<A928<T>>();
  blackhole<A929<T>>();
  blackhole<A930<T>>();
  blackhole<A931<T>>();
  blackhole<A932<T>>();
  blackhole<A933<T>>();
  blackhole<A934<T>>();
  blackhole<A935<T>>();
  blackhole<A936<T>>();
  blackhole<A937<T>>();
  blackhole<A938<T>>();
  blackhole<A939<T>>();
  blackhole<A940<T>>();
  blackhole<A941<T>>();
  blackhole<A942<T>>();
  blackhole<A943<T>>();
  blackhole<A944<T>>();
  blackhole<A945<T>>();
  blackhole<A946<T>>();
  blackhole<A947<T>>();
  blackhole<A948<T>>();
  blackhole<A949<T>>();
  blackhole<A950<T>>();
  blackhole<A951<T>>();
  blackhole<A952<T>>();
  blackhole<A953<T>>();
  blackhole<A954<T>>();
  blackhole<A955<T>>();
  blackhole<A956<T>>();
  blackhole<A957<T>>();
  blackhole<A958<T>>();
  blackhole<A959<T>>();
  blackhole<A960<T>>();
  blackhole<A961<T>>();
  blackhole<A962<T>>();
  blackhole<A963<T>>();
  blackhole<A964<T>>();
  blackhole<A965<T>>();
  blackhole<A966<T>>();
  blackhole<A967<T>>();
  blackhole<A968<T>>();
  blackhole<A969<T>>();
  blackhole<A970<T>>();
  blackhole<A971<T>>();
  blackhole<A972<T>>();
  blackhole<A973<T>>();
  blackhole<A974<T>>();
  blackhole<A975<T>>();
  blackhole<A976<T>>();
  blackhole<A977<T>>();
  blackhole<A978<T>>();
  blackhole<A979<T>>();
  blackhole<A980<T>>();
  blackhole<A981<T>>();
  blackhole<A982<T>>();
  blackhole<A983<T>>();
  blackhole<A984<T>>();
  blackhole<A985<T>>();
  blackhole<A986<T>>();
  blackhole<A987<T>>();
  blackhole<A988<T>>();
  blackhole<A989<T>>();
  blackhole<A990<T>>();
  blackhole<A991<T>>();
  blackhole<A992<T>>();
  blackhole<A993<T>>();
  blackhole<A994<T>>();
  blackhole<A995<T>>();
  blackhole<A996<T>>();
  blackhole<A997<T>>();
  blackhole<A998<T>>();
  blackhole<A999<T>>();
}

class C0 {}

class C1 {}

class C2 {}

class C3 {}

class C4 {}

class C5 {}

class C6 {}

class C7 {}

class C8 {}

class C9 {}

class C10 {}

class C11 {}

class C12 {}

class C13 {}

class C14 {}

class C15 {}

class C16 {}

class C17 {}

class C18 {}

class C19 {}

class C20 {}

class C21 {}

class C22 {}

class C23 {}

class C24 {}

class C25 {}

class C26 {}

class C27 {}

class C28 {}

class C29 {}

class C30 {}

class C31 {}

class C32 {}

class C33 {}

class C34 {}

class C35 {}

class C36 {}

class C37 {}

class C38 {}

class C39 {}

class C40 {}

class C41 {}

class C42 {}

class C43 {}

class C44 {}

class C45 {}

class C46 {}

class C47 {}

class C48 {}

class C49 {}

class C50 {}

class C51 {}

class C52 {}

class C53 {}

class C54 {}

class C55 {}

class C56 {}

class C57 {}

class C58 {}

class C59 {}

class C60 {}

class C61 {}

class C62 {}

class C63 {}

class C64 {}

class C65 {}

class C66 {}

class C67 {}

class C68 {}

class C69 {}

class C70 {}

class C71 {}

class C72 {}

class C73 {}

class C74 {}

class C75 {}

class C76 {}

class C77 {}

class C78 {}

class C79 {}

class C80 {}

class C81 {}

class C82 {}

class C83 {}

class C84 {}

class C85 {}

class C86 {}

class C87 {}

class C88 {}

class C89 {}

class C90 {}

class C91 {}

class C92 {}

class C93 {}

class C94 {}

class C95 {}

class C96 {}

class C97 {}

class C98 {}

class C99 {}

class C100 {}

class C101 {}

class C102 {}

class C103 {}

class C104 {}

class C105 {}

class C106 {}

class C107 {}

class C108 {}

class C109 {}

class C110 {}

class C111 {}

class C112 {}

class C113 {}

class C114 {}

class C115 {}

class C116 {}

class C117 {}

class C118 {}

class C119 {}

class C120 {}

class C121 {}

class C122 {}

class C123 {}

class C124 {}

class C125 {}

class C126 {}

class C127 {}

class C128 {}

class C129 {}

class C130 {}

class C131 {}

class C132 {}

class C133 {}

class C134 {}

class C135 {}

class C136 {}

class C137 {}

class C138 {}

class C139 {}

class C140 {}

class C141 {}

class C142 {}

class C143 {}

class C144 {}

class C145 {}

class C146 {}

class C147 {}

class C148 {}

class C149 {}

class C150 {}

class C151 {}

class C152 {}

class C153 {}

class C154 {}

class C155 {}

class C156 {}

class C157 {}

class C158 {}

class C159 {}

class C160 {}

class C161 {}

class C162 {}

class C163 {}

class C164 {}

class C165 {}

class C166 {}

class C167 {}

class C168 {}

class C169 {}

class C170 {}

class C171 {}

class C172 {}

class C173 {}

class C174 {}

class C175 {}

class C176 {}

class C177 {}

class C178 {}

class C179 {}

class C180 {}

class C181 {}

class C182 {}

class C183 {}

class C184 {}

class C185 {}

class C186 {}

class C187 {}

class C188 {}

class C189 {}

class C190 {}

class C191 {}

class C192 {}

class C193 {}

class C194 {}

class C195 {}

class C196 {}

class C197 {}

class C198 {}

class C199 {}

class C200 {}

class C201 {}

class C202 {}

class C203 {}

class C204 {}

class C205 {}

class C206 {}

class C207 {}

class C208 {}

class C209 {}

class C210 {}

class C211 {}

class C212 {}

class C213 {}

class C214 {}

class C215 {}

class C216 {}

class C217 {}

class C218 {}

class C219 {}

class C220 {}

class C221 {}

class C222 {}

class C223 {}

class C224 {}

class C225 {}

class C226 {}

class C227 {}

class C228 {}

class C229 {}

class C230 {}

class C231 {}

class C232 {}

class C233 {}

class C234 {}

class C235 {}

class C236 {}

class C237 {}

class C238 {}

class C239 {}

class C240 {}

class C241 {}

class C242 {}

class C243 {}

class C244 {}

class C245 {}

class C246 {}

class C247 {}

class C248 {}

class C249 {}

class C250 {}

class C251 {}

class C252 {}

class C253 {}

class C254 {}

class C255 {}

class C256 {}

class C257 {}

class C258 {}

class C259 {}

class C260 {}

class C261 {}

class C262 {}

class C263 {}

class C264 {}

class C265 {}

class C266 {}

class C267 {}

class C268 {}

class C269 {}

class C270 {}

class C271 {}

class C272 {}

class C273 {}

class C274 {}

class C275 {}

class C276 {}

class C277 {}

class C278 {}

class C279 {}

class C280 {}

class C281 {}

class C282 {}

class C283 {}

class C284 {}

class C285 {}

class C286 {}

class C287 {}

class C288 {}

class C289 {}

class C290 {}

class C291 {}

class C292 {}

class C293 {}

class C294 {}

class C295 {}

class C296 {}

class C297 {}

class C298 {}

class C299 {}

class C300 {}

class C301 {}

class C302 {}

class C303 {}

class C304 {}

class C305 {}

class C306 {}

class C307 {}

class C308 {}

class C309 {}

class C310 {}

class C311 {}

class C312 {}

class C313 {}

class C314 {}

class C315 {}

class C316 {}

class C317 {}

class C318 {}

class C319 {}

class C320 {}

class C321 {}

class C322 {}

class C323 {}

class C324 {}

class C325 {}

class C326 {}

class C327 {}

class C328 {}

class C329 {}

class C330 {}

class C331 {}

class C332 {}

class C333 {}

class C334 {}

class C335 {}

class C336 {}

class C337 {}

class C338 {}

class C339 {}

class C340 {}

class C341 {}

class C342 {}

class C343 {}

class C344 {}

class C345 {}

class C346 {}

class C347 {}

class C348 {}

class C349 {}

class C350 {}

class C351 {}

class C352 {}

class C353 {}

class C354 {}

class C355 {}

class C356 {}

class C357 {}

class C358 {}

class C359 {}

class C360 {}

class C361 {}

class C362 {}

class C363 {}

class C364 {}

class C365 {}

class C366 {}

class C367 {}

class C368 {}

class C369 {}

class C370 {}

class C371 {}

class C372 {}

class C373 {}

class C374 {}

class C375 {}

class C376 {}

class C377 {}

class C378 {}

class C379 {}

class C380 {}

class C381 {}

class C382 {}

class C383 {}

class C384 {}

class C385 {}

class C386 {}

class C387 {}

class C388 {}

class C389 {}

class C390 {}

class C391 {}

class C392 {}

class C393 {}

class C394 {}

class C395 {}

class C396 {}

class C397 {}

class C398 {}

class C399 {}

class C400 {}

class C401 {}

class C402 {}

class C403 {}

class C404 {}

class C405 {}

class C406 {}

class C407 {}

class C408 {}

class C409 {}

class C410 {}

class C411 {}

class C412 {}

class C413 {}

class C414 {}

class C415 {}

class C416 {}

class C417 {}

class C418 {}

class C419 {}

class C420 {}

class C421 {}

class C422 {}

class C423 {}

class C424 {}

class C425 {}

class C426 {}

class C427 {}

class C428 {}

class C429 {}

class C430 {}

class C431 {}

class C432 {}

class C433 {}

class C434 {}

class C435 {}

class C436 {}

class C437 {}

class C438 {}

class C439 {}

class C440 {}

class C441 {}

class C442 {}

class C443 {}

class C444 {}

class C445 {}

class C446 {}

class C447 {}

class C448 {}

class C449 {}

class C450 {}

class C451 {}

class C452 {}

class C453 {}

class C454 {}

class C455 {}

class C456 {}

class C457 {}

class C458 {}

class C459 {}

class C460 {}

class C461 {}

class C462 {}

class C463 {}

class C464 {}

class C465 {}

class C466 {}

class C467 {}

class C468 {}

class C469 {}

class C470 {}

class C471 {}

class C472 {}

class C473 {}

class C474 {}

class C475 {}

class C476 {}

class C477 {}

class C478 {}

class C479 {}

class C480 {}

class C481 {}

class C482 {}

class C483 {}

class C484 {}

class C485 {}

class C486 {}

class C487 {}

class C488 {}

class C489 {}

class C490 {}

class C491 {}

class C492 {}

class C493 {}

class C494 {}

class C495 {}

class C496 {}

class C497 {}

class C498 {}

class C499 {}

class C500 {}

class C501 {}

class C502 {}

class C503 {}

class C504 {}

class C505 {}

class C506 {}

class C507 {}

class C508 {}

class C509 {}

class C510 {}

class C511 {}

class C512 {}

class C513 {}

class C514 {}

class C515 {}

class C516 {}

class C517 {}

class C518 {}

class C519 {}

class C520 {}

class C521 {}

class C522 {}

class C523 {}

class C524 {}

class C525 {}

class C526 {}

class C527 {}

class C528 {}

class C529 {}

class C530 {}

class C531 {}

class C532 {}

class C533 {}

class C534 {}

class C535 {}

class C536 {}

class C537 {}

class C538 {}

class C539 {}

class C540 {}

class C541 {}

class C542 {}

class C543 {}

class C544 {}

class C545 {}

class C546 {}

class C547 {}

class C548 {}

class C549 {}

class C550 {}

class C551 {}

class C552 {}

class C553 {}

class C554 {}

class C555 {}

class C556 {}

class C557 {}

class C558 {}

class C559 {}

class C560 {}

class C561 {}

class C562 {}

class C563 {}

class C564 {}

class C565 {}

class C566 {}

class C567 {}

class C568 {}

class C569 {}

class C570 {}

class C571 {}

class C572 {}

class C573 {}

class C574 {}

class C575 {}

class C576 {}

class C577 {}

class C578 {}

class C579 {}

class C580 {}

class C581 {}

class C582 {}

class C583 {}

class C584 {}

class C585 {}

class C586 {}

class C587 {}

class C588 {}

class C589 {}

class C590 {}

class C591 {}

class C592 {}

class C593 {}

class C594 {}

class C595 {}

class C596 {}

class C597 {}

class C598 {}

class C599 {}

class C600 {}

class C601 {}

class C602 {}

class C603 {}

class C604 {}

class C605 {}

class C606 {}

class C607 {}

class C608 {}

class C609 {}

class C610 {}

class C611 {}

class C612 {}

class C613 {}

class C614 {}

class C615 {}

class C616 {}

class C617 {}

class C618 {}

class C619 {}

class C620 {}

class C621 {}

class C622 {}

class C623 {}

class C624 {}

class C625 {}

class C626 {}

class C627 {}

class C628 {}

class C629 {}

class C630 {}

class C631 {}

class C632 {}

class C633 {}

class C634 {}

class C635 {}

class C636 {}

class C637 {}

class C638 {}

class C639 {}

class C640 {}

class C641 {}

class C642 {}

class C643 {}

class C644 {}

class C645 {}

class C646 {}

class C647 {}

class C648 {}

class C649 {}

class C650 {}

class C651 {}

class C652 {}

class C653 {}

class C654 {}

class C655 {}

class C656 {}

class C657 {}

class C658 {}

class C659 {}

class C660 {}

class C661 {}

class C662 {}

class C663 {}

class C664 {}

class C665 {}

class C666 {}

class C667 {}

class C668 {}

class C669 {}

class C670 {}

class C671 {}

class C672 {}

class C673 {}

class C674 {}

class C675 {}

class C676 {}

class C677 {}

class C678 {}

class C679 {}

class C680 {}

class C681 {}

class C682 {}

class C683 {}

class C684 {}

class C685 {}

class C686 {}

class C687 {}

class C688 {}

class C689 {}

class C690 {}

class C691 {}

class C692 {}

class C693 {}

class C694 {}

class C695 {}

class C696 {}

class C697 {}

class C698 {}

class C699 {}

class C700 {}

class C701 {}

class C702 {}

class C703 {}

class C704 {}

class C705 {}

class C706 {}

class C707 {}

class C708 {}

class C709 {}

class C710 {}

class C711 {}

class C712 {}

class C713 {}

class C714 {}

class C715 {}

class C716 {}

class C717 {}

class C718 {}

class C719 {}

class C720 {}

class C721 {}

class C722 {}

class C723 {}

class C724 {}

class C725 {}

class C726 {}

class C727 {}

class C728 {}

class C729 {}

class C730 {}

class C731 {}

class C732 {}

class C733 {}

class C734 {}

class C735 {}

class C736 {}

class C737 {}

class C738 {}

class C739 {}

class C740 {}

class C741 {}

class C742 {}

class C743 {}

class C744 {}

class C745 {}

class C746 {}

class C747 {}

class C748 {}

class C749 {}

class C750 {}

class C751 {}

class C752 {}

class C753 {}

class C754 {}

class C755 {}

class C756 {}

class C757 {}

class C758 {}

class C759 {}

class C760 {}

class C761 {}

class C762 {}

class C763 {}

class C764 {}

class C765 {}

class C766 {}

class C767 {}

class C768 {}

class C769 {}

class C770 {}

class C771 {}

class C772 {}

class C773 {}

class C774 {}

class C775 {}

class C776 {}

class C777 {}

class C778 {}

class C779 {}

class C780 {}

class C781 {}

class C782 {}

class C783 {}

class C784 {}

class C785 {}

class C786 {}

class C787 {}

class C788 {}

class C789 {}

class C790 {}

class C791 {}

class C792 {}

class C793 {}

class C794 {}

class C795 {}

class C796 {}

class C797 {}

class C798 {}

class C799 {}

class C800 {}

class C801 {}

class C802 {}

class C803 {}

class C804 {}

class C805 {}

class C806 {}

class C807 {}

class C808 {}

class C809 {}

class C810 {}

class C811 {}

class C812 {}

class C813 {}

class C814 {}

class C815 {}

class C816 {}

class C817 {}

class C818 {}

class C819 {}

class C820 {}

class C821 {}

class C822 {}

class C823 {}

class C824 {}

class C825 {}

class C826 {}

class C827 {}

class C828 {}

class C829 {}

class C830 {}

class C831 {}

class C832 {}

class C833 {}

class C834 {}

class C835 {}

class C836 {}

class C837 {}

class C838 {}

class C839 {}

class C840 {}

class C841 {}

class C842 {}

class C843 {}

class C844 {}

class C845 {}

class C846 {}

class C847 {}

class C848 {}

class C849 {}

class C850 {}

class C851 {}

class C852 {}

class C853 {}

class C854 {}

class C855 {}

class C856 {}

class C857 {}

class C858 {}

class C859 {}

class C860 {}

class C861 {}

class C862 {}

class C863 {}

class C864 {}

class C865 {}

class C866 {}

class C867 {}

class C868 {}

class C869 {}

class C870 {}

class C871 {}

class C872 {}

class C873 {}

class C874 {}

class C875 {}

class C876 {}

class C877 {}

class C878 {}

class C879 {}

class C880 {}

class C881 {}

class C882 {}

class C883 {}

class C884 {}

class C885 {}

class C886 {}

class C887 {}

class C888 {}

class C889 {}

class C890 {}

class C891 {}

class C892 {}

class C893 {}

class C894 {}

class C895 {}

class C896 {}

class C897 {}

class C898 {}

class C899 {}

class C900 {}

class C901 {}

class C902 {}

class C903 {}

class C904 {}

class C905 {}

class C906 {}

class C907 {}

class C908 {}

class C909 {}

class C910 {}

class C911 {}

class C912 {}

class C913 {}

class C914 {}

class C915 {}

class C916 {}

class C917 {}

class C918 {}

class C919 {}

class C920 {}

class C921 {}

class C922 {}

class C923 {}

class C924 {}

class C925 {}

class C926 {}

class C927 {}

class C928 {}

class C929 {}

class C930 {}

class C931 {}

class C932 {}

class C933 {}

class C934 {}

class C935 {}

class C936 {}

class C937 {}

class C938 {}

class C939 {}

class C940 {}

class C941 {}

class C942 {}

class C943 {}

class C944 {}

class C945 {}

class C946 {}

class C947 {}

class C948 {}

class C949 {}

class C950 {}

class C951 {}

class C952 {}

class C953 {}

class C954 {}

class C955 {}

class C956 {}

class C957 {}

class C958 {}

class C959 {}

class C960 {}

class C961 {}

class C962 {}

class C963 {}

class C964 {}

class C965 {}

class C966 {}

class C967 {}

class C968 {}

class C969 {}

class C970 {}

class C971 {}

class C972 {}

class C973 {}

class C974 {}

class C975 {}

class C976 {}

class C977 {}

class C978 {}

class C979 {}

class C980 {}

class C981 {}

class C982 {}

class C983 {}

class C984 {}

class C985 {}

class C986 {}

class C987 {}

class C988 {}

class C989 {}

class C990 {}

class C991 {}

class C992 {}

class C993 {}

class C994 {}

class C995 {}

class C996 {}

class C997 {}

class C998 {}

class C999 {}

void instantiateMany() {
  D.instantiate<C0>();
  D.instantiate<C1>();
  D.instantiate<C2>();
  D.instantiate<C3>();
  D.instantiate<C4>();
  D.instantiate<C5>();
  D.instantiate<C6>();
  D.instantiate<C7>();
  D.instantiate<C8>();
  D.instantiate<C9>();
  D.instantiate<C10>();
  D.instantiate<C11>();
  D.instantiate<C12>();
  D.instantiate<C13>();
  D.instantiate<C14>();
  D.instantiate<C15>();
  D.instantiate<C16>();
  D.instantiate<C17>();
  D.instantiate<C18>();
  D.instantiate<C19>();
  D.instantiate<C20>();
  D.instantiate<C21>();
  D.instantiate<C22>();
  D.instantiate<C23>();
  D.instantiate<C24>();
  D.instantiate<C25>();
  D.instantiate<C26>();
  D.instantiate<C27>();
  D.instantiate<C28>();
  D.instantiate<C29>();
  D.instantiate<C30>();
  D.instantiate<C31>();
  D.instantiate<C32>();
  D.instantiate<C33>();
  D.instantiate<C34>();
  D.instantiate<C35>();
  D.instantiate<C36>();
  D.instantiate<C37>();
  D.instantiate<C38>();
  D.instantiate<C39>();
  D.instantiate<C40>();
  D.instantiate<C41>();
  D.instantiate<C42>();
  D.instantiate<C43>();
  D.instantiate<C44>();
  D.instantiate<C45>();
  D.instantiate<C46>();
  D.instantiate<C47>();
  D.instantiate<C48>();
  D.instantiate<C49>();
  D.instantiate<C50>();
  D.instantiate<C51>();
  D.instantiate<C52>();
  D.instantiate<C53>();
  D.instantiate<C54>();
  D.instantiate<C55>();
  D.instantiate<C56>();
  D.instantiate<C57>();
  D.instantiate<C58>();
  D.instantiate<C59>();
  D.instantiate<C60>();
  D.instantiate<C61>();
  D.instantiate<C62>();
  D.instantiate<C63>();
  D.instantiate<C64>();
  D.instantiate<C65>();
  D.instantiate<C66>();
  D.instantiate<C67>();
  D.instantiate<C68>();
  D.instantiate<C69>();
  D.instantiate<C70>();
  D.instantiate<C71>();
  D.instantiate<C72>();
  D.instantiate<C73>();
  D.instantiate<C74>();
  D.instantiate<C75>();
  D.instantiate<C76>();
  D.instantiate<C77>();
  D.instantiate<C78>();
  D.instantiate<C79>();
  D.instantiate<C80>();
  D.instantiate<C81>();
  D.instantiate<C82>();
  D.instantiate<C83>();
  D.instantiate<C84>();
  D.instantiate<C85>();
  D.instantiate<C86>();
  D.instantiate<C87>();
  D.instantiate<C88>();
  D.instantiate<C89>();
  D.instantiate<C90>();
  D.instantiate<C91>();
  D.instantiate<C92>();
  D.instantiate<C93>();
  D.instantiate<C94>();
  D.instantiate<C95>();
  D.instantiate<C96>();
  D.instantiate<C97>();
  D.instantiate<C98>();
  D.instantiate<C99>();
  D.instantiate<C100>();
  D.instantiate<C101>();
  D.instantiate<C102>();
  D.instantiate<C103>();
  D.instantiate<C104>();
  D.instantiate<C105>();
  D.instantiate<C106>();
  D.instantiate<C107>();
  D.instantiate<C108>();
  D.instantiate<C109>();
  D.instantiate<C110>();
  D.instantiate<C111>();
  D.instantiate<C112>();
  D.instantiate<C113>();
  D.instantiate<C114>();
  D.instantiate<C115>();
  D.instantiate<C116>();
  D.instantiate<C117>();
  D.instantiate<C118>();
  D.instantiate<C119>();
  D.instantiate<C120>();
  D.instantiate<C121>();
  D.instantiate<C122>();
  D.instantiate<C123>();
  D.instantiate<C124>();
  D.instantiate<C125>();
  D.instantiate<C126>();
  D.instantiate<C127>();
  D.instantiate<C128>();
  D.instantiate<C129>();
  D.instantiate<C130>();
  D.instantiate<C131>();
  D.instantiate<C132>();
  D.instantiate<C133>();
  D.instantiate<C134>();
  D.instantiate<C135>();
  D.instantiate<C136>();
  D.instantiate<C137>();
  D.instantiate<C138>();
  D.instantiate<C139>();
  D.instantiate<C140>();
  D.instantiate<C141>();
  D.instantiate<C142>();
  D.instantiate<C143>();
  D.instantiate<C144>();
  D.instantiate<C145>();
  D.instantiate<C146>();
  D.instantiate<C147>();
  D.instantiate<C148>();
  D.instantiate<C149>();
  D.instantiate<C150>();
  D.instantiate<C151>();
  D.instantiate<C152>();
  D.instantiate<C153>();
  D.instantiate<C154>();
  D.instantiate<C155>();
  D.instantiate<C156>();
  D.instantiate<C157>();
  D.instantiate<C158>();
  D.instantiate<C159>();
  D.instantiate<C160>();
  D.instantiate<C161>();
  D.instantiate<C162>();
  D.instantiate<C163>();
  D.instantiate<C164>();
  D.instantiate<C165>();
  D.instantiate<C166>();
  D.instantiate<C167>();
  D.instantiate<C168>();
  D.instantiate<C169>();
  D.instantiate<C170>();
  D.instantiate<C171>();
  D.instantiate<C172>();
  D.instantiate<C173>();
  D.instantiate<C174>();
  D.instantiate<C175>();
  D.instantiate<C176>();
  D.instantiate<C177>();
  D.instantiate<C178>();
  D.instantiate<C179>();
  D.instantiate<C180>();
  D.instantiate<C181>();
  D.instantiate<C182>();
  D.instantiate<C183>();
  D.instantiate<C184>();
  D.instantiate<C185>();
  D.instantiate<C186>();
  D.instantiate<C187>();
  D.instantiate<C188>();
  D.instantiate<C189>();
  D.instantiate<C190>();
  D.instantiate<C191>();
  D.instantiate<C192>();
  D.instantiate<C193>();
  D.instantiate<C194>();
  D.instantiate<C195>();
  D.instantiate<C196>();
  D.instantiate<C197>();
  D.instantiate<C198>();
  D.instantiate<C199>();
  D.instantiate<C200>();
  D.instantiate<C201>();
  D.instantiate<C202>();
  D.instantiate<C203>();
  D.instantiate<C204>();
  D.instantiate<C205>();
  D.instantiate<C206>();
  D.instantiate<C207>();
  D.instantiate<C208>();
  D.instantiate<C209>();
  D.instantiate<C210>();
  D.instantiate<C211>();
  D.instantiate<C212>();
  D.instantiate<C213>();
  D.instantiate<C214>();
  D.instantiate<C215>();
  D.instantiate<C216>();
  D.instantiate<C217>();
  D.instantiate<C218>();
  D.instantiate<C219>();
  D.instantiate<C220>();
  D.instantiate<C221>();
  D.instantiate<C222>();
  D.instantiate<C223>();
  D.instantiate<C224>();
  D.instantiate<C225>();
  D.instantiate<C226>();
  D.instantiate<C227>();
  D.instantiate<C228>();
  D.instantiate<C229>();
  D.instantiate<C230>();
  D.instantiate<C231>();
  D.instantiate<C232>();
  D.instantiate<C233>();
  D.instantiate<C234>();
  D.instantiate<C235>();
  D.instantiate<C236>();
  D.instantiate<C237>();
  D.instantiate<C238>();
  D.instantiate<C239>();
  D.instantiate<C240>();
  D.instantiate<C241>();
  D.instantiate<C242>();
  D.instantiate<C243>();
  D.instantiate<C244>();
  D.instantiate<C245>();
  D.instantiate<C246>();
  D.instantiate<C247>();
  D.instantiate<C248>();
  D.instantiate<C249>();
  D.instantiate<C250>();
  D.instantiate<C251>();
  D.instantiate<C252>();
  D.instantiate<C253>();
  D.instantiate<C254>();
  D.instantiate<C255>();
  D.instantiate<C256>();
  D.instantiate<C257>();
  D.instantiate<C258>();
  D.instantiate<C259>();
  D.instantiate<C260>();
  D.instantiate<C261>();
  D.instantiate<C262>();
  D.instantiate<C263>();
  D.instantiate<C264>();
  D.instantiate<C265>();
  D.instantiate<C266>();
  D.instantiate<C267>();
  D.instantiate<C268>();
  D.instantiate<C269>();
  D.instantiate<C270>();
  D.instantiate<C271>();
  D.instantiate<C272>();
  D.instantiate<C273>();
  D.instantiate<C274>();
  D.instantiate<C275>();
  D.instantiate<C276>();
  D.instantiate<C277>();
  D.instantiate<C278>();
  D.instantiate<C279>();
  D.instantiate<C280>();
  D.instantiate<C281>();
  D.instantiate<C282>();
  D.instantiate<C283>();
  D.instantiate<C284>();
  D.instantiate<C285>();
  D.instantiate<C286>();
  D.instantiate<C287>();
  D.instantiate<C288>();
  D.instantiate<C289>();
  D.instantiate<C290>();
  D.instantiate<C291>();
  D.instantiate<C292>();
  D.instantiate<C293>();
  D.instantiate<C294>();
  D.instantiate<C295>();
  D.instantiate<C296>();
  D.instantiate<C297>();
  D.instantiate<C298>();
  D.instantiate<C299>();
  D.instantiate<C300>();
  D.instantiate<C301>();
  D.instantiate<C302>();
  D.instantiate<C303>();
  D.instantiate<C304>();
  D.instantiate<C305>();
  D.instantiate<C306>();
  D.instantiate<C307>();
  D.instantiate<C308>();
  D.instantiate<C309>();
  D.instantiate<C310>();
  D.instantiate<C311>();
  D.instantiate<C312>();
  D.instantiate<C313>();
  D.instantiate<C314>();
  D.instantiate<C315>();
  D.instantiate<C316>();
  D.instantiate<C317>();
  D.instantiate<C318>();
  D.instantiate<C319>();
  D.instantiate<C320>();
  D.instantiate<C321>();
  D.instantiate<C322>();
  D.instantiate<C323>();
  D.instantiate<C324>();
  D.instantiate<C325>();
  D.instantiate<C326>();
  D.instantiate<C327>();
  D.instantiate<C328>();
  D.instantiate<C329>();
  D.instantiate<C330>();
  D.instantiate<C331>();
  D.instantiate<C332>();
  D.instantiate<C333>();
  D.instantiate<C334>();
  D.instantiate<C335>();
  D.instantiate<C336>();
  D.instantiate<C337>();
  D.instantiate<C338>();
  D.instantiate<C339>();
  D.instantiate<C340>();
  D.instantiate<C341>();
  D.instantiate<C342>();
  D.instantiate<C343>();
  D.instantiate<C344>();
  D.instantiate<C345>();
  D.instantiate<C346>();
  D.instantiate<C347>();
  D.instantiate<C348>();
  D.instantiate<C349>();
  D.instantiate<C350>();
  D.instantiate<C351>();
  D.instantiate<C352>();
  D.instantiate<C353>();
  D.instantiate<C354>();
  D.instantiate<C355>();
  D.instantiate<C356>();
  D.instantiate<C357>();
  D.instantiate<C358>();
  D.instantiate<C359>();
  D.instantiate<C360>();
  D.instantiate<C361>();
  D.instantiate<C362>();
  D.instantiate<C363>();
  D.instantiate<C364>();
  D.instantiate<C365>();
  D.instantiate<C366>();
  D.instantiate<C367>();
  D.instantiate<C368>();
  D.instantiate<C369>();
  D.instantiate<C370>();
  D.instantiate<C371>();
  D.instantiate<C372>();
  D.instantiate<C373>();
  D.instantiate<C374>();
  D.instantiate<C375>();
  D.instantiate<C376>();
  D.instantiate<C377>();
  D.instantiate<C378>();
  D.instantiate<C379>();
  D.instantiate<C380>();
  D.instantiate<C381>();
  D.instantiate<C382>();
  D.instantiate<C383>();
  D.instantiate<C384>();
  D.instantiate<C385>();
  D.instantiate<C386>();
  D.instantiate<C387>();
  D.instantiate<C388>();
  D.instantiate<C389>();
  D.instantiate<C390>();
  D.instantiate<C391>();
  D.instantiate<C392>();
  D.instantiate<C393>();
  D.instantiate<C394>();
  D.instantiate<C395>();
  D.instantiate<C396>();
  D.instantiate<C397>();
  D.instantiate<C398>();
  D.instantiate<C399>();
  D.instantiate<C400>();
  D.instantiate<C401>();
  D.instantiate<C402>();
  D.instantiate<C403>();
  D.instantiate<C404>();
  D.instantiate<C405>();
  D.instantiate<C406>();
  D.instantiate<C407>();
  D.instantiate<C408>();
  D.instantiate<C409>();
  D.instantiate<C410>();
  D.instantiate<C411>();
  D.instantiate<C412>();
  D.instantiate<C413>();
  D.instantiate<C414>();
  D.instantiate<C415>();
  D.instantiate<C416>();
  D.instantiate<C417>();
  D.instantiate<C418>();
  D.instantiate<C419>();
  D.instantiate<C420>();
  D.instantiate<C421>();
  D.instantiate<C422>();
  D.instantiate<C423>();
  D.instantiate<C424>();
  D.instantiate<C425>();
  D.instantiate<C426>();
  D.instantiate<C427>();
  D.instantiate<C428>();
  D.instantiate<C429>();
  D.instantiate<C430>();
  D.instantiate<C431>();
  D.instantiate<C432>();
  D.instantiate<C433>();
  D.instantiate<C434>();
  D.instantiate<C435>();
  D.instantiate<C436>();
  D.instantiate<C437>();
  D.instantiate<C438>();
  D.instantiate<C439>();
  D.instantiate<C440>();
  D.instantiate<C441>();
  D.instantiate<C442>();
  D.instantiate<C443>();
  D.instantiate<C444>();
  D.instantiate<C445>();
  D.instantiate<C446>();
  D.instantiate<C447>();
  D.instantiate<C448>();
  D.instantiate<C449>();
  D.instantiate<C450>();
  D.instantiate<C451>();
  D.instantiate<C452>();
  D.instantiate<C453>();
  D.instantiate<C454>();
  D.instantiate<C455>();
  D.instantiate<C456>();
  D.instantiate<C457>();
  D.instantiate<C458>();
  D.instantiate<C459>();
  D.instantiate<C460>();
  D.instantiate<C461>();
  D.instantiate<C462>();
  D.instantiate<C463>();
  D.instantiate<C464>();
  D.instantiate<C465>();
  D.instantiate<C466>();
  D.instantiate<C467>();
  D.instantiate<C468>();
  D.instantiate<C469>();
  D.instantiate<C470>();
  D.instantiate<C471>();
  D.instantiate<C472>();
  D.instantiate<C473>();
  D.instantiate<C474>();
  D.instantiate<C475>();
  D.instantiate<C476>();
  D.instantiate<C477>();
  D.instantiate<C478>();
  D.instantiate<C479>();
  D.instantiate<C480>();
  D.instantiate<C481>();
  D.instantiate<C482>();
  D.instantiate<C483>();
  D.instantiate<C484>();
  D.instantiate<C485>();
  D.instantiate<C486>();
  D.instantiate<C487>();
  D.instantiate<C488>();
  D.instantiate<C489>();
  D.instantiate<C490>();
  D.instantiate<C491>();
  D.instantiate<C492>();
  D.instantiate<C493>();
  D.instantiate<C494>();
  D.instantiate<C495>();
  D.instantiate<C496>();
  D.instantiate<C497>();
  D.instantiate<C498>();
  D.instantiate<C499>();
  D.instantiate<C500>();
  D.instantiate<C501>();
  D.instantiate<C502>();
  D.instantiate<C503>();
  D.instantiate<C504>();
  D.instantiate<C505>();
  D.instantiate<C506>();
  D.instantiate<C507>();
  D.instantiate<C508>();
  D.instantiate<C509>();
  D.instantiate<C510>();
  D.instantiate<C511>();
  D.instantiate<C512>();
  D.instantiate<C513>();
  D.instantiate<C514>();
  D.instantiate<C515>();
  D.instantiate<C516>();
  D.instantiate<C517>();
  D.instantiate<C518>();
  D.instantiate<C519>();
  D.instantiate<C520>();
  D.instantiate<C521>();
  D.instantiate<C522>();
  D.instantiate<C523>();
  D.instantiate<C524>();
  D.instantiate<C525>();
  D.instantiate<C526>();
  D.instantiate<C527>();
  D.instantiate<C528>();
  D.instantiate<C529>();
  D.instantiate<C530>();
  D.instantiate<C531>();
  D.instantiate<C532>();
  D.instantiate<C533>();
  D.instantiate<C534>();
  D.instantiate<C535>();
  D.instantiate<C536>();
  D.instantiate<C537>();
  D.instantiate<C538>();
  D.instantiate<C539>();
  D.instantiate<C540>();
  D.instantiate<C541>();
  D.instantiate<C542>();
  D.instantiate<C543>();
  D.instantiate<C544>();
  D.instantiate<C545>();
  D.instantiate<C546>();
  D.instantiate<C547>();
  D.instantiate<C548>();
  D.instantiate<C549>();
  D.instantiate<C550>();
  D.instantiate<C551>();
  D.instantiate<C552>();
  D.instantiate<C553>();
  D.instantiate<C554>();
  D.instantiate<C555>();
  D.instantiate<C556>();
  D.instantiate<C557>();
  D.instantiate<C558>();
  D.instantiate<C559>();
  D.instantiate<C560>();
  D.instantiate<C561>();
  D.instantiate<C562>();
  D.instantiate<C563>();
  D.instantiate<C564>();
  D.instantiate<C565>();
  D.instantiate<C566>();
  D.instantiate<C567>();
  D.instantiate<C568>();
  D.instantiate<C569>();
  D.instantiate<C570>();
  D.instantiate<C571>();
  D.instantiate<C572>();
  D.instantiate<C573>();
  D.instantiate<C574>();
  D.instantiate<C575>();
  D.instantiate<C576>();
  D.instantiate<C577>();
  D.instantiate<C578>();
  D.instantiate<C579>();
  D.instantiate<C580>();
  D.instantiate<C581>();
  D.instantiate<C582>();
  D.instantiate<C583>();
  D.instantiate<C584>();
  D.instantiate<C585>();
  D.instantiate<C586>();
  D.instantiate<C587>();
  D.instantiate<C588>();
  D.instantiate<C589>();
  D.instantiate<C590>();
  D.instantiate<C591>();
  D.instantiate<C592>();
  D.instantiate<C593>();
  D.instantiate<C594>();
  D.instantiate<C595>();
  D.instantiate<C596>();
  D.instantiate<C597>();
  D.instantiate<C598>();
  D.instantiate<C599>();
  D.instantiate<C600>();
  D.instantiate<C601>();
  D.instantiate<C602>();
  D.instantiate<C603>();
  D.instantiate<C604>();
  D.instantiate<C605>();
  D.instantiate<C606>();
  D.instantiate<C607>();
  D.instantiate<C608>();
  D.instantiate<C609>();
  D.instantiate<C610>();
  D.instantiate<C611>();
  D.instantiate<C612>();
  D.instantiate<C613>();
  D.instantiate<C614>();
  D.instantiate<C615>();
  D.instantiate<C616>();
  D.instantiate<C617>();
  D.instantiate<C618>();
  D.instantiate<C619>();
  D.instantiate<C620>();
  D.instantiate<C621>();
  D.instantiate<C622>();
  D.instantiate<C623>();
  D.instantiate<C624>();
  D.instantiate<C625>();
  D.instantiate<C626>();
  D.instantiate<C627>();
  D.instantiate<C628>();
  D.instantiate<C629>();
  D.instantiate<C630>();
  D.instantiate<C631>();
  D.instantiate<C632>();
  D.instantiate<C633>();
  D.instantiate<C634>();
  D.instantiate<C635>();
  D.instantiate<C636>();
  D.instantiate<C637>();
  D.instantiate<C638>();
  D.instantiate<C639>();
  D.instantiate<C640>();
  D.instantiate<C641>();
  D.instantiate<C642>();
  D.instantiate<C643>();
  D.instantiate<C644>();
  D.instantiate<C645>();
  D.instantiate<C646>();
  D.instantiate<C647>();
  D.instantiate<C648>();
  D.instantiate<C649>();
  D.instantiate<C650>();
  D.instantiate<C651>();
  D.instantiate<C652>();
  D.instantiate<C653>();
  D.instantiate<C654>();
  D.instantiate<C655>();
  D.instantiate<C656>();
  D.instantiate<C657>();
  D.instantiate<C658>();
  D.instantiate<C659>();
  D.instantiate<C660>();
  D.instantiate<C661>();
  D.instantiate<C662>();
  D.instantiate<C663>();
  D.instantiate<C664>();
  D.instantiate<C665>();
  D.instantiate<C666>();
  D.instantiate<C667>();
  D.instantiate<C668>();
  D.instantiate<C669>();
  D.instantiate<C670>();
  D.instantiate<C671>();
  D.instantiate<C672>();
  D.instantiate<C673>();
  D.instantiate<C674>();
  D.instantiate<C675>();
  D.instantiate<C676>();
  D.instantiate<C677>();
  D.instantiate<C678>();
  D.instantiate<C679>();
  D.instantiate<C680>();
  D.instantiate<C681>();
  D.instantiate<C682>();
  D.instantiate<C683>();
  D.instantiate<C684>();
  D.instantiate<C685>();
  D.instantiate<C686>();
  D.instantiate<C687>();
  D.instantiate<C688>();
  D.instantiate<C689>();
  D.instantiate<C690>();
  D.instantiate<C691>();
  D.instantiate<C692>();
  D.instantiate<C693>();
  D.instantiate<C694>();
  D.instantiate<C695>();
  D.instantiate<C696>();
  D.instantiate<C697>();
  D.instantiate<C698>();
  D.instantiate<C699>();
  D.instantiate<C700>();
  D.instantiate<C701>();
  D.instantiate<C702>();
  D.instantiate<C703>();
  D.instantiate<C704>();
  D.instantiate<C705>();
  D.instantiate<C706>();
  D.instantiate<C707>();
  D.instantiate<C708>();
  D.instantiate<C709>();
  D.instantiate<C710>();
  D.instantiate<C711>();
  D.instantiate<C712>();
  D.instantiate<C713>();
  D.instantiate<C714>();
  D.instantiate<C715>();
  D.instantiate<C716>();
  D.instantiate<C717>();
  D.instantiate<C718>();
  D.instantiate<C719>();
  D.instantiate<C720>();
  D.instantiate<C721>();
  D.instantiate<C722>();
  D.instantiate<C723>();
  D.instantiate<C724>();
  D.instantiate<C725>();
  D.instantiate<C726>();
  D.instantiate<C727>();
  D.instantiate<C728>();
  D.instantiate<C729>();
  D.instantiate<C730>();
  D.instantiate<C731>();
  D.instantiate<C732>();
  D.instantiate<C733>();
  D.instantiate<C734>();
  D.instantiate<C735>();
  D.instantiate<C736>();
  D.instantiate<C737>();
  D.instantiate<C738>();
  D.instantiate<C739>();
  D.instantiate<C740>();
  D.instantiate<C741>();
  D.instantiate<C742>();
  D.instantiate<C743>();
  D.instantiate<C744>();
  D.instantiate<C745>();
  D.instantiate<C746>();
  D.instantiate<C747>();
  D.instantiate<C748>();
  D.instantiate<C749>();
  D.instantiate<C750>();
  D.instantiate<C751>();
  D.instantiate<C752>();
  D.instantiate<C753>();
  D.instantiate<C754>();
  D.instantiate<C755>();
  D.instantiate<C756>();
  D.instantiate<C757>();
  D.instantiate<C758>();
  D.instantiate<C759>();
  D.instantiate<C760>();
  D.instantiate<C761>();
  D.instantiate<C762>();
  D.instantiate<C763>();
  D.instantiate<C764>();
  D.instantiate<C765>();
  D.instantiate<C766>();
  D.instantiate<C767>();
  D.instantiate<C768>();
  D.instantiate<C769>();
  D.instantiate<C770>();
  D.instantiate<C771>();
  D.instantiate<C772>();
  D.instantiate<C773>();
  D.instantiate<C774>();
  D.instantiate<C775>();
  D.instantiate<C776>();
  D.instantiate<C777>();
  D.instantiate<C778>();
  D.instantiate<C779>();
  D.instantiate<C780>();
  D.instantiate<C781>();
  D.instantiate<C782>();
  D.instantiate<C783>();
  D.instantiate<C784>();
  D.instantiate<C785>();
  D.instantiate<C786>();
  D.instantiate<C787>();
  D.instantiate<C788>();
  D.instantiate<C789>();
  D.instantiate<C790>();
  D.instantiate<C791>();
  D.instantiate<C792>();
  D.instantiate<C793>();
  D.instantiate<C794>();
  D.instantiate<C795>();
  D.instantiate<C796>();
  D.instantiate<C797>();
  D.instantiate<C798>();
  D.instantiate<C799>();
  D.instantiate<C800>();
  D.instantiate<C801>();
  D.instantiate<C802>();
  D.instantiate<C803>();
  D.instantiate<C804>();
  D.instantiate<C805>();
  D.instantiate<C806>();
  D.instantiate<C807>();
  D.instantiate<C808>();
  D.instantiate<C809>();
  D.instantiate<C810>();
  D.instantiate<C811>();
  D.instantiate<C812>();
  D.instantiate<C813>();
  D.instantiate<C814>();
  D.instantiate<C815>();
  D.instantiate<C816>();
  D.instantiate<C817>();
  D.instantiate<C818>();
  D.instantiate<C819>();
  D.instantiate<C820>();
  D.instantiate<C821>();
  D.instantiate<C822>();
  D.instantiate<C823>();
  D.instantiate<C824>();
  D.instantiate<C825>();
  D.instantiate<C826>();
  D.instantiate<C827>();
  D.instantiate<C828>();
  D.instantiate<C829>();
  D.instantiate<C830>();
  D.instantiate<C831>();
  D.instantiate<C832>();
  D.instantiate<C833>();
  D.instantiate<C834>();
  D.instantiate<C835>();
  D.instantiate<C836>();
  D.instantiate<C837>();
  D.instantiate<C838>();
  D.instantiate<C839>();
  D.instantiate<C840>();
  D.instantiate<C841>();
  D.instantiate<C842>();
  D.instantiate<C843>();
  D.instantiate<C844>();
  D.instantiate<C845>();
  D.instantiate<C846>();
  D.instantiate<C847>();
  D.instantiate<C848>();
  D.instantiate<C849>();
  D.instantiate<C850>();
  D.instantiate<C851>();
  D.instantiate<C852>();
  D.instantiate<C853>();
  D.instantiate<C854>();
  D.instantiate<C855>();
  D.instantiate<C856>();
  D.instantiate<C857>();
  D.instantiate<C858>();
  D.instantiate<C859>();
  D.instantiate<C860>();
  D.instantiate<C861>();
  D.instantiate<C862>();
  D.instantiate<C863>();
  D.instantiate<C864>();
  D.instantiate<C865>();
  D.instantiate<C866>();
  D.instantiate<C867>();
  D.instantiate<C868>();
  D.instantiate<C869>();
  D.instantiate<C870>();
  D.instantiate<C871>();
  D.instantiate<C872>();
  D.instantiate<C873>();
  D.instantiate<C874>();
  D.instantiate<C875>();
  D.instantiate<C876>();
  D.instantiate<C877>();
  D.instantiate<C878>();
  D.instantiate<C879>();
  D.instantiate<C880>();
  D.instantiate<C881>();
  D.instantiate<C882>();
  D.instantiate<C883>();
  D.instantiate<C884>();
  D.instantiate<C885>();
  D.instantiate<C886>();
  D.instantiate<C887>();
  D.instantiate<C888>();
  D.instantiate<C889>();
  D.instantiate<C890>();
  D.instantiate<C891>();
  D.instantiate<C892>();
  D.instantiate<C893>();
  D.instantiate<C894>();
  D.instantiate<C895>();
  D.instantiate<C896>();
  D.instantiate<C897>();
  D.instantiate<C898>();
  D.instantiate<C899>();
  D.instantiate<C900>();
  D.instantiate<C901>();
  D.instantiate<C902>();
  D.instantiate<C903>();
  D.instantiate<C904>();
  D.instantiate<C905>();
  D.instantiate<C906>();
  D.instantiate<C907>();
  D.instantiate<C908>();
  D.instantiate<C909>();
  D.instantiate<C910>();
  D.instantiate<C911>();
  D.instantiate<C912>();
  D.instantiate<C913>();
  D.instantiate<C914>();
  D.instantiate<C915>();
  D.instantiate<C916>();
  D.instantiate<C917>();
  D.instantiate<C918>();
  D.instantiate<C919>();
  D.instantiate<C920>();
  D.instantiate<C921>();
  D.instantiate<C922>();
  D.instantiate<C923>();
  D.instantiate<C924>();
  D.instantiate<C925>();
  D.instantiate<C926>();
  D.instantiate<C927>();
  D.instantiate<C928>();
  D.instantiate<C929>();
  D.instantiate<C930>();
  D.instantiate<C931>();
  D.instantiate<C932>();
  D.instantiate<C933>();
  D.instantiate<C934>();
  D.instantiate<C935>();
  D.instantiate<C936>();
  D.instantiate<C937>();
  D.instantiate<C938>();
  D.instantiate<C939>();
  D.instantiate<C940>();
  D.instantiate<C941>();
  D.instantiate<C942>();
  D.instantiate<C943>();
  D.instantiate<C944>();
  D.instantiate<C945>();
  D.instantiate<C946>();
  D.instantiate<C947>();
  D.instantiate<C948>();
  D.instantiate<C949>();
  D.instantiate<C950>();
  D.instantiate<C951>();
  D.instantiate<C952>();
  D.instantiate<C953>();
  D.instantiate<C954>();
  D.instantiate<C955>();
  D.instantiate<C956>();
  D.instantiate<C957>();
  D.instantiate<C958>();
  D.instantiate<C959>();
  D.instantiate<C960>();
  D.instantiate<C961>();
  D.instantiate<C962>();
  D.instantiate<C963>();
  D.instantiate<C964>();
  D.instantiate<C965>();
  D.instantiate<C966>();
  D.instantiate<C967>();
  D.instantiate<C968>();
  D.instantiate<C969>();
  D.instantiate<C970>();
  D.instantiate<C971>();
  D.instantiate<C972>();
  D.instantiate<C973>();
  D.instantiate<C974>();
  D.instantiate<C975>();
  D.instantiate<C976>();
  D.instantiate<C977>();
  D.instantiate<C978>();
  D.instantiate<C979>();
  D.instantiate<C980>();
  D.instantiate<C981>();
  D.instantiate<C982>();
  D.instantiate<C983>();
  D.instantiate<C984>();
  D.instantiate<C985>();
  D.instantiate<C986>();
  D.instantiate<C987>();
  D.instantiate<C988>();
  D.instantiate<C989>();
  D.instantiate<C990>();
  D.instantiate<C991>();
  D.instantiate<C992>();
  D.instantiate<C993>();
  D.instantiate<C994>();
  D.instantiate<C995>();
  D.instantiate<C996>();
  D.instantiate<C997>();
  D.instantiate<C998>();
  D.instantiate<C999>();
}
