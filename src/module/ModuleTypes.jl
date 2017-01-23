###############################################################################
#
#   SingularModuleClass/smodule 
#
###############################################################################

const SingularModuleClassID = ObjectIdDict()

type SingularModuleClass{T <: Nemo.RingElem} <: Nemo.Set
   base_ring::SingularPolyRing

   function SingularModuleClass(R::SingularPolyRing)
      if haskey(SingularModuleClassID, R)
         return SingularModuleClassID[R]
      else
         return SingularModuleClassID[R] = new(R)
      end
   end
end

type smodule{T <: Nemo.RingElem} <: Nemo.Module{spoly{T}}
   ptr::libSingular.ideal # ideal and module types are the same in Singular
   base_ring::SingularPolyRing
   isGB::Bool

   function smodule(R::SingularPolyRing, m::libSingular.ideal)
      z = new(m, R, false)
      finalizer(z, _smodule_clear_fn)
      return z
   end

   function smodule(R::SingularPolyRing, m::libSingular.matrix)
      ptr = libSingular.mp_Copy(m, R.ptr)
      ptr = libSingular.id_Matrix2Module(ptr, R.ptr)
      z = new(ptr, R, false)
      finalizer(z, _smodule_clear_fn)
      return z
   end
end

function _smodule_clear_fn(I::smodule)
   libSingular.id_Delete(I.ptr, I.base_ring.ptr)
end

###############################################################################
#
#   svector 
#
###############################################################################

type svector{T <: Nemo.RingElem} <: Nemo.ModuleElem{spoly{T}}
   ptr::libSingular.poly # not really a polynomial
   rank::Int
   base_ring::SingularPolyRing{T}

   function svector(R::SingularPolyRing, r::Int, p::libSingular.poly)
      z = new(p, r, R)
      R.refcount += 1
      finalizer(z, _svector_clear_fn)
      return z
   end
end

function _svector_clear_fn(p::svector)
   R = p.base_ring
   libSingular.p_Delete(p.ptr, R.ptr)
   _SingularPolyRing_clear_fn(R)
end
