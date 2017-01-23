export SubquotientClass, base_ring

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent(M::subquotient) = M.parent

base_ring(S::SubquotientClass) = S.base_ring

base_ring(M::subquotient) = base_ring(parent(M))

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, S::SubquotientClass)
   print(io, "Class of Subquotient Modules over ")
   show(io, base_ring(S))
end

function show(io::IO, M::subquotient)
end

###############################################################################
#
#   Subquotient constructor
#
###############################################################################

function Subquotient{T <: Nemo.RingElem}(R::FreeModuleClass{T}, S::FreeModuleClass{T})
end

