import numpy as np

if __name__ == '__main__':

    from ccpy.interfaces.pyscf_tools import load_pyscf_integrals
    from pyscf import gto, scf, cc

    from ccpy.models.calculation import Calculation
    from ccpy.drivers.cc import driver

    # Testing from PySCF
    mol = gto.Mole()
    mol.build(
        atom="""C   0.68350000  0.78650000  0.00000000
                C  -0.68350000  0.78650000  0.00000000
                C   0.68350000 -0.78650000  0.00000000
                C  -0.68350000 -0.78650000  0.00000000
                H   1.45771544  1.55801763  0.00000000
                H   1.45771544 -1.55801763  0.00000000
                H  -1.45771544  1.55801763  0.00000000
                H  -1.45771544 -1.55801763  0.00000000""",
        basis="ccpvdz",
        charge=0,
        spin=0,
        symmetry="D2H",
        cart=False,
        unit="Angstrom",
    )
    mf = scf.ROHF(mol)
    mf.kernel()

    nfrozen = 4
    system, H = load_pyscf_integrals(mf, nfrozen, dump_integrals=False)

    calculation = Calculation('ccsd')
    T, cc_energy = driver(calculation, system, H)

    pyscf_cc = cc.CCSD(mf, frozen=nfrozen)
    pyscf_cc.run()

    assert np.allclose(pyscf_cc.e_tot, cc_energy, atol=1.0e-06, rtol=1.0e-06)
