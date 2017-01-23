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

function show(io::IO, M::freemodulemorphism)
   R = base_ring(source(M))
   ptr = libSingular.id_Copy(M.images, R.ptr)
   M = SingularMatrix(SingularModule(R, ptr))
   show(io, M)
end

###############################################################################
#
#   FreeModuleMorphism constructor
#
###############################################################################

function FreeModuleMorphism(m::smatrix)
   R = base_ring(m)
   T = elem_type(base_ring(R))
   r = nrows(m)
   c = ncols(m)
   S = FreeModuleMorphismModule{T}(FreeModule(R, r), FreeModule(R, c))
   M = SingularModule(R, m.ptr)
   return freemodulemorphism{T}(S, M.ptr)
end

