import numpy as np
from ccpy.utilities.active_space import get_active_slices

def update(T, dT, H, H0, shift, system):
    oa, Oa, va, Va, ob, Ob, vb, Vb = get_active_slices(system)

    dT.abb.VvvOoO += (1.0 / 2.0) * (
            +1.0 * np.einsum('mI,AcbmjK->AbcIjK', H.a.oo[oa, Oa], T.abb.VvvooO, optimize=True)
            + 1.0 * np.einsum('MI,AcbMjK->AbcIjK', H.a.oo[Oa, Oa], T.abb.VvvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            +1.0 * np.einsum('mj,AcbImK->AbcIjK', H.b.oo[ob, ob], T.abb.VvvOoO, optimize=True)
            + 1.0 * np.einsum('Mj,AcbIMK->AbcIjK', H.b.oo[Ob, ob], T.abb.VvvOOO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -1.0 * np.einsum('mK,AcbImj->AbcIjK', H.b.oo[ob, Ob], T.abb.VvvOoo, optimize=True)
            + 1.0 * np.einsum('MK,AcbIjM->AbcIjK', H.b.oo[Ob, Ob], T.abb.VvvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -1.0 * np.einsum('AE,EcbIjK->AbcIjK', H.a.vv[Va, Va], T.abb.VvvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            -1.0 * np.einsum('be,AceIjK->AbcIjK', H.b.vv[vb, vb], T.abb.VvvOoO, optimize=True)
            + 1.0 * np.einsum('bE,AEcIjK->AbcIjK', H.b.vv[vb, Vb], T.abb.VVvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -0.5 * np.einsum('mnjK,AcbImn->AbcIjK', H.bb.oooo[ob, ob, ob, Ob], T.abb.VvvOoo, optimize=True)
            - 1.0 * np.einsum('mNjK,AcbImN->AbcIjK', H.bb.oooo[ob, Ob, ob, Ob], T.abb.VvvOoO, optimize=True)
            - 0.5 * np.einsum('MNjK,AcbIMN->AbcIjK', H.bb.oooo[Ob, Ob, ob, Ob], T.abb.VvvOOO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -1.0 * np.einsum('mnIj,AcbmnK->AbcIjK', H.ab.oooo[oa, ob, Oa, ob], T.abb.VvvooO, optimize=True)
            - 1.0 * np.einsum('MnIj,AcbMnK->AbcIjK', H.ab.oooo[Oa, ob, Oa, ob], T.abb.VvvOoO, optimize=True)
            - 1.0 * np.einsum('mNIj,AcbmNK->AbcIjK', H.ab.oooo[oa, Ob, Oa, ob], T.abb.VvvoOO, optimize=True)
            - 1.0 * np.einsum('MNIj,AcbMNK->AbcIjK', H.ab.oooo[Oa, Ob, Oa, ob], T.abb.VvvOOO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            +1.0 * np.einsum('MnIK,AcbMnj->AbcIjK', H.ab.oooo[Oa, ob, Oa, Ob], T.abb.VvvOoo, optimize=True)
            - 1.0 * np.einsum('mNIK,AcbmjN->AbcIjK', H.ab.oooo[oa, Ob, Oa, Ob], T.abb.VvvooO, optimize=True)
            - 1.0 * np.einsum('MNIK,AcbMjN->AbcIjK', H.ab.oooo[Oa, Ob, Oa, Ob], T.abb.VvvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -0.5 * np.einsum('bcef,AfeIjK->AbcIjK', H.bb.vvvv[vb, vb, vb, vb], T.abb.VvvOoO, optimize=True)
            + 1.0 * np.einsum('bcEf,AEfIjK->AbcIjK', H.bb.vvvv[vb, vb, Vb, vb], T.abb.VVvOoO, optimize=True)
            - 0.5 * np.einsum('bcEF,AFEIjK->AbcIjK', H.bb.vvvv[vb, vb, Vb, Vb], T.abb.VVVOoO, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            +1.0 * np.einsum('AbeF,eFcIjK->AbcIjK', H.ab.vvvv[Va, vb, va, Vb], T.abb.vVvOoO, optimize=True)
            - 1.0 * np.einsum('AbEf,EcfIjK->AbcIjK', H.ab.vvvv[Va, vb, Va, vb], T.abb.VvvOoO, optimize=True)
            + 1.0 * np.einsum('AbEF,EFcIjK->AbcIjK', H.ab.vvvv[Va, vb, Va, Vb], T.abb.VVvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -1.0 * np.einsum('AmIE,EcbmjK->AbcIjK', H.aa.voov[Va, oa, Oa, Va], T.abb.VvvooO, optimize=True)
            - 1.0 * np.einsum('AMIE,EcbMjK->AbcIjK', H.aa.voov[Va, Oa, Oa, Va], T.abb.VvvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -1.0 * np.einsum('AmIE,EcbmjK->AbcIjK', H.ab.voov[Va, ob, Oa, Vb], T.bbb.VvvooO, optimize=True)
            + 1.0 * np.einsum('AMIE,EcbjMK->AbcIjK', H.ab.voov[Va, Ob, Oa, Vb], T.bbb.VvvoOO, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            -1.0 * np.einsum('mbej,AecmIK->AbcIjK', H.ab.ovvo[oa, vb, va, ob], T.aab.VvvoOO, optimize=True)
            + 1.0 * np.einsum('Mbej,AecIMK->AbcIjK', H.ab.ovvo[Oa, vb, va, ob], T.aab.VvvOOO, optimize=True)
            + 1.0 * np.einsum('mbEj,EAcmIK->AbcIjK', H.ab.ovvo[oa, vb, Va, ob], T.aab.VVvoOO, optimize=True)
            - 1.0 * np.einsum('MbEj,EAcIMK->AbcIjK', H.ab.ovvo[Oa, vb, Va, ob], T.aab.VVvOOO, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            +1.0 * np.einsum('mbeK,AecmIj->AbcIjK', H.ab.ovvo[oa, vb, va, Ob], T.aab.VvvoOo, optimize=True)
            - 1.0 * np.einsum('MbeK,AecIMj->AbcIjK', H.ab.ovvo[Oa, vb, va, Ob], T.aab.VvvOOo, optimize=True)
            - 1.0 * np.einsum('mbEK,EAcmIj->AbcIjK', H.ab.ovvo[oa, vb, Va, Ob], T.aab.VVvoOo, optimize=True)
            + 1.0 * np.einsum('MbEK,EAcIMj->AbcIjK', H.ab.ovvo[Oa, vb, Va, Ob], T.aab.VVvOOo, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            -1.0 * np.einsum('bmje,AceImK->AbcIjK', H.bb.voov[vb, ob, ob, vb], T.abb.VvvOoO, optimize=True)
            - 1.0 * np.einsum('bMje,AceIMK->AbcIjK', H.bb.voov[vb, Ob, ob, vb], T.abb.VvvOOO, optimize=True)
            + 1.0 * np.einsum('bmjE,AEcImK->AbcIjK', H.bb.voov[vb, ob, ob, Vb], T.abb.VVvOoO, optimize=True)
            + 1.0 * np.einsum('bMjE,AEcIMK->AbcIjK', H.bb.voov[vb, Ob, ob, Vb], T.abb.VVvOOO, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            +1.0 * np.einsum('bmKe,AceImj->AbcIjK', H.bb.voov[vb, ob, Ob, vb], T.abb.VvvOoo, optimize=True)
            - 1.0 * np.einsum('bMKe,AceIjM->AbcIjK', H.bb.voov[vb, Ob, Ob, vb], T.abb.VvvOoO, optimize=True)
            - 1.0 * np.einsum('bmKE,AEcImj->AbcIjK', H.bb.voov[vb, ob, Ob, Vb], T.abb.VVvOoo, optimize=True)
            + 1.0 * np.einsum('bMKE,AEcIjM->AbcIjK', H.bb.voov[vb, Ob, Ob, Vb], T.abb.VVvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (2.0 / 2.0) * (
            +1.0 * np.einsum('mbIe,AcemjK->AbcIjK', H.ab.ovov[oa, vb, Oa, vb], T.abb.VvvooO, optimize=True)
            + 1.0 * np.einsum('MbIe,AceMjK->AbcIjK', H.ab.ovov[Oa, vb, Oa, vb], T.abb.VvvOoO, optimize=True)
            - 1.0 * np.einsum('mbIE,AEcmjK->AbcIjK', H.ab.ovov[oa, vb, Oa, Vb], T.abb.VVvooO, optimize=True)
            - 1.0 * np.einsum('MbIE,AEcMjK->AbcIjK', H.ab.ovov[Oa, vb, Oa, Vb], T.abb.VVvOoO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            +1.0 * np.einsum('AmEj,EcbImK->AbcIjK', H.ab.vovo[Va, ob, Va, ob], T.abb.VvvOoO, optimize=True)
            + 1.0 * np.einsum('AMEj,EcbIMK->AbcIjK', H.ab.vovo[Va, Ob, Va, ob], T.abb.VvvOOO, optimize=True)
    )
    dT.abb.VvvOoO += (1.0 / 2.0) * (
            -1.0 * np.einsum('AmEK,EcbImj->AbcIjK', H.ab.vovo[Va, ob, Va, Ob], T.abb.VvvOoo, optimize=True)
            + 1.0 * np.einsum('AMEK,EcbIjM->AbcIjK', H.ab.vovo[Va, Ob, Va, Ob], T.abb.VvvOoO, optimize=True)
    )

    dT.abb.VvvOoO -= np.transpose(dT.abb.VvvOoO, (0, 2, 1, 3, 4, 5))

    return T, dT