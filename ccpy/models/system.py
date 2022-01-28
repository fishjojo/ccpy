class System:

    """Class that holds information about the molecular or periodic system."""

    def __init__(self, nelectrons, norbitals, multiplicity, nfrozen,
                 point_group='C1', orbital_symmetries=None, charge=0,
                 nkpts=0, nuclear_repulsion=0):
        """Default constructor for the System object.

        Arguments:
        ----------
        nelectrons : int -> total number of electrons
        norbitals : int -> total number of spatial orbitals
        multiplicity : int -> spin multiplicity of reference state (2S+1)
        nfrozen : int -> number of frozen spatial orbitals
        point_group : str -> spatial point group, default = 'C1'
        orbital_symmetries : list -> point group irreps of each molecular orbital, default = [None]*norbitals
        charge : int -> total charge on the molecule, default = 0
        nkpts : int -> number of k-points used in reciprocal space sampling (periodic calculations only)
        e_nuclear : float -> nuclear repulsion energy at the molecular geometry (in hartree)
        Returns:
        ----------
        sys : Object -> System object"""
        self.nelectrons = nelectrons - 2*nfrozen
        self.norbitals = norbitals - nfrozen
        self.nfrozen = nfrozen
        self.multiplicity = multiplicity
        self.noccupied_alpha = int( (self.nelectrons + self.multiplicity - 1)/2 )
        self.noccupied_beta = int( (self.nelectrons - self.multiplicity + 1)/2 )
        self.nunoccupied_alpha = self.norbitals - self.noccupied_alpha
        self.nunoccupied_beta = self.norbitals - self.noccupied_beta
        self.charge = charge
        self.nkpts = nkpts
        self.point_group = point_group
        if orbital_symmetries is None:
            self.orbital_symmetries = ['A1'] * norbitals
        else:
            self.orbital_symmetries = orbital_symmetries
        self.nuclear_repulsion = nuclear_repulsion

    def __repr__(self):
        for key,value in vars(self).items():
            print('     ',key,'->',value)
        return ''

if __name__ == "__main__":

    test_case = 'pyscf'

    if test_case == 'native':
        # H2O / cc-pVDZ
        nfrozen = 1
        norbitals = 24
        nelectrons = 10
        multiplicity = 1
        system = System(nelectrons, norbitals, multiplicity, nfrozen)

    if test_case == 'gamess':
        from ccpy.interfaces.gamess_tools import loadFromGamess
        # F2+ / 6-31G
        nfrozen = 2
        gamess_logfile = "/Users/harellab/Documents/ccpy/tests/F2+-1.0-631g/F2+-1.0-631g.log"
        onebody_file = "/Users/harellab/Documents/ccpy/tests/F2+-1.0-631g/onebody.inp"
        twobody_file = "/Users/harellab/Documents/ccpy/tests/F2+-1.0-631g/twobody.inp"

        system, H = loadFromGamess(gamess_logfile, onebody_file, twobody_file, nfrozen)

    if test_case == 'pyscf':
        from ccpy.interfaces.pyscf_tools import loadFromPyscfMolecular
        from pyscf import gto, scf
        mol = gto.Mole()
        mol.build(
            atom = '''F 0.0 0.0 -2.66816
                      F 0.0 0.0  2.66816''',
            basis = 'ccpvdz',
            charge = 1,
            spin = 1,
            symmetry = 'D2H',
            cart = True,
            unit = 'Bohr',
        )
        mf = scf.ROHF(mol)
        mf.kernel()

        nfrozen = 2
        system, H = loadFromPyscfMolecular(mf, nfrozen)

    print(system)