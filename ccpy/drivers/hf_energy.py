import numpy as np

def calc_g_matrix(H, system):

    from ccpy.models.integrals import Integral

    G = Integral.from_empty(system, 1, data_type=H.a.oo.dtype, use_none=True)
    # <p|g|q> = <pi|v|qi> + <pi~|v|qi~>
    G.a.oo = (
        + np.einsum("piqi->pq", H.aa.oooo)
        + np.einsum("piqi->pq", H.ab.oooo)
    )
    G.a.ov = (
        + np.einsum("piqi->pq", H.aa.oovo)
        + np.einsum("piqi->pq", H.ab.oovo)
    )
    G.a.vo = (
        + np.einsum("piqi->pq", H.aa.vooo)
        + np.einsum("piqi->pq", H.ab.vooo)
    )
    G.a.vv = (
        + np.einsum("piqi->pq", H.aa.vovo)
        + np.einsum("piqi->pq", H.ab.vovo)
    )
    # <p~|g|q~> = <p~i~|v|q~i~> + <ip~|v|iq~>
    G.b.oo = (
        + np.einsum("piqi->pq", H.bb.oooo)
        + np.einsum("ipiq->pq", H.ab.oooo)
    )
    G.b.ov = (
        + np.einsum("piqi->pq", H.bb.oovo)
        + np.einsum("ipiq->pq", H.ab.ooov)
    )
    G.b.vo = (
        + np.einsum("piqi->pq", H.bb.vooo)
        + np.einsum("ipiq->pq", H.ab.ovoo)
    )
    G.b.vv = (
        + np.einsum("piqi->pq", H.bb.vovo)
        + np.einsum("ipiq->pq", H.ab.ovov)
    )

    return G

    # slice_table = {
    #     "a": {
    #         "o": slice(0, system.noccupied_alpha),
    #         "v": slice(system.noccupied_alpha, system.norbitals),
    #     },
    #     "b": {
    #         "o": slice(0, system.noccupied_beta),
    #         "v": slice(system.noccupied_beta, system.norbitals),
    #     },
    # }
    #
    # # Compute the HF-based G part of the Fock matrix
    # G_a = np.zeros((system.norbitals, system.norbitals))
    # G_b = np.zeros((system.norbitals, system.norbitals))
    # # <p|g|q> = <pi|v|qi> + <pi~|v|qi~>
    # G_a[slice_table["a"]["o"], slice_table["a"]["o"]] = (
    #     + np.einsum("piqi->pq", H.aa.oooo)
    #     + np.einsum("piqi->pq", H.ab.oooo)
    # )
    # G_a[slice_table["a"]["o"], slice_table["a"]["v"]] = (
    #     + np.einsum("piqi->pq", H.aa.oovo)
    #     + np.einsum("piqi->pq", H.ab.oovo)
    # )
    # G_a[slice_table["a"]["v"], slice_table["a"]["o"]] = (
    #     + np.einsum("piqi->pq", H.aa.vooo)
    #     + np.einsum("piqi->pq", H.ab.vooo)
    # )
    # G_a[slice_table["a"]["v"], slice_table["a"]["v"]] = (
    #     + np.einsum("piqi->pq", H.aa.vovo)
    #     + np.einsum("piqi->pq", H.ab.vovo)
    # )
    # # <p~|g|q~> = <p~i~|v|q~i~> + <ip~|v|iq~>
    # G_b[slice_table["b"]["o"], slice_table["b"]["o"]] = (
    #     + np.einsum("piqi->pq", H.bb.oooo)
    #     + np.einsum("ipiq->pq", H.ab.oooo)
    # )
    # G_b[slice_table["b"]["o"], slice_table["b"]["v"]] = (
    #     + np.einsum("piqi->pq", H.bb.oovo)
    #     + np.einsum("ipiq->pq", H.ab.ooov)
    # )
    # G_b[slice_table["b"]["v"], slice_table["b"]["o"]] = (
    #     + np.einsum("piqi->pq", H.bb.vooo)
    #     + np.einsum("ipiq->pq", H.ab.ovoo)
    # )
    # G_b[slice_table["b"]["v"], slice_table["b"]["v"]] = (
    #     + np.einsum("piqi->pq", H.bb.vovo)
    #     + np.einsum("ipiq->pq", H.ab.ovov)
    # )
    #
    # return G_a, G_b


def calc_hf_energy(e1int, e2int, system):

    occ_a = slice(0, system.noccupied_alpha + system.nfrozen)
    occ_b = slice(0, system.noccupied_beta + system.nfrozen)

    e1a = np.einsum("ii->", e1int[occ_a, occ_a])
    e1b = np.einsum("ii->", e1int[occ_b, occ_b])
    e2a = 0.5 * (
        np.einsum("ijij->", e2int[occ_a, occ_a, occ_a, occ_a])
        - np.einsum("ijji->", e2int[occ_a, occ_a, occ_a, occ_a])
    )
    e2b = np.einsum("ijij->", e2int[occ_a, occ_b, occ_a, occ_b])
    e2c = 0.5 * (
        np.einsum("ijij->", e2int[occ_b, occ_b, occ_b, occ_b])
        - np.einsum("ijji->", e2int[occ_b, occ_b, occ_b, occ_b])
    )

    hf_energy = e1a + e1b + e2a + e2b + e2c

    return hf_energy


def calc_khf_energy(e1int, e2int, system):
    # Note that any V must have a factor of 1/Nkpts!
    e1a = 0.0
    e1b = 0.0
    e2a = 0.0
    e2b = 0.0
    e2c = 0.0

    # slices
    occ_a = slice(0, system.noccupied_alpha + system.nfrozen)
    occ_b = slice(0, system.noccupied_beta + system.nfrozen)

    e1a = np.einsum("uuii->", e1int[:, :, occ_a, occ_a])
    e1b = np.einsum("uuii->", e1int[:, :, occ_b, occ_b])
    e2a = 0.5 * (
        np.einsum("uvuvijij->", e2int[:, :, :, :, occ_a, occ_a, occ_a, occ_a])
        - np.einsum("uvvuijji->", e2int[:, :, :, :, occ_a, occ_a, occ_a, occ_a])
    )
    e2b = 1.0 * (np.einsum("uvuvijij->", e2int[:, :, :, :, occ_a, occ_b, occ_a, occ_b]))
    e2c = 0.5 * (
        np.einsum("uvuvijij->", e2int[:, :, :, :, occ_b, occ_b, occ_b, occ_b])
        - np.einsum("uvvuijji->", e2int[:, :, :, :, occ_b, occ_b, occ_b, occ_b])
    )

    e1a + e1b + e2a + e2b + e2c

    return np.real(Escf) / system.nkpts
