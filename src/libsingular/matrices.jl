function ncols(I::matrix) 
  icxx"""(int) MATCOLS($I);"""
end

function nrows(I::matrix) 
  icxx"""(int) MATROWS($I);"""
end

function id_Module2Matrix(I::ideal, R::ring)
   icxx"""id_Module2Matrix($I, $R);"""
end

function id_Matrix2Module(M::matrix, R::ring)
   icxx"""id_Matrix2Module($M, $R);"""
end

function getindex(M::matrix, i::Cint, j::Cint) 
  icxx"""(poly) MATELEM($M, $i, $j);"""
end

function setindex!(M::matrix, p::poly, i::Cint, j::Cint) 
  icxx"""MATELEM($M, $i, $j) = (poly) $p;"""
end

function mp_New(r::Cint, c::Cint)
   icxx"""mp_New($r, $c);"""
end

function mp_Delete(M::matrix, R::ring)
   icxx"""mp_Delete(&$M, $R);"""
end

function mp_Copy(M::matrix, R::ring)
   icxx"""mp_Copy($M, $R);"""
end

function mp_InitP(r::Cint, c::Cint, p::poly, R::ring)
   icxx"""mp_InitP($r, $c, $p, $R);"""
end

function iiStringMatrix(I::matrix, d::Cint, R::ring)
   icxx"""iiStringMatrix($I, $d, $R);"""
end
