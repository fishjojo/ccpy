import numpy as np
from ccpy.utilities.active_space import get_active_slices

def update(T, dT, H, H0, shift, system):
    oa, Oa, va, Va, ob, Ob, vb, Vb = get_active_slices(system)

    dT.aab.VvvOOO += (2.0 / 2.0) * (
            -1.0 * np.einsum('mI,AbcmJK->AbcIJK', H.a.oo[oa, Oa], T.aab.VvvoOO, optimize=True)
            - 1.0 * np.einsum('MI,AbcMJK->AbcIJK', H.a.oo[Oa, Oa], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            -1.0 * np.einsum('mK,AbcIJm->AbcIJK', H.b.oo[ob, Ob], T.aab.VvvOOo, optimize=True)
            - 1.0 * np.einsum('MK,AbcIJM->AbcIJK', H.b.oo[Ob, Ob], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('AE,EbcIJK->AbcIJK', H.a.vv[Va, Va], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('be,AecIJK->AbcIJK', H.a.vv[va, va], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('bE,AEcIJK->AbcIJK', H.a.vv[va, Va], T.aab.VVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('ce,AbeIJK->AbcIJK', H.b.vv[vb, vb], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('cE,AbEIJK->AbcIJK', H.b.vv[vb, Vb], T.aab.VvVOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +0.5 * np.einsum('mnIJ,AbcmnK->AbcIJK', H.aa.oooo[oa, oa, Oa, Oa], T.aab.VvvooO, optimize=True)
            - 1.0 * np.einsum('MnIJ,AbcnMK->AbcIJK', H.aa.oooo[Oa, oa, Oa, Oa], T.aab.VvvoOO, optimize=True)
            + 0.5 * np.einsum('MNIJ,AbcMNK->AbcIJK', H.aa.oooo[Oa, Oa, Oa, Oa], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (2.0 / 2.0) * (
            -1.0 * np.einsum('mnJK,AbcmIn->AbcIJK', H.ab.oooo[oa, ob, Oa, Ob], T.aab.VvvoOo, optimize=True)
            - 1.0 * np.einsum('mNJK,AbcmIN->AbcIJK', H.ab.oooo[oa, Ob, Oa, Ob], T.aab.VvvoOO, optimize=True)
            + 1.0 * np.einsum('MnJK,AbcIMn->AbcIJK', H.ab.oooo[Oa, ob, Oa, Ob], T.aab.VvvOOo, optimize=True)
            + 1.0 * np.einsum('MNJK,AbcIMN->AbcIJK', H.ab.oooo[Oa, Ob, Oa, Ob], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('AbEf,EfcIJK->AbcIJK', H.aa.vvvv[Va, va, Va, va], T.aab.VvvOOO, optimize=True)
            - 0.5 * np.einsum('AbEF,FEcIJK->AbcIJK', H.aa.vvvv[Va, va, Va, Va], T.aab.VVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('bcef,AefIJK->AbcIJK', H.ab.vvvv[va, vb, va, vb], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('bceF,AeFIJK->AbcIJK', H.ab.vvvv[va, vb, va, Vb], T.aab.VvVOOO, optimize=True)
            - 1.0 * np.einsum('bcEf,EAfIJK->AbcIJK', H.ab.vvvv[va, vb, Va, vb], T.aab.VVvOOO, optimize=True)
            - 1.0 * np.einsum('bcEF,EAFIJK->AbcIJK', H.ab.vvvv[va, vb, Va, Vb], T.aab.VVVOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('AceF,ebFIJK->AbcIJK', H.ab.vvvv[Va, vb, va, Vb], T.aab.vvVOOO, optimize=True)
            + 1.0 * np.einsum('AcEf,EbfIJK->AbcIJK', H.ab.vvvv[Va, vb, Va, vb], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('AcEF,EbFIJK->AbcIJK', H.ab.vvvv[Va, vb, Va, Vb], T.aab.VvVOOO, optimize=True)
    )
    dT.aab.VvvOOO += (2.0 / 2.0) * (
            +1.0 * np.einsum('AmIE,EbcmJK->AbcIJK', H.aa.voov[Va, oa, Oa, Va], T.aab.VvvoOO, optimize=True)
            + 1.0 * np.einsum('AMIE,EbcMJK->AbcIJK', H.aa.voov[Va, Oa, Oa, Va], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (2.0 / 2.0) * (
            +1.0 * np.einsum('bmIe,AecmJK->AbcIJK', H.aa.voov[va, oa, Oa, va], T.aab.VvvoOO, optimize=True)
            + 1.0 * np.einsum('bMIe,AecMJK->AbcIJK', H.aa.voov[va, Oa, Oa, va], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('bmIE,AEcmJK->AbcIJK', H.aa.voov[va, oa, Oa, Va], T.aab.VVvoOO, optimize=True)
            + 1.0 * np.einsum('bMIE,AEcMJK->AbcIJK', H.aa.voov[va, Oa, Oa, Va], T.aab.VVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (2.0 / 2.0) * (
            +1.0 * np.einsum('AmIE,bEcJmK->AbcIJK', H.ab.voov[Va, ob, Oa, Vb], T.abb.vVvOoO, optimize=True)
            + 1.0 * np.einsum('AMIE,bEcJMK->AbcIJK', H.ab.voov[Va, Ob, Oa, Vb], T.abb.vVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (2.0 / 2.0) * (
            +1.0 * np.einsum('bmIe,AceJmK->AbcIJK', H.ab.voov[va, ob, Oa, vb], T.abb.VvvOoO, optimize=True)
            + 1.0 * np.einsum('bMIe,AceJMK->AbcIJK', H.ab.voov[va, Ob, Oa, vb], T.abb.VvvOOO, optimize=True)
            - 1.0 * np.einsum('bmIE,AEcJmK->AbcIJK', H.ab.voov[va, ob, Oa, Vb], T.abb.VVvOoO, optimize=True)
            - 1.0 * np.einsum('bMIE,AEcJMK->AbcIJK', H.ab.voov[va, Ob, Oa, Vb], T.abb.VVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            -1.0 * np.einsum('mceK,AebmIJ->AbcIJK', H.ab.ovvo[oa, vb, va, Ob], T.aaa.VvvoOO, optimize=True)
            - 1.0 * np.einsum('MceK,AebIJM->AbcIJK', H.ab.ovvo[Oa, vb, va, Ob], T.aaa.VvvOOO, optimize=True)
            + 1.0 * np.einsum('mcEK,EAbmIJ->AbcIJK', H.ab.ovvo[oa, vb, Va, Ob], T.aaa.VVvoOO, optimize=True)
            + 1.0 * np.einsum('McEK,EAbIJM->AbcIJK', H.ab.ovvo[Oa, vb, Va, Ob], T.aaa.VVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            +1.0 * np.einsum('cmKe,AbeIJm->AbcIJK', H.bb.voov[vb, ob, Ob, vb], T.aab.VvvOOo, optimize=True)
            + 1.0 * np.einsum('cMKe,AbeIJM->AbcIJK', H.bb.voov[vb, Ob, Ob, vb], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('cmKE,AbEIJm->AbcIJK', H.bb.voov[vb, ob, Ob, Vb], T.aab.VvVOOo, optimize=True)
            + 1.0 * np.einsum('cMKE,AbEIJM->AbcIJK', H.bb.voov[vb, Ob, Ob, Vb], T.aab.VvVOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            -1.0 * np.einsum('AmEK,EbcIJm->AbcIJK', H.ab.vovo[Va, ob, Va, Ob], T.aab.VvvOOo, optimize=True)
            - 1.0 * np.einsum('AMEK,EbcIJM->AbcIJK', H.ab.vovo[Va, Ob, Va, Ob], T.aab.VvvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (1.0 / 2.0) * (
            -1.0 * np.einsum('bmeK,AecIJm->AbcIJK', H.ab.vovo[va, ob, va, Ob], T.aab.VvvOOo, optimize=True)
            - 1.0 * np.einsum('bMeK,AecIJM->AbcIJK', H.ab.vovo[va, Ob, va, Ob], T.aab.VvvOOO, optimize=True)
            - 1.0 * np.einsum('bmEK,AEcIJm->AbcIJK', H.ab.vovo[va, ob, Va, Ob], T.aab.VVvOOo, optimize=True)
            - 1.0 * np.einsum('bMEK,AEcIJM->AbcIJK', H.ab.vovo[va, Ob, Va, Ob], T.aab.VVvOOO, optimize=True)
    )
    dT.aab.VvvOOO += (2.0 / 2.0) * (
            -1.0 * np.einsum('mcIe,AbemJK->AbcIJK', H.ab.ovov[oa, vb, Oa, vb], T.aab.VvvoOO, optimize=True)
            - 1.0 * np.einsum('McIe,AbeMJK->AbcIJK', H.ab.ovov[Oa, vb, Oa, vb], T.aab.VvvOOO, optimize=True)
            - 1.0 * np.einsum('mcIE,AbEmJK->AbcIJK', H.ab.ovov[oa, vb, Oa, Vb], T.aab.VvVoOO, optimize=True)
            - 1.0 * np.einsum('McIE,AbEMJK->AbcIJK', H.ab.ovov[Oa, vb, Oa, Vb], T.aab.VvVOOO, optimize=True)
    )

    dT.aab.VvvOOO -= np.transpose(dT.aab.VvvOOO, (0, 1, 2, 4, 3, 5))

    return T, dT