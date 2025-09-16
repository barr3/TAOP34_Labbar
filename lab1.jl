using JuMP, HiGHS

m = 10
N = 6
L = 100
M = 3
#total_lenght = L*x
#find minimal value of x that satisfies the demand and minimize waste.
l = [11 13 17 23 37 41 51 61 71 79]


A = [0 0 0 0 0 0 0 0 0 1   
     0 1 1 0 0 0 0 0 0 0
     0 0 0 1 1 0 0 1 0 0
     0 0 0 0 0 0 0 0 1 0
     0 0 0 0 0 1 1 0 0 0
     1 0 0 0 0 0 0 0 0 0]

A = transpose(A)

b = ones(1,m) # Demand
c = ones(1,N)


model = Model(HiGHS.Optimizer)
@variable(model, x[1:N] >= 0)

demand = @constraint(model, A*x .== b)

@objective(model, Min, sum(x))


optimize!(model)
obj = objective_value(model)
x_opt = value.(x)
u = dual.(demand)

println("LP-optimum (sum x) = ", obj)
println("x* = ", x_opt)
println("dualer u = ", u)


function columnGeneration(dualVar)
    print("\n", dualVar)
    columnModel = Model(HiGHS.Optimizer)
    @variable(columnModel, a[1:m]>=0, Bin)
    @constraint(columnModel, column, sum(l[j] * a[j] for j in 1:m) <= L)
    @constraint(columnModel, max_cut , sum(a[j] for j in 1:m) <= M)
    @objective(columnModel, Max, sum(dualVar[i] * a[i] for i in 1:m))
    print("\nColumn Generation!\n")
    optimize!(columnModel)
    println("\n", value.(a))
    return vec(value.(a))
end


y = columnGeneration(u)
# A = hcat(A, x)



# print(transpose(A))

function reducedCost(c, y, A)
    c_bar = c - transpose(y) * A
    return c_bar
end

println(reducedCost(c, y, A))








