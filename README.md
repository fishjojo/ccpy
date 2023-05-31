
# CCpy: A coupled-cluster package written in Python.
![image](docs/assets/img/Diagrams-CCD.png)
<p style="text-align: right;">Image from: https://nucleartalent.github.io/ManyBody2018/doc/pub/CCM/html/CCM.html</p>

---
# Overview
CCpy is a research-level Python package for performing non-relativistic electronic structure calculations for molecular systems 
using methods based on the ground-state coupled-cluster (CC) theory and its equation-of-motion (EOM) extension
to excited electronic states. As a design philosophy, CCpy favors simplicity over efficiency, and this is reflected in the
usage of computational routines that are transparent enough so that they can be easily used, modifiied, and extended, while 
still maintaining reasonable efficiency. To this end, CCpy operates within a hybrid Python-Fortran environment made possible
with the f2py package, which allows one to painlessly compile Fortran code into shared object libraries containing subroutines
that are callable from Python and have seamless interoperability with Numpy arrays. This approach is particularly useful when
devectorized, loop-driven implementations are used, as Python is notoriously slow at executing deep nested loops. On the other
hand, the dense tensor contractions forming the bulk of the computational cost of all CC implementations are very efficiently
implemented using standard Numpy functions, especially when the latter is compiled with efficient BLAS libraries. As a result, CCpy
can achieve a serial performance comparable to a standard Fortran implementation. 

CCpy specializes in applying the CC(P;Q) and externally corrected (ec) CC methodologies developed in the Piecuch group at Michigan State University.
In CC(P;Q), the energetics obtained by solving the ground- or excited-state CC/EOMCC equations in
one subspace of the many-electron Hilbert space, called the P space, are corrected for the missing many-electron correlation
effects captured with the help of a complementary subspace called the Q space using the state-selective, non-iterative,
and non-perturbative energy corrections based on the CC moment expansion formalism. Currently, CCpy offers implementations
of several CC(P;Q) methods, the majority of which are aimed at converging the high-level CCSDT and EOMCCSDT energetics. 
These include the completely-renormalized (CR) methods such as the CR-CC(2,3) and CR-CC(2,4) triples and quadruples 
corrections to CCSD, the
active-space CCSDt and CC(t;3) approaches, which are based on a user-defined selection of active orbitals, and the black-box 
selected configuration interaction (CI) driven and adaptive CC(P;Q) methodologies, which construct the P and Q spaces 
entering the CC(P;Q) computations using information extracted from selected CI wave functions or the adaptive CC(P;Q) moment 
expansions themselves, respectively. The ec-CC approaches on the other hand seek to converge the exact, full CI energetics
directly by solving for the T1 and T2 clusters in the presence of the leading T3 and T4 clusters extracted from an
external non-CC wave function. Current implementations of the ec-CC approaches in CCpy are designed to iterate T1 and T2 clusters 
in the presence of T3 and T4 obtained from CI wave functions of the selected CI or multireference CI types, and correct the resulting
energetics for the missing many-electron correlations using the generalized moment expansions of the ec-CC equations.

Because CCpy is primarily used for CC method development work, we use interfaces to GAMESS and Pyscf to obtain the mean-field (typically Hartree-Fock)
reference state and associated molecular orbital one- and two-electron integrals prior to performing the correlated CC calculations. All implementations
in CCpy are based on the spin-integrated spinorbital formulation and are compatible with RHF and ROHF references. The expressions
used in all methods are also valid for UHF references, however, CCpy does not yet have a convenient interface to UHF references computed
by PySCF or GAMESS. Once this is made available, all computations will also be compatible with UHF.

A list of all computational options available in CCpy:
  - MP2
  - MP3
  - CCD
  - CCSD
  - CCSD(T)
  - CR-CC(2,3)
  - CCSDt
  - CC(t;3)
  - CIPSI-driven CC(P;Q) aimed at converging CCSDT
  - Adaptive CC(P;Q) aimed at converging CCSDT (unpublished)
  - CCSDT
  - CR-CC(2,4)
  - CCSDTQ (available for RHF reference only)
  - EOMCCSD
  - Spin-Flip (SF) EOMCCSD
  - CR-EOMCC(2,3) and its size-intensive δ-CR-EOMCC(2,3) extension
  - EOMCCSDt
  - EOMCCSDT
  - ec-CC-II
  - ec-CC-II_{3}
  - ec-CC_II_{3,4} (unpublished)
  - DEA-EOMCCSD(3p-1h)

Currently, all EOMCC options are initiated using a CIS-like guess, which can reliably locate states dominated by single
excitations. The more desirable CISd-like guess, capable of finding doubly excited states, is not available yet. Also
note that the MPn methods available in CCpy are not implemented for non-Hartree-Fock orbitals, and thus should only be
used with RHF and ROHF references. 


# Installation
Installation should be simple. Simply clone this git repository and run `make install` followed by `make all` inside of it. You will
need a working gfortran compiler as well as locations for BLAS (preferably MKL) libraries, which enter in the Makefile as the environment
variable `$MKLROOT`. For a given computer architecture, the Intel Link Line Advisor is a useful tool to figure out what compiler flags need to be included.
(https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-link-line-advisor.html#gs.jxf4xw)

Additionally, you will need the `cclib` package (`conda install --channel conda-forge cclib`) and Pyscf (`pip install pyscf`).

In all selected CI based computations, including the ec-CC-II and CIPSI-driven CC(P;Q), we currently rely on the CIPSI wave functions obtained 
using the open-source Quantum Package software (https://github.com/QuantumPackage/qp2).

# Contact
Karthik Gururangan - gururang@msu.edu

J. Emiliano Deustua - edeustua@gmail.com

CCpy is affiliated with the Piecuch Group at Michigan State University (https://www2.chemistry.msu.edu/faculty/piecuch/)
