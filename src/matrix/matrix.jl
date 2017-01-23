export SingularMatrix

###############################################################################
#
#   Basic manipulation
#
###############################################################################

nrows(M::smatrix) = Int(libSingular.nrows(M.ptr))

ncols(M::smatrix) = Int(libSingular.nrows(M.ptr))

function parent(M::smatrix)
   return SingularMatrixSpace(M.base_ring, nrows(M), ncols(M))
end

base_ring(S::SingularMatrixSpace) = S.base_ring

base_ring(M::smatrix) = M.base_ring

elem_type(S::SingularMatrixSpace) = smatrix

parent_type(M::smatrix) = SingularMatrixSpace

function getindex(M::smatrix, i::Int, j::Int)
   R = base_ring(M)
   ptr = libSingular.getindex(M.ptr, Cint(i), Cint(j))
   return R(libSingular.p_Copy(ptr, R.ptr))
end

function setindex!(M::smatrix, p::spoly, i::Int, j::Int)
   ptr = libSingular.p_Copy(p.ptr, parent(p).ptr)
   libSingular.setindex!(M.ptr, ptr, Cint(i), Cint(j))
   nothing
end

###############################################################################
#
#   String I/O 
#
###############################################################################

function show(io::IO, S::SingularMatrixSpace)
   print(io, "Space of ", S.nrows, "x", S.ncols, " Singular Matrices over ")
   show(io, base_ring(S))
end

function show(io::IO, M::smatrix)
   print(io, "[")
   m = nrows(M)
   n = ncols(M)
   for i = 1:m
      for j = 1:n
         show(io, M[i, j])
         if j != n
            print(io, ", ")
         elseif i != m
            println(io, "")
         end
      end
   end
   print(io, "]")
end

###############################################################################
#
#   SingularMatrix constructors
#
###############################################################################

function SingularMatrix(I::smodule)
   return smatrix(base_ring(I), I.ptr)
end

function typed_hvcat{T <: Nemo.RingElem}(R::SingularPolyRing{T}, dims, d...)
   r = length(dims)
   c = dims[1]
   A = smatrix(R, r, c)
   for i = 1:r
      dims[i] != c && throw(ArgumentError("row $i has mismatched number of columns (expected $c, got $(dims[i]))"))
      for j = 1:c
         A[i, j] = R(d[(i - 1)*c + j])
      end
   end 
   return A
end

function typed_hcat{T <: Nemo.RingElem}(R::SingularPolyRing{T}, d...)
   r = length(d)
   A = smatrix(R, r, c)
   for i = 1:r
      A[1, i] = R(d[i])
   end
   return A
end
