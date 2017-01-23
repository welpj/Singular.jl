###############################################################################
#
#   FreeModuleClass, freemodule
#
###############################################################################

const FreeModuleClassID = ObjectIdDict()

type FreeModuleClass{T <: Nemo.RingElem} <: Nemo.Set
   base_ring::SingularPolyRing{T}

   function FreeModuleClass(R::SingularPolyRing)
      if haskey(FreeModuleClassID, R)
         return FreeModuleClassID[R]
      else
         return FreeModuleClassID[R] = new(R)
      end
   end
end

const freemoduleID = ObjectIdDict()

type freemodule{T <: Nemo.RingElem} <: Nemo.Module{T}
   rank::Int
   parent::FreeModuleClass{T}

   function freemodule(par::FreeModuleClass, r::Int)
      if haskey(freemoduleID, (par, r))
         return freemoduleID[par, r]
      else
         return freemoduleID[par, r] = new(r, par)
      end
   end
end

###############################################################################
#
#   FreeModuleMorphismClass, freemodulemorphism
#
###############################################################################

const FreeModuleMorphismClassID = ObjectIdDict()

type FreeModuleMorphismClass{T <: Nemo.RingElem} <: Nemo.Set
   source::freemodule{T}
   target::freemodule{T}

   function FreeModuleMorphismClass(M::freemodule, N::freemodule)
      if haskey(FreeModuleClassID, (M, N))
         return FreeModuleClassID[M, N]
      else
         return FreeModuleClassID[M, N] = new(M, N)
      end
   end
end

type freemodulemorphism{T <: Nemo.RingElem} <: Nemo.Module{T}
   images::smodule
   parent::FreeModuleMorphismClass{T}

   function freemodulemorphism(im::smodule)
      z = new(im)
      return z
   end
end

###############################################################################
#
#   SubquotientClass, subquotient
#
###############################################################################

const SubquotientClassID = ObjectIdDict()

type SubquotientClass{T <: Nemo.RingElem} <: Nemo.Set
   base_ring::SingularPolyRing{T}

   function SubquotientClass(R::SingularPolyRing)
      if haskey(SubquotientClassID, R)
         return SubquotientClassID[R]
      else
         return SubquotientClassID[R] = new(R)
      end
   end   
end

type subquotient{T <: Nemo.RingElem} <: Nemo.Module{T}
   generators::freemodulemorphism{T}
   relations::freemodulemorphism{T}
   parent::SubquotientClass{T}
end

