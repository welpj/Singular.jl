export FreeModuleMorphismClass

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent(M::freemodulemorphism) = M.parent

source(S::FreeModuleMorphismModule) = S.source

source(m::freemodulemorphism) = source(parent(m))

target(S::FreeModuleMorphismModule) = S.target

target(m::freemodulemorphism) = target(parent(m))

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, S::FreeModuleMorphismModule)
   print(io, "Module of Morphisms from ")
   show(io, source(S))
   print(io, " to ")
   show(io, target(S))
end

function show{T <: Nemo.RingElem}(io::IO, M::freemodulemorphism{T})
   R = base_ring(source(M))
   ptr = libSingular.id_Copy(M.images, R.ptr)
   M = smatrix{T}(R, ptr)
   show(io, M)
end

###############################################################################
#
#   FreeModuleMorphism constructor
#
###############################################################################

function FreeModuleMorphism{T <: Nemo.RingElem}(m::smatrix{T})
   R = base_ring(m)
   r = nrows(m)
   c = ncols(m)
   S = FreeModuleMorphismModule{T}(FreeModule(R, r), FreeModule(R, c))
   M = smodule{T}(R, m.ptr)
   return freemodulemorphism{T}(S, M.ptr)
end

