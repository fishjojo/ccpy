import numpy as np

def get_deaeom4_intermediates(H, R):

    # Create dictionary to store intermediates, which have spincases that resemble those of the DEA R operator itself
    X = {"ab": {"vo": np.array([0.0]), "ov": np.array([0.0]), "oo": np.array([0.0])},
         "aba": {"vvvv": np.array([0.0]), "vvoo": np.array([0.0]), "vovo": np.array([0.0])},
         "abb": {"vvvv": np.array([0.0]), "vvoo": np.array([0.0]), "ovvo": np.array([0.0])}}

    # x(mb~)
    X["ab"]["ov"] = (
            np.einsum("mbef,ef->mb", H.ab.ovvv, R.ab, optimize=True)
            + 0.5 * np.einsum("mnef,ebfn->mb", H.aa.oovv, R.aba, optimize=True)
            + np.einsum("mnef,ebfn->mb", H.ab.oovv, R.abb, optimize=True)
    )
    # x(am~)
    X["ab"]["vo"] = (
            np.einsum("amef,ef->am", H.ab.vovv, R.ab, optimize=True)
            + 0.5 * np.einsum("nmfe,aefn->am", H.bb.oovv, R.abb, optimize=True)
            + np.einsum("nmfe,aefn->am", H.ab.oovv, R.aba, optimize=True)
    )
    # x(mn~)
    X["ab"]["oo"] = np.einsum("mnef,ef->mn", H.ab.oovv, R.ab, optimize=True)
    # x(ab~ce)
    X["aba"]["vvvv"] = (
            # A(ac) h2a(cnef) r_aba(ab~fn)
            np.einsum("cnef,abfn->abce", H.aa.vovv, R.aba, optimize=True)
            # A(ac) h2b(cn~ef~) r_abb(ab~f~n~)
            + np.einsum("cnef,abfn->abce", H.ab.vovv, R.abb, optimize=True)
            # A(ac) h2b(cb~ef~) r_ab(af~)
            + np.einsum("cbef,af->abce", H.ab.vvvv, R.ab, optimize=True)
            # h2a(acfe) r_ab(fb~)


            + 0.5 * np.einsum("acfe,fb->abce", H.aa.vvvv, R.ab, optimize=True)
            # -1/2 h2a(mnef) r_abaa(ab~cfmn)
            - 0.25 * np.einsum("mnef,abcfmn->abce", H.aa.oovv, R.abaa, optimize=True)
            # -h2b(mn~ef~) r_abab(ab~cf~mn~)
            - 0.5 * np.einsum("mnef,abcfmn->abce", H.ab.oovv, R.abab, optimize=True)
    )
    X["aba"]["vvvv"] -= np.transpose(X["aba"]["vvvv"], (2, 1, 0, 3)) # antisymmetrize A(ac)
    # x(ab~c~e~)
    X["abb"]["vvvv"] = (
            # A(bc) h2b(nc~fe~) r_aba(ab~fn)
            np.einsum("ncfe,abfn->abce", H.ab.ovvv, R.aba, optimize=True)
            # A(bc) h2c(c~n~e~f~) r_abb(ab~f~n~)
            + np.einsum("cnef,abfn->abce", H.bb.vovv, R.abb, optimize=True)
            # h2c(b~c~f~e~) r_ab(af~)
            + 0.5 * np.einsum("bcfe,af->abce", H.bb.vvvv, R.ab, optimize=True)
            # A(bc) h2b(ac~fe~) r_ab(fb~)
            + np.einsum("acfe,fb->abce", H.ab.vvvv, R.ab, optimize=True)
            # -1/2 h2c(mnef) r_abbb(ab~c~f~m~n~)
            - 0.25 * np.einsum("mnef,abcfmn->abce", H.bb.oovv, R.abbb, optimize=True)
            # -h2b(nm~fe~) r_abab(ab~fc~nm~)
            - 0.5 * np.einsum("nmfe,abfcnm->abce", H.ab.oovv, R.abab, optimize=True)
    )
    X["abb"]["vvvv"] -= np.transpose(X["abb"]["vvvv"], (0, 2, 1, 3)) # antisymmetrize A(bc)
    # x(ab~mk)
    X["aba"]["vvoo"] = (
        # h2a(mnkf) r_aba(ab~fn)
        np.einsum("mnkf,abfn->abmk", H.aa.ooov, R.aba, optimize=True)
        # h2b(mn~kf~) r_abb(ab~f~n~)
        + np.einsum("mnkf,abfn->abmk", H.ab.ooov, R.abb, optimize=True)
        # 1/2 h2a(amef) r_aba(eb~fk)
        + 0.5 * np.einsum("amef,ebfk->abmk", H.aa.vovv, R.aba, optimize=True)
        # h2b(mb~fe~) r_aba(ae~fk)
        + np.einsum("mbfe,aefk->abmk", H.ab.ovvv, R.aba, optimize=True)
        # h2a(amfk) r_ab(fb~) -> -h2a(amkf) r_ab(fb~)
        - np.einsum("amkf,fb->abmk", H.aa.voov, R.ab, optimize=True)
        # h2b(mb~kf~) r_ab(af~)
        + np.einsum("mbkf,af->abmk", H.ab.ovov, R.ab, optimize=True)
        # 1/2 h2a(mnef) r_abaa(ab~efkn)
        + 0.5 * np.einsum("mnef,abefkn->abmk", H.aa.oovv, R.abaa, optimize=True)
        # h2b(mn~ef~) r_abab(ab~ef~kn~)
        + np.einsum("mnef,abefkn->abmk", H.ab.oovv, R.abab, optimize=True)
    )
    # x(ab~m~k~)
    X["abb"]["vvoo"] = (
        # h2b(nm~fk~) r_aba(ab~fn)
        np.einsum("nmfk,abfn->abmk", H.ab.oovo, R.aba, optimize=True)
        # h2c(m~n~k~f~) r_abb(ab~f~n~)
        + np.einsum("mnkf,abfn->abmk", H.bb.ooov, R.abb, optimize=True)
        # 1/2 h2c(b~m~e~f~) r_abb(ae~f~k~)
        + 0.5 * np.einsum("bmef,aefk->abmk", H.bb.vovv, R.abb, optimize=True)
        # h2b(am~ef~) r_abb(eb~f~k~)
        + np.einsum("amef,ebfk->abmk", H.ab.vovv, R.abb, optimize=True)
        # h2b(am~fk~) r_ab(fb~)
        + np.einsum("amfk,fb->abmk", H.ab.vovo, R.ab, optimize=True)
        # h2c(b~m~f~k~) r_ab(af~) -> -h2c(b~m~k~f~) r_ab(af~)
        - np.einsum("bmkf,af->abmk", H.bb.voov, R.ab, optimize=True)
        # 1/2 h2c(m~n~e~f~) r_abbb(ab~e~f~k~n~)
        + 0.5 * np.einsum("mnef,abefkn->abmk", H.bb.oovv, R.abbb, optimize=True)
        # h2b(nm~fe~) r_abab(ab~fe~nk~)
        + np.einsum("nmfe,abfenk->abmk", H.ab.oovv, R.abab, optimize=True)
    )
    # x_aba(am~ck)
    X["aba"]["vovo"] = (
        # A(ac) h2b(am~ef~) r_aba(ef~ck)
        np.einsum("amef,efck->amck", H.ab.vovv, R.aba, optimize=True)
        # A(ac) h2b(cm~kf~) r_ab(af~)
        + np.einsum("cmkf,af->amck", H.ab.voov, R.ab, optimize=True)
        # 1/2 h2c(m~n~e~f~) r_abab(ae~cf~kn~)
        + 0.25 * np.einsum("mnef,aecfkn->amck", H.bb.oovv, R.abab, optimize=True)
        # h2b(nm~fe~) r_abaa(ae~cfkn)
        + 0.5 * np.einsum("nmfe,aecfkn->amck", H.ab.oovv, R.abaa, optimize=True)
    )
    X["aba"]["vovo"] -= np.transpose(X["aba"]["vovo"], (2, 1, 0, 3)) # antisymmetrize A(ac)
    # # x_abb(mb~ck)
    # X["aba"]["ovov"] = (
    #     # h2b(mb~fe~) r_aba(fe~ck)
    #     np.einsum("mbfe,feck->mbck", H.ab.ovvv, R.aba, optimize=True)
    #     # h2a(cmkf) r_ab(fb~)
    #     + np.einsum("cmkf,fb->mbck", H.aa.voov, R.ab, optimize=True)
    #     # 1/2 h2a(cmfe) r_aba(eb~fk)
    #     + 0.5 * np.einsum("cmfe,ebfk->mbck", H.aa.vovv, R.aba, optimize=True)
    #     # -h2b(mb~kf~) r_ab(cf~)
    #     - np.einsum("mbkf,cf->mbck", H.ab.ovov, R.ab, optimize=True)
    #     # 1/2 h2a(mnef) r_abaa(eb~cfkn)
    #     + 0.5 * np.einsum("mnef,ebcfkn->mbck", H.aa.oovv, R.abaa, optimize=True)
    #     # h2b(mn~ef~) r_abab(eb~cf~kn~)
    #     + np.einsum("mnef,ebcfkn->mbck", H.ab.oovv, R.abab, optimize=True)
    # )
    # x_abb(mb~d~l~)
    X["abb"]["ovvo"] = (
        # -h2b(mn~el~) r_abb(eb~d~n)
        - 0.5 * np.einsum("mnel,ebdn->mbdl", H.ab.oovo, R.abb, optimize=True)
        # A(bd) h2b(md~ef~) r_abb(eb~f~l~)
        + np.einsum("mdef,ebfl->mbdl", H.ab.ovvv, R.abb, optimize=True)
        # A(bd) h2b(md~el~) r_ab(eb~)
        + np.einsum("mdel,eb->mbdl", H.ab.ovvo, R.ab, optimize=True)
        # 1/2 h2a(mnef) r_abab(eb~fd~nl~)
        + 0.25 * np.einsum("mnef,abfdnl->mbdl", H.aa.oovv, R.abab, optimize=True)
        # h2b(mn~ef~) r_abbb(eb~f~d~n~l~)
        + 0.5 * np.einsum("mnef,ebfdnl->mbdl", H.ab.oovv, R.abbb, optimize=True)
    )
    X["abb"]["ovvo"] -= np.transpose(X["abb"]["ovvo"], (0, 2, 1, 3))  # antisymmetrize A(bd)

    return X
