"""
    AbstractSurveyDesign

Supertype for every survey design type. 

!!! note

    The data passed to a survey constructor is modified. To avoid this pass a copy of the data
    instead of the original.
"""
abstract type AbstractSurveyDesign end

"""
    SurveyDesign <: AbstractSurveyDesign

General survey design encompassing a simple random, stratified, cluster or multi-stage design.

In the case of cluster sample, the clusters are chosen by simple random sampling. All
individuals in one cluster are sampled. The clusters are considered disjoint and nested.

`strata` and `clusters` must be given as columns in `data`.

# Arguments:
- `data::AbstractDataFrame`: the survey dataset (!this gets modified by the constructor).
- `strata::Union{Nothing, Symbol}=nothing`: the stratification variable.
- `clusters::Union{Nothing, Symbol, Vector{Symbol}}=nothing`: the clustering variable.
- `weights::Union{Nothing, Symbol}=nothing`: the sampling weights.
- `popsize::Union{Nothing, Int, Symbol}=nothing`: the (expected) survey population size.

```jldoctest
julia> apistrat = load_data("apistrat");

julia> strat = SurveyDesign(apistrat; strata=:stype, weights=:pw)
SurveyDesign:
data: 200×46 DataFrame
strata: stype
    [E, E, E  …  H]
cluster: none
popsize: [6190.0, 6190.0, 6190.0  …  6190.0]
sampsize: [200, 200, 200  …  200]
weights: [44.2, 44.2, 44.2  …  15.1]
probs: [0.0226, 0.0226, 0.0226  …  0.0662]
```
"""
struct SurveyDesign <: AbstractSurveyDesign
    data::AbstractDataFrame
    cluster::Symbol
    popsize::Symbol
    sampsize::Symbol
    strata::Symbol
    pps::Bool
    # Single stage clusters sample, like apiclus1
    function SurveyDesign(
		data::AbstractDataFrame;
        strata::Union{Nothing, Symbol}=nothing,
        clusters::Union{Nothing, Symbol, Vector{Symbol}}=nothing,
        weights::Union{Nothing, Symbol}=nothing,
        popsize::Union{Nothing, Int, Symbol}=nothing
    )
        # sampsize here is number of clusters completely sampled, popsize is total clusters in population
        if typeof(strata) <: Nothing
            data.false_strata = repeat(["FALSE_STRATA"], nrow(data))
            strata = :false_strata
        end
        if typeof(clusters) <: Nothing
            data.false_cluster = 1:nrow(data)
            cluster = :false_cluster
        end
        ## Single stage approximation
        if typeof(clusters) <: Vector{Symbol}
            cluster = first(clusters)
        end
        if typeof(clusters) <: Symbol
            cluster = clusters
        end
        # For one-stage sample only one sampsize vector
        sampsize_labels = :sampsize
        data[!, sampsize_labels] = fill(length(unique(data[!, cluster])), (nrow(data),))
        if !(typeof(popsize) <: Nothing)
            data[!, :weights] = data[!, popsize] ./ data[!, sampsize_labels]
        elseif !(typeof(weights) <: Nothing)
            data.weights = data[!, weights]
        else
            data.weights = repeat([1], nrow(data))
        end
        data[!, :probs] = 1 ./ data[!, :weights] # Many formulae are easily defined in terms of sampling probabilties
        data[!, :allprobs] = data[!, :probs] # In one-stage cluster sample, allprobs is just probs, no multiplication needed
        pps = false
        if !(typeof(popsize) <: Symbol)
            data.popsize = repeat([sum(data.weights)], nrow(data))
            popsize = :popsize
        end
        new(data, cluster, popsize, sampsize_labels, strata, pps)
    end
end

"""
    ReplicateDesign <: AbstractSurveyDesign

Survey design obtained by replicating an original design using [`bootweights`](@ref).

```jldoctest
julia> apistrat = load_data("apistrat");

julia> strat = SurveyDesign(apistrat; strata=:stype, weights=:pw);

julia> bootstrat = bootweights(strat; replicates=1000)
ReplicateDesign:
data: 200×1046 DataFrame
strata: stype
    [E, E, E  …  H]
cluster: none
popsize: [6190.0, 6190.0, 6190.0  …  6190.0]
sampsize: [200, 200, 200  …  200]
weights: [44.2, 44.2, 44.2  …  15.1]
probs: [0.0226, 0.0226, 0.0226  …  0.0662]
replicates: 1000
```
"""
struct ReplicateDesign <: AbstractSurveyDesign
    data::AbstractDataFrame
    cluster::Symbol
    popsize::Symbol
    sampsize::Symbol
    strata::Symbol
    pps::Bool
    replicates::UInt
end
