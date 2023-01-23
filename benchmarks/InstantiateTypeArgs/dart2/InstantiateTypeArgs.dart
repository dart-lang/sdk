// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This benchmark suite measures the overhead of instantiating type arguments,
// with a particular aim of measuring the overhead of the caching mechanism.

// @dart=2.9"

import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
  const Instantiate1().report();
  const Instantiate5().report();
  const Instantiate10().report();
  const Instantiate100().report();
  const Instantiate1000().report();
}

class Instantiate1 extends BenchmarkBase {
  const Instantiate1() : super('InstantiateTypeArgs.Instantiate1');

  // Normalize the cost across the benchmarks by number of instantiations.
  @override
  void report() => emitter.emit(name, measure() / 1);

  @override
  void run() {
    D.instantiate<C0>();
  }
}

class Instantiate5 extends BenchmarkBase {
  const Instantiate5() : super('InstantiateTypeArgs.Instantiate5');

  // Normalize the cost across the benchmarks by number of instantiations.
  @override
  void report() => emitter.emit(name, measure() / 5);

  @override
  void run() {
    D.instantiate<C0>();
    D.instantiate<C1>();
    D.instantiate<C2>();
    D.instantiate<C3>();
    D.instantiate<C4>();
  }
}

class Instantiate10 extends BenchmarkBase {
  const Instantiate10() : super('InstantiateTypeArgs.Instantiate10');

  // Normalize the cost across the benchmarks by number of instantiations.
  @override
  void report() => emitter.emit(name, measure() / 10);

  @override
  void run() {
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
  }
}

class Instantiate100 extends BenchmarkBase {
  const Instantiate100() : super('InstantiateTypeArgs.Instantiate100');

  // Normalize the cost across the benchmarks by number of instantiations.
  @override
  void report() => emitter.emit(name, measure() / 100);

  @override
  void run() {
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
  }
}

class Instantiate1000 extends BenchmarkBase {
  const Instantiate1000() : super('InstantiateTypeArgs.Instantiate1000');

  // Normalize the cost across the benchmarks by number of instantiations.
  @override
  void report() => emitter.emit(name, measure() / 1000);

  @override
  void run() {
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
}

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
void blackhole<T>() => null;

class D<T> {
  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static void instantiate<S>() => blackhole<D<S>>();
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
