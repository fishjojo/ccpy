import numpy as np

if __name__ == '__main__':

    from ccpy.interfaces.pyscf_tools import load_pyscf_integrals
    from pyscf import gto, scf, cc

    from ccpy.models.calculation import Calculation
    from ccpy.models.driver import CCMethod

    # Testing from PySCF
    mol = gto.Mole()
    mol.build(
        atom='''F 0.0 0.0 -1.33408
                F 0.0 0.0  1.33408''',
        basis='ccpvdz',
        charge=1,
        spin=1,
        symmetry='D2H',
        cart=True,
        unit='Bohr',
    )
    mf = scf.ROHF(mol)
    mf.kernel()

    nfrozen = 2
    system, H = load_pyscf_integrals(mf, nfrozen, dump_integrals=False)

    #mycc = CCDriver('ccsd'
    
    #calculation = Calculation('ccsd')
    #T, cc_energy = calc_driver_main(calculation, system, H)

    pyscf_cc = cc.CCSD(mf, frozen=2)
    pyscf_cc.run()

    assert( np.allclose(pyscf_cc.e_tot, cc_energy, atol=1.0e-06, rtol=1.0e-06) )