module ccp3_full_correction

      use omp_lib

      implicit none

      contains
         
              subroutine ccp3a_ijk(deltaA,deltaB,deltaC,deltaD,&
                                    i,j,k,omega,&
                                    M3A,L3A,t3a_excits,&
                                    fA_oo,fA_vv,H1A_oo,H1A_vv,&
                                    H2A_voov,H2A_oooo,H2A_vvvv,&
                                    D3A_O,D3A_V,n3aaa,noa,nua)

                        integer, intent(in) :: noa, nua, n3aaa
                        integer, intent(in) :: i, j, k
                        integer, intent(in) :: t3a_excits(n3aaa,6)
                        real(kind=8), intent(in) :: M3A(1:nua,1:nua,1:nua),&
                                                    L3A(1:nua,1:nua,1:nua),&
                                                    fA_oo(1:noa,1:noa),fA_vv(1:nua,1:nua),&
                                                    H1A_oo(1:noa,1:noa),H1A_vv(1:nua,1:nua),&
                                                    H2A_voov(1:nua,1:noa,1:noa,1:nua),&
                                                    H2A_oooo(1:noa,1:noa,1:noa,1:noa),&
                                                    H2A_vvvv(1:nua,1:nua,1:nua,1:nua),&
                                                    D3A_O(1:nua,1:noa,1:noa),&
                                                    D3A_V(1:nua,1:noa,1:nua)
                        real(kind=8), intent(in) :: omega
                        ! output variables
                        real(kind=8), intent(inout) :: deltaA
                        !f2py intent(in,out) :: deltaA
                        real(kind=8), intent(inout) :: deltaB
                        !f2py intent(in,out) :: deltaB
                        real(kind=8), intent(inout) :: deltaC
                        !f2py intent(in,out) :: deltaC
                        real(kind=8), intent(inout) :: deltaD
                        !f2py intent(in,out) :: deltaD
                        
                        ! Low-memory looping variables
                        logical(kind=1) :: qspace(nua,nua,nua)
                        integer :: nloc, idet, idx
                        integer, allocatable :: loc_arr(:,:), idx_table(:,:,:)
                        integer :: excits_buff(n3aaa,6)
                        real(kind=8) :: amps_buff(n3aaa)
                        ! local variables
                        integer :: a, b, c
                        real(kind=8) :: D, LM

                        ! reorder t3a into (i,j,k) order
                        excits_buff(:,:) = t3a_excits(:,:)
                        amps_buff = 0.0
                        nloc = noa*(noa-1)*(noa-2)/6
                        allocate(loc_arr(2,nloc))
                        allocate(idx_table(noa,noa,noa))
                        call get_index_table3(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), noa, noa, noa)
                        call sort3(excits_buff, amps_buff, loc_arr, idx_table, (/4,5,6/), noa, noa, noa, nloc, n3aaa)
                        
                        ! Construct Q space for block (i,j,k)
                        qspace = .true.
                        idx = idx_table(i,j,k)
                        if (idx/=0) then
                           do idet = loc_arr(1,idx), loc_arr(2,idx)
                              a = excits_buff(idet,1); b = excits_buff(idet,2); c = excits_buff(idet,3);
                              qspace(a,b,c) = .false.
                           end do
                        end if
                        deallocate(idx_table,loc_arr)
                        
                        do a = 1, nua
                            do b = a+1, nua
                                do c = b+1, nua

                                    if (.not. qspace(a,b,c)) cycle
                                   
                                    LM = M3A(a,b,c) * L3A(a,b,c)

                                    D = fA_oo(i,i) + fA_oo(j,j) + fA_oo(k,k)&
                                    - fA_vv(a,a) - fA_vv(b,b) - fA_vv(c,c)

                                    deltaA = deltaA + LM/(omega+D)

                                    D = H1A_oo(i,i) + H1A_oo(j,j) + H1A_oo(k,k)&
                                    - H1A_vv(a,a) - H1A_vv(b,b) - H1A_vv(c,c)

                                    deltaB = deltaB + LM/(omega+D)

                                    D = D &
                                    -H2A_voov(a,i,i,a) - H2A_voov(b,i,i,b) - H2A_voov(c,i,i,c)&
                                    -H2A_voov(a,j,j,a) - H2A_voov(b,j,j,b) - H2A_voov(c,j,j,c)&
                                    -H2A_voov(a,k,k,a) - H2A_voov(b,k,k,b) - H2A_voov(c,k,k,c)&
                                    -H2A_oooo(j,i,j,i) - H2A_oooo(k,i,k,i) - H2A_oooo(k,j,k,j)&
                                    -H2A_vvvv(b,a,b,a) - H2A_vvvv(c,a,c,a) - H2A_vvvv(c,b,c,b)

                                    deltaC = deltaC + LM/(omega+D)

                                    D = D &
                                    +D3A_O(a,i,j)+D3A_O(a,i,k)+D3A_O(a,j,k)&
                                    +D3A_O(b,i,j)+D3A_O(b,i,k)+D3A_O(b,j,k)&
                                    +D3A_O(c,i,j)+D3A_O(c,i,k)+D3A_O(c,j,k)&
                                    -D3A_V(a,i,b)-D3A_V(a,i,c)-D3A_V(b,i,c)&
                                    -D3A_V(a,j,b)-D3A_V(a,j,c)-D3A_V(b,j,c)&
                                    -D3A_V(a,k,b)-D3A_V(a,k,c)-D3A_V(b,k,c)

                                    deltaD = deltaD + LM/(omega+D)

                                end do
                            end do
                        end do
                 
              end subroutine ccp3a_ijk
         
              subroutine ccp3b_ijk(deltaA,deltaB,deltaC,deltaD,&
                                    i,j,k,omega,&
                                    M3B,L3B,t3b_excits,&
                                    fA_oo,fA_vv,fB_oo,fB_vv,&
                                    H1A_oo,H1A_vv,H1B_oo,H1B_vv,&
                                    H2A_voov,H2A_oooo,H2A_vvvv,&
                                    H2B_ovov,H2B_vovo,&
                                    H2B_oooo,H2B_vvvv,&
                                    H2C_voov,&
                                    D3A_O,D3A_V,D3B_O,D3B_V,D3C_O,D3C_V,&
                                    n3aab,noa,nua,nob,nub)

                        integer, intent(in) :: noa, nua, nob, nub, n3aab
                        integer, intent(in) :: i, j, k
                        integer, intent(in) :: t3b_excits(n3aab,6)
                        real(kind=8), intent(in) :: M3B(1:nua,1:nua,1:nub),&
                                                    L3B(1:nua,1:nua,1:nub),&
                                                    fA_oo(1:noa,1:noa),fA_vv(1:nua,1:nua),&
                                                    fB_oo(1:nob,1:nob),fB_vv(1:nub,1:nub),&
                                                    H1A_oo(1:noa,1:noa),H1A_vv(1:nua,1:nua),&
                                                    H1B_oo(1:nob,1:nob),H1B_vv(1:nub,1:nub),&
                                                    H2A_voov(1:nua,1:noa,1:noa,1:nua),&
                                                    H2A_oooo(1:noa,1:noa,1:noa,1:noa),&
                                                    H2A_vvvv(1:nua,1:nua,1:nua,1:nua),&
                                                    H2B_ovov(1:noa,1:nub,1:noa,1:nub),&
                                                    H2B_vovo(1:nua,1:nob,1:nua,1:nob),&
                                                    H2B_oooo(1:noa,1:nob,1:noa,1:nob),&
                                                    H2B_vvvv(1:nua,1:nub,1:nua,1:nub),&
                                                    H2C_voov(1:nub,1:nob,1:nob,1:nub),&
                                                    D3A_O(1:nua,1:noa,1:noa),&
                                                    D3A_V(1:nua,1:noa,1:nua),&
                                                    D3B_O(1:nua,1:noa,1:nob),&
                                                    D3B_V(1:nua,1:noa,1:nub),&
                                                    D3C_O(1:nub,1:noa,1:nob),&
                                                    D3C_V(1:nua,1:nob,1:nub)
                        real(kind=8), intent(in) :: omega
                        ! output variables
                        real(kind=8), intent(inout) :: deltaA
                        !f2py intent(in,out) :: deltaA
                        real(kind=8), intent(inout) :: deltaB
                        !f2py intent(in,out) :: deltaB
                        real(kind=8), intent(inout) :: deltaC
                        !f2py intent(in,out) :: deltaC
                        real(kind=8), intent(inout) :: deltaD
                        !f2py intent(in,out) :: deltaD
                        
                        ! Low-memory looping variables
                        logical(kind=1) :: qspace(nua,nua,nub)
                        integer :: nloc, idet, idx
                        integer, allocatable :: loc_arr(:,:), idx_table(:,:,:)
                        integer :: excits_buff(n3aab,6)
                        real(kind=8) :: amps_buff(n3aab)
                        ! local variables
                        integer :: a, b, c
                        real(kind=8) :: D, LM

                        ! reorder t3b into (i,j,k) order
                        excits_buff(:,:) = t3b_excits(:,:)
                        amps_buff = 0.0
                        nloc = noa*(noa-1)/2*nob
                        allocate(loc_arr(2,nloc))
                        allocate(idx_table(noa,noa,nob))
                        call get_index_table3(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), noa, noa, nob)
                        call sort3(excits_buff, amps_buff, loc_arr, idx_table, (/4,5,6/), noa, noa, nob, nloc, n3aab)
                        
                        ! Construct Q space for block (i,j,k)
                        qspace = .true.
                        idx = idx_table(i,j,k)
                        if (idx/=0) then
                           do idet = loc_arr(1,idx), loc_arr(2,idx)
                              a = excits_buff(idet,1); b = excits_buff(idet,2); c = excits_buff(idet,3);
                              qspace(a,b,c) = .false.
                           end do
                        end if
                        deallocate(idx_table,loc_arr)
                        
                        do a = 1, nua
                            do b = a+1, nua
                                do c = 1, nub

                                    if (.not. qspace(a,b,c)) cycle
                                   
                                    LM = M3B(a,b,c) * L3B(a,b,c)
                                    
                                    D = fA_oo(i,i) + fA_oo(j,j) + fB_oo(k,k)&
                                    - fA_vv(a,a) - fA_vv(b,b) - fB_vv(c,c)
   
                                    deltaA = deltaA + LM/(omega+D)
   
                                    D = H1A_oo(i,i) + H1A_oo(j,j) + H1B_oo(k,k)&
                                    - H1A_vv(a,a) - H1A_vv(b,b) - H1B_vv(c,c)
   
                                    deltaB = deltaB + LM/(omega+D)
   
                                    D = D &
                                    -H2A_voov(a,i,i,a)-H2A_voov(b,i,i,b)+H2B_ovov(i,c,i,c)&
                                    -H2A_voov(a,j,j,a)-H2A_voov(b,j,j,b)+H2B_ovov(j,c,j,c)&
                                    +H2B_vovo(a,k,a,k)+H2B_vovo(b,k,b,k)-H2C_voov(c,k,k,c)&
                                    -H2A_oooo(j,i,j,i)-H2B_oooo(i,k,i,k)-H2B_oooo(j,k,j,k)&
                                    -H2A_vvvv(b,a,b,a)-H2B_vvvv(a,c,a,c)-H2B_vvvv(b,c,b,c)
   
                                    deltaC = deltaC + LM/(omega+D)
   
                                    D = D &
                                    +D3A_O(a,i,j)+D3B_O(a,i,k)+D3B_O(a,j,k)&
                                    +D3A_O(b,i,j)+D3B_O(b,i,k)+D3B_O(b,j,k)&
                                    +D3C_O(c,i,k)+D3C_O(c,j,k)&
                                    -D3A_V(a,i,b)-D3B_V(a,i,c)-D3B_V(b,i,c)&
                                    -D3A_V(a,j,b)-D3B_V(a,j,c)-D3B_V(b,j,c)&
                                    -D3C_V(a,k,c)-D3C_V(b,k,c)
   
                                    deltaD = deltaD + LM/(omega+D)
                                end do
                            end do
                        end do
              end subroutine ccp3b_ijk
         
              subroutine ccp3c_ijk(deltaA,deltaB,deltaC,deltaD,&
                                    i,j,k,omega,&
                                    M3C,L3C,t3c_excits,&
                                    fA_oo,fA_vv,fB_oo,fB_vv,&
                                    H1A_oo,H1A_vv,H1B_oo,H1B_vv,&
                                    H2A_voov,&
                                    H2B_ovov,H2B_vovo,&
                                    H2B_oooo,H2B_vvvv,&
                                    H2C_voov,H2C_oooo,H2C_vvvv,&
                                    D3B_O,D3B_V,D3C_O,D3C_V,D3D_O,D3D_V,&
                                    n3abb,noa,nua,nob,nub)

                        integer, intent(in) :: noa, nua, nob, nub, n3abb
                        integer, intent(in) :: i, j, k
                        integer, intent(in) :: t3c_excits(n3abb,6)
                        real(kind=8), intent(in) :: M3C(1:nua,1:nub,1:nub),&
                                                    L3C(1:nua,1:nub,1:nub),&
                                                    fA_oo(1:noa,1:noa),fA_vv(1:nua,1:nua),&
                                                    fB_oo(1:nob,1:nob),fB_vv(1:nub,1:nub),&
                                                    H1A_oo(1:noa,1:noa),H1A_vv(1:nua,1:nua),&
                                                    H1B_oo(1:nob,1:nob),H1B_vv(1:nub,1:nub),&
                                                    H2A_voov(1:nua,1:noa,1:noa,1:nua),&
                                                    H2B_ovov(1:noa,1:nub,1:noa,1:nub),&
                                                    H2B_vovo(1:nua,1:nob,1:nua,1:nob),&
                                                    H2B_oooo(1:noa,1:nob,1:noa,1:nob),&
                                                    H2B_vvvv(1:nua,1:nub,1:nua,1:nub),&
                                                    H2C_voov(1:nub,1:nob,1:nob,1:nub),&
                                                    H2C_oooo(1:nob,1:nob,1:nob,1:nob),&
                                                    H2C_vvvv(1:nub,1:nub,1:nub,1:nub),&
                                                    D3B_O(1:nua,1:noa,1:nob),&
                                                    D3B_V(1:nua,1:noa,1:nub),&
                                                    D3C_O(1:nub,1:noa,1:nob),&
                                                    D3C_V(1:nua,1:nob,1:nub),&
                                                    D3D_O(1:nub,1:nob,1:nob),&
                                                    D3D_V(1:nub,1:nob,1:nub)
                        real(kind=8), intent(in) :: omega
                        ! output variables
                        real(kind=8), intent(inout) :: deltaA
                        !f2py intent(in,out) :: deltaA
                        real(kind=8), intent(inout) :: deltaB
                        !f2py intent(in,out) :: deltaB
                        real(kind=8), intent(inout) :: deltaC
                        !f2py intent(in,out) :: deltaC
                        real(kind=8), intent(inout) :: deltaD
                        !f2py intent(in,out) :: deltaD
                        
                        ! Low-memory looping variables
                        logical(kind=1) :: qspace(nua,nub,nub)
                        integer :: nloc, idet, idx
                        integer, allocatable :: loc_arr(:,:), idx_table(:,:,:)
                        integer :: excits_buff(n3abb,6)
                        real(kind=8) :: amps_buff(n3abb)
                        ! local variables
                        integer :: a, b, c
                        real(kind=8) :: D, LM

                        ! reorder t3b into (i,j,k) order
                        excits_buff(:,:) = t3c_excits(:,:)
                        amps_buff = 0.0
                        nloc = nob*(nob-1)/2*noa
                        allocate(loc_arr(2,nloc))
                        allocate(idx_table(nob,nob,noa))
                        call get_index_table3(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), nob, nob, noa)
                        call sort3(excits_buff, amps_buff, loc_arr, idx_table, (/5,6,4/), nob, nob, noa, nloc, n3abb)
                        
                        ! Construct Q space for block (i,j,k)
                        qspace = .true.
                        idx = idx_table(j,k,i)
                        if (idx/=0) then
                           do idet = loc_arr(1,idx), loc_arr(2,idx)
                              a = excits_buff(idet,1); b = excits_buff(idet,2); c = excits_buff(idet,3);
                              qspace(a,b,c) = .false.
                           end do
                        end if
                        deallocate(idx_table,loc_arr)
                        
                        do a = 1, nua
                            do b = 1, nub
                                do c = b+1, nub
                                    if (.not. qspace(a,b,c)) cycle
                                    LM = M3C(a,b,c) * L3C(a,b,c)
   
                                    D = fA_oo(i,i) + fB_oo(j,j) + fB_oo(k,k)&
                                    - fA_vv(a,a) - fB_vv(b,b) - fB_vv(c,c)
   
                                    deltaA = deltaA + LM/(omega+D)
   
                                    D = H1A_oo(i,i) + H1B_oo(j,j) + H1B_oo(k,k)&
                                    - H1A_vv(a,a) - H1B_vv(b,b) - H1B_vv(c,c)
   
                                    deltaB = deltaB + LM/(omega+D)
   
                                    D = D &
                                    -H2A_voov(a,i,i,a)+H2B_ovov(i,b,i,b)+H2B_ovov(i,c,i,c)&
                                    +H2B_vovo(a,j,a,j)-H2C_voov(b,j,j,b)-H2C_voov(c,j,j,c)&
                                    +H2B_vovo(a,k,a,k)-H2C_voov(b,k,k,b)-H2C_voov(c,k,k,c)&
                                    -H2B_oooo(i,j,i,j)-H2B_oooo(i,k,i,k)-H2C_oooo(k,j,k,j)&
                                    -H2B_vvvv(a,b,a,b)-H2B_vvvv(a,c,a,c)-H2C_vvvv(c,b,c,b)
                                    
                                    deltaC = deltaC + LM/(omega+D)
                                    
                                    D = D &
                                    +D3B_O(a,i,j)+D3B_O(a,i,k)&
                                    +D3C_O(b,i,j)+D3C_O(b,i,k)+D3D_O(b,j,k)&
                                    +D3C_O(c,i,j)+D3C_O(c,i,k)+D3D_O(c,j,k)&
                                    -D3B_V(a,i,b)-D3B_V(a,i,c)&
                                    -D3C_V(a,j,b)-D3C_V(a,j,c)-D3D_V(b,j,c)&
                                    -D3C_V(a,k,b)-D3C_V(a,k,c)-D3D_V(b,k,c)
   
                                    deltaD = deltaD + LM/(omega+D)
                                end do
                            end do
                        end do
              end subroutine ccp3c_ijk
         
              subroutine ccp3d_ijk(deltaA,deltaB,deltaC,deltaD,&
                                   i,j,k,omega,&
                                   M3D,L3D,t3d_excits,&
                                   fB_oo,fB_vv,H1B_oo,H1B_vv,&
                                   H2C_voov,H2C_oooo,H2C_vvvv,&
                                   D3D_O,D3D_V,n3bbb,nob,nub)

                        integer, intent(in) :: nob, nub, n3bbb
                        integer, intent(in) :: i, j, k
                        integer, intent(in) :: t3d_excits(n3bbb,6)
                        real(kind=8), intent(in) :: M3D(1:nub,1:nub,1:nub),&
                                                    L3D(1:nub,1:nub,1:nub),&
                                                    fB_oo(1:nob,1:nob),fB_vv(1:nub,1:nub),&
                                                    H1B_oo(1:nob,1:nob),H1B_vv(1:nub,1:nub),&
                                                    H2C_voov(1:nub,1:nob,1:nob,1:nub),&
                                                    H2C_oooo(1:nob,1:nob,1:nob,1:nob),&
                                                    H2C_vvvv(1:nub,1:nub,1:nub,1:nub),&
                                                    D3D_O(1:nub,1:nob,1:nob),&
                                                    D3D_V(1:nub,1:nob,1:nub)
                        real(kind=8), intent(in) :: omega
                        ! output variables
                        real(kind=8), intent(inout) :: deltaA
                        !f2py intent(in,out) :: deltaA
                        real(kind=8), intent(inout) :: deltaB
                        !f2py intent(in,out) :: deltaB
                        real(kind=8), intent(inout) :: deltaC
                        !f2py intent(in,out) :: deltaC
                        real(kind=8), intent(inout) :: deltaD
                        !f2py intent(in,out) :: deltaD
                        
                        ! Low-memory looping variables
                        logical(kind=1) :: qspace(nub,nub,nub)
                        integer :: nloc, idet, idx
                        integer, allocatable :: loc_arr(:,:), idx_table(:,:,:)
                        integer :: excits_buff(n3bbb,6)
                        real(kind=8) :: amps_buff(n3bbb)
                        ! local variables
                        integer :: a, b, c
                        real(kind=8) :: D, LM

                        ! reorder t3d into (i,j,k) order
                        excits_buff(:,:) = t3d_excits(:,:)
                        amps_buff = 0.0
                        nloc = nob*(nob-1)*(nob-2)/6
                        allocate(loc_arr(2,nloc))
                        allocate(idx_table(nob,nob,nob))
                        call get_index_table3(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), nob, nob, nob)
                        call sort3(excits_buff, amps_buff, loc_arr, idx_table, (/4,5,6/), nob, nob, nob, nloc, n3bbb)
                        
                        ! Construct Q space for block (i,j,k)
                        qspace = .true.
                        idx = idx_table(i,j,k)
                        if (idx/=0) then
                           do idet = loc_arr(1,idx), loc_arr(2,idx)
                              a = excits_buff(idet,1); b = excits_buff(idet,2); c = excits_buff(idet,3);
                              qspace(a,b,c) = .false.
                           end do
                        end if
                        deallocate(idx_table,loc_arr)
                        
                        do a = 1, nub
                            do b = a+1, nub
                                do c = b+1, nub

                                    if (.not. qspace(a,b,c)) cycle
                                   
                                    LM = M3D(a,b,c) * L3D(a,b,c)

                                    D = fB_oo(i,i) + fB_oo(j,j) + fB_oo(k,k)&
                                    - fB_vv(a,a) - fB_vv(b,b) - fB_vv(c,c)

                                    deltaA = deltaA + LM/(omega+D)

                                    D = H1B_oo(i,i) + H1B_oo(j,j) + H1B_oo(k,k)&
                                    - H1B_vv(a,a) - H1B_vv(b,b) - H1B_vv(c,c)

                                    deltaB = deltaB + LM/(omega+D)

                                    D = D &
                                    -H2C_voov(a,i,i,a) - H2C_voov(b,i,i,b) - H2C_voov(c,i,i,c)&
                                    -H2C_voov(a,j,j,a) - H2C_voov(b,j,j,b) - H2C_voov(c,j,j,c)&
                                    -H2C_voov(a,k,k,a) - H2C_voov(b,k,k,b) - H2C_voov(c,k,k,c)&
                                    -H2C_oooo(j,i,j,i) - H2C_oooo(k,i,k,i) - H2C_oooo(k,j,k,j)&
                                    -H2C_vvvv(b,a,b,a) - H2C_vvvv(c,a,c,a) - H2C_vvvv(c,b,c,b)

                                    deltaC = deltaC + LM/(omega+D)

                                    D = D &
                                    +D3D_O(a,i,j)+D3D_O(a,i,k)+D3D_O(a,j,k)&
                                    +D3D_O(b,i,j)+D3D_O(b,i,k)+D3D_O(b,j,k)&
                                    +D3D_O(c,i,j)+D3D_O(c,i,k)+D3D_O(c,j,k)&
                                    -D3D_V(a,i,b)-D3D_V(a,i,c)-D3D_V(b,i,c)&
                                    -D3D_V(a,j,b)-D3D_V(a,j,c)-D3D_V(b,j,c)&
                                    -D3D_V(a,k,b)-D3D_V(a,k,c)-D3D_V(b,k,c)

                                    deltaD = deltaD + LM/(omega+D)

                                end do
                            end do
                        end do
                 
              end subroutine ccp3d_ijk
         
              subroutine build_moments3a_ijk(resid, qspace,&
                                             t3a_amps, t3a_excits,&
                                             t3b_amps, t3b_excits,&
                                             t2a,&
                                             H1A_oo, H1A_vv,&
                                             H2A_oovv, H2A_vvov, H2A_vooo,&
                                             H2A_oooo, H2A_voov, H2A_vvvv,&
                                             H2B_oovv, H2B_voov,&
                                             n3aaa, n3aab, num_q,&
                                             noa, nua, nob, nub)

                  integer, intent(in) :: noa, nua, nob, nub, n3aaa, n3aab, num_q
                  integer, intent(in) :: qspace(num_q,6)
                  integer, intent(in) :: t3a_excits(n3aaa,6), t3b_excits(n3aab,6)
                  real(kind=8), intent(in) :: t3a_amps(n3aaa), t3b_amps(n3aab)
                  real(kind=8), intent(in) :: t2a(nua,nua,noa,noa),&
                                              H1A_oo(noa,noa), H1A_vv(nua,nua),&
                                              H2A_oovv(noa,noa,nua,nua),&
                                              H2B_oovv(noa,nob,nua,nub),&
                                              H2A_vvov(nua,nua,nua,noa),& ! reordered
                                              H2A_vooo(noa,nua,noa,noa),& ! reordered
                                              H2A_oooo(noa,noa,noa,noa),&
                                              H2A_voov(noa,nua,nua,noa),& ! reordered
                                              H2A_vvvv(nua,nua,nua,nua),&
                                              H2B_voov(nob,nub,nua,noa)   ! reordered
                  
                  real(kind=8), intent(out) :: resid(num_q)

                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)

                  real(kind=8), allocatable :: amps_buff(:), t3a_amps_copy(:), xbuf(:,:,:,:)
                  integer, allocatable :: excits_buff(:,:), t3a_excits_copy(:,:)
                  
                  real(kind=8) :: val, denom, t_amp, res_mm23, hmatel
                  real(kind=8) :: hmatel1, hmatel2, hmatel3, hmatel4
                  integer :: ii, jj, kk, a, b, c, d, l, e, f, m, n, jdet
                  integer :: idx, nloc

                  ! Zero the residual container
                  resid = 0.0d0
                  
                  ! copy over t3a_amps and t3a_excits
                  allocate(t3a_amps_copy(n3aaa),t3a_excits_copy(n3aaa,6))
                  t3a_amps_copy(:) = t3a_amps(:)
                  t3a_excits_copy(:,:) = t3a_excits(:,:)

                  !!!! diagram 1: -A(i/jk) h1a(mi) * t3a(abcmjk)
                  !!!! diagram 3: 1/2 A(i/jk) h2a(mnij) * t3a(abcmnk)
                  ! NOTE: WITHIN THESE LOOPS, H1A(OO) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2
                  ! allocate new sorting arrays
                  nloc = nua*(nua-1)*(nua-2)/6*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,nua,noa))
                  !!! ABCK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/-1,nua/), (/3,noa/), nua, nua, nua, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,2,3,6/), nua, nua, nua, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,qspace,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua,num_q),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3a_excits_copy(jdet,4); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(oooo) | lmkabc >
                        !hmatel = h2a_oooo(l,m,i,j)
                        hmatel = h2a_oooo(m,l,j,i)
                        ! compute < ijkabc | h1a(oo) | lmkabc > = -A(ij)A(lm) h1a_oo(l,i) * delta(m,j)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (m==j) hmatel1 = -h1a_oo(l,i) ! (1)      < ijkabc | h1a(oo) | ljkabc >
                        if (m==i) hmatel2 = h1a_oo(l,j) ! (ij)     < ijkabc | h1a(oo) | likabc >
                        if (l==j) hmatel3 = h1a_oo(m,i) ! (lm)     < ijkabc | h1a(oo) | jmkabc >
                        if (l==i) hmatel4 = -h1a_oo(m,j) ! (ij)(lm) < ijkabc | h1a(oo) | imkabc >
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3  + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     ! (ik)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3a_excits_copy(jdet,4); m = t3a_excits_copy(jdet,5);
                           ! compute < ijkabc | h2a(oooo) | lmiabc >
                           !hmatel = -h2a_oooo(l,m,k,j)
                           hmatel = h2a_oooo(m,l,k,j)
                           ! compute < ijkabc | h1a(oo) | lmiabc > = A(jk)A(lm) h1a_oo(l,k) * delta(m,j)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (m==j) hmatel1 = h1a_oo(l,k) ! (1)      < ijkabc | h1a(oo) | ljiabc >
                           if (m==k) hmatel2 = -h1a_oo(l,j) ! (jk)     < ijkabc | h1a(oo) | lkiabc >
                           if (l==j) hmatel3 = -h1a_oo(m,k) ! (lm)
                           if (l==k) hmatel4 = h1a_oo(m,j) ! (jk)(lm)
                           hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3a_excits_copy(jdet,4); m = t3a_excits_copy(jdet,5);
                           ! compute < ijkabc | h2a(oooo) | lmjabc >
                           !hmatel = -h2a_oooo(l,m,i,k)
                           hmatel = -h2a_oooo(m,l,k,i)
                           ! compute < ijkabc | h1a(oo) | lmjabc > = A(ik)A(lm) h1a_oo(l,i) * delta(m,k)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (m==k) hmatel1 = h1a_oo(l,i) ! (1)      < ijkabc | h1a(oo) | lkjabc >
                           if (m==i) hmatel2 = -h1a_oo(l,k) ! (ik)
                           if (l==k) hmatel3 = -h1a_oo(m,i) ! (lm)
                           if (l==i) hmatel4 = h1a_oo(m,k) ! (ik)(lm)
                           hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABCI LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/-1,nua/), (/1,noa-2/), nua, nua, nua, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,2,3,4/), nua, nua, nua, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,i)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = t3a_excits_copy(jdet,5); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(oooo) | imnabc >
                        !hmatel = h2a_oooo(m,n,j,k)
                        hmatel = h2a_oooo(n,m,k,j)
                        ! compute < ijkabc | h1a(oo) | imnabc > = -A(jk)A(mn) h1a_oo(m,j) * delta(n,k)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (n==k) hmatel1 = -h1a_oo(m,j)  ! < ijkabc | h1a(oo) | imkabc >
                        if (n==j) hmatel2 = h1a_oo(m,k)
                        if (m==k) hmatel3 = h1a_oo(n,j)
                        if (m==j) hmatel4 = -h1a_oo(n,k)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = t3a_excits_copy(jdet,5); n = t3a_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | jmnabc >
                           !hmatel = -h2a_oooo(m,n,i,k)
                           hmatel = -h2a_oooo(n,m,k,i)
                           ! compute < ijkabc | h1a(oo) | jmnabc > = A(ik)A(mn) h1a_oo(m,i) * delta(n,k)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==k) hmatel1 = h1a_oo(m,i)
                           if (n==i) hmatel2 = -h1a_oo(m,k)
                           if (m==k) hmatel3 = -h1a_oo(n,i)
                           if (m==i) hmatel4 = h1a_oo(n,k)
                           hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                        end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = t3a_excits_copy(jdet,5); n = t3a_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | kmnabc >
                           !hmatel = -h2a_oooo(m,n,j,i)
                           hmatel = h2a_oooo(n,m,j,i)
                           ! compute < ijkabc | h1a(oo) | kmnabc > = A(ij)A(mn) h1a_oo(m,j) * delta(n,i)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==i) hmatel1 = -h1a_oo(m,j)
                           if (n==j) hmatel2 = h1a_oo(m,i)
                           if (m==i) hmatel3 = h1a_oo(n,j)
                           if (m==j) hmatel4 = -h1a_oo(n,i)
                           hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABCJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/-1,nua/), (/2,noa-1/), nua, nua, nua, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,2,3,5/), nua, nua, nua, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3a_excits_copy(jdet,4); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(oooo) | ljnabc >
                        !hmatel = h2a_oooo(l,n,i,k)
                        hmatel = h2a_oooo(n,l,k,i)
                        ! compute < ijkabc | h1a(oo) | ljnabc > = -A(ik)A(ln) h1a_oo(l,i) * delta(n,k)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (n==k) hmatel1 = -h1a_oo(l,i)
                        if (n==i) hmatel2 = h1a_oo(l,k)
                        if (l==k) hmatel3 = h1a_oo(n,i)
                        if (l==i) hmatel4 = -h1a_oo(n,k)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3a_excits_copy(jdet,4); n = t3a_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | linabc >
                           !hmatel = -h2a_oooo(l,n,j,k)
                           hmatel = -h2a_oooo(n,l,k,j)
                           ! compute < ijkabc | h1a(oo) | linabc > = A(jk)A(ln) h1a_oo(l,j) * delta(n,k)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==k) hmatel1 = h1a_oo(l,j)
                           if (n==j) hmatel2 = -h1a_oo(l,k)
                           if (l==k) hmatel3 = -h1a_oo(n,j)
                           if (l==j) hmatel4 = h1a_oo(n,k)
                           hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3a_excits_copy(jdet,4); n = t3a_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | lknabc >
                           !hmatel = -h2a_oooo(l,n,i,j)
                           hmatel = -h2a_oooo(n,l,j,i)
                           ! compute < ijkabc | h1a(oo) | lknabc > = A(ij)A(ln) h1a_oo(l,i) * delta(n,j)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==j) hmatel1 = h1a_oo(l,i)
                           if (n==i) hmatel2 = -h1a_oo(l,j)
                           if (l==j) hmatel3 = -h1a_oo(n,i)
                           if (l==i) hmatel4 = h1a_oo(n,j)
                           hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 2: A(a/bc) h1a(ae) * t3a(ebcijk)
                  !!!! diagram 4: 1/2 A(c/ab) h2a(abef) * t3a(ebcijk)
                  ! NOTE: WITHIN THESE LOOPS, H1A(VV) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2
                  ! allocate new sorting arrays
                  nloc = noa*(noa-1)*(noa-2)/6*nua
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,noa,nua))
                  !!! IJKA LOOP !!!
                  call get_index_table(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), (/1,nua-2/), noa, noa, noa, nua)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/4,5,6,1/), noa, noa, noa, nua, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,a)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); f = t3a_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkaef >
                        !hmatel = h2a_vvvv(b,c,e,f)
                        !hmatel = h2a_vvvv(e,f,b,c)
                        hmatel = h2a_vvvv(f,e,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkaef > = A(bc)A(ef) h1a_vv(b,e) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = h1a_vv(e,b)  !h1a_vv(b,e) ! (1)
                        if (b==f) hmatel2 = -h1a_vv(e,c) !-h1a_vv(c,e) ! (bc)
                        if (c==e) hmatel3 = -h1a_vv(f,b) !-h1a_vv(b,f) ! (ef)
                        if (b==e) hmatel4 = h1a_vv(f,c)  ! h1a_vv(c,f) ! (bc)(ef)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); f = t3a_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkbef >
                        !hmatel = -h2a_vvvv(a,c,e,f)
                        !hmatel = -h2a_vvvv(e,f,a,c)
                        hmatel = -h2a_vvvv(f,e,c,a)
                        ! compute < ijkabc | h1a(vv) | ijkbef > = -A(ac)A(ef) h1a_vv(a,e) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = -h1a_vv(e,a) !-h1a_vv(a,e) ! (1)
                        if (a==f) hmatel2 = h1a_vv(e,c)  !h1a_vv(c,e) ! (ac)
                        if (c==e) hmatel3 = h1a_vv(f,a)  !h1a_vv(a,f) ! (ef)
                        if (a==e) hmatel4 = -h1a_vv(f,c) !-h1a_vv(c,f) ! (ac)(ef)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); f = t3a_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkcef >
                        !hmatel = -h2a_vvvv(b,a,e,f)
                        !hmatel = -h2a_vvvv(e,f,b,a)
                        hmatel = h2a_vvvv(f,e,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkcef > = -A(ab)A(ef) h1a_vv(b,e) * delta(a,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (a==f) hmatel1 = -h1a_vv(e,b) !-h1a_vv(b,e) ! (1)
                        if (b==f) hmatel2 = h1a_vv(e,a)  !h1a_vv(a,e) ! (ab)
                        if (a==e) hmatel3 = h1a_vv(f,b)  !h1a_vv(b,f) ! (ef)
                        if (b==e) hmatel4 = -h1a_vv(f,a) !-h1a_vv(a,f) ! (ab)(ef)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! IJKB LOOP !!!
                  call get_index_table(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), (/2,nua-1/), noa, noa, noa, nua)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/4,5,6,2/), noa, noa, noa, nua, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,b)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); f = t3a_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdbf >
                        !hmatel = h2a_vvvv(a,c,d,f)
                        !hmatel = h2a_vvvv(d,f,a,c)
                        hmatel = h2a_vvvv(f,d,c,a)
                        ! compute < ijkabc | h1a(vv) | ijkdbf > = A(ac)A(df) h1a_vv(a,d) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = h1a_vv(d,a)  !h1a_vv(a,d) ! (1)
                        if (a==f) hmatel2 = -h1a_vv(d,c) !-h1a_vv(c,d) ! (ac)
                        if (c==d) hmatel3 = -h1a_vv(f,a) !-h1a_vv(a,f) ! (df)
                        if (a==d) hmatel4 = h1a_vv(f,c)  !h1a_vv(c,f) ! (ac)(df)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); f = t3a_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdaf >
                        !hmatel = -h2a_vvvv(b,c,d,f)
                        !hmatel = -h2a_vvvv(d,f,b,c)
                        hmatel = -h2a_vvvv(f,d,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkdaf > = -A(bc)A(df) h1a_vv(b,d) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = -h1a_vv(d,b) !-h1a_vv(b,d) ! (1)
                        if (b==f) hmatel2 = h1a_vv(d,c)  !h1a_vv(c,d) ! (bc)
                        if (c==d) hmatel3 = h1a_vv(f,b)  !h1a_vv(b,f) ! (df)
                        if (b==d) hmatel4 = -h1a_vv(f,c) !-h1a_vv(c,f) ! (bc)(df)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); f = t3a_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdcf >
                        !hmatel = -h2a_vvvv(a,b,d,f)
                        !hmatel = -h2a_vvvv(d,f,a,b)
                        hmatel = -h2a_vvvv(f,d,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkdcf > = -A(ab)A(df) h1a_vv(a,d) * delta(b,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==f) hmatel1 = -h1a_vv(d,a) !-h1a_vv(a,d) ! (1)
                        if (a==f) hmatel2 = h1a_vv(d,b)  !h1a_vv(b,d) ! (ab)
                        if (b==d) hmatel3 = h1a_vv(f,a)  !h1a_vv(a,f) ! (df)
                        if (a==d) hmatel4 = -h1a_vv(f,b) !-h1a_vv(b,f) ! (ab)(df)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! IJKC LOOP !!!
                  call get_index_table(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), (/3,nua/), noa, noa, noa, nua)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/4,5,6,3/), noa, noa, noa, nua, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); e = t3a_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdec >
                        !hmatel = h2a_vvvv(a,b,d,e)
                        !hmatel = h2a_vvvv(d,e,a,b)
                        hmatel = h2a_vvvv(e,d,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkdec > = A(ab)A(de) h1a_vv(a,d) * delta(b,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==e) hmatel1 = h1a_vv(d,a)  !h1a_vv(a,d) ! (1)
                        if (a==e) hmatel2 = -h1a_vv(d,b) !-h1a_vv(b,d) ! (ab)
                        if (b==d) hmatel3 = -h1a_vv(e,a) !-h1a_vv(a,e) ! (de)
                        if (a==d) hmatel4 = h1a_vv(e,b)  !h1a_vv(b,e) ! (ab)(de)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     ! (ac)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); e = t3a_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdea >
                        !hmatel = -h2a_vvvv(c,b,d,e)
                        !hmatel = -h2a_vvvv(d,e,c,b)
                        hmatel = h2a_vvvv(e,d,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkdea > = -A(bc)A(de) h1a_vv(c,d) * delta(b,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==e) hmatel1 = -h1a_vv(d,c) !-h1a_vv(c,d) ! (1)
                        if (c==e) hmatel2 = h1a_vv(d,b)  !h1a_vv(b,d) ! (bc)
                        if (b==d) hmatel3 = h1a_vv(e,c)  !h1a_vv(c,e) ! (de)
                        if (c==d) hmatel4 = -h1a_vv(e,b) !-h1a_vv(b,e) ! (bc)(de)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); e = t3a_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdeb >
                        !hmatel = -h2a_vvvv(a,c,d,e)
                        !hmatel = -h2a_vvvv(d,e,a,c)
                        hmatel = -h2a_vvvv(e,d,c,a)
                        ! compute < ijkabc | h1a(vv) | ijkdeb > = -A(ac)A(de) h1a_vv(a,d) * delta(c,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==e) hmatel1 = -h1a_vv(d,a) !-h1a_vv(a,d) ! (1)
                        if (a==e) hmatel2 = h1a_vv(d,c)  !h1a_vv(c,d) ! (ac)
                        if (c==d) hmatel3 = h1a_vv(e,a)  !h1a_vv(a,e) ! (de)
                        if (a==d) hmatel4 = -h1a_vv(e,c) !-h1a_vv(c,e) ! (ac)(de)
                        hmatel = hmatel + 0.5d0*(hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel*t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 5: A(i/jk)A(a/bc) h2a(amie) * t3a(ebcmjk)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = (nua-1)*(nua-2)/2*(noa-1)*(noa-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnabf >
                        !hmatel = h2a_voov(c,n,k,f)
                        hmatel = h2a_voov(n,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnbcf >
                        !hmatel = h2a_voov(a,n,k,f)
                        hmatel = h2a_voov(n,f,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnacf >
                        !hmatel = -h2a_voov(b,n,k,f)
                        hmatel = -h2a_voov(n,f,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknabf >
                        !hmatel = h2a_voov(c,n,i,f)
                        hmatel = h2a_voov(n,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknbcf >
                        !hmatel = h2a_voov(a,n,i,f)
                        hmatel = h2a_voov(n,f,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknacf >
                        !hmatel = -h2a_voov(b,n,i,f)
                        hmatel = -h2a_voov(n,f,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknabf >
                        !hmatel = -h2a_voov(c,n,j,f)
                        hmatel = -h2a_voov(n,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknbcf >
                        !hmatel = -h2a_voov(a,n,j,f)
                        hmatel = -h2a_voov(n,f,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknacf >
                        !hmatel = h2a_voov(b,n,j,f)
                        hmatel = h2a_voov(n,f,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnaec >
                        !hmatel = h2a_voov(b,n,k,e)
                        hmatel = h2a_voov(n,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnbec >
                        !hmatel = -h2a_voov(a,n,k,e)
                        hmatel = -h2a_voov(n,e,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnaeb >
                        !hmatel = -h2a_voov(c,n,k,e)
                        hmatel = -h2a_voov(n,e,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknaec >
                        !hmatel = h2a_voov(b,n,i,e)
                        hmatel = h2a_voov(n,e,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknbec >
                        !hmatel = -h2a_voov(a,n,i,e)
                        hmatel = -h2a_voov(n,e,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknaeb >
                        !hmatel = -h2a_voov(c,n,i,e)
                        hmatel = -h2a_voov(n,e,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknaec >
                        !hmatel = -h2a_voov(b,n,j,e)
                        hmatel = -h2a_voov(n,e,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknbec >
                        !hmatel = h2a_voov(a,n,j,e)
                        hmatel = h2a_voov(n,e,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknaeb >
                        !hmatel = h2a_voov(c,n,j,e)
                        hmatel = h2a_voov(n,e,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIJ LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/2,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijndbc >
                        !hmatel = h2a_voov(a,n,k,d)
                        hmatel = h2a_voov(n,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijndac >
                        !hmatel = -h2a_voov(b,n,k,d)
                        hmatel = -h2a_voov(n,d,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijndab >
                        !hmatel = h2a_voov(c,n,k,d)
                        hmatel = h2a_voov(n,d,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jkndbc >
                        !hmatel = h2a_voov(a,n,i,d)
                        hmatel = h2a_voov(n,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jkndac >
                        !hmatel = -h2a_voov(b,n,i,d)
                        hmatel = -h2a_voov(n,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jkndab >
                        !hmatel = h2a_voov(c,n,i,d)
                        hmatel = h2a_voov(n,d,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ikndbc >
                        !hmatel = -h2a_voov(a,n,j,d)
                        hmatel = -h2a_voov(n,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ikndac >
                        !hmatel = h2a_voov(b,n,j,d)
                        hmatel = h2a_voov(n,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); n = t3a_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ikndab >
                        !hmatel = -h2a_voov(c,n,j,d)
                        hmatel = -h2a_voov(n,d,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkabf >
                        !hmatel = h2a_voov(c,m,j,f)
                        hmatel = h2a_voov(m,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkbcf >
                        !hmatel = h2a_voov(a,m,j,f)
                        hmatel = h2a_voov(m,f,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkacf >
                        !hmatel = -h2a_voov(b,m,j,f)
                        hmatel = -h2a_voov(m,f,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkabf >
                        !hmatel = -h2a_voov(c,m,i,f)
                        hmatel = -h2a_voov(m,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkbcf >
                        !hmatel = -h2a_voov(a,m,i,f)
                        hmatel = -h2a_voov(m,f,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkacf >
                        !hmatel = h2a_voov(b,m,i,f)
                        hmatel = h2a_voov(m,f,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjabf >
                        !hmatel = -h2a_voov(c,m,k,f)
                        hmatel = -h2a_voov(m,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjbcf >
                        !hmatel = -h2a_voov(a,m,k,f)
                        hmatel = -h2a_voov(m,f,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjacf >
                        !hmatel = h2a_voov(b,m,k,f)
                        hmatel = h2a_voov(m,f,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkaec >
                        !hmatel = h2a_voov(b,m,j,e)
                        hmatel = h2a_voov(m,e,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkbec >
                        !hmatel = -h2a_voov(a,m,j,e)
                        hmatel = -h2a_voov(m,e,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkaeb >
                        !hmatel = -h2a_voov(c,m,j,e)
                        hmatel = -h2a_voov(m,e,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkaec >
                        !hmatel = -h2a_voov(b,m,i,e)
                        hmatel = -h2a_voov(m,e,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkbec >
                        !hmatel = h2a_voov(a,m,i,e)
                        hmatel = h2a_voov(m,e,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkaeb >
                        !hmatel = h2a_voov(c,m,i,e)
                        hmatel = h2a_voov(m,e,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjaec >
                        !hmatel = -h2a_voov(b,m,k,e)
                        hmatel = -h2a_voov(m,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjbec >
                        !hmatel = h2a_voov(a,m,k,e)
                        hmatel = h2a_voov(m,e,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjaeb >
                        !hmatel = h2a_voov(c,m,k,e)
                        hmatel = h2a_voov(m,e,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkdbc >
                        !hmatel = h2a_voov(a,m,j,d)
                        hmatel = h2a_voov(m,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkdac >
                        !hmatel = -h2a_voov(b,m,j,d)
                        hmatel = -h2a_voov(m,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkdab >
                        !hmatel = h2a_voov(c,m,j,d)
                        hmatel = h2a_voov(m,d,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkdbc >
                        !hmatel = -h2a_voov(a,m,i,d)
                        hmatel = -h2a_voov(m,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkdac >
                        !hmatel = h2a_voov(b,m,i,d)
                        hmatel = h2a_voov(m,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkdab >
                        !hmatel = -h2a_voov(c,m,i,d)
                        hmatel = -h2a_voov(m,d,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjdbc >
                        !hmatel = -h2a_voov(a,m,k,d)
                        hmatel = -h2a_voov(m,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjdac >
                        !hmatel = h2a_voov(b,m,k,d)
                        hmatel = h2a_voov(m,d,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); m = t3a_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjdab >
                        !hmatel = -h2a_voov(c,m,k,d)
                        hmatel = -h2a_voov(m,d,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,2,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkabf >
                        !hmatel = h2a_voov(c,l,i,f)
                        hmatel = h2a_voov(l,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkbcf >
                        !hmatel = h2a_voov(a,l,i,f)
                        hmatel = h2a_voov(l,f,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkacf >
                        !hmatel = -h2a_voov(b,l,i,f)
                        hmatel = -h2a_voov(l,f,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likabf >
                        !hmatel = -h2a_voov(c,l,j,f)
                        hmatel = -h2a_voov(l,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likbcf >
                        !hmatel = -h2a_voov(a,l,j,f)
                        hmatel = -h2a_voov(l,f,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likacf >
                        !hmatel = h2a_voov(b,l,j,f)
                        hmatel = h2a_voov(l,f,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijabf >
                        !hmatel = h2a_voov(c,l,k,f)
                        hmatel = h2a_voov(l,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijbcf >
                        !hmatel = h2a_voov(a,l,k,f)
                        hmatel = h2a_voov(l,f,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3a_excits_copy(jdet,3); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijacf >
                        !hmatel = -h2a_voov(b,l,k,f)
                        hmatel = -h2a_voov(l,f,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/1,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkaec >
                        !hmatel = h2a_voov(b,l,i,e)
                        hmatel = h2a_voov(l,e,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkbec >
                        !hmatel = -h2a_voov(a,l,i,e)
                        hmatel = -h2a_voov(l,e,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkaeb >
                        !hmatel = -h2a_voov(c,l,i,e)
                        hmatel = -h2a_voov(l,e,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likaec >
                        !hmatel = -h2a_voov(b,l,j,e)
                        hmatel = -h2a_voov(l,e,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likbec >
                        !hmatel = h2a_voov(a,l,j,e)
                        hmatel = h2a_voov(l,e,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likaeb >
                        !hmatel = h2a_voov(c,l,j,e)
                        hmatel = h2a_voov(l,e,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijaec >
                        !hmatel = h2a_voov(b,l,k,e)
                        hmatel = h2a_voov(l,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijbec >
                        !hmatel = -h2a_voov(a,l,k,e)
                        hmatel = -h2a_voov(l,e,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3a_excits_copy(jdet,2); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijaeb >
                        !hmatel = -h2a_voov(c,l,k,e)
                        hmatel = -h2a_voov(l,e,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(t3a_excits_copy, t3a_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,&
                  !$omp t3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkdbc >
                        !hmatel = h2a_voov(a,l,i,d)
                        hmatel = h2a_voov(l,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkdac >
                        !hmatel = -h2a_voov(b,l,i,d)
                        hmatel = -h2a_voov(l,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkdab >
                        !hmatel = h2a_voov(c,l,i,d)
                        hmatel = h2a_voov(l,d,c,i)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likdbc >
                        !hmatel = -h2a_voov(a,l,j,d)
                        hmatel = -h2a_voov(l,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likdac >
                        !hmatel = h2a_voov(b,l,j,d)
                        hmatel = h2a_voov(l,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likdab >
                        !hmatel = -h2a_voov(c,l,j,d)
                        hmatel = -h2a_voov(l,d,c,j)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijdbc >
                        !hmatel = h2a_voov(a,l,k,d)
                        hmatel = h2a_voov(l,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijdac >
                        !hmatel = -h2a_voov(b,l,k,d)
                        hmatel = -h2a_voov(l,d,b,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3a_excits_copy(jdet,1); l = t3a_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijdab >
                        !hmatel = h2a_voov(c,l,k,d)
                        hmatel = h2a_voov(l,d,c,k)
                        resid(idet) = resid(idet) + hmatel * t3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 6: A(i/jk)A(a/bc) h2b(amie) * t3b(abeijm)
                  ! allocate and copy over t3b arrays
                  allocate(amps_buff(n3aab),excits_buff(n3aab,6))
                  amps_buff(:) = t3b_amps(:)
                  excits_buff(:,:) = t3b_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nua*(nua-1)/2*noa*(noa-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3a_excits_copy,excits_buff,&
                  !$omp t3a_amps_copy,amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | ijn~abf~ >
                        !hmatel = h2b_voov(c,n,k,f)
                        hmatel = h2b_voov(n,f,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | jkn~abf~ >
                        !hmatel = h2b_voov(c,n,i,f)
                        hmatel = h2b_voov(n,f,c,i)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | ikn~abf~ >
                        !hmatel = -h2b_voov(c,n,j,f)
                        hmatel = -h2b_voov(n,f,c,j)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | ijn~bcf~ >
                        !hmatel = h2b_voov(a,n,k,f)
                        hmatel = h2b_voov(n,f,a,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)(ac)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | jkn~bcf~ >
                        !hmatel = h2b_voov(a,n,i,f)
                        hmatel = h2b_voov(n,f,a,i)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (jk)(ac)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | ikn~bcf~ >
                        !hmatel = -h2b_voov(a,n,j,f)
                        hmatel = -h2b_voov(n,f,a,j)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | ijn~acf~ >
                        !hmatel = -h2b_voov(b,n,k,f)
                        hmatel = -h2b_voov(n,f,b,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)(bc)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | jkn~acf~ >
                        !hmatel = -h2b_voov(b,n,i,f)
                        hmatel = -h2b_voov(n,f,b,i)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (jk)(bc)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijkabc | h2b(voov) | ikn~acf~ >
                        !hmatel = h2b_voov(b,n,j,f)
                        hmatel = h2b_voov(n,f,b,j)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate t3 buffer arrays
                  deallocate(amps_buff,excits_buff)

                  !
                  ! Moment contributions
                  !
                  allocate(xbuf(noa,noa,nua,nua))
                  do a = 1,nua
                     do b = 1,nua
                        do ii = 1,noa
                           do jj = 1,noa
                              xbuf(jj,ii,b,a) = t2a(b,a,jj,ii)
                           end do
                        end do
                     end do
                  end do
                  !$omp parallel shared(resid,t3a_excits_copy,xbuf,H2A_vooo),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, noa
                          ! -A(k/ij)A(a/bc) h2a(amij) * t2a(bcmk)
                          resid(idet) = resid(idet) - H2A_vooo(m,a,i,j) * xbuf(m,k,b,c)
                          resid(idet) = resid(idet) + H2A_vooo(m,b,i,j) * xbuf(m,k,a,c)
                          resid(idet) = resid(idet) + H2A_vooo(m,c,i,j) * xbuf(m,k,b,a)
                          resid(idet) = resid(idet) + H2A_vooo(m,a,k,j) * xbuf(m,i,b,c)
                          resid(idet) = resid(idet) - H2A_vooo(m,b,k,j) * xbuf(m,i,a,c)
                          resid(idet) = resid(idet) - H2A_vooo(m,c,k,j) * xbuf(m,i,b,a)
                          resid(idet) = resid(idet) + H2A_vooo(m,a,i,k) * xbuf(m,j,b,c)
                          resid(idet) = resid(idet) - H2A_vooo(m,b,i,k) * xbuf(m,j,a,c)
                          resid(idet) = resid(idet) - H2A_vooo(m,c,i,k) * xbuf(m,j,b,a)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  deallocate(xbuf)

                  !$omp parallel shared(resid,t3a_excits_copy,t2a,H2A_vvov),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do e = 1, nua
                           ! A(i/jk)(c/ab) h2a(abie) * t2a(ecjk)
                          resid(idet) = resid(idet) + H2A_vvov(e,a,b,i) * t2a(e,c,j,k)
                          resid(idet) = resid(idet) - H2A_vvov(e,c,b,i) * t2a(e,a,j,k)
                          resid(idet) = resid(idet) - H2A_vvov(e,a,c,i) * t2a(e,b,j,k)
                          resid(idet) = resid(idet) - H2A_vvov(e,a,b,j) * t2a(e,c,i,k)
                          resid(idet) = resid(idet) + H2A_vvov(e,c,b,j) * t2a(e,a,i,k)
                          resid(idet) = resid(idet) + H2A_vvov(e,a,c,j) * t2a(e,b,i,k)
                          resid(idet) = resid(idet) - H2A_vvov(e,a,b,k) * t2a(e,c,j,i)
                          resid(idet) = resid(idet) + H2A_vvov(e,c,b,k) * t2a(e,a,j,i)
                          resid(idet) = resid(idet) + H2A_vvov(e,a,c,k) * t2a(e,b,j,i)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  ! deallocate the copied t3 vectors and excitations
                  deallocate(t3a_amps_copy,t3a_excits_copy)
              end subroutine build_moments3a_ijk

              subroutine build_moments3b_ijk(resid,i,j,k,&
                                             t3a_amps, t3a_excits,&
                                             t3b_amps, t3b_excits,&
                                             t3c_amps, t3c_excits,&
                                             t2a, t2b,&
                                             H1A_oo, H1A_vv, H1B_oo, H1B_vv,&
                                             H2A_oovv, H2A_vvov, H2A_vooo, H2A_oooo, H2A_voov, H2A_vvvv,&
                                             H2B_oovv, H2B_vvov, H2B_vvvo, H2B_vooo, H2B_ovoo,&
                                             H2B_oooo, H2B_voov, H2B_vovo, H2B_ovov, H2B_ovvo, H2B_vvvv,&
                                             H2C_oovv, H2C_voov,&
                                             orbsym, sym_ijk, target_sym,&
                                             n3aaa, n3aab, n3abb,&
                                             noa, nua, nob, nub, norb)

                  integer, intent(in) :: noa, nua, nob, nub, n3aaa, n3aab, n3abb
                  integer, intent(in) :: norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  ! occupied orbital block indices
                  integer, intent(in) :: i, j, k
                  !
                  integer, intent(in) :: t3a_excits(n3aaa,6), t3b_excits(n3aab,6), t3c_excits(n3abb,6)
                  real(kind=8), intent(in) :: t3a_amps(n3aaa), t3b_amps(n3aab), t3c_amps(n3abb)
                  real(kind=8), intent(in) :: t2a(1:nua,1:nua,1:noa,1:noa),&
                                              t2b(1:nua,1:nub,1:noa,1:nob),&
                                              H1A_oo(1:noa,1:noa),&
                                              H1A_vv(1:nua,1:nua),&
                                              H1B_oo(1:nob,1:nob),&
                                              H1B_vv(1:nub,1:nub),&
                                              H2A_oovv(1:noa,1:noa,1:nua,1:nua),&
                                              H2A_vvov(nua,nua,nua,noa),& ! reordered
                                              H2A_vooo(noa,nua,noa,noa),& ! reordered
                                              H2A_oooo(1:noa,1:noa,1:noa,1:noa),&
                                              H2A_voov(noa,nua,nua,noa),& ! reordered
                                              H2A_vvvv(1:nua,1:nua,1:nua,1:nua),&
                                              H2B_oovv(1:noa,1:nob,1:nua,1:nub),&
                                              H2B_vooo(nob,nua,noa,nob),& ! reordered
                                              H2B_ovoo(1:noa,1:nub,1:noa,1:nob),&
                                              H2B_vvov(nub,nua,nub,noa),& ! reordered
                                              H2B_vvvo(nua,nua,nub,nob),& ! reordered
                                              H2B_oooo(1:noa,1:nob,1:noa,1:nob),&
                                              H2B_voov(nob,nub,nua,noa),& ! reordered
                                              H2B_vovo(nob,nua,nua,nob),& ! reordered
                                              H2B_ovov(noa,nub,nub,noa),& ! reordered
                                              H2B_ovvo(noa,nua,nub,nob),& ! reordered
                                              H2B_vvvv(1:nub,1:nua,1:nub,1:nua),&
                                              H2C_oovv(1:nob,1:nob,1:nub,1:nub),&
                                              H2C_voov(nob,nub,nub,nob)   ! reordered

                  real(kind=8), intent(out) :: resid(nua,nua,nub)

                  real(kind=8), allocatable :: amps_buff(:), t3b_amps_copy(:), xbuf(:,:,:,:)
                  integer, allocatable :: excits_buff(:,:), t3b_excits_copy(:,:)

                  integer, allocatable :: loc_arr(:,:)
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)

                  real(kind=8) :: denom, val, t_amp, res_mm23, hmatel
                  real(kind=8) :: hmatel1, hmatel2, hmatel3, hmatel4
                  integer :: ii, jj, kk, l, a, b, c, d, m, n, e, f, jdet
                  integer :: idx, nloc
                  integer :: sym
                  !
                  logical(kind=1) :: qspace(nua,nua,nub)

                  ! Zero the residual container
                  resid = 0.0d0

                  ! copy over t3b_amps_copy and t3b_excits_copy
                  allocate(t3b_amps_copy(n3aab),t3b_excits_copy(n3aab,6))
                  t3b_amps_copy(:) = t3b_amps(:)
                  t3b_excits_copy(:,:) = t3b_excits(:,:)

                  ! reorder t3b into (i,j,k) order
                  nloc = noa*(noa-1)/2*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(noa,noa,nob))
                  call get_index_table3(idx_table3, (/1,noa-1/), (/-1,noa/), (/1,nob/), noa, noa, nob)
                  call sort3(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table3, (/4,5,6/), noa, noa, nob, nloc, n3aab)
                  ! Construct Q space for block (i,j,k)
                  qspace = .true.
                  idx = idx_table3(i,j,k)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = t3b_excits_copy(jdet,1); b = t3b_excits_copy(jdet,2); c = t3b_excits_copy(jdet,3);
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+noa))
                        sym = ieor(sym,orbsym(b+noa))
                        sym = ieor(sym,orbsym(c+nob))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                        qspace(a,b,c) = .false.
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)

                  !!!! diagram 1: -A(ij) h1a(mi)*t3b(abcmjk)
                  !!!! diagram 5: A(ij) 1/2 h2a(mnij)*t3b(abcmnk)
                  !!! ABCK LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nua*(nua-1)/2*nub*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,nub,noa))
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,nub/), (/1,nob/), nua, nua, nub, noa)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,2,3,6/), nua, nua, nub, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,c,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3b_excits_copy(jdet,4); m = t3b_excits_copy(jdet,5);
                        ! compute < ijk~abc~ | h2a(oooo) | lmk~abc~ >
                        !hmatel = h2a_oooo(l,m,i,j)
                        hmatel = h2a_oooo(m,l,j,i)
                        ! compute < ijk~abc~ | h1a(oo) | lmk~abc~ > = -A(ij)A(lm) h1a_oo(l,i) * delta(m,j)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (m==j) hmatel1 = -h1a_oo(l,i)
                        if (m==i) hmatel2 = h1a_oo(l,j)
                        if (l==j) hmatel3 = h1a_oo(m,i)
                        if (l==i) hmatel4 = -h1a_oo(m,j)
                        resid(idet) = resid(idet) + (hmatel + hmatel1 + hmatel2 + hmatel3 + hmatel4)*t3b_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 2: A(ab) h1a(ae)*t3b(ebcmjk)
                  !!!! diagram 6: A(ab) 1/2 h2a(abef)*t3b(ebcmjk)
                  !!! CIJK LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nub*noa*(noa-1)/2*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,nob,nub))
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), (/1,nub/), noa, noa, nob, nub)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/4,5,6,3/), noa, noa, nob, nub, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  ! Look for a DGEMM somewhere
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     !idx = idx_table(c,i,j,k)
                     idx = idx_table(i,j,k,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3b_excits_copy(jdet,1); e = t3b_excits_copy(jdet,2); ! swap t3b_excits_copy everywher
                        ! compute < ijk~abc~ | h2a(vvvv) | ijk~dec~ >
                        !hmatel = h2a_vvvv(a,b,d,e)
                        !hmatel = h2a_vvvv(d,e,a,b)
                        hmatel = h2a_vvvv(e,d,b,a)
                        ! compute < ijk~abc~ | h1a(vv) | ijk~dec > = A(ab)A(de) h1a_vv(a,d)*delta(b,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==e) hmatel1 = h1a_vv(d,a)  !h1a_vv(a,d)
                        if (a==e) hmatel2 = -h1a_vv(d,b) !-h1a_vv(b,d)
                        if (b==d) hmatel3 = -h1a_vv(e,a) !-h1a_vv(a,e)
                        if (a==d) hmatel4 = h1a_vv(e,b)  !h1a_vv(b,e)
                        resid(idet) = resid(idet) + (hmatel + hmatel1 + hmatel2 + hmatel3 + hmatel4)*t3b_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 3: -h1b(mk)*t3b(abcijm)
                  !!!! diagram 7: A(ij) h2b(mnjk)*t3b(abcimn)
                  !!! ABCI LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nua*(nua-1)/2*nub*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,nub,noa))
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,nub/), (/1,noa-1/), nua, nua, nub, noa)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,2,3,4/), nua, nua, nub, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,i)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = t3b_excits_copy(jdet,5); n = t3b_excits_copy(jdet,6);
                        ! compute < ijk~abc~ | h2b(oooo) | imn~abc~ >
                        hmatel = h2b_oooo(m,n,j,k)
                        ! compute < ijk~abc~ | h1b(oo) | imn~abc~ >
                        hmatel1 = 0.0d0
                        if (m==j) hmatel1 = -h1b_oo(n,k)
                        resid(idet) = resid(idet) + (hmatel + hmatel1)*t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = t3b_excits_copy(jdet,5); n = t3b_excits_copy(jdet,6);
                           ! compute < ijk~abc~ | h2b(oooo) | jmn~abc~ >
                           hmatel = -h2b_oooo(m,n,i,k)
                           ! compute < ijk~abc~ | h1b(oo) | jmn~abc~ >
                           hmatel1 = 0.0d0
                           if (m==i) hmatel1 = h1b_oo(n,k)
                           resid(idet) = resid(idet) + (hmatel + hmatel1)*t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABCJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,nub/), (/2,noa/), nua, nua, nub, noa)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,2,3,5/), nua, nua, nub, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3b_excits_copy(jdet,4); n = t3b_excits_copy(jdet,6);
                        ! compute < ijk~abc~ | h2b(oooo) | ljn~abc~ >
                        hmatel = h2b_oooo(l,n,i,k)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3b_excits_copy(jdet,4); n = t3b_excits_copy(jdet,6);
                           ! compute < ijk~abc~ | h2b(oooo) | lin~abc~ >
                           hmatel = -h2b_oooo(l,n,j,k)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECITON !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 5: h1b(ce)*t3b(abeijm)
                  !!!! diagram 8: A(ab) h2b(bcef)*t3b(aefijk)
                  ! allocate new sorting arrays
                  nloc = nua*noa*(noa-1)/2*nob ! no3nu
                  allocate(loc_arr(2,nloc)) ! 2*no3nu
                  allocate(idx_table(noa,noa,nob,nua)) ! no3nu
                  !!! AIJK LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), (/1,nua-1/), noa, noa, nob, nua)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/4,5,6,1/), noa, noa, nob, nua, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(i,j,k,a) ! make sizes powers of two to speed up address lookup
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         e = t3b_excits_copy(jdet,2); f = t3b_excits_copy(jdet,3);
                         ! compute < ijk~abc~ | h2b(vvvv) | ijk~aef~ >
                         !hmatel = h2b_vvvv(b,c,e,f)
                         !hmatel = h2b_vvvv(e,f,b,c)
                         hmatel = h2b_vvvv(f,e,c,b)
                         hmatel1 = 0.0d0
                         if (b==e) hmatel1 = h1b_vv(f,c) !h1b_vv(c,f)
                         resid(idet) = resid(idet) + (hmatel + hmatel1)*t3b_amps_copy(jdet)
                      end do
                      ! (ab)
                      idx = idx_table(i,j,k,b)
                      if (idx/=0) then ! protect against case where b = nua because a = 1, nua-1
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = t3b_excits_copy(jdet,2); f = t3b_excits_copy(jdet,3);
                            ! compute < ijk~abc~ | h2b(vvvv) | ijk~bef~ >
                            !hmatel = -h2b_vvvv(a,c,e,f)
                            !hmatel = -h2b_vvvv(e,f,a,c)
                            hmatel = -h2b_vvvv(f,e,c,a)
                            hmatel1 = 0.0d0
                            if (a==e) hmatel1 = -h1b_vv(f,c) !-h1b_vv(c,f)
                            resid(idet) = resid(idet) + (hmatel + hmatel1)*t3b_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BIJK LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), (/2,nua/), noa, noa, nob, nua)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/4,5,6,2/), noa, noa, nob, nua, nloc, n3aab)
                  !!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(i,j,k,b)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = t3b_excits_copy(jdet,1); f = t3b_excits_copy(jdet,3);
                         ! compute < ijk~abc~ | h2b(vvvv) | ijk~dbf~ >
                         !hmatel = h2b_vvvv(a,c,d,f)
                         !hmatel = h2b_vvvv(d,f,a,c)
                         hmatel = h2b_vvvv(f,d,c,a)
                         resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                      end do
                      idx = idx_table(i,j,k,a)
                      if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = t3b_excits_copy(jdet,1); f = t3b_excits_copy(jdet,3);
                            ! compute < ijk~abc~ | h2b(vvvv) | ijk~daf~ >
                            !hmatel = -h2b_vvvv(b,c,d,f)
                            !hmatel = -h2b_vvvv(d,f,b,c)
                            hmatel = -h2b_vvvv(f,d,c,b)
                            resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 9: A(ij)A(ab) h2a(amie)*t3b(ebcmjk)
                  ! allocate new sorting arrays
                  nloc = nua*nub*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,4);
                        ! compute < ijk~abc~ | h2a(voov) | ljk~dbc~ >
                        !hmatel = h2a_voov(a,l,i,d)
                        hmatel = h2a_voov(l,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | ljk~dac~ >
                           !hmatel = -h2a_voov(b,l,i,d)
                           hmatel = -h2a_voov(l,d,b,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then ! protect against case where i = 1 because j = 2, noa
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~dbc~ >
                           !hmatel = -h2a_voov(a,l,j,d)
                           hmatel = -h2a_voov(l,d,a,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then ! protect against case where a = 1 because b = 2, nua and i = 1 because j = 2, noa
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~dac~ >
                           !hmatel = h2a_voov(b,l,j,d)
                           hmatel = h2a_voov(l,d,b,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,5);
                        ! compute < ijk~abc~ | h2a(voov) | ilk~dbc~ >
                        !hmatel = h2a_voov(a,l,j,d)
                        hmatel = h2a_voov(l,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then ! protect against where j = noa because i = 1, noa-1
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~dbc~ >
                           !hmatel = -h2a_voov(a,l,i,d)
                           hmatel = -h2a_voov(l,d,a,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | ilk~dac~ >
                           !hmatel = -h2a_voov(b,l,j,d)
                           hmatel = -h2a_voov(l,d,b,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then ! protect against case where j = noa because i = 1, noa-1 and where a = 1 because b = 2, nua
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); l = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~dac~ >
                           !hmatel = h2a_voov(b,l,i,d)
                           hmatel = h2a_voov(l,d,b,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,5);
                        ! compute < ijk~abc~ | h2a(voov) | ilk~adc~  >
                        !hmatel = h2a_voov(b,l,j,d)
                        hmatel = h2a_voov(l,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~adc~  >
                           !hmatel = -h2a_voov(b,l,i,d)
                           hmatel = -h2a_voov(l,d,b,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | ilk~bdc~  >
                           !hmatel = -h2a_voov(a,l,j,d)
                           hmatel = -h2a_voov(l,d,a,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~bdc~  >
                           !hmatel = h2a_voov(a,l,i,d)
                           hmatel = h2a_voov(l,d,a,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,j,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,4);
                        ! compute < ijk~abc~ | h2a(voov) | ljk~adc~  >
                        !hmatel = h2a_voov(b,l,i,d)
                        hmatel = h2a_voov(l,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~adc~  >
                           !hmatel = -h2a_voov(b,l,j,d)
                           hmatel = -h2a_voov(l,d,b,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | ljk~bdc~  >
                           !hmatel = -h2a_voov(a,l,i,d)
                           hmatel = -h2a_voov(l,d,a,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,2); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~abc~  >
                           !hmatel = h2a_voov(a,l,j,d)
                           hmatel = h2a_voov(l,d,a,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 10: h2c(cmke)*t3b(abeijm)
                  ! allocate sorting arrays
                  nloc = nua*(nua-1)/2*noa*(noa-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,&
                  !$omp n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(a,b,i,j)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         f = t3b_excits_copy(jdet,3); n = t3b_excits_copy(jdet,6);
                         ! compute < ijk~abc~ | h2c(voov) | ijn~abf~ > = h2c_voov(c,n,k,f)
                         !hmatel = h2c_voov(c,n,k,f)
                         hmatel = h2c_voov(n,f,c,k)
                         resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 11: -A(ij) h2b(mcie)*t3b(abemjk)
                  ! allocate sorting arrays
                  nloc = nua*(nua-1)/2*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,nob))
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,noa-1/), (/1,nob/), nua, nua, noa, nob)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nua, nua, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3b_excits_copy(jdet,3); m = t3b_excits_copy(jdet,5);
                        ! compute < ijk~abc~ | h2b(ovov) | imk~abf~ >
                        !hmatel = -h2b_ovov(m,c,j,f)
                        hmatel = -h2b_ovov(m,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = t3b_excits_copy(jdet,3); m = t3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2b(ovov) | jmk~abf~ >
                           !hmatel = h2b_ovov(m,c,i,f)
                           hmatel = h2b_ovov(m,f,c,i)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/2,noa/), (/1,nob/), nua, nua, noa, nob)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/1,2,5,6/), nua, nua, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,j,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3b_excits_copy(jdet,3); l = t3b_excits_copy(jdet,4);
                        ! compute < ijk~abc~ | h2b(ovov) | ljk~abf~ >
                        !hmatel = -h2b_ovov(l,c,i,f)
                        hmatel = -h2b_ovov(l,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = t3b_excits_copy(jdet,3); l = t3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2b(ovov) | lik~abf~ >
                           !hmatel = h2b_ovov(l,c,j,f)
                           hmatel = h2b_ovov(l,f,c,j)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 12: -A(ab) h2b(amek)*t3b(ebcijm)
                  ! allocate sorting arrays
                  nloc = nua*nub*noa*(noa-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,nua,nub))
                  !!! BCIJ LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/2,nua/), (/1,nub/), noa, noa, nua, nub)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/4,5,2,3/), noa, noa, nua, nub, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,b,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3b_excits_copy(jdet,1); n = t3b_excits_copy(jdet,6);
                        ! compute < ijk~abc~ | h2b(vovo) | ijn~dbc~ >
                        !hmatel = -h2b_vovo(a,n,d,k)
                        hmatel = -h2b_vovo(n,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,a,c)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = t3b_excits_copy(jdet,1); n = t3b_excits_copy(jdet,6);
                           ! compute < ijk~abc~ | h2b(vovo) | ijn~dac~ >
                           !hmatel = h2b_vovo(b,n,d,k)
                           hmatel = h2b_vovo(n,d,b,k)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nua-1/), (/1,nub/), noa, noa, nua, nub)
                  call sort4(t3b_excits_copy, t3b_amps_copy, loc_arr, idx_table, (/4,5,1,3/), noa, noa, nua, nub, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,&
                  !$omp t3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,a,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3b_excits_copy(jdet,2); n = t3b_excits_copy(jdet,6);
                        ! compute < ijk~abc~ | h2b(vovo) | ijn~aec~ >
                        !hmatel = -h2b_vovo(b,n,e,k)
                        hmatel = -h2b_vovo(n,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,b,c)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = t3b_excits_copy(jdet,2); n = t3b_excits_copy(jdet,6);
                           ! compute < ijk~abc~ | h2b(vovo) | ijn~bec~ >
                           !hmatel = h2b_vovo(a,n,e,k)
                           hmatel = h2b_vovo(n,e,a,k)
                           resid(idet) = resid(idet) + hmatel * t3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 13: h2b(mcek)*t3a(abeijm) !!!!
                  ! allocate and initialize the copy of t3a
                  allocate(amps_buff(n3aaa))
                  allocate(excits_buff(n3aaa,6))
                  amps_buff(:) = t3a_amps(:)
                  excits_buff(:,:) = t3a_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = (nua-1)*(nua-2)/2*(noa-1)*(noa-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijk~abc~ | h2b(ovvo) | ijnabf >
                        !hmatel = h2b_ovvo(n,c,f,k)
                        hmatel = h2b_ovvo(n,f,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                        ! compute < ijk~abc~ | h2b(ovvo) | ijnaeb >
                        !hmatel = -h2b_ovvo(n,c,e,k)
                        hmatel = -h2b_ovvo(n,e,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIJ LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); n = excits_buff(jdet,6);
                        ! compute < ijk~abc~ | h2b(ovvo) | ijndab >
                        !hmatel = h2b_ovvo(n,c,d,k)
                        hmatel = h2b_ovvo(n,d,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                        ! compute < ijk~abc~ | h2b(ovvo) | imjabf >
                        !hmatel = -h2b_ovvo(m,c,f,k)
                        hmatel = -h2b_ovvo(m,f,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                        ! compute < ijk~abc~ | h2b(ovvo) | imjaeb >
                        !hmatel = h2b_ovvo(m,c,e,k)
                        hmatel = h2b_ovvo(m,e,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                        ! compute < ijk~abc~ | h2b(ovvo) | imjdab >
                        !hmatel = -h2b_ovvo(m,c,d,k)
                        hmatel = -h2b_ovvo(m,d,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); l = excits_buff(jdet,4);
                        ! compute < ijk~abc~ | h2b(ovvo) | lijabf >
                        !hmatel = h2b_ovvo(l,c,f,k)
                        hmatel = h2b_ovvo(l,f,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                        ! compute < ijk~abc~ | h2b(ovvo) | lijaeb >
                        !hmatel = -h2b_ovvo(l,c,e,k)
                        hmatel = -h2b_ovvo(l,e,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < ijk~abc~ | h2b(ovvo) | lijdab >
                        !hmatel = h2b_ovvo(l,c,d,k)
                        hmatel = h2b_ovvo(l,d,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate t3 buffer arrays
                  deallocate(amps_buff,excits_buff)

                  !!!! diagram 14: A(ab)A(ij) h2b(bmje)*t3c(aecimk)
                  ! allocate and initialize the copy of t3c
                  allocate(amps_buff(n3abb))
                  allocate(excits_buff(n3abb,6))
                  amps_buff(:) = t3c_amps(:)
                  excits_buff(:,:) = t3c_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nua*nub*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp t3b_amps_copy,amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | im~k~ae~c~ >
                           !hmatel = h2b_voov(b,m,j,e)
                           hmatel = h2b_voov(m,e,b,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | im~k~be~c~ >
                           !hmatel = -h2b_voov(a,m,j,e)
                           hmatel = -h2b_voov(m,e,a,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | jm~k~ae~c~ >
                           !hmatel = -h2b_voov(b,m,i,e)
                           hmatel = -h2b_voov(m,e,b,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | jm~k~be~c~ >
                           !hmatel = h2b_voov(a,m,i,e)
                           hmatel = h2b_voov(m,e,a,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp t3b_amps_copy,amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | im~k~ac~f~ >
                           !hmatel = -h2b_voov(b,m,j,f)
                           hmatel = -h2b_voov(m,f,b,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | im~k~bc~f~ >
                           !hmatel = h2b_voov(a,m,j,f)
                           hmatel = h2b_voov(m,f,a,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | jm~k~ac~f~ >
                           !hmatel = h2b_voov(b,m,i,f)
                           hmatel = h2b_voov(m,f,b,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < ijk~abc~ | h2b(voov) | jm~k~bc~f~ >
                           !hmatel = -h2b_voov(a,m,i,f)
                           hmatel = -h2b_voov(m,f,a,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp t3b_amps_copy,amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | ik~n~ae~c~ >
                           !hmatel = -h2b_voov(b,n,j,e)
                           hmatel = -h2b_voov(n,e,b,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | ik~n~be~c~ >
                           !hmatel = h2b_voov(a,n,j,e)
                           hmatel = h2b_voov(n,e,a,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | jk~n~ae~c~ >
                           !hmatel = h2b_voov(b,n,i,e)
                           hmatel = h2b_voov(n,e,b,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | jk~n~be~c~ >
                           !hmatel = -h2b_voov(a,n,i,e)
                           hmatel = -h2b_voov(n,e,a,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3b_excits_copy,excits_buff,&
                  !$omp t3b_amps_copy,amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | ik~n~ac~f~ >
                           !hmatel = h2b_voov(b,n,j,f)
                           hmatel = h2b_voov(n,f,b,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | ik~n~bc~f~ >
                           !hmatel = -h2b_voov(a,n,j,f)
                           hmatel = -h2b_voov(n,f,a,j)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | jk~n~ac~f~ >
                           !hmatel = -h2b_voov(b,n,i,f)
                           hmatel = -h2b_voov(n,f,b,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < ijk~abc~ | h2b(voov) | jk~n~bc~f~ >
                           !hmatel = h2b_voov(a,n,i,f)
                           hmatel = h2b_voov(n,f,a,i)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate t3 buffer arrays
                  deallocate(amps_buff,excits_buff)

                  !
                  ! Moment contributions
                  !
                  !$omp parallel shared(resid,t3b_excits_copy,t2a,H2B_vvvo,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do e = 1, nua
                          ! A(ab) I2B(bcek) * t2a(aeij)
                          resid(idet) = resid(idet) + H2B_vvvo(e,b,c,k) * t2a(e,a,j,i)
                          resid(idet) = resid(idet) - H2B_vvvo(e,a,c,k) * t2a(e,b,j,i)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel

                  !$omp parallel shared(resid,t3b_excits_copy,t2b,H2A_vvov,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do e = 1, nua
                          ! A(ij) I2A(abie) * t2b(ecjk)
                          resid(idet) = resid(idet) + H2A_vvov(e,a,b,i) * t2b(e,c,j,k)
                          resid(idet) = resid(idet) - H2A_vvov(e,a,b,j) * t2b(e,c,i,k)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel

                  allocate(xbuf(nub,nua,nob,noa))
                  do ii = 1,noa
                     do jj = 1,nob
                        do a = 1,nua
                           do b = 1,nub
                              xbuf(b,a,jj,ii) = t2b(a,b,ii,jj)
                           end do
                        end do
                     end do
                  end do
                  !$omp parallel shared(resid,t3b_excits_copy,xbuf,H2B_vvov,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do e = 1, nub
                          ! A(ij)A(ab) I2b(acie) * t2b(bejk)
                          resid(idet) = resid(idet) + H2B_vvov(e,a,c,i) * xbuf(e,b,k,j)
                          resid(idet) = resid(idet) - H2B_vvov(e,a,c,j) * xbuf(e,b,k,i)
                          resid(idet) = resid(idet) - H2B_vvov(e,b,c,i) * xbuf(e,a,k,j)
                          resid(idet) = resid(idet) + H2B_vvov(e,b,c,j) * xbuf(e,a,k,i)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  deallocate(xbuf)

                  allocate(xbuf(noa,noa,nua,nua))
                  do a = 1,nua
                     do b = 1,nua
                        do ii = 1,noa
                           do jj = 1,noa
                              xbuf(jj,ii,b,a) = t2a(b,a,jj,ii)
                           end do
                        end do
                     end do
                  end do
                  !$omp parallel shared(resid,t3b_excits_copy,xbuf,H2B_ovoo,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, noa
                          ! -A(ij) h2b(mcjk) * t2a(abim)
                          resid(idet) = resid(idet) - H2B_ovoo(m,c,j,k) * xbuf(m,i,b,a)
                          resid(idet) = resid(idet) + H2B_ovoo(m,c,i,k) * xbuf(m,j,b,a)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  deallocate(xbuf)

                  allocate(xbuf(noa,nob,nua,nub))
                  do b = 1,nub
                     do a = 1,nua
                        do jj = 1,nob
                           do ii = 1,noa
                              xbuf(ii,jj,a,b) = t2b(a,b,ii,jj)
                           end do
                        end do
                     end do
                  end do
                  !$omp parallel shared(resid,t3b_excits_copy,xbuf,H2A_vooo,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, noa
                          ! -A(ab) h2a(amij) * t2b(bcmk)
                          resid(idet) = resid(idet) - H2A_vooo(m,a,i,j) * xbuf(m,k,b,c)
                          resid(idet) = resid(idet) + H2A_vooo(m,b,i,j) * xbuf(m,k,a,c)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  deallocate(xbuf)

                  allocate(xbuf(nob,noa,nub,nua))
                  do a = 1,nua
                     do b = 1,nub
                        do ii = 1,noa
                           do jj = 1,nob
                              xbuf(jj,ii,b,a) = t2b(a,b,ii,jj)
                           end do
                        end do
                     end do
                  end do
                  !$omp parallel shared(resid,t3b_excits_copy,xbuf,H2B_vooo,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, nob
                          ! -A(ij)A(ab) h2b(amik) * t2b(bcjm)
                          resid(idet) = resid(idet) - H2B_vooo(m,a,i,k) * xbuf(m,j,c,b)
                          resid(idet) = resid(idet) + H2B_vooo(m,b,i,k) * xbuf(m,j,c,a)
                          resid(idet) = resid(idet) + H2B_vooo(m,a,j,k) * xbuf(m,i,c,b)
                          resid(idet) = resid(idet) - H2B_vooo(m,b,j,k) * xbuf(m,i,c,a)
                      end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  deallocate(xbuf)

                  ! deallocate copies of t3b amplitude and excitation arrays
                  deallocate(t3b_amps_copy,t3b_excits_copy)
              end subroutine build_moments3b_ijk

              subroutine build_moments3c_ijk(resid, i, j, k,&
                                      t3b_amps, t3b_excits,&
                                      t3c_amps, t3c_excits,&
                                      t3d_amps, t3d_excits,&
                                      t2b, t2c,&
                                      H1A_oo, H1A_vv, H1B_oo, H1B_vv,&
                                      H2A_oovv, H2A_voov,&
                                      H2B_oovv, H2B_vooo, H2B_ovoo, H2B_vvov, H2B_vvvo, H2B_oooo,&
                                      H2B_voov, H2B_vovo, H2B_ovov, H2B_ovvo, H2B_vvvv,&
                                      H2C_oovv, H2C_vooo, H2C_vvov, H2C_oooo, H2C_voov, H2C_vvvv,&
                                      orbsym, sym_ijk, target_sym,&
                                      n3aab, n3abb, n3bbb,&
                                      noa, nua, nob, nub, norb)

                  integer, intent(in) :: noa, nua, nob, nub, n3aab, n3abb, n3bbb
                  integer, intent(in) :: norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  ! occupied orbital block indices
                  integer, intent(in) :: i, j, k
                  !
                  integer, intent(in) :: t3b_excits(n3aab,6), t3c_excits(n3abb,6), t3d_excits(n3bbb,6)
                  real(kind=8), intent(in) :: t2b(1:nua,1:nub,1:noa,1:nob),&
                                              t2c(1:nub,1:nub,1:nob,1:nob),&
                                              t3b_amps(n3aab),t3c_amps(n3abb),t3d_amps(n3bbb),&
                                              H1A_oo(1:noa,1:noa),&
                                              H1A_vv(1:nua,1:nua),&
                                              H1B_oo(1:nob,1:nob),&
                                              H1B_vv(1:nub,1:nub),&
                                              H2A_oovv(1:noa,1:noa,1:nua,1:nua),&
                                              H2A_voov(noa,nua,nua,noa),& ! reordered
                                              H2B_oovv(1:noa,1:nob,1:nua,1:nub),&
                                              H2B_vooo(nob,nua,noa,nob),& ! reordered
                                              H2B_ovoo(1:noa,1:nub,1:noa,1:nob),&
                                              H2B_vvov(nub,nua,nub,noa),& ! reordered
                                              H2B_vvvo(nua,nua,nub,nob),& ! reordered
                                              H2B_oooo(1:noa,1:nob,1:noa,1:nob),&
                                              H2B_voov(nob,nub,nua,noa),& ! reordered
                                              H2B_vovo(nob,nua,nua,nob),& ! reordered
                                              H2B_ovov(noa,nub,nub,noa),& ! reordered
                                              H2B_ovvo(noa,nua,nub,nob),& ! reordered
                                              H2B_vvvv(1:nua,1:nub,1:nua,1:nub),&
                                              H2C_oovv(1:nob,1:nob,1:nub,1:nub),&
                                              H2C_vooo(nob,nub,nob,nob),& ! reordered
                                              H2C_vvov(nub,nub,nub,nob),& ! reordered
                                              H2C_oooo(1:nob,1:nob,1:nob,1:nob),&
                                              H2C_voov(nob,nub,nub,nob),& ! reordered
                                              H2C_vvvv(1:nub,1:nub,1:nub,1:nub)
                  ! output variables
                  real(kind=8), intent(out) :: resid(nua,nub,nub)
                  ! local variables
                  real(kind=8), allocatable :: amps_buff(:), t3c_amps_copy(:)
                  integer, allocatable :: excits_buff(:,:), t3c_excits_copy(:,:)
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)
                  !
                  real(kind=8) :: denom, val, t_amp, res_mm23, hmatel
                  real(kind=8) :: hmatel1, hmatel2, hmatel3, hmatel4
                  integer :: ii, jj, kk, l, a, b, c, d, m, n, e, f, jdet
                  integer :: idx, nloc
                  integer :: sym
                  real(kind=8), allocatable :: xbuf(:,:,:,:)
                  !
                  logical(kind=1) :: qspace(nua,nub,nub)

                  ! copy over t3c_amps_copy and t3c_excits_copy
                  allocate(t3c_amps_copy(n3abb),t3c_excits_copy(n3abb,6))
                  t3c_amps_copy(:) = t3c_amps(:)
                  t3c_excits_copy(:,:) = t3c_excits(:,:)

                  ! reorder t3c into (i,j,k) order
                  nloc = nob*(nob-1)/2*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(nob,nob,noa))
                  call get_index_table3(idx_table3, (/1,nob-1/), (/-1,nob/), (/1,noa/), nob, nob, noa)
                  call sort3(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table3, (/5,6,4/), nob, nob, noa, nloc, n3abb)
                  ! Construct Q space for block (j,k,i)
                  qspace = .true.
                  idx = idx_table3(j,k,i)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = t3c_excits_copy(jdet,1); b = t3c_excits_copy(jdet,2); c = t3c_excits_copy(jdet,3);
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+noa))
                        sym = ieor(sym,orbsym(b+nob))
                        sym = ieor(sym,orbsym(c+nob))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                        qspace(a,b,c) = .false.
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)

                  ! Zero the residual container
                  resid = 0.0d0

                  !!!! diagram 1: -A(jk) h1b(mk)*t3c(abcijm)
                  !!!! diagram 5: A(jk) 1/2 h2c(mnjk)*t3c(abcimn)
                  !!! BCAI LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nub*(nub-1)/2*nua*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nua,noa))
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nua/), (/1,noa/), nub, nub, nua, noa)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/2,3,1,4/), nub, nub, nua, noa, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(b,c,a,i)
                     ! (1)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = t3c_excits_copy(jdet,5); n = t3c_excits_copy(jdet,6);
                        ! compute < ij~k~ab~c~ | h2c(oooo) | im~n~ab~c~ >
                        !hmatel = h2c_oooo(m,n,j,k)
                        hmatel = h2c_oooo(n,m,k,j)
                        ! compute < ij~k~ab~c~ | h1b(oo) | im~n~ab~c~ > = -A(jk)A(mn) h1b_oo(m,j) * delta(n,k)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.d0;
                        if (n==k) hmatel1 = -h1b_oo(m,j) ! (1)
                        if (n==j) hmatel2 = h1b_oo(m,k) ! (jk)
                        if (m==k) hmatel3 = h1b_oo(n,j) ! (mn)
                        if (m==j) hmatel4 = -h1b_oo(n,k) ! (jk)(mn)
                        resid(idet) = resid(idet) + (hmatel + hmatel1 + hmatel2 + hmatel3 + hmatel4)*t3c_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 2: A(bc) h1b(ce)*t3c(abeijk)
                  !!!! diagram 6: A(bc) 1/2 h2c(bcef)*t3c(aefijk)
                  !!! JKIA LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nua*nob*(nob-1)/2*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,noa,nua))
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), (/1,nua/), nob, nob, noa, nua)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/5,6,4,1/), nob, nob, noa, nua, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(j,k,i,a)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3c_excits_copy(jdet,2); f = t3c_excits_copy(jdet,3);
                        ! compute < ij~k~ab~c~ | h2c(vvvv) | ij~k~ae~f~ >
                        !hmatel = h2c_vvvv(b,c,e,f)
                        !hmatel = h2c_vvvv(e,f,b,c)
                        hmatel = h2c_vvvv(f,e,c,b)
                        ! compute < ij~k~ab~c~ | h2c(vvvv) | ij~k~ae~f~ > = A(bc)A(ef) h1b_vv(b,e) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.d0;
                        if (c==f) hmatel1 = h1b_vv(e,b)  !h1b_vv(b,e) ! (1)
                        if (b==f) hmatel2 = -h1b_vv(e,c) !-h1b_vv(c,e) ! (bc)
                        if (c==e) hmatel3 = -h1b_vv(f,b) !-h1b_vv(b,f) ! (ef)
                        if (b==e) hmatel4 = h1b_vv(f,c)  !h1b_vv(c,f) ! (bc)(ef)
                        resid(idet) = resid(idet) + (hmatel + hmatel1 + hmatel2 + hmatel3 + hmatel4)*t3c_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 3: -h1a(mi)*t3c(abcmjk)
                  !!!! diagram 7: A(jk) h2b(mnij)*t3c(abcmnk)
                  !!! BCAK LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nub*(nub-1)/2*nua*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nua,nob))
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nua/), (/2,nob/), nub, nub, nua, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/2,3,1,6/), nub, nub, nua, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,a,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3c_excits_copy(jdet,4); m = t3c_excits_copy(jdet,5);
                        ! compute < ij~k~ab~c~ | h2b(oooo) | lm~k~ab~c~ >
                        hmatel = h2b_oooo(l,m,i,j)
                        ! compute < ij~k~ab~c~ | h1a(oo) | lm~k~ab~c~ >
                        hmatel1 = 0.0d0
                        if (m==j) hmatel1 = -h1a_oo(l,i)
                        resid(idet) = resid(idet) + (hmatel + hmatel1)*t3c_amps_copy(jdet)
                     end do
                     ! (jk)
                     idx = idx_table(b,c,a,j)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            l = t3c_excits_copy(jdet,4); m = t3c_excits_copy(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(oooo) | lm~j~ab~c~ >
                            hmatel = -h2b_oooo(l,m,i,k)
                            ! compute < ij~k~ab~c~ | h1a(oo) | lm~j~ab~c~ >
                            hmatel1 = 0.0d0
                            if (m==k) hmatel1 = h1a_oo(l,i)
                            resid(idet) = resid(idet) + (hmatel + hmatel1)*t3c_amps_copy(jdet)
                         end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCAJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nua/), (/1,nob-1/), nub, nub, nua, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/2,3,1,5/), nub, nub, nua, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,a,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3c_excits_copy(jdet,4); n = t3c_excits_copy(jdet,6);
                        ! compute < ij~k~ab~c~ | h2b(oooo) | lj~n~ab~c~ >
                        hmatel = h2b_oooo(l,n,i,k)
                        resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                     end do
                     ! (jk)
                     idx = idx_table(b,c,a,k)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            l = t3c_excits_copy(jdet,4); n = t3c_excits_copy(jdet,6);
                            ! compute < ij~k~ab~c~ | h2b(oooo) | lk~n~ab~c~ >
                            hmatel = -h2b_oooo(l,n,i,j)
                            resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                         end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECITON !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 5: h1a(ae)*t3c(ebcijk)
                  !!!! diagram 8: A(bc) h2b(abef)*t3c(efcijk)
                  ! allocate new sorting arrays
                  nloc = nub*nob*(nob-1)/2*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,noa,nub))
                  !!! JKIB LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), (/1,nub-1/), nob, nob, noa, nub)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/5,6,4,2/), nob, nob, noa, nub, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(j,k,i,b) ! a changes faster than c
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = t3c_excits_copy(jdet,1); f = t3c_excits_copy(jdet,3); ! unlike in t3b, d changes faster than f
                         ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~db~f~ >
                         !hmatel = h2b_vvvv(a,c,d,f)
                         hmatel = h2b_vvvv(d,f,a,c)
                         hmatel1 = 0.0d0
                         if (c==f) hmatel1 = h1a_vv(d,a) !h1a_vv(a,d)
                         resid(idet) = resid(idet) + (hmatel + hmatel1)*t3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,i,c)
                      if (idx/=0) then ! protect against case where b = nua because a = 1, nua-1
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = t3c_excits_copy(jdet,1); f = t3c_excits_copy(jdet,3);
                            ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~dc~f~ >
                            !hmatel = -h2b_vvvv(a,b,d,f)
                            hmatel = -h2b_vvvv(d,f,a,b)
                            hmatel1 = 0.0d0
                            if (b==f) hmatel1 = -h1a_vv(d,a) !-h1a_vv(a,d)
                            resid(idet) = resid(idet) + (hmatel + hmatel1)*t3c_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! JKIC LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), (/2,nub/), nob, nob, noa, nub)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/5,6,4,3/), nob, nob, noa, nub, nloc, n3abb)
                  !!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(j,k,i,c)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = t3c_excits_copy(jdet,1); e = t3c_excits_copy(jdet,2);
                         ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~de~c~ >
                         !hmatel = h2b_vvvv(a,b,d,e)
                         hmatel = h2b_vvvv(d,e,a,b)
                         resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,i,b)
                      if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = t3c_excits_copy(jdet,1); e = t3c_excits_copy(jdet,2);
                            ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~de~b~ >
                            !hmatel = -h2b_vvvv(a,c,d,e)
                            hmatel = -h2b_vvvv(d,e,a,c)
                            resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do; ! end loop over idet
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 9: A(jk)A(bc) h2c(cmke)*t3c(abeijm)
                  ! allocate new sorting arrays
                  nloc = nub*nua*nob*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3c_excits_copy(jdet,3); n = t3c_excits_copy(jdet,6);
                        ! compute < ij~k~ab~c~ | h2a(voov) | ij~n~ab~f~ >
                        !hmatel = h2c_voov(c,n,k,f)
                        hmatel = h2c_voov(n,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                     end do
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            f = t3c_excits_copy(jdet,3); n = t3c_excits_copy(jdet,6);
                            ! compute < ij~k~ab~c~ | h2a(voov) | ik~n~ab~f~ >
                            !hmatel = -h2c_voov(c,n,j,f)
                            hmatel = -h2c_voov(n,f,c,j)
                            resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                         end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            f = t3c_excits_copy(jdet,3); n = t3c_excits_copy(jdet,6);
                            ! compute < ij~k~ab~c~ | h2a(voov) | ij~n~ac~f~ >
                            !hmatel = -h2c_voov(b,n,k,f)
                            hmatel = -h2c_voov(n,f,b,k)
                            resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                         end do
                     end if
                     ! (jk)(bc)
                      idx = idx_table(a,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                             f = t3c_excits_copy(jdet,3); n = t3c_excits_copy(jdet,6);
                             ! compute < ij~k~ab~c~ | h2a(voov) | ik~n~ac~f~ >
                             !hmatel = h2c_voov(b,n,j,f)
                             hmatel = h2c_voov(n,f,b,j)
                             resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/1,3,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(a,c,i,j)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          e = t3c_excits_copy(jdet,2); n = t3c_excits_copy(jdet,6);
                          ! compute < ij~k~ab~c~ | h2c(voov) | ij~n~ae~c~ >
                          !hmatel = h2c_voov(b,n,k,e)
                          hmatel = h2c_voov(n,e,b,k)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(a,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); n = t3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2c(voov) | ik~n~ae~c~ >
                              !hmatel = -h2c_voov(b,n,j,e)
                              hmatel = -h2c_voov(n,e,b,j)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                      ! (bc)
                      idx = idx_table(a,b,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); n = t3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2c(voov) | ij~n~ae~b~ >
                              !hmatel = -h2c_voov(c,n,k,e)
                              hmatel = -h2c_voov(n,e,c,k)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                      ! (jk)(bc)
                      idx = idx_table(a,b,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); n = t3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2c(voov) | ik~n~ae~b~ >
                              !hmatel = h2c_voov(c,n,j,e)
                              hmatel = h2c_voov(n,e,c,j)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(a,b,i,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          f = t3c_excits_copy(jdet,3); m = t3c_excits_copy(jdet,5);
                          ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ab~f~ >
                          !hmatel = h2c_voov(c,m,j,f)
                          hmatel = h2c_voov(m,f,c,j)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(a,b,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = t3c_excits_copy(jdet,3); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ab~f~ >
                              !hmatel = -h2c_voov(c,m,k,f)
                              hmatel = -h2c_voov(m,f,c,k)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                      ! (bc)
                      idx = idx_table(a,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = t3c_excits_copy(jdet,3); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ac~f~ >
                              !hmatel = -h2c_voov(b,m,j,f)
                              hmatel = -h2c_voov(m,f,b,j)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                      ! (jk)(bc)
                      idx = idx_table(a,c,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = t3c_excits_copy(jdet,3); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ac~f~ >
                              !hmatel = h2c_voov(b,m,k,f)
                              hmatel = h2c_voov(m,f,b,k)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(a,c,i,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          e = t3c_excits_copy(jdet,2); m = t3c_excits_copy(jdet,5);
                          ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ae~c~ >
                          !hmatel = h2c_voov(b,m,j,e)
                          hmatel = h2c_voov(m,e,b,j)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(a,c,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ae~c~ >
                              !hmatel = -h2c_voov(b,m,k,e)
                              hmatel = -h2c_voov(m,e,b,k)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                      ! (bc)
                      idx = idx_table(a,b,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ae~b~ >
                              !hmatel = -h2c_voov(c,m,j,e)
                              hmatel = -h2c_voov(m,e,c,j)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                      ! (jk)(bc)
                      idx = idx_table(a,b,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ae~b~ >
                              !hmatel = h2c_voov(c,m,k,e)
                              hmatel = h2c_voov(m,e,c,k)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 10: h2a(amie)*t3c(ebcmjk)
                  ! allocate sorting arrays
                  nloc = nub*(nub-1)/2*nob*(nob-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,&
                  !$omp n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(b,c,j,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = t3c_excits_copy(jdet,1); l = t3c_excits_copy(jdet,4);
                         ! compute < ij~k~ab~c~ | h2a(voov) | lj~k~db~c~ >
                         !hmatel = h2a_voov(a,l,i,d)
                         hmatel = h2a_voov(l,d,a,i)
                         resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                  end do; end do; end do; ! end loop over idet
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 11: -A(bc) h2b(mbie)*t3c(aecmjk)
                  ! allocate sorting arrays
                  nloc = nob*(nob-1)/2*nub*nua
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,nua,nub))
                  !!! JKAC LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,nua/), (/2,nub/), nob, nob, nua, nub)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/5,6,1,3/), nob, nob, nua, nub, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(j,k,a,c)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          e = t3c_excits_copy(jdet,2); l = t3c_excits_copy(jdet,4);
                          ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ae~c~ >
                          !hmatel = -h2b_ovov(l,b,i,e)
                          hmatel = -h2b_ovov(l,e,b,i)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,a,b)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = t3c_excits_copy(jdet,2); l = t3c_excits_copy(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ae~b~ >
                              !hmatel = h2b_ovov(l,c,i,e)
                              hmatel = h2b_ovov(l,e,c,i)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! JKAB LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,nua/), (/1,nub-1/), nob, nob, nua, nub)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/5,6,1,2/), nob, nob, nua, nub, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(j,k,a,b)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          f = t3c_excits_copy(jdet,3); l = t3c_excits_copy(jdet,4);
                          ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ab~f~ >
                          !hmatel = -h2b_ovov(l,c,i,f)
                          hmatel = -h2b_ovov(l,f,c,i)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,a,c)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = t3c_excits_copy(jdet,3); l = t3c_excits_copy(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ac~f~ >
                              !hmatel = h2b_ovov(l,b,i,f)
                              hmatel = h2b_ovov(l,f,b,i)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 12: -A(bc) h2b(amej)*t3c(ebcimk)
                  ! allocate sorting arrays
                  nloc = nub*(nub-1)/2*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,noa,nob))
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,noa/), (/2,nob/), nub, nub, noa, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nub, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,i,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          d = t3c_excits_copy(jdet,1); m = t3c_excits_copy(jdet,5);
                          ! compute < ij~k~ab~c~ | h2b(vovo) | im~k~db~c~ >
                          !hmatel = -h2b_vovo(a,m,d,j)
                          hmatel = -h2b_vovo(m,d,a,j)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(b,c,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = t3c_excits_copy(jdet,1); m = t3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(vovo) | im~j~db~c~ >
                              !hmatel = h2b_vovo(a,m,d,k)
                              hmatel = h2b_vovo(m,d,a,k)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,noa/), (/1,nob-1/), nub, nub, noa, nob)
                  call sort4(t3c_excits_copy, t3c_amps_copy, loc_arr, idx_table, (/2,3,4,5/), nub, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,&
                  !$omp t3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,i,j)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          d = t3c_excits_copy(jdet,1); n = t3c_excits_copy(jdet,6);
                          ! compute < ij~k~ab~c~ | h2b(vovo) | ij~n~db~c~ >
                          !hmatel = -h2b_vovo(a,n,d,k)
                          hmatel = -h2b_vovo(n,d,a,k)
                          resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(b,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = t3c_excits_copy(jdet,1); n = t3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(vovo) | ik~n~db~c~ >
                              !hmatel = h2b_vovo(a,n,d,j)
                              hmatel = h2b_vovo(n,d,a,j)
                              resid(idet) = resid(idet) + hmatel * t3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 13: h2b(amie)*t3d(ebcmjk)
                  ! allocate and initialize the copy of t3d
                  allocate(amps_buff(n3bbb))
                  allocate(excits_buff(n3bbb,6))
                  amps_buff(:) = t3d_amps(:)
                  excits_buff(:,:) = t3d_excits(:,:)
                  ! allocate sorting arrays
                  nloc = (nub-1)*(nub-2)/2*(nob-1)*(nob-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(voov) | l~j~k~d~b~c~ >
                              !hmatel = h2b_voov(a,l,i,d)
                              hmatel = h2b_voov(l,d,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(voov) | j~m~k~d~b~c~ >
                              !hmatel = -h2b_voov(a,m,i,d)
                              hmatel = -h2b_voov(m,d,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIJ LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = excits_buff(jdet,1); n = excits_buff(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(voov) | j~k~n~d~b~c~ >
                              !hmatel = h2b_voov(a,n,i,d)
                              hmatel = h2b_voov(n,d,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACJK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(voov) | l~j~k~b~e~c~ >
                              !hmatel = -h2b_voov(a,l,i,e)
                              hmatel = -h2b_voov(l,e,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(voov) | j~m~k~b~e~c~ >
                              !hmatel = h2b_voov(a,m,i,e)
                              hmatel = h2b_voov(m,e,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(voov) | j~k~n~b~e~c~ >
                              !hmatel = -h2b_voov(a,n,i,e)
                              hmatel = -h2b_voov(n,e,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABJK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = excits_buff(jdet,3); l = excits_buff(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(voov) | l~j~k~b~c~f~ >
                              !hmatel = h2b_voov(a,l,i,f)
                              hmatel = h2b_voov(l,f,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(voov) | j~m~k~b~c~f~ >
                              !hmatel = -h2b_voov(a,m,i,f)
                              hmatel = -h2b_voov(m,f,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(voov) | j~k~n~b~c~f~ >
                              !hmatel = h2b_voov(a,n,i,f)
                              hmatel = h2b_voov(n,f,a,i)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate t3 buffer arrays
                  deallocate(amps_buff,excits_buff)
                  
                  !!!! diagram 14: A(bc)A(jk) h2b(mbej)*t3b(aecimk)
                  ! allocate and initialize the copy of t3b
                  allocate(amps_buff(n3aab))
                  allocate(excits_buff(n3aab,6))
                  amps_buff(:) = t3b_amps(:)
                  excits_buff(:,:) = t3b_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nua*nub*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imk~aec~ >
                            !hmatel = h2b_ovvo(m,b,e,j)
                            hmatel = h2b_ovvo(m,e,b,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imk~aeb~ >
                            !hmatel = -h2b_ovvo(m,c,e,j)
                            hmatel = -h2b_ovvo(m,e,c,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imj~aec~ >
                            !hmatel = -h2b_ovvo(m,b,e,k)
                            hmatel = -h2b_ovvo(m,e,b,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imj~aeb~ >
                            !hmatel = h2b_ovvo(m,c,e,k)
                            hmatel = h2b_ovvo(m,e,c,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imk~dac~ >
                            !hmatel = -h2b_ovvo(m,b,d,j)
                            hmatel = -h2b_ovvo(m,d,b,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imk~dab~ >
                            !hmatel = h2b_ovvo(m,c,d,j)
                            hmatel = h2b_ovvo(m,d,c,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imj~dac~ >
                            !hmatel = h2b_ovvo(m,b,d,k)
                            hmatel = h2b_ovvo(m,d,b,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | imj~dab~ >
                            !hmatel = -h2b_ovvo(m,c,d,k)
                            hmatel = -h2b_ovvo(m,d,c,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACJK LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lik~aec~ >
                            !hmatel = -h2b_ovvo(l,b,e,j)
                            hmatel = -h2b_ovvo(l,e,b,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lik~aeb~ >
                            !hmatel = h2b_ovvo(l,c,e,j)
                            hmatel = h2b_ovvo(l,e,c,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lij~aec~ >
                            !hmatel = h2b_ovvo(l,b,e,k)
                            hmatel = h2b_ovvo(l,e,b,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lij~aeb~ >
                            !hmatel = -h2b_ovvo(l,c,e,k)
                            hmatel = -h2b_ovvo(l,e,c,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lik~dac~ >
                            !hmatel = h2b_ovvo(l,b,d,j)
                            hmatel = h2b_ovvo(l,d,b,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lik~dab~ >
                            !hmatel = -h2b_ovvo(l,c,d,j)
                            hmatel = -h2b_ovvo(l,d,c,j)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lij~dac~ >
                            !hmatel = -h2b_ovvo(l,b,d,k)
                            hmatel = -h2b_ovvo(l,d,b,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(ovvo) | lij~dab~ >
                            !hmatel = h2b_ovvo(l,c,d,k)
                            hmatel = h2b_ovvo(l,d,c,k)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate t3 buffer arrays
                  deallocate(amps_buff,excits_buff)
                  
                  !
                  ! Moment contributions
                  !
                  !$omp parallel shared(resid,t3c_excits_copy,t2b,I2B_vvvo,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     do e = 1, nua
                        ! A(jk)A(bc) h2B(abej) * t2b(ecik)
                        resid(idet) = resid(idet) + H2B_vvvo(e,a,b,j) * t2b(e,c,i,k)
                        resid(idet) = resid(idet) - H2B_vvvo(e,a,b,k) * t2b(e,c,i,j)
                        resid(idet) = resid(idet) - H2B_vvvo(e,a,c,j) * t2b(e,b,i,k)
                        resid(idet) = resid(idet) + H2B_vvvo(e,a,c,k) * t2b(e,b,i,j)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel

                  !$omp parallel shared(resid,t3c_excits_copy,t2c,I2B_vvov,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do e = 1, nub
                         ! A(bc) h2B(abie) * t2c(ecjk)
                         resid(idet) = resid(idet) + H2B_vvov(e,a,b,i) * t2c(e,c,j,k)
                         resid(idet) = resid(idet) - H2B_vvov(e,a,c,i) * t2c(e,b,j,k)
                      end do
                   end do; end do; end do;
                   !$omp end do
                   !$omp end parallel

                   allocate(xbuf(nub,nua,nob,noa))
                   do ii = 1,noa
                      do jj = 1,nob
                         do a = 1,nua
                            do b = 1,nub
                               xbuf(b,a,jj,ii) = t2b(a,b,ii,jj)
                            end do
                         end do
                      end do
                   end do
                  !$omp parallel shared(resid,t3c_excits_copy,xbuf,I2C_vvov,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do e = 1, nub
                         ! A(jk) h2C(cbke) * t2b(aeij)
                         resid(idet) = resid(idet) + H2C_vvov(e,c,b,k) * xbuf(e,a,j,i)
                         resid(idet) = resid(idet) - H2C_vvov(e,c,b,j) * xbuf(e,a,k,i)
                      end do
                   end do; end do; end do;
                   !$omp end do
                   !$omp end parallel
                   deallocate(xbuf)

                   allocate(xbuf(noa,nob,nua,nub))
                   do b = 1,nub
                      do a = 1,nua
                         do jj = 1,nob
                            do ii = 1,noa
                               xbuf(ii,jj,a,b) = t2b(a,b,ii,jj)
                            end do
                         end do
                      end do
                   end do
                   !$omp parallel shared(resid,t3c_excits_copy,xbuf,I2B_ovoo,n3abb),&
                   !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, noa
                         ! -A(kj)A(bc) h2b(mbij) * t2b(acmk)
                         resid(idet) = resid(idet) - H2B_ovoo(m,b,i,j) * xbuf(m,k,a,c)
                         resid(idet) = resid(idet) + H2B_ovoo(m,c,i,j) * xbuf(m,k,a,b)
                         resid(idet) = resid(idet) + H2B_ovoo(m,b,i,k) * xbuf(m,j,a,c)
                         resid(idet) = resid(idet) - H2B_ovoo(m,c,i,k) * xbuf(m,j,a,b)
                      end do
                   end do; end do; end do;
                   !$omp end do
                   !$omp end parallel
                   deallocate(xbuf)

                   allocate(xbuf(nob,nob,nub,nub))
                   do b = 1,nub
                      do a = 1,nub
                         do jj = 1,nob
                            do ii = 1,nob
                               xbuf(ii,jj,a,b) = t2c(a,b,ii,jj)
                            end do
                         end do
                      end do
                   end do
                   !$omp parallel shared(resid,t3c_excits_copy,xbuf,I2B_vooo,n3abb),&
                   !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, nob
                         ! -A(jk) h2b(amij) * t2c(bcmk)
                         resid(idet) = resid(idet) - H2B_vooo(m,a,i,j) * xbuf(m,k,b,c)
                         resid(idet) = resid(idet) + H2B_vooo(m,a,i,k) * xbuf(m,j,b,c)
                      end do
                   end do; end do; end do;
                   !$omp end do
                   !$omp end parallel
                   deallocate(xbuf)

                   allocate(xbuf(nob,noa,nub,nua))
                   do a = 1,nua
                      do b = 1,nub
                         do ii = 1,noa
                            do jj = 1,nob
                               xbuf(jj,ii,b,a) = t2b(a,b,ii,jj)
                            end do
                         end do
                      end do
                   end do
                   !$omp parallel shared(resid,t3c_excits_copy,xbuf,I2C_vooo,n3abb),&
                   !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      do m = 1, nob
                         ! -A(bc) h2c(cmkj) * t2b(abim)
                         resid(idet) = resid(idet) - H2C_vooo(m,c,k,j) * xbuf(m,i,b,a)
                         resid(idet) = resid(idet) + H2C_vooo(m,b,k,j) * xbuf(m,i,c,a)
                      end do
                   end do; end do; end do;
                   !$omp end do
                   !$omp end parallel
                   deallocate(xbuf)

                   ! deallocate t3c copy arrays
                   deallocate(t3c_amps_copy,t3c_excits_copy)

              end subroutine build_moments3c_ijk

              subroutine build_moments3d_ijk(resid, i, j, k,&
                                      t3c_amps, t3c_excits,&
                                      t3d_amps, t3d_excits,&
                                      t2c,&
                                      H1B_oo, H1B_vv,&
                                      H2C_oovv, H2C_vvov, H2C_vooo,&
                                      H2C_oooo, H2C_voov, H2C_vvvv,&
                                      H2B_oovv, H2B_ovvo,&
                                      orbsym, sym_ijk, target_sym,&
                                      n3abb, n3bbb,&
                                      noa, nua, nob, nub, norb)
                  ! input variables 
                  integer, intent(in) :: noa, nua, nob, nub, n3abb, n3bbb
                  integer, intent(in) :: norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  ! orbital block indices
                  integer, intent(in) :: i, j, k
                  integer, intent(in) :: t3c_excits(n3abb,6), t3d_excits(n3bbb,6)
                  real(kind=8), intent(in) :: t2c(nub,nub,nob,nob),&
                                              t3c_amps(n3abb),&
                                              t3d_amps(n3bbb),&
                                              H1B_oo(nob,nob), H1B_vv(nub,nub),&
                                              H2B_oovv(noa,nob,nua,nub),&
                                              H2B_ovvo(noa,nua,nub,nob),& ! reordered
                                              H2C_oovv(nob,nob,nub,nub),&
                                              H2C_vooo(nob,nub,nob,nob),& ! reordered
                                              H2C_vvov(nub,nub,nub,nob),& ! reordered
                                              H2C_oooo(nob,nob,nob,nob),&
                                              H2C_voov(nob,nub,nub,nob),& ! reordered
                                              H2C_vvvv(nub,nub,nub,nub)
                  ! output variables
                  real(kind=8), intent(out) :: resid(nub,nub,nub)
                  ! local variables
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)
                  real(kind=8), allocatable :: amps_buff(:), t3d_amps_copy(:)
                  integer, allocatable :: excits_buff(:,:), t3d_excits_copy(:,:)

                  real(kind=8) :: val, denom, t_amp, res_mm23, hmatel
                  real(kind=8) :: hmatel1, hmatel2, hmatel3, hmatel4
                  integer :: a, b, c, d, ii, jj, kk, l, e, f, m, n, jdet
                  integer :: idx, nloc
                  integer :: sym
                  real(kind=8), allocatable :: xbuf(:,:,:,:)
                  !
                  logical(kind=1) :: qspace(nub,nub,nub)

                  ! copy over t3d_amps and t3d_excits
                  allocate(t3d_amps_copy(n3bbb),t3d_excits_copy(n3bbb,6))
                  t3d_amps_copy(:) = t3d_amps(:)
                  t3d_excits_copy(:,:) = t3d_excits(:,:)
                  
                  ! reorder t3d into (i,j,k) order
                  nloc = nob*(nob-1)*(nob-2)/6
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(nob,nob,nob))
                  call get_index_table3(idx_table3, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), nob, nob, nob)
                  call sort3(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table3, (/4,5,6/), nob, nob, nob, nloc, n3bbb)
                  ! Construct Q space for block (i,j,k)
                  qspace = .true.
                  idx = idx_table3(i,j,k)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = t3d_excits_copy(jdet,1); b = t3d_excits_copy(jdet,2); c = t3d_excits_copy(jdet,3);
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+nob))
                        sym = ieor(sym,orbsym(b+nob))
                        sym = ieor(sym,orbsym(c+nob))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                        qspace(a,b,c) = .false.
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)

                  ! Zero the residual
                  resid = 0.0d0
                  
                  !!!! diagram 1: -A(i/jk) h1b(mi) * t3d(abcmjk)
                  !!!! diagram 3: 1/2 A(i/jk) h2c(mnij) * t3d(abcmnk)
                  ! NOTE: WITHIN THESE LOOPS, H1B(OO) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2
                  ! allocate new sorting arrays
                  nloc = nub*(nub-1)*(nub-2)/6*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nub,nob))
                  !!! ABCK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/-1,nub/), (/3,nob/), nub, nub, nub, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,2,3,6/), nub, nub, nub, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3d_excits_copy(jdet,4); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(oooo) | lmkabc >
                        !hmatel = h2c_oooo(l,m,i,j)
                        hmatel = h2c_oooo(m,l,j,i)
                        ! compute < ijkabc | h1a(oo) | lmkabc > = -A(ij)A(lm) h1b_oo(l,i) * delta(m,j)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (m==j) hmatel1 = -h1b_oo(l,i) ! (1)      < ijkabc | h1a(oo) | ljkabc >
                        if (m==i) hmatel2 = h1b_oo(l,j) ! (ij)     < ijkabc | h1a(oo) | likabc >
                        if (l==j) hmatel3 = h1b_oo(m,i) ! (lm)     < ijkabc | h1a(oo) | jmkabc >
                        if (l==i) hmatel4 = -h1b_oo(m,j) ! (ij)(lm) < ijkabc | h1a(oo) | imkabc >
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     ! (ik)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3d_excits_copy(jdet,4); m = t3d_excits_copy(jdet,5);
                           ! compute < ijkabc | h2a(oooo) | lmiabc >
                           !hmatel = -h2c_oooo(l,m,k,j)
                           hmatel = h2c_oooo(m,l,k,j)
                           ! compute < ijkabc | h1a(oo) | lmiabc > = A(jk)A(lm) h1b_oo(l,k) * delta(m,j)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (m==j) hmatel1 = h1b_oo(l,k) ! (1)      < ijkabc | h1a(oo) | ljiabc >
                           if (m==k) hmatel2 = -h1b_oo(l,j) ! (jk)     < ijkabc | h1a(oo) | lkiabc >
                           if (l==j) hmatel3 = -h1b_oo(m,k) ! (lm)
                           if (l==k) hmatel4 = h1b_oo(m,j) ! (jk)(lm)
                           hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3d_excits_copy(jdet,4); m = t3d_excits_copy(jdet,5);
                           ! compute < ijkabc | h2a(oooo) | lmjabc >
                           !hmatel = -h2c_oooo(l,m,i,k)
                           hmatel = -h2c_oooo(m,l,k,i)
                           ! compute < ijkabc | h1a(oo) | lmjabc > = A(ik)A(lm) h1b_oo(l,i) * delta(m,k)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (m==k) hmatel1 = h1b_oo(l,i) ! (1)      < ijkabc | h1a(oo) | lkjabc >
                           if (m==i) hmatel2 = -h1b_oo(l,k) ! (ik)
                           if (l==k) hmatel3 = -h1b_oo(m,i) ! (lm)
                           if (l==i) hmatel4 = h1b_oo(m,k) ! (ik)(lm)
                           hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABCI LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/-1,nub/), (/1,nob-2/), nub, nub, nub, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,2,3,4/), nub, nub, nub, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,i)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = t3d_excits_copy(jdet,5); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(oooo) | imnabc >
                        !hmatel = h2c_oooo(m,n,j,k)
                        hmatel = h2c_oooo(n,m,k,j)
                        ! compute < ijkabc | h1a(oo) | imnabc > = -A(jk)A(mn) h1b_oo(m,j) * delta(n,k)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (n==k) hmatel1 = -h1b_oo(m,j)  ! < ijkabc | h1a(oo) | imkabc >
                        if (n==j) hmatel2 = h1b_oo(m,k)
                        if (m==k) hmatel3 = h1b_oo(n,j)
                        if (m==j) hmatel4 = -h1b_oo(n,k)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = t3d_excits_copy(jdet,5); n = t3d_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | jmnabc >
                           !hmatel = -h2c_oooo(m,n,i,k)
                           hmatel = -h2c_oooo(n,m,k,i)
                           ! compute < ijkabc | h1a(oo) | jmnabc > = A(ik)A(mn) h1b_oo(m,i) * delta(n,k)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==k) hmatel1 = h1b_oo(m,i)
                           if (n==i) hmatel2 = -h1b_oo(m,k)
                           if (m==k) hmatel3 = -h1b_oo(n,i)
                           if (m==i) hmatel4 = h1b_oo(n,k)
                           hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                        end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = t3d_excits_copy(jdet,5); n = t3d_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | kmnabc >
                           !hmatel = -h2c_oooo(m,n,j,i)
                           hmatel = h2c_oooo(n,m,j,i)
                           ! compute < ijkabc | h1a(oo) | kmnabc > = A(ij)A(mn) h1b_oo(m,j) * delta(n,i)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==i) hmatel1 = -h1b_oo(m,j)
                           if (n==j) hmatel2 = h1b_oo(m,i)
                           if (m==i) hmatel3 = h1b_oo(n,j)
                           if (m==j) hmatel4 = -h1b_oo(n,i)
                           hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABCJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/-1,nub/), (/2,nob-1/), nub, nub, nub, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,2,3,5/), nub, nub, nub, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = t3d_excits_copy(jdet,4); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(oooo) | ljnabc >
                        !hmatel = h2c_oooo(l,n,i,k)
                        hmatel = h2c_oooo(n,l,k,i)
                        ! compute < ijkabc | h1a(oo) | ljnabc > = -A(ik)A(ln) h1b_oo(l,i) * delta(n,k)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (n==k) hmatel1 = -h1b_oo(l,i)
                        if (n==i) hmatel2 = h1b_oo(l,k)
                        if (l==k) hmatel3 = h1b_oo(n,i)
                        if (l==i) hmatel4 = -h1b_oo(n,k)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3d_excits_copy(jdet,4); n = t3d_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | linabc >
                           !hmatel = -h2c_oooo(l,n,j,k)
                           hmatel = -h2c_oooo(n,l,k,j)
                           ! compute < ijkabc | h1a(oo) | linabc > = A(jk)A(ln) h1b_oo(l,j) * delta(n,k)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==k) hmatel1 = h1b_oo(l,j)
                           if (n==j) hmatel2 = -h1b_oo(l,k)
                           if (l==k) hmatel3 = -h1b_oo(n,j)
                           if (l==j) hmatel4 = h1b_oo(n,k)
                           hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = t3d_excits_copy(jdet,4); n = t3d_excits_copy(jdet,6);
                           ! compute < ijkabc | h2a(oooo) | lknabc >
                           !hmatel = -h2c_oooo(l,n,i,j)
                           hmatel = -h2c_oooo(n,l,j,i)
                           ! compute < ijkabc | h1a(oo) | lknabc > = A(ij)A(ln) h1b_oo(l,i) * delta(n,j)
                           hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                           if (n==j) hmatel1 = h1b_oo(l,i)
                           if (n==i) hmatel2 = -h1b_oo(l,j)
                           if (l==j) hmatel3 = -h1b_oo(n,i)
                           if (l==i) hmatel4 = h1b_oo(n,j)
                           hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                           resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 2: A(a/bc) h1b(ae) * t3d(ebcijk)
                  !!!! diagram 4: 1/2 A(c/ab) h2c(abef) * t3d(ebcijk) 
                  ! NOTE: WITHIN THESE LOOPS, H1B(VV) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2  
                  ! allocate new sorting arrays
                  nloc = nob*(nob-1)*(nob-2)/6*nub
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,nob,nub))
                  !!! IJKA LOOP !!!
                  call get_index_table(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), (/1,nub-2/), nob, nob, nob, nub)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/4,5,6,1/), nob, nob, nob, nub, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,a)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); f = t3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkaef >
                        !hmatel = h2c_vvvv(b,c,e,f)
                        !hmatel = h2c_vvvv(e,f,b,c)
                        hmatel = h2c_vvvv(f,e,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkaef > = A(bc)A(ef) h1b_vv(b,e) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = h1b_vv(e,b)  !h1b_vv(b,e) ! (1)
                        if (b==f) hmatel2 = -h1b_vv(e,c) !-h1b_vv(c,e) ! (bc)
                        if (c==e) hmatel3 = -h1b_vv(f,b) !-h1b_vv(b,f) ! (ef)
                        if (b==e) hmatel4 = h1b_vv(f,c)  !h1b_vv(c,f) ! (bc)(ef)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); f = t3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkbef >
                        !hmatel = -h2c_vvvv(a,c,e,f)
                        !hmatel = -h2c_vvvv(e,f,a,c)
                        hmatel = -h2c_vvvv(f,e,c,a)
                        ! compute < ijkabc | h1a(vv) | ijkbef > = -A(ac)A(ef) h1b_vv(a,e) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = -h1b_vv(e,a) !-h1b_vv(a,e) ! (1)
                        if (a==f) hmatel2 = h1b_vv(e,c)  !h1b_vv(c,e) ! (ac)
                        if (c==e) hmatel3 = h1b_vv(f,a)  !h1b_vv(a,f) ! (ef)
                        if (a==e) hmatel4 = -h1b_vv(f,c) !-h1b_vv(c,f) ! (ac)(ef)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); f = t3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkcef >
                        !hmatel = -h2c_vvvv(b,a,e,f)
                        !hmatel = -h2c_vvvv(e,f,b,a)
                        hmatel = h2c_vvvv(f,e,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkcef > = -A(ab)A(ef) h1b_vv(b,e) * delta(a,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (a==f) hmatel1 = -h1b_vv(e,b) !-h1b_vv(b,e) ! (1)
                        if (b==f) hmatel2 = h1b_vv(e,a)  !h1b_vv(a,e) ! (ab)
                        if (a==e) hmatel3 = h1b_vv(f,b)  !h1b_vv(b,f) ! (ef)
                        if (b==e) hmatel4 = -h1b_vv(f,a) !-h1b_vv(a,f) ! (ab)(ef)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! IJKB LOOP !!!
                  call get_index_table(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), (/2,nub-1/), nob, nob, nob, nub)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/4,5,6,2/), nob, nob, nob, nub, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,b)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); f = t3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdbf >
                        !hmatel = h2c_vvvv(a,c,d,f)
                        !hmatel = h2c_vvvv(d,f,a,c)
                        hmatel = h2c_vvvv(f,d,c,a)
                        ! compute < ijkabc | h1a(vv) | ijkdbf > = A(ac)A(df) h1b_vv(a,d) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = h1b_vv(d,a)  !h1b_vv(a,d) ! (1)
                        if (a==f) hmatel2 = -h1b_vv(d,c) !-h1b_vv(c,d) ! (ac)
                        if (c==d) hmatel3 = -h1b_vv(f,a) !-h1b_vv(a,f) ! (df)
                        if (a==d) hmatel4 = h1b_vv(f,c)  !h1b_vv(c,f) ! (ac)(df)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); f = t3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdaf >
                        !hmatel = -h2c_vvvv(b,c,d,f)
                        !hmatel = -h2c_vvvv(d,f,b,c)
                        hmatel = -h2c_vvvv(f,d,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkdaf > = -A(bc)A(df) h1b_vv(b,d) * delta(c,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==f) hmatel1 = -h1b_vv(d,b) !-h1b_vv(b,d) ! (1)
                        if (b==f) hmatel2 = h1b_vv(d,c)  !h1b_vv(c,d) ! (bc)
                        if (c==d) hmatel3 = h1b_vv(f,b)  !h1b_vv(b,f) ! (df)
                        if (b==d) hmatel4 = -h1b_vv(f,c) !-h1b_vv(c,f) ! (bc)(df)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); f = t3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdcf >
                        !hmatel = -h2c_vvvv(a,b,d,f)
                        !hmatel = -h2c_vvvv(d,f,a,b)
                        hmatel = -h2c_vvvv(f,d,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkdcf > = -A(ab)A(df) h1b_vv(a,d) * delta(b,f)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==f) hmatel1 = -h1b_vv(d,a) !-h1b_vv(a,d) ! (1)
                        if (a==f) hmatel2 = h1b_vv(d,b)  !h1b_vv(b,d) ! (ab)
                        if (b==d) hmatel3 = h1b_vv(f,a)  !h1b_vv(a,f) ! (df)
                        if (a==d) hmatel4 = -h1b_vv(f,b) !-h1b_vv(b,f) ! (ab)(df)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if 
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! IJKC LOOP !!!
                  call get_index_table(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), (/3,nub/), nob, nob, nob, nub)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/4,5,6,3/), nob, nob, nob, nub, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); e = t3d_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdec >
                        !hmatel = h2c_vvvv(a,b,d,e)
                        !hmatel = h2c_vvvv(d,e,a,b)
                        hmatel = h2c_vvvv(e,d,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkdec > = A(ab)A(de) h1b_vv(a,d) * delta(b,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==e) hmatel1 = h1b_vv(d,a)  !h1b_vv(a,d) ! (1)
                        if (a==e) hmatel2 = -h1b_vv(d,b) !-h1b_vv(b,d) ! (ab)
                        if (b==d) hmatel3 = -h1b_vv(e,a) !-h1b_vv(a,e) ! (de)
                        if (a==d) hmatel4 = h1b_vv(e,b)  !h1b_vv(b,e) ! (ab)(de)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     ! (ac)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); e = t3d_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdea >
                        !hmatel = -h2c_vvvv(c,b,d,e)
                        !hmatel = -h2c_vvvv(d,e,c,b)
                        hmatel = h2c_vvvv(e,d,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkdea > = -A(bc)A(de) h1b_vv(c,d) * delta(b,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (b==e) hmatel1 = -h1b_vv(d,c) !-h1b_vv(c,d) ! (1)
                        if (c==e) hmatel2 = h1b_vv(d,b)  !h1b_vv(b,d) ! (bc)
                        if (b==d) hmatel3 = h1b_vv(e,c)  !h1b_vv(c,e) ! (de)
                        if (c==d) hmatel4 = -h1b_vv(e,b) !-h1b_vv(b,e) ! (bc)(de)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); e = t3d_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdeb >
                        !hmatel = -h2c_vvvv(a,c,d,e)
                        !hmatel = -h2c_vvvv(d,e,a,c)
                        hmatel = -h2c_vvvv(e,d,c,a)
                        ! compute < ijkabc | h1a(vv) | ijkdeb > = -A(ac)A(de) h1b_vv(a,d) * delta(c,e)
                        hmatel1 = 0.0d0; hmatel2 = 0.0d0; hmatel3 = 0.0d0; hmatel4 = 0.0d0;
                        if (c==e) hmatel1 = -h1b_vv(d,a) !-h1b_vv(a,d) ! (1)
                        if (a==e) hmatel2 = h1b_vv(d,c)  !h1b_vv(c,d) ! (ac)
                        if (c==d) hmatel3 = h1b_vv(e,a)  !h1b_vv(a,e) ! (de)
                        if (a==d) hmatel4 = -h1b_vv(e,c) !-h1b_vv(c,e) ! (ac)(de)
                        hmatel = hmatel + 0.5d0 * (hmatel1 + hmatel2 + hmatel3 + hmatel4)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 5: A(i/jk)A(a/bc) h2c(amie) * t3d(ebcmjk)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = (nub-1)*(nub-2)/2*(nob-1)*(nob-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! ABIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnabf >
                        !hmatel = h2c_voov(c,n,k,f)
                        hmatel = h2c_voov(n,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnbcf >
                        !hmatel = h2c_voov(a,n,k,f)
                        hmatel = h2c_voov(n,f,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnacf >
                        !hmatel = -h2c_voov(b,n,k,f)
                        hmatel = -h2c_voov(n,f,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknabf >
                        !hmatel = h2c_voov(c,n,i,f)
                        hmatel = h2c_voov(n,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknbcf >
                        !hmatel = h2c_voov(a,n,i,f)
                        hmatel = h2c_voov(n,f,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknacf >
                        !hmatel = -h2c_voov(b,n,i,f)
                        hmatel = -h2c_voov(n,f,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknabf >
                        !hmatel = -h2c_voov(c,n,j,f)
                        hmatel = -h2c_voov(n,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknbcf >
                        !hmatel = -h2c_voov(a,n,j,f)
                        hmatel = -h2c_voov(n,f,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknacf >
                        !hmatel = h2c_voov(b,n,j,f)
                        hmatel = h2c_voov(n,f,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIJ LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnaec >
                        !hmatel = h2c_voov(b,n,k,e)
                        hmatel = h2c_voov(n,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnbec >
                        !hmatel = -h2c_voov(a,n,k,e)
                        hmatel = -h2c_voov(n,e,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijnaeb >
                        !hmatel = -h2c_voov(c,n,k,e)
                        hmatel = -h2c_voov(n,e,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknaec >
                        !hmatel = h2c_voov(b,n,i,e)
                        hmatel = h2c_voov(n,e,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknbec >
                        !hmatel = -h2c_voov(a,n,i,e)
                        hmatel = -h2c_voov(n,e,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jknaeb >
                        !hmatel = -h2c_voov(c,n,i,e)
                        hmatel = -h2c_voov(n,e,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknaec >
                        !hmatel = -h2c_voov(b,n,j,e)
                        hmatel = -h2c_voov(n,e,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknbec >
                        !hmatel = h2c_voov(a,n,j,e)
                        hmatel = h2c_voov(n,e,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | iknaeb >
                        !hmatel = h2c_voov(c,n,j,e)
                        hmatel = h2c_voov(n,e,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIJ LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/2,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijndbc >
                        !hmatel = h2c_voov(a,n,k,d)
                        hmatel = h2c_voov(n,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijndac >
                        !hmatel = -h2c_voov(b,n,k,d)
                        hmatel = -h2c_voov(n,d,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ijndab >
                        !hmatel = h2c_voov(c,n,k,d)
                        hmatel = h2c_voov(n,d,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jkndbc >
                        !hmatel = h2c_voov(a,n,i,d)
                        hmatel = h2c_voov(n,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jkndac >
                        !hmatel = -h2c_voov(b,n,i,d)
                        hmatel = -h2c_voov(n,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | jkndab >
                        !hmatel = h2c_voov(c,n,i,d)
                        hmatel = h2c_voov(n,d,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ikndbc >
                        !hmatel = -h2c_voov(a,n,j,d)
                        hmatel = -h2c_voov(n,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ikndac >
                        !hmatel = h2c_voov(b,n,j,d)
                        hmatel = h2c_voov(n,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); n = t3d_excits_copy(jdet,6);
                        ! compute < ijkabc | h2a(voov) | ikndab >
                        !hmatel = -h2c_voov(c,n,j,d)
                        hmatel = -h2c_voov(n,d,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABIK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkabf >
                        !hmatel = h2c_voov(c,m,j,f)
                        hmatel = h2c_voov(m,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkbcf >
                        !hmatel = h2c_voov(a,m,j,f)
                        hmatel = h2c_voov(m,f,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkacf >
                        !hmatel = -h2c_voov(b,m,j,f)
                        hmatel = -h2c_voov(m,f,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkabf >
                        !hmatel = -h2c_voov(c,m,i,f)
                        hmatel = -h2c_voov(m,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkbcf >
                        !hmatel = -h2c_voov(a,m,i,f)
                        hmatel = -h2c_voov(m,f,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkacf >
                        !hmatel = h2c_voov(b,m,i,f)
                        hmatel = h2c_voov(m,f,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjabf >
                        !hmatel = -h2c_voov(c,m,k,f)
                        hmatel = -h2c_voov(m,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjbcf >
                        !hmatel = -h2c_voov(a,m,k,f)
                        hmatel = -h2c_voov(m,f,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjacf >
                        !hmatel = h2c_voov(b,m,k,f)
                        hmatel = h2c_voov(m,f,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACIK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkaec >
                        !hmatel = h2c_voov(b,m,j,e)
                        hmatel = h2c_voov(m,e,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkbec >
                        !hmatel = -h2c_voov(a,m,j,e)
                        hmatel = -h2c_voov(m,e,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkaeb >
                        !hmatel = -h2c_voov(c,m,j,e)
                        hmatel = -h2c_voov(m,e,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkaec >
                        !hmatel = -h2c_voov(b,m,i,e)
                        hmatel = -h2c_voov(m,e,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkbec >
                        !hmatel = h2c_voov(a,m,i,e)
                        hmatel = h2c_voov(m,e,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkaeb >
                        !hmatel = h2c_voov(c,m,i,e)
                        hmatel = h2c_voov(m,e,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjaec >
                        !hmatel = -h2c_voov(b,m,k,e)
                        hmatel = -h2c_voov(m,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjbec >
                        !hmatel = h2c_voov(a,m,k,e)
                        hmatel = h2c_voov(m,e,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjaeb >
                        !hmatel = h2c_voov(c,m,k,e)
                        hmatel = h2c_voov(m,e,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCIK LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkdbc >
                        !hmatel = h2c_voov(a,m,j,d)
                        hmatel = h2c_voov(m,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkdac >
                        !hmatel = -h2c_voov(b,m,j,d)
                        hmatel = -h2c_voov(m,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imkdab >
                        !hmatel = h2c_voov(c,m,j,d)
                        hmatel = h2c_voov(m,d,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkdbc >
                        !hmatel = -h2c_voov(a,m,i,d)
                        hmatel = -h2c_voov(m,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkdac >
                        !hmatel = h2c_voov(b,m,i,d)
                        hmatel = h2c_voov(m,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | jmkdab >
                        !hmatel = -h2c_voov(c,m,i,d)
                        hmatel = -h2c_voov(m,d,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjdbc >
                        !hmatel = -h2c_voov(a,m,k,d)
                        hmatel = -h2c_voov(m,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjdac >
                        !hmatel = h2c_voov(b,m,k,d)
                        hmatel = h2c_voov(m,d,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); m = t3d_excits_copy(jdet,5);
                        ! compute < ijkabc | h2a(voov) | imjdab >
                        !hmatel = -h2c_voov(c,m,k,d)
                        hmatel = -h2c_voov(m,d,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ABJK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,2,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkabf >
                        !hmatel = h2c_voov(c,l,i,f)
                        hmatel = h2c_voov(l,f,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkbcf >
                        !hmatel = h2c_voov(a,l,i,f)
                        hmatel = h2c_voov(l,f,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkacf >
                        !hmatel = -h2c_voov(b,l,i,f)
                        hmatel = -h2c_voov(l,f,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likabf >
                        !hmatel = -h2c_voov(c,l,j,f)
                        hmatel = -h2c_voov(l,f,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likbcf >
                        !hmatel = -h2c_voov(a,l,j,f)
                        hmatel = -h2c_voov(l,f,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likacf >
                        !hmatel = h2c_voov(b,l,j,f)
                        hmatel = h2c_voov(l,f,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijabf >
                        !hmatel = h2c_voov(c,l,k,f)
                        hmatel = h2c_voov(l,f,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijbcf >
                        !hmatel = h2c_voov(a,l,k,f)
                        hmatel = h2c_voov(l,f,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = t3d_excits_copy(jdet,3); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijacf >
                        !hmatel = -h2c_voov(b,l,k,f)
                        hmatel = -h2c_voov(l,f,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! ACJK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/1,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkaec >
                        !hmatel = h2c_voov(b,l,i,e)
                        hmatel = h2c_voov(l,e,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkbec >
                        !hmatel = -h2c_voov(a,l,i,e)
                        hmatel = -h2c_voov(l,e,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkaeb >
                        !hmatel = -h2c_voov(c,l,i,e)
                        hmatel = -h2c_voov(l,e,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likaec >
                        !hmatel = -h2c_voov(b,l,j,e)
                        hmatel = -h2c_voov(l,e,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likbec >
                        !hmatel = h2c_voov(a,l,j,e)
                        hmatel = h2c_voov(l,e,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likaeb >
                        !hmatel = h2c_voov(c,l,j,e)
                        hmatel = h2c_voov(l,e,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijaec >
                        !hmatel = h2c_voov(b,l,k,e)
                        hmatel = h2c_voov(l,e,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijbec >
                        !hmatel = -h2c_voov(a,l,k,e)
                        hmatel = -h2c_voov(l,e,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = t3d_excits_copy(jdet,2); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijaeb >
                        !hmatel = -h2c_voov(c,l,k,e)
                        hmatel = -h2c_voov(l,e,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(t3d_excits_copy, t3d_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,&
                  !$omp t3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkdbc >
                        !hmatel = h2c_voov(a,l,i,d)
                        hmatel = h2c_voov(l,d,a,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkdac >
                        !hmatel = -h2c_voov(b,l,i,d)
                        hmatel = -h2c_voov(l,d,b,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | ljkdab >
                        !hmatel = h2c_voov(c,l,i,d)
                        hmatel = h2c_voov(l,d,c,i)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likdbc >
                        !hmatel = -h2c_voov(a,l,j,d)
                        hmatel = -h2c_voov(l,d,a,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likdac >
                        !hmatel = h2c_voov(b,l,j,d)
                        hmatel = h2c_voov(l,d,b,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | likdab >
                        !hmatel = -h2c_voov(c,l,j,d)
                        hmatel = -h2c_voov(l,d,c,j)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijdbc >
                        !hmatel = h2c_voov(a,l,k,d)
                        hmatel = h2c_voov(l,d,a,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijdac >
                        !hmatel = -h2c_voov(b,l,k,d)
                        hmatel = -h2c_voov(l,d,b,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = t3d_excits_copy(jdet,1); l = t3d_excits_copy(jdet,4);
                        ! compute < ijkabc | h2a(voov) | lijdab >
                        !hmatel = h2c_voov(c,l,k,d)
                        hmatel = h2c_voov(l,d,c,k)
                        resid(idet) = resid(idet) + hmatel * t3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 6: A(i/jk)A(a/bc) h2b(maei) * t3c(ebcmjk)
                  ! allocate and copy over t3c arrays
                  allocate(amps_buff(n3abb),excits_buff(n3abb,6))
                  amps_buff(:) = t3c_amps(:)
                  excits_buff(:,:) = t3c_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nub*(nub-1)/2*nob*(nob-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! BCJK LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp t3d_excits_copy,excits_buff,&
                  !$omp t3d_amps_copy,amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | lj~k~db~c~ >
                        !hmatel = h2b_ovvo(l,a,d,i)
                        hmatel = h2b_ovvo(l,d,a,i)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | lj~k~da~c~ >
                        !hmatel = -h2b_ovvo(l,b,d,i)
                        hmatel = -h2b_ovvo(l,d,b,i)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | lj~k~da~b~ >
                        !hmatel = h2b_ovvo(l,c,d,i)
                        hmatel = h2b_ovvo(l,d,c,i)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | li~k~db~c~ >
                        !hmatel = -h2b_ovvo(l,a,d,j)
                        hmatel = -h2b_ovvo(l,d,a,j)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | li~k~da~c~ >
                        !hmatel = h2b_ovvo(l,b,d,j)
                        hmatel = h2b_ovvo(l,d,b,j)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | li~k~da~b~ >
                        !hmatel = -h2b_ovvo(l,c,d,j)
                        hmatel = -h2b_ovvo(l,d,c,j)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | li~j~db~c~ >
                        !hmatel = h2b_ovvo(l,a,d,k)
                        hmatel = h2b_ovvo(l,d,a,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | li~j~da~c~ >
                        !hmatel = -h2b_ovvo(l,b,d,k)
                        hmatel = -h2b_ovvo(l,d,b,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(ovvo) | li~j~da~b~ >
                        !hmatel = h2b_ovvo(l,c,d,k)
                        hmatel = h2b_ovvo(l,d,c,k)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                 end do; end do; end do;
                 !$omp end do
                 !$omp end parallel
                 !!!! END OMP PARALLEL SECTION !!!!
                 ! deallocate sorting arrays
                 deallocate(loc_arr,idx_table)
                 ! deallocate t3 buffer arrays
                 deallocate(amps_buff,excits_buff)

                 !
                 ! Moment contributions
                 !
                 allocate(xbuf(nob,nob,nub,nub))
                 do a = 1,nub
                    do b = 1,nub
                       do ii = 1,nob
                          do jj = 1,nob
                             xbuf(jj,ii,b,a) = t2c(b,a,jj,ii)
                          end do
                       end do
                    end do
                 end do
                 !$omp parallel shared(resid,t3d_excits_copy,xbuf,I2C_vooo,n3bbb),&
                 !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                    do m = 1, nob
                       ! -A(k/ij)A(a/bc) h2a(amij) * t2c(bcmk)
                       resid(idet) = resid(idet) - H2C_vooo(m,a,i,j) * xbuf(m,k,b,c)
                       resid(idet) = resid(idet) + H2C_vooo(m,b,i,j) * xbuf(m,k,a,c)
                       resid(idet) = resid(idet) + H2C_vooo(m,c,i,j) * xbuf(m,k,b,a)
                       resid(idet) = resid(idet) + H2C_vooo(m,a,k,j) * xbuf(m,i,b,c)
                       resid(idet) = resid(idet) - H2C_vooo(m,b,k,j) * xbuf(m,i,a,c)
                       resid(idet) = resid(idet) - H2C_vooo(m,c,k,j) * xbuf(m,i,b,a)
                       resid(idet) = resid(idet) + H2C_vooo(m,a,i,k) * xbuf(m,j,b,c)
                       resid(idet) = resid(idet) - H2C_vooo(m,b,i,k) * xbuf(m,j,a,c)
                       resid(idet) = resid(idet) - H2C_vooo(m,c,i,k) * xbuf(m,j,b,a)
                    end do
                 end do; end do; end do;
                 !$omp end do
                 !$omp end parallel
                 deallocate(xbuf)

                 !$omp parallel shared(resid,t3d_excits_copy,t2c,I2C_vvov,n3bbb),&
                 !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                    do e = 1, nub
                       ! A(i/jk)(c/ab) h2a(abie) * t2c(ecjk)
                       resid(idet) = resid(idet) + H2C_vvov(e,a,b,i) * t2c(e,c,j,k)
                       resid(idet) = resid(idet) - H2C_vvov(e,c,b,i) * t2c(e,a,j,k)
                       resid(idet) = resid(idet) - H2C_vvov(e,a,c,i) * t2c(e,b,j,k)
                       resid(idet) = resid(idet) - H2C_vvov(e,a,b,j) * t2c(e,c,i,k)
                       resid(idet) = resid(idet) + H2C_vvov(e,c,b,j) * t2c(e,a,i,k)
                       resid(idet) = resid(idet) + H2C_vvov(e,a,c,j) * t2c(e,b,i,k)
                       resid(idet) = resid(idet) - H2C_vvov(e,a,b,k) * t2c(e,c,j,i)
                       resid(idet) = resid(idet) + H2C_vvov(e,c,b,k) * t2c(e,a,j,i)
                       resid(idet) = resid(idet) + H2C_vvov(e,a,c,k) * t2c(e,b,j,i)
                    end do
                 end do; end do; end do;
                 !$omp end do
                 !$omp end parallel

                  ! deallocate copied t3d arrays
                  deallocate(t3d_amps_copy,t3d_excits_copy)
              end subroutine build_moments3d_ijk

              subroutine build_leftamps3a_ijk(resid, i, j, k,&
                                              l1a, l2a,&
                                              l3a_amps, l3a_excits,&
                                              l3b_amps, l3b_excits,&
                                              h1a_ov, h1a_oo, h1a_vv,&
                                              h2a_oooo, h2a_ooov, h2a_oovv,&
                                              h2a_voov, h2a_vovv, h2a_vvvv,&
                                              h2b_ovvo,&
                                              x2a_ooov, x2a_vovv,&
                                              orbsym, sym_ijk, target_sym,&
                                              n3aaa, n3aab,&
                                              noa, nua, nob, nub, norb)
                  ! Input dimension variables
                  integer, intent(in) :: noa, nua, nob, nub, norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  integer, intent(in) :: n3aaa, n3aab
                  ! occupied block indices
                  integer, intent(in) :: i, j, k
                  ! Input L arrays
                  real(kind=8), intent(in) :: l1a(nua,noa)
                  real(kind=8), intent(in) :: l2a(nua,nua,noa,noa)
                  integer, intent(in) :: l3a_excits(n3aaa,6)
                  integer, intent(in) :: l3b_excits(n3aab,6)
                  real(kind=8), intent(in) :: l3a_amps(n3aaa)
                  real(kind=8), intent(in) :: l3b_amps(n3aab)
                  ! Input H and X arrays
                  real(kind=8), intent(in) :: h1a_ov(noa,nua)
                  real(kind=8), intent(in) :: h1a_oo(noa,noa)
                  real(kind=8), intent(in) :: h1a_vv(nua,nua)
                  real(kind=8), intent(in) :: h2a_oooo(noa,noa,noa,noa)
                  real(kind=8), intent(in) :: h2a_ooov(noa,noa,noa,nua)
                  real(kind=8), intent(in) :: h2a_oovv(noa,noa,nua,nua)
                  real(kind=8), intent(in) :: h2a_voov(nua,noa,noa,nua)
                  real(kind=8), intent(in) :: h2a_vovv(nua,noa,nua,nua)
                  real(kind=8), intent(in) :: h2a_vvvv(nua,nua,nua,nua)
                  real(kind=8), intent(in) :: h2b_ovvo(noa,nub,nua,nob)
                  real(kind=8), intent(in) :: x2a_ooov(noa,noa,noa,nua)
                  real(kind=8), intent(in) :: x2a_vovv(nua,noa,nua,nua)
                  ! Output variables
                  real(kind=8), intent(out) :: resid(nua,nua,nua)
                  ! Local variables
                  integer, allocatable :: excits_buff(:,:), l3a_excits_copy(:,:)
                  real(kind=8), allocatable :: amps_buff(:), l3a_amps_copy(:)
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)
                  real(kind=8) :: l_amp, hmatel, hmatel1, res
                  integer :: a, b, c, d, ii, jj, kk, l, m, n, e, f, jdet
                  integer :: idx, nloc
                  integer :: sym
                  ! Q space array
                  logical(kind=1) :: qspace(nua,nua,nua)

                  ! zero the residual vector
                  resid = 0.0d0

                  ! copy over l3a_amps_copy and l3a_excits_copy
                  allocate(l3a_amps_copy(n3aaa),l3a_excits_copy(n3aaa,6))
                  l3a_amps_copy(:) = l3a_amps(:)
                  l3a_excits_copy(:,:) = l3a_excits(:,:)

                  ! reorder l3a into (i,j,k) order
                  nloc = noa*(noa-1)*(noa-2)/6
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(noa,noa,noa))
                  call get_index_table3(idx_table3, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), noa, noa, noa)
                  call sort3(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table3, (/4,5,6/), noa, noa, noa, nloc, n3aaa)
                  ! Construct Q space for block (i,j,k)
                  qspace = .true.
                  idx = idx_table3(i,j,k)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = l3a_excits_copy(jdet,1); b = l3a_excits_copy(jdet,2); c = l3a_excits_copy(jdet,3);
                        qspace(a,b,c) = .false.
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+noa))
                        sym = ieor(sym,orbsym(b+noa))
                        sym = ieor(sym,orbsym(c+noa))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)
        
                  !if (n3aaa/=0) then
                  !!!! diagram 1: -A(i/jk) h1a(im) * l3a(abcmjk)
                  !!!! diagram 3: 1/2 A(k/ij) h2a(ijmn) * l3a(abcmnk)
                  ! NOTE: WITHIN THESE LOOPS, H1A(OO) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2
                  ! allocate new sorting arrays
                  nloc = nua*(nua-1)*(nua-2)/6*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,nua,noa))
                  !!! SB: (1,2,3,6) !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/-1,nua/), (/3,noa/), nua, nua, nua, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,2,3,6/), nua, nua, nua, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h1a_oo,h2a_oooo,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3a_excits_copy(jdet,4); m = l3a_excits_copy(jdet,5);
                        ! compute < lmkabc | h2a(oooo) | ijkabc >
                        hmatel = h2a_oooo(i,j,l,m)
                        ! compute < lmkabc | h1a(oo) | ijkabc > = -A(ij)A(lm) h1a_oo(i,l) * delta(j,m)
                        hmatel1 = 0.0d0
                        if (m==j) hmatel1 = hmatel1 - h1a_oo(i,l) ! (1)
                        if (m==i) hmatel1 = hmatel1 + h1a_oo(j,l) ! (ij)
                        if (l==j) hmatel1 = hmatel1 + h1a_oo(i,m) ! (lm)
                        if (l==i) hmatel1 = hmatel1 - h1a_oo(j,m) ! (ij)(lm)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     ! (ik)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3a_excits_copy(jdet,4); m = l3a_excits_copy(jdet,5);
                           ! compute < lmiabc | h2a(oooo) | ijkabc >
                           hmatel = -h2a_oooo(k,j,l,m)
                           ! compute < lmiabc | h1a(oo) | ijkabc > = A(jk)A(lm) h1a_oo(k,l) * delta(j,m)
                           hmatel1 = 0.0d0
                           if (m==j) hmatel1 = hmatel1 + h1a_oo(k,l) ! (1)
                           if (m==k) hmatel1 = hmatel1 - h1a_oo(j,l) ! (jk)
                           if (l==j) hmatel1 = hmatel1 - h1a_oo(k,m) ! (lm)
                           if (l==k) hmatel1 = hmatel1 + h1a_oo(j,m) ! (jk)(lm)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3a_excits_copy(jdet,4); m = l3a_excits_copy(jdet,5);
                           ! compute < lmjabc | h2a(oooo) | ijkabc >
                           hmatel = -h2a_oooo(i,k,l,m)
                           ! compute < lmjabc | h1a(oo) | ijkabc > = A(ik)A(lm) h1a_oo(i,l) * delta(k,m)
                           hmatel1 = 0.0d0
                           if (m==k) hmatel1 = hmatel1 + h1a_oo(i,l) ! (1)
                           if (m==i) hmatel1 = hmatel1 - h1a_oo(k,l) ! (ik)
                           if (l==k) hmatel1 = hmatel1 - h1a_oo(i,m) ! (lm)
                           if (l==i) hmatel1 = hmatel1 + h1a_oo(k,m) ! (ik)(lm)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,3,4) !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/-1,nua/), (/1,noa-2/), nua, nua, nua, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,2,3,4/), nua, nua, nua, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,i)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = l3a_excits_copy(jdet,5); n = l3a_excits_copy(jdet,6);
                        ! compute < imnabc | h2a(oooo) | ijkabc >
                        hmatel = h2a_oooo(j,k,m,n)
                        ! compute < imnabc | h1a(oo) | ijkabc > = -A(jk)A(mn) h1a_oo(j,m) * delta(k,n)
                        hmatel1 = 0.0d0
                        if (n==k) hmatel1 = hmatel1 - h1a_oo(j,m) ! (1)
                        if (n==j) hmatel1 = hmatel1 + h1a_oo(k,m) ! (jk)
                        if (m==k) hmatel1 = hmatel1 + h1a_oo(j,n) ! (mn)
                        if (m==j) hmatel1 = hmatel1 - h1a_oo(k,n) ! (jk)(mn)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = l3a_excits_copy(jdet,5); n = l3a_excits_copy(jdet,6);
                           ! compute < jmnabc | h2a(oooo) | ijkabc >
                           hmatel = -h2a_oooo(i,k,m,n)
                           ! compute < jmnabc | h1a(oo) | ijkabc > = A(ik)A(mn) h1a_oo(i,m) * delta(k,n)
                           hmatel1 = 0.0d0
                           if (n==k) hmatel1 = hmatel1 + h1a_oo(i,m) ! (1)
                           if (n==i) hmatel1 = hmatel1 - h1a_oo(k,m) ! (ik)
                           if (m==k) hmatel1 = hmatel1 - h1a_oo(i,n) ! (mn)
                           if (m==i) hmatel1 = hmatel1 + h1a_oo(k,n) ! (ik)(mn)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                        end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = l3a_excits_copy(jdet,5); n = l3a_excits_copy(jdet,6);
                           ! compute < kmnabc | h2a(oooo) | ijkabc >
                           hmatel = -h2a_oooo(j,i,m,n)
                           ! compute < kmnabc | h1a(oo) | ijkabc > = A(ij)A(mn) h1a_oo(j,m) * delta(i,n)
                           hmatel1 = 0.0d0
                           if (n==i) hmatel1 = hmatel1 - h1a_oo(j,m) ! (1)
                           if (n==j) hmatel1 = hmatel1 + h1a_oo(i,m) ! (ij)
                           if (m==i) hmatel1 = hmatel1 + h1a_oo(j,n) ! (mn)
                           if (m==j) hmatel1 = hmatel1 - h1a_oo(i,n) ! (ij)(mn)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,3,5) !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/-1,nua/), (/2,noa-1/), nua, nua, nua, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,2,3,5/), nua, nua, nua, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3a_excits_copy(jdet,4); n = l3a_excits_copy(jdet,6);
                        ! compute < ljnabc | h2a(oooo) | ijkabc >
                        hmatel = h2a_oooo(i,k,l,n)
                        ! compute < ljnabc | h1a(oo) | ijkabc > = -A(ik)A(ln) h1a_oo(i,l) * delta(k,n)
                        hmatel1 = 0.0d0
                        if (n==k) hmatel1 = hmatel1 - h1a_oo(i,l) ! (1)
                        if (n==i) hmatel1 = hmatel1 + h1a_oo(k,l) ! (ik)
                        if (l==k) hmatel1 = hmatel1 + h1a_oo(i,n) ! (ln)
                        if (l==i) hmatel1 = hmatel1 - h1a_oo(k,n) ! (ik)(ln)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3a_excits_copy(jdet,4); n = l3a_excits_copy(jdet,6);
                           ! compute < linabc | h2a(oooo) | ijkabc >
                           hmatel = -h2a_oooo(j,k,l,n)
                           ! compute < linabc | h1a(oo) | ijkabc > = A(jk)A(ln) h1a_oo(j,l) * delta(k,n)
                           hmatel1 = 0.0d0
                           if (n==k) hmatel1 = hmatel1 + h1a_oo(j,l) ! (1)
                           if (n==j) hmatel1 = hmatel1 - h1a_oo(k,l) ! (jk)
                           if (l==k) hmatel1 = hmatel1 - h1a_oo(j,n) ! (ln)
                           if (l==j) hmatel1 = hmatel1 + h1a_oo(k,n) ! (jk)(ln)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3a_excits_copy(jdet,4); n = l3a_excits_copy(jdet,6);
                           ! compute < lknabc | h2a(oooo) | ijkabc >
                           hmatel = -h2a_oooo(i,j,l,n)
                           ! compute < lknabc | h1a(oo) | ijkabc > = A(ij)A(ln) h1a_oo(i,l) * delta(j,n)
                           hmatel1 = 0.0d0
                           if (n==j) hmatel1 = hmatel1 + h1a_oo(i,l) ! (1)
                           if (n==i) hmatel1 = hmatel1 - h1a_oo(j,l) ! (ij)
                           if (l==j) hmatel1 = hmatel1 - h1a_oo(i,n) ! (ln)
                           if (l==i) hmatel1 = hmatel1 + h1a_oo(j,n) ! (ij)(ln)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 2: A(a/bc) h1a(ea) * l3a(ebcijk)
                  !!!! diagram 4: 1/2 A(c/ab) h2a(efab) * l3a(ebcijk)
                  ! NOTE: WITHIN THESE LOOPS, H1A(VV) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2
                  ! allocate new sorting arrays
                  nloc = noa*(noa-1)*(noa-2)/6*nua
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,noa,nua))
                  !!! SB: (4,5,6,1) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), (/1,nua-2/), noa, noa, noa, nua)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/4,5,6,1/), noa, noa, noa, nua, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,a)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); f = l3a_excits_copy(jdet,3);
                        ! compute < ijkaef | h2a(vvvv) | ijkabc >
                        hmatel = h2a_vvvv(e,f,b,c)
                        ! compute < ijkaef | h1a(vv) | ijkabc > = A(bc)A(ef) h1a_vv(e,b) * delta(f,c)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 + h1a_vv(e,b) ! (1)
                        if (b==f) hmatel1 = hmatel1 - h1a_vv(e,c) ! (bc)
                        if (c==e) hmatel1 = hmatel1 - h1a_vv(f,b) ! (ef)
                        if (b==e) hmatel1 = hmatel1 + h1a_vv(f,c) ! (bc)(ef)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); f = l3a_excits_copy(jdet,3);
                        ! compute < ijkbef | h2a(vvvv) | ijkabc >
                        hmatel = -h2a_vvvv(e,f,a,c)
                        ! compute < ijkbef | h1a(vv) | ijkabc > = -A(ac)A(ef) h1a_vv(e,a) * delta(f,c)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 - h1a_vv(e,a) ! (1)
                        if (a==f) hmatel1 = hmatel1 + h1a_vv(e,c) ! (ac)
                        if (c==e) hmatel1 = hmatel1 + h1a_vv(f,a) ! (ef)
                        if (a==e) hmatel1 = hmatel1 - h1a_vv(f,c) ! (ac)(ef)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); f = l3a_excits_copy(jdet,3);
                        ! compute < ijkcef | h2a(vvvv) | ijkabc >
                        hmatel = -h2a_vvvv(e,f,b,a)
                        ! compute < ijkcef | h1a(vv) | ijkabc > = -A(ab)A(ef) h1a_vv(e,b) * delta(f,a)
                        hmatel1 = 0.0d0
                        if (a==f) hmatel1 = hmatel1 - h1a_vv(e,b) ! (1)
                        if (b==f) hmatel1 = hmatel1 + h1a_vv(e,a) ! (ab)
                        if (a==e) hmatel1 = hmatel1 + h1a_vv(f,b) ! (ef)
                        if (b==e) hmatel1 = hmatel1 - h1a_vv(f,a) ! (ab)(ef)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (4,5,6,2) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), (/2,nua-1/), noa, noa, noa, nua)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/4,5,6,2/), noa, noa, noa, nua, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); f = l3a_excits_copy(jdet,3);
                        ! compute < ijkdbf | h2a(vvvv) | ijkabc >
                        hmatel = h2a_vvvv(d,f,a,c)
                        ! compute < ijkdbf | h1a(vv) | ijkabc > = A(ac)A(df) h1a_vv(d,a) * delta(f,c)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 + h1a_vv(d,a) ! (1)
                        if (a==f) hmatel1 = hmatel1 - h1a_vv(d,c) ! (ac)
                        if (c==d) hmatel1 = hmatel1 - h1a_vv(f,a) ! (df)
                        if (a==d) hmatel1 = hmatel1 + h1a_vv(f,c) ! (ac)(df)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); f = l3a_excits_copy(jdet,3);
                        ! compute < ijkdaf | h2a(vvvv) | ijkabc >
                        hmatel = -h2a_vvvv(d,f,b,c)
                        ! compute < ijkdaf | h1a(vv) | ijkabc > = -A(bc)A(df) h1a_vv(d,b) * delta(f,c)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 - h1a_vv(d,b) ! (1)
                        if (b==f) hmatel1 = hmatel1 + h1a_vv(d,c) ! (bc)
                        if (c==d) hmatel1 = hmatel1 + h1a_vv(f,b) ! (df)
                        if (b==d) hmatel1 = hmatel1 - h1a_vv(f,c) ! (bc)(df)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); f = l3a_excits_copy(jdet,3);
                        ! compute < ijkdcf | h2a(vvvv) | ijkabc >
                        hmatel = -h2a_vvvv(d,f,a,b)
                        ! compute < ijkdcf | h1a(vv) | ijkabc > = -A(ab)A(df) h1a_vv(d,a) * delta(f,b)
                        hmatel1 = 0.0d0
                        if (b==f) hmatel1 = hmatel1 - h1a_vv(d,a) ! (1)
                        if (a==f) hmatel1 = hmatel1 + h1a_vv(d,b) ! (ab)
                        if (b==d) hmatel1 = hmatel1 + h1a_vv(f,a) ! (df)
                        if (a==d) hmatel1 = hmatel1 - h1a_vv(f,b) ! (ab)(df)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (4,5,6,3) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-2/), (/-1,noa-1/), (/-1,noa/), (/3,nua/), noa, noa, noa, nua)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/4,5,6,3/), noa, noa, noa, nua, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); e = l3a_excits_copy(jdet,2);
                        ! compute < ijkdec | h2a(vvvv) | ijkabc >
                        hmatel = h2a_vvvv(d,e,a,b)
                        ! compute < ijkdec | h1a(vv) | ijkabc > = A(ab)A(de) h1a_vv(d,a) * delta(e,b)
                        hmatel1 = 0.0d0
                        if (b==e) hmatel1 = hmatel1 + h1a_vv(d,a) ! (1)
                        if (a==e) hmatel1 = hmatel1 - h1a_vv(d,b) ! (ab)
                        if (b==d) hmatel1 = hmatel1 - h1a_vv(e,a) ! (de)
                        if (a==d) hmatel1 = hmatel1 + h1a_vv(e,b) ! (ab)(de)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     ! (ac)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); e = l3a_excits_copy(jdet,2);
                        ! compute < ijkdea | h2a(vvvv) | ijkabc >
                        hmatel = -h2a_vvvv(d,e,c,b)
                        ! compute < ijkdea | h1a(vv) | ijkabc > = -A(bc)A(de) h1a_vv(d,c) * delta(e,b)
                        hmatel1 = 0.0d0
                        if (b==e) hmatel1 = hmatel1 - h1a_vv(d,c) ! (1)
                        if (c==e) hmatel1 = hmatel1 + h1a_vv(d,b) ! (bc)
                        if (b==d) hmatel1 = hmatel1 + h1a_vv(e,c) ! (de)
                        if (c==d) hmatel1 = hmatel1 - h1a_vv(e,b) ! (bc)(de)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); e = l3a_excits_copy(jdet,2);
                        ! compute < ijkdeb | h2a(vvvv) | ijkabc >
                        hmatel = -h2a_vvvv(d,e,a,c)
                        ! compute < ijkdeb | h1a(vv) | ijkabc > = -A(ac)A(de) h1a_vv(d,a) * delta(e,c)
                        hmatel1 = 0.0d0
                        if (c==e) hmatel1 = hmatel1 - h1a_vv(d,a) ! (1)
                        if (a==e) hmatel1 = hmatel1 + h1a_vv(d,c) ! (ac)
                        if (c==d) hmatel1 = hmatel1 + h1a_vv(e,a) ! (de)
                        if (a==d) hmatel1 = hmatel1 - h1a_vv(e,c) ! (ac)(de)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 5: A(i/jk)A(a/bc) h2a(eima) * l3a(ebcmjk)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = (nua-1)*(nua-2)/2*(noa-1)*(noa-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < ijnabf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < ijnbcf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,k,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < ijnacf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,k,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < jknabf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,i,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < jknbcf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,i,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < jknacf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,i,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < iknabf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,j,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < iknbcf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,j,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); n = l3a_excits_copy(jdet,6);
                        ! compute < iknacf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,j,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < ijnaec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,k,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < ijnbec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,k,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < ijnaeb | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < jknaec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,i,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < jknbec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,i,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < jknaeb | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,i,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < iknaec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,j,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < iknbec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,j,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); n = l3a_excits_copy(jdet,6);
                        ! compute < iknaeb | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,j,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/2,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < ijndbc | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,k,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < ijndac | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,k,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < ijndab | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < jkndbc | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,i,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < jkndac | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,i,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < jkndab | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,i,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < ikndbc | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,j,n,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < ikndac | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,j,n,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); n = l3a_excits_copy(jdet,6);
                        ! compute < ikndab | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,j,n,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < imkabf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,j,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < imkbcf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,j,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < imkacf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,j,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkabf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,i,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkbcf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,i,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkacf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,i,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < imjabf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,k,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < imjbcf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,k,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); m = l3a_excits_copy(jdet,5);
                        ! compute < imjacf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,k,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < imkaec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,j,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < imkbec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,j,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < imkaeb | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,j,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkaec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,i,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkbec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,i,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkaeb | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,i,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < imjaec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,k,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < imjbec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,k,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); m = l3a_excits_copy(jdet,5);
                        ! compute < imjaeb | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,k,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < imkdbc | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,j,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < imkdac | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,j,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < imkdab | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,j,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkdbc | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,i,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkdac | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,i,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < jmkdab | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,i,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < imjdbc | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,k,m,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < imjdac | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,k,m,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); m = l3a_excits_copy(jdet,5);
                        ! compute < imjdab | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,k,m,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,2,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkabf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,i,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkbcf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkacf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < likabf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,j,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < likbcf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < likacf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < lijabf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,k,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < lijbcf | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(f,k,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3a_excits_copy(jdet,3); l = l3a_excits_copy(jdet,4);
                        ! compute < lijacf | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(f,k,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/1,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkaec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkbec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkaeb | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,i,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < likaec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < likbec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < likaeb | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,j,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < lijaec | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(e,k,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < lijbec | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,k,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3a_excits_copy(jdet,2); l = l3a_excits_copy(jdet,4);
                        ! compute < lijaeb | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(e,k,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(l3a_excits_copy, l3a_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l3a_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2a_voov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkdbc | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkdac | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < ljkdab | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,i,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < likdbc | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < likdac | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < likdab | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,j,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < lijdbc | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,k,l,a)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < lijdac | h2a(voov) | ijkabc >
                        hmatel = -h2a_voov(d,k,l,b)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3a_excits_copy(jdet,1); l = l3a_excits_copy(jdet,4);
                        ! compute < lijdab | h2a(voov) | ijkabc >
                        hmatel = h2a_voov(d,k,l,c)
                        resid(idet) = resid(idet) + hmatel * l3a_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                 
                  !!!! diagram 6: A(i/jk)A(a/bc) h2b(ieam) * l3b(bcejkm)
                  ! allocate and copy over l3b arrays
                  allocate(amps_buff(n3aab),excits_buff(n3aab,6))
                  amps_buff(:) = l3b_amps(:)
                  excits_buff(:,:) = l3b_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nua*(nua-1)/2*noa*(noa-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijn~abf~ | h2b(ovvo) | ijkabc >
                        hmatel = h2b_ovvo(k,f,c,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < jkn~abf~ | h2b(ovvo) | ijkabc >
                        hmatel = h2b_ovvo(i,f,c,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ikn~abf~ | h2b(ovvo) | ijkabc >
                        hmatel = -h2b_ovvo(j,f,c,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijn~bcf~ | h2b(ovvo) | ijkabc >
                        hmatel = h2b_ovvo(k,f,a,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)(ac)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < jkn~bcf~ | h2b(ovvo) | ijkabc >
                        hmatel = h2b_ovvo(i,f,a,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (jk)(ac)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ikn~bcf~ | h2b(ovvo) | ijkabc >
                        hmatel = -h2b_ovvo(j,f,a,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijn~acf~ | h2b(ovvo) | ijkabc >
                        hmatel = -h2b_ovvo(k,f,b,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)(bc)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < jkn~acf~ | h2b(ovvo) | ijkabc >
                        hmatel = -h2b_ovvo(i,f,b,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (jk)(bc)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ikn~acf~ | h2b(ovvo) | ijkabc >
                        hmatel = h2b_ovvo(j,f,b,n)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate l3 buffer arrays
                  deallocate(amps_buff,excits_buff)
                  
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3a_excits_copy,&
                  !$omp l1a,l2a,&
                  !$omp H1A_ov,H2A_oovv,H2A_vovv,H2A_ooov,&
                  !$omp X2A_vovv,X2A_ooov,&
                  !$omp noa,nua,n3aaa),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! A(i/jk)A(a/bc) [l1a(ai) * h2a(jkbc) + h1a(ia) * l2a(bcjk)]
                      res =  l1a(a,i)*h2a_oovv(j,k,b,c) + h1a_ov(i,a)*l2a(b,c,j,k)& ! (1)
                            -l1a(a,j)*h2a_oovv(i,k,b,c) - h1a_ov(j,a)*l2a(b,c,i,k)& ! (ij)
                            -l1a(a,k)*h2a_oovv(j,i,b,c) - h1a_ov(k,a)*l2a(b,c,j,i)& ! (ik)
                            -l1a(b,i)*h2a_oovv(j,k,a,c) - h1a_ov(i,b)*l2a(a,c,j,k)& ! (ab)
                            +l1a(b,j)*h2a_oovv(i,k,a,c) + h1a_ov(j,b)*l2a(a,c,i,k)& ! (ij)(ab)
                            +l1a(b,k)*h2a_oovv(j,i,a,c) + h1a_ov(k,b)*l2a(a,c,j,i)& ! (ik)(ab)
                            -l1a(c,i)*h2a_oovv(j,k,b,a) - h1a_ov(i,c)*l2a(b,a,j,k)& ! (ac)
                            +l1a(c,j)*h2a_oovv(i,k,b,a) + h1a_ov(j,c)*l2a(b,a,i,k)& ! (ij)(ac)
                            +l1a(c,k)*h2a_oovv(j,i,b,a) + h1a_ov(k,c)*l2a(b,a,j,i)  ! (ik)(ac)
                      ! A(c/ab)A(j/ik) [-h2a(ikmc) * l2a(abmj) - h2a(mjab) * x2a(ikmc)]
                      do m = 1, noa
                         res = res&
                               - h2a_oovv(m,j,a,b)*x2a_ooov(i,k,m,c)& ! (1)
                               + h2a_oovv(m,i,a,b)*x2a_ooov(j,k,m,c)& ! (ij)
                               + h2a_oovv(m,k,a,b)*x2a_ooov(i,j,m,c)& ! (jk)
                               + h2a_oovv(m,j,c,b)*x2a_ooov(i,k,m,a)& ! (ac)
                               - h2a_oovv(m,i,c,b)*x2a_ooov(j,k,m,a)& ! (ij)(ac)
                               - h2a_oovv(m,k,c,b)*x2a_ooov(i,j,m,a)& ! (jk)(ac)
                               + h2a_oovv(m,j,a,c)*x2a_ooov(i,k,m,b)& ! (bc)
                               - h2a_oovv(m,i,a,c)*x2a_ooov(j,k,m,b)& ! (ij)(bc)
                               - h2a_oovv(m,k,a,c)*x2a_ooov(i,j,m,b)  ! (jk)(bc)
                         res = res&
                               - l2a(a,b,m,j)*h2a_ooov(i,k,m,c)& ! (1)
                               + l2a(a,b,m,i)*h2a_ooov(j,k,m,c)& ! (ij)
                               + l2a(a,b,m,k)*h2a_ooov(i,j,m,c)& ! (jk)
                               + l2a(c,b,m,j)*h2a_ooov(i,k,m,a)& ! (ac)
                               - l2a(c,b,m,i)*h2a_ooov(j,k,m,a)& ! (ij)(ac)
                               - l2a(c,b,m,k)*h2a_ooov(i,j,m,a)& ! (jk)(ac)
                               + l2a(a,c,m,j)*h2a_ooov(i,k,m,b)& ! (bc)
                               - l2a(a,c,m,i)*h2a_ooov(j,k,m,b)& ! (ij)(bc)
                               - l2a(a,c,m,k)*h2a_ooov(i,j,m,b)  ! (jk)(bc)
                      end do
                      ! A(b/ac)A(k/ij) [h2a_vovv(ekac)*l2a(ebij) + h2a(ijeb)*x2a(ekac)]
                      do e = 1, nua
                         res = res&
                               + h2a_oovv(i,j,e,b)*x2a_vovv(e,k,a,c)& ! (1)
                               - h2a_oovv(k,j,e,b)*x2a_vovv(e,i,a,c)& ! (ik)
                               - h2a_oovv(i,k,e,b)*x2a_vovv(e,j,a,c)& ! (jk)
                               - h2a_oovv(i,j,e,a)*x2a_vovv(e,k,b,c)& ! (ab)
                               + h2a_oovv(k,j,e,a)*x2a_vovv(e,i,b,c)& ! (ik)(ab)
                               + h2a_oovv(i,k,e,a)*x2a_vovv(e,j,b,c)& ! (jk)(ab)
                               - h2a_oovv(i,j,e,c)*x2a_vovv(e,k,a,b)& ! (bc)
                               + h2a_oovv(k,j,e,c)*x2a_vovv(e,i,a,b)& ! (ik)(bc)
                               + h2a_oovv(i,k,e,c)*x2a_vovv(e,j,a,b)  ! (jk)(bc)
                         res = res&
                               + l2a(e,b,i,j)*h2a_vovv(e,k,a,c)& ! (1)
                               - l2a(e,b,k,j)*h2a_vovv(e,i,a,c)& ! (ik)
                               - l2a(e,b,i,k)*h2a_vovv(e,j,a,c)& ! (jk)
                               - l2a(e,a,i,j)*h2a_vovv(e,k,b,c)& ! (ab)
                               + l2a(e,a,k,j)*h2a_vovv(e,i,b,c)& ! (ik)(ab)
                               + l2a(e,a,i,k)*h2a_vovv(e,j,b,c)& ! (jk)(ab)
                               - l2a(e,c,i,j)*h2a_vovv(e,k,a,b)& ! (bc)
                               + l2a(e,c,k,j)*h2a_vovv(e,i,a,b)& ! (ik)(bc)
                               + l2a(e,c,i,k)*h2a_vovv(e,j,a,b)  ! (jk)(bc)
                      end do
                      resid(idet) = resid(idet) + res
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!

                  ! deallocate copies of l3a amplitude and excitation arrays
                  deallocate(l3a_amps_copy,l3a_excits_copy)
              end subroutine build_leftamps3a_ijk

              subroutine build_leftamps3b_ijk(resid, i, j, k,&
                                              l1a, l1b, l2a, l2b,&
                                              l3a_amps, l3a_excits,&
                                              l3b_amps, l3b_excits,&
                                              l3c_amps, l3c_excits,&
                                              h1a_ov, h1a_oo, h1a_vv,&
                                              h1b_ov, h1b_oo, h1b_vv,&
                                              h2a_oooo, h2a_ooov, h2a_oovv,&
                                              h2a_voov, h2a_vovv, h2a_vvvv,&
                                              h2b_oooo, h2b_ooov, h2b_oovo, h2b_oovv,&
                                              h2b_voov, h2b_vovo, h2b_ovov, h2b_ovvo,&
                                              h2b_vovv, h2b_ovvv, h2b_vvvv,&
                                              h2c_voov,&
                                              x2a_ooov, x2a_vovv,&
                                              x2b_ooov, x2b_oovo, x2b_vovv, x2b_ovvv,&
                                              orbsym, sym_ijk, target_sym,&
                                              n3aaa, n3aab, n3abb,&
                                              noa, nua, nob, nub, norb)
                  ! Input dimension variables
                  integer, intent(in) :: noa, nua, nob, nub
                  integer, intent(in) :: n3aaa, n3aab, n3abb
                  integer, intent(in) :: norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  ! occupied block indices
                  integer :: i, j, k
                  ! Input L arrays
                  real(kind=8), intent(in) :: l1a(nua,noa), l1b(nub,nob)
                  real(kind=8), intent(in) :: l2a(nua,nua,noa,noa), l2b(nua,nub,noa,nob)
                  integer, intent(in) :: l3a_excits(n3aaa,6), l3b_excits(n3aab,6), l3c_excits(n3abb,6)
                  real(kind=8), intent(in) :: l3a_amps(n3aaa), l3b_amps(n3aab), l3c_amps(n3abb)
                  ! Input H and X arrays
                  real(kind=8), intent(in) :: h1a_ov(noa,nua), h1b_ov(nob,nub)
                  real(kind=8), intent(in) :: h1a_oo(noa,noa), h1b_oo(nob,nob)
                  real(kind=8), intent(in) :: h1a_vv(nua,nua), h1b_vv(nub,nub)
                  real(kind=8), intent(in) :: h2a_oooo(noa,noa,noa,noa), h2b_oooo(noa,nob,noa,nob)
                  real(kind=8), intent(in) :: h2a_ooov(noa,noa,noa,nua), h2b_ooov(noa,nob,noa,nub), h2b_oovo(noa,nob,nua,nob)
                  real(kind=8), intent(in) :: h2a_oovv(noa,noa,nua,nua), h2b_oovv(noa,nob,nua,nub)
                  real(kind=8), intent(in) :: h2a_voov(nua,noa,noa,nua)
                  real(kind=8), intent(in) :: h2a_vovv(nua,noa,nua,nua), h2b_vovv(nua,nob,nua,nub), h2b_ovvv(noa,nub,nua,nub)
                  real(kind=8), intent(in) :: h2a_vvvv(nua,nua,nua,nua), h2b_vvvv(nua,nub,nua,nub)
                  real(kind=8), intent(in) :: h2b_voov(nua,nob,noa,nub), h2b_vovo(nua,nob,nua,nob), h2b_ovov(noa,nub,noa,nub), h2b_ovvo(noa,nub,nua,nob)
                  real(kind=8), intent(in) :: x2a_ooov(noa,noa,noa,nua), x2b_ooov(noa,nob,noa,nub), x2b_oovo(noa,nob,nua,nob)
                  real(kind=8), intent(in) :: x2a_vovv(nua,noa,nua,nua), x2b_vovv(nua,nob,nua,nub), x2b_ovvv(noa,nub,nua,nub)
                  real(kind=8), intent(in) :: h2c_voov(nub,nob,nob,nub)
                  ! Output and Inout variables
                  real(kind=8), intent(out) :: resid(nua,nua,nub)
                  ! Local variables
                  integer, allocatable :: excits_buff(:,:), l3b_excits_copy(:,:)
                  real(kind=8), allocatable :: amps_buff(:), l3b_amps_copy(:)
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)
                  real(kind=8) :: l_amp, hmatel, hmatel1, res
                  integer :: a, b, c, d, ii, jj, kk, l, m, n, e, f, jdet
                  integer :: idx, nloc
                  integer :: sym
                  ! Q space array
                  logical(kind=1) :: qspace(nua,nua,nub)

                  ! zero residual array
                  resid = 0.0d0

                  ! copy over l3b_amps_copy and l3b_excits_copy
                  allocate(l3b_amps_copy(n3aab),l3b_excits_copy(n3aab,6))
                  l3b_amps_copy(:) = l3b_amps(:)
                  l3b_excits_copy(:,:) = l3b_excits(:,:)

                  ! reorder l3b into (i,j,k) order
                  nloc = noa*(noa-1)/2*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(noa,noa,nob))
                  call get_index_table3(idx_table3, (/1,noa-1/), (/-1,noa/), (/1,nob/), noa, noa, nob)
                  call sort3(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table3, (/4,5,6/), noa, noa, nob, nloc, n3aab)
                  ! Construct Q space for block (i,j,k)
                  qspace = .true.
                  idx = idx_table3(i,j,k)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = l3b_excits_copy(jdet,1); b = l3b_excits_copy(jdet,2); c = l3b_excits_copy(jdet,3);
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+noa))
                        sym = ieor(sym,orbsym(b+noa))
                        sym = ieor(sym,orbsym(c+nob))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                        qspace(a,b,c) = .false.
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)
                  
                  !if (n3aab/=0) then
                  !!!! diagram 1: -A(ij) h1a(im)*l3b(abcmjk)
                  !!!! diagram 5: A(ij) 1/2 h2a(ijmn)*l3b(abcmnk)
                  !!! SB: (1,2,3,6) LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nua*(nua-1)/2*nub*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,nub,noa))
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,nub/), (/1,nob/), nua, nua, nub, noa)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,2,3,6/), nua, nua, nub, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2A_oooo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,c,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3b_excits_copy(jdet,4); m = l3b_excits_copy(jdet,5);
                        ! compute < lmk~abc~ | h2a(oooo) | ijk~abc~ >
                        hmatel = h2a_oooo(i,j,l,m)
                        ! compute < lmk~abc~ | h1a(oo) | ijk~abc~ > = -A(ij)A(lm) h1a_oo(i,l) * delta(j,m)
                        if (m==j) hmatel = hmatel - h1a_oo(i,l)
                        if (m==i) hmatel = hmatel + h1a_oo(j,l)
                        if (l==j) hmatel = hmatel + h1a_oo(i,m)
                        if (l==i) hmatel = hmatel - h1a_oo(j,m)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                 
                  !!!! diagram 2: A(ab) h1a(ea)*l3b(ebcmjk)
                  !!!! diagram 6: A(ab) 1/2 h2a(efab)*l3b(ebcmjk)
                  !!! SB: (4,5,6,3) LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nub*noa*(noa-1)/2*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,nob,nub))
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), (/1,nub/), noa, noa, nob, nub)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/4,5,6,3/), noa, noa, nob, nub, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2A_vvvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     !idx = idx_table(c,i,j,k)
                     idx = idx_table(i,j,k,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3b_excits_copy(jdet,1); e = l3b_excits_copy(jdet,2);
                        ! compute < ijk~dec~ | h2a(vvvv) | ijk~abc~ >
                        hmatel = h2a_vvvv(d,e,a,b)
                        ! compute < ijk~dec~ | h1a(vv) | ijk~abc~ > = A(ab)A(de) h1a_vv(d,a)*delta(e,b)
                        if (b==e) hmatel = hmatel + h1a_vv(d,a)
                        if (a==e) hmatel = hmatel - h1a_vv(d,b)
                        if (b==d) hmatel = hmatel - h1a_vv(e,a)
                        if (a==d) hmatel = hmatel + h1a_vv(e,b)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                 
                  !!!! diagram 3: -h1b(km)*l3b(abcijm)
                  !!!! diagram 7: A(ij) h2b(jkmn)*l3b(abcimn)
                  !!! SB: (1,2,3,4) LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nua*(nua-1)/2*nub*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,nub,noa))
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,nub/), (/1,noa-1/), nua, nua, nub, noa)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,2,3,4/), nua, nua, nub, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,i)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = l3b_excits_copy(jdet,5); n = l3b_excits_copy(jdet,6);
                        ! compute < imn~abc~ | h2b(oooo) | ijk~abc~ >
                        hmatel = h2b_oooo(j,k,m,n)
                        ! compute < imn~abc~ | h1b(oo) | ijk~abc~ >
                        if (m==j) hmatel = hmatel - h1b_oo(k,n)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = l3b_excits_copy(jdet,5); n = l3b_excits_copy(jdet,6);
                           ! compute < jmn~abc~ | h2b(oooo) | ijk~abc~ >
                           hmatel = -h2b_oooo(i,k,m,n)
                           ! compute < jmn~abc~ | h1b(oo) | ijk~abc~ >
                           if (m==i) hmatel = hmatel + h1b_oo(k,n)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,3,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,nub/), (/2,noa/), nua, nua, nub, noa)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,2,3,5/), nua, nua, nub, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3b_excits_copy(jdet,4); n = l3b_excits_copy(jdet,6);
                        ! compute < ljn~abc~ | h2b(oooo) | ijk~abc~ >
                        hmatel = h2b_oooo(i,k,l,n)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3b_excits_copy(jdet,4); n = l3b_excits_copy(jdet,6);
                           ! compute < lin~abc~ | h2b(oooo) | ijk~abc~ >
                           hmatel = -h2b_oooo(j,k,l,n)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECITON !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                 
                  !!!! diagram 5: h1b(ec)*l3b(abeijm)
                  !!!! diagram 8: A(ab) h2b(efbc)*l3b(aefijk)
                  ! allocate new sorting arrays
                  nloc = nua*noa*(noa-1)/2*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,nob,nua))
                  !!! SB: (4,5,6,1) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), (/1,nua-1/), noa, noa, nob, nua)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/4,5,6,1/), noa, noa, nob, nua, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(i,j,k,a)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         e = l3b_excits_copy(jdet,2); f = l3b_excits_copy(jdet,3);
                         ! compute < ijk~aef~ | h2b(vvvv) | ijk~abc~ >
                         hmatel = h2b_vvvv(e,f,b,c)
                         if (b==e) hmatel = hmatel + h1b_vv(f,c)
                         resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                      end do
                      ! (ab)
                      idx = idx_table(i,j,k,b)
                      if (idx/=0) then ! protect against case where b = nua because a = 1, nua-1
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = l3b_excits_copy(jdet,2); f = l3b_excits_copy(jdet,3);
                            ! compute < ijk~bef~ | h2b(vvvv) | ijk~abc~ >
                            hmatel = -h2b_vvvv(e,f,a,c)
                            if (a==e) hmatel = hmatel - h1b_vv(f,c)
                            resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (4,5,6,2) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nob/), (/2,nua/), noa, noa, nob, nua)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/4,5,6,2/), noa, noa, nob, nua, nloc, n3aab)
                  !!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(i,j,k,b)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = l3b_excits_copy(jdet,1); f = l3b_excits_copy(jdet,3);
                         ! compute < ijk~dbf~ | h2b(vvvv) | ijk~abc~ >
                         hmatel = h2b_vvvv(d,f,a,c)
                         resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                      end do
                      idx = idx_table(i,j,k,a)
                      if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = l3b_excits_copy(jdet,1); f = l3b_excits_copy(jdet,3);
                            ! compute < ijk~daf~ | h2b(vvvv) | ijk~abc~ >
                            hmatel = -h2b_vvvv(d,f,b,c)
                            resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do; ! end loop over idet
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                 
                  !!!! diagram 9: A(ij)A(ab) h2a(eima)*l3b(ebcmjk)
                  ! allocate new sorting arrays
                  nloc = nua*nub*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,4);
                        ! compute < ijk~abc~ | h2a(voov) | ljk~dbc~ >
                        hmatel = h2a_voov(d,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | ljk~dac~ >
                           hmatel = -h2a_voov(d,i,l,b)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then ! protect against case where i = 1 because j = 2, noa
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~dbc~ >
                           hmatel = -h2a_voov(d,j,l,a)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then ! protect against case where a = 1 because b = 2, nua and i = 1 because j = 2, noa
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~dac~ >
                           hmatel = h2a_voov(d,j,l,b)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,i,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,5);
                        ! compute < ijk~abc~ | h2a(voov) | ilk~dbc~ >
                        hmatel = h2a_voov(d,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then ! protect against where j = noa because i = 1, noa-1
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~dbc~ >
                           hmatel = -h2a_voov(d,i,l,a)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | ilk~dac~ >
                           hmatel = -h2a_voov(d,j,l,b)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then ! protect against case where j = noa because i = 1, noa-1 and where a = 1 because b = 2, nua
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); l = l3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~dac~ >
                           hmatel = h2a_voov(d,i,l,b)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,5);
                        ! compute < ijk~abc~ | h2a(voov) | ilk~adc~  >
                        hmatel = h2a_voov(d,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~adc~  >
                           hmatel = -h2a_voov(d,i,l,b)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | ilk~bdc~  >
                           hmatel = -h2a_voov(d,j,l,a)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,5);
                           ! compute < ijk~abc~ | h2a(voov) | jlk~bdc~  >
                           hmatel = h2a_voov(d,i,l,a)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,j,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,4);
                        ! compute < ijk~abc~ | h2a(voov) | ljk~adc~  >
                        hmatel = h2a_voov(d,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~adc~  >
                           hmatel = -h2a_voov(d,j,l,b)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | ljk~bdc~  >
                           hmatel = -h2a_voov(d,i,l,a)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                     ! (ij)(ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,2); l = l3b_excits_copy(jdet,4);
                           ! compute < ijk~abc~ | h2a(voov) | lik~abc~  >
                           hmatel = h2a_voov(d,j,l,a)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                 
                  !!!! diagram 10: h2c(ekmc)*l3b(abeijm)
                  ! allocate sorting arrays
                  nloc = nua*(nua-1)/2*noa*(noa-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,&
                  !$omp n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(a,b,i,j)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         f = l3b_excits_copy(jdet,3); n = l3b_excits_copy(jdet,6);
                         ! compute < ijn~abf~ | h2c(voov) | ijk~abc~ >
                         hmatel = h2c_voov(f,k,n,c)
                         resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                      end do
                  end do; end do; end do; ! end loop over idet
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 11: -A(ij) h2b(iemc)*l3b(abemjk)
                  ! allocate sorting arrays
                  nloc = nua*(nua-1)/2*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,nob))
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/1,noa-1/), (/1,nob/), nua, nua, noa, nob)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nua, nua, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3b_excits_copy(jdet,3); m = l3b_excits_copy(jdet,5);
                        ! compute < imk~abf~ | h2b(ovov) | ijk~abc~ >
                        hmatel = -h2b_ovov(j,f,m,c)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = l3b_excits_copy(jdet,3); m = l3b_excits_copy(jdet,5);
                           ! compute < jmk~abf~ | h2b(ovov) | ijk~abc~ >
                           hmatel = h2b_ovov(i,f,m,c)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/-1,nua/), (/2,noa/), (/1,nob/), nua, nua, noa, nob)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/1,2,5,6/), nua, nua, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,j,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3b_excits_copy(jdet,3); l = l3b_excits_copy(jdet,4);
                        ! compute < ljk~abf~ | h2b(ovov) | ijk~abc~ >
                        hmatel = -h2b_ovov(i,f,l,c)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = l3b_excits_copy(jdet,3); l = l3b_excits_copy(jdet,4);
                           ! compute < lik~abf~ | h2b(ovov) | ijk~abc~ >
                           hmatel = h2b_ovov(j,f,l,c)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 12: -A(ab) h2b(ekam)*l3b(ebcijm)
                  ! allocate sorting arrays
                  nloc = nua*nub*noa*(noa-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(noa,noa,nua,nub))
                  !!! SB: (4,5,2,3) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/2,nua/), (/1,nub/), noa, noa, nua, nub)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/4,5,2,3/), noa, noa, nua, nub, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,b,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3b_excits_copy(jdet,1); n = l3b_excits_copy(jdet,6);
                        ! compute < ijn~dbc~ | h2b(vovo) | ijk~abc~ >
                        hmatel = -h2b_vovo(d,k,a,n)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,a,c)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           d = l3b_excits_copy(jdet,1); n = l3b_excits_copy(jdet,6);
                           ! compute < ijn~dac~ | h2b(vovo) | ijk~abc~ >
                           hmatel = h2b_vovo(d,k,b,n)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (4,5,1,3) LOOP !!!
                  call get_index_table(idx_table, (/1,noa-1/), (/-1,noa/), (/1,nua-1/), (/1,nub/), noa, noa, nua, nub)
                  call sort4(l3b_excits_copy, l3b_amps_copy, loc_arr, idx_table, (/4,5,1,3/), noa, noa, nua, nub, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l3b_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,a,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3b_excits_copy(jdet,2); n = l3b_excits_copy(jdet,6);
                        ! compute < ijn~aec~ | h2b(vovo) | ijk~abc~ >
                        hmatel = -h2b_vovo(e,k,b,n)
                        resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,b,c)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = l3b_excits_copy(jdet,2); n = l3b_excits_copy(jdet,6);
                           ! compute < ijn~bec~ | h2b(vovo) | ijk~abc~ >
                           hmatel = h2b_vovo(e,k,a,n)
                           resid(idet) = resid(idet) + hmatel * l3b_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  !end if
                 
                  !!!! diagram 13: h2b(ekmc)*l3a(abeijm) !!!!
                  !if (n3aaa/=0) then
                  ! allocate and initialize the copy of l3a
                  allocate(amps_buff(n3aaa))
                  allocate(excits_buff(n3aaa,6))
                  amps_buff(:) = l3a_amps(:)
                  excits_buff(:,:) = l3a_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = (nua-1)*(nua-2)/2*(noa-1)*(noa-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nua,noa,noa))
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j)
                     if (idx==0) cycle 
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                        ! compute < ijnabf | h2b(voov) | ijk~abc~ >
                        hmatel = h2b_voov(f,k,n,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                        ! compute < ijnaeb | h2b(voov) | ijk~abc~ >
                        hmatel = -h2b_voov(e,k,n,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-1,noa-1/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,5/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); n = excits_buff(jdet,6);
                        ! compute < ijndab | h2b(voov) | ijk~abc~ >
                        hmatel = h2b_voov(d,k,n,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                        ! compute < imjabf | h2b(voov) | ijk~abc~ >
                        hmatel = -h2b_voov(f,k,m,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                        ! compute < imjaeb | h2b(voov) | ijk~abc~ >
                        hmatel = h2b_voov(e,k,m,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/1,noa-2/), (/-2,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                        ! compute < imjdab | h2b(voov) | ijk~abc~ >
                        hmatel = -h2b_voov(d,k,m,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-1,nua-1/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = excits_buff(jdet,3); l = excits_buff(jdet,4);
                        ! compute < lijabf | h2b(voov) | ijk~abc~ >
                        hmatel = h2b_voov(f,k,l,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-2/), (/-2,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                        ! compute < lijaeb | h2b(voov) | ijk~abc~ >
                        hmatel = -h2b_voov(e,k,l,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do; 
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua-1/), (/-1,nua/), (/2,noa-1/), (/-1,noa/), nua, nua, noa, noa)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nua, nua, noa, noa, nloc, n3aaa)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(a,b,i,j) 
                     if (idx==0) cycle
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < lijdab | h2b(voov) | ijk~abc~ >
                        hmatel = h2b_voov(d,k,l,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate l3 buffer arrays
                  deallocate(amps_buff,excits_buff)
                 
                  !!!! diagram 14: A(ab)A(ij) h2b(jebm)*l3c(aecimk)
                  !if (n3abb/=0) then
                  ! allocate and initialize the copy of l3c
                  allocate(amps_buff(n3abb))
                  allocate(excits_buff(n3abb,6))
                  amps_buff(:) = l3c_amps(:)
                  excits_buff(:,:) = l3c_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nua*nub*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < im~k~ae~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(j,e,b,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < im~k~be~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(j,e,a,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < jm~k~ae~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(i,e,b,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                           ! compute < jm~k~be~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(i,e,a,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < im~k~ac~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(j,f,b,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < im~k~bc~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(j,f,a,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < jm~k~ac~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(i,f,b,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                           ! compute < jm~k~bc~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(i,f,a,m)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < ik~n~ae~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(j,e,b,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < ik~n~be~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(j,e,a,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < jk~n~ae~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(i,e,b,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                           ! compute < jk~n~be~c~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(i,e,a,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < ik~n~ac~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(j,f,b,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < ik~n~bc~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(j,f,a,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < jk~n~ac~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = -h2b_ovvo(i,f,b,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                           ! compute < jk~n~bc~f~ | h2b(ovvo) | ijk~abc~ >
                           hmatel = h2b_ovvo(i,f,a,n)
                           resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate l3 buffer arrays
                  deallocate(amps_buff,excits_buff)
                  
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3b_excits_copy,&
                  !$omp l1a,l1b,l2a,l2b,&
                  !$omp H1A_ov,H1B_ov,&
                  !$omp H2A_oovv,H2B_oovv,&
                  !$omp H2A_ooov,H2A_vovv,&
                  !$omp H2B_ooov,H2B_oovo,H2B_vovv,H2B_ovvv,&
                  !$omp X2A_ooov,X2A_vovv,&
                  !$omp X2B_ooov,X2B_oovo,X2B_vovv,X2B_ovvv,&
                  !$omp noa,nua,nob,nub,n3aab),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! A(ab)A(ij) [l1a(ai)*h2b(jkbc) + h1a(ia)*l2a(bcjk)
                      res =  l1a(a,i)*h2b_oovv(j,k,b,c) + h1a_ov(i,a)*l2b(b,c,j,k)& ! (1)
                            -l1a(a,j)*h2b_oovv(i,k,b,c) - h1a_ov(j,a)*l2b(b,c,i,k)& ! (ij)
                            -l1a(b,i)*h2b_oovv(j,k,a,c) - h1a_ov(i,b)*l2b(a,c,j,k)& ! (ab)
                            +l1a(b,j)*h2b_oovv(i,k,a,c) + h1a_ov(j,b)*l2b(a,c,i,k)  ! (ij)(ab)
                      ! l1b(ck)*h2a(ijab) + h1b(kc)*l2a(abij)
                      res = res + l1b(c,k)*h2a_oovv(i,j,a,b) + h1b_ov(k,c)*l2a(a,b,i,j)
                      ! -A(ij) h2b(jkmc)*l2a(abim)
                      ! -A(ab) h2a(jima)*l2b(bcmk)
                      ! -A(ij) x2b(jkmc)*h2a(imab)
                      ! -A(ab) x2a(jima)*h2b(mkbc)
                      do m = 1, noa
                         res = res&
                               -h2b_ooov(j,k,m,c)*l2a(a,b,i,m) + h2b_ooov(i,k,m,c)*l2a(a,b,j,m)&
                               -h2a_ooov(j,i,m,a)*l2b(b,c,m,k) + h2a_ooov(j,i,m,b)*l2b(a,c,m,k)&
                               -x2b_ooov(j,k,m,c)*h2a_oovv(i,m,a,b) + x2b_ooov(i,k,m,c)*h2a_oovv(j,m,a,b)&
                               -x2a_ooov(j,i,m,a)*h2b_oovv(m,k,b,c) + x2a_ooov(j,i,m,b)*h2b_oovv(m,k,a,c)
                      end do
                      ! -A(ij)A(ab) h2b(ikam)*l2b(bcjm)
                      ! -A(ij)A(ab) x2b(ikam)*h2b(jmbc)
                      do m = 1, nob
                         res = res&
                               -h2b_oovo(i,k,a,m)*l2b(b,c,j,m) - x2b_oovo(i,k,a,m)*h2b_oovv(j,m,b,c)& ! (1)
                               +h2b_oovo(j,k,a,m)*l2b(b,c,i,m) + x2b_oovo(j,k,a,m)*h2b_oovv(i,m,b,c)& ! (ij)
                               +h2b_oovo(i,k,b,m)*l2b(a,c,j,m) + x2b_oovo(i,k,b,m)*h2b_oovv(j,m,a,c)& ! (ab)
                               -h2b_oovo(j,k,b,m)*l2b(a,c,i,m) - x2b_oovo(j,k,b,m)*h2b_oovv(i,m,a,c)  ! (ij)(ab)
                      end do
                      ! A(ab) h2b(ekbc)*l2a(aeij)
                      ! A(ij) h2a(eiba)*l2b(ecjk)
                      ! A(ab) x2b(ekbc)*h2a(ijae)
                      ! A(ij) x2a(eiba)*h2b(jkec)
                      do e = 1, nua
                         res = res&
                               +h2b_vovv(e,k,b,c)*l2a(a,e,i,j) - h2b_vovv(e,k,a,c)*l2a(b,e,i,j)&
                               +h2a_vovv(e,i,b,a)*l2b(e,c,j,k) - h2a_vovv(e,j,b,a)*l2b(e,c,i,k)&
                               +x2b_vovv(e,k,b,c)*h2a_oovv(i,j,a,e) - x2b_vovv(e,k,a,c)*h2a_oovv(i,j,b,e)&
                               +x2a_vovv(e,i,b,a)*h2b_oovv(j,k,e,c) - x2a_vovv(e,j,b,a)*h2b_oovv(i,k,e,c)
                      end do
                      ! A(ij)A(ab) h2b(ieac)*l2b(bejk)
                      ! A(ij)A(ab) x2b(ieac)*h2b(jkbe)
                      do e = 1, nub
                         res = res&
                               +h2b_ovvv(i,e,a,c)*l2b(b,e,j,k) + x2b_ovvv(i,e,a,c)*h2b_oovv(j,k,b,e)& ! (1)
                               -h2b_ovvv(j,e,a,c)*l2b(b,e,i,k) - x2b_ovvv(j,e,a,c)*h2b_oovv(i,k,b,e)& ! (ij)
                               -h2b_ovvv(i,e,b,c)*l2b(a,e,j,k) - x2b_ovvv(i,e,b,c)*h2b_oovv(j,k,a,e)& ! (ab)
                               +h2b_ovvv(j,e,b,c)*l2b(a,e,i,k) + x2b_ovvv(j,e,b,c)*h2b_oovv(i,k,a,e)  ! (ij)(ab)
                      end do
                      resid(idet) = resid(idet) + res
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!                 
                 
                  ! deallocate copies of l3b amplitude and excitation arrays
                  deallocate(l3b_amps_copy,l3b_excits_copy)
        end subroutine build_leftamps3b_ijk

        subroutine build_leftamps3c_ijk(resid, i, j, k,&
                              l1a, l1b, l2b, l2c,&
                              l3b_amps, l3b_excits,&
                              l3c_amps, l3c_excits,&
                              l3d_amps, l3d_excits,&
                              h1a_ov, h1a_oo, h1a_vv,&
                              h1b_ov, h1b_oo, h1b_vv,&
                              h2a_voov,&
                              h2b_oooo, h2b_ooov, h2b_oovo, h2b_oovv,&
                              h2b_voov, h2b_vovo, h2b_ovov, h2b_ovvo,&
                              h2b_vovv, h2b_ovvv, h2b_vvvv,&
                              h2c_oooo, h2c_ooov, h2c_oovv,&
                              h2c_voov, h2c_vovv, h2c_vvvv,&
                              x2b_ooov, x2b_oovo, x2b_vovv, x2b_ovvv,&
                              x2c_ooov, x2c_vovv,&
                              orbsym, sym_ijk, target_sym,&
                              n3aab, n3abb, n3bbb,&
                              noa, nua, nob, nub, norb)
                  ! Input dimension variables
                  integer, intent(in) :: noa, nua, nob, nub
                  integer, intent(in) :: n3aab, n3abb, n3bbb
                  integer, intent(in) :: norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  ! occupied orbital block indices
                  integer, intent(in) :: i, j, k
                  ! Input L arrays
                  real(kind=8), intent(in) :: l1a(nua,noa), l1b(nub,nob)
                  real(kind=8), intent(in) :: l2c(nub,nub,nob,nob), l2b(nua,nub,noa,nob)
                  integer, intent(in) :: l3d_excits(n3bbb,6), l3c_excits(n3abb,6), l3b_excits(n3aab,6)
                  real(kind=8), intent(in) :: l3d_amps(n3bbb), l3c_amps(n3abb), l3b_amps(n3aab)
                  ! Input H and X arrays
                  real(kind=8), intent(in) :: h1a_ov(noa,nua), h1b_ov(nob,nub)
                  real(kind=8), intent(in) :: h1a_oo(noa,noa), h1b_oo(nob,nob)
                  real(kind=8), intent(in) :: h1a_vv(nua,nua), h1b_vv(nub,nub)
                  real(kind=8), intent(in) :: h2c_oooo(nob,nob,nob,nob), h2b_oooo(noa,nob,noa,nob)
                  real(kind=8), intent(in) :: h2c_ooov(nob,nob,nob,nub), h2b_ooov(noa,nob,noa,nub), h2b_oovo(noa,nob,nua,nob)
                  real(kind=8), intent(in) :: h2c_oovv(nob,nob,nub,nub), h2b_oovv(noa,nob,nua,nub)
                  real(kind=8), intent(in) :: h2c_voov(nub,nob,nob,nub)
                  real(kind=8), intent(in) :: h2c_vovv(nub,nob,nub,nub), h2b_vovv(nua,nob,nua,nub), h2b_ovvv(noa,nub,nua,nub)
                  real(kind=8), intent(in) :: h2c_vvvv(nub,nub,nub,nub), h2b_vvvv(nua,nub,nua,nub)
                  real(kind=8), intent(in) :: h2b_voov(nua,nob,noa,nub), h2b_vovo(nua,nob,nua,nob), h2b_ovov(noa,nub,noa,nub), h2b_ovvo(noa,nub,nua,nob)
                  real(kind=8), intent(in) :: x2c_ooov(nob,nob,nob,nub), x2b_ooov(noa,nob,noa,nub), x2b_oovo(noa,nob,nua,nob)
                  real(kind=8), intent(in) :: x2c_vovv(nub,nob,nub,nub), x2b_vovv(nua,nob,nua,nub), x2b_ovvv(noa,nub,nua,nub)
                  real(kind=8), intent(in) :: h2a_voov(nua,noa,noa,nua)
                  ! Output and Inout variables
                  real(kind=8), intent(out) :: resid(nua,nub,nub)
                  ! Local variables
                  integer, allocatable :: excits_buff(:,:), l3c_excits_copy(:,:)
                  real(kind=8), allocatable :: amps_buff(:), l3c_amps_copy(:)
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)
                  real(kind=8) :: l_amp, hmatel, hmatel1, res
                  integer :: a, b, c, d, ii, jj, kk, l, m, n, e, f, idet, jdet
                  integer :: idx, nloc
                  integer :: sym
                  ! Q space array
                  logical(kind=1) :: qspace(nua,nub,nub)

                  ! copy over l3c_amps_copy and l3c_excits_copy
                  allocate(l3c_amps_copy(n3abb),l3c_excits_copy(n3abb,6))
                  l3c_amps_copy(:) = l3c_amps(:)
                  l3c_excits_copy(:,:) = l3c_excits(:,:)

                  ! reorder l3c into (i,j,k) order
                  nloc = nob*(nob-1)/2*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(nob,nob,noa))
                  call get_index_table3(idx_table3, (/1,nob-1/), (/-1,nob/), (/1,noa/), nob, nob, noa)
                  call sort3(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table3, (/5,6,4/), nob, nob, noa, nloc, n3abb)
                  ! Construct Q space for block (j,k,i)
                  qspace = .true.
                  idx = idx_table3(j,k,i)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = l3c_excits_copy(jdet,1); b = l3c_excits_copy(jdet,2); c = l3c_excits_copy(jdet,3);
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+noa))
                        sym = ieor(sym,orbsym(b+nob))
                        sym = ieor(sym,orbsym(c+nob))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                        qspace(a,b,c) = .false.
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)

                  ! Zero the residual container
                  resid = 0.0d0
                  
                  !if (n3abb/=0) then
                  !!!! diagram 1: -A(jk) h1b(km)*l3c(abcijm)
                  !!!! diagram 5: A(jk) 1/2 h2c(jkmn)*l3c(abcimn)
                  !!! SB: (2,3,1,4) LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nub*(nub-1)/2*nua*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nua,noa))
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nua/), (/1,noa/), nub, nub, nua, noa)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/2,3,1,4/), nub, nub, nua, noa, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(b,c,a,i)
                     ! (1)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = l3c_excits_copy(jdet,5); n = l3c_excits_copy(jdet,6);
                        ! compute < im~n~ab~c~ | h2c(oooo) | ij~k~ab~c~ >
                        hmatel = h2c_oooo(j,k,m,n)
                        ! compute < im~n~ab~c~ | h1b(oo) | ij~k~ab~c~ > = -A(jk)A(mn) h1b_oo(j,m) * delta(k,n)
                        if (n==k) hmatel = hmatel - h1b_oo(j,m) ! (1)
                        if (n==j) hmatel = hmatel + h1b_oo(k,m) ! (jk)
                        if (m==k) hmatel = hmatel + h1b_oo(j,n) ! (mn)
                        if (m==j) hmatel = hmatel - h1b_oo(k,n) ! (jk)(mn)
                        resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
           
                  !!!! diagram 2: A(bc) h1b(ec)*l3c(abeijk)
                  !!!! diagram 6: A(bc) 1/2 h2c(efbc)*l3c(aefijk)
                  !!! SB: (5,6,4,1) LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nua*nob*(nob-1)/2*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,noa,nua))
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), (/1,nua/), nob, nob, noa, nua)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/5,6,4,1/), nob, nob, noa, nua, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     idx = idx_table(j,k,i,a)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3c_excits_copy(jdet,2); f = l3c_excits_copy(jdet,3);
                        ! compute < ij~k~ab~c~ | h2c(vvvv) | ij~k~ae~f~ >
                        hmatel = h2c_vvvv(e,f,b,c)
                        ! compute < ij~k~ab~c~ | h2c(vvvv) | ij~k~ae~f~ > = A(bc)A(ef) h1b_vv(b,e) * delta(c,f)
                        if (c==f) hmatel = hmatel + h1b_vv(e,b) ! (1)
                        if (b==f) hmatel = hmatel - h1b_vv(e,c) ! (bc)
                        if (c==e) hmatel = hmatel - h1b_vv(f,b) ! (ef)
                        if (b==e) hmatel = hmatel + h1b_vv(f,c) ! (bc)(ef)
                        resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                     end do
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)    
                  
                  !!!! diagram 3: -h1a(im)*l3c(abcmjk)
                  !!!! diagram 7: A(jk) h2b(ijmn)*l3c(abcmnk)
                  !!! SB: (2,3,1,6) LOOP !!!
                  ! allocate new sorting arrays
                  nloc = nub*(nub-1)/2*nua*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nua,nob))
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nua/), (/2,nob/), nub, nub, nua, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/2,3,1,6/), nub, nub, nua, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_oo,H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,a,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3c_excits_copy(jdet,4); m = l3c_excits_copy(jdet,5);
                        ! compute < ij~k~ab~c~ | h2b(oooo) | lm~k~ab~c~ >
                        hmatel = h2b_oooo(i,j,l,m)
                        ! compute < ij~k~ab~c~ | h1a(oo) | lm~k~ab~c~ >
                        if (m==j) hmatel = hmatel - h1a_oo(i,l)
                        resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                     end do
                     ! (jk)
                     idx = idx_table(b,c,a,j)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            l = l3c_excits_copy(jdet,4); m = l3c_excits_copy(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(oooo) | lm~j~ab~c~ >
                            hmatel = -h2b_oooo(i,k,l,m)
                            ! compute < ij~k~ab~c~ | h1a(oo) | lm~j~ab~c~ >
                            if (m==k) hmatel = hmatel + h1a_oo(i,l)
                            resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                         end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,1,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nua/), (/1,nob-1/), nub, nub, nua, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/2,3,1,5/), nub, nub, nua, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_oooo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(b,c,a,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3c_excits_copy(jdet,4); n = l3c_excits_copy(jdet,6);
                        ! compute < ij~k~ab~c~ | h2b(oooo) | lj~n~ab~c~ >
                        hmatel = h2b_oooo(i,k,l,n)
                        resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                     end do
                     ! (jk)
                     idx = idx_table(b,c,a,k)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            l = l3c_excits_copy(jdet,4); n = l3c_excits_copy(jdet,6);
                            ! compute < ij~k~ab~c~ | h2b(oooo) | lk~n~ab~c~ >
                            hmatel = -h2b_oooo(i,j,l,n)
                            resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                         end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECITON !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 5: h1a(ea)*l3c(ebcijk)
                  !!!! diagram 8: A(bc) h2b(efab)*l3c(efcijk)
                  ! allocate new sorting arrays
                  nloc = nub*nob*(nob-1)/2*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,noa,nub))
                  !!! SB: (5,6,4,2) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), (/1,nub-1/), nob, nob, noa, nub)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/5,6,4,2/), nob, nob, noa, nub, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1A_vv,H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(j,k,i,b)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = l3c_excits_copy(jdet,1); f = l3c_excits_copy(jdet,3);
                         ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~db~f~ >
                         hmatel = h2b_vvvv(d,f,a,c)
                         if (c==f) hmatel = hmatel + h1a_vv(d,a)
                         resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,i,c)
                      if (idx/=0) then ! protect against case where b = nua because a = 1, nua-1
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = l3c_excits_copy(jdet,1); f = l3c_excits_copy(jdet,3);
                            ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~dc~f~ >
                            hmatel = -h2b_vvvv(d,f,a,b)
                            if (b==f) hmatel = hmatel - h1a_vv(d,a)
                            resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (5,6,4,3) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,noa/), (/2,nub/), nob, nob, noa, nub)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/5,6,4,3/), nob, nob, noa, nub, nloc, n3abb)
                  !!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vvvv,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(j,k,i,c)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = l3c_excits_copy(jdet,1); e = l3c_excits_copy(jdet,2);
                         ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~de~c~ >
                         hmatel = h2b_vvvv(d,e,a,b)
                         resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,i,b)
                      if (idx/=0) then ! protect against case where a = 1 because b = 2, nua
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = l3c_excits_copy(jdet,1); e = l3c_excits_copy(jdet,2);
                            ! compute < ij~k~ab~c~ | h2b(vvvv) | ij~k~de~b~ >
                            hmatel = -h2b_vvvv(d,e,a,c)
                            resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                         end do
                      end if
                  end do; end do; end do; ! end loop over idet
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 9: A(jk)A(bc) h2c(ekmc)*l3c(abeijm)
                  ! allocate new sorting arrays
                  nloc = nub*nua*nob*noa
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3c_excits_copy(jdet,3); n = l3c_excits_copy(jdet,6);
                        ! compute < ij~k~ab~c~ | h2a(voov) | ij~n~ab~f~ >
                        hmatel = h2c_voov(f,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                     end do
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            f = l3c_excits_copy(jdet,3); n = l3c_excits_copy(jdet,6);
                            ! compute < ij~k~ab~c~ | h2a(voov) | ik~n~ab~f~ >
                            hmatel = -h2c_voov(f,j,n,c)
                            resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                         end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                         do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            f = l3c_excits_copy(jdet,3); n = l3c_excits_copy(jdet,6);
                            ! compute < ij~k~ab~c~ | h2a(voov) | ij~n~ac~f~ >
                            hmatel = -h2c_voov(f,k,n,b)
                            resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                         end do
                     end if
                     ! (jk)(bc)
                      idx = idx_table(a,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                             f = l3c_excits_copy(jdet,3); n = l3c_excits_copy(jdet,6);
                             ! compute < ij~k~ab~c~ | h2a(voov) | ik~n~ac~f~ >
                             hmatel = h2c_voov(f,j,n,b)
                             resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/1,nob-1/), nua, nub, noa, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/1,3,4,5/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(a,c,i,j)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          e = l3c_excits_copy(jdet,2); n = l3c_excits_copy(jdet,6);
                          ! compute < ij~k~ab~c~ | h2c(voov) | ij~n~ae~c~ >
                          hmatel = h2c_voov(e,k,n,b)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(a,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); n = l3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2c(voov) | ik~n~ae~c~ >
                              hmatel = -h2c_voov(e,j,n,b)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                      ! (bc)
                      idx = idx_table(a,b,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); n = l3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2c(voov) | ij~n~ae~b~ >
                              hmatel = -h2c_voov(e,k,n,c)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                      ! (jk)(bc)
                      idx = idx_table(a,b,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); n = l3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2c(voov) | ik~n~ae~b~ >
                              hmatel = h2c_voov(e,j,n,c)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/1,nub-1/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(a,b,i,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          f = l3c_excits_copy(jdet,3); m = l3c_excits_copy(jdet,5);
                          ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ab~f~ >
                          hmatel = h2c_voov(f,j,m,c)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(a,b,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = l3c_excits_copy(jdet,3); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ab~f~ >
                              hmatel = -h2c_voov(f,k,m,c)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                      ! (bc)
                      idx = idx_table(a,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = l3c_excits_copy(jdet,3); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ac~f~ >
                              hmatel = -h2c_voov(f,j,m,b)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                      ! (jk)(bc)
                      idx = idx_table(a,c,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = l3c_excits_copy(jdet,3); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ac~f~ >
                              hmatel = h2c_voov(f,k,m,b)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua/), (/2,nub/), (/1,noa/), (/2,nob/), nua, nub, noa, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2C_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(a,c,i,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          e = l3c_excits_copy(jdet,2); m = l3c_excits_copy(jdet,5);
                          ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ae~c~ >
                          hmatel = h2c_voov(e,j,m,b)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(a,c,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ae~c~ >
                              hmatel = -h2c_voov(e,k,m,b)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                      ! (bc)
                      idx = idx_table(a,b,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~k~ae~b~ >
                              hmatel = -h2c_voov(e,j,m,c)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                      ! (jk)(bc)
                      idx = idx_table(a,b,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2c(voov) | im~j~ae~b~ >
                              hmatel = h2c_voov(e,k,m,c)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
           
                  !!!! diagram 10: h2a(amie)*t3c(ebcmjk)
                  ! allocate sorting arrays
                  nloc = nub*(nub-1)/2*nob*(nob-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2A_voov,&
                  !$omp noa,nua,nob,nub,&
                  !$omp n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      idx = idx_table(b,c,j,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                         d = l3c_excits_copy(jdet,1); l = l3c_excits_copy(jdet,4);
                         ! compute < ij~k~ab~c~ | h2a(voov) | lj~k~db~c~ >
                         hmatel = h2a_voov(d,i,l,a)
                         resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                  end do; end do; end do; ! end loop over idet
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
           
                  !!!! diagram 11: -A(bc) h2b(iemb)*l3c(aecmjk)
                  ! allocate sorting arrays
                  nloc = nob*(nob-1)/2*nub*nua
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,nua,nub))
                  !!! SB: (5,6,1,3) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,nua/), (/2,nub/), nob, nob, nua, nub)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/5,6,1,3/), nob, nob, nua, nub, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(j,k,a,c)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          e = l3c_excits_copy(jdet,2); l = l3c_excits_copy(jdet,4);
                          ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ae~c~ >
                          hmatel = -h2b_ovov(i,e,l,b)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,a,b)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = l3c_excits_copy(jdet,2); l = l3c_excits_copy(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ae~b~ >
                              hmatel = h2b_ovov(i,e,l,c)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (5,6,1,2) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-1/), (/-1,nob/), (/1,nua/), (/1,nub-1/), nob, nob, nua, nub)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/5,6,1,2/), nob, nob, nua, nub, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(j,k,a,b)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          f = l3c_excits_copy(jdet,3); l = l3c_excits_copy(jdet,4);
                          ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ab~f~ >
                          hmatel = -h2b_ovov(i,f,l,c)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (bc)
                      idx = idx_table(j,k,a,c)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = l3c_excits_copy(jdet,3); l = l3c_excits_copy(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovov) | lj~k~ac~f~ >
                              hmatel = h2b_ovov(i,f,l,b)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 12: -A(bc) h2b(ejam)*l3c(ebcimk)
                  ! allocate sorting arrays
                  nloc = nub*(nub-1)/2*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,noa,nob))
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,noa/), (/2,nob/), nub, nub, noa, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nub, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,i,k)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          d = l3c_excits_copy(jdet,1); m = l3c_excits_copy(jdet,5);
                          ! compute < ij~k~ab~c~ | h2b(vovo) | im~k~db~c~ >
                          hmatel = -h2b_vovo(d,j,a,m)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(b,c,i,j)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = l3c_excits_copy(jdet,1); m = l3c_excits_copy(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(vovo) | im~j~db~c~ >
                              hmatel = h2b_vovo(d,k,a,m)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,noa/), (/1,nob-1/), nub, nub, noa, nob)
                  call sort4(l3c_excits_copy, l3c_amps_copy, loc_arr, idx_table, (/2,3,4,5/), nub, nub, noa, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l3c_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_vovo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,i,j)
                      do jdet = loc_arr(1,idx), loc_arr(2,idx)
                          d = l3c_excits_copy(jdet,1); n = l3c_excits_copy(jdet,6);
                          ! compute < ij~k~ab~c~ | h2b(vovo) | ij~n~db~c~ >
                          hmatel = -h2b_vovo(d,k,a,n)
                          resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                      end do
                      ! (jk)
                      idx = idx_table(b,c,i,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = l3c_excits_copy(jdet,1); n = l3c_excits_copy(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(vovo) | ik~n~db~c~ >
                              hmatel = h2b_vovo(d,j,a,n)
                              resid(idet) = resid(idet) + hmatel * l3c_amps_copy(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  !end if

                  !!!! diagram 13: h2b(ieam)*l3d(ebcmjk)
                  !if (n3bbb/=0) then
                  ! allocate and initialize the copy of l3d
                  allocate(amps_buff(n3bbb))
                  allocate(excits_buff(n3bbb,6))
                  amps_buff(:) = l3d_amps(:)
                  excits_buff(:,:) = l3d_excits(:,:)
                  ! allocate sorting arrays
                  nloc = (nub-1)*(nub-2)/2*(nob-1)*(nob-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | l~j~k~d~b~c~ >
                              hmatel = h2b_ovvo(i,d,a,l)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | j~m~k~d~b~c~ >
                              hmatel = -h2b_ovvo(i,d,a,m)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              d = excits_buff(jdet,1); n = excits_buff(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | j~k~n~d~b~c~ >
                              hmatel = h2b_ovvo(i,d,a,n)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | l~j~k~b~e~c~ >
                              hmatel = -h2b_ovvo(i,e,a,l)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | j~m~k~b~e~c~ >
                              hmatel = h2b_ovvo(i,e,a,m)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              e = excits_buff(jdet,2); n = excits_buff(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | j~k~n~b~e~c~ >
                              hmatel = -h2b_ovvo(i,e,a,n)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = excits_buff(jdet,3); l = excits_buff(jdet,4);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | l~j~k~b~c~f~ >
                              hmatel = h2b_ovvo(i,f,a,l)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = excits_buff(jdet,3); m = excits_buff(jdet,5);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | j~m~k~b~c~f~ >
                              hmatel = -h2b_ovvo(i,f,a,m)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,2,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_ovvo,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                      ! (1)
                      idx = idx_table(b,c,j,k)
                      if (idx/=0) then
                          do jdet = loc_arr(1,idx), loc_arr(2,idx)
                              f = excits_buff(jdet,3); n = excits_buff(jdet,6);
                              ! compute < ij~k~ab~c~ | h2b(ovvo) | j~k~n~b~c~f~ >
                              hmatel = h2b_ovvo(i,f,a,n)
                              resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                          end do
                      end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate l3 buffer arrays
                  deallocate(amps_buff,excits_buff)
                  !end if

                  !!!! diagram 14: A(bc)A(jk) h2b(ejmb)*l3b(aecimk)
                  !if (n3aab/=0) then
                  ! allocate and initialize the copy of l3b
                  allocate(amps_buff(n3aab))
                  allocate(excits_buff(n3aab,6))
                  amps_buff(:) = l3b_amps(:)
                  excits_buff(:,:) = l3b_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nua*nub*noa*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nua,nub,noa,nob))
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imk~aec~ >
                            hmatel = h2b_voov(e,j,m,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imk~aeb~ >
                            hmatel = -h2b_voov(e,j,m,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imj~aec~ >
                            hmatel = -h2b_voov(e,k,m,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imj~aeb~ >
                            hmatel = h2b_voov(e,k,m,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/1,noa-1/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,4,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imk~dac~ >
                            hmatel = -h2b_voov(d,j,m,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imk~dab~ >
                            hmatel = h2b_voov(d,j,m,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imj~dac~ >
                            hmatel = h2b_voov(d,k,m,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); m = excits_buff(jdet,5);
                            ! compute < ij~k~ab~c~ | h2b(voov) | imj~dab~ >
                            hmatel = -h2b_voov(d,k,m,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nua-1/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/1,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lik~aec~ >
                            hmatel = -h2b_voov(e,j,l,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lik~aeb~ >
                            hmatel = h2b_voov(e,j,l,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lij~aec~ >
                            hmatel = h2b_voov(e,k,l,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            e = excits_buff(jdet,2); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lij~aeb~ >
                            hmatel = -h2b_voov(e,k,l,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nua/), (/1,nub/), (/2,noa/), (/1,nob/), nua, nub, noa, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nua, nub, noa, nob, nloc, n3aab)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3abb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lik~dac~ >
                            hmatel = h2b_voov(d,j,l,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lik~dab~ >
                            hmatel = -h2b_voov(d,j,l,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lij~dac~ >
                            hmatel = -h2b_voov(d,k,l,b)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                            d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                            ! compute < ij~k~ab~c~ | h2b(voov) | lij~dab~ >
                            hmatel = h2b_voov(d,k,l,c)
                            resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  ! deallocate l3 buffer arrays
                  deallocate(amps_buff,excits_buff)

                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3c_excits_copy,&
                  !$omp l1a,l1b,l2b,l2c,&
                  !$omp H1A_ov,H1B_ov,H2B_oovv,H2C_oovv,&
                  !$omp H2C_vovv,H2C_ooov,&
                  !$omp H2B_vovv,H2B_ovvv,H2B_ooov,H2B_oovo,&
                  !$omp X2C_vovv,X2C_ooov,&
                  !$omp X2B_vovv,X2B_ovvv,X2B_ooov,X2B_oovo,&
                  !$omp noa,nob,nua,nub,n3bbb),&
                  !$omp do schedule(static)
                  do c=1,nua; do b=1,nub; do a=b+1,nub;
                      kk = i; jj = j; ii = k;
                      ! A(ab)A(ij) l1b(ai)*h2b(kjcb)
                      ! l1a(ck)*h2c(ijab)
                      ! A(ab)A(ij) l2b(cbkj)*h1b(ia)
                      ! l2c(abij)*h1a(kc)
                      res =  l1b(a,ii)*h2b_oovv(kk,jj,c,b) + l2b(c,b,kk,jj)*h1b_ov(ii,a)& ! (1)
                            -l1b(a,jj)*h2b_oovv(kk,ii,c,b) - l2b(c,b,kk,ii)*h1b_ov(jj,a)& ! (ij)
                            -l1b(b,ii)*h2b_oovv(kk,jj,c,a) - l2b(c,a,kk,jj)*h1b_ov(ii,b)& ! (ab)
                            +l1b(b,jj)*h2b_oovv(kk,ii,c,a) + l2b(c,a,kk,ii)*h1b_ov(jj,b)& ! (ab)(ij)
                            +l1a(c,kk)*h2c_oovv(ii,jj,a,b) + l2c(a,b,ii,jj)*h1a_ov(kk,c)
                      ! A(ab)A(ij) h2b(eica)*l2b(ebkj)
                      ! A(ab)A(ij) x2b(eica)*h2b(kjeb)
                      do e = 1, nua
                         res = res&
                               +h2b_vovv(e,ii,c,a)*l2b(e,b,kk,jj) + x2b_vovv(e,ii,c,a)*h2b_oovv(kk,jj,e,b)& ! (1)
                               -h2b_vovv(e,jj,c,a)*l2b(e,b,kk,ii) - x2b_vovv(e,jj,c,a)*h2b_oovv(kk,ii,e,b)& ! (iijj)
                               -h2b_vovv(e,ii,c,b)*l2b(e,a,kk,jj) - x2b_vovv(e,ii,c,b)*h2b_oovv(kk,jj,e,a)& ! (ab)
                               +h2b_vovv(e,jj,c,b)*l2b(e,a,kk,ii) + x2b_vovv(e,jj,c,b)*h2b_oovv(kk,ii,e,a)  ! (iijj)(ab)
                      end do
                      ! A(ab) h2b(kecb)*l2c(aeij)
                      ! A(ij) h2c(eiba)*l2b(cekj)
                      ! A(ab) x2b(kecb)*h2c(ijae)
                      ! A(ij) x2c(eiba)*h2b(kjce)
                      do e = 1, nub
                         res = res&
                               +h2b_ovvv(kk,e,c,b)*l2c(a,e,ii,jj) - h2b_ovvv(kk,e,c,a)*l2c(b,e,ii,jj)&
                               +h2c_vovv(e,ii,b,a)*l2b(c,e,kk,jj) - h2c_vovv(e,jj,b,a)*l2b(c,e,kk,ii)&
                               +x2b_ovvv(kk,e,c,b)*h2c_oovv(ii,jj,a,e) - x2b_ovvv(kk,e,c,a)*h2c_oovv(ii,jj,b,e)&
                               +x2c_vovv(e,ii,b,a)*h2b_oovv(kk,jj,c,e) - x2c_vovv(e,jj,b,a)*h2b_oovv(kk,ii,c,e)
                      end do
                      ! A(ij)A(ab) -h2b(kima)*l2b(cbmj)
                      ! A(ij)A(ab) -x2b(kima)*h2b(mjcb)
                      do m = 1, noa
                         res = res&
                              -h2b_ooov(kk,ii,m,a)*l2b(c,b,m,jj) - x2b_ooov(kk,ii,m,a)*h2b_oovv(m,jj,c,b)& ! (1)
                              +h2b_ooov(kk,jj,m,a)*l2b(c,b,m,ii) + x2b_ooov(kk,jj,m,a)*h2b_oovv(m,ii,c,b)& ! (iijj)
                              +h2b_ooov(kk,ii,m,b)*l2b(c,a,m,jj) + x2b_ooov(kk,ii,m,b)*h2b_oovv(m,jj,c,a)& ! (ab)
                              -h2b_ooov(kk,jj,m,b)*l2b(c,a,m,ii) - x2b_ooov(kk,jj,m,b)*h2b_oovv(m,ii,c,a)  ! (iijj)(ab)
                      end do
                      ! A(ij) -h2b(kjcm)*l2c(abim)
                      ! A(ab) -h2c(jima)*l2b(cbkm)
                      ! A(ij) -x2b(kjcm)*h2c(imab)
                      ! A(ab) -x2c(jima)*h2b(kmcb)
                      do m = 1, nob
                         res = res&
                              -h2b_oovo(kk,jj,c,m)*l2c(a,b,ii,m) + h2b_oovo(kk,ii,c,m)*l2c(a,b,jj,m)&
                              -h2c_ooov(jj,ii,m,a)*l2b(c,b,kk,m) + h2c_ooov(jj,ii,m,b)*l2b(c,a,kk,m)&
                              -x2b_oovo(kk,jj,c,m)*h2c_oovv(ii,m,a,b) + x2b_oovo(kk,ii,c,m)*h2c_oovv(jj,m,a,b)&
                              -x2c_ooov(jj,ii,m,a)*h2b_oovv(kk,m,c,b) + x2c_ooov(jj,ii,m,b)*h2b_oovv(kk,m,c,a)
                      end do
                      resid(c,b,a) = resid(c,b,a) + res
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!

                  ! deallocate copied l3c arrays
                  deallocate(l3c_excits_copy,l3c_amps_copy)

        end subroutine build_leftamps3c_ijk

        subroutine build_leftamps3d_ijk(resid, i, j, k,&
                              l1b, l2c,&
                              l3c_amps, l3c_excits,&
                              l3d_amps, l3d_excits,&
                              h1b_ov, h1b_oo, h1b_vv,&
                              h2b_voov,&
                              h2c_oooo, h2c_ooov, h2c_oovv,&
                              h2c_voov, h2c_vovv, h2c_vvvv,&
                              x2c_ooov, x2c_vovv,&
                              orbsym, sym_ijk, target_sym,&
                              n3abb, n3bbb,&
                              noa, nua, nob, nub, norb)
                  ! Input dimension variables
                  integer, intent(in) :: noa, nua, nob, nub
                  integer, intent(in) :: n3abb, n3bbb
                  integer, intent(in) :: norb
                  integer, intent(in) :: orbsym(norb), sym_ijk, target_sym
                  ! orbital integer blocks
                  integer, intent(in) :: i, j, k
                  ! Input L arrays
                  real(kind=8), intent(in) :: l1b(nub,nob)
                  real(kind=8), intent(in) :: l2c(nub,nub,nob,nob)
                  integer, intent(in) :: l3c_excits(n3abb,6), l3d_excits(n3bbb,6)
                  real(kind=8), intent(in) :: l3c_amps(n3abb), l3d_amps(n3bbb)
                  ! Input H and X arrays
                  real(kind=8), intent(in) :: h1b_ov(nob,nub)
                  real(kind=8), intent(in) :: h1b_oo(nob,nob)
                  real(kind=8), intent(in) :: h1b_vv(nub,nub)
                  real(kind=8), intent(in) :: h2c_oooo(nob,nob,nob,nob)
                  real(kind=8), intent(in) :: h2c_ooov(nob,nob,nob,nub)
                  real(kind=8), intent(in) :: h2c_oovv(nob,nob,nub,nub)
                  real(kind=8), intent(in) :: h2c_voov(nub,nob,nob,nub)
                  real(kind=8), intent(in) :: h2c_vovv(nub,nob,nub,nub)
                  real(kind=8), intent(in) :: h2c_vvvv(nub,nub,nub,nub)
                  real(kind=8), intent(in) :: h2b_voov(nua,nob,noa,nub)
                  real(kind=8), intent(in) :: x2c_ooov(nob,nob,nob,nub)
                  real(kind=8), intent(in) :: x2c_vovv(nub,nob,nub,nub)
                  ! Output and variables
                  real(kind=8), intent(out) :: resid(nub,nub,nub)
                  ! Local variables
                  integer, allocatable :: excits_buff(:,:), l3d_excits_copy(:,:)
                  real(kind=8), allocatable :: amps_buff(:), l3d_amps_copy(:)
                  integer, allocatable :: idx_table(:,:,:,:), idx_table3(:,:,:)
                  integer, allocatable :: loc_arr(:,:)
                  real(kind=8) :: l_amp, hmatel, hmatel1, res
                  integer :: a, b, c, d, ii, jj, kk, l, m, n, e, f, jdet
                  integer :: idx, nloc
                  integer :: sym
                  !
                  logical(kind=1) :: qspace(nub,nub,nub)

                  ! copy over l3d_amps and l3d_excits
                  allocate(l3d_amps_copy(n3bbb),l3d_excits_copy(n3bbb,6))
                  l3d_amps_copy(:) = l3d_amps(:)
                  l3d_excits_copy(:,:) = l3d_excits(:,:)
                  
                  ! reorder l3d into (i,j,k) order
                  nloc = nob*(nob-1)*(nob-2)/6
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table3(nob,nob,nob))
                  call get_index_table3(idx_table3, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), nob, nob, nob)
                  call sort3(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table3, (/4,5,6/), nob, nob, nob, nloc, n3bbb)
                  ! Construct Q space for block (i,j,k)
                  qspace = .true.
                  idx = idx_table3(i,j,k)
                  if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        a = l3d_excits_copy(jdet,1); b = l3d_excits_copy(jdet,2); c = l3d_excits_copy(jdet,3);
                        ! get symmetry of |ijkabc>
                        sym = ieor(sym_ijk,orbsym(a+nob))
                        sym = ieor(sym,orbsym(b+nob))
                        sym = ieor(sym,orbsym(c+nob))
                        ! skip excitation if not in correct symmetry
                        if (sym /= target_sym) cycle
                        qspace(a,b,c) = .false.
                     end do
                  end if
                  deallocate(loc_arr,idx_table3)

                  ! zero the residual
                  resid = 0.0d0

                  !if (n3bbb/=0) then
                  !!!! diagram 1: -A(i/jk) h1b(im) * l3d(abcmjk)
                  !!!! diagram 3: 1/2 A(k/ij) h2c(ijmn) * l3d(abcmnk)
                  ! NOTE: WITHIN THESE LOOPS, H1B(OO) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2
                  ! allocate new sorting arrays
                  nloc = nub*(nub-1)*(nub-2)/6*nob
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nub,nob))
                  !!! SB: (1,2,3,6) !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/-1,nub/), (/3,nob/), nub, nub, nub, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,2,3,6/), nub, nub, nub, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h1b_oo,h2c_oooo,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,k)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3d_excits_copy(jdet,4); m = l3d_excits_copy(jdet,5);
                        ! compute < lmkabc | h2c(oooo) | ijkabc >
                        hmatel = h2c_oooo(i,j,l,m)
                        ! compute < lmkabc | h1b(oo) | ijkabc > = -A(ij)A(lm) h1b_oo(i,l) * delta(j,m)
                        hmatel1 = 0.0d0
                        if (m==j) hmatel1 = hmatel1 - h1b_oo(i,l) ! (1)
                        if (m==i) hmatel1 = hmatel1 + h1b_oo(j,l) ! (ij)
                        if (l==j) hmatel1 = hmatel1 + h1b_oo(i,m) ! (lm)
                        if (l==i) hmatel1 = hmatel1 - h1b_oo(j,m) ! (ij)(lm)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     ! (ik)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3d_excits_copy(jdet,4); m = l3d_excits_copy(jdet,5);
                           ! compute < lmiabc | h2c(oooo) | ijkabc >
                           hmatel = -h2c_oooo(k,j,l,m)
                           ! compute < lmiabc | h1b(oo) | ijkabc > = A(jk)A(lm) h1b_oo(k,l) * delta(j,m)
                           hmatel1 = 0.0d0
                           if (m==j) hmatel1 = hmatel1 + h1b_oo(k,l) ! (1)
                           if (m==k) hmatel1 = hmatel1 - h1b_oo(j,l) ! (jk)
                           if (l==j) hmatel1 = hmatel1 - h1b_oo(k,m) ! (lm)
                           if (l==k) hmatel1 = hmatel1 + h1b_oo(j,m) ! (jk)(lm)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3d_excits_copy(jdet,4); m = l3d_excits_copy(jdet,5);
                           ! compute < lmjabc | h2c(oooo) | ijkabc >
                           hmatel = -h2c_oooo(i,k,l,m)
                           ! compute < lmjabc | h1b(oo) | ijkabc > = A(ik)A(lm) h1b_oo(i,l) * delta(k,m)
                           hmatel1 = 0.0d0
                           if (m==k) hmatel1 = hmatel1 + h1b_oo(i,l) ! (1)
                           if (m==i) hmatel1 = hmatel1 - h1b_oo(k,l) ! (ik)
                           if (l==k) hmatel1 = hmatel1 - h1b_oo(i,m) ! (lm)
                           if (l==i) hmatel1 = hmatel1 + h1b_oo(k,m) ! (ik)(lm)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,3,4) !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/-1,nub/), (/1,nob-2/), nub, nub, nub, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,2,3,4/), nub, nub, nub, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,i)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        m = l3d_excits_copy(jdet,5); n = l3d_excits_copy(jdet,6);
                        ! compute < imnabc | h2c(oooo) | ijkabc >
                        hmatel = h2c_oooo(j,k,m,n)
                        ! compute < imnabc | h1b(oo) | ijkabc > = -A(jk)A(mn) h1b_oo(j,m) * delta(k,n)
                        hmatel1 = 0.0d0
                        if (n==k) hmatel1 = hmatel1 - h1b_oo(j,m) ! (1)
                        if (n==j) hmatel1 = hmatel1 + h1b_oo(k,m) ! (jk)
                        if (m==k) hmatel1 = hmatel1 + h1b_oo(j,n) ! (mn)
                        if (m==j) hmatel1 = hmatel1 - h1b_oo(k,n) ! (jk)(mn)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,j)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = l3d_excits_copy(jdet,5); n = l3d_excits_copy(jdet,6);
                           ! compute < jmnabc | h2c(oooo) | ijkabc >
                           hmatel = -h2c_oooo(i,k,m,n)
                           ! compute < jmnabc | h1b(oo) | ijkabc > = A(ik)A(mn) h1b_oo(i,m) * delta(k,n)
                           hmatel1 = 0.0d0
                           if (n==k) hmatel1 = hmatel1 + h1b_oo(i,m) ! (1)
                           if (n==i) hmatel1 = hmatel1 - h1b_oo(k,m) ! (ik)
                           if (m==k) hmatel1 = hmatel1 - h1b_oo(i,n) ! (mn)
                           if (m==i) hmatel1 = hmatel1 + h1b_oo(k,n) ! (ik)(mn)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                        end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           m = l3d_excits_copy(jdet,5); n = l3d_excits_copy(jdet,6);
                           ! compute < kmnabc | h2c(oooo) | ijkabc >
                           hmatel = -h2c_oooo(j,i,m,n)
                           ! compute < kmnabc | h1b(oo) | ijkabc > = A(ij)A(mn) h1b_oo(j,m) * delta(i,n)
                           hmatel1 = 0.0d0
                           if (n==i) hmatel1 = hmatel1 - h1b_oo(j,m) ! (1)
                           if (n==j) hmatel1 = hmatel1 + h1b_oo(i,m) ! (ij)
                           if (m==i) hmatel1 = hmatel1 + h1b_oo(j,n) ! (mn)
                           if (m==j) hmatel1 = hmatel1 - h1b_oo(i,n) ! (ij)(mn)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,3,5) !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/-1,nub/), (/2,nob-1/), nub, nub, nub, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,2,3,5/), nub, nub, nub, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_oo,H2C_oooo,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(a,b,c,j)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        l = l3d_excits_copy(jdet,4); n = l3d_excits_copy(jdet,6);
                        ! compute < ljnabc | h2c(oooo) | ijkabc >
                        hmatel = h2c_oooo(i,k,l,n)
                        ! compute < ljnabc | h1b(oo) | ijkabc > = -A(ik)A(ln) h1b_oo(i,l) * delta(k,n)
                        hmatel1 = 0.0d0
                        if (n==k) hmatel1 = hmatel1 - h1b_oo(i,l) ! (1)
                        if (n==i) hmatel1 = hmatel1 + h1b_oo(k,l) ! (ik)
                        if (l==k) hmatel1 = hmatel1 + h1b_oo(i,n) ! (ln)
                        if (l==i) hmatel1 = hmatel1 - h1b_oo(k,n) ! (ik)(ln)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     ! (ij)
                     idx = idx_table(a,b,c,i)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3d_excits_copy(jdet,4); n = l3d_excits_copy(jdet,6);
                           ! compute < linabc | h2c(oooo) | ijkabc >
                           hmatel = -h2c_oooo(j,k,l,n)
                           ! compute < linabc | h1b(oo) | ijkabc > = A(jk)A(ln) h1b_oo(j,l) * delta(k,n)
                           hmatel1 = 0.0d0
                           if (n==k) hmatel1 = hmatel1 + h1b_oo(j,l) ! (1)
                           if (n==j) hmatel1 = hmatel1 - h1b_oo(k,l) ! (jk)
                           if (l==k) hmatel1 = hmatel1 - h1b_oo(j,n) ! (ln)
                           if (l==j) hmatel1 = hmatel1 + h1b_oo(k,n) ! (jk)(ln)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                        end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,c,k)
                     if (idx/=0) then
                        do jdet = loc_arr(1,idx), loc_arr(2,idx)
                           l = l3d_excits_copy(jdet,4); n = l3d_excits_copy(jdet,6);
                           ! compute < lknabc | h2c(oooo) | ijkabc >
                           hmatel = -h2c_oooo(i,j,l,n)
                           ! compute < lknabc | h1b(oo) | ijkabc > = A(ij)A(ln) h1b_oo(i,l) * delta(j,n)
                           hmatel1 = 0.0d0
                           if (n==j) hmatel1 = hmatel1 + h1b_oo(i,l) ! (1)
                           if (n==i) hmatel1 = hmatel1 - h1b_oo(j,l) ! (ij)
                           if (l==j) hmatel1 = hmatel1 - h1b_oo(i,n) ! (ln)
                           if (l==i) hmatel1 = hmatel1 + h1b_oo(j,n) ! (ij)(ln)
                           hmatel = hmatel + 0.5d0 * hmatel1
                           resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                        end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)

                  !!!! diagram 2: A(a/bc) h1b(ea) * l3d(ebcijk)
                  !!!! diagram 4: 1/2 A(c/ab) h2c(efab) * l3d(ebcijk) 
                  ! NOTE: WITHIN THESE LOOPS, H1B(VV) TERMS ARE DOUBLE-COUNTED SO COMPENSATE BY FACTOR OF 1/2  
                  ! allocate new sorting arrays
                  nloc = nob*(nob-1)*(nob-2)/6*nub
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nob,nob,nob,nub))
                  !!! SB: (4,5,6,1) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), (/1,nub-2/), nob, nob, nob, nub)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/4,5,6,1/), nob, nob, nob, nub, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,a)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); f = l3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkaef >
                        hmatel = h2c_vvvv(e,f,b,c)
                        ! compute < ijkabc | h1a(vv) | ijkaef > = A(bc)A(ef) h1b_vv(b,e) * delta(c,f)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 + h1b_vv(e,b) ! (1)
                        if (b==f) hmatel1 = hmatel1 - h1b_vv(e,c) ! (bc)
                        if (c==e) hmatel1 = hmatel1 - h1b_vv(f,b) ! (ef)
                        if (b==e) hmatel1 = hmatel1 + h1b_vv(f,c) ! (bc)(ef)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); f = l3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkbef >
                        hmatel = -h2c_vvvv(e,f,a,c)
                        ! compute < ijkabc | h1a(vv) | ijkbef > = -A(ac)A(ef) h1b_vv(a,e) * delta(c,f)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 - h1b_vv(e,a) ! (1)
                        if (a==f) hmatel1 = hmatel1 + h1b_vv(e,c) ! (ac)
                        if (c==e) hmatel1 = hmatel1 + h1b_vv(f,a) ! (ef)
                        if (a==e) hmatel1 = hmatel1 - h1b_vv(f,c) ! (ac)(ef)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); f = l3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkcef >
                        hmatel = -h2c_vvvv(e,f,b,a)
                        ! compute < ijkabc | h1a(vv) | ijkcef > = -A(ab)A(ef) h1b_vv(b,e) * delta(a,f)
                        hmatel1 = 0.0d0
                        if (a==f) hmatel1 = hmatel1 - h1b_vv(e,b) ! (1)
                        if (b==f) hmatel1 = hmatel1 + h1b_vv(e,a) ! (ab)
                        if (a==e) hmatel1 = hmatel1 + h1b_vv(f,b) ! (ef)
                        if (b==e) hmatel1 = hmatel1 - h1b_vv(f,a) ! (ab)(ef)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (4,5,6,2) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), (/2,nub-1/), nob, nob, nob, nub)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/4,5,6,2/), nob, nob, nob, nub, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do idet=1,num_q
                     a = qspace(idet,1); b = qspace(idet,2); c = qspace(idet,3);
                     i = qspace(idet,4); j = qspace(idet,5); k = qspace(idet,6);
                     ! (1)
                     idx = idx_table(i,j,k,b)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); f = l3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdbf >
                        hmatel = h2c_vvvv(d,f,a,c)
                        ! compute < ijkabc | h1a(vv) | ijkdbf > = A(ac)A(df) h1b_vv(a,d) * delta(c,f)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 + h1b_vv(d,a) ! (1)
                        if (a==f) hmatel1 = hmatel1 - h1b_vv(d,c) ! (ac)
                        if (c==d) hmatel1 = hmatel1 - h1b_vv(f,a) ! (df)
                        if (a==d) hmatel1 = hmatel1 + h1b_vv(f,c) ! (ac)(df)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     ! (ab)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); f = l3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdaf >
                        hmatel = -h2c_vvvv(d,f,b,c)
                        ! compute < ijkabc | h1a(vv) | ijkdaf > = -A(bc)A(df) h1b_vv(b,d) * delta(c,f)
                        hmatel1 = 0.0d0
                        if (c==f) hmatel1 = hmatel1 - h1b_vv(d,b) ! (1)
                        if (b==f) hmatel1 = hmatel1 + h1b_vv(d,c) ! (bc)
                        if (c==d) hmatel1 = hmatel1 + h1b_vv(f,b) ! (df)
                        if (b==d) hmatel1 = hmatel1 - h1b_vv(f,c) ! (bc)(df)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,c)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); f = l3d_excits_copy(jdet,3);
                        ! compute < ijkabc | h2a(vvvv) | ijkdcf >
                        hmatel = -h2c_vvvv(d,f,a,b)
                        ! compute < ijkabc | h1a(vv) | ijkdcf > = -A(ab)A(df) h1b_vv(a,d) * delta(b,f)
                        hmatel1 = 0.0d0
                        if (b==f) hmatel1 = hmatel1 - h1b_vv(d,a) ! (1)
                        if (a==f) hmatel1 = hmatel1 + h1b_vv(d,b) ! (ab)
                        if (b==d) hmatel1 = hmatel1 + h1b_vv(f,a) ! (df)
                        if (a==d) hmatel1 = hmatel1 - h1b_vv(f,b) ! (ab)(df)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if 
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (4,5,6,3) LOOP !!!
                  call get_index_table(idx_table, (/1,nob-2/), (/-1,nob-1/), (/-1,nob/), (/3,nub/), nob, nob, nob, nub)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/4,5,6,3/), nob, nob, nob, nub, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp H1B_vv,H2C_vvvv,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(i,j,k,c)
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); e = l3d_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdec >
                        hmatel = h2c_vvvv(d,e,a,b)
                        ! compute < ijkabc | h1a(vv) | ijkdec > = A(ab)A(de) h1b_vv(a,d) * delta(b,e)
                        hmatel1 = 0.0d0
                        if (b==e) hmatel1 = hmatel1 + h1b_vv(d,a) ! (1)
                        if (a==e) hmatel1 = hmatel1 - h1b_vv(d,b) ! (ab)
                        if (b==d) hmatel1 = hmatel1 - h1b_vv(e,a) ! (de)
                        if (a==d) hmatel1 = hmatel1 + h1b_vv(e,b) ! (ab)(de)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     ! (ac)
                     idx = idx_table(i,j,k,a)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); e = l3d_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdea >
                        hmatel = -h2c_vvvv(d,e,c,b)
                        ! compute < ijkabc | h1a(vv) | ijkdea > = -A(bc)A(de) h1b_vv(c,d) * delta(b,e)
                        hmatel1 = 0.0d0
                        if (b==e) hmatel1 = hmatel1 - h1b_vv(d,c) ! (1)
                        if (c==e) hmatel1 = hmatel1 + h1b_vv(d,b) ! (bc)
                        if (b==d) hmatel1 = hmatel1 + h1b_vv(e,c) ! (de)
                        if (c==d) hmatel1 = hmatel1 - h1b_vv(e,b) ! (bc)(de)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(i,j,k,b)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); e = l3d_excits_copy(jdet,2);
                        ! compute < ijkabc | h2a(vvvv) | ijkdeb >
                        hmatel = -h2c_vvvv(d,e,a,c)
                        ! compute < ijkabc | h1a(vv) | ijkdeb > = -A(ac)A(de) h1b_vv(a,d) * delta(c,e)
                        hmatel1 = 0.0d0
                        if (c==e) hmatel1 = hmatel1 - h1b_vv(d,a) ! (1)
                        if (a==e) hmatel1 = hmatel1 + h1b_vv(d,c) ! (ac)
                        if (c==d) hmatel1 = hmatel1 + h1b_vv(e,a) ! (de)
                        if (a==d) hmatel1 = hmatel1 - h1b_vv(e,c) ! (ac)(de)
                        hmatel = hmatel + 0.5d0 * hmatel1
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  
                  !!!! diagram 5: A(i/jk)A(a/bc) h2c(eima) * l3c(ebcmjk)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = (nub-1)*(nub-2)/2*(nob-1)*(nob-2)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! SB: (1,2,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,2,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < ijnabf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < ijnbcf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,k,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < ijnacf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,k,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < jknabf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,i,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < jknbcf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,i,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < jknacf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,i,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < iknabf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,j,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < iknbcf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,j,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); n = l3d_excits_copy(jdet,6);
                        ! compute < iknacf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,j,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < ijnaec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,k,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < ijnbec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,k,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < ijnaeb | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < jknaec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,i,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < jknbec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,i,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < jknaeb | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,i,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < iknaec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,j,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < iknbec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,j,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); n = l3d_excits_copy(jdet,6);
                        ! compute < iknaeb | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,j,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,5) LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-1,nob-1/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/2,3,4,5/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < ijndbc | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,k,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < ijndac | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,k,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < ijndab | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,k,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < jkndbc | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,i,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < jkndac | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,i,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < jkndab | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,i,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < ikndbc | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,j,n,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < ikndac | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,j,n,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); n = l3d_excits_copy(jdet,6);
                        ! compute < ikndab | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,j,n,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,2,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < imkabf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,j,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < imkbcf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,j,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < imkacf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,j,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkabf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,i,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkbcf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,i,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkacf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,i,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < imjabf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,k,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < imjbcf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,k,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); m = l3d_excits_copy(jdet,5);
                        ! compute < imjacf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,k,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < imkaec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,j,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < imkbec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,j,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < imkaeb | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,j,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkaec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,i,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkbec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,i,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkaeb | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,i,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < imjaec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,k,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < imjbec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,k,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); m = l3d_excits_copy(jdet,5);
                        ! compute < imjaeb | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,k,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,4,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/1,nob-2/), (/-2,nob/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/2,3,4,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < imkdbc | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,j,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < imkdac | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,j,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < imkdab | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,j,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkdbc | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,i,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkdac | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,i,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < jmkdab | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,i,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (jk)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < imjdbc | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,k,m,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(jk)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < imjdac | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,k,m,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(jk)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); m = l3d_excits_copy(jdet,5);
                        ! compute < imjdab | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,k,m,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,2,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-1,nub-1/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,2,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkabf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,i,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkbcf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkacf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < likabf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,j,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < likbcf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < likacf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < lijabf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,k,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < lijbcf | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(f,k,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        f = l3d_excits_copy(jdet,3); l = l3d_excits_copy(jdet,4);
                        ! compute < lijacf | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(f,k,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (1,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-2/), (/-2,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/1,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkaec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkbec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkaeb | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,i,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < likaec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < likbec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < likaeb | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,j,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < lijaec | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(e,k,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < lijbec | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,k,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (bc)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        e = l3d_excits_copy(jdet,2); l = l3d_excits_copy(jdet,4);
                        ! compute < lijaeb | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(e,k,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/2,nub-1/), (/-1,nub/), (/2,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(l3d_excits_copy, l3d_amps_copy, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3bbb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l3d_amps_copy,&
                  !$omp loc_arr,idx_table,&
                  !$omp h2c_voov,&
                  !$omp noa,nua,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkdbc | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,i,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkdac | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,i,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < ljkdab | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,i,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < likdbc | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,j,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < likdac | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,j,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < likdab | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,j,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < lijdbc | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,k,l,a)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < lijdac | h2c(voov) | ijkabc >
                        hmatel = -h2c_voov(d,k,l,b)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = l3d_excits_copy(jdet,1); l = l3d_excits_copy(jdet,4);
                        ! compute < lijdab | h2c(voov) | ijkabc >
                        hmatel = h2c_voov(d,k,l,c)
                        resid(idet) = resid(idet) + hmatel * l3d_amps_copy(jdet)
                     end do
                     end if
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
                  ! deallocate sorting arrays
                  deallocate(loc_arr,idx_table)
                  !end if
                  
                  !!!! diagram 6: A(i/jk)A(a/bc) h2b(eima) * l3c(ebcmjk)
                  !if (n3abb/=0) then
                  ! allocate and copy over t3c arrays
                  allocate(amps_buff(n3abb),excits_buff(n3abb,6))
                  amps_buff(:) = l3c_amps(:)
                  excits_buff(:,:) = l3c_excits(:,:)
                  ! allocate sorting arrays (can be reused for each permutation)
                  nloc = nub*(nub-1)/2*nob*(nob-1)/2
                  allocate(loc_arr(2,nloc))
                  allocate(idx_table(nub,nub,nob,nob))
                  !!! SB: (2,3,5,6) LOOP !!!
                  call get_index_table(idx_table, (/1,nub-1/), (/-1,nub/), (/1,nob-1/), (/-1,nob/), nub, nub, nob, nob)
                  call sort4(excits_buff, amps_buff, loc_arr, idx_table, (/2,3,5,6/), nub, nub, nob, nob, nloc, n3abb)
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,excits_buff,&
                  !$omp amps_buff,&
                  !$omp loc_arr,idx_table,&
                  !$omp H2B_voov,&
                  !$omp noa,nua,nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                     if (.not. qspace(a,b,c)) cycle
                     ! (1)
                     idx = idx_table(b,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | lj~k~db~c~ >
                        hmatel = h2b_voov(d,i,l,a)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ab)
                     idx = idx_table(a,c,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | lj~k~da~c~ >
                        hmatel = -h2b_voov(d,i,l,b)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)
                     idx = idx_table(a,b,j,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | lj~k~da~b~ >
                        hmatel = h2b_voov(d,i,l,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ij)
                     idx = idx_table(b,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | li~k~db~c~ >
                        hmatel = -h2b_voov(d,j,l,a)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ab)(ij)
                     idx = idx_table(a,c,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | li~k~da~c~ >
                        hmatel = h2b_voov(d,j,l,b)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)(ij)
                     idx = idx_table(a,b,i,k)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | li~k~da~b~ >
                        hmatel = -h2b_voov(d,j,l,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ik)
                     idx = idx_table(b,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | li~j~db~c~ >
                        hmatel = h2b_voov(d,k,l,a)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ab)(ik)
                     idx = idx_table(a,c,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | li~j~da~c~ >
                        hmatel = -h2b_voov(d,k,l,b)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                     ! (ac)(ik)
                     idx = idx_table(a,b,i,j)
                     if (idx/=0) then
                     do jdet = loc_arr(1,idx), loc_arr(2,idx)
                        d = excits_buff(jdet,1); l = excits_buff(jdet,4);
                        ! compute < i~j~k~a~b~c~ | h2b(voov) | li~j~da~b~ >
                        hmatel = h2b_voov(d,k,l,c)
                        resid(idet) = resid(idet) + hmatel * amps_buff(jdet)
                     end do
                     end if
                 end do; end do; end do;
                 !$omp end do
                 !$omp end parallel
                 !!!! END OMP PARALLEL SECTION !!!!
                 ! deallocate sorting arrays
                 deallocate(loc_arr,idx_table)
                 ! deallocate l3 buffer arrays
                 deallocate(amps_buff,excits_buff)
           
                  !!!! BEGIN OMP PARALLEL SECTION !!!!
                  !$omp parallel shared(resid,&
                  !$omp l3d_excits_copy,&
                  !$omp l1b,l2c,&
                  !$omp H1B_ov,H2C_oovv,H2C_vovv,H2C_ooov,&
                  !$omp X2C_vovv,X2C_ooov,&
                  !$omp nob,nub,n3bbb),&
                  !$omp do schedule(static)
                  do a=1,nub; do b=a+1,nub; do c=b+1,nub;
                      if (.not. qspace(a,b,c)) cycle
                      ! A(i/jk)A(a/bc) [l1b(ai) * h2c(jkbc) + h1b(ia) * l2c(bcjk)]
                      res =  l1b(a,i)*h2c_oovv(j,k,b,c) + h1b_ov(i,a)*l2c(b,c,j,k)& ! (1)
                            -l1b(a,j)*h2c_oovv(i,k,b,c) - h1b_ov(j,a)*l2c(b,c,i,k)& ! (ij)
                            -l1b(a,k)*h2c_oovv(j,i,b,c) - h1b_ov(k,a)*l2c(b,c,j,i)& ! (ik)
                            -l1b(b,i)*h2c_oovv(j,k,a,c) - h1b_ov(i,b)*l2c(a,c,j,k)& ! (ab)
                            +l1b(b,j)*h2c_oovv(i,k,a,c) + h1b_ov(j,b)*l2c(a,c,i,k)& ! (ij)(ab)
                            +l1b(b,k)*h2c_oovv(j,i,a,c) + h1b_ov(k,b)*l2c(a,c,j,i)& ! (ik)(ab)
                            -l1b(c,i)*h2c_oovv(j,k,b,a) - h1b_ov(i,c)*l2c(b,a,j,k)& ! (ac)
                            +l1b(c,j)*h2c_oovv(i,k,b,a) + h1b_ov(j,c)*l2c(b,a,i,k)& ! (ij)(ac)
                            +l1b(c,k)*h2c_oovv(j,i,b,a) + h1b_ov(k,c)*l2c(b,a,j,i)  ! (ik)(ac)
                      ! A(c/ab)A(j/ik) [-h2c(ikmc) * l2c(abmj) - h2c(mjab) * x2c(ikmc)]
                      do m = 1, nob
                         res = res&
                               - h2c_oovv(m,j,a,b)*x2c_ooov(i,k,m,c)& ! (1)
                               + h2c_oovv(m,i,a,b)*x2c_ooov(j,k,m,c)& ! (ij)
                               + h2c_oovv(m,k,a,b)*x2c_ooov(i,j,m,c)& ! (jk)
                               + h2c_oovv(m,j,c,b)*x2c_ooov(i,k,m,a)& ! (ac)
                               - h2c_oovv(m,i,c,b)*x2c_ooov(j,k,m,a)& ! (ij)(ac)
                               - h2c_oovv(m,k,c,b)*x2c_ooov(i,j,m,a)& ! (jk)(ac)
                               + h2c_oovv(m,j,a,c)*x2c_ooov(i,k,m,b)& ! (bc)
                               - h2c_oovv(m,i,a,c)*x2c_ooov(j,k,m,b)& ! (ij)(bc)
                               - h2c_oovv(m,k,a,c)*x2c_ooov(i,j,m,b)  ! (jk)(bc)
                         res = res&
                               - l2c(a,b,m,j)*h2c_ooov(i,k,m,c)& ! (1)
                               + l2c(a,b,m,i)*h2c_ooov(j,k,m,c)& ! (ij)
                               + l2c(a,b,m,k)*h2c_ooov(i,j,m,c)& ! (jk)
                               + l2c(c,b,m,j)*h2c_ooov(i,k,m,a)& ! (ac)
                               - l2c(c,b,m,i)*h2c_ooov(j,k,m,a)& ! (ij)(ac)
                               - l2c(c,b,m,k)*h2c_ooov(i,j,m,a)& ! (jk)(ac)
                               + l2c(a,c,m,j)*h2c_ooov(i,k,m,b)& ! (bc)
                               - l2c(a,c,m,i)*h2c_ooov(j,k,m,b)& ! (ij)(bc)
                               - l2c(a,c,m,k)*h2c_ooov(i,j,m,b)  ! (jk)(bc)
                      end do
                      ! A(b/ac)A(k/ij) [h2c_vovv(ekac)*l2c(ebij) + h2c(ijeb)*x2c(ekac)]
                      do e = 1, nub
                         res = res&
                               + h2c_oovv(i,j,e,b)*x2c_vovv(e,k,a,c)& ! (1)
                               - h2c_oovv(k,j,e,b)*x2c_vovv(e,i,a,c)& ! (ik)
                               - h2c_oovv(i,k,e,b)*x2c_vovv(e,j,a,c)& ! (jk)
                               - h2c_oovv(i,j,e,a)*x2c_vovv(e,k,b,c)& ! (ab)
                               + h2c_oovv(k,j,e,a)*x2c_vovv(e,i,b,c)& ! (ik)(ab)
                               + h2c_oovv(i,k,e,a)*x2c_vovv(e,j,b,c)& ! (jk)(ab)
                               - h2c_oovv(i,j,e,c)*x2c_vovv(e,k,a,b)& ! (bc)
                               + h2c_oovv(k,j,e,c)*x2c_vovv(e,i,a,b)& ! (ik)(bc)
                               + h2c_oovv(i,k,e,c)*x2c_vovv(e,j,a,b)  ! (jk)(bc)
                         res = res&
                               + l2c(e,b,i,j)*h2c_vovv(e,k,a,c)& ! (1)
                               - l2c(e,b,k,j)*h2c_vovv(e,i,a,c)& ! (ik)
                               - l2c(e,b,i,k)*h2c_vovv(e,j,a,c)& ! (jk)
                               - l2c(e,a,i,j)*h2c_vovv(e,k,b,c)& ! (ab)
                               + l2c(e,a,k,j)*h2c_vovv(e,i,b,c)& ! (ik)(ab)
                               + l2c(e,a,i,k)*h2c_vovv(e,j,b,c)& ! (jk)(ab)
                               - l2c(e,c,i,j)*h2c_vovv(e,k,a,b)& ! (bc)
                               + l2c(e,c,k,j)*h2c_vovv(e,i,a,b)& ! (ik)(bc)
                               + l2c(e,c,i,k)*h2c_vovv(e,j,a,b)  ! (jk)(bc)
                      end do
                      resid(idet) = resid(idet) + res
                  end do; end do; end do;
                  !$omp end do
                  !$omp end parallel
                  !!!! END OMP PARALLEL SECTION !!!!
          
                  ! deallocate l3d array copies
                  deallocate(l3d_excits_copy,l3d_amps_copy)
        end subroutine build_leftamps3d_ijk
         
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!! SORTING FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      
      subroutine get_index_table3(idx_table, rng1, rng2, rng3, n1, n2, n3)

           integer, intent(in) :: n1, n2, n3
           integer, intent(in) :: rng1(2), rng2(2), rng3(2)

           integer, intent(inout) :: idx_table(n1,n2,n3)

           integer :: kout
           integer :: p, q, r

           idx_table = 0
           if (rng1(1) > 0 .and. rng2(1) < 0 .and. rng3(1) < 0) then ! p < q < r
              kout = 1
              do p = rng1(1), rng1(2)
                 do q = p-rng2(1), rng2(2)
                    do r = q-rng3(1), rng3(2)
                       idx_table(p,q,r) = kout
                       kout = kout + 1
                    end do
                 end do
              end do
           elseif (rng1(1) > 0 .and. rng2(1) > 0 .and. rng3(1) < 0) then ! p, q < r
              kout = 1
              do p = rng1(1), rng1(2)
                 do q = rng2(1), rng2(2)
                    do r = q-rng3(1), rng3(2)
                       idx_table(p,q,r) = kout
                       kout = kout + 1
                    end do
                 end do
              end do
           elseif (rng1(1) > 0 .and. rng2(1) < 0 .and. rng3(1) > 0) then ! p < q, r
              kout = 1
              do p = rng1(1), rng1(2)
                 do q = p-rng2(1), rng2(2)
                    do r = rng3(1), rng3(2)
                       idx_table(p,q,r) = kout
                       kout = kout + 1
                    end do
                 end do
              end do
           else ! p, q, r
              kout = 1
              do p = rng1(1), rng1(2)
                 do q = rng2(1), rng2(2)
                    do r = rng3(1), rng3(2)
                       idx_table(p,q,r) = kout
                       kout = kout + 1
                    end do
                 end do
              end do
           end if

     end subroutine get_index_table3

     subroutine sort3(excits, amps, loc_arr, idx_table, idims, n1, n2, n3, nloc, n3p, x1a)

           integer, intent(in) :: n1, n2, n3, nloc, n3p
           integer, intent(in) :: idims(3)
           integer, intent(in) :: idx_table(n1,n2,n3)

           integer, intent(inout) :: loc_arr(2,nloc)
           integer, intent(inout) :: excits(n3p,6)
           real(kind=8), intent(inout) :: amps(n3p)
           real(kind=8), intent(inout), optional :: x1a(n3p)

           integer :: idet
           integer :: p, q, r
           integer :: p1, q1, r1, p2, q2, r2
           integer :: pqr1, pqr2
           integer, allocatable :: temp(:), idx(:)

           allocate(temp(n3p),idx(n3p))
           do idet = 1, n3p
              p = excits(idet,idims(1)); q = excits(idet,idims(2)); r = excits(idet,idims(3));
              temp(idet) = idx_table(p,q,r)
           end do
           call argsort(temp, idx)
           excits = excits(idx,:)
           amps = amps(idx)
           if (present(x1a)) x1a = x1a(idx)
           deallocate(temp,idx)

           loc_arr(1,:) = 1; loc_arr(2,:) = 0;
           !!! WARNING: THERE IS A MEMORY LEAK HERE! pqrs2 is used below but is not set if n3p <= 1
           !if (n3p <= 1) print*, "eomccsdt_p_loops >> WARNING: potential memory leakage in sort4 function. pqrs2 set to -1"
           if (n3p == 1) then
              if (excits(1,1)==1 .and. excits(1,2)==1 .and. excits(1,3)==1 .and. excits(1,4)==1 .and. excits(1,5)==1 .and. excits(1,6)==1) return
              p2 = excits(n3p,idims(1)); q2 = excits(n3p,idims(2)); r2 = excits(n3p,idims(3));
              pqr2 = idx_table(p2,q2,r2)
           else
              pqr2 = -1
           end if
           do idet = 1, n3p-1
              p1 = excits(idet,idims(1));   q1 = excits(idet,idims(2));   r1 = excits(idet,idims(3));
              p2 = excits(idet+1,idims(1)); q2 = excits(idet+1,idims(2)); r2 = excits(idet+1,idims(3));
              pqr1 = idx_table(p1,q1,r1)
              pqr2 = idx_table(p2,q2,r2)
              if (pqr1 /= pqr2) then
                 loc_arr(2,pqr1) = idet
                 loc_arr(1,pqr2) = idet+1
              end if
           end do
           if (n3p > 1) then
              loc_arr(2,pqr2) = n3p
           end if
     end subroutine sort3

      subroutine get_index_table(idx_table, rng1, rng2, rng3, rng4, n1, n2, n3, n4)

              integer, intent(in) :: n1, n2, n3, n4
              integer, intent(in) :: rng1(2), rng2(2), rng3(2), rng4(2)

              integer, intent(inout) :: idx_table(n1,n2,n3,n4)

              integer :: kout
              integer :: p, q, r, s

              idx_table = 0
              ! 5 possible cases. Always organize so that ordered indices appear first.
              if (rng1(1) < 0 .and. rng2(1) < 0 .and. rng3(1) < 0 .and. rng4(1) < 0) then ! p < q < r < s
                 kout = 1
                 do p = rng1(1), rng1(2)
                    do q = p-rng2(1), rng2(2)
                       do r = q-rng3(1), rng3(2)
                          do s = r-rng4(1), rng4(2)
                             idx_table(p,q,r,s) = kout
                             kout = kout + 1
                          end do
                       end do
                    end do
                 end do
              elseif (rng1(1) > 0 .and. rng2(1) < 0 .and. rng3(1) < 0 .and. rng4(1) > 0) then ! p < q < r, s
                 kout = 1
                 do p = rng1(1), rng1(2)
                    do q = p-rng2(1), rng2(2)
                       do r = q-rng3(1), rng3(2)
                          do s = rng4(1), rng4(2)
                             idx_table(p,q,r,s) = kout
                             kout = kout + 1
                          end do
                       end do
                    end do
                 end do
              elseif (rng1(1) > 0 .and. rng2(1) < 0 .and. rng3(1) > 0 .and. rng4(1) < 0) then ! p < q, r < s
                 kout = 1
                 do p = rng1(1), rng1(2)
                    do q = p-rng2(1), rng2(2)
                       do r = rng3(1), rng3(2)
                          do s = r-rng4(1), rng4(2)
                             idx_table(p,q,r,s) = kout
                             kout = kout + 1
                          end do
                       end do
                    end do
                 end do
              elseif (rng1(1) > 0 .and. rng2(1) < 0 .and. rng3(1) > 0 .and. rng4(1) > 0) then ! p < q, r, s
                 kout = 1
                 do p = rng1(1), rng1(2)
                    do q = p-rng2(1), rng2(2)
                       do r = rng3(1), rng3(2)
                          do s = rng4(1), rng4(2)
                             idx_table(p,q,r,s) = kout
                             kout = kout + 1
                          end do
                       end do
                    end do
                 end do
              else ! p, q, r, s
                 kout = 1
                 do p = rng1(1), rng1(2)
                    do q = rng2(1), rng2(2)
                       do r = rng3(1), rng3(2)
                          do s = rng4(1), rng4(2)
                             idx_table(p,q,r,s) = kout
                             kout = kout + 1
                          end do
                       end do
                    end do
                 end do
              end if

      end subroutine get_index_table

      subroutine sort4(excits, amps, loc_arr, idx_table, idims, n1, n2, n3, n4, nloc, n3p, resid)
      ! Sort the 1D array of T3 amplitudes, the 2D array of T3 excitations, and, optionally, the
      ! associated 1D residual array such that triple excitations with the same spatial orbital
      ! indices in the positions indicated by idims are next to one another.
      ! In:
      !   idims: array of 4 integer dimensions along which T3 will be sorted
      !   n1, n2, n3, and n4: no/nu sizes of each dimension in idims
      !   nloc: permutationally unique number of possible (p,q,r,s) tuples
      !   n3p: Number of P-space triples of interest
      ! In,Out:
      !   excits: T3 excitation array (can be aaa, aab, abb, or bbb)
      !   amps: T3 amplitude vector (can be aaa, aab, abb, or bbb)
      !   resid (optional): T3 residual vector (can be aaa, aab, abb, or bbb)
      !   loc_arr: array providing the start- and end-point indices for each sorted block in t3 excitations
          
              integer, intent(in) :: n1, n2, n3, n4, nloc, n3p
              integer, intent(in) :: idims(4)
              integer, intent(in) :: idx_table(n1,n2,n3,n4)

              integer, intent(inout) :: loc_arr(2,nloc)
              integer, intent(inout) :: excits(n3p,6)
              real(kind=8), intent(inout) :: amps(n3p)
              real(kind=8), intent(inout), optional :: resid(n3p)

              integer :: idet
              integer :: p, q, r, s
              integer :: p1, q1, r1, s1, p2, q2, r2, s2
              integer :: pqrs1, pqrs2
              integer, allocatable :: temp(:), idx(:)

              ! obtain the lexcial index for each triple excitation in the P space along the sorting dimensions idims
              allocate(temp(n3p),idx(n3p))
              do idet = 1, n3p
                 p = excits(idet,idims(1)); q = excits(idet,idims(2)); r = excits(idet,idims(3)); s = excits(idet,idims(4))
                 temp(idet) = idx_table(p,q,r,s)
              end do
              ! get the sorting array
              call argsort(temp, idx)
              ! apply sorting array to t3 excitations, amplitudes, and, optionally, residual arrays
              excits = excits(idx,:)
              amps = amps(idx)
              if (present(resid)) resid = resid(idx)
              deallocate(temp,idx)
              ! obtain the start- and end-point indices for each lexical index in the sorted t3 excitation and amplitude arrays
              loc_arr(1,:) = 1; loc_arr(2,:) = 0; ! set default start > end so that empty sets do not trigger loops
              !!! WARNING: THERE IS A MEMORY LEAK HERE! pqrs2 is used below but is not set if n3p <= 1
              !if (n3p <= 1) print*, "(ccsdt_p_loops) >> WARNING: potential memory leakage in sort4 function. pqrs2 set to -1"
              if (n3p == 1) then
                 if (excits(1,1)==1 .and. excits(1,2)==1 .and. excits(1,3)==1 .and. excits(1,4)==1 .and. excits(1,5)==1 .and. excits(1,6)==1) return
                 p2 = excits(n3p,idims(1)); q2 = excits(n3p,idims(2)); r2 = excits(n3p,idims(3)); s2 = excits(n3p,idims(4))
                 pqrs2 = idx_table(p2,q2,r2,s2)
              else
                 pqrs2 = -1
              end if
              do idet = 1, n3p-1
                 ! get consecutive lexcial indices
                 p1 = excits(idet,idims(1));   q1 = excits(idet,idims(2));   r1 = excits(idet,idims(3));   s1 = excits(idet,idims(4))
                 p2 = excits(idet+1,idims(1)); q2 = excits(idet+1,idims(2)); r2 = excits(idet+1,idims(3)); s2 = excits(idet+1,idims(4))
                 pqrs1 = idx_table(p1,q1,r1,s1)
                 pqrs2 = idx_table(p2,q2,r2,s2)
                 ! if change occurs between consecutive indices, record these locations in loc_arr as new start/end points
                 if (pqrs1 /= pqrs2) then
                    loc_arr(2,pqrs1) = idet
                    loc_arr(1,pqrs2) = idet+1
                 end if
              end do
              !if (n3p > 1) then
              loc_arr(2,pqrs2) = n3p
              !end if

      end subroutine sort4

      subroutine argsort(r,d)

              integer, intent(in), dimension(:) :: r
              integer, intent(out), dimension(size(r)) :: d

              integer, dimension(size(r)) :: il

              integer :: stepsize
              integer :: i, j, n, left, k, ksize

              n = size(r)

              do i=1,n
                 d(i)=i
              end do

              if (n==1) return

              stepsize = 1
              do while (stepsize < n)
                 do left = 1, n-stepsize,stepsize*2
                    i = left
                    j = left+stepsize
                    ksize = min(stepsize*2,n-left+1)
                    k=1

                    do while (i < left+stepsize .and. j < left+ksize)
                       if (r(d(i)) < r(d(j))) then
                          il(k) = d(i)
                          i = i+1
                          k = k+1
                       else
                          il(k) = d(j)
                          j = j+1
                          k = k+1
                       endif
                    enddo

                    if (i < left+stepsize) then
                       ! fill up remaining from left
                       il(k:ksize) = d(i:left+stepsize-1)
                    else
                       ! fill up remaining from right
                       il(k:ksize) = d(j:left+ksize-1)
                    endif
                    d(left:left+ksize-1) = il(1:ksize)
                 end do
                 stepsize = stepsize*2
              end do

      end subroutine argsort
      
      subroutine reorder4(y, x, iorder)

          integer, intent(in) :: iorder(4)
          real(kind=8), intent(in) :: x(:,:,:,:)

          real(kind=8), intent(out) :: y(:,:,:,:)

          integer :: i, j, k, l
          integer :: vec(4)

          y = 0.0d0
          do i = 1, size(x,1)
             do j = 1, size(x,2)
                do k = 1, size(x,3)
                   do l = 1, size(x,4)
                      vec = (/i,j,k,l/)
                      y(vec(iorder(1)),vec(iorder(2)),vec(iorder(3)),vec(iorder(4))) = x(i,j,k,l)
                   end do
                end do
             end do
          end do

      end subroutine reorder4
    
      subroutine sum4(x, y, iorder)

          integer, intent(in) :: iorder(4)
          real(kind=8), intent(in) :: y(:,:,:,:)

          real(kind=8), intent(inout) :: x(:,:,:,:)
          
          integer :: i, j, k, l
          integer :: vec(4)

          do i = 1, size(x,1)
             do j = 1, size(x,2)
                do k = 1, size(x,3)
                   do l = 1, size(x,4)
                      vec = (/i,j,k,l/)
                      x(i,j,k,l) = x(i,j,k,l) + y(vec(iorder(1)),vec(iorder(2)),vec(iorder(3)),vec(iorder(4)))
                   end do
                end do
             end do
          end do

      end subroutine sum4

end module ccp3_full_correction
