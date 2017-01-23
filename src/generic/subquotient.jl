export SubquotientClass, Subquotient, base_ring

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
   println(io, "Subquotient Module with Generators:")
   show(io, M.generators)
   println("")
   println(io, "and Relations:")
   show(io, M.relations)
end

###############################################################################
#
#   Subquotient constructor
#
###############################################################################

function Subquotient{T <: Nemo.RingElem}(R::freemodulemorphism{T}, S::freemodulemorphism{T})
   return subquotient{T}(R, S, SubquotientClass{T}(base_ring(target(R))))
end

