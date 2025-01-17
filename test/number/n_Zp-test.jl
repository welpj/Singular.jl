@testset "n_Zp.constructors" begin
   F = Fp(7)
   F1 = Fp(7)
   F2 = Fp(7, cached = false)

   @test F isa Singular.Field
   @test F1 isa Singular.Field
   @test F2 isa Singular.Field
   @test F == F1
   @test F != F2
   @test F1 != F2
end

@testset "n_Zp.printing" begin
   R = Fp(5)

   @test string(R(3)) == "-2"

   @test sprint(show, "text/plain", R(3)) == "-2"
end

@testset "n_Zp.manipulation" begin
   R = Fp(5)

   @test isone(one(R))
   @test iszero(zero(R))
   @test isunit(R(1)) && isunit(R(2))
   @test !isunit(R(0))

   @test characteristic(R) == 5

   @test deepcopy(R(2)) == R(2)

   @test Int(R(2)) == 2
end

@testset "n_Zp.unary_ops" begin
   R = Fp(5)

   @test -R(3) == R(2)
   @test -R() == R()
end

@testset "n_Zp.binary_ops" begin
   R = Fp(5)

   a = R(2)
   b = R(3)

   @test a + b == R(0)
   @test a - b == R(4)
   @test a*b == R(1)
end

@testset "n_Zp.comparison" begin
   R = Fp(5)

   @test R(2) == R(2)
   @test isequal(R(2), R(2))
end

@testset "n_Zp.ad_hoc_comparison" begin
   R = Fp(5)

   @test R(2) == 2
   @test 2 == R(2)
   @test isequal(R(2), 2)
   @test isequal(2, R(2))
end

@testset "n_Zp.powering" begin
   R = Fp(5)

   @test R(2)^10 == R(4)
   @test_throws DomainError R(2)^-rand(1:99)
end

@testset "n_Zp.exact_division" begin
   R = Fp(5)

   @test_throws ErrorException inv(zero(R))
   @test_throws ErrorException divexact(one(R), zero(R))
   @test_throws ErrorException divexact(zero(R), zero(R))

   @test inv(R(2)) == R(3)
   @test divexact(R(2), R(3)) == R(4)
end

@testset "n_Zp.gcd_lcm" begin
   R = Fp(5)

   @test gcd(R(2), R(3)) == R(1)
   @test gcd(R(0), R(0)) == R(0)
end

@testset "n_Zp.Polynomials" begin
   R = Fp(5)
   S, x = Nemo.PolynomialRing(R, "x")

   f = 1 + 2x + 3x^2

   g = f^2

   @test g == -x^4+2*x^3-x+1
end

@testset "n_Zp.rand" begin
   F = Fp(7)
   @test rand(F) isa n_Zp
   @test parent(rand(F)) == F
   m = make(F, [1, 3])
   for x in (rand(rng, F, [1, 3]),
             rand(F, [1, 3]),
             rand(rng, m),
             rand(m))

      @test parent(x) == F
      @test x in [F(1), F(3)]
   end
   @test rand(m, 3) isa Vector{n_Zp}
   @test rand(F, 3) isa Vector{n_Zp}
   seed = rand(UInt128)
   Random.seed!(rng, seed)
   x = rand(rng, m)
   Random.seed!(rng, seed)
   @test x == rand(rng, m)
end
