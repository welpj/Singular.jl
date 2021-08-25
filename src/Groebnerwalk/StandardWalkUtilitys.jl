using Oscar

###############################################################
#Utilitys for standard_walk
###############################################################


#Solves problems with weight vectors of floats.
function convertBoundingVector(wtemp::Vector{T}) where {T<:Number}
    w = Vector{Int64}()
    for i = 1:length(wtemp)
        push!(w, float(divexact(wtemp[i], gcd(wtemp))))
    end
    return w
end

function nextw(
    G::Singular.sideal,
    cweight::Array{T,1},
    tweight::Array{K,1},
) where {T<:Number,K<:Number}
    tv = []
    for v in diff_vectors(G)
        cw = dot(cweight, v)
        tw = dot(tweight, v)
        ctw = cw - tw
        if tw < 0
            push!(tv, cw // ctw)
        end
    end
    #tv = [dot(cweight, v) < 0 ? dot(cweight, v) / (dot(cweight, v) - dot(tweight, v)) : nothing for v = V ]
    if isempty(tv)
        return [0]
    end
    t = minimum(tv)
    if (0 == float(t))
        return [0]
    end
    w = (1 - t) * cweight + t * tweight
    return convertBoundingVector(w)
end
