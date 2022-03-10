import numpy as np

from pyscf import gto, scf

from ccpy.models.operators import ClusterOperator

from ccpy.models.calculation import Calculation
from ccpy.interfaces.pyscf_tools import load_pyscf_integrals
from ccpy.drivers.driver import cc_driver

from ccpy.hbar.hbar_ccsd import build_hbar_ccsd

from ccpy.utilities.active_space import fill_t3aaa, fill_t3aab, fill_t3abb, fill_t3bbb, get_active_slices,\
    zero_t3aaa_outside_active_space, zero_t3bbb_outside_active_space, zero_t3aab_outside_active_space, zero_t3abb_outside_active_space

from ccpy.cc.ccsdt1_updates import *

def calc_error(dT_act, dT, system):

    def _get_error(x, y):
        error = x - y
        return np.linalg.norm(error.flatten())

    oa, Oa, va, Va, ob, Ob, vb, Vb = get_active_slices(system)

    print('Error in T3.aaa')
    print('-------------------------')
    print("Error in VVVOOO = ", _get_error(dT_act.aaa.VVVOOO, dT.aaa[Va, Va, Va, Oa, Oa, Oa]))
    print("Error in VVvOOO = ", _get_error(dT_act.aaa.VVvOOO, dT.aaa[Va, Va, va, Oa, Oa, Oa]))
    print("Error in VVVoOO = ", _get_error(dT_act.aaa.VVVoOO, dT.aaa[Va, Va, Va, oa, Oa, Oa]))
    print("Error in VVvoOO = ", _get_error(dT_act.aaa.VVvoOO, dT.aaa[Va, Va, va, oa, Oa, Oa]))
    print("Error in VvvOOO = ", _get_error(dT_act.aaa.VvvOOO, dT.aaa[Va, va, va, Oa, Oa, Oa]))
    print("Error in VVVooO = ", _get_error(dT_act.aaa.VVVooO, dT.aaa[Va, Va, Va, oa, oa, Oa]))
    print("Error in VVvooO = ", _get_error(dT_act.aaa.VVvooO, dT.aaa[Va, Va, va, oa, oa, Oa]))
    print("Error in VvvoOO = ", _get_error(dT_act.aaa.VvvoOO, dT.aaa[Va, va, va, oa, Oa, Oa]))
    print("Error in VvvooO = ", _get_error(dT_act.aaa.VvvooO, dT.aaa[Va, va, va, oa, oa, Oa]))

    print('Error in T3.aab')
    print('-------------------------')
    print("Error in VVVOOO = ", _get_error(dT_act.aab.VVVOOO, dT.aab[Va, Va, Vb, Oa, Oa, Ob]))
    # one inactive
    print("Error in VVVOOo = ", _get_error(dT_act.aab.VVVOOo, dT.aab[Va, Va, Vb, Oa, Oa, ob]))
    print("Error in VvVOOO = ", _get_error(dT_act.aab.VvVOOO, dT.aab[Va, va, Vb, Oa, Oa, Ob]))
    print("Error in VVvOOO = ", _get_error(dT_act.aab.VVvOOO, dT.aab[Va, Va, vb, Oa, Oa, Ob]))
    print("Error in VVVoOO = ", _get_error(dT_act.aab.VVVoOO, dT.aab[Va, Va, Vb, oa, Oa, Ob]))
    # two inactive
    print("Error in VVVooO = ", _get_error(dT_act.aab.VVVooO, dT.aab[Va, Va, Vb, oa, oa, Ob]))
    print("Error in VVVoOo = ", _get_error(dT_act.aab.VVVoOo, dT.aab[Va, Va, Vb, oa, Oa, ob]))
    print("Error in vvVOOO = ", _get_error(dT_act.aab.vvVOOO, dT.aab[va, va, Vb, Oa, Oa, Ob]))
    print("Error in VvvOOO = ", _get_error(dT_act.aab.VvvOOO, dT.aab[Va, va, vb, Oa, Oa, Ob]))
    print("Error in VVvoOO = ", _get_error(dT_act.aab.VVvoOO, dT.aab[Va, Va, vb, oa, Oa, Ob]))
    print("Error in VvVOOo = ", _get_error(dT_act.aab.VvVOOo, dT.aab[Va, va, Vb, Oa, Oa, ob]))
    print("Error in VvVoOO = ", _get_error(dT_act.aab.VvVoOO, dT.aab[Va, va, Vb, oa, Oa, Ob]))
    print("Error in VVvOOo = ", _get_error(dT_act.aab.VVvOOo, dT.aab[Va, Va, vb, Oa, Oa, ob]))
    # three inactive
    print("Error in VvVooO = ", _get_error(dT_act.aab.VvVooO, dT.aab[Va, va, Vb, oa, oa, Ob]))
    print("Error in VvVoOo = ", _get_error(dT_act.aab.VvVoOo, dT.aab[Va, va, Vb, oa, Oa, ob]))
    print("Error in VVvooO = ", _get_error(dT_act.aab.VVvooO, dT.aab[Va, Va, vb, oa, oa, Ob]))
    print("Error in VVvoOo = ", _get_error(dT_act.aab.VVvoOo, dT.aab[Va, Va, vb, oa, Oa, ob]))
    print("Error in vvVoOO = ", _get_error(dT_act.aab.vvVoOO, dT.aab[va, va, Vb, oa, Oa, Ob]))
    print("Error in vvVOOo = ", _get_error(dT_act.aab.vvVOOo, dT.aab[va, va, Vb, Oa, Oa, ob]))
    print("Error in VvvoOO = ", _get_error(dT_act.aab.VvvoOO, dT.aab[Va, va, vb, oa, Oa, Ob]))
    print("Error in VvvOOo = ", _get_error(dT_act.aab.VvvOOo, dT.aab[Va, va, vb, Oa, Oa, ob]))
    # four inactive
    print("Error in vvVooO = ", _get_error(dT_act.aab.vvVooO, dT.aab[va, va, Vb, oa, oa, Ob]))
    print("Error in vvVoOo = ", _get_error(dT_act.aab.vvVoOo, dT.aab[va, va, Vb, oa, Oa, ob]))
    print("Error in VvvooO = ", _get_error(dT_act.aab.VvvooO, dT.aab[Va, va, vb, oa, oa, Ob]))
    print("Error in VvvoOo = ", _get_error(dT_act.aab.VvvoOo, dT.aab[Va, va, vb, oa, Oa, ob]))


def calc_full_update_t3a(T, dT, H, H0, shift, system):

    dT.aaa = -(1.0 / 12.0) * np.einsum("mk,abcijm->abcijk", H.a.oo, T.aaa, optimize=True)
    dT.aaa += (1.0 / 12.0) * np.einsum("ce,abeijk->abcijk", H.a.vv, T.aaa, optimize=True)
    dT.aaa += (1.0 / 24.0) * np.einsum("mnij,abcmnk->abcijk", H.aa.oooo, T.aaa, optimize=True)
    dT.aaa += (1.0 / 24.0) * np.einsum("abef,efcijk->abcijk", H.aa.vvvv, T.aaa, optimize=True)
    dT.aaa += 0.25 * np.einsum("cmke,abeijm->abcijk", H.aa.voov, T.aaa, optimize=True)
    dT.aaa += 0.25 * np.einsum("cmke,abeijm->abcijk", H.ab.voov, T.aab, optimize=True)

    dT.aaa -= np.transpose(dT.aaa, (1, 0, 2, 3, 4, 5)) + np.transpose(dT.aaa, (0, 2, 1, 3, 4, 5)) \
           + np.transpose(dT.aaa, (2, 1, 0, 3, 4, 5)) - np.transpose(dT.aaa, (1, 2, 0, 3, 4, 5)) \
           - np.transpose(dT.aaa, (2, 0, 1, 3, 4, 5))

    dT.aaa -= np.transpose(dT.aaa, (0, 1, 2, 4, 3, 5)) + np.transpose(dT.aaa, (0, 1, 2, 3, 5, 4)) \
           + np.transpose(dT.aaa, (0, 1, 2, 5, 4, 3)) - np.transpose(dT.aaa, (0, 1, 2, 4, 5, 3)) \
           - np.transpose(dT.aaa, (0, 1, 2, 5, 3, 4))

    return T, dT

def calc_full_update_t3b(T, dT, H, H0, shift, system):

    # calculate full update
    dT.aab = -0.5 * np.einsum("mi,abcmjk->abcijk", HBar.a.oo, T.aab, optimize=True)
    dT.aab -= 0.25 * np.einsum("mk,abcijm->abcijk", HBar.b.oo, T.aab, optimize=True)
    dT.aab += 0.5 * np.einsum("ae,ebcijk->abcijk", HBar.a.vv, T.aab, optimize=True)
    dT.aab += 0.25 * np.einsum("ce,abeijk->abcijk", HBar.b.vv, T.aab, optimize=True)
    dT.aab += 0.125 * np.einsum("mnij,abcmnk->abcijk", HBar.aa.oooo, T.aab, optimize=True)
    dT.aab += 0.5 * np.einsum("mnjk,abcimn->abcijk", HBar.ab.oooo, T.aab, optimize=True)
    dT.aab += 0.125 * np.einsum("abef,efcijk->abcijk", HBar.aa.vvvv, T.aab, optimize=True)
    dT.aab += 0.5 * np.einsum("bcef,aefijk->abcijk", HBar.ab.vvvv, T.aab, optimize=True)
    dT.aab += np.einsum("amie,ebcmjk->abcijk", HBar.aa.voov, T.aab, optimize=True)
    dT.aab += np.einsum("amie,becjmk->abcijk", HBar.ab.voov, T.abb, optimize=True)
    dT.aab += 0.25 * np.einsum("mcek,abeijm->abcijk", HBar.ab.ovvo, T.aaa, optimize=True)
    dT.aab += 0.25 * np.einsum("cmke,abeijm->abcijk", HBar.bb.voov, T.aab, optimize=True)
    dT.aab -= 0.5 * np.einsum("amek,ebcijm->abcijk", HBar.ab.vovo, T.aab, optimize=True)
    dT.aab -= 0.5 * np.einsum("mcie,abemjk->abcijk", HBar.ab.ovov, T.aab, optimize=True)
    dT.aab -= np.transpose(dT.aab, (1, 0, 2, 3, 4, 5))
    dT.aab -= np.transpose(dT.aab, (0, 1, 2, 4, 3, 5))

    return T, dT

def update_t3a(T, dT, H, H0, shift, system):

    _, dT = update_t3a_111111.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_110111.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_111011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_110011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_100111.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_111001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_100011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_110001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3a_100001.update(T, dT, H, H0, shift, system)

    return T, dT

def update_t3b(T, dT, H, H0, shift, system):

    _, dT = update_t3b_111111.update(T, dT, H, H0, shift, system)
    # one inactive
    _, dT = update_t3b_111110.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_111011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_110111.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_101111.update(T, dT, H, H0, shift, system)
    # two inactive
    _, dT = update_t3b_111001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_111010.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_001111.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_100111.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_110011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_101110.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_101011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_110110.update(T, dT, H, H0, shift, system)
    # three inactive
    _, dT = update_t3b_101001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_101010.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_110001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_110010.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_001011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_001110.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_100011.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_100110.update(T, dT, H, H0, shift, system)
    # four inactive
    _, dT = update_t3b_001001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_001010.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_100001.update(T, dT, H, H0, shift, system)
    _, dT = update_t3b_100010.update(T, dT, H, H0, shift, system)

    return T, dT


if __name__ == "__main__":

    mol = gto.Mole()
    mol.build(
        atom="""F 0.0 0.0 -2.66816
                F 0.0 0.0  2.66816""",
        basis="ccpvdz",
        charge=0,
        spin=0,
        symmetry="D2H",
        cart=True,
        unit='Bohr',
    )
    mf = scf.ROHF(mol)
    mf.kernel()

    system, H = load_pyscf_integrals(mf, nfrozen=2,
                                     num_act_holes_alpha=4, num_act_particles_alpha=10,
                                     num_act_holes_beta=4, num_act_particles_beta=10
                                     )

    calculation = Calculation(
        order=3,
        active_orders=[None],
        num_active=[None],
        calculation_type="ccsdt",
        convergence_tolerance=1.0e-08
    )

    T, total_energy, is_converged = cc_driver(calculation, system, H)
    HBar = build_hbar_ccsd(T, H)

    # create full residual container
    dT = ClusterOperator(system, order=3)

    # create acitve-space cluster operator and residual container
    T_act = ClusterOperator(system, order=3, active_orders=[3], num_active=[1])
    dT_act = ClusterOperator(system, order=3, active_orders=[3], num_active=[1])

    # zero amplitudes outside active space
    T = zero_t3aaa_outside_active_space(T, system, 1)
    T = zero_t3aab_outside_active_space(T, system, 1)
    T = zero_t3abb_outside_active_space(T, system, 1)
    T = zero_t3bbb_outside_active_space(T, system, 1)

    # fill in the active-space cluster operator
    T_act = fill_t3aaa(T_act, T, system)
    T_act = fill_t3aab(T_act, T, system)
    T_act = fill_t3abb(T_act, T, system)
    T_act = fill_t3bbb(T_act, T, system)

    # get the full update
    _, dT = calc_full_update_t3a(T, dT, HBar, H, 0.0, system)
    _, dT = calc_full_update_t3b(T, dT, HBar, H, 0.0, system)

    # get the active-space updates
    _, dT_act = update_t3a(T_act, dT_act, HBar, H, 0.0, system)
    _, dT_act = update_t3b(T_act, dT_act, HBar, H, 0.0, system)

    # Get the error
    calc_error(dT_act, dT, system)