export FreeModule, FreeModuleClass

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent(M::freemodule) = M.parent

base_ring(S::FreeModuleClass) = S.base_ring

base_ring(M::freemodule) = base_ring(parent(M))

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, S::FreeModuleClass)
   print(io, "Class of Free Modules over ")
   show(io, base_ring(S))
end

function show(io::IO, M::freemodule)
   print(io, "Free Module of Rank ", M.rank, " over ")
   show(io, base_ring(M))
end

###############################################################################
#
#   FreeModule constructor
#
###############################################################################

function FreeModule{T <: Nemo.RingElem}(R::SingularPolyRing{T}, r::Int)
   r < 0 && throw(DomainError())
   par = FreeModuleClass{T}(R)
   return freemodule{T}(par, r)
end

