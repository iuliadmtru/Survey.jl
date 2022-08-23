@testset "SurveyDesign.jl" begin
    # SimpleRandomSample tests
    apisrs = load_data("apisrs")

    srs = SimpleRandomSample(apisrs)
    @test srs.data.weights == ones(size(apisrs, 1))
    @test srs.data.weights == srs.data.probs
    # THIS NEEDS TO BE CHANGED WHEN `sampsize` IS UPDATED
    @test srs.data.sampsize[1] == size(apisrs, 1)

    srs_freq = SimpleRandomSample(apisrs; weights = repeat([0.3], size(apisrs, 1)))
    @test srs_freq.data.weights[1] == 0.3
    @test srs_freq.data.weights == 1 ./ srs_freq.data.probs

    srs_prob = SimpleRandomSample(apisrs; probs = repeat([0.3], size(apisrs, 1)))
    @test srs_prob.data.probs[1] == 0.3
    @test srs_prob.data.weights == ones(size(apisrs, 1))
end
