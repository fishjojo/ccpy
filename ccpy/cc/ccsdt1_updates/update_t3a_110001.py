import numpy as np
from ccpy.utilities.active_space import get_active_slices

def update(T, dT, H, H0, shift, system):
    oa, Oa, va, Va, ob, Ob, vb, Vb = get_active_slices(system)

    dT.aaa.VVvooO += (2.0 / 4.0) * (
            +1.0 * np.einsum('mi,BAcmjK->ABcijK', H.a.oo[oa, oa], T.aaa.VVvooO, optimize=True)
            - 1.0 * np.einsum('Mi,BAcjMK->ABcijK', H.a.oo[Oa, oa], T.aaa.VVvoOO, optimize=True)
    )
    dT.aaa.VVvooO += (1.0 / 4.0) * (
            -1.0 * np.einsum('MK,BAcjiM->ABcijK', H.a.oo[Oa, Oa], T.aaa.VVvooO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            +1.0 * np.einsum('Ae,BceijK->ABcijK', H.a.vv[Va, va], T.aaa.VvvooO, optimize=True)
            - 1.0 * np.einsum('AE,BEcijK->ABcijK', H.a.vv[Va, Va], T.aaa.VVvooO, optimize=True)
    )
    dT.aaa.VVvooO += (1.0 / 4.0) * (
            +1.0 * np.einsum('ce,ABeijK->ABcijK', H.a.vv[va, va], T.aaa.VVvooO, optimize=True)
            + 1.0 * np.einsum('cE,ABEijK->ABcijK', H.a.vv[va, Va], T.aaa.VVVooO, optimize=True)
    )
    dT.aaa.VVvooO += (1.0 / 4.0) * (
            -0.5 * np.einsum('mnij,BAcmnK->ABcijK', H.aa.oooo[oa, oa, oa, oa], T.aaa.VVvooO, optimize=True)
            - 1.0 * np.einsum('mNij,BAcmNK->ABcijK', H.aa.oooo[oa, Oa, oa, oa], T.aaa.VVvoOO, optimize=True)
            - 0.5 * np.einsum('MNij,BAcMNK->ABcijK', H.aa.oooo[Oa, Oa, oa, oa], T.aaa.VVvOOO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            -1.0 * np.einsum('mNKj,BAcmiN->ABcijK', H.aa.oooo[oa, Oa, Oa, oa], T.aaa.VVvooO, optimize=True)
            + 0.5 * np.einsum('MNKj,BAciMN->ABcijK', H.aa.oooo[Oa, Oa, Oa, oa], T.aaa.VVvoOO, optimize=True)
    )
    dT.aaa.VVvooO += (1.0 / 4.0) * (
            -1.0 * np.einsum('ABEf,EcfijK->ABcijK', H.aa.vvvv[Va, Va, Va, va], T.aaa.VvvooO, optimize=True)
            - 0.5 * np.einsum('ABEF,FEcijK->ABcijK', H.aa.vvvv[Va, Va, Va, Va], T.aaa.VVvooO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            +0.5 * np.einsum('cBef,AfeijK->ABcijK', H.aa.vvvv[va, Va, va, va], T.aaa.VvvooO, optimize=True)
            - 1.0 * np.einsum('cBEf,AEfijK->ABcijK', H.aa.vvvv[va, Va, Va, va], T.aaa.VVvooO, optimize=True)
            + 0.5 * np.einsum('cBEF,AFEijK->ABcijK', H.aa.vvvv[va, Va, Va, Va], T.aaa.VVVooO, optimize=True)
    )
    dT.aaa.VVvooO += (4.0 / 4.0) * (
            +1.0 * np.einsum('Amie,BcemjK->ABcijK', H.aa.voov[Va, oa, oa, va], T.aaa.VvvooO, optimize=True)
            - 1.0 * np.einsum('AMie,BcejMK->ABcijK', H.aa.voov[Va, Oa, oa, va], T.aaa.VvvoOO, optimize=True)
            - 1.0 * np.einsum('AmiE,BEcmjK->ABcijK', H.aa.voov[Va, oa, oa, Va], T.aaa.VVvooO, optimize=True)
            + 1.0 * np.einsum('AMiE,BEcjMK->ABcijK', H.aa.voov[Va, Oa, oa, Va], T.aaa.VVvoOO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            +1.0 * np.einsum('cmie,ABemjK->ABcijK', H.aa.voov[va, oa, oa, va], T.aaa.VVvooO, optimize=True)
            - 1.0 * np.einsum('cMie,ABejMK->ABcijK', H.aa.voov[va, Oa, oa, va], T.aaa.VVvoOO, optimize=True)
            + 1.0 * np.einsum('cmiE,ABEmjK->ABcijK', H.aa.voov[va, oa, oa, Va], T.aaa.VVVooO, optimize=True)
            - 1.0 * np.einsum('cMiE,ABEjMK->ABcijK', H.aa.voov[va, Oa, oa, Va], T.aaa.VVVoOO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            -1.0 * np.einsum('AMKe,BcejiM->ABcijK', H.aa.voov[Va, Oa, Oa, va], T.aaa.VvvooO, optimize=True)
            + 1.0 * np.einsum('AMKE,BEcjiM->ABcijK', H.aa.voov[Va, Oa, Oa, Va], T.aaa.VVvooO, optimize=True)
    )
    dT.aaa.VVvooO += (1.0 / 4.0) * (
            -1.0 * np.einsum('cMKe,ABejiM->ABcijK', H.aa.voov[va, Oa, Oa, va], T.aaa.VVvooO, optimize=True)
            - 1.0 * np.einsum('cMKE,ABEjiM->ABcijK', H.aa.voov[va, Oa, Oa, Va], T.aaa.VVVooO, optimize=True)
    )
    dT.aaa.VVvooO += (4.0 / 4.0) * (
            +1.0 * np.einsum('Amie,BcejKm->ABcijK', H.ab.voov[Va, ob, oa, vb], T.aab.VvvoOo, optimize=True)
            + 1.0 * np.einsum('AMie,BcejKM->ABcijK', H.ab.voov[Va, Ob, oa, vb], T.aab.VvvoOO, optimize=True)
            + 1.0 * np.einsum('AmiE,BcEjKm->ABcijK', H.ab.voov[Va, ob, oa, Vb], T.aab.VvVoOo, optimize=True)
            + 1.0 * np.einsum('AMiE,BcEjKM->ABcijK', H.ab.voov[Va, Ob, oa, Vb], T.aab.VvVoOO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            +1.0 * np.einsum('cmie,ABejKm->ABcijK', H.ab.voov[va, ob, oa, vb], T.aab.VVvoOo, optimize=True)
            + 1.0 * np.einsum('cMie,ABejKM->ABcijK', H.ab.voov[va, Ob, oa, vb], T.aab.VVvoOO, optimize=True)
            + 1.0 * np.einsum('cmiE,ABEjKm->ABcijK', H.ab.voov[va, ob, oa, Vb], T.aab.VVVoOo, optimize=True)
            + 1.0 * np.einsum('cMiE,ABEjKM->ABcijK', H.ab.voov[va, Ob, oa, Vb], T.aab.VVVoOO, optimize=True)
    )
    dT.aaa.VVvooO += (2.0 / 4.0) * (
            -1.0 * np.einsum('AMKe,BcejiM->ABcijK', H.ab.voov[Va, Ob, Oa, vb], T.aab.VvvooO, optimize=True)
            - 1.0 * np.einsum('AMKE,BcEjiM->ABcijK', H.ab.voov[Va, Ob, Oa, Vb], T.aab.VvVooO, optimize=True)
    )
    dT.aaa.VVvooO += (1.0 / 4.0) * (
            -1.0 * np.einsum('cMKe,ABejiM->ABcijK', H.ab.voov[va, Ob, Oa, vb], T.aab.VVvooO, optimize=True)
            - 1.0 * np.einsum('cMKE,ABEjiM->ABcijK', H.ab.voov[va, Ob, Oa, Vb], T.aab.VVVooO, optimize=True)
    )

    dT.aaa.VVvooO -= np.transpose(dT.aaa.VVvooO, (1, 0, 2, 3, 4, 5))
    dT.aaa.VVvooO -= np.transpose(dT.aaa.VVvooO, (0, 1, 2, 4, 3, 5))

    return T, dT