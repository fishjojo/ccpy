module ccp_loops

      USE OMP_LIB

      implicit none

      integer, parameter :: omp_num_threads = 8
      integer, parameter :: mkl_num_threads = 4


      contains

              subroutine initialize_t3(idx3a,idx3b,idx3c,idx3d,&
                              num_ijk_3a,num_ijk_3b,num_ijk_3c,num_ijk_3d,&
                              noa,nua,nob,nub)

                 integer, intent(in) :: noa, nua, nob, nub
                 integer, intent(out) :: idx3a(noa,noa,noa), idx3b(noa,noa,nob),&
                 idx3c(noa,nob,nob), idx3d(nob,nob,nob), num_ijk_3a, num_ijk_3b,&
                 num_ijk_3c, num_ijk_3d

                 integer :: i, j, k
                 integer, parameter :: t3a_io = 100, t3b_io = 101, t3c_io = 102, t3d_io = 103
                 real(kind=8), allocatable :: temp(:,:,:)

                 num_ijk_3a = 0
                 do i = 1,noa
                    do j = i+1,noa
                       do k = j+1,noa
                          num_ijk_3a = num_ijk_3a + 1
                       end do
                    end do
                 end do
                 num_ijk_3b = 0
                 do i = 1,noa
                    do j = i+1,noa
                       do k = 1,nob
                          num_ijk_3b = num_ijk_3b + 1
                       end do
                    end do
                 end do
                 num_ijk_3c = 0
                 do i = 1,noa
                    do j = 1,nob
                       do k = j+1,nob
                          num_ijk_3c = num_ijk_3c + 1
                       end do
                    end do
                 end do
                 num_ijk_3d = 0
                 do i = 1,nob
                    do j = i+1,nob
                       do k = j+1,nob
                          num_ijk_3d = num_ijk_3d + 1
                       end do
                    end do
                 end do

                 allocate(temp(nua,nua,nua))
                 open(t3a_io,file='t3a.bin',access='sequential',form='unformatted',status='new',recl=num_ijk_3a)
                 ct = 1
                 do i = 1,noa
                    do j = i+1,noa
                       do k = j+1,noa
                          write(t3a_io,temp,rec=ct)
                          idx3a(i,j,k) = ct
                          ct = ct + 1
                       end do
                    end do
                 end do
                 close(t3a_io)
                 deallocate(temp)

                 allocate(temp(nua,nua,nub))
                 open(t3b_io,file='t3b.bin',access='sequential',form='unformatted',status='new',recl=num_ijk_3b)
                 ct = 1
                 do i = 1,noa
                    do j = i+1,noa
                       do k = 1,nob
                          write(t3b_io,temp,rec=ct)
                          idx3b(i,j,k) = ct
                          ct = ct + 1
                       end do
                    end do
                 end do
                 close(t3b_io)
                 deallocate(temp)

                 allocate(temp(nua,nub,nub))
                 open(t3c_io,file='t3c.bin',access='sequential',form='unformatted',status='new',recl=num_ijk_3c)
                 ct = 1
                 do i = 1,noa
                    do j = 1,nob
                       do k = j+1,nob
                          write(t3c_io,temp,rec=ct)
                          idx3c(i,j,k) = ct
                          ct = ct + 1
                       end do
                    end do
                 end do
                 close(t3c_io)
                 deallocate(temp)

                 allocate(temp(nub,nub,nub))
                 open(t3d_io,file='t3d.bin',access='sequential',form='unformatted',status='new',recl=num_ijk_3d)
                 ct = 1
                 do i = 1,nob
                    do j = i+1,nob
                       do k = j+1,nob
                          write(t3c_io,temp,rec=ct)
                          idx3d(i,j,k) = ct
                          ct = ct + 1
                       end do
                    end do
                 end do
                 close(t3d_io)
                 deallocate(temp)

              end subroutine initialize_t3

              subroutine update_t3a(t2a,idx3a,idx3b,&
                         nocc_3a, nocc_3b,&
                         vA_oovv,vB_oovv,&
                         H1A_oo,H1A_vv,H2A_oooo,&
                         H2A_vvvv,H2A_voov,H2B_voov,&
                         H2A_vooo,I2A_vvov,&
                         fA_oo,fA_vv,shift,&
                         noa,nua,nob,nub,num_triples)

                 integer, intent(in) :: noa, nua, nob, nub
                 integer, intent(in) :: idx3a(noa,noa,noa), idx3b(noa,noa,nob), nocc_3a, nocc_3b
                 real(kind=8), intent(in) :: shift
                 real(kind=8), intent(in) :: t2a(nua,nua,noa,noa),&
                                             vA_oovv(noa,noa,nua,nua),&
                                             vB_oovv(noa,nob,nua,nub),&
                                             H1A_oo(noa,noa),H1A_vv(nua,nua),&
                                             H2A_oooo(noa,noa,noa,noa),&
                                             H2A_vvvv(nua,nua,nua,nua),&
                                             H2A_voov(nua,noa,noa,nua),&
                                             H2B_voov(nua,nob,noa,nub),&
                                             H2A_vooo(nua,noa,noa,noa),&
                                             I2A_vvov(nua,nua,noa,nua),&
                                             fA_oo(noa,noa),fA_vv(nua,nua)

                integer :: a, b, c, i, j, k
                real(kind=8) :: m1, m2, d1, d2, d3, d4, d5, d6,&
                                residual, denom, val, mval
                real(kind=8) :: vt3_oa(noa), vt3_ua(nua),&
                                H2A_voov_r(nua,nua,noa,noa),&
                                H2B_voov_r(nua,nub,noa,nob),&
                                vA_oovv_r1(nua,nua,noa,noa),&
                                vA_oovv_r2(nua,noa,noa,nua),&
                                vB_oovv_r1(nua,nub,nob,noa),&
                                vB_oovv_r2(nub,noa,nob,nua),&
                                temp1(noa), temp2(noa),&
                                temp3(nua), temp4(nua)
                real(kind=8), allocatable :: t3a(:,:,:), t3b(:,:,:), t3c(:,:,:), t3d(:,:,:)


                integer, parameter :: t3a_io = 100, t3b_io = 101
                real(kind=8), parameter :: MINUSONE=-1.0d+0, HALF=0.5d+0, ZERO=0.0d+0, ONE=1.0d+0
                real(kind=8), external :: ddot

                integer :: m, n, e ,f
                real(kind=8) :: error(8), refval
                
                !call mkl_set_num_threads_local(mkl_num_threads)
                !call omp_set_num_threads(omp_num_threads)

                do i = 1,8
                    error(i) = ZERO
                end do

                open(t3a_io,file='t3a.bin',access='sequential',status='old',recl=nocc_3a)
                allocate(t3a(nua,nua,nua))
                do i = 1,noa
                   do j = i+1,noa
                      do k = j+1,noa
                         ! Diagram 1: -A(i/jk)A(a/bc) h1a(mi)t3a(abcmjk)
                         do m = 1,noa
                            read(t3a_io,rec=idx3a(m,j,k)) t3a
                            call dgemm('t','n',
                        
                         do a = 1,nua
                            do b = a+1,nua
                               do c = b+1,nua
    
                               end do
                            end do
                         end do
                      end do
                    end do
                 end do

    

                !!!!!!!!!!!!

           
                   ! Shift indices up by since the triples list is coming from
                   ! Python, where indices start from 0       
                   a = triples_list(ct,1)+1
                   b = triples_list(ct,2)+1
                   c = triples_list(ct,3)+1
                   i = triples_list(ct,4)+1
                   j = triples_list(ct,5)+1
                   k = triples_list(ct,6)+1
                    
                   ! Calculate devectorized residual for triple |ijkabc>
                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(a,:,:,i,j,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(a,:,:,i,j,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = MINUSONE*ddot(noa,H2A_vooo(a,:,i,j)+vt3_oa,1,t2a(b,c,:,k),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(a,:,:,i,k,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(a,:,:,i,k,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 + ddot(noa,H2A_vooo(a,:,i,k)+vt3_oa,1,t2a(b,c,:,j),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(a,:,:,k,j,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(a,:,:,k,j,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 + ddot(noa,H2A_vooo(a,:,k,j)+vt3_oa,1,t2a(b,c,:,i),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(b,:,:,i,j,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(b,:,:,i,j,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 + ddot(noa,H2A_vooo(b,:,i,j)+vt3_oa,1,t2a(a,c,:,k),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(b,:,:,i,k,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(b,:,:,i,k,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 - ddot(noa,H2A_vooo(b,:,i,k)+vt3_oa,1,t2a(a,c,:,j),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(b,:,:,k,j,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(b,:,:,k,j,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 - ddot(noa,H2A_vooo(b,:,k,j)+vt3_oa,1,t2a(a,c,:,i),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(c,:,:,i,j,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(c,:,:,i,j,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 + ddot(noa,H2A_vooo(c,:,i,j)+vt3_oa,1,t2a(b,a,:,k),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(c,:,:,i,k,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(c,:,:,i,k,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 - ddot(noa,H2A_vooo(c,:,i,k)+vt3_oa,1,t2a(b,a,:,j),1)

                   call dgemv('t',noanua2,noa,HALF,vA_oovv_r1,noanua2,t3a(c,:,:,k,j,:),1,ZERO,temp1,1)
                   call dgemv('t',nuanobnub,noa,ONE,vB_oovv_r1,nuanobnub,t3b(c,:,:,k,j,:),1,ZERO,temp2,1)
                   vt3_oa = temp1 + temp2
                   m1 = m1 - ddot(noa,H2A_vooo(c,:,k,j)+vt3_oa,1,t2a(b,a,:,i),1)

                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      do f = e+1,nua
                   !         do n = 1,noa
                   !            refval = refval&
                   !            -vA_oovv(m,n,e,f)*t3a(a,e,f,i,j,n)*t2a(b,c,m,k)&
                   !            +vA_oovv(m,n,e,f)*t3a(a,e,f,i,k,n)*t2a(b,c,m,j)&
                   !            +vA_oovv(m,n,e,f)*t3a(a,e,f,k,j,n)*t2a(b,c,m,i)&
                   !            +vA_oovv(m,n,e,f)*t3a(b,e,f,i,j,n)*t2a(a,c,m,k)&
                   !            -vA_oovv(m,n,e,f)*t3a(b,e,f,i,k,n)*t2a(a,c,m,j)&
                   !            -vA_oovv(m,n,e,f)*t3a(b,e,f,k,j,n)*t2a(a,c,m,i)&
                   !            +vA_oovv(m,n,e,f)*t3a(c,e,f,i,j,n)*t2a(b,a,m,k)&
                   !            -vA_oovv(m,n,e,f)*t3a(c,e,f,i,k,n)*t2a(b,a,m,j)&
                   !            -vA_oovv(m,n,e,f)*t3a(c,e,f,k,j,n)*t2a(b,a,m,i)
                   !         end do
                   !      end do
                   !   end do
                   !   do e = 1,nua
                   !      do f = 1,nub
                   !         do n = 1,nob
                   !            refval = refval&
                   !            -vB_oovv(m,n,e,f)*t3b(a,e,f,i,j,n)*t2a(b,c,m,k)&
                   !            +vB_oovv(m,n,e,f)*t3b(a,e,f,i,k,n)*t2a(b,c,m,j)&
                   !            +vB_oovv(m,n,e,f)*t3b(a,e,f,k,j,n)*t2a(b,c,m,i)&
                   !            +vB_oovv(m,n,e,f)*t3b(b,e,f,i,j,n)*t2a(a,c,m,k)&
                   !            -vB_oovv(m,n,e,f)*t3b(b,e,f,i,k,n)*t2a(a,c,m,j)&
                   !            -vB_oovv(m,n,e,f)*t3b(b,e,f,k,j,n)*t2a(a,c,m,i)&
                   !            +vB_oovv(m,n,e,f)*t3b(c,e,f,i,j,n)*t2a(b,a,m,k)&
                   !            -vB_oovv(m,n,e,f)*t3b(c,e,f,i,k,n)*t2a(b,a,m,j)&
                   !            -vB_oovv(m,n,e,f)*t3b(c,e,f,k,j,n)*t2a(b,a,m,i)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval&
                   !           -H2A_vooo(a,m,i,j)*t2a(b,c,m,k)&
                   !           +H2A_vooo(a,m,i,k)*t2a(b,c,m,j)&
                   !           +H2A_vooo(a,m,k,j)*t2a(b,c,m,i)&
                   !           +H2A_vooo(b,m,i,j)*t2a(a,c,m,k)&
                   !           -H2A_vooo(b,m,i,k)*t2a(a,c,m,j)&
                   !           -H2A_vooo(b,m,k,j)*t2a(a,c,m,i)&
                   !           +H2A_vooo(c,m,i,j)*t2a(b,a,m,k)&
                   !           -H2A_vooo(c,m,i,k)*t2a(b,a,m,j)&
                   !           -H2A_vooo(c,m,k,j)*t2a(b,a,m,i)
                   !end do
                   !error(1) = error(1) + (m1-refval)
                
                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(a,b,:,i,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(a,b,:,i,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = ddot(nua,I2A_vvov(a,b,i,:)-vt3_ua,1,t2a(:,c,j,k),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(a,b,:,j,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(a,b,:,j,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 - ddot(nua,I2A_vvov(a,b,j,:)-vt3_ua,1,t2a(:,c,i,k),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(a,b,:,k,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(a,b,:,k,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 - ddot(nua,I2A_vvov(a,b,k,:)-vt3_ua,1,t2a(:,c,j,i),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(c,b,:,i,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(c,b,:,i,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 - ddot(nua,I2A_vvov(c,b,i,:)-vt3_ua,1,t2a(:,a,j,k),1)
                    
                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(c,b,:,j,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(c,b,:,j,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 + ddot(nua,I2A_vvov(c,b,j,:)-vt3_ua,1,t2a(:,a,i,k),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(c,b,:,k,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(c,b,:,k,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 + ddot(nua,I2A_vvov(c,b,k,:)-vt3_ua,1,t2a(:,a,j,i),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(a,c,:,i,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(a,c,:,i,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 - ddot(nua,I2A_vvov(a,c,i,:)-vt3_ua,1,t2a(:,b,j,k),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(a,c,:,j,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(a,c,:,j,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 + ddot(nua,I2A_vvov(a,c,j,:)-vt3_ua,1,t2a(:,b,i,k),1)

                   call dgemv('t',noa2nua,nua,HALF,vA_oovv_r2,noa2nua,t3a(a,c,:,k,:,:),1,ZERO,temp3,1)
                   call dgemv('t',noanobnub,nua,ONE,vB_oovv_r2,noanobnub,t3b(a,c,:,k,:,:),1,ZERO,temp4,1)
                   vt3_ua = temp3 + temp4
                   m2 = m2 + ddot(nua,I2A_vvov(a,c,k,:)-vt3_ua,1,t2a(:,b,j,i),1)

                   !refval = ZERO
                   !do e = 1,nua
                   !   do m = 1,noa
                   !      do n = m+1,noa
                   !         do f = 1,nua
                   !            refval = refval&
                   !            -vA_oovv(m,n,e,f)*t3a(a,b,f,i,m,n)*t2a(e,c,j,k)&
                   !            +vA_oovv(m,n,e,f)*t3a(a,c,f,i,m,n)*t2a(e,b,j,k)&
                   !            +vA_oovv(m,n,e,f)*t3a(c,b,f,i,m,n)*t2a(e,a,j,k)&
                   !            +vA_oovv(m,n,e,f)*t3a(a,b,f,j,m,n)*t2a(e,c,i,k)&
                   !            -vA_oovv(m,n,e,f)*t3a(a,c,f,j,m,n)*t2a(e,b,i,k)&
                   !            -vA_oovv(m,n,e,f)*t3a(c,b,f,j,m,n)*t2a(e,a,i,k)&
                   !            +vA_oovv(m,n,e,f)*t3a(a,b,f,k,m,n)*t2a(e,c,j,i)&
                   !            -vA_oovv(m,n,e,f)*t3a(a,c,f,k,m,n)*t2a(e,b,j,i)&
                   !            -vA_oovv(m,n,e,f)*t3a(c,b,f,k,m,n)*t2a(e,a,j,i)
                   !         end do
                   !      end do
                   !   end do
                   !   do m = 1,noa
                   !      do n = 1,nob
                   !         do f = 1,nub
                   !            refval = refval&
                   !            -vB_oovv(m,n,e,f)*t3b(a,b,f,i,m,n)*t2a(e,c,j,k)&
                   !            +vB_oovv(m,n,e,f)*t3b(a,c,f,i,m,n)*t2a(e,b,j,k)&
                   !            +vB_oovv(m,n,e,f)*t3b(c,b,f,i,m,n)*t2a(e,a,j,k)&
                   !            +vB_oovv(m,n,e,f)*t3b(a,b,f,j,m,n)*t2a(e,c,i,k)&
                   !            -vB_oovv(m,n,e,f)*t3b(a,c,f,j,m,n)*t2a(e,b,i,k)&
                   !            -vB_oovv(m,n,e,f)*t3b(c,b,f,j,m,n)*t2a(e,a,i,k)&
                   !            +vB_oovv(m,n,e,f)*t3b(a,b,f,k,m,n)*t2a(e,c,j,i)&
                   !            -vB_oovv(m,n,e,f)*t3b(a,c,f,k,m,n)*t2a(e,b,j,i)&
                   !            -vB_oovv(m,n,e,f)*t3b(c,b,f,k,m,n)*t2a(e,a,j,i)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval&
                   !           +I2A_vvov(a,b,i,e)*t2a(e,c,j,k)&
                   !           -I2A_vvov(a,c,i,e)*t2a(e,b,j,k)&
                   !           -I2A_vvov(c,b,i,e)*t2a(e,a,j,k)&
                   !           -I2A_vvov(a,b,j,e)*t2a(e,c,i,k)&
                   !           +I2A_vvov(a,c,j,e)*t2a(e,b,i,k)&
                   !           +I2A_vvov(c,b,j,e)*t2a(e,a,i,k)&
                   !           -I2A_vvov(a,b,k,e)*t2a(e,c,j,i)&
                   !           +I2A_vvov(a,c,k,e)*t2a(e,b,j,i)&
                   !           +I2A_vvov(c,b,k,e)*t2a(e,a,j,i)
                   !end do
                   !error(2) = error(2) + (m2-refval)
                    
                   d1 = MINUSONE*ddot(noa,H1A_oo(:,k),1,t3a(a,b,c,i,j,:),1)
                   d1 = d1 + ddot(noa,H1A_oo(:,j),1,t3a(a,b,c,i,k,:),1)
                   d1 = d1 + ddot(noa,H1A_oo(:,i),1,t3a(a,b,c,k,j,:),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   refval = refval - H1A_oo(m,k)*t3a(a,b,c,i,j,m)&
                   !                   + H1A_oo(m,j)*t3a(a,b,c,i,k,m)&
                   !                   + H1A_oo(m,i)*t3a(a,b,c,k,j,m)
                   !end do
                   !error(3) = error(3) + (d1-refval)

                   d2 = ddot(nua,H1A_vv(c,:),1,t3a(a,b,:,i,j,k),1)
                   d2 = d2 - ddot(nua,H1A_vv(b,:),1,t3a(a,c,:,i,j,k),1)
                   d2 = d2 - ddot(nua,H1A_vv(a,:),1,t3a(c,b,:,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   refval = refval + H1A_vv(c,e)*t3a(a,b,e,i,j,k)&
                   !                   - H1A_vv(b,e)*t3a(a,c,e,i,j,k)&
                   !                   - H1A_vv(a,e)*t3a(c,b,e,i,j,k)
                   !end do
                   !error(4) = error(4) + (d2-refval)

                   d3 = ddot(noa2,H2A_oooo(:,:,i,j),1,t3a(a,b,c,:,:,k),1)
                   d3 = d3 - ddot(noa2,H2A_oooo(:,:,k,j),1,t3a(a,b,c,:,:,i),1)
                   d3 = d3 - ddot(noa2,H2A_oooo(:,:,i,k),1,t3a(a,b,c,:,:,j),1)
                   d3 = HALF*d3
                   !refval = ZERO
                   !do m = 1,noa
                   !   do n = m+1,noa
                   !      refval = refval + H2A_oooo(m,n,i,j)*t3a(a,b,c,m,n,k)&
                   !                      - H2A_oooo(m,n,i,k)*t3a(a,b,c,m,n,j)&
                   !                      - H2A_oooo(m,n,k,j)*t3a(a,b,c,m,n,i)
                   !   end do
                   !end do
                   !error(5) = error(5) + (d3-refval)
        
                   d4 = ddot(nua2,H2A_vvvv(a,b,:,:),1,t3a(:,:,c,i,j,k),1)
                   d4 = d4 - ddot(nua2,H2A_vvvv(c,b,:,:),1,t3a(:,:,a,i,j,k),1)
                   d4 = d4 - ddot(nua2,H2A_vvvv(a,c,:,:),1,t3a(:,:,b,i,j,k),1)
                   d4 = HALF*d4
                   !refval = ZERO
                   !do e = 1,nua
                   !   do f = e+1,nua
                   !      refval = refval + H2A_vvvv(a,b,e,f)*t3a(e,f,c,i,j,k)&
                   !                      - H2A_vvvv(a,c,e,f)*t3a(e,f,b,i,j,k)&
                   !                      - H2A_vvvv(c,b,e,f)*t3a(e,f,a,i,j,k)
                   !   end do
                   !end do
                   !error(6) = error(6) + (d4-refval)

                   d5 = ddot(noaua,h2a_voov_r(c,:,k,:),1,t3a(a,b,:,i,j,:),1)
                   d5 = d5 - ddot(noaua,h2a_voov_r(c,:,i,:),1,t3a(a,b,:,k,j,:),1)
                   d5 = d5 - ddot(noaua,h2a_voov_r(c,:,j,:),1,t3a(a,b,:,i,k,:),1)
                   d5 = d5 - ddot(noaua,h2a_voov_r(a,:,k,:),1,t3a(c,b,:,i,j,:),1)
                   d5 = d5 + ddot(noaua,h2a_voov_r(a,:,i,:),1,t3a(c,b,:,k,j,:),1)
                   d5 = d5 + ddot(noaua,h2a_voov_r(a,:,j,:),1,t3a(c,b,:,i,k,:),1)
                   d5 = d5 - ddot(noaua,h2a_voov_r(b,:,k,:),1,t3a(a,c,:,i,j,:),1)
                   d5 = d5 + ddot(noaua,h2a_voov_r(b,:,i,:),1,t3a(a,c,:,k,j,:),1)
                   d5 = d5 + ddot(noaua,h2a_voov_r(b,:,j,:),1,t3a(a,c,:,i,k,:),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   do m = 1,noa
                   !      refval = refval + H2A_voov(c,m,k,e)*t3a(a,b,e,i,j,m)&
                   !                      - H2A_voov(c,m,j,e)*t3a(a,b,e,i,k,m)&
                   !                      - H2A_voov(c,m,i,e)*t3a(a,b,e,k,j,m)&
                   !                      - H2A_voov(b,m,k,e)*t3a(a,c,e,i,j,m)&
                   !                      + H2A_voov(b,m,j,e)*t3a(a,c,e,i,k,m)&
                   !                      + H2A_voov(b,m,i,e)*t3a(a,c,e,k,j,m)&
                   !                      - H2A_voov(a,m,k,e)*t3a(c,b,e,i,j,m)&
                   !                      + H2A_voov(a,m,j,e)*t3a(c,b,e,i,k,m)&
                   !                      + H2A_voov(a,m,i,e)*t3a(c,b,e,k,j,m)
                   !   end do
                   !end do
                   !error(7) = error(7) + (d5-refval)

                   d6 = ddot(nobub,h2b_voov_r(c,:,k,:),1,t3b(a,b,:,i,j,:),1)
                   d6 = d6 - ddot(nobub,h2b_voov_r(c,:,i,:),1,t3b(a,b,:,k,j,:),1)
                   d6 = d6 - ddot(nobub,h2b_voov_r(c,:,j,:),1,t3b(a,b,:,i,k,:),1)
                   d6 = d6 - ddot(nobub,h2b_voov_r(a,:,k,:),1,t3b(c,b,:,i,j,:),1)
                   d6 = d6 + ddot(nobub,h2b_voov_r(a,:,i,:),1,t3b(c,b,:,k,j,:),1)
                   d6 = d6 + ddot(nobub,h2b_voov_r(a,:,j,:),1,t3b(c,b,:,i,k,:),1)
                   d6 = d6 - ddot(nobub,h2b_voov_r(b,:,k,:),1,t3b(a,c,:,i,j,:),1)
                   d6 = d6 + ddot(nobub,h2b_voov_r(b,:,i,:),1,t3b(a,c,:,k,j,:),1)
                   d6 = d6 + ddot(nobub,h2b_voov_r(b,:,j,:),1,t3b(a,c,:,i,k,:),1)
                   !refval = ZERO
                   !do e = 1,nub
                   !   do m = 1,nob
                   !      refval = refval + H2B_voov(c,m,k,e)*t3b(a,b,e,i,j,m)&
                   !                      - H2B_voov(c,m,j,e)*t3b(a,b,e,i,k,m)&
                   !                      - H2B_voov(c,m,i,e)*t3b(a,b,e,k,j,m)&
                   !                      - H2B_voov(b,m,k,e)*t3b(a,c,e,i,j,m)&
                   !                      + H2B_voov(b,m,j,e)*t3b(a,c,e,i,k,m)&
                   !                      + H2B_voov(b,m,i,e)*t3b(a,c,e,k,j,m)&
                   !                      - H2B_voov(a,m,k,e)*t3b(c,b,e,i,j,m)&
                   !                      + H2B_voov(a,m,j,e)*t3b(c,b,e,i,k,m)&
                   !                      + H2B_voov(a,m,i,e)*t3b(c,b,e,k,j,m)
                   !   end do
                   !end do
                   !error(8) = error(8) + (d6-refval)
                
                   residual = m1 + m2 + d1 + d2 + d3 + d4 + d5 + d6
                   denom = fA_oo(i,i)+fA_oo(j,j)+fA_oo(k,k)&
                           -fA_vv(a,a)-fA_vv(b,b)-fA_vv(c,c)
                   val = t3a(a,b,c,i,j,k) + residual/(denom-shift)
                   mval = MINUSONE*val

                   t3a_new(a,b,c,i,j,k) = val
                   t3a_new(A,B,C,K,I,J) = val
                   t3a_new(A,B,C,J,K,I) = val
                   t3a_new(A,B,C,I,K,J) = mval
                   t3a_new(A,B,C,J,I,K) = mval
                   t3a_new(A,B,C,K,J,I) = mval
                                      
                   t3a_new(B,A,C,I,J,K) = mval
                   t3a_new(B,A,C,K,I,J) = mval
                   t3a_new(B,A,C,J,K,I) = mval
                   t3a_new(B,A,C,I,K,J) = val
                   t3a_new(B,A,C,J,I,K) = val
                   t3a_new(B,A,C,K,J,I) = val
                                      
                   t3a_new(A,C,B,I,J,K) = mval
                   t3a_new(A,C,B,K,I,J) = mval
                   t3a_new(A,C,B,J,K,I) = mval
                   t3a_new(A,C,B,I,K,J) = val
                   t3a_new(A,C,B,J,I,K) = val
                   t3a_new(A,C,B,K,J,I) = val
                                      
                   t3a_new(C,B,A,I,J,K) = mval
                   t3a_new(C,B,A,K,I,J) = mval
                   t3a_new(C,B,A,J,K,I) = mval
                   t3a_new(C,B,A,I,K,J) = val
                   t3a_new(C,B,A,J,I,K) = val
                   t3a_new(C,B,A,K,J,I) = val
                                      
                   t3a_new(B,C,A,I,J,K) = val
                   t3a_new(B,C,A,K,I,J) = val
                   t3a_new(B,C,A,J,K,I) = val
                   t3a_new(B,C,A,I,K,J) = mval
                   t3a_new(B,C,A,J,I,K) = mval
                   t3a_new(B,C,A,K,J,I) = mval
                                      
                   t3a_new(C,A,B,I,J,K) = val
                   t3a_new(C,A,B,K,I,J) = val
                   t3a_new(C,A,B,J,K,I) = val
                   t3a_new(C,A,B,I,K,J) = mval
                   t3a_new(C,A,B,J,I,K) = mval
                   t3a_new(C,A,B,K,J,I) = mval

                end do
                !$OMP END DO
                !$OMP END PARALLEL

                !do i = 1,8
                !   print*,'Error in term',i,'=',error(i)
                !end do

            end subroutine update_t3a


            subroutine update_t3b(t2a,t2b,&
                         t3a,t3b,t3c,&
                         triples_list,&
                         vA_oovv,vB_oovv,vC_oovv,&
                         H1A_oo,H1A_vv,H1B_oo,H1B_vv,&
                         H2A_oooo,H2A_vvvv,H2A_voov,&
                         H2B_oooo,H2B_vvvv,H2B_voov,&
                         H2B_ovov,H2B_vovo,H2B_ovvo,&
                         H2C_voov,&
                         I2A_vooo,H2A_vvov,&
                         I2B_vooo,I2B_ovoo,H2B_vvov,H2B_vvvo,&
                         fA_oo,fA_vv,fB_oo,fB_vv,shift,&
                         noa,nua,nob,nub,num_triples,t3b_new)

                integer, intent(in) :: noa, nua, nob, nub, num_triples
                real(kind=8), intent(in) :: shift
                integer, intent(in) :: triples_list(num_triples,6)
                real(kind=8), intent(in) ::  t2a(nua,nua,noa,noa),&
                                             t2b(nua,nub,noa,nob),&
                                             t3a(nua,nua,nua,noa,noa,noa),&
                                             t3b(nua,nua,nub,noa,noa,nob),&
                                             t3c(nua,nub,nub,noa,nob,nob),&
                                             vA_oovv(noa,noa,nua,nua),&
                                             vB_oovv(noa,nob,nua,nub),&
                                             vC_oovv(nob,nob,nub,nub),&
                                             H1A_oo(noa,noa),H1A_vv(nua,nua),&
                                             H1B_oo(nob,nob),H1B_vv(nub,nub),&
                                             H2A_oooo(noa,noa,noa,noa),&
                                             H2A_vvvv(nua,nua,nua,nua),&
                                             H2A_voov(nua,noa,noa,nua),&
                                             H2B_oooo(noa,nob,noa,nob),&
                                             H2B_vvvv(nua,nub,nua,nub),&
                                             H2B_voov(nua,nob,noa,nub),&
                                             H2B_ovov(noa,nub,noa,nub),&
                                             H2B_vovo(nua,nob,nua,nob),&
                                             H2B_ovvo(noa,nub,nua,nob),&
                                             H2C_voov(nub,nob,nob,nub),&
                                             I2A_vooo(nua,noa,noa,noa),&
                                             H2A_vvov(nua,nua,noa,nua),&
                                             I2B_vooo(nua,nob,noa,nob),&
                                             I2B_ovoo(noa,nub,noa,nob),&
                                             H2B_vvov(nua,nub,noa,nub),&
                                             H2B_vvvo(nua,nub,nua,nob),&
                                             fA_oo(noa,noa),fA_vv(nua,nua),&
                                             fB_oo(nob,nob),fB_vv(nub,nub)

                real(kind=8), intent(out) :: t3b_new(nua,nua,nub,noa,noa,nob)

                integer :: a, b, c, i, j, k, ct,&
                           Noo_aa, Noo_ab, Nvv_aa, Nvv_ab, Nov_aa, Nov_bb,&
                           Nov_ab, Nov_ba, Noov_aaa, Noov_abb, Novv_aaa,&
                           Novv_bba, Noov_baa, Noov_bbb, Novv_aab, Novv_bbb
                real(kind=8) :: m1, m2, m3, m4, m5, m6,&
                                d1, d2, d3, d4, d5, d6, d7,&
                                d8, d9, d10, d11, d12, d13, d14,&
                                residual, denom, val, mval
                real(kind=8) :: H2A_voov_r(nua,nua,noa,noa),& ! reorder 1432
                                H2B_voov_r(nua,nub,noa,nob),& ! reorder 1432
                                H2B_ovvo_r(nua,nub,noa,nob),& ! reorder 3214
                                H2C_voov_r(nub,nub,nob,nob),& ! reorder 1432
                                H2B_vovo_r(nua,nua,nob,nob),& ! reorder 1324
                                H2B_ovov_r(nub,nub,noa,noa),& ! reorder 4231
                                vA_oovv_r1(nua,noa,noa,nua),& ! reorder 4123
                                vB_oovv_r1(nub,noa,nob,nua),& ! reorder 4123
                                vA_oovv_r2(nua,nua,noa,noa),& ! reorder 3421
                                vB_oovv_r2(nua,nub,nob,noa),& ! reorder 3421
                                vB_oovv_r3(nua,noa,nob,nub),& ! reorder 3124
                                vC_oovv_r1(nub,nob,nob,nub),& ! reorder 3124
                                vB_oovv_r4(nua,nub,noa,nob),& ! reorder 3412
                                vC_oovv_r2(nub,nub,nob,nob),& ! reorder 4321
                                temp1a(nua),temp1b(nua),&
                                temp2a(noa),temp2b(noa),&
                                temp3a(nub),temp3b(nub),&
                                temp4a(nob),temp4b(nob),&
                                vt3_oa(noa),vt3_ua(nua),vt3_ob(nob),vt3_ub(nub)


                real(kind=8), parameter :: MINUSONE=-1.0d+0, HALF=0.5d+0, ZERO=0.0d+0,&
                                           MINUSHALF=-0.5d+0, ONE=1.0d+0

                real(kind=8), external :: ddot

                !integer :: m, n, e, f
                !real(kind=8) :: error(20), refval

                call mkl_set_num_threads_local(mkl_num_threads)
                call omp_set_num_threads(omp_num_threads)

                Noo_aa = noa*noa
                Noo_ab = noa*nob
                Nvv_aa = nua*nua
                Nvv_ab = nua*nub
                Nov_aa = noa*nua
                Nov_bb = nob*nub
                Nov_ab = noa*nub
                Nov_ba = nob*nua
                Noov_aaa = noa*noa*nua
                Noov_abb = noa*nob*nub
                Novv_aaa = noa*nua*nua
                Novv_bba = nob*nub*nua 
                Noov_baa = nob*noa*nua
                Noov_bbb = nob*nob*nub
                Novv_aab = noa*nua*nub
                Novv_bbb = nob*nub*nub

                call reorder1432(H2A_voov,H2A_voov_r)
                call reorder1432(H2B_voov,H2B_voov_r)
                call reorder3214(H2B_ovvo,H2B_ovvo_r)
                call reorder1432(H2C_voov,H2C_voov_r)
                call reorder1324(H2B_vovo,H2B_vovo_r)
                call reorder4231(H2B_ovov,H2B_ovov_r)
                call reorder4123(vA_oovv,vA_oovv_r1)
                call reorder4123(vB_oovv,vB_oovv_r1)
                call reorder3421(vA_oovv,vA_oovv_r2)
                call reorder3421(vB_oovv,vB_oovv_r2)
                call reorder3124(vB_oovv,vB_oovv_r3)
                call reorder3124(vC_oovv,vC_oovv_r1)
                call reorder3412(vB_oovv,vB_oovv_r4)
                call reorder4321(vC_oovv,vC_oovv_r2)

                !do i = 1,20
                !   error(i) = ZERO
                !end do

                t3b_new = 0.0d0

                !$OMP PARALLEL SHARED(t3b_new)
                !$OMP DO
                do ct = 1 , num_triples
            
                   ! Shift indices up by since the triples list is coming from
                   ! Python, where indices start from 0       
                   a = triples_list(ct,1)+1
                   b = triples_list(ct,2)+1
                   c = triples_list(ct,3)+1
                   i = triples_list(ct,4)+1
                   j = triples_list(ct,5)+1
                   k = triples_list(ct,6)+1
                    
                   ! Calculate devectorized residual for triple |ijk~abc~>
                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3b(b,:,c,:,:,k),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r1,Noov_abb,t3c(b,:,c,:,:,k),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m1 = ddot(nua,H2B_vvvo(b,c,:,k)-vt3_ua,1,t2a(a,:,i,j),1)
                    
                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3b(a,:,c,:,:,k),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r1,Noov_abb,t3c(a,:,c,:,:,k),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m1 = m1 - ddot(nua,H2B_vvvo(a,c,:,k)-vt3_ua,1,t2a(b,:,i,j),1)

                   !refval = ZERO
                   !do e = 1,nua                    
                   !   do f = 1,nua
                   !      do m = 1,noa
                   !         do n = m+1,noa
                   !            refval = refval -&
                   !            vA_oovv(m,n,e,f)*t3b(b,f,c,m,n,k)*t2a(a,e,i,j)+&
                   !            vA_oovv(m,n,e,f)*t3b(a,f,c,m,n,k)*t2a(b,e,i,j)
                   !         end do
                   !      end do
                   !   end do
                   !   do f = 1,nub
                   !      do m = 1,noa
                   !         do n = 1,nob
                   !            refval = refval -&
                   !            vB_oovv(m,n,e,f)*t3c(b,f,c,m,n,k)*t2a(a,e,i,j)+&
                   !            vB_oovv(m,n,e,f)*t3c(a,f,c,m,n,k)*t2a(b,e,i,j)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval + H2B_vvvo(b,c,e,k)*t2a(a,e,i,j)&
                   !                   - H2B_vvvo(a,c,e,k)*t2a(b,e,i,j)
                   !end do
                   !error(1) = error(1) + (m1 - refval)

                  call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3b(:,:,c,i,:,k),1,ZERO,temp2a,1)
                  call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r2,Novv_bba,t3c(:,:,c,i,:,k),1,ZERO,temp2b,1)
                  vt3_oa = temp2a + temp2b
                  m2 = MINUSONE*ddot(noa,I2B_ovoo(:,c,i,k)+vt3_oa,1,t2a(a,b,:,j),1)

                  call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3b(:,:,c,j,:,k),1,ZERO,temp2a,1)
                  call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r2,Novv_bba,t3c(:,:,c,j,:,k),1,ZERO,temp2b,1)
                  vt3_oa = temp2a + temp2b
                  m2 = m2 + ddot(noa,I2B_ovoo(:,c,j,k)+vt3_oa,1,t2a(a,b,:,i),1)

                  !refval = ZERO
                  !do m = 1,noa
                  !   do f = 1,nua
                  !      do e = f+1,nua
                  !         do n = 1,noa
                  !            refval = refval -&
                  !            vA_oovv(m,n,e,f)*t3b(e,f,c,i,n,k)*t2a(a,b,m,j)+&
                  !            vA_oovv(m,n,e,f)*t3b(e,f,c,j,n,k)*t2a(a,b,m,i)
                  !         end do
                  !      end do
                  !  end do
                  !  do f = 1,nub
                  !     do e = 1,nua
                  !        do n = 1,nob
                  !           refval = refval -&
                  !           vB_oovv(m,n,e,f)*t3c(e,f,c,i,n,k)*t2a(a,b,m,j)+&
                  !           vB_oovv(m,n,e,f)*t3c(e,f,c,j,n,k)*t2a(a,b,m,i)
                  !        end do
                  !      end do
                  !  end do
                  !  refval = refval - I2B_ovoo(m,c,i,k)*t2a(a,b,m,j)&
                  !                  + I2B_ovoo(m,c,j,k)*t2a(a,b,m,i)
                  !end do
                  !error(2) = error(2) + (m2-refval)

                  call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r3,Noov_baa,t3b(a,:,c,i,:,:),1,ZERO,temp3a,1)
                  call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r1,Noov_bbb,t3c(a,:,c,i,:,:),1,ZERO,temp3b,1)
                  vt3_ub = temp3a + temp3b
                  m3 = ddot(nub,H2B_vvov(a,c,i,:)-vt3_ub,1,t2b(b,:,j,k),1)
                  
                  call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r3,Noov_baa,t3b(b,:,c,i,:,:),1,ZERO,temp3a,1)
                  call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r1,Noov_bbb,t3c(b,:,c,i,:,:),1,ZERO,temp3b,1)
                  vt3_ub = temp3a + temp3b
                  m3 = m3 - ddot(nub,H2B_vvov(b,c,i,:)-vt3_ub,1,t2b(a,:,j,k),1)

                  call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r3,Noov_baa,t3b(a,:,c,j,:,:),1,ZERO,temp3a,1)
                  call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r1,Noov_bbb,t3c(a,:,c,j,:,:),1,ZERO,temp3b,1)
                  vt3_ub = temp3a + temp3b
                  m3 = m3 - ddot(nub,H2B_vvov(a,c,j,:)-vt3_ub,1,t2b(b,:,i,k),1)

                  call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r3,Noov_baa,t3b(b,:,c,j,:,:),1,ZERO,temp3a,1)
                  call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r1,Noov_bbb,t3c(b,:,c,j,:,:),1,ZERO,temp3b,1)
                  vt3_ub = temp3a + temp3b
                  m3 = m3 + ddot(nub,H2B_vvov(b,c,j,:)-vt3_ub,1,t2b(a,:,i,k),1)

                  !refval = ZERO
                  !do e = 1,nub
                  !   do f = 1,nua
                  !      do m = 1,nob
                  !         do n = 1,noa
                  !            refval = refval -&
                  !            vB_oovv(n,m,f,e)*t3b(a,f,c,i,n,m)*t2b(b,e,j,k)+&
                  !            vB_oovv(n,m,f,e)*t3b(b,f,c,i,n,m)*t2b(a,e,j,k)+&
                  !            vB_oovv(n,m,f,e)*t3b(a,f,c,j,n,m)*t2b(b,e,i,k)-&
                  !            vB_oovv(n,m,f,e)*t3b(b,f,c,j,n,m)*t2b(a,e,i,k)
                  !         end do
                  !      end do
                  !   end do
                  !   do f = 1,nub
                  !      do m = 1,nob
                  !         do n = m+1,nob
                  !            refval = refval -&
                  !            vC_oovv(n,m,f,e)*t3c(a,f,c,i,n,m)*t2b(b,e,j,k)+&
                  !            vC_oovv(n,m,f,e)*t3c(b,f,c,i,n,m)*t2b(a,e,j,k)+&
                  !            vC_oovv(n,m,f,e)*t3c(a,f,c,j,n,m)*t2b(b,e,i,k)-&
                  !            vC_oovv(n,m,f,e)*t3c(b,f,c,j,n,m)*t2b(a,e,i,k)
                  !         end do
                  !      end do
                  !   end do
                  !   refval = refval + H2B_vvov(a,c,i,e)*t2b(b,e,j,k)&
                  !                   - H2B_vvov(b,c,i,e)*t2b(a,e,j,k)&
                  !                   - H2B_vvov(a,c,j,e)*t2b(b,e,i,k)&
                  !                   + H2B_vvov(b,c,j,e)*t2b(a,e,i,k)
                  !end do
                  !error(3) = error(3) + (m3-refval)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r4,Novv_aab,t3b(b,:,:,j,:,k),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r2,Novv_bbb,t3c(b,:,:,j,:,k),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m4 = MINUSONE*ddot(nob,I2B_vooo(b,:,j,k)+vt3_ob,1,t2b(a,c,i,:),1)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r4,Novv_aab,t3b(a,:,:,j,:,k),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r2,Novv_bbb,t3c(a,:,:,j,:,k),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m4 = m4 + ddot(nob,I2B_vooo(a,:,j,k)+vt3_ob,1,t2b(b,c,i,:),1)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r4,Novv_aab,t3b(b,:,:,i,:,k),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r2,Novv_bbb,t3c(b,:,:,i,:,k),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m4 = m4 + ddot(nob,I2B_vooo(b,:,i,k)+vt3_ob,1,t2b(a,c,j,:),1)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r4,Novv_aab,t3b(a,:,:,i,:,k),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r2,Novv_bbb,t3c(a,:,:,i,:,k),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m4 = m4 - ddot(nob,I2B_vooo(a,:,i,k)+vt3_ob,1,t2b(b,c,j,:),1)

                   !refval = ZERO
                   !do m = 1,nob
                   !   do f = 1,nua
                   !      do e = 1,nub
                   !         do n = 1,noa
                   !            refval = refval -&
                   !            vB_oovv(n,m,f,e)*t3b(b,f,e,j,n,k)*t2b(a,c,i,m)+&
                   !            vB_oovv(n,m,f,e)*t3b(a,f,e,j,n,k)*t2b(b,c,i,m)+&
                   !            vB_oovv(n,m,f,e)*t3b(b,f,e,i,n,k)*t2b(a,c,j,m)-&
                   !            vB_oovv(n,m,f,e)*t3b(a,f,e,i,n,k)*t2b(b,c,j,m)
                   !         end do
                   !      end do
                   !   end do
                   !   do f = 1,nub
                   !      do e = f+1,nub
                   !         do n = 1,nob
                   !            refval = refval -&
                   !            vC_oovv(m,n,e,f)*t3c(b,f,e,j,n,k)*t2b(a,c,i,m)+&
                   !            vC_oovv(m,n,e,f)*t3c(a,f,e,j,n,k)*t2b(b,c,i,m)+&
                   !            vC_oovv(m,n,e,f)*t3c(b,f,e,i,n,k)*t2b(a,c,j,m)-&
                   !            vC_oovv(m,n,e,f)*t3c(a,f,e,i,n,k)*t2b(b,c,j,m)
                   !         end do
                   !       end do
                   !   end do
                   !   refval = refval - I2B_vooo(b,m,j,k)*t2b(a,c,i,m)&
                   !                   + I2B_vooo(a,m,j,k)*t2b(b,c,i,m)&
                   !                   + I2B_vooo(b,m,i,k)*t2b(a,c,j,m)&
                   !                   - I2B_vooo(a,m,i,k)*t2b(b,c,j,m)
                   !end do
                   !error(4) = error(4) + (m4-refval)

                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3a(a,b,:,i,:,:),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r1,Noov_abb,t3b(a,b,:,i,:,:),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m5 = ddot(nua,H2A_vvov(a,b,i,:)-vt3_ua,1,t2b(:,c,j,k),1)

                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3a(a,b,:,j,:,:),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r1,Noov_abb,t3b(a,b,:,j,:,:),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m5 = m5 - ddot(nua,H2A_vvov(a,b,j,:)-vt3_ua,1,t2b(:,c,i,k),1)

                   !refval = ZERO
                   !do e = 1,nua
                   !   do f = 1,nua
                   !      do m = 1,noa
                   !         do n = m+1,noa
                   !            refval = refval -&
                   !            vA_oovv(m,n,e,f)*t3a(a,b,f,i,m,n)*t2b(e,c,j,k)+&
                   !            vA_oovv(m,n,e,f)*t3a(a,b,f,j,m,n)*t2b(e,c,i,k)
                   !         end do
                   !      end do
                   !   end do
                   !   do f = 1,nub
                   !      do m = 1,noa
                   !         do n = 1,nob
                   !            refval = refval -&
                   !            vB_oovv(m,n,e,f)*t3b(a,b,f,i,m,n)*t2b(e,c,j,k)+&
                   !            vB_oovv(m,n,e,f)*t3b(a,b,f,j,m,n)*t2b(e,c,i,k)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval + H2A_vvov(a,b,i,e)*t2b(e,c,j,k)&
                   !                   - H2A_vvov(a,b,j,e)*t2b(e,c,i,k)
                   ! end do
                   ! error(5) = error(5) + (m5-refval)

                   call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3a(a,:,:,i,j,:),1,ZERO,temp2a,1)
                   call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r2,Novv_bba,t3b(a,:,:,i,j,:),1,ZERO,temp2b,1)
                   vt3_oa = temp2a + temp2b
                   m6 = MINUSONE*ddot(noa,I2A_vooo(a,:,i,j)+vt3_oa,1,t2b(b,c,:,k),1)

                   call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3a(b,:,:,i,j,:),1,ZERO,temp2a,1)
                   call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r2,Novv_bba,t3b(b,:,:,i,j,:),1,ZERO,temp2b,1)
                   vt3_oa = temp2a + temp2b
                   m6 = m6 + ddot(noa,I2A_vooo(b,:,i,j)+vt3_oa,1,t2b(a,c,:,k),1)

                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      do f = e+1,nua
                   !         do n = 1,noa
                   !            refval = refval -&
                   !            vA_oovv(m,n,e,f)*t3a(a,e,f,i,j,n)*t2b(b,c,m,k)+&
                   !            vA_oovv(m,n,e,f)*t3a(b,e,f,i,j,n)*t2b(a,c,m,k)
                   !         end do
                   !      end do
                   !   end do
                   !   do e = 1,nua
                   !      do f = 1,nub
                   !         do n = 1,nob
                   !            refval = refval -&
                   !            vB_oovv(m,n,e,f)*t3b(a,e,f,i,j,n)*t2b(b,c,m,k)+&
                   !            vB_oovv(m,n,e,f)*t3b(b,e,f,i,j,n)*t2b(a,c,m,k)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval - I2A_vooo(a,m,i,j)*t2b(b,c,m,k)&
                   !                   + I2A_vooo(b,m,i,j)*t2b(a,c,m,k)
                   ! end do
                   ! error(6) = error(6) + (m6-refval)

                   d1 = MINUSONE*ddot(noa,H1A_oo(:,i),1,t3b(a,b,c,:,j,k),1)
                   d1 = d1 + ddot(noa,H1A_oo(:,j),1,t3b(a,b,c,:,i,k),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   refval = refval - H1A_oo(m,i)*t3b(a,b,c,m,j,k)&
                   !                   + H1A_oo(m,j)*t3b(a,b,c,m,i,k)
                   !end do
                   !error(7) = error(7) + (d1-refval)
    
                   d2 = MINUSONE*ddot(nob,H1B_oo(:,k),1,t3b(a,b,c,i,j,:),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   refval = refval - H1B_oo(m,k)*t3b(a,b,c,i,j,m)
                   !end do
                   !error(8) = error(8) + (d2-refval)

                   d3 = ddot(nua,H1A_vv(a,:),1,t3b(:,b,c,i,j,k),1)
                   d3 = d3 - ddot(nua,H1A_vv(b,:),1,t3b(:,a,c,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   refval = refval + H1A_vv(a,e)*t3b(e,b,c,i,j,k)&
                   !                   - H1A_vv(b,e)*t3b(e,a,c,i,j,k)
                   !end do
                   !error(9) = error(9) + (d3-refval)

                   d4 = ddot(nub,H1B_vv(c,:),1,t3b(a,b,:,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nub
                   !   refval = refval + H1B_vv(c,e)*t3b(a,b,e,i,j,k)
                   !end do
                   !error(10) = error(10) + (d4-refval)

                   d5 = HALF*ddot(Noo_aa,H2A_oooo(:,:,i,j),1,t3b(a,b,c,:,:,k),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do n = m+1,noa
                   !      refval = refval + H2A_oooo(m,n,i,j)*t3b(a,b,c,m,n,k)
                   !   end do
                   !end do
                   !error(11) = error(11) + (d5-refval)

                   d6 = ddot(Noo_ab,H2B_oooo(:,:,j,k),1,t3b(a,b,c,i,:,:),1)
                   d6 = d6 - ddot(Noo_ab,H2B_oooo(:,:,i,k),1,t3b(a,b,c,j,:,:),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do n = 1,nob 
                   !      refval = refval + H2B_oooo(m,n,j,k)*t3b(a,b,c,i,m,n)&
                   !                      - H2B_oooo(m,n,i,k)*t3b(a,b,c,j,m,n)
                   !   end do
                   !end do
                   !error(12) = error(12) + (d6-refval)

                   d7 = HALF*ddot(Nvv_aa,H2A_vvvv(a,b,:,:),1,t3b(:,:,c,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   do f = e+1,nua
                   !      refval = refval + H2A_vvvv(a,b,e,f)*t3b(e,f,c,i,j,k)
                   !   end do
                   !end do
                   !error(13) = error(13) + (d7-refval)

                   d8 = ddot(Nvv_ab,H2B_vvvv(b,c,:,:),1,t3b(a,:,:,i,j,k),1)
                   d8 = d8 - ddot(Nvv_ab,H2B_vvvv(a,c,:,:),1,t3b(b,:,:,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   do f = 1,nub
                   !      refval = refval + H2B_vvvv(b,c,e,f)*t3b(a,e,f,i,j,k)&
                   !                      - H2B_vvvv(a,c,e,f)*t3b(b,e,f,i,j,k)
                   !   end do
                   !end do
                   !error(14) = error(14) + (d8-refval)

                   d9 = ddot(Nov_aa,H2A_voov_r(a,:,i,:),1,t3b(:,b,c,:,j,k),1)
                   d9 = d9 - ddot(Nov_aa,H2A_voov_r(b,:,i,:),1,t3b(:,a,c,:,j,k),1)
                   d9 = d9 - ddot(Nov_aa,H2A_voov_r(a,:,j,:),1,t3b(:,b,c,:,i,k),1)
                   d9 = d9 + ddot(Nov_aa,H2A_voov_r(b,:,j,:),1,t3b(:,a,c,:,i,k),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      refval = refval + H2A_voov(a,m,i,e)*t3b(e,b,c,m,j,k)&
                   !                      - H2A_voov(b,m,i,e)*t3b(e,a,c,m,j,k)&
                   !                      - H2A_voov(a,m,j,e)*t3b(e,b,c,m,i,k)&
                   !                      + H2A_voov(b,m,j,e)*t3b(e,a,c,m,i,k)
                   !   end do
                   !end do
                   !error(15) = error(15) + (d9-refval)
    
                   d10 = ddot(Nov_bb,H2B_voov_r(a,:,i,:),1,t3c(b,:,c,j,:,k),1)
                   d10 = d10 - ddot(Nov_bb,H2B_voov_r(b,:,i,:),1,t3c(a,:,c,j,:,k),1)
                   d10 = d10 - ddot(Nov_bb,H2B_voov_r(a,:,j,:),1,t3c(b,:,c,i,:,k),1)
                   d10 = d10 + ddot(Nov_bb,H2B_voov_r(b,:,j,:),1,t3c(a,:,c,i,:,k),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do e = 1,nub
                   !      refval = refval + H2B_voov(a,m,i,e)*t3c(b,e,c,j,m,k)&
                   !                      - H2B_voov(b,m,i,e)*t3c(a,e,c,j,m,k)&
                   !                      - H2B_voov(a,m,j,e)*t3c(b,e,c,i,m,k)&
                   !                      + H2B_voov(b,m,j,e)*t3c(a,e,c,i,m,k)
                   !   end do
                   !end do
                   !error(16) = error(16) + (d10-refval)

                   d11 = ddot(Nov_aa,H2B_ovvo_r(:,c,:,k),1,t3a(a,b,:,i,j,:),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      refval = refval + H2B_ovvo(m,c,e,k)*t3a(a,b,e,i,j,m)
                   !   end do
                   !end do
                   !error(17) = error(17) + (d11-refval)

                   d12 = ddot(Nov_bb,H2C_voov_r(c,:,k,:),1,t3b(a,b,:,i,j,:),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do e = 1,nub
                   !      refval = refval + H2C_voov(c,m,k,e)*t3b(a,b,e,i,j,m)
                   !   end do
                   !end do
                   !error(18) = error(18) + (d12-refval)

                   d13 = MINUSONE*ddot(Nov_ba,H2B_vovo_r(a,:,:,k),1,t3b(:,b,c,i,j,:),1)
                   d13 = d13 + ddot(Nov_ba,H2B_vovo_r(b,:,:,k),1,t3b(:,a,c,i,j,:),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do e = 1,nua
                   !      refval = refval - H2B_vovo(a,m,e,k)*t3b(e,b,c,i,j,m)&
                   !                      + H2B_vovo(b,m,e,k)*t3b(e,a,c,i,j,m)
                   !   end do
                   !end do
                   !error(19) = error(19) + (d13-refval)
                   
                   d14 = MINUSONE*ddot(Nov_ab,H2B_ovov_r(:,c,i,:),1,t3b(a,b,:,:,j,k),1)
                   d14 = d14 + ddot(Nov_ab,H2B_ovov_r(:,c,j,:),1,t3b(a,b,:,:,i,k),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nub
                   !      refval = refval - H2B_ovov(m,c,i,e)*t3b(a,b,e,m,j,k)&
                   !                      + H2B_ovov(m,c,j,e)*t3b(a,b,e,m,i,k)
                   !   end do
                   !end do
                   !error(20) = error(20) + (d14-refval)

                   residual = d1+d2+d3+d4+d5+d6+d7+d8+d9+d10+&
                   d11+d12+d13+d14+m1+m2+m3+m4+m5+m6
                   denom = fA_oo(i,i) + fA_oo(j,j) + fB_oo(k,k)&
                          -fA_vv(a,a) - fA_vv(b,b) - fB_vv(c,c)
                   val = t3b(a,b,c,i,j,k) + residual/denom
                   mval = MINUSONE*val

                   t3b_new(a,b,c,i,j,k) = val
                   t3b_new(b,a,c,i,j,k) = mval
                   t3b_new(a,b,c,j,i,k) = mval
                   t3b_new(b,a,c,j,i,k) = val

               end do
               !$OMP END DO
               !$OMP END PARALLEL

               !do i = 1,20
               !   print*,'Error in term',i,'=',error(i)
               !end do

            end subroutine update_t3b


            subroutine update_t3c(t2b,t2c,&
                         t3b,t3c,t3d,&
                         triples_list,&
                         vA_oovv,vB_oovv,vC_oovv,&
                         H1A_oo,H1A_vv,H1B_oo,H1B_vv,&
                         H2A_voov,&
                         H2B_oooo,H2B_vvvv,H2B_voov,&
                         H2B_ovov,H2B_vovo,H2B_ovvo,&
                         H2C_oooo,H2C_vvvv,H2C_voov,&
                         I2C_vooo,H2C_vvov,&
                         I2B_vooo,I2B_ovoo,H2B_vvov,H2B_vvvo,&
                         fA_oo,fA_vv,fB_oo,fB_vv,shift,&
                         noa,nua,nob,nub,num_triples,t3c_new)

                integer, intent(in) :: noa, nua, nob, nub, num_triples
                real(kind=8), intent(in) :: shift
                integer, intent(in) :: triples_list(num_triples,6)
                real(kind=8), intent(in) ::  t2b(nua,nub,noa,nob),&
                                             t2c(nub,nub,nob,nob),&
                                             t3b(nua,nua,nub,noa,noa,nob),&
                                             t3c(nua,nub,nub,noa,nob,nob),&
                                             t3d(nub,nub,nub,nob,nob,nob),&
                                             vA_oovv(noa,noa,nua,nua),&
                                             vB_oovv(noa,nob,nua,nub),&
                                             vC_oovv(nob,nob,nub,nub),&
                                             H1A_oo(noa,noa),H1A_vv(nua,nua),&
                                             H1B_oo(nob,nob),H1B_vv(nub,nub),&
                                             H2A_voov(nua,noa,noa,nua),&
                                             H2B_oooo(noa,nob,noa,nob),&
                                             H2B_vvvv(nua,nub,nua,nub),&
                                             H2B_voov(nua,nob,noa,nub),&
                                             H2B_ovov(noa,nub,noa,nub),&
                                             H2B_vovo(nua,nob,nua,nob),&
                                             H2B_ovvo(noa,nub,nua,nob),&
                                             H2C_oooo(nob,nob,nob,nob),&
                                             H2C_vvvv(nub,nub,nub,nub),&
                                             H2C_voov(nub,nob,nob,nub),&
                                             I2B_ovoo(noa,nub,noa,nob),&
                                             I2B_vooo(nua,nob,noa,nob),&
                                             I2C_vooo(nub,nob,nob,nob),&
                                             H2B_vvov(nua,nub,noa,nub),&
                                             H2C_vvov(nub,nub,nob,nub),&
                                             H2B_vvvo(nua,nub,nua,nob),&
                                             fA_oo(noa,noa),fA_vv(nua,nua),&
                                             fB_oo(nob,nob),fB_vv(nub,nub)

                real(kind=8), intent(out) :: t3c_new(nua,nub,nub,noa,nob,nob)

                integer :: a, b, c, i, j, k, ct,&
                           Noo_aa, Noo_bb, Nvv_aa, Nvv_bb,&
                           Nov_aa, Nov_bb, Nov_ab, Nov_ba,&
                           Noo_ab, Nvv_ab,&
                           Noov_baa, Noov_bbb, Novv_aab, Novv_bbb,&
                           Noov_aaa, Noov_abb, Novv_aaa, Novv_bba

                real(kind=8) :: m1, m2, m3, m4, m5, m6,&
                                d1, d2, d3, d4, d5, d6, d7,&
                                d8, d9, d10, d11, d12, d13, d14,&
                                residual, denom, val, mval

                real(kind=8) :: H2A_voov_r1(nua,nua,noa,noa),& ! reorder 1432
                                H2B_voov_r1(nua,nub,noa,nob),& ! reorder 1432
                                H2B_ovvo_r1(nua,nub,noa,nob),& ! reorder 3214
                                H2C_voov_r1(nub,nub,nob,nob),& ! reorder 1432
                                H2B_ovov_r1(nub,nub,noa,noa),& ! reorder 4231
                                H2B_vovo_r1(nua,nua,nob,nob),& ! reorder 1324
                                vB_oovv_r1(nua,noa,nob,nub),& ! reorder 3124
                                vC_oovv_r1(nub,nob,nob,nub),& ! reorder 3124
                                vB_oovv_r2(nua,nub,noa,nob),& ! reorder 3412
                                vC_oovv_r2(nub,nub,nob,nob),& ! reorder 3412
                                vC_oovv_r3(nub,nob,nob,nub),& ! reorder 4123
                                vC_oovv_r4(nub,nub,nob,noa),& ! reorder 3421
                                vA_oovv_r1(nua,noa,noa,nua),& ! reorder 4123
                                vB_oovv_r3(nub,noa,nob,nua),& ! reorder 4123
                                vA_oovv_r2(nua,nua,noa,noa),& ! reorder 3421
                                vB_oovv_r4(nua,nub,nob,noa),& ! reorder 3421
                                temp1a(nua),temp1b(nua),&
                                temp2a(noa),temp2b(noa),&
                                temp3a(nub),temp3b(nub),&
                                temp4a(nob),temp4b(nob),&
                                vt3_oa(noa),vt3_ua(nua),vt3_ob(nob),vt3_ub(nub)


                real(kind=8), parameter :: MINUSONE=-1.0d+0, HALF=0.5d+0, ZERO=0.0d+0,&
                                           MINUSHALF=-0.5d+0, ONE=1.0d+0

                real(kind=8), external :: ddot

                !integer :: m, n, e, f
                !real(kind=8) :: error(20), refval

                call mkl_set_num_threads_local(mkl_num_threads)
                call omp_set_num_threads(omp_num_threads)

                Noo_aa = noa*noa
                Noo_ab = noa*nob
                Nvv_aa = nua*nua
                Nvv_ab = nua*nub
                Noo_bb = nob*nob
                Nvv_bb = nub*nub
                Nov_aa = noa*nua
                Nov_bb = nob*nub
                Nov_ab = noa*nub
                Nov_ba = nob*nua
                Noov_baa = nob*noa*nua
                Noov_bbb = nob*nob*nub
                Novv_aab = noa*nua*nub
                Novv_bbb = nob*nub*nub
                Noov_aaa = noa*noa*nua
                Noov_abb = noa*nob*nub
                Novv_aaa = noa*nua*nua
                Novv_bba = nob*nub*nua

                call reorder1432(H2A_voov,H2A_voov_r1)
                call reorder1432(H2B_voov,H2B_voov_r1)
                call reorder3214(H2B_ovvo,H2B_ovvo_r1)
                call reorder1432(H2C_voov,H2C_voov_r1)
                call reorder4231(H2B_ovov,H2B_ovov_r1)
                call reorder1324(H2B_vovo,H2B_vovo_r1)
                call reorder3124(vB_oovv,vB_oovv_r1)
                call reorder3124(vC_oovv,vC_oovv_r1)
                call reorder3412(vB_oovv,vB_oovv_r2)
                call reorder3412(vC_oovv,vC_oovv_r2)
                call reorder4123(vC_oovv,vC_oovv_r3)
                call reorder3421(vC_oovv,vC_oovv_r4)
                call reorder4123(vA_oovv,vA_oovv_r1)
                call reorder4123(vB_oovv,vB_oovv_r3)
                call reorder3421(vA_oovv,vA_oovv_r2)
                call reorder3421(vB_oovv,vB_oovv_r4)

                !do i = 1,20
                !   error(i) = ZERO
                !end do

                t3c_new = 0.0d0

                !$OMP PARALLEL SHARED(t3c_new)
                !$OMP DO
                do ct = 1 , num_triples
                   
                   ! Shift indices up by 1 since the triples list is coming from
                   ! Python, where indices start from 0       
                   a = triples_list(ct,1)+1
                   b = triples_list(ct,2)+1
                   c = triples_list(ct,3)+1
                   i = triples_list(ct,4)+1
                   j = triples_list(ct,5)+1
                   k = triples_list(ct,6)+1

                   ! calculate devectorized residual for triple |ij~k~ab~c~>
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r1,Noov_baa,t3b(a,:,b,i,:,:),1,ZERO,temp3a,1)
                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r1,Noov_bbb,t3c(a,:,b,i,:,:),1,ZERO,temp3b,1)
                   vt3_ub = temp3a + temp3b
                   m1 = ddot(nub,H2B_vvov(a,b,i,:)-vt3_ub,1,t2c(:,c,j,k),1)

                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r1,Noov_baa,t3b(a,:,c,i,:,:),1,ZERO,temp3a,1)
                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r1,Noov_bbb,t3c(a,:,c,i,:,:),1,ZERO,temp3b,1)
                   vt3_ub = temp3a + temp3b
                   m1 = m1 - ddot(nub,H2B_vvov(a,c,i,:)-vt3_ub,1,t2c(:,b,j,k),1)

                    !refval = ZERO
                    !do e = 1,nub
                    !  do f = 1,nua
                    !     do n = 1,noa
                    !        do m = 1,nob
                    !           refval = refval -&
                    !           vB_oovv(n,m,f,e)*t3b(a,f,b,i,n,m)*t2c(e,c,j,k)+&
                    !           vB_oovv(n,m,f,e)*t3b(a,f,c,i,n,m)*t2c(e,b,j,k)
                    !        end do
                    !     end do
                    !  end do
                    !  do f = 1,nub
                    !     do n = 1,nob
                    !        do m = n+1,nob
                    !           refval = refval -&
                    !           vC_oovv(n,m,f,e)*t3c(a,f,b,i,n,m)*t2c(e,c,j,k)+&
                    !           vC_oovv(n,m,f,e)*t3c(a,f,c,i,n,m)*t2c(e,b,j,k)
                    !        end do
                    !     end do
                    !  end do
                    !  refval = refval + H2B_vvov(a,b,i,e)*t2c(e,c,j,k)&
                    !                  - H2B_vvov(a,c,i,e)*t2c(e,b,j,k)
                    !end do
                    !error(1) = error(1) + (m1-refval)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r2,Novv_aab,t3b(a,:,:,i,:,j),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r2,Novv_bbb,t3c(a,:,:,i,:,j),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m2 = MINUSONE*ddot(nob,I2B_vooo(a,:,i,j)+vt3_ob,1,t2c(b,c,:,k),1)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r2,Novv_aab,t3b(a,:,:,i,:,k),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r2,Novv_bbb,t3c(a,:,:,i,:,k),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m2 = m2 + ddot(nob,I2B_vooo(a,:,i,k)+vt3_ob,1,t2c(b,c,:,j),1)

                  ! refval = ZERO
                  ! do m = 1,nob
                  !    do f = 1,nua
                  !       do e = 1,nub
                  !          do n = 1,noa
                  !             refval = refval -&
                  !             vB_oovv(n,m,f,e)*t3b(a,f,e,i,n,j)*t2c(b,c,m,k)+&
                  !             vB_oovv(n,m,f,e)*t3b(a,f,e,i,n,k)*t2c(b,c,m,j)
                  !          end do
                  !        end do
                  !     end do
                  !     do f = 1,nub
                  !        do e = f+1,nub
                  !           do n = 1,nob
                  !              refval = refval -&
                  !              vC_oovv(n,m,f,e)*t3c(a,f,e,i,n,j)*t2c(b,c,m,k)+&
                  !              vC_oovv(n,m,f,e)*t3c(a,f,e,i,n,k)*t2c(b,c,m,j)
                  !           end do
                  !        end do
                  !     end do
                  !     refval = refval - I2B_vooo(a,m,i,j)*t2c(b,c,m,k)&
                  !                     + I2B_vooo(a,m,i,k)*t2c(b,c,m,j)
                  !  end do
                  !  error(2) = error(2) + (m2-refval)


                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r3,Noov_bbb,t3d(c,b,:,k,:,:),1,ZERO,temp3a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r1,Noov_baa,t3c(:,c,b,:,k,:),1,ZERO,temp3b,1)
                   vt3_ub = temp3a + temp3b
                   m3 = ddot(nub,H2C_vvov(c,b,k,:)-vt3_ub,1,t2b(a,:,i,j),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r3,Noov_bbb,t3d(c,b,:,j,:,:),1,ZERO,temp3a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r1,Noov_baa,t3c(:,c,b,:,j,:),1,ZERO,temp3b,1)
                   vt3_ub = temp3a + temp3b
                   m3 = m3 - ddot(nub,H2C_vvov(c,b,j,:)-vt3_ub,1,t2b(a,:,i,k),1)

                   !refval = ZERO
                   !do e = 1,nub
                   !   do f = 1,nub
                   !      do m = 1,nob
                   !         do n = m+1,nob
                   !            refval = refval -&
                   !            vC_oovv(m,n,e,f)*t3d(c,b,f,k,m,n)*t2b(a,e,i,j)+&
                   !            vC_oovv(m,n,e,f)*t3d(c,b,f,j,m,n)*t2b(a,e,i,k)
                   !         end do
                   !       end do
                   !    end do
                   !    do f = 1,nua
                   !       do m = 1,nob
                   !          do n = 1,noa
                   !             refval = refval -&
                   !             vB_oovv(n,m,f,e)*t3c(f,c,b,n,k,m)*t2b(a,e,i,j)+&
                   !             vB_oovv(n,m,f,e)*t3c(f,c,b,n,j,m)*t2b(a,e,i,k)
                   !          end do
                   !       end do
                   !     end do
                   !     refval = refval + H2C_vvov(c,b,k,e)*t2b(a,e,i,j)&
                   !                     - H2C_vvov(c,b,j,e)*t2b(a,e,i,k)
                   !    end do
                   !  error(3) = error(3) + (m3-refval)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r2,Novv_aab,t3c(:,c,:,:,k,j),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r4,Novv_bbb,t3d(c,:,:,k,j,:),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m4 = MINUSONE*ddot(nob,I2C_vooo(c,:,k,j)+vt3_ob,1,t2b(a,b,i,:),1)

                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r2,Novv_aab,t3c(:,b,:,:,k,j),1,ZERO,temp4a,1)
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r4,Novv_bbb,t3d(b,:,:,k,j,:),1,ZERO,temp4b,1)
                   vt3_ob = temp4a + temp4b
                   m4 = m4 + ddot(nob,I2C_vooo(b,:,k,j)+vt3_ob,1,t2b(a,c,i,:),1)

                   !refval = ZERO
                   !do m = 1,nob
                   !    do f = 1,nua
                   !      do e = 1,nub
                   !         do n = 1,noa
                   !            refval = refval -&
                   !            vB_oovv(n,m,f,e)*t3c(f,c,e,n,k,j)*t2b(a,b,i,m)+&
                   !            vB_oovv(n,m,f,e)*t3c(f,b,e,n,k,j)*t2b(a,c,i,m)
                   !         end do
                   !      end do
                   !    end do
                   !    do f = 1,nub
                   !       do e = f+1,nub
                   !          do n = 1,nob
                   !             refval = refval -&
                   !             vC_oovv(m,n,e,f)*t3d(c,e,f,k,j,n)*t2b(a,b,i,m)+&
                   !             vC_oovv(m,n,e,f)*t3d(b,e,f,k,j,n)*t2b(a,c,i,m)
                   !          end do
                   !       end do
                   !    end do
                   !    refval = refval - I2C_vooo(c,m,k,j)*t2b(a,b,i,m)&
                   !                    + I2C_vooo(b,m,k,j)*t2b(a,c,i,m)
                   ! end do
                   ! error(4) = error(4) + (m4-refval)

                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3b(a,:,b,:,:,j),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r3,Noov_abb,t3c(a,:,b,:,:,j),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m5 = ddot(nua,H2B_vvvo(a,b,:,j)-vt3_ua,1,t2b(:,c,i,k),1)

                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3b(a,:,c,:,:,j),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r3,Noov_abb,t3c(a,:,c,:,:,j),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m5 = m5 - ddot(nua,H2B_vvvo(a,c,:,j)-vt3_ua,1,t2b(:,b,i,k),1)

                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3b(a,:,b,:,:,k),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r3,Noov_abb,t3c(a,:,b,:,:,k),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m5 = m5 - ddot(nua,H2B_vvvo(a,b,:,k)-vt3_ua,1,t2b(:,c,i,j),1)

                   call dgemv('t',Noov_aaa,nua,HALF,vA_oovv_r1,Noov_aaa,t3b(a,:,c,:,:,k),1,ZERO,temp1a,1)
                   call dgemv('t',Noov_abb,nua,ONE,vB_oovv_r3,Noov_abb,t3c(a,:,c,:,:,k),1,ZERO,temp1b,1)
                   vt3_ua = temp1a + temp1b
                   m5 = m5 + ddot(nua,H2B_vvvo(a,c,:,k)-vt3_ua,1,t2b(:,b,i,j),1)

                   !refval = ZERO
                   !do e = 1,nua
                   !   do f = 1,nua
                   !      do m = 1,noa
                   !         do n = m+1,noa
                   !            refval = refval -&
                   !            vA_oovv(m,n,e,f)*t3b(a,f,b,m,n,j)*t2b(e,c,i,k)+&
                   !            vA_oovv(m,n,e,f)*t3b(a,f,c,m,n,j)*t2b(e,b,i,k)+&
                   !            vA_oovv(m,n,e,f)*t3b(a,f,b,m,n,k)*t2b(e,c,i,j)-&
                   !            vA_oovv(m,n,e,f)*t3b(a,f,c,m,n,k)*t2b(e,b,i,j)
                   !         end do
                   !      end do
                   !    end do
                   !    do f = 1,nub
                   !       do m = 1,noa
                   !          do n = 1,nob
                   !             refval = refval -&
                   !             vB_oovv(m,n,e,f)*t3c(a,f,b,m,n,j)*t2b(e,c,i,k)+&
                   !             vB_oovv(m,n,e,f)*t3c(a,f,c,m,n,j)*t2b(e,b,i,k)+&
                   !             vB_oovv(m,n,e,f)*t3c(a,f,b,m,n,k)*t2b(e,c,i,j)-&
                   !             vB_oovv(m,n,e,f)*t3c(a,f,c,m,n,k)*t2b(e,b,i,j)
                   !          end do
                   !       end do
                   !     end do
                   !     refval = refval + H2B_vvvo(a,b,e,j)*t2b(e,c,i,k)&
                   !                     - H2B_vvvo(a,c,e,j)*t2b(e,b,i,k)&
                   !                     - H2B_vvvo(a,b,e,k)*t2b(e,c,i,j)&
                   !                     + H2B_vvvo(a,c,e,k)*t2b(e,b,i,j)
                   ! end do
                   ! error(5) = error(5) + (m5-refval)

                   call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3b(:,:,b,i,:,j),1,ZERO,temp2a,1)
                   call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r4,Novv_bba,t3c(:,:,b,i,:,j),1,ZERO,temp2b,1)
                   vt3_oa = temp2a + temp2b
                   m6 = MINUSONE*ddot(noa,I2B_ovoo(:,b,i,j)+vt3_oa,1,t2b(a,c,:,k),1)

                   call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3b(:,:,c,i,:,j),1,ZERO,temp2a,1)
                   call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r4,Novv_bba,t3c(:,:,c,i,:,j),1,ZERO,temp2b,1)
                   vt3_oa = temp2a + temp2b
                   m6 = m6 + ddot(noa,I2B_ovoo(:,c,i,j)+vt3_oa,1,t2b(a,b,:,k),1)

                   call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3b(:,:,b,i,:,k),1,ZERO,temp2a,1)
                   call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r4,Novv_bba,t3c(:,:,b,i,:,k),1,ZERO,temp2b,1)
                   vt3_oa = temp2a + temp2b
                   m6 = m6 + ddot(noa,I2B_ovoo(:,b,i,k)+vt3_oa,1,t2b(a,c,:,j),1)

                   call dgemv('t',Novv_aaa,noa,HALF,vA_oovv_r2,Novv_aaa,t3b(:,:,c,i,:,k),1,ZERO,temp2a,1)
                   call dgemv('t',Novv_bba,noa,ONE,vB_oovv_r4,Novv_bba,t3c(:,:,c,i,:,k),1,ZERO,temp2b,1)
                   vt3_oa = temp2a + temp2b
                   m6 = m6 - ddot(noa,I2B_ovoo(:,c,i,k)+vt3_oa,1,t2b(a,b,:,j),1)

                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      do f = e+1,nua
                   !         do n = 1,noa
                   !            refval = refval -&
                   !            vA_oovv(m,n,e,f)*t3b(e,f,b,i,n,j)*t2b(a,c,m,k)+&
                   !            vA_oovv(m,n,e,f)*t3b(e,f,c,i,n,j)*t2b(a,b,m,k)+&
                   !            vA_oovv(m,n,e,f)*t3b(e,f,b,i,n,k)*t2b(a,c,m,j)-&
                   !            vA_oovv(m,n,e,f)*t3b(e,f,c,i,n,k)*t2b(a,b,m,j)
                   !         end do
                   !      end do
                   !   end do
                   !   do e = 1,nua
                   !      do f = 1,nub
                   !         do n = 1,nob
                   !            refval = refval -&
                   !            vB_oovv(m,n,e,f)*t3c(e,f,b,i,n,j)*t2b(a,c,m,k)+&
                   !            vB_oovv(m,n,e,f)*t3c(e,f,c,i,n,j)*t2b(a,b,m,k)+&
                   !            vB_oovv(m,n,e,f)*t3c(e,f,b,i,n,k)*t2b(a,c,m,j)-&
                   !            vB_oovv(m,n,e,f)*t3c(e,f,c,i,n,k)*t2b(a,b,m,j)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval - I2B_ovoo(m,b,i,j)*t2b(a,c,m,k)&
                   !                   + I2B_ovoo(m,c,i,j)*t2b(a,b,m,k)&
                   !                   + I2B_ovoo(m,b,i,k)*t2b(a,c,m,j)&
                   !                   - I2B_ovoo(m,c,i,k)*t2b(a,b,m,j)
                   ! end do
                   ! error(6) = error(6) + (m6-refval)
                   

                   ! (HBar T3)_C
                   d1 = MINUSONE*ddot(noa,H1A_oo(:,i),1,t3c(a,b,c,:,j,k),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   refval = refval - H1A_oo(m,i)*t3c(a,b,c,m,j,k)
                   !end do
                   !error(7) = error(7) + (d1-refval)

                   d2 = MINUSONE*ddot(nob,H1B_oo(:,j),1,t3c(a,b,c,i,:,k),1)
                   d2 = d2 + ddot(nob,H1B_oo(:,k),1,t3c(a,b,c,i,:,j),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   refval = refval - H1B_oo(m,j)*t3c(a,b,c,i,m,k)&
                   !                   + H1B_oo(m,k)*t3c(a,b,c,i,m,j)
                   !end do
                   !error(8) = error(8) + (d2-refval)

                   d3 = ddot(nua,H1A_vv(a,:),1,t3c(:,b,c,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   refval = refval + H1A_vv(a,e)*t3c(e,b,c,i,j,k)
                   !end do
                   !error(9) = error(9) + (d3-refval)

                   d4 = ddot(nub,H1B_vv(b,:),1,t3c(a,:,c,i,j,k),1)
                   d4 = d4 - ddot(nub,H1B_vv(c,:),1,t3c(a,:,b,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nub
                   !   refval = refval + H1B_vv(b,e)*t3c(a,e,c,i,j,k)&
                   !                   - H1B_vv(c,e)*t3c(a,e,b,i,j,k)
                   !end do
                   !error(10) = error(10) + (d4-refval)

                   d5 = HALF*ddot(Noo_bb,H2C_oooo(:,:,j,k),1,t3c(a,b,c,i,:,:),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do n = m+1,nob
                   !      refval = refval + H2C_oooo(m,n,j,k)*t3c(a,b,c,i,m,n)
                   !   end do
                   !end do
                   !error(11) = error(11) + (d5-refval)

                   d6 = ddot(Noo_ab,H2B_oooo(:,:,i,k),1,t3c(a,b,c,:,j,:),1)
                   d6 = d6 - ddot(Noo_ab,H2B_oooo(:,:,i,j),1,t3c(a,b,c,:,k,:),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do n = 1,nob
                   !      refval = refval + H2B_oooo(m,n,i,k)*t3c(a,b,c,m,j,n)&
                   !                      - H2B_oooo(m,n,i,j)*t3c(a,b,c,m,k,n)
                   !   end do
                   !end do
                   !error(12) = error(12) + (d6-refval)

                   d7 = HALF*ddot(Nvv_bb,H2C_vvvv(b,c,:,:),1,t3c(a,:,:,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nub
                   !   do f = e+1,nub
                   !      refval = refval + H2C_vvvv(b,c,e,f)*t3c(a,e,f,i,j,k)
                   !   end do
                   !end do
                   !error(13) = error(13) + (d7-refval)

                   d8 = ddot(Nvv_ab,H2B_vvvv(a,b,:,:),1,t3c(:,:,c,i,j,k),1)
                   d8 = d8 - ddot(Nvv_ab,H2B_vvvv(a,c,:,:),1,t3c(:,:,b,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   do f = 1,nub
                   !      refval = refval + H2B_vvvv(a,b,e,f)*t3c(e,f,c,i,j,k)&
                   !                      - H2B_vvvv(a,c,e,f)*t3c(e,f,b,i,j,k)
                   !   end do
                   !end do
                   !error(14) = error(14) + (d8-refval)

                   d9 = ddot(Nov_aa,H2A_voov_r1(a,:,i,:),1,t3c(:,b,c,:,j,k),1)
                   !refval = ZERO
                   !do e = 1,nua
                   !   do m = 1,noa
                   !      refval = refval + H2A_voov(a,m,i,e)*t3c(e,b,c,m,j,k)
                   !   end do
                   !end do
                   !error(15) = error(15) + (d9-refval)

                   d10 = ddot(Nov_bb,H2B_voov_r1(a,:,i,:),1,t3d(:,b,c,:,j,k),1)
                   !refval = ZERO
                   !do e = 1,nub
                   !   do m = 1,nob
                   !      refval = refval + H2B_voov(a,m,i,e)*t3d(e,b,c,m,j,k)
                   !   end do
                   !end do
                   !error(16) = error(16) + (d10-refval)

                   d11 = ddot(Nov_aa,H2B_ovvo_r1(:,b,:,j),1,t3b(a,:,c,i,:,k),1)
                   d11 = d11 - ddot(Nov_aa,H2B_ovvo_r1(:,c,:,j),1,t3b(a,:,b,i,:,k),1)
                   d11 = d11 - ddot(Nov_aa,H2B_ovvo_r1(:,b,:,k),1,t3b(a,:,c,i,:,j),1)
                   d11 = d11 + ddot(Nov_aa,H2B_ovvo_r1(:,c,:,k),1,t3b(a,:,b,i,:,j),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      refval = refval + H2B_ovvo(m,b,e,j)*t3b(a,e,c,i,m,k)&
                   !                      - H2B_ovvo(m,c,e,j)*t3b(a,e,b,i,m,k)&
                   !                      - H2B_ovvo(m,b,e,k)*t3b(a,e,c,i,m,j)&
                   !                      + H2B_ovvo(m,c,e,k)*t3b(a,e,b,i,m,j)
                   !   end do
                   !end do
                   !error(17) = error(17) + (d11-refval)

                   d12 = ddot(Nov_bb,H2C_voov_r1(b,:,j,:),1,t3c(a,:,c,i,:,k),1)
                   d12 = d12 - ddot(Nov_bb,H2C_voov_r1(c,:,j,:),1,t3c(a,:,b,i,:,k),1)
                   d12 = d12 - ddot(Nov_bb,H2C_voov_r1(b,:,k,:),1,t3c(a,:,c,i,:,j),1)
                   d12 = d12 + ddot(Nov_bb,H2C_voov_r1(c,:,k,:),1,t3c(a,:,b,i,:,j),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do e = 1,nub
                   !      refval = refval + H2C_voov(b,m,j,e)*t3c(a,e,c,i,m,k)&
                   !                      - H2C_voov(c,m,j,e)*t3c(a,e,b,i,m,k)&
                   !                      - H2C_voov(b,m,k,e)*t3c(a,e,c,i,m,j)&
                   !                      + H2C_voov(c,m,k,e)*t3c(a,e,b,i,m,j)
                   !   end do
                   !end do
                   !error(18) = error(18) + (d12-refval)

                   d13 = MINUSONE*ddot(Nov_ab,H2B_ovov_r1(:,b,i,:),1,t3c(a,:,c,:,j,k),1)
                   d13 = d13 + ddot(Nov_ab,H2B_ovov_r1(:,c,i,:),1,t3c(a,:,b,:,j,k),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nub
                   !      refval = refval - H2B_ovov(m,b,i,e)*t3c(a,e,c,m,j,k)&
                   !                      + H2B_ovov(m,c,i,e)*t3c(a,e,b,m,j,k)
                   !   end do
                   !end do
                   !error(19) = error(19) + (d13-refval)

                   d14 = MINUSONE*ddot(Nov_ba,H2B_vovo_r1(a,:,:,j),1,t3c(:,b,c,i,:,k),1)
                   d14 = d14 + ddot(Nov_ba,H2B_vovo_r1(a,:,:,k),1,t3c(:,b,c,i,:,j),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do e = 1,nua
                   !      refval = refval - H2B_vovo(a,m,e,j)*t3c(e,b,c,i,m,k)&
                   !                      + H2B_vovo(a,m,e,k)*t3c(e,b,c,i,m,j)
                   !   end do
                   !end do
                   !error(20) = error(20) + (d14-refval)

                   residual = d1+d2+d3+d4+d5+d6+d7+d8+d9+d10&
                              +d11+d12+d13+d14&
                              +m1+m2+m3+m4+m5+m6
                   denom = fA_oo(i,i)+fB_oo(j,j)+fB_oo(k,k)&
                           -fA_vv(a,a)-fB_vv(b,b)-fB_vv(c,c)
                   val = t3c(a,b,c,i,j,k) + residual/(denom-shift)
                   mval = MINUSONE*val

                   t3c_new(a,b,c,i,j,k) = val
                   t3c_new(a,c,b,i,j,k) = mval
                   t3c_new(a,b,c,i,k,j) = mval
                   t3c_new(a,c,b,i,k,j) = val

                end do
                !$OMP END DO
                !$OMP END PARALLEL

                !do i = 1,20
                !   print*,'Error in term',i,'=',error(i)
                !end do

            end subroutine update_t3c
                    
            subroutine update_t3d(t2c,t3c,t3d,&
                         triples_list,&
                         vB_oovv,vC_oovv,&
                         H1B_oo,H1B_vv,H2C_oooo,&
                         H2C_vvvv,H2C_voov,H2B_ovvo,&
                         H2C_vooo,I2C_vvov,&
                         fB_oo,fB_vv,shift,&
                         noa,nua,nob,nub,num_triples,t3d_new)

                 integer, intent(in) :: noa, nua, nob, nub, num_triples
                 real(kind=8), intent(in) :: shift
                 integer, intent(in) :: triples_list(num_triples,6)
                 real(kind=8), intent(in) :: t2c(nub,nub,nob,nob),&
                                             t3c(nua,nub,nub,noa,nob,nob),&
                                             t3d(nub,nub,nub,nob,nob,nob),&
                                             vB_oovv(noa,nob,nua,nub),&
                                             vC_oovv(nob,nob,nub,nub),&
                                             H1B_oo(nob,nob),H1B_vv(nub,nub),&
                                             H2C_oooo(nob,nob,nob,nob),&
                                             H2C_vvvv(nub,nub,nub,nub),&
                                             H2C_voov(nub,nob,nob,nub),&
                                             H2B_ovvo(noa,nub,nua,nob),&
                                             H2C_vooo(nub,nob,nob,nob),&
                                             I2C_vvov(nub,nub,nob,nub),&
                                             fB_oo(nob,nob),fB_vv(nub,nub)

                real(kind=8), intent(out) :: t3d_new(nub,nub,nub,nob,nob,nob)

                integer :: a, b, c, i, j, k, ct,&
                           Noo_bb, Nvv_bb, Nov_bb, Novv_bbb, Noov_bbb,&
                           Noov_baa, Novv_aab, Nov_aa
                real(kind=8) :: m1, m2, d1, d2, d3, d4, d5, d6,&
                                residual, denom, val, mval
                real(kind=8) :: vt3_ob(nob), vt3_ub(nub),&
                                H2C_voov_r(nub,nub,nob,nob),& ! reorder 1432
                                H2B_ovvo_r(nua,nub,noa,nob),& ! reorder 3214
                                vC_oovv_r1(nub,nub,nob,nob),& ! reorder 3421
                                vC_oovv_r2(nub,nob,nob,nub),& ! reorder 4123 
                                vB_oovv_r1(nua,nub,noa,nob),& ! reorder 3412
                                vB_oovv_r2(nua,noa,nob,nub),& ! reorder 3124
                                temp1a(nob), temp1b(nob),&
                                temp2a(nub), temp2b(nub)

                real(kind=8), parameter :: MINUSONE=-1.0d+0, HALF=0.5d+0, ZERO=0.0d+0,&
                                           ONE=1.0d+0

                real(kind=8), external :: ddot

                !integer :: m, n, e, f
                !real(kind=8) :: refval ,error(8)

                call mkl_set_num_threads_local(mkl_num_threads)
                call omp_set_num_threads(omp_num_threads)

                Nov_aa = noa*nua
                Noo_bb = nob*nob
                Nvv_bb = nub*nub
                Nov_bb = nob*nub
                Novv_bbb = nob*nub*nub
                Noov_bbb = nob*nob*nub
                Noov_baa = nob*noa*nua
                Novv_aab = noa*nua*nub

                call reorder1432(H2C_voov,H2C_voov_r)
                call reorder3214(H2B_ovvo,H2B_ovvo_r)
                call reorder3421(vC_oovv,vC_oovv_r1)
                call reorder4123(vC_oovv,vC_oovv_r2)
                call reorder3412(vB_oovv,vB_oovv_r1)
                call reorder3124(vB_oovv,vB_oovv_r2)

                !do i = 1,8
                !   error(i) = ZERO
                !end do

                t3d_new = 0.0d0

                !$OMP PARALLEL SHARED(t3d_new)
                !$OMP DO
                do ct = 1 , num_triples
            
                   ! Shift indices up by since the triples list is coming from
                   ! Python, where indices start from 0       
                   a = triples_list(ct,1)+1
                   b = triples_list(ct,2)+1
                   c = triples_list(ct,3)+1
                   i = triples_list(ct,4)+1
                   j = triples_list(ct,5)+1
                   k = triples_list(ct,6)+1
                    
                   ! Calculate devectorized residual for triple |ijkabc>
                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(a,:,:,i,j,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,a,:,:,i,j),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = MINUSONE*ddot(nob,H2C_vooo(a,:,i,j)+vt3_ob,1,t2c(b,c,:,k),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(a,:,:,k,j,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,a,:,:,k,j),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 + ddot(nob,H2C_vooo(a,:,k,j)+vt3_ob,1,t2c(b,c,:,i),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(a,:,:,i,k,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,a,:,:,i,k),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 + ddot(nob,H2C_vooo(a,:,i,k)+vt3_ob,1,t2c(b,c,:,j),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(b,:,:,i,j,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,b,:,:,i,j),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 + ddot(nob,H2C_vooo(b,:,i,j)+vt3_ob,1,t2c(a,c,:,k),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(b,:,:,k,j,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,b,:,:,k,j),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 - ddot(nob,H2C_vooo(b,:,k,j)+vt3_ob,1,t2c(a,c,:,i),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(b,:,:,i,k,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,b,:,:,i,k),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 - ddot(nob,H2C_vooo(b,:,i,k)+vt3_ob,1,t2c(a,c,:,j),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(c,:,:,i,j,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,c,:,:,i,j),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 + ddot(nob,H2C_vooo(c,:,i,j)+vt3_ob,1,t2c(b,a,:,k),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(c,:,:,k,j,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,c,:,:,k,j),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 - ddot(nob,H2C_vooo(c,:,k,j)+vt3_ob,1,t2c(b,a,:,i),1)

                   call dgemv('t',Novv_bbb,nob,HALF,vC_oovv_r1,Novv_bbb,t3d(c,:,:,i,k,:),1,ZERO,temp1a,1)
                   call dgemv('t',Novv_aab,nob,ONE,vB_oovv_r1,Novv_aab,t3c(:,c,:,:,i,k),1,ZERO,temp1b,1)
                   vt3_ob = temp1a + temp1b
                   m1 = m1 - ddot(nob,H2C_vooo(c,:,i,k)+vt3_ob,1,t2c(b,a,:,j),1)

                    !refval = ZERO
                    !do m = 1,nob
                    ! do f = 1,nub
                    !   do e = f+1,nub
                    !     do n = 1,nob
                    !       refval = refval&
                    !       -vC_oovv(m,n,e,f)*t3d(a,e,f,i,j,n)*t2c(b,c,m,k)&
                    !       +vC_oovv(m,n,e,f)*t3d(a,e,f,k,j,n)*t2c(b,c,m,i)&
                    !       +vC_oovv(m,n,e,f)*t3d(a,e,f,i,k,n)*t2c(b,c,m,j)&
                    !       +vC_oovv(m,n,e,f)*t3d(b,e,f,i,j,n)*t2c(a,c,m,k)&
                    !       -vC_oovv(m,n,e,f)*t3d(b,e,f,k,j,n)*t2c(a,c,m,i)&
                    !       -vC_oovv(m,n,e,f)*t3d(b,e,f,i,k,n)*t2c(a,c,m,j)&
                    !       +vC_oovv(m,n,e,f)*t3d(c,e,f,i,j,n)*t2c(b,a,m,k)&
                    !       -vC_oovv(m,n,e,f)*t3d(c,e,f,k,j,n)*t2c(b,a,m,i)&
                    !       -vC_oovv(m,n,e,f)*t3d(c,e,f,i,k,n)*t2c(b,a,m,j)
                    !     end do
                    !   end do
                    ! end do
                    ! do f = 1,nua
                    !    do e = 1,nub
                    !       do n = 1,noa
                    !          refval = refval&
                    !          -vB_oovv(n,m,f,e)*t3c(f,a,e,n,i,j)*t2c(b,c,m,k)&
                    !          +vB_oovv(n,m,f,e)*t3c(f,a,e,n,k,j)*t2c(b,c,m,i)&
                    !          +vB_oovv(n,m,f,e)*t3c(f,a,e,n,i,k)*t2c(b,c,m,j)&
                    !          +vB_oovv(n,m,f,e)*t3c(f,b,e,n,i,j)*t2c(a,c,m,k)&
                    !          -vB_oovv(n,m,f,e)*t3c(f,b,e,n,k,j)*t2c(a,c,m,i)&
                    !          -vB_oovv(n,m,f,e)*t3c(f,b,e,n,i,k)*t2c(a,c,m,j)&
                    !          +vB_oovv(n,m,f,e)*t3c(f,c,e,n,i,j)*t2c(b,a,m,k)&
                    !          -vB_oovv(n,m,f,e)*t3c(f,c,e,n,k,j)*t2c(b,a,m,i)&
                    !          -vB_oovv(n,m,f,e)*t3c(f,c,e,n,i,k)*t2c(b,a,m,j)
                    !       end do
                    !    end do
                    !  end do
                    !  refval = refval - H2C_vooo(a,m,i,j)*t2c(b,c,m,k)&
                    !                  + H2C_vooo(a,m,k,j)*t2c(b,c,m,i)&
                    !                  + H2C_vooo(a,m,i,k)*t2c(b,c,m,j)&
                    !                  + H2C_vooo(b,m,i,j)*t2c(a,c,m,k)&
                    !                  - H2C_vooo(b,m,k,j)*t2c(a,c,m,i)&
                    !                  - H2C_vooo(b,m,i,k)*t2c(a,c,m,j)&
                    !                  + H2C_vooo(c,m,i,j)*t2c(b,a,m,k)&
                    !                  - H2C_vooo(c,m,k,j)*t2c(b,a,m,i)&
                    !                  - H2C_vooo(c,m,i,k)*t2c(b,a,m,j)
                    !end do
                    !error(1) = error(1) + (m1-refval)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(a,b,:,i,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,a,b,:,i,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = ddot(nub,I2C_vvov(a,b,i,:)-vt3_ub,1,t2c(:,c,j,k),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(a,c,:,i,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,a,c,:,i,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 - ddot(nub,I2C_vvov(a,c,i,:)-vt3_ub,1,t2c(:,b,j,k),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(c,b,:,i,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,c,b,:,i,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 - ddot(nub,I2C_vvov(c,b,i,:)-vt3_ub,1,t2c(:,a,j,k),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(a,b,:,j,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,a,b,:,j,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 - ddot(nub,I2C_vvov(a,b,j,:)-vt3_ub,1,t2c(:,c,i,k),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(a,c,:,j,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,a,c,:,j,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 + ddot(nub,I2C_vvov(a,c,j,:)-vt3_ub,1,t2c(:,b,i,k),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(c,b,:,j,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,c,b,:,j,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 + ddot(nub,I2C_vvov(c,b,j,:)-vt3_ub,1,t2c(:,a,i,k),1)

                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(a,b,:,k,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,a,b,:,k,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 - ddot(nub,I2C_vvov(a,b,k,:)-vt3_ub,1,t2c(:,c,j,i),1)
                   
                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(a,c,:,k,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,a,c,:,k,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 + ddot(nub,I2C_vvov(a,c,k,:)-vt3_ub,1,t2c(:,b,j,i),1)
                   
                   call dgemv('t',Noov_bbb,nub,HALF,vC_oovv_r2,Noov_bbb,t3d(c,b,:,k,:,:),1,ZERO,temp2a,1)
                   call dgemv('t',Noov_baa,nub,ONE,vB_oovv_r2,Noov_baa,t3c(:,c,b,:,k,:),1,ZERO,temp2b,1)
                   vt3_ub = temp2a + temp2b
                   m2 = m2 + ddot(nub,I2C_vvov(c,b,k,:)-vt3_ub,1,t2c(:,a,j,i),1)

                   !refval = ZERO
                   !do e = 1,nub
                   !   do f = 1,nub
                   !      do m = 1,nob
                   !         do n = m+1,nob
                   !            refval = refval&
                   !            -vC_oovv(m,n,e,f)*t3d(a,b,f,i,m,n)*t2c(e,c,j,k)&
                   !            +vC_oovv(m,n,e,f)*t3d(c,b,f,i,m,n)*t2c(e,a,j,k)&
                   !            +vC_oovv(m,n,e,f)*t3d(a,c,f,i,m,n)*t2c(e,b,j,k)&
                   !            +vC_oovv(m,n,e,f)*t3d(a,b,f,j,m,n)*t2c(e,c,i,k)&
                   !            -vC_oovv(m,n,e,f)*t3d(c,b,f,j,m,n)*t2c(e,a,i,k)&
                   !            -vC_oovv(m,n,e,f)*t3d(a,c,f,j,m,n)*t2c(e,b,i,k)&
                   !            +vC_oovv(m,n,e,f)*t3d(a,b,f,k,m,n)*t2c(e,c,j,i)&
                   !            -vC_oovv(m,n,e,f)*t3d(c,b,f,k,m,n)*t2c(e,a,j,i)&
                   !            -vC_oovv(m,n,e,f)*t3d(a,c,f,k,m,n)*t2c(e,b,j,i)
                   !         end do
                   !      end do
                   !   end do
                   !   do f = 1,nua
                   !      do m = 1,nob
                   !         do n = 1,noa
                   !            refval = refval&
                   !            -vB_oovv(n,m,f,e)*t3c(f,a,b,n,i,m)*t2c(e,c,j,k)&
                   !            +vB_oovv(n,m,f,e)*t3c(f,c,b,n,i,m)*t2c(e,a,j,k)&
                   !            +vB_oovv(n,m,f,e)*t3c(f,a,c,n,i,m)*t2c(e,b,j,k)&
                   !            +vB_oovv(n,m,f,e)*t3c(f,a,b,n,j,m)*t2c(e,c,i,k)&
                   !            -vB_oovv(n,m,f,e)*t3c(f,c,b,n,j,m)*t2c(e,a,i,k)&
                   !            -vB_oovv(n,m,f,e)*t3c(f,a,c,n,j,m)*t2c(e,b,i,k)&
                   !            +vB_oovv(n,m,f,e)*t3c(f,a,b,n,k,m)*t2c(e,c,j,i)&
                   !            -vB_oovv(n,m,f,e)*t3c(f,c,b,n,k,m)*t2c(e,a,j,i)&
                   !            -vB_oovv(n,m,f,e)*t3c(f,a,c,n,k,m)*t2c(e,b,j,i)
                   !         end do
                   !      end do
                   !   end do
                   !   refval = refval + I2C_vvov(a,b,i,e)*t2c(e,c,j,k)&
                   !                   - I2C_vvov(c,b,i,e)*t2c(e,a,j,k)&
                   !                   - I2C_vvov(a,c,i,e)*t2c(e,b,j,k)&
                   !                   - I2C_vvov(a,b,j,e)*t2c(e,c,i,k)&
                   !                   + I2C_vvov(c,b,j,e)*t2c(e,a,i,k)&
                   !                   + I2C_vvov(a,c,j,e)*t2c(e,b,i,k)&
                   !                   - I2C_vvov(a,b,k,e)*t2c(e,c,j,i)&
                   !                   + I2C_vvov(c,b,k,e)*t2c(e,a,j,i)&
                   !                   + I2C_vvov(a,c,k,e)*t2c(e,b,j,i)
                   ! end do
                   ! error(2) = error(2) + (m2-refval)

                    
                   d1 = MINUSONE*ddot(nob,H1B_oo(:,k),1,t3d(a,b,c,i,j,:),1)
                   d1 = d1 + ddot(nob,H1B_oo(:,j),1,t3d(a,b,c,i,k,:),1)
                   d1 = d1 + ddot(nob,H1B_oo(:,i),1,t3d(a,b,c,k,j,:),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   refval = refval - H1B_oo(m,k)*t3d(a,b,c,i,j,m)&
                   !                   + H1B_oo(m,j)*t3d(a,b,c,i,k,m)&
                   !                   + H1B_oo(m,i)*t3d(a,b,c,k,j,m)
                   !end do
                   !error(3) = error(3) + (d1-refval)

                   d2 = ddot(nub,H1B_vv(c,:),1,t3d(a,b,:,i,j,k),1)
                   d2 = d2 - ddot(nub,H1B_vv(b,:),1,t3d(a,c,:,i,j,k),1)
                   d2 = d2 - ddot(nub,H1B_vv(a,:),1,t3d(c,b,:,i,j,k),1)
                   !refval = ZERO
                   !do e = 1,nub
                   !   refval = refval + H1B_vv(c,e)*t3d(a,b,e,i,j,k)&
                   !                   - H1B_vv(b,e)*t3d(a,c,e,i,j,k)&
                   !                   - H1B_vv(a,e)*t3d(c,b,e,i,j,k)
                   !end do
                   !error(4) = error(4) + (d2-refval)

                   d3 = ddot(Noo_bb,H2C_oooo(:,:,i,j),1,t3d(a,b,c,:,:,k),1)
                   d3 = d3 - ddot(Noo_bb,H2C_oooo(:,:,k,j),1,t3d(a,b,c,:,:,i),1)
                   d3 = d3 - ddot(Noo_bb,H2C_oooo(:,:,i,k),1,t3d(a,b,c,:,:,j),1)
                   d3 = HALF*d3
                   !refval = ZERO
                   !do m = 1,nob
                   !   do n = m+1,nob
                   !      refval = refval + H2C_oooo(m,n,i,j)*t3d(a,b,c,m,n,k)&
                   !                      - H2C_oooo(m,n,k,j)*t3d(a,b,c,m,n,i)&
                   !                      - H2C_oooo(m,n,i,k)*t3d(a,b,c,m,n,j)
                   !   end do
                   !end do
                   !error(5) = error(5) + (d3-refval)
        
                   d4 = ddot(Nvv_bb,H2C_vvvv(a,b,:,:),1,t3d(:,:,c,i,j,k),1)
                   d4 = d4 - ddot(Nvv_bb,H2C_vvvv(c,b,:,:),1,t3d(:,:,a,i,j,k),1)
                   d4 = d4 - ddot(Nvv_bb,H2C_vvvv(a,c,:,:),1,t3d(:,:,b,i,j,k),1)
                   d4 = HALF*d4
                   !refval = ZERO
                   !do e = 1,nub
                   !   do f = e+1,nub
                   !      refval = refval + H2C_vvvv(a,b,e,f)*t3d(e,f,c,i,j,k)&
                   !                      - H2C_vvvv(a,c,e,f)*t3d(e,f,b,i,j,k)&
                   !                      - H2C_vvvv(c,b,e,f)*t3d(e,f,a,i,j,k)
                   !   end do
                   !end do
                   !error(6) = error(6) + (d4-refval)

                   d5 = ddot(Nov_aa,H2B_ovvo_r(:,a,:,i),1,t3c(:,b,c,:,j,k),1)
                   d5 = d5 - ddot(Nov_aa,H2B_ovvo_r(:,a,:,j),1,t3c(:,b,c,:,i,k),1)
                   d5 = d5 - ddot(Nov_aa,H2B_ovvo_r(:,a,:,k),1,t3c(:,b,c,:,j,i),1)
                   d5 = d5 - ddot(Nov_aa,H2B_ovvo_r(:,b,:,i),1,t3c(:,a,c,:,j,k),1)
                   d5 = d5 + ddot(Nov_aa,H2B_ovvo_r(:,b,:,j),1,t3c(:,a,c,:,i,k),1)
                   d5 = d5 + ddot(Nov_aa,H2B_ovvo_r(:,b,:,k),1,t3c(:,a,c,:,j,i),1)
                   d5 = d5 - ddot(Nov_aa,H2B_ovvo_r(:,c,:,i),1,t3c(:,b,a,:,j,k),1)
                   d5 = d5 + ddot(Nov_aa,H2B_ovvo_r(:,c,:,j),1,t3c(:,b,a,:,i,k),1)
                   d5 = d5 + ddot(Nov_aa,H2B_ovvo_r(:,c,:,k),1,t3c(:,b,a,:,j,i),1)
                   !refval = ZERO
                   !do m = 1,noa
                   !   do e = 1,nua
                   !      refval = refval&
                   !      +H2B_ovvo(m,a,e,i)*t3c(e,b,c,m,j,k)&
                   !      -H2B_ovvo(m,a,e,j)*t3c(e,b,c,m,i,k)&
                   !      -H2B_ovvo(m,a,e,k)*t3c(e,b,c,m,j,i)&
                   !      -H2B_ovvo(m,b,e,i)*t3c(e,a,c,m,j,k)&
                   !      +H2B_ovvo(m,b,e,j)*t3c(e,a,c,m,i,k)&
                   !      +H2B_ovvo(m,b,e,k)*t3c(e,a,c,m,j,i)&
                   !      -H2B_ovvo(m,c,e,i)*t3c(e,b,a,m,j,k)&
                   !      +H2B_ovvo(m,c,e,j)*t3c(e,b,a,m,i,k)&
                   !      +H2B_ovvo(m,c,e,k)*t3c(e,b,a,m,j,i)
                   !   end do
                   !end do
                   !error(7) = error(7) + (d5-refval)

                   d6 = ddot(Nov_bb,H2C_voov_r(c,:,k,:),1,t3d(a,b,:,i,j,:),1)
                   d6 = d6 - ddot(Nov_bb,H2C_voov_r(c,:,i,:),1,t3d(a,b,:,k,j,:),1)
                   d6 = d6 - ddot(Nov_bb,H2C_voov_r(c,:,j,:),1,t3d(a,b,:,i,k,:),1)
                   d6 = d6 - ddot(Nov_bb,H2C_voov_r(a,:,k,:),1,t3d(c,b,:,i,j,:),1)
                   d6 = d6 + ddot(Nov_bb,H2C_voov_r(a,:,i,:),1,t3d(c,b,:,k,j,:),1)
                   d6 = d6 + ddot(Nov_bb,H2C_voov_r(a,:,j,:),1,t3d(c,b,:,i,k,:),1)
                   d6 = d6 - ddot(Nov_bb,H2C_voov_r(b,:,k,:),1,t3d(a,c,:,i,j,:),1)
                   d6 = d6 + ddot(Nov_bb,H2C_voov_r(b,:,i,:),1,t3d(a,c,:,k,j,:),1)
                   d6 = d6 + ddot(Nov_bb,H2C_voov_r(b,:,j,:),1,t3d(a,c,:,i,k,:),1)
                   !refval = ZERO
                   !do m = 1,nob
                   !   do e = 1,nub
                   !      refval = refval&
                   !      +H2C_voov(c,m,k,e)*t3d(a,b,e,i,j,m)&
                   !      -H2C_voov(c,m,i,e)*t3d(a,b,e,k,j,m)&
                   !      -H2C_voov(c,m,j,e)*t3d(a,b,e,i,k,m)&
                   !      -H2C_voov(a,m,k,e)*t3d(c,b,e,i,j,m)&
                   !      +H2C_voov(a,m,i,e)*t3d(c,b,e,k,j,m)&
                   !      +H2C_voov(a,m,j,e)*t3d(c,b,e,i,k,m)&
                   !      -H2C_voov(b,m,k,e)*t3d(a,c,e,i,j,m)&
                   !      +H2C_voov(b,m,i,e)*t3d(a,c,e,k,j,m)&
                   !      +H2C_voov(b,m,j,e)*t3d(a,c,e,i,k,m)
                   !   end do
                   !end do
                   !error(8) = error(8) + (d6-refval)

                   residual = m1 + m2 + d1 + d2 + d3 + d4 + d5 + d6
                   denom = fB_oo(i,i)+fB_oo(j,j)+fB_oo(k,k)&
                           -fB_vv(a,a)-fB_vv(b,b)-fB_vv(c,c)
                   val = t3d(a,b,c,i,j,k) + residual/(denom-shift)
                   mval = MINUSONE*val

                   t3d_new(a,b,c,i,j,k) = val
                   t3d_new(A,B,C,K,I,J) = val
                   t3d_new(A,B,C,J,K,I) = val
                   t3d_new(A,B,C,I,K,J) = mval
                   t3d_new(A,B,C,J,I,K) = mval
                   t3d_new(A,B,C,K,J,I) = mval
                                      
                   t3d_new(B,A,C,I,J,K) = mval
                   t3d_new(B,A,C,K,I,J) = mval
                   t3d_new(B,A,C,J,K,I) = mval
                   t3d_new(B,A,C,I,K,J) = val
                   t3d_new(B,A,C,J,I,K) = val
                   t3d_new(B,A,C,K,J,I) = val
                                      
                   t3d_new(A,C,B,I,J,K) = mval
                   t3d_new(A,C,B,K,I,J) = mval
                   t3d_new(A,C,B,J,K,I) = mval
                   t3d_new(A,C,B,I,K,J) = val
                   t3d_new(A,C,B,J,I,K) = val
                   t3d_new(A,C,B,K,J,I) = val
                                      
                   t3d_new(C,B,A,I,J,K) = mval
                   t3d_new(C,B,A,K,I,J) = mval
                   t3d_new(C,B,A,J,K,I) = mval
                   t3d_new(C,B,A,I,K,J) = val
                   t3d_new(C,B,A,J,I,K) = val
                   t3d_new(C,B,A,K,J,I) = val
                                      
                   t3d_new(B,C,A,I,J,K) = val
                   t3d_new(B,C,A,K,I,J) = val
                   t3d_new(B,C,A,J,K,I) = val
                   t3d_new(B,C,A,I,K,J) = mval
                   t3d_new(B,C,A,J,I,K) = mval
                   t3d_new(B,C,A,K,J,I) = mval
                                      
                   t3d_new(C,A,B,I,J,K) = val
                   t3d_new(C,A,B,K,I,J) = val
                   t3d_new(C,A,B,J,K,I) = val
                   t3d_new(C,A,B,I,K,J) = mval
                   t3d_new(C,A,B,J,I,K) = mval
                   t3d_new(C,A,B,K,J,I) = mval

                end do
                !$OMP END DO
                !$OMP END PARALLEL

                !do i = 1,8
                !   print*,'Error in term',i,'=',error(i)
                !end do

            end subroutine update_t3d

            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            !!!!!!!!!!!!!!!!!!!!!! UTILITY ROUTINES !!!!!!!!!!!!!!!!!!!!!!!!
            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

            subroutine reorder4321(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i4,i3,i2,i1) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder4321

            subroutine reorder3412(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i3,i4,i1,i2) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder3412

            subroutine reorder3124(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i3,i1,i2,i4) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder3124

            subroutine reorder4231(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i4,i2,i3,i1) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder4231

            subroutine reorder1324(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i1,i3,i2,i4) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder1324

            subroutine reorder3214(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i3,i2,i1,i4) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder3214

            subroutine reorder4123(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i4,i1,i2,i3) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder4123

            subroutine reorder3421(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i3,i4,i2,i1) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder3421

            subroutine reorder1432(x_in,x_out)

                    real(kind=8), intent(in) :: x_in(:,:,:,:)
                    real(kind=8), intent(out) :: x_out(:,:,:,:)

                    integer :: i1, i2, i3, i4
                    integer :: L1, L2, L3, L4

                    L1 = size(x_in,1)
                    L2 = size(x_in,2)
                    L3 = size(x_in,3)
                    L4 = size(x_in,4)

                    do i1 = 1,L1
                       do i2 = 1,L2
                          do i3 = 1,L3
                             do i4 = 1,L4
                                x_out(i1,i4,i3,i2) = x_in(i1,i2,i3,i4)
                             end do
                          end do
                       end do
                    end do

            end subroutine reorder1432

            !subroutine dgemv(K,N,A,x,y)
            !        ! Assuming:
            !        ! trans='t'
            !        ! K = M = LDA = LDB (on Netlib), contraction dim
            !        ! INCX = INCY = 1
            !        ! ALPHA = 1.0
            !        ! BETA = 0.0
            !
            !        integer :: K, N
            !        double precision :: A(K,*), X(*), Y(*)
            !        double precision :: zero
            !        parameter(zero=0.0d+0)
            !        double precision :: temp
            !        integer :: i, j, jy
            !        
            !        jy = 1
            !        do j = 1,n
            !           temp = zero
            !           do i = 1,k
            !              temp = temp + a(i,j)*x(i)
            !           end do
            !           y(jy) = temp
            !           jy = jy + 1
            !        end do
            !
            !end subroutine dgemv

            !double precision function ddot(N,dx,dy)
            !
            !        integer :: N
            !        real(8) :: dx(*), dy(*)
            !        real(8) :: dtemp
            !        integer :: i, ix, iy, m, mp1
            !
            !        intrinsic mod
            !
            !        ddot = 0.0d0
            !        dtemp = 0.0d0
            !
            !        ! perform the dot product using batches of 5
            !        m = mod(n,5)
            !
            !        !
            !        if (m .ne. 0) then
            !           do i = 1,m
            !              dtemp = dtemp + dx(i)*dy(i)
            !           end do
            !           if (n .lt. 5) then
            !              ddot = dtemp
            !              return
            !           end if
            !        end if
            !
            !        ! 
            !        mp1 = m + 1
            !        do i = mp1,N,5
            !           dtemp = dtemp + dx(i)*dy(i)&
            !                         + dx(i+1)*dy(i+1)&
            !                         + dx(i+2)*dy(i+2)&
            !                         + dx(i+3)*dy(i+3)&
            !                         + dx(i+4)*dy(i+4)
            !        end do
            !
            !        ! return the final dot product
            !        ddot = dtemp
            !
            !end function ddot



end module ccp_loops
                                             
