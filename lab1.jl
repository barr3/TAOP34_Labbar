using JuMP, HiGHS

m = 10
L = 100
M = 3
l = [11 13 17 23 37 41 51 61 71 79
]

iterMax = 20
reducedCostThreshold = -1e-8

A = [0 0 0 0 0 1
     0 1 0 0 0 0
     0 1 0 0 0 0
     0 0 1 0 0 0
     0 0 1 0 0 0
     0 0 0 0 1 0
     0 0 0 0 1 0
     0 0 0 0 0 1
     0 0 0 1 0 0
     1 0 0 0 0 0]


b = ones(1,m) # Demand


pattern_len(col) = sum(l[j] for j in 1:m if col[j] > 1e-9)
pattern_pieces(col) = sum(col .> 1e-9)
pattern_waste(col) = L - pattern_len(col)

function columnGeneration(V)
    print("\n", V)
    columnModel = Model(HiGHS.Optimizer)
    @variable(columnModel, a[1:m]>=0, Bin)
    @constraint(columnModel, column, sum(l[j] * a[j] for j in 1:m) <= L)
    @constraint(columnModel, max_cut , sum(a[j] for j in 1:m) <= M)
    @objective(columnModel, Max, sum(V[i] * a[i] for i in 1:m))
    print("\nColumn Generation!\n")
    optimize!(columnModel)
    println("\n", value.(a))
    return vec(value.(a))
end

c_bar_list = []
primal_values_list = []
dual_values_list = []

for i in 1:iterMax
    N = size(A,2)
    LP = Model(HiGHS.Optimizer)

    @variable(LP, x[1:N]>=0)
    @constraint(LP, demand[j in 1:m], sum( A[j,i]*x[i] for i in 1:N ) >= b[j])
    @constraint(LP, maximum[i in 1:N], sum( A[j,i]*x[i] for j in 1:m ) <= M )

    @objective(LP, Min, sum(x) )

    optimize!(LP)

    primal_value = value.(sum(x))
    push!(primal_values_list, primal_value)

    V = [dual(demand[i]) for i in 1:m]
    column = columnGeneration(V)
    c_bar = 1 - V' * column

    dual_value = b * V
    push!(dual_values_list, dual_value)

    push!(c_bar_list, c_bar)

    if c_bar >= reducedCostThreshold
        break
    end
    global A = [A column]
    print(size(A))
end


N = size(A,2)
LP = Model(HiGHS.Optimizer)
@variable(LP, x[1:N], Bin)
@constraint(LP, demand[j in 1:m], sum( A[j,i]*x[i] for i in 1:N ) .== b[j])
@constraint(LP, maximum[i in 1:N], sum( A[j,i]*x[i] for j in 1:m ) <= M )
@objective(LP, Min, sum(x) )
optimize!(LP)

print("\nx values:\n", value.(x), "\n")
print("Objective value: ", objective_value(LP), "\n")
print("\n\nA: ", A)



print("\n\nIteration    Primal/dual value     lower bound     upper bound     reduced cost\n")

for k in 1:length(c_bar_list)
    print(k)
    print(" ")
    print(primal_values_list[k])
    print(" ")
    print(primal_values_list[k] / (1 - c_bar_list[k]))
    print(" ")
    print(primal_values_list[k])
    print(" ")
    print(c_bar_list[k])
    print("\n")
end
