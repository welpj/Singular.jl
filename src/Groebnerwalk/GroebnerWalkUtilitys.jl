###############################################################
#Utilitys for Groebnerwalks
###############################################################

#Returns the initials of polynomials w.r.t. a weight vector.
#The ordering doesn´t affect this.
function initials(
    R::Singular.PolyRing,
    G::Vector{spoly{n_Q}},
    w::Vector{Int64}
)
    inits = []
    for g in G
        maxw = 0
        indexw = []
        e = collect(Singular.exponent_vectors(g))
        for i = 1:length(g)
            tmpw = dot(w, e[i])
            if maxw == tmpw
                push!(indexw, (i, e[i]))
                #rethink this. gens are preordered
            elseif maxw < tmpw
                indexw = []
                push!(indexw, (i, e[i]))
                maxw = tmpw
            end
        end
        inw = MPolyBuildCtx(R)
        for (k, j) in indexw
            Singular.push_term!(inw, collect(Singular.coefficients(g))[k], j)
        end
        h = finish(inw)
        push!(inits, h)
    end
    return inits
end
mutable struct MonomialOrder{T<:Matrix{Int64},v<:Vector{Int64}, tv<:Vector{Int64}}
    m::T
    w::v
    t::tv
end

function diff_vectors(
    I::Singular.sideal,
    Lm::Vector{spoly{L}},
) where L <: Nemo.RingElem
    v = []
    for i = 1:ngens(I)
        ltu = Singular.leading_exponent_vector(Lm[i])
        for e in filter(
            x -> ltu != x,
            collect(Singular.exponent_vectors(gens(I)[i])),
        )
            push!(v, ltu .- e)
        end
    end
    return unique!(v)
end

function diff_vectors(I::Singular.sideal)
    v = []
    for g in gens(I)
        ltu = Singular.leading_exponent_vector(g)
        for e in Singular.exponent_vectors(tail(g))
            push!(v, ltu .- e)
        end
    end
    return unique!(v)
end

###############################################################
#TODO: Change T instead of using a()
###############################################################
function change_order(
    I::Singular.sideal,
    cweight::Array{L,1},
    T::Matrix{Int64},
) where {L<:Number,K<:Number}
    R = I.base_ring
    G = Singular.gens(I.base_ring)
    Gstrich = string.(G)
    S, H = Singular.PolynomialRing(
        R.base_ring,
        Gstrich,
        ordering = Singular.ordering_a(cweight) *
                   Singular.ordering_M(T),
    )
    return S, H
end


function change_order(
    I::Singular.sideal,
    M::Matrix{Int64},
) where {T<:Number,K<:Number}
    R = I.base_ring
    G = Singular.gens(I.base_ring)
    Gstrich = string.(G)
    S, H = Singular.PolynomialRing(
        R.base_ring,
        Gstrich,
        ordering = Singular.ordering_M(M),
    )
    #@error("Not implemented yet")
    return S, H
end

function change_ring(p::Singular.spoly, R::Singular.PolyRing)
    cvzip = zip(Singular.coefficients(p), Singular.exponent_vectors(p))
    M = MPolyBuildCtx(R)
    for (c, v) in cvzip
        Singular.push_term!(M, c, v)
    end
    return finish(M)
end
function change_ring(p::Singular.spoly, R::Singular.PolyRing)
    cvzip = zip(Singular.coefficients(p), Singular.exponent_vectors(p))
    M = MPolyBuildCtx(R)
    for (c, v) in cvzip
        Singular.push_term!(M, c, v)
    end
    return finish(M)
end

function ordering_as_matrix(w::Vector{Int64}, ord::Symbol)
    if length(w) > 2
        if ord == :lex || ord == Symbol("Singular(lp)")
            return [
                w'
                ident_matrix(length(w))[1:length(w)-1, :]
            ]
        end
        if ord == :deglex
            return [
                w'
                ones(Int64, length(w))'
                ident_matrix(length(w))[1:length(w)-2, :]
            ]
        end
        if ord == :degrevlex || a.ord == Symbol("Singular(dp)")
            return [
                w'
                ones(Int64, length(w))'
                anti_diagonal_matrix(length(w))[1:length(w)-2, :]
            ]
        end
    else
        error("not implemented yet")
    end
end

function change_weight_vector(w::Vector{Int64}, M::Matrix{Int64})
    return [
        w'
        M[2:length(w), :]
    ]
end
function insert_weight_vector(w::Vector{Int64}, M::Matrix{Int64})
    return [
        w'
        M[1:length(w)-1, :]
    ]
end


function ordering_as_matrix(ord::Symbol, nvars::Int64)
    if ord == :lex || ord == Symbol("Singular(lp)")
        #return [w'; ident_matrix(length(w))[1:length(w)-1,:]]
        return ident_matrix(nvars)
    end
    if ord == :deglex
        return [
            ones(Int64, nvars)'
            ident_matrix(nvars)[1:nvars-1, :]
        ]
    end
    if ord == :degrevlex || ord == Symbol("Singular(dp)")
        return [
            ones(Int64, nvars)'
            anti_diagonal_matrix(nvars)[1:nvars-1, :]
        ]
    end
end

function pert_Vectors(G::Singular.sideal, Mo::MonomialOrder{Matrix{Int64}}, t::Vector{Int64}, p::Integer)
    if t == Mo.m[1,:]
    M = Mo.m
else
    M = insert_weight_vector(t, Mo.m)
end
m = []
    n = size(M)[1]
    for i = 1:p
        max = M[i, 1]
        for j = 2:n
            temp = abs(M[i, j])
            if temp > max
                max = temp
            end
        end
        push!(m, max)
    end
    msum = 0
    for i = 2:p
        msum = msum + m[i]
    end
    maxtdeg = 0
    for g in gens(G)
        td = tdeg(g,n)
        if (td > maxtdeg)
            maxtdeg = td
        end
    end
    e = maxtdeg * msum + 1
    w = M[1, :] * e^(p - 1)
    for i = 2:p
        w = w + e^(p - i) * M[i, :]
    end
    return w
end

function pert_Vectors(G::Singular.sideal, M::Matrix{Int64}, p::Integer)
    m = []
    n = size(M)[1]
    for i = 1:p
        max = M[i, 1]
        for j = 2:n
            temp = abs(M[i, j])
            if temp > max
                max = temp
            end
        end
        push!(m, max)
    end
    msum = 0
    for i = 2:p
        msum = msum + m[i]
    end
    maxtdeg = 0
    for g in gens(G)
        td = tdeg(g,n)
        if (td > maxtdeg)
            maxtdeg = td
        end
    end
    e = maxtdeg * msum + 1
    w = M[1, :] * e^(p - 1)
    for i = 2:p
        w = w + e^(p - i) * M[i, :]
    end
    return w
end
function pert_Vectors(G::Singular.sideal, T::MonomialOrder{Matrix{Int64}, Vector{Int64}}, p::Integer)
    m = []
    if T.t == T.m[1,:]
    M = T.m
else
    M = insert_weight_vector(T.t, T.m)
end
    n = size(M)[1]
    for i = 1:p
        max = M[i, 1]
        for j = 2:n
            temp = abs(M[i, j])
            if temp > max
                max = temp
            end
        end
        push!(m, max)
    end
    msum = 0
    for i = 2:p
        msum = msum + m[i]
    end
    maxtdeg = 0
    for g in gens(G)
        td = tdeg(g,n)
        if (td > maxtdeg)
            maxtdeg = td
        end
    end
    e = maxtdeg * msum + 1
    w = M[1, :] * e^(p - 1)
    for i = 2:p
        w = w + e^(p - i) * M[i, :]
    end
    return w
end
function pert_Vectors(G::Singular.sideal, T::MonomialOrder{Matrix{Int64}, Vector{Int64}}, mult::Int64, p::Integer)
    m = []
    if T.t == T.m[1,:]
    M = T.m
else
    M = insert_weight_vector(T.t, T.m)
end
    n = size(M)[1]
    for i = 1:p
        max = M[i, 1]
        for j = 2:n
            temp = abs(M[i, j])
            if temp > max
                max = temp
            end
        end
        push!(m, max)
    end
    msum = 0
    for i = 2:p
        msum = msum + m[i]
    end
    maxtdeg = 0
    for g in gens(G)
        td = tdeg(g,n)
        if (td > maxtdeg)
            maxtdeg = td
        end
    end
    e = maxtdeg * msum + 1 * mult
    w = M[1, :] * e^(p - 1)
    for i = 2:p
        w = w + e^(p - i) * M[i, :]
    end
    return w
end

function tdeg(p::Singular.spoly, n::Int64)
    max = 0
    for mon in Singular.monomials(p)
        ev = collect(Singular.exponent_vectors(mon))
        sum = 0
        for e in ev
            for i in 1:n
            sum = e[i] + sum
        end
        end
        if (max < sum)
            max = sum
        end
    end
    return max
end

function inCone(G::Singular.sideal, T::Matrix{Int64},t::Vector{Int64})
    R, V = change_order(G, T)
    I = Singular.Ideal(R, [change_ring(x, R) for x in gens(G)])
    cvzip = zip(Singular.gens(I), initials(R, Singular.gens(I), t))
    for (g, ing) in cvzip
        if !isequal(Singular.leading_term(g), Singular.leading_term(ing))
            return false
        end
    end
    return true
end

function liftGW(G::Singular.sideal, InG::Singular.sideal, R::Singular.PolyRing, S::Singular.PolyRing)
    G.isGB = true
    rest = [
        gen - change_ring(Singular.reduce(change_ring(gen, R), G), S)
        for gen in gens(InG)
    ]
    Gnew = Singular.Ideal(S, [S(x) for x in rest])
    Gnew.isGB = true
    return Gnew
end

#############################################
# unspecific help functions
#############################################

#Use MPolybuildCTX
function vec_sum(p::Vector{spoly{n_Q}}, q::Vector{spoly{n_Q}})
    poly = 0
    for i = 1:length(p)
        poly = poly + p[i] * q[i]
    end
    return poly
end

function ident_matrix(n::Int64)
    M = zeros(Int64, n, n)
    for i = 1:n
        M[i, i] = 1
    end
    return M
end

function anti_diagonal_matrix(n::Int64)
    M = zeros(Int64, n, n)
    for i = 1:n
        M[i, n+1-i] = -1
    end
    return M
end

# Singular.isequal depends on order of generators
function equalitytest(G::Singular.sideal, K::Singular.sideal)
    generators = Singular.gens(G)
    count = 0
    for gen in generators
        for r in Singular.gens(K)
            if gen - r == 0
                count = count + 1
            end
        end
    end
    if count == Singular.ngens(G)
        return true
    end
    return false
end

function dot(v::Vector{Int64}, w::Vector{Int64})
    n = length(v)
    sum = 0
    for i in 1:n
        sum = sum + v[i] * w[i]
    end
    return sum
end
