import argparse
import numpy as np
from pyscf import gto, scf
from ccpy.drivers.driver import Driver
from ccpy.utilities.pspace import get_active_triples_pspace
from ccpy.utilities.utilities import convert_t3_from_pspace

def test_dipeomccsdt_cl2():

    nfrozen = 10

    geom = [["Cl", (0.0, 0.0, 0.0)],
            ["Cl", (0.0, 0.0, 1.9870)]]

    mol = gto.M(atom=geom, basis="cc-pvdz", symmetry="D2H", unit="Angstrom", cart=False, charge=0)
    mf = scf.RHF(mol)
    mf = mf.x2c()
    mf.kernel()

    print("   Using SFX2C-1e scalar relativity")

    driver = Driver.from_pyscf(mf, nfrozen=nfrozen)
    driver.system.print_info()
    driver.system.set_active_space(nact_occupied=driver.system.noccupied_alpha, nact_unoccupied=driver.system.nunoccupied_alpha)
    t3_excitations = get_active_triples_pspace(driver.system, target_irrep="AG")

    driver.run_ccp(method="ccsdt_p", t3_excitations=t3_excitations)
    driver.run_hbar(method="ccsdt_p", t3_excitations=t3_excitations)
    convert_t3_from_pspace(driver, t3_excitations)

    driver.run_guess(method="dipcis", multiplicity=-1, nact_occupied=driver.system.noccupied_alpha, roots_per_irrep={"A1": 10}, use_symmetry=False) 
    driver.run_dipeomcc(method="dipeomccsdt", state_index=[0, 1, 3, 4])

if __name__ == "__main__":

    test_dipeomccsdt_cl2()
