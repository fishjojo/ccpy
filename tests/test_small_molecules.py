from pathlib import Path

import numpy as np
from pyscf import scf, gto
from ccpy.drivers.driver import Driver, AdaptDriver


TEST_DATA_DIR = str(Path(__file__).parent.absolute() / "data")

def test_creom23_chplus():
    """
    """
    driver = Driver.from_gamess(logfile=TEST_DATA_DIR+"/chplus/chplus.log",
                                fcidump=TEST_DATA_DIR+"/chplus/chplus.FCIDUMP",
                                nfrozen=0)
    driver.system.print_info()
    driver.options["maximum_iterations"] = 300
    driver.run_cc(method="ccsd")
    driver.run_hbar(method="ccsd")
    driver.run_guess(method="cis", multiplicity=1, nroot=10)
    driver.run_eomcc(method="eomccsd", state_index=[1, 2, 3, 4])
    driver.run_leftcc(method="left_ccsd", state_index=[0, 1, 2, 3, 4])
    driver.options["energy_shift"] = 0.5
    driver.run_ccp3(method="crcc23", state_index=[0, 1, 2, 3, 4])

    expected_vee = [0.0, 0.11982887, 0.11982887, 0.49906873, 0.53118318]
    expected_total_energy = [-38.0176701653, -37.8978412944, -37.8978412944, -37.5186014361, -37.4864869901]
    expected_deltapq = {"A" : [-0.0013798405, -0.0016296078, -0.0016296078, -0.0021697718, -0.0045706983],
                        "D" : [-0.0017825588, -0.0022877876, -0.0022877876, -0.0030686698, -0.0088507112]}
    expected_ddeltapq = {"A" : [0.0, -0.0016296078, -0.0016296078, -0.0022291593, -0.0045706983],
                         "D" : [0.0, -0.0022877876, -0.0022877876, -0.0031525794, -0.0088507112]}

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -37.9027681837))
    for n in range(5):
        if n == 0:
            # Check CCSD energy
            assert (np.allclose(driver.correlation_energy, -0.11490198))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy, -38.01767017))
            # Check CR-CC(2,3)_A energy
            assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["A"], -0.1162818221))
            assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["A"], -38.0190500058))
            # Check CR-CC(2,3)_D energy
            assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["D"], -0.1166845404))
            assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["D"], -38.0194527241))
        else:
            # Check EOMCCSD energy
            assert (np.allclose(driver.vertical_excitation_energy[n], expected_vee[n]))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.vertical_excitation_energy[n], expected_total_energy[n]))
            # Check CR-CC(2,3)_A energy
            assert (np.allclose(driver.vertical_excitation_energy[n] + driver.deltapq[n]["A"], expected_vee[n] + expected_deltapq["A"][n]))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy +
                                driver.vertical_excitation_energy[n] + driver.deltapq[n]["A"],
                                -38.01767017 + expected_vee[n] + expected_deltapq["A"][n]))
            assert (np.allclose(driver.vertical_excitation_energy[n] + driver.ddeltapq[n]["A"], expected_vee[n] + expected_ddeltapq["A"][n]))

            # Check CR-CC(2,3)_D energy
            assert (np.allclose(driver.vertical_excitation_energy[n] + driver.deltapq[n]["D"], expected_vee[n] + expected_deltapq["D"][n]))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy +
                                driver.vertical_excitation_energy[n] + driver.deltapq[n]["D"],
                                -38.01767017 + expected_vee[n] + expected_deltapq["D"][n]))
            assert (np.allclose(driver.vertical_excitation_energy[n] + driver.ddeltapq[n]["D"], expected_vee[n] + expected_ddeltapq["D"][n]))

def test_eomccsdt1_chplus():
    """
    """
    driver = Driver.from_gamess(logfile=TEST_DATA_DIR+"/chplus/chplus.log",
                                fcidump=TEST_DATA_DIR+"/chplus/chplus.FCIDUMP",
                                nfrozen=0)
    driver.system.print_info()
    driver.system.set_active_space(nact_occupied=1, nact_unoccupied=3)

    driver.run_cc(method="ccsdt1")
    driver.run_hbar(method="ccsdt1")
    driver.run_guess(method="cis", multiplicity=1, nroot=10)
    driver.run_eomcc(method="eomccsdt1", state_index=[1, 2, 3, 4, 5])

    expected_vee = [0.0, 0.11879449, 0.11879449, 0.49704224, 0.52261182, 0.52261184]
    expected_total_energy = [-38.01904114 + omega for omega in expected_vee]

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -37.9027681837))
    for n in range(6):
        if n == 0:
            # Check CCSD energy
            assert (np.allclose(driver.correlation_energy, -0.11627295))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy, -38.01904114))
        else:
            # Check EOMCCSDt energy
            assert (np.allclose(driver.vertical_excitation_energy[n], expected_vee[n]))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.vertical_excitation_energy[n], expected_total_energy[n]))

def test_eomccsdt1_ch():
    """
    """
    driver = Driver.from_gamess(logfile=TEST_DATA_DIR+"/ch/ch.log",
                                fcidump=TEST_DATA_DIR+"/ch/ch.FCIDUMP",
                                nfrozen=1)
    driver.system.print_info()
    driver.system.set_active_space(nact_occupied=1, nact_unoccupied=1)

    driver.run_cc(method="ccsdt1")
    driver.run_hbar(method="ccsdt1")
    driver.run_guess(method="cis", multiplicity=2, nroot=10)
    driver.run_eomcc(method="eomccsdt1", state_index=[1, 2, 3])

    expected_vee = [0.0, 0.00015539, 0.12326569, 0.11287039]
    expected_total_energy = [-38.38596742 + omega for omega in expected_vee]

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -38.2713247488))
    for n in range(4):
        if n == 0:
            # Check CCSD energy
            assert (np.allclose(driver.correlation_energy, -0.11464267))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy, -38.38596742))
        else:
            # Check EOMCCSDt energy
            assert (np.allclose(driver.vertical_excitation_energy[n], expected_vee[n]))
            assert (np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.vertical_excitation_energy[n], expected_total_energy[n]))

def test_cct3_f2():
    """
    F2 / cc-pVDZ at R = 2.0Re, where Re = 2.66816 bohr using RHF.
    Cartesian orbitals are used for the d orbitals in the cc-pVDZ basis.
    Reference: Chem. Phys. Lett. 344, 165 (2001).
    """
    geometry = [["F", (0.0, 0.0, -2.66816)],
                ["F", (0.0, 0.0,  2.66816)]]
    mol = gto.M(atom=geometry,
                basis="cc-pvdz",
                charge=0,
                spin=0,
                symmetry="D2H",
                cart=True,
                unit="Bohr",
    )
    mf = scf.RHF(mol)
    mf.kernel()

    driver = Driver.from_pyscf(mf, nfrozen=2)
    driver.system.set_active_space(nact_occupied=5, nact_unoccupied=1)
    driver.run_cc(method="ccsdt1")
    driver.run_hbar(method="ccsd")
    driver.run_leftcc(method="left_ccsd")
    driver.run_ccp3(method="cct3", state_index=[0])

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -198.4200962814))
    # Check CCSDt energy
    assert(np.allclose(driver.correlation_energy, -0.6363154135))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy, -199.0564116949))
    # Check CC(t;3)_A energy
    assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["A"], -0.6376818524))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["A"], -199.0577781338))
    # Check CC(t;3)_D energy
    assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["D"], -0.6378384699))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["D"], -199.0579347513))

def test_cct3_hfhminus_triplet():
    """
    (HFH)- / 6-31g(1d,1p) open-shell triplet in the symmetric D2H geometry
    with R_{HF} = 2.0 angstrom using ROHF and MO integrals from GAMESS.
    Reference: J. Chem. Theory Comput. 8, 4968 (2012)
    """
    driver = Driver.from_gamess(logfile=TEST_DATA_DIR+"/hfhminus-triplet/hfhminus-triplet.log",
                                fcidump=TEST_DATA_DIR+"/hfhminus-triplet/hfhminus-triplet.FCIDUMP",
                                nfrozen=1)
    driver.system.set_active_space(nact_unoccupied=1, nact_occupied=1)
    driver.system.print_info()

    driver.run_cc(method="ccsdt1")
    driver.run_hbar(method="ccsd")
    driver.run_leftcc(method="left_ccsd")
    driver.run_ccp3(method="cct3", state_index=[0])

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -100.3591573557))
    # Check CCSDt energy
    assert(np.allclose(driver.correlation_energy, -0.1925359236))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy, -100.5516932793))
    # Check CC(t;3)_A energy
    assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["A"], -0.1936455544))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["A"], -100.5528029101))
    # Check CC(t;3)_D energy
    assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["D"], -0.1938719549))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["D"], -100.5530293106))

def test_ccsdt_ch():
    """
    """
    driver = Driver.from_gamess(logfile=TEST_DATA_DIR+"/ch/ch.log",
                                fcidump=TEST_DATA_DIR+"/ch/ch.FCIDUMP",
                                nfrozen=1)
    driver.system.print_info()

    driver.run_cc(method="ccsdt")

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -38.2713247488))
    # Check CCSDT energy
    assert(np.allclose(driver.correlation_energy, -0.1164237849))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy, -38.3877485336))
                

def test_cct3_ch():
    """
    """
    driver = Driver.from_gamess(logfile=TEST_DATA_DIR+"/ch/ch.log",
                                fcidump=TEST_DATA_DIR+"/ch/ch.FCIDUMP",
                                nfrozen=1)
    driver.system.set_active_space(nact_occupied=1, nact_unoccupied=2)
    driver.system.print_info()

    driver.run_cc(method="ccsdt1")
    driver.run_hbar(method="ccsd")
    driver.run_leftcc(method="left_ccsd")
    driver.run_ccp3(method="cct3")

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -38.2713247488))
    # Check CCSDt energy
    assert(np.allclose(driver.correlation_energy, -0.11469532))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy, -38.38602007))
    # Check CC(t;3)_A energy
    assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["A"], -0.1160181452))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["A"], -38.3873428940))
    # Check CC(t;3)_D energy
    assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["D"], -0.1162820915))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["D"], -38.3876068402))

def test_ccsdpt_f2():
    """
    F2 / cc-pVDZ at R = 2.0Re, where Re = 2.66816 bohr using RHF.
    Cartesian orbitals are used for the d orbitals in the cc-pVTZ basis.
    Reference: Chem. Phys. Lett. 344, 165 (2001).
    """
    geometry = [["F", (0.0, 0.0, -2.66816)],
                ["F", (0.0, 0.0,  2.66816)]]
    mol = gto.M(atom=geometry,
                basis="cc-pvtz",
                charge=0,
                spin=0,
                symmetry="D2H",
                cart=False,
                unit="Bohr",
    )
    mf = scf.RHF(mol)
    mf.kernel()

    driver = Driver.from_pyscf(mf, nfrozen=2)
    driver.run_cc(method="ccsd")
    driver.run_ccp3(method="ccsd(t)")
    driver.run_hbar(method="ccsd")
    driver.run_leftcc(method="left_ccsd")
    driver.run_ccp3(method="crcc23")

    # Check reference energy
    assert(np.allclose(driver.system.reference_energy, -198.48327030))
    # Check CCSD energy
    assert(np.allclose(driver.correlation_energy, -0.69225474))
    assert(np.allclose(driver.system.reference_energy + driver.correlation_energy, -199.17552504))
    # Check CCSD(T) energy
    #assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["A"], -0.6376818524))
    #assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["A"], -199.0577781338))
    # Check CR-CC(2,3) energy
    #assert(np.allclose(driver.correlation_energy + driver.deltapq[0]["D"], -0.6378384699))
    #assert(np.allclose(driver.system.reference_energy + driver.correlation_energy + driver.deltapq[0]["D"], -199.0579347513))

def test_adaptive_f2():
    """
    F2 / cc-pVDZ at R = 2.0Re, where Re = 2.66816 bohr using RHF.
    Cartesian orbitals are used for the d orbitals in the cc-pVTZ basis.
    Reference: Chem. Phys. Lett. 344, 165 (2001).
    """
    geometry = [["F", (0.0, 0.0, -2.66816)],
                ["F", (0.0, 0.0,  2.66816)]]
    mol = gto.M(atom=geometry,
                basis="cc-pvdz",
                charge=0,
                spin=0,
                symmetry="D2H",
                cart=True,
                unit="Bohr",
    )
    mf = scf.RHF(mol)
    mf.kernel()

    percentages = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]

    driver = Driver.from_pyscf(mf, nfrozen=2)
    driver.system.print_info()
    adaptdriver = AdaptDriver(driver, percentages, full_storage=False, perturbative=False, pspace_analysis=False)
    adaptdriver.run()


if __name__ == "__main__":
    test_adaptive_f2()

