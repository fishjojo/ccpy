import numpy as np
from itertools import permutations

from ccpy.utilities.determinants import get_excits_from, get_excits_to, get_spincase, spatial_orb_idx, get_excit_rank


def get_empty_pspace(system, nexcit, use_bool=False):
    if nexcit == 3:
        if use_bool:
            pspace = [{"aaa": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha),
                                      fill_value=False, dtype=bool),
                       "aab": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta),
                                      fill_value=False, dtype=bool),
                       "abb": np.full((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=False, dtype=bool),
                       "bbb": np.full((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_beta, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=False, dtype=bool)}
                      ]
        else:
            pspace = [{'aaa': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha)),
                       'aab': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta)),
                       'abb': np.zeros((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta)),
                       'bbb': np.zeros((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_beta, system.noccupied_beta, system.noccupied_beta))}]
    if nexcit == 4:
        if use_bool:
            pspace = [{"aaa": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha),
                                      fill_value=False, dtype=bool),
                       "aab": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta),
                                      fill_value=False, dtype=bool),
                       "abb": np.full((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=False, dtype=bool),
                       "bbb": np.full((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_beta, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=False, dtype=bool)},
                      {'aaaa': np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_alpha,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_alpha), fill_value=False, dtype=bool),
                       'aaab': np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_beta), fill_value=False, dtype=bool),
                       'aabb': np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta,
                                         system.noccupied_beta), fill_value=False, dtype=bool),
                       'bbbb': np.full((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_beta, system.noccupied_beta, system.noccupied_beta,
                                         system.noccupied_beta), fill_value=False, dtype=bool)}]
        else:
            pspace = [{'aaa': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha)),
                       'aab': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta)),
                       'abb': np.zeros((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta)),
                       'bbb': np.zeros((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_beta, system.noccupied_beta, system.noccupied_beta))},
                      {'aaaa': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_alpha,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_alpha)),
                       'aaab': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_beta)),
                       'aabb': np.zeros((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta,
                                         system.noccupied_beta)),
                       'bbbb': np.zeros((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_beta, system.noccupied_beta, system.noccupied_beta,
                                         system.noccupied_beta))}]
    return pspace


def get_full_pspace(system, nexcit, use_bool=False):
    if nexcit == 3:
        if use_bool:
            pspace = [{"aaa": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha),
                                      fill_value=True, dtype=bool),
                       "aab": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta),
                                      fill_value=True, dtype=bool),
                       "abb": np.full((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=True, dtype=bool),
                       "bbb": np.full((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_beta, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=True, dtype=bool)}
                      ]
        else:
            pspace = [{'aaa': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha)),
                       'aab': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta)),
                       'abb': np.ones((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta)),
                       'bbb': np.ones((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_beta, system.noccupied_beta, system.noccupied_beta))}]
    if nexcit == 4:
        if use_bool:
            pspace = [{"aaa": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha),
                                      fill_value=True, dtype=bool),
                       "aab": np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta),
                                      fill_value=True, dtype=bool),
                       "abb": np.full((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=True, dtype=bool),
                       "bbb": np.full((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                       system.noccupied_beta, system.noccupied_beta, system.noccupied_beta),
                                      fill_value=True, dtype=bool)},
                      {'aaaa': np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_alpha,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_alpha), fill_value=True, dtype=bool),
                       'aaab': np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_beta), fill_value=True, dtype=bool),
                       'aabb': np.full((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta,
                                         system.noccupied_beta), fill_value=True, dtype=bool),
                       'bbbb': np.full((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_beta, system.noccupied_beta, system.noccupied_beta,
                                         system.noccupied_beta), fill_value=True, dtype=bool)}]
        else:
            pspace = [{'aaa': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha)),
                       'aab': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta)),
                       'abb': np.ones((system.nunoccupied_alpha, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_alpha, system.noccupied_beta, system.noccupied_beta)),
                       'bbb': np.ones((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                        system.noccupied_beta, system.noccupied_beta, system.noccupied_beta))},
                      {'aaaa': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_alpha,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_alpha)),
                       'aaab': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_alpha,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_alpha,
                                         system.noccupied_beta)),
                       'aabb': np.ones((system.nunoccupied_alpha, system.nunoccupied_alpha, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_alpha, system.noccupied_alpha, system.noccupied_beta,
                                         system.noccupied_beta)),
                       'bbbb': np.ones((system.nunoccupied_beta, system.nunoccupied_beta, system.nunoccupied_beta,
                                         system.nunoccupied_beta,
                                         system.noccupied_beta, system.noccupied_beta, system.noccupied_beta,
                                         system.noccupied_beta))}]
    return pspace


def get_pspace_from_cipsi(pspace_file, system, nexcit=3, ordered_index=True):

    pspace = get_empty_pspace(system, nexcit)

    HF = sorted(
        [2 * i - 1 for i in range(1, system.noccupied_alpha + 1)]
        + [2 * i for i in range(1, system.noccupied_beta + 1)]
    )

    occupied_lower_bound = 1
    occupied_upper_bound = system.noccupied_alpha
    unoccupied_lower_bound = 1
    unoccupied_upper_bound = system.nunoccupied_beta

    orb_table = {'a': system.noccupied_alpha, 'b': system.noccupied_beta}

    excitation_count = [{'aaa': 0, 'aab': 0, 'abb': 0, 'bbb': 0},
                        {'aaaa': 0, 'aaab': 0, 'aabb': 0, 'abbb': 0, 'bbbb': 0}]
    excitations = [{'aaa': [], 'aab': [], 'abb': [], 'bbb': []},
                   {'aaaa': [], 'aaab': [], 'aabb': [], 'abbb': [], 'bbbb': []}]

    with open(pspace_file) as f:

        for line in f.readlines():

            det = list(map(int, line.split()[2:]))

            excit_rank = get_excit_rank(det, HF)

            if excit_rank < 3 or excit_rank > nexcit: continue

            spinorb_occ = get_excits_from(det, HF)
            spinorb_unocc = get_excits_to(det, HF)
            spincase = get_spincase(spinorb_occ, spinorb_unocc)

            unocc_shift = [orb_table[x] for x in spincase]

            spinorb_occ_alpha = [i for i in spinorb_occ if i % 2 == 1]
            spinorb_occ_alpha.sort()
            spinorb_occ_beta = [i for i in spinorb_occ if i % 2 == 0]
            spinorb_occ_beta.sort()
            spinorb_unocc_alpha = [i for i in spinorb_unocc if i % 2 == 1]
            spinorb_unocc_alpha.sort()
            spinorb_unocc_beta = [i for i in spinorb_unocc if i % 2 == 0]
            spinorb_unocc_beta.sort()

            idx_occ = [spatial_orb_idx(x) for x in spinorb_occ_alpha] + [spatial_orb_idx(x) for x in spinorb_occ_beta]
            idx_unocc = [spatial_orb_idx(x) for x in spinorb_unocc_alpha] + [spatial_orb_idx(x) for x in
                                                                             spinorb_unocc_beta]
            idx_unocc = [x - shift for x, shift in zip(idx_unocc, unocc_shift)]

            if any([i > occupied_upper_bound for i in idx_occ]) or any([i < occupied_lower_bound for i in idx_occ]):
                print("Occupied orbitals out of range!")
                print(idx_occ)
                break
            if any([i > unoccupied_upper_bound for i in idx_unocc]) or any(
                    [i < unoccupied_lower_bound for i in idx_unocc]):
                print("Unoccupied orbitals out of range!")
                print(idx_unocc)
                break

            n = excit_rank - 3

            excitation_count[n][spincase] += 1
            if n == 0:
                excitations[n][spincase].append([idx_unocc[0], idx_unocc[1], idx_unocc[2], idx_occ[0], idx_occ[1], idx_occ[2]])
            if n == 1:
                excitations[n][spincase].append([idx_unocc[0], idx_unocc[1], idx_unocc[2], idx_unocc[3], idx_occ[0], idx_occ[1], idx_occ[2], idx_occ[3]])

            ct_aaa = 1
            ct_aab = 1
            ct_abb = 1
            ct_bbb = 1

            if excit_rank == 3:
                if spincase == 'aaa':
                    for perms_unocc in permutations((idx_unocc[0], idx_unocc[1], idx_unocc[2])):
                        for perms_occ in permutations((idx_occ[0], idx_occ[1], idx_occ[2])):
                            a, b, c = perms_unocc
                            i, j, k = perms_occ
                            if ordered_index:
                                pspace[n][spincase][a - 1, b - 1, c - 1, i - 1, j - 1, k - 1] = ct_aaa
                                ct_aaa += 1
                            else:
                                pspace[n][spincase][a - 1, b - 1, c - 1, i - 1, j - 1, k - 1] = 1

                if spincase == 'aab':
                    for perms_unocc in permutations((idx_unocc[0], idx_unocc[1])):
                        for perms_occ in permutations((idx_occ[0], idx_occ[1])):
                            a, b = perms_unocc
                            i, j = perms_occ
                            if ordered_index:
                                pspace[n][spincase][a - 1, b - 1, idx_unocc[2] - 1, i - 1, j - 1, idx_occ[2] - 1] = ct_aab
                                ct_aab += 1
                            else:
                                pspace[n][spincase][a - 1, b - 1, idx_unocc[2] - 1, i - 1, j - 1, idx_occ[2] - 1] = 1

                if spincase == 'abb':
                    for perms_unocc in permutations((idx_unocc[1], idx_unocc[2])):
                        for perms_occ in permutations((idx_occ[1], idx_occ[2])):
                            b, c = perms_unocc
                            j, k = perms_occ
                            if ordered_index:
                                pspace[n][spincase][idx_unocc[0] - 1, b - 1, c - 1, idx_occ[0] - 1, j - 1, k - 1] = ct_abb
                                ct_abb += 1
                            else:
                                pspace[n][spincase][idx_unocc[0] - 1, b - 1, c - 1, idx_occ[0] - 1, j - 1, k - 1] = 1

                if spincase == 'bbb':
                    for perms_unocc in permutations((idx_unocc[0], idx_unocc[1], idx_unocc[2])):
                        for perms_occ in permutations((idx_occ[0], idx_occ[1], idx_occ[2])):
                            a, b, c = perms_unocc
                            i, j, k = perms_occ
                            if ordered_index:
                                pspace[n][spincase][a - 1, b - 1, c - 1, i - 1, j - 1, k - 1] = ct_bbb
                                ct_bbb += 1
                            else:
                                pspace[n][spincase][a - 1, b - 1, c - 1, i - 1, j - 1, k - 1] = 1

            if excit_rank == 4:
                pspace[n][spincase][idx_unocc[0] - 1, idx_unocc[1] - 1, idx_unocc[2] - 1, idx_unocc[3] - 1, idx_occ[0] - 1, idx_occ[1] - 1, idx_occ[2] - 1, idx_occ[3] - 1] = 1

    # convert excitation arrays to Numpy arrays
    for spincase in ["aaa", "aab", "abb", "bbb"]:
        excitations[0][spincase] = np.asarray(excitations[0][spincase])
        if len(excitations[0][spincase].shape) < 2:
            excitations[0][spincase] = np.ones((1, 6))
    for spincase in ["aaaa", "aaab", "aabb", "abbb", "bbbb"]:
        excitations[1][spincase] = np.asarray(excitations[1][spincase])
        if len(excitations[1][spincase].shape) < 2:
            excitations[1][spincase] = np.ones((1, 8))

    return pspace, excitations, excitation_count


def count_excitations_in_pspace(pspace, system, ordered_index=True):
    excitation_count = [{'aaa': 0, 'aab': 0, 'abb': 0, 'bbb': 0},
                        {'aaaa': 0, 'aaab': 0, 'aabb': 0, 'abbb': 0, 'bbbb': 0}]

    for n, p in enumerate(pspace):

        if n == 0:

            for a in range(system.nunoccupied_alpha):
                for b in range(a + 1, system.nunoccupied_alpha):
                    for c in range(b + 1, system.nunoccupied_alpha):
                        for i in range(system.noccupied_alpha):
                            for j in range(i + 1, system.noccupied_alpha):
                                for k in range(j + 1, system.noccupied_alpha):

                                    if ordered_index:
                                        if p['aaa'][a, b, c, i, j, k] != 0:
                                            excitation_count[n]['aaa'] += 1
                                    else:
                                        if p['aaa'][a, b, c, i, j, k] == 1:
                                            excitation_count[n]['aaa'] += 1

            for a in range(system.nunoccupied_alpha):
                for b in range(a + 1, system.nunoccupied_alpha):
                    for c in range(system.nunoccupied_beta):
                        for i in range(system.noccupied_alpha):
                            for j in range(i + 1, system.noccupied_alpha):
                                for k in range(system.noccupied_beta):

                                    if ordered_index:
                                        if p['aab'][a, b, c, i, j, k] != 0:
                                            excitation_count[n]['aab'] += 1
                                    else:
                                        if p['aab'][a, b, c, i, j, k] == 1:
                                            excitation_count[n]['aab'] += 1

            for a in range(system.nunoccupied_alpha):
                for b in range(system.nunoccupied_beta):
                    for c in range(b + 1, system.nunoccupied_beta):
                        for i in range(system.noccupied_alpha):
                            for j in range(system.noccupied_beta):
                                for k in range(j + 1, system.noccupied_beta):

                                    if ordered_index:
                                        if p['abb'][a, b, c, i, j, k] != 0:
                                            excitation_count[n]['abb'] += 1
                                    else:
                                        if p['abb'][a, b, c, i, j, k] == 1:
                                            excitation_count[n]['abb'] += 1

            for a in range(system.nunoccupied_beta):
                for b in range(a + 1, system.nunoccupied_beta):
                    for c in range(b + 1, system.nunoccupied_beta):
                        for i in range(system.noccupied_beta):
                            for j in range(i + 1, system.noccupied_beta):
                                for k in range(j + 1, system.noccupied_beta):

                                    if ordered_index:
                                        if p['bbb'][a, b, c, i, j, k] != 0:
                                            excitation_count[n]['bbb'] += 1
                                    else:
                                        if p['bbb'][a, b, c, i, j, k] == 1:
                                            excitation_count[n]['bbb'] += 1

    return excitation_count

def count_excitations_in_pspace_with_symmetry(pspace, system):

    h_sym = len(system.point_group_irrep_to_number)

    excitation_count = [[{'aaa': 0, 'aab': 0, 'abb': 0, 'bbb': 0},
                        {'aaaa': 0, 'aaab': 0, 'aabb': 0, 'abbb': 0, 'bbbb': 0}] for i in range(h_sym)]

    for n, p in enumerate(pspace):

        if n == 0:

            for a in range(system.nunoccupied_alpha):
                for b in range(a + 1, system.nunoccupied_alpha):
                    for c in range(b + 1, system.nunoccupied_alpha):
                        for i in range(system.noccupied_alpha):
                            for j in range(i + 1, system.noccupied_alpha):
                                for k in range(j + 1, system.noccupied_alpha):

                                    sym = system.point_group_irrep_to_number[system.reference_symmetry]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[i]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[j]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[k]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[a + system.noccupied_alpha]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[b + system.noccupied_alpha]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[c + system.noccupied_alpha]]

                                    if p['aaa'][a, b, c, i, j, k] == 1:
                                        excitation_count[sym][n]['aaa'] += 1

            for a in range(system.nunoccupied_alpha):
                for b in range(a + 1, system.nunoccupied_alpha):
                    for c in range(system.nunoccupied_beta):
                        for i in range(system.noccupied_alpha):
                            for j in range(i + 1, system.noccupied_alpha):
                                for k in range(system.noccupied_beta):

                                    sym = system.point_group_irrep_to_number[system.reference_symmetry]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[i]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[j]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[k]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[a + system.noccupied_alpha]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[b + system.noccupied_alpha]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[c + system.noccupied_beta]]

                                    if p['aab'][a, b, c, i, j, k] == 1:
                                        excitation_count[sym][n]['aab'] += 1

            for a in range(system.nunoccupied_alpha):
                for b in range(system.nunoccupied_beta):
                    for c in range(b + 1, system.nunoccupied_beta):
                        for i in range(system.noccupied_alpha):
                            for j in range(system.noccupied_beta):
                                for k in range(j + 1, system.noccupied_beta):

                                    sym = system.point_group_irrep_to_number[system.reference_symmetry]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[i]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[j]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[k]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[a + system.noccupied_alpha]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[b + system.noccupied_beta]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[c + system.noccupied_beta]]

                                    if p['abb'][a, b, c, i, j, k] == 1:
                                        excitation_count[sym][n]['abb'] += 1

            for a in range(system.nunoccupied_beta):
                for b in range(a + 1, system.nunoccupied_beta):
                    for c in range(b + 1, system.nunoccupied_beta):
                        for i in range(system.noccupied_beta):
                            for j in range(i + 1, system.noccupied_beta):
                                for k in range(j + 1, system.noccupied_beta):

                                    sym = system.point_group_irrep_to_number[system.reference_symmetry]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[i]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[j]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[k]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[a + system.noccupied_beta]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[b + system.noccupied_beta]]
                                    sym = sym ^ system.point_group_irrep_to_number[system.orbital_symmetries[c + system.noccupied_beta]]

                                    if p['bbb'][a, b, c, i, j, k] == 1:
                                        excitation_count[sym][n]['bbb'] += 1

    return excitation_count


def add_spinorbital_triples_to_pspace(triples_list, pspace, t3_excitations, system, ordered_index=False):
    """Expand the size of the previous P space using the determinants contained in the list
    of triples (stored as a, b, c, i, j, k) in triples_list. The variable triples_list stores
    triples in spinorbital form, where all orbital indices start from 1 and odd indices
    correspond to alpha orbitals while even indices corresopnd to beta orbitals."""

    def _add_t3_excitations(new_t3_excitations, old_t3_excitations, num_add, spincase):
        if num_add > 0:
            if np.array_equal(old_t3_excitations[spincase][0, :], np.ones(6)):
                new_t3_excitations[spincase] = np.asarray(new_t3_excitations[spincase])
            else:
                new_t3_excitations[spincase] = np.vstack((old_t3_excitations[spincase], np.asarray(new_t3_excitations[spincase])))
        else:
            new_t3_excitations[spincase] = old_t3_excitations[spincase].copy()

        return new_t3_excitations

    # should these be copied?
    new_pspace = {
        "aaa": pspace["aaa"],
        "aab": pspace["aab"],
        "abb": pspace["abb"],
        "bbb": pspace["bbb"],
    }
    new_t3_excitations = {
        "aaa" : [],
        "aab" : [],
        "abb" : [],
        "bbb" : []
    }

    if ordered_index:
        ct_aaa = np.max(pspace["aaa"].flatten()) + 1
        ct_aab = np.max(pspace["aab"].flatten()) + 1
        ct_abb = np.max(pspace["abb"].flatten()) + 1
        ct_bbb = np.max(pspace["bbb"].flatten()) + 1

    num_add = triples_list.shape[0]
    n3aaa = 0
    n3aab = 0
    n3abb = 0
    n3bbb = 0
    for n in range(num_add):
        num_alpha = int(sum([x % 2 for x in triples_list[n, :]]) / 2)
        idx = [spatial_orb_idx(p) - 1 for p in triples_list[n, :]]
        a, b, c, i, j, k = idx

        if num_alpha == 3:
            new_t3_excitations["aaa"].append([a+1, b+1, c+1, i+1, j+1, k+1])
            n3aaa += 1
            for perms_unocc in permutations((a, b, c)):
                for perms_occ in permutations((i, j, k)):
                    a, b, c = perms_unocc
                    i, j, k = perms_occ
                    if ordered_index:
                        new_pspace['aaa'][a, b, c, i, j, k] = ct_aaa
                        ct_aaa += 1
                    else:
                        new_pspace['aaa'][a, b, c, i, j, k] = True
                   
        if num_alpha == 2:
            new_t3_excitations["aab"].append([a+1, b+1, c+1, i+1, j+1, k+1])
            n3aab += 1
            for perms_unocc in permutations((a, b)):
                for perms_occ in permutations((i, j)):
                    a, b = perms_unocc
                    i, j = perms_occ
                    if ordered_index:
                        new_pspace['aab'][a, b, c, i, j, k] = ct_aab
                        ct_aab += 1
                    else:
                        new_pspace['aab'][a, b, c, i, j, k] = True

        if num_alpha == 1:
            new_t3_excitations["abb"].append([a+1, b+1, c+1, i+1, j+1, k+1])
            n3abb += 1
            for perms_unocc in permutations((b, c)):
                for perms_occ in permutations((j, k)):
                    b, c = perms_unocc
                    j, k = perms_occ
                    if ordered_index:
                        new_pspace['abb'][a, b, c, i, j, k] = ct_abb
                        ct_abb += 1
                    else:
                        new_pspace['abb'][a, b, c, i, j, k] = True

        if num_alpha == 0:
            new_t3_excitations["bbb"].append([a+1, b+1, c+1, i+1, j+1, k+1])
            n3bbb += 1
            for perms_unocc in permutations((a, b, c)):
                for perms_occ in permutations((i, j, k)):
                    a, b, c = perms_unocc
                    i, j, k = perms_occ
                    if ordered_index:
                        new_pspace['bbb'][a, b, c, i, j, k] = ct_bbb
                        ct_bbb += 1
                    else:
                        new_pspace['bbb'][a, b, c, i, j, k] = True

    # Update the t3 excitation lists with the new content from the moment selection
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3aaa, "aaa") 
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3aab, "aab") 
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3abb, "abb") 
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3bbb, "bbb") 

    return new_pspace, new_t3_excitations


def adaptive_triples_selection_from_moments(moments, pspace, t3_excitations, num_add, system):

    def _add_t3_excitations(new_t3_excitations, old_t3_excitations, num_add, spincase):
        if num_add > 0:
            if np.array_equal(old_t3_excitations[spincase][0, :], np.ones(6)):
                new_t3_excitations[spincase] = np.asarray(new_t3_excitations[spincase])
            else:
                new_t3_excitations[spincase] = np.vstack(
                    (old_t3_excitations[spincase], np.asarray(new_t3_excitations[spincase])))
        else:
            new_t3_excitations[spincase] = old_t3_excitations[spincase].copy()

        return new_t3_excitations

    # should these be copied?
    new_pspace = {
        "aaa": pspace["aaa"],
        "aab": pspace["aab"],
        "abb": pspace["abb"],
        "bbb": pspace["bbb"],
    }
    new_t3_excitations = {
        "aaa": [],
        "aab": [],
        "abb": [],
        "bbb": []
    }

    n3aaa = system.noccupied_alpha**3 * system.nunoccupied_alpha**3
    n3aab = system.noccupied_alpha**2 * system.noccupied_beta * system.nunoccupied_alpha**2 * system.nunoccupied_beta
    n3abb = system.noccupied_alpha * system.noccupied_beta**2 * system.nunoccupied_alpha * system.nunoccupied_beta**2
    n3bbb = system.noccupied_beta**3 * system.nunoccupied_beta**3

    # Create full moment vector and populate it with different spin cases
    mvec = np.zeros(n3aaa + n3aab + n3abb + n3bbb)
    mvec[:n3aaa] = moments["aaa"].flatten()
    mvec[n3aaa:n3aaa+n3aab] = moments["aab"].flatten()
    mvec[n3aaa+n3aab:n3aaa+n3aab+n3abb] = moments["abb"].flatten()
    mvec[n3aaa+n3aab+n3abb:] = moments["bbb"].flatten()

    idx = np.flip(np.argsort(abs(mvec))) # sort the moments in descending order by absolute value

    ct = 0
    n3a = 0
    n3b = 0
    n3c = 0
    n3d = 0
    while n3a + n3b + n3c + n3d < num_add:
        if idx[ct] < n3aaa:
            a, b, c, i, j, k = np.unravel_index(idx[ct], moments["aaa"].shape)
            if pspace["aaa"][a, b, c, i, j, k]:
                ct += 1
                continue
            else:
                n3a += 1
                new_t3_excitations["aaa"].append([a + 1, b + 1, c + 1, i + 1, j + 1, k + 1])
                for perms_unocc in permutations((a, b, c)):
                    for perms_occ in permutations((i, j, k)):
                        a, b, c = perms_unocc
                        i, j, k = perms_occ
                        new_pspace['aaa'][a, b, c, i, j, k] = True
        elif idx[ct] < n3aaa + n3aab:
            a, b, c, i, j, k = np.unravel_index(idx[ct] - n3aaa, moments["aab"].shape)
            if pspace["aab"][a, b, c, i, j, k]:
                ct += 1
                continue
            else:
                n3b += 1
                new_t3_excitations["aab"].append([a + 1, b + 1, c + 1, i + 1, j + 1, k + 1])
                for perms_unocc in permutations((a, b)):
                    for perms_occ in permutations((i, j)):
                        a, b = perms_unocc
                        i, j = perms_occ
                        new_pspace['aab'][a, b, c, i, j, k] = True
        elif idx[ct] < n3aaa + n3aab + n3abb:
            a, b, c, i, j, k = np.unravel_index(idx[ct] - n3aaa - n3aab, moments["abb"].shape)
            if pspace["abb"][a, b, c, i, j, k]:
                ct += 1
                continue
            else:
                n3c += 1
                new_t3_excitations["abb"].append([a + 1, b + 1, c + 1, i + 1, j + 1, k + 1])
                for perms_unocc in permutations((b, c)):
                    for perms_occ in permutations((j, k)):
                        b, c = perms_unocc
                        j, k = perms_occ
                        new_pspace['abb'][a, b, c, i, j, k] = True
        else:
            a, b, c, i, j, k = np.unravel_index(idx[ct] - n3aaa - n3aab - n3abb, moments["bbb"].shape)
            if pspace["bbb"][a, b, c, i, j, k]:
                ct += 1
                continue
            else:
                n3d += 1
                new_t3_excitations["bbb"].append([a + 1, b + 1, c + 1, i + 1, j + 1, k + 1])
                for perms_unocc in permutations((a, b, c)):
                    for perms_occ in permutations((i, j, k)):
                        a, b, c = perms_unocc
                        i, j, k = perms_occ
                        new_pspace['bbb'][a, b, c, i, j, k] = True

    # Update the t3 excitation lists with the new content from the moment selection
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3a, "aaa")
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3b, "aab")
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3c, "abb")
    new_t3_excitations = _add_t3_excitations(new_t3_excitations, t3_excitations, n3d, "bbb")

    return new_pspace, new_t3_excitations


def add_spinorbital_quadruples_to_pspace(quadruples_list, pspace):
    """Expand the size of the previous P space using the determinants contained in the list
    of quadruples (stored as a, b, c, d, i, j, k, l) in quadruples_list. The variable quadruples_list stores
    quadruples in spinorbital form, where all orbital indices start from 1 and odd indices
    correspond to alpha orbitals while even indices corresopnd to beta orbitals."""

    # should these be copied?
    new_pspace = {
        "aaaa": pspace["aaaa"],
        "aaab": pspace["aaab"],
        "aabb": pspace["aabb"],
        "abbb": pspace["abbb"],
        "bbbb": pspace["bbbb"],
    }

    num_add = quadruples_list.shape[0]
    for n in range(num_add):
        num_alpha = int(sum([x % 2 for x in quadruples_list[n, :]]) / 2)
        idx = [spatial_orb_idx(p) - 1 for p in quadruples_list[n, :]]
        a, b, c, d, i, j, k, l = idx
        if num_alpha == 4:
            new_pspace['aaaa'][a, b, c, d, i, j, k, l] = 1
        elif num_alpha == 3:
            new_pspace['aaab'][a, b, c, d, i, j, k, l] = 1
        elif num_alpha == 2:
            new_pspace['aabb'][a, b, c, d, i, j, k, l] = 1
        elif num_alpha == 1:
            new_pspace['abbb'][a, b, c, d, i, j, k, l] = 1
        else:
            new_pspace['bbbb'][a, b, c, d, i, j, k, l] = 1

    return new_pspace


def get_active_pspace(system, nact_o, nact_u, num_active=1):
    from ccpy.utilities.active_space import active_hole, active_particle

    def count_active_occ_alpha(occ):
        return sum([active_hole(i, system.noccupied_alpha, nact_o) for i in occ])

    def count_active_occ_beta(occ):
        return sum([active_hole(i, system.noccupied_beta, nact_o) for i in occ])

    def count_active_unocc_alpha(unocc):
        return sum([active_particle(a, nact_u) for a in unocc])

    def count_active_unocc_beta(unocc):
        return sum([active_particle(a, nact_u) for a in unocc])

    pspace = get_empty_pspace(system, 3)

    # aaa
    for i in range(system.noccupied_alpha):
        for j in range(system.noccupied_alpha):
            for k in range(system.noccupied_alpha):
                for a in range(system.nunoccupied_alpha):
                    for b in range(system.nunoccupied_alpha):
                        for c in range(system.nunoccupied_alpha):
                            if count_active_occ_alpha([i, j, k]) >= num_active and count_active_unocc_alpha([a, b, c]) >= num_active:
                                pspace[0]["aaa"][a, b, c, i, j, k] = 1
    # aab
    for i in range(system.noccupied_alpha):
        for j in range(system.noccupied_alpha):
            for k in range(system.noccupied_beta):
                for a in range(system.nunoccupied_alpha):
                    for b in range(system.nunoccupied_alpha):
                        for c in range(system.nunoccupied_beta):
                            if (count_active_occ_alpha([i, j]) + count_active_occ_beta([k])) >= num_active and (count_active_unocc_alpha([a, b]) + count_active_unocc_beta([c])) >= num_active:
                                pspace[0]["aab"][a, b, c, i, j, k] = 1

    # abb
    for i in range(system.noccupied_alpha):
        for j in range(system.noccupied_beta):
            for k in range(system.noccupied_beta):
                for a in range(system.nunoccupied_alpha):
                    for b in range(system.nunoccupied_beta):
                        for c in range(system.nunoccupied_beta):
                            if (count_active_occ_alpha([i]) + count_active_occ_beta([j, k])) >= num_active and (count_active_unocc_alpha([a]) + count_active_unocc_beta([b, c])) >= num_active:
                                pspace[0]["abb"][a, b, c, i, j, k] = 1
    # bbb
    for i in range(system.noccupied_beta):
        for j in range(system.noccupied_beta):
            for k in range(system.noccupied_beta):
                for a in range(system.nunoccupied_beta):
                    for b in range(system.nunoccupied_beta):
                        for c in range(system.nunoccupied_beta):
                            if count_active_occ_beta([i, j, k]) >= num_active and count_active_unocc_beta([a, b, c]) >= num_active:
                                pspace[0]["bbb"][a, b, c, i, j, k] = 1

    return pspace
