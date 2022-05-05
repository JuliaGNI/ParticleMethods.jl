
# test constructors
l = 7
vars = (x = 1:3, v = 4:6, z = 1:6, w = 7)
params = (a = 1, b = 1.0)

ps = MVector{l}(zeros(l))
p1 = Particle(ps; variables = vars, parameters = params)
p2 = Particle(eltype(ps), length(ps); variables = vars, parameters = params)

@test p1.state == p2.state == ps
@test p1.views == p2.views
@test p1.params == p2.params == params
@test p1.params === p2.params === params

# test assertions
@test_throws AssertionError Particle(ps; variables = (z = 1:6, w = 7), parameters = (a = 1, z = 2))
@test_throws AssertionError Particle(ps; variables = (z = 1:6, state = 7), parameters = (a = 1, b = 2))
@test_throws AssertionError Particle(ps; variables = (z = 1:6, w = 7), parameters = (a = 1, state = 2))


# test getproperty
s = rand(7)
p = Particle(s; variables = (x = 1:3, v = 4:6, z = 1:6, w = 7), parameters = (a = 1, b = 1.0))

# test state vector
@test p.state === s

# test views
@test p.x == p.state[1:3]
@test p.v == p.state[4:6]
@test p.z == p.state[1:6]
@test p.w == fill(p.state[7])

# test parameters
@test p.a == 1
@test p.b == 1.0
