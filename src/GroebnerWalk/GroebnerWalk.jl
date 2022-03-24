include("Helper.jl")
include("GroebnerWalkUtilitys.jl")
include("FractalWalkUtilitys.jl")
include("GenericWalkUtilitys.jl")
include("TranWalkUtilitys.jl")


export groebnerwalk

###############################################################
# Implementation of different variants of the Groebner Walk.
# The Groebner Walk is proposed by Collart, Kalkbrener & Mall (1997).
###############################################################

#=
Compute a reduced Groebner basis w.r.t. to a monomial order by converting it using the Groebner Walk.
The Groebner Walk is proposed by Collart, Kalkbrener & Mall (1997).
One can choose a strategy of:
Standard Walk (:standard) computes the Walk like it´s presented in Cox, Little & O´Shea (2005).
Generic Walk (:generic) computes the Walk like it´s presented in Fukuda, Jensen, Lauritzen & Thomas (2005).
Pertubed Walk (:pertubed, with p = degree of the pertubation) computes the Walk like it´s presented in Amrhein, Gloor & Küchlin (1997).
Tran´s Walk (:tran) computes the Walk like it´s presented in Tran (2000).
Fractal Walk (:fractalcombined) computes the Walk like it´s presented in Amrhein & Gloor (1998) with multiple extensions. The target order has to be lex. This version uses the Buchberger Algorithm to skip weight vectors with entries bigger than Int32.
Fractal Walk (:fractal) computes the Walk like it´s presented in Amrhein & Gloor (1998). Pertubes only the target vector.

#Arguments
*`I::Singular.sideal`: ideal one wants to compute a Groebner basis for.
*`startOrder::Symbol=:degrevlex`: monomial order to begin the conversion.
*`targetOrder::Symbol=:lex`: monomial order one wants to compute a Groebner basis for.
*`walktype::Symbol=standard`: strategy of the Groebner Walk. One can choose a strategy of:
    - `standard`: Standard Walk,
    - `pertubed`: Pertubed Walk,
    - `tran`: Tran´s Walk,
    - `generic`: Generic Walk,
    - `fractal`: standard-version of the Fractal Walk,
    - `fractalcombined`: combined Fractal Walk. Target order needs to be lex,
*`pertubationDegree::Int=2`: pertubationdegree for the Pertubed Walk.
*'infoLevel::Int=0':
    -'0': no printout,
    -'1': intermediate weight vectors,
    -'2': information about the Groebner basis.
=#
function groebnerwalk(
    G::Singular.sideal,
    startOrder::Symbol = :degrevlex,
    targetOrder::Symbol = :lex,
    walktype::Symbol = :standard,
    pertubationDegree::Int = 2,
    infoLevel::Int = 0,
)
    R = change_order(
        base_ring(G),
        order_as_matrix(startOrder, nvars(base_ring(G))),
    )
    Gb = std(
        Singular.Ideal(R, [change_ring(x, R) for x in gens(G)]),
        complete_reduction = true,
    )

    return groebnerwalk(
        Gb,
        order_as_matrix(startOrder, nvars(R)),
        order_as_matrix(targetOrder, nvars(R)),
        walktype,
        pertubationDegree,
        infoLevel,
    )
end

#=
Computes a reduced Groebner basis w.r.t. the monomial order T by converting the reduced Groebner basis G w.r.t. the monomial order S using the Groebner Walk.
One can choose a strategy of:
Standard Walk (:standard) computes the Walk like it´s presented in Cox et al. (2005).
Generic Walk (:generic) computes the Walk like it´s presented in Fukuda et al. (2005).
Pertubed Walk (:pertubed, with p = degree of the pertubation) computes the Walk like it´s presented in Amrhein et al. (1997).
Tran´s Walk (:tran) computes the Walk like it´s presented in Tran (2000).
Fractal Walk (:fractal) computes the Walk like it´s presented in Amrhein & Gloor (1998). Pertubes only the target vector.
Fractal Walk (:fractalcombined) computes the Walk like it´s presented in Amrhein & Gloor (1998) with multiple extensions. The target order has to be lex. This version uses the Buchberger Algorithm to skip weightvectors with entries bigger than Int32.

#Arguments
*`G::Singular.sideal`: Groebner basis to convert to the Groebner basis w.r.t. the traget-order.
*`S::Matrix{Int}`: The start order w.r.t. the Groebner basis I. Note that S has to be a nxn-matrix with rank(S)=n.
*`T::Matrix{Int}`: The target order we want to compute a Groebner basis for. Note that T has to be a nxn-matrix with rank(T)=n.
*`grwalktype::Symbol=:standard`: Strategy of the Groebner Walk to be used. There are the strategies:
    - `standard`: Standard Walk (default),
    - `pertubed`: Pertubed Walk,
    - `tran`: Tran´s Walk,
    - `generic`: Generic Walk,
    - `fractal`: standard-version of the Fractal Walk,
    - `fractalcombined`: combined Fractal Walk. Target order needs to be lex,
*`p::Int=2`: Pertubationdegree for the pertubed Walk.
*'infoLevel::Int=0':
    -'0': no printout,
    -'1': intermediate weight vectors,
    -'2': information about the Groebner basis.
=#
function groebnerwalk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    walktype::Symbol = :standard,
    p::Int = 2,
    infoLevel::Int = 1,
)
    if walktype == :standard
        walk = (x) -> standard_walk(x, S, T, infoLevel)
    elseif walktype == :generic
        walk = (x) -> generic_walk(x, S, T, infoLevel)
    elseif walktype == :pertubed
        walk = (x) -> pertubed_walk(x, S, T, p, infoLevel)
    elseif walktype == :fractal
        walk = (x) -> fractal_walk(x, S, T, infoLevel)
    elseif walktype == :fractal_start_order
        walk = (x) -> fractal_walk_start_order(x, S, T, infoLevel)
    elseif walktype == :fractal_lex
        walk = (x) -> fractal_walk_lex(x, S, T, infoLevel)
    elseif walktype == :fractal_look_ahead
        walk = (x) -> fractal_walk_look_ahead(x, S, T, infoLevel)
    elseif walktype == :tran
        walk = (x) -> tran_walk(x, S, T, infoLevel)
    elseif walktype == :fractal_combined
        walk = (x) -> fractal_walk_combined(x, S, T, infoLevel)
    end

    !check_order_M(S, T, G) && throw(
        error(
            "The matrices representing the monomial order have to be nxn-matrices with full rank.",
        ),
    )

    R = base_ring(G)
    Gb = walk(Singular.Ideal(R, [R(x) for x in gens(G)]))
    S = change_order(R, T)
    return Singular.Ideal(S, [change_ring(gen, S) for gen in gens(Gb)])
end


###############################################################
# Implementation of the standard walk.
###############################################################

function standard_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("standard_walk results")
        println("Crossed Cones in: ")
    end

    Gb = standard_walk(G, S, T, S[1, :], T[1, :], infoLevel)
    return Gb
end

function standard_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    currweight::Vector{Int},
    tarweight::Vector{Int},
    infoLevel::Int,
)
    counter = 0
    terminate = false
    while !terminate
        G = standard_step(G, currweight, T)
        if infoLevel >= 1
            println(currweight)
            if infoLevel == 2
                println(G)
            end
        end
        counter += 1
        if currweight == tarweight
            terminate = true
        else
            currweight = next_weight(G, currweight, tarweight)
        end
    end

    if infoLevel >= 1
        println("Cones crossed: ", counter)
    end
    return G
end

###############################################################
# The standard step is used for the strategies standard and pertubed.
###############################################################

function standard_step(G::Singular.sideal, w::Vector{Int}, T::Matrix{Int})
    R = base_ring(G)
    Rn = 0
    Gw = 0

    #check if no entry of w is bigger than Int32. If it´s bigger multiply it by 0.1 and round.
    if !checkInt32(w)
        Gw = initials(R, gens(G), w)
        w, b = truncw(G, w, Gw)
        if !b
            throw(
                error(
                    "Some entries of the intermediate weight-vector $w are bigger than int32",
                ),
            )
        end
        Rn = change_order(R, w, T)
        Gw = [change_ring(x, Rn) for x in Gw]
    else
        Rn = change_order(R, w, T)
        Gw = initials(Rn, gens(G), w)
    end

    H = Singular.std(Singular.Ideal(Rn, Gw), complete_reduction = true)
    #H = liftGW2(G, R, Gw, H, Rn)
    H = lift(G, R, H, Rn)
    return interreduce_walk(H)
end

###############################################################
# Generic-version of the Groebner Walk.
###############################################################

function generic_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    counter = 0
    R = base_ring(G)
    Rn = change_order(G.base_ring, T)
    Lm = [change_ring(Singular.leading_term(g), Rn) for g in gens(G)]
    G = [change_ring(x, Rn) for x in gens(G)]
    v = next_gamma(G, Lm, [0], S, T)

    if infoLevel >= 1
        println("generic_walk results")
        println("Crossed Cones with: ")
    end
    while !isempty(v)
        counter += 1
        G, Lm = generic_step(G, Lm, v, Rn)

        if infoLevel >= 1
            println(v)
            if infoLevel == 2
                println(G)
            end
        end

        v = next_gamma(G, Lm, v, S, T)
    end
    G = Singular.Ideal(Rn, G)
    G.isGB = true
    if infoLevel >= 1
        println("Cones crossed: ", counter)
    end
    # to generate the same coefficients as Singular.std does. This version of the generic walk computes LC(g)=1 for all g \in G.
    return Singular.interreduce(G)
end

function generic_step(
    G::Vector{Singular.spoly{L}},
    Lm::Vector{Singular.spoly{L}},
    v::Vector{Int},
    Rn::Singular.PolyRing,
) where {L<:Nemo.RingElem}
    facet_Generators = facet_initials(G, Lm, v)
    H = Singular.std(
        Singular.Ideal(Rn, facet_Generators),
        complete_reduction = true,
    )
    H, Lm = lift_generic(G, Lm, H)
    G = interreduce(H, Lm)
    return G, Lm
end

###############################################################
#Pertubed-version of the Groebner Walk.
###############################################################

function pertubed_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    p::Int,
    infoLevel::Int,
)
    if infoLevel >= 1
        println("pertubed_walk results")
        println("Crossed Cones in: ")
    end

    currweight = pertubed_vector(G, S, p)
    terminate = false

    while !terminate
        tarweight = pertubed_vector(G, T, p)
        Tn = add_weight_vector(tarweight, T)
        G = standard_walk(G, S, Tn, currweight, tarweight, infoLevel)
        if same_cone(G, T)
            terminate = true
        else
            p = p - 1
            currweight = tarweight
            S = Tn
        end
    end
    return G
end

###############################################################
# The Fractal Walk
###############################################################

###########################################
# Counter for the steps in the Fractal Walk.
###########################################
counterFr = 0
function deleteCounterFr()
    global counterFr
    temp = counterFr
    counterFr = 0
    return temp
end
function getCounterFr()
    global counterFr
    return counterFr
end
function raiseCounterFr()
    global counterFr = getCounterFr() + 1
end
##########################################
# global weightvectors
##########################################
pTargetWeights = []
pStartWeights = []
firstStepMode = false

###############################################################
# Combined version of the extensions of the Fractal Walk.
# This version
# - checks if the starting weight vector represents the order and pertubes it if necessary.
# - analyses the Groebner basis Gw of the initialforms and uses the Buchberger-algorithm if the generators of Gw are binomial or less.
# - skips a step in top level in the last step.
# - checks if an entry of an intermediate weight vector is bigger than int32. In case of that the Buchberger-Algorithm is used to compute the Groebner basis of the ideal of the initialforms.
###############################################################
function fractal_walk_combined(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("fractal_walk_combined results")
        println("Crossed Cones in: ")
    end

    global pTargetWeights =
        [pertubed_vector(G, T, i) for i = 1:nvars(Singular.base_ring(G))]
    Gb = fractal_walk_combined(G, S, T, S[1, :], pTargetWeights, 1, infoLevel)

    if infoLevel >= 1
        println("Cones crossed: ", deleteCounterFr())
    end
    return Gb
end

function fractal_walk_combined(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    currweight::Vector{Int},
    pTargetWeights::Vector{Vector{Int}},
    p::Int,
    infoLevel::Int,
)
    R = Singular.base_ring(G)
    terminate = false
    G.isGB = true

    # Handling the weight of the start order.
    if (p == 1)
        if !ismonomial(initials(R, Singular.gens(G), currweight))
            global pStartWeights = [pertubed_vector(G, S, i) for i = 1:nvars(R)]
            global firstStepMode = true
        end
    end
    if firstStepMode
        w = pStartWeights[p]
    else
        w = currweight
    end

    # main loop
    while !terminate
        t = next_weightfr(G, w, pTargetWeights[p])

        # Handling the final step in the current depth.
        # Next_weightfr may return 0 if the target vector does not lie in the cone of T while G already defines the Groebner basis w.r.t. T.
        # -> Checking if G is already a Groebner basis w.r.t. T solves this problem and reduces computational effort since next_weightfr returns 1 in the last step on every local path.
        if t == 1 && p != 1
            if same_cone(G, T)
                if infoLevel >= 1
                    println("depth $p: in cone ", currweight, ".")
                end

                # Check if a target weight of pTargetWeights[p] and pTargetWeights[p-1] lies in the wrong cone.
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        elseif t == [0] # The Groebner basis w.r.t. the target weight and T is already computed.
            if inCone(G, T, pTargetWeights, p)
                if infoLevel >= 1
                    println("depth $p: in cone ", pTargetWeights[p], ".")
                end
                return G
            end
            global pTargetWeights =
                [pertubed_vector(G, T, i) for i = 1:nvars(R)]
            if infoLevel >= 1
                println("depth $p: not in cone ",pTargetWeights[p], ".")
            end
            continue
        end

        # skip a step for target order lex.
        if t == 1 && p == 1
            if infoLevel >= 1
                println("depth $p: recursive call in ", pTargetWeights[p])
            end
            return fractal_walk_combined(
                G,
                S,
                T,
                w,
                pTargetWeights,
                p + 1,
                infoLevel,
            )
        else
            w = w + t * (pTargetWeights[p] - w)
            w = convert_bounding_vector(w)
            Gw = initials(R, gens(G), w)

            # handling the current weight with regards to Int32-entries. If an entry of w is bigger than Int32 use the Buchberger-algorithm.
            if !checkInt32(w)
                w, b = truncw(G, w, Gw)
                if !b
                    Rn = change_order(R, T)
                    w = T[1, :]
                    G = Singular.std(
                        Singular.Ideal(
                            Rn,
                            [change_ring(x, Rn) for x in gens(G)],
                        ),
                        complete_reduction = true,
                    )
                    if !inCone(G, T, pTargetWeights, p)
                        global pTargetWeights =
                            [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                        if infoLevel >= 1
                            println(
                                "depth $p: not in cone ",
                               pTargetWeights[p],
                                ".",
                            )
                        end
                    end
                    return G
                end
            end
            Rn = change_order(R, w, T)

            # converting the Groebner basis
            if (p == Singular.nvars(R) || isbinomial(Gw))
                H = Singular.std(
                    Singular.Ideal(Rn, [change_ring(x, Rn) for x in Gw]),
                    complete_reduction = true,
                )
                if infoLevel >= 1
                    println("depth $p: conversion in ", w, ".")
                end
                raiseCounterFr()
            else
                if infoLevel >= 1
                    println("depth $p: recursive call in $w.")
                end
                H = fractal_walk_combined(
                    Singular.Ideal(R, Gw),
                    S,
                    T,
                    deepcopy(currweight),
                    pTargetWeights,
                    p + 1,
                    infoLevel,
                )
                global firstStepMode = false
            end
        end
        #H = liftGW2(G, R, Gw, H, Rn)
        H = lift_fractal_walk(G, H, Rn)
        G = interreduce_walk(H)
        R = Rn
        currweight = w
    end
    return G
end

###############################################################
# Plain version of the Fractal Walk.
# This version checks if an entry of an intermediate weight vector is bigger than int32. In case of that the Buchberger-Algorithm is used to compute the Groebner basis of the ideal of the initialforms.
###############################################################

function fractal_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("FractalWalk_standard results")
        println("Crossed Cones in: ")
    end

    global pTargetWeights =
        [pertubed_vector(G, T, i) for i = 1:nvars(base_ring(G))]
    Gb = fractal_recursiv(G, S, T, S[1, :], pTargetWeights, 1, infoLevel)

    if infoLevel >= 1
        println("Cones crossed: ", deleteCounterFr())
    end
    return Gb
end

function fractal_recursiv(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    currweight::Vector{Int},
    pTargetWeights::Vector{Vector{Int}},
    p::Int,
    infoLevel::Int,
)
    R = base_ring(G)
    terminate = false
    G.isGB = true
    w = currweight

    while !terminate
        t = next_weightfr(G, w, pTargetWeights[p])

        # Handling the final step in the current depth.
        # Next_weightfr may return 0 if the target vector does not lie in the cone of T while G already defines the Groebner basis w.r.t. T.
        # -> Checking if G is already a Groebner basis w.r.t. T solves this problem and reduces computational effort since next_weightfr returns 1 in the last step on every local path.        if t == 1 && p != 1
        if t == 1 && p != 1
            if same_cone(G, T)
                if infoLevel >= 1
                    println("depth $p: in cone ", currweight, ".")
                end

                # Check if a target weight of pTargetWeights[p] and pTargetWeights[p-1] lies in the wrong cone.
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        elseif t == [0] # The Groebner basis w.r.t. the target weight and T is already computed.
            if inCone(G, T, pTargetWeights, p)
                if infoLevel >= 1
                    println("depth $p: in cone ",pTargetWeights[p], ".")
                end
                return G
            end
            global pTargetWeights =
                [pertubed_vector(G, T, i) for i = 1:nvars(R)]
            if infoLevel >= 1
                println("depth $p: not in cone ",pTargetWeights[p], ".")
            end
            continue
        end

        w = w + t * (pTargetWeights[p] - w)
        w = convert_bounding_vector(w)
        Gw = initials(R, Singular.gens(G), w)

        # Handling the current weight with regards to Int32-entries. If an entry of w is bigger than Int32 use the Buchberger-algorithm.
        if !checkInt32(w)
            w, b = truncw(G, w, Gw)
            if !b
                Rn = change_order(R, T)
                w = T[1, :]
                G = Singular.std(
                    Singular.Ideal(Rn, [change_ring(x, Rn) for x in gens(G)]),
                    complete_reduction = true,
                )
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        end

        # Converting the Groebner basis
        Rn = change_order(R, w, T)
        if p == nvars(R)
            H = Singular.std(
                Singular.Ideal(Rn, [change_ring(x, Rn) for x in Gw]),
                complete_reduction = true,
            )
            if infoLevel >= 1
                println("depth $p: conversion in ", w, ".")
            end
            raiseCounterFr()
        else
            if infoLevel >= 1
                println("depth $p: recursive call in $w.")
            end
            H = fractal_recursiv(
                Singular.Ideal(R, Gw),
                S,
                T,
                deepcopy(currweight),
                pTargetWeights,
                p + 1,
                infoLevel,
            )
        end
        #H = liftGW2(G, R, Gw, H, Rn)
        H = lift_fractal_walk(G, H, Rn)
        G = interreduce_walk(H)
        R = Rn
        currweight = w
    end
    return G
end

###############################################################
# Extends the plain Fractal Walk by checking the start order.
###############################################################

function fractal_walk_start_order(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("fractal_walk_withStartorder results")
        println("Crossed Cones in: ")
    end

    global pTargetWeights =
        [pertubed_vector(G, T, i) for i = 1:nvars(Singular.base_ring(G))]
    Gb = fractal_walk_recursiv_startorder(
        G,
        S,
        T,
        S[1, :],
        pTargetWeights,
        1,
        infoLevel,
    )

    if infoLevel >= 1
        println("Cones crossed: ", deleteCounterFr())
    end
    return Gb
end

function fractal_walk_recursiv_startorder(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    currweight::Vector{Int},
    pTargetWeights::Vector{Vector{Int}},
    p::Int,
    infoLevel::Int,
)
    R = Singular.base_ring(G)
    terminate = false
    G.isGB = true

    # Handling the starting weight.
    if (p == 1)
        if !ismonomial(initials(R, Singular.gens(G), currweight))
            global pStartWeights = [pertubed_vector(G, S, i) for i = 1:nvars(R)]
            global firstStepMode = true
        end
    end
    if firstStepMode
        w = pStartWeights[p]
    else
        w = currweight
    end

    while !terminate
        t = next_weightfr(G, w, pTargetWeights[p])

        # Handling the final step in the current depth.
        # Next_weightfr may return 0 if the target vector does not lie in the cone of T while G already defines the Groebner basis w.r.t. T.
        # -> Checking if G is already a Groebner basis w.r.t. T solves this problem and reduces computational effort since next_weightfr returns 1 in the last step on every local path.        if t == 1 && p != 1
        if t == 1 && p != 1
            if same_cone(G, T)
                if infoLevel >= 1
                    println("depth $p: in cone ", currweight, ".")
                end

                # Check if a target weight of pTargetWeights[p] and pTargetWeights[p-1] lies in the wrong cone.
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        elseif t == [0] # The Groebner basis w.r.t. the target weight and T is already computed.
            if inCone(G, T, pTargetWeights, p)
                if infoLevel >= 1
                    println("depth $p: in cone ",pTargetWeights[p], ".")
                end
                return G
            end
            global pTargetWeights =
                [pertubed_vector(G, T, i) for i = 1:nvars(R)]
            if infoLevel >= 1
                println("depth $p: not in cone ",pTargetWeights[p], ".")
            end
            continue
        end

        w = w + t * (pTargetWeights[p] - w)
        w = convert_bounding_vector(w)
        Gw = initials(R, gens(G), w)

        # Handling the current weight with regards to Int32-entries. If an entry of w is bigger than Int32 use the Buchberger-algorithm.
        if !checkInt32(w)
            w, b = truncw(G, w, Gw)
            if !b
                Rn = change_order(R, T)
                w = T[1, :]
                G = Singular.std(
                    Singular.Ideal(Rn, [change_ring(x, Rn) for x in gens(G)]),
                    complete_reduction = true,
                )
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        end
        Rn = change_order(R, w, T)

        # Converting the Groebner basis
        if p == Singular.nvars(R)
            H = Singular.std(
                Singular.Ideal(Rn, [change_ring(x, Rn) for x in Gw]),
                complete_reduction = true,
            )
            if infoLevel >= 1
                println("depth $p: conversion in ", w, ".")
            end
            raiseCounterFr()
        else
            if infoLevel >= 1
                println("depth $p: recursive call in $w.")
            end
            H = fractal_walk_recursiv_startorder(
                Singular.Ideal(R, Gw),
                S,
                T,
                deepcopy(currweight),
                pTargetWeights,
                p + 1,
                infoLevel,
            )
            global firstStepMode = false
        end
        #H = liftGW2(G, R, Gw, H, Rn)
        H = lift_fractal_walk(G, H, Rn)
        G = interreduce_walk(H)
        R = Rn
        currweight = w
    end
    return G
end

###############################################################
# Plain version of the Fractal Walk in case of a lexicographic target order.
###############################################################

function fractal_walk_lex(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("fractal_walk_lex results")
        println("Crossed Cones in: ")
    end

    global pTargetWeights =
        [pertubed_vector(G, T, i) for i = 1:nvars(base_ring(G))]
    Gb = fractal_walk_recursive_lex(
        G,
        S,
        T,
        S[1, :],
        pTargetWeights,
        1,
        infoLevel,
    )

    if infoLevel >= 1
        println("Cones crossed: ", deleteCounterFr())
    end
    return Gb
end

function fractal_walk_recursive_lex(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    currweight::Vector{Int},
    pTargetWeights::Vector{Vector{Int}},
    p::Int,
    infoLevel::Int,
)
    R = Singular.base_ring(G)
    terminate = false
    G.isGB = true
    w = currweight

    while !terminate
        t = next_weightfr(G, w, pTargetWeights[p])

        # Handling the final step in the current depth.
        # Handling the final step in the current depth.
        # Next_weightfr may return 0 if the target vector does not lie in the cone of T while G already defines the Groebner basis w.r.t. T.
        # -> Checking if G is already a Groebner basis w.r.t. T solves this problem and reduces computational effort since next_weightfr returns 1 in the last step on every local path.        if t == 1 && p != 1
        if t == 1 && p != 1
            if same_cone(G, T)
                if infoLevel >= 1
                    println("depth $p: in cone ", currweight, ".")
                end

                # Check if a target weight of pTargetWeights[p] and pTargetWeights[p-1] lies in the wrong cone.
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        elseif t == [0] # The Groebner basis w.r.t. the target weight and T is already computed.
            if inCone(G, T, pTargetWeights, p)
                if infoLevel >= 1
                    println("depth $p: in cone ",pTargetWeights[p], ".")
                end
                return G
            end
            global pTargetWeights =
                [pertubed_vector(G, T, i) for i = 1:nvars(R)]
            if infoLevel >= 1
                println("depth $p: not in cone ",pTargetWeights[p], ".")
            end
            continue
        end

        # Skipping a step in lex.
        if t == 1 && p == 1
            return fractal_walk_recursive_lex(
                G,
                S,
                T,
                w,
                pTargetWeights,
                p + 1,
                infoLevel,
            )
        else
            w = w + t * (pTargetWeights[p] - w)
            w = convert_bounding_vector(w)
            Gw = initials(R, Singular.gens(G), w)

            # Handling the current weight with regards to Int32-entries. If an entry of w is bigger than Int32 use the Buchberger-algorithm.
            if !checkInt32(w)
                w, b = truncw(G, w, Gw)
                if !b
                    Rn = change_order(R, T)
                    w = T[1, :]
                    G = Singular.std(
                        Singular.Ideal(
                            Rn,
                            [change_ring(x, Rn) for x in gens(G)],
                        ),
                        complete_reduction = true,
                    )
                    if !inCone(G, T, pTargetWeights, p)
                        global pTargetWeights =
                            [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                        if infoLevel >= 1
                            println(
                                "depth $p: not in cone ",
                               pTargetWeights[p],
                                ".",
                            )
                        end
                    end
                    return G
                end
            end
            Rn = change_order(R, w, T)

            # Converting the Groebnerbasis
            if p == Singular.nvars(R)
                H = Singular.std(
                    Singular.Ideal(Rn, [change_ring(x, Rn) for x in Gw]),
                    complete_reduction = true,
                )
                if infoLevel >= 1
                    println("depth $p: conversion in ", w, ".")
                end
                raiseCounterFr()
            else
                if infoLevel >= 1
                    println("depth $p: recursive call in $w.")
                end
                H = fractal_walk_recursive_lex(
                    Singular.Ideal(R, Gw),
                    S,
                    T,
                    deepcopy(currweight),
                    pTargetWeights,
                    p + 1,
                    infoLevel,
                )
                global firstStepMode = false
            end
        end
        #H = liftGW2(G, R, Gw, H, Rn)
        H = lift_fractal_walk(G, H, Rn)
        G = interreduce_walk(H)
        R = Rn
        currweight = w
    end
    return G
end

###############################################################
# Plain version of the Fractal Walk with look-ahead extension.
###############################################################

function fractal_walk_look_ahead(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("fractal_walk_look_ahead results")
        println("Crossed Cones in: ")
    end

    global pTargetWeights =
        [pertubed_vector(G, T, i) for i = 1:nvars(base_ring(G))]
    Gb = fractal_walk_look_ahead_recursiv(
        G,
        S,
        T,
        S[1, :],
        pTargetWeights,
        1,
        infoLevel,
    )

    if infoLevel >= 1
        println("Cones crossed: ", deleteCounterFr())
    end
    return Gb
end

function fractal_walk_look_ahead_recursiv(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    currweight::Vector{Int},
    pTargetWeights::Vector{Vector{Int}},
    p::Int,
    infoLevel,
)
    R = Singular.base_ring(G)
    terminate = false
    G.isGB = true
    w = currweight

    while !terminate
        t = next_weightfr(G, w, pTargetWeights[p])

        # Handling the final step in the current depth.
        # Next_weightfr may return 0 if the target vector does not lie in the cone of T while G already defines the Groebner basis w.r.t. T.
        # -> Checking if G is already a Groebner basis w.r.t. T solves this problem and reduces computational effort since next_weightfr returns 1 in the last step on every local path.        if t == 1 && p != 1
        if t == 1 && p != 1
            if same_cone(G, T)
                if infoLevel >= 1
                    println("depth $p: in cone ", currweight, ".")
                end

                # Check if a target weight of pTargetWeights[p] and pTargetWeights[p-1] lies in the wrong cone.
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        elseif t == [0] # The Groebner basis w.r.t. the target weight and T is already computed.
            if inCone(G, T, pTargetWeights, p)
                if infoLevel >= 1
                    println("depth $p: in cone ",pTargetWeights[p], ".")
                end
                return G
            end
            global pTargetWeights =
                [pertubed_vector(G, T, i) for i = 1:nvars(R)]
            if infoLevel >= 1
                println("depth $p: not in cone ",pTargetWeights[p], ".")
            end
            continue
        end

        w = w + t * (pTargetWeights[p] - w)
        w = convert_bounding_vector(w)
        Gw = initials(R, Singular.gens(G), w)

        # Handling the current weight with regards to Int32-entries. If an entry of w is bigger than Int32 use the Buchberger-algorithm.
        if !checkInt32(w)
            w, b = truncw(G, w, Gw)
            if !b
                Rn = change_order(R, T)
                w = T[1, :]
                G = Singular.std(
                    Singular.Ideal(Rn, [change_ring(x, Rn) for x in gens(G)]),
                    complete_reduction = true,
                )
                if !inCone(G, T, pTargetWeights, p)
                    global pTargetWeights =
                        [pertubed_vector(G, T, i) for i = 1:nvars(R)]
                    if infoLevel >= 1
                        println("depth $p: not in cone ",pTargetWeights[p], ".")
                    end
                end
                return G
            end
        end
        Rn = change_order(R, w, T)

        # Converting the Groebner basis
        if (p == Singular.nvars(R) || isbinomial(Gw))
            H = Singular.std(
                Singular.Ideal(Rn, [change_ring(x, Rn) for x in Gw]),
                complete_reduction = true,
            )
            if infoLevel >= 1
                println("depth $p: conversion in ", w, ".")
            end
            raiseCounterFr()
        else
            if infoLevel >= 1
                println("depth $p: recursive call in $w.")
            end
            H = fractal_walk_look_ahead_recursiv(
                Singular.Ideal(R, Gw),
                S,
                T,
                deepcopy(currweight),
                pTargetWeights,
                p + 1,
                infoLevel,
            )
        end
        #H = liftGW2(G, R, Gw, H, Rn)
        H = lift_fractal_walk(G, H, Rn)
        G = interreduce_walk(H)
        R = Rn
        currweight = w
    end
    return G
end
global time = 0

###############################################################
# Tran´s version of the Groebner Walk.
# Returns the intermediate Groebner basis if an entry of an intermediate weight vector is bigger than int32.
###############################################################

function tran_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    infoLevel::Int,
)
    if infoLevel >= 1
        println("tran_walk results")
        println("Crossed Cones in: ")
    end

    counter = 0
    currweight = S[1, :]
    tarweight = T[1, :]
    R = base_ring(G)
    if !ismonomial(initials(R, Singular.gens(G), currweight))
        currweight = pertubed_vector(G, S, nvars(R))
    end

    terminate = false
    while !terminate
        w = next_weight(G, currweight, tarweight)

        # return the Groebner basis if an entry of w is bigger than int32.
        if !checkInt32(w)
            w, b = truncw(G, w, initials(R, gens(G), w))
            if !b
                return G
            end
        end
        Rn = change_order(R, w, T)
        if w == tarweight
            if same_cone(G, T)
                return G
            elseif inSeveralCones(initials(base_ring(G), gens(G), tarweight))
                tarweight = representation_vector(G, T)
                continue
            end
        end
        G = standard_step_without_int32_check(G, w, T)
        if infoLevel >= 1
            println(w)
            if infoLevel == 2
                println(G)
            end
        end
        counter += 1
        R = Rn
        currweight = w
    end
    if infoLevel >= 1
        println("Cones crossed: ", counter)
    end
    return G
end

###############################################################
# Standard step without checking of the entries of a given weight vector.
###############################################################

function standard_step_without_int32_check(
    G::Singular.sideal,
    w::Vector{Int},
    T::Matrix{Int},
)
    R = base_ring(G)
    Rn = change_order(R, w, T)
    Gw = initials(Rn, gens(G), w)
    H = Singular.std(Singular.Ideal(Rn, Gw), complete_reduction = true)
    #H = liftGW2(G, R, Gw, H, Rn)
    H = lift(G, R, H, Rn)
    return interreduce_walk(H)
end

###############################################################
# Generic Walk with a choosable pertubationdegree. This version is not tested yet.
###############################################################

function pgeneric_walk(
    G::Singular.sideal,
    S::Matrix{Int},
    T::Matrix{Int},
    p::Int,
    infoLevel::Int,
)
    R = base_ring(G)
    Rn = change_order(G.base_ring, T)
    v = next_gamma(G, [0], S, T, p)
    Lm = [change_ring(Singular.leading_term(g), Rn) for g in gens(G)]
    G = Singular.Ideal(Rn, [change_ring(x, Rn) for x in gens(G)])

    println("generic_walk results")
    println("Crossed Cones with facetNormal: ")
    while !isempty(v)
        global counter = getCounter() + 1
        println(v)
        G, Lm = generic_step(G, Lm, v, T, R)
        v = next_gamma(G, Lm, v, S, T, p)
    end
    return Singular.interreduce(G)
end

function generic_step(
    G::Singular.sideal,
    Lm::Vector{Singular.spoly{L}},
    v::Vector{Int},
    T::Matrix{Int},
    R::Singular.PolyRing,
) where {L<:Nemo.RingElem}

    Rn = Singular.base_ring(G)
    facet_Generators = facet_initials(G, Lm, v)
    H = Singular.std(
        Singular.Ideal(Rn, facet_Generators),
        complete_reduction = true,
    )
    H, Lm = lift_generic(G, Lm, H)
    G = interreduce(H, Lm)
    G = Singular.Ideal(Rn, G)
    G.isGB = true
    return G, Lm
end