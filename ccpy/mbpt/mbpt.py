import time
from ccpy.utilities.updates import mbpt_loops

def calc_mbpt2(system, H):

    t_start = time.time()
    corr_energy = mbpt_loops.mbpt_loops.mp2(H.a.oo, H.a.vv, H.b.oo, H.b.vv,
                                            H.aa.oovv, H.aa.vvoo, H.ab.oovv, H.ab.vvoo, H.bb.oovv, H.bb.vvoo)
    t_end = time.time()
    minutes, seconds = divmod(t_end - t_start, 60)

    print('\n   MBPT(2) Calculation Summary')
    print('   -------------------------------------')
    print("   Completed in  ({:0.2f}m  {:0.2f}s)".format(minutes, seconds))
    print("   Reference = {:>10.10f}".format(system.reference_energy))
    print("   MBPT(2) = {:>10.10f}     ΔE = {:>10.10f}".format(system.reference_energy + corr_energy, corr_energy))

    return corr_energy

def calc_mbpt3(system, H):

    t_start = time.time()
    corr_energy2 = mbpt_loops.mbpt_loops.mp2(H.a.oo, H.a.vv, H.b.oo, H.b.vv,
                                            H.aa.oovv, H.aa.vvoo, H.ab.oovv, H.ab.vvoo, H.bb.oovv, H.bb.vvoo)
    corr_energy3 = mbpt_loops.mbpt_loops.mp3(H.a.oo, H.a.vv, H.b.oo, H.b.vv,
                                             H.aa.oovv, H.aa.vvoo, H.aa.voov, H.aa.oooo, H.aa.vvvv,
                                             H.ab.oovv, H.ab.vvoo, H.ab.voov, H.ab.ovvo, H.ab.vovo, H.ab.ovov, H.ab.oooo, H.ab.vvvv,
                                             H.bb.oovv, H.bb.vvoo, H.bb.voov, H.bb.oooo, H.bb.vvvv)
    t_end = time.time()
    minutes, seconds = divmod(t_end - t_start, 60)

    corr_energy = corr_energy2 + corr_energy3

    print('\n   MBPT(3) Calculation Summary')
    print('   -------------------------------------')
    print("   Completed in  ({:0.2f}m  {:0.2f}s)".format(minutes, seconds))
    print("   Reference = {:>10.10f}".format(system.reference_energy))
    print("   2nd-order contribution = {:>10.10f}".format(corr_energy2))
    print("   3rd-order contribution = {:>10.10f}".format(corr_energy3))
    print("   MBPT(3) = {:>10.10f}     ΔE = {:>10.10f}".format(system.reference_energy + corr_energy, corr_energy))

    return corr_energy

def calc_mbpt4(system, H):

    t_start = time.time()
    corr_energy2 = mbpt_loops.mbpt_loops.mp2(H.a.oo, H.a.vv, H.b.oo, H.b.vv,
                                            H.aa.oovv, H.aa.vvoo, H.ab.oovv, H.ab.vvoo, H.bb.oovv, H.bb.vvoo)
    corr_energy3 = mbpt_loops.mbpt_loops.mp3(H.a.oo, H.a.vv, H.b.oo, H.b.vv,
                                             H.aa.oovv, H.aa.vvoo, H.aa.voov, H.aa.oooo, H.aa.vvvv,
                                             H.ab.oovv, H.ab.vvoo, H.ab.voov, H.ab.ovvo, H.ab.vovo, H.ab.ovov, H.ab.oooo, H.ab.vvvv,
                                             H.bb.oovv, H.bb.vvoo, H.bb.voov, H.bb.oooo, H.bb.vvvv)
    corr_energy4 = mbpt_loops.mbpt_loops.mp4(H.a.oo, H.a.vv, H.b.oo, H.b.vv,
                                             H.aa.oovv, H.aa.vvoo, H.aa.voov, H.aa.oooo, H.aa.vvvv, H.aa.vooo, H.aa.vvov, H.aa.ooov, H.aa.vovv,
                                             H.ab.oovv, H.ab.vvoo, H.ab.voov, H.ab.ovvo, H.ab.vovo, H.ab.ovov, H.ab.oooo, H.ab.vvvv,
                                             H.ab.vooo, H.ab.ovoo, H.ab.vvov, H.ab.vvvo, H.ab.ooov, H.ab.oovo, H.ab.vovv, H.ab.ovvv,
                                             H.bb.oovv, H.bb.vvoo, H.bb.voov, H.bb.oooo, H.bb.vvvv, H.bb.vooo, H.bb.vvov, H.bb.ooov, H.bb.vovv)
    t_end = time.time()
    minutes, seconds = divmod(t_end - t_start, 60)

    corr_energy = corr_energy2 + corr_energy3 + corr_energy4

    print('\n   MBPT(4) Calculation Summary')
    print('   -------------------------------------')
    print("   Completed in  ({:0.2f}m  {:0.2f}s)".format(minutes, seconds))
    print("   Reference = {:>10.10f}".format(system.reference_energy))
    print("   2nd-order contribution = {:>10.10f}".format(corr_energy2))
    print("   3rd-order contribution = {:>10.10f}".format(corr_energy3))
    print("   4th-order contribution = {:>10.10f}".format(corr_energy4))
    print("   MBPT(4) = {:>10.10f}     ΔE = {:>10.10f}".format(system.reference_energy + corr_energy, corr_energy))

    return corr_energy
