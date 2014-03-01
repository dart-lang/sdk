timing_test(function() {
  at(0, function() {
    assert_styles("#anim1", {'transform':'matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 87.5, 87.5)'});
  }, "Check #anim1 at t=0s");
  at(0, function() {
    assert_styles("#anim2", {'transform':'matrix(0.9701425001453319, 0.24253562503633294, -0.24253562503633294, 0.9701425001453319, 387.5, 87.5)'});
  }, "Check #anim2 at t=0s");
  at(0, function() {
    assert_styles("#anim3", {'transform':'matrix(0.315770091409682, 0.9488357336078364, -0.9488357336078364, 0.315770091409682, 87.5, 287.5)'});
  }, "Check #anim3 at t=0s");
  at(0, function() {
    assert_styles("#anim4", {'transform':'matrix(0.7992672511833444, 0.6009757575691558, -0.6009757575691558, 0.7992672511833444, 387.5, 287.5)'});
  }, "Check #anim4 at t=0s");
  at(1, function() {
    assert_styles("#anim1", {'transform':'matrix(0.9579312613870519, 0.28699773249524424, -0.28699773249524424, 0.9579312613870519, 101.79008483886719, 131.62628173828125)'});
  }, "Check #anim1 at t=1s");
  at(1, function() {
    assert_styles("#anim2", {'transform':'matrix(0.9701425001453319, 0.24253562503633294, -0.24253562503633294, 0.9701425001453319, 387.5, 87.5)'});
  }, "Check #anim2 at t=1s");
  at(1, function() {
    assert_styles("#anim3", {'transform':'matrix(0.00000000000000006123031769111886, -1, 1, 0.00000000000000006123031769111886, 87.5, 237.5)'});
  }, "Check #anim3 at t=1s");
  at(1, function() {
    assert_styles("#anim4", {'transform':'matrix(0.00000000000000006123031769111886, -1, 1, 0.00000000000000006123031769111886, 387.5, 237.5)'});
  }, "Check #anim4 at t=1s");
  at(2, function() {
    assert_styles("#anim1", {'transform':'matrix(0.9986513691327125, 0.051917655276012574, -0.051917655276012574, 0.9986513691327125, 139.31741333007813, 158.8489227294922)'});
  }, "Check #anim1 at t=2s");
  at(2, function() {
    assert_styles("#anim2", {'transform':'matrix(0.9701425001453319, 0.24253562503633294, -0.24253562503633294, 0.9701425001453319, 387.5, 87.5)'});
  }, "Check #anim2 at t=2s");
  at(2, function() {
    assert_styles("#anim3", {'transform':'matrix(1, 0, 0, 1, 137.5, 237.5)'});
  }, "Check #anim3 at t=2s");
  at(2, function() {
    assert_styles("#anim4", {'transform':'matrix(1, 0, 0, 1, 437.5, 237.5)'});
  }, "Check #anim4 at t=2s");
  at(3, function() {
    assert_styles("#anim1", {'transform':'matrix(0.9518379246708917, -0.3066016391968738, 0.3066016391968738, 0.9518379246708917, 185.6825714111328, 158.8485107421875)'});
  }, "Check #anim1 at t=3s");
  at(3, function() {
    assert_styles("#anim2", {'transform':'matrix(0.00000000000000006123031769111886, -1, 1, 0.00000000000000006123031769111886, 387.5, 62.5)'});
  }, "Check #anim2 at t=3s");
  at(3, function() {
    assert_styles("#anim3", {'transform':'matrix(1, 0, 0, 1, 187.5, 237.5)'});
  }, "Check #anim3 at t=3s");
  at(3, function() {
    assert_styles("#anim4", {'transform':'matrix(1, 0, 0, 1, 487.5, 237.5)'});
  }, "Check #anim4 at t=3s");
  at(4, function() {
    assert_styles("#anim1", {'transform':'matrix(0.5877177689498689, -0.8090660195933261, 0.8090660195933261, 0.5877177689498689, 223.1812286376953, 131.5857696533203)'});
  }, "Check #anim1 at t=4s");
  at(4, function() {
    assert_styles("#anim2", {'transform':'matrix(0.00000000000000006123031769111886, -1, 1, 0.00000000000000006123031769111886, 387.5, 37.5)'});
  }, "Check #anim2 at t=4s");
  at(4, function() {
    assert_styles("#anim3", {'transform':'matrix(0.5753043900207572, 0.8179393980135964, -0.8179393980135964, 0.5753043900207572, 216.27749633789063, 278.3883361816406)'});
  }, "Check #anim3 at t=4s");
  at(4, function() {
    assert_styles("#anim4", {'transform':'matrix(0.309, -0.9511, 0.9511, 0.309, 387.5, 287.5)'});
  }, "Check #anim4 at t=4s");
  at(5, function() {
    assert_styles("#anim1", {'transform':'matrix(0.0030534208803044073, -0.9999953382995981, 0.9999953382995981, 0.0030534208803044073, 237.50001525878906, 87.5)'});
  }, "Check #anim1 at t=5s");
  at(5, function() {
    assert_styles("#anim2", {'transform':'matrix(1, 0, 0, 1, 437.5, 37.5)'});
  }, "Check #anim2 at t=5s");
  at(5, function() {
    assert_styles("#anim3", {'transform':'matrix(0.5742821086196931, 0.818657473989775, -0.818657473989775, 0.5742821086196931, 245.05499267578125, 319.27667236328125)'});
  }, "Check #anim3 at t=5s");
  at(5, function() {
    assert_styles("#anim4", {'transform':'matrix(0, -1, 1, 0, 387.5, 287.5)'});
  }, "Check #anim4 at t=5s");
  at(6, function() {
    assert_styles("#anim1", {'transform':'matrix(-0.9580576465567913, -0.2865755500283692, 0.2865755500283692, -0.9580576465567913, 223.20993041992188, 43.373722076416016)'});
  }, "Check #anim1 at t=6s");
  at(6, function() {
    assert_styles("#anim2", {'transform':'matrix(1, 0, 0, 1, 487.5, 37.5)'});
  }, "Check #anim2 at t=6s");
  at(6, function() {
    assert_styles("#anim3", {'transform':'matrix(0.5763239825284185, 0.8172213085588157, -0.8172213085588157, 0.5763239825284185, 273.8324890136719, 360.1650085449219)'});
  }, "Check #anim3 at t=6s");
  at(6, function() {
    assert_styles("#anim4", {'transform':'matrix(-0.309, -0.9511, 0.9511, -0.309, 387.5, 287.5)'});
  }, "Check #anim4 at t=6s");
  at(7, function() {
    assert_styles("#anim1", {'transform':'matrix(-0.9986372991232751, -0.05218759239292748, 0.05218759239292748, -0.9986372991232751, 185.68263244628906, 16.151107788085938)'});
  }, "Check #anim1 at t=7s");
  at(7, function() {
    assert_styles("#anim2", {'transform':'matrix(0.5742821086196931, 0.818657473989775, -0.818657473989775, 0.5742821086196931, 530.666259765625, 98.83250427246094)'});
  }, "Check #anim2 at t=7s");
  at(7, function() {
    assert_styles("#anim3", {'transform':'matrix(-0.9318041877673755, -0.36296136937583534, 0.36296136937583534, -0.9318041877673755, 227.24935913085938, 341.998779296875)'});
  }, "Check #anim3 at t=7s");
  at(7, function() {
    assert_styles("#anim4", {'transform':'matrix(-0.931197578528315, -0.3645148415949653, 0.3645148415949653, -0.931197578528315, 527.2493896484375, 341.998779296875)'});
  }, "Check #anim4 at t=7s");
  at(8, function() {
    assert_styles("#anim1", {'transform':'matrix(-0.9517822672814281, 0.30677437260733537, -0.30677437260733537, -0.9517822672814281, 139.31747436523438, 16.151521682739258)'});
  }, "Check #anim1 at t=8s");
  at(8, function() {
    assert_styles("#anim2", {'transform':'matrix(0.5742821086196931, 0.818657473989775, -0.818657473989775, 0.5742821086196931, 573.83251953125, 160.16500854492188)'});
  }, "Check #anim2 at t=8s");
  at(8, function() {
    assert_styles("#anim3", {'transform':'matrix(-0.932004671541296, -0.36244626115494827, 0.36244626115494827, -0.932004671541296, 180.66622924804688, 323.83251953125)'});
  }, "Check #anim3 at t=8s");
  at(8, function() {
    assert_styles("#anim4", {'transform':'matrix(-0.932004671541296, -0.36244626115494827, 0.36244626115494827, -0.932004671541296, 480.6662292480469, 323.83251953125)'});
  }, "Check #anim4 at t=8s");
  at(9, function() {
    assert_styles("#anim1", {'transform':'matrix(-0.586811457968811, 0.8097236027167038, -0.8097236027167038, -0.586811457968811, 101.81876373291016, 43.41425704956055)'});
  }, "Check #anim1 at t=9s");
  at(9, function() {
    assert_styles("#anim2", {'transform':'matrix(-0.932004671541296, -0.36244626115494827, 0.36244626115494827, -0.932004671541296, 480.6662292480469, 123.83251953125)'});
  }, "Check #anim2 at t=9s");
  at(9, function() {
    assert_styles("#anim3", {'transform':'matrix(-0.9318041877673755, -0.36296136937583534, 0.36296136937583534, -0.9318041877673755, 134.08311462402344, 305.666259765625)'});
  }, "Check #anim3 at t=9s");
  at(9, function() {
    assert_styles("#anim4", {'transform':'matrix(-0.9316028474785737, -0.3634778322949191, 0.3634778322949191, -0.9316028474785737, 434.0831298828125, 305.666259765625)'});
  }, "Check #anim4 at t=9s");
  at(10, function() {
    assert_styles("#anim1", {'transform':'matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 87.5, 87.5)'});
  }, "Check #anim1 at t=10s");
  at(10, function() {
    assert_styles("#anim2", {'transform':'matrix(0.9701425001453319, 0.24253562503633294, -0.24253562503633294, 0.9701425001453319, 387.5, 87.5)'});
  }, "Check #anim2 at t=10s");
  at(10, function() {
    assert_styles("#anim3", {'transform':'matrix(0.315770091409682, 0.9488357336078364, -0.9488357336078364, 0.315770091409682, 87.5, 287.5)'});
  }, "Check #anim3 at t=10s");
  at(10, function() {
    assert_styles("#anim4", {'transform':'matrix(0.7992672511833444, 0.6009757575691558, -0.6009757575691558, 0.7992672511833444, 387.5, 287.5)'});
  }, "Check #anim4 at t=10s");
  at(11, function() {
    assert_styles("#anim1", {'transform':'matrix(0.9579312613870519, 0.28699773249524424, -0.28699773249524424, 0.9579312613870519, 101.79008483886719, 131.62628173828125)'});
  }, "Check #anim1 at t=11s");
  at(11, function() {
    assert_styles("#anim2", {'transform':'matrix(0.9701425001453319, 0.24253562503633294, -0.24253562503633294, 0.9701425001453319, 387.5, 87.5)'});
  }, "Check #anim2 at t=11s");
  at(11, function() {
    assert_styles("#anim3", {'transform':'matrix(0.00000000000000006123031769111886, -1, 1, 0.00000000000000006123031769111886, 87.5, 237.5)'});
  }, "Check #anim3 at t=11s");
  at(11, function() {
    assert_styles("#anim4", {'transform':'matrix(0.00000000000000006123031769111886, -1, 1, 0.00000000000000006123031769111886, 387.5, 237.5)'});
  }, "Check #anim4 at t=11s");
}, "Autogenerated checks.");
