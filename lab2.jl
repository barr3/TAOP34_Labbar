using JuMP, HiGHS

c_1 = [10 9 9 13]
c_2 = [12 11 10 9]
A_1 = [16 12 10 8
        7 11 11 9
        8 8 14 12]
A_2 = [8 9 11 4
        7 13 2 15
        13 10 10 3]

B_1 = [9 10 9 9
       10 10 8 9
       9 9 13 13]

B_2 = [7 12 12 13
       11 8 11 10
       11 12 11 10]
b = [125 126 123]

e_1 = [63 68 69]
e_2 = [66 63 71]

x_1 = [0 0 0 0]
x_2 = [0 0 0 0]


function RMP_solver(x_1, x_2, i)
    #RMP
    
    RMP = Model(HiGHS.Optimizer)
    @variable(RMP, lambda[1:i] >= 0)
    @variable(RMP, mu[1:i] >= 0)
    @objective(RMP, Max, (c_1*x_1') * lambda + (c_2*x_2')*mu)
    @constraint(RMP, compted, A_1*x_1*lambda + A_2*x_2*mu <= b')
    @constraint(RMP, lambdacomted, sum(lambda[j] for j in 1:i) == 1)
    @constraint(RMP, mucomted, sum(mu[j] for j in 1:i) == 1)
    optimize!(RMP)

    return value.(lambda), value.(mu), objective_value(RMP)
end

iterMax = 2
for i in 1:iterMax

    println(RMP_solver(x_1, x_2, i))

end



