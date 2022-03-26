
from ccpy.models.calculation import Calculation
from ccpy.interfaces.gamess_tools import load_from_gamess
from ccpy.drivers.driver import cc_driver, lcc_driver, eomcc_driver

from ccpy.hbar.hbar_ccsdt import build_hbar_ccsdt1

from ccpy.eomcc.initial_guess import get_initial_guess

if __name__ == "__main__":
    system, H = load_from_gamess(
            "chplus_re.log",
            "onebody.inp",
            "twobody.inp",
            nfrozen=0,
    )
    system.set_active_space(nact_occupied=1, nact_unoccupied=3)

    calculation = Calculation(
        order=3,
        calculation_type="ccsdt1",
        active_orders=[3],
        num_active=[1],
        convergence_tolerance=1.0e-08,
        RHF_symmetry=False,
    )

    T, total_energy, is_converged = cc_driver(calculation, system, H)

    Hbar = build_hbar_ccsdt1(T, H, system)

    calculation = Calculation(
        order=3,
        calculation_type="eomccsdt1",
        active_orders=[3],
        num_active=[1],
        maximum_iterations=60,
        convergence_tolerance=1.0e-08,
        multiplicity=1,
        RHF_symmetry=False,
        low_memory=False,
    )

    R, omega = get_initial_guess(calculation, system, Hbar, 10, noact=0, nuact=0, guess_order=1)

    R, omega, r0, is_converged = eomcc_driver(calculation, system, Hbar, T, R, omega)
