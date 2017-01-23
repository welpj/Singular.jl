export FreeModuleMorphismClass

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent(M::freemodulemorphism) = M.parent

source(S::FreeModuleMorphismClass) = S.source

target(S::FreeModuleMorphismClass) = S.target

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, S::FreeModuleMorphismClass)
   print(io, "Class of Morphisms from ")
   show(io, source(S))
   print(io, " to ")
   show(io, target(T))
end

function show(io::IO, M::freemodulemorphism)
end

###############################################################################
#
#   FreeModuleMorphism constructor
#
###############################################################################

function FreeModuleMorphism{T <: Nemo.RingElem}(R::FreeModuleClass{T}, S::FreeModuleClass{T})
end

